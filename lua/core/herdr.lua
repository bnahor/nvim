-- herdr integration. herdr (https://herdr.dev) owns terminals, layout and
-- agents; Neovim just asks it to do things through the `herdr` CLI.
--
-- Everything here degrades gracefully: outside herdr the same keys fall back
-- to Neovim windows and Snacks terminals.
--
--   <C-h/j/k/l>   move between nvim splits, then across into herdr panes
--   <leader>tt    toggle a shell pane below (stashed, not killed, when hidden)
--   <leader>tv    toggle a shell pane to the right
--   <leader>rr    run a command in the runner pane      <leader>rl  re-run last
--   <leader>rf    run the current file                   <leader>rq  runner output -> quickfix
--   <leader>aa    start an agent next to the editor      <leader>ap  prompt an agent
--   <leader>as    send selection / file ref to an agent  <leader>ag  go to an agent
--   <leader>tz    zen: zoom this pane and hide chrome

local env = require 'core.env'

local M = {}

M.enabled = vim.env.HERDR_ENV == '1' and vim.env.HERDR_PANE_ID ~= nil and vim.fn.executable 'herdr' == 1
M.pane = vim.env.HERDR_PANE_ID

local state = {
  term = {}, -- direction -> { id = pane_id, stashed = bool }
  runner = nil,
  last_cmd = nil,
  agent = nil, -- last agent used
}

-- ---------------------------------------------------------------------------
-- CLI plumbing

local function decode(out)
  local ok, data = pcall(vim.json.decode, out or '')
  if ok and type(data) == 'table' then
    return data.result or data
  end
end

--- Run herdr synchronously. Returns the decoded `.result` table, or nil + error.
function M.call(args)
  local res = vim.system(vim.list_extend({ 'herdr' }, args), { text = true }):wait(5000)
  if res.code ~= 0 then
    return nil, vim.trim((res.stderr ~= '' and res.stderr) or res.stdout or 'herdr failed')
  end
  return decode(res.stdout) or {}
end

--- Run herdr without blocking the editor.
function M.spawn(args, on_done)
  vim.system(vim.list_extend({ 'herdr' }, args), { text = true }, function(res)
    if on_done then
      vim.schedule(function()
        on_done(res.code == 0 and (decode(res.stdout) or {}) or nil, res.stderr)
      end)
    end
  end)
end

local function notify_err(what, err)
  vim.notify(('herdr: %s failed\n%s'):format(what, err or ''), vim.log.levels.WARN)
end

local function alive(id)
  return id and M.call { 'pane', 'get', id } ~= nil
end

local function cwd()
  return vim.fn.getcwd()
end

-- ---------------------------------------------------------------------------
-- Navigation: nvim window first, herdr pane at the edge.

local wincmd_dir = { h = 'left', j = 'down', k = 'up', l = 'right' }

function M.navigate(key)
  local before = vim.api.nvim_get_current_win()
  vim.cmd.wincmd(key)
  if vim.api.nvim_get_current_win() ~= before or not M.enabled then
    return
  end
  M.spawn { 'pane', 'focus', '--direction', wincmd_dir[key], '--current' }
end

-- ---------------------------------------------------------------------------
-- Split panes

--- Split this pane. Returns the new pane id.
function M.split(direction, opts)
  opts = opts or {}
  local args = { 'pane', 'split', '--current', '--direction', direction, '--cwd', opts.cwd or cwd() }
  if opts.ratio then
    vim.list_extend(args, { '--ratio', tostring(opts.ratio) })
  end
  table.insert(args, opts.focus and '--focus' or '--no-focus')
  local res, err = M.call(args)
  if not res then
    return notify_err('split', err)
  end
  return res.pane.pane_id
end

-- ---------------------------------------------------------------------------
-- Toggle terminal. Hiding moves the pane to a stash tab so the shell and
-- whatever it's running survive; showing moves it back next to the editor.

local term_layout = {
  down = { split = 'down', ratio = 0.7 },
  right = { split = 'right', ratio = 0.6 },
}

function M.toggle_term(direction)
  direction = direction or 'down'
  if not M.enabled then
    return Snacks.terminal.toggle(nil, { win = { position = direction == 'down' and 'bottom' or 'right' } })
  end

  local layout = term_layout[direction]
  local t = state.term[direction]

  if t and alive(t.id) then
    if t.stashed then
      local here = M.call { 'pane', 'current', '--current' }
      local res, err = M.call {
        'pane',
        'move',
        t.id,
        '--tab',
        here.pane.tab_id,
        '--split',
        layout.split,
        '--target-pane',
        M.pane,
        '--ratio',
        tostring(layout.ratio),
        '--focus',
      }
      if not res then
        return notify_err('restore terminal', err)
      end
      t.id, t.stashed = res.move_result.pane.pane_id, false
    else
      local res, err = M.call { 'pane', 'move', t.id, '--new-tab', '--label', '󰆓 stash', '--no-focus' }
      if not res then
        return notify_err('stash terminal', err)
      end
      t.id, t.stashed = res.move_result.pane.pane_id, true
    end
    return
  end

  local id = M.split(layout.split, { ratio = layout.ratio, focus = true })
  if id then
    state.term[direction] = { id = id, stashed = false }
  end
end

-- ---------------------------------------------------------------------------
-- Runner pane: run commands next to the editor without leaving it.

local function runner()
  if alive(state.runner) then
    return state.runner
  end
  state.runner = M.split('down', { ratio = 0.7 })
  return state.runner
end

function M.run(cmd)
  if not cmd or cmd == '' then
    return
  end
  state.last_cmd = cmd
  if not M.enabled then
    return Snacks.terminal.open(cmd, { cwd = cwd(), win = { position = 'bottom' }, interactive = false })
  end
  local id = runner()
  if id then
    M.spawn({ 'pane', 'run', id, cmd }, function(ok, err)
      if not ok then
        notify_err('run', err)
      end
    end)
  end
end

function M.run_prompt()
  vim.ui.input({ prompt = 'Run: ', default = state.last_cmd, completion = 'shellcmd' }, M.run)
end

function M.run_last()
  if state.last_cmd then
    M.run(state.last_cmd)
  else
    M.run_prompt()
  end
end

-- How to run the current file, by filetype. %s is the shell-escaped path.
M.runners = {
  python = 'python3 %s',
  lua = 'nvim -l %s',
  sh = 'bash %s',
  bash = 'bash %s',
  zsh = 'zsh %s',
  fish = 'fish %s',
  javascript = 'node %s',
  typescript = 'npx tsx %s',
  go = 'go run %s',
  rust = 'cargo run',
  ruby = 'ruby %s',
  c = 'cc %s -o /tmp/a.out && /tmp/a.out',
  cpp = 'c++ -std=c++20 %s -o /tmp/a.out && /tmp/a.out',
  java = 'java %s',
}

function M.run_file()
  local tmpl = M.runners[vim.bo.filetype]
  if not tmpl then
    return vim.notify('No runner for filetype ' .. vim.bo.filetype .. ' (see core.herdr runners)', vim.log.levels.WARN)
  end
  vim.cmd 'silent! write'
  M.run(tmpl:format(vim.fn.shellescape(vim.fn.expand '%:p')))
end

--- Read the runner pane's recent output into the quickfix list.
function M.runner_to_quickfix()
  if not (M.enabled and alive(state.runner)) then
    return vim.notify('No runner pane', vim.log.levels.WARN)
  end
  local res = vim.system({ 'herdr', 'pane', 'read', state.runner, '--source', 'recent-unwrapped', '--lines', '400' }, { text = true }):wait()
  vim.fn.setqflist({}, ' ', { title = 'runner: ' .. (state.last_cmd or ''), lines = vim.split(res.stdout or '', '\n') })
  vim.cmd 'botright copen'
end

-- ---------------------------------------------------------------------------
-- Agents

local function agents()
  local res = M.call { 'agent', 'list' }
  return res and res.agents or {}
end

local function agent_label(a)
  return ('%s  %s  [%s]'):format(a.name or a.pane_id, a.kind or a.agent or '?', a.status or a.agent_status or '?')
end

--- Pick an agent (skips the picker when there is only one).
local function pick_agent(cb)
  local list = agents()
  if #list == 0 then
    return vim.notify('No agents running. <leader>aa starts one.', vim.log.levels.INFO)
  end
  if #list == 1 then
    return cb(list[1])
  end
  vim.ui.select(list, { prompt = 'Agent', format_item = agent_label }, function(a)
    if a then
      cb(a)
    end
  end)
end

local function target(a)
  return a.name or a.pane_id
end

M.agent_kinds = { 'claude', 'codex', 'gemini', 'opencode', 'cursor', 'copilot', 'amp', 'pi' }

function M.start_agent()
  if not M.enabled then
    return vim.notify('Agents need herdr: run nvim inside a herdr pane', vim.log.levels.WARN)
  end
  local kinds = vim.tbl_filter(function(k)
    return vim.fn.executable(k == 'cursor' and 'cursor-agent' or k) == 1
  end, M.agent_kinds)
  vim.ui.select(kinds, { prompt = 'Start agent' }, function(kind)
    if not kind then
      return
    end
    local id = M.split('right', { ratio = 0.55 })
    if not id then
      return
    end
    local name = ('%s-%d'):format(kind, vim.uv.hrtime() % 1000)
    vim.notify(('Starting %s…'):format(name))
    M.spawn({ 'agent', 'start', name, '--kind', kind, '--pane', id }, function(ok, err)
      if ok then
        state.agent = name
        vim.notify(name .. ' is ready')
      else
        notify_err('agent start', err)
      end
    end)
  end)
end

function M.prompt_agent(text)
  pick_agent(function(a)
    local function send(msg)
      if msg and msg ~= '' then
        state.agent = target(a)
        M.spawn({ 'agent', 'prompt', target(a), msg }, function(ok, err)
          if not ok then
            notify_err('prompt', err)
          end
        end)
      end
    end
    if text then
      send(text)
    else
      vim.ui.input({ prompt = ('Ask %s: '):format(target(a)) }, send)
    end
  end)
end

--- Paste context into an agent's input without submitting, then jump there.
function M.send_context(text)
  pick_agent(function(a)
    M.spawn({ 'pane', 'send-text', a.pane_id, text }, function(ok, err)
      if not ok then
        return notify_err('send', err)
      end
      M.spawn { 'agent', 'focus', target(a) }
    end)
  end)
end

function M.send_selection()
  local s, e = vim.fn.line 'v', vim.fn.line '.'
  if s > e then
    s, e = e, s
  end
  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
  local path = vim.fn.expand '%:.'
  local header = ('%s:%d-%d\n```%s\n'):format(path, s, e, vim.bo.filetype)
  M.send_context(header .. table.concat(lines, '\n') .. '\n```\n')
end

function M.send_file_ref()
  M.send_context(('@%s:%d '):format(vim.fn.expand '%:.', vim.fn.line '.'))
end

function M.goto_agent()
  pick_agent(function(a)
    M.spawn { 'agent', 'focus', target(a) }
  end)
end

-- ---------------------------------------------------------------------------
-- Zen: zoom this herdr pane together with zen-mode.

function M.zoom(on)
  if M.enabled then
    M.spawn { 'pane', 'zoom', '--current', on and '--on' or '--off' }
  end
end

-- ---------------------------------------------------------------------------
-- Pane metadata: let herdr's sidebar show which file is open and where.

local function report_metadata()
  if not M.enabled then
    return
  end
  local name = vim.fn.expand '%:t'
  local args = { 'pane', 'report-metadata', M.pane, '--source', 'herdvim' }
  if name ~= '' and vim.bo.buftype == '' then
    vim.list_extend(args, { '--token', 'file=' .. name })
  else
    vim.list_extend(args, { '--clear-token', 'file' })
  end
  if env.label then
    vim.list_extend(args, { '--token', 'env=' .. env.label })
  end
  M.spawn(args)
end

-- ---------------------------------------------------------------------------

function M.setup()
  local map = vim.keymap.set

  for key in pairs(wincmd_dir) do
    map({ 'n', 't' }, '<C-' .. key .. '>', function()
      if vim.fn.mode() == 't' then
        vim.cmd.stopinsert()
      end
      M.navigate(key)
    end, { desc = 'Move to split/pane ' .. wincmd_dir[key] })
  end

  map('n', '<leader>tt', function()
    M.toggle_term 'down'
  end, { desc = '[T]oggle [T]erminal (below)' })
  map('n', '<leader>tv', function()
    M.toggle_term 'right'
  end, { desc = '[T]oggle terminal [V]ertical' })

  map('n', '<leader>rr', M.run_prompt, { desc = '[R]un command' })
  map('n', '<leader>rl', M.run_last, { desc = '[R]un [L]ast command' })
  map('n', '<leader>rf', M.run_file, { desc = '[R]un current [F]ile' })
  map('n', '<leader>rq', M.runner_to_quickfix, { desc = '[R]unner output to [Q]uickfix' })

  map('n', '<leader>aa', M.start_agent, { desc = '[A]gent: start' })
  map('n', '<leader>ap', function()
    M.prompt_agent()
  end, { desc = '[A]gent: [P]rompt' })
  map('x', '<leader>as', M.send_selection, { desc = '[A]gent: [S]end selection' })
  map('n', '<leader>as', M.send_file_ref, { desc = '[A]gent: [S]end file:line' })
  map('n', '<leader>ag', M.goto_agent, { desc = '[A]gent: [G]o to' })

  if M.enabled then
    local group = vim.api.nvim_create_augroup('herdvim-herdr', { clear = true })
    -- Debounce: buffer switches can come in bursts.
    local timer = assert(vim.uv.new_timer())
    vim.api.nvim_create_autocmd({ 'BufEnter', 'VimEnter' }, {
      group = group,
      callback = function()
        timer:stop()
        timer:start(150, 0, vim.schedule_wrap(report_metadata))
      end,
    })
    vim.api.nvim_create_autocmd('VimLeavePre', {
      group = group,
      callback = function()
        vim.system({ 'herdr', 'pane', 'report-metadata', M.pane, '--source', 'herdvim', '--clear-token', 'file' }):wait(500)
      end,
    })
  end
end

return M

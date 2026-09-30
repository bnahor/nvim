-- Colorscheme, statusline, dashboard, pickers and other things you look at.

local pack = require 'core.pack'
local env = require 'core.env'

pack.add {
  'scottmckendry/cyberdream.nvim',
  'nvim-tree/nvim-web-devicons',
  'folke/snacks.nvim',
  'nvim-lualine/lualine.nvim',
  'folke/which-key.nvim',
  'folke/todo-comments.nvim',
  'nvim-lua/plenary.nvim',
  'j-hui/fidget.nvim',
  'folke/zen-mode.nvim',
}

-- Colorscheme -----------------------------------------------------------------

require('cyberdream').setup { saturation = 1, transparent = true }
vim.cmd.colorscheme 'cyberdream'

local function theme_tweaks()
  vim.api.nvim_set_hl(0, 'Visual', { bg = '#7f3aa0', fg = 'NONE', blend = 20 })
  vim.api.nvim_set_hl(0, 'MatchParen', { bg = '#7f3aa0', fg = '#ffffff', bold = true })
  vim.api.nvim_set_hl(0, 'LineNrAbove', { fg = '#707889' })
  vim.api.nvim_set_hl(0, 'LineNrBelow', { fg = '#707889' })
  vim.api.nvim_set_hl(0, 'Cursor', { bg = env.color })
  vim.api.nvim_set_hl(0, 'CursorInsert', { bg = env.color })
  vim.api.nvim_set_hl(0, 'TreesitterContext', { bg = 'NONE' })
  vim.api.nvim_set_hl(0, 'TreesitterContextLineNumberBottom', { underline = true, sp = 'Grey' })
  env.apply_highlights()
end
theme_tweaks()
vim.api.nvim_create_autocmd('ColorScheme', { callback = theme_tweaks })
vim.o.guicursor = 'n-v-c:block-Cursor,i:ver25-CursorInsert'

-- Snacks: dashboard, picker, indent guides, smooth scroll, lazygit, images ----

local header = [[
                                                                       
                                                                      
       ████ ██████           █████      ██                      
      ███████████             █████                              
      █████████ ███████████████████ ███   ███████████    
     █████████  ███    █████████████ █████ ██████████████    
    █████████ ██████████ █████████ █████ █████ ████ █████    
  ███████████ ███    ███ █████████ █████ █████ ████ █████   
 ██████  █████████████████████ ████ █████ █████ ████ ██████  
                                                                       ]]

if env.label then
  header = header .. '\n\n' .. env.icon .. '  ' .. env.label
end

require('snacks').setup {
  bigfile = { enabled = true },
  quickfile = { enabled = true },
  notifier = { enabled = true },
  input = { enabled = true },
  picker = { enabled = true, ui_select = true },
  indent = { enabled = true },
  image = { enabled = true, doc = { enabled = true, inline = false, float = false, max_width = 80, max_height = 80 } },
  scroll = { enabled = true, animate = { duration = { step = 5, total = 250 }, easing = 'outQuad' } },
  dim = {
    animate = { duration = { step = 2, total = 300 } },
    -- Only dim the buffer you're typing in.
    filter = function(buf)
      return buf == vim.api.nvim_get_current_buf() and vim.g.snacks_dim ~= false and vim.b[buf].snacks_dim ~= false and vim.bo[buf].buftype == ''
    end,
  },
  lazygit = {
    config = {
      os = { editPreset = 'nvim-remote' },
      gui = { nerdFontsVersion = '3' },
    },
  },
  dashboard = {
    sections = {
      { section = 'header' },
      { section = 'keys', gap = 1, padding = 1 },
      { section = 'startup' },
    },
    preset = {
      header = header,
      keys = {
        { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
        { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
        { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
        { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
        { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
        { icon = '󰒲 ', key = 'u', desc = 'Update Plugins', action = ':PackUpdate' },
        { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
      },
    },
  },
}

-- Dim everything but the current buffer while typing.
vim.api.nvim_create_autocmd('InsertEnter', {
  callback = function()
    Snacks.dim.enable()
  end,
})
vim.api.nvim_create_autocmd('InsertLeave', {
  callback = function()
    Snacks.dim.disable()
  end,
})

local map = vim.keymap.set
local P = function(name, opts)
  return function()
    Snacks.picker[name](opts)
  end
end

map('n', '<leader>sf', P 'files', { desc = '[S]earch [F]iles' })
map('n', '<leader>sg', P 'grep', { desc = '[S]earch by [G]rep (append " -- -g *.lua" to filter)' })
map('n', '<leader>sw', P 'grep_word', { desc = '[S]earch current [W]ord' })
map('n', '<leader>sh', P 'help', { desc = '[S]earch [H]elp' })
map('n', '<leader>sk', P 'keymaps', { desc = '[S]earch [K]eymaps' })
map('n', '<leader>sd', P 'diagnostics', { desc = '[S]earch [D]iagnostics' })
map('n', '<leader>sr', P 'resume', { desc = '[S]earch [R]esume' })
map('n', '<leader>ss', P 'pickers', { desc = '[S]earch [S]elect picker' })
map('n', '<leader>s.', P 'recent', { desc = '[S]earch recent files' })
map('n', '<leader>st', P 'todo_comments', { desc = '[S]earch [T]odos' })
map('n', '<leader>s/', P 'grep_buffers', { desc = '[S]earch [/] in open buffers' })
map('n', '<leader>sn', P('files', { cwd = vim.fn.stdpath 'config' }), { desc = '[S]earch [N]eovim config' })
map('n', '<leader>/', P 'lines', { desc = '[/] Search in buffer' })
map('n', '<leader><leader>', P('buffers', { current = false }), { desc = '[ ] Find buffers' })
map('n', '<leader>u', P 'undo', { desc = '[U]ndo history' })
map('n', '<leader>n', function()
  Snacks.notifier.show_history()
end, { desc = '[N]otification history' })

-- Statusline --------------------------------------------------------------------

-- Filename turns red while modified, green once saved.
local fname = require('lualine.components.filename'):extend()
local hl = require 'lualine.highlight'
function fname:init(options)
  fname.super.init(self, options)
  self.colors = {
    saved = hl.create_component_highlight_group({ fg = '#5eff6c' }, 'filename_status_saved', self.options),
    modified = hl.create_component_highlight_group({ fg = '#ff6e5e' }, 'filename_status_modified', self.options),
  }
  self.options.color = self.options.color or ''
end
function fname:update_status()
  local data = fname.super.update_status(self)
  return hl.component_format_highlight(vim.bo.modified and self.colors.modified or self.colors.saved) .. data
end

-- The mode block wears the environment's color, and non-local sessions get a
-- label ("box:api", "ssh:rohan-dev") so you always know where you are.
local where = {
  function()
    return env.icon .. ' ' .. env.label
  end,
  cond = function()
    return env.label ~= nil
  end,
  color = { fg = '#000000', bg = env.color, gui = 'bold' },
}

require('lualine').setup {
  options = { theme = 'auto', component_separators = '', section_separators = '', globalstatus = true },
  sections = {
    lualine_a = { where, { 'mode', color = { fg = '#000000', bg = env.color, gui = 'bold' } } },
    lualine_b = { 'branch', 'diff' },
    lualine_c = { fname },
    lualine_x = {
      { 'diagnostics', sources = { 'nvim_diagnostic' }, symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' } },
    },
    lualine_y = { 'progress' },
    lualine_z = {
      {
        'lsp_status',
        icon = '',
        symbols = { spinner = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }, done = '', separator = ' ' },
        ignore_lsp = { 'copilot' },
      },
    },
  },
}

-- Everything else -----------------------------------------------------------------

require('which-key').setup {
  delay = 0,
  spec = {
    { '<leader>a', group = '[A]gents (herdr)' },
    { '<leader>b', group = '[B]uffer' },
    { '<leader>g', group = '[G]it' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
    { '<leader>l', group = '[L]aTeX' },
    { '<leader>m', group = '[M]arkdown' },
    { '<leader>p', group = '[P]lugins' },
    { '<leader>r', group = '[R]un (herdr)' },
    { '<leader>s', group = '[S]earch' },
    { '<leader>t', group = '[T]oggle / [T]erminal' },
  },
}

require('todo-comments').setup { signs = false }
require('fidget').setup {}

require('zen-mode').setup {
  window = {
    backdrop = 0.95,
    width = 1.0,
    height = 1,
    options = { signcolumn = 'no', cursorline = true, foldcolumn = '0' },
  },
  plugins = {
    options = { enabled = true, ruler = false, showcmd = false, laststatus = 0 },
    gitsigns = { enabled = false },
  },
  -- Zoom the herdr pane too, so neighbouring panes get out of the way.
  on_open = function()
    require('core.herdr').zoom(true)
  end,
  on_close = function()
    require('core.herdr').zoom(false)
  end,
}
map('n', '<leader>tz', '<cmd>ZenMode<CR>', { desc = '[T]oggle [Z]en mode' })

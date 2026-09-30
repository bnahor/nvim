-- Where is this Neovim running? Every surface that shows "where am I"
-- (statusline, cursor line number, window separators, herdr sidebar) reads
-- from here so a box or a remote host is never mistaken for your laptop.
--
--   local   your own machine                         magenta
--   box     an hbox container on this machine         orange
--   remote  an SSH host                               cyan
--   rbox    an hbox container on a remote docker host violet
--
-- Override the color for a session with HERDVIM_COLOR=#rrggbb.

local M = {}

M.palette = {
  ['local'] = '#ff5ef1',
  box = '#ffa14f',
  remote = '#5ef1ff',
  rbox = '#b58cff',
}

local function in_container()
  return vim.env.HBOX_NAME ~= nil or vim.uv.fs_stat '/.dockerenv' ~= nil or vim.uv.fs_stat '/run/.containerenv' ~= nil
end

local function short_host()
  return (vim.uv.os_gethostname() or 'host'):gsub('%..*$', '')
end

-- An hbox marker wins, then SSH (a host you log into is "remote" even if it
-- happens to be a container), then any other container.
if vim.env.HBOX_NAME then
  local host = vim.env.HBOX_HOST
  M.kind = (host and host ~= '') and 'rbox' or 'box'
  M.label = (M.kind == 'rbox') and ('box:%s@%s'):format(vim.env.HBOX_NAME, host) or ('box:' .. vim.env.HBOX_NAME)
  M.icon = '󰆧'
elseif vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
  M.kind = 'remote'
  M.label = 'ssh:' .. short_host()
  M.icon = '󰣀'
elseif in_container() then
  M.kind = 'box'
  M.label = 'box:' .. short_host()
  M.icon = '󰆧'
else
  M.kind = 'local'
  M.label = nil
  M.icon = ''
end

M.color = vim.env.HERDVIM_COLOR or M.palette[M.kind]
M.is_local = M.kind == 'local'

--- Re-apply accent highlights (called after every colorscheme change).
function M.apply_highlights()
  local c = M.color
  vim.api.nvim_set_hl(0, 'HerdvimAccent', { fg = '#000000', bg = c, bold = true })
  vim.api.nvim_set_hl(0, 'HerdvimAccentFg', { fg = c, bold = true })
  vim.api.nvim_set_hl(0, 'CursorLineNr', { fg = c, bold = true })
  vim.api.nvim_set_hl(0, 'LineNr', { fg = c })
  if not M.is_local then
    -- Tint the separators too so a split screen still says "not local".
    vim.api.nvim_set_hl(0, 'WinSeparator', { fg = c })
    vim.api.nvim_set_hl(0, 'FloatBorder', { fg = c })
  end
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('herdvim-env', { clear = true }),
  callback = M.apply_highlights,
})

return M

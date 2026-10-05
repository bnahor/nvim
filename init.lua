-- herdvim: a plain Neovim 0.12+ config built on vim.pack, with herdr as the
-- terminal/pane layer. No distro, no third-party plugin manager.
--
-- Load order matters:
--   core.options  -> leader keys and editor defaults (before any mappings)
--   core.env      -> where are we running? (local / box / remote) and its accent color
--   core.pack     -> tiny helpers around vim.pack
--   plugins.*     -> each file installs and configures one area
--   core.herdr    -> herdr-aware navigation, terminals, runners and agents
--   core.keymaps  -> editor keymaps that don't belong to a plugin
--   local.lua     -> optional, git-ignored personal overrides

-- For the dashboard's "started in N ms".
vim.g.herdvim_start = vim.uv.hrtime()

if vim.fn.has 'nvim-0.12' == 0 then
  vim.notify('herdvim needs Neovim 0.12+ (for vim.pack). Found ' .. tostring(vim.version()), vim.log.levels.ERROR)
  return
end

require 'core.options'
require 'core.env'
require 'core.pack'

for _, name in ipairs {
  'ui',
  'editor',
  'treesitter',
  'lsp',
  'completion',
  'git',
  'files',
  'lang',
  'ai',
} do
  local ok, err = pcall(require, 'plugins.' .. name)
  if not ok then
    vim.notify(('plugins.%s failed to load:\n%s'):format(name, err), vim.log.levels.ERROR)
  end
end

require('core.herdr').setup()
require 'core.keymaps'
require 'core.autocmds'

pcall(require, 'local')

-- Completion (blink.cmp), snippets (LuaSnip) and Copilot suggestions.

local pack = require 'core.pack'

pack.on_build('LuaSnip', function(data)
  -- Optional: jsregexp enables regex-based snippet transforms.
  if vim.fn.executable 'make' == 1 then
    vim.system({ 'make', 'install_jsregexp' }, { cwd = data.path })
  end
end)

pack.add {
  -- Pin to a release so blink downloads its prebuilt fuzzy matcher.
  { src = 'saghen/blink.cmp', version = vim.version.range '1.*' },
  { src = 'L3MON4D3/LuaSnip', version = vim.version.range '2.*' },
  'rafamadriz/friendly-snippets',
  'zbirenbaum/copilot.lua',
}

local luasnip = require 'luasnip'
luasnip.config.setup { enable_autosnippets = true }
require('luasnip.loaders.from_vscode').lazy_load()
require('luasnip.loaders.from_lua').lazy_load { paths = { vim.fn.stdpath 'config' .. '/snippets' } }

require('blink.cmp').setup {
  keymap = { preset = 'default' },
  appearance = { nerd_font_variant = 'mono' },
  completion = { documentation = { auto_show = true, auto_show_delay_ms = 500 } },
  sources = {
    default = { 'lsp', 'path', 'snippets', 'lazydev' },
    providers = {
      lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
    },
  },
  snippets = { preset = 'luasnip' },
  fuzzy = { implementation = 'prefer_rust_with_warning' },
  signature = { enabled = true },
}

-- Copilot loads on first insert so it never slows startup. It needs Node and
-- a one-time `:Copilot auth`; set HERDVIM_COPILOT=0 to turn it off.
if vim.env.HERDVIM_COPILOT ~= '0' then
  vim.api.nvim_create_autocmd('InsertEnter', {
    once = true,
    callback = function()
      require('copilot').setup {
        panel = {
          auto_refresh = false,
          keymap = { accept = '<CR>', jump_prev = '[[', jump_next = ']]', refresh = 'gr', open = '<M-CR>' },
        },
        suggestion = {
          auto_trigger = true,
          keymap = { accept = '<C-l>', prev = '<M-[>', next = '<M-]>', dismiss = '<C-]>' },
        },
      }
    end,
  })
end

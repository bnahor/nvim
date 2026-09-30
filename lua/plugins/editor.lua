-- Editing: motions, text objects, pairs, folds, alignment.

local pack = require 'core.pack'

pack.add {
  'NMAC427/guess-indent.nvim',
  'nvim-mini/mini.nvim',
  'windwp/nvim-autopairs',
  'windwp/nvim-ts-autotag',
  'folke/flash.nvim',
  'junegunn/vim-easy-align',
  'kevinhwang91/promise-async',
  'kevinhwang91/nvim-ufo',
  'luukvbaal/statuscol.nvim',
}

local map = vim.keymap.set

require('guess-indent').setup {}

-- Better around/inside text objects: va), yinq, ci'
require('mini.ai').setup { n_lines = 500 }

-- Surround under gs* so that s/S stay free for flash.
require('mini.surround').setup {
  mappings = {
    add = 'gsa',
    delete = 'gsd',
    find = 'gsf',
    find_left = 'gsF',
    highlight = 'gsh',
    replace = 'gsr',
    update_n_lines = 'gsn',
  },
}

require('nvim-autopairs').setup {}
require('nvim-ts-autotag').setup {
  opts = { enable_close = true, enable_rename = true, enable_close_on_slash = false },
}

require('flash').setup { modes = { search = { enabled = false } } }
map({ 'n', 'x', 'o' }, 's', function()
  require('flash').jump()
end, { desc = 'Flash' })
map({ 'n', 'x', 'o' }, 'S', function()
  require('flash').treesitter()
end, { desc = 'Flash Treesitter' })

map({ 'n', 'x' }, 'ga', '<Plug>(EasyAlign)', { desc = 'Align text' })

-- Folds: LSP ranges where available, treesitter for markdown, indent otherwise.
require('ufo').setup {
  provider_selector = function(_, ft)
    if ft == 'markdown' then
      return { 'treesitter', 'indent' }
    end
    return { 'lsp', 'indent' }
  end,
}
map('n', 'zR', function()
  require('ufo').openAllFolds()
end, { desc = 'Open all folds' })
map('n', 'zM', function()
  require('ufo').closeAllFolds()
end, { desc = 'Close all folds' })

-- Gutter: fold arrows, signs, then line numbers.
local builtin = require 'statuscol.builtin'
require('statuscol').setup {
  setopt = true,
  segments = {
    { text = { builtin.foldfunc, ' ' }, click = 'v:lua.ScFa' },
    { text = { '%s' }, click = 'v:lua.ScSa' },
    { text = { builtin.lnumfunc, ' ' }, condition = { true, builtin.not_empty }, click = 'v:lua.ScLa' },
  },
}

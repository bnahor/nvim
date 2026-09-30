-- Language extras: LaTeX and Markdown.

local pack = require 'core.pack'

pack.on_build('markdown-preview.nvim', function()
  vim.fn['mkdp#util#install']()
end)

pack.add {
  'lervag/vimtex',
  'iurimateus/luasnip-latex-snippets.nvim',
  'iamcco/markdown-preview.nvim',
  'MeanderingProgrammer/render-markdown.nvim',
  'bullets-vim/bullets.vim',
}

local group = vim.api.nvim_create_augroup('herdvim-lang', { clear = true })
local on_ft = function(ft, fn)
  vim.api.nvim_create_autocmd('FileType', { group = group, pattern = ft, callback = fn })
end

-- LaTeX ------------------------------------------------------------------------------

vim.g.vimtex_view_method = vim.fn.has 'mac' == 1 and 'skim' or 'zathura'
vim.g.vimtex_compiler_method = 'latexmk'
vim.g.vimtex_quickfix_mode = 0
vim.g.vimtex_quickfix_ignore_filters = { 'Underfull', 'Overfull', 'specifier changed to' }
vim.g.vimtex_mappings_enabled = 0
vim.g.vimtex_imaps_enabled = 0
vim.g.vimtex_complete_enabled = 1

require('luasnip-latex-snippets').setup()

--- Replace the buffer with a template from snippets/templates/latex.
local function pick_latex_template()
  Snacks.picker.files {
    title = 'LaTeX Templates',
    cwd = vim.fn.stdpath 'config' .. '/snippets/templates/latex',
    confirm = function(picker, item)
      picker:close()
      if not item then
        return
      end
      local lines = vim.fn.readfile(Snacks.picker.util.path(item))
      vim.schedule(function()
        vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
      end)
    end,
  }
end

on_ft({ 'tex', 'latex' }, function(ev)
  local map = function(lhs, rhs, desc)
    vim.keymap.set('n', lhs, rhs, { buffer = ev.buf, desc = desc })
  end
  map('<leader>ll', '<cmd>VimtexCompile<CR>', 'Compile LaTeX')
  map('<leader>lv', '<cmd>VimtexView<CR>', 'View PDF')
  map('<leader>ls', '<cmd>VimtexForwardSearch<CR>', 'Forward search')
  map('<leader>lc', '<cmd>VimtexClean<CR>', 'Clean auxiliary files')
  map('<leader>le', '<cmd>VimtexErrors<CR>', 'Show errors')
  map('<leader>lt', '<cmd>VimtexToggleMain<CR>', 'Toggle main file')
  map('<leader>nt', pick_latex_template, 'Pick LaTeX template')

  -- Compile on save unless a compile is already running.
  vim.api.nvim_create_autocmd('BufWritePost', {
    buffer = ev.buf,
    group = group,
    callback = function()
      local v = vim.b.vimtex
      if v and v.compiler and not v.compiler.is_running then
        vim.cmd 'VimtexCompile'
      end
    end,
  })
end)

-- Markdown ---------------------------------------------------------------------------

vim.g.mkdp_filetypes = { 'markdown' }

require('render-markdown').setup {
  completions = { blink = { enabled = true } },
}

on_ft('markdown', function(ev)
  vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<CR>', { buffer = ev.buf, desc = '[M]arkdown [P]review' })
  vim.keymap.set('n', '<leader>mr', '<cmd>RenderMarkdown toggle<CR>', { buffer = ev.buf, desc = '[M]arkdown [R]ender' })
end)

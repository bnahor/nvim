local group = vim.api.nvim_create_augroup('herdvim-core', { clear = true })

vim.api.nvim_create_autocmd('TextYankPost', {
  group = group,
  desc = 'Highlight when yanking text',
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd('BufReadPost', {
  group = group,
  desc = 'Return to the last cursor position',
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines and vim.bo[ev.buf].filetype ~= 'gitcommit' then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd('VimResized', {
  group = group,
  desc = 'Equalise splits when herdr resizes the pane',
  command = 'wincmd =',
})

vim.api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = { 'markdown', 'text', 'gitcommit', 'tex' },
  callback = function()
    vim.opt_local.linebreak = true
  end,
})

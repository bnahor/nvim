-- AI agents run in herdr panes rather than inside Neovim; see lua/core/herdr.lua
-- (<leader>a…). This file only teaches Neovim to notice when an agent edits
-- a file you have open.

vim.o.autoread = true

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'TermLeave' }, {
  group = vim.api.nvim_create_augroup('herdvim-autoread', { clear = true }),
  callback = function()
    if vim.fn.mode() ~= 'c' and vim.fn.getcmdwintype() == '' then
      vim.cmd 'silent! checktime'
    end
  end,
})

vim.api.nvim_create_autocmd('FileChangedShellPost', {
  group = 'herdvim-autoread',
  callback = function(ev)
    vim.notify(('Reloaded %s (changed on disk)'):format(vim.fn.fnamemodify(ev.file, ':.')), vim.log.levels.INFO)
  end,
})

local pack = require 'core.pack'

pack.add { 'lewis6991/gitsigns.nvim' }

require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  on_attach = function(buf)
    local gs = require 'gitsigns'
    local map = function(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = buf, desc = desc })
    end

    map('n', ']c', function()
      if vim.wo.diff then
        vim.cmd.normal { ']c', bang = true }
      else
        gs.nav_hunk 'next'
      end
    end, 'Next git [c]hange')
    map('n', '[c', function()
      if vim.wo.diff then
        vim.cmd.normal { '[c', bang = true }
      else
        gs.nav_hunk 'prev'
      end
    end, 'Previous git [c]hange')

    map('v', '<leader>hs', function()
      gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, '[S]tage hunk')
    map('v', '<leader>hr', function()
      gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
    end, '[R]eset hunk')
    map('n', '<leader>hs', gs.stage_hunk, '[S]tage hunk')
    map('n', '<leader>hr', gs.reset_hunk, '[R]eset hunk')
    map('n', '<leader>hS', gs.stage_buffer, '[S]tage buffer')
    map('n', '<leader>hR', gs.reset_buffer, '[R]eset buffer')
    map('n', '<leader>hp', gs.preview_hunk, '[P]review hunk')
    map('n', '<leader>hb', gs.blame_line, '[B]lame line')
    map('n', '<leader>hd', gs.diffthis, '[D]iff against index')
    map('n', '<leader>hD', function()
      gs.diffthis '@'
    end, '[D]iff against last commit')
    map('n', '<leader>tb', gs.toggle_current_line_blame, '[T]oggle [B]lame line')
    map('n', '<leader>tD', gs.preview_hunk_inline, '[T]oggle [D]eleted')
  end,
}

-- lazygit floats inside nvim and opens files back in this instance.
vim.keymap.set('n', '<leader>gg', function()
  Snacks.lazygit.open()
end, { desc = 'Lazy[g]it' })
vim.keymap.set('n', '<leader>gl', function()
  Snacks.lazygit.log()
end, { desc = 'Lazygit [l]og' })
vim.keymap.set('n', '<leader>gf', function()
  Snacks.lazygit.log_file()
end, { desc = 'Lazygit [f]ile history' })
vim.keymap.set('n', '<leader>gb', function()
  Snacks.picker.git_branches()
end, { desc = 'Git [b]ranches' })
vim.keymap.set({ 'n', 'x' }, '<leader>go', function()
  Snacks.gitbrowse()
end, { desc = 'Git [o]pen in browser' })

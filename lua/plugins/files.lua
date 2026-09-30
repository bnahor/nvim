-- File explorers: neo-tree for the sidebar, oil for editing directories as buffers.

local pack = require 'core.pack'

pack.add {
  'MunifTanjim/nui.nvim',
  { src = 'nvim-neo-tree/neo-tree.nvim', version = 'v3.x' },
  { src = 's1n7ax/nvim-window-picker', name = 'window-picker', version = vim.version.range '2.*' },
  'stevearc/oil.nvim',
}

require('window-picker').setup {
  selection_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
  hint = 'floating-big-letter',
  picker_config = { handle_mouse_click = true },
}

require('neo-tree').setup {
  close_if_last_window = true,
  default_component_configs = {
    indent = {
      indent_size = 1,
      with_markers = true,
      indent_marker = '│',
      last_indent_marker = '└',
      expander_collapsed = '',
      expander_expanded = '',
    },
  },
  window = {
    width = 40,
    mappings = { ['<space>'] = 'none' },
  },
  filesystem = {
    follow_current_file = { enabled = true },
    use_libuv_file_watcher = true,
    filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = false },
    window = {
      mappings = {
        ['o'] = 'open_with_window_picker',
        ['<cr>'] = 'open_with_window_picker',
        ['s'] = 'open_split',
        ['v'] = 'open_vsplit',
        ['\\'] = 'close_window',
      },
    },
  },
}

require('oil').setup {
  default_file_explorer = false,
  delete_to_trash = true,
  watch_for_changes = true,
  sort = { { 'type', 'asc' }, { 'name', 'asc' } },
}

local map = vim.keymap.set
map('n', '<leader>e', '<cmd>Neotree toggle<CR>', { desc = 'File tree' })
map('n', '<leader>o', '<cmd>Neotree focus<CR>', { desc = 'Focus file tree' })
map('n', '\\', '<cmd>Neotree reveal<CR>', { desc = 'Reveal file in tree', silent = true })
map('n', '<leader>E', '<cmd>Oil<CR>', { desc = 'Oil (edit directory)' })
map('n', '<leader>w', function()
  local win = require('window-picker').pick_window()
  if win then
    vim.api.nvim_set_current_win(win)
  end
end, { desc = 'Pick a [w]indow' })

-- Editor keymaps that don't belong to a specific plugin.
-- Plugin keymaps live next to the plugin in lua/plugins/*.lua,
-- herdr keymaps live in lua/core/herdr.lua.

local map = vim.keymap.set

map('n', '<Esc>', '<cmd>nohlsearch<CR>')
map('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

map('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Diagnostics to loclist' })
map('n', ']q', '<cmd>cnext<CR>', { desc = 'Next quickfix item' })
map('n', '[q', '<cmd>cprevious<CR>', { desc = 'Previous quickfix item' })
map('n', '<leader>bd', function()
  Snacks.bufdelete()
end, { desc = '[B]uffer [D]elete' })

map('n', '<leader>ts', function()
  vim.wo.spell = not vim.wo.spell
end, { desc = '[T]oggle [S]pell' })

-- Move by visual lines when wrapping, unless a count is given.
map({ 'n', 'v' }, 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true })
map({ 'n', 'v' }, 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true })
map({ 'n', 'v' }, '0', 'g0', { desc = 'Visual line start' })
map({ 'n', 'v' }, '_', 'g^', { desc = 'Visual line first non-blank' })
map({ 'n', 'v' }, '$', 'g$', { desc = 'Visual line end' })

-- Keep the selection when indenting.
map('v', '<', '<gv')
map('v', '>', '>gv')

map('n', '<leader>pu', '<cmd>PackUpdate<CR>', { desc = '[P]lugins: [U]pdate' })
map('n', '<leader>ps', '<cmd>PackStatus<CR>', { desc = '[P]lugins: [S]tatus' })

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true

local o = vim.o

o.number = true
o.relativenumber = true
o.mouse = 'a'
o.showmode = false
o.breakindent = true
o.undofile = true
o.ignorecase = true
o.smartcase = true
o.signcolumn = 'yes'
o.updatetime = 250
o.timeoutlen = 300
o.splitright = true
o.splitbelow = true
o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
o.inccommand = 'split'
o.cursorline = true
o.scrolloff = 10
o.confirm = true
o.termguicolors = true
o.winborder = 'rounded'
o.spell = false
vim.opt.spelllang = { 'en_gb' }

-- Folding (nvim-ufo drives the actual folds)
o.foldcolumn = '1'
o.foldlevel = 99
o.foldlevelstart = 99
o.foldenable = true
o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

-- Let herdr's sidebar and the host terminal show what nvim is editing.
o.title = true
o.titlestring = 'nvim %t'

-- Sync the clipboard after startup; it can be slow to initialise.
-- Over SSH and inside boxes there is no system clipboard, so use OSC 52,
-- which herdr and most terminals forward to the local clipboard.
vim.schedule(function()
  if vim.env.SSH_TTY or vim.env.HBOX_NAME then
    vim.g.clipboard = 'osc52'
  end
  o.clipboard = 'unnamedplus'
end)

vim.diagnostic.config {
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = vim.diagnostic.severity.ERROR },
  virtual_text = { source = 'if_many', spacing = 2 },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = '󰅚 ',
      [vim.diagnostic.severity.WARN] = '󰀪 ',
      [vim.diagnostic.severity.INFO] = '󰋽 ',
      [vim.diagnostic.severity.HINT] = '󰌶 ',
    },
  },
}

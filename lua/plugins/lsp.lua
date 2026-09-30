-- Language servers, formatters and linters.
--
-- Servers are configured with the built-in vim.lsp.config() and installed by
-- Mason. nvim-lspconfig only supplies the per-server defaults (cmd,
-- filetypes, root markers). Add a server: put it in `servers` below.

local pack = require 'core.pack'

pack.add {
  'neovim/nvim-lspconfig',
  'mason-org/mason.nvim',
  'mason-org/mason-lspconfig.nvim',
  'WhoIsSethDaniel/mason-tool-installer.nvim',
  'folke/lazydev.nvim',
  'stevearc/conform.nvim',
  'mfussenegger/nvim-lint',
}

-- Per-server overrides. An empty table means "defaults are fine".
local servers = {
  lua_ls = {
    settings = { Lua = { completion = { callSnippet = 'Replace' } } },
  },
  clangd = {},
  cssls = {},
  html = {},
  jdtls = {},
  marksman = {},
  pyright = {},
  texlab = {},
  ts_ls = {},
  rust_analyzer = {},
}

-- Non-LSP tools Mason should install.
local tools = { 'stylua', 'prettier', 'latexindent', 'markdownlint' }

-- Mason has no build of some tools for every platform, and asking for one
-- that can't install stalls :MasonToolsInstallSync forever.
local unsupported = {
  latexindent = jit.os == 'Linux' and jit.arch == 'arm64',
}
tools = vim.tbl_filter(function(t)
  return not unsupported[t]
end, tools)

-- Inside a box, keep the image lean: only install what the project needs.
-- Set HERDVIM_LSP="pyright,ts_ls" (or "none") to choose.
if vim.env.HERDVIM_LSP then
  local only = {}
  for s in vim.env.HERDVIM_LSP:gmatch '[^,%s]+' do
    only[s] = true
  end
  servers = vim.tbl_isempty(only) and {}
    or vim
      .iter(servers)
      :filter(function(k)
        return only[k]
      end)
      :fold({}, function(acc, k, v)
        acc[k] = v
        return acc
      end)
  if only.none then
    tools = {}
  end
end

require('lazydev').setup {
  library = { { path = '${3rd}/luv/library', words = { 'vim%.uv' } } },
}

require('mason').setup {}

for name, cfg in pairs(servers) do
  if not vim.tbl_isempty(cfg) then
    vim.lsp.config(name, cfg)
  end
end

require('mason-lspconfig').setup {
  ensure_installed = {},
  automatic_enable = vim.tbl_keys(servers),
}

-- mason-tool-installer translates lspconfig names (lua_ls) to Mason packages
-- (lua-language-server) itself, once the registry is available. Don't map
-- them here: on a fresh machine the registry isn't downloaded yet.
require('mason-tool-installer').setup {
  ensure_installed = vim.list_extend(vim.list_extend({}, tools), vim.tbl_keys(servers)),
}

-- Keymaps when a server attaches. Neovim already maps grn/gra/grr/gri/grt/gO;
-- these swap the list-style ones for pickers.
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('herdvim-lsp-attach', { clear = true }),
  callback = function(ev)
    local map = function(keys, fn, desc, mode)
      vim.keymap.set(mode or 'n', keys, fn, { buffer = ev.buf, desc = 'LSP: ' .. desc })
    end
    local P = function(name)
      return function()
        Snacks.picker[name]()
      end
    end

    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')
    map('gra', vim.lsp.buf.code_action, 'Code [A]ction', { 'n', 'x' })
    map('grr', P 'lsp_references', '[R]eferences')
    map('gri', P 'lsp_implementations', '[I]mplementation')
    map('grd', P 'lsp_definitions', '[D]efinition')
    map('grD', vim.lsp.buf.declaration, '[D]eclaration')
    map('grt', P 'lsp_type_definitions', '[T]ype definition')
    map('gO', P 'lsp_symbols', 'Document symbols')
    map('gW', P 'lsp_workspace_symbols', 'Workspace symbols')

    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    -- Highlight references of the word under the cursor.
    if client:supports_method('textDocument/documentHighlight', ev.buf) then
      local group = vim.api.nvim_create_augroup('herdvim-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, { buffer = ev.buf, group = group, callback = vim.lsp.buf.document_highlight })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, { buffer = ev.buf, group = group, callback = vim.lsp.buf.clear_references })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('herdvim-lsp-detach', { clear = true }),
        callback = function(ev2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'herdvim-lsp-highlight', buffer = ev2.buf }
        end,
      })
    end

    if client:supports_method('textDocument/inlayHint', ev.buf) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = ev.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- Formatting ----------------------------------------------------------------------

require('conform').setup {
  notify_on_error = false,
  format_on_save = function(buf)
    if ({ c = true, cpp = true })[vim.bo[buf].filetype] then
      return nil
    end
    return { timeout_ms = 500, lsp_format = 'fallback' }
  end,
  formatters_by_ft = {
    lua = { 'stylua' },
    tex = { 'latexindent' },
    latex = { 'latexindent' },
    html = { 'prettier' },
    css = { 'prettier' },
  },
}
vim.keymap.set('', '<leader>f', function()
  require('conform').format { async = true, lsp_format = 'fallback' }
end, { desc = '[F]ormat buffer' })

-- Linting --------------------------------------------------------------------------

local lint = require 'lint'
lint.linters_by_ft = { markdown = { 'markdownlint' } }
vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
  group = vim.api.nvim_create_augroup('herdvim-lint', { clear = true }),
  callback = function()
    if vim.bo.modifiable then
      lint.try_lint()
    end
  end,
})

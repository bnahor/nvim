-- Treesitter (main branch): parsers are installed by nvim-treesitter, but
-- highlighting, folds and indent are switched on per buffer below.
-- Needs the `tree-sitter` CLI and a C compiler; `:checkhealth nvim-treesitter`.

local pack = require 'core.pack'

pack.on_build('nvim-treesitter', function()
  vim.cmd 'TSUpdate'
end)

pack.add {
  { src = 'nvim-treesitter/nvim-treesitter', version = 'main' },
  'nvim-treesitter/nvim-treesitter-context',
}

local ts = require 'nvim-treesitter'

-- Always installed. Anything else is installed the first time you open it.
local ensure = {
  'bash',
  'c',
  'css',
  'diff',
  'html',
  'javascript',
  'json',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'python',
  'query',
  'regex',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'yaml',
}

local installed = {}
for _, lang in ipairs(ts.get_installed()) do
  installed[lang] = true
end

local missing = vim.tbl_filter(function(l)
  return not installed[l]
end, ensure)
if #missing > 0 and vim.fn.executable 'tree-sitter' == 1 then
  ts.install(missing)
end

-- LaTeX highlighting is left to vimtex.
local skip = { tex = true, latex = true }

local available
local function can_install(lang)
  available = available or ts.get_available()
  return vim.tbl_contains(available, lang)
end

local function enable(buf, lang)
  if not pcall(vim.treesitter.start, buf, lang) then
    return
  end
  vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('herdvim-treesitter', { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang or skip[ev.match] then
      return
    end
    if vim.treesitter.language.add(lang) then
      return enable(ev.buf, lang)
    end
    -- Parser not installed yet: fetch it in the background, then enable.
    if vim.fn.executable 'tree-sitter' == 1 and can_install(lang) then
      ts.install({ lang }):await(function()
        vim.schedule(function()
          if vim.api.nvim_buf_is_valid(ev.buf) then
            enable(ev.buf, lang)
          end
        end)
      end)
    end
  end,
})

require('treesitter-context').setup { mode = 'cursor', multiline_threshold = 20 }
vim.keymap.set('n', '<leader>tc', function()
  require('treesitter-context').toggle()
end, { desc = '[T]oggle [C]ontext' })

return { ensure = ensure }

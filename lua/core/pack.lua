-- Thin helpers over the built-in plugin manager (:help vim.pack).
--
--   :PackUpdate          review and apply plugin updates (write to confirm, :q to cancel)
--   :PackSync            reset every plugin to the revision in nvim-pack-lock.json
--   :PackClean           delete plugins that are on disk but no longer in the config
--   :PackStatus          list managed plugins without touching the network

local M = {}

--- Short GitHub source: gh 'folke/snacks.nvim'
function M.gh(repo)
  return 'https://github.com/' .. repo
end

--- Install (if needed) and load plugins. Accepts 'owner/repo' strings or vim.pack specs.
function M.add(specs)
  local resolved = {}
  for _, spec in ipairs(specs) do
    if type(spec) == 'string' then
      spec = { src = M.gh(spec) }
    elseif not spec.src:find '://' then
      spec = vim.tbl_extend('force', spec, { src = M.gh(spec.src) })
    end
    table.insert(resolved, spec)
  end
  vim.pack.add(resolved, { confirm = false })
end

-- Build hooks keyed by plugin name. They run on install and on update.
local builds = {}

function M.on_build(name, fn)
  builds[name] = fn
end

-- Must be registered before the first vim.pack.add() so it also fires
-- when plugins are installed from the lockfile on a fresh machine.
vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('herdvim-pack-build', { clear = true }),
  callback = function(ev)
    local data = ev.data
    local build = builds[data.spec.name]
    if build and (data.kind == 'install' or data.kind == 'update') then
      if not data.active then
        vim.cmd.packadd(data.spec.name)
      end
      local ok, err = pcall(build, data)
      if not ok then
        vim.notify(('build for %s failed: %s'):format(data.spec.name, err), vim.log.levels.WARN)
      end
    end
  end,
})

local function inactive()
  return vim
    .iter(vim.pack.get(nil, { info = false }))
    :filter(function(p)
      return not p.active
    end)
    :map(function(p)
      return p.spec.name
    end)
    :totable()
end

vim.api.nvim_create_user_command('PackUpdate', function(args)
  vim.pack.update(#args.fargs > 0 and args.fargs or nil)
end, { nargs = '*', desc = 'Update plugins (review, then :write to apply)' })

vim.api.nvim_create_user_command('PackSync', function()
  vim.pack.update(nil, { target = 'lockfile' })
end, { desc = 'Reset plugins to nvim-pack-lock.json' })

vim.api.nvim_create_user_command('PackStatus', function()
  vim.pack.update(nil, { offline = true })
end, { desc = 'Show installed plugins' })

vim.api.nvim_create_user_command('PackClean', function()
  local names = inactive()
  if #names == 0 then
    vim.notify 'No unused plugins'
    return
  end
  if vim.fn.confirm('Delete unused plugins?\n' .. table.concat(names, '\n'), '&Yes\n&No', 2) == 1 then
    vim.pack.del(names)
  end
end, { desc = 'Delete plugins no longer in the config' })

package.loaded['core.pack'] = M
return M

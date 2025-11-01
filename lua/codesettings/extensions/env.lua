local Control = require('codesettings.extensions').Control

---@class CodesettingsEnvExtension: CodesettingsLoaderExtension
local M = {}

function M.expand_env(str)
  -- Handle ${VAR:-default} syntax
  str = str:gsub('%${([%w_]+):%-([^}]-)}', function(var, default)
    return vim.env[var] or default
  end)

  -- Handle ${VAR} syntax
  str = str:gsub('%${([%w_]+)}', function(var)
    return vim.env[var] or ''
  end)

  -- Handle $VAR syntax (optional)
  str = str:gsub('%$([%w_]+)', function(var)
    return vim.env[var] or ''
  end)

  return str
end

function M.leaf(value, _)
  if type(value) == 'string' then
    local expanded = M.expand_env(value)
    if expanded ~= value then
      return Control.REPLACE, expanded
    end
  end
  return Control.CONTINUE
end

return M

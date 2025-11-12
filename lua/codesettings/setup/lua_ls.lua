local Util = require('codesettings.util')

local M = {}

function M.setup()
  ---@type lsp.lua_ls
  local lua_ls_settings = (vim.lsp.config.lua_ls or {}).settings or {}
  local library = vim.tbl_get(lua_ls_settings, 'Lua', 'workspace', 'library') or {}
  vim.list_extend(library, { Util.path('lua/codesettings/generated') })
  vim.lsp.config('lua_ls', {
    settings = {
      Lua = {
        workspace = {
          library = library,
        },
      },
    },
  })

  -- lazy loading; if lua_ls is already active, restart it
  vim.defer_fn(function()
    Util.did_change_configuration('lua_ls', vim.lsp.config.lua_ls, true)
  end, 500)
end

return M

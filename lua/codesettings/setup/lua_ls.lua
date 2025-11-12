local Util = require('codesettings.util')

local M = {}

function M.setup()
  ---@type lsp.lua_ls
  local config_update = {
    settings = {
      Lua = {
        workspace = {
          library = { Util.path('lua/codesettings/generated') },
        },
      },
    },
  }

  Util.ensure_lsp_settings('lua_ls', config_update)
end

return M

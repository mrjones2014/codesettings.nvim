local Util = require('codesettings.util')

local M = {}

function M.setup()
  local config_update = {
    ---@type lsp.lua_ls
    settings = {
      Lua = {
        workspace = {
          library = { Util.path('lua/codesettings/generated') },
        },
      },
    },
  }

  Util.ensure_lsp_settings('lua_ls', config_update)
  Util.ensure_lsp_settings('emmylua_ls', config_update)
end

return M

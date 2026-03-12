local Util = require('codesettings.util')

local M = {}

function M.setup()
  local generated_dir = Util.runtime_dir('lua/codesettings/generated/annotations.lua')
  local config_update = {
    ---@type lsp.lua_ls
    settings = {
      Lua = {
        workspace = {
          library = generated_dir and { generated_dir } or {},
        },
      },
    },
  }

  Util.ensure_lsp_settings('lua_ls', config_update)
  Util.ensure_lsp_settings('emmylua_ls', config_update)
end

return M

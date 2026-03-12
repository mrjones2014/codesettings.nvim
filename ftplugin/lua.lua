---@type boolean
vim.g.codesettings_lua_ls_setup_done = vim.g.codesettings_lua_ls_setup_done

if vim.g.codesettings_lua_ls_setup_done then
  return
end

local Config = require('codesettings.config')

if
  Config.lua_ls_integration == false
  or (type(Config.lua_ls_integration) == 'function' and (not Config.lua_ls_integration()))
then
  return
end

require('codesettings.integrations.luals').setup()

local Config = require('codesettings.config')

if
  Config.lua_ls_integration == false
  or (type(Config.lua_ls_integration) == 'function' and (not Config.lua_ls_integration()))
then
  return
end

require('codesettings.integrations.luals').setup()

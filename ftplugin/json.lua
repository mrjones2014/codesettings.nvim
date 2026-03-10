local Config = require('codesettings.config')

if Config.jsonc_filetype then
  require('codesettings.integrations.jsonc').setup()
end

if Config.jsonls_integration then
  require('codesettings.integrations.jsonls').setup()
end

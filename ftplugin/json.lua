---@type boolean
vim.g.codesettings_jsonc_setup_done = vim.g.codesettings_jsonc_setup_done
---@type boolean
vim.g.codesettings_jsonls_setup_done = vim.g.codesettings_jsonls_setup_done

if vim.g.codesettings_jsonc_setup_done and vim.g.codesettings_jsonls_setup_done then
  return
end

local Config = require('codesettings.config')

if Config.jsonc_filetype and not vim.g.codesettings_jsonc_setup_done then
  require('codesettings.integrations.jsonc').setup()
end

if Config.jsonls_integration and not vim.g.codesettings_jsonls_setup_done then
  require('codesettings.integrations.jsonls').setup()
end

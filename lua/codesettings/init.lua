local Util = require('codesettings.util')
local Settings = require('codesettings.settings')

local M = {}

---Load settings from project-local config files. By default looks for
---.vscode/settings.json, codesettings.json, and lspsettings.json, but this is configurable.
---@param lsp_name string|nil the name of the LSP, like 'rust-analyzer' or 'tsserver', or nil to get all settings
---@return Settings config settings object, if any local config files were found, empty Settings object otherwise
function M.load(lsp_name)
  local root = Util.get_root()
  if not root then
    return Settings.new()
  end

  local settings = Settings.new()
  vim.iter(Util.get_local_configs()):each(function(fname)
    settings = settings:merge(Settings.get(fname))
  end)

  if lsp_name then
    return settings:get_for_lsp_schema(lsp_name)
  end

  return settings
end

---Load settings from VS Code settings.json file
---@param lsp_name string the name of the LSP, like 'rust-analyzer' or 'tsserver'
---@param config table the LSP config to merge the vscode settings into
function M.with_local_settings(lsp_name, config)
  local settings = M.load()
  local lsp_settings = settings:get_for_lsp_schema(lsp_name):to_tbl()

  local result = Util.merge(config, { settings = lsp_settings })
  return result
end

function M.setup(opts)
  require('codesettings.config').setup(opts)
end

return M

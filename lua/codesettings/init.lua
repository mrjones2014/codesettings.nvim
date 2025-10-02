local Util = require('codesettings.util')
local Settings = require('codesettings.settings')

local M = {}

---Load settings from .vscode/settings.json
---@return Settings config VS Code settings object, if a .vscode/settings.json exists, empty otherwise
function M.load()
  local root = Util.get_root()
  if not root then
    return Settings.new()
  end

  local settings = Settings.get(('%s/.vscode/settings.json'):format(root))
  if not settings then
    return Settings.new()
  end

  return settings
end

---Load settings from VS Code settings.json file
---@param namespace string the namespace VS Code's settings.json uses, usually LSP name but not always (yamlls uses 'yaml')
---@param config table the LSP config to merge the vscode settings into
function M.with_vscode_settings(namespace, config)
  local settings = M.load()
  local namespaced_settings = settings:get(namespace)
  if not namespaced_settings then
    return config
  end

  local result = Util.merge(config, { settings = namespaced_settings })
  return result
end

return M

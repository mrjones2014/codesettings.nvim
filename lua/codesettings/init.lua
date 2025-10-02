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
---@param lsp_name string the name of the LSP, like 'rust-analyzer' or 'tsserver'
---@param config table the LSP config to merge the vscode settings into
function M.with_vscode_settings(lsp_name, config)
  local settings = M.load()
  local lsp_settings = settings:get_for_lsp_schema(lsp_name):to_tbl()

  local result = Util.merge(config, { settings = lsp_settings })
  return result
end

return M

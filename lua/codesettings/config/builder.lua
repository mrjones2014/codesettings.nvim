local Config = require('codesettings.config')

local M = {}

---@class ConfigBuilder
---@field private _config CodesettingsOverridableConfig
local ConfigBuilder = {}
ConfigBuilder.__index = ConfigBuilder

---Create a new ConfigBuilder, initialized with the default global config
---@return ConfigBuilder
function M.new()
  ---@type CodesettingsOverridableConfig
  local opts = {
    config_file_paths = Config.config_file_paths,
    root_dir = Config.root_dir,
    merge_opts = Config.merge_opts,
  }
  return setmetatable({ _config = opts }, ConfigBuilder)
end

---Set the config file paths to look for
---@param paths string[]
---@return ConfigBuilder
function ConfigBuilder:config_file_paths(paths)
  self._config.config_file_paths = paths
  return self
end

---Set the merge behavior for list fields
---@param behavior CodesettingsMergeListsBheavior
---@return ConfigBuilder
function ConfigBuilder:merge_list_behavior(behavior)
  self._config.merge_opts = self._config.merge_opts or {}
  self._config.merge_opts.list_behavior = behavior
  return self
end

---Set the root directory path or function to determine it
---@param root string|fun():string Root directory path or function to determine it
---@return ConfigBuilder
function ConfigBuilder:root_dir(root)
  self._config.root_dir = root
  return self
end

---Return the resulting configuration table
---@return CodesettingsOverridableConfig
function ConfigBuilder:build()
  return self._config
end

return M

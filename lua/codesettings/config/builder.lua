local Config = require('codesettings.config')

local M = {}

---@class CodesettingsConfigBuilder
---@field private _config CodesettingsOverridableConfig
local ConfigBuilder = {}
ConfigBuilder.__index = ConfigBuilder

---Create a new ConfigBuilder, initialized with the default global config
---@return CodesettingsConfigBuilder
function M.new()
  ---@type CodesettingsOverridableConfig
  local opts = {
    config_file_paths = Config.config_file_paths,
    root_dir = Config.root_dir,
    merge_opts = Config.merge_opts,
    loader_extensions = Config.loader_extensions,
  }
  return setmetatable({ _config = opts }, ConfigBuilder)
end

---Set the config file paths to look for
---@param config_file_paths string[]
---@return CodesettingsConfigBuilder
function ConfigBuilder:config_file_paths(config_file_paths)
  vim.validate('config_file_paths', config_file_paths, function()
    if
      not vim.islist(config_file_paths)
      or vim.iter(config_file_paths):any(function(v)
        return type(v) ~= 'string'
      end)
    then
      return false
    end
    return true
  end, 'string[]')
  self._config.config_file_paths = config_file_paths
  return self
end

---Set the merge behavior for list fields
---@param behavior CodesettingsMergeListsBehavior
---@return CodesettingsConfigBuilder
function ConfigBuilder:merge_list_behavior(behavior)
  vim.validate('behavior', behavior, function(v)
    return v == 'replace' or v == 'append' or v == 'prepend'
  end, "'replace' | 'append' | 'prepend'")
  self._config.merge_opts = self._config.merge_opts or {}
  self._config.merge_opts.list_behavior = behavior
  return self
end

---Set the root directory path or function to determine it. If nil, uses global setting.
---@param root_dir? string|fun():string Root directory path or function to determine it; if nill, uses global setting
---@return CodesettingsConfigBuilder
function ConfigBuilder:root_dir(root_dir)
  vim.validate('root_dir', root_dir, { 'nil', 'string', 'function' })
  self._config.root_dir = root_dir or self._config.root_dir
  return self
end

---Set the loader extensions to use when loading settings; `string` values will be `require`d
---@param extensions (string|CodesettingsLoaderExtension)[]
---@return CodesettingsConfigBuilder
function ConfigBuilder:extensions(extensions)
  vim.validate('extensions', extensions, 'table')
  for _, ext in ipairs(extensions) do
    vim.validate('extension', ext, { 'string', 'table' })
  end
  self._config.loader_extensions = extensions
  return self
end

---Return the resulting configuration table
---@return CodesettingsConfigOverrides
function ConfigBuilder:build()
  -- self._config is of type CodesettingsOverridableConfig,
  -- CodesettingsConfigOverrides is just a `@class (partial)` of that type
  return self._config --[[@as CodesettingsConfigOverrides]]
end

---Load the local settings, using the configuration built by this builder (i.e. you may
---have overridden some options like `root_dir` or `config_file_paths`).
---@return CodesettingsSettings
function ConfigBuilder:local_settings()
  return require('codesettings').local_settings(self:build())
end

---Load the local settings and merge them into the given LSP config,
---using the configuration built by this builder (i.e. you may
---have overridden some options like `root_dir` or `config_file_paths`).
---@param lsp_name string the name of the LSP, like 'rust-analyzer' or 'tsserver'
---@param config table the LSP config to merge the vscode settings into
---@return table config the merged config
function ConfigBuilder:with_local_settings(lsp_name, config)
  return require('codesettings').with_local_settings(lsp_name, config, self:build())
end

return M

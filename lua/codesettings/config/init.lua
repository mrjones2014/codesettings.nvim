---Input type for config options that can be overridden per-load
---@class (partial) CodesettingsConfigOverrides: CodesettingsOverridableConfig

---@class CodesettingsOverridableConfig Options which can be passed on a per-load basis (i.e. can override global config)
---@field config_file_paths string[] List of config file paths to look for
---@field merge_opts CodesettingsMergeOpts Default options for merging settings
---@field root_dir (string|fun():string)? Function or string to determine the project root directory; defaults to `require('codesettings.util').get_root()`
---@field loader_extensions (string|CodesettingsLoaderExtension)[] List of loader extensions to use when loading settings; `string` values will be `require`d

---@class CodesettingsConfig: CodesettingsOverridableConfig
---@field jsonls_integration boolean Integrate with jsonls for LSP settings completion
---@field lua_ls_integration boolean|fun():boolean Integrate with lua_ls for LSP settings completion; can be a function so that, for example, you can enable it only if editing your nvim config
---@field jsonc_filetype boolean Set filetype to jsonc for config files

---@class CodesettingsConfigModule: CodesettingsConfig
---@field setup fun(opts: table|nil) Sets up the configuration with user options
---@field private reset fun() Resets the configuration to defaults, useful for tests

---@type CodesettingsConfig
local options = {
  config_file_paths = { '.vscode/settings.json', 'codesettings.json', 'lspsettings.json' },
  jsonls_integration = true,
  lua_ls_integration = true,
  jsonc_filetype = true,
  root_dir = nil, -- use the default root finder
  merge_opts = {
    list_behavior = 'append',
  },
  loader_extensions = {},
}

local defaults = vim.deepcopy(options)

local Config = {}

---@class (partial) CodesettingsConfigInput: CodesettingsConfig

---Merge user-supplied options into the defaults.
---@param opts CodesettingsConfigInput|nil
function Config.setup(opts)
  opts = opts or {}
  options = vim.tbl_deep_extend('force', {}, options, opts)

  if options.jsonls_integration then
    require('codesettings.integrations.jsonls').setup()
  end

  if options.jsonc_filetype then
    require('codesettings.integrations.jsonc-filetype').setup()
  end

  local lua_ls_integration = options.lua_ls_integration
  if lua_ls_integration == true or (type(lua_ls_integration) == 'function' and lua_ls_integration()) then
    require('codesettings.integrations.lua_ls').setup()
  end
end

---Reset the configuration to defaults.
---Useful for testing.
function Config.reset()
  options = vim.deepcopy(defaults)
end

setmetatable(Config, {
  __index = function(_, k)
    return options[k]
  end,
  __newindex = function(_, k, v)
    options[k] = v
  end,
  __pairs = function()
    return next, options, nil
  end,
})

-- it implements the type through the metatable above,
-- set the type information so that consuming modules get
-- the right info through the LSP
---@cast Config CodesettingsConfigModule
return Config

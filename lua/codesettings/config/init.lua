local ConfigSchema = require('codesettings.config.schema')

---@class CodesettingsConfigModule: CodesettingsConfig
---@field setup fun(opts: table|nil) Sets up the configuration with user options
---@field jsonschema fun(): CodesettingsSchema Returns a canonical JSON schema for codesettings configuration
---@field private reset fun() Resets the configuration to defaults, useful for tests

---@class (partial) CodesettingsConfigInput: CodesettingsConfig

local options = ConfigSchema.defaults()

local Config = {}

---Merge user-supplied options into the defaults.
---@param opts CodesettingsConfigInput|nil
function Config.setup(opts)
  opts = opts or {}
  options = vim.tbl_deep_extend('force', {}, options, opts)

  -- configure the plugin itself with local files
  -- NB: do this first in case local files turn off integrations
  local Settings = require('codesettings.settings')
  local settings = Settings.load_all()
  local plugin_config = settings:schema(Config.jsonschema()):get('codesettings') or {}
  options = vim.tbl_deep_extend('force', {}, options, plugin_config)

  if options.jsonls_integration then
    require('codesettings.setup.jsonls').setup()
  end

  if options.jsonc_filetype then
    require('codesettings.setup.jsonc-filetype').setup()
  end

  local lua_ls_integration = options.lua_ls_integration
  if lua_ls_integration == true or (type(lua_ls_integration) == 'function' and lua_ls_integration()) then
    require('codesettings.setup.lua_ls').setup()
  end

  if options.live_reload then
    require('codesettings.setup.live-reload').setup()
  end
end

---Reset the configuration to defaults.
---Useful for testing.
function Config.reset()
  options = ConfigSchema.defaults()
end

---Get the canonical JSON schema for codesettings configuration.
---@return CodesettingsSchema
function Config.jsonschema()
  return ConfigSchema.jsonschema()
end

setmetatable(Config, {
  __index = function(_, k)
    return options[k]
  end,
  __newindex = function(_, k, v)
    options[k] = v
  end,
})

---@cast Config CodesettingsConfigModule
return Config

local Util = require('codesettings.util')

---@class CodesettingsConfigModule: CodesettingsConfig
---@field setup fun(opts: table|nil) Sets up the configuration with user options
---@field jsonschema fun(): CodesettingsSchema Returns a canonical JSON schema for codesettings configuration
---@field private reset fun() Resets the configuration to defaults, useful for tests

---@class (partial) CodesettingsConfigInput: CodesettingsConfig

local options = vim.deepcopy(require('codesettings.generated.defaults'))

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

  if options.live_reload then
    require('codesettings.integrations.live-reload').setup()
  end
end

---Reset the configuration to defaults.
---Useful for testing.
function Config.reset()
  options = vim.deepcopy(require('codesettings.generated.defaults'))
end

local _jsonschema
---Get the canonical JSON schema for codesettings configuration.
---@return CodesettingsSchema
function Config.jsonschema()
  if not _jsonschema then
    local Schema = require('codesettings.schema')
    local json_str = Util.read_file(Util.path('schemas/codesettings.json'))
    _jsonschema = Schema.from_table(vim.fn.json_decode(json_str))
  end
  return _jsonschema
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

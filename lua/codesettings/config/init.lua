local Schema = require('codesettings.schema')

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
---@field jsonschema fun(): CodesettingsSchema Returns a canonical JSON schema for codesettings configuration
---@field private reset fun() Resets the configuration to defaults, useful for tests

---@class (partial) CodesettingsConfigInput: CodesettingsConfig

local config_schema = Schema.new({
  type = 'object',
  properties = {
    config_file_paths = {
      type = 'array',
      items = { type = 'string' },
      description = 'List of config file paths to look for',
      default = { '.vscode/settings.json', 'codesettings.json', 'lspsettings.json' },
    },
    merge_opts = {
      type = 'object',
      properties = {
        list_behavior = {
          type = 'string',
          description = 'How to merge lists',
          default = 'append',
        },
      },
      default = { list_behavior = 'append' },
    },
    root_dir = {
      type = { 'string', 'function', 'nil' },
      description = 'Function or string to determine the project root directory',
      default = nil,
    },
    loader_extensions = {
      type = 'array',
      items = { type = { 'string', 'object' } },
      description = 'List of loader extensions to use when loading settings',
      default = {},
    },
    jsonls_integration = {
      type = 'boolean',
      description = 'Integrate with jsonls for LSP settings completion',
      default = true,
    },
    lua_ls_integration = {
      type = { 'boolean', 'function' },
      description = 'Integrate with lua_ls for LSP settings completion',
      default = true,
    },
    jsonc_filetype = {
      type = 'boolean',
      description = 'Set filetype to jsonc for config files',
      default = true,
    },
  },
})

local options = config_schema:defaults_table()

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
  options = vim.deepcopy(config_schema:defaults_table())
end

---Get the cacnonical JSON schema for codesettings configuration.
---@return CodesettingsSchema
function Config.jsonschema()
  -- NB: here we want to return the canconical schema,
  -- which means we should look for a top-level `codesettings` property
  return Schema.from_table({
    ['$schema'] = 'http://json-schema.org/draft-07/schema#',
    type = 'object',
    properties = {
      codesettings = config_schema:totable(),
    },
  }):flatten()
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

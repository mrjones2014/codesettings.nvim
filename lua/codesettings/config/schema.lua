local Schema = require('codesettings.schema')

---Raw schema definition for codesettings configuration
---This is the single source of truth for both JSON schema and Lua types
local M = {}

---@class CodesettingsConfigFunctionType
---@field args string[] List of argument types
---@field ret string Return type

---@alias CodesettingsSchemaType string|CodesettingsConfigFunctionType|(string|CodesettingsConfigFunctionType)[]

---@class CodesettingsSchemaValue
---@field type CodesettingsSchemaType Type or types of the value
---@field description string Description of the value
---@field default any Default value
---@field overridable boolean|nil Whether the value can be overridden by workspace settings; default false
---@field enum string[]|nil List of allowed values (for enum validation)
---@field items CodesettingsSchemaValue|nil Schema for items if type is array
---@field properties table<string, CodesettingsSchemaValue>|nil Schema for properties if type is object

---@alias CodesettingsMergeListsBehavior 'replace'|'append'|'prepend'

---Check if a type definition is a function type table
---@param t any
---@return boolean
function M.is_function_type(t)
  return type(t) == 'table' and t.args ~= nil and t.ret ~= nil
end

function M.function_type(args, ret)
  return { args = args, ret = ret }
end

---@type table<string, CodesettingsSchemaValue> JSON Schema properties for codesettings configuration
M.properties = {
  config_file_paths = {
    type = 'array',
    items = { type = 'string', description = 'List of relative config file paths to look for' },
    description = 'Look for these config files',
    default = { '.vscode/settings.json', 'codesettings.json', 'lspsettings.json' },
    overridable = true,
  },
  merge_lists = {
    type = 'CodesettingsMergeListsBehavior',
    description = [[How to merge lists; 'append' (default), 'prepend' or 'replace']],
    enum = { 'replace', 'append', 'prepend' },
    default = 'append',
    overridable = true,
  },
  root_dir = {
    type = { 'string', M.function_type({}, 'string'), 'null' },
    description = [[Provide your own root dir; can be a string or function returning a string.
It should be/return the full absolute path to the root directory.
If not set, defaults to `require('codesettings.util').get_root()`]],
    default = vim.NIL,
    overridable = true,
  },
  loader_extensions = {
    type = 'array',
    items = {
      type = { 'string', 'CodesettingsLoaderExtension', M.function_type({}, 'CodesettingsLoaderExtension') },
      description = 'List of module paths, or inline extension instances',
    },
    description = 'List of loader extensions to use when loading settings; `string` values will be `require`d',
    default = { 'codesettings.extensions.vscode' },
    overridable = true,
  },
  jsonls_integration = {
    type = 'boolean',
    description = 'Integrate with jsonls to provide LSP completion for LSP settings based on schemas',
    default = true,
  },
  lua_ls_integration = {
    type = { 'boolean', M.function_type({}, 'boolean') },
    description = [[Set up library paths for `lua_ls` automatically to pick up the generated type
annotations provided by codesettings.nvim; to enable for only your nvim config,
you can also do something like:
lua_ls_integration = function()
  return vim.uv.cwd() == ('%%s/.config/nvim'):format(vim.env.HOME)
end,
This integration also works for emmylua_ls]],
    default = true,
  },
  jsonc_filetype = {
    type = 'boolean',
    description = [[Set filetype to jsonc when opening a file specified by `config_file_paths`,
make sure you have the json tree-sitter parser installed for highlighting]],
    default = true,
  },
  live_reload = {
    type = 'boolean',
    description = [[Enable live reloading of settings when config files change; for servers that support it,
this is done via the `workspace/didChangeConfiguration` notification, otherwise the
server is restarted]],
    default = false,
  },
}

---Extract the default values from the schema
---@return CodesettingsConfig
function M.defaults()
  local defaults = {}
  for key, prop in pairs(M.properties) do
    if prop.default ~= nil then
      defaults[key] = prop.default == vim.NIL and nil or vim.deepcopy(prop.default)
    end
  end
  return defaults
end

---Filter function types from a type definition for JSON schema
---@param types string|table
---@return string|table
local function filter_function_types(types)
  if type(types) == 'string' then
    return types
  end

  if M.is_function_type(types) then
    -- Single function type - return nil to filter it out
    return 'null'
  end

  -- Array of types
  local filtered = {}
  for _, t in ipairs(types) do
    if not M.is_function_type(t) then
      table.insert(filtered, t)
    end
  end

  if #filtered == 0 then
    return 'null'
  elseif #filtered == 1 then
    return filtered[1]
  else
    return filtered
  end
end

---Deep copy a property and filter function types
---@param prop CodesettingsSchemaValue
---@return table
local function copy_and_filter_prop(prop)
  local result = vim.deepcopy(prop)

  -- Filter function types from the type field
  if result.type then
    result.type = filter_function_types(result.type)
  end

  -- Recursively handle items
  if result.items and result.items.type then
    result.items.type = filter_function_types(result.items.type)
  end

  -- Recursively handle nested properties
  if result.properties then
    for key, child_prop in pairs(result.properties) do
      result.properties[key] = copy_and_filter_prop(child_prop)
    end
  end

  -- Remove custom fields that aren't part of JSON schema
  result.overridable = nil

  return result
end

---Generate a canonical JSON schema from the definition
---@return CodesettingsSchema
function M.jsonschema()
  local properties = {}
  for key, prop in pairs(M.properties) do
    properties[key] = copy_and_filter_prop(prop)
  end

  -- NB: here we want to return the canonical schema,
  -- which means we should look for a top-level `codesettings` property
  return Schema.from_table({
    ['$schema'] = 'http://json-schema.org/draft-07/schema#',
    type = 'object',
    properties = {
      codesettings = {
        type = 'object',
        description = 'Configuration for codesettings.nvim',
        properties = properties,
      },
    },
  }):flatten()
end

return M

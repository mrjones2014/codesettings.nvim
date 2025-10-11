local Settings = require('codesettings.settings')

local M = {}

---map lsp_name to schema file metadata
---@type table<string, CodesettingsLspSchema>
local _schema_metadata

---map of lsp_name to parsed schema
---@type table<string, CodesettingsSchema>
local _cache = {}

---@class CodesettingsSchema
---@field _schema CodesettingsSettings
local Schema = {}
Schema.__index = Schema

---Create a new Schema object from a Settings object
---@param schema CodesettingsSettings|nil
---@return CodesettingsSchema
function M.new(schema)
  return setmetatable({ _schema = schema or Settings.new() }, Schema)
end

---Load the schema for the given LSP name, or return an empty schema if none is found
---@param lsp_name string the name of the LSP, like 'rust-analyzer'
---@return CodesettingsSchema schema the loaded schema, or an empty schema if none is found
function M.load(lsp_name)
  if _schema_metadata == nil then
    _schema_metadata = require('codesettings.build.schemas').get_schemas()
  end

  if _cache[lsp_name] then
    return _cache[lsp_name]
  end

  local schema = _schema_metadata[lsp_name]
  if not schema then
    -- try replacing dashes with underscores and see if that helps, e.g. for rust
    schema = _schema_metadata[string.gsub(lsp_name, '%-', '_')]
    if not schema then
      return M.new()
    end
  end
  local settings = Settings.new():load(schema.settings_file)
  _cache[lsp_name] = M.new(settings)
  return _cache[lsp_name]
end

---Enumerate all property paths in the schema;
---they may be nested, e.g. `yaml.format.bracketSpacing`.
---@return string[] keys list of JSON keys
function Schema:properties()
  local properties = {}
  local function collect(prefix, node)
    if type(node) ~= 'table' then
      return
    end
    local props = node.properties
    if type(props) ~= 'table' then
      return
    end
    for name, def in pairs(props) do
      local full = prefix and (prefix .. '.' .. name) or name
      properties[full] = true
      if type(def) == 'table' and def.properties then
        collect(full, def)
      end
    end
  end
  collect(nil, self._schema:totable())
  return vim.tbl_keys(properties)
end

return M

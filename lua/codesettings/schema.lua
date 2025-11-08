local M = {}

---map lsp_name to schema file metadata
---@type table<string, CodesettingsLspSchema>
local _schema_metadata

---map of lsp_name to parsed schema
---@type table<string, CodesettingsSchema>
local _cache = {}

---@class CodesettingsSchema
---@field _schema table
local Schema = {}
Schema.__index = Schema

---Create a new Schema object from a raw table
---@param schema table|nil
---@return CodesettingsSchema
function M.new(schema)
  local schema_obj = type(schema) == 'table' and schema or {}
  return setmetatable({ _schema = schema_obj }, Schema)
end

---Create a new Schema object from a JSON-schema-like table
---@param schema_table table
---@return CodesettingsSchema
function M.from_table(schema_table)
  return M.new(schema_table)
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
  local settings_tbl = {}
  if schema.settings_file then
    local ok, data = pcall(vim.fn.readfile, schema.settings_file)
    if ok and type(data) == 'table' then
      local json_str = table.concat(data, '\n')
      local ok2, json = pcall(vim.fn.json_decode, json_str)
      if ok2 and type(json) == 'table' then
        settings_tbl = json
      end
    end
  end
  _cache[lsp_name] = M.new(settings_tbl)
  return _cache[lsp_name]
end

---Return the schema descriptor as a raw table
function Schema:totable()
  return self._schema
end

---Return a table of default settings according to the schema.
---@return table
function Schema:defaults_table()
  local function extract(node)
    if type(node) ~= 'table' then
      return nil
    end
    if node.type == 'object' and node.properties then
      local t = {}
      for k, v in pairs(node.properties) do
        t[k] = extract(v)
      end
      return t
    elseif node.type == 'array' and node.default ~= nil then
      return vim.deepcopy(node.default)
    elseif node.default ~= nil then
      return vim.deepcopy(node.default)
    else
      return nil
    end
  end
  return extract(self._schema) or {}
end

---Flatten the schema to a single-level table with dot-separated keys.
---@return CodesettingsSchema schema flattened schema
function Schema:flatten()
  local function flatten_properties(node, prefix, out)
    if type(node) ~= 'table' then
      return
    end
    local props = node.properties
    if type(props) ~= 'table' then
      return
    end
    for name, def in pairs(props) do
      local key = prefix and (prefix .. '.' .. name) or name
      if def.type == 'object' and def.properties then
        flatten_properties(def, key, out)
      else
        out[key] = vim.deepcopy(def)
      end
    end
  end
  local ret = vim.deepcopy(self._schema)
  local flat = {}
  flatten_properties(self._schema, nil, flat)
  -- check if properly formed JSON schema
  if ret.properties then
    ret.properties = flat
  else
    -- schema is just the properties
    ret = flat
  end
  return M.new(ret)
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
  collect(nil, self._schema)
  return vim.tbl_keys(properties)
end

return M

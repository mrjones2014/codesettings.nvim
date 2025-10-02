local Util = require('codesettings.util')

local M = {}

local all_schemas

local _cache = {}

---Get the list of JSON keys that are relevant for this LSP.
---The properties are VS Code style, so might be dotted-paths,
---like `yaml.format.bracketSpacing`, for example.
---@param lsp_name string
---@return string[] list of JSON keys
function M.get_properties_list(lsp_name)
  if all_schemas == nil then
    all_schemas = require('codesettings.build.schemas').get_schemas()
  end

  if _cache[lsp_name] then
    return _cache[lsp_name]
  end

  local schema = all_schemas[lsp_name]
  if not schema then
    -- try replacing dashes with underscores and see if that helps, e.g. for rust-analyzer
    schema = all_schemas[string.gsub(lsp_name, '%-', '_')]
    if not schema then
      return {}
    end
  end
  local ok, schema_file = pcall(Util.read_file, schema.settings_file)
  if not ok then
    return {}
  end
  local json = Util.json_decode(schema_file)
  _cache[lsp_name] = _cache[lsp_name] or {}
  for k, _ in pairs(json.properties or {}) do
    table.insert(_cache[lsp_name], k)
  end
  -- Collect all (possibly nested) property keys, deduplicated by using them as table keys
  local props_set = {}
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
      props_set[full] = true
      if type(def) == 'table' and def.properties then
        collect(full, def)
      end
    end
  end
  collect(nil, json)

  local keys = vim.tbl_keys(props_set)
  _cache[lsp_name] = keys
  return _cache[lsp_name]
end

return M

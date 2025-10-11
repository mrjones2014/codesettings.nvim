local Util = require('codesettings.util')

local M = {}

-- Expand dotted property keys in a JSON Schema into nested object properties,
-- while keeping the original dotted keys too. This lets jsonls offer completion
-- for both "dotted at root" and "nested object" forms simultaneously.
local function expand_schema(schema)
  if type(schema) ~= 'table' then
    return schema
  end

  local function ensure_obj(def)
    if type(def) ~= 'table' then
      def = {}
    end
    def.type = def.type or 'object'
    def.properties = def.properties or {}
    return def
  end

  local function insert_nested_prop(props, parts, leaf_def)
    -- Wrap props in a synthetic container to mutate in-place
    local container = { type = 'object', properties = props }
    local node = container
    for i = 1, #parts do
      local p = parts[i]
      if i == #parts then
        local existing = node.properties[p]
        if type(leaf_def) == 'table' then
          node.properties[p] = Util.merge(existing or {}, leaf_def)
        else
          node.properties[p] = leaf_def
        end
      else
        local next = node.properties[p]
        next = ensure_obj(next)
        node.properties[p] = next
        node = next
      end
    end
    return container.properties
  end

  local function recurse(def)
    if type(def) ~= 'table' then
      return def
    end
    local props = def.properties
    if type(props) ~= 'table' then
      return def
    end

    -- Copy and recurse children first
    local new_props = {}
    for k, v in pairs(props) do
      new_props[k] = recurse(v)
    end

    -- Add nested equivalents for dotted property keys
    for k, v in pairs(props) do
      if type(k) == 'string' and k:find('%.') then
        local parts = {}
        for part in k:gmatch('[^.]+') do
          parts[#parts + 1] = part
        end
        new_props = insert_nested_prop(new_props, parts, recurse(v))
      end
    end

    def.properties = new_props
    return def
  end

  return recurse(schema)
end

function M.setup()
  local schemas = require('codesettings.build.schemas').get_schemas()
  local json_schemas = {}
  for _, schema in pairs(schemas) do
    local file_ok, json = pcall(Util.read_file, schema.settings_file)
    if file_ok then
      local parse_ok, parsed_schema = pcall(require('codesettings.util').json_decode, json)
      if parse_ok then
        -- Make schema support both dotted and nested property forms
        parsed_schema = expand_schema(parsed_schema)

        local configs = Util.get_local_configs()
        table.insert(json_schemas, {
          fileMatch = configs,
          schema = parsed_schema,
        })
      end
    end
  end

  vim.lsp.config('jsonls', {
    settings = {
      json = {
        schemas = json_schemas,
        validate = { enable = true },
      },
    },
  })
end

return M

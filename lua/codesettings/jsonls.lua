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

  local function ensure_path(props, parts)
    -- Wrap props in a synthetic container to mutate in-place and return the final node
    local container = { type = 'object', properties = props }
    local node = container
    for i = 1, #parts do
      local p = parts[i]
      local next = node.properties[p]
      next = ensure_obj(next)
      node.properties[p] = next
      node = next
    end
    return container.properties, node
  end

  local function recurse(def)
    if type(def) ~= 'table' then
      return def
    end
    local props = def.properties
    if type(props) ~= 'table' then
      return def
    end

    -- Preserve original properties and add nested and mixed-form equivalents for dotted property keys
    local new_props = {}
    -- First, keep all original properties (recursing into them)
    for k, v in pairs(props) do
      new_props[k] = recurse(v)
    end

    -- Then, for each dotted property, generate all combinations
    for k, _ in pairs(props) do
      if type(k) == 'string' and k:find('%.') then
        local parts = {}
        for part in k:gmatch('[^.]+') do
          parts[#parts + 1] = part
        end

        -- Recurse into the leaf once (already processed above)
        local leaf = new_props[k]

        -- Fully nested form (e.g. "a.b.c" -> a -> b -> c)
        new_props = insert_nested_prop(new_props, parts, leaf)

        -- Mixed forms: for each split point, create an intermediate object
        -- and add a dotted suffix property at that level (e.g. a -> "b.c")
        for i = 1, #parts - 1 do
          local prefix = {}
          for j = 1, i do
            prefix[j] = parts[j]
          end
          local _, node = ensure_path(new_props, prefix)
          local suffix = table.concat(parts, '.', i + 1) -- no leading dot
          local existing = type(node.properties) == 'table' and node.properties[suffix] or nil
          if type(leaf) == 'table' then
            node.properties[suffix] = Util.merge(existing or {}, leaf)
          else
            node.properties[suffix] = leaf
          end
        end
      end
    end

    def.properties = new_props
    return def
  end

  return recurse(schema)
end

---Retrieve JSON schemas as tables.
---You can use this is the automatic configuration doesn't work.
---```lua
---vim.lsp.config('jsonls', {
---  settings = {
---    json = {
---      schemas = require('codesettings.jsonls').get_json_schemas(),
---      validate = { enable = true },
---    },
---  },
---})
---```
---@return table[] list of JSON schema objects suitable for jsonls config
function M.get_json_schemas()
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
  return json_schemas
end

function M.setup()
  vim.lsp.config('jsonls', {
    settings = {
      json = {
        schemas = M.get_json_schemas(),
        validate = { enable = true },
      },
    },
  })

  -- lazy loading; if jsonls is already active, restart it
  vim.defer_fn(function()
    if #vim.lsp.get_clients({ name = 'jsonls' }) > 0 then
      vim.lsp.enable('jsonls', false)
      vim.defer_fn(function()
        vim.lsp.enable('jsonls')
      end, 500)
    end
  end, 500)
end

return M

local Util = require('codesettings.util')

local M = {}

local _cache = nil

-- Expand dotted property keys in a JSON Schema into nested object properties,
-- while keeping the original dotted keys too. This lets jsonls offer completion
-- for both "dotted at root" and "nested object" forms simultaneously.
local function expand_schema(schema)
  if type(schema) ~= 'table' then
    return schema
  end

  local function ensure_obj(def)
    if type(def) == 'table' then
      def.type = def.type or 'object'
      def.properties = def.properties or {}
      return def
    end
    return { type = 'object', properties = {} }
  end

  local function insert_nested_prop(props, parts, leaf_def)
    local node_props = props

    for i = 1, #parts - 1 do
      local p = parts[i]
      local next = node_props[p]
      if type(next) ~= 'table' then
        next = { type = 'object', properties = {} }
        node_props[p] = next
      end
      next.type = next.type or 'object'
      next.properties = next.properties or {}
      node_props = next.properties
    end

    -- Handle leaf
    local final_key = parts[#parts]
    local existing = node_props[final_key]
    if type(leaf_def) == 'table' then
      node_props[final_key] = Util.merge(existing or {}, leaf_def)
    else
      node_props[final_key] = leaf_def
    end

    return props
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

    local new_props = {}
    local dotted_keys = {} -- Cache dotted keys and their parts

    -- Single pass: recurse and identify dotted keys
    for k, v in pairs(props) do
      new_props[k] = recurse(v)
      if type(k) == 'string' and k:find('%.', 1, true) then -- plain search is faster
        local parts = {}
        for part in k:gmatch('[^.]+') do
          parts[#parts + 1] = part
        end
        dotted_keys[#dotted_keys + 1] = { key = k, parts = parts }
      end
    end

    -- Process dotted keys
    for _, entry in ipairs(dotted_keys) do
      local k = entry.key
      local parts = entry.parts
      local leaf = new_props[k]

      -- Rest of your expansion logic using cached parts
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

    def.properties = new_props
    return def
  end

  return recurse(schema)
end

---Clear the cached JSON schemas.
---They will be reloaded on the next call to `get_json_schemas()`.
function M.clear_cache()
  _cache = nil
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
  if _cache then
    return _cache
  end

  local schemas = require('codesettings.build.schemas').get_schemas()
  local json_schemas = {}
  local configs = Util.get_local_configs()

  for _, schema in pairs(schemas) do
    local ok, json = pcall(Util.read_file, schema.settings_file)
    if not ok then
      Util.error('Failed to read JSON schema file: ' .. schema.settings_file)
    end
    if json then
      local parsed_schema = require('codesettings.util').json_decode(json)
      if parsed_schema then
        parsed_schema = expand_schema(parsed_schema)
        json_schemas[#json_schemas + 1] = {
          fileMatch = configs,
          schema = parsed_schema,
        }
      end
    end
  end

  _cache = json_schemas
  return _cache
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

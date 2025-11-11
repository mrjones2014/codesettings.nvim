local M = {}

---Expand dotted property keys in a JSON Schema into nested object properties,
---while preserving the original dotted keys as well.
---
---This allows JSON language servers to offer completion for both:
---  - "dotted at root" style: `"Lua.workspace.library"`
---  - "nested object" style: `{ Lua = { workspace = { library = ... }}}`
---
---Example:
---```lua
---local schema = {
---  type = "object",
---  properties = {
---    ["Lua.workspace.library"] = { type = "array", items = { type = "string" } }
---  }
---}
---
---local expanded = expand_schema(schema)
---```
---
---Now both `"Lua.workspace.library"` and `"Lua.workspace.library"` via nested paths
---are valid in completions.
---
---@param schema table A JSON schema object (decoded from JSON)
---@return table expanded_schema The schema with dotted keys expanded into nested form
function M.expand_schema(schema)
  if type(schema) ~= 'table' then
    return schema
  end

  -- Single deep copy at the start instead of multiple copies
  local result = vim.deepcopy(schema)

  ---Recursively merge two schema tables without overwriting existing fields.
  ---@param a table Base table (takes precedence where overlapping)
  ---@param b table Table to merge into `a`
  local function merge(a, b)
    if type(a) ~= 'table' then
      return type(b) == 'table' and b or a
    end
    -- Modify in place instead of deep copying
    for k, v in pairs(b) do
      if type(v) == 'table' and type(a[k]) == 'table' then
        merge(a[k], v)
      elseif a[k] == nil then
        a[k] = v
      end
    end
    return a
  end

  ---Insert a property definition into a nested object structure.
  ---If intermediate objects don't exist, they are created automatically.
  ---
  ---Example:
  ---```lua
  ---insert_nested(props, { "Lua", "workspace", "library" }, { type = "array" })
  ---```
  ---Results in:
  ---```lua
  ---props.Lua.properties.workspace.properties.library = { type = "array" }
  ---```
  ---@param props table The root `properties` table being modified
  ---@param parts string[] List of path parts split from a dotted key
  ---@param leaf table The schema definition to assign at the leaf
  local function insert_nested(props, parts, leaf)
    local node = props
    for i = 1, #parts - 1 do
      local key = parts[i]
      if not node[key] then
        node[key] = { type = 'object', properties = {} }
      elseif not node[key].properties then
        node[key].properties = {}
      end
      node = node[key].properties
    end
    local last = parts[#parts]
    node[last] = merge(node[last] or {}, leaf)
  end

  ---Recursively walk a schema definition, expanding any dotted keys in
  ---`properties` into nested object definitions.
  ---@param def table The schema definition node
  local function recurse(def)
    if type(def) ~= 'table' or type(def.properties) ~= 'table' then
      return
    end

    -- Recurse first on child properties (in place)
    for _, v in pairs(def.properties) do
      recurse(v)
    end

    -- Collect dotted keys (avoid table allocation for non-dotted schemas)
    local dotted
    for k, v in pairs(def.properties) do
      if type(k) == 'string' and k:find('.', 1, true) then
        if not dotted then
          dotted = {}
        end
        -- Cache the split result instead of recalculating
        table.insert(dotted, { parts = vim.split(k, '.', { plain = true }), leaf = v })
      end
    end

    if not dotted then
      return
    end

    -- Expand each dotted key into nested structures
    for _, entry in ipairs(dotted) do
      insert_nested(def.properties, entry.parts, entry.leaf)

      -- Mixed form expansion:
      -- Also define intermediate dotted forms for partial prefixes.
      -- Example: "a.b.c" → creates:
      --   a.b.c (original)
      --   a["b.c"]
      --   a.b["c"]
      local parts_len = #entry.parts
      for i = 1, parts_len - 1 do
        local node = def.properties
        for j = 1, i do
          local p = entry.parts[j]
          if not node[p] then
            node[p] = { type = 'object', properties = {} }
          elseif not node[p].properties then
            node[p].properties = {}
          end
          node = node[p].properties
        end
        -- Build suffix string without creating intermediate arrays
        local suffix_parts = {}
        for j = i + 1, parts_len do
          suffix_parts[#suffix_parts + 1] = entry.parts[j]
        end
        local suffix = table.concat(suffix_parts, '.')
        node[suffix] = merge(node[suffix] or {}, entry.leaf)
      end
    end
  end

  recurse(result)
  return result
end

return M

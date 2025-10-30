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

  ---Recursively merge two schema tables without overwriting existing fields.
  ---@param a table|nil Base table (takes precedence where overlapping)
  ---@param b table|nil Table to merge into `a`
  ---@return table merged A deep copy of `a` merged with `b`
  local function merge(a, b)
    a = a or {}
    b = b or {}
    if type(a) ~= 'table' then
      if type(b) == 'table' then
        return vim.deepcopy(b)
      else
        return a -- keep original a, don’t replace it with {}
      end
    end
    local res = vim.deepcopy(a)
    for k, v in pairs(b) do
      if type(v) == 'table' and type(res[k]) == 'table' then
        res[k] = merge(res[k], v)
      else
        res[k] = vim.deepcopy(v)
      end
    end
    return res
  end

  ---Insert a property definition into a nested object structure.
  ---If intermediate objects don’t exist, they are created automatically.
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
      node[key] = node[key] or { type = 'object', properties = {} }
      if node[key].properties == nil then
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
  ---@return table def The processed schema node with nested properties added
  local function recurse(def)
    if type(def) ~= 'table' then
      return def
    end
    if type(def.properties) ~= 'table' then
      return def
    end

    -- Recurse first on child properties
    local props = {}
    for k, v in pairs(def.properties) do
      props[k] = recurse(v)
    end

    -- Identify dotted keys like "Lua.workspace.library"
    local dotted = {}
    for k, v in pairs(props) do
      if type(k) == 'string' and k:find('.', 1, true) then
        local parts = vim.split(k, '.', { plain = true, trimempty = true })
        table.insert(dotted, { parts = parts, leaf = v })
      end
    end

    -- Expand each dotted key into nested structures
    for _, entry in ipairs(dotted) do
      insert_nested(props, entry.parts, entry.leaf)

      -- Mixed form expansion:
      -- Also define intermediate dotted forms for partial prefixes.
      -- Example: "a.b.c" → creates:
      --   a.b.c (original)
      --   a["b.c"]
      --   a.b["c"]
      for i = 1, #entry.parts - 1 do
        local prefix = vim.list_slice(entry.parts, 1, i)
        local suffix = table.concat(vim.list_slice(entry.parts, i + 1), '.')
        local node = props
        for _, p in ipairs(prefix) do
          node[p] = node[p] or { type = 'object', properties = {} }
          node = node[p].properties
        end
        node[suffix] = merge(node[suffix] or {}, entry.leaf)
      end
    end

    def.properties = props
    return def
  end

  return recurse(vim.deepcopy(schema))
end

return M

local Config = require('codesettings.config')
local Extensions = require('codesettings.extensions')
local TerminalObjects = require('codesettings.generated.terminal-objects')
local Util = require('codesettings.util')

local M = {}

---@class CodesettingsSettings
---@field private _settings table
---@field private file string
local Settings = {}
Settings.__index = Settings

---Create a new Settings object
---@param settings table? optional initial settings to populate
---@return CodesettingsSettings
function M.new(settings)
  local ret = setmetatable({ _settings = {} }, Settings)
  for k, v in pairs(settings or {}) do
    ret:set(k, v)
  end
  return ret
end

---Load all local settings files
---@param opts CodesettingsConfigOverrides? optional config overrides for this load
---@return CodesettingsSettings
function M.load_all(opts)
  opts = opts or {} --[[@as CodesettingsGetlocalConfigsOpts]]
  local settings = M.new()
  vim.iter(Util.get_local_configs(opts)):each(function(fname)
    settings:merge(M.new():load(fname, opts))
  end)
  return settings
end

local function is_map(t)
  return type(t) == 'table' and not vim.islist(t)
end

local function merge_set(parent, key, value)
  local existing = parent[key]
  if is_map(existing) and is_map(value) then
    parent[key] = Util.merge(existing, value)
  else
    parent[key] = value
  end
end

local function set_by_path(t, parts, value)
  local node = t
  for i = 1, #parts - 1 do
    local p = parts[i]
    if type(node[p]) ~= 'table' or vim.islist(node[p]) then
      node[p] = {}
    end
    node = node[p]
  end
  merge_set(node, parts[#parts], value)
end

---Expand a table with dotted keys into a nested table structure
---@param tbl table the table to expand
---@param current_path string? internal recursion use: current property path for tracking terminal objects
---@return table expanded the expanded table
function M.expand(tbl, current_path)
  if type(tbl) ~= 'table' then
    return tbl
  end

  -- Check if we're inside a terminal object (free-form dictionary)
  -- If so, do not expand dotted keys in this table
  local is_terminal = current_path and TerminalObjects[current_path]

  local out = {}
  for key, value in pairs(tbl) do
    local v = value

    -- Build the path for this key
    local key_path = current_path and (current_path .. '.' .. key) or key

    -- Recurse into map-like tables, but never into JSON Schema "properties" tables.
    if is_map(v) and key ~= 'properties' then
      v = M.expand(v, key_path)
    end

    -- Only expand dotted keys if:
    -- 1. The key contains a dot
    -- 2. We're NOT inside a terminal object
    if type(key) == 'string' and key:find('%.') and not is_terminal then
      local parts = {}
      for part in key:gmatch('[^.]+') do
        parts[#parts + 1] = part
      end
      set_by_path(out, parts, v)
    else
      merge_set(out, key, v)
    end
  end

  return out
end

---Split a dotted key into its parts
---@param key string the key to split, like 'rust-analyzer.cargo.loadOutDirsFromCheck'
---@return string[] parts the parts of the key
function M.path(key)
  if not key or key == '' then
    return {}
  end
  if type(key) ~= 'string' then
    return { key }
  end
  local parts = {}
  for part in string.gmatch(key, '[^.]+') do
    table.insert(parts, part)
  end
  return parts
end

---Clear all settings and reset to an empty Settings object
function Settings:clear()
  self._settings = {}
end

---Set a setting by key; if the key is dotted,
---it will internally create a well-formed nested table structure.
---@param key string the key to set, like 'rust-analyzer.cargo.loadOutDirsFromCheck'
---@param value table|string|boolean|number|nil the value to set at that key
function Settings:set(key, value)
  local parts = M.path(key)

  if #parts == 0 then
    if type(value) ~= 'table' then
      error('cannot set root settings to non-table value')
    end
    self._settings = value
    return
  end

  local node = self._settings
  for i = 1, #parts - 1, 1 do
    local part = parts[i]
    if type(node[part]) ~= 'table' then
      node[part] = {}
    end
    node = node[part]
  end
  node[parts[#parts]] = value
end

---@param key string|nil the key to get, like 'rust-analyzer.cargo.loadOutDirsFromCheck'; if `key` is nil, acts like `:totable()`
---@return table|string|boolean|number|nil setting the sub-value at that key
function Settings:get(key)
  ---@type table|string|boolean|number|nil
  local node = self._settings

  for _, part in ipairs(M.path(key or '')) do
    if type(node) ~= 'table' then
      node = nil
      break
    end
    node = node[part]
  end

  return node
end

---Like Settings:get(), but returns nil if the value is not a table,
---and it returns a `Settings` object wrapping that table if it is, instead
---of a raw table.
---@param key string the key to get, like 'rust-analyzer.cargo'
---@return CodesettingsSettings? settings the subtable wrapped in a Settings object, or nil if the
function Settings:get_subtable(key)
  local value = self:get(key)
  if type(value) ~= 'table' then
    return nil
  end
  return M.new(value)
end

---Return a new Settings object containing only the keys defined in the given schema.
---Does *not* modify this Settings object, returns a new instance.
---@param lsp_name_or_schema string|CodesettingsSchema the name of lsp for which to load the schema (e.g. 'rust-analyzer' or 'tsserver'), or a pre-loaded CodesettingsSchema object
---@return CodesettingsSettings settings a new Settings object containing only the keys defined in the schema
function Settings:schema(lsp_name_or_schema)
  -- NB: inline require to avoid circular dependency
  local Schema = require('codesettings.schema')
  local schema
  if type(lsp_name_or_schema) == 'string' then
    schema = Schema.load(lsp_name_or_schema)
  else
    schema = lsp_name_or_schema
    -- quick smoke test to make sure this is actually
    -- a CodesettingsSchema object
    if schema.properties == nil or type(schema.properties) ~= 'function' then
      error('expected CodesettingsSchema object')
    end
  end
  local settings = M.new()
  for _, property in ipairs(schema:properties()) do
    local subtable = self:get(property)
    if subtable ~= nil then
      settings:set(property, subtable)
    end
  end
  return settings
end

function Settings:totable()
  return self._settings
end

---@param file string the file to load settings from
---@param opts CodesettingsConfigOverrides? options for loading settings
---@return CodesettingsSettings
function Settings:load(file, opts)
  if not Util.exists(file) then
    Util.error('file does not exist: ' .. tostring(file))
    return self
  end
  local data = Util.read_file(file)
  local ok, json = pcall(Util.json_decode, data)
  if not ok then
    Util.error('failed to parse json settings from %s: %s', file, json)
    return self
  end
  json = Extensions.apply(M.expand(json), opts and opts.loader_extensions or Config.loader_extensions or {})
  self:merge(M.new(json))
  return self
end

---@param settings CodesettingsSettings settings to merge into this one
---@param key string|nil if given, merge only the subtable at this key
---@param config CodesettingsConfigOverrides? config options for merging
---@return CodesettingsSettings
function Settings:merge(settings, key, config)
  if not settings then
    return self
  end
  if settings.__index ~= Settings then
    settings = M.new(settings)
  end
  if key then
    local existing = self:get(key)
    if existing then
      -- Mutate the existing table in place to preserve references
      local value = Util.merge(existing, settings._settings, config)
      -- technically `Util.merge` will mutate the value,
      -- but set here to be explicit
      self:set(key, value)
    else
      -- No existing value, safe to set directly
      self:set(key, settings._settings)
    end
  else
    self._settings = Util.merge(self._settings, settings._settings, config)
  end
  return self
end

return M

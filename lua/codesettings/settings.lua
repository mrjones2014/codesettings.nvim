local Util = require('codesettings.util')
local Extensions = require('codesettings.extensions')

local M = {}

---@class CodesettingsSettings
---@field private _settings table
---@field private file string
local Settings = {}
Settings.__index = Settings

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

function M.expand(tbl)
  if type(tbl) ~= 'table' then
    return tbl
  end

  local out = {}
  for key, value in pairs(tbl) do
    local v = value
    -- Recurse into map-like tables, but never into JSON Schema "properties" tables.
    if is_map(v) and key ~= 'properties' then
      v = M.expand(v)
    end

    if type(key) == 'string' and key:find('%.') then
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

function Settings:clear()
  self._settings = {}
end

function Settings:set(key, value)
  local parts = M.path(key)

  if #parts == 0 then
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
---@return table|string|boolean|number|nil setting the subtable value at that key; if the value is a table, it returns a table, not a Settings object
function Settings:get(key)
  ---@type table|string|boolean|number|nil
  local node = self._settings

  for _, part in ipairs(M.path(key)) do
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
  self:clear()
  if Util.exists(file) then
    local data = Util.read_file(file)
    local ok, json = pcall(Util.json_decode, data)
    if ok then
      json = Extensions.apply(json, opts and opts.loader_extensions or {})
      for k, v in pairs(M.expand(json)) do
        self:set(k, v)
      end
    else
      Util.error('failed to load json settings from %s', file)
    end
  end
  return self
end

---@param settings CodesettingsSettings settings to merge into this one
---@param key string|nil if given, merge only the subtable at this key
---@param opts CodesettingsMergeOpts? options for merging tables
---@return CodesettingsSettings
function Settings:merge(settings, key, opts)
  if not settings then
    return self
  end
  if settings.__index ~= Settings then
    settings = M.new(settings)
  end
  if key then
    local value = Util.merge(Util.merge({}, self:get(key) or {}, opts), settings._settings, opts)
    self:set(key, value)
  else
    self._settings = Util.merge(self._settings, settings._settings, opts)
  end
  return self
end

M._cache = {}

function M.clear(fname)
  M._cache[fname] = nil
end

return M

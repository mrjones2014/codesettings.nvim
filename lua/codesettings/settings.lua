local Util = require('codesettings.util')

local M = {}

---@class Settings
---@field _settings table
---@field file string
local Settings = {}
Settings.__index = Settings

function M.new(settings)
  local ret = setmetatable({ _settings = {} }, Settings)
  for k, v in pairs(settings or {}) do
    ret:set(k, v)
  end
  return ret
end

function M.expand(tbl)
  if type(tbl) ~= 'table' then
    return tbl
  end
  local ret = M.new()
  for key, value in pairs(tbl) do
    ret:set(key, value)
  end
  return ret:get()
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

function Settings:get(key)
  ---@type table|nil
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

---Get a new Settings object with only the keys that are relevant for the given LSP.
function Settings:get_for_lsp_schema(lsp_name)
  local schema = require('codesettings.schema').get_properties_list(lsp_name)
  local ret = M.new()
  for _, key in ipairs(schema) do
    local value = self:get(key)
    if value ~= nil then
      ret:set(key, value)
    end
  end
  return ret
end

function Settings:to_tbl()
  return self._settings
end

function Settings:load(file)
  self:clear()
  if Util.exists(file) then
    local data = Util.read_file(file)
    local ok, json = pcall(Util.json_decode, data)
    if ok then
      for k, v in pairs(M.expand(json)) do
        self:set(k, v)
      end
    else
      vim.notify(('failed to load json settings from %s'):format(file), vim.log.levels.ERROR)
    end
  end
  return self
end

---@param settings Settings settings to merge into this one
---@param key string|nil if given, merge only the subtable at this key
---@return Settings
function Settings:merge(settings, key)
  if not settings then
    return M.new()
  end
  if settings.__index ~= Settings then
    settings = M.new(settings)
  end
  if key then
    local value = Util.merge({}, self:get(key) or {}, settings._settings)
    self:set(key, value)
  else
    self._settings = Util.merge(self._settings, settings._settings)
  end
  return self
end

M._cache = {}

function M.clear(fname)
  M._cache[fname] = nil
end

function M.get(fname)
  fname = Util.fqn(fname)
  if not M._cache[fname] and Util.exists(fname) then
    M._cache[fname] = M.new():load(fname)
  end
  return M._cache[fname]
end

return M

local M = {}

---@type table<string, table>
local _cache = {}
---@type table<string, boolean>
local _not_found = {}

---Read and JSON-decode a file, returning the decoded table or nil on any error.
---@param path string
---@return table|nil
local function read_json_file(path)
  local ok, data = pcall(vim.fn.readfile, path)
  if not ok or type(data) ~= 'table' then
    return nil
  end
  local ok2, tbl = pcall(vim.fn.json_decode, table.concat(data, '\n'))
  return ok2 and type(tbl) == 'table' and tbl or nil
end

---Recursively apply NLS substitution to a value.
---Strings matching exactly `%key%` are replaced with `nls_table[key]` if present.
---@param value any
---@param nls_table table<string, string>
---@return any
function M.apply(value, nls_table)
  if type(value) == 'string' then
    local key = value:match('^%%(.+)%%$')
    if key and nls_table[key] then
      local v = nls_table[key]
      return type(v) == 'table' and v.message or v
    end
    return value
  end

  if type(value) == 'table' then
    local result = {}
    for k, v in pairs(value) do
      result[k] = M.apply(v, nls_table)
    end
    return result
  end

  return value
end

---Load bundled English NLS for an LSP server from `after/codesettings-nls/{lsp_name}.json`.
---Results are cached after the first load.
---@param lsp_name string
---@return table<string, string>|nil
function M.load_bundled(lsp_name)
  if _cache[lsp_name] then
    return _cache[lsp_name]
  end
  if _not_found[lsp_name] then
    return nil
  end

  local Util = require('codesettings.util')
  local nls_file = Util.runtime_file('after/codesettings-nls/' .. lsp_name .. '.nls.json')
  if not nls_file then
    _not_found[lsp_name] = true
    return nil
  end

  local tbl = read_json_file(nls_file)
  if not tbl then
    _not_found[lsp_name] = true
    return nil
  end

  _cache[lsp_name] = tbl
  return tbl
end

---Attempt to resolve NLS data for the given LSP.
---Uses `Config.nls` setting to find data.
---@param lsp_name string
---@return table<string, string>|nil
function M.resolve(lsp_name)
  local nls_config = require('codesettings.config').nls

  if nls_config == false then
    return nil
  end

  if nls_config == nil or nls_config == true then
    return M.load_bundled(lsp_name)
  end

  if type(nls_config) == 'table' then
    return nls_config
  end

  if type(nls_config) == 'string' then
    return read_json_file(nls_config .. '/' .. lsp_name .. '.nls.json')
  end

  if type(nls_config) == 'function' then
    return nls_config(lsp_name)
  end

  return nil
end

return M

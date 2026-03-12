---@class CodesettingsBuildUtil
local M = {}

---@type string
local _root_dir

---Get path relative to git repo root
---@param str string? relative path
---@return string absolute path
function M.path(str)
  if not _root_dir then
    _root_dir = vim.fn.system('git rev-parse --show-toplevel'):gsub('\n', '')
    -- git based detection doesn't work in flake checks (e.g. in CI)
    if (_root_dir or '') == '' or vim.v.shell_error ~= 0 then
      _root_dir = assert(vim.uv.cwd())
    end
  end
  return _root_dir .. '/' .. (str or '')
end

---Get schema file path for an LSP server
---@param lsp_name string
---@return string
function M.schema_path(lsp_name)
  return M.path('after/codesettings-schemas/' .. lsp_name .. '.json')
end

---@class CodesettingsBuildLspSchema
---@field name string the name of the LSP server
---@field package_url string url of the package.json of the LSP server
---@field settings_file string file of the settings json schema of the LSP server

---@return table<string, CodesettingsBuildLspSchema>
function M.get_schemas()
  local index = require('codesettings.build.schemas').index
  ---@type table<string, CodesettingsBuildLspSchema>
  local ret = {}
  for server, package_json in pairs(index) do
    ret[server] = {
      name = server,
      package_url = package_json,
      settings_file = M.schema_path(server),
    }
  end
  return ret
end

---Write all contents to file
---@param file string file path to write to
---@param data string data to write
function M.write_file(file, data)
  local fd = io.open(file, 'w+')
  if not fd then
    error(('Could not open file %s for writing'):format(file))
  end
  fd:write(data)
  fd:close()
end

---Delete the given file
---@param f string file path to delete
function M.delete_file(f)
  vim.uv.fs_unlink(f)
end

---Fetch URL content
---@param url string
---@return string
function M.fetch(url)
  local fd = io.popen(string.format('curl -s -k %q', url))
  if not fd then
    error(('Could not download %s'):format(url))
  end
  local ret = fd:read('*a')
  fd:close()
  return ret
end

---Format JSON using jq;
---requires `jq` to be installed and available in PATH
---@param obj table
---@return string formatted json string
function M.json_format(obj)
  local tmp = os.tmpname()
  M.write_file(tmp, vim.json.encode(obj))
  local fd = io.popen('jq -S < ' .. tmp)
  if not fd then
    error('Could not format json')
  end
  local ret = fd:read('*a')
  if ret == '' then
    error('Could not format json')
  end
  fd:close()
  return ret
end

return M

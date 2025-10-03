local Config = require('codesettings.config')

local M = {}

function M.read_file(file)
  local fd = io.open(file, 'r')
  if not fd then
    error(('Could not open file %s for reading'):format(file))
  end
  local data = fd:read('*a')
  fd:close()
  return data
end

function M.write_file(file, data)
  local fd = io.open(file, 'w+')
  if not fd then
    error(('Could not open file %s for writing'):format(file))
  end
  fd:write(data)
  fd:close()
end

function M.fqn(fname)
  fname = vim.fn.fnamemodify(fname, ':p')
  return vim.uv.fs_realpath(fname) or fname
end

---Get root directory based on root markers
---@param fname string?
---@return string?
function M.get_root(fname)
  local file_paths = Config.config_file_paths
  local root_patterns = {}
  for _, pattern in ipairs(file_paths) do
    local base = vim.fn.fnamemodify(pattern, ':h')
    table.insert(root_patterns, base)
  end
  table.insert(root_patterns, '.git')
  return vim.fs.root(fname or vim.env.PWD, root_patterns)
end

---Get all the local config files found in the current project based on configured paths;
---returns fully qualified filepaths of files that exist.
---@return string[] configs list of fully qualified filenames
function M.get_local_configs()
  local root = M.get_root()
  if not root then
    return {}
  end

  return vim
    .iter(Config.config_file_paths)
    :map(function(path)
      return M.fqn(root .. '/' .. path)
    end)
    :filter(function(path)
      return M.exists(path)
    end)
    :totable()
end

function M.merge(...)
  local function can_merge(v)
    return type(v) == 'table' and (vim.tbl_isempty(v) or not vim.islist(v))
  end

  local values = { ... }
  local ret = values[1]
  for i = 2, #values, 1 do
    local value = values[i]
    if can_merge(ret) and can_merge(value) then
      for k, v in pairs(value) do
        ret[k] = M.merge(ret[k], v)
      end
    else
      ret = value
    end
  end
  return ret
end

---@return boolean
function M.exists(fname)
  local stat = vim.uv.fs_stat(fname)
  -- not not to coerce to boolean, or false if nil
  return (not not (stat and stat.type)) or false
end

function M.json_decode(json)
  json = vim.trim(json)
  if json == '' then
    json = '{}'
  end
  return require('codesettings.json.jsonc').decode_jsonc(json)
end

function M.path(str)
  local f = debug.getinfo(1, 'S').source:sub(2)
  return M.fqn(vim.fn.fnamemodify(f, ':h:h:h') .. '/' .. (str or ''))
end

function M.fetch(url)
  local fd = io.popen(string.format('curl -s -k %q', url))
  if not fd then
    error(('Could not download %s'):format(url))
  end
  local ret = fd:read('*a')
  fd:close()
  return ret
end

---@param t table
---@param ret? table
function M.flatten(t, ret)
  ret = ret or {}
  for _, v in pairs(t) do
    if type(v) == 'table' then
      M.flatten(v, ret)
    else
      ret[#ret + 1] = v
    end
  end
  return ret
end

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

local Config = require('codesettings.config')

---@class CodesettingsUtil
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
  local root_patterns = vim
    .iter(file_paths)
    :map(function(path)
      return vim.fn.fnamemodify(path, ':t')
    end)
    :totable()
  table.insert(root_patterns, '.git')
  return vim.fs.root(fname or vim.env.PWD or vim.uv.cwd(), root_patterns)
end

---@class GetlocalConfigsOpts
---@field only_exists boolean? if true, only return files that exist; true by default
---@field reload boolean? if true, invalidate the cached file list

local _config_files = {}

---Get all the local config files found in the current project based on configured paths;
---returns fully qualified filepaths of files that exist.
---@param opts GetlocalConfigsOpts? options for getting local configs
---@return string[] configs list of fully qualified filenames
function M.get_local_configs(opts)
  opts = opts or {}

  if opts.reload then
    _config_files = {}
  end

  if not vim.tbl_isempty(_config_files) then
    return _config_files
  end

  local root = M.get_root()
  if not root then
    return {}
  end

  _config_files = vim
    .iter(Config.config_file_paths)
    :map(function(path)
      return M.fqn(root .. '/' .. path)
    end)
    :filter(function(path)
      if opts.only_exists == false then
        return true
      end
      return M.exists(path)
    end)
    :totable()
  return _config_files
end

---@class CodesettingsMergeOpts
---@field list_behavior? 'replace'|'append'|'prepend' how to merge lists; defaults to 'append'

--- Deep merge two values, with `b` taking precedence over `a`.
--- Tables are merged recursively; lists are merged based on `opts.list_behavior`.
---@generic T
---@param a T first value
---@param b T second value
---@param opts CodesettingsMergeOpts? options for merging
---@return T merged value
function M.merge(a, b, opts)
  opts = vim.tbl_deep_extend('force', Config.default_merge_opts, opts or {})
  local function can_merge(v)
    if type(v) ~= 'table' then
      return false
    end
    if vim.islist(v) then
      return false
    end
    return true
  end

  local values = { a, b }
  local ret = values[1]
  for i = 2, #values, 1 do
    local value = values[i]
    if can_merge(ret) and can_merge(value) then
      for k, v in pairs(value) do
        ret[k] = M.merge(ret[k], v, opts)
      end
    else
      if (ret == nil or vim.islist(ret)) and (value == nil or vim.islist(value)) then
        if opts.list_behavior == 'append' then
          local out = {}
          vim.list_extend(out, ret or {})
          vim.list_extend(out, value or {})
          ret = out
        elseif opts.list_behavior == 'prepend' then
          local out = {}
          vim.list_extend(out, value or {})
          vim.list_extend(out, ret or {})
          ret = out
        else -- replace
          ret = value
        end
      else
        ret = value
      end
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

local Config = require('codesettings.config')

---@class CodesettingsUtil
local M = {}

---Read entire contents of a file
---@param file string filepath
---@return string contents of the file
function M.read_file(file)
  local fd = io.open(file, 'r')
  if not fd then
    error(('Could not open file %s for reading'):format(file))
  end
  local data = fd:read('*a')
  fd:close()
  return data
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

---Get fully qualified normalized path
---@param fname string file path to normalize
---@return string
function M.fqn(fname)
  fname = vim.fn.fnamemodify(fname, ':p')
  return vim.uv.fs_realpath(fname) or fname
end

---strip off trailing slash, if any
local function normalize_root(path)
  if vim.endswith(path, '/') and path ~= '/' then
    return path:sub(1, -2)
  end
  return path
end

---Get root directory based on root markers
---@param opts CodesettingsConfigOverrides? optional config overrides for this load
---@return string?
function M.get_root(opts)
  opts = opts or {}
  local user_root = opts.root_dir or Config.root_dir
  if type(user_root) == 'string' then
    return normalize_root(user_root)
  elseif type(user_root) == 'function' then
    return normalize_root(user_root())
  end

  local file_paths = opts.config_file_paths or Config.config_file_paths
  local root_patterns = vim
    .iter(file_paths)
    :map(function(path)
      return vim.fn.fnamemodify(path, ':t')
    end)
    :totable()
  table.insert(root_patterns, '.git')
  table.insert(root_patterns, '.jj')
  return vim.fs.root(0, root_patterns)
end

---@class (partial) CodesettingsGetlocalConfigsOpts: CodesettingsConfigOverrides
---@field only_exists boolean? if true, only return files that exist; true by default

---Get all the local config files found in the current project based on configured paths;
---returns fully qualified filepaths of files that exist.
---@param opts CodesettingsGetlocalConfigsOpts? options for getting local configs
---@return string[] configs list of fully qualified filenames
function M.get_local_configs(opts)
  opts = opts or {}

  local root = M.get_root(opts)
  if not root then
    return {}
  end

  local file_paths = opts.config_file_paths or Config.config_file_paths
  return vim
    .iter(file_paths)
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
end

--- Deep merge two values, with `b` taking precedence over `a`.
--- Tables are merged recursively; lists are merged based on config.
---@generic T
---@param a T first value
---@param b T second value
---@param config CodesettingsConfigOverrides? config options (uses Config.merge_lists if not provided)
---@return T merged value
function M.merge(a, b, config)
  config = config or {}
  local merge_lists = config.merge_lists or 'append'
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
        ret[k] = M.merge(ret[k], v, config)
      end
    else
      if (ret == nil or vim.islist(ret)) and (value == nil or vim.islist(value)) then
        if merge_lists == 'append' then
          local out = {}
          vim.list_extend(out, ret or {})
          vim.list_extend(out, value or {})
          ret = out
        elseif merge_lists == 'prepend' then
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

---Check if a file exists
---@return boolean
function M.exists(fname)
  local stat = vim.uv.fs_stat(fname)
  -- not not to coerce to boolean, or false if nil
  return (not not (stat and stat.type)) or false
end

local function parse_composite_key(key)
  if type(key) ~= 'string' or key:sub(1, 1) ~= '[' then
    return nil
  end
  local segments = {}
  local idx = 1
  while idx <= #key do
    local start_pos, end_pos, segment = key:find('%[([^%]]+)%]', idx)
    if not start_pos or start_pos ~= idx then
      return nil
    end
    segment = vim.trim(segment)
    if segment == '' then
      return nil
    end
    segments[#segments + 1] = segment
    idx = end_pos + 1
  end
  if idx <= #key or #segments == 0 then
    return nil
  end
  return segments
end

---Expand vs code style bracketed keys
---e.g.
---```json
---{
---  "[json][jsonc][javascript][typescript][typescriptreact]": {
---    "editor.defaultFormatter": "esbenp.prettier-vscode"
---  }
---}
---```
---is equivalent to
---```json
---{
---  "json": {
---    "editor.defaultFormatter": "esbenp.prettier-vscode"
---  },
---  "jsonc": {
---    "editor.defaultFormatter": "esbenp.prettier-vscode"
---  },
---  "javascript": {
---    "editor.defaultFormatter": "esbenp.prettier-vscode"
---  },
---  "typescript": {
---    "editor.defaultFormatter": "esbenp.prettier-vscode"
---  },
---  "typescriptreact": {
---    "editor.defaultFormatter": "esbenp.prettier-vscode"
---  }
---}
---```
---@param node table
local function normalize_json_settings(node)
  if type(node) ~= 'table' then
    return
  end
  if vim.islist(node) then
    for _, item in ipairs(node) do
      normalize_json_settings(item)
    end
    return
  end

  local composites = {}
  for key, value in pairs(node) do
    normalize_json_settings(value)
    local segments = parse_composite_key(key)
    if segments then
      composites[#composites + 1] = { key = key, segments = segments, value = value }
    end
  end

  for _, composite in ipairs(composites) do
    node[composite.key] = nil
    for _, target_key in ipairs(composite.segments) do
      local new_value = vim.deepcopy(composite.value)
      local existing = node[target_key]
      if existing ~= nil then
        if type(existing) == 'table' and type(new_value) == 'table' then
          node[target_key] = M.merge(existing, new_value)
        else
          node[target_key] = new_value
        end
      else
        node[target_key] = new_value
      end
      normalize_json_settings(node[target_key])
    end
  end
end

---Decode JSON or JSONC string
---@param json string json string
---@return table
function M.json_decode(json)
  json = vim.trim(json)
  if json == '' then
    json = '{}'
  end
  local data = require('codesettings.json.jsonc').decode_jsonc(json)
  normalize_json_settings(data)
  return data
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

local msg_prefix = '[codesettings] '

---@param msg string
---@param ... any
function M.info(msg, ...)
  vim.notify(('%s%s'):format(msg_prefix, msg:format(...)), vim.log.levels.INFO)
end

---@param msg string
---@param ... any
function M.warn(msg, ...)
  vim.notify(('%s%s'):format(msg_prefix, msg:format(...)), vim.log.levels.WARN)
end

---@param msg string
---@param ... any
function M.error(msg, ...)
  vim.notify(('%s%s'):format(msg_prefix, msg:format(...)), vim.log.levels.ERROR)
end

---Restart LSP client by name, if active
---@param name string
function M.restart_lsp(name)
  vim.defer_fn(function()
    if #vim.lsp.get_clients({ name = name }) > 0 then
      vim.lsp.enable(name, false)
      vim.defer_fn(function()
        vim.lsp.enable(name)
      end, 500)
    end
  end, 500)
end

return M

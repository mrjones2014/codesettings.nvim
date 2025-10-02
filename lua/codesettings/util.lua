local M = {}

function M.read_file(file)
  local fd = io.open(file, "r")
  if not fd then
    error(("Could not open file %s for reading"):format(file))
  end
  local data = fd:read("*a")
  fd:close()
  return data
end

function M.fqn(fname)
  fname = vim.fn.fnamemodify(fname, ':p')
  return vim.uv.fs_realpath(fname) or fname
end

---Get root directory based on root markers
---@param fname string?
---@return string?
function M.get_root(fname)
  return vim.fs.root(fname or vim.env.PWD, { '.vscode', '.git' })
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

function M.exists(fname)
  local stat = vim.uv.fs_stat(fname)
  return (stat and stat.type) or false
end

function M.json_decode(json)
  json = vim.trim(json)
  if json == '' then
    json = '{}'
  end
  return require('codesettings.json.jsonc').decode_jsonc(json)
end

return M

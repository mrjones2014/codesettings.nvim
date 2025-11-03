---@class CodesettingsLoaderExtensionContext
---@field parent table? The immediate parent table/list of this node
---@field path string[] Full path from the root to this node
---@field key string|integer The key/index of this node in the parent
---@field list_idx integer? Index if parent is a list

---@class CodesettingsLoaderExtension
---Optional visitor for non-leaf nodes (tables or lists). Return a control code and optional replacement value.
---Note that the replacement value is only used if the control code is `REPLACE`.
---@field object (fun(node:any, ctx:CodesettingsLoaderExtensionContext): CodesettingsLoaderExtensionControl, any?)?
---Optional visitor for leaf nodes. Return a control code and optional replacement value.
---Note that the replacement value is only used if the control code is `REPLACE`.
---@field leaf (fun(value:any, ctx:CodesettingsLoaderExtensionContext): CodesettingsLoaderExtensionControl, any?)?

---Call a function or method safely; this is to support both function and method-style calls.
---@generic C, T
---@param fn fun(...): C, T Function or method
---@param self table? Optional self
---@param ... any Arguments
---@return C, T
local function safe_call(fn, self, ...)
  if type(fn) ~= 'function' then
    error('Attempted to call a non-function')
  end
  if self ~= nil and fn == rawget(self, fn) then
    -- Actually, we can't reliably detect method from function
    return fn(self, ...)
  else
    return fn(...)
  end
end

---@param ext any
---@return boolean
local function is_extension(ext)
  if type(ext) ~= 'table' then
    return false
  end
  if ext.object ~= nil and type(ext.object) ~= 'function' then
    return false
  end
  if ext.leaf ~= nil and type(ext.leaf) ~= 'function' then
    return false
  end
  -- valid extension must have at least one of object or leaf
  if ext.object == nil and ext.leaf == nil then
    return false
  end
  return true
end

---@param ext string|CodesettingsLoaderExtension
---@return CodesettingsLoaderExtension
local function to_extension(ext)
  if type(ext) == 'string' then
    local ok, extension = pcall(require, ext)
    if not ok then
      error(extension)
    end
    if not is_extension(extension) then
      error(string.format('Module %q is not a valid CodesettingsLoaderExtension', ext))
    end
    return extension
  elseif type(ext) == 'table' and is_extension(ext) then
    return ext
  else
    error('Invalid extension type; expected string or CodesettingsLoaderExtension table')
  end
end

local M = {}

---@enum CodesettingsLoaderExtensionControl
M.Control = {
  ---Continue recursion (for objects) or leave leaf unchanged
  CONTINUE = 'continue',
  ---Skip recursion (objects only)
  SKIP = 'skip',
  ---Replace this node/leaf with provided replacement value (can be nil)
  REPLACE = 'replace',
}

---@param extensions (string|CodesettingsLoaderExtension)[]
---@return CodesettingsLoaderExtension[]
function M.resolve_extensions(extensions)
  local exts = {}
  vim.iter(extensions):each(function(ext)
    table.insert(exts, to_extension(ext))
  end)
  return exts
end

---@param root any
---@param extensions (string|CodesettingsLoaderExtension)[]
---@return any
function M.apply(root, extensions)
  local exts = M.resolve_extensions(extensions)
  return M.traverse(root, {}, nil, nil, nil, exts)
end

---@param node any
---@param path string[]
---@param parent table?
---@param key string|integer?
---@param list_idx integer?
---@param extensions CodesettingsLoaderExtension[]
---@return any
function M.traverse(node, path, parent, key, list_idx, extensions)
  path = path or {}

  local skip_node = false
  local replace_node, replacement

  -- Run all extensions once per node
  vim.iter(extensions):each(function(ext)
    local ctx = { parent = parent, path = path, key = key, list_idx = list_idx }

    if type(node) == 'table' and ext.object then
      local c, r = safe_call(ext.object, ext, node, ctx)
      if c == M.Control.SKIP then
        skip_node = true
      elseif c == M.Control.REPLACE then
        replace_node = true
        replacement = r
      end
    elseif type(node) ~= 'table' and ext.leaf then
      local c, r = safe_call(ext.leaf, ext, node, ctx)
      if c == M.Control.REPLACE then
        replace_node = true
        replacement = r
      end
      -- CONTINUE or SKIP has no effect on leaves; node remains as-is
    end
  end)

  if replace_node then
    return replacement
  elseif skip_node then
    return node
  end

  -- Recurse into children if this is a table/list
  if type(node) == 'table' then
    if vim.islist(node) then
      vim.iter(ipairs(node)):each(function(i, v)
        node[i] = M.traverse(v, { unpack(path), i }, node, i, i, extensions)
      end)
    else
      vim.iter(pairs(node)):each(function(k, v)
        node[k] = M.traverse(v, { unpack(path), k }, node, k, nil, extensions)
      end)
    end
  end

  return node
end

return M

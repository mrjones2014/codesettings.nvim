local Util = require('codesettings.util')

local M = {}

M.class_name = ''
M.lines = {}

function M.table_key(str)
  if str:match('[^%a_]') then
    return '[' .. vim.inspect(str) .. ']'
  end
  return str
end

function M.comment(desc, prefix)
  if desc then
    prefix = (prefix or '') .. '-- '
    return prefix .. desc:gsub('\n', '\n' .. prefix)
  end
end

function M.add_desc(lines, prop, prefix)
  local ret = prop.markdownDescription or prop.description
  if type(ret) == 'table' and ret.message then
    ret = ret.message
  end
  if prop.default then
    if prop.default == vim.NIL then
      prop.default = nil
    end
    if type(prop.default) == 'table' and vim.tbl_isempty(prop.default) then
      prop.default = {}
    end
    ret = (ret and (ret .. '\n\n') or '') .. '```lua\ndefault = ' .. vim.inspect(prop.default) .. '\n```'
  end
  if ret then
    table.insert(lines, M.comment(ret, prefix))
  end
end

function M.fix_props(node)
  return node.leaf and node
    or {
      type = 'object',
      properties = vim.tbl_map(function(child)
        return M.fix_props(child)
      end, node),
    }
end

function M.get_class(name)
  if name == M.class_name then
    return name
  end
  local ret = { M.class_name }
  for word in string.gmatch(name, '([^_]+)') do
    table.insert(ret, word:sub(1, 1):upper() .. word:sub(2))
  end
  return table.concat(ret, '.')
end

function M.get_type(prop)
  if prop.enum then
    return table.concat(
      vim.tbl_map(function(e)
        return vim.inspect(e)
      end, prop.enum),
      ' | '
    )
  end
  local types = type(prop.type) == 'table' and prop.type or { prop.type }
  if vim.tbl_isempty(types) and type(prop.anyOf) == 'table' then
    return table.concat(
      vim.tbl_map(function(p)
        return M.get_type(p)
      end, prop.anyOf),
      '|'
    )
  end
  types = vim.tbl_map(function(t)
    if t == 'null' then
      return
    end
    if t == 'array' then
      if prop.items and prop.items.type then
        if type(prop.items.type) == 'table' then
          prop.items.type = 'any'
        end
        return prop.items.type .. '[]'
      end
      return 'any[]'
    end
    if t == 'object' then
      return 'table'
    end
    return t
  end, types)
  if vim.tbl_isempty(types) then
    types = { 'any' }
  end
  return table.concat(Util.flatten(types), '|')
end

function M.process_object(name, prop)
  local lines = {}
  M.add_desc(lines, prop)
  table.insert(lines, '---@class ' .. M.get_class(name))
  if prop.properties then
    local props = vim.tbl_keys(prop.properties)
    table.sort(props)
    for _, field in ipairs(props) do
      local child = prop.properties[field]
      M.add_desc(lines, child)

      if child.type == 'object' and child.properties then
        table.insert(lines, '---@field ' .. field .. ' ' .. M.get_class(field) .. '?') -- ? since all fields are optional
        M.process_object(field, child)
      else
        table.insert(lines, '---@field ' .. field .. ' ' .. M.get_type(child) .. '?') -- ? since all fields are optional
      end
    end
  end
  table.insert(M.lines, '')
  vim.list_extend(M.lines, lines)
end

function M.build_annotations(name)
  local file = Util.path('schemas/' .. name .. '.json')
  local json = Util.json_decode(Util.read_file(file)) or {}
  M.class_name = 'lsp.' .. name

  local schema = require('codesettings.settings').new()
  for key, prop in pairs(json.properties) do
    prop.leaf = true
    schema:set(key, prop)
  end

  M.process_object(M.class_name, M.fix_props(schema:get()))
end

---THIS WILL CALL `os.exit(1)` IF A SCHEMA CANNOT BE FETCHED.
---This is only meant to be called from a build script!
function M.build()
  print('Generating Lua type annotations based on all schemas...')
  M.lines = { '-- vim: ft=bigfile', '-- stylua: ignore', '---@meta', '' }

  local index = vim.tbl_keys(require('codesettings.build.schemas').get_schemas())
  table.sort(index)

  for _, name in ipairs(index) do
    local ok, err = pcall(M.build_annotations, name)
    if not ok then
      print('error building ' .. name .. ': ' .. err)
      os.exit(1)
    end
  end

  local lines = vim.tbl_filter(function(v)
    return v ~= nil
  end, M.lines)

  Util.write_file('lua/codesettings/generated/annotations.lua', table.concat(lines, '\n'))
end

return M

local Util = require('codesettings.util')

local relpath = 'lua/codesettings/generated/codesettings-config-schema.lua'

local Build = {}

Build.lines = {}

---Add a comment block from a description
---@param desc string|nil
---@param prefix string|nil
local function add_comment(desc, prefix)
  if desc then
    prefix = (prefix or '') .. '---'
    table.insert(Build.lines, prefix .. desc:gsub('\n', '\n' .. prefix))
  end
end

---Check if a type definition is a function type table
---@param t any
---@return boolean
local function is_function_type(t)
  return type(t) == 'table' and t.args ~= nil and t.ret ~= nil
end

---Convert a function type table to Lua type annotation
---@param func_type CodesettingsConfigFunctionType
---@return string
local function function_type_to_lua(func_type)
  local args = table.concat(func_type.args, ', ')
  if args == '' then
    return 'fun():' .. func_type.ret
  end
  return 'fun(' .. args .. '):' .. func_type.ret
end

---Get Lua type from schema type
---@param prop CodesettingsSchemaValue
---@return string
local function get_lua_type(prop)
  local types = type(prop.type) == 'table' and prop.type or { prop.type }

  -- Handle if types is actually a single type table (not an array of types)
  if is_function_type(types) then
    types = { types }
  end

  local lua_types = {}

  for _, t in
    ipairs(types --[[@as table<CodesettingsSchemaType>]])
  do
    if is_function_type(t) then
      table.insert(lua_types, function_type_to_lua(t))
    elseif t == 'null' then
      table.insert(lua_types, 'nil')
    elseif t == 'array' then
      if prop.items and prop.items.type then
        local item_types = type(prop.items.type) == 'table' and prop.items.type or { prop.items.type }

        -- Handle function types in array items
        local item_type_strs = {}
        for _, item_t in
          ipairs(item_types --[[@as table<CodesettingsSchemaType>]])
        do
          if is_function_type(item_t) then
            table.insert(item_type_strs, function_type_to_lua(item_t))
          elseif item_t == 'object' then
            table.insert(item_type_strs, 'table')
          else
            table.insert(item_type_strs, item_t)
          end
        end

        local item_type = #item_type_strs > 1 and ('(' .. table.concat(item_type_strs, '|') .. ')')
          or item_type_strs[1]
          or 'any'
        table.insert(lua_types, item_type .. '[]')
      else
        table.insert(lua_types, 'any[]')
      end
    elseif t == 'object' then
      table.insert(lua_types, 'table')
    else
      -- Plain string type or class name
      table.insert(lua_types, t)
    end
  end

  if vim.tbl_isempty(lua_types) then
    lua_types = { 'any' }
  end

  return table.concat(lua_types, '|')
end

---Add description with default value
---@param prop CodesettingsSchemaValue
local function add_desc_with_default(prop)
  local desc = prop.description

  if prop.default then
    local default_val = prop.default
    if default_val == vim.NIL then
      default_val = nil
    end
    if type(default_val) == 'table' and vim.tbl_isempty(default_val) then
      default_val = {}
    end
    desc = (desc and (desc .. '\n\n') or '') .. '```lua\ndefault = ' .. vim.inspect(default_val) .. '\n```'
  end

  add_comment(desc)
end

---Convert a string from `snake_case` to `PascalCase`
local function to_pascal_case(str)
  return str
    :gsub('_(%w)', function(c)
      return c:upper()
    end)
    :gsub('^%w', string.upper)
end

---Process a schema property and generate annotations
---@param name string
---@param prop CodesettingsSchemaValue
---@param class_prefix string
local function process_property(name, prop, class_prefix)
  if prop.type == 'object' and prop.properties then
    -- Generate nested class
    local class_name = class_prefix .. to_pascal_case(name)

    add_desc_with_default(prop)
    table.insert(Build.lines, '---@class ' .. class_name)

    local props = vim.tbl_keys(prop.properties)
    table.sort(props)

    for _, field in ipairs(props) do
      local child = prop.properties[field]
      add_desc_with_default(child)

      if child.type == 'object' and child.properties then
        local nested_class = class_name .. to_pascal_case(field)
        table.insert(Build.lines, '---@field ' .. field .. ' ' .. nested_class .. '?')
        -- Recursively process nested object
        process_property(field, child, class_name)
      else
        table.insert(Build.lines, '---@field ' .. field .. ' ' .. get_lua_type(child) .. '?')
      end
    end

    table.insert(Build.lines, '')
  end
end

local M = {}

---Generate annotations for the config schema
function M.build()
  if #arg == 0 then
    error('This function is part of a build tool and should not be called directly!')
  end
  print('Generating Lua type annotations for codesettings configuration...')

  Build.lines = {
    '-- stylua: ignore',
    '---@meta',
    '',
    '---Codesettings plugin configuration types',
    '',
  }

  local schema = require('codesettings.config.schema')

  -- Generate overridable config class
  table.insert(Build.lines, '---Input type for config options that can be overridden per-load')
  table.insert(Build.lines, '---@class (partial) CodesettingsConfigOverrides: CodesettingsOverridableConfig')
  table.insert(Build.lines, '')

  -- Generate overridable config class
  table.insert(Build.lines, '---Options which can be passed on a per-load basis (i.e. can override global config)')
  table.insert(Build.lines, '---@class CodesettingsOverridableConfig')

  local props = vim.tbl_keys(schema.properties)
  table.sort(props)

  -- First pass: collect overridable properties
  local overridable_props = {}
  local non_overridable_props = {}

  for _, name in ipairs(props) do
    local prop = schema.properties[name]
    if prop.overridable then
      table.insert(overridable_props, name)
    else
      table.insert(non_overridable_props, name)
    end
  end

  -- Add overridable fields
  for _, name in ipairs(overridable_props) do
    local prop = schema.properties[name]
    add_desc_with_default(prop)

    if prop.type == 'object' and prop.properties then
      local class_name = 'Codesettings' .. to_pascal_case(name)
      table.insert(Build.lines, '---@field ' .. name .. ' ' .. class_name .. '?')
    else
      table.insert(Build.lines, '---@field ' .. name .. ' ' .. get_lua_type(prop) .. '?')
    end
  end

  table.insert(Build.lines, '')

  -- Generate main config class
  table.insert(Build.lines, '---Main configuration class')
  table.insert(Build.lines, '---@class CodesettingsConfig: CodesettingsOverridableConfig')

  -- Add non-overridable fields
  for _, name in ipairs(non_overridable_props) do
    local prop = schema.properties[name]
    add_desc_with_default(prop)
    table.insert(Build.lines, '---@field ' .. name .. ' ' .. get_lua_type(prop))
  end

  table.insert(Build.lines, '')

  -- Process nested objects
  for _, name in ipairs(props) do
    local prop = schema.properties[name]
    if prop.type == 'object' and prop.properties then
      process_property(name, prop, 'Codesettings')
    end
  end

  Util.write_file(Util.path(relpath), table.concat(Build.lines, '\n'))
  print('Generated ' .. relpath)
end

function M.clean()
  if #arg == 0 then
    error('This function is part of a build tool and should not be called directly!')
  end
  Util.delete_file(Util.path(relpath))
  print('Deleted ' .. relpath)
end

return M

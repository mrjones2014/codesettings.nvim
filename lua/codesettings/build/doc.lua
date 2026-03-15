local BuildUtil = require('codesettings.build.util')
local ConfigSchema = require('codesettings.config.schema')
local Util = require('codesettings.util')

local M = {}

---@class DocSection
---@field start_marker string The start marker to find in the README (without <!-- -->)
---@field end_marker string The end marker to find in the README (without <!-- -->)
---@field generator fun(): string Function that generates the content for this section

---Generate the LSP servers list section
---@return string
local function generate_lsp_servers()
  local lines = {}
  local schemas = BuildUtil.get_schemas()
  local lsp_names = vim.tbl_keys(schemas)
  table.sort(lsp_names)
  for _, name in ipairs(lsp_names) do
    local schema = schemas[name]
    local url = schema.schema_url
    if url:find('githubusercontent') then
      url = url
        :gsub('raw%.githubusercontent', 'github')
        :gsub('/master/', '/tree/master/', 1)
        :gsub('/develop/', '/tree/develop/', 1)
        :gsub('/main/', '/tree/main/', 1)
    end
    local supports_i18n = vim.uv.fs_stat(BuildUtil.nls_path(name))
    table.insert(lines, ('- [x] [%s](%s)%s'):format(name, url, supports_i18n and ' (supports i18n)' or ''))
  end
  return table.concat(lines, '\n')
end

---Format a value for Lua code
---@param value any
---@return string
local function format_value(value)
  if value == nil or value == vim.NIL then
    return 'nil'
  elseif type(value) == 'string' then
    return string.format("'%s'", value)
  elseif type(value) == 'table' and vim.tbl_isempty(value) then
    return '{}'
  elseif type(value) == 'table' and vim.islist(value) then
    local items = {}
    for _, v in ipairs(value) do
      table.insert(items, format_value(v))
    end
    return '{ ' .. table.concat(items, ', ') .. ' }'
  else
    return vim.inspect(value)
  end
end

---Generate the default config section
---@return string
local function generate_default_config()
  local template = [[```lua
return {
  'mrjones2014/codesettings.nvim',
  -- You don't need to lazy load this plugin since it already
  -- lazy loads its constituent parts via `plugin/*` and `ftplugin/*` files
  lazy = false,
  -- these are the default settings just set `opts = {}` to use defaults
  opts = {
%s
  },
}
```]]

  local prop_lines = {}
  local props = vim.tbl_keys(ConfigSchema.properties)
  table.sort(props)

  for _, name in ipairs(props) do
    local prop = ConfigSchema.properties[name]
    if prop.description then
      for line in prop.description:gmatch('[^\n]+') do
        table.insert(prop_lines, '    --- ' .. line)
      end
    end
    local default_val = prop.default
    if default_val == vim.NIL then
      default_val = nil
    end
    table.insert(prop_lines, '    ' .. name .. ' = ' .. format_value(default_val) .. ',')
  end

  return template:format(table.concat(prop_lines, '\n'))
end

---@type DocSection[]
local sections = {
  {
    start_marker = 'GENERATED:CONFIG:START',
    end_marker = 'GENERATED:CONFIG:END',
    generator = generate_default_config,
  },
  {
    start_marker = 'GENERATED:SERVERS:START',
    end_marker = 'GENERATED:SERVERS:END',
    generator = generate_lsp_servers,
  },
}

function M.build()
  if #arg == 0 then
    error('This function is part of a build tool and should not be called directly!')
  end

  print('Generating documentation sections in README.md...')
  local readme = Util.read_file('README.md')

  -- Process each section
  for _, section in ipairs(sections) do
    local content = section.generator()
    local start_pattern = '<!%-%- ' .. section.start_marker:gsub('%-', '%%-') .. ' %-%->'
    local end_pattern = '<!%-%- ' .. section.end_marker:gsub('%-', '%%-') .. ' %-%->'

    -- Replace content between start and end markers
    local pattern = '(' .. start_pattern .. ').-(' .. end_pattern .. ')'
    local replacement = '%1\n\n' .. content .. '\n\n%2'

    local new_readme, count = readme:gsub(pattern, replacement)
    if count > 0 then
      readme = new_readme
      print('  Generated section: ' .. section.start_marker:gsub(':START', ''))
    else
      print('  Warning: Markers not found: ' .. section.start_marker .. ' / ' .. section.end_marker)
    end
  end

  Util.write_file('README.md', readme)
  print('Documentation generation complete!')
end

return M

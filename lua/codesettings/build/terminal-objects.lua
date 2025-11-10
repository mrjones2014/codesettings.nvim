-- Build script to generate cache of terminal object paths
local Schemas = require('codesettings.build.schemas')
local Util = require('codesettings.util')

local relpath = 'lua/codesettings/generated/terminal-objects.lua'

local M = {}

function M.build()
  if #arg == 0 then
    error('This function is part of a build tool and should not be called directly!')
  end

  print('Generating terminal objects cache...')
  local terminals = Schemas.generate_terminal_objects_cache()

  -- Generate Lua file with the cache
  local lines = {
    '-- stylua: ignore',
    '-- This file contains a lookup table of property paths that represent',
    '-- terminal objects (type=object with no properties field).',
    '-- Keys inside these objects should not be dot-expanded.',
    '',
    '---@type table<string, boolean>',
    'return {',
  }

  local paths = vim.tbl_keys(terminals)
  table.sort(paths)

  for _, path in ipairs(paths) do
    table.insert(lines, string.format('  [%q] = true,', path))
  end

  table.insert(lines, '}')
  table.insert(lines, '')

  Util.write_file(Util.path(relpath), table.concat(lines, '\n'))

  print(string.format('Generated %s with %d terminal object paths', relpath, #paths))
end

return M

local build_targets = {
  schemas = require('codesettings.build.schemas'),
  annotations = require('codesettings.build.annotations'),
  config = require('codesettings.build.config-schema'),
  doc = require('codesettings.build.doc'),
}

-- Define build order and dependencies
local build_order = { 'schemas', 'annotations', 'config', 'doc' }

local build_dependencies = {
  annotations = { 'schemas' },
  doc = { 'schemas' },
}

local function get_target_names()
  local names = {}
  for name in pairs(build_targets) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

local function build_with_dependencies(target_name, built)
  built = built or {}

  -- Skip if already built
  if built[target_name] then
    return
  end

  local target = build_targets[target_name]
  if not target then
    error('Unknown build target: ' .. target_name)
  end

  -- Build dependencies first
  local deps = build_dependencies[target_name]
  if deps then
    for _, dep in ipairs(deps) do
      build_with_dependencies(dep, built)
    end
  end

  -- Build this target
  print('Building ' .. target_name .. '...')
  target.build()
  built[target_name] = true
end

local function build_target(target_name)
  if target_name then
    build_with_dependencies(target_name)
  else
    -- Build all targets in defined order
    for _, name in ipairs(build_order) do
      local target = build_targets[name]
      if target then
        print('Building ' .. name .. '...')
        target.build()
      end
    end
  end
end

local function clean_target(target_name)
  if target_name then
    local target = build_targets[target_name]
    if not target then
      error('Unknown build target: ' .. target_name)
    end
    -- no-op if clean is not defined
    if target.clean then
      print('Cleaning ' .. target_name .. '...')
      target.clean()
    end
  else
    -- Clean all targets
    for _, name in ipairs(build_order) do
      local target = build_targets[name]
      if target and target.clean then
        print('Cleaning ' .. name .. '...')
        target.clean()
      end
    end
  end
end

if #arg == 0 then
  error('This module is a build CLI and should not be `require`d directly!')
end

local argparse = require('argparse')

local parser = argparse('build', 'Build system for codesettings')

local target_list = table.concat(get_target_names(), ', ')

parser
  :command('build', 'Build the specified target or all targets')
  :argument('target', 'Build target: ' .. target_list)
  :args('?')

parser
  :command('clean', 'Clean the specified target or all targets')
  :argument('target', 'Build target: ' .. target_list)
  :args('?')

local args = parser:parse()

if args.build then
  build_target(args.target)
elseif args.clean then
  clean_target(args.target)
end

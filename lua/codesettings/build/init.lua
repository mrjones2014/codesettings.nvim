local M = {}

local build_targets = {
  schemas = require('codesettings.build.schemas'),
  annotations = require('codesettings.build.annotations'),
  config = require('codesettings.build.config-schema'),
  doc = require('codesettings.build.doc'),
}

local build_target = build_targets[arg[1]]
if build_target then
  build_target.build()
  return
end

-- otherwise, build all
for _, target in pairs(build_targets) do
  target.build()
end

return M

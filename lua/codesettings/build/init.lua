local M = {}

function M.build()
  require('codesettings.build.schemas').build()
  require('codesettings.build.annotations').build()
  require('codesettings.build.doc').build()
end

M.build()

return M

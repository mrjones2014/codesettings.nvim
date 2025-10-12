local M = {}

function M.build()
  require('codesettings.build.schemas').build()
  require('codesettings.build.annotations').build()
end

M.build()

return M

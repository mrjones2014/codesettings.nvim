local Util = require('codesettings.util')

local M = {}

function M.docs()
  local schemas = require('codesettings.build.schemas').get_schemas()
  local keys = vim.tbl_keys(schemas)
  table.sort(keys)
  local lines = {}

  for _, name in ipairs(keys) do
    local schema = schemas[name]
    local url = schema.package_url
    if url:find('githubusercontent') then
      url = url
        :gsub('raw%.githubusercontent', 'github')
        :gsub('/master/', '/tree/master/', 1)
        :gsub('/develop/', '/tree/develop/', 1)
        :gsub('/main/', '/tree/main/', 1)
    end
    table.insert(lines, ('- [x] [%s](%s)'):format(name, url))
  end
  local str = '<!-- GENERATED -->\n' .. table.concat(lines, '\n')
  local md = Util.read_file('README.md')
  md = md:gsub('<!%-%- GENERATED %-%->.*', str) .. '\n'
  Util.write_file('README.md', md)
end

function M.build()
  require('codesettings.build.schemas').build()
  M.docs()
end

M.build()

return M

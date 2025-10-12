local Util = require('codesettings.util')
local Schemas = require('codesettings.build.schemas')

local M = {}

function M.build()
  print('Generating list of supported LSP servers in README.md...')
  local lines = {}
  local schemas = Schemas.get_schemas()
  local lsp_names = vim.tbl_keys(schemas)
  table.sort(lsp_names)
  for _, name in ipairs(lsp_names) do
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
  local generated_doc = '<!-- GENERATED -->\n' .. table.concat(lines, '\n') .. '\n'
  local readme = Util.read_file('README.md')
  readme = readme:gsub('<!%-%- GENERATED %-%->.*', generated_doc) .. '\n'
  Util.write_file('README.md', readme)
end

return M

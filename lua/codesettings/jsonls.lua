local Util = require('codesettings.util')

local M = {}

function M.setup()
  local schemas = require('codesettings.build.schemas').get_schemas()
  local json_schemas = {}
  for _, schema in pairs(schemas) do
    local file_ok, json = pcall(Util.read_file, schema.settings_file)
    if not file_ok then
      goto continue
    end

    local parse_ok, parsed_schema = pcall(require('codesettings.util').json_decode, json)
    if not parse_ok then
      goto continue
    end

    local configs = Util.get_local_configs()
    table.insert(json_schemas, {
      fileMatch = configs,
      schema = parsed_schema,
    })

    ::continue::
  end

  vim.lsp.config('jsonls', {
    settings = {
      json = {
        schemas = json_schemas,
        validate = { enable = true },
      },
    },
  })
end

return M

---@module 'luassert'

describe('jsonls integration', function()
  local Jsonls = require('codesettings.integrations.jsonls')

  before_each(function()
    Jsonls.clear_cache()
  end)

  describe('get_json_schemas', function()
    it('should preserve existing schemas from vim.lsp.config', function()
      local existing_schema = {
        fileMatch = { 'my-custom-file.json' },
        schema = {
          type = 'object',
          properties = {
            customField = { type = 'string' },
          },
        },
      }

      vim.lsp.config('jsonls', {
        settings = {
          json = {
            schemas = { existing_schema },
          },
        },
      })

      local schemas = Jsonls.get_json_schemas()

      local codesettings_schemas = require('codesettings.build.schemas').get_schemas()
      assert.is.True(#schemas > #codesettings_schemas)
      assert.are.same(existing_schema, schemas[1])
    end)
  end)
end)

---@module 'busted'

describe('jsonls integration', function()
  local Jsonls = require('codesettings.setup.jsonls')

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

      Jsonls.setup()
      vim.lsp.enable('jsonls')
      -- Create a mock jsonls client
      local mock_client = {
        id = 999,
        name = 'jsonls',
        config = {
          settings = {
            json = {
              schemas = { existing_schema },
            },
          },
        },
      }
      -- Temporarily override vim.lsp.get_client_by_id to return our mock
      local original_get_client = vim.lsp.get_client_by_id
      vim.lsp.get_client_by_id = function(id) ---@diagnostic disable-line: duplicate-set-field
        if id == 999 then
          return mock_client
        end
        return original_get_client(id)
      end

      -- Fire the LspAttach autocmd
      vim.api.nvim_exec_autocmds('LspAttach', {
        data = { client_id = 999 },
      })

      -- Restore original function
      vim.lsp.get_client_by_id = original_get_client
      -- Fire the LspAttach autocmd
      vim.api.nvim_exec_autocmds('LspAttach', {
        data = { client_id = 999 },
      })

      -- Restore original function
      vim.lsp.get_client_by_id = original_get_client

      -- Check that existing schema is still present
      local schemas = mock_client.config.settings.json.schemas
      assert.truthy(vim.tbl_contains(schemas, existing_schema))

      -- Check that codesettings schemas were added
      assert.True(#schemas > 1)
      assert.same(schemas[#schemas], Jsonls.get_json_schemas()[1])
    end)
  end)
end)

describe('expand_schema', function()
  local expand_schema = require('codesettings.setup.jsonls.transformer').expand_schema

  it('creates both dotted and nested forms for a single dotted key', function()
    local input = {
      type = 'object',
      properties = {
        ['Lua.workspace.library'] = {
          type = 'array',
          items = { type = 'string' },
        },
      },
    }

    local result = expand_schema(input)
    local props = result.properties

    -- dotted key still exists
    assert.truthy(props['Lua.workspace.library'])

    -- nested path exists and is object typed
    local lua = props.Lua
    assert.same(lua.type, 'object')
    local workspace = lua.properties.workspace
    assert.same(workspace.type, 'object')
    local library = workspace.properties.library
    assert.same(library.type, 'array')
  end)

  it('handles multiple dotted keys in the same schema', function()
    local input = {
      type = 'object',
      properties = {
        ['Lua.workspace.library'] = { type = 'array', items = { type = 'string' } },
        ['Lua.window.statusBar'] = { type = 'boolean' },
      },
    }

    local result = expand_schema(input)
    local props = result.properties

    -- dotted keys exist
    assert.truthy(props['Lua.workspace.library'])
    assert.truthy(props['Lua.window.statusBar'])

    -- nested keys
    local lua = props.Lua
    assert.same(lua.type, 'object')
    local workspace = lua.properties.workspace
    assert.same(workspace.type, 'object')
    local library = workspace.properties.library
    assert.same(library.type, 'array')

    local window = lua.properties.window
    assert.same(window.type, 'object')
    local statusBar = window.properties.statusBar
    assert.same(statusBar.type, 'boolean')
  end)

  it('merges nested and dotted keys correctly when nested already exists', function()
    local input = {
      type = 'object',
      properties = {
        Lua = {
          type = 'object',
          properties = {
            workspace = {
              type = 'object',
              properties = {
                library = { description = 'existing' },
              },
            },
          },
        },
        ['Lua.workspace.library'] = {
          type = 'array',
          items = { type = 'string' },
        },
      },
    }

    local result = expand_schema(input)
    local props = result.properties

    -- nested path is merged, not overwritten
    local library = props.Lua.properties.workspace.properties.library
    assert.same(library.type, 'array')
    assert.same(library.items.type, 'string')
    assert.same(library.description, 'existing')

    -- dotted key still exists
    assert.truthy(props['Lua.workspace.library'])
  end)

  it('handles deeper nested dotted keys', function()
    local input = {
      type = 'object',
      properties = {
        ['A.B.C.D'] = { type = 'string' },
      },
    }

    local result = expand_schema(input)
    local props = result.properties

    assert.truthy(props['A.B.C.D'])
    local A = props.A
    assert.same(A.type, 'object')
    local B = A.properties.B
    assert.same(B.type, 'object')
    local C = B.properties.C
    assert.same(C.type, 'object')
    local D = C.properties.D
    assert.same(D.type, 'string')
  end)

  it('handles single-part keys and does not break them', function()
    local input = {
      type = 'object',
      properties = {
        Foo = { type = 'number' },
      },
    }

    local result = expand_schema(input)
    local props = result.properties
    assert.same(props.Foo.type, 'number')
  end)

  it('handles empty schema gracefully', function()
    local result = expand_schema({})
    assert.same(result, { properties = nil, type = nil } or result.type == nil)
  end)
end)

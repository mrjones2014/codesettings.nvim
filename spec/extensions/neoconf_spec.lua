local Extensions = require('codesettings.extensions')

describe('neoconf extension', function()
  it('should return input unchanged for tables without neoconf keys', function()
    local input = {
      foo = 'bar',
      nested = { key = 'value' },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.same(input, result)
  end)

  it('should transform neoconf.filetype_jsonc to codesettings.jsonc_filetype', function()
    local input = {
      neoconf = {
        filetype_jsonc = true,
      },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.is_table(result.codesettings)
    assert.is_true(result.codesettings.jsonc_filetype)
    assert.is_nil(result.neoconf)
  end)

  it('should transform neoconf.plugins.lua_ls.enabled to codesettings.lua_ls_integration', function()
    local input = {
      neoconf = {
        plugins = {
          lua_ls = {
            enabled = true,
          },
        },
      },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.is_table(result.codesettings)
    assert.is_true(result.codesettings.lua_ls_integration)
    assert.is_nil(result.neoconf)
  end)

  it('should transform neoconf.plugins.lua_ls.enabled_for_neovim_config to codesettings.lua_ls_integration', function()
    local input = {
      neoconf = {
        plugins = {
          lua_ls = {
            enabled_for_neovim_config = true,
          },
        },
      },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.is_table(result.codesettings)
    assert.is_true(result.codesettings.lua_ls_integration)
    assert.is_nil(result.neoconf)
  end)

  it('should prefer enabled over enabled_for_neovim_config', function()
    local input = {
      neoconf = {
        plugins = {
          lua_ls = {
            enabled = false,
            enabled_for_neovim_config = true,
          },
        },
      },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.is_false(result.codesettings.lua_ls_integration)
  end)

  it('should transform neoconf.plugins.jsonls.enabled to codesettings.jsonls_integration', function()
    local input = {
      neoconf = {
        plugins = {
          jsonls = {
            enabled = false,
          },
        },
      },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.is_table(result.codesettings)
    assert.is_false(result.codesettings.jsonls_integration)
    assert.is_nil(result.neoconf)
  end)

  it('should flatten lspconfig.* settings to root level', function()
    local input = {
      lspconfig = {
        lua_ls = {
          ['Lua.completion.callSnippet'] = 'Replace',
          ['Lua.diagnostics.globals'] = { 'vim' },
        },
        rust_analyzer = {
          ['rust-analyzer.cargo.features'] = 'all',
        },
      },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.equal('Replace', result['Lua.completion.callSnippet'])
    assert.same({ 'vim' }, result['Lua.diagnostics.globals'])
    assert.equal('all', result['rust-analyzer.cargo.features'])
    assert.is_nil(result.lspconfig)
  end)

  it('should remove neodev key', function()
    local input = {
      neodev = {
        library = {
          enabled = true,
          plugins = { 'nvim-lspconfig' },
        },
      },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.is_nil(result.neodev)
  end)

  it('should preserve non-neoconf keys', function()
    local input = {
      neoconf = {
        filetype_jsonc = true,
      },
      someOtherKey = 'value',
      nested = {
        data = 'preserved',
      },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.equal('value', result.someOtherKey)
    assert.same({ data = 'preserved' }, result.nested)
    assert.is_nil(result.neoconf)
  end)

  it('should handle complete neoconf config transformation', function()
    local input = {
      neodev = {
        library = {
          enabled = true,
          plugins = { 'nvim-lspconfig', 'lsp' },
        },
      },
      neoconf = {
        filetype_jsonc = false,
        plugins = {
          lua_ls = {
            enabled = false,
          },
          jsonls = {
            enabled = false,
          },
        },
      },
      lspconfig = {
        lua_ls = {
          ['Lua.completion.callSnippet'] = 'Replace',
          ['Lua.runtime.version'] = 'LuaJIT',
        },
        rust_analyzer = {
          ['rust-analyzer.check.command'] = 'clippy',
        },
      },
      customKey = { foo = 'bar' },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    -- Check codesettings transformation
    assert.is_table(result.codesettings)
    assert.is_false(result.codesettings.jsonc_filetype)
    assert.is_false(result.codesettings.lua_ls_integration)
    assert.is_false(result.codesettings.jsonls_integration)

    -- Check LSP settings flattened
    assert.equal('Replace', result['Lua.completion.callSnippet'])
    assert.equal('LuaJIT', result['Lua.runtime.version'])
    assert.equal('clippy', result['rust-analyzer.check.command'])

    -- Check neoconf-specific keys removed
    assert.is_nil(result.neoconf)
    assert.is_nil(result.lspconfig)
    assert.is_nil(result.neodev)

    -- Check custom keys preserved
    assert.same({ foo = 'bar' }, result.customKey)
  end)

  it('should handle empty neoconf table', function()
    local input = {
      neoconf = {},
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.is_table(result.codesettings)
    assert.is_nil(result.neoconf)
  end)

  it('should handle empty lspconfig table', function()
    local input = {
      lspconfig = {},
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.is_nil(result.lspconfig)
  end)

  it('should work with multiple extensions', function()
    local input = {
      neoconf = {
        filetype_jsonc = true,
      },
      someEnvVar = '${HOME}/test',
    }

    local result = Extensions.apply(input, {
      'codesettings.extensions.neoconf',
      'codesettings.extensions.env',
    })

    -- Both extensions should apply
    assert.is_table(result.codesettings)
    assert.is_true(result.codesettings.jsonc_filetype)
    -- env extension should have expanded the variable
    assert.equal(vim.env.HOME .. '/test', result.someEnvVar)
  end)

  it('should handle deeply nested structures', function()
    local input = {
      lspconfig = {
        lua_ls = {
          ['Lua.workspace.library'] = { '/path/one', '/path/two' },
          ['Lua.runtime.path'] = { '?.lua', '?/init.lua' },
        },
      },
      other = {
        deeply = {
          nested = {
            value = 'preserved',
          },
        },
      },
    }

    local result = Extensions.apply(input, { 'codesettings.extensions.neoconf' })

    assert.same({ '/path/one', '/path/two' }, result['Lua.workspace.library'])
    assert.same({ '?.lua', '?/init.lua' }, result['Lua.runtime.path'])
    assert.equal('preserved', result.other.deeply.nested.value)
  end)
end)

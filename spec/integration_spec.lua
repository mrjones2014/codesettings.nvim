---@module 'luassert'

describe('integration tests', function()
  setup(function()
    -- configure the plugin to look in the directory with the test files
    local Config = require('codesettings.config')
    local cfg_file_paths = vim
      .iter(Config.config_file_paths)
      :map(function(p)
        return ('spec/test-config-files/%s'):format(p)
      end)
      :totable()
    local Codesettings = require('codesettings')
    Codesettings.setup({
      config_file_paths = cfg_file_paths,
    })
  end)
  it('should load and merge settings from local configs', function()
    local Codesettings = require('codesettings')
    vim.lsp.config(
      'lua_ls',
      Codesettings.with_local_settings('lua_ls', {
        settings = {
          Lua = {
            workspace = {
              library = { 'test' },
            },
          },
        },
      })
    )
    local resolved_lua_ls = vim.lsp.config['lua_ls']
    assert.same(resolved_lua_ls.settings, {
      Lua = {
        window = {
          -- comes from ./vscode/settings.json
          statusBar = false,
        },
        addonManager = {
          enable = true, -- comes from ./codesettings.json
        },
        workspace = {
          library = { 'test' },
        },
      },
    })
  end)

  it('should load and merge eslint settings properly by default', function()
    local Codesettings = require('codesettings')
    -- test eslint specifically since its a special case (see codesettings/init.lua)
    vim.lsp.config(
      'eslint',
      Codesettings.with_local_settings('eslint', {
        settings = {
          execArgv = { '--codesettings-test' },
        },
      })
    )
    local resolved_eslint = vim.lsp.config['eslint']
    assert.same(resolved_eslint.settings, {
      execArgv = { '--codesettings-test' },
      -- comes from ./lspsettings.json
      codeAction = {
        disableRuleComment = {
          enable = true,
          location = 'separateLine',
        },
        showDocumentation = { enable = true },
      },
    })
  end)
end)

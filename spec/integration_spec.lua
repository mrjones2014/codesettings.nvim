---@module 'luassert'

describe('integration tests', function()
  describe('basic usage', function()
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

    -- test eslint specifically since its a special case (see codesettings/init.lua)
    it('should load and merge eslint settings properly by default', function()
      local Codesettings = require('codesettings')
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

    -- test nixd specifically since its a special case (see codesettings/init.lua)
    it('should load and merge nixd settings properly by default', function()
      local Codesettings = require('codesettings')
      vim.lsp.config(
        'nixd',
        Codesettings.with_local_settings('nixd', {
          settings = {
            nixd = {
              options = {
                nix_darwin = {
                  expr = 'test darwin expr',
                },
              },
            },
          },
        })
      )
      local resolved_nixd = vim.lsp.config['nixd']
      assert.same(resolved_nixd.settings, {
        nixd = {
          options = {
            nix_darwin = {
              expr = 'test darwin expr',
            },
            nixos = {
              -- comes from ./lspsettings.json
              expr = 'test nixos expr',
            },
          },
          -- comes from ./vscode/settings.json
          formatting = {
            command = { 'nixfmt' },
          },
        },
      })
    end)
  end)

  describe('one-shot custom loaders via CodesettingsConfigBuilder', function()
    setup(function()
      -- reset the global config to defaults before each test
      local Config = require('codesettings.config')
      Config.reset() ---@diagnostic disable-line: invisible
    end)
    it('should allow overriding root_dir via builder', function()
      local Codesettings = require('codesettings')
      local settings =
        Codesettings.loader():root_dir(assert(vim.uv.cwd()) .. '/spec/test-config-files/subroot'):local_settings()

      -- this setting is from spec/test-config-files/subroot/customsettings.json
      assert.equal('Lua 5.1', settings:schema('lua_ls'):get('Lua.runtime.version'))
    end)

    it('should allow custom local config paths via builder', function()
      local Codesettings = require('codesettings')
      local settings = Codesettings.loader()
        :root_dir(assert(vim.uv.cwd()) .. '/spec/test-config-files/subroot')
        :config_file_paths({ 'customsettings.json' })
        :local_settings()

      -- this setting comes from spec/test-config-files/subroot/.vscode/settings.json
      assert.same({ 'feature-a' }, settings:schema('rust-analyzer'):get('rust-analyzer.cargo.features'))
    end)

    it('should apply custom merge_list_behavior=prepend', function()
      local base_config = {
        settings = {
          Lua = {
            workspace = {
              library = { 'base' },
            },
          },
        },
      }

      -- spec/test-config-files/subroot/.vscode/settings.json defines Lua.workspace.library = { 'local' }
      local Codesettings = require('codesettings')
      local merged = Codesettings.loader()
        :root_dir(vim.fn.getcwd() .. '/spec/test-config-files/subroot')
        :merge_list_behavior('prepend')
        :with_local_settings('lua_ls', base_config)

      -- Expect 'local' to appear before 'base' because of 'prepend'
      assert.same(merged.settings.Lua.workspace.library, { 'local', 'base' })
    end)

    it('should not modify global config when using the builder', function()
      local Codesettings = require('codesettings')
      local Config = require('codesettings.config')
      local original_paths = vim.deepcopy(Config.config_file_paths)

      local _ = Codesettings.loader():config_file_paths({ 'random-path.json' }):local_settings()

      -- Ensure global Config.config_file_paths are unchanged
      assert.same(Config.config_file_paths, original_paths)
    end)
  end)
end)

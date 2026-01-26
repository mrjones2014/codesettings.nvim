---@module 'busted'

local Extensions = require('codesettings.extensions')
local Util = require('codesettings.util')
local VSCodeExtension = require('codesettings.extensions.vscode')

describe('CodesettingsVSCodeExtension', function()
  describe('expand_vscode_vars', function()
    it('expands ${userHome}', function()
      local ext = VSCodeExtension()
      local result = ext:expand_vscode_vars('${userHome}/projects')
      assert.are.equal(vim.fn.expand('~') .. '/projects', result)
    end)

    it('expands ${workspaceFolder}', function()
      local root = Util.get_root()
      local ext = VSCodeExtension()
      local result = ext:expand_vscode_vars('${workspaceFolder}/src')
      if root then
        assert.are.equal(root .. '/src', result)
      else
        assert.are.equal('/src', result)
      end
    end)

    it('expands ${workspaceFolderBasename}', function()
      local root = Util.get_root()
      local ext = VSCodeExtension({ root = root })
      local result = ext:expand_vscode_vars('project: ${workspaceFolderBasename}')
      if root then
        local basename = vim.fn.fnamemodify(root, ':t')
        assert.are.equal('project: ' .. basename, result)
      else
        assert.are.equal('project: ', result)
      end
    end)

    it('expands ${cwd}', function()
      local cwd = vim.uv.cwd()
      local ext = VSCodeExtension()
      local result = ext:expand_vscode_vars('${cwd}/file.txt')
      assert.are.equal((cwd or '') .. '/file.txt', result)
    end)

    it('expands ${pathSeparator}', function()
      local sep = vim.fn.has('win32') == 1 and '\\' or '/'
      local ext = VSCodeExtension()
      local result = ext:expand_vscode_vars('path${pathSeparator}to${pathSeparator}file')
      assert.are.equal('path' .. sep .. 'to' .. sep .. 'file', result)
    end)

    it('expands ${/} as shorthand for pathSeparator', function()
      local sep = vim.fn.has('win32') == 1 and '\\' or '/'
      local ext = VSCodeExtension()
      local result = ext:expand_vscode_vars('path${/}to${/}file')
      assert.are.equal('path' .. sep .. 'to' .. sep .. 'file', result)
    end)

    it('handles multiple different variables in one string', function()
      local ext = VSCodeExtension()
      local result = ext:expand_vscode_vars('${userHome}${/}${workspaceFolderBasename}${/}src')
      local home = vim.fn.expand('~')
      local root = Util.get_root()
      local sep = vim.fn.has('win32') == 1 and '\\' or '/'
      local basename = root and vim.fn.fnamemodify(root, ':t') or ''

      assert.are.equal(home .. sep .. basename .. sep .. 'src', result)
    end)

    it('leaves unknown variables unchanged', function()
      local ext = VSCodeExtension()
      -- Variables we explicitly do not support
      local result = ext:expand_vscode_vars('${file}')
      assert.are.equal('${file}', result)

      result = ext:expand_vscode_vars('${lineNumber}')
      assert.are.equal('${lineNumber}', result)

      result = ext:expand_vscode_vars('${selectedText}')
      assert.are.equal('${selectedText}', result)
    end)

    it('handles strings with no variables', function()
      local str = 'plain string with no variables'
      local ext = VSCodeExtension()
      local result = ext:expand_vscode_vars(str)
      assert.are.equal(str, result)
    end)

    it('handles empty strings', function()
      local ext = VSCodeExtension()
      assert.are.equal('', ext:expand_vscode_vars(''))
    end)

    it('handles adjacent variables', function()
      local home = vim.fn.expand('~')
      local ext = VSCodeExtension()
      local result = ext:expand_vscode_vars('${userHome}${userHome}')
      assert.are.equal(home .. home, result)
    end)
  end)

  describe('leaf', function()
    it('expands VS Code variables in string leaves', function()
      local input = {
        home_path = '${userHome}/projects',
        workspace = '${workspaceFolder}',
        static = 'no variables',
      }

      local result = Extensions.apply(input, { VSCodeExtension })

      assert.are.equal(vim.fn.expand('~') .. '/projects', result.home_path)
      local root = Util.get_root()
      assert.are.equal(root or '', result.workspace)
      assert.are.equal('no variables', result.static)
    end)

    it('expands variables in nested tables', function()
      local input = {
        paths = {
          home = '${userHome}',
          workspace = '${workspaceFolder}/src',
        },
        config = {
          cwd = '${cwd}',
          sep = '${/}',
        },
      }

      local result = Extensions.apply(input, { VSCodeExtension })

      assert.are.equal(vim.fn.expand('~'), result.paths.home)
      local root = Util.get_root()
      assert.are.equal((root or '') .. '/src', result.paths.workspace)
      assert.are.equal(vim.uv.cwd() or '', result.config.cwd)
      local sep = vim.fn.has('win32') == 1 and '\\' or '/'
      assert.are.equal(sep, result.config.sep)
    end)

    it('handles arrays with mixed values', function()
      local input = {
        paths = { '${userHome}', '${workspaceFolder}', 123, false, 'static' },
      }

      local result = Extensions.apply(input, { VSCodeExtension })

      assert.are.equal(vim.fn.expand('~'), result.paths[1])
      assert.are.equal(Util.get_root() or '', result.paths[2])
      assert.are.equal(123, result.paths[3])
      assert.is_false(result.paths[4])
      assert.are.equal('static', result.paths[5])
    end)

    it('does not modify non-string values', function()
      local input = {
        number = 42,
        boolean = true,
        null = vim.NIL,
      }

      local result = Extensions.apply(input, { VSCodeExtension })

      assert.are.equal(42, result.number)
      assert.is_true(result.boolean)
      assert.are.equal(vim.NIL, result.null)
    end)
  end)

  describe('integration with extension system', function()
    it('can be loaded by module path', function()
      local input = {
        path = '${userHome}/config',
      }

      local result = Extensions.apply(input, { 'codesettings.extensions.vscode' })

      assert.are.equal(vim.fn.expand('~') .. '/config', result.path)
    end)

    it('works with multiple extensions in correct order', function()
      -- Set up test environment variable that won't conflict with VS Code vars
      local old_env = vim.deepcopy(vim.env)
      vim.env.MY_TEST_VAR = 'test_value'

      local input = {
        vscode_var = '${userHome}/projects',
        env_var = '${MY_TEST_VAR}/path',
        both = '${userHome}/${MY_TEST_VAR}',
      }

      -- VS Code extension should run first, then env
      local result = Extensions.apply(input, {
        'codesettings.extensions.vscode',
        'codesettings.extensions.env',
      })

      assert.are.equal(vim.fn.expand('~') .. '/projects', result.vscode_var)
      assert.are.equal('test_value/path', result.env_var)
      assert.are.equal(vim.fn.expand('~') .. '/test_value', result.both)

      -- Cleanup
      vim.env = old_env
    end)

    it('demonstrates ordering importance - wrong order fails', function()
      -- Ensure no workspaceFolder environment variable exists
      local old_env = vim.deepcopy(vim.env)
      vim.env.workspaceFolder = nil

      local input = {
        workspace = '${workspaceFolder}/src',
      }

      -- If env runs first, it will replace ${workspaceFolder} with empty string
      -- Then VS Code extension sees the result '/src' with no variables to expand
      local result = Extensions.apply(input, {
        'codesettings.extensions.env', -- Wrong order!
        'codesettings.extensions.vscode',
      })

      -- The env extension replaced ${workspaceFolder} with '', result is '/src'
      assert.are.equal('/src', result.workspace)

      -- Cleanup
      vim.env = old_env
    end)

    it('demonstrates correct ordering - right order works', function()
      -- Ensure no workspaceFolder environment variable exists
      local old_env = vim.deepcopy(vim.env)
      vim.env.workspaceFolder = nil

      local input = {
        workspace = '${workspaceFolder}/src',
      }

      -- Correct order: VS Code first (expands ${workspaceFolder}), then env (no-op)
      local result = Extensions.apply(input, {
        'codesettings.extensions.vscode', -- Correct order!
        'codesettings.extensions.env',
      })

      local root = Util.get_root()
      assert.are.equal((root or '') .. '/src', result.workspace)

      -- Cleanup
      vim.env = old_env
    end)
  end)

  describe('edge cases', function()
    it('handles deeply nested structures', function()
      local input = {
        level1 = {
          level2 = {
            level3 = {
              path = '${userHome}/deep/path',
            },
          },
        },
      }

      local result = Extensions.apply(input, { VSCodeExtension })

      assert.are.equal(vim.fn.expand('~') .. '/deep/path', result.level1.level2.level3.path)
    end)

    it('handles complex real-world example', function()
      local input = {
        ['rust-analyzer'] = {
          cargo = {
            extraEnv = {
              CARGO_TARGET_DIR = '${workspaceFolder}/target',
            },
          },
          checkOnSave = {
            command = 'clippy',
          },
        },
        Lua = {
          workspace = {
            library = {
              '${workspaceFolder}/lua',
              '${userHome}/.local/share/nvim/lazy',
            },
          },
        },
      }

      local result = Extensions.apply(input, { VSCodeExtension })

      local root = Util.get_root()
      assert.are.equal((root or '') .. '/target', result['rust-analyzer'].cargo.extraEnv.CARGO_TARGET_DIR)
      assert.are.equal('clippy', result['rust-analyzer'].checkOnSave.command)
      assert.are.equal((root or '') .. '/lua', result.Lua.workspace.library[1])
      assert.are.equal(vim.fn.expand('~') .. '/.local/share/nvim/lazy', result.Lua.workspace.library[2])
    end)
  end)
end)

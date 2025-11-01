---@module 'luassert'

local EnvExt = require('codesettings.extensions.env')

describe('CodesettingsEnvExtension', function()
  describe('expand_env', function()
    local old_env

    before_each(function()
      old_env = vim.deepcopy(vim.env)
      vim.env = {}
    end)

    after_each(function()
      vim.env = old_env
    end)

    it('expands normal variables', function()
      vim.env.USER = 'username'
      assert.are.equal('username', EnvExt.expand_env('${USER}'))
      assert.are.equal('username', EnvExt.expand_env('$USER'))
    end)

    it('uses default if variable is nil', function()
      vim.env.UNDEF = nil
      assert.are.equal('default', EnvExt.expand_env('${UNDEF:-default}'))
      assert.are.equal('', EnvExt.expand_env('${UNDEF}'))
    end)

    it('does not override empty string with default', function()
      vim.env.EMPTY = ''
      assert.are.equal('', EnvExt.expand_env('${EMPTY:-default}'))
    end)

    it('handles multiple variables in one string', function()
      vim.env.USER = 'username'
      vim.env.HOME = '/home/username'
      assert.are.equal('username:/home/username', EnvExt.expand_env('${USER}:${HOME}'))
    end)

    it('handles special characters in paths', function()
      vim.env.PATH = '/usr/bin:/bin'
      assert.are.equal('/usr/bin:/bin/file.txt', EnvExt.expand_env('${PATH}/file.txt'))
    end)

    it('handles nested defaults gracefully', function()
      vim.env.HOME = nil
      vim.env.USER = 'username'
      assert.are.equal('username', EnvExt.expand_env('${HOME:-${USER}}'))
      assert.are.equal('', EnvExt.expand_env('${HOME:-}'))
    end)

    it('handles trailing dash defaults', function()
      vim.env.VAR = nil
      assert.are.equal('', EnvExt.expand_env('${VAR:-}'))
    end)

    it('does not expand invalid patterns', function()
      assert.are.equal('${}', EnvExt.expand_env('${}'))
    end)

    it('does not incorrectly expand variables when adjacent to text', function()
      vim.env.FOO = 'foo'
      assert.are.equal('foobar', EnvExt.expand_env('${FOO}bar'))
      assert.are.equal('foo-bar', EnvExt.expand_env('${FOO}-bar'))
    end)
  end)

  describe('leaf', function()
    local Extensions = require('codesettings.extensions')

    it('expands string leaves in a flat table', function()
      local input = {
        path = '${HOME}/projects',
        username = '${USER}',
        unused = 'static',
      }

      local ext = EnvExt
      local result = Extensions.apply(input, { ext })

      assert.same({
        path = vim.env.HOME .. '/projects',
        username = vim.env.USER,
        unused = 'static',
      }, result)
    end)

    it('expands nested tables', function()
      local input = {
        paths = {
          project = '${HOME}/projects',
          bin = '${HOME}/bin',
        },
        user = {
          name = '${USER}',
          id = 42,
        },
      }

      local ext = EnvExt
      local result = Extensions.apply(input, { ext })

      assert.same({
        paths = {
          project = vim.env.HOME .. '/projects',
          bin = vim.env.HOME .. '/bin',
        },
        user = {
          name = vim.env.USER,
          id = 42,
        },
      }, result)
    end)

    it('handles arrays with mixed values', function()
      local input = {
        list = { '${USER}', '${HOME}/docs', 123, false },
      }

      local ext = EnvExt
      local result = Extensions.apply(input, { ext })

      assert.same({
        list = { vim.env.USER, vim.env.HOME .. '/docs', 123, false },
      }, result)
    end)

    it('handles ${VAR:-default} style defaults in nested tables', function()
      local input = {
        path = '${NOTSET:-/default/path}',
        nested = { value = '${ANOTHER:-fallback}' },
      }

      local ext = EnvExt
      local result = Extensions.apply(input, { ext })

      assert.same({
        path = '/default/path',
        nested = { value = 'fallback' },
      }, result)
    end)
  end)
end)

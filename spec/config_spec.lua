---@module 'busted'

describe('codesettings.config', function()
  before_each(function()
    require('codesettings.config').reset() ---@diagnostic disable-line: invisible
  end)

  describe('schema for local config files', function()
    it('loads config for the plugin itself from local config files based on config schema', function()
      local Codesettings = require('codesettings')
      Codesettings.setup({
        config_file_paths = { 'spec/test-config-files/codesettings_plugin_conf.json' },
      })
      -- from spec/test-config-files/codesettings_plugin_conf.json
      local Config = require('codesettings.config')
      assert.equal('replace', Config.merge_opts.list_behavior)
      assert.equal(false, Config.jsonc_filetype)
      assert.equal(false, Config.lua_ls_integration)
      assert.equal(false, Config.jsonls_integration)
    end)

    it('should not run integration setups when disabled in local config', function()
      local Codesettings = require('codesettings')
      local jsonls_mod = require('codesettings.integrations.jsonls')
      local lua_ls_mod = require('codesettings.integrations.lua_ls')
      local jsonc_filetype_mod = require('codesettings.integrations.jsonc-filetype')
      spy.on(jsonls_mod, 'setup')
      spy.on(lua_ls_mod, 'setup')
      spy.on(jsonc_filetype_mod, 'setup')
      Codesettings.setup({
        -- this config file disables all three integrations
        config_file_paths = { 'spec/test-config-files/codesettings_plugin_conf.json' },
      })
      assert.spy(jsonls_mod.setup --[[@as luassert.spy]]).called(0)
      assert.spy(lua_ls_mod.setup --[[@as luassert.spy]]).called(0)
      assert.spy(jsonc_filetype_mod.setup --[[@as luassert.spy]]).called(0)
    end)
  end)

  describe('config json schema', function()
    local schema = require('codesettings.config').jsonschema()
    local schema_table = schema:totable()

    it('returns a CodesettingsSchema instance', function()
      assert.is_not_nil(schema)
      assert.is_table(schema)
      assert.is_function(schema.totable)
      assert.is_function(schema.flatten)
      assert.is_function(schema.properties)
    end)

    it('has the correct flattened structure', function()
      assert.is_table(schema_table.properties)
      assert.equal('http://json-schema.org/draft-07/schema#', schema_table['$schema'])
      assert.is_not_nil(schema_table.properties['codesettings.config_file_paths'])
      assert.is_not_nil(schema_table.properties['codesettings.merge_opts.list_behavior'])
      assert.is_not_nil(schema_table.properties['codesettings.root_dir'])
    end)

    it('filters out function types because they are not valid in json schema', function()
      local root_dir_prop = schema_table.properties['codesettings.root_dir']
      assert.is_not_nil(root_dir_prop)

      -- Original type is { 'string', { args = {}, ret = 'string' }, 'null' }
      -- Should be filtered to { 'string', 'null' } or similar
      local prop_type = root_dir_prop.type

      if type(prop_type) == 'table' then
        -- Ensure no function type objects remain
        for _, t in ipairs(prop_type) do
          assert.is_not_table(t)
        end
      end
    end)
  end)

  describe('ConfigBuilder', function()
    local ConfigBuilder = require('codesettings.config.builder')
    local Config = require('codesettings.config')
    it('creates a new builder with default config', function()
      local config = ConfigBuilder.new():build()
      assert.is_table(config)
      assert.same(Config.config_file_paths, config.config_file_paths)
      assert.equal(Config.root_dir, config.root_dir)
      assert.same(Config.merge_opts, config.merge_opts)
    end)

    it('sets config_file_paths with a valid string array', function()
      local paths = { 'foo.json', 'bar.json' }
      local config = ConfigBuilder.new():config_file_paths(paths):build()
      assert.same(paths, config.config_file_paths)
    end)

    it('errors on invalid config_file_paths', function()
      local builder = ConfigBuilder.new()
      assert.has_error(function()
        builder:config_file_paths('not-a-list') ---@diagnostic disable-line: param-type-mismatch
      end)
      assert.has_error(function()
        builder:config_file_paths({ 123 }) ---@diagnostic disable-line: assign-type-mismatch
      end)
    end)

    it('sets merge_list_behavior correctly', function()
      local config = ConfigBuilder.new():merge_list_behavior('replace'):build()
      assert.equal('replace', config.merge_opts.list_behavior)
    end)

    it('errors on invalid merge_list_behavior', function()
      local builder = ConfigBuilder.new()
      assert.has_error(function()
        builder:merge_list_behavior('invalid') ---@diagnostic disable-line: param-type-mismatch
      end)
    end)

    it('sets root_dir correctly', function()
      local builder = ConfigBuilder.new():root_dir('/new/path'):build()
      assert.equal('/new/path', builder.root_dir)
    end)

    it('accepts a function as root_dir', function()
      local fn = function()
        return '/dynamic'
      end
      local config = ConfigBuilder.new():root_dir(fn):build()
      assert.equal(fn, config.root_dir)
    end)

    it('errors on invalid root_dir', function()
      local builder = ConfigBuilder.new()
      assert.has_error(function()
        builder:root_dir(123) ---@diagnostic disable-line: param-type-mismatch
      end)
    end)
  end)
end)

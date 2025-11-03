local ConfigBuilder = require('codesettings.config.builder')
local Config = require('codesettings.config')

describe('codesettings.config.builder', function()
  it('creates a new builder with default config', function()
    local config = ConfigBuilder.new():build()
    assert.is_table(config)
    assert.same(Config.config_file_paths, config.config_file_paths)
    assert.equals(Config.root_dir, config.root_dir)
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
    assert.equals('replace', config.merge_opts.list_behavior)
  end)

  it('errors on invalid merge_list_behavior', function()
    local builder = ConfigBuilder.new()
    assert.has_error(function()
      builder:merge_list_behavior('invalid') ---@diagnostic disable-line: param-type-mismatch
    end)
  end)

  it('sets root_dir correctly', function()
    local builder = ConfigBuilder.new():root_dir('/new/path'):build()
    assert.equals('/new/path', builder.root_dir)
  end)

  it('accepts a function as root_dir', function()
    local fn = function()
      return '/dynamic'
    end
    local config = ConfigBuilder.new():root_dir(fn):build()
    assert.equals(fn, config.root_dir)
  end)

  it('errors on invalid root_dir', function()
    local builder = ConfigBuilder.new()
    assert.has_error(function()
      builder:root_dir(123) ---@diagnostic disable-line: param-type-mismatch
    end)
  end)
end)

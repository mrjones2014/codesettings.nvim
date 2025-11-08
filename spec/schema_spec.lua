---@module 'busted'

local Schema = require('codesettings.schema')
local Schemas = require('codesettings.build.schemas')

describe('Schema loading and property enumeration', function()
  it('has schemas index populated', function()
    local all = Schemas.get_schemas()
    assert.is_table(all)
    -- Expect at least several schemas present
    assert.is_true(vim.tbl_count(all) > 5)
    assert.is_table(all.rust_analyzer)
    assert.is_truthy(all.rust_analyzer.settings_file)
  end)

  it('loads schema by underscore name and enumerates properties', function()
    local s = Schema.load('rust_analyzer')
    assert.is_table(s)
    local props = s:properties()
    assert.is_table(props)

    -- Build lookup set for membership assertions
    local set = {}
    for _, p in ipairs(props) do
      set[p] = true
    end

    -- A few representative rust-analyzer settings that should exist
    assert.is_true(set['rust-analyzer.cargo.allTargets'] or set['rust_analyzer.cargo.allTargets'])
    assert.is_true(set['rust-analyzer.cargo.features'] or set['rust_analyzer.cargo.features'])
    assert.is_true(set['rust-analyzer.diagnostics.enable'] or set['rust_analyzer.diagnostics.enable'])
  end)

  it('loads schema by dash name (fallback underscore replacement)', function()
    -- Intentionally load with dash form; internal table uses underscore.
    local s = Schema.load('rust-analyzer')
    local props = s:properties()
    assert.is_true(#props > 0)

    local set = {}
    for _, p in ipairs(props) do
      set[p] = true
    end
    -- The property path should use the original dashed root (because dotted expansion keeps original key)
    assert.is_true(set['rust-analyzer.cargo.allTargets'])
  end)

  it('caches per lsp_name key', function()
    local a1 = Schema.load('lua_ls')
    local a2 = Schema.load('lua_ls')
    assert.is_true(a1 == a2, 'Expected same cached Schema object for repeated loads with identical key')

    -- Different key form (if it existed) would produce a distinct cache entry; rust analyzer has two forms.
    local r1 = Schema.load('rust_analyzer')
    local r2 = Schema.load('rust-analyzer')
    -- They are separate cache entries (different lookup keys)
    assert.is_true(r1 ~= r2)
    -- But they should expose (largely) overlapping properties; test an exemplar key.
    local set1, set2 = {}, {}
    for _, p in ipairs(r1:properties()) do
      set1[p] = true
    end
    for _, p in ipairs(r2:properties()) do
      set2[p] = true
    end
    assert.is_true(set1['rust-analyzer.cargo.allTargets'])
    assert.is_true(set2['rust-analyzer.cargo.allTargets'])
  end)

  it('returns empty schema for unknown server', function()
    local unknown = Schema.load('definitely_nonexistent_language_server_xyz')
    local props = unknown:properties()
    -- No properties expected
    assert.same({}, props)
  end)

  it('enumerates nested property paths (multi-level)', function()
    local lua_schema = Schema.load('lua_ls')
    local props = lua_schema:properties()
    local set = {}
    for _, p in ipairs(props) do
      set[p] = true
    end
    -- Lua LS schema commonly includes Lua.runtime.version & Lua.workspace.library
    assert.is_true(set['Lua.runtime.version'], 'Expected Lua.runtime.version in enumerated properties')
    assert.is_true(set['Lua.workspace.library'], 'Expected Lua.workspace.library in enumerated properties')
  end)
end)

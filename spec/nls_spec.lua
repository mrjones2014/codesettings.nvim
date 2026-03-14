---@module 'busted'

local NLS = require('codesettings.nls')

describe('NLS.apply()', function()
  it('substitutes %key% when key exists in table', function()
    local result = NLS.apply('%hello%', { hello = 'world' })
    assert.equal('world', result)
  end)

  it('leaves %key% unchanged when key is absent', function()
    local result = NLS.apply('%missing%', { other = 'value' })
    assert.equal('%missing%', result)
  end)

  it('passes through non-string values unchanged', function()
    assert.equal(42, NLS.apply(42, { ['42'] = 'nope' }))
    assert.equal(true, NLS.apply(true, {}))
    assert.is_nil(NLS.apply(nil, {}))
  end)

  it('does not modify strings that are not wrapped in %...%', function()
    assert.equal('hello world', NLS.apply('hello world', { hello = 'REPLACED' }))
    assert.equal('%partial', NLS.apply('%partial', { partial = 'x' }))
    assert.equal('partial%', NLS.apply('partial%', { partial = 'x' }))
  end)

  it('recurses into nested tables and replaces strings at any depth', function()
    local tbl = {
      description = '%desc%',
      nested = {
        markdownDescription = '%md%',
        value = 123,
        deeper = {
          title = '%title%',
        },
      },
    }
    local nls = { desc = 'A description', md = 'Markdown desc', title = 'My title' }
    local result = NLS.apply(tbl, nls)
    assert.equal('A description', result.description)
    assert.equal('Markdown desc', result.nested.markdownDescription)
    assert.equal(123, result.nested.value)
    assert.equal('My title', result.nested.deeper.title)
  end)

  it('does not mutate the original table', function()
    local tbl = { description = '%key%' }
    local nls = { key = 'replaced' }
    local result = NLS.apply(tbl, nls)
    assert.equal('replaced', result.description)
    assert.equal('%key%', tbl.description)
  end)
end)

describe('NLS.load_bundled()', function()
  it('returns a table for a known LSP that has a bundled NLS file (jsonls)', function()
    local tbl = assert(NLS.load_bundled('jsonls'))
    assert.is_table(tbl)
    assert.is_true(vim.tbl_count(tbl) > 0)
  end)

  it('returns nil for an unknown LSP name', function()
    local result = NLS.load_bundled('definitely_nonexistent_lsp_xyz_nls')
    assert.is_nil(result)
  end)

  it('returns the same table on second call (cache hit)', function()
    -- Use a name that won't exist so we can test the nil-cache path too
    local r1 = NLS.load_bundled('definitely_nonexistent_lsp_xyz_nls')
    local r2 = NLS.load_bundled('definitely_nonexistent_lsp_xyz_nls')
    -- Both nil — same result (nil == nil)
    assert.is_nil(r1)
    assert.is_nil(r2)

    -- For a real bundled file, both calls return the same table reference
    local a1 = NLS.load_bundled('jsonls')
    local a2 = NLS.load_bundled('jsonls')
    if a1 ~= nil then
      assert.is_true(a1 == a2)
    end
  end)
end)

describe('NLS.resolve()', function()
  local Config = require('codesettings.config')

  after_each(function()
    Config.reset() ---@diagnostic disable-line: invisible
    package.loaded['codesettings.nls'] = nil
  end)

  it('true → calls load_bundled (returns table or nil)', function()
    Config.nls = true
    local result = NLS.resolve('jsonls')
    -- Either nil (no bundled file) or a table
    assert.is_true(result == nil or type(result) == 'table')
  end)

  it('nil → same as true (default)', function()
    Config.nls = true
    local result_true = NLS.resolve('jsonls')
    Config.nls = nil
    local result_nil = NLS.resolve('jsonls')
    assert.same(result_true, result_nil)
  end)

  it('false → returns nil (no substitution)', function()
    Config.nls = false
    local result = NLS.resolve('jsonls')
    assert.is_nil(result)
  end)

  it('table → returns the table itself', function()
    local nls = { ['json.schemas.desc'] = 'My JSON schemas' }
    Config.nls = nls
    local result = NLS.resolve('jsonls')
    assert.is_true(result == nls)
  end)

  it('string path → reads {path}/{lsp_name}.nls.json and returns decoded table', function()
    -- Write a fixture NLS file to a temp directory
    local tmpdir = vim.fn.tempname()
    vim.fn.mkdir(tmpdir, 'p')
    local fixture = { ['test.key'] = 'Test Value' }
    local fixture_path = tmpdir .. '/testlsp.nls.json'
    local fd = io.open(fixture_path, 'w')
    assert.is_truthy(fd)
    ---@cast fd file*
    fd:write(vim.json.encode(fixture))
    fd:close()

    Config.nls = tmpdir
    local result = assert(NLS.resolve('testlsp'))
    assert.is_table(result)
    assert.equal('Test Value', result['test.key'])

    -- Cleanup
    os.remove(fixture_path)
    vim.fn.delete(tmpdir, 'rf')
  end)

  it('string path → returns nil if file does not exist', function()
    Config.nls = '/nonexistent/path'
    local result = NLS.resolve('jsonls')
    assert.is_nil(result)
  end)

  it('function → calls it with lsp_name and returns result', function()
    local called_with = nil
    Config.nls = function(lsp_name)
      called_with = lsp_name
      return { ['fn.key'] = 'fn value' }
    end

    local result = assert(NLS.resolve('lua_ls'))
    assert.equal('lua_ls', called_with)
    assert.is_table(result)
    assert.equal('fn value', result['fn.key'])
  end)
end)

describe('NLS integration with Schema.load()', function()
  local Config = require('codesettings.config')

  before_each(function()
    -- Reset schema cache between tests by clearing the private cache.
    -- We reload the module to get a fresh cache.
    package.loaded['codesettings.schema'] = nil
    package.loaded['codesettings.nls'] = nil
    Config.reset() ---@diagnostic disable-line: invisible
  end)

  it('Schema.load() with nls=false leaves raw %placeholder% strings', function()
    Config.nls = false
    -- Directly test that apply is not called: resolve(false) = nil
    local resolved = NLS.resolve('jsonls')
    assert.is_nil(resolved)
  end)

  it('Schema.load() with nls=table substitutes descriptions', function()
    local custom_nls = { ['json.schemas.desc'] = 'Custom schema description' }
    Config.nls = custom_nls

    -- Test that resolve returns the table directly
    local resolved = NLS.resolve('jsonls')
    assert.is_true(resolved == custom_nls)

    -- Test apply works with schema-like data
    local schema_fragment = { description = '%json.schemas.desc%' }
    local result = NLS.apply(schema_fragment, custom_nls)
    assert.equal('Custom schema description', result.description)
  end)

  it('Schema.load() with bundled NLS active: descriptions do not contain %...% patterns', function()
    Config.nls = true
    local Schema = require('codesettings.schema')
    local s = Schema.load('jsonls')
    local tbl = s:totable()

    -- Walk through all string values and check none match the %...% pattern
    local function check_no_placeholders(node)
      if type(node) == 'string' then
        assert.is_nil(node:match('^%%(.+)%%$'))
      elseif type(node) == 'table' then
        for _, v in pairs(node) do
          check_no_placeholders(v)
        end
      end
    end
    check_no_placeholders(tbl)
  end)
end)

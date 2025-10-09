---@module 'luassert'

local Settings = require('codesettings.settings')

describe('Settings.path()', function()
  it('returns empty table for nil/empty', function()
    assert.same({}, Settings.path(nil))
    assert.same({}, Settings.path(''))
  end)

  it('splits dotted keys', function()
    assert.same({ 'a', 'b', 'c' }, Settings.path('a.b.c'))
  end)

  it('wraps non-string keys', function()
    assert.same({ 123 }, Settings.path(123))
  end)
end)

describe('Settings basic set/get', function()
  local S
  before_each(function()
    S = Settings.new()
  end)

  it('sets and gets nested value', function()
    S:set('a.b.c', 42)
    assert.equal(42, S:get('a.b.c'))
    assert.same({ b = { c = 42 } }, S:get('a'))
  end)

  it('get without key returns root table', function()
    S:set('x.y', true)
    local root = S:get()
    assert.is_table(root)
    assert.same({ x = { y = true } }, root)
  end)

  it('overwrites root when setting empty key', function()
    S:set('a.b', 1)
    S:set('', { overwritten = true })
    assert.same({ overwritten = true }, S:get())
  end)
end)

describe('Settings:get_subtable()', function()
  it('returns a Settings wrapper for a table', function()
    local S = Settings.new()
    S:set('lang.rust.features', { 'a' })
    local sub = S:get_subtable('lang.rust')
    assert.is_table(sub)
    assert.same({ features = { 'a' } }, sub:get())
  end)

  it('returns empty Settings when value is not a table', function()
    local S = Settings.new()
    S:set('value.leaf', 1)
    local sub = S:get_subtable('value.leaf')
    assert.same({}, sub:get())
  end)
end)

describe('Settings.expand()', function()
  it('passes non-table through', function()
    assert.equal(5, Settings.expand(5))
  end)

  it('expands dotted keys into nested tables', function()
    local expanded = Settings.expand({
      ['a.b'] = 1,
      c = 2,
      d = { e = 3 },
    })
    assert.same({
      a = { b = 1 },
      c = 2,
      d = { e = 3 },
    }, expanded)
  end)
end)

describe('Settings:merge()', function()
  it('merges nested tables', function()
    local A = Settings.new()
    A:set('tool.cfg.alpha', 1)
    local B = Settings.new()
    B:set('tool.cfg.beta', 2)
    A:merge(B)
    assert.same({ tool = { cfg = { alpha = 1, beta = 2 } } }, A:get())
  end)

  it('merges only a subtable when key provided', function()
    local base = Settings.new()
    base:set('lsp.rust.features', { 'a' })

    local extra = Settings.new()
    extra:set('features', { 'b' })

    base:merge(extra, 'lsp.rust')
    assert.same({ lsp = { rust = { features = { 'a', 'b' } } } }, base:get())
  end)

  it('overwrites scalar values', function()
    local A = Settings.new()
    A:set('opt.value', 1)
    local B = Settings.new()
    B:set('opt.value', 2)
    A:merge(B)
    assert.equal(2, A:get('opt.value'))
  end)
end)

describe('Settings:clear()', function()
  it('clears all data', function()
    local S = Settings.new()
    S:set('a.b', 1)
    S:clear()
    assert.same({}, S:get())
  end)
end)

describe('Settings:load()', function()
  local tmpfile

  local function write_tmp(contents)
    local f = assert(io.open(tmpfile, 'w'))
    f:write(contents)
    f:close()
  end

  setup(function()
    tmpfile = os.tmpname()
  end)

  teardown(function()
    os.remove(tmpfile)
  end)

  it('loads and parses json with dotted keys expanded', function()
    write_tmp('{"a.b":1, "c": { "d": 2 }}')
    local S = Settings.new():load(tmpfile)
    assert.same({ a = { b = 1 }, c = { d = 2 } }, S:get())
  end)

  it('loads empty file as empty table', function()
    write_tmp('')
    local S = Settings.new():load(tmpfile)
    assert.same({}, S:get())
  end)
end)

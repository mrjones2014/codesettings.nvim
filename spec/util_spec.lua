local Util = require('codesettings.util')

describe('util.merge - scalar merge', function()
  it('overwrites scalar with later value', function()
    local a = 1
    local b = 2
    local merged = Util.merge(a, b)
    assert.equal(2, merged)
  end)

  it('nil right side keeps left if right nil (expected: becomes nil because b takes precedence)', function()
    local a = { value = 5 }
    local b = { value = nil }
    local merged = Util.merge(a, b)
    -- Current contract: b takes precedence even if nil
    assert.is_nil(merged.value)
  end)
end)

describe('util.merge - nested table merging (maps)', function()
  it('merges distinct nested keys', function()
    local a = { tool = { cfg = { alpha = 1 } } }
    local b = { tool = { cfg = { beta = 2 } } }
    local merged = Util.merge(a, b)
    assert.same({ tool = { cfg = { alpha = 1, beta = 2 } } }, merged)
  end)

  it('overwrites scalar value at same key', function()
    local a = { opt = { value = 1 } }
    local b = { opt = { value = 3 } }
    local merged = Util.merge(a, b)
    assert.same({ opt = { value = 3 } }, merged)
  end)
end)

describe('util.merge - list behavior: append (default)', function()
  it('appends lists by default', function()
    local a = { list = { 1, 2 } }
    local b = { list = { 3, 4 } }
    local merged = Util.merge(a, b) -- default list_behavior=append
    -- Desired behavior: {1,2,3,4}
    assert.same({ list = { 1, 2, 3, 4 } }, merged)
  end)

  it('appends nested lists inside tables', function()
    local a = { outer = { inner = { 10 } } }
    local b = { outer = { inner = { 20 } } }
    local merged = Util.merge(a, b)
    assert.same({ outer = { inner = { 10, 20 } } }, merged)
  end)
end)

describe('util.merge - list behavior: prepend', function()
  it('prepends list values when specified', function()
    local a = { vals = { 'a', 'b' } }
    local b = { vals = { 'c', 'd' } }
    local merged = Util.merge(a, b, { list_behavior = 'prepend' })
    -- Desired: b items first
    assert.same({ vals = { 'c', 'd', 'a', 'b' } }, merged)
  end)

  it('prepends nested lists when specified', function()
    local a = { nest = { nums = { 2 } } }
    local b = { nest = { nums = { 1 } } }
    local merged = Util.merge(a, b, { list_behavior = 'prepend' })
    assert.same({ nest = { nums = { 1, 2 } } }, merged)
  end)
end)

describe('util.merge - list behavior: replace', function()
  it('replaces list entirely', function()
    local a = { l = { 1, 2 } }
    local b = { l = { 9, 8 } }
    local merged = Util.merge(a, b, { list_behavior = 'replace' })
    assert.same({ l = { 9, 8 } }, merged)
  end)

  it('replaces nested list entirely', function()
    local a = { x = { y = { 1 } } }
    local b = { x = { y = { 2, 3 } } }
    local merged = Util.merge(a, b, { list_behavior = 'replace' })
    assert.same({ x = { y = { 2, 3 } } }, merged)
  end)
end)

describe('util.merge - mixed list and map', function()
  it('replaces map with list when types differ', function()
    local a = { key = { sub = 1 } }
    local b = { key = { 5, 6 } } -- list
    local merged = Util.merge(a, b)
    assert.same({ key = { 5, 6 } }, merged)
  end)

  it('replaces list with map when types differ', function()
    local a = { key = { 5, 6 } }
    local b = { key = { sub = 1 } }
    local merged = Util.merge(a, b)
    assert.same({ key = { sub = 1 } }, merged)
  end)
end)

describe('util.merge - option propagation', function()
  it('applies list_behavior to nested lists (prepend)', function()
    local a = { a = { list = { 1 } } }
    local b = { a = { list = { 2 } } }
    local merged = Util.merge(a, b, { list_behavior = 'prepend' })
    assert.same({ a = { list = { 2, 1 } } }, merged)
  end)

  it('applies list_behavior to nested lists (replace)', function()
    local a = { a = { list = { 1, 2 } } }
    local b = { a = { list = { 3 } } }
    local merged = Util.merge(a, b, { list_behavior = 'replace' })
    assert.same({ a = { list = { 3 } } }, merged)
  end)
end)

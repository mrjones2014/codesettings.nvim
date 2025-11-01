---@module 'luassert'

local Extensions = require('codesettings.extensions')

describe('CodesettingsLoaderExtension', function()
  it('returns the table unodified when no extensions are given', function()
    local input = {
      a = 1,
      b = { c = 2 },
    }
    local result = Extensions.apply(input, {})
    assert.same(result, input)
  end)

  it('calls object and leaf visitors and respects control codes', function()
    local input = {
      a = 1,
      b = { c = 2 },
      d = { 3, 4 },
    }

    -- Dummy extension
    local ext = {
      object = function(_, ctx)
        if ctx.key == 'b' then
          return Extensions.Control.REPLACE, { replaced = true }
        elseif ctx.key == 'd' then
          return Extensions.Control.SKIP
        else
          return Extensions.Control.CONTINUE
        end
      end,
      leaf = function(value, _)
        if value == 1 then
          return Extensions.Control.REPLACE, 42
        end
        return Extensions.Control.CONTINUE
      end,
    }

    local result = Extensions.apply(input, { ext })

    -- 'a' leaf replaced
    assert.same(result.a, 42)

    -- 'b' object replaced
    assert.same(result.b, { replaced = true })

    -- 'd' skipped
    assert.same(result.d, { 3, 4 })
  end)

  it('traverses nested structures and arrays', function()
    local input = {
      arr = { { x = 1 }, { x = 2 } },
    }

    local seen = {}
    local ext = {
      leaf = function(value, ctx)
        table.insert(seen, { path = { unpack(ctx.path) }, value = value })
        return Extensions.Control.CONTINUE
      end,
    }

    Extensions.apply(input, { ext })

    -- Check that all leaf values were visited
    local values = {}
    for _, v in ipairs(seen) do
      table.insert(values, v.value)
    end
    assert.same(values, { 1, 2 })
  end)

  it('calls both method-style and function-style extensions correctly', function()
    local fn_object_called = false
    local fn_leaf_called = false
    local method_object_called = false
    local method_leaf_called = false

    -- Function-style extension
    local fn_ext = {
      object = function(_, _)
        fn_object_called = true
        return Extensions.Control.CONTINUE
      end,
      leaf = function(_, _)
        fn_leaf_called = true
        return Extensions.Control.CONTINUE
      end,
    }

    -- Method-style extension using a metatable class
    local MethodExtension = {}
    MethodExtension.__index = MethodExtension

    function MethodExtension:new()
      return setmetatable({}, self)
    end

    function MethodExtension:object(_, _)
      method_object_called = true
      return Extensions.Control.CONTINUE
    end

    function MethodExtension:leaf(_, _)
      method_leaf_called = true
      return Extensions.Control.CONTINUE
    end

    local method_ext = MethodExtension:new()

    -- Input structure
    local input = {
      a = 1,
      b = { 2, 3 },
    }

    -- Apply both extensions
    local result = Extensions.apply(input, { fn_ext, method_ext })
    assert.Not.is_nil(result)

    assert.is_true(fn_object_called)
    assert.is_true(fn_leaf_called)
    assert.is_true(method_object_called)
    assert.is_true(method_leaf_called)
  end)
end)

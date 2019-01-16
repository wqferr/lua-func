local module = {}
local internal = {}

local Iterable = {}
local iter_meta = {}
iter_meta.__index = Iterable


function Iterable.create(t)
  local iterable = internal.base_iter(internal.iter_next)

  iterable.values = { table.unpack(t) }
  iterable.index = 0

  return iterable
end


function Iterable:filter(predicate)
  local iterable = internal.base_iter(internal.filter_next)

  iterable.values = self
  iterable.predicate = predicate

  return iterable
end


function Iterable:map(mapping)
  local iterable = internal.base_iter(internal.map_next)

  iterable.values = self
  iterable.mapping = mapping

  return iterable
end


function Iterable:next()
  return self:next_value()
end


iter_meta.__call = Iterable.next


-- RAW FUNCTIONS --


local function iter(t)
  return Iterable.create(t)
end


local function filter(t, predicate)
  return iter(t):filter(predicate)
end


local function map(t, mapping)
  return iter(t):map(mapping)
end


local function export_funcs()
  _G.iter = iter
  _G.filter = filter

  return module
end


-- INTERNAL --


function internal.base_iter(next_f)
  local iterable = {}
  setmetatable(iterable, iter_meta)
  iterable.completed = false
  iterable.next_value = next_f
  return iterable
end


function internal.iter_next(iter)
  if iter.completed then
    return nil
  end
  iter.index = iter.index + 1
  local next_value = iter.values[iter.index]
  iter.completed = next_value == nil
  return next_value
end


function internal.filter_next(iter)
  if iter.completed then
    return nil
  end
  local next_input = iter.values:next_value()
  while next_input ~= nil do
    if iter.predicate(next_input) then
      return next_input
    end
    next_input = iter.values:next_value()
  end

  iter.completed = true
  return nil
end


function internal.map_next(iter)
  if iter.completed then
    return nil
  end
  local next_input = iter.values:next_value()
  if next_input == nil then
    iter.completed = true
    return nil
  end

  -- get only 1st return value (could mess up iteration)
  return (iter.mapping(next_input))
end


function internal.assert_table(arg, arg_name)
  assert(
    type(arg) == 'table',
    internal.ERR_EXPECTED_TABLE:format(arg_name, arg)
  )
end

internal.ERR_EXPECTED_TABLE = 'argument %s is %s, expected table'


module.Iterable = Iterable
module.iter = iter
module.filter = filter
module.import = export_funcs


return module
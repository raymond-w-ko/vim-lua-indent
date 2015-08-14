-- vim: et sw=2 sts=2 ts=2
local tsukuyomi = tsukuyomi
local util = require('tsukuyomi.thirdparty.util')

local PersistentList = tsukuyomi.lang.PersistentList
local PersistentVector = tsukuyomi.lang.PersistentVector
local PersistentHashMap = tsukuyomi.lang.PersistentHashMap
local ArraySeq = tsukuyomi.lang.ArraySeq
local ConcatSeq = tsukuyomi.lang.ConcatSeq
local Symbol = tsukuyomi.lang.Symbol
local Keyword = tsukuyomi.lang.Keyword
local Var = tsukuyomi.lang.Var

print('PersistentList: ' .. tostring(PersistentList))
print('PersistentList.EMPTY: ' .. tostring(PersistentList.EMPTY))
print('PersistentVector: ' .. tostring(PersistentVector))
print('PersistentHashMap: ' .. tostring(PersistentHashMap))
print('ConcatSeq: ' .. tostring(ConcatSeq))
print('ArraySeq: ' .. tostring(ArraySeq))

-- TODO: add indenting
-- TODO: make not vulnerable to a stack overflow when printing cons cells
-- TODO: make not vulnerable to infinite loop due to self referential data structures
function tsukuyomi.print(datum)
  if type(datum) == 'boolean' then
    return tostring(datum)
  elseif type(datum) == 'number' then
    return tostring(datum)
  elseif type(datum) == 'string' then
    return '"' .. datum .. '"'
  elseif datum == nil then
    return 'nil'
  end

  local mt = getmetatable(datum)

  if mt == Symbol or mt == Keyword then
    return tostring(datum)
  elseif mt == PersistentVector then
    local items = {}
    for i = 0, datum:count() - 1 do
      table.insert(items, tsukuyomi.print(datum:get(i)))
    end
    return '[' .. table.concat(items, ' ') .. ']'
  elseif mt == PersistentHashMap then
    local items = {}
    local seq = datum:seq()
    while seq and seq:first() ~= nil do
      local kv = seq:first()
      local k = kv:get(0)
      local v = kv:get(1)
      table.insert(items, tsukuyomi.print(k))
      table.insert(items, tsukuyomi.print(v))
      seq = seq:rest()
    end
    return '{' .. table.concat(items, ' ') .. '}'
  elseif mt == Var then
    return tostring(datum)
  elseif datum.first ~= nil then
    local items = {}

    --[[
    while true do
      if datum:count() == 0 then
        local check = datum:seq()
        if check ~= nil then
          print(getmetatable(datum))
          print(util.show(datum))
          assert(false)
        end
        break
      end

      local item = datum:first()
      table.insert(items, tsukuyomi.print(item))

      datum = datum:rest()
    end
    ]]--

    while datum:seq() do
      local item = datum:first()
      table.insert(items, tsukuyomi.print(item))
      datum = datum:rest()
    end
    return '(' .. table.concat(items, ' ') .. ')'
  else
    print(util.show(datum))
    assert(false)
  end
end

tsukuyomi.core['pr-str'] = tsukuyomi.lang.Function.new()
tsukuyomi.core['pr-str'][1] = tsukuyomi.print

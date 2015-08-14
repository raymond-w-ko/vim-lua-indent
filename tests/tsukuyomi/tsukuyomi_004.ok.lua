-- vim: et sw=2 sts=2 ts=2
local tsukuyomi = tsukuyomi
local tsukuyomi_core = tsukuyomi.core
local PushbackReader = tsukuyomi.lang.PushbackReader
local Compiler = tsukuyomi.lang.Namespace.GetNamespaceSpace('tsukuyomi.lang.Compiler')
local PersistentList = tsukuyomi.lang.PersistentList
local Symbol = tsukuyomi.lang.Symbol

tsukuyomi_core['eval'] = tsukuyomi.lang.Function.new()
tsukuyomi_core['eval'][1] = function (form)
  assert(false)
end

local def_symbol = Symbol.intern('def')

local function describe(datum)
  local info
  if type(datum) == 'table' and datum.first then
    if datum:first() == def_symbol then
      local symbol = datum:rest():first()
      symbol = tsukuyomi.core['*ns*']:bind_symbol(symbol)
      info = tostring(symbol)
    end
  end
  return info
end

tsukuyomi_core['load-file'] = tsukuyomi.lang.Function.new()
tsukuyomi_core['load-file'][1] = function (name)
  local f = io.open(name)
  local text = f:read('*all')
  f:close()
  local r = PushbackReader.new(text, name)

  local datum = tsukuyomi_core.read[1](r)
  while datum do
    local lua_code = Compiler.compile(datum)
    local chunk, err = loadstring(lua_code, describe(datum))
    if err then
      io.stderr:write(err)
      io.stderr:write('\n')
      assert(false)
    else
      chunk()
    end

    datum = tsukuyomi_core.read[1](r)
  end
end

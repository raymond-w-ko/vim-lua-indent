-- vim: et sw=2 sts=2 ts=2
local tsukuyomi = tsukuyomi
local tsukuyomi_core = tsukuyomi.core
local util = require('tsukuyomi.thirdparty.util')
local Compiler = tsukuyomi.lang.Namespace.GetNamespaceSpace('tsukuyomi.lang.Compiler')

local Symbol = tsukuyomi.lang.Symbol
local Keyword = tsukuyomi.lang.Keyword
local Function = tsukuyomi.lang.Function
-- special forms
local kNsSymbol = Symbol.intern('ns')
local kQuoteSymbol = Symbol.intern('quote')
local kDefSymbol = Symbol.intern('def')
local kIfSymbol = Symbol.intern('if')
local kFnSymbol = Symbol.intern('fn')
local kEmitSymbol = Symbol.intern('_emit_')
local kNilSymbol = Symbol.intern("nil")
local kLetSymbol = Symbol.intern("let")
local kAmpersandSymbol = Symbol.intern("&")
local kDotSymbol = Symbol.intern(".")

local PersistentList = tsukuyomi.lang.PersistentList
local PersistentVector = tsukuyomi.lang.PersistentVector
local PersistentHashMap = tsukuyomi.lang.PersistentHashMap

local Var = tsukuyomi.lang.Var

--------------------------------------------------------------------------------
-- standard doubly-linked list
--
-- so far, just used for IR list, so that is why ll_new_node accepts op
--------------------------------------------------------------------------------
function Compiler.ll_new_node(op, env)
  assert(op)
  assert(env)

  local node = {}
  node.op = op
  node.environment = env
  return node
end

function Compiler.ll_insert_after(node, new_node)
  new_node.prev = node
  new_node.next = node.next
  if node.next then
    node.next.prev = new_node
  end
  node.next = new_node
end

function Compiler.ll_insert_before(node, new_node)
  new_node.prev = node.prev
  new_node.next = node
  if node.prev then
    node.prev.next = new_node
  end
  node.prev = new_node
end

function Compiler.ll_remove(node)
  node.prev.next = node.next
  node.next.prev = node.prev
end

--------------------------------------------------------------------------------

local var_counter = -1
local function make_unique_var_name(desc)
  desc = desc or 'var'
  var_counter = var_counter + 1
  return '__' .. desc .. '_' .. tostring(var_counter)
end
Compiler.make_unique_var_name = make_unique_var_name

--------------------------------------------------------------------------------

local function is_lua_primitive(datum)
  -- actual primitive types
  if type(datum) == 'string' or type(datum) == 'number' or type(datum) == 'boolean' then
    return true
  elseif datum == nil then
    return true
  elseif getmetatable(datum) == Symbol then
    -- this isn't a true Lua primitive, but it's intent is that it is just a
    -- variable name referring to something like a Lua variable, so pretend
    -- that it is
    return true
  end

  return false
end

local function compile_lua_primitive(datum)
  if type(datum) == 'number' or type(datum) == 'boolean' then
    return tostring(datum)
  elseif type(datum) == 'string' then
    return string.format('%q', datum)
  elseif getmetatable(datum) == Symbol then
    -- we can't do symbol binding here since we don't know if the symbol is
    -- referring to a variable in a namespace or a lambda function argument
    -- variable
    -- do this in the the lua_compiler
    -- (ns core)
    -- (def a 1234)
    -- (fn (a) (+ 1 a))
    -- "a" above should refer to the function argument "a", not "a" in the
    -- namespace
    return datum
  elseif datum == nil then
    return 'nil'
  end

  -- if datum has been checked using is_lua_primitive, this should never happend
  assert(false)
end

--------------------------------------------------------------------------------

-- these set of function are used to maintain the lexical stack of symbols
-- introduced that are actually bound to lambdas instead of resolving to
-- something inside a namespace
--
-- like
--   (ns core)
--   (def a 1)
--   ((lambda [a b c] a) 2)
--
-- the "a" in "print a" would NOT bind to core/a, but the "a" of the lambda argument
-- e.g. this would print 2 instead of 1

-- mapping of variable name to number of time mentioned in enclosing functions
Compiler.LexicalEnvironment = {}
local LexicalEnvironment = Compiler.LexicalEnvironment
LexicalEnvironment.__index = LexicalEnvironment

function LexicalEnvironment.new()
  local env = setmetatable({symbols = {}}, LexicalEnvironment)
  return env
end

function LexicalEnvironment:extend_with(symbols)
  local newenv = LexicalEnvironment.new()
  for i = 1, #symbols do
    local symbol = symbols[i]
    assert(getmetatable(symbol) == Symbol,
           'LexicalEnvironment:extend_with(): argument must be a list of tsukuyomi.lang.Symbol')

    if symbol ~= kAmpersandSymbol then
      newenv.symbols[tostring(symbol)] = true
    end
  end
  newenv.parent = self
  return newenv
end

function LexicalEnvironment:has_symbol(symbol)
  assert(getmetatable(symbol) == Symbol,
         'LexicalEnvironment:has_symbol(): argument must be tsukuyomi.lang.Symbol')

  if self.symbols[tostring(symbol)] then
    return true
  end

  if self.parent then
    return self.parent:has_symbol(symbol)
  else
    return false
  end
end

function LexicalEnvironment:set_recur_point(recur_type, recur_point_name, recur_arity)
  if recur_type == 'fn' then
    self.recur_type = 'fn'
    self.recur_point_name = recur_point_name
    self.recur_arity = recur_arity
  else
    assert(false)
  end
end

function LexicalEnvironment:__tostring()
  local t = {}

  local symbols = {}
  local env = self
  while env do
    for symbol, _ in pairs(env.symbols) do
      symbols[symbol] = true
    end
    env = env.parent
  end
  table.insert(t, 'LOCALS: ')
  for symbol, _ in pairs(symbols) do
    table.insert(t, symbol)
  end

  if self.recur_type == 'fn' then
    table.insert(t, '\t[RECUR]')
    table.insert(t, ' TYPE: ')
    table.insert(t, self.recur_type)
    table.insert(t, ' NAME: ')
    table.insert(t, self.recur_point_name)
    table.insert(t, ' ARITY: ')
    table.insert(t, self.recur_arity)
  end

  return table.concat(t)
end

--------------------------------------------------------------------------------

-- dispatch tables to compile down input

-- used to implement dispatch based on the first / car of a cons cell
Compiler.special_forms = {}
local special_forms = Compiler.special_forms

-- TODO: support other namespaces via require
-- TODO: check for symbol collision in namespaces
special_forms['ns'] = function(node, datum, new_dirty_nodes)
  node.op = 'NS'
  node.args = {datum:first()}

  -- TODO: see if it makes sense to return anything here other than a dummy value
  if node.is_return then
    node.is_return = false

    local dummy_return = Compiler.ll_new_node('PRIMITIVE', node.environment)
    dummy_return.args = { 'nil' }
    Compiler.ll_insert_after(node, dummy_return)
    dummy_return.is_return = true
  end
end

special_forms['def'] = function(node, datum, new_dirty_nodes)
  local orig_node = node

  local symbol = datum:first()
  assert(getmetatable(symbol) == Symbol, 'First argument to def must be a Symbol')

  local intern_var_node = Compiler.ll_new_node('INTERNVAR', orig_node.environment)
  local bound_symbol = tsukuyomi_core['*ns*']:bind_symbol(symbol)
  intern_var_node.args = {bound_symbol, symbol:meta()}
  Compiler.ll_insert_before(node, intern_var_node)

  -- (def symbol datum)
  local defnode = Compiler.ll_new_node('LISP', node.environment)
  table.insert(new_dirty_nodes, defnode)
  defnode.op = 'LISP'
  defnode.define_symbol = symbol
  defnode.args = {datum:rest():first()}
  Compiler.ll_insert_before(node, defnode)

  node.op = 'GETVAR'
  node.args = {bound_symbol}
end

special_forms['_emit_'] = function(node, datum, new_dirty_nodes)
  node.op = 'RAW'
  local inline = datum:first()
  assert(type(inline) == 'string')
  node.args = {inline}
end

special_forms['quote'] = function(node, datum, new_dirty_nodes)
  node.op = 'DATA'
  node.args = {datum:first()}
end

special_forms['if'] = function(node, datum, new_dirty_nodes)
  local orig_node = node

  local ret_var_node = Compiler.ll_new_node('EMPTYVAR', orig_node.environment)
  local ret_var_name = make_unique_var_name('if_ret')
  ret_var_node.args = {ret_var_name}
  Compiler.ll_insert_before(orig_node, ret_var_node)
  node = ret_var_node

  local fence = Compiler.ll_new_node('VARFENCE', orig_node.environment)
  Compiler.ll_insert_after(node, fence)
  node = fence

  local test = datum
  -- this can be nil legitimately, although I don't know why anyone would do
  -- this, maybe a macro?
  --assert(test:first() ~= nil)
  local var_test_node = Compiler.ll_new_node('NEWLVAR', orig_node.environment)
  table.insert(new_dirty_nodes, var_test_node)
  local var_name = make_unique_var_name('cond')
  var_test_node.args = {var_name, test:first()}
  Compiler.ll_insert_after(node, var_test_node)
  node = var_test_node

  local if_node = Compiler.ll_new_node('IF', orig_node.environment)
  if_node.args = { var_name }
  Compiler.ll_insert_after(node, if_node)
  node = if_node

  local then_cell = test:rest()
  assert(then_cell)
  local then_node = Compiler.ll_new_node('LISP', orig_node.environment)
  table.insert(new_dirty_nodes, then_node)
  then_node.args = { then_cell:first() }
  then_node.set_var_name = ret_var_name
  Compiler.ll_insert_after(node, then_node)
  node = then_node

  local else_keyword_node = Compiler.ll_new_node('ELSE', orig_node.environment)
  Compiler.ll_insert_after(node, else_keyword_node)
  node = else_keyword_node

  local else_cell = then_cell:rest()
  local else_node
  if else_cell then
    else_node = Compiler.ll_new_node('LISP', orig_node.environment)
    else_node.args = { else_cell:first() }
    table.insert(new_dirty_nodes, else_node)
  else
    else_node = Compiler.ll_new_node('PRIMITIVE', orig_node.environment)
    else_node.args = { kNilSymbol }
  end
  else_node.set_var_name = ret_var_name
  Compiler.ll_insert_after(node, else_node)
  node = else_node

  local end_node = Compiler.ll_new_node('ENDIF', orig_node.environment)
  Compiler.ll_insert_after(node, end_node)
  node = end_node

  local endfence = Compiler.ll_new_node('ENDVARFENCE', orig_node.environment)
  Compiler.ll_insert_after(node, endfence)
  node = endfence

  node = orig_node
  node.op = 'PRIMITIVE'
  node.args = { ret_var_name }
end

special_forms['do'] = function(node, datum, dirty_nodes)
  local orig_node = node

  local ret_var_node = Compiler.ll_new_node('EMPTYVAR', orig_node.environment)
  local ret_var_name = make_unique_var_name('do_ret')
  ret_var_node.args = {ret_var_name}
  Compiler.ll_insert_before(orig_node, ret_var_node)
  node = ret_var_node

  local num_forms = 0

  while datum:seq() do
    local form = datum:first()

    num_forms = num_forms + 1

    local fence = Compiler.ll_new_node('VARFENCE', orig_node.environment)
    Compiler.ll_insert_after(node, fence)
    node = fence

    local lisp_node = Compiler.ll_new_node('LISP', orig_node.environment)
    lisp_node.args = {form}
    Compiler.ll_insert_after(node, lisp_node)
    table.insert(dirty_nodes, lisp_node)
    node = lisp_node

    local endfence = Compiler.ll_new_node('ENDVARFENCE', orig_node.environment)
    Compiler.ll_insert_after(node, endfence)
    node = endfence

    datum = datum:rest()
  end

  if num_forms > 0 then
    node.prev.set_var_name = ret_var_name
  end

  node = orig_node
  node.op = 'PRIMITIVE'
  node.args = { ret_var_name }
end

special_forms['let'] = function(node, datum, new_dirty_nodes)
  local orig_node = node

  local bindings = datum:first()
  assert(bindings and getmetatable(bindings) == PersistentVector and (bindings:count() % 2 == 0))
  local exprs = datum:rest()

  local ret_var_node = Compiler.ll_new_node('EMPTYVAR', orig_node.environment)
  local ret_var_name = make_unique_var_name('let_ret')
  ret_var_node.args = { ret_var_name }
  Compiler.ll_insert_before(orig_node, ret_var_node)
  node = ret_var_node

  local fence = Compiler.ll_new_node('VARFENCE', orig_node.environment)
  Compiler.ll_insert_after(node, fence)
  node = fence

  local extended_environment = orig_node.environment
  local i = 0
  while i < bindings:count() do
    -- TODO: support destructuring
    local var_symbol = bindings:get(i)
    local var_name = var_symbol.name
    extended_environment = extended_environment:extend_with({var_symbol})

    local form = bindings:get(i + 1)
    local lisp_node = Compiler.ll_new_node('NEWLVAR', extended_environment)
    lisp_node.args = { var_name, form }
    table.insert(new_dirty_nodes, lisp_node)
    Compiler.ll_insert_after(node, lisp_node)
    node = lisp_node

    i = i + 2
  end

  while exprs do
    local fence = Compiler.ll_new_node('VARFENCE', extended_environment)
    Compiler.ll_insert_after(node, fence)
    node = fence

    local lisp_node = Compiler.ll_new_node('LISP', extended_environment)
    lisp_node.args = { exprs:first() }
    if exprs:next() == nil then
      lisp_node.set_var_name = ret_var_name
    end
    table.insert(new_dirty_nodes, lisp_node)
    Compiler.ll_insert_after(node, lisp_node)
    node = lisp_node

    exprs = exprs:next()

    local endfence = Compiler.ll_new_node('ENDVARFENCE', extended_environment)
    Compiler.ll_insert_after(node, endfence)
    node = endfence
  end

  local endfence = Compiler.ll_new_node('ENDVARFENCE', extended_environment)
  Compiler.ll_insert_after(node, endfence)
  node = endfence

  node = orig_node
  node.op = 'PRIMITIVE'
  node.args = { ret_var_name }
end

-- (fn [arg0 arg1] (body))
special_forms['fn'] = function(node, datum, new_dirty_nodes)
  local func_var_name = make_unique_var_name('func')

  local orig_node = node
  node.op = 'PRIMITIVE'
  node.args = {func_var_name}

  local real_func_node = Compiler.ll_new_node('FUNC', orig_node.environment)
  Compiler.ll_insert_before(node, real_func_node)
  real_func_node.new_lvar_name = func_var_name
  node = real_func_node
  orig_node = node

  local bodies = {}
  local mt = datum.first and getmetatable(datum:first())
  if mt == PersistentVector then
    -- this function has only 1 arity
    table.insert(bodies, datum)
  elseif datum:first() then
    -- this function has multiple aritys
    while datum do
      table.insert(bodies, datum:first())
      datum = datum:next()
    end
  else
    assert(false)
  end

  local rest_arg_index = false

  for i = 1, #bodies do
    local body = bodies[i]
    local args = body:first()
    local exprs = body:rest()

    local extended_environment = orig_node.environment:extend_with(args:ToLuaArray())
    local func_node = Compiler.ll_new_node('FUNCBODY', extended_environment)
    Compiler.ll_insert_after(node, func_node)
    node = func_node
    node.args = {}; local slot = 1
    node.parent = orig_node

    -- convert function argument symbols to string
    -- TODO: will I or someone ever put explicit namespace symbols here by accident?
    -- like (fn [foobar lol/wut] (+ foobar lol/wut))
    -- is it even worth it to check?
    local args_count = args:count()
    if args_count > 20 then
      if (args_count == 21 or args_count == 22) then
        if (args:get(20) == kAmpersandSymbol) then
          -- pass
        else
          assert(false, "Can't specify more than 20 params, did you mean to use (... & rest)?")
        end
      else
        assert(false, "Can't specify more than 20 params")
      end
    end
    for i = 0, args_count - 1 do
      local arg_name = tostring(args:get(i))
      if arg_name ~= '&' then
        node.args[slot] = arg_name
        slot = slot + 1
      else
        rest_arg_index = i + 1
      end
    end

    extended_environment:set_recur_point('fn', func_var_name ,#node.args)

    while exprs do
      local fence = Compiler.ll_new_node('VARFENCE', extended_environment)
      Compiler.ll_insert_after(node, fence)
      node = fence

      local lisp_node = Compiler.ll_new_node('LISP', extended_environment)
      table.insert(new_dirty_nodes, lisp_node)
      lisp_node.args = { exprs:first() }
      if exprs:next() == nil then
        lisp_node.is_return = true
      end
      Compiler.ll_insert_after(node, lisp_node)
      node = lisp_node

      local endfence = Compiler.ll_new_node('ENDVARFENCE', extended_environment)
      Compiler.ll_insert_after(node, endfence)
      node = endfence

      exprs = exprs:next()
    end

    local end_func_body_node = Compiler.ll_new_node('ENDFUNCBODY', extended_environment)
    Compiler.ll_insert_after(node, end_func_body_node)
    node = end_func_body_node
  end

  if rest_arg_index then
    local rest_args_at_node = Compiler.ll_new_node('RESTARGSAT', orig_node.environment)
    rest_args_at_node.args = {orig_node, rest_arg_index}
    Compiler.ll_insert_after(node, rest_args_at_node)
    node = rest_args_at_node
  end

  local end_func_node = Compiler.ll_new_node('ENDFUNC', orig_node.environment)
  Compiler.ll_insert_after(node, end_func_node)
end

Compiler.op_dispatch = {}
local op_dispatch = Compiler.op_dispatch

op_dispatch['LISP'] = function(node, new_dirty_nodes)
  local datum = node.args[1]
  local mt = getmetatable(datum)
  if mt == PersistentVector then
    local orig_node = node

    node.op = 'NEWVEC'
    node.args = {}

    for i = 0, datum:count() - 1 do
      local arg = datum:get(i)

      local vecadd_node = Compiler.ll_new_node('VECADD', orig_node.environment)
      table.insert(new_dirty_nodes, vecadd_node)
      vecadd_node.args = {orig_node, arg}
      Compiler.ll_insert_after(node, vecadd_node)
      node = vecadd_node
    end
  elseif mt == PersistentHashMap then
    local orig_node = node

    node.op = 'NEWMAP'
    node.args = {}

    local items = datum:seq()
    while items:seq() do
      local kv = items:first()
      local k = kv:get(0)
      local v = kv:get(1)

      local mapadd_node = Compiler.ll_new_node('MAPADD', orig_node.environment)
      table.insert(new_dirty_nodes, mapadd_node)
      mapadd_node.args = {orig_node, k, v}
      Compiler.ll_insert_after(node, mapadd_node)
      node = mapadd_node

      items = items:rest()
    end
  elseif type(datum) == 'table' and datum.first ~= nil then
    --print(tsukuyomi.print(datum))
    --print(util.show(datum))
    local first = datum:first()
    local rest = datum:rest()
    local symbol
    local symbol_name
    if getmetatable(first) == Symbol then
      symbol = first
      symbol_name = tostring(first)
    end

    assert(first ~= nil, 'tsukuyomi.lang.Compiler: attempted to call with a nil function or empty list')

    -- below does not hold, it make actually be another list, which returns a function,
    -- like: ((fn [x] (+ 1 x)) 42)
    -- assert(getmetatable(first) == Symbol)
    if special_forms[symbol_name] then
      special_forms[symbol_name](node, rest, new_dirty_nodes)
      return
    end

    -- check to see if this is actually a macro
    if symbol and not node.environment:has_symbol(symbol) then
      local len = symbol_name:len()
      -- make sure it is not an interop macro
      if symbol_name:sub(1, 1) ~= '.' and symbol_name:sub(len, len) ~= '.' then
        local bound_symbol = tsukuyomi_core['*ns*']:bind_symbol(symbol)
        local var = Var.GetVar(bound_symbol)
        if var == nil then
          local err = {
            'unable to resolve var: ',
            tostring(symbol),
            ' while checking for macro. attemped to retrieve Var ',
            tostring(bound_symbol),
          }
          assert(false, table.concat(err))
        end
        if var:is_macro() then
          local transformed_list = tsukuyomi_core['apply'][2](var:get(), rest)
          Compiler._log('*** MACRO TRANSFORMATION TO ***')
          Compiler._log(tsukuyomi.print(transformed_list))

          node.args[1] = transformed_list
          table.insert(new_dirty_nodes, node)
          return
        end
      end
    end

    if first == kDotSymbol then
      datum = datum:rest()

      local ns = datum:first()
      datum = datum:rest()

      local method = datum:first()
      datum = datum:rest()

      local real_sym = Symbol.intern(method.name, ns.name)
      datum = PersistentList.new(nil, real_sym, datum, 1 + datum:count())

      node.is_direct_function = true
    end

    -- normal function call
    node.op = 'CALL'
    node.args, node.args_length = datum:ToLuaArray()
    table.insert(new_dirty_nodes, node)
  elseif mt == Keyword then
    node.op = 'KEYWORD'
    node.args = {datum}
  else
    local primitive = compile_lua_primitive(datum)
    node.op = 'PRIMITIVE'
    node.args = {primitive}
  end
end

op_dispatch['VECADD'] = function(node, new_dirty_nodes)
  local args = node.args

  local datum = args[2]
  if is_lua_primitive(datum) then
    args[2] = compile_lua_primitive(args[2])
  else
    local var_name = make_unique_var_name('vec_item')
    args[2] = var_name

    local datum_node = Compiler.ll_new_node('NEWLVAR', node.environment)
    datum_node.args = {var_name, datum}

    table.insert(new_dirty_nodes, datum_node)
    Compiler.ll_insert_before(node, datum_node)
  end
end

op_dispatch['MAPADD'] = function(node, new_dirty_nodes)
  local args = node.args

  local datum = args[2]
  if is_lua_primitive(datum) then
    args[2] = compile_lua_primitive(args[2])
  else
    local var_name = make_unique_var_name('map_key')
    args[2] = var_name

    local datum_node = Compiler.ll_new_node('NEWLVAR', node.environment)
    datum_node.args = {var_name, datum}

    table.insert(new_dirty_nodes, datum_node)
    Compiler.ll_insert_before(node, datum_node)
  end

  local datum = args[3]
  if is_lua_primitive(datum) then
    args[3] = compile_lua_primitive(args[3])
  else
    local var_name = make_unique_var_name('map_value')
    args[3] = var_name

    local datum_node = Compiler.ll_new_node('NEWLVAR', node.environment)
    datum_node.args = {var_name, datum}

    table.insert(new_dirty_nodes, datum_node)
    Compiler.ll_insert_before(node, datum_node)
  end
end

op_dispatch['CALL'] = function(node, new_dirty_nodes)
  local args = node.args
  for i = 1, node.args_length do
    if is_lua_primitive(args[i]) then
      args[i] = compile_lua_primitive(args[i])
    else
      local var_node = Compiler.ll_new_node('NEWLVAR', node.environment)
      table.insert(new_dirty_nodes, var_node)

      local var_name = make_unique_var_name('arg')
      var_node.args = {var_name, args[i]}
      args[i] = var_name
      Compiler.ll_insert_before(node, var_node)
    end
  end
end

op_dispatch['NEWLVAR'] = function(node, new_dirty_nodes)
  node.op = 'LISP'
  node.new_lvar_name = node.args[1]
  node.args = {node.args[2]}
  table.insert(new_dirty_nodes, node)
end

-- given a doubly linked list, iteratively process each node until each node
-- has been "cleaned". processing a node usually expands / creates more nodes
-- around it, as the Lisp is being broken into elementary operations.
--
-- by default nodes are dirty, until it has been processed through once.
--
-- nodes are in the form of
-- node = {
--    ['op'] = 'OPCODE',
--    ['args'] = { arg0, arg1, arg2 },
-- }
-- optional fields are:
-- new_lvar_name
-- set_var_name
-- define_symbol
-- is_return
function Compiler.compile_to_ir(datum)
  local head_node = Compiler.ll_new_node('LISP', LexicalEnvironment.new())
  head_node.args = {datum}
  head_node.is_return = true

  -- prepare input nodes by marking them all as dirty
  local dirty_nodes = {}
  local node = head_node
  while node do
    table.insert(dirty_nodes, node)
    node = node.next
  end

  while #dirty_nodes > 0 do
    local new_dirty_nodes = {}
    for i = 1, #dirty_nodes do
      local node = dirty_nodes[i]
      local op = node.op
      op_dispatch[op](node, new_dirty_nodes)
    end
    dirty_nodes = new_dirty_nodes
  end

  -- it is possible that this expansion process has tacked on nodes in front of the head node
  while head_node.prev do
    head_node = head_node.prev
  end

  return head_node
end

function Compiler._debug_ir(node)
  local lines = {}

  while node do
    local line = {}

    if node.is_return then
      table.insert(line, 'RET ')
    end
    if node.new_lvar_name then
      table.insert(line, 'NEWLVAR ')
      table.insert(line, node.new_lvar_name)
      table.insert(line, ' := ')
    end
    if node.set_var_name then
      table.insert(line, 'SETVAR ')
      table.insert(line, node.set_var_name)
      table.insert(line, ' := ')
    end
    if node.define_symbol then
      table.insert(line, 'DEFSYM ')
      table.insert(line, tostring(node.define_symbol))
      table.insert(line, ' := ')
    end

    table.insert(line, node.op)
    table.insert(line, ' ')
    local args = node.args
    if args then
      for i = 1, #args do
        local arg = args[i]
        if node.op == 'LISP' then
          table.insert(line, tsukuyomi.print(arg))
        elseif type(arg) == 'table' and arg.op ~= nil and arg.environment ~= nil then
          table.insert(line, 'NODE(')
          table.insert(line, tostring(arg))
          table.insert(line, ')')
        else
          table.insert(line, tostring(arg))
        end

        if i < #args then
          table.insert(line, ', ')
        end
      end
    end

    assert(node.environment)
    local line_prefix = table.concat(line)
    line = {line_prefix}
    local spacing = 50 - line_prefix:len()
    spacing = math.max(spacing, 1)
    for i = 1, spacing do
      table.insert(line, ' ')
    end
    table.insert(line, tostring(node.environment))

    table.insert(lines, table.concat(line))
    node = node.next
  end

  return table.concat(lines, '\n')
end

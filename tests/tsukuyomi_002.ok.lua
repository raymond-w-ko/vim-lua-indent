-- vim: et sw=2 sts=2 ts=2
local tsukuyomi = tsukuyomi
local Symbol = tsukuyomi.lang.Symbol
local Compiler = tsukuyomi.lang.Namespace.GetNamespaceSpace('tsukuyomi.lang.Compiler')
local Var = tsukuyomi.lang.Var
local Namespace = tsukuyomi.lang.Namespace

local safe_char_map = {
  -- is the below a good idea?
  -- or is the following needed instead?
  --['-'] = '__SUB__',
  --['.'] = '__DOT__',
  ['-'] = '_',
  ['.'] = '_',

  ['+'] = '__ADD__',
  ['*'] = '__MUL__',
  ['/'] = '__DIV__',
  ['?'] = '__QMARK__',
  [':'] = '__COLON__',
}
function Compiler.to_safe_lua_identifier(lisp_name)
  local safe_var = {}
  for i = 1, lisp_name:len() do
    local ch = lisp_name:sub(i, i)
    local safe_ch = safe_char_map[ch]
    safe_ch = safe_ch or ch
    safe_var[i] = safe_ch
  end
  return table.concat(safe_var)
end

local function check_var_exists(bound_symbol)
  local lisp_var_exists = Var.GetVar(bound_symbol)
  local external_var_exists = Namespace.GetExternalNamespace(bound_symbol.namespace)[bound_symbol.name]

  if lisp_var_exists ~= nil or external_var_exists ~= nil then
    return
  end

  local err = {
    'unable to resolve var: ',
    tostring(bound_symbol),
    ' while compiling to Lua',
  }
  assert(false, table.concat(err))
end

local function symbol_to_lua(state, symbol, skip_var_existence_check)
  local code = {}
  local bound_symbol = tsukuyomi.core['*ns*']:bind_symbol(symbol)

  -- var existence check should only be skipped when defining something
  if not skip_var_existence_check then
    check_var_exists(bound_symbol)
  end

  local namespace = bound_symbol.namespace
  if namespace then
    table.insert(code, Compiler.compile_ns(state, namespace))
  end

  table.insert(code, '["')
  table.insert(code, bound_symbol.name)
  table.insert(code, '"]')

  return table.concat(code)
end

local kNilSymbol = Symbol.intern('nil')
local function compile_string_or_symbol(state, datum, environment)
  if type(datum) == 'string' then
    return datum
  elseif datum == kNilSymbol then
    return 'nil'
  elseif getmetatable(datum) == Symbol then
    if environment:has_symbol(datum) then
      return datum.name
    else
      return symbol_to_lua(state, datum)
    end
  else
    assert(false)
  end
end

local function get_bound_var_name(state, obj)
  local name

  if obj.new_lvar_name then
    assert(name == nil)
    name = obj.new_lvar_name
  end
  if obj.define_symbol then
    assert(name == nil)
    name = symbol_to_lua(state, obj.define_symbol, true)
  end
  if obj.set_var_name then
    assert(name == nil)
    name = obj.set_var_name
  end

  assert(name)
  return name
end

function Compiler.compile_ns(state, ns)
  local identifier = '__NS__' .. Compiler.to_safe_lua_identifier(ns)
  if not state.seen_namespaces[ns] then
    table.insert(state.seen_namespaces_list, {identifier, ns})
    state.seen_namespaces[ns] = true
  end
  return identifier
end

function Compiler.compile_symbol(state, symbol)
  local full_symbol_name = tostring(symbol)
  local identifier = '__SYM__' .. Compiler.to_safe_lua_identifier(full_symbol_name)
  if not state.seen_symbols[full_symbol_name] then
    table.insert(state.seen_symbols_list, {identifier, {symbol.name, symbol.namespace}})
    state.seen_namespaces[full_symbol_name] = true
  end
  return identifier
end

function Compiler.compile_keyword(state, keyword)
  local full_keyword_name = tostring(keyword)
  local identifier = '__KEYWORD__' .. Compiler.to_safe_lua_identifier(full_keyword_name)
  if not state.seen_keywords[full_keyword_name] then
    table.insert(state.seen_keywords_list,
                 {identifier, Compiler.compile_symbol(state, keyword.sym)})
    state.seen_namespaces[full_keyword_name] = true
  end
  return identifier
end

function Compiler.compile_data(state, data)
  local var_name = Compiler.make_unique_var_name('data')
  local data_str = string.format('%q', tsukuyomi.core['pr-str'][1](data))
  table.insert(state.data_list, {var_name, data_str})
  return var_name
end

function Compiler.compile_to_lua(ir_list)
  local lines = {}

  local state = {
    indent = 0,

    seen_namespaces = {},
    seen_namespaces_list = {},

    seen_symbols = {},
    seen_symbols_list = {},

    seen_keywords = {},
    seen_keywords_list = {},

    data_list = {},
  }

  local insn = ir_list
  local line = {}
  local function emit(...)
    local t = {...}
    for _, text in ipairs(t) do
      assert(text)
      table.insert(line, text)
    end
  end
  while insn do
    -- IR instructions can be tagged in the following fashion to signal
    -- variable definition, or returning
    if insn.new_lvar_name then
      emit('local ', insn.new_lvar_name, ' = ')
    elseif insn.set_var_name then
      emit(insn.set_var_name, ' = ')
    elseif insn.define_symbol then
      emit(symbol_to_lua(state, insn.define_symbol, true), " = ")
    elseif insn.is_return then
      emit('return ')
    end

    if insn.op == 'NOP' then
      -- pass
    elseif insn.op == 'EMPTYVAR' then
      emit('local ', insn.args[1])
    elseif insn.op == 'NS' then
      emit('tsukuyomi.lang.Namespace.SetActiveNamespace("')
      emit(insn.args[1].name)
      emit('"); ')
    elseif insn.op == 'PRIMITIVE' then
      emit(compile_string_or_symbol(state, insn.args[1], insn.environment))
    elseif insn.op == 'RAW' then
      emit(insn.args[1])
    elseif insn.op == 'DATA' then
      emit(Compiler.compile_data(state, insn.args[1]))
    elseif insn.op == 'CALL' then
      local args = insn.args

      local fn = insn.args[1]
      assert(getmetatable(fn) == Symbol or type(fn) == 'string')
      local name_len
      if getmetatable(fn) == Symbol then
        name_len = fn.name:len()
      elseif type(fn) == 'string' then
        name_len = fn:len()
      end
      -- does this always hold true?

      local arg_start_index = 2

      if getmetatable(fn) == Symbol and fn.namespace == nil and fn.name:sub(1, 1) == '.' then
        -- object oriented function call
        -- (method_name object arg0 arg1)
        emit(compile_string_or_symbol(state, args[2], insn.environment))
        emit(':')
        emit(fn.name:sub(2))

        arg_start_index = 3
      elseif getmetatable(fn) == Symbol and fn.name:sub(name_len, name_len) == '.' then
        -- new style constructor call
        -- (PersistentHashMap.)
        local real_sym = Symbol.intern(args[1].name:sub(1, name_len - 1), args[1].namespace)
        emit(compile_string_or_symbol(state, args[2], insn.environment))
        emit('.new')
      else
        emit(compile_string_or_symbol(state, fn, insn.environment))
        local arity = #args - 1
        if not insn.is_direct_function then
          emit('[', tostring(math.min(arity, 21)), ']')
        end
      end

      emit('(')
      local stray_args_max_bounds = math.min(20 + 1, #args)
      for i = arg_start_index, stray_args_max_bounds do
        emit(compile_string_or_symbol(state, args[i], insn.environment))
        if i < stray_args_max_bounds then
          emit(', ')
        end
      end
      if #args > 21 then
        emit(', ')
        emit(Compiler.compile_ns(state, 'tsukuyomi.lang.ArraySeq'))
        emit('.new(nil, {')
        for i = 21 + 1, #args do
          emit(compile_string_or_symbol(state, args[i], insn.environment))
          if i < #args then
            emit(', ')
          end
        end
        emit('}, 1, ')
        emit(tostring(#args - 20 - 1))
        emit( ')')
      end
      emit( ')')
    elseif insn.op == 'FUNC' then
      emit(Compiler.compile_ns(state,  'tsukuyomi.lang.Function'))
      emit('.new()')
    elseif insn.op == 'FUNCBODY' then
      local arity = #insn.args
      emit(get_bound_var_name(state, insn.parent))
      emit('[', tostring(arity), ']')
      emit(' = function ')
      emit('(')
      for i = 1, #insn.args do
        local arg_name = insn.args[i]
        emit(arg_name)
        if i < #insn.args then emit(', ') end
      end
      emit(')')
    elseif insn.op == 'RESTARGSAT' then
      local args = insn.args

      emit(Compiler.compile_ns(state,  'tsukuyomi.lang.Function'))
      emit('.make_functions_for_rest(')

      emit(get_bound_var_name(state, args[1]))

      emit(', ')
      emit(insn.args[2])
      emit(')')
    elseif insn.op == 'ENDFUNCBODY' then
      emit('end')
      state.indent = state.indent - 1
    elseif insn.op == 'ENDFUNC' then
      -- pass
    elseif insn.op == 'IF' then
      emit('if ', insn.args[1], ' then')
    elseif insn.op == 'ELSE' then
      state.indent = state.indent - 1
      emit('else')
    elseif insn.op == 'ENDIF' then
      state.indent = state.indent - 1
      emit('end')
    elseif insn.op == 'VARFENCE' then
      emit('do')
    elseif insn.op == 'ENDVARFENCE' then
      emit('end')
      state.indent = state.indent - 1
    elseif insn.op == 'INTERNVAR' then
      emit(Compiler.compile_ns(state, 'tsukuyomi.lang.Var'))
      emit('.intern(')
      emit(Compiler.compile_data(state, insn.args[1]))
      emit('):set_metadata(')
      emit(Compiler.compile_data(state, insn.args[2]))
      emit(')')
    elseif insn.op == 'GETVAR' then
      emit(Compiler.compile_ns(state, 'tsukuyomi.lang.Var'))
      emit('.GetVar(')
      emit(Compiler.compile_data(state, insn.args[1]))
      emit(')')
    elseif insn.op == 'NEWVEC' then
      emit(Compiler.compile_ns(state,  'tsukuyomi.lang.PersistentVector'))
      emit('.new()')
    elseif insn.op == 'VECADD' then
      local vec = insn.args[1]
      local datum = insn.args[2]
      local vec_name = get_bound_var_name(state, vec)
      emit(vec_name)
      emit(' = ')
      emit(vec_name)
      emit(':conj(')
      emit(compile_string_or_symbol(state, insn.args[2], insn.environment))
      emit(')')
    elseif insn.op == 'NEWMAP' then
      emit(Compiler.compile_ns(state,  'tsukuyomi.lang.PersistentHashMap'))
      emit('.new()')
    elseif insn.op == 'MAPADD' then
      local map = insn.args[1]
      local k = insn.args[2]
      local v = insn.args[3]
      local map_name = get_bound_var_name(state, map)
      emit(map_name)
      emit(' = ')
      emit(map_name)
      emit(':assoc(')
      emit(compile_string_or_symbol(state, insn.args[2], insn.environment))
      emit(', ')
      emit(compile_string_or_symbol(state, insn.args[3], insn.environment))
      emit(')')
    elseif insn.op == 'KEYWORD' then
      emit(Compiler.compile_keyword(state, insn.args[1]))
    else
      print('unknown opcode: ' .. insn.op)
      assert(false)
    end

    if #line > 0 then
      for i = 1, state.indent do
        table.insert(line, 1, '\t')
      end
      table.insert(lines, table.concat(line))
      line = {}
    end

    -- state.indent change after line is generated
    if insn.op == 'FUNCBODY' then
      state.indent = state.indent + 1
    elseif insn.op == 'IF' then
      state.indent = state.indent + 1
    elseif insn.op == 'ELSE' then
      state.indent = state.indent + 1
    elseif insn.op == 'VARFENCE' then
      state.indent = state.indent + 1
    end

    insn = insn.next
  end

  local body = table.concat(lines, '\n')

  local final = {}

  table.insert(final, 'local tsukuyomi = _G.tsukuyomi')
  table.insert(final, '')

  -- write out seen namespaces
  for i = 1, #state.seen_namespaces_list do
    local pair = state.seen_namespaces_list[i]
    local line = {}
    table.insert(line, 'local ')
    table.insert(line, pair[1])
    table.insert(line, ' = tsukuyomi.lang.Namespace.GetNamespaceSpace("')
    table.insert(line, pair[2])
    table.insert(line, '")')
    table.insert(final, table.concat(line))
  end
  table.insert(final, '')

  -- write out seen symbols
  for i = 1, #state.seen_symbols_list do
    local pair = state.seen_symbols_list[i]
    local symbol = pair[2]
    local line = {}
    table.insert(line, 'local ')
    table.insert(line, pair[1])
    table.insert(line, ' = tsukuyomi.lang.Symbol.intern(')
    table.insert(line, string.format('%q', symbol[1]))
    table.insert(line, '')
    if symbol[2] then
      table.insert(line, ', ')
      table.insert(line, string.format('%q', symbol[2]))
    end
    table.insert(line, ')')
    table.insert(final, table.concat(line))
  end
  table.insert(final, '')

  -- write out seen keywords
  for i = 1, #state.seen_keywords_list do
    local pair = state.seen_keywords_list[i]
    local line = {}
    table.insert(line, 'local ')
    table.insert(line, pair[1])
    table.insert(line, ' = tsukuyomi.lang.Keyword.intern(')
    table.insert(line, pair[2])
    table.insert(line, ')')
    table.insert(final, table.concat(line))
  end
  table.insert(final, '')

  -- write out data
  for i = 1, #state.data_list do
    local pair = state.data_list[i]
    local line = {}
    table.insert(line, 'local ')
    table.insert(line, pair[1])
    table.insert(line, ' = tsukuyomi.core.read[1](')
    table.insert(line, pair[2])
    table.insert(line, ')')
    table.insert(final, table.concat(line))
  end
  table.insert(final, '')

  table.insert(final, body)

  return table.concat(final, '\n')
end

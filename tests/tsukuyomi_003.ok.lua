-- vim: et sw=2 sts=2 ts=2
local tsukuyomi = tsukuyomi

local dispatch = {
  nil, nil, nil, nil,
  nil, nil, nil, nil,
  nil, nil, nil, nil,
  nil, nil, nil, nil,
  nil, nil, nil, nil,
}

dispatch[0 + 1] = function(fn, arglist)
  return fn()
end

dispatch[1 + 1] = function(fn, arglist)
  return fn(arglist.first())
end

dispatch[2 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2)
end

dispatch[3 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3)
end

dispatch[4 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4)
end

dispatch[5 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5)
end

dispatch[6 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6)
end

dispatch[7 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7)
end

dispatch[8 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
end

dispatch[9 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
end

dispatch[10 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10)
end

dispatch[11 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11)
end

dispatch[12 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  local arg11 = arglist:first(); arglist = arglist:next();
  local arg12 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11, arg12)
end

dispatch[13 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  local arg11 = arglist:first(); arglist = arglist:next();
  local arg12 = arglist:first(); arglist = arglist:next();
  local arg13 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11, arg12, arg13)
end

dispatch[14 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  local arg11 = arglist:first(); arglist = arglist:next();
  local arg12 = arglist:first(); arglist = arglist:next();
  local arg13 = arglist:first(); arglist = arglist:next();
  local arg14 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11, arg12, arg13, arg14)
end

dispatch[15 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  local arg11 = arglist:first(); arglist = arglist:next();
  local arg12 = arglist:first(); arglist = arglist:next();
  local arg13 = arglist:first(); arglist = arglist:next();
  local arg14 = arglist:first(); arglist = arglist:next();
  local arg15 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11, arg12, arg13, arg14, arg15)
end

dispatch[16 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  local arg11 = arglist:first(); arglist = arglist:next();
  local arg12 = arglist:first(); arglist = arglist:next();
  local arg13 = arglist:first(); arglist = arglist:next();
  local arg14 = arglist:first(); arglist = arglist:next();
  local arg15 = arglist:first(); arglist = arglist:next();
  local arg16 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11, arg12, arg13, arg14, arg15, arg16)
end

dispatch[17 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  local arg11 = arglist:first(); arglist = arglist:next();
  local arg12 = arglist:first(); arglist = arglist:next();
  local arg13 = arglist:first(); arglist = arglist:next();
  local arg14 = arglist:first(); arglist = arglist:next();
  local arg15 = arglist:first(); arglist = arglist:next();
  local arg16 = arglist:first(); arglist = arglist:next();
  local arg17 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11, arg12, arg13, arg14, arg15, arg16, arg17)
end

dispatch[18 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  local arg11 = arglist:first(); arglist = arglist:next();
  local arg12 = arglist:first(); arglist = arglist:next();
  local arg13 = arglist:first(); arglist = arglist:next();
  local arg14 = arglist:first(); arglist = arglist:next();
  local arg15 = arglist:first(); arglist = arglist:next();
  local arg16 = arglist:first(); arglist = arglist:next();
  local arg17 = arglist:first(); arglist = arglist:next();
  local arg18 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18)
end

dispatch[19 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  local arg11 = arglist:first(); arglist = arglist:next();
  local arg12 = arglist:first(); arglist = arglist:next();
  local arg13 = arglist:first(); arglist = arglist:next();
  local arg14 = arglist:first(); arglist = arglist:next();
  local arg15 = arglist:first(); arglist = arglist:next();
  local arg16 = arglist:first(); arglist = arglist:next();
  local arg17 = arglist:first(); arglist = arglist:next();
  local arg18 = arglist:first(); arglist = arglist:next();
  local arg19 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19)
end

dispatch[20 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  local arg11 = arglist:first(); arglist = arglist:next();
  local arg12 = arglist:first(); arglist = arglist:next();
  local arg13 = arglist:first(); arglist = arglist:next();
  local arg14 = arglist:first(); arglist = arglist:next();
  local arg15 = arglist:first(); arglist = arglist:next();
  local arg16 = arglist:first(); arglist = arglist:next();
  local arg17 = arglist:first(); arglist = arglist:next();
  local arg18 = arglist:first(); arglist = arglist:next();
  local arg19 = arglist:first(); arglist = arglist:next();
  local arg20 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20)
end


dispatch[21 + 1] = function(fn, arglist)
  local arg1 = arglist:first(); arglist = arglist:next();
  local arg2 = arglist:first(); arglist = arglist:next();
  local arg3 = arglist:first(); arglist = arglist:next();
  local arg4 = arglist:first(); arglist = arglist:next();
  local arg5 = arglist:first(); arglist = arglist:next();
  local arg6 = arglist:first(); arglist = arglist:next();
  local arg7 = arglist:first(); arglist = arglist:next();
  local arg8 = arglist:first(); arglist = arglist:next();
  local arg9 = arglist:first(); arglist = arglist:next();
  local arg10 = arglist:first(); arglist = arglist:next();
  local arg11 = arglist:first(); arglist = arglist:next();
  local arg12 = arglist:first(); arglist = arglist:next();
  local arg13 = arglist:first(); arglist = arglist:next();
  local arg14 = arglist:first(); arglist = arglist:next();
  local arg15 = arglist:first(); arglist = arglist:next();
  local arg16 = arglist:first(); arglist = arglist:next();
  local arg17 = arglist:first(); arglist = arglist:next();
  local arg18 = arglist:first(); arglist = arglist:next();
  local arg19 = arglist:first(); arglist = arglist:next();
  local arg20 = arglist:first(); arglist = arglist:next();
  return fn(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10,
            arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20,
            arglist)
end

--local MoreArgsMetatable = {}
--MoreArgsMetatable.__index = function() return more_args_fn end
--setmetatable(dispatch, MoreArgsMetatable)

local function apply(fn, arglist)
  -- Lua proper's table's array part first slot is 1, so add 1 to make sure
  -- everything is an array part index.
  local count = math.min(21, arglist:count())
  return dispatch[count + 1](fn[count], arglist)
end

tsukuyomi.core._apply = tsukuyomi.lang.Function.new()
tsukuyomi.core._apply[2] = apply

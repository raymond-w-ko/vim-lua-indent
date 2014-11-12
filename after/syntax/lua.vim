" LuaJIT BitOp functions by Mike Pall
"
" Rationale: LuaJIT is fairly popular among Lua users due to the speed
" increases provided by the JIT compiler. I don't see why this shouldn't be
" included. These fit in the spirit of basic language ops anyways.
"
if lua_version > 5 || (lua_version == 5 && lua_subversion >= 1)
  syn match   luaFunc /\<bit\.tobit\>/
  syn match   luaFunc /\<bit\.tohex\>/
  syn match   luaFunc /\<bit\.bnot\>/
  syn match   luaFunc /\<bit\.band\>/
  syn match   luaFunc /\<bit\.bor\>/
  syn match   luaFunc /\<bit\.bxor\>/
  syn match   luaFunc /\<bit\.lshift\>/
  syn match   luaFunc /\<bit\.rshift\>/
  syn match   luaFunc /\<bit\.arshift\>/
  syn match   luaFunc /\<bit\.rol\>/
  syn match   luaFunc /\<bit\.ror\>/
  syn match   luaFunc /\<bit\.bswap\>/
end

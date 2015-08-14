-- tries to fool the indenter by having ( in the comments

-- foo(
-- this should not be indented, since the above is meaningless

if true then
    local a = [[
here is how to call a Lua function:
....lua_func(arg1,]]
    foo()
end

if valid then
    emit("(")
    save()
end

if valid then
    emit('(')
    save()
end

if valid then
    emit("\"(")
    save()
end

if valid then
    emit('\'(')
    save()
end

-- vim: et sw=4 sts=4 ts=4

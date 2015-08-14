function foo(
    long_variable_name,
    stuf)
    b = {}
end

function foo(bar)
    if (something) then
        a:stuff()
    end
end

function foo(bar)
    func2(handle, self:get_my_handle(),
          foo, bar, baz, fizz, buzz)
end

function foo(bar)
    function1(something, bit.bor(1, 2, 4, 8),
              some_var)
end

function foo(bar)
    function1(
        something,
        bit.bor(1, 2, 4, 8),
        some_var)
end

function foo(bar)
    function1(
        bit.bor(1, 2, 4, 8),
        something,
        some_var)
end

function ClassName:FunctionName(VariableName)
    local var = func1(something, something2)
    if (something ~= something_else) then
        return Find(VariableName, "text", more_stuff)
    end
    return -1
end

-- vim: et sw=4 sts=4 ts=4

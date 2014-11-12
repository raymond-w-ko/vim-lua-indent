function foo(bar)
    if (something) then
        a:stuff()
    end
end

function foo(bar)
    a = {
        stuff,
        stasdtas,
        asdf
    }
    if (something) then
        a:stuff()
    end
end

function foo(long_variable_name,
             longer_variable_name,
             bar)
    if (stuff) then
        more_stuff()
    end
end

function foo(long_variable_name,
             longer_variable_name,
             bar)
    if (very_very_very_long_condition,
        more_things,
        even_more_things) then
        more_stuff()
    end
end

function foo(long_variable_name,
             longer_variable_name,
             bar)
    if (some_function(arg1,
                      arg2)) then
        foobar(arg1)
    end
end

function foo(
    long_variable_name,
    stuf)
    if (stuff) then
        more_stuff()
    end
    b = {}
end

function foo(bar)
    a = {}
end

function foo(bar)
    a = {
        stuff,
        stasdtas,
        asdf
    }
end

function foo(long_variable_name,
             longer_variable_name,
             bar)
    stuff
end

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

function ClassName:FunctionName(VariableName)
    local var = func1(something, something2)
    if (something ~= something_else) then
        return Find(VariableName, "text", more_stuff)
    end
    return -1
end

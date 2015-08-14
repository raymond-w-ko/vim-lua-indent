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
    if (fn(very_very_very_long_condition,
           more_things,
           even_more_things)) then
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

-- vim: et sw=4 sts=4 ts=4

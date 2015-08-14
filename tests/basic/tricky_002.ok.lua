setTimeout(function()
    if condition == true then
        return 1
    end
end, 1000)

if condition == true then
    setTimeout(function()
        if condition == true then
            return 1
        end
    end, 1000)
end
-- vim: et sw=4 sts=4 ts=4

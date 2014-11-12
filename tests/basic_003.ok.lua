if foo then
    bar()
end

for k, v in pairs(t) do
    bar()
end

while true do
    bar()
end

while foo() do
    bar()
end

if foo then
    bar()
elseif true then
    fizz()
end

if foo then
    bar()
elseif true then
    fizz()
elseif true then
    buzz()
end

do
    stuff()
end

repeat
    download()
until disk_full()

-- vim: et sw=4 sts=4 ts=4

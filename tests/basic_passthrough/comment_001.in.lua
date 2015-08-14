-- basically a test to make sure it doesn't touch indents inside comments
local comment = [[
asdf
 foobar
  fizzbuzz
   quux
    42
     slide]]

local comment = [[
 asdf
  foobar
 fizzbuzz
   quux
 42
slide]]

local comment = [[
     asdf
    foobar
   fizzbuzz
  quux
 42
slide]]

if condition == true then
    local comment = [[
 asdf
foobar
   fizzbuzz
 quux
42]]
    more_computation()
end

local a = "asdf"

--asdf

--[[
 asdf
  foobar
 fizzbuzz
   quux
 42
slide]]


-- vim: et sw=4 sts=4 ts=4

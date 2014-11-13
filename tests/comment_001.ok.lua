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

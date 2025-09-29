local dir = (debug.getinfo(1, "S").source:match("@(.*/)") or "./")
package.cpath = dir .. "?.so;" .. package.cpath

local p301 = require("p301")

-- demo
local t = {1, 2, 3, 4, 5, 6}
local evens = p301.filter(t, function(x)
  return x % 2 == 0
end)

for i, v in ipairs(evens) do
  print(i, v)
end



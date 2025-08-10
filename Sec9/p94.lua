dofile("geometry.lua")
local c1 = Disk(0, 0, 1)
Plot(Difference(c1, Translate(c1, -0.3, 0)), 50, 50)
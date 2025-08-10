local function calpoly(t, x)
    local res, P = 0, 1
    for i = 1, #t do
        res = res + t[i] * P
        P = P * x
    end
    return res
end

local t = {1, 2, 3, 4, 5}
local x = 2
print(calpoly(t, x))
local function returnExcept1st(t)
    local res = {}
    for i = 2, #t do
        res[i-1] = t[i]
    end
    return res
end

local function calCombination(t)

    if #t < 2 then
        return t
    end
    local res = calCombination(returnExcept1st(t))

    for i = 1, #res do
        table.insert(res, t[1]..res[i])
    end
    return res
end

local res = calCombination({1, 2, 3, 4, 5})
for _, v in ipairs(res) do
    io.write(v .. " ")
end
print()

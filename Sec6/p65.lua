local function calCombination(t)
    if #t < 1 then
        return {""}
    end
    local first = table.remove(t, 1)
    local res = calCombination(t)
    for i = 1, #res do
        table.insert(res, first..res[i])
    end
    return res
end

local res = calCombination({1, 2, 3, 4, 5})
for _, v in ipairs(res) do
    io.write(v .. " ")
end
print()

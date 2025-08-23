local Set = {}
function Set.new(l)
    local set = {}
    for _, v in ipairs(l) do set[v] = true end
    return setmetatable(set, {__sub = Set.__sub})
end

function Set.__sub(a, b)
    local res = Set.new{}
    for k in pairs(a) do
        if not b[k] then
            res[k] = true
        end
    end
    return res
end

local s1 = Set.new{1, 2, 3, 5, 7}
local s2 = Set.new{2, 4, 6, 8}
local s3 = s1 - s2
for k in pairs(s3) do
    io.write(k, " ")
end
local Set = {}

function Set.new(l)
    local set = {}
    for _, v in ipairs(l) do set[v] = true end
    return setmetatable(set, {__len = Set.__len})
end

function Set:__len()
    local cnt = 0
    for _, v in pairs(self) do
        cnt = cnt + 1 
    end
    return cnt
end

local s = Set.new{1, 2, 3, 5, 7}
print(#s)
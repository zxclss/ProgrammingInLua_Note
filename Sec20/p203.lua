local readOnlyMT = {
    __index = function(proxy, key)
        local originalTable = getmetatable(proxy).__original
        return originalTable[key]
    end,
    __newindex = function (t, k, v)
        error("attempt to update a read-only table", 2)
    end
}

function readOnlyShared (t)
    local proxy = {}
    local mt = {
        __index = readOnlyMT.__index,
        __newindex = readOnlyMT.__newindex,
        __original = t  -- 保存原始表的引用
    }
    setmetatable(proxy, mt)
    return proxy
end

-- 创建只读表
days3 = readOnlyShared{"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}
months = readOnlyShared{"January", "February", "March", "April", "May", "June"}

print(days3[1])
print(months[1])
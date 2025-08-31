print("=== 测试程序出错退出时的__gc行为 ===")
o = {x = "错误退出对象"}
setmetatable(o, { __gc = function (o) print("__gc执行: " .. o.x) end})
o = nil
print("程序即将出错退出...")

-- 故意制造一个错误
local function cause_error()
    local t = {}
    return t.nonexistent_field.nonexistent_method()
end

cause_error()
print("这行不会执行") 
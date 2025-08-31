print("=== 测试1: 正常垃圾收集 ===")
o1 = {x = "对象1"}
setmetatable(o1, { __gc = function (o) print("__gc执行: " .. o.x) end})
o1 = nil
print("调用collectgarbage()...")
collectgarbage()
print("垃圾收集完成")

print("\n=== 测试2: 程序正常退出（不调用垃圾收集）===")
o2 = {x = "对象2"}
setmetatable(o2, { __gc = function (o) print("__gc执行: " .. o.x) end})
o2 = nil
print("程序即将退出，没有调用collectgarbage()")

print("\n=== 测试3: 使用os.exit()退出 ===")
o3 = {x = "对象3"}
setmetatable(o3, { __gc = function (o) print("__gc执行: " .. o.x) end})
o3 = nil
print("调用os.exit()...")
os.exit(0)

print("这行不会执行") 
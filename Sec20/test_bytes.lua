-- 引入修正后的函数
dofile("p204.lua")

print("=== 按字节操作文件测试 ===")

-- 直接创建文件操作对象
local file_obj = fileAsArray("test_bytes.txt")

-- 读取文件内容
print("\n1. 读取文件字节:")
for i = 1, 13 do
    local byte_val = file_obj[i]
    if byte_val then
        local char = string.char(byte_val)
        print(string.format("位置 %d: 字节值 %d, 字符 '%s'", i, byte_val, char))
    else
        print(string.format("位置 %d: 超出文件范围", i))
        break
    end
end

-- 修改字节
print("\n2. 修改第7个字节 (逗号改为感叹号):")
print("修改前第7个字节:", file_obj[7], "字符:", string.char(file_obj[7] or 0))
file_obj[7] = string.byte("!")
print("修改后第7个字节:", file_obj[7], "字符:", string.char(file_obj[7]))

-- 验证修改
print("\n3. 验证修改结果:")
local f = io.open("test_bytes.txt", "r")
local content = f:read("*a")
f:close()
print("文件内容:", content)

-- 关闭文件
print("\n4. 关闭文件句柄")
getmetatable(file_obj).__close(file_obj)

print("\n=== 正确的按字节操作要点 ===")
print("1. 使用 'r+b' 模式打开文件（读写二进制）")
print("2. 使用 file:seek('set', position-1) 定位到字节位置")
print("3. 使用 file:read(1) 读取单个字节")
print("4. 使用 string.byte() 将字符转为字节值")
print("5. 使用 string.char() 将字节值转为字符")
print("6. 使用 file:flush() 确保写入") 
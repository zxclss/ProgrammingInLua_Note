if not arg[1] then
    print("用法: lua p137.lua <二进制文件名>")
    os.exit(1)
end

local file = io.open(arg[1], "rb")
if not file then
    print("错误: 无法打开文件 " .. arg[1])
    os.exit(1)
end

local sum = 0.0
local record_count = 0
-- 记录结构大小计算 (考虑内存对齐):
-- int x: 4 字节 (偏移0-3)
-- char[3] code: 3 字节 (偏移4-6)
-- padding: 1 字节 (偏移7, 为float对齐)
-- float value: 4 字节 (偏移8-11)
-- 结构体末尾对齐: 4 字节 (总大小必须是4的倍数)
-- 总计: 16 字节每个记录
local RECORD_SIZE = 16

print("开始读取二进制文件: " .. arg[1])

while true do
    local record_data = file:read(RECORD_SIZE)
    
    if not record_data or #record_data < RECORD_SIZE then
        break
    end
    
    local x = string.unpack("<i4", record_data, 1)
    
    local code = string.sub(record_data, 5, 7)
    
    local value = string.unpack("<f", record_data, 9)
    
    sum = sum + value
    record_count = record_count + 1
    
    print(string.format("记录 %d: x=%d, code='%s', value=%.6f", 
                       record_count, x, code, value))
end

file:close()

print(string.format("\n总计读取 %d 条记录", record_count))
print(string.format("value字段总和: %.6f", sum))
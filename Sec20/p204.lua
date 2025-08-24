function fileAsArray (filename)
    local file = io.open(filename, "r+b")  -- 修正：使用读写二进制模式
    if not file then
        -- 如果文件不存在，尝试创建
        file = io.open(filename, "w+b")
        if not file then
            error("cannot open file: " .. filename)
        end
    end

    local proxy = {}
    local mt = {
        __index = function (table, key)
            if type(key) ~= "number" or key < 1 then
                error("invalid index: " .. tostring(key))
            end
            
            file:seek("set", key - 1)  -- 修正：定位到指定字节位置
            local byte = file:read(1)  -- 修正：只读取一个字节
            if byte then
                return string.byte(byte)  -- 修正：返回字节值而不是字符
            else
                return nil  -- 超出文件范围
            end
        end,
        __newindex = function (table, key, value)
            if type(key) ~= "number" or key < 1 then
                error("invalid index: " .. tostring(key))
            end
            if type(value) ~= "number" or value < 0 or value > 255 then
                error("invalid byte value: " .. tostring(value))
            end
            
            file:seek("set", key - 1)  -- 修正：定位到指定字节位置
            file:write(string.char(value))  -- 修正：写入单个字节
            file:flush()  -- 确保写入到磁盘
        end,
        __close = function (table)
            file:close()
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

-- 创建一个测试文件
local testFile = "test_bytes.txt"
local f = io.open(testFile, "w")
f:write("Hello, World!")
f:close()

-- 测试按字节操作
local file = fileAsArray(testFile)
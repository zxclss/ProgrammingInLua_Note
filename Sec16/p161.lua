loadwithprefix = function (prefix)
    return function (chunk, chunkname)
        -- 检查chunk的类型
        if type(chunk) == "string" then
            -- 字符串形式：直接拼接前缀和代码段
            local code = chunk .. "\n" .. prefix
            local fn, err = loadstring(code, chunkname)
            if not fn then 
                error(err) 
            end
            return fn()
        elseif type(chunk) == "function" then
            -- reader函数形式：需要读取所有内容后再拼接前缀
            local parts = {}
            local part = chunk()
            while part do
                table.insert(parts, part)
                part = chunk()
            end
            local code = table.concat(parts) .. "\n" .. prefix
            local fn, err = loadstring(code, chunkname)
            if not fn then 
                error(err) 
            end
            return fn()
        else
            error("chunk must be a string or function")
        end
    end
end

-- 测试示例1：字符串形式
print("=== 测试字符串形式 ===")
local f = loadwithprefix("print('hello from ' .. name)")
f("name = 'Lua'")

-- 测试示例2：reader函数形式
print("=== 测试reader函数形式 ===")
local function createReader(str)
    local sent = false
    return function()
        if not sent then
            sent = true
            return str
        else
            return nil
        end
    end
end

local reader = createReader("name = 'Reader Function'")
local g = loadwithprefix("print('hello from ' .. name)")
g(reader)

-- 测试示例3：更复杂的reader函数（按行读取）
print("=== 测试按行读取的reader函数 ===")
local function lineReader(lines)
    local index = 1
    return function()
        if index <= #lines then
            local line = lines[index]
            index = index + 1
            return line .. "\n"
        else
            return nil
        end
    end
end

local multiLineReader = lineReader({
    "local x = 10",
    "local y = 20",
    "name = 'Multi-line Code'"
})
local h = loadwithprefix("print('Result: ' .. (x + y) .. ', hello from ' .. name)")
h(multiLineReader)

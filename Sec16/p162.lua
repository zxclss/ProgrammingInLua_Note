multiload = function(...)
    local args = {...}
    local parts = {}
    
    -- 处理每个参数
    for i, arg in ipairs(args) do
        if type(arg) == "string" then
            -- 字符串直接添加
            table.insert(parts, arg)
        elseif type(arg) == "function" then
            -- 迭代器函数：读取所有内容
            local content = arg()
            while content do
                table.insert(parts, content)
                content = arg()
            end
        else
            error("Argument " .. i .. " must be a string or function, got " .. type(arg))
        end
    end
    
    -- 连接所有部分成完整代码
    local code = table.concat(parts)
    
    -- 编译代码
    local fn, err = loadstring(code)
    if not fn then
        error("Failed to compile code: " .. err)
    end
    
    return fn
end

f = multiload("local x = 10;",
              io.lines("temp", "*L"),
              " print(x)")
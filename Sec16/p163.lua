stringrep = function(s, n)
    local r = ""
    if n > 0 then
        while n > 1 do
            if n % 2 ~= 0 then r = r .. s end
            s = s .. s
            n = math.floor(n / 2)
        end
        r = r .. s
    end
    return r
end

-- 为指定的n生成特定版本的stringrep_n函数
function make_stringrep_n(n)
    if n <= 0 then
        -- 对于n <= 0的情况，返回空字符串
        local code = [[
            return function(s)
                return ""
            end
        ]]
        return load(code)()
    end
    
    -- 生成指令序列
    local instructions = {}
    local temp_n = n
    local step = 0
    
    -- 分析n的二进制表示，生成对应的指令序列
    while temp_n > 1 do
        if temp_n % 2 ~= 0 then
            table.insert(instructions, string.format("r = r .. s%d", step))
        end
        table.insert(instructions, string.format("s%d = s%d .. s%d", step + 1, step, step))
        temp_n = math.floor(temp_n / 2)
        step = step + 1
    end
    
    -- 最后总是需要添加最终的s
    table.insert(instructions, string.format("r = r .. s%d", step))
    
    -- 构造函数代码
    local code_parts = {
        "return function(s)",
        "    local r = \"\"",
        string.format("    local s0 = s")
    }
    
    -- 添加所有指令
    for _, instruction in ipairs(instructions) do
        table.insert(code_parts, "    " .. instruction)
    end
    
    table.insert(code_parts, "    return r")
    table.insert(code_parts, "end")
    
    local code = table.concat(code_parts, "\n")
    
    -- 使用load生成函数
    return load(code)()
end

-- 测试函数
function test_stringrep_generators()
    print("Testing stringrep generators:")
    
    local test_cases = {1, 2, 3, 4, 5, 8, 10, 16}
    local test_string = "ab"
    
    for _, n in ipairs(test_cases) do
        local generated_func = make_stringrep_n(n)
        local original_result = stringrep(test_string, n)
        local generated_result = generated_func(test_string)
        
        print(string.format("n=%d: original='%s', generated='%s', match=%s", 
              n, original_result, generated_result, tostring(original_result == generated_result)))
    end
end

-- 显示生成的代码示例
function show_generated_code(n)
    print(string.format("\nGenerated code for n=%d:", n))
    
    if n <= 0 then
        print([[
            return function(s)
                return ""
            end
        ]])
        return
    end
    
    local instructions = {}
    local temp_n = n
    local step = 0
    
    while temp_n > 1 do
        if temp_n % 2 ~= 0 then
            table.insert(instructions, string.format("r = r .. s%d", step))
        end
        table.insert(instructions, string.format("s%d = s%d .. s%d", step + 1, step, step))
        temp_n = math.floor(temp_n / 2)
        step = step + 1
    end
    
    table.insert(instructions, string.format("r = r .. s%d", step))
    
    local code_parts = {
        "return function(s)",
        "    local r = \"\"",
        string.format("    local s0 = s")
    }
    
    for _, instruction in ipairs(instructions) do
        table.insert(code_parts, "    " .. instruction)
    end
    
    table.insert(code_parts, "    return r")
    table.insert(code_parts, "end")
    
    print(table.concat(code_parts, "\n"))
end
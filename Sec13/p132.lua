-- 计算Lua语言中整型数所占用位数的方法
-- Programming in Lua 第13章示例

-- 方法1: 使用数学对数计算位数（适用于正整数）
function countDigitsMath(n)
    if n == 0 then
        return 1
    end
    if n < 0 then
        n = -n  -- 处理负数，取绝对值
    end
    return math.floor(math.log10(n)) + 1
end

-- 方法2: 使用字符串转换计算位数（最简单直接的方法）
function countDigitsString(n)
    local str = tostring(math.abs(n))  -- 转换为字符串并取绝对值
    return #str  -- 返回字符串长度即为位数
end

-- 方法3: 使用循环除法计算位数（传统算法）
function countDigitsLoop(n)
    if n == 0 then
        return 1
    end
    
    n = math.abs(n)  -- 处理负数
    local count = 0
    
    while n > 0 do
        n = math.floor(n / 10)
        count = count + 1
    end
    
    return count
end

-- 方法4: 使用递归计算位数
function countDigitsRecursive(n)
    n = math.abs(n)  -- 处理负数
    
    if n < 10 then
        return 1
    else
        return 1 + countDigitsRecursive(math.floor(n / 10))
    end
end

-- 方法5: 使用位运算计算二进制位数（针对二进制表示）
function countBinaryBits(n)
    if n == 0 then
        return 1
    end
    
    n = math.abs(n)
    local count = 0
    
    while n > 0 do
        n = math.floor(n / 2)  -- 除以2相当于右移一位（兼容Lua 5.1）
        count = count + 1
    end
    
    return count
end

-- 方法6: 使用查表法计算位数（适用于小范围数字，性能最优）
local digitTable = {}
for i = 1, 9 do
    digitTable[10^(i-1)] = i
end

function countDigitsTable(n)
    n = math.abs(n)
    
    if n == 0 then
        return 1
    end
    
    -- 对于小数字直接查表
    if n < 1000000 then
        if n < 10 then return 1
        elseif n < 100 then return 2
        elseif n < 1000 then return 3
        elseif n < 10000 then return 4
        elseif n < 100000 then return 5
        else return 6
        end
    else
        -- 对于大数字使用对数方法
        return math.floor(math.log10(n)) + 1
    end
end

-- 测试函数
function testAllMethods()
    local testNumbers = {0, 5, 42, 123, 1000, 99999, -123, -9876}
    
    print("=== 测试各种方法计算整型数位数 ===")
    print(string.format("%-10s %-8s %-8s %-8s %-8s %-8s %-8s", 
          "数字", "数学法", "字符串", "循环法", "递归法", "二进制", "查表法"))
    print(string.rep("-", 70))
    
    for _, num in ipairs(testNumbers) do
        local math_result = countDigitsMath(num)
        local string_result = countDigitsString(num)
        local loop_result = countDigitsLoop(num)
        local recursive_result = countDigitsRecursive(num)
        local binary_result = countBinaryBits(num)
        local table_result = countDigitsTable(num)
        
        print(string.format("%-10d %-8d %-8d %-8d %-8d %-8d %-8d", 
              num, math_result, string_result, loop_result, 
              recursive_result, binary_result, table_result))
    end
end

-- 性能测试函数
function performanceTest()
    local testNum = 123456789
    local iterations = 100000
    
    print("\n=== 性能测试 ===")
    print(string.format("测试数字: %d, 迭代次数: %d", testNum, iterations))
    
    -- 测试各种方法的性能
    local methods = {
        {"数学对数法", countDigitsMath},
        {"字符串转换法", countDigitsString},
        {"循环除法", countDigitsLoop},
        {"递归法", countDigitsRecursive},
        {"查表法", countDigitsTable}
    }
    
    for _, method in ipairs(methods) do
        local name, func = method[1], method[2]
        local start_time = os.clock()
        
        for i = 1, iterations do
            func(testNum)
        end
        
        local end_time = os.clock()
        local elapsed = end_time - start_time
        
        print(string.format("%-15s: %.4f 秒", name, elapsed))
    end
end

-- 主程序入口
function main()
    print("Lua整型数位数计算方法演示")
    print("=" .. string.rep("=", 30))
    
    -- 运行测试
    testAllMethods()
    
    -- 运行性能测试
    performanceTest()
    
    print("\n=== 方法总结 ===")
    print("1. 数学对数法: 性能好，但不适用于0和负数需要特殊处理")
    print("2. 字符串转换法: 最简单直接，代码可读性高")
    print("3. 循环除法: 传统算法，逻辑清晰")
    print("4. 递归法: 代码简洁，但可能有栈溢出风险")
    print("5. 二进制位运算: 计算二进制位数")
    print("6. 查表法: 对小数字性能最优")
end

-- 如果直接运行此文件，则执行主程序
if arg and arg[0] and arg[0]:match("p132%.lua$") then
    main()
end

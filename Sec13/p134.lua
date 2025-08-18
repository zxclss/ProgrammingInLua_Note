-- 计算整数的汉明权重（二进制表示中1的个数）
function CalHamWeight(x)
    local count = 0
    -- 使用位运算逐位检查
    while x > 0 do
        if x & 1 == 1 then
            count = count + 1
        end
        x = x >> 1
    end
    return count
end

-- 更高效的实现：使用Brian Kernighan算法
function CalHamWeightFast(x)
    local count = 0
    while x > 0 do
        x = x & (x - 1)  -- 清除最低位的1
        count = count + 1
    end
    return count
end

-- 使用查表法的实现
function CalHamWeightTable(x)
    -- 预计算0-255的汉明权重
    local popcount_table = {
        0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
        1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
        1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
        2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
        1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
        2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
        2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
        3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
        1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5,
        2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
        2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
        3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
        2, 3, 3, 4, 3, 4, 4, 5, 3, 4, 4, 5, 4, 5, 5, 6,
        3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
        3, 4, 4, 5, 4, 5, 5, 6, 4, 5, 5, 6, 5, 6, 6, 7,
        4, 5, 5, 6, 5, 6, 6, 7, 5, 6, 6, 7, 6, 7, 7, 8
    }
    
    local count = 0
    while x > 0 do
        count = count + popcount_table[(x & 0xFF) + 1]  -- Lua数组从1开始
        x = x >> 8
    end
    return count
end

-- 测试函数
function testHamWeight()
    local test_cases = {
        {0, 0},      -- 0: 二进制 0
        {1, 1},      -- 1: 二进制 1
        {2, 1},      -- 2: 二进制 10
        {3, 2},      -- 3: 二进制 11
        {7, 3},      -- 7: 二进制 111
        {8, 1},      -- 8: 二进制 1000
        {15, 4},     -- 15: 二进制 1111
        {255, 8},    -- 255: 二进制 11111111
        {1023, 10},  -- 1023: 二进制 1111111111
    }
    
    print("测试汉明权重计算：")
    print("数值\t二进制\t\t期望\t基础算法\t快速算法\t查表算法")
    print(string.rep("-", 60))
    
    for _, case in ipairs(test_cases) do
        local num, expected = case[1], case[2]
        local result1 = CalHamWeight(num)
        local result2 = CalHamWeightFast(num)
        local result3 = CalHamWeightTable(num)
        
        local binary = ""
        local temp = num
        if temp == 0 then
            binary = "0"
        else
            while temp > 0 do
                binary = (temp & 1) .. binary
                temp = temp >> 1
            end
        end
        
        print(string.format("%d\t%s\t\t%d\t%d\t\t%d\t\t%d", 
              num, binary, expected, result1, result2, result3))
              
        -- 验证结果
        assert(result1 == expected, "基础算法错误")
        assert(result2 == expected, "快速算法错误")
        assert(result3 == expected, "查表算法错误")
    end
    
    print("\n所有测试通过！")
end

-- 性能测试
function performanceTest()
    print("\n性能测试（计算1到10000的汉明权重）：")
    
    local start_time = os.clock()
    for i = 1, 10000 do
        CalHamWeight(i)
    end
    local time1 = os.clock() - start_time
    
    start_time = os.clock()
    for i = 1, 10000 do
        CalHamWeightFast(i)
    end
    local time2 = os.clock() - start_time
    
    start_time = os.clock()
    for i = 1, 10000 do
        CalHamWeightTable(i)
    end
    local time3 = os.clock() - start_time
    
    print(string.format("基础算法用时: %.4f秒", time1))
    print(string.format("快速算法用时: %.4f秒", time2))
    print(string.format("查表算法用时: %.4f秒", time3))
end

-- 运行测试
testHamWeight()
performanceTest()
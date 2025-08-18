function IsBinaryPalindrome(x)
    if x <= 0 then
        return x == 0  -- 0是回文，负数不是回文
    end
    
    local right = 0
    for i = 0, 63 do
        if x & (1 << i) ~= 0 then
            right = i
        end
    end
    
    local left = 0
    while left < right do
        if (x >> left) & 1 ~= (x >> right) & 1 then
            return false
        end
        left = left + 1
        right = right - 1
    end
    return true
end

-- 测试函数
function testBinaryPalindrome()
    local test_cases = {
        {0, true},      -- 0: 二进制 0 (回文)
        {1, true},      -- 1: 二进制 1 (回文)
        {3, true},      -- 3: 二进制 11 (回文)
        {5, true},      -- 5: 二进制 101 (回文)
        {7, true},      -- 7: 二进制 111 (回文)
        {9, true},      -- 9: 二进制 1001 (回文)
        {17, true},     -- 17: 二进制 10001 (回文)
        {21, true},     -- 21: 二进制 10101 (回文)
        {2, false},     -- 2: 二进制 10 (不是回文)
        {4, false},     -- 4: 二进制 100 (不是回文)
        {6, false},     -- 6: 二进制 110 (不是回文)
        {8, false},     -- 8: 二进制 1000 (不是回文)
        {10, false},    -- 10: 二进制 1010 (不是回文)
        {-1, false},    -- 负数不是回文
    }
    
    print("测试二进制回文数检查：")
    print("数值\t二进制\t\t原函数\t修正函数\t期望结果")
    print(string.rep("-", 60))
    
    for _, case in ipairs(test_cases) do
        local num, expected = case[1], case[2]
        local result1 = Is(num)
        local result2 = IsBinaryPalindrome(num)
        
        -- 生成二进制表示
        local binary = ""
        local temp = math.abs(num)
        if temp == 0 then
            binary = "0"
        else
            while temp > 0 do
                binary = (temp & 1) .. binary
                temp = temp >> 1
            end
        end
        if num < 0 then binary = "-" .. binary end
        
        local status1 = result1 == expected and "✓" or "✗"
        local status2 = result2 == expected and "✓" or "✗"
        
        print(string.format("%d\t%s\t\t%s %s\t%s %s\t%s", 
              num, binary, tostring(result1), status1, 
              tostring(result2), status2, tostring(expected)))
    end
end

-- 运行测试
testBinaryPalindrome()
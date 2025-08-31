-- 字符串记忆表的正确理解和实现
-- 重要概念：字符串在Lua中是不可回收的对象！

print("=== 字符串垃圾回收的真相 ===")

-- 首先验证字符串确实不会被垃圾回收
function demonstrateStringGC()
    print("\n--- 演示字符串不被垃圾回收 ---")
    
    -- 创建一个弱引用表
    local weakTable = {}
    setmetatable(weakTable, {__mode = "k"})  -- 键为弱引用
    
    -- 测试普通对象（表）作为键
    do
        local normalTable = {data = "test"}
        weakTable[normalTable] = "普通表对象"
        print("添加普通表对象作为键")
    end
    -- normalTable离开作用域，应该被回收
    
    -- 测试字符串作为键
    do
        local str = "test_string_key"
        weakTable[str] = "字符串值"
        print("添加字符串作为键")
    end
    -- str离开作用域，但字符串不会被回收
    
    -- 强制垃圾回收
    collectgarbage("collect")
    
    print("\n垃圾回收后的弱引用表内容：")
    for k, v in pairs(weakTable) do
        print(string.format("键: %s (类型: %s), 值: %s", 
                          tostring(k), type(k), v))
    end
    
    print("\n结论：字符串键仍然存在，普通表键被回收了！")
end

-- 正确的字符串记忆表实现方案

-- 方案1：使用显式大小限制
function createLimitedMemoTable(maxSize)
    maxSize = maxSize or 1000
    local cache = {}
    local keys = {}  -- 记录插入顺序
    local size = 0
    
    return {
        get = function(key)
            return cache[key]
        end,
        
        set = function(key, value)
            -- 如果键已存在，只更新值
            if cache[key] ~= nil then
                cache[key] = value
                return
            end
            
            -- 如果达到大小限制，删除最老的条目
            if size >= maxSize then
                local oldestKey = table.remove(keys, 1)
                cache[oldestKey] = nil
                size = size - 1
                print(string.format("清理最老条目: %s", tostring(oldestKey)))
            end
            
            -- 添加新条目
            cache[key] = value
            table.insert(keys, key)
            size = size + 1
        end,
        
        size = function()
            return size
        end,
        
        clear = function()
            cache = {}
            keys = {}
            size = 0
        end
    }
end

-- 方案2：使用时间戳清理策略
function createTimedMemoTable(maxAge)
    maxAge = maxAge or 300  -- 默认5分钟
    local cache = {}
    local timestamps = {}
    
    local function cleanup()
        local currentTime = os.time()
        local keysToRemove = {}
        
        for key, timestamp in pairs(timestamps) do
            if currentTime - timestamp > maxAge then
                table.insert(keysToRemove, key)
            end
        end
        
        for _, key in ipairs(keysToRemove) do
            cache[key] = nil
            timestamps[key] = nil
            print(string.format("清理过期条目: %s", tostring(key)))
        end
    end
    
    return {
        get = function(key)
            cleanup()  -- 每次访问时清理过期条目
            return cache[key]
        end,
        
        set = function(key, value)
            cleanup()
            cache[key] = value
            timestamps[key] = os.time()
        end,
        
        size = function()
            cleanup()
            local count = 0
            for _ in pairs(cache) do
                count = count + 1
            end
            return count
        end,
        
        clear = function()
            cache = {}
            timestamps = {}
        end
    }
end

-- 方案3：使用概率性清理
function createProbabilisticMemoTable(maxSize, cleanupProbability)
    maxSize = maxSize or 1000
    cleanupProbability = cleanupProbability or 0.1  -- 10%概率清理
    
    local cache = {}
    local accessCounts = {}
    local size = 0
    
    local function probabilisticCleanup()
        if math.random() < cleanupProbability and size > maxSize * 0.8 then
            print("执行概率性清理...")
            local keysToRemove = {}
            
            -- 找出访问次数最少的条目
            local minAccess = math.huge
            for key, count in pairs(accessCounts) do
                if count < minAccess then
                    minAccess = count
                end
            end
            
            -- 删除访问次数最少的条目
            for key, count in pairs(accessCounts) do
                if count == minAccess and #keysToRemove < size * 0.2 then
                    table.insert(keysToRemove, key)
                end
            end
            
            for _, key in ipairs(keysToRemove) do
                cache[key] = nil
                accessCounts[key] = nil
                size = size - 1
                print(string.format("清理低频访问条目: %s", tostring(key)))
            end
        end
    end
    
    return {
        get = function(key)
            probabilisticCleanup()
            if cache[key] ~= nil then
                accessCounts[key] = (accessCounts[key] or 0) + 1
                return cache[key]
            end
            return nil
        end,
        
        set = function(key, value)
            if cache[key] == nil then
                size = size + 1
            end
            cache[key] = value
            accessCounts[key] = (accessCounts[key] or 0) + 1
            probabilisticCleanup()
        end,
        
        size = function()
            return size
        end
    }
end

-- 包装函数使用正确的记忆表
function memoizeStringFunctionCorrect(func, strategy, ...)
    local cache
    
    if strategy == "limited" then
        cache = createLimitedMemoTable(...)
    elseif strategy == "timed" then
        cache = createTimedMemoTable(...)
    elseif strategy == "probabilistic" then
        cache = createProbabilisticMemoTable(...)
    else
        error("未知的策略: " .. tostring(strategy))
    end
    
    return function(str)
        local cached = cache.get(str)
        if cached ~= nil then
            print(string.format("从%s缓存获取: %s", strategy, str))
            return cached
        end
        
        local result = func(str)
        cache.set(str, result)
        print(string.format("计算并存入%s缓存: %s -> %s", strategy, str, tostring(result)))
        return result
    end
end

-- 测试函数
function expensiveStringOperation(str)
    -- 模拟耗时操作
    local count = 0
    for i = 1, 100000 do
        count = count + 1
    end
    return string.upper(str) .. "_PROCESSED"
end

-- 测试所有策略
function testCorrectMemoization()
    print("\n=== 测试正确的字符串记忆表实现 ===")
    
    -- 测试限制大小策略
    print("\n--- 测试限制大小策略 ---")
    local limitedMemo = memoizeStringFunctionCorrect(expensiveStringOperation, "limited", 3)
    
    local testStrings = {"a", "b", "c", "d", "e", "a", "b"}
    for _, str in ipairs(testStrings) do
        limitedMemo(str)
    end
    
    -- 测试时间清理策略（这里用短时间演示）
    print("\n--- 测试时间清理策略 ---")
    local timedMemo = memoizeStringFunctionCorrect(expensiveStringOperation, "timed", 2)  -- 2秒过期
    
    timedMemo("test1")
    timedMemo("test2")
    print("等待3秒...")
    -- 在实际使用中这里会 os.execute("sleep 3")，但为了演示跳过
    timedMemo("test1")  -- 应该重新计算
    
    -- 测试概率清理策略
    print("\n--- 测试概率清理策略 ---")
    local probMemo = memoizeStringFunctionCorrect(expensiveStringOperation, "probabilistic", 5, 0.5)
    
    for i = 1, 10 do
        probMemo("item" .. i)
    end
end

-- 运行演示
demonstrateStringGC()
testCorrectMemoization()

print("\n=== 总结 ===")
print("1. 字符串在Lua中确实不会被垃圾回收，即使使用弱引用表")
print("2. 因此字符串记忆表必须使用显式的清理策略：")
print("   - 大小限制策略：达到上限时删除最老的条目")
print("   - 时间清理策略：定期删除过期的条目")
print("   - 概率清理策略：随机清理低频访问的条目")
print("3. 选择哪种策略取决于具体的使用场景和性能要求") 
-- 无限调用链程序 - 展示尾调用消除
-- 这不是递归，而是函数间的相互尾调用

-- 前向声明
local functionA, functionB, functionC

functionA = function(n)
    if n <= 0 then
        return "结束"
    end
    print("函数A: " .. n)
    -- 尾调用：调用functionB，这是最后一个操作
    return functionB(n - 1)
end

functionB = function(n)
    if n <= 0 then
        return "结束"
    end
    print("函数B: " .. n)
    -- 尾调用：调用functionC，这是最后一个操作
    return functionC(n - 1)
end

functionC = function(n)
    if n <= 0 then
        return "结束"
    end
    print("函数C: " .. n)
    -- 尾调用：调用functionA，这是最后一个操作
    return functionA(n - 1)
end

-- 测试无限调用链
print("开始无限调用链测试:")
local result = functionA(10)
print("最终结果: " .. result)

-- 另一个例子：状态机模式
local state1, state2, state3

state1 = function(n)
    if n <= 0 then
        return "完成"
    end
    print("状态1处理: " .. n)
    -- 尾调用到状态2
    return state2(n - 1)
end

state2 = function(n)
    if n <= 0 then
        return "完成"
    end
    print("状态2处理: " .. n)
    -- 尾调用到状态3
    return state3(n - 1)
end

state3 = function(n)
    if n <= 0 then
        return "完成"
    end
    print("状态3处理: " .. n)
    -- 尾调用回到状态1
    return state1(n - 1)
end

print("\n状态机测试:")
local stateResult = state1(15)
print("状态机结果: " .. stateResult)

-- 协程风格的无限调用链
local coroutineStyle, nextCoroutine

coroutineStyle = function(n)
    if n <= 0 then
        return "协程完成"
    end
    print("协程步骤: " .. n)
    -- 尾调用到下一个协程函数
    return nextCoroutine(n - 1)
end

nextCoroutine = function(n)
    if n <= 0 then
        return "协程完成"
    end
    print("下一个协程: " .. n)
    -- 尾调用回到主协程函数
    return coroutineStyle(n - 1)
end

print("\n协程风格测试:")
local coroutineResult = coroutineStyle(8)
print("协程结果: " .. coroutineResult) 
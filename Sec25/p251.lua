function getvarvalue(a, b, c, d)
    -- 支持可选协程参数：[thread,] name, level, isenv
    local thread, name, level, isenv
    if type(a) == "thread" then
        thread, name, level, isenv = a, b, c, d
    else
        thread, name, level, isenv = nil, a, b, c
    end

    local value
    local found = false

    -- 若提供了 thread，则 level 直接针对该协程的调用栈；
    -- 否则（当前协程）需要 +1 跳过本函数自身。
    if thread then
        level = level or 1
    else
        level = (level or 1) + 1
    end

    -- 尝试局部变量
    for i = 1, math.huge do
        local n, v
        if thread then
            n, v = debug.getlocal(thread, level, i)
        else
            n, v = debug.getlocal(level, i)
        end
        if not n then break end
        if n == name then
            value = v
            found = true
        end
    end
    if found then return "local", value end

    -- 尝试非局部变量
    local func
    if thread then
        func = debug.getinfo(thread, level, "f").func
    else
        func = debug.getinfo(level, "f").func
    end
    for i = 1, math.huge do
        local n, v = debug.getupvalue(func, i)
        if not n then break end
        if n == name then return "upvalue", v end
    end

    if isenv then return "noenv" end -- 避免循环

    -- 没找到；从环境变量中获取值
    local _, env
    if thread then
        _, env = getvarvalue(thread, "_ENV", level, true)
    else
        _, env = getvarvalue("_ENV", level, true)
    end
    if env then
        return "global", env[name]
    else    -- 没有有效的 _ENV
        return "noenv"
    end
end

function case1()
    local a = 4; print(getvarvalue("a"))
end

function case2()
    a = "xx"; print(getvarvalue("a"))
    a = nil;
end

case1()
case2()

function case3()
    -- 创建协程并在其内部构造局部变量、上值以及设置全局变量
    local u = "UPVALUE_IN_CO"
    local co = coroutine.create(function()
        local function inner()
            local l = "LOCAL_" .. u  -- 确保捕获上值 u
            a = "GLOBAL_FROM_CO"      -- 设置全局，便于 global 路径测试
            coroutine.yield("yielded")
            return l
        end
        inner()
    end)

    local ok, msg = coroutine.resume(co)
    print("-- case3 first resume:", ok, msg)

    -- 在协程调用栈 level=1（当前为 inner）上读取不同类别的变量
    print(getvarvalue(co, "l", 1))  -- 期望：local
    print(getvarvalue(co, "u", 1))  -- 期望：upvalue
    print(getvarvalue(co, "a", 1))  -- 期望：global

    -- 继续运行直至结束
    local ok2, ret = coroutine.resume(co)
    print("-- case3 second resume:", ok2, ret)
end

case3()
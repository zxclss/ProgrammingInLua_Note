function getvarvalue(name, level, isenv)
    local value
    local found = false
    
    level = (level or 1) + 1
    -- 尝试局部变量
    for i = 1, math.huge do
        local n, v = debug.getlocal(level, i)
        if not n then break end
        if n == name then
            value = v
            found = true
        end
    end
    if found then return "local", value end

    -- 尝试非局部变量
    local func = debug.getinfo(level, "f").func
    for i = 1, math.huge do
        local n, v = debug.getupvalue(func, i)
        if not n then break end
        if n == name then return "upvalue", v end
    end

    if isenv then return "noenv" end -- 避免循环

    -- 没找到；从环境变中获取值
    local _, env = getvarvalue("_ENV", level, true)
    if env then
        return "global", env[name]
    else    -- 没有有效的 _ENV
        return "noenv"
    end
end

function setvarvalue(name, newvalue, level, isenv)
    local updated = false

    level = (level or 1) + 1
    -- 尝试局部变量
    for i = 1, math.huge do
        local n = debug.getlocal(level, i)
        if not n then break end
        if n == name then
            debug.setlocal(level, i, newvalue)
            updated = true
        end
    end
    if updated then return "local" end

    -- 尝试非局部变量
    local func = debug.getinfo(level, "f").func
    for i = 1, math.huge do
        local n = debug.getupvalue(func, i)
        if not n then break end
        if n == name then
            debug.setupvalue(func, i, newvalue)
            return "upvalue"
        end
    end

    if isenv then return "noenv" end -- 避免循环

    -- 没找到；设置环境变量
    local _, env = getvarvalue("_ENV", level, true)
    if env then
        env[name] = newvalue
        return "global"
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
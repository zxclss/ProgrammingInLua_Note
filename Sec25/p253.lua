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

function getvarvaluetable(level)
    local visible = {}
    local shadowNil = {}
    local baseEnv = nil

    level = (level or 1) + 1

    -- 先收集非局部变量（上值）。记录 _ENV 以便继承
    local func = debug.getinfo(level, "f").func
    for i = 1, math.huge do
        local name, value = debug.getupvalue(func, i)
        if not name then break end
        if name == "_ENV" then
            baseEnv = value
        else
            if value == nil then
                shadowNil[name] = true
            else
                visible[name] = value
            end
        end
    end

    -- 再收集局部变量，使其遮蔽上值
    for i = 1, math.huge do
        local name, value = debug.getlocal(level, i)
        if not name then break end
        if name ~= "_ENV" then
            if value == nil then
                shadowNil[name] = true
                visible[name] = nil
            else
                visible[name] = value
            end
        end
    end

    -- 通过元表从原来的 _ENV 继承未在可见表中的名字
    setmetatable(visible, {
        __index = function(_, key)
            if shadowNil[key] then return nil end
            return baseEnv and baseEnv[key] or nil
        end
    })

    return visible
end

function printtable(t)
    for k, v in pairs(t) do
        print(k, v)
    end
end

function case1()
    local a = 4; print(getvarvalue("a"))
    local tab = getvarvaluetable(1)
    printtable(tab)
end

function case2()
    a = "xx"; print(getvarvalue("a"))
    local tab = getvarvaluetable(1)
    printtable(tab)
    -- print("a" .. "\t" .. tab["a"])
end

-- case1()
case2()
-- 改进版 debug.debug：在调用点的词法定界中运行命令
if type(getvarvalue) ~= "function" then
    local src = debug.getinfo(1, "S").source
    if type(src) == "string" and src:sub(1, 1) == "@" then
        local dir = src:sub(2):match("(.*/)") or ""
        pcall(dofile, dir .. "getvarvalue.lua")
    end
end
if type(setvarvalue) ~= "function" then
    local src = debug.getinfo(1, "S").source
    if type(src) == "string" and src:sub(1, 1) == "@" then
        local dir = src:sub(2):match("(.*/)") or ""
        pcall(dofile, dir .. "p252.lua")
    end
end
local function pretty_print(...)
    local n = select('#', ...)
    if n == 0 then return end
    for i = 1, n do
        if i > 1 then io.write("\t") end
        io.write(tostring(select(i, ...)))
    end
    io.write("\n")
end
-- 覆盖 debug.debug，实现词法可见性下的交互求值
---@diagnostic disable-next-line: duplicate-set-field
function debug.debug(prompt)
    prompt = prompt or "lexdebug> "

    if type(getvarvalue) ~= "function" then
        io.write("[lexdebug] 缺少 getvarvalue 助手函数，无法启用词法访问。\n")
        return
    end

    -- 空环境，所有名字解析经由 __index 委托到 getvarvalue
    local env
    env = setmetatable({}, {
        __index = function(_, key)
            -- 让所有读取落到调用 debug.debug 的函数词法定界
            -- 这里传入 level=4，使 getvarvalue 实际查看到调用者帧
            local _, v = getvarvalue(key, 4)
            return v
        end,
        __newindex = function(t, key, value)
            -- 写入：优先尝试局部/上值/环境（若用户提供了 setvarvalue 则生效）
            if type(setvarvalue) == "function" then
                local kind = setvarvalue(key, value, 4)
                if kind == "noenv" then
                    rawset(t, key, value)
                end
            else
                -- 无 setvarvalue 时，写入调试环境自身（不影响调用者变量）
                rawset(t, key, value)
            end
        end,
    })

    io.write("-- lexical debug -- type 'cont' to continue --\n")
    while true do
        io.write(prompt)
        local line = io.read("*l")
        if line == nil or line == "cont" or line == "exit" or line == "quit" then
            io.write("\n")
            break
        end

        -- 先尝试把输入当作表达式求值
        local chunk, err = load("return " .. line, "=(lexdebug)", "t", env)
        if not chunk then
            -- 再当作语句执行
            chunk, err = load(line, "=(lexdebug)", "t", env)
        end

        if not chunk then
            io.write("[compile error] " .. tostring(err) .. "\n")
        else
            local results = table.pack(pcall(chunk))
            if not results[1] then
                io.write("[runtime error] " .. tostring(results[2]) .. "\n")
            else
                if results.n > 1 then
                    pretty_print(table.unpack(results, 2, results.n))
                end
            end
        end
    end
end

-- 示例：
-- 在任意函数中调用 debug.debug()，在提示符下可以直接访问该函数的局部/上值/全局
-- 例如：输入 a 或者 a=123，然后输入 cont 继续程序。
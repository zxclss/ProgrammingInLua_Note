---@diagnostic disable-next-line: duplicate-set-field
function debug.debug(prompt)
    prompt = prompt or "lex> "

    if type(getvarvalue) ~= "function" then
        io.write("[lexdebug] 需要先提供 getvarvalue。\n")
        return
    end

    local env = setmetatable({}, {
        __index = function(_, key)
            local _, v = getvarvalue(key, 4)
            return v
        end
    })

    io.write("-- lexical debug -- 输入 continue 继续 --\n")
    while true do
        io.write(prompt)
        local line = io.read("*l")
        if line == nil or line == "continue" then io.write("\n"); break end

        local chunk, err = load("return " .. line, "=(lexdebug)", "t", env)
        if not chunk then chunk, err = load(line, "=(lexdebug)", "t", env) end

        if not chunk then
            io.write(tostring(err) .. "\n")
        else
            local res = table.pack(pcall(chunk))
            if not res[1] then
                io.write(tostring(res[2]) .. "\n")
            elseif res.n > 1 then
                print(table.unpack(res, 2, res.n))
            end
        end
    end
end
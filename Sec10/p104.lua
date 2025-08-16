function Trim(s)
    local len = #s
    local i = 1
    -- skip leading whitespace (Lua %s: space, \t, \n, \v, \f, \r)
    while i <= len do
        local b = string.byte(s, i)
        if b ~= 32 and b ~= 9 and b ~= 10 and b ~= 11 and b ~= 12 and b ~= 13 then
            break
        end
        i = i + 1
    end
    if i > len then
        return ""
    end
    -- skip trailing whitespace
    local j = len
    while j >= i do
        local b = string.byte(s, j)
        if b ~= 32 and b ~= 9 and b ~= 10 and b ~= 11 and b ~= 12 and b ~= 13 then
            break
        end
        j = j - 1
    end
    return string.sub(s, i, j)
end

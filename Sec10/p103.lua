function Transliterate(s, t)
    local result = ""
    for i = 1, #s do
        local c = s:sub(i, i)
        if t[c] then
            result = result .. t[c]
        elseif t[c] == nil then
            result = result .. c
        end
    end
    return result
end

Sample = "Hello, world!"
print(Transliterate(Sample, {
    ["H"] = "H",
    ["e"] = "e",
    ["l"] = "y",
    ["o"] = false,
    [","] = "B",
    [" "] = "r",
    ["w"] = "s",
}))
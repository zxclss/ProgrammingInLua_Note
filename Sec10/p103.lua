function Transliterate(s, t)
    local result = ""
    for i = 1, #s do
        local c = s:sub(i, i)
        if t[c] then
            result = result .. t[c]
        else
            result = result .. c
        end
    end
    return result
end

Sample = "Hello, world!"
print(Transliterate(Sample, {
    ["H"] = "A",
    ["e"] = "B",
    ["l"] = "C",
    ["o"] = "D",
    [","] = "E",
    [" "] = "F",
    ["w"] = "G",
}))
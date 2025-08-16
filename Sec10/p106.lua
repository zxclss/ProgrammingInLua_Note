function Transliterate(s, t)
    local out = {}
    for _, codepoint in utf8.codes(s) do
        local ch = utf8.char(codepoint)
        local repl = t[ch] or t[codepoint]
        out[#out + 1] = repl or ch
    end
    return table.concat(out)
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
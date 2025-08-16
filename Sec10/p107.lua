function UTF8Reverse(s)
    local chars = {}
    for _, codepoint in utf8.codes(s) do
        chars[#chars + 1] = utf8.char(codepoint)
    end
    local i, j = 1, #chars
    while i < j do
        chars[i], chars[j] = chars[j], chars[i]
        i = i + 1
        j = j - 1
    end
    return table.concat(chars)
end
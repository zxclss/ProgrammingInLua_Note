local function uniquewords(file)
    local words = {}
    for line in io.lines(file) do
        for word in string.gmatch(line, "%w+") do
            words[word] = true
        end
    end
    return next, words, nil
end

for word in uniquewords("p183.lua") do
    io.write(word, " ")
end
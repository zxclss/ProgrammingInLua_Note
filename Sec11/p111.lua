local counter = {}
for line in io.lines() do
    for word in line:gmatch("%w+") do
        if #word >= 4 then
            counter[word] = (counter[word] or 0) + 1
        end
    end
end

local words = {}
for word in pairs(counter) do
    words[#words + 1] = word
end

table.sort(words, function(a, b)
    return counter[a] > counter[b] or (counter[a] == counter[b] and a < b)
end)

local n = math.min(tonumber(arg[1]) or math.huge, #words)
for i = 1, n do
    print(words[i], counter[words[i]])
end
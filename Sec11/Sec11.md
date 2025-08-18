## 11 小插曲：出现频率最高的词

### 笔记

内容比较简单，不做过多介绍。

### 练习

练习 11.1

```lua
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
```

练习 11.2

```lua
do
    local ignore_words = {}
    local old = io.input()
    io.input(arg[2])

    
    for line in io.lines() do
        for word in line:gmatch("%w+") do
            ignore_words[word] = true
        end
    end

    io.input(old)
end

local counter = {}
for line in io.lines() do
    for word in line:gmatch("%w+") do
        if not ignore_words[word] then
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
```
local history_horizon = tonumber(arg[1]) or 2

function allwords ()
    local line = io.read()
    local pos = 1
    return function()
        while line do
            local w, e = string.match(line, "(%w+[,;.:]?)()", pos)
            if w then
                pos = e
                return w
            else
                line = io.read()
                pos = 1
            end
        end
        return nil
    end
end

function prefix (words)
    local t = {}
    for _, word in ipairs(words) do
        t[#t + 1] = word
    end
    return table.concat(t, " ")
end

statetab = {}

function insert (prefix, value)
    local list = statetab[prefix]
    if list == nil then
        statetab[prefix] = {value}
    else
        list[#list + 1] = value
    end
end

local datain = io.open("data.in", "r")
local dataout = io.open("data.out", "w")
io.input(datain)
io.output(dataout)

local MAXGEN = 200
local NOWORD = "\n"

function clear_table (words)
    for i=1, history_horizon do
        words[i] = NOWORD
    end
end

local words = {}
clear_table(words)
for nextword in allwords() do
    insert(prefix(words), nextword)
    for i=1, history_horizon - 1 do
        words[i] = words[i + 1]
    end
    words[history_horizon] = nextword
end
insert(prefix(words), NOWORD)

clear_table(words)
for i = 1, MAXGEN do
    local list = statetab[prefix(words)]
    local nextword = list[math.random(1, #list)]
    if nextword == NOWORD then return end
    dataout:write(nextword .. " ")
    for i=1, history_horizon - 1 do
        words[i] = words[i + 1]
    end
    words[history_horizon] = nextword
end

datain:close()
dataout:close()
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

function prefix (w1, w2)
    return w1 .. " " .. w2
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

local w1, w2 = NOWORD, NOWORD
for nextword in allwords() do
    insert(prefix(w1, w2), nextword)
    w1, w2 = w2, nextword
end
insert(prefix(w1, w2), NOWORD)

w1, w2 = NOWORD, NOWORD
for i = 1, MAXGEN do
    local list = statetab[prefix(w1, w2)]
    local nextword = list[math.random(1, #list)]
    if nextword == NOWORD then return end
    dataout:write(nextword .. " ")
    w1, w2 = w2, nextword
end

datain:close()
dataout:close()
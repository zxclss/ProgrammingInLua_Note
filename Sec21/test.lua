local function search (k, plist)
    for i = 1, #plist do
        local v = plist[i][k]
        if v then return v end
    end
end

function createrClass (...)
    local c = {}
    local parents = {...}
    setmetatable(c, {
        __index = function(table, key)
            return search(key, parents)
        end
    })
    c.__index = c
    function c:new(o)
        o = o or {}
        setmetatable(o, c)
        return o
    end
    return c
end

Named = {}
function Named:getname ()
    return self.name
end

function Named:setname (name)
    self.name = name
end

Person = createrClass(Named)

p = Person:new()
print(p:getname())
p:setname("Jane")
print(p:getname())
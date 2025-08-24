Stack = {}

function Stack:new()
    local o = {items = {}}
    self.__index = self
    setmetatable(o, self)
    return o
end

function Stack:push(value)
    table.insert(self.items, value)
end

function Stack:pop()
    return table.remove(self.items)
end

function Stack:top()
    return self.items[#self.items]
end

function Stack:isEmpty()
    return #self.items == 0
end

if arg[1] == "test211" then
    local s = Stack:new()
    s:push(10)
    s:push(20)
    print(s:top())
    print(s:pop())
    print(s:isEmpty())
    print(s:top())
    print(s:pop())
    print(s:isEmpty())
    print(s:top())
end
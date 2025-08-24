local stack_data = {}

Stack = {}

function Stack:new(o)
    local o = o or {}
    self.__index = self
    setmetatable(o, self)
    stack_data[o] = {}
    return o
end

function Stack:push(value)
    table.insert(stack_data[self], value)
end

function Stack:pop()
    return table.remove(stack_data[self])
end

function Stack:top()
    return stack_data[self][#stack_data[self]]
end

function Stack:isEmpty()
    return #stack_data[self] == 0
end

if arg[1] == "test213" then
    local s = Stack:new()
    s:push(10)
    s:push(20)
    print(s:pop())
    print(s:pop())
end
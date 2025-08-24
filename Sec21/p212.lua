require "p211"

StackQueue = Stack:new()

function StackQueue:insertbottom(value)
    if #self.items == 0 then
        self:push(value)
        return
    end
    for i = #self.items, 1, -1 do
        self.items[i+1] = self.items[i]
    end
    self.items[1] = value
end

if arg[1] == "test212" then
    local sq = StackQueue:new()
    sq:insertbottom(1)
    sq:insertbottom(2)
    sq:insertbottom(3)
    sq:insertbottom(4)
    sq:insertbottom(5)
    sq:insertbottom(6)
    sq:insertbottom(7)
    sq:insertbottom(8)
    sq:insertbottom(9)
    sq:insertbottom(10)
    while not sq:isEmpty() do
        print(sq:top())
        sq:pop()
    end
end
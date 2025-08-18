Queue = {}
function Queue:listNew()
    self.first = 0
    self.last = 0
    self.list = {}
end
function Queue:pushFirst(value)
    if self.first == 0 and self.last == 0 then
        self.first = 1
        self.last = 1
        self.list[1] = value
    else
        local first = self.first - 1
        self.first = first
        self.list[first] = value
    end
end
function Queue:pushLast(value)
    if self.first == 0 and self.last == 0 then
        self.first = 1
        self.last = 1
        self.list[1] = value
    else
        local last = self.last + 1
        self.last = last
        self.list[last] = value
    end
end
function Queue:popFirst()
    if self.first == 0 and self.last == 0 then
        return nil
    end
    local first = self.first
    local value = self.list[first]
    self.list[first] = nil
    if first == self.last then
        self.first = 0
        self.last = 0
    else
        self.first = first + 1
    end
    return value
end
function Queue:popLast()
    if self.first == 0 and self.last == 0 then
        return nil
    end
    local last = self.last
    local value = self.list[last]
    self.list[last] = nil
    if last == self.first then
        self.first = 0
        self.last = 0
    else
        self.last = last - 1
    end
    return value
end
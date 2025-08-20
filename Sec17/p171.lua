function listNew()
    return {first = 0, last = -1}
end

function pushFirst(list, value)
    local first = list.first - 1
    list.first = first
    list[first] = value
end

function popFirst(list)
    local first = list.first
    if first > list.last then
        return nil
    end
    local value = list[first]
    list[first] = nil
    list.first = first + 1
    return value
end

function popLast(list)
    local last = list.last
    if last < list.first then
        return nil
    end
    local value = list[last]
    list[last] = nil
    list.last = last - 1
    return value
end

return {
    pushFirst = pushFirst,
    popFirst = popFirst,
    popLast = popLast,
    listNew = listNew,
}

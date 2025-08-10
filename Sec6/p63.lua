local function returnExceptLast(...)
    local list_len = select("#", ...)
    local res = ""
    for i, v in ipairs({...}) do
        if i == list_len then
            break
        end
        res = res .. v .. " "
    end
    return res
end

print(returnExceptLast(1, 2, 3, 4, 5))
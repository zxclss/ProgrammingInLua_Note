local function isValidSeq(t)
    local cnt = 1
    for k, v in pairs(t) do
        if k ~= cnt then
            return false
        end
        cnt = cnt + 1
    end
    return true
end
print(isValidSeq({1, 2, 3, 4, 5, 6}) and "yes" or "no")
print(isValidSeq({1, 2, 3, nil, 5, 6}) and "yes" or "no")

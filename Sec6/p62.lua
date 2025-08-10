local function returnExcept1st(...)
    if select("#", ...) < 2 then
        return nil
    end
    return select(2, ...)
end

-- lua5.2
-- local function returnExcept1st_(...)
--     local t = table.pack(...)
--     t:move(1, #t, 2)
--     return t
-- end

print(returnExcept1st(1, 2, 3, 4, 5))
print(returnExcept1st(1))
print(returnExcept1st())

-- print(returnExcept1st_(1, 2, 3, 4, 5))
-- print(returnExcept1st_(1))
-- print(returnExcept1st_())
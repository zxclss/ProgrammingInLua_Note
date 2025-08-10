local function printList(t)
    for _, v in ipairs(t) do
        io.write(v .. " ")
    end
    print()
end

printList({1, 2, 3, 4, 5})
local function insert(str, index, insert_str)
    return str:sub(1, index - 1) .. insert_str .. str:sub(index)
end

print(insert("Hello World!", 1, "Start: "))
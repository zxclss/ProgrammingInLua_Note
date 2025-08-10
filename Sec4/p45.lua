local function remove(str, start, len)
    return str:sub(1, start - 1) .. str:sub(start + len)
end

print(remove("Hello World!", 7, 4))
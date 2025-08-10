local function insert(str, char_index, insert_str)
    local byte_index = utf8.offset(str, char_index)
    if byte_index then
        return str:sub(1, byte_index - 1) .. insert_str .. str:sub(byte_index)
    else
        error("position out of bounds", 2)
    end
end

-- Example with an ASCII string, same behavior as before
print(insert("Hello World!", 7, "Lua "))

-- Example with a UTF-8 string
local s = "你好世界"
print("Original string: " .. s)

-- Insert "的美好" before "世界" (at character position 3)
local s_modified = insert(s, 3, "的美好")
print("After insert: " .. s_modified)

-- Insert at the beginning (position 1)
print(insert(s, 1, "开始: "))

-- Insert at the end (position 5)
print(insert(s, 5, "!"))
local function remove(str, start_char, len_char)
    local start_byte = utf8.offset(str, start_char)
    if not start_byte then
        error("start position out of bounds", 2)
    end

    local end_byte_of_removed = utf8.offset(str, start_char + len_char)

    if end_byte_of_removed then
        return str:sub(1, start_byte - 1) .. str:sub(end_byte_of_removed)
    else
        return str:sub(1, start_byte - 1)
    end
end

-- Example with an ASCII string, same behavior as before.
print("ASCII example:")
print(remove("Hello World!", 7, 4))

-- Example with a UTF-8 string.
local s = "你好,美丽的世界!"
print("\nUTF-8 example:")
print("Original: " .. s)

-- Remove "美丽" (2 chars starting at character position 4)
local s_modified = remove(s, 4, 2)
print("After removing '美丽': " .. s_modified)

-- Remove from "世界" to the end
-- "世界!" is 3 characters, starting at position 7
local s_end_removed = remove(s, 7, 3)
print("After removing '世界!': " .. s_end_removed)

-- Remove more characters than available until the end
local s_over_removed = remove(s, 4, 100)
print("After removing from char 4 to the end: " .. s_over_removed)
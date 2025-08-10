local function insert(str, index, insert_str)
    local valid_char_count = 0
    local real_index = #str + 1 -- Default to end of string if index is out of bounds

    -- Find the real position in the string, skipping non-alphanumeric characters
    for i = 1, #str do
        if str:sub(i, i):match("%w") then -- %w matches alphanumeric characters
            valid_char_count = valid_char_count + 1
            if valid_char_count == index then
                real_index = i
                break
            end
        end
    end

    return str:sub(1, real_index - 1) .. insert_str .. str:sub(real_index)
end

print(insert("Hello, World!", 7, "->")) -- 7th letter is 'o', should be "Hello, W->orld!"
print(insert("Hello World!", 1, "Start: ")) -- Should be "Start: Hello World!"

local function remove(str, start, len)
    if start <= 0 or len <= 0 then
        return str
    end

    local valid_char_count = 0
    local real_start_index = -1
    local real_end_index = -1

    -- Find the real start and end indices in the string
    for i = 1, #str do
        if str:sub(i, i):match("%w") then
            valid_char_count = valid_char_count + 1

            if valid_char_count == start then
                real_start_index = i
            end

            if valid_char_count == start + len - 1 then
                real_end_index = i
                break
            end
        end
    end

    -- If we found a start but not an end (len goes beyond string), remove to the end
    if real_start_index ~= -1 and real_end_index == -1 then
        real_end_index = #str
    end

    if real_start_index ~= -1 then
        return str:sub(1, real_start_index - 1) .. str:sub(real_end_index + 1)
    else
        -- If the start index is out of bounds of valid characters, return original string
        return str
    end
end

print(remove("Hello, World!", 7, 4)) -- Should remove "orld", result: "Hello, W!"
print(remove("a-b-c-d-e", 2, 3))      -- Should remove "-b-c-d", result: "a-e"
print(remove("Hello World!", 1, 5))  -- Should remove "Hello ", result: "World!"

local function isPalindrome(str)
    -- Clean the string: remove non-alphanumeric chars and convert to lower case
    local clean_str = str:gsub("[^%w]", ""):lower()
    -- Check if the cleaned string is equal to its reverse
    return clean_str == clean_str:reverse()
end

print("\n--- Palindrome Tests ---")
print("'step on no pets' ->", isPalindrome("step on no pets")) -- true
print("'Was it a car or a cat I saw?' ->", isPalindrome("Was it a car or a cat I saw?")) -- true
print("'A man, a plan, a canal: Panama' ->", isPalindrome("A man, a plan, a canal: Panama")) -- true
print("'hello world' ->", isPalindrome("hello world")) -- false
print("'No 'x' in 'Nixon'' ->", isPalindrome("No 'x' in 'Nixon'")) -- true

local function trim(str)
    -- First, remove leading/trailing whitespace as usual
    local s = str:gsub("^%s+", ""):gsub("%s+$", "")
    -- Then, remove all other non-alphanumeric characters from the entire string
    return s:gsub("[^%w%s]", "")
end

print("\n--- Trim Tests ---")
print(trim("  Hello, World!  ")) -- "Hello World"
print(trim("..a-b-c.."))         -- "abc"
print(trim("  (deal with it)  "))  -- "deal with it"
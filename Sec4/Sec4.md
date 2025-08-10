## 4 字符串

### 笔记

lua中的字符串是不可变值，不能像C那样改变字符串的某个字符，只能创建新的串来达到修改的目的。

`#` 是字符串的长度操作符，可以获取字符串的长度。但实际返回的是字节数，因此有些编码下和实际字符数不同。

`..`是连接操作符，连接数值时会优先转成字符串再连接。

lua支持的C风格转义字符有：

1. `\a` 响铃（bell）
2. `\b`：退格 (backspace)
3. `\f`：换页 (form feed)
4. `\n`：换行 (newline)
5. `\r`：回车 (carriage return)
6. `\t`：水平制表符 (horizontal tab)
7. `\v`：垂直制表符 (vertical tab)
8. `\\`：反斜杠 (backslash)
9. `\"`：双引号 (double quote)
10. `\'`：单引号 (single quote)

UTF-8字符声明方式：`\u{3b1} -> α`。

多行字符串可以像多行注释一样用`[[]]`包裹起来，但类似于`b[c[i]]`这样的字符串用到了`]]`，可以用任意数量的等号来更改需要匹配的右括号，比如`[==[xxxxx]==]`，lua会根据等号数量相同的括号来匹配（对多行注释同样有效）。

类型转换：
1. string2number：`tonumber("number string", base number)`
2. number2string：`tostring(number)`

常用标准库函数：
1. `string.rep("abc", 3) -> abcabcabc`
2. `string.reverse("abc") -> cba`
3. `string.lower`
4. `string.upper`
5. `string.sub("123456", 2, 4) -> "234"` 是闭集[left, right]
6. `string.byte("abc", 1) -> 97`
7. `string.format("x = %02d y = %.2f", 10, math.pi)`
8. `string.find("123321", "123" -> 1 3)`
9. `string.gsub("123321", "1", "x") -> x2332x 2`

### 练习

练习 4.1

1. `[==[]==]`可以过滤掉`]]`
2. 换行用换行符`\n`转成单行字符串然后使用单行字符串`""`避免使用`[[]]`

练习 4.2

对于包含大量转义序列的字符串常量，最推荐的方法是**使用字符串连接操作符（`..`）将其分解到多行**。这种方式在可读性、代码风格和可维护性之间取得了最佳平衡。

**示例：**
```lua
local complex_string = "这是一个包含多种转义符的例子。\n" ..
                       "\t- 这是一个制表符开头的行\n" ..
                       "\a\t- 这是一个响铃符和制表符\n" ..
                       "这是一个包含 \"引号\" 和 \\反斜杠\\ 的行。"
```

练习 4.3

```lua
local function insert(str, index, insert_str)
    return str:sub(1, index - 1) .. insert_str .. str:sub(index)
end
print(insert("Hello World!", 1, "Start: "))
```

练习 4.4

```lua
local function insert(str, char_index, insert_str)
    local byte_index = utf8.offset(str, char_index)
    if byte_index then
        return str:sub(1, byte_index - 1) .. insert_str .. str:sub(byte_index)
    else
        error("position out of bounds", 2)
    end
end
```

练习 4.5

```lua
local function remove(str, start, len)
    return str:sub(1, start - 1) .. str:sub(start + len)
end

print(remove("Hello World!", 7, 4))
```

练习 4.6

```lua
local function remove(str, start_char, len_char)
    local start_byte = utf8.offset(str, start_char)
    local end_byte_of_removed = utf8.offset(str, start_char + len_char)
    if end_byte_of_removed then
        return str:sub(1, start_byte - 1) .. str:sub(end_byte_of_removed)
    else
        return str:sub(1, start_byte - 1)
    end
end
```

练习 4.7

```lua
local function isPalindrome(str)
    local len = #str
    for i = 1, len / 2 do
        if str:sub(i, i) ~= str:sub(len - i + 1, len - i + 1) then
            return false
        end
    end
    return true
end
```

练习 4.8

```lua
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

local function isPalindrome(str)
    -- Clean the string: remove non-alphanumeric chars and convert to lower case
    local clean_str = str:gsub("[^%w]", ""):lower()
    -- Check if the cleaned string is equal to its reverse
    return clean_str == clean_str:reverse()
end
```

练习 4.9

不做了，我的win平台lua才5.1，根本没有utf-8，也懒得从源码安装了，就这样吧。
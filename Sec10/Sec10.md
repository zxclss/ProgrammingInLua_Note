## 10 模式匹配

> 这张内容我短期用不到这么细，靠G老师来补充吧

### 笔记

模式匹配的相关函数

1. 函数 string.find
   - 作用：在字符串中查找与模式匹配的第一处位置
   - 参数：`string.find(s, pattern [, init [, plain]])`
     - **返回**：起始下标、结束下标，以及任何捕获（若有）
     - `init`：起始搜索位置（可为负，表示从末尾倒数）
     - `plain=true`：关闭模式匹配，按字面量查找
   - 示例：
    ```lua
    local s = "Lua 5.4"
    print(string.find(s, "Lua"))         -- 1	3
    print(string.find(s, "%d+"))         -- 5	5 （一位数字）
    print(string.find(s, "5%.4"))        -- 5	7 （字面点需转义 % .）
    print(string.find(s, "Lua", 2))      -- nil （从下标 2 起找）
    print(string.find(s, "Lua", 1, true))-- 1	3 （plain=true 关闭模式）
    ```
2. 函数 string.match
   - 作用：返回与模式匹配的第一处结果（若有捕获则返回捕获；否则返回整个匹配片段）
   - 参数：`string.match(s, pattern [, init])`
   - 示例：
   ```lua
   local date = "2025-08-12"
   local y, m, d = string.match(date, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
   print(y, m, d) -- 2025	08	12
   ```

3. 函数 string.gsub
   - 作用：全局替换。支持将匹配替换为：
     - 字符串模版（用 `%1`、`%2`… 引用捕获，`%%` 表示字面 `%`）
     - 查表（key 为捕获或整段匹配）
     - 函数（参数为捕获；若无捕获则参数为整段匹配；返回替换文本）
   - 参数：`string.gsub(s, pattern, repl [, n])`（返回新串与替换次数）
   - 示例：
   ```lua
   -- 1) 用模版捕获
   print(("abc123def"):gsub("(%d+)", "[%1]")) -- abc[123]def	1

   -- 2) 用表做映射
   local map = { Lua = "Lua💙", code = "code✨" }
   print(("Lua code Lua"):gsub("%w+", map)) -- Lua💙 code✨ Lua💙	2

   -- 3) 用函数生成替换
   local s = "price: 12, tax: 3"
   local r, n = s:gsub("%d+", function(num)
     return string.format("<%02d>", tonumber(num))
   end)
   print(r, n) -- price: <12>, tax: <03>	2
   ```

4. 函数 string.gmatch
   - 作用：返回一个迭代器，遍历所有匹配结果（返回捕获或整段匹配）
   - 示例：
   ```lua
   local s = "one two  three"
   for w in s:gmatch("%S+") do
     print(w)
   end
   -- one\ntwo\nthree

   -- 遍历键值对形式（有捕获）
   local conf = "k1=v1;k2=v2"
   for k, v in conf:gmatch("([^=;]+)=([^=;]+)") do
     print(k, v)
   end
   ```

**字符类**：
- `.` 任意字符；`%a` 字母；`%d` 数字；`%s` 空白；`%w` 字母数字；`%x` 十六进制；`%p` 标点；`%l` 小写；`%u` 大写；`%c` 控制；`%z` 字节 0
- 自定义集合：`[abc]`、范围 `[0-9]`、取反 `[^abc]`
- 特殊字符需转义：`( ) . % + - * ? [ ^ $`，转义符号`%`

**量词**：
- `+`（1 次或多次，贪婪）
- `*`（0 次或多次，贪婪）
- `-`（0 次或多次，最短匹配，非贪婪）
- `?`（0 次或 1 次）

**锚点**：`^` 行首，`$` 行尾

**边界**：`%f[set]` 前沿匹配（集合边界），常用于“单词边界”
  - 规则：
    - 若当前位置的前一个字符 不属于 `set`，且后一个字符 属于 `set`，则匹配该位置（单词开头）。
    - 若当前位置的前一个字符 属于 `set`，且后一个字符 不属于 `set`，则匹配该位置（单词结尾）。
  - 例：`%f[%w]word%f[^%w]` 匹配完整单词 `word`

**配对平衡**：`%bxy` 匹配形如 `x ... y` 的成对结构
  - 例：`%b()` 可匹配括号内的最短内容
    示例：
    ```lua
    print(string.match("[a](bcd)", "%b[]"))   -- [a]
    print(string.match("(abc)def", "%b()"))   -- (abc)
    print(string.match("..word..", "%f[%w]word%f[^%w]")) -- word
    ```

- 用 `()` 标记捕获，按出现顺序编号 `%1`、`%2` …
- 空捕获 `()` 会捕获当前位置（返回一个数字）
- `string.find` 若模式含捕获，会在起止下标之后返回各捕获

示例：
```lua
local s = "name: Anna; age: 24"
local name, age = string.match(s, "name:%s*([^;]+);%s*age:%s*(%d+)")
print(name, age) -- Anna	24

-- 空捕获返回位置
local i1, i2, p = string.find("abc", "a()b")
print(i1, i2, p) -- 1	2	2 （p 为空捕获的位置）

-- 规范化空白：将多个空白压成一个空格
local t = ("a\t b  c\n"):gsub("%s+", " ")
print(t) -- "a b c "

-- 保留部分匹配并包裹
print(("abc123def"):gsub("(%d+)", "<%1>")) -- abc<123>def
```

- 模版替换使用 `%n` 引用捕获，`%%` 表示字面 `%`
- 表替换会用捕获（若有）或整段匹配作为键查表
- 函数替换可根据捕获动态生成文本（返回 `nil`/`false` 表示保持原匹配不变）

**URL编码**

- 典型做法：保留 RFC 3986 中的 unreserved（`%w - _ . ~`），其余转成 `%HH`
- 注意：查询串里常把空格编码为 `+`（视场景决定是否如此）
  ```lua
  local function url_encode(s, space_as_plus)
  s = s:gsub("\n", "\r\n")
  s = s:gsub("([^%w%-_%.~ ])", function(c)
      return string.format("%%%02X", string.byte(c))
  end)
  if space_as_plus then s = s:gsub(" ", "+") end
  return s
  end

  local function url_decode(s)
  s = s:gsub("%+", " ")
  s = s:gsub("%%(%x%x)", function(h)
      return string.char(tonumber(h, 16))
  end)
  s = s:gsub("\r\n", "\n")
  return s
  end
  ```

**制表符展开**

- 目标：把 `\t` 展开为若干空格，使光标列对齐到 `tabsize` 的倍数
- 实现（逐字符处理，正确处理换行）：
    ```lua
    local function expand_tabs(s, tabsize)
    tabsize = tabsize or 8
    local out, col = {}, 0
    for i = 1, #s do
        local ch = s:sub(i, i)
        if ch == "\n" then
        out[#out+1] = ch
        col = 0
        elseif ch == "\t" then
        local n = tabsize - (col % tabsize)
        out[#out+1] = string.rep(" ", n)
        col = col + n
        else
        out[#out+1] = ch
        col = col + 1
        end
    end
    return table.concat(out)
    end

    -- 书上做法
    function expand_tabs(s, tabsize)
      tab = tab or 8
      local col = 0
      s = string.gub(s, "()\t", function(p)
        local n = tabsize - (p - 1 + col) % tabsize
        col = col - 1 + n
        return string.rep(" ", n)
      end)
      return s
    end
    ```

### 练习

练习 10.1

```lua
function Split(s, sep)
    local t = {}
    local i = 1
    for str in string.gmatch(s, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

Sample = "a,b,c,d,e,f,g"
for i, v in ipairs(Split(Sample, ",")) do
    io.write(v, " ")
end
```

练习 10.2

不等价，`[^%d%u]` 是补集，匹配既不是数字也不是大写字母的字符，即 `%D ∩ %U`;`[%D%U]` 是并集，匹配非数字或非大写的任一者，即 `%D ∪ %U`，这对所有字符都为真（因为字符不可能同时是“数字且大写”），因此等价于“任意字符”。

练习 10.3

```lua
function Transliterate(s, t)
    local result = ""
    for i = 1, #s do
        local c = s:sub(i, i)
        if t[c] then
            result = result .. t[c]
        elseif t[c] == nil then
            result = result .. c
        end
    end
    return result
end
```

练习 10.4

`"^%s*(.-)%s*$"` 在“全空白”上会在两侧 `%s*` 与中间 `.-` 之间大量回溯，导致近似 `O(n^2)`。

```lua
local n = 200000
local s = string.rep(" ", n)  -- 全是空白
Trim(s)

function Trim(s)
    local len = #s
    local i = 1
    -- skip leading whitespace (Lua %s: space, \t, \n, \v, \f, \r)
    while i <= len do
        local b = string.byte(s, i)
        if b ~= 32 and b ~= 9 and b ~= 10 and b ~= 11 and b ~= 12 and b ~= 13 then
            break
        end
        i = i + 1
    end
    if i > len then
        return ""
    end
    -- skip trailing whitespace
    local j = len
    while j >= i do
        local b = string.byte(s, j)
        if b ~= 32 and b ~= 9 and b ~= 10 and b ~= 11 and b ~= 12 and b ~= 13 then
            break
        end
        j = j - 1
    end
    return string.sub(s, i, j)
end
```

练习 10.5

```lua
function Escape(binary)
    local parts = { '"' }
    for i = 1, #binary do
        local byte = string.byte(binary, i)
        if byte == 34 then
            -- '"'
            parts[#parts + 1] = '\\"'
        elseif byte == 92 then
            -- '\\'
            parts[#parts + 1] = '\\\\'
        else
            parts[#parts + 1] = string.format("\\x%02X", byte)
        end
    end
    parts[#parts + 1] = '"'

    return table.concat(parts)
end

print(Escape("\0\1hello\200"))

```

练习 10.6

```lua
function Transliterate(s, t)
    local out = {}
    for _, codepoint in utf8.codes(s) do
        local ch = utf8.char(codepoint)
        local repl = t[ch] or t[codepoint]
        out[#out + 1] = repl or ch
    end
    return table.concat(out)
end
```

练习 10.7

```lua
function UTF8Reverse(s)
    local chars = {}
    for _, codepoint in utf8.codes(s) do
        chars[#chars + 1] = utf8.char(codepoint)
    end
    local i, j = 1, #chars
    while i < j do
        chars[i], chars[j] = chars[j], chars[i]
        i = i + 1
        j = j - 1
    end
    return table.concat(chars)
end
```
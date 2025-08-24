## 元表和元方法

### 笔记

**算术运算相关的元方法**

元表可以定义算术运算符的行为。当Lua需要对两个值进行算术运算时，它会检查这些值是否有对应的元方法。

主要的算术元方法包括：
- `__add`：加法运算符 `+`
- `__sub`：减法运算符 `-`
- `__mul`：乘法运算符 `*`
- `__div`：除法运算符 `/`
- `__mod`：取模运算符 `%`
- `__pow`：幂运算符 `^`
- `__unm`：一元减号运算符 `-`（负号）

**关系运算相关的元方法**

关系运算符也可以通过元方法进行定义：
- `__eq`：等于运算符 `==`
- `__lt`：小于运算符 `<`
- `__le`：小于等于运算符 `<=`

大于 `>` 和大于等于 `>=` 是通过对应的小于操作转换得到的。

**库定义相关的元方法**

这些元方法主要用于与Lua标准库的集成：
- `__tostring`：用于 `tostring()` 函数和字符串连接
- `__concat`：连接运算符 `..`
- `__len`：长度运算符 `#`
- `__call`：使表可以像函数一样被调用

**表相关的元方法**

表的访问和修改可以通过以下元方法控制：
- `__index`：访问不存在的字段时调用
- `__newindex`：给不存在的字段赋值时调用

这两个元方法是实现高级表行为的基础。

**__index元方法**

`__index` 元方法在访问表中不存在的字段时被调用。它可以是一个函数或者另一个表。

当作为函数使用：
```lua
local mt = {}

function mt.__index(table, key)
    print("Accessing key: " .. key)
    return "default_value"
end

local t = setmetatable({}, mt)
print(t.foo)  -- 输出：Accessing key: foo 然后是 default_value
```

__**newindex元方法**

`__newindex` 元方法在给表的不存在字段赋值时被调用。

```lua
local mt = {}

function mt.__newindex(table, key, value)
    print("Setting " .. key .. " = " .. tostring(value))
    rawset(table, key, value)  -- 绕过元方法直接设置
end

local t = setmetatable({}, mt)
t.foo = "bar"  -- 输出：Setting foo = bar
```

**具有默认值的表**

使用 `__index` 可以创建具有默认值的表：

```lua
function setdefault(t, d)
    setmetatable(t, {__index = function() return d end})
end

local tab = {x = 10, y = 20}
setdefault(tab, 0)
print(tab.x)    -- 10
print(tab.z)    -- 0 (默认值)

-- 更高效的版本，避免每次都创建新函数
local mt = {__index = function(t, k) return 0 end}
function setdefault_efficient(t)
    setmetatable(t, mt)
end
```

**跟踪对表的访问**

可以使用元方法来监控表的访问模式：

```lua
function track(t)
    local proxy = {}
    local mt = {
        __index = function(_, k)
            print("Accessing key: " .. tostring(k))
            return t[k]
        end,
        __newindex = function(_, k, v)
            print("Setting key " .. tostring(k) .. " to " .. tostring(v))
            t[k] = v
        end
    }
    return setmetatable(proxy, mt)
end

local t = track({})
t.x = 10        -- 输出：Setting key x to 10
print(t.x)      -- 输出：Accessing key: x 然后是 10
```

**只读的表**

通过 `__newindex` 可以创建只读表：

```lua
function readonly(t)
    local proxy = {}
    local mt = {
        __index = t,
        __newindex = function(_, k, v)
            error("Attempt to modify read-only table")
        end
    }
    return setmetatable(proxy, mt)
end

local days = readonly{"Sunday", "Monday", "Tuesday", "Wednesday",
                     "Thursday", "Friday", "Saturday"}

print(days[1])  -- Sunday
-- days[2] = "Noday"  -- 错误：Attempt to modify read-only table
```

### 练习

练习 20.1

```lua
local Set = {}
function Set.new(l)
    local set = {}
    for _, v in ipairs(l) do set[v] = true end
    return setmetatable(set, {__sub = Set.__sub})
end

function Set.__sub(a, b)
    local res = Set.new{}
    for k in pairs(a) do
        if not b[k] then
            res[k] = true
        end
    end
    return res
end

local s1 = Set.new{1, 2, 3, 5, 7}
local s2 = Set.new{2, 4, 6, 8}
local s3 = s1 - s2
for k in pairs(s3) do
    io.write(k, " ")
end
```

练习 20.2

```lua
local Set = {}

function Set.new(l)
    local set = {}
    for _, v in ipairs(l) do set[v] = true end
    return setmetatable(set, {__len = Set.__len})
end

function Set:__len()
    local cnt = 0
    for _, v in pairs(self) do
        cnt = cnt + 1 
    end
    return cnt
end

local s = Set.new{1, 2, 3, 5, 7}
print(#s)
```

练习 20.3

```lua
local readOnlyMT = {
    __index = function(proxy, key)
        local originalTable = getmetatable(proxy).__original
        return originalTable[key]
    end,
    __newindex = function (t, k, v)
        error("attempt to update a read-only table", 2)
    end
}

function readOnlyShared (t)
    local proxy = {}
    local mt = {
        __index = readOnlyMT.__index,
        __newindex = readOnlyMT.__newindex,
        __original = t  -- 保存原始表的引用
    }
    setmetatable(proxy, mt)
    return proxy
end

days = readOnlyShared{"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"}

print(days[1])
```

练习 20.4

```lua
function fileAsArray (filename)
    local file = io.open(filename, "r+b")  -- 修正：使用读写二进制模式
    if not file then
        -- 如果文件不存在，尝试创建
        file = io.open(filename, "w+b")
        if not file then
            error("cannot open file: " .. filename)
        end
    end

    local proxy = {}
    local mt = {
        __index = function (table, key)
            if type(key) ~= "number" or key < 1 then
                error("invalid index: " .. tostring(key))
            end
            
            file:seek("set", key - 1)  -- 修正：定位到指定字节位置
            local byte = file:read(1)  -- 修正：只读取一个字节
            if byte then
                return string.byte(byte)  -- 修正：返回字节值而不是字符
            else
                return nil  -- 超出文件范围
            end
        end,
        __newindex = function (table, key, value)
            if type(key) ~= "number" or key < 1 then
                error("invalid index: " .. tostring(key))
            end
            if type(value) ~= "number" or value < 0 or value > 255 then
                error("invalid byte value: " .. tostring(value))
            end
            
            file:seek("set", key - 1)  -- 修正：定位到指定字节位置
            file:write(string.char(value))  -- 修正：写入单个字节
            file:flush()  -- 确保写入到磁盘
        end,
        __close = function (table)
            file:close()
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

-- 创建一个测试文件
local testFile = "test_bytes.txt"
local f = io.open(testFile, "w")
f:write("Hello, World!")
f:close()

-- 测试按字节操作
local file = fileAsArray(testFile)
```

练习 20.5

```lua
function fileAsArray (filename)
    local file = io.open(filename, "r+b")  -- 修正：使用读写二进制模式
    if not file then
        -- 如果文件不存在，尝试创建
        file = io.open(filename, "w+b")
        if not file then
            error("cannot open file: " .. filename)
        end
    end

    local proxy = {}
    local mt = {
        __index = function (table, key)
            if type(key) ~= "number" or key < 1 then
                error("invalid index: " .. tostring(key))
            end
            
            file:seek("set", key - 1)  -- 修正：定位到指定字节位置
            local byte = file:read(1)  -- 修正：只读取一个字节
            if byte then
                return string.byte(byte)  -- 修正：返回字节值而不是字符
            else
                return nil  -- 超出文件范围
            end
        end,
        __newindex = function (table, key, value)
            if type(key) ~= "number" or key < 1 then
                error("invalid index: " .. tostring(key))
            end
            if type(value) ~= "number" or value < 0 or value > 255 then
                error("invalid byte value: " .. tostring(value))
            end
            
            file:seek("set", key - 1)  -- 修正：定位到指定字节位置
            file:write(string.char(value))  -- 修正：写入单个字节
            file:flush()  -- 确保写入到磁盘
        end,
        __close = function (table)
            file:close()
        end,
        __pairs = function (table)  -- 返回一个迭代器函数
            
            local function iterator(t, index)  -- 迭代器函数接受状态对象和当前索引
                index = index + 1  -- 移动到下一个位置
                file:seek("set", index - 1)  -- 定位到指定字节位置
                local byte = file:read(1)  -- 读取一个字节
                if byte then
                    return index, string.byte(byte)  -- 返回索引和字节值
                else
                    return nil  -- 超出文件范围，结束迭代
                end
            end
            return iterator, table, 0  -- 返回迭代器函数、状态对象、初始索引
        end
    }
    setmetatable(proxy, mt)
    return proxy
end

-- 创建一个测试文件
local testFile = "test_bytes.txt"
local f = io.open(testFile, "w")
f:write("Hello, World!")
f:close()

-- 测试按字节操作
local file = fileAsArray(testFile)
for i, v in pairs(file) do
    print(i, v, string.char(v))
end
```
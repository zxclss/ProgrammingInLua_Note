## 5 表

### 笔记

表是一种动态分配的对象，程序只能操作指向表的引用/指针，即`a = {}; b = a; a = nil;`时，b仍然指向这个表，a作为表的指针制空不影响原表。

`a["str_x"]`等价于`a.str_x`。

`a = {x = 10, y = 20}`等价于`a = {}; a.x = 10; a.y = 20`，前者高效。

通用构造器-方括号：`{x = 0, y = 0}`等价于`{["x"] = 0, ["y"] = 0}`

只建议用`#`索引序列table，有nil的table不要这么干。

遍历table可以用`for k,v in pairs(t)`（无序），遍历序列可以用 `for i, v in ipairs(t)`（有序）或者`for i = 1,#t do`

安全访问的有效方法（避免多次查表的行为，类似C#的安全访问操作符`?.`）：

```lua
-- condition
zip = company and 
        company.director and
        company.director.address and
        company.director.address.zipcode
-- C#
zip = company?.director?.address?.zipcode
-- lua
zip = (((company or {}).director or {}).address or {}).zipcode
-- lua more efficient
E = {}
zip = (((company or E).director or E).address or E).zipcode
```

常用库函数：

1. `table.insert(t, index, value)` index省略则默认最后位置
2. `table.remove(t, index)` index省略则默认最后位置
3. `table.move(t, start, end, index)`
4. `table.move(t, start, end, index, {})` move到新表的index位置

### 练习

练习 5.1

表里的内容是：`t = {"sunday" = "monday", "monday" = "monday"}`
打印的内容是：`t["sunday"], t["monday"], t[t["sunday"]]`

1. `t.sunday = t["sunday"] = "monday"`
2. `t[sunday] = t["monday"] = "monday"`
3. `t[t.sunday] = t["monday"] = "monday"`

练习 5.2

`a`是指向空表`{}`的指针，`a.a; a.a.a; a.a.a.a`都是表里的项，key是`"a"`，value是该表的指针。
会报错，因为`a["a"] = 3`了，所以`a["a"]["a"]`是在索引number，就报错了。

练习 5.3

用方括号的通用构造器：`local a = {["\t"] = "水平制表符 (horizontal tab)"};`

练习 5.4

```lua
local function calpoly(t, x)
    local res, P = 0, 1
    for i = 1, #t do
        res = res + t[i] * P
        P = P * x
    end
    return res
end
```

练习 5.5

同上

练习 5.6

```lua
local function isValidSeq(t)
    local cnt = 1
    for k, v in pairs(t) do
        if k ~= cnt then
            return false
        end
        cnt = cnt + 1
    end
    return true
end
print(isValidSeq({1, 2, 3, 4, 5, 6}) and "yes" or "no")
print(isValidSeq({1, 2, 3, nil, 5, 6}) and "yes" or "no")

```

练习 5.7

```lua
-- lua 5.1
local function insertAt(ori_t, tar_t, index)
    if index > #tar_t then
        return nil
    end
    for i = #tar_t + #ori_t, index + #ori_t, -1 do
        tar_t[i] = tar_t[i - #ori_t]
    end
    for i = 1, #ori_t do
        tar_t[i + index - 1] = ori_t[i]
    end
end

local ori_t = {1, 2, 3, 4, 5}
local tar_t = {6, 7, 8, 9, 10}
local index = 3
insertAt(ori_t, tar_t, index)
print(table.concat(tar_t, " "))
```

练习 5.8

```lua
local function concat(str_list)
    local res = ""
    for _, v in ipairs(str_list) do
        res = res .. v
    end
    return res
end

local function gen_str_list(N)
    local str_list = {}
    for i = 1, N do
        str_list[i] = string.format("%05d", i)
    end
    return str_list
end

local function calTime(func)
    local start_time = os.clock()
    func()
    local end_time = os.clock()
    return end_time - start_time
end

local str_list = gen_str_list(100000)
print(calTime(function()
    concat(str_list)
end).."s")
print(calTime(function()
    table.concat(str_list)
end).."s")

-- 4.481s
-- 0.021s
```
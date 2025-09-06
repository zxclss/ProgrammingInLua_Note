## 6 函数

### 笔记

有默认值的参数的写法：

```lua
function func_haveDefaultValue(parm1)
    parm1 = parm1 or default_Value1
end
```

多返回值的函数有一个逆天的点，当函数调用不是表达式列表的最后一个时，只会返回第一个值。

可变长参数可以用`table.pack`和`select`来处理。

`table.pack`和`table.unpack`对偶，一个是包装数组，一个是拆开数组。（仅限于序列）

lua有尾调用消除，即在函数返回另一个函数时，当前函数会离开调用栈，下层执行完直接往上。尾调用消除不仅限于递归，还适用于任何形式的尾调用，包括函数间的相互调用、状态机模式等。

### 练习

练习 6.1

```lua
local function printList(t)
    for _, v in ipairs(t) do
        io.write(v .. " ")
    end
    print()
end
```

练习 6.2

```lua
local function returnExcept1st(...)
    if select("#", ...) < 2 then
        return nil
    end
    return select(2, ...)
end
-- lua5.2
local function returnExcept1st_(...)
    local t = table.pack(...)
    t:move(1, #t, 2)
    return t
end
```

练习 6.3

```lua
local function returnExceptLast(...)
    local list_len = select("#", ...)
    local res = ""
    for i, v in ipairs({...}) do
        if i == list_len then
            break
        end
        res = res .. v .. " "
    end
    return res
end
```

练习 6.4

```lua
local function shuffleArray(arr)
    local shuffled = {}
    for i = 1, #arr do
        shuffled[i] = arr[i]
    end
    
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    
    return shuffled
end
```

练习 6.5

```lua
local function calCombination(t)
    if #t < 1 then
        return {""}
    end
    local first = table.remove(t, 1)
    local res = calCombination(t)
    for i = 1, #res do
        table.insert(res, first..res[i])
    end
    return res
end

local res = calCombination({1, 2, 3, 4, 5})
for _, v in ipairs(res) do
    io.write(v .. " ")
end
print()
```

练习 6.6

```lua
-- 无限调用链程序 - 展示尾调用消除
-- 这不是递归，而是函数间的相互尾调用

-- 前向声明
local functionA, functionB, functionC

functionA = function(n)
    if n <= 0 then
        return "结束"
    end
    print("函数A: " .. n)
    -- 尾调用：调用functionB，这是最后一个操作
    return functionB(n - 1)
end

functionB = function(n)
    if n <= 0 then
        return "结束"
    end
    print("函数B: " .. n)
    -- 尾调用：调用functionC，这是最后一个操作
    return functionC(n - 1)
end

functionC = function(n)
    if n <= 0 then
        return "结束"
    end
    print("函数C: " .. n)
    -- 尾调用：调用functionA，这是最后一个操作
    return functionA(n - 1)
end

-- 测试无限调用链
local result = functionA(10)
print("最终结果: " .. result)
```

这个程序展示了：
1. 尾调用消除不仅限于递归
2. 函数间的相互调用也可以形成无限调用链
3. 每次调用都是尾调用，所以不会导致栈溢出
4. 可以用于实现状态机、协程等模式

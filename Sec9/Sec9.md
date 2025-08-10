## 9 闭包

### 笔记

非语法糖方式声明函数时，写递归的方法：

```lua
local func  -- 先声明再定义
local func = function(n)
    if n == 0 then return end
    return func(n - 1)
end
```

闭包（Closure）是一个函数和其引用环境的组合。当一个函数被定义在另一个函数内部时，内部函数可以访问外部函数的局部变量，即使外部函数已经执行完毕，这些变量仍然可以被内部函数访问。

闭包的特点：

1. **词法作用域**：函数可以访问其定义时所在作用域中的变量
2. **变量捕获**：内部函数"捕获"外部函数的局部变量
3. **状态保持**：即使外部函数执行完毕，被捕获的变量仍然存在

示例：
```lua
function createCounter()
    local count = 0  -- 外部函数的局部变量
    return function()  -- 返回内部函数
        count = count + 1
        return count
    end
end

local counter1 = createCounter()
local counter2 = createCounter()

print(counter1())  -- 输出: 1
print(counter1())  -- 输出: 2
print(counter2())  -- 输出: 1 (独立的计数器)
```

闭包的2种高级应用：

1. 数据隐藏和封装。由于函数也是变量的一种类型，因此闭包可以用来创建安全的运行时环境，即所谓的沙盒。

```lua
-- 1. 沙盒环境
do
    local oldIOOpen = io.open
    local access_ok = function(filename, mode)
        -- check access
    end
    io.open = function(filename, mode)
        if access_ok(filename, mode) then
            return oldIOOpen(filename, mode)
        else
            return nil, "access denied"
        end
    end
end

-- 2. 函数工厂
function makeAdder(x)
    return function(y)
        return x + y
    end
end

local add5 = makeAdder(5)
local add10 = makeAdder(10)

print(add5(3))   -- 输出: 8
print(add10(3))  -- 输出: 13
```

注意事项：

- 闭包会保持对变量的引用，可能导致内存占用
- 在循环中创建闭包时要注意变量捕获的时机
- 闭包是Lua中实现面向对象编程的重要机制

### 练习

练习 9.1

```lua
local integral = function(f, a, b)
    local n = 1e6
    local w = (b - a) / n
    local sum = 0
    for i = 1, n do
        sum = sum + f(a + (i - 1) * w + w / 2) * w
    end
    return sum
end

print(integral(function(x) return x * x end, 0, 1))
```

练习 9.2

闭包把形参保留了下来。

```bash
10      20
300     100
```

练习 9.3

```lua
local newpoly = function(t)
    return function(x)
        local res = 0
        local P = 1
        for i = 1, #t do
            res = res + t[i] * P
            P = P * x
        end
        return res
    end
end

local f = newpoly({3, 0, 1})
print(f(0))
print(f(5))
print(f(10))
```

练习 9.4

```lua
dofile("geometry.lua")
local c1 = Disk(0, 0, 1)
Plot(Difference(c1, Translate(c1, -0.3, 0)), 50, 50)
```

练习 9.5

```lua
dofile("geometry.lua")

function RotateArea(area, angle)
    -- x' = x*cos(angle) - y*sin(angle)
    -- y' = x*sin(angle) + y*cos(angle)
    return function(x, y)
        local cos_a = math.cos(angle)
        local sin_a = math.sin(angle)
        local x_rotated = x * cos_a + y * sin_a
        local y_rotated = -x * sin_a + y * cos_a
        return area(x_rotated, y_rotated)
    end
end

local rect = Rect(-0.5, 0.5, 0.5, -0.5)
local rotated_rect = RotateArea(rect, math.pi / 4)
print("origin:")
Plot(rect, 50, 50)
print("\nafter:")
Plot(rotated_rect, 50, 50)
```
## 1 Lua语言入门

### 笔记

**lua的8种基本类型**:

1. nil `type(nil)`
2. boolean `type(true)`
3. number `type(1)`
4. string `type("Hello World!")`
5. userdata `type(io.stdin)`
6. function `type(print)`
7. thread `type(type)`
8. table `type({})`

**注释使用方法及技巧**：

```lua
-- 单行注释
--[[
    多行注释
]]


-- 常用注释技巧，多加一个-即可重启代码:
--[[
    print("Hello World!")
--]]

---[[
    print("Hello World!")
--]]
```

**`and`和`or`遵循短路求值**，lua里的三元运算符如下：

```lua
    a and b or c
-- a ? b : c
```

**独立解释器**：

1. 让lua文件变成可以直接执行的脚本，方法是在文件开头加一行路径方便POSIX找到脚本解释器：`#!/usr/local/bin/lua`
2. 完整参数形式：`lua [options] [script [args]]`
3. 在命令行输入代码`-e`：`lua -e "print(math.sin(12))"`
4. 加载文件`-l`：`lua -l xxx.lua`
5. 运行完文件后进入交互模式`-i`：`lua -i -llib -e "x = 10"`
6. 在交互模式下运行文件`dofile`：`> dofile("xxx.lua")`
7. 不想输出结果可以加分号无效表达式，但代码仍然执行
8. 获取参数的方式是使用`args`变量，0是执行的lua文件，-1往前找参数，+1往后找参数。

### 练习

练习 1.1

```lua
#!/bin
function Factorial(n)
    if n < 0 then
        return "Error: Factorial of a negative number is not defined"
    elseif n == 0 then
        return 1
    else
        return n * Factorial(n - 1)
    end
end

print("enter a number:")
a = io.read("*n")
print(Factorial(a))
```

练习 1.2

```shell
lua -l Sec1.p12 -e "print(Twice(3))"
lua -e "dofile('Sec1/p12.lua'); print(Twice(3))"
```

练习 1.3

- SQL 家族: Standard SQL、PostgreSQL、SQLite、MySQL、MariaDB、T‑SQL、PL/SQL
- 函数式系: Haskell、Elm、PureScript、Idris、Agda
- 系统/硬件: Ada、VHDL
- 其他: Eiffel、AppleScript

练习 1.4

1. ---中的-不是标识符字符
2. _end合法
3. End合法
4. end是关键字，非法
5. until?中的?不是标识符字符
6. nil是关键字，非法
7. NULL合法
8. one-step的-不是标识符字符

练习 1.5

打印`type(type(nil))`可知，type返回的是字符串类型，因此 `type(nil)`返回的是`"nil"`，而`"nil" == nil`显然为`false`。

```lua
if type(nil) == "nil" then
    print("type(nil) is a string")
elseif type(nil) == nil then
    print("type(nil) is nil")
else
    print("type(nil) is not a string or nil")
end
```

练习 1.6

```lua
local function is_boolean(x)
    return x == true or x == false
end
local function is_boolean(x)
    return rawequal(x, true) or rawequal(x, false)
end
local function is_boolean(x)
  return x == (not not x)
end
```

练习 1.7

之前提到过 `a and b or c` 是三元表达式，所以 `a1 and a2 and b or c` 根据and的优先级可知是 `(a1 and a2) ? b : c`。

not优先级最大，可以看作和变量是一体的，所以原式等价于：

```lua
(x and y and (not z)) or ((not y) and x)
(x and y) ? not z : ((not y) and x)
```

括号不是必须的，但推荐用啊，因为优先级并不是总能搞对，让读者易读也是写的人的职责。

练习 1.8

```lua
print(arg[0])
```
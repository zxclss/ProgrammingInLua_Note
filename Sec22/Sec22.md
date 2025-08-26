## 22 环境 Environment

### 笔记

**具有动态名称的全局变量**

在Lua中，全局变量实际上存储在一个叫做环境的表中。我们可以使用动态的方式来访问和操作这些全局变量：

```lua
-- 直接访问全局变量
var = "hello"
print(var)  -- "hello"

-- 通过_G表动态访问
_G["var"] = "world"
print(var)  -- "world"

-- 动态访问不存在的变量
varname = "nonexistent"
print(_G[varname])  -- nil

-- 动态创建全局变量
varname = "dynamic_var"
_G[varname] = 42
print(dynamic_var)  -- 42

-- 遍历所有全局变量
for name, value in pairs(_G) do
    print(name, value)
end
```

**全局变量的声明**

- 在Lua中，未使用`local`关键字声明的变量默认为全局变量
- 全局变量存储在全局环境表`_G`中
- `_G`表包含对自身的引用：`_G._G == _G`

```lua
-- 全局变量声明
x = 10               -- 全局变量
_G.y = 20           -- 等价的全局变量声明
_G["z"] = 30        -- 使用字符串索引的全局变量

-- 检查变量是否存在
if _G["some_var"] then
    print("Variable exists")
end

-- 安全地获取全局变量的值
function getGlobal(name, default)
    return _G[name] or default
end

print(getGlobal("undefined_var", "default_value"))  -- "default_value"
```

**非全局环境**

Lua允许为函数设置不同的环境，使函数在执行时使用自定义的变量查找表：

```lua
-- 创建自定义环境
local myenv = {
    print = print,  -- 保留原有的print函数
    x = 100,
    y = 200
}

-- 在自定义环境中执行代码
local function test()
    print("x + y =", x + y)  -- 将使用myenv中的x和y
end

-- 设置函数环境（Lua 5.2+的方式）
debug.setupvalue(test, 1, myenv)
test()  -- 输出: x + y = 300

-- 另一种方式：在代码中直接设置_ENV
local function test_with_env()
    local _ENV = myenv
    print("x * y =", x * y)  -- 使用myenv中的变量
end
test_with_env()  -- 输出: x * y = 20000
```

**使用 _ENV**

`_ENV`是Lua 5.2+中引入的特殊变量，用于控制环境：

```lua
-- _ENV的基本使用
local originalEnv = _ENV

-- 创建新环境
local myEnv = {
    print = print,
    tostring = tostring,
    message = "Hello from custom environment!"
}

-- 切换到新环境
local _ENV = myEnv
print(message)  -- 输出: Hello from custom environment!

-- 恢复原环境
_ENV = originalEnv

-- 使用元表实现环境继承
local function createSandbox()
    local sandbox = {}
    setmetatable(sandbox, {__index = _G})  -- 继承全局环境
    return sandbox
end

local sandbox = createSandbox()
sandbox.safeVar = "This is safe"

-- 在沙盒环境中执行代码
local code = [[
    print("Safe variable:", safeVar)
    -- 仍可访问全局函数，但新变量只在沙盒中
    newVar = "Only in sandbox"
]]

local func = load(code, "sandbox", "t", sandbox)
func()
```

**环境和模块**

环境在模块系统中扮演重要角色，可以用来创建模块的私有空间：

```lua
-- 模块示例：使用环境隔离
local M = {}
local _ENV = M  -- 将模块表设为环境

-- 现在所有的"全局"变量都会进入M表中
version = "1.0"
author = "Lua Developer"

function greet(name)
    return "Hello, " .. name .. "!"
end

function getInfo()
    return "Module version: " .. version .. ", by " .. author
end

-- 将模块暴露给外部
return M

-- 使用模块
-- local mymodule = require("mymodule")
-- print(mymodule.greet("World"))  -- "Hello, World!"
-- print(mymodule.getInfo())       -- "Module version: 1.0, by Lua Developer"
```

**_ENV和load**

`load`函数可以接受环境参数，控制加载代码的执行环境：

```lua
-- 基本的load使用
local code = "return x + y"

-- 为代码提供环境
local env = {x = 10, y = 20}
local func = load(code, "chunk", "t", env)
print(func())  -- 30

-- 安全的代码执行环境
local safeEnv = {
    print = print,
    tostring = tostring,
    tonumber = tonumber,
    type = type,
    pairs = pairs,
    ipairs = pairs,
    -- 不包含io、os等危险函数
}

-- 加载用户代码到安全环境
local userCode = [[
    print("User code executing safely")
    -- io.open() -- 这会出错，因为io不在环境中
]]

local safeFunc, err = load(userCode, "user", "t", safeEnv)
if safeFunc then
    safeFunc()
else
    print("Error:", err)
end

-- 动态环境修改
local dynamicEnv = {}
setmetatable(dynamicEnv, {
    __index = function(t, k)
        print("Accessing:", k)
        return _G[k]  -- 转发到全局环境
    end,
    __newindex = function(t, k, v)
        print("Setting:", k, "=", v)
        rawset(t, k, v)  -- 存储在当前环境
    end
})

local dynamicCode = [[
    x = 42        -- 触发__newindex
    print(x)      -- 触发__index（如果x不在dynamicEnv中）
    print(type)   -- 触发__index，获取全局type函数
]]

local dynamicFunc = load(dynamicCode, "dynamic", "t", dynamicEnv)
dynamicFunc()
```

### 练习

练习 22.1

```lua
function getfield(f)
    -- 检查字符串是否严格符合有效的字段名格式
    -- 只允许字母/下划线开头，后跟字母/数字/下划线，用点分隔的标识符
    -- 使用两个模式：一个匹配单个标识符，另一个匹配多个用点分隔的标识符
    local single_id = "^[%a_][%w_]*$"
    local multi_id = "^[%a_][%w_]*%.[%a_][%w_]*"
    
    if not (string.find(f, single_id) or string.find(f, multi_id)) then
        error("Invalid field name: " .. f)
    end
    
    -- 如果有点分隔符，进一步验证完整格式
    if string.find(f, "%.") then
        -- 检查是否只包含有效的标识符和单个点分隔符
        local parts = {}
        for part in string.gmatch(f, "[^%.]+") do
            if not string.find(part, "^[%a_][%w_]*$") then
                error("Invalid field name: " .. f)
            end
            table.insert(parts, part)
        end
        
        -- 重新构建字符串并检查是否与原字符串相同
        local reconstructed = table.concat(parts, ".")
        if reconstructed ~= f then
            error("Invalid field name: " .. f)
        end
    end
    
    local v = _G
    for w in string.gmatch(f, "[%a_][%w_]*") do
        v = v[w]
        if v == nil then
            return nil
        end
        -- 如果不是表类型且还有更多字段要查找，返回nil
        if type(v) ~= "table" then
            local remaining = string.match(f, w .. "%.(.+)")
            if remaining then
                return nil
            end
        end
    end
    return v
end
```

练习 22.2

```lua
local foo
do
    local _ENV = _ENV
    function foo () print(X) end
end
X = 13
_ENV = nil
foo()
X = 0
```

函数`foo()`成功输出了`13`，因为它在定义时捕获了有效的`_ENV`环境，此时`X=13`。

程序在第9行出错，因为`_ENV`被设置为`nil`后，无法再进行全局变量的赋值操作。

这个例子很好地说明了`Lua`中闭包如何捕获环境变量，以及`_ENV`对全局变量访问的重要性。

练习 22.3

```lua
local print = print
function foo (_ENV, a)
    print(a + b)
end

foo({b = 14}, 12)
foo({b = 10}, 1)
```

第一次调用：`foo({b = 14}, 12)`

- `a = 12, b = 14`（从传入的环境表中获取）

- `print(12 + 14)` → 输出 `26`

第二次调用：`foo({b = 10}, 1)`

- `a = 1, b = 10`（从传入的环境表中获取）

- `print(1 + 10)` → 输出 11

这个例子很好地说明了Lua中如何通过显式传递`_ENV`参数来创建不同的变量查找环境，使得同一个函数可以在不同的环境上下文中执行。
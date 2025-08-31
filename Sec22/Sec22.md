## 22 环境 Environment

### 笔记

**具有动态名称的全局变量**

- 在 Lua 5.2+，每个 chunk/函数都在一个“环境表”中运行；所有“全局变量”其实是对该表的字段访问。默认环境是 `_G`。
- 通过字符串构造（如 "a.b.c"）按需读取/写入，可把路径拆分后在环境表上逐级索引。

```lua
-- 读取：从 root（默认 _G）取以点号分隔的路径
local function getfield(path, root)
  local v = root or _G
  for name in string.gmatch(path, "[%a_][%w_]*") do
    v = v[name]
    if v == nil then return nil end
  end
  return v
end

-- 写入：必要时创建中间表
local function setfield(path, value, root)
  local t = root or _G
  local last
  for name in string.gmatch(path, "([%a_][%w_]*)%.?") do
    if last then
      t[last] = t[last] or {}
      t = t[last]
    end
    last = name
  end
  t[last] = value
end

setfield("pkg.sub.answer", 42)
print(getfield("pkg.sub.answer")) -- 42
```

- 若要绕过元方法，使用 `rawget/rawset` 访问表字段。

**全局变量的声明**

- 未声明直接赋值会写入当前 `_ENV`：`x = 10` 等价于 `_ENV.x = 10`。易因拼写错误引入隐式全局。
- 最佳实践：
  - 始终用 `local` 声明新名字。
  - 仅在极少数需要暴露为全局时，显式写入 `_G`（或用 `rawset(_G, "NAME", v)`）。

```lua
-- 简单“strict”全局：禁止读/写未声明的全局
setmetatable(_G, {
  __newindex = function(_, k, v)
    error("attempt to create global '" .. tostring(k) .."'", 2)
  end,
  __index = function(_, k)
    error("attempt to read undeclared global '" .. tostring(k) .."'", 2)
  end
})

-- 显式创建全局（绕过 strict）
rawset(_G, "APP_VERSION", "1.0.0")
```

**非全局环境**

- 通过自定义环境表可以隔离、限制或定制名字解析，实现沙箱或命名空间。
- 常见做法：让新环境“只暴露需要的 API”，并通过 `__index = _G` 回退到标准库（或完全禁止回退）。

```lua
-- 受限沙箱：只允许 print 与部分 math
local sandbox = {
  print = print,
  math = { abs = math.abs, max = math.max }
}
setmetatable(sandbox, {
  __index = function(_, k) error("access to global '" .. k .. "' denied", 2) end
})

local code = [[
  print(math.abs(-3))
  return (unknown or 0) + 1 -- 触发错误：unknown 不可访问
]]

local f = load(code, "sandbox", "t", sandbox)
print(pcall(f)) -- false  错误信息
```

- 若需要保留标准库，可用：`setmetatable(env, { __index = _G })`。

**使用 _ENV**

- `_ENV` 是一个普通上值；编译器会把对自由名字 `a` 的访问重写为 `_ENV.a`。
- 通过在块内创建新的 `_ENV`，可为该块及其中定义的函数设定词法环境。

```lua
local print = print -- 把常用全局提前缓存为局部
do
  local _ENV = setmetatable({ x = 10, print = print }, { __index = _G })
  function show() print(x) end   -- 等价于 _ENV.print(_ENV.x)
  x = x + 1
  show() -- 11
end
```

- 给函数显式传入 `_ENV` 也是一种模式（见练习 22.3），可让同一函数在不同环境下运行。

**环境和模块**

- 推荐的模块写法：返回一个表；可用 `_ENV` 把模块内“全局”定向到该表。
- 如需自动继承标准库，可以给模块表设置 `__index = _G`。

```lua
-- mymath.lua
local M = {}
setmetatable(M, { __index = _G }) -- 可选：继承标准库
local _ENV = M                    -- 之后的“全局”都写入 M

pi = 3.141592653589793
function add(x, y) return x + y end
function area(r) return pi * r * r end

return M

-- 使用
-- local mymath = require "mymath"
-- print(mymath.add(1, 2), mymath.pi)
```

- 不再推荐使用旧的 `module(...)`（在新版本中已移除/弃用）。

**_ENV和load**

- `load(chunk [, chunkname [, mode [, env]]])` 会返回一个函数；若提供 `env`，该函数在此环境中运行，其 `_ENV` 上值被设为 `env`。
- 典型用法：为动态代码提供隔离/定制的环境。

```lua
-- 独立环境，不影响全局 _G
local f = load("x = x + 1; return x", "inc", "t", { x = 41, print = print })
print(f()) -- 42

-- 带回退到标准库
local env = setmetatable({ x = 10 }, { __index = _G })
local g = load("print(x, type(math), math.pi)", "demo", "t", env)
g() -- 10 table 3.141592653589793
```

- `loadfile` 与 `load` 一样可指定 `env`；`dofile` 则直接在当前全局环境运行。

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
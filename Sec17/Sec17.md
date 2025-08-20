## 模块和包

### 笔记

**函数 require**

- 基本语义：`require(modname)` 按搜索器顺序查找并加载模块，只执行一次；成功后结果缓存在 `package.loaded[modname]`，以后再次调用直接返回缓存。
- 返回值与缓存：
  - 模块 chunk 若返回非 `nil` 值，`require` 将该值写入 `package.loaded[modname]` 并返回它。
  - 若未显式返回，通常会把 `package.loaded[modname]` 置为 `true`（历史习惯），调用方拿到的就是该值；实际工程中建议“返回模块表”。
  - 若你把 `package.loaded[modname]` 设为任意非 `nil` 值（包括 `false`），`require` 都会把它当作“已加载”并直接返回。
- 幂等与循环依赖：
  - `require` 幂等：同一 `modname` 只初始化一次。
  - 循环依赖时，常见技巧是“在模块顶端尽早写入 `package.loaded[...] = M`”，允许对方在初始化早期拿到（可能尚未完全填充的）模块表。
- 名字与路径映射：`modname` 中的 `.` 会映射为目录分隔（如 `a.b.c` → `a/b/c`），并尝试 `?.lua` 与 `?/init.lua` 等模式。

**模块重命名**

- C 模块的导出函数名规则：`luaopen_<modname>`，其中把 `modname` 中的 `.` 替换为 `_`。因此模块名应尽量使用 C 标识符风格（字母/数字/下划线）。
- 版本化文件名与符号名：可以给动态库文件加版本后缀（如 `mod-v3.4.dll`/`mod-v3.4.so`），但导出符号仍必须是 `luaopen_mod`（而不是 `luaopen_mod-v3_4`）。
- 做法一（推荐）：保持 `require("mod")`，仅通过 `package.cpath` 匹配到带版本的文件名：
```lua
-- Windows 举例
package.cpath = "./?.dll;./?-v3.4.dll;" .. package.cpath
local m = require "mod"   -- 将加载 mod-v3.4.dll 并查找符号 luaopen_mod
```
- 做法二：为版本名提供别名，允许 `require("mod-v3.4")` 复用同一实现：
```lua
package.preload["mod-v3.4"] = function() return require("mod") end
```
- 若需要并存多个版本，可用不同模块名（如 `mod_v3` 导出 `luaopen_mod_v3`），或通过调整 `package.cpath` 顺序决定优先加载的库文件。

**搜索路径**

- `package.path`：Lua 模块搜索路径（文本 `.lua`）。形如：`"?.lua;?/init.lua;./libs/?.lua;./libs/?/init.lua"`。
- `package.cpath`：C 模块搜索路径（`.so`/`.dll`）。
- 环境变量：`LUA_PATH`、`LUA_CPATH` 可覆盖默认值；路径段用 `;` 分隔，`?` 会被模块名（把 `.` 替换为目录分隔符）替换。
- 典型用法：
```lua
print("path=", package.path)
package.path = package.path .. ";./third/?.lua;./third/?/init.lua"
```

**搜索器**

- 5.2+ 为 `package.searchers`（5.1 为 `package.loaders`），按顺序尝试：
  1) `preload`：查 `package.preload[modname]` 的加载器函数；
  2) Lua 加载器：按 `package.path` 试 `?.lua`、`?/init.lua`；
  3) C 加载器：按 `package.cpath` 试动态库，并寻找导出符号 `luaopen_<modname>`（`modname` 的 `.` 替换为 `_`）；
  4) 其他（平台相关）。
- 自定义加载器示例（把内存中的字符串表当作模块源）：
```lua
local sources = { ["mem.hello"] = "return { hi=function() print('hi') end }" }
local function memory_searcher(name)
  local src = sources[name]
  if not src then return nil, "no memory module: " .. name end
  local loader, err = load(src, "@mem:"..name)
  if not loader then return nil, err end
  return function(modname)
    return loader()
  end
end

local searchers = package.searchers or package.loaders
table.insert(searchers, 1, memory_searcher)
```

**Lua语言中编写模块的基本方法**

- **推荐写法（返回表）**：
```lua
-- file: my/mathutil.lua
local M = {}

local function check_number(x)
  assert(type(x) == "number", "number expected")
end

function M.clamp(x, lo, hi)
  check_number(x); check_number(lo); check_number(hi)
  if x < lo then return lo end
  if x > hi then return hi end
  return x
end

return M
```
- **面向对象风格**：
```lua
-- file: my/stack.lua
local Stack = {}
Stack.__index = Stack

function Stack.new()
  return setmetatable({ data = {} }, Stack)
end
function Stack:push(v) self.data[#self.data+1] = v end
function Stack:pop() local d = self.data; local v = d[#d]; d[#d] = nil; return v end

return Stack
```
- 不建议再使用历史的 `module(...)` 方式；保持“`local` 顶层 + `return` 模块表”的习惯更清晰、可控。

**子模块和包**

- 目录结构：
```
my/                <-- 包名 my
  init.lua         <-- require "my"
  util.lua         <-- require "my.util"
  http/
    client.lua     <-- require "my.http.client"
```
- `init.lua` 可以组织并导出子模块，同时处理循环依赖：
```lua
-- file: my/init.lua
local M = { _VERSION = "1.0.0" }
package.loaded[...] = M              -- 提前暴露，缓解相互 require 时的循环依赖

M.util   = require((...) .. ".util")
M.http   = { client = require((...) .. ".http.client") }

return M
```
- 子模块文件各自 `return` 自己的表；使用处：
```lua
local my = require "my"
print(my._VERSION)
my.util.someFunc()
local client = my.http.client.new()
```

### 练习

练习 17.1

```lua
function listNew()
    return {first = 0, last = -1}
end

function pushFirst(list, value)
    local first = list.first - 1
    list.first = first
    list[first] = value
end

function popFirst(list)
    local first = list.first
    if first > list.last then
        return nil
    end
    local value = list[first]
    list[first] = nil
    list.first = first + 1
    return value
end

function popLast(list)
    local last = list.last
    if last < list.first then
        return nil
    end
    local value = list[last]
    list[last] = nil
    list.last = last - 1
    return value
end

return {
    pushFirst = pushFirst,
    popFirst = popFirst,
    popLast = popLast,
    listNew = listNew,
}
```

练习 17.2

```lua
function Disk(cx, cy, r)
    return function(x, y)
        return (x - cx) ^ 2 + (y - cy) ^ 2 <= r ^ 2
    end
end

function Rect(left, right, top, bottom)
    return function(x, y)
        return x >= left and x <= right and y >= bottom and y <= top
    end
end

function Union(f1, f2)
    return function(x, y)
        return f1(x, y) or f2(x, y)
    end
end

function Intersection(f1, f2)
    return function(x, y)
        return f1(x, y) and f2(x, y)
    end
end

function Difference(f1, f2)
    return function(x, y)
        return f1(x, y) and not f2(x, y)
    end
end

function Translate(r, dx, dy)
    return function(x, y)
        return r(x - dx, y - dy)
    end
end

function Plot(r, M, N)
    io.write("P1\n", M, " ", N, "\n")
    for i = 1, N do
        local y = (N - i * 2) / N
        for j = 1, M do
            local x = (j * 2 - M) / M
            io.write(r(x, y) and "1 " or "0 ")
        end
        io.write("\n")
    end
end

return {
    Disk = Disk,
    Rect = Rect,
    Union = Union,
    Intersection = Intersection,
    Difference = Difference,
    Translate = Translate,
    Plot = Plot,
}
```

练习 17.3

**会发生什么**？

该路径段被当作“字面文件名”尝试，因没有 ?，不会做名字替换；对任意 require("xxx")，都会先尝试加载这同一个文件。若能成功加载，搜索立即停止，执行得到的 chunk 作为此 modname 的加载器被调用，其返回值写入 package.loaded[modname] 并作为 require 的返回。

**有什么用**？
- **统一调度/别名映射**：用一个固定的 Lua 文件作为“调度器”，根据 modname 决定实际返回哪个模块（或填充 package.preload[modname] 后再转发），从而实现别名、版本映射、兼容层。
- **单文件打包**：把多个 Lua 子模块逻辑集中在一个文件中，由该文件按 modname 分发。
- **C 库的一体化加载**：在 package.cpath 放入固定 .so/.dll（经典例子是 loadall.so）。对于任意 require("x.y") 都加载这同一个库文件，再在其中查找 luaopen_x_y 符号，实现一个库文件导出多个模块入口。
- **启动/引导**：作为通用引导脚本，第一次被命中时调整 package.searchers、package.path、预填 preload 等。

**注意**
- 它会“拦截”所有模块名；若该固定文件存在，后续正常路径将不会再被尝试。
- 返回值将分别写入不同的 package.loaded[modname]；若该文件总是返回同一表，不同名字将共享同一实例（可能是有意也可能引发混淆）。

练习 17.4

```lua
local function combinedSearcher(modname)
	local combinedPath = package.path .. ";" .. package.cpath
	local filename, searchErr = package.searchpath(modname, combinedPath)
	if not filename then
		return "\n\t" .. tostring(searchErr)
	end

	local loader, luaErr = loadfile(filename)
	if loader then
		return loader, filename
	end

	local initFunc = "luaopen_" .. (modname:gsub("%.", "_"))
	local cfunc, cErr = package.loadlib(filename, initFunc)
	if cfunc then
		return cfunc, filename
	end

	local msg = string.format(
		"\n\tno loader for file '%s'\n\tloadfile error: %s\n\tloadlib error: %s",
		filename,
		tostring(luaErr),
		tostring(cErr)
	)
	return msg
end

-- insert after preloader, before default Lua/C searchers
if type(package.searchers) == "table" then
	table.insert(package.searchers, 2, combinedSearcher)
end
```
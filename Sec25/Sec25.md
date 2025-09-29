## 反射（Reflection）

### 笔记

**自省机制（Introspective Facility）**

- **核心**: 通过 `debug` 库访问运行时信息（仅用于调试/工具，不建议在生产逻辑中依赖）。
- **调用栈层级（level）**: 0 为 `debug` 自身；1 为当前正在调用 `debug` 的函数；2 为其调用者；依此类推。
- **获取基本信息**: `debug.getinfo([thread,] level|func, what)`，`what` 由字符组成（常用 "nSluf"）：
  - **n**: 函数名与名的来源（`name`, `namewhat`）
  - **S**: 源信息（`short_src`, `linedefined`, `lastlinedefined`, `what`）
  - **l**: 当前行（`currentline`，仅当处在活跃栈帧时）
  - **u**: upvalue、参数数量（`nups`, `nparams`, `isvararg`）
  - **f**: 返回函数本身（`func`）

**访问局部变量**

- 使用 `debug.getlocal([thread,] level, index)` 读取，`debug.setlocal([thread,] level, index, value)` 修改。
- `index` 从 1 开始递增，直到返回 `nil` 表示没有更多局部变量；可能出现 `(*temporary)` 等内部名。

```lua
local function demo(a, b)
  local x = 42
  -- 列出当前栈帧（level=1）的所有局部变量
  local i = 1
  while true do
    local name, val = debug.getlocal(1, i)
    if not name then break end
    print(i, name, val)
    i = i + 1
  end

  -- 修改第3个局部变量（此处一般是 x）
  debug.setlocal(1, 3, 99)
  return x
end

print(demo(10, 20)) -- 99（被修改）
```

- 注意：修改局部变量会影响后续执行，仅在调试/诊断工具中使用。

**访问非局部变量**

- 闭包的 upvalue 可通过 `debug.getupvalue(func, index)`、`debug.setupvalue(func, index, value)` 访问与修改。
- 比较/合并 upvalue：`debug.upvalueid(func, index)` 获取唯一标识；`debug.upvaluejoin(f1,i1,f2,i2)` 让两个闭包共享同一个 upvalue。

```lua
local function makeCounter()
  local count = 0
  return function()
    count = count + 1
    return count
  end
end

local c1, c2 = makeCounter(), makeCounter()
print(debug.getupvalue(c1, 1)) -- count, 0（或执行后为其它值）

-- 比较是否共享同一 upvalue
print(debug.upvalueid(c1, 1) == debug.upvalueid(c2, 1)) -- false

-- 让两个计数器共享同一个 upvalue
debug.upvaluejoin(c1, 1, c2, 1)
print(debug.upvalueid(c1, 1) == debug.upvalueid(c2, 1)) -- true
```

**访问其他协程**

- 多数 `debug` API 接受可选的 `thread` 参数：当传入协程对象时，操作发生在该协程的栈上。
- 仅当协程处于可检查状态（如 `suspended`）时，才能安全读取其局部变量/栈信息。

```lua
local co = coroutine.create(function(a)
  local x = 10
  coroutine.yield("paused")
  return a + x
end)

coroutine.resume(co, 5) -- => "paused"

-- 列出协程当前帧（level=1）的局部变量
local i = 1
while true do
  local name, val = debug.getlocal(co, 1, i)
  if not name then break end
  print(i, name, val)
  i = i + 1
end

-- 协程的栈回溯
print(debug.traceback(co))

coroutine.resume(co) -- 结束协程
```

**钩子（Hook）**

- 使用 `debug.sethook([thread,] hook, mask[, count])` 安装钩子；`mask` 包含：
  - **"c"**: 函数调用事件（call）
  - **"r"**: 函数返回事件（return；包含 tail return）
  - **"l"**: 行事件（line）
  - `count`>0 时启用“指令计数”钩子（每执行 `count` 条指令触发一次）
- `hook` 形如 `function(event, line)`；在钩子中用 `debug.getinfo(2, "nSluf")` 获取触发点的函数信息。
- 取消钩子：`debug.sethook()`（或传入 `nil`）。

```lua
local function hook(event, line)
  local info = debug.getinfo(2, "nSl")
  print(('[%s] %s:%s %s')
    :format(event, info.short_src, tostring(line or info.currentline), info.name or "(anonymous)"))
end

-- 监听调用/返回/逐行
debug.sethook(hook, "crl")

local function f(n)
  if n <= 1 then return 1 end
  return n * f(n - 1)
end
f(3)

-- 移除钩子
debug.sethook()
```

- 钩子频繁触发，可能显著降低性能；仅在调试/分析期间启用。

**调优（Profile）**

- 基于钩子的两类思路：
  - **计时型（call/return）**：在调用/返回之间累积耗时，得到“包含时间”（inclusive time）。
  - **采样型（count/line）**：定期采样当前执行点，近似定位热点（低开销但非精确）。

```lua
-- 简单计时型 profiler（包含时间）
local stats, stack = {}, {}

local function key(info)
  return string.format("%s:%d", info.short_src, info.linedefined)
end

local function prof(event)
  local info = debug.getinfo(2, "nS")
  if event == "call" or event == "tail return" then
    stack[#stack+1] = { info = info, t0 = os.clock() }
  elseif event == "return" then
    local rec = stack[#stack]; stack[#stack] = nil
    local dt = os.clock() - rec.t0
    local k = key(rec.info)
    local s = stats[k] or { name = rec.info.name or "(anonymous)", src = rec.info.short_src, line = rec.info.linedefined, time = 0, calls = 0 }
    s.time, s.calls = s.time + dt, s.calls + 1
    stats[k] = s
  end
end

debug.sethook(prof, "cr")
-- 运行待分析的工作负载...
-- ...

debug.sethook()
for _, s in pairs(stats) do
  print(string.format("%-20s %s:%d  calls=%d  time=%.4f",
    s.name, s.src, s.line, s.calls, s.time))
end
```

```lua
-- 采样型 profiler（每执行 N 条指令采样一次）
local samples = {}

debug.sethook(function()
  local info = debug.getinfo(2, "nSl")
  local k = string.format("%s:%d", info.short_src, info.currentline or -1)
  samples[k] = (samples[k] or 0) + 1
end, "", 10000)  -- 每 10000 条指令采样一次

-- 运行待分析的工作负载...
-- ...

debug.sethook()

-- 输出采样结果（命中次数越多，越可能是热点）
for loc, cnt in pairs(samples) do
  print(loc, cnt)
end
```

- 注意：计时型需要处理递归与“自身时间/子调用时间”的归并（上例为简单版本，统计的是包含时间）。采样型结果具有统计波动，需多次运行取平均/中位数。

**沙盒（Sandbox）**

- 通过 `load(chunk, chunkname, mode, env)`（Lua 5.2+）给不可信代码提供受限环境；避免暴露 `io`/`os`/`debug` 等敏感能力。
- 白名单策略：仅暴露安全子集；对 `table`/`string`/`math` 等模块拷贝必要函数；不给出可变更原表的引用。
- 资源限制：协程级 hook，限制指令步数/时间/内存（粗粒度）。

```lua
-- 协程级 hook：步数 + 时间 + 内存限制（内存为 Lua 状态总量，粗粒度）
local function run_with_limits(user_code, opts, env)
  opts = opts or {}
  local max_instructions = opts.max_instructions or 200000
  local max_seconds = opts.max_seconds or 0      -- 0 表示不限
  local max_kbytes = opts.max_kbytes or 0        -- 0 表示不限

  env = env or {}
  setmetatable(env, { __index = function() return nil end })

  local chunk, err = load(user_code, "user", "t", env)
  if not chunk then return false, err end

  local co = coroutine.create(chunk)

  local tick = math.max(1, math.floor(max_instructions / 100))
  local steps_acc = 0
  local start_clock = os.clock()
  local start_mem_kb = collectgarbage("count")

  local function guard(event, line)
    steps_acc = steps_acc + tick
    if steps_acc > max_instructions then
      error("instruction limit exceeded", 2)
    end
    if max_seconds > 0 and (os.clock() - start_clock) > max_seconds then
      error("time limit exceeded", 2)
    end
    if max_kbytes > 0 and (collectgarbage("count") - start_mem_kb) > max_kbytes then
      error("memory limit exceeded", 2)
    end
  end

  -- 只给目标协程安装 hook（count按照每tick行进行触发）
  debug.sethook(co, guard, "", tick)

  local results = { coroutine.resume(co) }
  debug.sethook(co) -- 移除 hook
  return table.unpack(results)
end

-- 示例：限制 2e5 指令、0.05s 与 +512KB
local code = [[
  local t = {}
  for i=1,1e9 do
    t[i] = i
  end
  return #t
]]

local ok, res_or_err = run_with_limits(code, { max_instructions = 200000, max_seconds = 0.05, max_kbytes = 512 }, {})
print(ok, res_or_err)
```

- Lua 5.1 中可用 `setfenv`/`getfenv` 对函数设置环境；5.2+ 已移除，统一通过 `load` 的 `env` 参数与 upvalue 机制实现。

### 练习

练习 25.1

```lua
function getvarvalue(a, b, c, d)
    -- 支持可选协程参数：[thread,] name, level, isenv
    local thread, name, level, isenv
    if type(a) == "thread" then
        thread, name, level, isenv = a, b, c, d
    else
        thread, name, level, isenv = nil, a, b, c
    end

    local value
    local found = false

    -- 若提供了 thread，则 level 直接针对该协程的调用栈；
    -- 否则（当前协程）需要 +1 跳过本函数自身。
    if thread then
        level = level or 1
    else
        level = (level or 1) + 1
    end

    -- 尝试局部变量
    for i = 1, math.huge do
        local n, v
        if thread then
            n, v = debug.getlocal(thread, level, i)
        else
            n, v = debug.getlocal(level, i)
        end
        if not n then break end
        if n == name then
            value = v
            found = true
        end
    end
    if found then return "local", value end

    -- 尝试非局部变量
    local func
    if thread then
        func = debug.getinfo(thread, level, "f").func
    else
        func = debug.getinfo(level, "f").func
    end
    for i = 1, math.huge do
        local n, v = debug.getupvalue(func, i)
        if not n then break end
        if n == name then return "upvalue", v end
    end

    if isenv then return "noenv" end -- 避免循环

    -- 没找到；从环境变量中获取值
    local _, env
    if thread then
        _, env = getvarvalue(thread, "_ENV", level, true)
    else
        _, env = getvarvalue("_ENV", level, true)
    end
    if env then
        return "global", env[name]
    else    -- 没有有效的 _ENV
        return "noenv"
    end
end

function case1()
    local a = 4; print(getvarvalue("a"))
end

function case2()
    a = "xx"; print(getvarvalue("a"))
    a = nil;
end

case1()
case2()

function case3()
    -- 创建协程并在其内部构造局部变量、上值以及设置全局变量
    local u = "UPVALUE_IN_CO"
    local co = coroutine.create(function()
        local function inner()
            local l = "LOCAL_" .. u  -- 确保捕获上值 u
            a = "GLOBAL_FROM_CO"      -- 设置全局，便于 global 路径测试
            coroutine.yield("yielded")
            return l
        end
        inner()
    end)

    local ok, msg = coroutine.resume(co)
    print("-- case3 first resume:", ok, msg)

    -- 在协程调用栈 level=1（当前为 inner）上读取不同类别的变量
    print(getvarvalue(co, "l", 1))  -- 期望：local
    print(getvarvalue(co, "u", 1))  -- 期望：upvalue
    print(getvarvalue(co, "a", 1))  -- 期望：global

    -- 继续运行直至结束
    local ok2, ret = coroutine.resume(co)
    print("-- case3 second resume:", ok2, ret)
end

case3()
```

练习 25.2

```lua
function setvarvalue(name, newvalue, level, isenv)
    local updated = false

    level = (level or 1) + 1
    -- 尝试局部变量
    for i = 1, math.huge do
        local n = debug.getlocal(level, i)
        if not n then break end
        if n == name then
            debug.setlocal(level, i, newvalue)
            updated = true
        end
    end
    if updated then return "local" end

    -- 尝试非局部变量
    local func = debug.getinfo(level, "f").func
    for i = 1, math.huge do
        local n = debug.getupvalue(func, i)
        if not n then break end
        if n == name then
            debug.setupvalue(func, i, newvalue)
            return "upvalue"
        end
    end

    if isenv then return "noenv" end -- 避免循环

    -- 没找到；设置环境变量
    local _, env = getvarvalue("_ENV", level, true)
    if env then
        env[name] = newvalue
        return "global"
    else    -- 没有有效的 _ENV
        return "noenv"
    end
end
```

练习 25.3

```lua
function getvarvaluetable(level)
    local visible = {}
    local shadowNil = {}
    local baseEnv = nil

    level = (level or 1) + 1

    -- 先收集非局部变量（上值）。记录 _ENV 以便继承
    local func = debug.getinfo(level, "f").func
    for i = 1, math.huge do
        local name, value = debug.getupvalue(func, i)
        if not name then break end
        if name == "_ENV" then
            baseEnv = value
        else
            if value == nil then
                shadowNil[name] = true
            else
                visible[name] = value
            end
        end
    end

    -- 再收集局部变量，使其遮蔽上值
    for i = 1, math.huge do
        local name, value = debug.getlocal(level, i)
        if not name then break end
        if name ~= "_ENV" then
            if value == nil then
                shadowNil[name] = true
                visible[name] = nil
            else
                visible[name] = value
            end
        end
    end

    -- 通过元表从原来的 _ENV 继承未在可见表中的名字
    setmetatable(visible, {
        __index = function(_, key)
            if shadowNil[key] then return nil end
            return baseEnv and baseEnv[key] or nil
        end
    })

    return visible
end
```

练习 25.4

```lua
-- 需已有 getvarvalue
---@diagnostic disable-next-line: duplicate-set-field
function debug.debug(prompt)
    prompt = prompt or "lex> "

    if type(getvarvalue) ~= "function" then
        io.write("[lexdebug] 需要先提供 getvarvalue。\n")
        return
    end

    local env = setmetatable({}, {
        __index = function(_, key)
            local _, v = getvarvalue(key, 4)
            return v
        end
    })

    io.write("-- lexical debug -- 输入 cont 继续 --\n")
    while true do
        io.write(prompt)
        local line = io.read("*l")
        if line == nil or line == "cont" then io.write("\n"); break end

        local chunk, err = load("return " .. line, "=(lexdebug)", "t", env)
        if not chunk then chunk, err = load(line, "=(lexdebug)", "t", env) end

        if not chunk then
            io.write(tostring(err) .. "\n")
        else
            local res = table.pack(pcall(chunk))
            if not res[1] then
                io.write(tostring(res[2]) .. "\n")
            elseif res.n > 1 then
                print(table.unpack(res, 2, res.n))
            end
        end
    end
end
```

练习 25.5

```lua
env = setmetatable({}, {
    __index = function(_, key)
        local _, v = getvarvalue(key, 4)
        return v
    end,
    __newindex = function(t, key, value)
        local kind = setvarvalue(key, value, 4)
        if kind == "noenv" then
            rawset(t, key, value)
        end
    end,
})
```

练习 25.6

```lua
-- Collect and sort results for pretty printing
local entries = {}
for func, count in pairs(Counters) do
    table.insert(entries, { name = getname(func), count = count })
end
table.sort(entries, function(a, b)
    if a.count ~= b.count then
        return a.count > b.count -- sort by count desc
    else
        return a.name < b.name   -- tie-break by name asc
    end
end)
```

练习 25.7

```lua
function M.setbreakpoint(func, line)
  if type(func) ~= "function" then
    error("setbreakpoint: first argument must be a function", 2)
  end
  if type(line) ~= "number" then
    error("setbreakpoint: second argument must be a line number", 2)
  end

  nextHandleId = nextHandleId + 1
  local handle = { __breakpoint_handle_id = nextHandleId }

  local byFunc = breakpointsByFunc[func]
  if not byFunc then
    byFunc = { lines = {}, totalCount = 0 }
    breakpointsByFunc[func] = byFunc
  end

  local byLine = byFunc.lines[line]
  if not byLine then
    byLine = { count = 0 }
    byFunc.lines[line] = byLine
  end

  if not byLine[handle] then
    byLine[handle] = true
    byLine.count = byLine.count + 1
    byFunc.totalCount = byFunc.totalCount + 1
  end

  handleToBreakpoint[handle] = { func = func, line = line }

  updateHookMask()
  return handle
end

function M.removebreakpoint(handle)
  local bp = handleToBreakpoint[handle]
  if not bp then return false end

  local func = bp.func
  local line = bp.line
  local byFunc = breakpointsByFunc[func]
  if byFunc then
    local byLine = byFunc.lines[line]
    if byLine and byLine[handle] then
      byLine[handle] = nil
      byLine.count = byLine.count - 1
      byFunc.totalCount = byFunc.totalCount - 1
      if byLine.count <= 0 then
        byFunc.lines[line] = nil
      end
      if byFunc.totalCount <= 0 then
        breakpointsByFunc[func] = nil
      end
    end
  end

  handleToBreakpoint[handle] = nil
  updateHookMask()
  return true
end
```

练习 25.8

```lua
local env = {}
env._G = env -- 让沙盒内的代码可以通过 _G 访问到自身定义的全局函数/变量
local f = assert(loadfile(arg[1], "t", env))
```
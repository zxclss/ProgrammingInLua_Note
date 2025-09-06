## 24 协程

### 笔记

**协程基础**

- 定义：协程是合作式多任务，单线程内在多个执行栈之间切换，切换点由代码通过 `coroutine.yield` 显式让出。
- 核心API：
  - `coroutine.create(f)`: 创建协程；
  - `coroutine.resume(co, ...)`: 恢复执行，向 `yield/函数` 传参；返回 `ok, ...`；
  - `coroutine.yield(...)`: 让出执行，并把返回值交给 `resume`；
  - `coroutine.status(co)`: `running|suspended|normal|dead`；
  - `coroutine.wrap(f)`: 返回一个函数，调用即 `resume`，错误会直接抛出。
- 生命周期：函数首次在 `resume` 时开始执行；函数 `return` 或出错后协程变为 `dead`，不能再次恢复。
- 错误处理：用 `assert(coroutine.resume(...))` 或检查返回的 `ok`；`wrap` 会直接抛出，常用于简化迭代器写法。
- 注意：只能在被 `resume` 起来的协程内部 `yield`；不要从普通回调里直接 `yield`。

示例：生产者-消费者

```lua
local function producer()
  for i = 1, 3 do
    coroutine.yield(i)
  end
end

local co = coroutine.create(producer)
while true do
  local ok, value = coroutine.resume(co)
  if not ok then error(value) end
  if coroutine.status(co) == "dead" then break end
  print("consume", value)
end
```

**哪个协程占据主循环**

- 经验法则：让“调度/驱动器”协程占据主循环（事件循环、轮询或帧循环），工作协程在需要等待时 `yield`，由驱动器在事件就绪时 `resume`。
- 好处：主循环集中管理时序与资源，工作协程以顺序风格书写（看起来像同步代码）。

简易调度器雏形

```lua
local tasks = {}

local function spawn(f)
  local co = coroutine.create(f)
  table.insert(tasks, co)
end

local function run()
  while #tasks > 0 do
    local co = table.remove(tasks, 1)
    local ok, want = coroutine.resume(co)
    if not ok then error(want) end
    if coroutine.status(co) ~= "dead" then
      table.insert(tasks, co)
    end
  end
end

spawn(function()
  for i = 1, 2 do
    print("A", i)
    coroutine.yield()
  end
end)

spawn(function()
  print("B start")
  coroutine.yield()
  print("B end")
end)

run()
```

**将协程用作迭代器**

- 思想：让生成器在有新值时 `yield(value)`，外部用 `wrap` 把它当作迭代函数。
- 适用：自定义遍历、按需（惰性）生成、复杂状态机。

示例：简单的 `range` 迭代器

```lua
local function range(n)
  return coroutine.wrap(function()
    for i = 1, n do
      coroutine.yield(i)
    end
  end)
end

for i in range(5) do
  io.write(i, " ")
end
-- 输出：1 2 3 4 5
```

**事件驱动式编程**

- 模式：用 `yield`/`resume` 把回调风格改写为顺序风格（类似 "await"）。
- 实现要点：订阅事件时保存当前协程；事件到来时 `resume` 该协程并传入数据。

示例：基于订阅的等待

```lua
local listeners = {}

local function emit(evt, ...)
  local list = listeners[evt]
  if not list then return end
  for i = 1, #list do
    list[i](...)
  end
end

local function wait(evt)
  local current = coroutine.running()
  listeners[evt] = listeners[evt] or {}
  table.insert(listeners[evt], function(...)
    coroutine.resume(current, ...)
  end)
  return coroutine.yield()
end

local function task()
  print("waiting data...")
  local data = wait("data")
  print("got", data)
end

coroutine.resume(coroutine.create(task))
emit("data", 42)
```

### 练习

练习 24.1

```lua
function send(x, prod)
    coroutine.resume(prod, x)
end

function receive()
    return coroutine.yield()
end

function consumer()
    return coroutine.create(function (x)
        while true do
            io.write(x, "\n")
            x = receive()
        end
    end)
end

function producer(prod)
    while true do
        local x = io.read()
        send(x, prod)
    end
end

producer(consumer())
```

练习 24.2

```lua
local function printResult(t)
    for i = 1, #t do
        io.write(t[i], " ")
    end
    io.write("\n")
end

local function helper(arr, idx, res)
    if idx > #arr then
        coroutine.yield(res)
        return
    end
    helper(arr, idx + 1, res)
    table.insert(res, arr[idx])
    helper(arr, idx + 1, res)
    table.remove(res)
end
local function combinations(arr)
    local co = coroutine.create(
        function()
            helper(arr, 1, {})
        end
    )
    return function()
        local status, value = coroutine.resume(co)
        return status and value or nil
    end
end

for c in combinations({"a", "b", "c"}) do
    printResult(c)
end
```

练习 24.3

```lua
local putline_callbacks = setmetatable({}, { __mode = "k" })
local getline_callbacks = setmetatable({}, { __mode = "k" })

function putline (stream, line)
    local co = coroutine.running()
    local callback = putline_callbacks[co]
    if not callback then
        callback = function () coroutine.resume(co) end
        putline_callbacks[co] = callback
    end
    lib.writeline(stream, line, callback)
    coroutine.yield()
end

function getline (stream, line)
    local co = coroutine.running()
    local callback = getline_callbacks[co]
    if not callback then
        callback = function (l) coroutine.resume(co, l) end
        getline_callbacks[co] = callback
    end
    lib.readline(stream, callback)
    local line = coroutine.yield()
    return line
end
```

练习 24.4

```lua
local lib = require "async-lib"

function run (code)
    local co = coroutine.wrap(function()
        code()
        lib.stop()
    end)
    co()
    lib.runloop()
end

local putline_callbacks = setmetatable({}, { __mode = "k" })
local getline_callbacks = setmetatable({}, { __mode = "k" })

function putline (stream, line)
    local co = coroutine.running()
    local callback = putline_callbacks[co]
    if not callback then
        callback = function () coroutine.resume(co) end
        putline_callbacks[co] = callback
    end
    lib.writeline(stream, line, callback)
    coroutine.yield()
end

function getline (stream, line)
    local co = coroutine.running()
    local callback = getline_callbacks[co]
    if not callback then
        callback = function (l) coroutine.resume(co, l) end
        getline_callbacks[co] = callback
    end
    lib.readline(stream, callback)
    local line = coroutine.yield()
    return line
end

-- Iterator that yields lines from a stream using getline
function lines (stream)
    return function ()
        return getline(stream)
    end
end

run(function ()
    local t = {}
    local inp = io.input()
    local out = io.output()

    for line in lines(inp) do
        t[#t + 1] = line
    end

    for i = #t, 1, -1 do
        putline(out, t[i] .. "\n")
    end    
end)
```

练习 24.5

```lua
local lib = require "async-lib"

local running_tasks = 0

local function on_task_finished()
    running_tasks = running_tasks - 1
    if running_tasks == 0 then
        lib.stop()
    end
end

function spawn (code)
    running_tasks = running_tasks + 1
    local co = coroutine.wrap(function()
        code()
        on_task_finished()
    end)
    co()
    return co
end

function run (code)
    running_tasks = 0
    spawn(code)
    lib.runloop()
end

function run_all (codes)
    running_tasks = 0
    for _, fn in ipairs(codes) do
        spawn(fn)
    end
    lib.runloop()
end

local putline_callbacks = setmetatable({}, { __mode = "k" })
local getline_callbacks = setmetatable({}, { __mode = "k" })

function putline (stream, line)
    local co = coroutine.running()
    local callback = putline_callbacks[co]
    if not callback then
        callback = function () coroutine.resume(co) end
        putline_callbacks[co] = callback
    end
    lib.writeline(stream, line, callback)
    coroutine.yield()
end

function getline (stream, line)
    local co = coroutine.running()
    local callback = getline_callbacks[co]
    if not callback then
        callback = function (l) coroutine.resume(co, l) end
        getline_callbacks[co] = callback
    end
    lib.readline(stream, callback)
    local line = coroutine.yield()
    return line
end

run(function ()
    local t = {}
    local inp = io.input()
    local out = io.output()

    while true do
        local line = getline(inp)
        if not line then break end
        t[#t + 1] = line
    end

    for i = #t, 1, -1 do
        putline(out, t[i] .. "\n")
    end    
end)
```

练习 24.6

```lua
-- RUN_P246_DEMO=1 lua Sec24/p246.lua

-- Minimal coroutine scheduler with transfer semantics (resume/yield mediated)

local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
  return setmetatable({ current = nil }, Scheduler)
end

-- Run starting from an entry coroutine. It continues following transfer hops
-- until the current coroutine returns or yields something other than a transfer.
function Scheduler:run(entry, ...)
  local nextCoroutine = assert(entry, "entry coroutine required")
  local args = { ... }

  while nextCoroutine do
    self.current = nextCoroutine

    if coroutine.status(nextCoroutine) == "dead" then
      return
    end

    local ok, yielded = coroutine.resume(nextCoroutine, table.unpack(args))
    if not ok then
      error(yielded, 0)
    end

    if coroutine.status(nextCoroutine) == "dead" then
      return
    end

    if type(yielded) == "table" and yielded.op == "transfer" then
      local target = yielded.target
      assert(type(target) == "thread", "transfer target must be a coroutine (thread)")
      assert(coroutine.status(target) ~= "dead", "cannot transfer to a dead coroutine")
      nextCoroutine = target
      args = yielded.args or {}
    else
      -- Any non-transfer yield stops the scheduler (simple demo policy)
      return
    end
  end
end

function Scheduler:transfer(target, ...)
  -- Yield a transfer request to the scheduler. When this coroutine is
  -- later resumed, the values passed to resume become our return values.
  return coroutine.yield({ op = "transfer", target = target, args = { ... } })
end

local scheduler = Scheduler.new()

local function spawn(fn)
  assert(type(fn) == "function", "spawn expects a function")
  return coroutine.create(fn)
end

-- transfer(target, ...): suspend the current coroutine and switch to target.
-- When some coroutine transfers back to this one, returned values will be
-- whatever that transfer provided to resume this coroutine.
local function transfer(target, ...)
  assert(coroutine.running(), "transfer must be called inside a coroutine")
  local results = { scheduler:transfer(target, ...) }
  return table.unpack(results)
end

local function demo()
  local coA, coB

  coA = spawn(function()
    print("A: start")
    local r1 = transfer(coB, "msg-from-A1")
    print("A: back, got", r1)
    local r2 = transfer(coB, "msg-from-A2")
    print("A: back again, got", r2)
    print("A: done")
  end)

  coB = spawn(function(x)
    print("B: got", x)
    transfer(coA, "reply-from-B1")
    print("B: resumed")
    transfer(coA, "reply-from-B2")
    -- At this point B is suspended until someone transfers back to it.
  end)

  scheduler:run(coA)
end

if os.getenv("RUN_P246_DEMO") == "1" then
  demo()
end
```
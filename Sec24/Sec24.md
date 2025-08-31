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

练习 24.2

练习 24.3

练习 24.4

练习 24.5

练习 24.6
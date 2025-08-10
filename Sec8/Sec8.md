## 8 补充知识

### 笔记

封装代码块可以用`do...end`来实现。尽量使用局部变量。

repeat局部变量作用域包含until的条件。

lua支持goto，要结合`::name::`使用`goto name`

### 练习

练习 8.1

Lua 更需要 `elseif` 的原因：
  - Lua 没有 `switch/case`，多路分支主要依赖 `if ... elseif ... else ... end`。
  - Lua 用 `end` 结束块；若用 `else if` 只能写成嵌套，会多一层缩进和一个 `end`，也引入额外的局部作用域，降低可读性。
  - `elseif` 让整条语句保持为一个平坦结构，减少 `end`、避免多余作用域，代码更清晰。

```lua
-- 没有 elseif 的写法（需要额外的缩进与 end）
if a then
  ...
else
  if b then
    ...
  else
    ...
  end
end

-- 使用 elseif（单一语句，更扁平）
if a then
  ...
elseif b then
  ...
else
  ...
end
```

练习 8.2

四种实现无条件循环的方法：
  1) `while true do ... end`

```lua
while true do
  -- work
  if should_stop() then break end
end
```

  2) `repeat ... until false`

```lua
repeat
  -- work
  if should_stop() then break end
until false
```

  3) 数值 for 搭配无穷大上界：`for i = 1, math.huge do ... end`

```lua
for i = 1, math.huge do
  -- work (i 可忽略)
  if should_stop() then break end
end
```

  4) 使用 `goto`：

```lua
::loop::
-- work
if should_stop() then goto done end
goto loop
::done::
```

推荐：
  - 默认使用 `while true do`（最直观、可读性最好）。
  - 如果天然需要“先执行一次再判断退出”的结构，`repeat ... until false` 更贴合书写顺序。
  - 避免用 `for ... math.huge` 与 `goto`，除非有特殊风格或微优化诉求。

练习 8.3

虽然使用频率低，但它提供“先执行一次再判断退出”的语义，能在某些场景显著提升可读性，避免哨兵变量与多余分支。
何时使用：
  - 循环体必须先运行一次才能确定退出条件（如读取/解析直到有效）。
  - 退出条件在逻辑上更自然地写成“直到满足X”，而非“当不满足X时继续”。
  - 需要在循环体内声明临时局部变量并在 `until` 条件中使用（Lua 中 `repeat` 的作用域覆盖到 `until` 条件）。
示例：
```lua
-- 读取直到拿到非空行
repeat
  line = io.read("*l")
until (line ~= nil and #line > 0)
```
建议：
  - 当确有“先做再判”的需求时，用 `repeat ... until`；
  - 其他一般场景使用 `while` 即可，避免滥用。

练习 8.4

把 `goto` 换成 `return func` 即可，同时去掉else，保证是函数尾部执行的。

练习 8.5

为什么禁止 `goto` 跳出函数：
  - `goto` 在 Lua 中是同一函数体内的局部跳转；跨函数将变成“非局部跳转”，需要展开调用栈、关闭 upvalue、执行 to-be-closed 变量的 `__close` 等清理逻辑，本质等同于异常机制，复杂且易破坏可读性与资源安全。
  - 标签、局部变量与作用域都是按函数编译期解析；允许跨函数会打破词法作用域规则与实现简单性。
  - Lua 已提供结构化替代：`return`、`error/pcall`、协程等。
如果要实现/模拟：
  - 方案一（推荐）：用 `error` 抛出标记值，在外层用 `pcall/xpcall` 捕获，作为“跳出函数”的语义。
```lua
local Jump = {}

local function inner()
  if need_jump_out then error(Jump) end
  -- work
end

local ok, err = pcall(inner)
if not ok and err == Jump then
  -- 好比从 inner 非局部跳出到这里
end
```
  - 方案二：返回码/状态驱动的结构化返回；必要时配合尾调用。
  - 方案三：用协程 `coroutine.yield/resume` 在调用方处“接管”控制流。

练习 8.6

调用 `getlabel()` 时，先返回闭包，`getlabel` 已经结束，`::L1::` 尚未执行。
之后调用闭包时执行 `goto L1`，这是一次“非局部跳转”。若被允许：
  - 控制流离开闭包调用，转移到外层函数的 `::L1::` 位置，随后执行 `return 0`。
  - 因而闭包调用本身不会“正常返回”；它把控制权与返回值直接带到外层跳转目标处，返回 `0`。


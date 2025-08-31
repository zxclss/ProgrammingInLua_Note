## 23 垃圾收集

### 笔记

**弱引用表**
- 通过元表字段 `__mode` 开启弱引用：
  - `"k"` 弱键；`"v"` 弱值；`"kv"` 键和值都弱（5.2+ 具 ephemeron 语义）。
- 当键或值的唯一剩余引用来自弱表时，相应条目会在一次 GC 后被移除。
- 仅“可收集的对象”会受弱性影响（表、函数、线程、完整 userdata、字符串）。数值与布尔值不是独立对象，不受影响。
- 遍历弱表时，条目可能在遍历过程中消失；不要在迭代中依赖其稳定性。

```lua
-- 弱值缓存（值可被回收，不阻止对象存活）
local cache = setmetatable({}, { __mode = "v" })

local function getUser(id)
  local u = cache[id]
  if u == nil then
    u = loadUserFromDb(id) -- 示例：加载真实数据
    cache[id] = u
  end
  return u
end

-- 弱键映射（对象生命周期结束时，条目自动消失）
local props = setmetatable({}, { __mode = "k" })
props[obj] = { color = "red" }
```

**记忆函数**
- 用缓存避免重复计算；对“对象参数”的记忆应使用弱键，避免缓存阻止对象回收。
- 若结果体量大且可重算，可用弱值使结果在内存紧张时被回收。

```lua
-- 单参记忆：键和值都弱，不阻止入参/结果存活
local function memoize1(f)
  local cache = setmetatable({}, { __mode = "kv" })
  return function(x)
    local r = cache[x]
    if r == nil then
      r = f(x)
      cache[x] = r
    end
    return r
  end
end

-- 使用示例
local function slowSquare(n)
  -- 假设这里很慢
  return n * n
end
local fastSquare = memoize1(slowSquare)
```

- 多参记忆常见做法：
  - 用“嵌套表”按参数层级索引；
  - 把参数打包为一张表作为键（需注意复用/弱键以避免泄漏）。

**对象属性**
- 不修改对象自身结构，使用旁路表把“属性包”关联到对象上：

```lua
-- 弱键属性表：对象被回收后，属性自动消失
local Attributes = setmetatable({}, { __mode = "k" })

local function setAttr(obj, key, value)
  local bag = Attributes[obj]
  if bag == nil then
    bag = {}
    Attributes[obj] = bag
  end
  bag[key] = value
end

local function getAttr(obj, key)
  local bag = Attributes[obj]
  return bag and bag[key] or nil
end
```

**回顾具有默认值的表**
- 用 `__index`（函数）实现“按需创建并保存”的默认值，避免每次都返回同一共享对象。
- 若键是短生命周期对象，结合弱键减少长期驻留。

```lua
-- 自动创建默认子表；首次访问某键时创建并缓存
local function defaultTable(factory)
  return setmetatable({}, {
    __mode = "k",
    __index = function(self, key)
      local v = factory(key)
      rawset(self, key, v)
      return v
    end,
  })
end

local groups = defaultTable(function() return {} end)
table.insert(groups["admin"], "alice") -- 第一次访问自动创建 {}
```

**瞬表（Ephemeron Table）**
- 当 `__mode = "kv"` 且值引用了其键时，5.2+ 的 GC 把该对视作 ephemeron：值对键的引用不会让键存活。
- 典型用途：把辅助结构与对象互相引用又不造成“彼此保活”。

```lua
-- 值里可以保存对键的反向引用，键仍可被回收
local aux = setmetatable({}, { __mode = "kv" })

local function wrap(obj)
  local a = aux[obj]
  if a == nil then
    a = { owner = obj }
    aux[obj] = a
  end
  return a
end
```

**析构器（Finalizer）**
- 在对象变为不可达后，带 `__gc` 的对象会在某个时刻被调用析构器：用于释放外部资源（文件、socket、C 句柄等）。
- Lua 5.2+：表与完整 userdata 都支持 `__gc`。Lua 5.1：仅完整 userdata；可用 `newproxy(true)` 创建带析构器的代理。
- 析构器：
  - 调用次序不保证；
  - 不要假设在进程退出时一定全部执行；
  - 不应 `yield`；请保持幂等且尽量简单。

```lua
-- Lua 5.2+：表也可拥有析构器
local mt = {
  __gc = function(self)
    print("finalizing:", self.name)
    -- 关闭外部资源等
  end
}
local obj = setmetatable({ name = "R" }, mt)
obj = nil
collectgarbage("collect")
```

```lua
-- Lua 5.1：使用 newproxy 创建可析构的代理（要么元表时就创建__gc，要么创建前先打上要析构的标记）
local p = newproxy(true)
getmetatable(p).__gc = function(self)
  print("proxy finalized")
end
p = nil
collectgarbage("collect")
```

**垃圾收集器**
- Lua 的基础算法是标记-清除；默认运行方式是“增量式标记-清除”；Lua 5.4 起可切换为“分代 GC”。关键阶段会专门处理弱表、瞬表与带 `__gc` 的对象。
- 常用 API：`collectgarbage`
  - `"count"`：返回当前使用内存（KB）及字节余数。
  - `"collect"`：完整收集（全堆），无论处于何种模式。
  - `"stop"` / `"restart"` / `"isrunning"`。
  - `"step", sz`：做一次小步；完成一个周期返回 true。
  - `"setpause", n`：两次周期触发间隔（越小越省内存、停顿更频）。
  - `"setstepmul", n`：每步工作量（越大越积极、抖动更小）。
  - 5.4：`"incremental", pause, stepmul` 与 `"generational"` 模式切换与参数。

- 标记-清除（Mark–Sweep，停顿式）
  - 把堆里所有对象想成“书籍”。先给还能“摸到”的书做上记号（可达），再把没记号的书一次性丢掉。
  - 触发：内存达到阈值、手动 `collect`、或驻留增长过快。
  - 核心步骤：
    1. 标记阶段：从“根”（全局变量、各线程栈、闭包 upvalue、注册表等）出发，沿着引用把能到达的对象都做记号。
    2. 处理弱表/瞬表：移除键或值未被标记的元素（满足弱语义）；把没有记号、但被标记为需要进行析构的对象，放在一个“待析构队列“中。
    3. 清除阶段：释放未被标记的对象，并把带 `__gc` 的未标记对象放入待析构队列。
    4. 析构阶段：在安全时机调用 `__gc`（次序不保证）。
  - 特点：一次性停顿较大；吞吐高、实现简单。适合维护/工具场景的整堆回收。

- 增量式 GC（Incremental，三色标记）
  - 把“大工程”拆成小步，分散到多次 `step` 调用里执行，避免长停顿。
  - 三色模型（颜色的意义）：
    - 白（white）：尚未被标记到的对象，若最终仍为白将被回收。
    - 灰（gray）：已发现但其“子引用”尚未全部扫描的对象。
    - 黑（black）：已扫描完毕的对象（它的所有子引用都已被标记）。
  - 三色不变式（保证正确性）：任何时刻都不允许出现“黑对象直接指向白对象”。
    - 一旦程序写入造成这种情形，必须执行写屏障：要么把新引用对象标为灰，要么把写入的黑对象重新置灰以便重扫。
  - 阶段与小步：mark（传播灰对象）→ atomic（统一处理弱表/瞬表/待析构）→ sweep（分批清理白对象）→ pause。
  - 伪代码（简化/带注释）：
```lua
-- 每次调用只做有限工作量（budget）
function gc_step(budget)
  if phase == "mark" then            -- 传播：把灰对象扫描成黑
    while budget > 0 and not isEmpty(gray) do
      local obj = pop(gray)           -- 从灰集中取出
      markBlack(obj)                  -- 当前对象变黑（已扫描）
      for each child in references(obj) do
        if isWhite(child) then        -- 新发现白对象
          markGray(child)             -- 先放入灰集，稍后扫描
          budget = budget - 1
        end
      end
    end
    if isEmpty(gray) then phase = "atomic" end
  elseif phase == "atomic" then      -- 封顶标记：弱表/瞬表/析构统一处理
    processWeakAndEphemeron()
    queueUnmarkedFinalizables()
    phase = "sweep"
  elseif phase == "sweep" then       -- 分批清理白对象
    sweepSome(budget)
    if sweepDone() then phase = "pause" end
  end
end

-- 写屏障：当黑对象被写入一个指向白对象的新引用时触发
function writeField(blackObj, newRef)
  blackObj.field = newRef
  if isBlack(blackObj) and isWhite(newRef) then
    markGray(newRef)                  -- 或把 blackObj 重新置灰
  end
end
```

- 分代 GC（Generational，Lua 5.4）
  - 大多数对象“朝生暮死”。把新生对象放在“年轻代”，频繁回收；活得久的对象放在“老年代”，很少扫描。
  - 核心概念：
    - 年轻代（nursery）/ 老年代（old）。新分配对象进入年轻代。
    - 记忆集（remembered set）：记录“老→年轻”的引用，避免 minor GC 漏标。
  - Minor GC 做什么（只关心年轻代）：
    1. 从根集合和记忆集出发，标记可达的“年轻对象”。
    2. 清理未标记的年轻对象（死亡对象）。
    3. 对多次幸存的对象执行“晋升”（promote）到老年代。
  - Major GC 做什么（全堆一次性）：
    - 退化为一次整堆标记-清除，统一处理弱表/瞬表/析构；通常当年轻代收益变差、老年代膨胀或显式 `collect` 时触发。
  - 伪代码（简化）：
```lua
function minor_gc()
  markYoungFromRoots()
  markYoungFromRememberedSet()
  sweepYoung()
  promoteSurvivors()
end

function major_gc()
  fullMarkAndSweep()        -- 等同整堆回收
  clearRememberedSet()
end

-- 写屏障：当老对象指向年轻对象时，把“老对象”加入记忆集
function writeField(oldObj, newYoung)
  oldObj.field = newYoung
  if inOld(oldObj) and inYoung(newYoung) then
    rememberedSetAdd(oldObj)
  end
end
```
  - 为什么需要记忆集：minor 只扫描年轻代，但“可达路径”可能来自老年代；用记忆集把“老→年轻”的桥接点记录下来，minor 扫描记忆集即可补齐可达性。
  - 何时用：
    - 对象短命且分配频繁（解析、协程/闭包大量创建、游戏帧脚本）：分代更省时。
    - 对象多为长寿、跨代引用很多或写入非常频繁：增量式更稳。


- 选择与实践建议
  - 以吞吐为主且能接受偶发停顿：直接 `collect` 或较大 `pause` + 较小 `stepmul`。
  - 需要平滑延迟：用增量式，设置合理 `setpause` 与 `setstepmul`，并在主循环中 `step`。
  - 短命对象密集：切到分代；仍可不定期触发一次 `collect` 做全堆“整顿”。

### 练习

练习 23.1

Lua 需要“瞬表”：处理弱键表中 value→key 的环，避免因交叉引用导致的不可回收对象。

练习 23.2

会执行：
- 显式调用collectgarbage()
- 程序出错退出时
- 内存压力触发自动垃圾收集时
不会执行：
- 程序正常退出且没有垃圾收集
- 调用os.exit()退出
- 程序被强制终止（如Ctrl+C）

练习 23.3

可以实现一个类似LRU的管理器，显示管理缓存的string。

```lua
function createLimitedMemoTable(maxSize)
    maxSize = maxSize or 1000
    local cache = {}
    local keys = {}  -- 记录插入顺序
    local size = 0
    
    return {
        get = function(key)
            return cache[key]
        end,
        
        set = function(key, value)
            -- 如果键已存在，只更新值
            if cache[key] ~= nil then
                cache[key] = value
                return
            end
            
            -- 如果达到大小限制，删除最老的条目
            if size >= maxSize then
                local oldestKey = table.remove(keys, 1)
                cache[oldestKey] = nil
                size = size - 1
                print(string.format("清理最老条目: %s", tostring(oldestKey)))
            end
            
            -- 添加新条目
            cache[key] = value
            table.insert(keys, key)
            size = size + 1
        end,
        
        size = function()
            return size
        end,
        
        clear = function()
            cache = {}
            keys = {}
            size = 0
        end
    }
end
```

练习 23.4

在第二次 `collectgarbage()`（`a = nil` 之后）中，GC 发现这些对象不可达，只是把它们放入“待终结”列表并调用各自的 `__gc`；此时 `count` 归零，但这些对象尚未真正释放，所以内存没有完全下降。到了第三次 `collectgarbage()`，GC 才会把这些已终结且仍不可达的对象真正释放，因此内存进一步减少。

这是 Lua 的设计，用于防止 `__gc` 里“复活”对象的情况；因此必须等到下一轮确认仍不可达后才释放。

练习 23.5

```bash
lua Sec23/p235.lua auto <pause> <stepmul> <num_tables> [inner_empty=1]
lua Sec23/p235.lua manual <num_tables> <batch_size> <step_work> <full_collect_every> [inner_empty=1]
```

脚本输出字段说明：
- mode: auto 或 manual
- pause, stepmul: 自动模式下的调参值
- num/batch/step_work: 分配数量/批大小/每次 step 的工作量
- alloc_s: 分配阶段时间
- gc_s: 释放后执行 GC 的时间（近似）
- mem_: GC 统计的字节数（collectgarbage("count")*1024）

**pause 和 stepmul 的影响（以及极端值）**
- 基础概念：
  - `pause`: 相对上次收集结束时的内存，决定何时恢复新一轮 GC（阈值=内存×pause/100）。`pause` 越大，允许堆增长越多才重新启动收集；越小，越频繁启动收集。
  - `stepmul`: 控制增量收集每一步的“力度”（每分配 1KB 内存，垃圾收集器应该做多少工作）。越大，收集器追赶得更凶（可能更抢 CPU）；越小，收集器更温和（可能内存更高）。
- 观察与直觉：
  - `pause=0`: 极端激进。收集几乎在结束后就立刻再次启动，相当于极低的增长容忍度。结果是：
    - 内存峰值较低（更快触发收集）
    - 可能频繁打断，带来较多小的 GC 开销，吞吐可能变差
  - `pause=1000`: 极端保守。允许内存的 10 倍增长才重启收集：
    - 内存峰值明显升高（延迟收集）
    - 分配阶段可能更顺畅（更少被 GC 打断），但释放后回收需要更久或更多工作
  - `stepmul=0`: 收集器几乎不推进。表现为：
    - 自动模式下，增量 GC 不会“追赶”，只有显式的 `collectgarbage()` 才会真正回收
    - 内存使用会偏高（无法靠增量阶段逐步回收）
  - `stepmul=1000000`: 极端激进。每次增量 `step` 做非常多的工作：
    - 有利于快速降低内存（收集器追得很紧）
    - 可能在分配路径中花大量时间进行 GC，影响吞吐（CPU 抢占更明显）
- 实测样例（你的运行环境与数据会不同，仅作为趋势参考）：
  - `pause` 小（0）时：`mem_after_alloc` 较低，`alloc_s/gc_s` 可能略高或更不稳定（频繁干预）
  - `pause` 大（1000）时：`mem_after_alloc` 偏高，`alloc_s` 通常更平稳
  - `stepmul=0`：自动增量几乎不工作，释放前后 `mem_*` 波动小；全量回收时才会下降
  - `stepmul=1000000`：内存压得更紧，`gc_s` 可能稍增但峰值更低
- 把 `pause` 设成 0/1000、`stepmul` 设成 0/1000000 会发生什么
  - `pause=0`：几乎“刚回完又开新一轮”，抑制堆增长，频繁 GC，内存峰值低，CPU 干预高。
  - `pause=1000`：允许堆膨胀至内存的 10 倍再收集，内存峰值高，GC 次数更少，吞吐平稳。
  - `stepmul=0`：增量 GC 不推进，靠最终或显式 collectgarbage() 才回收，内存可能积累。
  - `stepmul=1000000`：每次 GC step 非常重，内存迅速回落，但 GC 抢占 CPU 明显。
- 完全控制垃圾收集器（手动模式）
  - 脚本的 `manual` 模式先 `collectgarbage("stop")` 停止自动 GC，再在每批分配后调用：
    - `collectgarbage("step", step_work)` 做少量增量推进
    - 可选地每隔 N 个对象/批触发 `collectgarbage("collect")` 做一次全量收集
  - 如：
```bash
lua Sec23/p235.lua manual 200000 5000 400 0 1
# 调小 step_work 提高吞吐但更高内存；调大 step_work 压低内存但可能影响吞吐
```
  - 是否能提升性能？
    - 如果你的工作负载对延迟/吞吐有明确窗口（例如批处理、帧间隙），手动在“空闲点”集中推进 GC，常常能改善整体性能稳定性和峰值。
    - 如果是均匀持续的负载，自动 GC 配合合理的 pause/stepmul 通常更省心。手动模式需要你自己选择合适的批大小和 step 工作量，避免要么回收不足（内存飙升），要么回收过度（CPU 开销大）。
    - 建议做 A/B：用同样的 `num_tables`，在 `auto` 与 `manual` 下对比 `alloc_s/gc_s` 和 `mem_after_alloc/mem_after_collect`，结合应用的延迟目标取舍。
- 建议的测试矩阵
  - 固定 `num_tables=200000`：
    - auto: `(pause,stepmul)` ∈ `{(0,200),(100,50),(200,0),(200,200),(1000,50),(200,1000000)}`
    - manual: `(batch_size,step_work)` ∈ `{(5000,0),(5000,200),(5000,400),(10000,800)}，full_collect_every ∈ {0,100000}`
  - 比较指标：`alloc_s`、`gc_s`、内存峰值（`mem_after_alloc`）和回收后（`mem_after_collect`）。
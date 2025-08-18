## 16 编译、执行和错误

### 笔记

**编译**

- 概念：Lua 会先把一个 chunk（源代码字符串或文件）编译为一个可调用的函数（字节码原型 + 闭包）。编译阶段不执行代码，只有在调用返回的函数时才会运行顶层语句。
- 入口 API：
  - `load(s [, chunkname [, mode [, env]]])`：从字符串或 reader 函数加载，成功返回函数，失败返回 `nil, errmsg`。
  - `loadfile([filename [, mode [, env]]])`：从文件加载并返回函数，失败返回 `nil, errmsg`。
  - `dofile([filename])`：加载并立即执行，返回 chunk 的返回值（不缓存编译结果）。
  - `require(modname)`：按搜索路径加载并执行模块，只执行一次并缓存结果到 `package.loaded`。
- 参数要点：
  - `chunkname`：用于错误信息和调试栈显示来源（例如 `@path/to/file.lua`）。
  - `mode`："t" 仅文本、"b" 仅二进制、"bt" 或 `nil` 同时接受（5.2+）。
  - `env`：指定 chunk 的环境；在 5.2+ 设置其首个 upvalue `_ENV`（5.1 用 `setfenv`）。
- Reader 函数：当 `load` 的第一个实参是函数时，Lua 会反复调用该函数获取下一段源码字符串，直到返回 `nil` 为止，适合从网络流、加密流按需供给源码。
- 执行与返回：
  - `load*` 返回的是“零参”的 chunk 函数，调用时才会执行；调用的返回值就是 chunk 末尾 `return` 的值。
  - `dofile` 直接返回执行结果；`require` 返回模块值并缓存，后续再次 `require` 直接取缓存。

**预编译的代码**

- 作用：
  - 跳过词法/语法分析，加快加载速度；便于将多个脚本打包发布。
  - 不是安全手段，二进制 chunk 可被反编译，不应依赖其隐藏源码。
- 生成方式：
  - 构建期使用 `luac`：例如 `luac -o out.lc a.lua b.lua` 生成/合并二进制 chunk。
  - 运行时使用 `string.dump(func [, strip])`：把函数（或经 `load*` 得到的 chunk 函数）序列化为二进制字符串；`strip=true` 可去除符号/调试信息以减小体积。
- 加载方式：
  - `load`/`loadfile` 默认同时接受文本与二进制；需要时用 `mode="b"` 强制仅接收二进制。
  - 对 `string.dump` 的结果，直接 `load(binary)` 即可还原为可调用函数。
  - `require` 通常可直接加载预编译文件；可在 `package.path` 中把 `?.lc` 放在 `?.lua` 之前以优先加载二进制。
- 兼容性：
  - 二进制 chunk 不保证跨 Lua 主版本兼容；也可能受编译选项、整数/浮点大小、字节序影响而与平台绑定。
  - 若要最大可移植性，优先分发源码；若必须分发二进制，请保证生产与运行环境一致。

**错误**

- 分类：
  - 编译期错误（语法/词法）：`load*` 返回 `nil, errmsg`，不会执行。
  - 运行期错误：执行过程中触发，若未被保护调用捕获，将向上传播至最外层导致终止。
- 抛错：
  - `error(msg [, level])` 抛出错误；`level` 控制把错误归因到哪一层（1 表示调用者）。
  - `assert(cond [, msg])` 在 `cond` 为 `false`/`nil` 时抛错，否则返回 `cond` 及其后续返回值。
- 约定：很多库以 `nil, errmsg[, code]` 表示失败（例如 `io.open`）。
- 建议：业务边界/IO 边界用受保护调用拦截错误；内部逻辑让错误冒泡，避免静默吞掉 bug。

**错误处理和异常**

- 受保护调用：
  - `pcall(f, ...)`：返回 `ok, ...`；若 `f` 抛错，`ok=false`，第二个返回值是错误对象（通常为字符串）。
  - `xpcall(f, msgh, ...)`：在错误发生时调用 `msgh(err)` 生成增强后的错误信息，常用来附加回溯。
- 与协程：
  - `coroutine.resume(co, ...)` 返回 `ok, ...`；协程内错误不会直接终止主线程，但 `ok=false`，第二个值为错误信息（通常不含回溯）。
  - 如需回溯，协程内部可用 `xpcall`/`debug.traceback` 包裹入口函数。
- 清理：在需要保证清理的场景，使用“创建-调用-在错误分支清理”的结构配合 `pcall/xpcall`，避免资源泄漏。

**错误信息和栈回溯**

- 生成回溯：
  - `debug.traceback([thread][, message[, level]])` 返回带有调用栈的字符串；`level` 控制从哪一层开始展示。
  - 常见用法是作为 `xpcall` 的错误处理函数：
```lua
local function run()
  error("boom", 2)
end

local ok, err = xpcall(run, function(msg)
  return debug.traceback(msg, 2)
end)
if not ok then
  print(err)
end
```
- 调整来源：`error(msg, level)`/`debug.traceback(..., level)` 可把错误归因到调用者，隐藏内部包装层。
- 调试：需要更细节可用 `debug.getinfo(level[, what])` 检查指定帧的信息（函数名、源文件、行号等）。

### 练习

练习 16.1

```lua
loadwithprefix = function (prefix)
    return function (chunk, chunkname)
        local fn, err = loadstring(chunk .. "\n" .. prefix, chunkname)
        if not fn then error(err) end
        return fn()
    end
end

local f = loadwithprefix("print('hello from ' .. name)")
f("name = 'Lua'")
```

练习 16.2

```lua
multiload = function(...)
    local args = {...}
    local parts = {}
    
    -- 处理每个参数
    for i, arg in ipairs(args) do
        if type(arg) == "string" then
            -- 字符串直接添加
            table.insert(parts, arg)
        elseif type(arg) == "function" then
            -- 迭代器函数：读取所有内容
            local content = arg()
            while content do
                table.insert(parts, content)
                content = arg()
            end
        else
            error("Argument " .. i .. " must be a string or function, got " .. type(arg))
        end
    end
    
    -- 连接所有部分成完整代码
    local code = table.concat(parts)
    
    -- 编译代码
    local fn, err = loadstring(code)
    if not fn then
        error("Failed to compile code: " .. err)
    end
    
    return fn
end

f = multiload("local x = 10;",
              io.lines("temp", "*L"),
              " print(x)")
```

练习 16.3

```lua
stringrep = function(s, n)
    local r = ""
    if n > 0 then
        while n > 1 do
            if n % 2 ~= 0 then r = r .. s end
            s = s .. s
            n = math.floor(n / 2)
        end
        r = r .. s
    end
    return r
end

-- 为指定的n生成特定版本的stringrep_n函数
function make_stringrep_n(n)
    if n <= 0 then
        -- 对于n <= 0的情况，返回空字符串
        local code = [[
            return function(s)
                return ""
            end
        ]]
        return load(code)()
    end
    
    -- 生成指令序列
    local instructions = {}
    local temp_n = n
    local step = 0
    
    -- 分析n的二进制表示，生成对应的指令序列
    while temp_n > 1 do
        if temp_n % 2 ~= 0 then
            table.insert(instructions, string.format("r = r .. s%d", step))
        end
        table.insert(instructions, string.format("s%d = s%d .. s%d", step + 1, step, step))
        temp_n = math.floor(temp_n / 2)
        step = step + 1
    end
    
    -- 最后总是需要添加最终的s
    table.insert(instructions, string.format("r = r .. s%d", step))
    
    -- 构造函数代码
    local code_parts = {
        "return function(s)",
        "    local r = \"\"",
        string.format("    local s0 = s")
    }
    
    -- 添加所有指令
    for _, instruction in ipairs(instructions) do
        table.insert(code_parts, "    " .. instruction)
    end
    
    table.insert(code_parts, "    return r")
    table.insert(code_parts, "end")
    
    local code = table.concat(code_parts, "\n")
    
    -- 使用load生成函数
    return load(code)()
end

-- 测试函数
function test_stringrep_generators()
    print("Testing stringrep generators:")
    
    local test_cases = {1, 2, 3, 4, 5, 8, 10, 16}
    local test_string = "ab"
    
    for _, n in ipairs(test_cases) do
        local generated_func = make_stringrep_n(n)
        local original_result = stringrep(test_string, n)
        local generated_result = generated_func(test_string)
        
        print(string.format("n=%d: original='%s', generated='%s', match=%s", 
              n, original_result, generated_result, tostring(original_result == generated_result)))
    end
end

-- 显示生成的代码示例
function show_generated_code(n)
    print(string.format("\nGenerated code for n=%d:", n))
    
    if n <= 0 then
        print([[
            return function(s)
                return ""
            end
        ]])
        return
    end
    
    local instructions = {}
    local temp_n = n
    local step = 0
    
    while temp_n > 1 do
        if temp_n % 2 ~= 0 then
            table.insert(instructions, string.format("r = r .. s%d", step))
        end
        table.insert(instructions, string.format("s%d = s%d .. s%d", step + 1, step, step))
        temp_n = math.floor(temp_n / 2)
        step = step + 1
    end
    
    table.insert(instructions, string.format("r = r .. s%d", step))
    
    local code_parts = {
        "return function(s)",
        "    local r = \"\"",
        string.format("    local s0 = s")
    }
    
    for _, instruction in ipairs(instructions) do
        table.insert(code_parts, "    " .. instruction)
    end
    
    table.insert(code_parts, "    return r")
    table.insert(code_parts, "end")
    
    print(table.concat(code_parts, "\n"))
end
```

练习 16.4

让 f 在协程里尝试 yield，就会让内层 pcall 本身出错，从而使外层 pcall(pcall, f) 的第一个返回值为 false。

```lua
-- Lua 5.1 场景
local f = function()
  coroutine.yield()  -- 试图跨过 pcall 这个 C 函数边界 yield
end

local co = coroutine.create(function()
  local ok, err = pcall(pcall, f)
  print(ok, err)     -- false  "attempt to yield across metamethod/C-call boundary"
end)

coroutine.resume(co)
```

这说明“外层的 pcall 只保护对 pcall 的这次调用”，而内层 pcall 并不能处理“跨不可yield的 C 边界的 yield”这类错误（在 Lua 5.1 中 pcall 不可 yield），导致内层 pcall 自身报错，进而由外层 pcall 捕获并返回 false。它揭示了受保护调用的边界与限制：不是所有错误都以“内层 pcall 返回 false”的形式出现，有些会让“调用 pcall 本身”失败。
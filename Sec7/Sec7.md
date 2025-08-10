## 7 输入输出

### 笔记

`io.write`接受多参数，因此多用`io.write(a, b, c)`代替`io.write(a..b..c)`。

`io.read`支持的参数有：

1. `"a"/"all"` - 读取整个文件内容
2. `"l"` - 读取一行，丢弃换行符
3. `"L"` - 读取一行，保留换行符
4. `"n"` - 读取一个数字，跳过空格也读不到一个数字就返回nil。
5. `num` - 读取指定数量的字符，比如`io.read(2^10)`就是读1KB的块，因为一个字符是1B。

`io.read(0)`常用于检测是否到达文件末尾，仍有数据会返回空字符串，否则返回nil。

可以一口气读多个数字：`io.read("n", "n", "n")`

读文件的两种方式：
1. `for count = 1, math.huge do`
2. `for line in io.lines() do`

`io.lines(arg)` 可以返回一个从流中不断读取内容的迭代器，无参数时是当前输入流，参数是可以只读打开的文件名。

`io.read(args)`实际上是`io.input():read(args)`的简写，即在当前输入流上使用read函数。`io.output(args)`同理。

切换输入流的操作：

```lua
local temp = io.input() --保存当前输入流
io.input("new_input")   --打开一个新的输入流
-- do something
io.input().close()      --关闭新的输入流
io.input(temp)          --切换回去
```
其他tips：

1. `io.tmpfile`可以返回一个操作临时文件的句柄。
2. `io.flush`用于刷新缓冲区，将缓冲区的数据写入文件。
3. `io.setvbuf`用于设置流的缓冲模式。
4. `io.seek`用来获取和设置文件的当前位置。
5. `os.rename`和`os。remove`用于重命名文件和删除文件。
6. `os.exit()`用于终止程序的执行。
7. `os.getenv`用于获取某个环境变量。
8. `os.excute(str)`执行指令str，返回第一个bool表示指令是否执行成功，第二个str是指令状态。
9. `io.popen(str, "r/w")`在excute基础上可以写入指令和读出指令的输出。

### 习题

练习 7.1

```lua
local input_file_dir = arg[1]
local output_file_dir = arg[2]

local input_file = nil
local output_file = nil
if input_file_dir then
    input_file = io.open(input_file_dir, "r")
    if not input_file then
        io.write("File not found\n")
        os.exit()
    end
    io.input(input_file)
else
    io.write("Enter your input content (press Ctrl+Z then Enter to finish on Windows, or Ctrl+D on Unix):\n")
    io.input(io.stdin)
end

local lines = {}
for line in io.lines() do
    table.insert(lines, line)
end
if input_file then
    input_file:close()
end

table.sort(lines)

if output_file_dir then
    output_file = io.open(output_file_dir, "w")
    if not output_file then
        io.write("Cannot create output file\n")
        os.exit()
    end
    io.output(output_file)
else
    io.output(io.stdout)
end

for _, line in ipairs(lines) do
    io.write(line .. "\n")
end

if output_file then
    output_file:close()
end
```

练习 7.2

```lua
if output_file_dir then
    local file_exists = io.open(output_file_dir, "r")
    if file_exists then
        file_exists:close()
        io.write("Output file '" .. output_file_dir .. "' already exists. Overwrite? (y/n): ")
        local response = io.read()
        if response ~= "y" and response ~= "Y" then
            io.write("Operation cancelled.\n")
            os.exit()
        end
    end
    output_file = io.open(output_file_dir, "w")
    if not output_file then
        io.write("Cannot create output file\n")
        os.exit()
    end
    io.output(output_file)
else
    io.output(io.stdout)
end
```

练习 7.3

1. **按字节读取** - 使用 `file:read(1)` 逐字节读取
2. **按行读取** - 使用 `file:lines()` 逐行读取
3. **按块读取** - 使用 `file:read(8192)` 按8KB块读取
4. **一次性读取** - 使用 `file:read("*a")` 一次性读取整个文件

1. 按字节读取
   - **优点**: 精确控制，可以处理二进制数据
   - **缺点**: 性能最差，随着文件大小线性增长
   - **适用场景**: 需要逐字节处理的二进制文件
2. 按行读取
   - **优点**: 适合文本文件，内存使用稳定
   - **缺点**: 只适用于有换行符的文本文件
   - **适用场景**: 文本文件处理，日志分析
3. 按块读取 (8KB)
   - **优点**: 性能最好，内存使用可控
   - **缺点**: 需要手动处理块边界
   - **适用场景**: 大文件处理，网络传输
4. 一次性读取整个文件
   - **优点**: 代码简单，适合小文件
   - **缺点**: 内存使用量大，有文件大小限制
   - **适用场景**: 小文件处理，配置文件读取

1. 性能最佳: **按块读取** (8KB) 是处理各种大小文件的最佳选择
2. 文件大小限制: 一次性读取整个文件在当前系统下最大支持 300 MB
3. 内存效率: 按块读取内存使用最稳定，一次性读取内存消耗最大
4. 实用建议: 根据文件大小选择合适的读取方法，大文件必须使用按块读取

练习 7.4

```lua
local file_dir = "data.in"
local file = io.open(file_dir, "r")
if not file then
    io.write("File not found\n")
    os.exit()
end

-- 获取文件大小
local size = file:seek("end")
if size == 0 then
    io.write("File is empty\n")
    file:close()
    os.exit()
end

-- 从文件末尾开始向前搜索最后一行
local last_line = ""
local pos = size - 1
local found_line = false

while pos >= 0 and not found_line do
    file:seek("set", pos)
    local char = file:read(1)
    
    if char == "\n" then
        -- 找到换行符，读取这一行
        last_line = file:read("*line")
        found_line = true
    elseif pos == 0 then
        -- 到达文件开头，整个文件就是一行
        file:seek("set", 0)
        last_line = file:read("*line")
        found_line = true
    end
    
    pos = pos - 1
end

if not found_line then
    -- 如果没找到换行符，整个文件就是一行
    file:seek("set", 0)
    last_line = file:read("*line")
end

io.write("Last line: " .. (last_line or "") .. "\n")
file:close()
```

练习 7.5

```lua
local function get_last_n_lines(filename, n)
    local file = io.open(filename, "r")
    if not file then
        return nil, "File not found"
    end
    
    local size = file:seek("end")
    if size == 0 then
        file:close()
        return {}, "File is empty"
    end
    
    local lines = {}
    local pos = size - 1
    local line_count = 0
    
    while pos >= 0 and line_count < n do
        file:seek("set", pos)
        local char = file:read(1)
        
        if char == "\n" then
            local line = file:read("*line")
            if line then
                table.insert(lines, 1, line)
                line_count = line_count + 1
                pos = pos - 1
            end
        elseif pos == 0 then
            file:seek("set", 0)
            local line = file:read("*line")
            if line then
                table.insert(lines, 1, line)
                line_count = line_count + 1
            end
            break
        end
        
        pos = pos - 1
    end
    
    file:close()
    return lines
end

local file_dir = "data.in"
local n = tonumber(arg[1]) or 5

local lines, err = get_last_n_lines(file_dir, n)
if err then
    io.write("Error: " .. err .. "\n")
else
    io.write("Last " .. #lines .. " lines:\n")
    for i, line in ipairs(lines) do
        io.write(string.format("%d: %s\n", i, line))
    end
end
```

练习 7.6

```lua
local function sleep2s()
    -- 在Windows上使用timeout命令，在Unix/Linux上使用sleep命令
    if package.config:sub(1,1) == '\\' then
        -- Windows
        os.execute("timeout /t 2 /nobreak > nul")
    else
        -- Unix/Linux
        os.execute("sleep 2")
    end
end

local dir_name = "test"

os.execute(string.format("mkdir %s", dir_name))
sleep2s()
os.execute(string.format("rmdir %s", dir_name))
sleep2s()

-- 在Windows上使用dir命令，在Unix上使用ls命令
local cmd = (package.config:sub(1,1) == '\\') and "dir" or "ls -la"
local dir_content = io.popen(cmd, "r")

if dir_content then
    local line = dir_content:read("*line")
    while line do
        print(line)
        line = dir_content:read("*line")
    end
    dir_content:close()
else
    print("io.popen不可用，尝试使用os.execute")
    os.execute(cmd)
end

```

练习 7.7

`os.execute("cd /some/directory")` 不会改变 Lua 脚本的当前目录。每个 `os.execute` 都在独立的子进程中运行，子进程的目录改变不会影响主进程。
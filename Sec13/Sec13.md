## 13 位和字节

### 笔记

**位运算**
- 运算对象为整数（Lua 5.3+ 的整型）。常用运算符：
  - `a & b` 按位与，`a | b` 按位或，`a ~ b` 按位异或，`~a` 按位取反
  - `a << n` 左移 n 位，`a >> n` 右移 n 位（对负数的行为依实现整数语义）
- 常见用法：位标志、掩码、打包多字段到一个整数中。
```lua
local READ, WRITE, EXEC = 0x1, 0x2, 0x4
local perm = READ | WRITE

-- 置位
perm = perm | EXEC
-- 清位
perm = perm & ~WRITE
-- 测试
local canRead = (perm & READ) ~= 0
print(string.format("perm=0x%X, canRead=%s", perm, tostring(canRead)))

-- 取/放 指定位域（例如低 8 位作为通道号）
local function getLow8(x) return x & 0xFF end
local function setLow8(x, v) return (x & ~0xFF) | (v & 0xFF) end
```

**无符号整数**
- Lua 的整数语义是固定宽度二进制补码（通常 64 位），位运算按该宽度取模。
- 比较无符号大小可用 `math.ult(a, b)`；格式化为无符号十进制可用 `string.format("%u", x)`。
- 最大/最小整数：`math.maxinteger`, `math.mininteger`。
```lua
print(math.ult(-1, 0))              -- false（无符号视角下 0 < 2^N-1）
print(string.format("%u", -1))      -- 18446744073709551615（若为 64 位）
```

**打包和解包二进制数据（string.pack / string.unpack）**
- `string.pack(fmt, v1, v2, ...) -> string`
- `string.unpack(fmt, s [, pos]) -> v1, v2, ..., nextPos`
- 端序前缀：`<` 小端，`>` 大端，`=` 本机端序。
- 常用格式：
  - `i1/i2/i4/i8` 有符号整数（1/2/4/8 字节）
  - `I1/I2/I4/I8` 无符号整数（1/2/4/8 字节）
  - `f/d` float/double；`cN` 定长字节串；`s1/s2/s4` 前缀长度字串；`z` 以 `\0` 结尾字串
- 对齐与填充：
  - 本机模式（`=`）下，数值类型按“自然对齐”（通常等于其字节大小）对齐，可能自动插入填充字节。
  - 通过 `!n` 设置“最大对齐”（1/2/4/8/16），类型对齐不会超过该值；未设置时采用实现相关的默认上限（通常为 8）。
  - 在显式端序模式（`<`/`>`）下，最大对齐视为 1，即不做自动对齐；如需对齐，请用 `x` 手动填充。
  - `x` 表示 1 字节填充，可重复多次（例如 `xx` 表示 2 字节填充）。
```lua
-- 同一结构在不同对齐设置下的总长度
local s1 = string.pack("=I2I4", 1, 2)       -- 可能是 8 字节（I4 前自动插入 2 字节对齐）
local s2 = string.pack("=!1I2I4", 1, 2)     -- 最大对齐=1 → 6 字节（无自动对齐）
local s3 = string.pack("<I2I4", 1, 2)       -- 小端模式默认无自动对齐 → 6 字节
print(#s1, #s2, #s3)

-- 使用手动填充保证对齐
local s4 = string.pack("<I2xxI4", 1, 2)     -- 手动插入 2 字节填充 → 8 字节
```
```lua
-- 结构：version:uint16, id:uint32, tag:4字节
local fmt = "<I2I4c4"
local bin = string.pack(fmt, 1, 123456, "ABCD")

local ver, id, tag, pos = string.unpack(fmt, bin)
print(ver, id, tag, pos)  -- 1	123456	ABCD	11
```

**二进制文件**
- 以二进制方式打开：`io.open(path, "rb"/"wb"/"r+b")`。
- 写入使用 `file:write(string.pack(...))`；读取用 `file:read(n)` 获取字节串，再 `string.unpack`。
```lua
-- 写
local f = assert(io.open("data.bin", "wb"))
local header = string.pack("<I2I4c4", 1, 42, "TAG!")
f:write(header)
f:close()

-- 读
local rf = assert(io.open("data.bin", "rb"))
local buf = rf:read(2 + 4 + 4)
rf:close()
local ver, id, tag = string.unpack("<I2I4c4", buf)
print(ver, id, tag)
```


### 练习

我的lua版本只有5.1，这里只能靠g老师发挥了。

练习 13.1

```lua
function GetUnsignedModular(x, mod)
    local function ucmp(a, b)
        if a == b then return 0 end
        local aNeg = a < 0
        local bNeg = b < 0
        if aNeg ~= bNeg then
            return aNeg and 1 or -1
        end
        return a < b and -1 or 1
    end

    if mod == 0 then
        error("mod must be nonzero")
    end

    -- Fast path: if x < mod in unsigned sense
    if ucmp(x, mod) < 0 then
        return x
    end

    -- Find highest set bit of x (treat as 64-bit unsigned)
    local highest = -1
    for i = 63, 0, -1 do
        local mask = (1 << i)
        if (x & mask) ~= 0 then
            highest = i
            break
        end
    end

    if highest == -1 then
        return 0
    end

    -- Shift-subtract division to compute remainder
    local rem = 0
    for i = highest, 0, -1 do
        rem = (rem << 1)
        if (x & (1 << i)) ~= 0 then
            rem = rem | 1
        end
        if ucmp(rem, mod) >= 0 then
            rem = rem - mod
        end
    end

    return rem
end
```

练习 13.2

```lua
function countDigitsMath(n)
    if n == 0 then
        return 1
    end
    if n < 0 then
        n = -n  -- 处理负数，取绝对值
    end
    return math.floor(math.log10(n)) + 1
end
```

练习 13.3

```lua
function IsPowerOfTwo(x)
    if x <= 0 then return false end
    return (x & (x - 1)) == 0
end
```

练习 13.4

```lua
function CalHamWeight(x)
    local count = 0
    while x > 0 do
        if x & 1 == 1 then
            count = count + 1
        end
        x = x >> 1
    end
    return count
end
```

练习 13.5

```lua
function IsBinaryPalindrome(x)
    if x <= 0 then
        return x == 0  -- 0是回文，负数不是回文
    end
    
    local right = 0
    for i = 0, 63 do
        if x & (1 << i) ~= 0 then
            right = i
        end
    end
    
    local left = 0
    while left < right do
        if (x >> left) & 1 ~= (x >> right) & 1 then
            return false
        end
        left = left + 1
        right = right - 1
    end
    return true
end
```

练习 13.6

```lua
local BitArray = {}

function BitArray:newBitArray(n)
    if n > 63 then
        return nil
    end
    local self = {}
    self.n = n
    self.data = 0
    return self
end

function BitArray:setBit(n, v)
    if n > self.n then
        error("n is out of range")
    end
    self.data = self.data | (1 << n)
end

function BitArray:testBit(n)
    if n > self.n then
        error("n is out of range")
    end
    return (self.data >> n) & 1
end
```

练习 13.7

```lua
if not arg[1] then
    print("用法: lua p137.lua <二进制文件名>")
    os.exit(1)
end

local file = io.open(arg[1], "rb")
if not file then
    print("错误: 无法打开文件 " .. arg[1])
    os.exit(1)
end

local sum = 0.0
local record_count = 0
-- 记录结构大小计算 (考虑内存对齐):
-- int x: 4 字节 (偏移0-3)
-- char[3] code: 3 字节 (偏移4-6)
-- padding: 1 字节 (偏移7, 为float对齐)
-- float value: 4 字节 (偏移8-11)
-- 结构体末尾对齐: 4 字节 (总大小必须是4的倍数)
-- 总计: 16 字节每个记录
local RECORD_SIZE = 16

print("开始读取二进制文件: " .. arg[1])

while true do
    local record_data = file:read(RECORD_SIZE)
    
    if not record_data or #record_data < RECORD_SIZE then
        break
    end
    
    local x = string.unpack("<i4", record_data, 1)
    
    local code = string.sub(record_data, 5, 7)
    
    local value = string.unpack("<f", record_data, 9)
    
    sum = sum + value
    record_count = record_count + 1
    
    print(string.format("记录 %d: x=%d, code='%s', value=%.6f", 
                       record_count, x, code, value))
end

file:close()

print(string.format("\n总计读取 %d 条记录", record_count))
print(string.format("value字段总和: %.6f", sum))
```

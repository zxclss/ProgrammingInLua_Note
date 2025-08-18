## 12 日期和时间

### 笔记

**函数 os.time**
- 用途：获取当前时间戳，或把“日期表”转换为时间戳（自系统 Epoch 起的秒数）。
- 参数：`os.time([dateTable]) -> integer`
  - 不传参：返回当前本地时间的时间戳（1970/1/1 0:00 到现在的秒数）。
  - 传表：表中至少包含 `year`, `month`, `day`，可选 `hour`, `min`, `sec`, `isdst`（夏令时：true/false/nil）。未提供字段的默认值和推断行为可能受平台影响，建议显式提供。
- 示例：
```lua
-- 当前时间戳
local now = os.time()

-- 构造指定时间的时间戳（本地时区）
local ts = os.time{ year = 2025, month = 8, day = 16, hour = 13, min = 45, sec = 2 }

-- 时间差（单位：秒）
local later = os.time{ year = 2025, month = 9, day = 1, hour = 0, min = 0, sec = 0 }
local diffSeconds = os.difftime(later, ts)   -- 推荐用 os.difftime 计算差值
local diffDays = diffSeconds / 86400
```
- 相关：`os.difftime(t2, t1)` 返回以秒为单位的差值，避免潜在整型溢出；`os.clock()` 返回进程占用的 CPU 时间（非墙钟时间）。

**函数 os.date**
- 用途：把时间戳格式化为字符串，或解析为字段表。
- 参数：`os.date([format [, time]])`
  - `format` 省略时等价于 `"%c"`（本地日期时间）。
  - `time` 省略时使用当前时间；传入整数表示要格式化的时间戳。
  - `format` 以 `"!"` 前缀时使用 UTC，例如：`os.date("!%Y-%m-%dT%H:%M:%SZ", ts)`。
  - 当 `format == "*t"` 时，返回包含日期字段的表：
    - `year, month, day, hour, min, sec, wday, yday, isdst`
  - 恒等式：`os.time(os.date("*t", t)) == t`
- 示例：
```lua
-- 常见格式化
local s1 = os.date("%Y-%m-%d %H:%M:%S")            -- 本地时间
local s2 = os.date("!%Y-%m-%dT%H:%M:%SZ", now)     -- UTC ISO-like

-- 取字段表
local t = os.date("*t", now)
-- t = { year=2025, month=8, day=16, hour=13, min=45, sec=2, wday=1..7, yday=1..366, isdst=true/false }
```

**指示符（`os.date` 格式字符串）**

- 日期：
  - `%Y`：四位年份（例如 2025）
  - `%y`：两位年份（00..99）
  - `%m`：月份（01..12）
  - `%d`：日（01..31）
  - `%j`：当年第几天（001..366）
  - `%w`：星期（0..6，0 表示星期日）
- 时间：
  - `%H`：小时（00..23）
  - `%I`：小时（01..12）
  - `%M`：分钟（00..59）
  - `%S`：秒（00..60）
  - `%p`：AM/PM（本地化）
- 组合与本地化：
  - `%c`：本地日期与时间（例如 09/16/98 23:48:10）
  - `%x`：本地日期（例如 09/16/98）
  - `%X`：本地时间（例如 23:48:10）
- 时区：
  - `%Z`：时区缩写（如 CST）
  - `%z`：与 UTC 的时差（如 +0800）
- 其他：`%%` 输出 `%`
- 便捷：在格式字符串前加 `!` 使用 UTC（例如 `!%Y-%m-%d %H:%M:%S`）。
- 可移植性：部分平台不支持某些指示（如 `%e` 等），以实际平台为准。

**常见日期与时间处理**

```lua
-- 加40天后归一化
t = os.date("*t")
print(os.date("%Y/%m/%d", os.time(t)))
t.day = t.day + 40
print(os.date("%Y/%m/%d", os.time(t)))

-- 利用归一化转换成标准日期
T = {year = 2000, month = 1, day = 1, hour = 0, sec = 50133600}
os.date("%d/%m/%Y", os.time(T))

-- 利用difftime计算程序运行时间
local x = os.clock()
local s = 0
for i = 1, 100000 do s = s + i end
print(string.format("elapsed time: %.2f\n", os.clock() - x))
-- os.clock比os.time有更高精度的秒数，返回值是一个浮点数，POSIX里通常是1ms
```

### 练习

练习 12.1

```lua
function AddMonth(time)
    local t = os.date("*t", time)
    if type(t) == "table" then
        t.month = t.month + 1
        return os.time(t)
    end
    return os.time()
end

print(os.date("%d/%m/%Y", AddMonth(os.time())))
```

练习 12.2

```lua
function GetWeekday(time)
    local t = os.date("*t", time)
    return t.wday
end

print(GetWeekday(os.time()))
```

练习 12.3

```lua
function GetSecondOfDay(time)
    local t = os.date("*t", time)
    return t.hour * 3600 + t.min * 60 + t.sec
end

print(GetSecondOfDay(os.time()))
```

练习 12.4

```lua
function GetFirstFriday(year)
    local t = {year = year, month = 1, day = 1}
    if type(t) == "table" then
        t = os.date("*t", os.time(t))
    end
    while t.wday ~= 6 do
        t.day = t.day + 1
    end
    return t
end

print(GetFirstFriday(2025))
```

练习 12.5

```lua
function GetDiffDays(date1, date2)
    local diffSeconds = os.difftime(date2, date1)
    return math.floor(diffSeconds / 60 / 60 / 24)
end

print(GetDiffDays(os.time({year = 2024, month = 1, day = 1}), os.time({year = 2025, month = 1, day = 1})))
```

练习 12.6

```lua
function GetDiffMonths(date1, date2)
    local diffSeconds = os.difftime(date2, date1)
    return math.floor(diffSeconds / 60 / 60 / 24 / 30)
end

print(GetDiffMonths(os.time({year = 2024, month = 1, day = 1}), os.time({year = 2025, month = 1, day = 1})))
```

练习 12.7

不一样，加一个month后增加的day可能不一样。

练习 12.8

```lua
function GetTimeZone()
    local now = os.time()
    local localTime = os.date("*t", now)
    local utcTime = os.date("!*t", now)

    localTime.isdst = false
    utcTime.isdst = false

    local diffSeconds = os.difftime(os.time(localTime), os.time(utcTime))
    local sign = diffSeconds >= 0 and "+" or "-"
    local absSeconds = math.abs(diffSeconds)
    local hours = math.floor(absSeconds / 3600)
    local minutes = math.floor((absSeconds % 3600) / 60)

    return string.format("UTC%s%02d:%02d", sign, hours, minutes)
end

print(GetTimeZone())
```
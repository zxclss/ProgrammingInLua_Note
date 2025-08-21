## 18 迭代器和泛型for

### 笔记

**迭代器与闭包**：迭代器本质上是“多次调用可产生一系列返回值”的函数。最常见的做法是用闭包记住迭代状态。
```lua
-- 一个最小的数组值迭代器（闭包保存 i）
local function values(t)
	local i = 0
	return function()
		i = i + 1
		if t[i] ~= nil then return i, t[i] end
	end
end

for i, v in values({10, 20, 30}) do
	print(i, v)
end
```

**泛型 for 的语法与反 desugar**：
- 语法：`for var_1, ..., var_n in explist do body end`
- 运行时把 `explist` 求值为三元组：`迭代函数 f`，`不变状态 s`，`控制变量 var`。
- 循环结束条件：迭代函数返回的第一个值为 `nil`。
- 语义等价（伪代码）：
```lua
local f, s, var = explist
while true do
	local var_1, ..., var_n = f(s, var)
	if var_1 == nil then break end
	var = var_1
	body
end
```

**无状态迭代器**：迭代状态不存储在闭包里，而是通过 `(s, var)` 传入并返回新的 `var`。
- 典型例子：`pairs(t)` 返回 `next, t, nil`；迭代函数是标准库的 `next`，不变状态是表 `t`，控制变量从 `nil` 开始。
- `ipairs(t)`（5.3+）返回形如 `iter, t, 0` 的三元组；`iter(s, i)` 做 `i = i + 1; return i, s[i]`，当 `s[i] == nil` 时结束。

**按顺序遍历表（有序键）**：哈希部分无固有顺序，需先收集并排序键。
```lua
local function pairsByKeys(t, comp)
	local keys = {}
	for k in pairs(t) do keys[#keys+1] = k end
	table.sort(keys, comp)
	local i = 0
	return function()
		i = i + 1
		local k = keys[i]
		if k ~= nil then return k, t[k] end
	end
end

local t = {b=2, a=1, c=3}
for k, v in pairsByKeys(t) do
	print(k, v)
end
```
- 若需要对 `pairs` 的行为定制（如排序/过滤），可在表的元表中实现 `__pairs`（Lua 5.2+ 生效场景）。

**迭代器的真实含义**：
- 只是“遵循三元协议”的一组值：`(f, s, var)`；其中 `f` 负责给出下一批返回值。
- “闭包式迭代器”和“无状态迭代器”只是实现方式不同，语义一致。
- 许多库函数直接返回迭代器三元组或闭包：
  - `pairs/next`、`ipairs`（无状态）
  - `io.lines`, `string.gmatch`（常见为闭包，内部携带状态）

### 练习

练习 18.1

```lua
local function fromto(n, m)
	local function iter(s, i)
		i = i + 1
		if i < s.stop then
			return i
		end
	end
	return iter, { stop = m }, n - 1
end

for i in fromto(4, 7) do
	io.write(i, " ")
end
```

练习 18.2

```lua
local function fromto(start, stop, step)
	local function iter(s, i)
		i = i + step
		if i < s then
			return i
		end
	end
	return iter, stop, start - step
end

for i in fromto(4, 7, 2) do
	io.write(i, " ")
end
```

练习 18.3

```lua
local function uniquewords(file)
    local words = {}
    for line in io.lines(file) do
        for word in string.gmatch(line, "%w+") do
            words[word] = true
        end
    end
    return next, words, nil
end

for word in uniquewords("p183.lua") do
    io.write(word, " ")
end
```

练习 18.4

```lua
local function iterOfAllSubstr(str)
    local res = {}
    for s = 1, #str do
        for e = s, #str do
            table.insert(res, string.sub(str, s, e))
        end
    end
    return next, res, nil
end

for _, s in iterOfAllSubstr("abcdef") do
    io.write(s, " ")
end
```

练习 18.5

```lua
local function iter_subset(arr, f)
    local function dfs(depth, res)
        if depth > #arr then
            f(res)
            return
        end
        dfs(depth + 1, res)
        res[#res + 1] = arr[depth]
        dfs(depth + 1, res)
        res[#res] = nil
    end
    dfs(1, {})
end

iter_subset({1, 2, 3}, function(subset)
    for i = 1, #subset do
        io.write(subset[i], " ")
    end
    io.write("\n")
end)
```
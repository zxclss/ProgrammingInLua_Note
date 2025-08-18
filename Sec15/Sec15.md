## 15 数据文件和序列化

### 笔记

**数据文件**

把 Lua 文件当作数据文件，用lua的构造器来定义数据；使用时用`dofile`/`loadfile`加载。

> Lua 调用语法糖：`Entry{ ... }` 等价于 `Entry({ ... })`。所以在执行 `dofile("data.lua")` 时，Entry 被当作函数并以一个表作为唯一参数被调用。
> 补充：若 Entry 是带有 `__call` 元方法的表，也同样可以用 `Entry{...}` 调用。

```lua
-- data.lua
Entry{
    "Donald E. Knuth",
    "Literate Progamming",
    "CSLI",
    1992
}
```

```lua
-- 读取
local count = 0
function Entry () count = count + 1 end
dofile("data.lua")
print("number of entries: " .. count)
```

**序列化**

- 定义：把 Lua 值（主要是表）转成字符串，之后可`load`/`dofile`还原。
- 基本原则：
	- 字符串用`%q`转义；数值/布尔/`nil`直接写；函数/线程/userdata通常不支持。
	- 表：优先序列化数组部分，再序列化非数组键（带`[]`）。
	- 注意键必须可序列化（数值/字符串/布尔），否则跳过或报错。

**保存不带循环的表**

- 适用：树形结构，无共享子表、无自引用。

```lua
local function basicSerialize(v)
	if type(v) == "number" or type(v) == "boolean" or v == nil then
		return tostring(v)
	elseif type(v) == "string" then
		return string.format("%q", v)
	else
		error("unsupported type: " .. type(v))
	end
end

local function isArray(t)
	local n = 0
	for k in pairs(t) do
		if type(k) ~= "number" then return false end
		if k > n then n = k end
	end
	for i = 1, n do if t[i] == nil then return false end end
	return true
end

local function serializeNoCycle(t)
	assert(type(t) == "table")
	local parts = {"{"}
	if isArray(t) then
		for i = 1, #t do
			local v = t[i]
			parts[#parts+1] = (type(v) == "table") and serializeNoCycle(v) or basicSerialize(v)
			parts[#parts+1] = ","
		end
	else
		for k, v in pairs(t) do
			local keyStr = (type(k) == "string" and k:match("^[_%a][_%w]*$") ) and k or ("[" .. basicSerialize(k) .. "]")
			local valStr = (type(v) == "table") and serializeNoCycle(v) or basicSerialize(v)
			parts[#parts+1] = keyStr .. "=" .. valStr .. ","
		end
	end
	parts[#parts+1] = "}"
	return table.concat(parts)
end

-- 用法：
-- local s = "return " .. serializeNoCycle(t)
-- local copy = assert(load(s))()
```

**保存带有循环的表**

- 关键：为每个表分配唯一名字，先声明，再用赋值连接关系；用`saved`表记录已处理节点，避免无限递归；共享子表以引用方式还原。

```lua
local function basicSerialize(v)
	if type(v) == "number" or type(v) == "boolean" or v == nil then
		return tostring(v)
	elseif type(v) == "string" then
		return string.format("%q", v)
	else
		error("unsupported type: " .. type(v))
	end
end

local function saveWithCycles(name, value, saved, out)
	saved = saved or {}
	out = out or {}
	if type(value) ~= "table" then
		out[#out+1] = string.format("%s = %s\n", name, basicSerialize(value))
		return out
	end
	if saved[value] then
		out[#out+1] = string.format("%s = %s\n", name, saved[value])
		return out
	end
	saved[value] = name
	out[#out+1] = string.format("%s = {}\n", name)
	for k, v in pairs(value) do
		local field
		if type(k) == "string" and k:match("^[_%a][_%w]*$") then
			field = name .. "." .. k
		else
			field = string.format("%s[%s]", name, basicSerialize(k))
		end
		saveWithCycles(field, v, saved, out)
	end
	return out
end

-- 用法：
-- local t = {x = 1}; t.self = t
-- local lines = saveWithCycles("result", t)
-- local s = table.concat(lines)
-- -- s 形如：
-- -- result = {}
-- -- result.x = 1
-- -- result.self = result
-- -- 还原：local copy = assert(load(s))(); print(copy.x, copy.self == copy)
```

### 练习

练习 15.1

```lua
function serialize(o, indent)
	local t = type(o)
	indent = indent or 0
	local indentStr = string.rep("  ", indent)
	local nextIndentStr = string.rep("  ", indent + 1)
	if t == "number" or t == "string" or t == "boolean" or t == "nil" then
		io.write(string.format("%q", o))
	elseif t == "table" then
		io.write("{\n")
		for k, v in pairs(o) do
			io.write(nextIndentStr, k, " = ")
			serialize(v, indent + 1)
			io.write(",\n")
		end
		io.write(indentStr, "}\n")
	end
end
```

练习 15.2

```lua
function serialize(o, indent)
	local t = type(o)
	indent = indent or 0
	local indentStr = string.rep("  ", indent)
	local nextIndentStr = string.rep("  ", indent + 1)
	local function formatKey(k)
		if type(k) == "string" then
			return string.format("[%q]", k)
		else
			return "[" .. tostring(k) .. "]"
		end
	end
	if t == "number" or t == "string" or t == "boolean" or t == "nil" then
		io.write(string.format("%q", o))
	elseif t == "table" then
		io.write("{\n")
		for k, v in pairs(o) do
			io.write(nextIndentStr, formatKey(k), " = ")
			serialize(v, indent + 1)
			io.write(",\n")
		end
		io.write(indentStr, "}\n")
	end
end

local cases = {
	{
		{
			a = 1,
			b = 2,
			c = 3
		}
	}
}
for _, case in ipairs(cases) do
	serialize(case)
end
```

练习 15.3

```lua
function serialize(o, indent)
	local t = type(o)
	indent = indent or 0
	local indentStr = string.rep("  ", indent)
	local nextIndentStr = string.rep("  ", indent + 1)
	local function formatKey(k)
		if type(k) == "string" then
			if k:match("^[_%a][_%w]*$") then
				return k
			else
				return string.format("[%q]", k)
			end
		else
			return "[" .. tostring(k) .. "]"
		end
	end
	if t == "number" or t == "string" or t == "boolean" or t == "nil" then
		io.write(string.format("%q", o))
	elseif t == "table" then
		io.write("{\n")
		for k, v in pairs(o) do
			io.write(nextIndentStr, formatKey(k), " = ")
			serialize(v, indent + 1)
			io.write(",\n")
		end
		io.write(indentStr, "}\n")
	end
end

local cases = {
	{
		{
			a = 1,
			b = 2,
			c = 3,
		}
	}
}
for _, case in ipairs(cases) do
	serialize(case)
end
```

练习 15.4

```lua
function serialize(o, indent)
	local t = type(o)
	indent = indent or 0
	local indentStr = string.rep("  ", indent)
	local nextIndentStr = string.rep("  ", indent + 1)
	local function formatKey(k)
		if type(k) == "string" then
			if k:match("^[_%a][_%w]*$") then
				return k
			else
				return string.format("[%q]", k)
			end
		else
			return "[" .. tostring(k) .. "]"
		end
	end
	if t == "number" then
		io.write(tostring(o))
	elseif t == "boolean" or t == "nil" then
		io.write(tostring(o))
	elseif t == "string" then
		io.write(string.format("%q", o))
	elseif t == "table" then
		io.write("{\n")
		local n = #o
		-- 先输出数组部分（1..n）为纯元素列表
		for i = 1, n do
			io.write(nextIndentStr)
			serialize(o[i], indent + 1)
			io.write(",\n")
		end
		-- 再输出非数组键
		for k, v in pairs(o) do
			if not (type(k) == "number" and k % 1 == 0 and k >= 1 and k <= n) then
				io.write(nextIndentStr, formatKey(k), " = ")
				serialize(v, indent + 1)
				io.write(",\n")
			end
		end
		io.write(indentStr, "}\n")
	end
end

local cases = {
	{
		{
			a = 1,
			b = 2,
			c = 3,
		},
		{14, 15, 19},
	}
}
for _, case in ipairs(cases) do
	serialize(case)
end
```

练习 15.5

```lua
local function basicSerialize(v)
	local t = type(v)
	if t == "number" or t == "boolean" or t == "nil" then
		return tostring(v)
	elseif t == "string" then
		return string.format("%q", v)
	else
		error("unsupported type: " .. t)
	end
end

local function isIdentifier(s)
	return type(s) == "string" and s:match("^[_%a][_%w]*$") ~= nil
end

local function formatIndexKey(k)
	if isIdentifier(k) then
		return k
	else
		return "[" .. basicSerialize(k) .. "]"
	end
end

-- Count references and detect cycles
local function analyzeGraph(root)
	local refs = {}
	local cyclic = {}
	local visited = {}

	local function dfs(value, stack)
		if type(value) ~= "table" then return end
		refs[value] = (refs[value] or 0) + 1
		if stack[value] then
			cyclic[value] = true
			return
		end
		if visited[value] then return end
		visited[value] = true
		stack[value] = true
		for k, v in pairs(value) do
			dfs(k, stack)
			dfs(v, stack)
		end
		stack[value] = nil
	end

	dfs(root, {})
	return refs, cyclic
end

local function isArray(t)
	local n = 0
	for k in pairs(t) do
		if type(k) ~= "number" or k <= 0 or k % 1 ~= 0 then return false end
		if k > n then n = k end
	end
	for i = 1, n do if t[i] == nil then return false end end
	return true, n
end

local function save(name, value)
	assert(type(name) == "string" and name ~= "", "name must be a non-empty string")
	local out = {}
	local function write(str) out[#out+1] = str end

	local refs, cyclic = analyzeGraph(value)
	local anchored = {}
	for tbl, cnt in pairs(refs) do
		if cnt > 1 or cyclic[tbl] then
			anchored[tbl] = true
		end
	end

	local names = {}
	local function getName(tbl)
		if tbl == value then return name end
		local nm = names[tbl]
		if nm == nil then
			nm = "t" .. tostring(1 + #names)
			names[tbl] = nm
		end
		return nm
	end

	-- Pre-assign names to anchored, excluding root first for stable numbering
	for tbl in pairs(anchored) do
		if tbl ~= value then getName(tbl) end
	end

	local function writeValue(v, indent)
		local t = type(v)
		if t ~= "table" then
			write(basicSerialize(v))
			return
		end
		if anchored[v] then
			write(getName(v))
			return
		end
		-- Inline constructor for simple subtree
		local indentStr = string.rep("  ", indent)
		local nextIndentStr = string.rep("  ", indent + 1)
		local arr, n = isArray(v)
		write("{\n")
		if arr then
			for i = 1, n do
				write(nextIndentStr)
				writeValue(v[i], indent + 1)
				write(",\n")
			end
		else
			for k, vv in pairs(v) do
				write(nextIndentStr)
				write(formatIndexKey(k))
				write(" = ")
				writeValue(vv, indent + 1)
				write(",\n")
			end
		end
		write(indentStr .. "}")
	end

	-- 1) Declare non-root anchored locals so they can be referenced in constructors
	local anchoredList = {}
	for tbl in pairs(anchored) do
		if tbl ~= value then anchoredList[#anchoredList+1] = tbl end
	end
	-- deterministic ordering (optional): by assigned name
	table.sort(anchoredList, function(a, b) return getName(a) < getName(b) end)
	for _, tbl in ipairs(anchoredList) do
		write("local ")
		write(getName(tbl))
		write(" = {}\n")
	end

	-- 2) Assign root either as constructor (if not anchored) or empty table
	if type(value) == "table" then
		if anchored[value] then
			write(name .. " = {}\n")
		else
			write(name .. " = ")
			writeValue(value, 0)
			write("\n")
		end
	else
		write(name .. " = " .. basicSerialize(value) .. "\n")
	end

	-- 3) Populate anchored tables (including root if anchored)
	local function emitAssignments(tbl, targetName, indent)
		local nextIndentStr = string.rep("  ", indent + 1)
		for k, v in pairs(tbl) do
			write(nextIndentStr)
			write(targetName)
			if isIdentifier(k) then
				write("." .. k)
			else
				write("[" .. basicSerialize(k) .. "]")
			end
			write(" = ")
			writeValue(v, indent + 1)
			write("\n")
		end
	end

	if type(value) == "table" then
		if anchored[value] then
			emitAssignments(value, name, 0)
		end
		for _, tbl in ipairs(anchoredList) do
			emitAssignments(tbl, getName(tbl), 0)
		end
	end

	return table.concat(out)
end

-- export
return {
	save = save
}
```
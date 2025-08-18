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

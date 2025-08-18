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
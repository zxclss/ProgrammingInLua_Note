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
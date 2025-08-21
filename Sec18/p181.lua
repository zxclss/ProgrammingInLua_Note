local function fromto(n, m)
	local function iter(s, i)
		i = i + 1
		if i < s then
			return i
		end
	end
	return iter, m, n - 1
end

for i in fromto(4, 7) do
	io.write(i, " ")
end
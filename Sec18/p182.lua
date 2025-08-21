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
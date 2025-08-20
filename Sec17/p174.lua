local function combinedSearcher(modname)
	local combinedPath = package.path .. ";" .. package.cpath
	local filename, searchErr = package.searchpath(modname, combinedPath)
	if not filename then
		return "\n\t" .. tostring(searchErr)
	end

	local loader, luaErr = loadfile(filename)
	if loader then
		return loader, filename
	end

	local initFunc = "luaopen_" .. (modname:gsub("%.", "_"))
	local cfunc, cErr = package.loadlib(filename, initFunc)
	if cfunc then
		return cfunc, filename
	end

	local msg = string.format(
		"\n\tno loader for file '%s'\n\tloadfile error: %s\n\tloadlib error: %s",
		filename,
		tostring(luaErr),
		tostring(cErr)
	)
	return msg
end

-- insert after preloader, before default Lua/C searchers
if type(package.searchers) == "table" then
	table.insert(package.searchers, 2, combinedSearcher)
end

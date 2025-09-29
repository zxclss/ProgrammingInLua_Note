function getname(func)
    local n = Names[func]
    if not n then
        return "<unknown>"
    end
    if n.what == "C" then
        return n.name or "<C function>"
    end
    -- Prefer the Lua-visible name when available
    if n.name and n.name ~= "" then
        return n.name
    end
    local src = n.short_src or "?"
    local line = n.linedefined
    if n.what == "main" then
        return string.format("main@%s", src)
    end
    if type(line) == "number" and line > 0 then
        return string.format("%s:%d", src, line)
    else
        return src
    end
end

-- Collect and sort results for pretty printing
local entries = {}
for func, count in pairs(Counters) do
    table.insert(entries, { name = getname(func), count = count })
end

table.sort(entries, function(a, b)
    if a.count ~= b.count then
        return a.count > b.count -- sort by count desc
    else
        return a.name < b.name   -- tie-break by name asc
    end
end)

-- Compute column widths
local nameWidth, countWidth = 0, 0
for _, e in ipairs(entries) do
    if #e.name > nameWidth then nameWidth = #e.name end
    local cw = #tostring(e.count)
    if cw > countWidth then countWidth = cw end
end
if nameWidth < 8 then nameWidth = 8 end
if countWidth < 5 then countWidth = 5 end

-- Header
local header = string.format("%-" .. nameWidth .. "s  %" .. countWidth .. "s", "Function", "Count")
print(header)
print(string.rep("-", #header))

-- Rows
for _, e in ipairs(entries) do
    print(string.format("%-" .. nameWidth .. "s  %" .. countWidth .. "d", e.name, e.count))
end
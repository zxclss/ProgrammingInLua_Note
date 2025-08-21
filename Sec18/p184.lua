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
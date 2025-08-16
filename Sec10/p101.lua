function Split(s, sep)
    local t = {}
    local i = 1
    for str in string.gmatch(s, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

Sample = "a,b,c,d,e,f,g"
for i, v in ipairs(Split(Sample, ",")) do
    io.write(v, " ")
end
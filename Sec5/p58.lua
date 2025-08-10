local function concat(str_list)
    local res = ""
    for _, v in ipairs(str_list) do
        res = res .. v
    end
    return res
end

local function gen_str_list(N)
    local str_list = {}
    for i = 1, N do
        str_list[i] = string.format("%05d", i)
    end
    return str_list
end

local function calTime(func)
    local start_time = os.clock()
    func()
    local end_time = os.clock()
    return end_time - start_time
end

local str_list = gen_str_list(100000)
print(calTime(function()
    concat(str_list)
end).."s")
print(calTime(function()
    table.concat(str_list)
end).."s")
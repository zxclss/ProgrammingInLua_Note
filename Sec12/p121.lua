function AddMonth(time)
    local t = os.date("*t", time)
    if type(t) == "table" then
        t.month = t.month + 1
        return os.time(t)
    end
    return os.time()
end

print(os.date("%d/%m/%Y", AddMonth(os.time())))
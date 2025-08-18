function GetFirstFriday(year)
    local t = {year = year, month = 1, day = 1}
    if type(t) == "table" then
        t = os.date("*t", os.time(t))
    end
    while t.wday ~= 6 do
        t.day = t.day + 1
    end
    return t
end

print(GetFirstFriday(2025))
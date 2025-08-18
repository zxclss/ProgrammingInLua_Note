function GetWeekday(time)
    local t = os.date("*t", time)
    return t.wday
end

print(GetWeekday(os.time()))
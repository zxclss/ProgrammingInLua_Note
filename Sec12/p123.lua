function GetSecondOfDay(time)
    local t = os.date("*t", time)
    return t.hour * 3600 + t.min * 60 + t.sec
end

print(GetSecondOfDay(os.time()))
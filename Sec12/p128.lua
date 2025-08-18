function GetTimeZone()
    local now = os.time()
    local localTime = os.date("*t", now)
    local utcTime = os.date("!*t", now)

    localTime.isdst = false
    utcTime.isdst = false

    local diffSeconds = os.difftime(os.time(localTime), os.time(utcTime))
    local sign = diffSeconds >= 0 and "+" or "-"
    local absSeconds = math.abs(diffSeconds)
    local hours = math.floor(absSeconds / 3600)
    local minutes = math.floor((absSeconds % 3600) / 60)

    return string.format("UTC%s%02d:%02d", sign, hours, minutes)
end

print(GetTimeZone())
function GetDiffMonths(date1, date2)
    local diffSeconds = os.difftime(date2, date1)
    return math.floor(diffSeconds / 60 / 60 / 24 / 30)
end

print(GetDiffMonths(os.time({year = 2024, month = 1, day = 1}), os.time({year = 2025, month = 1, day = 1})))
function getfield(f)
    -- 检查字符串是否严格符合有效的字段名格式
    -- 只允许字母/下划线开头，后跟字母/数字/下划线，用点分隔的标识符
    -- 使用两个模式：一个匹配单个标识符，另一个匹配多个用点分隔的标识符
    local single_id = "^[%a_][%w_]*$"
    local multi_id = "^[%a_][%w_]*%.[%a_][%w_]*"
    
    if not (string.find(f, single_id) or string.find(f, multi_id)) then
        error("Invalid field name: " .. f)
    end
    
    -- 如果有点分隔符，进一步验证完整格式
    if string.find(f, "%.") then
        -- 检查是否只包含有效的标识符和单个点分隔符
        local parts = {}
        for part in string.gmatch(f, "[^%.]+") do
            if not string.find(part, "^[%a_][%w_]*$") then
                error("Invalid field name: " .. f)
            end
            table.insert(parts, part)
        end
        
        -- 重新构建字符串并检查是否与原字符串相同
        local reconstructed = table.concat(parts, ".")
        if reconstructed ~= f then
            error("Invalid field name: " .. f)
        end
    end
    
    local v = _G
    for w in string.gmatch(f, "[%a_][%w_]*") do
        v = v[w]
        if v == nil then
            return nil
        end
        -- 如果不是表类型且还有更多字段要查找，返回nil
        if type(v) ~= "table" then
            local remaining = string.match(f, w .. "%.(.+)")
            if remaining then
                return nil
            end
        end
    end
    return v
end


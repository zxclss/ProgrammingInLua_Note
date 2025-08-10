-- 获取文件最后n行的函数
local function get_last_n_lines(filename, n)
    local file = io.open(filename, "r")
    if not file then
        return nil, "File not found"
    end
    
    -- 获取文件大小
    local size = file:seek("end")
    if size == 0 then
        file:close()
        return {}, "File is empty"
    end
    
    local lines = {}
    local pos = size - 1
    local line_count = 0
    
    -- 从文件末尾开始向前搜索最后n行
    while pos >= 0 and line_count < n do
        file:seek("set", pos)
        local char = file:read(1)
        
        if char == "\n" then
            -- 找到换行符，读取这一行
            local line = file:read("*line")
            if line then
                table.insert(lines, 1, line)  -- 插入到开头，保持顺序
                line_count = line_count + 1
                pos = pos - 1
            end
        elseif pos == 0 then
            -- 到达文件开头，整个文件就是一行
            file:seek("set", 0)
            local line = file:read("*line")
            if line then
                table.insert(lines, 1, line)
                line_count = line_count + 1
            end
            break
        end
        
        pos = pos - 1
    end
    
    file:close()
    return lines
end

-- 主程序
local file_dir = "data.in"
local n = tonumber(arg[1]) or 5  -- 从命令行参数获取行数，默认为5行

local lines, err = get_last_n_lines(file_dir, n)
if err then
    io.write("Error: " .. err .. "\n")
else
    io.write("Last " .. #lines .. " lines:\n")
    for i, line in ipairs(lines) do
        io.write(string.format("%d: %s\n", i, line))
    end
end
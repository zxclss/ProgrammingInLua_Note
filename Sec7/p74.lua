local file_dir = "data.in"
local file = io.open(file_dir, "r")
if not file then
    io.write("File not found\n")
    os.exit()
end

-- 获取文件大小
local size = file:seek("end")
if size == 0 then
    io.write("File is empty\n")
    file:close()
    os.exit()
end

-- 从文件末尾开始向前搜索最后一行
local last_line = ""
local pos = size - 1
local found_line = false

while pos >= 0 and not found_line do
    file:seek("set", pos)
    local char = file:read(1)
    
    if char == "\n" then
        -- 找到换行符，读取这一行
        last_line = file:read("*line")
        found_line = true
    elseif pos == 0 then
        -- 到达文件开头，整个文件就是一行
        file:seek("set", 0)
        last_line = file:read("*line")
        found_line = true
    end
    
    pos = pos - 1
end

if not found_line then
    -- 如果没找到换行符，整个文件就是一行
    file:seek("set", 0)
    last_line = file:read("*line")
end

io.write("Last line: " .. (last_line or "") .. "\n")
file:close()
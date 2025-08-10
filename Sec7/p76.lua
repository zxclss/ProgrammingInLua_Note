local function sleep2s()
    -- 在Windows上使用timeout命令，在Unix/Linux上使用sleep命令
    if package.config:sub(1,1) == '\\' then
        -- Windows
        os.execute("timeout /t 2 /nobreak > nul")
    else
        -- Unix/Linux
        os.execute("sleep 2")
    end
end

local dir_name = "test"

os.execute(string.format("mkdir %s", dir_name))
sleep2s()
os.execute(string.format("rmdir %s", dir_name))
sleep2s()

-- 在Windows上使用dir命令，在Unix上使用ls命令
local cmd = (package.config:sub(1,1) == '\\') and "dir" or "ls -la"
local dir_content = io.popen(cmd, "r")

if dir_content then
    local line = dir_content:read("*line")
    while line do
        print(line)
        line = dir_content:read("*line")
    end
    dir_content:close()
else
    print("io.popen不可用，尝试使用os.execute")
    os.execute(cmd)
end

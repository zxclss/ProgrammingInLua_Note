-- 练习 7.3: 文件读取性能比较
-- 比较按字节、行、块（8KB）、一次性读取整个文件这几种方法的性能表现

local function create_test_file(filename, size_mb)
    -- 创建测试文件
    local file = io.open(filename, "w")
    if not file then
        error("Cannot create test file: " .. filename)
    end
    
    local size_bytes = size_mb * 1024 * 1024
    local chunk_size = 1024  -- 1KB chunks for writing
    
    for i = 1, size_bytes, chunk_size do
        local remaining = math.min(chunk_size, size_bytes - i + 1)
        local chunk = string.rep("A", remaining)
        file:write(chunk)
        
        -- 每1MB添加一个换行符，模拟真实文件
        if i % (1024 * 1024) == 0 then
            file:write("\n")
        end
    end
    
    file:close()
    print("Created test file: " .. filename .. " (" .. size_mb .. " MB)")
end

local function read_by_byte(filename)
    local start_time = os.clock()
    local file = io.open(filename, "rb")
    if not file then
        error("Cannot open file: " .. filename)
    end
    
    local byte_count = 0
    while true do
        local byte = file:read(1)
        if not byte then break end
        byte_count = byte_count + 1
    end
    
    file:close()
    local end_time = os.clock()
    return end_time - start_time, byte_count
end

local function read_by_line(filename)
    local start_time = os.clock()
    local file = io.open(filename, "r")
    if not file then
        error("Cannot open file: " .. filename)
    end
    
    local line_count = 0
    for line in file:lines() do
        line_count = line_count + 1
    end
    
    file:close()
    local end_time = os.clock()
    return end_time - start_time, line_count
end

local function read_by_block(filename, block_size)
    local start_time = os.clock()
    local file = io.open(filename, "rb")
    if not file then
        error("Cannot open file: " .. filename)
    end
    
    local block_count = 0
    local total_bytes = 0
    while true do
        local block = file:read(block_size)
        if not block then break end
        block_count = block_count + 1
        total_bytes = total_bytes + #block
    end
    
    file:close()
    local end_time = os.clock()
    return end_time - start_time, block_count, total_bytes
end

local function read_entire_file(filename)
    local start_time = os.clock()
    local file = io.open(filename, "rb")
    if not file then
        error("Cannot open file: " .. filename)
    end
    
    local content = file:read("*a")
    local size = #content
    
    file:close()
    local end_time = os.clock()
    return end_time - start_time, size
end

local function test_file_size_limit()
    print("\n=== 测试一次性读取整个文件的最大支持大小 ===")
    
    local sizes = {1, 10, 50, 100, 200, 500, 1000}  -- MB
    local max_supported = 0
    
    for _, size in ipairs(sizes) do
        local test_file = "test_" .. size .. "MB.dat"
        print("Testing file size: " .. size .. " MB...")
        
        -- 创建测试文件
        create_test_file(test_file, size)
        
        -- 尝试一次性读取
        local success, time, file_size = pcall(read_entire_file, test_file)
        if success then
            print("  ✓ Success: " .. string.format("%.3f", time) .. "s, " .. 
                  string.format("%.2f", file_size / (1024 * 1024)) .. " MB")
            max_supported = size
        else
            print("  ✗ Failed: " .. tostring(time))
            break
        end
        
        -- 清理测试文件
        os.remove(test_file)
    end
    
    print("\n最大支持的文件大小: " .. max_supported .. " MB")
    return max_supported
end

local function run_performance_test()
    print("=== 文件读取性能比较测试 ===")
    
    -- 创建不同大小的测试文件
    local test_sizes = {1, 10, 50}  -- MB
    local test_file = "performance_test.dat"
    
    for _, size in ipairs(test_sizes) do
        print("\n--- 测试文件大小: " .. size .. " MB ---")
        
        -- 创建测试文件
        create_test_file(test_file, size)
        
        -- 测试按字节读取
        local success, time, bytes = pcall(read_by_byte, test_file)
        if success then
            print(string.format("按字节读取: %.3fs, %d bytes", time, bytes))
        else
            print("按字节读取: 失败 - " .. tostring(time))
        end
        
        -- 测试按行读取
        success, time, lines = pcall(read_by_line, test_file)
        if success then
            print(string.format("按行读取:   %.3fs, %d lines", time, lines))
        else
            print("按行读取: 失败 - " .. tostring(time))
        end
        
        -- 测试按块读取 (8KB)
        success, time, blocks, total_bytes = pcall(read_by_block, test_file, 8 * 1024)
        if success then
            print(string.format("按块读取:   %.3fs, %d blocks (8KB), %d bytes", time, blocks, total_bytes))
        else
            print("按块读取: 失败 - " .. tostring(time))
        end
        
        -- 测试一次性读取整个文件
        success, time, file_size = pcall(read_entire_file, test_file)
        if success then
            print(string.format("一次性读取: %.3fs, %d bytes", time, file_size))
        else
            print("一次性读取: 失败 - " .. tostring(time))
        end
        
        -- 清理测试文件
        os.remove(test_file)
    end
end

-- 主程序
local function main()
    print("文件读取性能测试程序")
    print("====================")
    
    -- 运行性能测试
    run_performance_test()
    
    -- 测试文件大小限制
    test_file_size_limit()
    
    print("\n测试完成！")
end

-- 如果直接运行此脚本，则执行主程序
if arg[0]:match("p73%.lua$") then
    main()
end 
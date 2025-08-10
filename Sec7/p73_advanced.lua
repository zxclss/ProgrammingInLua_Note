-- 练习 7.3 高级版: 文件读取性能比较和内存限制测试
-- 测试更大的文件大小范围，监控内存使用情况

local function get_memory_usage()
    -- 获取当前内存使用情况（Lua 5.1兼容）
    local mem = collectgarbage("count")
    return math.floor(mem / 1024)  -- 转换为KB
end

local function create_test_file(filename, size_mb)
    -- 创建测试文件
    local file = io.open(filename, "w")
    if not file then
        error("Cannot create test file: " .. filename)
    end
    
    local size_bytes = size_mb * 1024 * 1024
    local chunk_size = 1024 * 1024  -- 1MB chunks for faster writing
    
    print("  Creating file...")
    for i = 1, size_bytes, chunk_size do
        local remaining = math.min(chunk_size, size_bytes - i + 1)
        local chunk = string.rep("A", remaining)
        file:write(chunk)
        
        -- 每10MB添加一个换行符
        if i % (10 * 1024 * 1024) == 0 then
            file:write("\n")
        end
        
        -- 显示进度
        if i % (50 * 1024 * 1024) == 0 then
            local progress = math.floor(i / size_bytes * 100)
            io.write(string.format("  Progress: %d%%\r", progress))
            io.flush()
        end
    end
    
    file:close()
    print("  File created successfully")
end

local function read_by_byte(filename)
    local start_time = os.clock()
    local start_mem = get_memory_usage()
    
    local file = io.open(filename, "rb")
    if not file then
        error("Cannot open file: " .. filename)
    end
    
    local byte_count = 0
    while true do
        local byte = file:read(1)
        if not byte then break end
        byte_count = byte_count + 1
        
        -- 每1MB显示进度
        if byte_count % (1024 * 1024) == 0 then
            local progress = math.floor(byte_count / (1024 * 1024))
            io.write(string.format("  Reading: %d MB\r", progress))
            io.flush()
        end
    end
    
    file:close()
    local end_time = os.clock()
    local end_mem = get_memory_usage()
    
    return end_time - start_time, byte_count, end_mem - start_mem
end

local function read_by_line(filename)
    local start_time = os.clock()
    local start_mem = get_memory_usage()
    
    local file = io.open(filename, "r")
    if not file then
        error("Cannot open file: " .. filename)
    end
    
    local line_count = 0
    for line in file:lines() do
        line_count = line_count + 1
        
        -- 每1000行显示进度
        if line_count % 1000 == 0 then
            io.write(string.format("  Reading: %d lines\r", line_count))
            io.flush()
        end
    end
    
    file:close()
    local end_time = os.clock()
    local end_mem = get_memory_usage()
    
    return end_time - start_time, line_count, end_mem - start_mem
end

local function read_by_block(filename, block_size)
    local start_time = os.clock()
    local start_mem = get_memory_usage()
    
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
        
        -- 每1000块显示进度
        if block_count % 1000 == 0 then
            local progress_mb = math.floor(total_bytes / (1024 * 1024))
            io.write(string.format("  Reading: %d MB\r", progress_mb))
            io.flush()
        end
    end
    
    file:close()
    local end_time = os.clock()
    local end_mem = get_memory_usage()
    
    return end_time - start_time, block_count, total_bytes, end_mem - start_mem
end

local function read_entire_file(filename)
    local start_time = os.clock()
    local start_mem = get_memory_usage()
    
    local file = io.open(filename, "rb")
    if not file then
        error("Cannot open file: " .. filename)
    end
    
    print("  Reading entire file into memory...")
    local content = file:read("*a")
    local size = #content
    
    file:close()
    local end_time = os.clock()
    local end_mem = get_memory_usage()
    
    return end_time - start_time, size, end_mem - start_mem
end

local function test_file_size_limit_advanced()
    print("\n=== 高级文件大小限制测试 ===")
    
    -- 测试更大的文件大小范围
    local sizes = {1, 10, 50, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000}
    local max_supported = 0
    local results = {}
    
    for _, size in ipairs(sizes) do
        local test_file = "test_" .. size .. "MB.dat"
        print("\nTesting file size: " .. size .. " MB...")
        
        -- 创建测试文件
        create_test_file(test_file, size)
        
        -- 尝试一次性读取
        local success, result = pcall(read_entire_file, test_file)
        if success then
            local time, file_size, mem_used = unpack(result)
            local actual_size_mb = file_size / (1024 * 1024)
            print(string.format("  ✓ Success: %.3fs, %.2f MB, Memory: %+d KB", 
                  time, actual_size_mb, mem_used))
            
            table.insert(results, {
                size = size,
                time = time,
                actual_size = actual_size_mb,
                memory = mem_used
            })
            
            max_supported = size
        else
            print("  ✗ Failed: " .. tostring(result))
            break
        end
        
        -- 清理测试文件
        os.remove(test_file)
        
        -- 强制垃圾回收
        collectgarbage("collect")
        
        -- 等待一下让系统稳定
        os.execute("timeout /t 1 /nobreak >nul 2>&1")
    end
    
    print("\n=== 测试结果汇总 ===")
    print("最大支持的文件大小: " .. max_supported .. " MB")
    print("\n详细结果:")
    print("大小(MB) | 时间(s) | 实际大小(MB) | 内存变化(KB)")
    print("---------|----------|---------------|-------------")
    
    for _, result in ipairs(results) do
        print(string.format("%8d | %8.3f | %13.2f | %+11d", 
              result.size, result.time, result.actual_size, result.memory))
    end
    
    return max_supported, results
end

local function run_performance_test_advanced()
    print("=== 高级文件读取性能比较测试 ===")
    
    -- 测试更大的文件大小
    local test_sizes = {1, 10, 50, 100, 200}
    local test_file = "performance_test_advanced.dat"
    local results = {}
    
    for _, size in ipairs(test_sizes) do
        print("\n--- 测试文件大小: " .. size .. " MB ---")
        
        -- 创建测试文件
        create_test_file(test_file, size)
        
        local test_result = {size = size}
        
        -- 测试按字节读取
        print("  测试按字节读取...")
        local success, time, bytes, mem = pcall(read_by_byte, test_file)
        if success then
            test_result.byte_time = time
            test_result.byte_bytes = bytes
            test_result.byte_mem = mem
            print(string.format("    按字节读取: %.3fs, %d bytes, Memory: %+d KB", time, bytes, mem))
        else
            print("    按字节读取: 失败 - " .. tostring(time))
        end
        
        -- 测试按行读取
        print("  测试按行读取...")
        success, time, lines, mem = pcall(read_by_line, test_file)
        if success then
            test_result.line_time = time
            test_result.line_lines = lines
            test_result.line_mem = mem
            print(string.format("    按行读取:   %.3fs, %d lines, Memory: %+d KB", time, lines, mem))
        else
            print("    按行读取: 失败 - " .. tostring(time))
        end
        
        -- 测试按块读取 (8KB)
        print("  测试按块读取...")
        success, time, blocks, total_bytes, mem = pcall(read_by_block, test_file, 8 * 1024)
        if success then
            test_result.block_time = time
            test_result.block_blocks = blocks
            test_result.block_bytes = total_bytes
            test_result.block_mem = mem
            print(string.format("    按块读取:   %.3fs, %d blocks (8KB), %d bytes, Memory: %+d KB", 
                  time, blocks, total_bytes, mem))
        else
            print("    按块读取: 失败 - " .. tostring(time))
        end
        
        -- 测试一次性读取整个文件
        print("  测试一次性读取...")
        success, time, file_size, mem = pcall(read_entire_file, test_file)
        if success then
            test_result.entire_time = time
            test_result.entire_size = file_size
            test_result.entire_mem = mem
            print(string.format("    一次性读取: %.3fs, %d bytes, Memory: %+d KB", time, file_size, mem))
        else
            print("    一次性读取: 失败 - " .. tostring(time))
        end
        
        table.insert(results, test_result)
        
        -- 清理测试文件
        os.remove(test_file)
        
        -- 强制垃圾回收
        collectgarbage("collect")
    end
    
    -- 输出性能比较表
    print("\n=== 性能比较表 ===")
    print("文件大小 | 按字节 | 按行 | 按块(8KB) | 一次性读取")
    print("---------|---------|------|------------|------------")
    
    for _, result in ipairs(results) do
        local byte_time = result.byte_time and string.format("%.3fs", result.byte_time) or "N/A"
        local line_time = result.line_time and string.format("%.3fs", result.line_time) or "N/A"
        local block_time = result.block_time and string.format("%.3fs", result.block_time) or "N/A"
        local entire_time = result.entire_time and string.format("%.3fs", result.entire_time) or "N/A"
        
        print(string.format("%8d | %7s | %4s | %10s | %10s", 
              result.size, byte_time, line_time, block_time, entire_time))
    end
    
    return results
end

-- 主程序
local function main()
    print("高级文件读取性能测试程序")
    print("==========================")
    
    -- 显示系统信息
    print("系统信息:")
    print("  Lua版本: " .. _VERSION)
    print("  当前内存使用: " .. get_memory_usage() .. " KB")
    
    -- 运行高级性能测试
    local perf_results = run_performance_test_advanced()
    
    -- 测试文件大小限制
    local max_size, size_results = test_file_size_limit_advanced()
    
    print("\n=== 最终结论 ===")
    print("1. 性能排名 (从快到慢):")
    print("   - 按块读取 (8KB) - 最快，内存效率最高")
    print("   - 一次性读取整个文件 - 较快，但内存消耗大")
    print("   - 按行读取 - 中等，适合文本文件")
    print("   - 按字节读取 - 最慢，但最灵活")
    
    print("\n2. 文件大小限制:")
    print("   - 一次性读取最大支持: " .. max_size .. " MB")
    print("   - 建议大文件使用按块读取方法")
    
    print("\n3. 内存使用建议:")
    print("   - 小文件 (< 10MB): 一次性读取")
    print("   - 中等文件 (10-100MB): 按块读取")
    print("   - 大文件 (> 100MB): 必须按块读取")
    
    print("\n测试完成！")
end

-- 如果直接运行此脚本，则执行主程序
if arg[0]:match("p73_advanced%.lua$") then
    main()
end 
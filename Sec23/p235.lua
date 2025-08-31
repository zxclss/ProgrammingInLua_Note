local function now()
    return os.clock()
end

local function bytes_in_use()
    return collectgarbage("count") * 1024
end

local function allocate_tables(num_tables, inner_empty)
    local a = {}
    for i = 1, num_tables do
        if inner_empty then
            a[i] = {}
        else
            a[i] = { i }
        end
    end
    return a
end

local function println(...)
    io.write(table.concat({ ... }, "\t"), "\n")
end

local function set_gc_tuning(pause, stepmul)
    if pause ~= nil then collectgarbage("setpause", pause) end
    if stepmul ~= nil then collectgarbage("setstepmul", stepmul) end
end

local function run_auto_mode(pause, stepmul, num_tables, inner_empty)
    set_gc_tuning(pause, stepmul)

    collectgarbage("collect")
    local mem_before = bytes_in_use()

    local t0 = now()
    local a = allocate_tables(num_tables, inner_empty)
    local t1 = now()
    local mem_after_alloc = bytes_in_use()

    -- Keep the allocation alive briefly, then release and collect
    a = nil
    local t2 = now()
    collectgarbage()
    local t3 = now()

    local mem_after_collect = bytes_in_use()

    println("mode=auto",
        "pause=" .. tostring(pause),
        "stepmul=" .. tostring(stepmul),
        "num=" .. tostring(num_tables),
        "alloc_s=" .. string.format("%.6f", t1 - t0),
        "gc_s=" .. string.format("%.6f", t3 - t2),
        "mem_before=" .. tostring(mem_before),
        "mem_after_alloc=" .. tostring(mem_after_alloc),
        "mem_after_collect=" .. tostring(mem_after_collect))
end

local function run_manual_mode(num_tables, batch_size, step_work, full_collect_every, inner_empty)
    -- Stop the automatic GC and drive it manually via steps and occasional full collect
    collectgarbage("stop")

    local total_alloc = 0
    local a = {}

    local t0 = now()
    while total_alloc < num_tables do
        local remaining = num_tables - total_alloc
        local this_batch = remaining < batch_size and remaining or batch_size

        -- allocate a batch
        for i = 1, this_batch do
            local idx = total_alloc + i
            if inner_empty then
                a[idx] = {}
            else
                a[idx] = { idx }
            end
        end
        total_alloc = total_alloc + this_batch

        -- drive GC a bit to amortize work
        if step_work > 0 then
            collectgarbage("step", step_work)
        end

        -- occasionally do a full collection (optional)
        if full_collect_every > 0 and (total_alloc % full_collect_every == 0) then
            collectgarbage("collect")
        end
    end
    local t1 = now()
    local mem_after_alloc = bytes_in_use()

    -- Release and finish up with final GC passes
    a = nil
    local t2 = now()
    if step_work > 0 then
        -- a few finishing steps to reclaim most garbage incrementally
        for _ = 1, 10 do
            collectgarbage("step", step_work)
        end
    end
    collectgarbage("collect")
    local t3 = now()

    local mem_after_collect = bytes_in_use()

    println("mode=manual",
        "num=" .. tostring(num_tables),
        "batch=" .. tostring(batch_size),
        "step_work=" .. tostring(step_work),
        "alloc_s=" .. string.format("%.6f", t1 - t0),
        "gc_s=" .. string.format("%.6f", t3 - t2),
        "mem_after_alloc=" .. tostring(mem_after_alloc),
        "mem_after_collect=" .. tostring(mem_after_collect))

    -- Restore default behavior for the rest of the process
    collectgarbage("restart")
end

local function print_usage()
    local prog = arg and arg[0] or "p235.lua"
    print("Usage:")
    print("  lua " .. prog .. " auto <pause> <stepmul> <num_tables> [inner_empty=1]")
    print("  lua " .. prog .. " manual <num_tables> <batch_size> <step_work> <full_collect_every> [inner_empty=1]")
    print("")
    print("Examples:")
    print("  lua " .. prog .. " auto 100 50 200000 1")
    print("  lua " .. prog .. " auto 0 200 200000 1     -- very eager restart (low pause)")
    print("  lua " .. prog .. " auto 1000 50 200000 1   -- high pause allows memory to grow")
    print("  lua " .. prog .. " auto 200 0 200000 1     -- stepmul=0 (collector makes no progress)")
    print("  lua " .. prog .. " auto 200 1000000 200000 1 -- extremely aggressive collector")
    print("  lua " .. prog .. " manual 200000 5000 400 0 1")
end

local function main()
    local mode = arg and arg[1] or nil
    if mode ~= "auto" and mode ~= "manual" then
        print_usage()
        return
    end

    if mode == "auto" then
        local pause = tonumber(arg[2]) or 100
        local stepmul = tonumber(arg[3]) or 50
        local num_tables = tonumber(arg[4]) or 10000
        local inner_empty = (tonumber(arg[5]) or 1) ~= 0
        run_auto_mode(pause, stepmul, num_tables, inner_empty)
    else
        local num_tables = tonumber(arg[2]) or 10000
        local batch_size = tonumber(arg[3]) or 5000
        local step_work = tonumber(arg[4]) or 400
        local full_collect_every = tonumber(arg[5]) or 0
        local inner_empty = (tonumber(arg[6]) or 1) ~= 0
        run_manual_mode(num_tables, batch_size, step_work, full_collect_every, inner_empty)
    end
end

main()
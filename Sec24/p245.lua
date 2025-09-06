local lib = require "async-lib"

local running_tasks = 0

local function on_task_finished()
    running_tasks = running_tasks - 1
    if running_tasks == 0 then
        lib.stop()
    end
end

function spawn (code)
    running_tasks = running_tasks + 1
    local co = coroutine.wrap(function()
        code()
        on_task_finished()
    end)
    co()
    return co
end

function run (code)
    running_tasks = 0
    spawn(code)
    lib.runloop()
end

function run_all (codes)
    running_tasks = 0
    for _, fn in ipairs(codes) do
        spawn(fn)
    end
    lib.runloop()
end

local putline_callbacks = setmetatable({}, { __mode = "k" })
local getline_callbacks = setmetatable({}, { __mode = "k" })

function putline (stream, line)
    local co = coroutine.running()
    local callback = putline_callbacks[co]
    if not callback then
        callback = function () coroutine.resume(co) end
        putline_callbacks[co] = callback
    end
    lib.writeline(stream, line, callback)
    coroutine.yield()
end

function getline (stream, line)
    local co = coroutine.running()
    local callback = getline_callbacks[co]
    if not callback then
        callback = function (l) coroutine.resume(co, l) end
        getline_callbacks[co] = callback
    end
    lib.readline(stream, callback)
    local line = coroutine.yield()
    return line
end

run(function ()
    local t = {}
    local inp = io.input()
    local out = io.output()

    while true do
        local line = getline(inp)
        if not line then break end
        t[#t + 1] = line
    end

    for i = #t, 1, -1 do
        putline(out, t[i] .. "\n")
    end    
end)
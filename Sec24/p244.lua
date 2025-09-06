local lib = require "async-lib"

function run (code)
    local co = coroutine.wrap(function()
        code()
        lib.stop()
    end)
    co()
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

-- Iterator that yields lines from a stream using getline
function lines (stream)
    return function ()
        return getline(stream)
    end
end

run(function ()
    local t = {}
    local inp = io.input()
    local out = io.output()

    for line in lines(inp) do
        t[#t + 1] = line
    end

    for i = #t, 1, -1 do
        putline(out, t[i] .. "\n")
    end    
end)
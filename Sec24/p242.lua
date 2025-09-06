local function printResult(t)
    for i = 1, #t do
        io.write(t[i], " ")
    end
    io.write("\n")
end

local function helper(arr, idx, res)
    if idx > #arr then
        coroutine.yield(res)
        return
    end
    helper(arr, idx + 1, res)
    table.insert(res, arr[idx])
    helper(arr, idx + 1, res)
    table.remove(res)
end
local function combinations(arr)
    local co = coroutine.create(
        function()
            helper(arr, 1, {})
        end
    )
    return function()
        local status, value = coroutine.resume(co)
        return status and value or nil
    end
end

for c in combinations({"a", "b", "c"}) do
    printResult(c)
end

local function iter_subset(arr, f)
    local function dfs(depth, res)
        if depth > #arr then
            f(res)
            return
        end
        dfs(depth + 1, res)
        res[#res + 1] = arr[depth]
        dfs(depth + 1, res)
        res[#res] = nil
    end
    dfs(1, {})
end

iter_subset({1, 2, 3}, function(subset)
    for i = 1, #subset do
        io.write(subset[i], " ")
    end
    io.write("\n")
end)
local row = {}
local col = {}
local diag = {}
local anti_diag = {}

local N = 8
local cnt = 0

local function dfs(u)
    cnt = cnt + 1
    if u == N then
        return true
    end
    for v = 0, N - 1 do
        if not col[v] and not diag[v - u + N] and not anti_diag[v + u] then
            row[u] = v
            col[v] = true
            diag[v - u + N] = true
            anti_diag[v + u] = true
            if dfs(u + 1) then
                return true
            end
            col[v] = false
            diag[v - u + N] = false
            anti_diag[v + u] = false
        end
    end
    return false
end

local function print_board()
    for i = 0, N - 1 do
        for j = 0, N - 1 do
            io.write(row[i] == j and "Q " or ". ")
        end
        io.write("\n")
    end
    io.write("\n")
end


dfs(0)
print_board()
print(cnt)
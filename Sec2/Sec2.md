## 2 小插曲：八皇后问题

### 笔记

常规的dfs，不做过多讲解。

### 练习

练习 2.1

```lua
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
```

练习2.2

```lua
local used = {}
local permlist = ""

local N = 8

local cnt = 0

local function isplaceok()
    local col = {}
    local diag = {}
    local anti_diag = {}
    for i = 0, N - 1 do
        local v = tonumber(permlist:sub(i + 1, i + 1))
        if not v or col[v] or diag[v - i + N] or anti_diag[v + i] then
            return false
        end
        col[v] = true
        diag[v - i + N] = true
        anti_diag[v + i] = true
    end
    return true
end

local function print_board()
    for i = 0, N - 1 do
        for j = 0, N - 1 do
            io.write((tonumber(permlist:sub(i + 1, i + 1)) == j) and "Q " or ". ")
        end
        io.write("\n")
    end
    io.write("\n")
end

local function perm(u)
    if u == N then
        cnt = cnt + 1
        if isplaceok() then
            print_board()
            print(cnt)
            os.exit(0)
        end
        return
    end
    for v = 0, N - 1 do
        if not used[v] then
            permlist = permlist .. tostring(v)
            used[v] = true
            if perm(u + 1) then
                return true
            end
            permlist = permlist:sub(1, -2)
            used[v] = false
        end
    end
    return false
end

perm(0)
```
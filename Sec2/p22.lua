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
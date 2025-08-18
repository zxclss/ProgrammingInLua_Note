## 14 数据结构

### 笔记

介绍了几个数据结构，都有老生常谈的，不做过多笔记，只记一些lua特殊的用法。

**稀疏矩阵乘法**

- 表示方式: 用行稀疏表示法，`A[i][j] = value` 表示第 `i` 行第 `j` 列的非零元素；缺省或 `nil` 视为 0。
- 计算思路: 只遍历非零项。对每个 `i` 行、其非零 `k` 列，若 `B[k]` 存在，则把 `A[i][k] * B[k][j]` 加到 `C[i][j]` 上。
- 复杂度: 大致为 `∑_k nnz(rowA_i) * nnz(rowB_k)`，通常远优于稠密乘法。

```lua
function MultiplySparseMatrix(A, B)
    local C = {}
    for i, rowA in pairs(A) do
        local resultline = {}
        for k, vA in pairs(rowA) do
            for j, vB in pairs(rowBk) do
                local sum = (rowC[j] or 0) + vA * vB
                resultline[j] = (sum ~= 0) and sum or nil
            end
        end
        C[i] = resultline
    end
    return C
end
```

**字符串缓冲区**

- 用于高效构建长字符串
- 避免频繁的字符串连接操作
- 可以使用表收集字符串片段，最后用`table.concat`连接

```lua
-- 字符串缓冲区实现
local StringBuffer = {}
StringBuffer.__index = StringBuffer

function StringBuffer:new()
    local obj = {parts = {}}
    setmetatable(obj, self)
    return obj
end

function StringBuffer:append(str)
    table.insert(self.parts, tostring(str))
end

function StringBuffer:appendLine(str)
    self:append(str)
    self:append("\n")
end

function StringBuffer:toString()
    return table.concat(self.parts)
end

function StringBuffer:clear()
    self.parts = {}
end

function StringBuffer:length()
    return #self.parts
end
```

### 练习

练习 14.1

```lua
function AddSparseMatrix(A, B)
    local C = {}

    for i, rowA in pairs(A or {}) do
        if rowA ~= nil then
            local rowC = {}
            for j, va in pairs(rowA) do
                if va ~= 0 then
                    rowC[j] = va
                end
            end
            if next(rowC) ~= nil then
                C[i] = rowC
            end
        end
    end

    for i, rowB in pairs(B or {}) do
        if rowB ~= nil then
            local rowC = C[i]
            if rowC == nil then
                rowC = {}
                C[i] = rowC
            end
            for j, vb in pairs(rowB) do
                local sum = (rowC[j] or 0) + vb
                if sum ~= 0 then
                    rowC[j] = sum
                else
                    rowC[j] = nil
                end
            end
            if next(rowC) == nil then
                C[i] = nil
            end
        end
    end

    return C
end
```

练习 14.2

```lua
Queue = {}
function Queue:listNew()
    self.first = 0
    self.last = 0
    self.list = {}
end
function Queue:pushFirst(value)
    if self.first == 0 and self.last == 0 then
        self.first = 1
        self.last = 1
        self.list[1] = value
    else
        local first = self.first - 1
        self.first = first
        self.list[first] = value
    end
end
function Queue:pushLast(value)
    if self.first == 0 and self.last == 0 then
        self.first = 1
        self.last = 1
        self.list[1] = value
    else
        local last = self.last + 1
        self.last = last
        self.list[last] = value
    end
end
function Queue:popFirst()
    if self.first == 0 and self.last == 0 then
        return nil
    end
    local first = self.first
    local value = self.list[first]
    self.list[first] = nil
    if first == self.last then
        self.first = 0
        self.last = 0
    else
        self.first = first + 1
    end
    return value
end
function Queue:popLast()
    if self.first == 0 and self.last == 0 then
        return nil
    end
    local last = self.last
    local value = self.list[last]
    self.list[last] = nil
    if last == self.first then
        self.first = 0
        self.last = 0
    else
        self.last = last - 1
    end
    return value
end
```

练习 14.3

```lua
local function name2node(graph, name)
    local node = graph[name]
    if not node then
        node = {name = name, adj = {}}
        graph[name] = node
    end
    return node
end

function readgraph()
    local graph = {}
    for line in io.lines() do
        local namefrom, nameto, tag = string.match(line, "(%S+)%s+(%S+)%s+(%d+)")
        local from = name2node(graph, namefrom)
        local to = name2node(graph, nameto)
        from.adj[to] = tag
    end
    return graph
end
```

练习 14.4

```lua
local function name2node(graph, name)
    local node = graph[name]
    if not node then
        node = {name = name, adj = {}}
        graph[name] = node
    end
    return node
end

function readgraph()
    local graph = {}
    for line in io.lines() do
        local namefrom, nameto, dist = string.match(line, "(%S+)%s+(%S+)%s+(%d+)")   -- a b 2
        dist = tonumber(dist)
        local from = name2node(graph, namefrom)
        local to = name2node(graph, nameto)
        from.adj[to] = dist
    end
    return graph
end

function Dijkstra(graph, start, target)
    local dist, st = {}, {}
    dist[start] = 0
    for i = 1, math.huge do
        local u = nil
        for _, node in pairs(graph) do
            if not st[node] and dist[node] ~= nil and (u == nil or dist[node] < dist[u]) then
                u = node
            end
        end
        if u == nil then
            break
        end
        if u == target then
            return dist[u]
        end
        st[u] = true
        for v, dist_uv in pairs(u.adj) do
            if dist[v] == nil or dist[v] > dist[u] + dist_uv then
                dist[v] = dist[u] + dist_uv
            end
        end
    end
    return nil
end
```
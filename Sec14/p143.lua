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
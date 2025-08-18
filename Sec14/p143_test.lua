local script_dir = debug.getinfo(1, "S").source:match("^@(.+[\\/])") or "./"

dofile(script_dir .. "p143.lua")

io.input(script_dir .. "graph.in")
local graph = readgraph()

local start = graph["a"]
local target = graph["e"]
local result = Dijkstra(graph, start, target)

print("distance a->e:", result)
assert(result == 20, "expected 20, got " .. tostring(result)) 
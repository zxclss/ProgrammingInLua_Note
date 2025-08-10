local function shuffleArray(arr)
    local shuffled = {}
    for i = 1, #arr do
        shuffled[i] = arr[i]
    end
    
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    
    return shuffled
end

local function testShuffle()
    math.randomseed(os.time())
    
    local original = {1, 2, 3, 4, 5}
    for i, v in ipairs(original) do
        io.write(v .. " ")
    end
    print()
    
    for i = 1, 5 do
        local shuffled = shuffleArray(original)
        io.write("Iteration[" .. i .. "]: ")
        for j, v in ipairs(shuffled) do
            io.write(v .. " ")
        end
        print()
    end
end

testShuffle()

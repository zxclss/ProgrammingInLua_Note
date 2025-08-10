local integral = function(f, a, b)
    local n = 1e6
    local w = (b - a) / n
    local sum = 0
    for i = 1, n do
        sum = sum + f(a + (i - 1) * w + w / 2) * w
    end
    return sum
end

print(integral(function(x) return x * x end, 0, 1))
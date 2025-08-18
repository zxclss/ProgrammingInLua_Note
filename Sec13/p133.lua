function IsPowerOfTwo(x)
    if x <= 0 then return false end
    return (x & (x - 1)) == 0
end
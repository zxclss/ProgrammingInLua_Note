function GetUnsignedModular(x, mod)
    local function ucmp(a, b)
        if a == b then return 0 end
        local aNeg = a < 0
        local bNeg = b < 0
        if aNeg ~= bNeg then
            return aNeg and 1 or -1
        end
        return a < b and -1 or 1
    end

    if mod == 0 then
        error("mod must be nonzero")
    end

    -- Fast path: if x < mod in unsigned sense
    if ucmp(x, mod) < 0 then
        return x
    end

    -- Find highest set bit of x (treat as 64-bit unsigned)
    local highest = -1
    for i = 63, 0, -1 do
        local mask = (1 << i)
        if (x & mask) ~= 0 then
            highest = i
            break
        end
    end

    if highest == -1 then
        return 0
    end

    -- Shift-subtract division to compute remainder
    local rem = 0
    for i = highest, 0, -1 do
        rem = (rem << 1)
        if (x & (1 << i)) ~= 0 then
            rem = rem | 1
        end
        if ucmp(rem, mod) >= 0 then
            rem = rem - mod
        end
    end

    return rem
end

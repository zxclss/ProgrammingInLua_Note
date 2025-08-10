local function calConVolume(h, theta)
    local r = math.tan(h)
    return math.pi * r * r * h / 3
end
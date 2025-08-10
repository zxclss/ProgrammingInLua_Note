local NormRandom = {
    mean = 0,
    stddev = 1,
}

function NormRandom:new(mean, stddev)
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.mean = mean or 0
    o.stddev = stddev or 1
    return o
end

function NormRandom:random()
    -- Box-Muller变换公式
    local u1, u2
    repeat
        u1, u2 = math.random(), math.random()
        if u1 == 0 and u2 ~= 0 then u1, u2 = u2, u1 end
    until u1 > 0
    local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return self.mean + self.stddev * z0
end

local norm = NormRandom:new(0, 1)
for i = 1, 10 do
    print(norm:random())
end
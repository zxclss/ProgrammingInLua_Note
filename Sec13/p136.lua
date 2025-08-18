local BitArray = {}

function BitArray:newBitArray(n)
    if n > 63 then
        return nil
    end
    local self = {}
    self.n = n
    self.data = 0
    return self
end

function BitArray:setBit(n, v)
    if n > self.n then
        error("n is out of range")
    end
    self.data = self.data | (1 << n)
end

function BitArray:testBit(n)
    if n > self.n then
        error("n is out of range")
    end
    return (self.data >> n) & 1
end



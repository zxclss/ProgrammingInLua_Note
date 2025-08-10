local newpoly = function(t)
    return function(x)
        local res = 0
        local P = 1
        for i = 1, #t do
            res = res + t[i] * P
            P = P * x
        end
        return res
    end
end

local f = newpoly({3, 0, 1})
print(f(0))
print(f(5))
print(f(10))
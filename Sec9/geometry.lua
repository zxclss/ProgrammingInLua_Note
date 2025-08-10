function Disk(cx, cy, r)
    return function(x, y)
        return (x - cx) ^ 2 + (y - cy) ^ 2 <= r ^ 2
    end
end

function Rect(left, right, top, bottom)
    return function(x, y)
        return x >= left and x <= right and y >= bottom and y <= top
    end
end

function Union(f1, f2)
    return function(x, y)
        return f1(x, y) or f2(x, y)
    end
end

function Intersection(f1, f2)
    return function(x, y)
        return f1(x, y) and f2(x, y)
    end
end

function Difference(f1, f2)
    return function(x, y)
        return f1(x, y) and not f2(x, y)
    end
end

function Translate(r, dx, dy)
    return function(x, y)
        return r(x - dx, y - dy)
    end
end

function Plot(r, M, N)
    io.write("P1\n", M, " ", N, "\n")
    for i = 1, N do
        local y = (N - i * 2) / N
        for j = 1, M do
            local x = (j * 2 - M) / M
            io.write(r(x, y) and "1 " or "0 ")
        end
        io.write("\n")
    end
end

if arg[0] == "geometry.lua" then
    local c1 = Disk(0, 0, 1)
    Plot(Difference(c1, Translate(c1, 0.3, 0)), 50, 50)
end
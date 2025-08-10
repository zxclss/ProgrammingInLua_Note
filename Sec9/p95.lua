dofile("geometry.lua")

function RotateArea(area, angle)
    -- x' = x*cos(angle) - y*sin(angle)
    -- y' = x*sin(angle) + y*cos(angle)
    return function(x, y)
        local cos_a = math.cos(angle)
        local sin_a = math.sin(angle)
        local x_rotated = x * cos_a + y * sin_a
        local y_rotated = -x * sin_a + y * cos_a
        return area(x_rotated, y_rotated)
    end
end

local rect = Rect(-0.5, 0.5, 0.5, -0.5)
local rotated_rect = RotateArea(rect, math.pi / 4)
print("origin:")
Plot(rect, 50, 50)
print("\nafter:")
Plot(rotated_rect, 50, 50)
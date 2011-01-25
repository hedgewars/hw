-- Library for miscellaneous utilitiy functions

-- Check if a gear is inside a box
function gearIsInBox(gear, x, y, w, h)
    gx, gy = GetGearPosition(gear)
    if gx >= x and gy >= y and gx <= x + w and gy <= y + h then
        return true
    end
    return false
end

-- Check if a gear is inside a circle
function gearIsInCircle(gear, x, y, r, useRadius)
    gx, gy = GetGearPosition(gear)
    if useRadius then
        r = r + GetGearRadius(gear)
    end
    if r ^ 2 >= (x - gx) ^ 2 + (y - gy) ^ 2 then
        return true
    end
    return false
end

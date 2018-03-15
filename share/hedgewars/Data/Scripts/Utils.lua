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

local function drawFullMap(erase, flush)
	for x = 200,4000,600 do
		for y = 100,2000,150 do
			AddPoint(x, y, 63, erase)
		end
	end
	if flush ~= false then
		FlushPoints()
	end
end

-- Completely fill the map with land. Requires MapGen=mgDrawn.
-- If flush is false, FlushPoints() is not called.
function fillMap(flush)
	drawFullMap(false, flush)
end

-- Completely erase all land from drawn maps. Requires MapGen=mgDrawn.
-- If flush is false, FlushPoints() is not called.
function eraseMap(flush)
	drawFullMap(true, flush)
end


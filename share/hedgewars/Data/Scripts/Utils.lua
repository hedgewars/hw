-- Library for miscellaneous utilitiy functions and global helper variables

HedgewarsScriptLoad("/Scripts/Locale.lua")

--[[ FUNCTIONS ]]
-- Check if a gear is inside a box
function gearIsInBox(gear, x, y, w, h)
    local gx, gy = GetGearPosition(gear)
    if gx >= x and gy >= y and gx <= x + w and gy <= y + h then
        return true
    end
    return false
end

-- Check if a gear is inside a circle
function gearIsInCircle(gear, x, y, r, useRadius)
    local gx, gy = GetGearPosition(gear)
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

local function challengeRecordToString(recordType, value)
	if recordType == "TimeRecord" then
		return string.format(loc("Team's best time: %.3fs"), value/1000)
	elseif recordType == "TimeRecordHigh" then
		return string.format(loc("Team's longest time: %.3fs"), value/1000)
	elseif recordType == "Highscore" then
		return string.format(loc("Team highscore: %d"), value)
	elseif recordType == "Lowscore" then
		return string.format(loc("Team lowscore: %d"), value)
	elseif recordType == "AccuracyRecord" then
		return string.format(loc("Team's top accuracy: %d%"), value)
	end
end

function getReadableChallengeRecord(recordType)
	local record = tonumber(GetMissionVar(recordType))
	if type(record) ~= "number" then
		return ""
	else
		return challengeRecordToString(recordType, record)
	end
end

function updateChallengeRecord(recordType, value, stat)
	local oldRecord = tonumber(GetMissionVar(recordType))
	local newRecord = false
	if stat == nil then
		stat = recordType ~= "AccuracyRecord"
	end
	if type(oldRecord) ~= "number" then
		newRecord = true
	else
		local recordBeaten = false
		if recordType == "Lowscore" or recordType == "TimeRecord" then
			if value < oldRecord then
				recordBeaten = true
				newRecord = true
			end
		else
			if value > oldRecord then
				recordBeaten = true
				newRecord = true
			end
		end
		if stat then
			if recordBeaten then
				SendStat(siCustomAchievement, loc("You have beaten the team record, congratulations!"))
			else
				SendStat(siCustomAchievement, challengeRecordToString(recordType, oldRecord))
			end
		end
	end
	if newRecord then
		SaveMissionVar(recordType, value)
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


--[[ GLOBAL VARIABLES ]]

-- Shared common land color values for land sprites.
-- These are useful if you want to make the land type visible.
-- To be used as tint argument of PlaceSprite.
U_LAND_TINT_NORMAL = 0xFFFFFFFF			-- tint for normal land
U_LAND_TINT_INDESTRUCTIBLE = 0x960000FF		-- tint for indestructible land
U_LAND_TINT_ICE = 0x00FAFAFA			-- tint for icy land
U_LAND_TINT_BOUNCY = 0x00FA00FF			-- tint for bouncy land

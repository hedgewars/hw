--[[ Static Mines Test

This test tests if mines are able to stand still on the ground for a very long time. 8 mines are spawned on a few girders.

The test passes if the mines don't move for a very long time.
The test failes if any mine moves even the tiniest bit or is destroyed.

This test case has been created as response to bug 96.
]]

-- Max. time to test
local TEST_TIME_LIMIT = 3600000 * 5 -- 5 hours

local hhs = {}

function onGameInit()

	ClearGameFlags()
	EnableGameFlags(gfDisableWind, gfOneClanMode)
	Map = ""
	Seed = 12
	Theme = "Desert"
	MapGen = mgDrawn
	TurnTime = -1
	Explosives = 0
	MinesNum = 0
	CaseFreq = 0
	Delay = 100
	WaterRise = 0
	HealthDecrease = 0
	AirMinesNum = 0


	AddTeam("Test Team", 0xFFFF00, "Statue", "Tank", "Default", "cm_test")
	hhs[1] = AddHog("Test Hog", 0, 100, "cm_test")
	SetGearPosition(hhs[1], 300, 1450)
end

local mines = {
	{ x = 231, y = 1708},
	{ x = 290, y = 1708},
	{ x = 342, y = 1708},
	{ x = 261, y = 1708},
	{ x = 319, y = 1708},
	{ x = 403, y = 1706},
	{ x = 428, y = 1706},
	{ x = 461, y = 1706},
	{ x = 498, y = 1706},
	{ x = 518, y = 1706},
}

function LoadGearData()
	------ GIRDER LIST ------
	PlaceGirder(290, 1718, 4)
	PlaceGirder(290, 1790, 4)
	PlaceGirder(452, 1716, 4)
	PlaceGirder(452, 1790, 4)
	
	PlaceGirder(300, 1500, 4)

	------ MINE LIST ------
	for m=1, #mines do
		mines[m].gear = AddGear(mines[m].x, mines[m].y, gtMine, 0, 0, 0, 0)
	end

end

function onGameStart()
	LoadGearData()
end

function onGearDelete(gear)
	for m=#mines, 1, -1 do
		if gear == mines[m] then
			WriteLnToConsole(string.format("Mine %d died!", m))
			table.remove(mines, m)
		end
	end
end

-- Give a short time for the mines to settle first.
local checkTimer = -5000
local initPosCheck = false
-- Count the total times the mines managed to stand still
local totalTime = 0
local fin = false
function onGameTick20()
	if fin then
		return
	end
	-- Infinite turn time
	if TurnTimeLeft < 6000 then
		TurnTimeLeft = -1
	end
	checkTimer = checkTimer + 20
	if initPosCheck then
		totalTime = totalTime + 20
	end
	if checkTimer >= 1000 then
		local failed = false
		for m=1, #mines do
			if not initPosCheck then
				-- Position initialization
				-- Save “real” x and y values after the mines have settled
				local x, y = GetGearPosition(mines[m].gear)
				mines[m].rx = x
				mines[m].ry = y
			else
				-- Position check
				local x, y = GetGearPosition(mines[m].gear)
				local rx, ry = mines[m].rx, mines[m].ry
				if not x or not y then
					WriteLnToConsole(string.format("Mine %d has died!", m))
					failed = true
				elseif x ~= rx or y ~= ry then
					WriteLnToConsole(string.format("Mine %d has moved! Expected: (%d, %d). Actual: (%d, %d)", m, rx, ry, x, y))
					failed = true
				end
			end
		end
		if not initPosCheck then
			initPosCheck = true
		end
		if failed then
			WriteLnToConsole(string.format("Test failed. The mines managed to stand still for %d ticks.", totalTime))
			EndLuaTest(TEST_FAILED)
			fin = true
			return
		end
	end
	if totalTime >= TEST_TIME_LIMIT then
		WriteLnToConsole(string.format("All mines have been static for over %d ticks! Success!", TEST_TIME_LIMIT))
		EndLuaTest(TEST_SUCCESSFUL)
		fin = true
		return
	end
end
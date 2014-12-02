
local ta_pointsize = 63
local ta_radius = (ta_pointsize * 10 + 6) / 2

local sqrttwo = math.sqrt(2)

-- creates round test area
function AddTestArea(testarea)
	step = 100
	xstep = step * testarea["xdir"]
	ystep = step * testarea["ydir"]
	x = testarea["x"]
	y = testarea["y"]
	if xstep * ystep ~= 0 then
		xstep = math.floor(xstep / sqrttwo)
		ystep = math.floor(ystep / sqrttwo)
	end
	AddPoint(x, y, ta_pointsize);
	AddPoint(x + xstep, y + ystep, ta_pointsize, true);
end

-- vertical test area
local taa_v2 = {x= 350, y=1500, xdir= 0, ydir=-1}

-- fail counter
local nfailed = 0
local nspawned = 0
local ndied = 0

function onGameInit()
	-- At first we have to overwrite/set some global variables
	-- that define the map, the game has to load, as well as
	-- other things such as the game rules to use, etc.
	-- Things we don't modify here will use their default values.

	-- The base number for the random number generator
	Seed = 1
	-- The map to be played
	MapGen = mgDrawn
	-- The theme to be used
	Theme = "Bamboo"
	-- Game settings and rules
	EnableGameFlags(gfOneClanMode, gfDisableWind, gfDisableLandObjects, gfDisableGirders)
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0

	-- No damage please
	DamagePercent = 1

	-- Draw Map
	AddPoint(10,30,0) -- hog spawn platform
	-- test areas
	AddTestArea(taa_v2)

	FlushPoints()

	-- Create the player team
	AddTeam("'Zooka Team", 14483456, "Simple", "Island", "Default")
	-- And add a hog to it
	player = AddHog("Hunter", 0, 1, "NoHat")
	-- place it on how spawn platform
	SetGearPosition(player, 10, 10)
end

function onNewTurn()
	if not TestRectForObstacle(300, 1500, 400, 1900, true) then
		WriteLnToConsole('HOLE DETECTED')
		EndLuaTest(TEST_SUCCESSFUL)
	else
		WriteLnToConsole('FIRE DID NOT BURN THROUGH!')
		EndLuaTest(TEST_FAILED)
	end
end


function onGameStart()
	AddGear(350, 1500, gtHellishBomb, 0, 0, 0, 0)
end



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

-- vertical test areas
local taa_v1 = {x= 350, y= 400, xdir= 0, ydir= 1}
local taa_v2 = {x= 350, y=1500, xdir= 0, ydir=-1}
-- horizontal test areas
local taa_h1 = {x=1150, y= 400, xdir= 1, ydir= 0}
local taa_h2 = {x=1200, y=1100, xdir=-1, ydir= 0}
-- diagonal test areas
local taa_d1 = {x=2200, y= 400, xdir= 1, ydir= 1}
local taa_d2 = {x=2000, y=1500, xdir= 1, ydir=-1}
local taa_d3 = {x=3300, y= 400, xdir=-1, ydir= 1}
local taa_d4 = {x=3300, y=1500, xdir=-1, ydir=-1}

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
	EnableGameFlags(gfOneClanMode, gfDisableWind, gfDisableLandObjects, gfDisableGirders, gfSolidLand)
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0

	-- No damage please
	DamagePercent = 1

	-- Draw Map
	-- AddPoint(10,30,0) -- hog spawn platform
	-- test areas
	AddTestArea(taa_v1)
	AddTestArea(taa_v2)
	AddTestArea(taa_h1)
	AddTestArea(taa_h2)
	AddTestArea(taa_d1)
	AddTestArea(taa_d2)
	AddTestArea(taa_d3)
	AddTestArea(taa_d4)

	FlushPoints()

	-- Create the player team
	AddTeam("'Zooka Team", 14483456, "Simple", "Island", "Default")
	-- And add a hog to it
	player = AddHog("Hunter", 0, 1, "NoHat")
	-- place it on how spawn platform
	SetGearPosition(player, 10, 10)
end

-- xdir/ydir is direction in which to fire the drills
function SpawnDrillRocketArray(testarea)
	xdir = testarea["xdir"]
	ydir = testarea["ydir"]
	centerx = testarea["x"]
	centery = testarea["y"]
	distance = 23
	d = distance
	radius = ta_radius
	speed = 900000;
	local xmin, xmax, ymin, ymax
	if (xdir ~= 0) and (ydir ~= 0) then
		d = d / sqrttwo
		radius = radius / sqrttwo
		speed = math.floor(speed / sqrttwo)
	end
	centerx = centerx - (xdir * (radius + 20))
	centery = centery - (ydir * (radius + 20))
	radius = radius - 6
	xn = ydir
	yn = -xdir
	startx = centerx - (radius * xn)
	starty = centery - (radius * yn)
	endx = centerx + (radius * xn)
	endy = centery + (radius * yn)

	-- spawn loop
	x = startx
	y = starty
	xd = d * xn
	yd = d * yn
	if (xd < 0) and (startx < endx) then x = endx end
	if (yd < 0) and (starty < endy) then y = endy end
	nsteps = math.floor(math.max(math.abs(startx - endx),math.abs(starty - endy)) / d)
	for i = 1, nsteps, 1 do
		AddGear(math.floor(x), math.floor(y), gtDrill, gsttmpFlag * (i % 2), speed * xdir, speed * ydir, 0)
		nspawned = nspawned + 1
		x = x + xd
		y = y + yd
	end
end

function onGearDelete(gear)
	if GetGearType(gear) == gtDrill then
		-- the way to check state will change in API at some point
		if band(GetState(gear), gsttmpFlag) == 0 then
			-- regular drill rocket
			if (GetTimer(gear) < 2000) or (GetTimer(gear) > 3000) then
				nfailed = nfailed + 1
			end
		else
			-- airstrike drill rocket
			if GetTimer(gear) > 0 then
				nfailed = nfailed + 1
			end
		end
		ndied = ndied + 1
		if ndied == nspawned then
			WriteLnToConsole('TESTRESULT: ' .. nfailed .. ' of ' .. nspawned .. ' drill rockets did not explode as expected')
			if (nfailed > 0) then
				EndLuaTest(TEST_FAILED)
			else
				EndLuaTest(TEST_SUCCESSFUL)
			end
		end
	end
end

function onGameStart()
	SetGravity(1)

	SpawnDrillRocketArray(taa_h1)
	SpawnDrillRocketArray(taa_h2)
	SpawnDrillRocketArray(taa_v1)
	SpawnDrillRocketArray(taa_v2)
	SpawnDrillRocketArray(taa_d1)
	SpawnDrillRocketArray(taa_d2)
	SpawnDrillRocketArray(taa_d3)
	SpawnDrillRocketArray(taa_d4)
end


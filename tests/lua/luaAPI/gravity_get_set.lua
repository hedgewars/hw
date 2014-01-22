

-- * let grenade fall
-- * after a second capture fall distance
-- * change gravity value every second and see if the fall distance in the
--   following second is about what we'd expect it to be

local spawnX = 10
local spawnY = -500

local defaultG = nil
local currentG = nil

local defaultDY = nil
local expectedY = nil

local testGs = nil

local nFails = 0

function onGameInit()


	-- The base number for the random number generator
	Seed = 1
	-- The map to be played
	Map = "Ruler"
	-- The theme to be used
	Theme = "Bamboo"
	-- Game settings and rules
	EnableGameFlags(gfOneClanMode, gfInvulnerable)
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0

	-- Create the player team
	AddTeam("O_o", 14483456, "Simple", "Island", "Default")
	-- And add a hog to it
	player = AddHog("o_O", 0, 1, "NoHat")
	SetGearPosition(player, 100, 100)
end

local tol = 0

function IsKindaSame(a, b)
	tol = 1 + math.max(1,math.abs(currentG) / 100)
	return (a >= b-tol) and (a <= b+tol)
end

function SpawnGrenade()
	AddGear(spawnX, spawnY, gtGrenade, 0, 0, 0, 1000)
end

local gIdx = 1

function onGearDelete(gear)
	if GetGearType(gear) ~= gtGrenade then
		return
	end

	-- catch initial measuring drop
	if defaultDY == nil then
		defaultDY = GetY(gear) - spawnY
	elseif not IsKindaSame(GetY(gear), expectedY) then
		nFails = nFails + 1
		WriteLnToConsole("FAIL: Unexpected Y position! " .. GetY(gear) .. " returned, expected " .. expectedY .. ' (max tolerated difference = ' .. tol .. ')')
	else
		WriteLnToConsole("Y position OK! " .. GetY(gear) .. " returned, expected " .. expectedY .. ' (max tolerated difference = ' .. tol .. ')')
	end

	returnedG = GetGravity()
	if (returnedG ~= currentG) then
		WriteLnToConsole("GetGravity did not return the value that we used with SetGravity! " .. returnedG .. " returned, expected " .. currentG)
		nFails = nFails + 1
	end

	currentG = testGs[gIdx]
	gIdx = gIdx + 1
	-- after last test
	if currentG == nil then
		if (nFails > 0) then
			EndLuaTest(TEST_FAILED)
		else
			EndLuaTest(TEST_SUCCESSFUL)
		end
	end

	WriteLnToConsole("SetGravity(" .. currentG .. ") ...")
	SetGravity(currentG)

	SpawnGrenade()
	expectedY = spawnY + math.floor(currentG * defaultDY / 100)
end

function onGameStart()
	currentG = 100
	defaultG = GetGravity()
	if (defaultG ~= 100) then
		WriteLnToConsole("GetGravity did not return 100 at game start")
		nFails = 1
	end

	SpawnGrenade()

	-- for current testing method don't use values over 400
	-- (values > 400 will cause speed cap in under 1 sec)
	testGs = {150, 200, 300, 10, 1, 13, 15, 0, 27, -350, -10, nil}
end



-- This function is called before the game loads its
-- resources.
-- It's one of the predefined function names that will
-- be called by the game. They give you entry points
-- where you're able to call your own code using either
-- provided instructions or custom functions.
function onGameInit()
	-- At first we have to overwrite/set some global variables
	-- that define the map, the game has to load, as well as
	-- other things such as the game rules to use, etc.
	-- Things we don't modify here will use their default values.

	-- The base number for the random number generator
	Seed = 1
	-- The map to be played
	Map = "Bamboo"
	-- The theme to be used
	Theme = "Bamboo"
	-- Game settings and rules
	EnableGameFlags(gfOneClanMode)

	-- Create the player team
	AddTeam("'Zooka Team", 14483456, "Simple", "Island", "Default")
	-- And add a hog to it
	player = AddHog("Hunter", 0, 1, "NoHat")
	SetGearPosition(player, 936, 136)
end

-- from lua API wiki:
local minZoom = 1.0;
local maxZoom = 3.0;
local defaultZoom = 2.0;

local nFails = 0;

function TestZoom(value)
	exp = math.max(minZoom, math.min(maxZoom, value))
	SetZoom(value)
	z = GetZoom()
	-- compare with some tolerance - because of float inprecision
	if (z > exp + 0.01) or (z < exp - 0.01) then
		WriteLnToConsole("Expected zoom value " .. exp .. " (after setting go zoom to " .. value .. "), but got: " .. z )
		nFails = nFails + 1
	end
end

function onGameStart()
	if (GetZoom() ~= defaultZoom) then
		WriteLnToConsole("Game did not start with zoom level of " .. defaultZoom)
		nFails = 1
	end

	TestZoom(0)
	TestZoom(1)
	TestZoom(0.5)
	TestZoom(3.5)
	TestZoom(7)
	TestZoom(2.0)
	TestZoom(2.2)

	if (nFails > 0) then
		EndLuaTest(TEST_FAILED)
	else
		EndLuaTest(TEST_SUCCESSFUL)
	end
end


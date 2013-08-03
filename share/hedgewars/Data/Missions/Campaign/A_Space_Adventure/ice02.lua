------------------- ABOUT ----------------------
--
-- Hero has to pass as fast as possible inside the
-- rings as in the racer mode

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Ice planet, a frozen adventure!")
local currentWaypoint = 1
local radius = 75
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("Collect the icegun and get the device part from Thanta"), 1, 4500},
}
-- hogs
local hero = {}
local ally = {}
-- teams
local teamA = {}
local teamB = {}
-- hedgehogs values
hero.name = "Hog Solo"
hero.x = 750
hero.y = 130
hero.dead = false
ally.name = "Paul McHoggy"
ally.x = 860
ally.y = 130
teamA.name = loc("Hog Solo")
teamA.color = tonumber("38D61C",16) -- green
teamB.name = loc("Allies")
teamB.color = tonumber("FF0000",16) -- red
-- way points
local current waypoint = 1
local waypoints = { 
	[1] = {x=1450, y=140},
	[2] = {x=990, y=580},
	[3] = {x=1650, y=950},
	[4] = {x=620, y=630},
	[5] = {x=1470, y=540},
	[6] = {x=1960, y=60},
	[7] = {x=1600, y=400},
	[8] = {x=240, y=940},
	[9] = {x=200, y=530},
	[10] = {x=1180, y=120},
	[11] = {x=1950, y=660},
	[12] = {x=1280, y=980},
	[13] = {x=590, y=1100},
	[14] = {x=20, y=620},
	[15] = {x=hero.x, y=hero.y}
}

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	TurnTime = 15000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Map = "ice02_map"
	Theme = "Snow"
	
	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	-- Ally
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	ally.gear = AddHog(ally.name, 0, 100, "tophats")
	AnimSetGearPosition(ally.gear, ally.x, ally.y)
	HogTurnLeft(ally.gear, true)
	
	AnimInit()
	--AnimationSetup()	
end
local wp = 0
function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddAmmo(hero.gear, amJetpack, 2)
	
	-- place a waypoint
	placeNextWaypoint()
	
	SendHealthStatsOff()
end

function onGameTick20()
	if checkIfHeroInWaypoint() then
		if not placeNextWaypoint() then
			-- GAME OVER, WIN!
			EndGame()
		end
	end
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	end
end

------------------ Other Functions -------------------

function placeNextWaypoint()
	WriteLnToConsole("IN PLACE NEXT POINT")
	if currentWaypoint > 1 then
		local wp = waypoints[currentWaypoint-1]
		DeleteVisualGear(wp.gear)
	end
	if currentWaypoint < 16 then
		local wp = waypoints[currentWaypoint]
		wp.gear = AddVisualGear(1,1,vgtCircle,1,true)
		SetVisualGearValues(wp.gear, wp.x,wp.y, 20, 200, 0, 0, 100, radius, 3, 0xff0000ff)
		-- add bonus time and "fuel"		
		WriteLnToConsole("Before "..TurnTimeLeft)
		if currentWaypoint % 2 == 0 then
			AddAmmo(hero.gear, amJetpack, GetAmmoCount(hero.gear, amJetpack)+1)
			if TurnTimeLeft <= 10000 then
				TurnTimeLeft = TurnTimeLeft + 8000
			end		
		else
			if TurnTimeLeft <= 7000 then
				TurnTimeLeft = TurnTimeLeft + 6000
			end
		end		
		WriteLnToConsole("After "..TurnTimeLeft)
		radius = radius - 4
		currentWaypoint = currentWaypoint + 1
		return true
	end
	return false
end

function checkIfHeroInWaypoint()
	if not hero.dead then
		local wp = waypoints[currentWaypoint-1]
		local distance = math.sqrt((GetX(hero.gear)-wp.x)^2 + (GetY(hero.gear)-wp.y)^2)
		if distance <= radius+4 then
			SetWind(math.random(-100,100))
			return true
		end
	end
	return false
end

------------------- ABOUT ----------------------
--
-- Hero has to pass as fast as possible inside the
-- rings as in the racer mode

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Desert planet, Journey down below!")
local challengeStarted = false
local currentWaypoint = 1
local radius = 75
local totalTime = 15000
local totalSaucers = 3
local gameEnded = false
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("Use your saucer and pass from the rings!"), 1, 4500},
}
-- hogs
local hero = {}
local ally = {}
-- teams
local teamA = {}
-- hedgehogs values
hero.name = "Hog Solo"
hero.x = 1600
hero.y = 1950
hero.dead = false
teamA.name = loc("Hog Solo")
teamA.color = tonumber("38D61C",16) -- green
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
	GameFlags = gfOneClanMode
	Seed = 1
	TurnTime = 6000
	Delay = 2
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	SuddenDeathTurns = 1
	WaterRise = 150
	Map = "desert02_map"
	Theme = "Desert"
	
	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	
	AnimInit()
	AnimationSetup()	
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	
	AddAmmo(hero.gear, amRope, 99)
	
	SendHealthStatsOff()
	AddAnim(dialog01)
end

function onNewTurn()
	if not hero.dead and CurrentHedgehog == ally.gear and challengeStarted then
		heroLost()
	end
end

function onGameTick()
	AnimUnWait()
	if ShowAnimation() == false then
		return
	end
	ExecuteAfterAnimations()
	CheckEvents()
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	end
end

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)   
	end
end

-------------- EVENTS ------------------

function onHeroDeath(gear)
	if hero.dead then
		return true
	end
	return false
end

function onHeroSafe(gear)
	if not hero.dead and GetY(hero.gear) < 200 and StoppedGear(hero.gear) then
		return true
	end
	return false
end

-------------- OUTCOMES ------------------

function heroDeath(gear)
	heroLost()
end

function heroSafe(gear)
	-- hero win stuff
	EndGame()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
end

function AnimationSetup()
	-- DIALOG 01 - Start
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Many meters below the surface..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("The tunnel is about to get flooded..."), SAY_THINK, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("I have to reach the surface asap..."), SAY_THINK, 4000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = challengeStart, args = {hero.gear}})
end

------------------ Other Functions -------------------

function challengeStart()
	TurnTimeLeft = 0
end

------------------- ABOUT ----------------------
--
-- Hero has to get to the surface as soon as possible.
-- Tunnel is about to get flooded.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("Running for survival")
local startChallenge = false
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("Use the rope to quickly get to the surface!"), 1, 4500},
}
-- health crates
healthX = 565
health1Y = 1400
health2Y = 850
-- hogs
local hero = {}
-- teams
local teamA = {}
-- hedgehogs values
hero.name = loc("Hog Solo")
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
	TurnTime = 8000
	Delay = 2
	CaseFreq = 0
	HealthCaseAmount = 50
	MinesNum = 500
	MinesTime = 1000
	MineDudPercent = 75
	Explosives = 0
	SuddenDeathTurns = 1
	WaterRise = 150
	HealthDecrease = 0
	Map = "desert02_map"
	Theme = "Desert"

	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "hedgewars")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)

	initCheckpoint("desert02")

	AnimInit()
	AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onHeroSafe, {hero.gear}, heroSafe, {hero.gear}, 0)

	SpawnHealthCrate(healthX, health1Y)
	SpawnHealthCrate(healthX, health2Y)

	AddAmmo(hero.gear, amRope, 100)

	SendHealthStatsOff()
	AddAnim(dialog01)
end

function onNewTurn()
	SetWeapon(amRope)
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
	if not hero.dead and GetY(hero.gear) < 170 and StoppedGear(hero.gear) then
		return true
	end
	return false
end

-------------- ACTIONS ------------------

function heroDeath(gear)
	SendStat(siGameResult, loc("Hog Solo lost, try again!"))
	SendStat(siCustomAchievement, loc("To win the game you have to go to the surface."))
	SendStat(siCustomAchievement, loc("Most mines are not active."))
	SendStat(siCustomAchievement, loc("From the second turn and beyond the water rises."))
	SendStat(siPlayerKills,'0',teamA.name)
	EndGame()
end

function heroSafe(gear)
	SendStat(siGameResult, loc("Congratulations, you won!"))
	SendStat(siCustomAchievement, loc("You have escaped successfully."))
	SendStat(siCustomAchievement, string.format(loc("Your escape took you %d turns."), TotalRounds))
	local record = tonumber(GetCampaignVar("FastestMineEscape"))
	if record ~= nil and TotalRounds >= record then
		SendStat(siCustomAchievement, string.format(loc("Your fastest escape so far: %d turns"), record))
	end
	if record == nil or TotalRounds < record then
		SaveCampaignVar("FastestMineEscape", tostring(TotalRounds))
		if record ~= nil then
			SendStat(siCustomAchievement, loc("This is a new personal best, congratulations!"))
		end
	end
	SendStat(siPlayerKills,'0',teamA.name)
	SaveCampaignVar("Mission7Won", "true")
	checkAllMissionsCompleted()
	EndGame()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
	challengeStart()
end

function AnimationSetup()
	-- DIALOG 01 - Start
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Many meters below the surface ..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("The tunnel is about to get flooded!"), SAY_THINK, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("I have to reach the surface as quickly as I can."), SAY_THINK, 4000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = challengeStart, args = {hero.gear}})
end

------------------ Other Functions -------------------

function challengeStart()
	startChallenge = true
	TurnTimeLeft = 0
end

------------------- ABOUT ----------------------
--
-- In this adventure hero visits the fruit planet
-- to search for the missing part. However, a war
-- has broke out and hero has to take part or leave.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Fruit planet, The War!")
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("Use the rope and get asap to the surface!"), 1, 4500},
}
-- hogs
local hero = {}
local yellow1 = {}
local yellow2 = {}
local yellow3 = {}
local green1 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
-- hedgehogs values
hero.name = "Hog Solo"
hero.x = 3650
hero.y = 95
hero.dead = false
green1.name = "Captain Limes"
green1.x = 3600
green1.y = 95
yellow1.name = "General Lemon"
yellow1.x = 1300
yellow1.y = 1500
teamA.name = loc("Hog Solo")
teamA.color = tonumber("38D61C",16) -- green  
teamB.name = loc("Green Bananas")
teamB.color = tonumber("38D61C",16) -- green
teamC.name = loc("Yellow Watermellons")
teamC.color = tonumber("DDFF00",16) -- yellow

function onGameInit()
	Seed = 1
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Delay = 3
	HealthCaseAmount = 30
	Map = "fruit01_map"
	Theme = "Fruit"
	
	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	-- Green Bananas
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	green1.gear = AddHog(green1.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(green1.gear, green1.x, green1.y)
	-- Yellow Watermellons
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(yellow1.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(yellow1.gear, yellow1.x, yellow1.y)
	
	AnimInit()
	--AnimationSetup()	
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	SendHealthStatsOff()
end

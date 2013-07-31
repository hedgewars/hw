------------------- ABOUT ----------------------
--
-- In the desert planet Hero will have to explore
-- the dunes below the surface and find the hidden
-- crates. It is told that one crate contains the
-- lost part.


HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- hogs
local hero = {}
local bandit1 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
local teamD = {}
-- hedgehogs values
hero.name = "Hog Solo"
hero.x = 340
hero.y = 200
bandit1.name = "Thanta"
bandit1.x = 500
bandit1.y = 1280
teamB.name = loc("Frozen Bandits")
teamB.color = tonumber("0033FF",16) -- blues
teamC.name = loc("Hog Solo")
teamC.color = tonumber("38D61C",16) -- green

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	--GameFlags = gfDisableWind
	TurnTime = 25000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Delay = 3
	Map = "desert01_map"
	Theme = "Desert"
	
	-- Hog Solo
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	-- Frozen Bandits
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	bandit1.gear = AddHog(bandit1.name, 1, 120, "tophats")
	AnimSetGearPosition(bandit1.gear, bandit1.x, bandit1.y)	
	HogTurnLeft(bandit1.gear, true)
	
	
	--AnimInit()
	--AnimationSetup()	
end

function onGameStart()
	--AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddAmmo(hero.gear, amRope, 10)
end


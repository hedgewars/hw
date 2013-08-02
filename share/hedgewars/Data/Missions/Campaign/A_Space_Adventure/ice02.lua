------------------- ABOUT ----------------------
--
-- Hero has to pass as fast as possible inside the
-- rings as in the runner mode

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Ice planet, a frozen adventure!")
local heroAtAntiFlyArea = false
local heroVisitedAntiFlyArea = false
local heroAtFinalStep = false
local iceGunTaken = false
local checkPointReached = 1 -- 1 is normal spawn
-- dialogs
local dialog01 = {}
local dialog02 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("Collect the icegun and get the device part from Thanta"), 1, 4500},
}
-- crates
local icegunY = 1950
local icegunX = 260
-- hogs
local hero = {}
local ally = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
-- hedgehogs values
hero.name = "Hog Solo"
hero.x = 450
hero.y = 200
hero.dead = false
ally.name = "Paul McHoggy"
ally.x = 512
ally.y = 200
teamA.name = loc("Hog Solo")
teamA.color = tonumber("38D61C",16) -- green
teamB.name = loc("Allies")
teamB.color = tonumber("FF0000",16) -- red

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	TurnTime = 25000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Delay = 3
	Map = "ice02_map"
	Theme = "Snow"
	
	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	-- Ally
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	ally.gear = AddHog(ally.name, 0, 100, "tophats")
	AnimSetGearPosition(ally.gear, ally.x, ally.y)
	
	AnimInit()
	--AnimationSetup()	
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddAmmo(hero.gear, amJetpack, 99)
	
	SendHealthStatsOff()
end

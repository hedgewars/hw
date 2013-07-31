------------------- ABOUT ----------------------
--
-- In the desert planet Hero will have to explore
-- the dunes below the surface and find the hidden
-- crates. It is told that one crate contains the
-- lost part.

-- TODO
-- maybe use same name in missionName and frontend mission name..

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Desert planet, lost in sand!")
local checkPointReached = 1 -- 1 is normal spawn
-- hogs
local hero = {}
local ally = {}
local smuggler1 = {}
local smuggler2 = {}
local smuggler3 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
-- hedgehogs values
hero.name = "Hog Solo"
hero.x = 1740
hero.y = 40
hero.dead = false
ally.name = "Chief Sandologist"
ally.x = 1660
ally.y = 40
smuggler1.name = "Sanndy"
smuggler1.x = 320
smuggler1.y = 235
smuggler2.name = "Spike"
smuggler2.x = 736
smuggler2.y = 860
smuggler3.name = "Sandstorm"
smuggler3.x = 1940
smuggler3.y = 1625
teamA.name = loc("PAotH")
teamA.color = tonumber("FF0000",16) -- red
teamB.name = loc("Smugglers")
teamB.color = tonumber("0033FF",16) -- blues
teamC.name = loc("Hog Solo")
teamC.color = tonumber("38D61C",16) -- green

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
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
	-- PAotH undercover scientist and chief Sandologist
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	ally.gear = AddHog(ally.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(ally.gear, ally.x, ally.y)
	-- Smugglers
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	smuggler1.gear = AddHog(smuggler1.name, 1, 120, "tophats")
	AnimSetGearPosition(smuggler1.gear, smuggler1.x, smuggler1.y)
	smuggler2.gear = AddHog(smuggler2.name, 1, 120, "tophats")
	AnimSetGearPosition(smuggler2.gear, smuggler2.x, smuggler2.y)	
	smuggler3.gear = AddHog(smuggler3.name, 1, 120, "tophats")
	AnimSetGearPosition(smuggler3.gear, smuggler3.x, smuggler3.y)	
	
	--AnimInit()
	--AnimationSetup()	
end

function onGameStart()
	--AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddAmmo(hero.gear, amRope, 10)
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	end
end


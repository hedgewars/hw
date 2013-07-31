------------------- ABOUT ----------------------
--
-- In the desert planet Hero will have to explore
-- the dunes below the surface and find the hidden
-- crates. It is told that one crate contains the
-- lost part.

-- TODO
-- maybe use same name in missionName and frontend mission name..
-- in this map I have to track the weapons the player has in checkpoints

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Desert planet, lost in sand!")
local checkPointReached = 1 -- 1 is normal spawn
-- crates
local btorch1Y = 60
local btorch1X = 2700
local btorch2Y = 1800
local btorch2X = 1010
local rope1Y = 970
local rope1X = 3200
local rope2Y = 1900
local rope2X = 680
local rope3Y = 1850
local rope3X = 2460
local portalY = 480
local portalX = 1465
local constructY = 1630
local constructX = 3350
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
	HealthCaseAmount = 30
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
	
	-- spawn crates	
	SpawnAmmoCrate(btorch1X, btorch1Y, amBlowTorch)
	SpawnAmmoCrate(btorch2X, btorch2Y, amBlowTorch)
	SpawnAmmoCrate(rope1X, rope1Y, amRope)
	SpawnAmmoCrate(rope2X, rope2Y, amRope)
	SpawnAmmoCrate(rope3X, rope3Y, amRope)
	SpawnAmmoCrate(portalX, portalY, amPortalGun)
	SpawnAmmoCrate(constructX, constructY, amConstruction)
	
	SpawnHealthCrate(3300, 970)
end

function onAmmoStoreInit()
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amRope, 0, 0, 0, 1)
	SetAmmo(amPortalGun, 0, 0, 0, 1)	
	SetAmmo(amConstruction, 0, 0, 0, 1)
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	end
end


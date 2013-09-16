------------------- ABOUT ----------------------
--
-- Hero has collected all the anti-gravity device
-- parts but because of the size of the meteorite
-- he needs to detonate some faulty explosives that
-- PAotH have previously placed on it.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("The big bang")
local challengeObjectives = loc("Find a way to detonate all the explosives and stay alive!")

-- hogs
local hero = {
	name = loc("Hog Solo"),
	x = 790,
	y = 70
}
-- teams
local teamA = {
	name = loc("Hog Solo"),
	color = tonumber("38D61C",16) -- green
}

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	GameFlags = gfDisableWind + gfOneClanMode
	Seed = 1
	TurnTime = -1
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	HealthCaseAmount = 50
	Map = "final_map"
	Theme = "EarthRise"
	
	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 1, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	
	initCheckpoint("final")
	
	AnimInit()
	--AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	ShowMission(missionName, loc("Challenge Objectives"), challengeObjectives, -amSkip, 0)
	
	-- explosives
	x = 400
	while x < 815 do
		AddGear(x, 500, gtExplosives, 0, 0, 0, 0)
		x = x + math.random(15,40)
	end
	-- mines
	local x = 360
	while x < 815 do
		AddGear(x, 480, gtMine, 0, 0, 0, 0)
		x = x + math.random(5,20)
	end
	-- health crate	
	SpawnHealthCrate(900, 5)
	-- ammo crates
	SpawnAmmoCrate(930, 1000,amRCPlane)
	SpawnAmmoCrate(1220, 672,amPickHammer)
	SpawnAmmoCrate(1220, 672,amGirder)
	
	-- ammo
	AddAmmo(hero.gear, amPortalGun, 1)	
	AddAmmo(hero.gear, amFirePunch, 1)	
	
	SendHealthStatsOff()
end

function onAmmoStoreInit()
	SetAmmo(amRCPlane, 0, 0, 0, 1)
	SetAmmo(amPickHammer, 0, 0, 0, 2)
	SetAmmo(amGirder, 0, 0, 0, 1)
end

------------------- ABOUT ----------------------
--
-- In this cold planet hero seeks for a part of the
-- antigravity device. He has to capture Icy Pit who
-- knows where the device is hidden. Hero will be
-- able to use only the ice gun for this mission.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local heroAtAntiFlyArea = false
-- crates
local icegunY = 1950
local icegunX = 260
-- hogs
local hero = {}
local ally = {}
local bandit1 = {}
local bandit2 = {}
local bandit3 = {}
local bandit4 = {}
local bandit5 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
local teamD = {}
-- hedgehogs values
hero.name = "Hog Solo"
hero.x = 340
hero.y = 1840
hero.dead = false
ally.name = "Paul McHoggy"
ally.x = 300
ally.y = 1840
bandit1.name = "Thanta"
bandit1.x = 3240
bandit1.y = 1280
bandit2.name = "Billy Frost"
bandit2.x = 1480
bandit2.y = 1990
bandit3.name = "Ice Jake"
bandit3.x = 1860
bandit3.y = 1150
bandit4.name = "John Snow"
bandit4.x = 3250
bandit4.y = 970
bandit5.name = "White Tee"
bandit5.x = 3300
bandit5.y = 600
teamA.name = loc("Allies")
teamA.color = tonumber("FF0000",16) -- red
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
	MinesTime = 3000
	Explosives = 0
	Delay = 5 
	Map = "ice01_map"
	Theme = "Snow"
	
	-- Hog Solo
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	-- Ally
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	ally.gear = AddHog(ally.name, 0, 100, "tophats")
	AnimSetGearPosition(ally.gear, ally.x, ally.y)
	-- Frozen Bandits
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	bandit1.gear = AddHog(bandit1.name, 0, 100, "tophats")
	AnimSetGearPosition(bandit1.gear, bandit1.x, bandit1.y)	
	HogTurnLeft(bandit1.gear, true)
	bandit2.gear = AddHog(bandit2.name, 0, 100, "tophats")
	AnimSetGearPosition(bandit2.gear, bandit2.x, bandit2.y)
	bandit3.gear = AddHog(bandit3.name, 0, 100, "tophats")
	AnimSetGearPosition(bandit3.gear, bandit3.x, bandit3.y)
	bandit4.gear = AddHog(bandit4.name, 0, 100, "tophats")
	AnimSetGearPosition(bandit4.gear, bandit4.x, bandit4.y)
	HogTurnLeft(bandit4.gear, true)
	bandit5.gear = AddHog(bandit5.name, 0, 100, "tophats")
	AnimSetGearPosition(bandit5.gear, bandit5.x, bandit5.y)
	HogTurnLeft(bandit5.gear, true)
	
	AnimInit()
	AnimationSetup()	
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 1)
	AddEvent(onAntiFlyArea, {hero.gear}, antiFlyArea, {hero.gear}, 1)
	AddEvent(onNonAntiFlyArea, {hero.gear}, nonAntiFlyArea, {hero.gear}, 1)
	
	AddAmmo(hero.gear, amJetpack, 99)
	AddAmmo(hero.gear, amBazooka, 1)
	SpawnAmmoCrate(icegunX, icegunY, amIceGun)
	
end

function onNewTurn()		
	-- rounds start if hero got his weapons or got near the enemies
	if not heroAtAntiFlyArea and CurrentHedgehog ~= hero.gear then
	WriteLnToConsole(" IF 1")
		TurnTimeLeft = 0
	elseif not heroAtAntiFlyArea and CurrentHedgehog == hero.gear then
	WriteLnToConsole(" IF 2")
		TurnTimeLeft = -1
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

function onAmmoStoreInit()
	SetAmmo(amIceGun, 0, 0, 0, 1)
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	end
end

-------------- EVENTS ------------------

function onAntiFlyArea(gear)
	if not hero.dead and (GetX(gear) > 860 or GetY(gear) < 1400) and not heroAtAntiFlyArea then
		return true
	end
	return false
end

function onNonAntiFlyArea(gear)
	if not hero.dead and (GetX(gear) < 860 and GetY(gear) > 1400) and heroAtAntiFlyArea then
		return true
	end
	return false
end

function onHeroDeath(gear)
	if hero.dead then
		return true
	end
	return false
end

-------------- OUTCOMES ------------------

function antiFlyArea(gear)
	heroAtAntiFlyArea = true
	TurnTimeLeft = 0	
	FollowGear(hero.gear)
	AddAmmo(hero.gear, amJetpack, 0)
	AnimSwitchHog(bandit1.gear)	
	FollowGear(hero.gear)
	TurnTimeLeft = 0
end

function nonAntiFlyArea(gear)
	heroAtAntiFlyArea = false
	TurnTimeLeft = 0	
	FollowGear(hero.gear)
	AddAmmo(hero.gear, amJetpack, 99)
	AnimSwitchHog(bandit1.gear)	
	FollowGear(hero.gear)
	TurnTimeLeft = 0	
end

function heroDeath(gear)
	SendStat('siGameResult', loc("Hog Solo lost, try again!")) --1
	-- more custom stats
	EndGame()
end

-------------- ANIMATIONS ------------------

function AnimationSetup()

end

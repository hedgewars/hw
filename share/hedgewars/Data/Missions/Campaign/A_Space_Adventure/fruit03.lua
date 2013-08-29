------------------- ABOUT ----------------------
--
-- Hero has get into an Red Strawberies ambush
-- He has to eliminate the enemies by using limited
-- ammo of sniper rifle and watermelon

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("Precise shooting")
-- hogs
local hero = {
	name = loc("Hog Solo"),
	x = 1830,
	y = 560,
	dead = false
}
local enemiesOdd = {
	{name = "Hog 1", x = 3670 , y = 175},
	{name = "Hog 3", x = 3795 , y = 1110},
	{name = "Hog 5", x = 1950 , y = 1480},
	{name = "Hog 7", x = 400 , y = 920},
	{name = "Hog 9", x = 1100 , y = 1950},
	{name = "Hog 11", x = 1200 , y = 1950},
	{name = "Hog 13", x = 2300 , y = 1950},
	{name = "Hog 15", x = 2400 , y = 1950},
}
local enemiesEven = {
	{name = "Hog 2", x = 660, y = 170},
	{name = "Hog 4", x = 1900, y = 1320},
	{name = "Hog 6", x = 2030, y = 1335},
	{name = "Hog 8", x = 1300, y = 1950},
	{name = "Hog 10", x = 1400, y = 1950},
	{name = "Hog 12", x = 2500, y = 1950},
	{name = "Hog 14", x = 2600, y = 1950},
	{name = "Hog 16", x = 1850, y = 560},
}
-- teams
local teamA = {
	name = loc("Hog Solo"),
	color = tonumber("38D61C",16) -- green
}
local teamB = {
	name = loc("RS1"),
	color = tonumber("FF0000",16) -- red
}
local teamC = {
	name = loc("RS2"),
	color = tonumber("FF0000",16) -- red
}

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	GameFlags = gfDisableWind + gfInfAttack
	Seed = 1
	TurnTime = 25000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Map = "fruit03_map"
	Theme = "Fruit"
	
	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	-- enemies
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	for i=1,table.getn(enemiesEven) do
		enemiesEven[i].gear = AddHog(enemiesEven[i].name, 1, 100, "war_desertgrenadier1")
		AnimSetGearPosition(enemiesEven[i].gear, enemiesEven[i].x, enemiesEven[i].y)
		enemiesEven[i].turnLeft = false
	end	
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	for i=1,table.getn(enemiesOdd) do
		enemiesOdd[i].gear = AddHog(enemiesOdd[i].name, 1, 100, "war_desertgrenadier1")
		AnimSetGearPosition(enemiesOdd[i].gear, enemiesOdd[i].x, enemiesOdd[i].y)
		enemiesOdd[i].turnLeft = false
	end
	
	initCheckpoint("fruit03")
	
	AnimInit()
	--AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	
	--hero ammo
	AddAmmo(hero.gear, amTeleport, 2)
	AddAmmo(hero.gear, amSniperRifle, 2)
	AddAmmo(hero.gear, amWatermelon, 2)
	--enemies ammo
	AddAmmo(enemiesOdd[1].gear, amSniperRifle, 100)
	AddAmmo(enemiesOdd[1].gear, amWatermelon, 1)
	AddAmmo(enemiesEven[1].gear, amSniperRifle, 100)
	AddAmmo(enemiesEven[1].gear, amWatermelon, 1)
	
	SendHealthStatsOff()
end

function onGameTick20()
	turnHogs()
end

function onGearDamage(gear, damage)
	FollowGear(gear)
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	end
end

-------------- EVENTS ------------------

function onHeroDeath(gear)
	if hero.dead then
		return true
	end
	return false
end

-------------- ACTIONS ------------------

-- game ends anyway but I want to sent custom stats probably...
function heroDeath(gear)
	heroLost()
end

------------------ Other Functions -------------------

function turnHogs()
	for i=1,table.getn(enemiesEven) do
		if GetHealth(enemiesEven[i].gear) then
			if GetX(enemiesEven[i].gear) < GetX(hero.gear) and enemiesEven[i].turnLeft then
				HogTurnLeft(enemiesEven[i].gear, false)
			elseif GetX(enemiesEven[i].gear) > GetX(hero.gear) and not enemiesEven[i].turnLeft then
				HogTurnLeft(enemiesEven[i].gear, true)
			end
		end
	end
	for i=1,table.getn(enemiesOdd) do
		if GetHealth(enemiesOdd[i].gear) then
			if GetX(enemiesOdd[i].gear) < GetX(hero.gear) and enemiesOdd[i].turnLeft then
				HogTurnLeft(enemiesOdd[i].gear, false)
			elseif GetX(enemiesOdd[i].gear) > GetX(hero.gear) and not enemiesOdd[i].turnLeft then
				HogTurnLeft(enemiesOdd[i].gear, true)
			end
		end
	end
end

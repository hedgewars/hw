------------------- ABOUT ----------------------
--
-- Hero has get into an Red Strawberries ambush
-- He has to eliminate the enemies by using limited
-- ammo of sniper rifle and watermelon

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("Precise shooting")
local timeLeft = 10000
local lastWeaponUsed = amSniperRifle
local challengeObjectives = loc("Use your available weapons in order to eliminate the enemies").."|"..
	loc("You can only use the Sniper Rifle or the Watermelon bomb").."|"..
	loc("You'll have only 2 watermelon bombs during the game").."|"..
	loc("You'll get an extra Sniper Rifle every time you kill an enemy hog with a limit of max 4 rifles").."|"..
	loc("You'll get an extra Teleport every time you kill an enemy hog with a limit of max 2 teleports").."|"..
	loc("The first turn will last 25 sec and every other turn 15 sec").."|"..
	loc("If you skip a turn then the turn time left will be added to your next turn").."|"..
	loc("Some parts of the land are indestructible")
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Challenge Objectives"), challengeObjectives, 1, 4500},
}
-- hogs
local hero = {
	name = loc("Hog Solo"),
	x = 1100,
	y = 560
}
local enemiesOdd = {
	{name = loc("Hog 1"), x = 2000 , y = 175},
	{name = loc("Hog III"), x = 1950 , y = 1110},
	{name = loc("Hog 100"), x = 1270 , y = 1480},
	{name = loc("Hog Saturn"), x = 240 , y = 790},
	{name = loc("Hog nueve"), x = 620 , y = 1950},
	{name = loc("Hog onze"), x = 720 , y = 1950},
	{name = loc("Hog dertien"), x = 1620 , y = 1950},
	{name = loc("Hog 3x5"), x = 1720 , y = 1950},
}
local enemiesEven = {
	{name = loc("Hog two"), x = 660, y = 140},
	{name = loc("Hog D"), x = 1120, y = 1250},
	{name = loc("Hog exi"), x = 1290, y = 1250},
	{name = loc("Hog octo"), x = 820, y = 1950},
	{name = loc("Hog decar"), x = 920, y = 1950},
	{name = loc("Hog Hephaestus"), x = 1820, y = 1950},
	{name = loc("Hog 7+7"), x = 1920, y = 1950},
	{name = loc("Hog EOF"), x = 1200, y = 560},
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
	TurnTime = 15000
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
	local hats = { "Bandit", "fr_apple", "fr_banana", "fr_lemon", "fr_orange",
					"fr_pumpkin", "Gasmask", "NinjaFull", "NinjaStraight", "NinjaTriangle" }
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	for i=1,table.getn(enemiesEven) do
		enemiesEven[i].gear = AddHog(enemiesEven[i].name, 1, 100, hats[GetRandom(table.getn(hats))+1])
		AnimSetGearPosition(enemiesEven[i].gear, enemiesEven[i].x, enemiesEven[i].y)
	end
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	for i=1,table.getn(enemiesOdd) do
		enemiesOdd[i].gear = AddHog(enemiesOdd[i].name, 1, 100, hats[GetRandom(table.getn(hats))+1])
		AnimSetGearPosition(enemiesOdd[i].gear, enemiesOdd[i].x, enemiesOdd[i].y)
	end

	initCheckpoint("fruit03")

	AnimInit()
	AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	ShowMission(missionName, loc("Challenge Objectives"), challengeObjectives, -amSkip, 0)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onHeroWin, {hero.gear}, heroWin, {hero.gear}, 0)

	--hero ammo
	AddAmmo(hero.gear, amTeleport, 2)
	AddAmmo(hero.gear, amSniperRifle, 2)
	AddAmmo(hero.gear, amWatermelon, 2)
	--enemies ammo
	AddAmmo(enemiesOdd[1].gear, amDEagle, 100)
	AddAmmo(enemiesOdd[1].gear, amSniperRifle, 100)
	AddAmmo(enemiesOdd[1].gear, amWatermelon, 1)
	AddAmmo(enemiesOdd[1].gear, amGrenade, 5)
	AddAmmo(enemiesEven[1].gear, amDEagle, 100)
	AddAmmo(enemiesEven[1].gear, amSniperRifle, 100)
	AddAmmo(enemiesEven[1].gear, amWatermelon, 1)
	AddAmmo(enemiesEven[1].gear, amGrenade, 5)

	SendHealthStatsOff()
	AddAnim(dialog01)
end

function onNewTurn()
	if CurrentHedgehog == hero.gear then
		if GetAmmoCount(hero.gear, amSkip) == 0 then
			TurnTimeLeft = TurnTime + timeLeft
			AddAmmo(hero.gear, amSkip, 1)
		end
		timeLeft = 0
	end
	turnHogs()
end

function onGameTick()
	AnimUnWait()
	if ShowAnimation() == false then
		return
	end
	ExecuteAfterAnimations()
	CheckEvents()
end

function onGameTick20()
	if CurrentHedgehog == hero.gear and TurnTimeLeft ~= 0 then
		timeLeft = TurnTimeLeft
	end
end

function onGearDelete(gear)
	if (isHog(gear)) then
		local availableTeleports = GetAmmoCount(hero.gear,amTeleport)
		local availableSniper = GetAmmoCount(hero.gear,amSniperRifle)
		if availableTeleports < 2 then
			AddAmmo(hero.gear, amTeleport, availableTeleports + 1 )
		end
		if availableSniper < 4 then
			AddAmmo(hero.gear, amSniperRifle, availableSniper + 1 )
		end
	end
end

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)
	end
end

-------------- EVENTS ------------------

function onHeroDeath(gear)
	if not GetHealth(hero.gear) then
		return true
	end
	return false
end

function onHeroWin(gear)
	local enemies = enemiesOdd
	for i=1,table.getn(enemiesEven) do
		table.insert(enemies, enemiesEven[i])
	end
	local allDead = true
	for i=1,table.getn(enemies) do
		if GetHealth(enemies[i].gear) then
			allDead = false
			break
		end
	end
	return allDead
end

-------------- ACTIONS ------------------

function heroDeath(gear)
	SendStat(siGameResult, loc("Hog Solo lost, try again!"))
	SendStat(siCustomAchievement, loc("You have to eliminate all the enemies"))
	SendStat(siCustomAchievement, loc("Read the Challenge Objectives from within the mission for more details"))
	SendStat(siPlayerKills,'1',teamB.name)
	SendStat(siPlayerKills,'0',teamA.name)
	EndGame()
end

function heroWin(gear)
	saveBonus(2, 1)
	SendStat(siGameResult, loc("Congratulations, you won!"))
	SendStat(siCustomAchievement, loc("You complete the mission in "..TotalRounds.." rounds"))
	SendStat(siCustomAchievement, loc("You will gain some extra ammo from the crates the next time you play the \"Getting to the device\" mission"))
	SendStat(siPlayerKills,'1',teamA.name)
	EndGame()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
    startBattle()
end

function AnimationSetup()
	-- DIALOG 01 - Start, game instructions
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Somewhere in the Fruit Planet Hog Solo got lost..."), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("...and got ambushed by the Red Strawberries"), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Use your available weapons in order to eliminate the enemies"), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("You can only use the Sniper Rifle or the Watermelon bomb"), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("You'll have only 2 watermelon bombs during the game"), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("You'll get an extra Sniper Rifle every time you kill an enemy hog with a limit of max 4 rifles"), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("You'll get an extra Teleport every time you kill an enemy hog with a limit of max 2 teleports"), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("The first turn will last 25 sec and every other turn 15 sec"), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("If you skip the game your time left will be added to your next turn"), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Some parts of the land are indestructible"), 5000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = startBattle, args = {hero.gear}})
end

------------------ Other Functions -------------------

function turnHogs()
	if GetHealth(hero.gear) then
		for i=1,table.getn(enemiesEven) do
			if GetHealth(enemiesEven[i].gear) then
				if GetX(enemiesEven[i].gear) < GetX(hero.gear) then
					HogTurnLeft(enemiesEven[i].gear, false)
				elseif GetX(enemiesEven[i].gear) > GetX(hero.gear) then
					HogTurnLeft(enemiesEven[i].gear, true)
				end
			end
		end
		for i=1,table.getn(enemiesOdd) do
			if GetHealth(enemiesOdd[i].gear) then
				if GetX(enemiesOdd[i].gear) < GetX(hero.gear) then
					HogTurnLeft(enemiesOdd[i].gear, false)
				elseif GetX(enemiesOdd[i].gear) > GetX(hero.gear) then
					HogTurnLeft(enemiesOdd[i].gear, true)
				end
			end
		end
	end
end

function startBattle()
	AnimSwitchHog(enemiesOdd[table.getn(enemiesOdd)].gear)
	TurnTimeLeft = 0
	-- these 2 are needed in order hero has 10 sec more in the first turn
	timeLeft = 10000
	AddAmmo(hero.gear, amSkip, 0)
end

function isHog(gear)
	local hog = false
	for i=1,table.getn(enemiesOdd) do
		if gear == enemiesOdd[i].gear then
			hog = true
			break
		end
	end
	if not hog then
		for i=1,table.getn(enemiesEven) do
			if gear == enemiesEven then
				hog = true
				break
			end
		end
	end
	return hog
end

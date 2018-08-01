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
local timeLeft = 0
local lastWeaponUsed = amNothing
local firstTurn = true
local battleStarted = false
local challengeObjectives = loc("Use your available weapons in order to eliminate the enemies.").."|"..
	loc("You can only use the sniper rifle or the watermelon bomb.").."|"..
	loc("You'll have only 2 watermelon bombs during the game.").."|"..
	loc("You'll get an extra sniper rifle every time you kill an enemy hog with a limit of max 4 rifles.").."|"..
	loc("You'll get an extra teleport every time you kill an enemy hog with a limit of max 2 teleports.").."|"..
	loc("The first turn will last 25 sec and every other turn 15 sec.").."|"..
	loc("If you skip a turn then the turn time left will be added to your next turn.").."|"..
	loc("Some parts of the land are indestructible.")
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	["init"] = {missionName, loc("Challenge objectives"), challengeObjectives, 1, 35000},
}
-- hogs
local hero = {
	name = loc("Hog Solo"),
	x = 1100,
	y = 560
}
local heroTurns = 0
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
	color = -6
}
local teamB = {
	-- Red Strawberries 1
	name = loc("RS1"),
	color = -1
}
local teamC = {
	-- Red Strawberries 2
	name = loc("RS2"),
	color = -1
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
	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0

	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Simple", "Island", "Default", "hedgewars")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	-- enemies
	local hats = { "Bandit", "fr_apple", "fr_banana", "fr_lemon", "fr_orange",
					"fr_pumpkin", "Gasmask", "NinjaFull", "NinjaStraight", "NinjaTriangle" }
	AddTeam(teamC.name, teamC.color, "bp2", "Island", "Default", "cm_bars")
	for i=1,table.getn(enemiesEven) do
		enemiesEven[i].gear = AddHog(enemiesEven[i].name, 1, 100, hats[GetRandom(table.getn(hats))+1])
		AnimSetGearPosition(enemiesEven[i].gear, enemiesEven[i].x, enemiesEven[i].y)
	end
	AddTeam(teamB.name, teamB.color, "bp2", "Island", "Default", "cm_bars")
	for i=1,table.getn(enemiesOdd) do
		enemiesOdd[i].gear = AddHog(enemiesOdd[i].name, 1, 100, hats[GetRandom(table.getn(hats))+1])
		AnimSetGearPosition(enemiesOdd[i].gear, enemiesOdd[i].x, enemiesOdd[i].y)
	end

	initCheckpoint("fruit03")

	AnimInit()
end

function onGameStart()
	FollowGear(hero.gear)
	ShowMission(unpack(goals["init"]))

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onHeroWin, {hero.gear}, heroWin, {hero.gear}, 0)

	--hero ammo
	AddAmmo(hero.gear, amTeleport, 2)
	AddAmmo(hero.gear, amSniperRifle, 2)
	AddAmmo(hero.gear, amWatermelon, 2)

	AddAmmo(hero.gear, amSkip, 100)
	timeLeft = 0

	--enemies ammo
	AddAmmo(enemiesOdd[1].gear, amDEagle, 100)
	AddAmmo(enemiesOdd[1].gear, amSniperRifle, 100)
	AddAmmo(enemiesOdd[1].gear, amWatermelon, 1)
	AddAmmo(enemiesOdd[1].gear, amGrenade, 5)
	AddAmmo(enemiesEven[1].gear, amDEagle, 100)
	AddAmmo(enemiesEven[1].gear, amSniperRifle, 100)
	AddAmmo(enemiesEven[1].gear, amWatermelon, 1)
	AddAmmo(enemiesEven[1].gear, amGrenade, 5)

	turnHogs()

	SendHealthStatsOff()
end

function onNewTurn()
	if CurrentHedgehog == hero.gear then
		if firstTurn then
			-- Unique game rule in this mission: First turn has more time
			TurnTimeLeft = 25000
			-- Generous ready time on first turn to give more time to read
			ReadyTimeLeft = 35000
			battleStarted = true
			firstTurn = false
		end
		if lastWeaponUsed == amSkip then
			TurnTimeLeft = TurnTime + timeLeft
		end
		timeLeft = 0
		heroTurns = heroTurns + 1
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

function onGameTick20()
	if CurrentHedgehog == hero.gear and TurnTimeLeft ~= 0 then
		timeLeft = TurnTimeLeft
	end
end

-- Display ammo icon above gear. i = offset (start at 1)
local function displayAmmoIcon(gear, ammoType, i)
	if not GetHealth(gear) then
		return
	end
	local x = GetX(gear) + 2
	local y = GetY(gear) + 32 * i
	local vgear = AddVisualGear(x, y, vgtAmmo, 0, true)
	if vgear ~= nil then
		local vgtX,vgtY,vgtdX,vgtdY,vgtAngle,vgtFrame,vgtFrameTicks,vgtState,vgtTimer,vgtTint = GetVisualGearValues(vgear)
		local vgtFrame = ammoType
		SetVisualGearValues(vgear,vgtX,vgtY,vgtdX,vgtdY,vgtAngle,vgtFrame,vgtFrameTicks,vgtState,vgtTimer,vgtTint)
	end
end

function onGearDelete(gear)
	if (isEnemyHog(gear) and GetHealth(hero.gear)) then
		local availableTeleports = GetAmmoCount(hero.gear,amTeleport)
		local availableSniper = GetAmmoCount(hero.gear,amSniperRifle)
		local ammolist = ""
		local tele = false
		if availableTeleports < 2 then
			AddAmmo(hero.gear, amTeleport, availableTeleports + 1 )
			displayAmmoIcon(hero.gear, amTeleport, 1)
			tele = true
			ammolist = ammolist .. string.format(loc("%s (+1)"), GetAmmoName(amTeleport))
		end
		if availableSniper < 4 then
			AddAmmo(hero.gear, amSniperRifle, availableSniper + 1 )
			displayAmmoIcon(hero.gear, amSniperRifle, 2)
			if tele then
				ammolist = ammolist .. " • "
			end
			ammolist = ammolist .. string.format(loc("%s (+1)"), GetAmmoName(amSniperRifle))
		end
		-- Show collected ammo
		if ammolist ~= "" then
			PlaySound(sndShotgunReload)
			AddCaption(ammolist, GetClanColor(GetHogClan(hero.gear)), capgrpAmmoinfo)
		end
	end
end

-- Hide mission panel when player does anything
function hideMissionOnAction()
	if battleStarted then
		HideMission()
	end
end

onSlot = hideMissionOnAction
onSetWeapon = hideMissionOnAction
onAttack = hideMissionOnAction
function onHogAttack(ammoType)
	hideMissionOnAction()
	if CurrentHedgehog == hero.gear then
		lastWeaponUsed = ammoType
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
	SendStat(siCustomAchievement, loc("You have to eliminate all the enemies."))
	SendStat(siCustomAchievement, loc("Read the challenge objectives from within the mission for more details."))
	sendSimpleTeamRankings({teamB.name, teamC.name, teamA.name})
	EndGame()
end

function heroWin(gear)
	saveBonus(2, 1)
	SendStat(siGameResult, loc("Congratulations, you won!"))
	SendStat(siCustomAchievement, string.format(loc("You completed the mission in %d rounds."), heroTurns))
	local record = tonumber(GetCampaignVar("FastestPreciseShooting"))
	if record ~= nil and heroTurns >= record then
		SendStat(siCustomAchievement, string.format(loc("Your fastest victory so far: %d rounds"), record))
	end
	if record == nil or heroTurns < record then
		SaveCampaignVar("FastestPreciseShooting", tostring(heroTurns))
		if record ~= nil then
			SendStat(siCustomAchievement, loc("This is a new personal best, congratulations!"))
		end
	end
	SendStat(siCustomAchievement, loc("You will gain some extra ammo from the crates the next time you play the \"Getting to the device\" mission."))
	sendSimpleTeamRankings({teamA.name, teamB.name, teamC.name})
	SaveCampaignVar("Mission10Won", "true")
	checkAllMissionsCompleted()
	EndGame()
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

function isEnemyHog(gear)
	for i=1, table.getn(enemiesOdd) do
		if gear == enemiesOdd[i].gear then
			return true
		end
	end
	for i=1, table.getn(enemiesEven) do
		if gear == enemiesEven then
			return true
		end
	end
	return false
end

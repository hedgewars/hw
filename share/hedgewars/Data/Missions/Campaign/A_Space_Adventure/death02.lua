------------------- ABOUT ----------------------
--
-- Hero has been surrounded my some space villains
-- He has to defeat them in order to escape

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("Killing the specialists")
local challengeObjectives = loc("Use your available weapons in order to eliminate the enemies.").."|"..
	loc("The enemy hogs play in a random order.").."|"..
	loc("At the start of the game each enemy hog has only the weapon that he is named after.").."|"..
	loc("A random hedgehog will inherit the weapons of his deceased team-mates.").."|"..
	loc("After you killed an enemy, you'll lose the weapon that he is named after.").."|"..
	loc("If only one enemy is left, you'll get bonus ammo.").."|"..
	loc("If you hurt an enemy, you'll get one third of the damage dealt.").."|"..
	loc("If you kill an enemy, your health will be set to 100.")
-- mission objectives
local goals = {
	["init"] = {missionName, loc("Challenge objectives"), challengeObjectives, 1, 35000},
}
-- hogs
local hero = {
	name = loc("Hog Solo"),
	x = 850,
	y = 460,
	mortarAmmo = 2,
	firepunchAmmo = 1,
	deagleAmmo = 4,
	bazookaAmmo = 2,
	grenadeAmmo = 4,
}
local heroTurns = 0
local enemies = {
	{ name = GetAmmoName(amMortar), x = 1890, y = 520, weapon = amMortar, additionalWeapons = {}},
	{ name = GetAmmoName(amDEagle), x = 1390, y = 790, weapon = amDEagle, additionalWeapons = {}},
	{ name = GetAmmoName(amGrenade), x = 186, y = 48, weapon = amGrenade, additionalWeapons = {}},
	{ name = GetAmmoName(amFirePunch), x = 330, y = 270, weapon = amFirePunch, additionalWeapons = {}},
	{ name = GetAmmoName(amBazooka), x = 1950, y = 150, weapon = amBazooka, additionalWeapons = {}},
}
-- teams
local teamA = {
	name = loc("Hog Solo"),
	color = -6
}
local teamB = {
	name = loc("5 Deadly Hogs"),
	color = -1
}
-- After hero killed an enemy, his weapons will be reset in the next round
local heroWeaponResetPending = false
local battleStarted = false
local firstTurn = true

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	TurnTime = 25000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Map = "death02_map"
	Theme = "Hell"
	Delay = 600 -- this makes the messages between turns more readable
	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0

	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Simple", "Island", "Default", "hedgewars")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	-- enemies
	shuffleHogs(enemies)
	AddTeam(teamB.name, teamB.color, "skull", "Island", "Default", "cm_skull")
	for i=1,table.getn(enemies) do
		enemies[i].gear = AddHog(enemies[i].name, 1, 100, "war_desertgrenadier1")
		AnimSetGearPosition(enemies[i].gear, enemies[i].x, enemies[i].y)
	end

	initCheckpoint("death02")

	AnimInit()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	ShowMission(unpack(goals["init"]))

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onHeroWin, {hero.gear}, heroWin, {hero.gear}, 0)

	--hero ammo
	AddAmmo(hero.gear, amSkip, 100)
	AddAmmo(hero.gear, amRope, 2)
	refreshHeroAmmo()

	SendHealthStatsOff()
end

function onNewTurn()
	battleStarted = true
	if firstTurn then
		-- Generous ready time in first turn to more time to read the mission panel
		SetReadyTimeLeft(35000)
		firstTurn = false
	end
	if CurrentHedgehog ~= hero.gear then
		enemyWeapons()
	else
		heroTurns = heroTurns + 1
	end
end

function onGearDelete(gear)
	if isHog(gear) then
		-- Set health to 100 (with heal effect, if health was smaller)
		local healthDiff = 100 - GetHealth(hero.gear)
		if healthDiff > 1 then
			HealHog(hero.gear, healthDiff, true, 0x00FF00FF)
		else
			SetHealth(hero.gear, 100)
		end
		local deadHog = getHog(gear)
		if deadHog.weapon == amMortar then
			hero.mortarAmmo = 0
		elseif deadHog.weapon == amFirePunch then
			hero.firepunchAmmo = 0
		elseif deadHog.weapon == amDEagle then
			hero.deagleAmmo = 0
		elseif deadHog.weapon == amBazooka then
			hero.bazookaAmmo = 0
		elseif deadHog.weapon == amGrenade then
			hero.grenadeAmmo = 0
		end
		local randomHog = GetRandom(table.getn(enemies))+1
		while not GetHealth(enemies[randomHog].gear) do
			randomHog = GetRandom(table.getn(enemies))+1
		end
		table.insert(enemies[randomHog].additionalWeapons, deadHog.weapon)
		for i=1,table.getn(deadHog.additionalWeapons) do
			table.insert(enemies[randomHog].additionalWeapons, deadHog.additionalWeapons[i])
		end
		heroWeaponResetPending = true
	end
end

function onGearDamage(gear, damage)
	if isHog(gear) and GetHealth(hero.gear) then
		local bonusHealth = div(damage, 3)
		HealHog(hero.gear, bonusHealth, true, 0xFF0000FF)
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
	-- Refresh hero ammo immediately after its not his turn anymore
	if CurrentHedgehog ~= hero.gear and heroWeaponResetPending then
		refreshHeroAmmo()
	end
end

-- Hide mission panel when player does anything
function hideMissionOnAction()
	if battleStarted then
		HideMission()
	end
end

onHogAttack = hideMissionOnAction
onAttack = hideMissionOnAction
onSlot = hideMissionOnAction
onSetWeapon = hideMissionOnAction

-------------- EVENTS ------------------

function onHeroDeath(gear)
	if not GetHealth(hero.gear) then
		return true
	end
	return false
end

function onHeroWin(gear)
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
	sendSimpleTeamRankings({teamB.name, teamA.name})
	EndGame()
end

function heroWin(gear)
	saveBonus(3, 4)
	SendStat(siGameResult, loc("Congratulations, you won!"))
	SendStat(siCustomAchievement, string.format(loc("You completed the mission in %d rounds."), heroTurns))
	local record = tonumber(GetCampaignVar("FastestSpecialistsWin"))
	if record ~= nil and heroTurns >= record then
		SendStat(siCustomAchievement, string.format(loc("Your fastest victory so far: %d rounds"), record))
	end
	if record == nil or heroTurns < record then
		SaveCampaignVar("FastestSpecialistsWin", tostring(heroTurns))
		if record ~= nil then
			SendStat(siCustomAchievement, loc("This is a new personal best, congratulations!"))
		end
	end
	-- An old version of this mission was buggy and stored a turn record WAY too low.
	-- Let's clear the broken variable (FastestSpecialistsKill) here.
	SaveCampaignVar("FastestSpecialistsKill", "")
	SendStat(siCustomAchievement, loc("The next 4 times you play the \"The last encounter\" mission you'll get 20 more hit points and a laser sight."))
	sendSimpleTeamRankings({teamA.name, teamB.name})
	SaveCampaignVar("Mission11Won", "true")
	checkAllMissionsCompleted()
	EndGame()
end

------------ Other Functions -------------------

function shuffleHogs(hogs)
    local hogsNumber = table.getn(hogs)
    for i=1,hogsNumber do
		local randomHog = GetRandom(hogsNumber) + 1
		hogs[i], hogs[randomHog] = hogs[randomHog], hogs[i]
    end
end

function refreshHeroAmmo()
	local extraAmmo = 0
	if getAliveEnemiesCount() == 1 then
		extraAmmo = 2
		PlaySound(sndShotgunReload)
		AddCaption(loc("Reinforcements! +2 of each weapon!"), GetClanColor(GetHogClan(hero.gear)), capgrpAmmoinfo)
	end
	AddAmmo(hero.gear, amMortar, hero.mortarAmmo + extraAmmo)
	AddAmmo(hero.gear, amFirePunch, hero.firepunchAmmo + extraAmmo)
	AddAmmo(hero.gear, amDEagle, hero.deagleAmmo + extraAmmo)
	AddAmmo(hero.gear, amBazooka, hero.bazookaAmmo + extraAmmo)
	AddAmmo(hero.gear, amGrenade, hero.grenadeAmmo + extraAmmo)
	heroWeaponResetPending = false
end

function enemyWeapons()
	for i=1,table.getn(enemies) do
		if GetHealth(enemies[i].gear) and enemies[i].gear == CurrentHedgehog then
			AddAmmo(enemies[i].gear, amMortar, 0)
			AddAmmo(enemies[i].gear, amFirePunch, 0)
			AddAmmo(enemies[i].gear, amDEagle, 0)
			AddAmmo(enemies[i].gear, amBazooka, 0)
			AddAmmo(enemies[i].gear, amGrenade, 0)
			AddAmmo(enemies[i].gear, enemies[i].weapon, 1)
			for w=1,table.getn(enemies[i].additionalWeapons) do
				AddAmmo(enemies[i].gear, enemies[i].additionalWeapons[w], 1)
			end
		end
	end
end

function isHog(gear)
	local hog = false
	for i=1,table.getn(enemies) do
		if gear == enemies[i].gear then
			hog = true
			break
		end
	end
	return hog
end

function getHog(gear)
	for i=1,table.getn(enemies) do
		if gear == enemies[i].gear then
			return enemies[i]
		end
	end
end

function getAliveEnemiesCount()
	local count = 0
	for i=1,table.getn(enemies) do
		if GetHealth(enemies[i].gear) then
			count = count + 1
		end
	end
	return count
end

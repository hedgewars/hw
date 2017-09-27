------------------- ABOUT ----------------------
--
-- Hero has to use the rc plane end perform some
-- flying tasks

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

-- globals
local missionName = loc("Precise flying")
local challengeObjectives = loc("Use the RC plane and destroy the all the targets.").."|"..
	loc("Each time you destroy all the targets on your current level you'll get teleported to the next level.").."|"..
	loc("You'll have only one RC plane at the start of the mission.").."|"..
	loc("During the game you can get new RC planes by collecting the weapon crates.")
local currentTarget = 1
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Challenge objectives"), challengeObjectives, 1, 4500},
}
-- hogs
local hero = {
	name = loc("Hog Solo"),
	x = 100,
	y = 170
}
-- teams
local teamA = {
	name = loc("Hog Solo"),
	color = tonumber("38D61C",16) -- green
}
-- creates & targets
local rcCrates = {
	{ x = 1680, y = 240},
	{ x = 2810, y = 720},
	{ x = 2440, y = 660},
	{ x = 256, y = 1090},
}
local targets = {
	{ x = 2070, y = 410},
	{ x = 3880, y = 1430},
	{ x = 4000, y = 1430},
	{ x = 2190, y = 1160},
	{ x = 2190, y = 1460},
	{ x = 2110, y = 1700},
	{ x = 2260, y = 1700},
	{ x = 2085, y = 1330},
	{ x = 156, y = 1400},
	{ x = 324, y = 1400},
	{ x = 660, y = 1310},
	{ x = 1200, y = 1310},
	{ x = 1700, y = 1310},
}
local targetsDead = {}
local flameCounter = 0

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	GameFlags = gfOneClanMode
	Seed = 1
	TurnTime = -1
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Map = "desert03_map"
	Theme = "Desert"
	-- Disable SuddenDeath
	WaterRise = 0
	HealthDecrease = 0

	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "hedgewars")
	hero.gear = AddHog(hero.name, 0, 1, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)

	initCheckpoint("desert03")

	AnimInit(true)
	AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	ShowMission(missionName, loc("Challenge objectives"), challengeObjectives, -amSkip, 0)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onLose, {hero.gear}, lose, {hero.gear}, 0)

	-- original crates and targets
	SpawnAmmoCrate(rcCrates[1].x, rcCrates[1].y, amRCPlane)
	targets[1].gear = AddGear(targets[1].x, targets[1].y, gtTarget, 0, 0, 0, 0)

	-- hero ammo
	AddAmmo(hero.gear, amRCPlane, 1)

	SendHealthStatsOff()
	AddAnim(dialog01)
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
	checkTargetsDestroyed()
end

function onAmmoStoreInit()
	SetAmmo(amNothing, 0, 0, 0, 0)
	SetAmmo(amRCPlane, 0, 0, 0, 1)
end

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)
	end
end

function onGearAdd(gear)
	if GetGearType(gear) == gtFlame then
		flameCounter = flameCounter + 1
	end
end

function onGearDelete(gear)
	if GetGearType(gear) == gtFlame then
		flameCounter = flameCounter - 1
	end
	for t=1, #targets do
		if gear == targets[t].gear then
			targetsDead[t] = true
			break
		end
	end
end

-------------- EVENTS ------------------

function onHeroDeath(gear)
	if not GetHealth(hero.gear) then
		return true
	end
	return false
end

function onLose(gear)
	if GetHealth(hero.gear) and currentTarget < 4 and GetAmmoCount(hero.gear, amRCPlane) == 0 and flameCounter <= 0 then
		return true
	end
	return false
end

-------------- ACTIONS ------------------

function heroDeath(gear)
	gameOver()
end

function lose(gear)
	AddCaption(loc("Out of ammo!"), 0xFFFFFFFF, capgrpMessage2)
	PlaySound(sndStupid, hero.gear)
	gameOver()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
end

function AnimationSetup()
	-- DIALOG 01 - Start, game instructions
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("On the Desert Planet, Hog Solo found some time to play with his RC plane"), 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Each time you destroy all the targets on your current level you'll get teleported to the next level"), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("You'll have only one RC plane at the start of the mission"), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("During the game you can get new RC planes by collecting the weapon crates"), 5000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
end

----------------- Other Functions -----------------

function checkTargetsDestroyed()
	if currentTarget == 1 then
		if targetsDead[1] then
			AddCaption(loc("Level 1 clear!"))
			SetGearPosition(hero.gear, 3590, 90)
			currentTarget = 2
			setTargets(currentTarget)
		end
	elseif currentTarget == 2 then
		if targetsDead[2] and targetsDead[3] then
			AddCaption(loc("Level 2 clear!"))
			SetGearPosition(hero.gear, 1110, 580)
			currentTarget = 3
			setTargets(currentTarget)
		end
	elseif currentTarget == 3 then
		local allDead = true
		for t=3, #targets do
			if targetsDead[t] ~= true then
				allDead = false
			end
		end
		if allDead then
			currentTarget = 4
			win()
		end
	end
end

function setTargets(ct)
	if ct == 2 then
		SpawnAmmoCrate(rcCrates[2].x, rcCrates[2].y, amRCPlane)
		for i=2,3 do
			targets[i].gear = AddGear(targets[i].x, targets[i].y, gtTarget, 0, 0, 0, 0)
		end
	elseif ct == 3 then
		SpawnUtilityCrate(rcCrates[4].x, rcCrates[4].y, amNothing)
		SpawnAmmoCrate(rcCrates[3].x, rcCrates[3].y, amRCPlane, 2)
		for i=4,13 do
			targets[i].gear = AddGear(targets[i].x, targets[i].y, gtTarget, 0, 0, 0, 0)
		end
	end
end

function win()
	AddCaption(loc("Victory!"))
	PlaySound(sndVictory, hero.gear)
	saveBonus(1, 1)
	SendStat(siGameResult, loc("Congratulations, you are the best!"))
	SendStat(siCustomAchievement, loc("You have destroyed all the targets."))
	SendStat(siCustomAchievement, loc("You are indeed the best PAotH pilot."))
	SendStat(siCustomAchievement, loc("Next time you play \"Searching in the dust\" you'll have an RC plane available."))
	sendSimpleTeamRankings({teamA.name})
	SaveCampaignVar("Mission12Won", "true")
	checkAllMissionsCompleted()
	EndGame()
end

function gameOver()
	SendStat(siGameResult, loc("Hog Solo lost, try again!"))
	SendStat(siCustomAchievement, loc("You have to destroy all the targets."))
	SendStat(siCustomAchievement, loc("You will fail if you run out of ammo and there are still targets available."))
	SendStat(siCustomAchievement, loc("Read the challenge objectives from within the mission for more details."))
	sendSimpleTeamRankings({teamA.name})
	EndGame()
end

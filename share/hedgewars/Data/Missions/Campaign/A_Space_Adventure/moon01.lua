------------------- ABOUT ----------------------
--
-- This is the first stop of hero's journey.
-- Here he'll get fuels to continue traveling.
-- However, the PAotH allies of the hero have
-- been taken hostages by professor Hogevil.
-- So hero has to get whatever available equipement
-- there is and rescue them.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("The first stop")
local weaponsAcquired = false
local battleZoneReached = false
local checkPointReached = 1 -- 1 is start of the game
local afterDialog02 = false
local gameOver = false
-- dialogs
local dialog01 = {}
local dialog02 = {}
local dialog03 = {}
local dialog04 = {}
local dialog05 = {}
local dialog06 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("Go to the upper platform and get the weapons in the crates!"), 1, 4500},
	[dialog02] = {missionName, loc("Prepare to fight"), loc("Go down and save these PAotH hogs!"), 1, 5000},
	[dialog03] = {missionName, loc("The fight begins!"), loc("Neutralize your enemies and be careful!"), 1, 5000},
	[dialog04] = {missionName, loc("The fight begins!"), loc("Neutralize your enemies and be careful!"), 1, 5000}
}
-- crates
local weaponsY = 100
local bazookaX = 70
local parachuteX = 110
local grenadeX = 160
local deserteagleX = 200
-- hogs
local hero = {}
local paoth1 = {}
local paoth2 = {}
local paoth3 = {}
local paoth4 = {}
local professor = {}
local minion1 = {}
local minion2 = {}
local minion3 = {}
local minion4 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
local teamD = {}
-- hedgehogs values
hero.name = loc("Hog Solo")
hero.x = 1380
hero.y = 1750
hero.dead = false
paoth1.name = loc("Joe")
paoth1.x = 1430
paoth1.y = 1750
paoth2.name = loc("Bruce")
paoth2.x = 3760
paoth2.y = 1800
paoth3.name = loc("Helena")
paoth3.x = 3800
paoth3.y = 1800
paoth4.name = loc("Boris")
paoth4.x = 3860
paoth4.y = 1800
professor.name = loc("Prof. Hogevil")
professor.x = 3800
professor.y = 1600
professor.dead = false
professor.health = 120
minion1.name = loc("Minion")
minion1.x = 2460
minion1.y = 1450
minion2.name = loc("Minion")
minion2.x = 2450
minion2.y = 1900
minion3.name = loc("Minion")
minion3.x = 3500
minion3.y = 1750

teamA.name = loc("PAotH")
teamA.color = -6
teamB.name = loc("Minions")
teamB.color = -2
teamC.name = loc("Professor")
teamC.color = -2
teamD.name = loc("Hog Solo")
teamD.color = -6

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	GameFlags = gfSolidLand + gfDisableWind
	TurnTime = 25000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 3000
	Explosives = 0
	HealthDecrease = 0
	WaterRise = 0
	Map = "moon01_map"
	Theme = "Cheese" -- Because ofc moon is made of cheese :)
	-- Hero
	teamD.name = AddMissionTeam(teamD.color)
	if tonumber(GetCampaignVar("HeroHealth")) then
		hero.gear = AddMissionHog(tonumber(GetCampaignVar("HeroHealth")))
	else
		hero.gear = AddMissionHog(100)
	end
	hero.name = GetHogName(hero.gear)
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	-- PAotH
	teamA.name = AddTeam(teamA.name, teamA.color, "Earth", "Island", "Default_qau", "cm_galaxy")
	SetTeamPassive(teamA.name, true)
	paoth1.gear = AddHog(paoth1.name, 0, 100, "scif_2001O")
	AnimSetGearPosition(paoth1.gear, paoth1.x, paoth1.y)
	HogTurnLeft(paoth1.gear, true)
	paoth2.gear = AddHog(paoth2.name, 0, 100, "scif_2001Y")
	AnimSetGearPosition(paoth2.gear, paoth2.x, paoth2.y)
	HogTurnLeft(paoth2.gear, true)
	paoth3.gear = AddHog(paoth3.name, 0, 100, "hair_purple")
	AnimSetGearPosition(paoth3.gear, paoth3.x, paoth3.y)
	HogTurnLeft(paoth3.gear, true)
	paoth4.gear = AddHog(paoth4.name, 0, 100, "scif_2001Y")
	AnimSetGearPosition(paoth4.gear, paoth4.x, paoth4.y)
	HogTurnLeft(paoth4.gear, true)
	-- Professor
	teamC.name = AddTeam(teamC.name, teamC.color, "star", "Island", "Default_qau", "cm_sine")
	SetTeamPassive(teamC.name, true)
	professor.gear = AddHog(professor.name, 0, professor.health, "tophats")
	AnimSetGearPosition(professor.gear, professor.x, professor.y)
	HogTurnLeft(professor.gear, true)
	-- Minions
	teamB.name = AddTeam(teamB.name, teamB.color, "eyecross", "Island", "Default_qau", "cm_sine")
	minion1.gear = AddHog(minion1.name, 1, 50, "Gasmask")
	AnimSetGearPosition(minion1.gear, minion1.x, minion1.y)
	HogTurnLeft(minion1.gear, true)
	minion2.gear = AddHog(minion2.name, 1, 50, "Gasmask")
	AnimSetGearPosition(minion2.gear, minion2.x, minion2.y)
	HogTurnLeft(minion2.gear, true)
	minion3.gear = AddHog(minion3.name, 1, 50, "Gasmask")
	AnimSetGearPosition(minion3.gear, minion3.x, minion3.y)
	HogTurnLeft(minion3.gear, true)

	-- get the check point
	checkPointReached = initCheckpoint("moon01")
	if checkPointReached == 1 then
		-- Start of the game
	elseif checkPointReached == 2 then
		AnimSetGearPosition(hero.gear, parachuteX, weaponsY)
		if GetHealth(hero.gear) + 5 > 100 then
			SaveCampaignVar("HeroHealth", 100)
		else
			SaveCampaignVar("HeroHealth", GetHealth(hero.gear) + 5)
		end
	end

	AnimInit(true)
	AnimationSetup()
end

function onGameStart()
	-- wait for the first turn to start
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)

	ShowMission(campaignName, missionName, string.format(loc("%s has to refuel the saucer."), hero.name)..
	"|"..loc("Rescue the imprisoned PAotH team and get the fuel!"), 10, 0)

	AddAmmo(minion1.gear, amDEagle, 10)
	AddAmmo(minion2.gear, amDEagle, 10)
	AddAmmo(minion3.gear, amDEagle, 10)
	AddAmmo(minion1.gear, amBazooka, 2)
	AddAmmo(minion2.gear, amBazooka, 2)
	AddAmmo(minion3.gear, amBazooka, 2)
	AddAmmo(minion1.gear, amGrenade, 2)
	AddAmmo(minion2.gear, amGrenade, 2)
	AddAmmo(minion3.gear, amGrenade, 2)

	-- check for death has to go first
	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onProfessorDeath, {professor.gear}, professorDeath, {professor.gear}, 0)
	AddEvent(onMinionsDeath, {professor.gear}, minionsDeath, {professor.gear}, 0)
	AddEvent(onProfessorAndMinionsDeath, {professor.gear}, professorAndMinionsDeath, {professor.gear}, 0)
	AddEvent(onProfessorHit, {professor.gear}, professorHit, {professor.gear}, 1)

	if checkPointReached == 1 then
		AddAmmo(hero.gear, amRope, 2)
		AddAmmo(hero.gear, amSkip, 0)
		SpawnSupplyCrate(bazookaX, weaponsY, amBazooka)
		SpawnSupplyCrate(parachuteX, weaponsY, amParachute)
		SpawnSupplyCrate(grenadeX, weaponsY, amGrenade)
		SpawnSupplyCrate(deserteagleX, weaponsY, amDEagle)
		AddEvent(onWeaponsPlatform, {hero.gear}, weaponsPlatform, {hero.gear}, 0)
		EndTurn(true)
		AddAnim(dialog01)
	elseif checkPointReached == 2 then
		AddAmmo(hero.gear, amBazooka, 3)
		AddAmmo(hero.gear, amParachute, 1)
		AddAmmo(hero.gear, amGrenade, 6)
		AddAmmo(hero.gear, amDEagle, 4)
		SetWind(60)
		GameFlags = bor(GameFlags,gfDisableWind)
		weaponsAcquired = true
		afterDialog02 = true
		EndTurn(true)
		AddAnim(dialog02)
	end
	-- this event check goes here to be executed after the onWeaponsPlatform check
	AddEvent(onBattleZone, {hero.gear}, battleZone, {hero.gear}, 0)

	SendHealthStatsOff()
end

function onAmmoStoreInit()
	SetAmmo(amBazooka, 0, 0, 0, 3)
	SetAmmo(amParachute, 0, 0, 0, 1)
	SetAmmo(amGrenade, 0, 0, 0, 6)
	SetAmmo(amDEagle, 0, 0, 0, 4)
	SetAmmo(amSkip, 9, 0, 0, 1)
end

function onGameTick()
	AnimUnWait()
	if ShowAnimation() == false then
		return
	end
	ExecuteAfterAnimations()
	CheckEvents()
	if CurrentHedgehog ~= hero.gear and not battleZone then
		EndTurn(true)
	end
end

function onNewTurn()
	-- rounds start if hero got his weapons or got near the enemies
	if CurrentHedgehog == hero.gear then
		if not weaponsAcquired and not battleZoneReached then
			SetTurnTimeLeft(MAX_TURN_TIME)
		end
	elseif CurrentHedgehog == minion1.gear or CurrentHedgehog == minion2.gear or CurrentHedgehog == minion3.gear then
		if not battleZoneReached then
			EndTurn(true)
		elseif weaponsAcquired and not battleZoneReached and afterDialog02 then
			battleZone(hero.gear)
		end
	elseif CurrentHedgehog == professor.gear then
		if weaponsAcquired and not battleZoneReached and afterDialog02 then
			battleZone(hero.gear)
		else
			EndTurn(true)
		end
	end
end

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)
	end
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	elseif gear == professor.gear then
		professor.dead = true
	end
end

-------------- EVENTS ------------------

function onWeaponsPlatform(gear)
	if not hero.dead and (GetAmmoCount(hero.gear, amBazooka) > 0 or GetAmmoCount(hero.gear, amParachute) > 0 or
			GetAmmoCount(hero.gear, amGrenade) > 0 or GetAmmoCount(hero.gear, amDEagle) > 0) and StoppedGear(hero.gear) then
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

function onBattleZone(gear)
	if not battleZoneReached and not hero.dead and StoppedGear(gear) and
			(GetX(gear) > 1900 or (weaponsAcquired and GetY(gear) > 1200)) then
		return true
	end
	return false
end

function onProfessorHit(gear)
	if GetHealth(gear) then
		if CurrentHedgehog ~= hero.gear and GetHealth(gear) < professor.health then
			professor.health = GetHealth(gear)
			return true
		elseif GetHealth(gear) < professor.health then
			professor.health = GetHealth(gear)
		end
	end
	return false
end

function onProfessorDeath(gear)
	if professor.dead then
		return true
	end
	return false
end

function onMinionsDeath(gear)
	if not (GetHealth(minion1.gear) or GetHealth(minion2.gear) or GetHealth(minion3.gear)) then
		return true
	end
	return false
end

function onProfessorAndMinionsDeath(gear)
	if professor.dead and (not (GetHealth(minion1.gear) or GetHealth(minion2.gear) or GetHealth(minion3.gear))) then
		return true
	end
	return false
end

-------------- ACTIONS ------------------

function weaponsPlatform(gear)
	if not battleZoneReached then
		-- Player entered weapons platform before entering battle zone.
		-- Checkpoint and dialog!
		saveCheckpoint("2")
		SaveCampaignVar("HeroHealth",GetHealth(hero.gear))
		EndTurn(true)
		weaponsAcquired = true
		SetWind(60)
		GameFlags = bor(GameFlags,gfDisableWind)
		AddAmmo(hero.gear, amRope, 0)
		AddAmmo(hero.gear, amSkip, 100)
		if GetX(hero.gear) < 1900 then
			AddAnim(dialog02)
		end
	end
	-- The player may screw up by going into the battle zone too early (dialog03).
	-- In that case, the player is punished for this stupid move (no checkpoint),
	-- but it is still theoretically possible to win by going for the weapons
	-- very fast.
end

function heroDeath(gear)
	SendStat(siGameResult, string.format(loc("%s lost, try again!"), hero.name))
	SendStat(siCustomAchievement, loc("You have to get the weapons and rescue the PAotH researchers."))
	sendSimpleTeamRankings({teamC.name, teamB.name, teamD.name, teamA.name})
	EndGame()
end

function battleZone(gear)
	battleZoneReached = true
	AddAmmo(hero.gear, amSkip, 100)
	EndTurn(true)
	if weaponsAcquired then
		AddAnim(dialog04)
	else
		AddAnim(dialog03)
	end
end

function professorHit(gear)
	if currentHedgehog ~= hero.gear then
		AnimSay(professor.gear,loc("Don't hit me, you fools!"), SAY_SHOUT, 2000)
	end
end

function victory()
	AnimCaption(hero.gear, loc("Congrats! You won!"), 6000)
	saveCompletedStatus(1)
	SendStat(siGameResult, string.format(loc("%s wins, congratulations!"), hero.name))
	sendSimpleTeamRankings({teamD.name, teamA.name, teamC.name, teamB.name})
	SaveCampaignVar("CosmosCheckPoint", "5") -- hero got fuels
	resetCheckpoint() -- reset this mission
	gameOver = true
	EndGame()
end

function professorAndMinionsDeath(gear)
	if gameOver then return end
	SendStat(siCustomAchievement, loc("You have eliminated the whole evil team. You're pretty tough!"))

	SaveCampaignVar("ProfDiedOnMoon", "1")
	victory()
end

function professorDeath(gear)
	if gameOver then return end
	local m1h = GetHealth(minion1.gear)
	local m2h = GetHealth(minion2.gear)
	local m3h = GetHealth(minion3.gear)
	if m1h == 0 or m2h == 0 or m3h == 0 then return end

	if m1h and m1h > 0 and StoppedGear(minion1.gear) then
		Dialog06Setup(minion1.gear)
	elseif m2h and m2h > 0 and StoppedGear(minion2.gear) then
		Dialog06ASetup(minion2.gear)
	elseif m3h and m3h > 0 and StoppedGear(minion3.gear) then
		Dialog06Setup(minion3.gear)
	end
	AddAnim(dialog06)
end

function afterDialog06()
	EndTurn(true)
	SendStat(siCustomAchievement, loc("You have eliminated Professor Hogevil."))
	SendStat(siCustomAchievement, loc("You drove the minions away."))
	SaveCampaignVar("ProfDiedOnMoon", "1")
	victory()
end

function afterDialog05()
	EndTurn(true)
	HideHog(professor.gear)
	SendStat(siCustomAchievement, loc("You have eliminated the evil minions."))
	SendStat(siCustomAchievement, loc("You drove Professor Hogevil away."))

	SaveCampaignVar("ProfDiedOnMoon", "0")
	victory()
end

function minionsDeath(gear)
	if professor.dead or GetHealth(professor.gear) == nil or GetHealth(professor.gear) == 0 then return end
	if gameOver then return end
	AddAnim(dialog05)
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
	end
	if anim == dialog01 then
		AnimSwitchHog(hero.gear)
	elseif anim == dialog02 then
		setAfterDialog02()
		AnimSwitchHog(hero.gear)
	elseif anim == dialog03 or anim == dialog04 then
		startCombat()
	elseif anim == dialog05 then
		runaway(professor.gear)
		afterDialog05()
	elseif anim == dialog06 then
		runaway(minion1.gear)
		runaway(minion2.gear)
		runaway(minion3.gear)
		afterDialog06()
	end
end

function AnimationSetup()
	-- DIALOG 01 - Start, welcome to moon
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Near a PAotH base on the moon ..."),  4000}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, string.format(loc("Hey, %s! Finally you have come!"), hero.name), SAY_SAY, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("It seems that Professor Hogevil has prepared for your arrival!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("He has captured the rest of the PAotH team and awaits to capture you!"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("We have to hurry! Are you armed?"), SAY_SAY, 4300}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 450}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("No, I am afraid I had to travel light."), SAY_SAY, 2500}})
	table.insert(dialog01, {func = AnimWait, args = {paoth1.gear, 3200}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("Okay, then you have to go and take some of the weapons we have hidden in case of an emergency!"), SAY_SAY, 7000}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("They are up there! Take this rope and hurry!"), SAY_SAY, 7000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Ehm, okay ..."), SAY_SAY, 2500}})
	table.insert(dialog01, {func = ShowMission, args = goals[dialog01]})
	table.insert(dialog01, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG 02 - To the weapons platform
	AddSkipFunction(dialog02, Skipanim, {dialog02})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 100}})
	table.insert(dialog02, {func = AnimCaption, args = {hero.gear, loc("Checkpoint reached!"), 4000}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("I've made it! Yeah!"), SAY_SHOUT, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {paoth1.gear, loc("Nice! Now hurry and get down! You have to rescue my friends!"), SAY_SHOUT, 7000}})
	table.insert(dialog02, {func = setAfterDialog02, args = {}})
	table.insert(dialog02, {func = ShowMission, args = goals[dialog02]})
	table.insert(dialog02, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG 03 - Hero spotted and has no weapons
	AddSkipFunction(dialog03, Skipanim, {dialog03})
	table.insert(dialog03, {func = AnimCaption, args = {hero.gear, loc("Get ready to fight!"), 4000}})
	table.insert(dialog03, {func = AnimSay, args = {minion1.gear, loc("Look, boss! There is the target!"), SAY_SHOUT, 4000}})
	table.insert(dialog03, {func = AnimSay, args = {professor.gear, loc("Prepare for battle!"), SAY_SHOUT, 4000}})
	table.insert(dialog03, {func = AnimSay, args = {hero.gear, loc("Oops, I've been spotted and I have no weapons! I am doomed!"), SAY_THINK, 4000}})
	table.insert(dialog03, {func = ShowMission, args = goals[dialog03]})
	table.insert(dialog03, {func = startCombat, args = {hero.gear}})
	-- DIALOG 04 - Hero spotted and *HAS* weapons
	AddSkipFunction(dialog04, Skipanim, {dialog04})
	table.insert(dialog04, {func = AnimCaption, args = {hero.gear, loc("Get ready to fight!"), 4000}})
	table.insert(dialog04, {func = AnimSay, args = {minion1.gear, loc("Look, boss! There is the target!"), SAY_SHOUT, 4000}})
	table.insert(dialog04, {func = AnimSay, args = {professor.gear, loc("Prepare for battle!"), SAY_SHOUT, 4000}})
	table.insert(dialog04, {func = AnimSay, args = {hero.gear, loc("Here we go!"), SAY_THINK, 4000}})
	table.insert(dialog04, {func = ShowMission, args = goals[dialog04]})
	table.insert(dialog04, {func = startCombat, args = {hero.gear}})
	-- DIALOG 05 - All minions dead
	AddSkipFunction(dialog05, Skipanim, {dialog05})
	table.insert(dialog05, {func = AnimWait, args = {professor.gear, 1500}})
	table.insert(dialog05, {func = AnimSay, args = {professor.gear, loc("I may lost this battle, but I haven't lost the war yet!"), SAY_SHOUT, 5000}})
	table.insert(dialog05, {func = runaway, args = {professor.gear}})
	table.insert(dialog05, {func = afterDialog05, args = {professor.gear}})
end

function Dialog06Setup(livingMinion)
	-- DIALOG 06 - Professor dead
	AddSkipFunction(dialog06, Skipanim, {dialog06})
	table.insert(dialog06, {func = AnimWait, args = {livingMinion, 1500}})
	table.insert(dialog06, {func = AnimSay, args = {livingMinion, loc("The boss has fallen! Retreat!"), SAY_SHOUT, 3000}})
	table.insert(dialog06, {func = runaway, args = {minion1.gear}})
	table.insert(dialog06, {func = runaway, args = {minion2.gear}})
	table.insert(dialog06, {func = runaway, args = {minion3.gear}})
	table.insert(dialog06, {func = afterDialog06, args = {livingMinion}})
end

function runaway(gear)
	if GetHealth(gear) then
		AddVisualGear(GetX(gear)-5, GetY(gear)-5, vgtSmoke, 0, false)
		AddVisualGear(GetX(gear)+5, GetY(gear)+5, vgtSmoke, 0, false)
		AddVisualGear(GetX(gear)-5, GetY(gear)+5, vgtSmoke, 0, false)
		AddVisualGear(GetX(gear)+5, GetY(gear)-5, vgtSmoke, 0, false)
		SetState(gear, bor(GetState(gear), gstInvisible))
	end
end

------------------- custom "animation" functions --------------------------

function startCombat()
	-- use this so minion3 will gain control
	AnimSwitchHog(minion3.gear)
	EndTurn(true)
end

function setAfterDialog02()
	afterDialog02 = true
end

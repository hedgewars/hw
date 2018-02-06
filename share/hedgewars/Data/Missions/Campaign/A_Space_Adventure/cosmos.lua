------------------- ABOUT ----------------------
--
-- This map works as a menu for the hero hog to
-- navigate through planets. It portrays the hogs
-- planet and above the planets that he'll later
-- visit.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("Spacetrip")
local timeForGuard1ToTurn = 1000 * 5 -- 5 sec
local timeForGuard1ToTurnLeft = timeForGuard1ToTurn
local saucerAcquired = false
local status
local getReadyForRumble = false -- guards wake up
local ropeDestroyed = false -- for detecting if player roped to the moon
local ropedToMoon = 0
local checkPointReached = 1 -- 1 is start of the game
-- dialogs
local dialog01 = {}
local dialog02 = {}
local dialog03 = {}
local dialog04 = {}
local dialog05 = {}
local dialog06 = {}
local dialog07 = {}
local dialog08 = {}
local dialog09 = {}
-- mission objectives
local goals = {
	["init"] = {missionName, loc("Getting ready"), loc("Help Hog Solo to find all the parts of the anti-gravity device.")..
	"|"..loc("Travel to all the neighbor planets and collect all the pieces"), 1, 0},
	[dialog01] = {missionName, loc("Getting ready"), loc("Go and collect the crate").."|"..loc("Try not to get spotted by the guards!"), 1, 4500},
	[dialog02] = {missionName, loc("The adventure begins!"), loc("Use the saucer and fly to the moon").."|"..loc("Travel carefully as your fuel is limited"), 1, 4500},
	[dialog03] = {missionName, loc("An unexpected event!"), loc("Use the saucer and fly away").."|"..loc("Beware, any damage taken will stay until you complete the moon's main mission"), 1, 7000},
	[dialog07] = {missionName, loc("Searching the stars!"), loc("Use the saucer and fly away").."|"..loc("Visit the planets of Ice, Desert and Fruit before you proceed to the Death Planet"), 1, 6000},
	[dialog08] = {missionName, loc("Saving Hogera"), loc("Fly to the meteorite and detonate the explosives"), 1, 7000},
	["open_side_missions"] = {missionName, loc("Conquering the galaxy"),
		loc("Use the flying saucer to fly to the other planets.").."|"..
		loc("Complete the remaining side missions to complete this mission.").."|"..
		loc("One flower: Incomplete side missions").."|"..
		loc("Two flowers: All missions complete"), 1, 8000},
	["free"] = {missionName, loc("Spacetrip"), loc("Use the flying saucer to fly to the other planets."), 1, 5000}
}
-- crates
local saucerX = 3270
local saucerY = 1500
-- hogs
local hero = {}
local director = {}
local doctor = {}
local guard1 = {}
local guard2 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
-- to check if flying saucer is active
local saucerGear = nil
-- if player abandoned any incomplete planet mission
local abandonedPlanetMission = false
-- hedgehogs values
hero.name = loc("Hog Solo")
hero.x = 1450
hero.y = 1550
director.name = loc("H")
director.x = 1350
director.y = 1550
doctor.name = loc("Dr. Cornelius")
doctor.x = 1300
doctor.y = 1550
guard1.name = loc("Bob")
guard1.x = 3350
guard1.y = 1800
guard1.turn = false
guard1.keepTurning = true
guard2.name = loc("Sam")
guard2.x = 3400
guard2.y = 1800
-- Planetary Association of the Hedgehogs
teamA.name = loc("PAotH")
teamA.color = 0x38D61C -- green
teamB.name = loc("Guards")
teamB.color = 0x0072FF -- blue
teamC.name = loc("Hog Solo")
teamC.color = 0x38D61C -- green

-------------- LuaAPI EVENT HANDLERS ------------------
function onGameInit()
	Seed = 35
	GameFlags = gfSolidLand + gfDisableWind + gfTagTeam
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0
	Delay = 5
	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0
	-- completed main missions
	status = getCompletedStatus()
	if status.death01 then
		Map = "cosmos2_map"
	else
		Map = "cosmos_map" -- custom map included in file
	end
	Theme = "Nature"
	-- I had originally hero in PAotH team and changed it, may reconsider though
	-- PAotH
	AddTeam(teamC.name, teamC.color, "Simple", "Island", "Default", "hedgewars")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	AddTeam(teamA.name, teamA.color, "Earth", "Island", "Default", "cm_galaxy")
	director.gear = AddHog(director.name, 0, 100, "hair_yellow")
	AnimSetGearPosition(director.gear, director.x, director.y)
	doctor.gear = AddHog(doctor.name, 0, 100, "Glasses")
	AnimSetGearPosition(doctor.gear, doctor.x, doctor.y)
	-- Guards
	AddTeam(teamB.name, teamB.color, "Statue", "Island", "Default", "cm_swordshield2")
	guard1.gear = AddHog(guard1.name, 1, 100, "policecap")
	AnimSetGearPosition(guard1.gear, guard1.x, guard1.y)
	guard2.gear = AddHog(guard2.name, 1, 100, "policecap")
	AnimSetGearPosition(guard2.gear, guard2.x, guard2.y)
	-- get the check point
	if tonumber(GetCampaignVar("CosmosCheckPoint")) then
		checkPointReached = tonumber(GetCampaignVar("CosmosCheckPoint"))
	end
	if checkPointReached == 4 then
		-- Disable walking as long we're stuck on the moon
		GameFlags = bor(GameFlags, gfArtillery)
	end
	-- Whether to start with an animation
	local startSequence
	-- do checkpoint stuff needed before game starts
	if checkPointReached == 1 then
		-- Start of the game
		startSequence = true
	elseif checkPointReached == 2 then
		-- Hero on the column, just took space ship unnoticed
		startSequence = true
		AnimSetGearPosition(hero.gear, saucerX, saucerY)
	elseif checkPointReached == 3 then
		-- Hero near column, without space ship unnoticed
		startSequence = true
	elseif checkPointReached == 4 then
		-- Hero visited moon for fuels
		startSequence = true
		AnimSetGearPosition(hero.gear, 1110, 850)
	elseif checkPointReached == 5 then
		startSequence = false
		-- Hero has visited a planet, he has plenty of fuels and can change planet
		if GetCampaignVar("Planet") == "moon" then
			AnimSetGearPosition(hero.gear, 1110, 850)
		elseif GetCampaignVar("Planet") == "desertPlanet" then
			AnimSetGearPosition(hero.gear, 3670, 270)
		elseif GetCampaignVar("Planet") == "fruitPlanet" then
			AnimSetGearPosition(hero.gear, 2400, 375)
		elseif GetCampaignVar("Planet") == "icePlanet" then
			AnimSetGearPosition(hero.gear, 1440, 260)
		elseif GetCampaignVar("Planet") == "deathPlanet" then
			AnimSetGearPosition(hero.gear, 620, 530)
		elseif GetCampaignVar("Planet") == "meteorite" then
			AnimSetGearPosition(hero.gear, 3080, 850)
		end
	end
	AnimInit(startSequence)

	-- Reset checkpoint of other missions when entering this mission.
	-- The player has left the planet, so we count that “abandoning” any incomplete missions.
	-- This also allows the player (indirectly) to reset the checkpointed missions.
	abandonedPlanetMission = resetCheckpoint()

	AnimationSetup()
end

function onGameStart()
	-- wait for the first turn to start
	AnimWait(hero.gear, 3000)

	FollowGear(hero.gear)
	if GetCampaignVar("Won") == "true" then
		if GetCampaignVar("Mission1Won") == "true" then
			ShowMission(unpack(goals["free"]))
		else
			ShowMission(unpack(goals["open_side_missions"]))
		end
	else
		ShowMission(unpack(goals["init"]))
	end

	-- do checkpoint stuff needed after game starts
	if checkPointReached == 1 then
		AddAnim(dialog01)
		AddAmmo(hero.gear, amRope, 1)
		AddAmmo(guard1.gear, amDEagle, 100)
		AddAmmo(guard2.gear, amDEagle, 100)
		SpawnUtilityCrate(saucerX, saucerY, amJetpack)
		-- EVENT HANDLERS
		AddEvent(onHeroBeforeTreePosition, {hero.gear}, heroBeforeTreePosition, {hero.gear}, 0)
		AddEvent(onHeroAcquiredSaucer, {hero.gear}, heroAcquiredSaucer, {hero.gear}, 1)
		AddEvent(onHeroOutOfGuardSight, {hero.gear}, heroOutOfGuardSight, {hero.gear}, 0)
	elseif checkPointReached == 2 then
		AddAmmo(hero.gear, amJetpack, 1)
		AddAnim(dialog02)
	elseif checkPointReached == 3 then
		-- Hero near column, without space ship unnoticed
	elseif checkPointReached == 4 then
		-- Hero visited moon for fuels
		AddAnim(dialog05)
	elseif checkPointReached == 5 then
		-- Hero has visited a planet, he has plenty of fuels and can change planet
		AddAmmo(hero.gear, amJetpack, 100)
	end

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onNoFuelAtLand, {hero.gear}, noFuelAtLand, {hero.gear}, 0)
	-- always check for landings
	if GetCampaignVar("Planet") ~= "moon" then
		AddEvent(onMoonLanding, {hero.gear}, moonLanding, {hero.gear}, 0)
	end
	if GetCampaignVar("Planet") ~= "desertPlanet" then
		AddEvent(onDesertPlanetLanding, {hero.gear}, desertPlanetLanding, {hero.gear}, 0)
	end
	if GetCampaignVar("Planet") ~= "fruitPlanet" then
		AddEvent(onFruitPlanetLanding, {hero.gear}, fruitPlanetLanding, {hero.gear}, 0)
	end
	if GetCampaignVar("Planet") ~= "icePlanet" then
		AddEvent(onIcePlanetLanding, {hero.gear}, icePlanetLanding, {hero.gear}, 0)
	end
	if GetCampaignVar("Planet") ~= "deathPlanet" then
		AddEvent(onDeathPlanetLanding, {hero.gear}, deathPlanetLanding, {hero.gear}, 0)
	end

	if status.death01 and not status.final then
		AddAnim(dialog08)
		if GetCampaignVar("Planet") ~= "meteorite" then
			AddEvent(onMeteoriteLanding, {hero.gear}, meteoriteLanding, {hero.gear}, 0)
		end
	end

	SendHealthStatsOff()
end

function onGameTick()
	-- maybe alert this to avoid timeForGuard1ToTurnLeft overflow
	if timeForGuard1ToTurnLeft == 0 and guard1.keepTurning then
		guard1.turn = not guard1.turn
		HogTurnLeft(guard1.gear, guard1.turn)
		timeForGuard1ToTurnLeft = timeForGuard1ToTurn
	end
	timeForGuard1ToTurnLeft = timeForGuard1ToTurnLeft - 1
	AnimUnWait()
	if ShowAnimation() == false then
		return
	end
	ExecuteAfterAnimations()
	CheckEvents()
end

function onGameTick20()
	setFoundDeviceVisual()
end

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)
	end
end

function onAmmoStoreInit()
	SetAmmo(amJetpack, 0, 0, 0, 1)
end

local abandonCheck = false

function onNewTurn()
	if ropedToMoon == 1 then
		AnimSetInputMask(0)
		sendStatsOnRopedToMoon()
		return
	end
	if saucerAcquired then
		-- The only way for the player to have a saucer at turn start is by having used the rope
		-- before; there's no other way to get it. We can therefore conclude the rope has been
		-- used.
		ropeDestroyed = true
	end
	if not abandonCheck and checkPointReached == 5 then
		if abandonedPlanetMission then
			HogSay(hero.gear, loc("I just forgot all checkpoints of incomplete missions."), SAY_THINK)
		end
		abandonCheck = true
	end

	if CurrentHedgehog == hero.gear then
		-- Hero just got spotted by guards
		if getReadyForRumble then
			EndTurn(true)
			getReadyForRumble = false
		else
			if guard1.keepTurning then
				TurnTimeLeft = -1
			end
		end
	elseif CurrentHedgehog == director.gear or CurrentHedgehog == doctor.gear then
		EndTurn(true)
	elseif (CurrentHedgehog == guard1.gear or CurrentHedgehog == guard2.gear) and guard1.keepTurning then
		EndTurn(true)
	end

end

-------------- EVENTS ------------------

function onHeroBeforeTreePosition(gear)
	if GetHealth(hero.gear) and GetX(gear) > 2350 then
		return true
	end
	return false
end

function onGearAdd(gear)
	if GetGearType(gear) == gtJetpack then
		saucerGear = gear
	end
end

function onGearDelete(gear)
	if GetGearType(gear) == gtCase and band(GetGearMessage(gear), gmDestroy) ~= 0 then
		saucerAcquired = true
	elseif GetGearType(gear) == gtJetpack then
		saucerGear = nil
	end
end

function onHeroOutOfGuardSight(gear)
	if GetHealth(hero.gear) and GetX(gear) < 3100 and GetY(gear) > saucerY-25 and StoppedGear(gear) and not guard1.keepTurning then
		return true
	end
	return false
end

function onMoonLanding(gear)
	if GetHealth(hero.gear) and GetX(gear) > 1010 and GetX(gear) < 1220  and GetY(gear) < 1300 and GetY(gear) > 750 and StoppedGear(gear) then
		return true
	end
	return false
end

function onFruitPlanetLanding(gear)
	if GetHealth(hero.gear) and GetX(gear) > 2240 and GetX(gear) < 2540  and GetY(gear) < 1100 and StoppedGear(gear) then
		return true
	end
	return false
end

function onDesertPlanetLanding(gear)
	if GetHealth(hero.gear) and GetX(gear) > 3568 and GetX(gear) < 4052  and GetY(gear) < 500 and StoppedGear(gear) then
		return true
	end
	return false
end

function onIcePlanetLanding(gear)
	if GetHealth(hero.gear) and GetX(gear) > 1330 and GetX(gear) < 1650  and GetY(gear) < 500 and StoppedGear(gear) then
		return true
	end
	return false
end

function onDeathPlanetLanding(gear)
	if GetHealth(hero.gear) and GetX(gear) > 280 and GetX(gear) < 700  and GetY(gear) < 720 and StoppedGear(gear) then
		return true
	end
	return false
end

function onMeteoriteLanding(gear)
	if GetHealth(hero.gear) and GetX(gear) > 2990 and GetX(gear) < 3395  and GetY(gear) < 940 and StoppedGear(gear) then
		return true
	end
	return false
end

function onNoFuelAtLand(gear)
	if checkPointReached > 1 and GetHealth(hero.gear) and GetY(gear) > 1400 and
			GetAmmoCount(gear, amJetpack) == 0 and saucerGear == nil and StoppedGear(gear) then
		return true
	end
	return false
end

function onHeroDeath(gear)
	if not GetHealth(hero.gear) then
		return true
	end
	return false
end

-------------- ACTIONS ------------------

function heroBeforeTreePosition(gear)
	if band(GetState(gear), gstHHDriven) ~= 0 then
		AnimSay(gear,loc("Now I have to climb these trees"), SAY_SAY, 4000)
		AnimCaption(hero.gear, loc("Use the rope to get to the crate"),  4000)
	end
end

function prepareDialog02(gear)
	if StoppedGear(gear) and guard1.keepTurning and checkPointReached < 2 then
		SetGearMessage(gear, band(GetGearMessage(gear), bnot(gmLeft+gmRight+gmUp+gmDown+gmPrecise)))
		EndTurn(true)
		-- save check point
		SaveCampaignVar("CosmosCheckPoint", "2")
		checkPointReached = 2
		AddAnim(dialog02)

		RemoveEventFunc(onHeroAcquiredSaucer)
	end
end

function heroAcquiredSaucer(gear)
	-- check if he was spotted by the guard
	if guard1.turn and guard1.keepTurning and GetX(gear) > saucerX-150 then
		guard1.keepTurning = false
		SetGearMessage(gear, band(GetGearMessage(gear), bnot(gmLeft+gmRight+gmUp+gmDown+gmPrecise)))
		local _, dy = GetGearVelocity(gear)
		SetGearVelocity(gear, 0, dy)
		AddAnim(dialog03)
	end

	prepareDialog02(gear)
end

function onHeroAcquiredSaucer(gear)
	return saucerAcquired
end

function heroOutOfGuardSight(gear)
	SetGearMessage(gear, 0)
	guard1.keepTurning = true
	AddAnim(dialog04)

	if onHeroAcquiredSaucer(gear) then
		prepareDialog02(gear)
	end
end

function moonLanding(gear)
	if checkPointReached == 1 and not ropeDestroyed then
		-- Player climbed the moon with rope.
		-- THIS IS A CRIMINAL OFFENSE AND WILL BE PUNISHED!
		ropedToMoon = 1
		SetGearVelocity(gear, 0, 0)
		SetGearMessage(gear, 0)
		AnimSetInputMask(0)
		AddAnim(dialog09)
	else
		if checkPointReached ~= 5 then
			SaveCampaignVar("CosmosCheckPoint", "4")
			SaveCampaignVar("HeroHealth",GetHealth(hero.gear))
		end
		AnimCaption(hero.gear,loc("Welcome to the moon!"))
		TurnTimeLeft = -1
		SaveCampaignVar("HeroHealth", GetHealth(hero.gear))
		SaveCampaignVar("Planet", "moon")
		SaveCampaignVar("UnlockedMissions", "3")
		SaveCampaignVar("Mission1", "2")
		SaveCampaignVar("Mission2", "13")
		SaveCampaignVar("Mission3", "1")
		sendStats(loc("Hog Solo arrived at the moon!"))
	end
end

function punishHeroForRopingToMoon(gear)
	-- Initiate the secret PAotH anti-rope defense system (5 bazookas dropped from sky)
	AddGear(GetX(gear), 100, gtShell, 0, 0, 0, 0)
	AddGear(GetX(gear), 0, gtShell, 0, 0, 0, 0)
	AddGear(GetX(gear), -100, gtShell, 0, 0, 0, 0)
	AddGear(GetX(gear), -200, gtShell, 0, 0, 0, 0)
	AddGear(GetX(gear), -300, gtShell, 0, 0, 0, 0)
	FollowGear(hero.gear)
	AnimSetInputMask(0)
end

function fruitPlanetLanding(gear)
	if checkPointReached < 5 then
		AddAnim(dialog06)
	else
		AnimCaption(hero.gear,loc("Welcome to the Fruit Planet!"))
		SaveCampaignVar("Planet", "fruitPlanet")
		if status.fruit01 then
			SaveCampaignVar("UnlockedMissions", "4")
			SaveCampaignVar("Mission1", "8")
			SaveCampaignVar("Mission2", "3")
			SaveCampaignVar("Mission3", "10")
			SaveCampaignVar("Mission4", "1")
		else
			SaveCampaignVar("UnlockedMissions", "3")
			SaveCampaignVar("Mission1", "3")
			SaveCampaignVar("Mission2", "10")
			SaveCampaignVar("Mission3", "1")
		end
		sendStats(loc("Hog Solo arrived at the Fruit Planet!"))
	end
end

function desertPlanetLanding(gear)
	if checkPointReached < 5 then
		AddAnim(dialog06)
	else
		AnimCaption(hero.gear,loc("Welcome to the Desert Planet!"))
		SaveCampaignVar("Planet", "desertPlanet")
		SaveCampaignVar("UnlockedMissions", "4")
		SaveCampaignVar("Mission1", "4")
		SaveCampaignVar("Mission2", "7")
		SaveCampaignVar("Mission3", "12")
		SaveCampaignVar("Mission4", "1")
		sendStats(loc("Hog Solo arrived at the Desert Planet!"))
	end
end

function icePlanetLanding(gear)
	if checkPointReached < 5 then
		AddAnim(dialog06)
	else
		AnimCaption(hero.gear,loc("Welcome to the Planet of Ice!"))
		SaveCampaignVar("Planet", "icePlanet")
		SaveCampaignVar("UnlockedMissions", "3")
		SaveCampaignVar("Mission1", "5")
		SaveCampaignVar("Mission2", "6")
		SaveCampaignVar("Mission3", "1")
		sendStats(loc("Hog Solo arrived at the Ice Planet!"))
	end
end

function deathPlanetLanding(gear)
	if checkPointReached < 5 then
		AddAnim(dialog06)
	elseif not (status.fruit02 and status.ice01 and status.desert01) then
		AddAnim(dialog07)
	else
		AnimCaption(hero.gear,loc("Welcome to the Death Planet!"))
		SaveCampaignVar("Planet", "deathPlanet")
		SaveCampaignVar("UnlockedMissions", "3")
		SaveCampaignVar("Mission1", "9")
		SaveCampaignVar("Mission2", "11")
		SaveCampaignVar("Mission3", "1")
		sendStats(loc("Hog Solo arrived at the Planet of Death!"))
	end
end

function meteoriteLanding(gear)
	-- first two conditionals are not possible but I'll leave it there...
	if checkPointReached < 5 then
		AddAnim(dialog06)
	elseif not (status.fruit02 and status.ice01 and status.desert01) then
		AddAnim(dialog07)
	else
		AnimCaption(hero.gear,loc("Welcome to the meteorite!"))
		SaveCampaignVar("Planet", "meteorite")
		SaveCampaignVar("UnlockedMissions", "2")
		SaveCampaignVar("Mission1", "14")
		SaveCampaignVar("Mission2", "1")
		sendStats(loc("Hog Solo arrived at the meteorite!"))
	end
end

function noFuelAtLand(gear)
	AddAnim(dialog06)
end

function heroDeath(gear)
	if ropedToMoon == 1 then
		sendStatsOnRopedToMoon()
	elseif ropedToMoon == 0 then
		sendStatsOnRetry()
	end
end

function setFoundDeviceVisual()
	--WriteLnToConsole("status: "..status.fruit01.." - "..status.fruit02)
	if status.moon01 then
		vgear = AddVisualGear(1116, 848, vgtBeeTrace, 0, false)
		if status.moon02 then
			vgear = AddVisualGear(1116, 828, vgtBeeTrace, 0, false)
		end
	end
	if status.ice01 then
		vgear = AddVisualGear(1512, 120, vgtBeeTrace, 0, false)
		if status.ice02 then
			vgear = AddVisualGear(1512, 100, vgtBeeTrace, 0, false)
		end
	end
	if status.desert01 then
		vgear = AddVisualGear(4015, 316, vgtBeeTrace, 0, false)
		if status.desert02 and status.desert03 then
			vgear = AddVisualGear(4015, 296, vgtBeeTrace, 0, false)
		end
	end
	if status.fruit01 and status.fruit02 then
		vgear = AddVisualGear(2390, 384, vgtBeeTrace, 0, false)
		if status.fruit03 then
			vgear = AddVisualGear(2390, 364, vgtBeeTrace, 0, false)
		end
	end
	if status.death01 then
		vgear = AddVisualGear(444, 400, vgtBeeTrace, 0, false)
		if status.death02 then
			vgear = AddVisualGear(444, 380, vgtBeeTrace, 0, false)
		end
	end
	if status.final then
		vgear = AddVisualGear(3070, 810, vgtBeeTrace, 0, false)
		vgear = AddVisualGear(3070, 790, vgtBeeTrace, 0, false)
	end
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
	end
	if anim == dialog09 then
		AnimSetInputMask(0)
		-- Quick punishment for the impatient
		AddGear(GetX(hero.gear)-1, GetY(hero.gear)+1, gtDynamite, 0, 0, 0, 1)
		sendStatsOnRopedToMoon()
	elseif anim == dialog05 then
		sendStatsOnStuckOnMoon()
	elseif anim == dialog06 then
		sendStatsOnRetry()
	elseif CurrentHedgehog ~= hero.gear and anim ~= dialog03 then
		AnimSwitchHog(hero.gear)
	elseif anim == dialog03 then
		startCombat()
	end
end

function AnimationSetup()
	-- DIALOG 01 - Start
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {doctor.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Near Secret Base 17 of PAotH in the rural Hogland ..."),  4000}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("So Hog Solo, here we are ..."), SAY_SAY, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("Behind these trees on the east side there is Secret Base 17."), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("You have to continue alone from now on."), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("Be careful, the future of Hogera is in your hands!"), SAY_SAY, 7200}})
	table.insert(dialog01, {func = AnimSay, args = {doctor.gear, loc("We'll use our communicators to contact you."), SAY_SAY, 2600}})
	table.insert(dialog01, {func = AnimSay, args = {doctor.gear, loc("In am also entrusting you with some rope."), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {doctor.gear, loc("You may find it handy."), SAY_SAY, 2300}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Thank you, Dr. Cornelius."), SAY_SAY, 1600}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("I'll make good use of it."), SAY_SAY, 4500}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("It would be wiser to steal the space ship while the PAotH guards are taking a brake!"), SAY_SAY, 7000}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("Remember! Many will seek the anti-gravity device! Now go, hurry up!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSwitchHog, args = {hero.gear}})
	table.insert(dialog01, {func = ShowMission, args = goals[dialog01]})
	-- DIALOG 02 - Hero got the saucer
	AddSkipFunction(dialog02, Skipanim, {dialog02})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog02, {func = AnimCaption, args = {hero.gear, loc("Checkpoint reached!"),  4000}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("Got the saucer!"), SAY_SHOUT, 2000}})
	table.insert(dialog02, {func = AnimSay, args = {director.gear, loc("Nice!"), SAY_SHOUT, 1000}})
	table.insert(dialog02, {func = AnimSay, args = {director.gear, loc("Now use it and go to the moon PAotH station to get more fuel!"), SAY_SHOUT, 5000}})
	table.insert(dialog02, {func = AnimGearWait, args = {hero.gear, 500}})
	table.insert(dialog02, {func = ShowMission, args = goals[dialog02]})
	-- DIALOG 03 - Hero got spotted by guard
	AddSkipFunction(dialog03, Skipanim, {dialog03})
	table.insert(dialog03, {func = AnimSay, args = {guard1.gear, string.format(loc("Hey, %s! Look, someone is stealing the saucer!"), guard2.name), SAY_SHOUT, 4000}})
	table.insert(dialog03, {func = AnimSay, args = {guard2.gear, loc("I'll get him!"), SAY_SAY, 4000}})
	table.insert(dialog03, {func = AnimCaption, args = {guard1.gear, loc("Prepare to flee!"), 1000}})
	table.insert(dialog03, {func = startCombat, args = {guard1.gear}})
	table.insert(dialog03, {func = ShowMission, args = goals[dialog03]})
	-- DIALOG 04 - Hero out of sight
	AddSkipFunction(dialog04, Skipanim, {dialog04})
	table.insert(dialog04, {func = AnimCaption, args = {guard1.gear, loc("You are out of danger, time to go to the moon!"),  4000}})
	table.insert(dialog04, {func = AnimSay, args = {guard1.gear, loc("I guess we lost him!"), SAY_SAY, 3000}})
	table.insert(dialog04, {func = AnimSay, args = {guard2.gear, loc("We should better report this and continue our watch!"), SAY_SAY, 5000}})
	table.insert(dialog04, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG 05 - Hero returned from moon without fuels
	AddSkipFunction(dialog05, Skipanim, {dialog05})
	table.insert(dialog05, {func = AnimSay, args = {hero.gear, loc("I guess I can't go far without fuel!"), SAY_THINK, 6000}})
	if abandonedPlanetMission then
		-- Hog solo is mad he has to play the moon main mission from start. Very sarcastic tone. ;-)
		table.insert(dialog05, {func = AnimSay, args = {hero.gear, loc("And I just forgot the checkpoint of my main mission. Great, just great!"), SAY_THINK, 7000}})
	end
	table.insert(dialog05, {func = AnimSay, args = {hero.gear, loc("Got to go back."), SAY_THINK, 2000}})
	table.insert(dialog05, {func = sendStatsOnStuckOnMoon, args = {hero.gear}})
	-- DIALOG 06 - Landing on wrong planet or on earth if not enough fuels
	AddSkipFunction(dialog06, Skipanim, {dialog06})
	table.insert(dialog06, {func = AnimSay, args = {hero.gear, loc("Hm ... Now I ran out of fuel."), SAY_THINK, 3000}})
	table.insert(dialog06, {func = AnimCaption, args = {hero.gear, loc("You have to try again!"), 0}})
	table.insert(dialog06, {func = sendStatsOnRetry, args = {hero.gear}})
	-- DIALOG 07 - Hero lands on Death Planet but isn't allowed yet to play this map
	AddSkipFunction(dialog07, Skipanim, {dialog07})
	table.insert(dialog07, {func = AnimCaption, args = {hero.gear, loc("This planet seems dangerous!"),  5000}})
	table.insert(dialog07, {func = AnimSay, args = {hero.gear, loc("I am not ready for this planet yet. I should visit it when I have found all the other device parts."), SAY_THINK, 4000}})
	-- DIALOG 08 - Hero wins death01
	AddSkipFunction(dialog08, Skipanim, {dialog08})
	table.insert(dialog08, {func = AnimCaption, args = {hero.gear, loc("Under the meteorite’s shadow ..."),  4000}})
	table.insert(dialog08, {func = AnimSay, args = {doctor.gear, loc("You did great, Hog Solo! However, we aren't out of danger yet!"), SAY_SHOUT, 4500}})
	table.insert(dialog08, {func = AnimSay, args = {doctor.gear, loc("The meteorite has come too close and the anti-gravity device isn't powerful enough to stop it now."), SAY_SHOUT, 5000}})
	table.insert(dialog08, {func = AnimSay, args = {doctor.gear, loc("We need it to get split into at least two parts."), SAY_SHOUT, 3000}})
	table.insert(dialog08, {func = AnimSay, args = {doctor.gear, loc("PAotH has sent explosives but unfortunately the trigger mechanism seems to be faulty!"), SAY_SHOUT, 5000}})
	table.insert(dialog08, {func = AnimSay, args = {doctor.gear, loc("We need you to go there and detonate them yourself! Good luck!"), SAY_SHOUT, 500}})
	table.insert(dialog08, {func = AnimWait, args = {doctor.gear, 3000}})
	table.insert(dialog08, {func = AnimSwitchHog, args = {hero.gear}})
	table.insert(dialog08, {func = ShowMission, args = goals[dialog08]})
	-- DIALOG 09 - Hero roped to the moon (how naughty!)
	AddSkipFunction(dialog09, Skipanim, {dialog09})
	table.insert(dialog09, {func = AnimSay, args = {doctor.gear, loc("One does not simply rope to the moon!"), SAY_SHOUT, 4500}})
	table.insert(dialog09, {func = punishHeroForRopingToMoon, args = {hero.gear}})
	table.insert(dialog09, {func = AnimWait, args = {hero.gear, 5000}})
	table.insert(dialog09, {func = sendStatsOnRopedToMoon, args = {hero.gear}})
end

------------------- custom "animation" functions --------------------------

function startCombat()
	-- Use this so guard2 gains control
	EndTurn(true)
	getReadyForRumble = true
end

function sendStats(planetMsg)
	SendStat(siGameResult, planetMsg)
	SendStat(siCustomAchievement, loc("Return to the mission menu by pressing the \"Go back\" button."))
	SendStat(siCustomAchievement, loc("You can choose another planet by replaying this mission."))
	SendStat(siCustomAchievement, loc("Planets with completed main missions will be marked with a flower."))
	SendStat(siCustomAchievement, loc("Planets with all missions completed will be marked with two flowers."))
	if GetCampaignVar("Won") == "true" and GetCampaignVar("Mission1Won") ~= "true" then
		SendStat(siCustomAchievement, loc("Complete all main and side missions to complete the spacetrip mission."))
	end
	sendSimpleTeamRankings({teamC.name})
	EndGame()
end

function sendStatsOnRetry()
	SendStat(siGameResult, loc("You have to travel again"))
	SendStat(siCustomAchievement, loc("Your first destination is the moon in order to get more fuel."))
	SendStat(siCustomAchievement, loc("You have to be careful and must not die!"))
	sendSimpleTeamRankings({teamC.name})
	EndGame()
end

function sendStatsOnStuckOnMoon()
	SendStat(siGameResult, loc("You have to go back to the moon!"))
	SendStat(siCustomAchievement, loc("You have to complete the main mission on moon in order to travel to other planets."))
	sendSimpleTeamRankings({teamC.name})
	EndGame()
end

function sendStatsOnRopedToMoon()
	if ropedToMoon ~= 2 then
		ropedToMoon = 2
		SendStat(siGameResult, loc("You have violated PAotH regulations!"))
		SendStat(siCustomAchievement, loc("You have triggered the secret Do-Not-Rope-to-the-Moon Defense System."))
		SendStat(siCustomAchievement, loc("Use the flying saucer from the crate to fly to the moon."))
		sendSimpleTeamRankings({teamC.name})
		EndGame()
	end
end

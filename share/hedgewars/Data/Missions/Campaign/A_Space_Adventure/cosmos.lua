------------------- ABOUT ----------------------
--
-- This map works as a menu for the hero hog to
-- navigate through planets. It portrays the hogs
-- planet and above the planets that he'll later
-- visit.

-- TODO
-- Save and Load All Check Points
-- Save hero health
-- Decide and implement if hero will use gas bombs...
-- ofc add custom stats page
-- PROBLEM : What if one makes a bad choice and wants to replay it map, how to reset?
-- POSSIBLE SOLUTIONS: In game function keys, frontend button...

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Cosmos")
local timeForGuard1ToTurn = 1000 * 5 -- 5 sec
local timeForGuard1ToTurnLeft = timeForGuard1ToTurn
local saucerAcquired = false
local checkPointReached = 1 -- 1 is start of the game
-- dialogs
local dialog01 = {}
local dialog02 = {}
local dialog03 = {}
local dialog04 = {}
local dialog05 = {}
local dialog06 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("Go and collect the crate on top of the column").."|"..loc("Use the sleep gas bomb if the guards spot you!"), 1, 4500},
	[dialog02] = {missionName, loc("The adventure begins!"), loc("Use the saucer and fly to the moon").."|"..loc("Drive carefully as your fuels are limited"), 1, 4500},
	[dialog03] = {missionName, loc("An unexpected event!"), loc("Use the saucer and fly away or use the gas bomb to neutralize the guards").."|"..loc("Beware, any damage taken will stay until you take some medicine or visit moon"), 1, 7000}
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
-- hedgehogs values
hero.name = loc("Hog Solo")
hero.x = 1450
hero.y = 1550
director.name = loc("H")
director.x = 1350
director.y = 1550
doctor.name = loc("Dr.Cornelius")
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
teamA.name = loc("PAoTH")
teamA.color = tonumber("FF0000",16) -- red
teamB.name = loc("Guards")
teamB.color = tonumber("0033FF",16) -- blue
teamC.name = loc("Hog Solo")
teamC.color = tonumber("38D61C",16) -- green

-------------- LuaAPI EVENT HANDLERS ------------------
function onGameInit()
	Seed = 35
	GameFlags = gfSolidLand + gfDisableWind
	TurnTime = 40000
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0
	Delay = 5
	Map = "cosmos_map" -- custom map included in file
	Theme = "Nature"
	-- I had originally hero in PAoTH team and changed it, may reconsider though
	-- PAoTH
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")	
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)	
	HogTurnLeft(hero.gear, true)
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")	
	director.gear = AddHog(director.name, 0, 100, "hair_yellow")
	AnimSetGearPosition(director.gear, director.x, director.y)
	doctor.gear = AddHog(doctor.name, 0, 100, "Glasses")
	AnimSetGearPosition(doctor.gear, doctor.x, doctor.y)
	-- Guards
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	guard1.gear = AddHog(guard1.name, 1, 100, "policecap")
	AnimSetGearPosition(guard1.gear, guard1.x, guard1.y)
	guard2.gear = AddHog(guard2.name, 1, 100, "policecap")
	AnimSetGearPosition(guard2.gear, guard2.x, guard2.y)
	
	-- get the check point
	if tonumber(GetCampaignVar("CosmosCheckPoint")) then
		checkPointReached = tonumber(GetCampaignVar("CosmosCheckPoint"))
	end
	-- do checkpoint stuff needed before game starts
	if checkPointReached == 1 then
		-- Start of the game
	elseif checkPointReached == 2 then
		-- Hero on the column, just took space ship unnoticed
		AnimSetGearPosition(hero.gear, saucerX, saucerY)
	elseif checkPointReached == 3 then
		-- Hero near column, without space ship unnoticed
	elseif checkPointReached == 4 then
		-- Hero visited moon for fuels
		AnimSetGearPosition(hero.gear, 1110, 850)
	elseif checkPointReached == 5 then
		-- Hero has visited a planet, he has plenty of fuels and can change planet
		if GetCampaignVar("Planet") == "moon" then
			AnimSetGearPosition(hero.gear, 1110, 850)
		elseif GetCampaignVar("Planet") == "desertPlanet" then
			AnimSetGearPosition(hero.gear, 3670, 270)
		elseif GetCampaignVar("Planet") == "fruitPlanet" then
			AnimSetGearPosition(hero.gear, 2400, 375)
		elseif GetCampaignVar("Planet") == "icePlanet" then
			AnimSetGearPosition(hero.gear, 1440, 260)
		end
	end
	
	AnimInit()
	AnimationSetup()
end

function onGameStart()
	-- wait for the first turn to start
	AnimWait(hero.gear, 3000)

	FollowGear(hero.gear)
	ShowMission(loc("A Space Adventure"), loc("Cosmos"), loc("Help Hog Solo to find all the parts of the anti-gravity device.")..
	"|"..loc("Travel to all the neighbor planets and collect all the pieces"), -amSkip, 0)
	
	-- do checkpoint stuff needed after game starts
	if checkPointReached == 1 then	
		AddAnim(dialog01)
		AddAmmo(hero.gear, amGasBomb, 5)
		AddAmmo(hero.gear, amRope, 2)
		-- Added for dev/debug purposes, remove before release
		AddAmmo(hero.gear, amJetpack, 2)
		AddAmmo(guard1.gear, amDEagle, 2)
		AddAmmo(guard2.gear, amDEagle, 2)
		SpawnAmmoCrate(saucerX, saucerY, amJetpack)	
		-- EVENT HANDLERS
		AddEvent(onHeroBeforeTreePosition, {hero.gear}, heroBeforeTreePosition, {hero.gear}, 0)
		AddEvent(onHeroAtSaucerPosition, {hero.gear}, heroAtSaucerPosition, {hero.gear}, 0)
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
		AddAmmo(hero.gear, amJetpack, 99)
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

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)   
	end
end

function onAmmoStoreInit()
	SetAmmo(amJetpack, 0, 0, 0, 1)
end

function onNewTurn()
	if CurrentHedgehog == director.gear or CurrentHedgehog == doctor.gear then
		TurnTimeLeft = 0
	end
	if guard1.keepTurning then
		AnimSwitchHog(hero.gear)
		TurnTimeLeft = -1
	end
end

-------------- EVENTS ------------------

function onHeroBeforeTreePosition(gear)
	if GetHealth(hero.gear) and GetX(gear) > 2350 then
		return true
	end
	return false
end

function onHeroAtSaucerPosition(gear)
	if GetHealth(hero.gear) and GetX(gear) >= saucerX-25 and GetX(gear) <= saucerX+32 and GetY(gear) >= saucerY-32 and GetY(gear) <= saucerY+32 then
		saucerAcquired = true
	end
	if saucerAcquired and GetHealth(hero.gear) and StoppedGear(gear) then
		return true
	end
	return false
end

function onHeroOutOfGuardSight(gear)
	if GetHealth(hero.gear) and GetX(gear) < 3100 and GetY(gear) > saucerY-25 and StoppedGear(gear) and not guard1.keepTurning then
		return true
	end
	return false
end

-- TODO somehow make it to count fall damage
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

function onNoFuelAtLand(gear)
	if GetHealth(hero.gear) and GetY(gear) > 1400 and GetAmmoCount(gear, amJetpack) == 0 and StoppedGear(gear) then
		return true
	end
	return false
end

function onHeroDeath(gear)
	if not GetHealth(gear) then
		return true
	end
	return false
end

-------------- OUTCOMES ------------------

function heroBeforeTreePosition(gear)
	AnimSay(gear,loc("Now I have to climb the trees"), SAY_SAY, 4000)
	AnimCaption(hero.gear, loc("Use the rope to get to the crate"),  4000)
end

function heroAtSaucerPosition(gear)
	TurnTimeLeft = 0
	-- save check point	
	SaveCampaignVar("CosmosCheckPoint", "2")
	AddAnim(dialog02)
	-- check if he was spotted by the guard
	if guard1.turn then
		guard1.keepTurning = false
		AddAnim(dialog03)
	end	
end

function heroOutOfGuardSight(gear)
	guard1.keepTurning = true
	AddAnim(dialog04)
end

function moonLanding(gear)
	AnimCaption(hero.gear,loc("Welcome to the moon!"))
	SaveCampaignVar("Planet", "moon")
	if checkPointReached ~= 5 then
		SaveCampaignVar("CosmosCheckPoint", "4")
		SaveCampaignVar("HeroHealth",GetHealth(hero.gear))
	end
	SaveCampaignVar("UnlockedMissions", "2")
	SaveCampaignVar("Mission1", "2")
	SaveCampaignVar("Mission2", "1")
	EndGame()
end

function fruitPlanetLanding(gear)
	if checkPointReached < 5 then
		AddAnim(dialog06)
	end
end

function desertPlanetLanding(gear)
	if checkPointReached < 5 then
		AddAnim(dialog06)
	else		
		AnimCaption(hero.gear,loc("Welcome to the desert planet!"))
		SaveCampaignVar("Planet", "desertPlanet")
		SaveCampaignVar("UnlockedMissions", "3")
		SaveCampaignVar("Mission1", "4")
		SaveCampaignVar("Mission2", "7")
		SaveCampaignVar("Mission3", "1")
		EndGame()
	end
end

function icePlanetLanding(gear)
	if checkPointReached < 5 then
		AddAnim(dialog06)
	else
		AnimCaption(hero.gear,loc("Welcome to the planet of ice!"))
		SaveCampaignVar("Planet", "icePlanet")
		SaveCampaignVar("UnlockedMissions", "3")
		SaveCampaignVar("Mission1", "5")
		SaveCampaignVar("Mission2", "6")
		SaveCampaignVar("Mission3", "1")
		EndGame()
	end
end

function noFuelAtLand(gear)
	AddAnim(dialog06)
end

function heroDeath(gear)
	EndGame()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
    if CurrentHedgehog ~= hero.gear and anim ~= dialog03 then
		AnimSwitchHog(hero.gear)
	elseif anim == dialog03 then
		startCombat()
	elseif anim == dialog05 or anim == dialog06 then
		EndGame()
	end
end

function AnimationSetup()
	-- DIALOG 01 - Start
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {doctor.gear, 3000}})
	--table.insert(dialog01, {func = AnimWait, args = {hero.gear, 2500}, skipFunc = Skipanim, skipArgs = dialog01})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Near secret base 17 of PAoTH in the rural Hogland..."),  4000}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("So Hog Solo, here we are..."), SAY_SAY, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("Behind these trees on the East there is secret base 17"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("You have to continue alone from now on."), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("Be careful, the future of Hogera is in your hands!"), SAY_SAY, 7200}})
	table.insert(dialog01, {func = AnimSay, args = {doctor.gear, loc("We'll use our communicators to contact you"), SAY_SAY, 2600}})
	table.insert(dialog01, {func = AnimSay, args = {doctor.gear, loc("In am also entrusting you with a rope and a sleep gas bomb"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {doctor.gear, loc("You may find them handy"), SAY_SAY, 2300}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Thank you Dr.Cornelius"), SAY_SAY, 1600}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("I'll make good use of them"), SAY_SAY, 4500}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("It would be wiser to steal the space ship while PAoTH guards are taking a brake!"), SAY_SAY, 7000}})
	table.insert(dialog01, {func = AnimSay, args = {director.gear, loc("Remember! Many will seek the anti-gravity device! Now go, hurry up!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG 02 - Hero got the saucer
	AddSkipFunction(dialog02, Skipanim, {dialog02})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog02, {func = AnimCaption, args = {hero.gear, loc("CheckPoint reached!"),  4000}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("Got the saucer!"), SAY_SHOUT, 2000}})
	table.insert(dialog02, {func = AnimSay, args = {director.gear, loc("Nice!"), SAY_SHOUT, 1000}})
	table.insert(dialog02, {func = AnimSay, args = {director.gear, loc("Now use it and go to the moon PAoTH station to get more fuels!"), SAY_SHOUT, 5000}})
    table.insert(dialog02, {func = AnimGearWait, args = {hero.gear, 500}})
    -- DIALOG 03 - Hero got spotted by guard
	AddSkipFunction(dialog03, Skipanim, {dialog03})
	table.insert(dialog03, {func = AnimWait, args = {guard1.gear, 4000}})
	table.insert(dialog03, {func = AnimCaption, args = {guard1.gear, loc("Prepare to battle or flee!"),  4000}})	
	table.insert(dialog03, {func = AnimSay, args = {guard1.gear, loc("Hey").." "..guard2.name.."! "..loc("Look, someone is stealing the saucer!"), SAY_SHOUT, 4000}})
	table.insert(dialog03, {func = AnimSay, args = {guard2.gear, loc("I'll get him!"), SAY_SAY, 4000}})
	table.insert(dialog03, {func = startCombat, args = {guard1.gear}})
	-- DIALOG 04 - Hero out of sight
	AddSkipFunction(dialog04, Skipanim, {dialog04})
	table.insert(dialog04, {func = AnimCaption, args = {guard1.gear, loc("You are out of danger, time to go to the moon!"),  4000}})
	table.insert(dialog04, {func = AnimSay, args = {guard1.gear, loc("I guess we lost him!"), SAY_SAY, 3000}})
	table.insert(dialog04, {func = AnimSay, args = {guard2.gear, loc("We should better report this and continue our watch!"), SAY_SAY, 5000}})
	table.insert(dialog04, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG 05 - Hero returned from moon without fuels
	AddSkipFunction(dialog05, Skipanim, {dialog05})
	table.insert(dialog05, {func = AnimSay, args = {hero.gear, loc("I guess I can't go far without fuels!"), SAY_THINK, 6000}})
	table.insert(dialog05, {func = AnimSay, args = {hero.gear, loc("Go to go back"), SAY_THINK, 2000}})
	table.insert(dialog05, {func = EndGame, args = {hero.gear}})
	-- DIALOG 06 - Landing on wrong planet or on earth if not enough fuels
	AddSkipFunction(dialog06, Skipanim, {dialog06})
	table.insert(dialog06, {func = AnimCaption, args = {hero.gear, loc("You have to try again!"),  5000}})
	table.insert(dialog06, {func = AnimSay, args = {hero.gear, loc("Hm... Now I run out of fuels..."), SAY_THINK, 3000}})
	table.insert(dialog06, {func = EndGame, args = {hero.gear}})
end

------------------- custom "animation" functions --------------------------

function startCombat()
	-- use this so guard2 will gain control
	AnimSwitchHog(hero.gear)
	TurnTimeLeft = 0
end

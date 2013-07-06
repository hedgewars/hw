------------------- ABOUT ----------------------
--
-- This is the first stop of hero's journey.
-- Here he'll get fuels to continue traveling.
-- However, the PAoTH allies of the hero have
-- been taken hostages by professor Hogevil.
-- So hero has to get whatever available equipement
-- there is and rescue them.

-- TODO
-- Fix some glitches when gaining control on animations
-- Round time after check point 2
-- Enemys take control
-- Continue with the rest :P

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Moon, stop for fuels!")
local weaponsAcquired = false
local checkPointReached = 1 -- 1 is start of the game
-- dialogs
local dialog01 = {}
local dialog02 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("Go to the upper platform and get the weapons in the crates!"), 1, 4500},
	[dialog02] = {missionName, loc("Prepare to fight"), loc("Go down and save these PAoTH hogs!"), 1, 5000}
}
-- crates
local weaponsY = 100
local bazookaX = 70
local parachuteX = 110
local grenadeX = 160
local deserteagleX = 200
local torchblowX = 3270
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
hero.name = "Hog Solo"
hero.x = 1380
hero.y = 1750
hero.dead = false
paoth1.name = "Joe"
paoth1.x = 1430
paoth1.y = 1750
paoth2.name = "Bruce"
paoth2.x = 3760
paoth2.y = 1800
paoth3.name = "Helena"
paoth3.x = 3800
paoth3.y = 1800
paoth4.name = "Boris"
paoth4.x = 3860
paoth4.y = 1800
professor.name = "Pr.Hogevil"
professor.x = 3710
professor.y = 1650
minion1.name = "Minion"
minion1.x = 2460
minion1.y = 1450
minion2.name = "Minion"
minion2.x = 2450
minion2.y = 1900
minion3.name = "Minion"
minion3.x = 3500
minion3.y = 1750
teamA.name = loc("PAoTH")
teamA.color = tonumber("FF0000",16) -- red
teamB.name = loc("Minions")
teamB.color = tonumber("0033FF",16) -- blue
teamC.name = loc("Professor")
teamC.color = tonumber("0033FF",16) -- blue
teamD.name = loc("Hog Solo")
teamD.color = tonumber("38D61C",16) -- green

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	GameFlags = gfSolidLand + gfDisableWind
	TurnTime = 45000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 3000
	Explosives = 0
	Delay = 5 
	Map = "moon01_map"
	Theme = "Cheese" -- Because ofc moon is made of cheese :)
	-- Hog Solo
	AddTeam(teamD.name, teamD.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	-- PAoTH
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
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
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	professor.gear = AddHog(professor.name, 0, 100, "tophats")
	AnimSetGearPosition(professor.gear, professor.x, professor.y)
	HogTurnLeft(professor.gear, true)
	-- Minions
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	minion1.gear = AddHog(minion1.name, 1, 100, "Gasmask")
	AnimSetGearPosition(minion1.gear, minion1.x, minion1.y)
	HogTurnLeft(minion1.gear, true)
	minion2.gear = AddHog(minion2.name, 1, 100, "Gasmask")
	AnimSetGearPosition(minion2.gear, minion2.x, minion2.y)
	HogTurnLeft(minion2.gear, true)
	minion3.gear = AddHog(minion3.name, 1, 100, "Gasmask")
	AnimSetGearPosition(minion3.gear, minion3.x, minion3.y)
	HogTurnLeft(minion3.gear, true)
	
	-- get the check point
	if tonumber(GetCampaignVar("Moon01CheckPoint")) then
		checkPointReached = tonumber(GetCampaignVar("Moon01CheckPoint"))
	end
	
	if checkPointReached == 1 then
		-- Start of the game
	elseif checkPointReached == 2 then
		AnimSetGearPosition(hero.gear, parachuteX, weaponsY)
	end
	
	AnimInit()
	AnimationSetup()	
end

function onGameStart()
	-- wait for the first turn to start
	AnimWait(hero.gear, 3000)

	FollowGear(hero.gear)
	
	ShowMission(campaignName, missionName, loc("Hog Solo has to refuel his saucer.")..
	"|"..loc("Rescue the imprisoned PAoTH team and get your fuels!"), -amSkip, 0)	
	
	-- check for death has to go first
	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)

	if checkPointReached == 1 then
		AddAmmo(hero.gear, amRope, 2)
		SpawnAmmoCrate(bazookaX, weaponsY, amBazooka)
		SpawnAmmoCrate(parachuteX, weaponsY, amParachute)
		SpawnAmmoCrate(grenadeX, weaponsY, amGrenade)
		SpawnAmmoCrate(deserteagleX, weaponsY, amDEagle)
		AddEvent(onWeaponsPlatform, {hero.gear}, weaponsPlatform, {hero.gear}, 0)
		AddAnim(dialog01)
	elseif checkPointReached == 2 then	
		AddAmmo(hero.gear, amBazooka, 2)
		AddAmmo(hero.gear, amParachute, 2)
		AddAmmo(hero.gear, amGrenade, 2)
		AddAmmo(hero.gear, amDEagle, 2)
		SetWind(80)		
		GameFlags = bor(GameFlags,gfDisableWind)
		weaponsAcquired = true
		AddAnim(dialog02)
	end
end

function onAmmoStoreInit()
	SetAmmo(amBazooka, 0, 0, 0, 2)
	SetAmmo(amParachute, 0, 0, 0, 2)
	SetAmmo(amGrenade, 0, 0, 0, 2)
	SetAmmo(amDEagle, 0, 0, 0, 2)
end

function onGameTick()
	AnimUnWait()
	if ShowAnimation() == false then
		return
	end
	ExecuteAfterAnimations()
	CheckEvents()
	if CurrentHedgehog ~= hero.gear then
		TurnTimeLeft = 0
	end
end

function onNewTurn()
	if not weaponsAcquired and CurrentHedgehog ~= hero.gear then
		TurnTimeLeft = 0
	elseif not weaponsAcquired and CurrentHedgehog == hero.gear then
		TurnTimeLeft = -1
	elseif CurrentHedgehog == paoth1.gear or CurrentHedgehog == paoth1.gear
		or CurrentHedgehog == paoth3.gear or CurrentHedgehog == paoth4.gear
		or CurrentHedgehog == professor.gear then
		TurnTimeLeft = 0
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
	end
end

-------------- EVENTS ------------------

function onWeaponsPlatform(gear)
	if GetX(gear) > bazookaX-200 and GetX(gear) < deserteagleX+400  and GetY(gear) < weaponsY+150 and StoppedGear(gear) then
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

function weaponsPlatform(gear)	
	SaveCampaignVar("Moon01CheckPoint", "2")
	TurnTimeLeft = 0
	weaponsAqcuired = true
	SetWind(80)		
	GameFlags = bor(GameFlags,gfDisableWind)
	AddAnim(dialog02)
end

function heroDeath(gear)
	
	EndGame()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
end

function AnimationSetup()
	-- DIALOG 01 - Start, welcome to moon
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Near PAoTH base at moon..."),  4000}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("Hey Hog Solo! Finaly you have come..."), SAY_SAY, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("It seems that Professor Hogevil learned for your arrival!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("Now he have captured the rest of the PAoTH team and awaits to capture you!"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("We have to hurry! Are you armed?"), SAY_SAY, 4300}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("No, I am afraid I had to travel light"), SAY_SAY, 2500}})
	table.insert(dialog01, {func = AnimWait, args = {paoth1.gear, 500}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("Ok, then you have to go and take some of the waepons we have hidden in case of an emergency!"), SAY_SAY, 7000}})
	table.insert(dialog01, {func = AnimSay, args = {paoth1.gear, loc("They are up there! Take that rope and hurry!"), SAY_SAY, 7000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Ehm... ok..."), SAY_SAY, 2500}})
	table.insert(dialog01, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG 02 - To the weapons platform
	AddSkipFunction(dialog02, Skipanim, {dialog02})
	table.insert(dialog02, {func = AnimCaption, args = {hero.gear, loc("Checkpoint reached!"),  4000}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("I've made it! YEAAAAAH!"), SAY_SHOUT, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {paoth1.gear, loc("Nice! Now hurry up and get down! You have to rescue my friends!"), SAY_SHOUT, 7000}})
	table.insert(dialog02, {func = AnimSwitchHog, args = {hero.gear}})
end

------------------- custom "animation" functions --------------------------

function startCombat()
	-- use this so guard2 will gain control
	AnimSwitchHog(minion3.gear)
	TurnTimeLeft = 0
end

------------------- ABOUT ----------------------
--
-- In this adventure hero visits the fruit planet
-- to search for the missing part. However, a war
-- has broke out and hero has to take part or leave.

-- NOTES:
-- There is an ugly hack out there! I use 2 Captain Limes
-- One in human level and one in bot level
-- I want to have a Captain Lime in human level when the game
-- begins because in animation if the hog is in bot level skip
-- doesn't work - onPrecise() isn't triggered
-- Later I want the hog to take place in the battle in bot level
-- However if I use SetHogLevel I get an error: Engine bug: AI may break demos playing
-- So I have 2 hogs, one in bot level and one in hog level that I hide them
-- or restore them regarding the case

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("Bad timing")
local chooseToBattle = false
local awaitingInput = false
local previousHog = 0
local heroPlayedFirstTurn = false
local startBattleCalled = false
-- dialogs
local dialog01 = {}
local dialog02 = {}
local dialog03 = {}

-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Ready for Battle?"),
		loc("Captain Lime offered his help if you assist him in battle.").."|"..
		loc("What do you want to do?").."| |"..
		loc("Fight: Press [Attack]").."|"..
		loc("Flee: Press [Jump]"), 1, 9999000, true},
	[dialog02] = {missionName, loc("Battle Starts Now!"), loc("You have chosen to fight!").."|"..loc("Lead your allies to battle and eliminate all the enemies!"), 1, 5000},
	[dialog03] = {missionName, loc("Time to run!"), loc("You have chosen to flee.").."|"..loc("You have to reach the left-most place on the map."), 1, 5000},
	["fight"] = {missionName, loc("Ready for Battle?"), loc("You have chosen to fight!"), 1, 2000},
	["flee"] = {missionName, loc("Ready for Battle?"), loc("You have chosen to flee."), 1, 2000},
	["flee_final"] = {missionName, loc("Time to run!"), loc("Knock off the enemies from the left-most place of the map!") .. "|" .. loc("Stay there to flee!"), 1, 6000},
}
-- crates
local crateWMX = 2170
local crateWMY = 1950
local health1X = 2680
local health1Y = 916
-- hogs
local hero = {}
local yellow1 = {}
local green1 = {}
local green2 = {}
local green3 = {}
local green4 = {}
local green5 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
local teamD = {}
-- hedgehogs values
hero.name = loc("Hog Solo")
hero.x = 3350
hero.y = 365
hero.dead = false
green1.name = loc("Captain Lime")
green1.x = 3300
green1.y = 395
green1.dead = false
green2.name = loc("Mister Pear")
green2.x = 3600
green2.y = 1570
green3.name = loc("Lady Mango")
green3.x = 2170
green3.y = 980
green4.name = loc("Green Hog Grape")
green4.x = 2900
green4.y = 1650
green5.name = loc("Mr Mango")
green5.x = 1350
green5.y = 850
yellow1.name = loc("General Lemon")
yellow1.x = 140
yellow1.y = 1980
local yellowArmy = {
	{name = loc("Robert Yellow Apple"), x = 710, y = 1780, health = 100},
	{name = loc("Summer Squash"), x = 315 , y = 1960, health = 100},
	{name = loc("Tall Potato"), x = 830 , y = 1748, health = 80},
	{name = loc("Yellow Pepper"), x = 2160 , y = 820, health = 60},
	{name = loc("Corn"), x = 1320 , y = 740, health = 60},
	{name = loc("Max Citrus"), x = 1900 , y = 1700, health = 40},
	{name = loc("Naranja Jed"), x = 960 , y = 516, health = 40},
}
teamA.name = loc("Hog Solo")
teamA.color = -6
teamB.name = loc("Green Bananas")
teamB.color = -6
teamC.name = loc("Yellow Watermelons")
teamC.color = -9
teamD.name = loc("Captain Lime")
teamD.color = -6

function onGameInit()
	Seed = 1
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0
	HealthCaseAmount = 50
	Map = "fruit01_map"
	Theme = "Fruit"

	-- Hero
	teamA.name = AddMissionTeam(teamA.color)
	hero.gear = AddMissionHog(100)
	hero.name = GetHogName(hero.gear)
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	-- Captain Lime
	teamD.name = AddTeam(teamD.name, teamD.color, "Cherry", "Island", "Default_qau", "congo-brazzaville")
	green1.gear = AddHog(green1.name, 0, 200, "war_desertofficer")
	AnimSetGearPosition(green1.gear, green1.x, green1.y)
	-- Green Bananas
	teamB.name = AddTeam(teamB.name, teamB.color, "Cherry", "Island", "Default_qau", "congo-brazzaville")
	green2.gear = AddHog(green2.name, 0, 100, "war_britmedic")
	AnimSetGearPosition(green2.gear, green2.x, green2.y)
	HogTurnLeft(green2.gear, true)
	green3.gear = AddHog(green3.name, 0, 100, "hair_red")
	AnimSetGearPosition(green3.gear, green3.x, green3.y)
	HogTurnLeft(green3.gear, true)
	green4.gear = AddHog(green4.name, 0, 100, "war_desertsapper1")
	AnimSetGearPosition(green4.gear, green4.x, green4.y)
	HogTurnLeft(green4.gear, true)
	green5.gear = AddHog(green5.name, 0, 100, "war_sovietcomrade2")
	AnimSetGearPosition(green5.gear, green5.x, green5.y)
	HogTurnLeft(green5.gear, true)
	-- Yellow Watermelons
	teamC.name = AddTeam(teamC.name, teamC.color, "Flower", "Island", "Default_qau", "cm_mog")
	yellow1.gear = AddHog(yellow1.name, 1, 100, "war_desertgrenadier2")
	AnimSetGearPosition(yellow1.gear, yellow1.x, yellow1.y)
	-- the rest of the Yellow Watermelons
	local yellowHats = { "fr_apple", "fr_banana", "fr_lemon", "fr_orange" }
	for i=1,7 do
		yellowArmy[i].gear = AddHog(yellowArmy[i].name, 1, yellowArmy[i].health, yellowHats[GetRandom(4)+1])
		AnimSetGearPosition(yellowArmy[i].gear, yellowArmy[i].x, yellowArmy[i].y)
	end

	initCheckpoint("fruit01")

	AnimInit(true)
	AnimationSetup()
end

function onGameStart()
	AnimSetInputMask(0)
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)

	-- Green team weapons
	local greenArmy = { green1, green2 }
	for i=1,2 do
		AddAmmo(greenArmy[i].gear, amBlowTorch, 5)
		AddAmmo(greenArmy[i].gear, amRope, 5)
		AddAmmo(greenArmy[i].gear, amBazooka, 10)
		AddAmmo(greenArmy[i].gear, amGrenade, 7)
		AddAmmo(greenArmy[i].gear, amFirePunch, 2)
		AddAmmo(greenArmy[i].gear, amDrill, 3)
		AddAmmo(greenArmy[i].gear, amSwitch, 2)
		AddAmmo(greenArmy[i].gear, amSkip, 100)
	end
	-- Yellow team weapons
	AddAmmo(yellow1.gear, amBlowTorch, 1)
	AddAmmo(yellow1.gear, amRope, 1)
	AddAmmo(yellow1.gear, amBazooka, 10)
	AddAmmo(yellow1.gear, amGrenade, 10)
	AddAmmo(yellow1.gear, amFirePunch, 5)
	AddAmmo(yellow1.gear, amDrill, 3)
	AddAmmo(yellow1.gear, amBee, 1)
	AddAmmo(yellow1.gear, amMortar, 3)
	AddAmmo(yellow1.gear, amDEagle, 4)
	AddAmmo(yellow1.gear, amDynamite, 1)
	AddAmmo(yellow1.gear, amSwitch, 100)
	for i=3,7 do
		HideHog(yellowArmy[i].gear)
	end

	-- crates
	SpawnHealthCrate(health1X, health1Y)
	SpawnSupplyCrate(crateWMX, crateWMY, amWatermelon)

	AddAnim(dialog01)
	SendHealthStatsOff()
end

function onNewTurn()
	if not heroPlayedFirstTurn and CurrentHedgehog ~= hero.gear and startBattleCalled then
		EndTurn(true)
	elseif not heroPlayedFirstTurn and CurrentHedgehog == hero.gear and startBattleCalled then
		heroPlayedFirstTurn = true
	elseif not heroPlayedFirstTurn and CurrentHedgehog == green1.gear then
		EndTurn(true)
	else
		if chooseToBattle then
			if CurrentHedgehog == green1.gear then
				TotalRounds = TotalRounds - 2
				AnimSwitchHog(previousHog)
				EndTurn(true)
			end
			previousHog = CurrentHedgehog
		end
		getNextWave()
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

local choiceDialogTimer = 0
function onGameTick20()
  -- Make sure the choice dialog never disappears while it is active
  if awaitingInput then
    choiceDialogTimer = choiceDialogTimer + 20
    if choiceDialogTimer > 9990000 then
      ShowMission(unpack(goals[dialog01]))
      choiceDialogTimer = 0
    end
  end
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	elseif gear == green1.gear then
		green1.dead = true
	end
end

function onAmmoStoreInit()
	SetAmmo(amWatermelon, 0, 0, 0, 1)
end

function onPreciseLocal()
	if GameTime > 3000 then
		SetAnimSkip(true)
	end
end

function onHogHide(gear)
	for i=3,7 do
		if gear == yellowArmy[i].gear then
			yellowArmy[i].hidden = true
			break
		end
	end
end

function onHogRestore(gear)
	for i=3,7 do
		if gear == yellowArmy[i].gear then
			yellowArmy[i].hidden = false
			break
		end
	end
end

-------------- EVENTS ------------------

function onHeroDeath(gear)
	if hero.dead then
		return true
	end
	return false
end

function onGreen1Death(gear)
	if green1.dead then
		return true
	end
	return false
end

function onBattleWin(gear)
	local win = true
	for i=1,7 do
		if i<3 then
			if GetHealth(yellowArmy[i].gear) then
				win = false
			end
		else
			if GetHealth(yellowArmy[i].gear) and not yellowArmy[i].hidden then
				win = false
			end
		end
	end
	if GetHealth(yellow1.gear) then
		win = false
	end
	return win
end

function isHeroOnLaunchPad()
	if not hero.dead and GetX(hero.gear) < 170 and GetY(hero.gear) > 1980 and StoppedGear(hero.gear) then
		return true
	end
	return false
end

function isLaunchPadEmpty(gear)
	local yellowTeam = { yellow1, unpack(yellowArmy) }
	for i=1, #yellowArmy+1 do
		if not yellowTeam[i].hidden and GetHealth(yellowTeam[i].gear) and GetX(yellowTeam[i].gear) < 170 then
			return false
		end
	end
	return true
end

function onHeroOnLaunchPadWithEnemies()
	return isHeroOnLaunchPad() and not isLaunchPadEmpty()
end

function heroOnLaunchPadWithEnemies()
	ShowMission(unpack(goals["flee_final"]))
end

function onEscapeWin(gear)
	local escape = false
	if isHeroOnLaunchPad() then
		escape = isLaunchPadEmpty()
	end
	return escape
end

-------------- ACTIONS ------------------

function heroDeath(gear)
	gameLost()
end

function green1Death(gear)
	gameLost()
end

function battleWin(gear)
	-- add stats
	saveVariables()
	SendStat(siGameResult, string.format(loc("%s won!"), teamB.name))
	SendStat(siCustomAchievement, loc("You have eliminated all visible enemy hedgehogs!"))
	sendSimpleTeamRankings({teamA.name, teamD.name, teamB.name, teamC.name})
	EndGame()
end

function escapeWin(gear)
	RemoveEventFunc(heroOnLaunchPadWithEnemies)
	-- add stats
	saveVariables()
	SendStat(siGameResult, string.format(loc("%s escaped successfully!"), hero.name))
	SendStat(siCustomAchievement, loc("You have reached the take-off area successfully!"))
	sendSimpleTeamRankings({teamA.name, teamD.name, teamB.name, teamC.name})
	EndGame()
end

function heroSelect()
	awaitingInput = false
	FollowGear(hero.gear)
	if chooseToBattle == true then
		chooseToBattle = true
		ShowMission(unpack(goals["fight"]))
		AddEvent(onGreen1Death, {green1.gear}, green1Death, {green1.gear}, 0)
		AddEvent(onBattleWin, {hero.gear}, battleWin, {hero.gear}, 0)
		AddAnim(dialog02)
	else
		ShowMission(unpack(goals["flee"]))
		AddAmmo(green1.gear, amSwitch, 100)
		AddEvent(onHeroOnLaunchPadWithEnemies, {hero.gear}, heroOnLaunchPadWithEnemies, {hero.gear}, 0)
		AddEvent(onEscapeWin, {hero.gear}, escapeWin, {hero.gear}, 0)
		local greenTeam = { green2, green3, green4, green5 }
		for i=1,4 do
			SetHogLevel(greenTeam[i].gear, 1)
		end
		AddAnim(dialog03)
	end
end

-------------- ANIMATIONS ------------------

function AfterDialog01()
	AnimSwitchHog(hero.gear)
	awaitingInput = true
end

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
	end
	if anim == dialog01 then
		AfterDialog01()
	elseif anim == dialog02 or anim == dialog03 then
		startBattle()
	end
end

function AnimationSetup()
	-- DIALOG 01 - Start, Captain Lime talks and explains stuff to hero
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 1000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Somewhere on the Planet of Fruits a terrible war is about to begin ..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("I was told that as the leader of the king's guard, no one knows this world better than you!"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("So, I kindly ask for your help."), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {green1.gear, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, string.format(loc("You couldn't have come to a worse time, %s!"), hero.name), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("The clan of the Red Strawberry wants to take over the dominion and overthrow King Pineapple."), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("Under normal circumstances we could easily defeat them but we have kindly sent most of our men to the Kingdom of Sand to help with the annual dusting of the king's palace."), SAY_SAY, 8000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, string.format(loc("However, the army of %s is about to attack any moment now."), teamC.name), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("I would gladly help you if we won this battle but under these circumstances I'll only help you if you fight for our side."), SAY_SAY, 6000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("What do you say? Will you fight for us?"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = ShowMission, args = goals[dialog01]})
	table.insert(dialog01, {func = AfterDialog01, args = {}})
	-- DIALOG 02 - Hero selects to fight
	AddSkipFunction(dialog02, Skipanim, {dialog02})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, string.format(loc("You choose well, %s!"), hero.name), SAY_SAY, 3000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("I have only 3 hogs available and they are all cadets."), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("As you are more experienced, I want you to lead them to battle."), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("Of course, I will observe the battle and intervene if necessary."), SAY_SAY, 5000}})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 4500}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("No problem, Captain!"), SAY_SAY, 2000}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("The enemies aren't many anyway, it is going to be easy!"), SAY_SAY, 1}})
	table.insert(dialog02, {func = AnimWait, args = {green1.gear, 9000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("Don't be foolish, son, there will be more."), SAY_SAY, 2000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("Try to be smart and eliminate them quickly. This way you might scare off the rest!"), SAY_SAY, 5000}})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 5000}})
	table.insert(dialog02, {func = ShowMission, args = goals[dialog02]})
	table.insert(dialog02, {func = startBattle, args = {hero.gear}})
	-- DIALOG 03 - Hero selects to flee
	AddSkipFunction(dialog03, Skipanim, {dialog03})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Too bad! Then you should really leave!"), SAY_SAY, 3000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Things are going to get messy around here."), SAY_SAY, 3000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Also, you should know that the only place where you can fly is the left-most part of this area."), SAY_SAY, 5000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("All the other places are protected by our flight-inhibiting weapons."), SAY_SAY, 4000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Now go and don't waste more of my time, you coward!"), SAY_SAY, 4000}})
	table.insert(dialog03, {func = AnimWait, args = {hero.gear, 5000}})
	table.insert(dialog03, {func = ShowMission, args = goals[dialog03]})
	table.insert(dialog03, {func = startBattle, args = {hero.gear}})
end

------------- OTHER FUNCTIONS ---------------

function startBattle()
	AnimSetInputMask(0xFFFFFFFF)
	-- Hero weapons
	AddAmmo(hero.gear, amRope, 2)
	AddAmmo(hero.gear, amBazooka, 3)
	AddAmmo(hero.gear, amParachute, 1)
	AddAmmo(hero.gear, amGrenade, 6)
	AddAmmo(hero.gear, amDEagle, 4)
	AddAmmo(hero.gear, amSkip, 100)
	SetHogLevel(green1.gear, 1)
	startBattleCalled = true
	EndTurn(true)
end

function gameLost()
	if chooseToBattle then
		SendStat(siGameResult, string.format(loc("%s lost, try again!"), teamB.name))
		SendStat(siCustomAchievement, loc("You have to eliminate all the visible enemies."))
		SendStat(siCustomAchievement, loc("5 additional enemies will be spawned during the game."))
		SendStat(siCustomAchievement, loc("You are in control of all the active ally units."))
		SendStat(siCustomAchievement, loc("The ally units share their ammo."))
		SendStat(siCustomAchievement, loc("Try to keep as many allies alive as possible."))
	else
		SendStat(siGameResult, string.format(loc("%s couldn't escape, try again!"), hero.name))
		SendStat(siCustomAchievement, loc("You have to get to the left-most land and remove any enemy hog from there."))
		SendStat(siCustomAchievement, loc("You will play every 3 turns."))
	end
	sendSimpleTeamRankings({teamC.name, teamA.name, teamD.name, teamB.name})
	EndGame()
end

function getNextWave()
	if GetHogTeamName(CurrentHedgehog) ~= teamC.name then
		return
	end
	if TotalRounds == 4 then
		RestoreHog(yellowArmy[3].gear)
		AnimCaption(hero.gear, string.format(loc("%s enters the battlefield"), yellowArmy[3].name), 5000)
		if not chooseToBattle and not GetHealth(yellow1.gear) then
			SetGearPosition(yellowArmy[3].gear, yellow1.x, yellow1.y)
		end
		AnimOutOfNowhere(yellowArmy[3].gear)
	elseif TotalRounds == 7 then
		RestoreHog(yellowArmy[4].gear)
		RestoreHog(yellowArmy[5].gear)
		AnimCaption(hero.gear, string.format(loc("%s and %s enter the battlefield"), yellowArmy[4].name, yellowArmy[5].name), 5000)
		if not chooseToBattle and not GetHealth(yellow1.gear) and not GetHealth(yellowArmy[3].gear) then
			SetGearPosition(yellowArmy[4].gear, yellow1.x, yellow1.y)
		end
		AnimOutOfNowhere(yellowArmy[4].gear)
		AnimOutOfNowhere(yellowArmy[5].gear)
	elseif TotalRounds == 10 then
		RestoreHog(yellowArmy[6].gear)
		RestoreHog(yellowArmy[7].gear)
		AnimCaption(hero.gear, string.format(loc("%s and %s enter the battlefield"), yellowArmy[6].name, yellowArmy[7].name), 5000)
		if not chooseToBattle and not GetHealth(yellow1.gear) and not GetHealth(yellowArmy[3].gear)
				and not GetHealth(yellowArmy[4].gear) then
			SetGearPosition(yellowArmy[6].gear, yellow1.x, yellow1.y)
		end
		AnimOutOfNowhere(yellowArmy[6].gear)
		AnimOutOfNowhere(yellowArmy[7].gear)
	end
end

function saveVariables()
	saveCompletedStatus(2)
	SaveCampaignVar("UnlockedMissions", "4")
	SaveCampaignVar("Mission1", "8")
	SaveCampaignVar("Mission2", "3")
	SaveCampaignVar("Mission3", "10")
	SaveCampaignVar("Mission4", "1")
end


function onLJump()
	if awaitingInput then
		PlaySound(sndPlaced)
		PlaySound(sndCoward, green1.gear)
		chooseToBattle = false
		heroSelect()
	end
end
onHJump = onLJump

function onAttack()
	if awaitingInput then
		PlaySound(sndPlaced)
		chooseToBattle = true
		heroSelect()
	end
end

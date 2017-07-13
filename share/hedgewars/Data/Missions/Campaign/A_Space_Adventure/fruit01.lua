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
local previousHog = 0
local heroPlayedFirstTurn = false
local startBattleCalled = false
-- dialogs
local dialog01 = {}
local dialog02 = {}
local dialog03 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Ready for Battle?"), loc("Walk left if you want to join Captain Lime or right if you want to decline his offer."), 1, 4000},
	[dialog02] = {missionName, loc("Battle Starts Now!"), loc("You have chosen to fight! Lead the Green Bananas to battle and eliminate all the enemies!"), 1, 4000},
	[dialog03] = {missionName, loc("Time to run!"), loc("You have chosen to flee ... Unfortunately, the only place where you can launch your saucer is the left-most place on the map."), 1, 4000},
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
teamA.color = tonumber("38D61C",16) -- green
teamB.name = loc("Green Bananas")
teamB.color = tonumber("38D61C",16) -- green
teamC.name = loc("Yellow Watermelons")
teamC.color = tonumber("DDFF00",16) -- yellow
teamD.name = loc("Captain Lime")
teamD.color = tonumber("38D61C",16) -- green

function onGameInit()
	Seed = 1
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Delay = 3
	SuddenDeathTurns = 100
	HealthCaseAmount = 50
	Map = "fruit01_map"
	Theme = "Fruit"

	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	-- Captain Lime
	AddTeam(teamD.name, teamD.color, "Bone", "Island", "HillBilly", "cm_birdy")
	green1.bot = AddHog(green1.name, 1, 200, "war_desertofficer")
	AnimSetGearPosition(green1.bot, green1.x, green1.y)
	green1.human =  AddHog(green1.name, 0, 200, "war_desertofficer")
	AnimSetGearPosition(green1.human, green1.x, green1.y)
	green1.gear = green1.human
	-- Green Bananas
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
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
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	yellow1.gear = AddHog(yellow1.name, 1, 100, "war_desertgrenadier2")
	AnimSetGearPosition(yellow1.gear, yellow1.x, yellow1.y)
	-- the rest of the Yellow Watermelons
	local yellowHats = { "fr_apple", "fr_banana", "fr_lemon", "fr_orange" }
	for i=1,7 do
		yellowArmy[i].gear = AddHog(yellowArmy[i].name, 1, yellowArmy[i].health, yellowHats[GetRandom(4)+1])
		AnimSetGearPosition(yellowArmy[i].gear, yellowArmy[i].x, yellowArmy[i].y)
	end

	initCheckpoint("fruit01")

	AnimInit()
	AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onHeroSelect, {hero.gear}, heroSelect, {hero.gear}, 0)

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
	HideHog(green1.bot)

	-- crates
	SpawnHealthCrate(health1X, health1Y)
	SpawnAmmoCrate(crateWMX, crateWMY, amWatermelon)

	AddAnim(dialog01)
	SendHealthStatsOff()
end

function onNewTurn()
	if not heroPlayedFirstTurn and CurrentHedgehog ~= hero.gear and startBattleCalled then
		TurnTimeLeft = 0
	elseif not heroPlayedFirstTurn and CurrentHedgehog == hero.gear and startBattleCalled then
		heroPlayedFirstTurn = true
	elseif not heroPlayedFirstTurn and CurrentHedgehog == green1.gear then
		TurnTimeLeft = 0
	else
		if chooseToBattle then
			if CurrentHedgehog == green1.gear then
				TotalRounds = TotalRounds - 2
				AnimSwitchHog(previousHog)
				TurnTimeLeft = 0
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

function onPrecise()
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

function onEscapeWin(gear)
	local escape = false
	if not hero.dead and GetX(hero.gear) < 170 and GetY(hero.gear) > 1980 and StoppedGear(hero.gear) then
		escape = true
		local yellowTeam = { yellow1, unpack(yellowArmy) }
		for i=1,8 do
			if not yellowTeam[i].hidden and GetHealth(yellowTeam[i].gear) and GetX(yellowTeam[i].gear) < 170 then
				escape = false
				break
			end
		end
	end
	return escape
end

function onHeroSelect(gear)
	if GetX(hero.gear) ~= hero.x then
		return true
	end
	return false
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
	SendStat(siGameResult, loc("Green Bananas won!"))
	SendStat(siCustomAchievement, loc("You have eliminated all visible enemy hedgehogs!"))
	SendStat(siPlayerKills,'1',teamA.name)
	SendStat(siPlayerKills,'1',teamB.name)
	SendStat(siPlayerKills,'0',teamC.name)
	EndGame()
end

function escapeWin(gear)
	-- add stats
	saveVariables()
	SendStat(siGameResult, loc("Hog Solo escaped successfully!"))
	SendStat(siCustomAchievement, loc("You have reached the take-off area successfully!"))
	SendStat(siPlayerKills,'1',teamA.name)
	SendStat(siPlayerKills,'0',teamB.name)
	SendStat(siPlayerKills,'0',teamC.name)
	EndGame()
end

function heroSelect(gear)
	TurnTimeLeft = 0
	FollowGear(hero.gear)
	if GetX(hero.gear) < hero.x then
		chooseToBattle = true
		AddEvent(onGreen1Death, {green1.gear}, green1Death, {green1.gear}, 0)
		AddEvent(onBattleWin, {hero.gear}, battleWin, {hero.gear}, 0)
		AddAnim(dialog02)
	elseif GetX(hero.gear) > hero.x then
		HogTurnLeft(hero.gear, true)
		AddAmmo(green1.gear, amSwitch, 100)
		AddEvent(onEscapeWin, {hero.gear}, escapeWin, {hero.gear}, 0)
		local greenTeam = { green2, green3, green4, green5 }
		for i=1,4 do
			SetHogLevel(greenTeam[i].gear, 1)
		end
		AddAnim(dialog03)
	end
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
    if anim == dialog01 then
		AnimSwitchHog(hero.gear)
	elseif anim == dialog02 or anim == dialog03 then
		startBattle()
    end
end

function AnimationSetup()
	-- DIALOG 01 - Start, Captain Lime talks explains to Hog Solo
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Somewhere on the Planet of Fruits a terrible war is about to begin ..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("I was told that as the leader of the king's guard, no one knows this world better than you!"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("So, I kindly ask for your help."), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {green1.gear, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("You couldn't have come to a worse time, Hog Solo!"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("The clan of the Red Strawberry wants to take over the dominion and overthrow King Pineapple."), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("Under normal circumstances we could easily defeat them but we have kindly sent most of our men to the Kingdom of Sand to help with the annual dusting of the king's palace."), SAY_SAY, 8000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("However, the army of Yellow Watermelons is about to attack any moment now."), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("I would gladly help you if we won this battle but under these circumstances I'll only help you if you fight for our side."), SAY_SAY, 6000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("What do you say? Will you fight for us?"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = ShowMission, args = {missionName, loc("Ready for Battle?"), loc("Walk left if you want to join Captain Lime or right if you want to decline his offer."), 1, 7000}})
	table.insert(dialog01, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG 02 - Hero selects to fight
	AddSkipFunction(dialog02, Skipanim, {dialog02})
	table.insert(dialog02, {func = AnimWait, args = {green1.gear, 3000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("You choose well, Hog Solo!"), SAY_SAY, 3000}})
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
	table.insert(dialog02, {func = startBattle, args = {hero.gear}})
	-- DIALOG 03 - Hero selects to flee
	AddSkipFunction(dialog03, Skipanim, {dialog03})
	table.insert(dialog03, {func = AnimWait, args = {green1.gear, 3000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Too bad! Then you should really leave!"), SAY_SAY, 3000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Things are going to get messy around here."), SAY_SAY, 3000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Also, you should know that the only place where you can fly is the left-most part of this area."), SAY_SAY, 5000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("All the other places are protected by our flight-inhibiting weapons."), SAY_SAY, 4000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Now go and don't waste more of my time, you coward!"), SAY_SAY, 4000}})
	table.insert(dialog03, {func = AnimWait, args = {hero.gear, 5000}})
	table.insert(dialog03, {func = startBattle, args = {hero.gear}})
end

------------- OTHER FUNCTIONS ---------------

function startBattle()
	-- Hog Solo weapons
	AddAmmo(hero.gear, amRope, 2)
	AddAmmo(hero.gear, amBazooka, 3)
	AddAmmo(hero.gear, amParachute, 1)
	AddAmmo(hero.gear, amGrenade, 6)
	AddAmmo(hero.gear, amDEagle, 4)
	AddAmmo(hero.gear, amSkip, 100)
	RestoreHog(green1.bot)
	DeleteGear(green1.human)
	green1.gear = green1.bot
	startBattleCalled = true
	TurnTimeLeft = 0
end

function gameLost()
	if chooseToBattle then
		SendStat(siGameResult, loc("The Green Bananas lost, try again!"))
		SendStat(siCustomAchievement, loc("You have to eliminate all the visible enemies."))
		SendStat(siCustomAchievement, loc("5 additional enemies will be spawned during the game."))
		SendStat(siCustomAchievement, loc("You are in control of all the active ally units."))
		SendStat(siCustomAchievement, loc("The ally units share their ammo."))
		SendStat(siCustomAchievement, loc("Try to keep as many allies alive as possible."))
	else
		SendStat(siGameResult, loc("Hog Solo couldn't escape, try again!"))
		SendStat(siCustomAchievement, loc("You have to get to the left-most land and remove any enemy hog from there."))
		SendStat(siCustomAchievement, loc("You will play every 3 turns."))
		SendStat(siCustomAchievement, loc("Green hogs won't intentionally hurt you."))
	end
	SendStat(siPlayerKills,'1',teamC.name)
	SendStat(siPlayerKills,'0',teamA.name)
	SendStat(siPlayerKills,'0',teamB.name)
	EndGame()
end

function getNextWave()
	if TotalRounds == 4 then
		RestoreHog(yellowArmy[3].gear)
		AnimCaption(hero.gear, loc("Next wave in 3 turns"), 5000)
		if not chooseToBattle and not GetHealth(yellow1.gear) then
			SetGearPosition(yellowArmy[3].gear, yellow1.x, yellow1.y)
		end
	elseif TotalRounds == 7 then
		RestoreHog(yellowArmy[4].gear)
		RestoreHog(yellowArmy[5].gear)
		AnimCaption(hero.gear, loc("Last wave in 3 turns"), 5000)
		if not chooseToBattle and not GetHealth(yellow1.gear) and not GetHealth(yellowArmy[3].gear) then
			SetGearPosition(yellowArmy[4].gear, yellow1.x, yellow1.y)
		end
	elseif TotalRounds == 10 then
		RestoreHog(yellowArmy[6].gear)
		RestoreHog(yellowArmy[7].gear)
		if not chooseToBattle and not GetHealth(yellow1.gear) and not GetHealth(yellowArmy[3].gear)
				and not GetHealth(yellowArmy[4].gear) then
			SetGearPosition(yellowArmy[6].gear, yellow1.x, yellow1.y)
		end
	end
end

function saveVariables()
	saveCompletedStatus(2)
	SaveCampaignVar("UnlockedMissions", "3")
	SaveCampaignVar("Mission1", "3")
	SaveCampaignVar("Mission2", "8")
	SaveCampaignVar("Mission3", "1")
end

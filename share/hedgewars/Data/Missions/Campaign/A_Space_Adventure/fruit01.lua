------------------- ABOUT ----------------------
--
-- In this adventure hero visits the fruit planet
-- to search for the missing part. However, a war
-- has broke out and hero has to take part or leave.

-- TODO: remove unwanted delay after first dialog

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Fruit planet, The War!")
local chooseToBattle = false
-- dialogs
local dialog01 = {}
local dialog02 = {}
local dialog03 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Ready for Battle?"), loc("Walk left if you want to join Captain Lime or right if you want to decline his offer"), 1, 7000},
	[dialog02] = {missionName, loc("Battle Starts Now!"), loc("You have choose to fight! Lead the Green Bananas to battle and try not to let them be killed"), 1, 7000},
	[dialog03] = {missionName, loc("Ready for Battle?"), loc("You have choose to flee... Unfortunately the only place where you can launch your saucer is in the most left side of the map"), 1, 7000},
}
-- crates
local crateWMX = 2170
local crateWMY = 1950
local health1X = 2680
local health1Y = 716
-- hogs
local hero = {}
local yellow1 = {}
local green1 = {}
local green2 = {}
local green3 = {}
local green4 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
-- hedgehogs values
hero.name = "Hog Solo"
hero.x = 3650
hero.y = 95
hero.dead = false
green1.name = "Captain Lime"
green1.x = 3600
green1.y = 95
green1.dead = false
green2.name = "Mister Pear"
green2.x = 3600
green2.y = 1570
green3.name = "Lady Mango"
green3.x = 2170
green3.y = 680
green4.name = "Green Hog Grape"
green4.x = 2900
green4.y = 1650
yellow1.name = "General Lemon"
yellow1.x = 140
yellow1.y = 1980
local yellowArmy = {
	{name = "Robert Yellow Apple", x = 710, y = 1780},
	{name = "Summer Squash", x = 315 , y = 1960},
	{name = "Tall Potato", x = 830 , y = 1748},
	{name = "Yellow Pepper", x = 285 , y = 1960},
	{name = "Corn", x = 1320 , y = 540},
	{name = "Max Citrus", x = 1900 , y = 1700},
	{name = "Naranja Jed", x = 960 , y = 316},
}
teamA.name = loc("Hog Solo")
teamA.color = tonumber("38D61C",16) -- green  
teamB.name = loc("Green Bananas")
teamB.color = tonumber("38D61C",16) -- green
teamC.name = loc("Yellow Watermellons")
teamC.color = tonumber("DDFF00",16) -- yellow

function onGameInit()
	Seed = 1
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Delay = 3
	HealthCaseAmount = 50
	Map = "fruit01_map"
	Theme = "Fruit"
	
	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	-- Green Bananas
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	green1.gear = AddHog(green1.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(green1.gear, green1.x, green1.y)
	green2.gear = AddHog(green2.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(green2.gear, green2.x, green2.y)
	HogTurnLeft(green2.gear, true)
	green3.gear = AddHog(green3.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(green3.gear, green3.x, green3.y)
	HogTurnLeft(green3.gear, true)
	green4.gear = AddHog(green4.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(green4.gear, green4.x, green4.y)
	HogTurnLeft(green4.gear, true)
	-- Yellow Watermellons
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	yellow1.gear = AddHog(yellow1.name, 1, 100, "war_desertgrenadier1")
	AnimSetGearPosition(yellow1.gear, yellow1.x, yellow1.y)
	-- the rest of the Yellow Watermellons
	for i=1,7 do
		yellowArmy[i].gear = AddHog(yellowArmy[i].name, 1, 100, "war_desertgrenadier1")
		AnimSetGearPosition(yellowArmy[i].gear, yellowArmy[i].x, yellowArmy[i].y)
	end

	AnimInit()
	AnimationSetup()	
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onHeroSelect, {hero.gear}, heroSelect, {hero.gear}, 0)
	
	-- Hog Solo weapons
	AddAmmo(hero.gear, amRope, 2)
	AddAmmo(hero.gear, amBazooka, 3)
	AddAmmo(hero.gear, amParachute, 1)
	AddAmmo(hero.gear, amGrenade, 6)
	AddAmmo(hero.gear, amDEagle, 4)
	-- Green team weapons
	local greenTeam = {	green1, green2, green3, green4 }
	for i=1,4 do
		AddAmmo(greenTeam[i].gear, amBlowTorch, 1)
		AddAmmo(greenTeam[i].gear, amRope, 1)
		AddAmmo(greenTeam[i].gear, amBazooka, 4)
		AddAmmo(greenTeam[i].gear, amGrenade, 3)
		AddAmmo(greenTeam[i].gear, amFirePunch, 2)
		AddAmmo(greenTeam[i].gear, amDrill, 1)
	end
	-- Yellow team weapons
	AddAmmo(yellow1.gear, amBlowTorch, 1)
	AddAmmo(yellow1.gear, amRope, 1)
	AddAmmo(yellow1.gear, amBazooka, 3)
	AddAmmo(yellow1.gear, amGrenade, 1)
	AddAmmo(yellow1.gear, amFirePunch, 1)
	AddAmmo(yellow1.gear, amDrill, 1)
	for i=1,7 do
		AddAmmo(yellowArmy[i].gear, amBlowTorch, 1)
		AddAmmo(yellowArmy[i].gear, amRope, 1)
		AddAmmo(yellowArmy[i].gear, amBazooka, 3)
		AddAmmo(yellowArmy[i].gear, amGrenade, 3)
		AddAmmo(yellowArmy[i].gear, amFirePunch, 1)
		AddAmmo(yellowArmy[i].gear, amDrill, 3)	
		AddAmmo(yellowArmy[i].gear, amBee, 1)	
		AddAmmo(yellowArmy[i].gear, amMortar, 2)	
		AddAmmo(yellowArmy[i].gear, amSniperRifle, 3)	
		AddAmmo(yellowArmy[i].gear, amDEagle, 2)	
		AddAmmo(yellowArmy[i].gear, amDynamite, 1)	
		if i>2 then
			HideHog(yellowArmy[i].gear)
		end
	end
	
	AddAnim(dialog01)
	SendHealthStatsOff()
end

function onNewTurn()
	if CurrentHedgehog == green1.gear then
		TotalRounds = TotalRounds - 1
		if GetHealth(green2.gear) then
			SwitchHog(green2.gear)
		elseif GetHealth(green3.gear) then
			SwitchHog(green3.gear)
		elseif GetHealth(green4.gear) then
			SwitchHog(green4.gear)
		end
	end
	getNextWave()
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

function onHeroSelect(gear)
	if GetX(hero.gear) ~= hero.x then
		return true
	end
	return false
end

-------------- OUTCOMES ------------------ I should really s/OUTCOMES/ACTIONS/

function heroDeath(gear)
	gameLost()
end

function green1Death(gear)
	gameLost()
end

function battleWin(gear)
	-- add stats
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
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Somewhere in the planet of fruits a terrible war is about to begin..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("I was told that as the leader of the king's guard, no one knows this world better than you!"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("So, I kindly ask for your help."), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {green1.gear, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("You couldn't have come to a worse time Hog Solo!"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("The clan of the Red Strawberry wants to take over the dominion and overthrone king Pineapple."), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("Under normal circumstances we could easily defeat them but we have kindly sent most of our men to the kingdom of sand to help to the annual dusting of the king's palace."), SAY_SAY, 8000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("However the army of Yellow Watermellons is about to attack any moment now."), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("I would gladly help you if we won this battle but under these circumstances I'll only help you if you fight for our side."), SAY_SAY, 6000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("What do you say? Will you fight for us?"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = ShowMission, args = {missionName, loc("Ready for Battle?"), loc("Walk left if you want to join Captain Lime or right if you want to decline his offer"), 1, 7000}})
	table.insert(dialog01, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG 02 - Hero selects to fight	
	AddSkipFunction(dialog02, Skipanim, {dialog02})
	table.insert(dialog02, {func = AnimWait, args = {green1.gear, 3000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("You choose well Hog Solo!"), SAY_SAY, 3000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("I have only 3 hogs available and they are all cadets"), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("As more experienced I want you to lead them to the battle"), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("I of cource will observe the battle and intervene if necessary"), SAY_SAY, 5000}})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 5000}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("No problem Captain! The enemies aren't many anyway, it is going to be easy!"), SAY_SAY, 5000}})
	table.insert(dialog02, {func = AnimWait, args = {green1.gear, 5000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("Don't be fool son, they'll be more"), SAY_SAY, 3000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("Try to be smart and eliminate them quickly. This way you might scare the rest!"), SAY_SAY, 5000}})
	table.insert(dialog02, {func = startBattle, args = {hero.gear}})
	-- DIALOG 03 - Hero selects to flee
	AddSkipFunction(dialog03, Skipanim, {dialog03})
	table.insert(dialog03, {func = AnimWait, args = {green1.gear, 3000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Too bad... Then you should really leave!"), SAY_SAY, 3000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Things are going to get messy around here"), SAY_SAY, 3000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Also, you should know that the only place that you can fly would be the most left one"), SAY_SAY, 5000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("All the other places are protected by our anti flying weapons"), SAY_SAY, 4000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("Now go and don't waste more of my time you coward..."), SAY_SAY, 4000}})
	table.insert(dialog03, {func = startBattle, args = {hero.gear}})
end

------------- OTHER FUNCTIONS ---------------

function startBattle()
	AnimSwitchHog(yellow1.gear)
	TurnTimeLeft = 0
end

function gameLost()	
	SendStat('siGameResult', loc("Green Bananas lost, try again!")) --1
	SendStat('siCustomAchievement', loc("Tips...")) --11
	SendStat('siPlayerKills','1',teamC.name)
	SendStat('siPlayerKills','0',teamA.name)
	SendStat('siPlayerKills','0',teamB.name)
	EndGame()
end

function getNextWave()
	if TotalRounds == 4 then
		RestoreHog(yellowArmy[3].gear)
		AnimCaption(hero.gear, loc("Next wave in 3 turns"), 5000)
	elseif TotalRounds == 7 then
		RestoreHog(yellowArmy[4].gear)
		RestoreHog(yellowArmy[5].gear)
		AnimCaption(hero.gear, loc("Last wave in 3 turns"), 5000)
	elseif TotalRounds == 10 then
		RestoreHog(yellowArmy[6].gear)
		RestoreHog(yellowArmy[7].gear)
	end
end

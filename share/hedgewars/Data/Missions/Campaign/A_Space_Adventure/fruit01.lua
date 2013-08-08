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
-- hogs
local hero = {}
local yellow1 = {}
local yellow2 = {}
local yellow3 = {}
local green1 = {}
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
green2.name = "Mister Pear"
green3.name = "Lady Mango"
green4.name = "Green Hog Grape"
yellow1.name = "General Lemon"
yellow1.x = 1300
yellow1.y = 1500
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
	HealthCaseAmount = 30
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
	-- Yellow Watermellons
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	yellow1.gear = AddHog(yellow1.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(yellow1.gear, yellow1.x, yellow1.y)
	
	AnimInit()
	AnimationSetup()	
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onHeroSelect, {hero.gear}, heroSelect, {hero.gear}, 0)
	
	AddAnim(dialog01)
	SendHealthStatsOff()
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
	end
end

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)   
	end
end

-------------- EVENTS ------------------

function onHeroDeath(gear)
	if hero.dead then
		return true
	end
	return false
end

function onHeroSelect(gear)
	if GetX(hero.gear) ~= hero.x then
		return true
	end
	return false
end

-------------- OUTCOMES ------------------ I should really s/OUTCOMES/ACTIONS/

function heroDeath(gear)
	SendStat('siGameResult', loc("Green Bananas lost, try again!")) --1
	SendStat('siCustomAchievement', loc("Tips...")) --11
	SendStat('siPlayerKills','1',teamC.name)
	SendStat('siPlayerKills','0',teamA.name)
	SendStat('siPlayerKills','0',teamB.name)
	EndGame()
end

function heroSelect(gear)
	FollowGear(hero.gear)
	if GetX(hero.gear) < hero.x then
		chooseToBattle = true
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
	
end

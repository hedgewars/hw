------------------- ABOUT ----------------------
--
-- In this adventure hero gets the lost part with
-- the help of the green bananas hogs.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Fruit planet, Searching the Part!")
local inBattle = false
-- dialogs
local dialog01 = {}
local dialog02 = {}
local dialog03 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Ready for Battle?"), loc("Walk left if you want to join Captain Lime or right if you want to decline his offer"), 1, 4000},
	[dialog02] = {missionName, loc("Battle Starts Now!"), loc("You have choose to fight! Lead the Green Bananas to battle and try not to let them be killed"), 1, 4000},
	[dialog03] = {missionName, loc("Ready for Battle?"), loc("You have choose to flee... Unfortunately the only place where you can launch your saucer is in the most left side of the map"), 1, 4000},
}
-- crates types=[0:ammo,1:utility,2:health]
local crates = {
	{type = 0, name = amDEagle, x = 1680, y = 1650},
	{type = 0, name = amGirder, x = 1680, y = 1160},
	{type = 0, name = amWatermelon, x = 1360, y = 1870},
	{type = 0, name = amRope, x = 1400, y = 1870},
}
-- hogs
local hero = {}
local green1 = {}
local green2 = {}
local green3 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
local teamD = {}
-- hedgehogs values
hero.name = "Hog Solo"
hero.x = 1200
hero.y = 820
hero.dead = false
green1.name = "Captain Lime"
green1.x = 1050
green1.y = 820
green2.name = "Mister Pear"
green2.x = 1350
green2.y = 820
green3.name = "Lady Mango"
green3.x = 1450
green3.y = 820
local redHedgehogs = {
	{ name = "Poisonous Apple" },
	{ name = "Dark Strawberry" },
	{ name = "Watermelon Heart" },
	{ name = "Deadly Grape" }
}
teamA.name = loc("Hog Solo and GB")
teamA.color = tonumber("38D61C",16) -- green
teamB.name = loc("Captain Lime")
teamB.color = tonumber("38D61C",16) -- green
teamC.name = loc("Fruit Assasins")
teamC.color = tonumber("FF0000",16) -- red

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
	Map = "fruit02_map"
	Theme = "Fruit"
	
	-- Hog Solo and Green Bananas
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)	
	green2.gear = AddHog(green2.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(green2.gear, green2.x, green2.y)
	HogTurnLeft(green2.gear, true)
	green3.gear = AddHog(green3.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(green3.gear, green3.x, green3.y)
	HogTurnLeft(green3.gear, true)
	-- Captain Lime
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	green1.gear =  AddHog(green1.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(green1.gear, green1.x, green1.y)
	-- Fruit Assasins
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	for i=1,table.getn(redHedgehogs) do
		redHedgehogs[i].gear =  AddHog(redHedgehogs[i].name, 0, 100, "war_desertgrenadier1")
		AnimSetGearPosition(redHedgehogs[i].gear, 2010 + 50*i, 630)
	end

	AnimInit()
	--AnimationSetup()	
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	
	-- Hog Solo and GB weapons
	AddAmmo(hero.gear, amFirePunch, 3)
	AddAmmo(hero.gear, amSwitch, 100)
	-- Assasins weapons
	AddAmmo(redHedgehogs[1].gear, amBazooka, 6)
	AddAmmo(redHedgehogs[1].gear, amGrenade, 6)
	for i=1,table.getn(redHedgehogs) do
		HideHog(redHedgehogs[i].gear)
	end
	
	-- place crates
	for i=1,table.getn(crates) do
		SpawnAmmoCrate(crates[i].x, crates[i].y, crates[i].name)
	end
	
	-- explosives
	-- I wanted to use FindPlace but doesn't accept height values...
	local x1 = 950
	local x2 = 1305
	local y1 = 1210
	local y2 = 1620
	while true do
		if y2<y1 then
			break
		end
		if x2<x1 then
			x2 = 1305
			y2 = y2 -60
		end
		if not TestRectForObstacle(x2+25, y2+25, x2-25, y2-25, true) then
			AddGear(x2, y2, gtExplosives, 0, 0, 0, 0)
		end
		x2 = x2 - 30
	end
	AddGear(3128, 1680, gtExplosives, 0, 0, 0, 0)
	--mines
	AddGear(3135, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3145, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3155, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3165, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3175, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3115, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3105, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3095, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3085, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3075, 1680, gtMine, 0, 0, 0, 0)
	
	--AddAnim(dialog01)
	SendHealthStatsOff()
end

function onNewTurn()
	if CurrentHedgehog == green1.gear then
		TurnTimeLeft = 0
	elseif not inBattle then
		TurnTimeLeft = -1
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
	end
end

function onAmmoStoreInit()
	SetAmmo(amDEagle, 0, 0, 0, 6)
	SetAmmo(amGirder, 0, 0, 0, 3)
	SetAmmo(amRope, 0, 0, 0, 1)
	SetAmmo(amWatermelon, 0, 0, 0, 1)
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

-------------- ACTIONS ------------------

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
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("However the army of Yellow Watermelons is about to attack any moment now."), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("I would gladly help you if we won this battle but under these circumstances I'll only help you if you fight for our side."), SAY_SAY, 6000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("What do you say? Will you fight for us?"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = ShowMission, args = {missionName, loc("Ready for Battle?"), loc("Walk left if you want to join Captain Lime or right if you want to decline his offer"), 1, 7000}})
	table.insert(dialog01, {func = AnimSwitchHog, args = {hero.gear}})
end

------------- OTHER FUNCTIONS ---------------


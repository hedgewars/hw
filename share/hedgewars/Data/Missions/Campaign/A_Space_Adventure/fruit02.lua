------------------- ABOUT ----------------------
--
-- In this adventure hero gets the lost part with
-- the help of the green bananas hogs.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Fruit planet, Searching the Device!")
local inBattle = false
local tookPartInBattle = false
-- dialogs
local dialog01 = {}
local dialog02 = {}
local dialog03 = {}
local dialog04 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting the Device"), loc("With the help of the other hogs search for the device").."|"..loc("Hog Solo has to reach the last crates"), 1, 4000},
	[dialog02] = {missionName, loc("Getting the Device"), loc("Explore the tunnel with the other hogs and search for the device").."|"..loc("Hog Solo has to reach the last crates"), 1, 4000},
	[dialog03] = {missionName, loc("Return to the Surface"), loc("Go to the surface!").."|"..loc("Attack Captain Lime before he attacks back"), 1, 4000},
	[dialog04] = {missionName, loc("Return to the Surface"), loc("Go to the surface!").."|"..loc("Attack the assasins before they attack back"), 1, 4000},
}
-- crates types=[0:ammo,1:utility,2:health]
local crates = {
	{type = 0, name = amDEagle, x = 1680, y = 1650},
	{type = 0, name = amGirder, x = 1680, y = 1160},
	{type = 0, name = amRope, x = 1400, y = 1870},
}
local weaponCrate = { x = 1360, y = 1870}
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
	AnimationSetup()	
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	if GetCampaignVar(Fruit01JoinedBattle) and GetCampaignVar(Fruit01JoinedBattle) == "true" then
		tookPartInBattle = true
	end
	
	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onDeviceCrates, {hero.gear}, deviceCrates, {hero.gear}, 0)
	
	-- Hog Solo and GB weapons
	AddAmmo(hero.gear, amFirePunch, 3)
	AddAmmo(hero.gear, amSwitch, 100)
	AddAmmo(hero.gear, amTeleport, 100)
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
	if tookPartInBattle then
		SpawnAmmoCrate(weaponCrate.x, weaponCrate.y, amWatermelon)
	else
		SpawnAmmoCrate(weaponCrate.x, weaponCrate.y, amSniperRifle)		
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
	
	if tookPartInBattle then
		AddAnim(dialog01)
	else
		AddAnim(dialog02)
	end
	
	SendHealthStatsOff()
end

function onNewTurn()
	WriteLnToConsole("TURNS "..TotalRounds.." and hog: "..CurrentHedgehog)
	if not inBattle and CurrentHedgehog == green1.gear then
		TurnTimeLeft = 0
	elseif CurrentHedgehog == green2.gear or CurrentHedgehog == green3.gear then
		if inBattle then
			SwitchHog(hero.gear)
			TurnTimeLeft = 20000
		else
			TurnTimeLeft = 0
		end
	elseif inBattle then
		WriteLnToConsole("IN BATTLE")
		TurnTimeLeft = 20000
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
	SetAmmo(amSniperRifle, 0, 0, 0, 1)
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

function onDeviceCrates(gear)
	if not hero.dead and GetY(hero.gear)>1850 and GetX(hero.gear)>1340 then
		return true
	end
	return false
end

function onSurface(gear)
	if not hero.dead and GetY(hero.gear)<850 and  StoppedGear(hero.gear) then
		return true
	end
	return false
end

-------------- ACTIONS ------------------

function heroDeath(gear)
	EndGame()
end

function deviceCrates(gear)
	TurnTimeLeft = 0
	if not tookPartInBattle then
		AddAnim(dialog03)
	else
		for i=1,table.getn(redHedgehogs) do
			RestoreHog(redHedgehogs[i].gear)
		end
		AddAnim(dialog04)
	end
	AddAmmo(hero.gear, amSwitch, 0)
	AddEvent(onSurface, {hero.gear}, surface, {hero.gear}, 0)
end

function surface(gear)
	-- TODO: after going to the surface first round must be played by the player
	AnimSwitchHog(hero.gear)
	TurnTimeLeft = 20000
	inBattle = true
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
    TurnTimeLeft = 0
end

function AnimationSetup()
	-- DIALOG 01 - Start, Captain Lime helps Hog Solo because he took part in the battle
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Somewhere else in the planet of fruits Captain Lime helps Hog Solo..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("You fought bravely and you helped us win this battle!"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("So, as promised I have brought you where I think that the device you are looking is hidden."), SAY_SAY, 7000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("I know that your resources are low due to the battle but I'll send with you two of my best hogs to assist you."), SAY_SAY, 7000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("Good luck!"), SAY_SAY, 2000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG02 - Start, Hog Solo escaped from the previous battle
	AddSkipFunction(dialog02, Skipanim, {dialog02})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog02, {func = AnimCaption, args = {hero.gear, loc("Somewhere else in the planet of fruits Hog Solo gets closer to the device..."), 5000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("You are the one who fled! So, you are alive..."), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("I'm still low on hogs. If you are not afraid I could use a set of extra hands"), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 8000}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("I am sorry but I was looking for a device that may be hidden somewhere around here"), SAY_SAY, 4500}})
	table.insert(dialog02, {func = AnimWait, args = {green1.gear, 12500}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("Many long forgotten things can be found in the same tunnels that we are about to search!"), SAY_SAY, 7000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("If you help us you can keep the device if you find it but we'll keep everything else"), SAY_SAY, 7000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("What do you say? Are you in?"), SAY_SAY, 3000}})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 1800}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("Ok then!"), SAY_SAY, 2000}})
	table.insert(dialog02, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG03 - At crates, hero learns that Captain Lime is bad
	AddSkipFunction(dialog03, Skipanim, {dialog03})
	table.insert(dialog03, {func = AnimWait, args = {hero.gear, 4000}})
	table.insert(dialog03, {func = FollowGear, args = {hero.gear}})
	table.insert(dialog03, {func = AnimSay, args = {hero.gear, loc("Hoo Ray! I've found it, now I have to get back to Captain Lime!"), SAY_SAY, 4000}})
	table.insert(dialog03, {func = AnimWait, args = {green1.gear, 4000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("This Hog Solo is so naive! I am gonna shoot him when he returns and keep his device for me!"), SAY_THINK, 4000}})
	table.insert(dialog03, {func = goToThesurface, args = {hero.gear}})
	-- DIALOG04 - At crates, hero learns about the assasins ambush
	AddSkipFunction(dialog04, Skipanim, {dialog04})
	table.insert(dialog04, {func = AnimWait, args = {hero.gear, 4000}})
	table.insert(dialog04, {func = FollowGear, args = {hero.gear}})
	table.insert(dialog04, {func = AnimSay, args = {hero.gear, loc("Hoo Ray! I've found it, now I have to get back to Captain Lime!"), SAY_SAY, 4000}})
	table.insert(dialog04, {func = AnimWait, args = {redHedgehogs[1].gear, 4000}})
	table.insert(dialog04, {func = AnimSay, args = {redHedgehogs[1].gear, loc("We have spotted the enemy! We'll attack when the enemies start gathering!"), SAY_THINK, 4000}})
	table.insert(dialog04, {func = goToThesurface, args = {hero.gear}})
end

------------- OTHER FUNCTIONS ---------------

function goToThesurface()
	TurnTimeLeft = 0
end

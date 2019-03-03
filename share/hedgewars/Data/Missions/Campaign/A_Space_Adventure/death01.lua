------------------- ABOUT ----------------------
--
-- This is the mission to acquire the last part.
-- This mission is the cameo of Professor Hogevil
-- who has took hostages H and Dr. Cornelius.
-- The hero has to defeat him and his thugs.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("The last encounter")
-- dialogs
local dialog01 = {}
-- missions objectives
local goals = {
	[dialog01] = {missionName, loc("The final part"), loc("Defeat Professor Hogevil!") .. "|" .. loc("Mines time: 1.5 seconds"), 1, 4500},
}
-- crates
local teleportCrate = {x = 1935, y = 1830}
local drillCrate = {x = 3810, y = 1705}
local batCrate = {x = 1975, y = 1830}
local blowtorchCrate = {x = 1520, y = 1950}
local cakeCrate = {x = 325, y = 1500}
local ropeCrate = {x = 1860, y = 500}
local pickHammerCrate = {x = 1900, y = 400}
-- hogs
local hero = {}
local paoth1 = {}
local paoth2 = {}
local professor = {}
local thug1 = {}
local thug2 = {}
local thug3 = {}
local thug4 = {}
local thug5 = {}
local thug6 = {}
local thug7 = {}
local thugs = { thug1, thug2, thug3, thug4, thug5, thug6, thug7 }
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
local teamD = {}
-- hedgehogs values
hero.name = loc("Hog Solo")
hero.x = 520
hero.y = 871
hero.dead = false
paoth1.name = loc("H")
paoth1.x = 3730
paoth1.y = 1538
paoth2.name = loc("Dr. Cornelius")
paoth2.x = 3800
paoth2.y = 1538
professor.name = loc("Prof. Hogevil")
professor.dead = false
thug1.x = 1265
thug1.y = 1465
thug1.health = 70
thug2.x = 2035
thug2.y = 1380
thug2.health = 95
thug3.x = 1980
thug3.y = 863
thug3.health = 35
thug3.turnLeft = true
thug4.x = 2830
thug4.y = 2007
thug4.health = 80
thug5.x = 2890
thug5.y = 2007
thug5.health = 80
thug6.x = 2940
thug6.y = 2007
thug6.health = 80
thug7.x = 2990
thug7.y = 2007
thug7.health = 80
teamA.name = loc("Hog Solo")
teamA.color = -6
teamB.name = loc("PAotH")
teamB.color = teamA.color
teamC.name = loc("Professor's Team")
teamC.color = -2
teamD.name = loc("Professor")
teamD.color = -2

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	TurnTime = 25000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1500
	Explosives = 0
	HealthCaseAmount = 50
	-- gfTagTeam makes it easier to skip the PAotH team
	GameFlags = gfTagTeam
	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0
	Map = "death01_map"
	Theme = "Hell"

	-- Hero
	teamA.name = AddMissionTeam(teamA.color)
	hero.gear = AddMissionHog(100)
	hero.name = GetHogName(hero.gear)
	AnimSetGearPosition(hero.gear, hero.x, hero.y)

	-- PAotH (passive team)
	teamB.name = AddTeam(teamB.name, teamB.color, "Earth", "Island", "Default", "cm_galaxy")
	SetTeamPassive(teamB.name, true)
	paoth1.gear = AddHog(paoth1.name, 0, 100, "hair_yellow")
	AnimSetGearPosition(paoth1.gear, paoth1.x, paoth1.y)
	HogTurnLeft(paoth1.gear, true)
	SetGearAIHints(paoth1.gear, aihDoesntMatter)
	paoth2.gear = AddHog(paoth2.name, 0, 100, "Glasses")
	AnimSetGearPosition(paoth2.gear, paoth2.x, paoth2.y)
	HogTurnLeft(paoth2.gear, true)
	SetGearAIHints(paoth2.gear, aihDoesntMatter)

	-- Professor's Team (computer enemy)
	teamC.name = AddTeam(teamC.name, teamC.color, "eyecross", "Island", "Default", "cm_sine")
	professor.bot = AddHog(professor.name, 1, 300, "tophats")
	AnimSetGearPosition(professor.bot, paoth1.x - 100, paoth1.y)
	HogTurnLeft(professor.bot, true)
	professor.gear = professor.bot
	for i=1,table.getn(thugs) do
		thugs[i].gear = AddHog(string.format(loc("Thug #%d"), i), 1, thugs[i].health, "war_desertgrenadier1")
		AnimSetGearPosition(thugs[i].gear, thugs[i].x, thugs[i].y)
		HogTurnLeft(thugs[i].gear, not thugs[i].turnLeft)
	end

	-- Professor (special team for cut sequence only)
	teamD.name = AddTeam(teamD.name, teamD.color, "star", "Island", "Default", "cm_sine")
	professor.human = AddHog(professor.name, 0, 300, "tophats")
	-- hog will be removed and replaced by professor.bot after cut sequence
	AnimSetGearPosition(professor.human, hero.x + 70, hero.y)
	HogTurnLeft(professor.human, true)

	initCheckpoint("death01")

	AnimInit(true)
	AnimationSetup()
end

function onGameStart()
	ShowMission(unpack(goals[dialog01]))
	HideMission()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onEnemiesDeath, {hero.gear}, enemiesDeath, {hero.gear}, 0)

	-- add crates
	SpawnSupplyCrate(teleportCrate.x, teleportCrate.y, amTeleport)
	SpawnSupplyCrate(drillCrate.x, drillCrate.y, amTeleport)
	SpawnSupplyCrate(drillCrate.x, drillCrate.y, amDrill)
	SpawnSupplyCrate(batCrate.x, batCrate.y, amBaseballBat)
	SpawnSupplyCrate(blowtorchCrate.x, blowtorchCrate.y, amBlowTorch)
	SpawnSupplyCrate(cakeCrate.x, cakeCrate.y, amCake)
	SpawnSupplyCrate(ropeCrate.x, ropeCrate.y, amRope)
	SpawnSupplyCrate(pickHammerCrate.x, pickHammerCrate.y, amPickHammer)
	SpawnHealthCrate(cakeCrate.x + 40, cakeCrate.y)
	SpawnHealthCrate(blowtorchCrate.x + 40, blowtorchCrate.y)
	-- add explosives
	AddGear(1900, 850, gtExplosives, 0, 0, 0, 0)
	AddGear(1900, 800, gtExplosives, 0, 0, 0, 0)
	AddGear(1900, 750, gtExplosives, 0, 0, 0, 0)
	AddGear(1900, 710, gtExplosives, 0, 0, 0, 0)

	AddGear(698, 1544, gtExplosives, 0, 0, 0, 0)
	-- add mines
	AddGear(3520, 1650, gtMine, 0, 0, 0, 0)
	AddGear(3480, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3440, 1690, gtMine, 0, 0, 0, 0)
	AddGear(3400, 1710, gtMine, 0, 0, 0, 0)
	AddGear(2100, 1730, gtMine, 0, 0, 0, 0)
	AddGear(2150, 1730, gtMine, 0, 0, 0, 0)
	AddGear(2200, 1750, gtMine, 0, 0, 0, 0)

	AddGear(1891, 1468, gtMine, 0, 0, 0, 0)
	-- add girders
	PlaceGirder(3770, 1370, 4)
	PlaceGirder(3700, 1460, 6)
	PlaceGirder(3840, 1460, 6)

	-- add ammo
	-- hero ammo
	AddAmmo(hero.gear, amRope, 2)
	AddAmmo(hero.gear, amBazooka, 3)
	AddAmmo(hero.gear, amParachute, 1)
	AddAmmo(hero.gear, amGrenade, 6)
	AddAmmo(hero.gear, amDEagle, 4)
	AddAmmo(hero.gear, amSkip, 100)
	local bonus = tonumber(getBonus(3))
	if bonus > 0 then
		SetHealth(hero.gear, 120)
		AddAmmo(hero.gear, amLaserSight, 1)
		saveBonus(3, bonus-1)
	end
	-- evil ammo
	AddAmmo(professor.gear, amRope, 4)
	AddAmmo(professor.gear, amBazooka, 8)
	AddAmmo(professor.gear, amSwitch, 100)
	AddAmmo(professor.gear, amGrenade, 8)
	AddAmmo(professor.gear, amDEagle, 8)

	HideHog(professor.bot)
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

function onAmmoStoreInit()
	SetAmmo(amCake, 0, 0, 0, 1)
	SetAmmo(amTeleport, 0, 0, 0, 1)
	SetAmmo(amBaseballBat, 0, 0, 0, 4)
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amRope, 0, 0, 0, 2)
	SetAmmo(amPickHammer, 0, 0, 0, 1)
	SetAmmo(amDrill, 0, 0, 0, 1)
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	elseif gear == professor.gear then
		professor.dead = true
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

function onEnemiesDeath(gear)
	local allDead = true
	if GetHealth(hero.gear) and professor.dead then
		for i=1,table.getn(thugs) do
			if GetHealth(thugs[i]) then
				allDead = false
				break
			end
		end
	else
		allDead = false
	end
	return allDead
end

-------------- ACTIONS ------------------

function heroDeath(gear)
	SendStat(siGameResult, string.format(loc("%s lost, try again!"), hero.name))
	SendStat(siCustomAchievement, loc("To win the game you have to eliminate Professor Hogevil."))
	sendSimpleTeamRankings({teamC.name, teamA.name, teamB.name})
	EndGame()
end

function enemiesDeath(gear)
	saveCompletedStatus(6)
	SendStat(siGameResult, loc("Congratulations, you won!"))
	SendStat(siCustomAchievement, loc("You have successfully eliminated Professor Hogevil."))
	SendStat(siCustomAchievement, loc("You have rescued H and Dr. Cornelius."))
	SendStat(siCustomAchievement, loc("You have acquired the last device part."))
	SendStat(siCustomAchievement, loc("Now go and play the menu mission to complete the campaign."))
	sendSimpleTeamRankings({teamA.name, teamB.name, teamC.name})
	EndGame()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	startBattle()
end

function AnimationSetup()
	local profDiedOnMoon = GetCampaignVar("ProfDiedOnMoon") == "1"
	-- DIALOG01, GAME START, INTRODUCTION
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Somewhere on the uninhabitable Death Planet ..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {professor.human, string.format(loc("Welcome, %s, surprised to see me?"), hero.name), SAY_SAY, 4000}})
	if profDiedOnMoon then
		table.insert(dialog01, {func = AnimSay, args = {professor.human, loc("After you left the moon, my other loyal minions came and resurrected me so I could complete my master plan."), SAY_SAY, 6000}})
	else
		table.insert(dialog01, {func = AnimSay, args = {professor.human, loc("As you can see I have survived our last encounter and I had time to plot my master plan!"), SAY_SAY, 4000}})
	end
	table.insert(dialog01, {func = AnimSay, args = {professor.human, loc("I've thought that the best way to get the device is to let you collect most of the parts for me!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {professor.human, loc("So, now I got the last part and I have your friends captured."), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {professor.human, loc("Will you give me the other parts?"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("I will never hand you the parts!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimWait, args = {professor.human, 3000}})
	if profDiedOnMoon then
		table.insert(dialog01, {func = AnimSay, args = {professor.human, loc("Then prepare for battle!"), SAY_SHOUT, 4000}})
	else
		table.insert(dialog01, {func = AnimSay, args = {professor.human, loc("Then prepare for battle!"), SAY_SAY, 4000}})
	end
	table.insert(dialog01, {func = startBattle, args = {}})
end

-------------- OTHER FUNCTIONS -----------------

function startBattle()
	ShowMission(unpack(goals[dialog01]))
	AddVisualGear(GetX(professor.human), GetY(professor.human), vgtExplosion, 0, false)
	HideHog(professor.human)
	RestoreHog(professor.bot)
	AddVisualGear(GetX(professor.bot), GetY(professor.bot), vgtExplosion, 0, false)
	PlaySound(sndWarp)
	SetGearMessage(hero.gear, 0)
	AnimSwitchHog(professor.gear)
	FollowGear(professor.gear)
	EndTurn(true)
end

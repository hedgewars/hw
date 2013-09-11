------------------- ABOUT ----------------------
--
-- Hog Solo has to catch the other hog in order
-- to get infoormations about the origin of Pr. Hogevil

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("Chasing ghosts in moon")
local challengeObjectives = loc("Use your available weapons in order to catch the other hog").."|"..
	loc("You have to stand very close to him")
local currentPosition = 1
local previousTimeLeft = 0
local startChallenge = false
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Challenge Objectives"), challengeObjectives, 1, 4500},
}
-- hogs
local hero = {
	name = loc("Hog Solo"),
	x = 1300,
	y = 850
}
local runner = {
	name = loc("Crazy Runner"),
	places = {
		{x = 1400,y = 850, turnTime = 0},
		{x = 3880,y = 33, turnTime = 30000},
		{x = 250,y = 1780, turnTime = 25000},
		{x = 3850,y = 1940, turnTime = 20000},
	}
}
-- teams
local teamA = {
	name = loc("Hog Solo"),
	color = tonumber("38D61C",16) -- green
}
local teamB = {
	name = loc("Crazy Runner"),
	color = tonumber("FF0000",16) -- red
}

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	GameFlags = gfDisableWind
	Seed = 1
	TurnTime = 25000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Map = "moon02_map"
	Theme = "Cheese"
	
	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 1, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	-- Crazy Runner
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	runner.gear = AddHog(runner.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(runner.gear, runner.places[1].x, runner.places[1].y)
	HogTurnLeft(runner.gear, true)
	
	initCheckpoint("moon02")
	
	AnimInit()
	AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	ShowMission(missionName, loc("Challenge Objectives"), challengeObjectives, -amSkip, 0)
	
	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	
	AddAmmo(hero.gear, amRope, 1)
	AddAmmo(hero.gear, amSkip, 1)
	AddAmmo(hero.gear, amTeleport, 100)
	
	SendHealthStatsOff()
	hogTurn = runner.gear
	AddAnim(dialog01)
end

function onNewTurn()
	WriteLnToConsole("NEW TURN "..CurrentHedgehog)
	if startChallenge then
		if CurrentHedgehog ~= hero.gear then
			TurnTimeLeft = 0
		else
			if GetAmmoCount(hero.gear, amRope) == 0  then
				lose()
			end
			TurnTimeLeft = runner.places[currentPosition].turnTime + previousTimeLeft
			previousTimeLeft = 0
		end
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

function onGameTick20()
	if isHeroNextToRunner() then
		moveRunner()
	end
end

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)   
	end
end

-------------- EVENTS ------------------

function onHeroDeath(gear)
	if not GetHealth(hero.gear) then
		return true
	end
	return false
end

-------------- ACTIONS ------------------

function heroDeath(gear)
	-- game over
	WriteLnToConsole("END GAME 1")
	EndGame()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
    if anim == dialog01 then
		moveRunner()
    end
end

function AnimationSetup()
	-- DIALOG 01 - Start, game instructions
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3200}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("In the other side of the moon..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {runner.gear, loc("So you are interested in Pr. Hogevil"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {runner.gear, loc("We'll play a game first"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {runner.gear, loc("I'll let you know whatever I know about him if you manage to catch me 3 times"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {runner.gear, loc("Let's go!"), SAY_SAY, 2000}})	
	table.insert(dialog01, {func = moveRunner, args = {}})	
end

------------- other functions ---------------

function isHeroNextToRunner()
	if GetHealth(hero.gear) and math.abs(GetX(hero.gear) - GetX(runner.gear)) < 75 and
			math.abs(GetY(hero.gear) - GetY(runner.gear)) < 75 and StoppedGear(hero.gear) then
		return true
	end
	return false
end

function moveRunner()
	if not startChallenge then
		startChallenge = true
	end
	AddAmmo(hero.gear, amRope, 1)
	-- add anim dialogs here
	if currentPosition ~= 1 then
		PlaySound(sndVictory)
		AnimSay(runner.gear, loc("You got me"), SAY_SAY, 3000)
		previousTimeLeft = TurnTimeLeft
	end
	currentPosition = currentPosition + 1
	SetGearPosition(runner.gear, runner.places[currentPosition].x, runner.places[currentPosition].y)
	WriteLnToConsole("HERE 1")
		WriteLnToConsole("HERE A")
		TurnTimeLeft = 0
	WriteLnToConsole("HERE 2")
end

function lose()
	-- game over
	WriteLnToConsole("ROPE "..GetAmmoCount(hero.gear, amRope))
	WriteLnToConsole("PREVIOUS TIME "..previousTimeLeft)
	WriteLnToConsole("HOG "..CurrentHedgehog)
	WriteLnToConsole("TurnTimeLeft "..TurnTimeLeft)
	WriteLnToConsole("END GAME 2")
	EndGame()
end

function heroOutOfRope()
	if GetAmmoCount(hero.gear, amRope) == 0  then
		return true
	end
	return false
end

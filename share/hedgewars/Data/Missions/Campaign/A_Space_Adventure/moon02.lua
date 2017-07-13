------------------- ABOUT ----------------------
--
-- Hog Solo has to catch the other hog in order
-- to get informations about the origin of Pr. Hogevil

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("Chasing the blue hog")
local challengeObjectives = loc("Use the rope in order to catch the blue hedgehog").."|"..
	loc("You have to stand very close to him")
local currentPosition = 1
local previousTimeLeft = 0
local startChallenge = false
-- dialogs
local dialog01 = {}
local dialog02 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Challenge objectives"), challengeObjectives, 1, 4500},
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
	runner.gear = AddHog(runner.name, 0, 100, "sth_Sonic")
	AnimSetGearPosition(runner.gear, runner.places[1].x, runner.places[1].y)
	HogTurnLeft(runner.gear, true)

	initCheckpoint("moon02")

	AnimInit()
	AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	ShowMission(missionName, loc("Challenge objectives"), challengeObjectives, -amSkip, 0)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)

	AddAmmo(hero.gear, amRope, 1)

	SendHealthStatsOff()
	hogTurn = runner.gear
	AddAnim(dialog01)
end

function onNewTurn()
	if startChallenge and currentPosition < 5 then
		if CurrentHedgehog ~= hero.gear then
			TurnTimeLeft = 0
		else
			if GetAmmoCount(hero.gear, amRope) == 0  then
				lose()
			end
			SetWeapon(amRope)
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
	if GetHealth(hero.gear) and startChallenge and isHeroNextToRunner() and currentPosition < 5 then
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
	lose()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
    if anim == dialog01 then
		moveRunner()
	elseif anim == dialog02 then
		win()
    end
end

function AnimationSetup()
	-- DIALOG 01 - Start, game instructions
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3200}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("On the other side of the moon ..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {runner.gear, loc("So you are interested in Professor Hogevil, huh?"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {runner.gear, loc("We'll play a game first."), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {runner.gear, loc("I'll let you know whatever I know about him if you manage to catch me 3 times."), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {runner.gear, loc("Let's go!"), SAY_SAY, 2000}})
	table.insert(dialog01, {func = moveRunner, args = {}})
	-- DIALOG 02 - Hog Solo story
	AddSkipFunction(dialog02, Skipanim, {dialog02})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 3200}})
	table.insert(dialog02, {func = AnimCaption, args = {hero.gear, loc("The truth about Professor Hogevil"), 5000}})
	table.insert(dialog02, {func = AnimSay, args = {runner.gear, loc("Amazing! I was never beaten in a race before!"), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {runner.gear, loc("So, let me tell you what I know about Professor Hogevil."), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {runner.gear, loc("Professor Hogevil, then known as James Hogus, worked for PAotH back in my time."), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {runner.gear, loc("He was the lab assistant of Dr. Goodhogan, the inventor of the anti-gravity device."), SAY_SAY, 5000}})
	table.insert(dialog02, {func = AnimSay, args = {runner.gear, loc("During the final testing of the device an accident happened."), SAY_SAY, 5000}})
	table.insert(dialog02, {func = AnimSay, args = {runner.gear, loc("In this accident, Professor Hogevil lost all his spines on his head!"), SAY_SAY, 5000}})
	table.insert(dialog02, {func = AnimSay, args = {runner.gear, loc("That's why he always wears a hat since then."), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {runner.gear, loc("After that incident he went underground and started working on his plan to steal the device."), SAY_SAY, 5000}})
	table.insert(dialog02, {func = AnimSay, args = {runner.gear, loc("He is a very tough and very determined hedgehog. I would be extremely careful if I were you."), SAY_SAY, 5000}})
	table.insert(dialog02, {func = AnimSay, args = {runner.gear, loc("I should go now, goodbye!"), SAY_SAY, 3000}})
	table.insert(dialog02, {func = win, args = {}})
end

------------- other functions ---------------

function isHeroNextToRunner()
	if GetGearType(hero.gear) == gtHedgehog and GetGearType(runner.gear) == gtHedgehog and
			math.abs(GetX(hero.gear) - GetX(runner.gear)) < 75 and
			math.abs(GetY(hero.gear) - GetY(runner.gear)) < 75 and StoppedGear(hero.gear) then
		return true
	end
	return false
end

function moveRunner()
	if currentPosition == 4 then
		currentPosition = currentPosition + 1
		if GetX(hero.gear) > GetX(runner.gear) then
			HogTurnLeft(runner.gear, false)
		end
		AddAnim(dialog02)
		TurnTimeLeft = 0
	elseif currentPosition < 4 then
		if not startChallenge then
			startChallenge = true
		end
		AddAmmo(hero.gear, amRope, 1)
		if currentPosition ~= 1 then
			PlaySound(sndVictory)
			if currentPosition > 1 and currentPosition < 4 then
				AnimCaption(hero.gear, loc("Go, get him again!"), 3000)
				AnimSay(runner.gear, loc("You got me!"), SAY_SAY, 3000)
			end
			previousTimeLeft = TurnTimeLeft
		end
		currentPosition = currentPosition + 1
		AddVisualGear(GetX(runner.gear), GetY(runner.gear), vgtExplosion, 0, false) 
		SetGearPosition(runner.gear, runner.places[currentPosition].x, runner.places[currentPosition].y)
		TurnTimeLeft = 0
	end
end

function lose()
	SendStat(siGameResult, loc("Too slow! Try again ..."))
	SendStat(siCustomAchievement, loc("You have to catch the other hog 3 times."))
	SendStat(siCustomAchievement, loc("The time that you have left when you reach the blue hedgehog will be added to the next turn."))
	SendStat(siCustomAchievement, loc("Each turn you'll have only one rope to use."))
	SendStat(siCustomAchievement, loc("You'll lose if you die or if your time is up."))
	SendStat(siPlayerKills,'0',teamA.name)
	EndGame()
end

function win()
	SendStat(siGameResult, loc("Congratulations, you are the fastest!"))
	SendStat(siCustomAchievement, loc("You have managed to catch the blue hedgehog in time."))
	SendStat(siPlayerKills,'1',teamA.name)
	EndGame()
end

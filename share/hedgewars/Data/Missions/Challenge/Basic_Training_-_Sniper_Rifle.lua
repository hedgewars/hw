-- Hedgewars SniperRifle Training
-- Scripting Example

-- Lines such as this one are comments - they are ignored
-- by the game, no matter what kind of text is in there.
-- It's also possible to place a comment after some real
-- instruction as you see below. In short, everything
-- following "--" is ignored.

---------------------------------------------------------------
-- At first we implement the localization library using loadfile.
-- This allows us to localize strings without needing to think
-- about translations.
-- We can use the function loc(text) to localize a string.

HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Scripts/Locale.lua")

-- This variable will hold the number of destroyed targets.
local score = 0
-- This variable will hold the number of shots from the sniper rifle
local shots = 0
-- This variable represents the number of targets to destroy.
local score_goal = 27
-- This variable controls how many milliseconds/ticks we'd
-- like to wait before we end the round once all targets
-- have been destroyed.
local end_timer = 1000 -- 1000 ms = 1 s
-- This variable is set to true if the game is lost (i.e.
-- time runs out).
local game_lost = false
-- This variable will point to the hog's gear
local player = nil
-- Current target gear
local target = nil
-- This variable will grab the time left at the end of the round
local time_goal = 0

-- Like score, but targets before a blow-up sequence count double.
-- Used to calculate final target score
local score_bonus = 0

local cinematic = false

-- Timer of dynamite (shorter than usual)
local dynamiteTimer = 2000
-- Number of dynamite gears currently in game
local dynamiteCounter = 0
-- Table of dynamite gears, indexed by gear ID
local dynamiteGears = {}

-- Position for delayed targets
local delayedTargetTargetX, delayedTargetY

-- Team name of the player's team
local playerTeamName

-- This is a custom function to make it easier to
-- spawn more targets with just one line of code
-- You may define as many custom functions as you
-- like.

-- Spawns a target at (x, y)
function spawnTarget(x, y)
	-- add a new target gear
	target = AddGear(x, y, gtTarget, 0, 0, 0, 0)
	-- have the camera move to the target so the player knows where it is
	FollowGear(target)
end

-- Remembers position to spawn a target at (x, y) after a dynamite explosion
function spawnTargetDelayed(x, y)
	delayedTargetX = x
	delayedTargetY = y
	-- The previous target always counts double after destruction
	score_bonus = score_bonus + 1
end

function getTargetScore()
	return score_bonus * 200
end

-- Cut sequence to blow up land with dynamite
function blowUp(x, y, follow)
	if cinematic == false then
		cinematic = true
		SetCinematicMode(true)
	end
	-- Spawn dynamite with short timer
	local dyna = AddGear(x, y, gtDynamite, 0, 0, 0, dynamiteTimer)
	-- Fix dynamite animation due to non-default timer
	SetTag(dyna, div(5000-dynamiteTimer, 166))
	if follow then
		FollowGear(dyna)
	end
end

function onNewTurn()
	SetWeapon(amSniperRifle)
end

-- This function is called before the game loads its
-- resources.
-- It's one of the predefined function names that will
-- be called by the game. They give you entry points
-- where you're able to call your own code using either
-- provided instructions or custom functions.
function onGameInit()
	-- At first we have to overwrite/set some global variables
	-- that define the map, the game has to load, as well as
	-- other things such as the game rules to use, etc.
	-- Things we don't modify here will use their default values.

	-- The base number for the random number generator
	Seed = 0
	-- Game settings and rules
	ClearGameFlags()
	EnableGameFlags(gfMultiWeapon, gfOneClanMode, gfArtillery)
	-- The time the player has to move each round (in ms)
	TurnTime = 150000
	-- The frequency of crate drops
	CaseFreq = 0
	-- The number of mines being placed
	MinesNum = 0
	-- The number of explosives being placed
	Explosives = 0
	-- The map to be played
	Map = "Ropes"
	-- The theme to be used
	Theme = "Golf"
	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0

	-- Create the player team
	AddMissionTeam(-1)
	playerTeamName = GetTeamName(0)
	-- And add a hog to it
	player = AddMissionHog(1)
	SetGearPosition(player, 602, 1465)
end

-- This function is called when the round starts
-- it spawns the first target that has to be destroyed.
-- In addition it shows the scenario goal(s).
function onGameStart()
	-- Disable graph in stats screen
	SendHealthStatsOff()
	-- Spawn the first target.
	spawnTarget(860,1020)

	local highscore = getReadableChallengeRecord("Highscore")
	-- Show some nice mission goals.
	-- Parameters are: caption, sub caption, description,
	-- extra text, icon and time to show.
	-- A negative icon parameter (-n) represents the n-th weapon icon
	-- A positive icon paramter (n) represents the (n+1)-th mission icon
	-- A timeframe of 0 is replaced with the default time to show.
	ShowMission(loc("Sniper Training"), loc("Aiming Practice"),
	loc("Eliminate all targets before your time runs out.|You have unlimited ammo for this mission.")
	.. "|" .. highscore, -amSniperRifle, 0)

	-- Displayed initial player score
	SetTeamLabel(playerTeamName, "0")
end

-- This function is called every game tick.
-- Note that there are 1000 ticks within one second.
-- You shouldn't try to calculate too complicated
-- code here as this might slow down your game.
function onGameTick20()
	if game_lost then
		return
	end
	-- If time's up, set the game to be lost.
	-- We actually check the time to be "1 ms" as it
	-- will be at "0 ms" right at the start of the game.
	if TurnTimeLeft < 40 and TurnTimeLeft > 0 and score < score_goal and game_lost == false then
		game_lost = true
		-- ... and show a short message.
		AddCaption(loc("Time's up!"))
		ShowMission(loc("Sniper Training"), loc("Aiming Practice"), loc("Oh no! Time's up! Just try again."), -amSkip, 0)
		-- and generate the stats and go to the stats screen
		generateStats()
		EndGame()
		-- Just to be sure set the goal time to 1 ms
		time_goal = 1
	end
	-- If the goal is reached or we've lost ...
	if score == score_goal or game_lost then
		-- ... check to see if the time we'd like to
		-- wait has passed and then ...
		if end_timer == 0 then
			-- ... end the game ...
			generateStats()
			EndGame()
		else
			-- ... or just lower the timer by 1.
			-- Reset the time left to stop the timer
			SetTurnTimeLeft(time_goal)
		end
        end_timer = end_timer - 20
	end
end

-- This function is called when the game is initialized
-- to request the available ammo and probabilities
function onAmmoStoreInit()
	-- add an unlimited supply of shotgun ammo
	SetAmmo(amSniperRifle, 9, 0, 0, 0)
end

--[[ Re-center camera to target after using sniper rifle.
This makes it easier to find the target. If we don't
do this, the camera would contantly bounce back to
the hog which would be annoying. ]]
function onAttack()
	if target and GetCurAmmoType() == amSniperRifle then
		FollowGear(target)
	end
end

-- Insta-blow up dynamite with precise key
function onPrecise()
	for gear, _ in pairs(dynamiteGears) do
		SetTimer(gear, 0)
	end
end

-- This function is called when a new gear is added.
-- We use it to count the number of shots, which we
-- in turn use to calculate the final score and stats
function onGearAdd(gear)
	if GetGearType(gear) == gtSniperRifleShot then
		shots = shots + 1
	elseif GetGearType(gear) == gtDynamite then
		dynamiteCounter = dynamiteCounter + 1
		dynamiteGears[gear] = true
	end
end

-- This function is called before a gear is destroyed.
-- We use it to count the number of targets destroyed.
function onGearDelete(gear)
	local gt = GetGearType(gear)

	if gt == gtCase then
		game_lost = true
		return
	end

	if (gt == gtDynamite) then
		-- Dynamite blow-up, used to continue the game.
		dynamiteCounter = dynamiteCounter - 1
		dynamiteGears[gear] = nil

		-- Wait for all dynamites to be destroyed before we continue.
		-- Most cut scenes spawn multiple dynamites.
		if dynamiteCounter == 0 then
			if cinematic then
				cinematic = false
				SetCinematicMode(false)
			end
			-- Now *actually* spawn the delayed target
			spawnTarget(delayedTargetX, delayedTargetY)
		end
		return
	end

	if gt == gtTarget then
		target = nil
		-- Add one point to our score/counter
		score = score + 1
		score_bonus = score_bonus + 1
		-- If we haven't reached the goal ...
		if score < score_goal then
			-- ... spawn another target.
			if score == 1 then
				spawnTarget(1520,1350)
			elseif score == 2 then
				spawnTarget(1730,1040)
			elseif score == 3 then
				spawnTarget(2080,780)
			elseif score == 4 then
				-- Short cut scene, blows up up lots up land and prepares
				-- next target position.
				AddCaption(loc("Good so far!") .. " " .. loc("Keep it up!"));
				blowUp(1730,1226)
				blowUp(1440,1595)
				blowUp(1527,1575)
				blowUp(1614,1595)
				blowUp(1420,1675, true)
				blowUp(1527,1675)
				blowUp(1634,1675)
				blowUp(1440,1755)
				blowUp(1527,1775)
				blowUp(1614,1755)
				-- Target appears *after* the cutscene.
				spawnTargetDelayed(1527,1667)
			elseif score == 5 then
				spawnTarget(2175,1300)
			elseif score == 6 then
				spawnTarget(2250,940)
			elseif score == 7 then
				spawnTarget(2665,1540)
			elseif score == 8 then
				spawnTarget(3040,1160)
			elseif score == 9 then
				spawnTarget(2930,1500)
			elseif score == 10 then
				AddCaption(loc("This one's tricky."));
				spawnTarget(700,720)
			elseif score == 11 then
				AddCaption(loc("Well done."));
				blowUp(914,1222)
				blowUp(1050,1222)
				blowUp(1160,1008)
				blowUp(1160,1093)
				blowUp(1160,1188)
				blowUp(375,911)
				blowUp(510,911)
				blowUp(640,911)
				blowUp(780,911)
				blowUp(920,911)
				blowUp(1060,913)
				blowUp(1198,913, true)
				spawnTargetDelayed(1200,830)
			elseif score == 12 then
				spawnTarget(1430,450)
			elseif score == 13 then
				spawnTarget(796,240)
			elseif score == 14 then
				spawnTarget(300,10)
			elseif score == 15 then
				spawnTarget(2080,820)
			elseif score == 16 then
				AddCaption(loc("Demolition is fun!"));
				blowUp(2110,920)
				blowUp(2210,920)
				blowUp(2200,305)
				blowUp(2300,305)
				blowUp(2300,400, true)
				blowUp(2300,500)
				blowUp(2300,600)
				blowUp(2300,700)
				blowUp(2300,800)
				blowUp(2300,900)
				blowUp(2401,305)
				blowUp(2532,305)
				blowUp(2663,305)
				spawnTargetDelayed(2300,760)
			elseif score == 17 then
				spawnTarget(2738,190)
			elseif score == 18 then
				spawnTarget(2590,-100)
			elseif score == 19 then
				AddCaption(loc("Will this ever end?"));
				blowUp(2790,305)
				blowUp(2930,305)
				blowUp(3060,305)
				blowUp(3190,305)
				blowUp(3310,305, true)
				blowUp(3393,613)
				blowUp(2805,370)
				blowUp(2805,500)
				blowUp(2805,630)
				blowUp(2805,760)
				blowUp(2805,890)
				blowUp(3258,370)
				blowUp(3258,475)
				blowUp(3264,575)
				spawnTargetDelayed(3230,290)
			elseif score == 20 then
				spawnTarget(3670,250)
			elseif score == 21 then
				spawnTarget(2620,-100)
			elseif score == 22 then
				spawnTarget(2870,300)
			elseif score == 23 then
				spawnTarget(3850,900)
			elseif score == 24 then
				spawnTarget(3780,300)
			elseif score == 25 then
				spawnTarget(3670,0)
			elseif score == 26 then
				AddCaption(loc("Last Target!"));
				spawnTarget(3480,1200)
			end
		else
			if not game_lost then
			-- Victory!
			SaveMissionVar("Won", "true")
			AddCaption(loc("Victory!"), capcolDefault, capgrpGameState)
			ShowMission(loc("Sniper Training"), loc("Aiming Practice"), loc("Congratulations! You've eliminated all targets|within the allowed time frame."), 0, 0)
			-- Also let the hogs shout "victory!"
			PlaySound(sndVictory, CurrentHedgehog)
			FollowGear(CurrentHedgehog)

			-- Unselect sniper rifle and disable hog controls
			SetInputMask(0)
			SetWeapon(amNothing)
			AddAmmo(CurrentHedgehog, amSniperRifle, 0)

			-- Save the time left so we may keep it.
			time_goal = TurnTimeLeft
			end
		end
		SetTeamLabel(playerTeamName, getTargetScore())
	end
end

-- This function calculates the final score of the player and provides some texts and
-- data for the final stats screen
function generateStats()
	local accuracy = 0
	if shots > 0 then
		accuracy = (score/shots)*100
	end
	local end_score_targets = getTargetScore()
	local end_score_overall
	if not game_lost then
		local end_score_time = math.ceil(time_goal/5)
		local end_score_accuracy = math.ceil(accuracy * 100)
		end_score_overall = end_score_time + end_score_targets + end_score_accuracy
		SetTeamLabel(playerTeamName, tostring(end_score_overall))

		SendStat(siGameResult, loc("You have successfully finished the sniper rifle training!"))
		SendStat(siCustomAchievement, string.format(loc("You have destroyed %d of %d targets (+%d points)."), score, score_goal, end_score_targets))
		SendStat(siCustomAchievement, string.format(loc("You have made %d shots."), shots))
		SendStat(siCustomAchievement, string.format(loc("Accuracy bonus: +%d points"), end_score_accuracy))
		SendStat(siCustomAchievement, string.format(loc("You had %.2fs remaining on the clock (+%d points)."), (time_goal/1000), end_score_time))
	else
		SendStat(siGameResult, loc("You lose!"))

		SendStat(siCustomAchievement, string.format(loc("You have destroyed %d of %d targets (+%d points)."), score, score_goal, end_score_targets))
		SendStat(siCustomAchievement, string.format(loc("You have made %d shots."), shots))
		end_score_overall = end_score_targets
	end
	SendStat(siPointType, loc("points"))
	SendStat(siPlayerKills, tostring(end_score_overall), playerTeamName)
	updateChallengeRecord("Highscore", end_score_overall)
end


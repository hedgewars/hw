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

loadfile(GetDataPath() .. "Scripts/Locale.lua")()

-- This variable will hold the number of destroyed targets.
local score = 0
-- This variable represents the number of targets to destroy.
local score_goal = 31
-- This variable controls how many milliseconds/ticks we'd
-- like to wait before we end the round once all targets
-- have been destroyed.
local end_timer = 5000 -- 5000 ms = 5 s
-- This variable is set to true if the game is lost (i.e.
-- time runs out).
local game_lost = false
-- This variable will point to the hog's gear
local player = nil
-- This variable will grab the time left at the end of the round
local time_goal = 0

local target = nil

local last_hit_time = 0
-- This is a custom function to make it easier to
-- spawn more targets with just one line of code
-- You may define as many custom functions as you
-- like.
function spawnTarget(x, y)
	-- add a new target gear
	target = AddGear(x, y, gtTarget, 0, 0, 0, 0)
	-- have the camera move to the target so the player knows where it is
	FollowGear(target)
end

function blowUp(x, y)
	-- adds some TNT
	gear = AddGear(x, y, gtDynamite, 0, 0, 0, 0)
end

function onNewTurn()
	ParseCommand("setweap " .. string.char(amSniperRifle))
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
	GameFlags = gfMultiWeapon + gfOneClanMode + gfArtillery
	-- The time the player has to move each round (in ms)
	TurnTime = 150000
	-- The frequency of crate drops
	CaseFreq = 0
	-- The number of mines being placed
	MinesNum = 0
	-- The number of explosives being placed
	Explosives = 0
	-- The delay between each round
	Delay = 0
	-- The map to be played
	Map = "Ropes"
	-- The theme to be used
	Theme = "City"

	-- Create the player team
	AddTeam(loc("Sniperz"), 14483456, "Simple", "Island", "Default")
	-- And add a hog to it
	player = AddHog(loc("Hunter"), 0, 1, "Sniper")
	SetGearPosition(player, 602, 1465)
end

-- This function is called when the round starts
-- it spawns the first target that has to be destroyed.
-- In addition it shows the scenario goal(s).
function onGameStart()
	-- Spawn the first target.
	spawnTarget(860,1020)
	
	-- Show some nice mission goals.
	-- Parameters are: caption, sub caption, description,
	-- extra text, icon and time to show.
	-- A negative icon parameter (-n) represents the n-th weapon icon
	-- A positive icon paramter (n) represents the (n+1)-th mission icon
	-- A timeframe of 0 is replaced with the default time to show.
	ShowMission(loc("Sniper Training"), loc("Aiming Practice"), loc("Eliminate all targets before your time runs out.|You have unlimited ammo for this mission."), -amSniperRifle, 0)
end

-- This function is called every game tick.
-- Note that there are 1000 ticks within one second.
-- You shouldn't try to calculate too complicated
-- code here as this might slow down your game.
function onGameTick20()
	if game_lost then
		return
	end
	-- after a target is destroyed, show hog, then target
	if (target ~= nil) and (TurnTimeLeft + 1300 < last_hit_time) then
		-- move camera to the target
		FollowGear(target)
	elseif TurnTimeLeft + 300 < last_hit_time then
		-- move camera to the hog
		FollowGear(player)
	end
	-- If time's up, set the game to be lost.
	-- We actually check the time to be "1 ms" as it
	-- will be at "0 ms" right at the start of the game.
	if TurnTimeLeft < 40 and TurnTimeLeft > 0 and score < score_goal then
		game_lost = true
		-- ... and show a short message.
		ShowMission(loc("Sniper Training"), loc("Aiming Practice"), loc("Oh no! Time's up! Just try again."), -amSkip, 0)
		-- How about killing our poor hog due to his poor performance?
		SetHealth(player, 0)
		-- Just to be sure set the goal time to 1 ms
		time_goal = 1
	end
	-- If the goal is reached or we've lost ...
	if score == score_goal or game_lost then
		-- ... check to see if the time we'd like to
		-- wait has passed and then ...
		if end_timer == 0 then
			-- ... end the game ...
			EndGame()
		else
			-- ... or just lower the timer by 1.
			end_timer = end_timer - 20
			-- Reset the time left to stop the timer
			TurnTimeLeft = time_goal
		end
	end
end

-- This function is called when the game is initialized
-- to request the available ammo and probabilities
function onAmmoStoreInit()
	-- add an unlimited supply of shotgun ammo
	SetAmmo(amSniperRifle, 9, 0, 0, 0)
end

-- This function is called when a new gear is added.
-- We don't need it for this training, so we can
-- keep it empty.
-- function onGearAdd(gear)
-- end

-- This function is called before a gear is destroyed.
-- We use it to count the number of targets destroyed.
function onGearDelete(gear)
    
	if GetGearType(gear) == gtCase then
		game_lost = true
		return
	end
	
	if (GetGearType(gear) == gtTarget) then
		-- remember when the target was hit for adjusting the camera
		last_hit_time = TurnTimeLeft
		-- Add one point to our score/counter
		score = score + 1
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
				AddCaption(loc("Good so far!") .. " " .. loc("Keep it up!"));
				blowUp(1730,1226)
				blowUp(1440,1595)
				blowUp(1527,1575)
				blowUp(1614,1595)
				blowUp(1420,1675)
				blowUp(1527,1675)
				blowUp(1634,1675)
				blowUp(1440,1755)
				blowUp(1527,1775)
				blowUp(1614,1755)
				spawnTarget(1527,1667)
			elseif score == 5 then
				spawnTarget(1527,1667)
			elseif score == 6 then
				spawnTarget(2175,1300)
			elseif score == 7 then
				spawnTarget(2250,940)
			elseif score == 8 then
				spawnTarget(2665,1540)
			elseif score == 9 then
				spawnTarget(3040,1160)
			elseif score == 10 then
				spawnTarget(2930,1500)
			elseif score == 11 then
				AddCaption(loc("This one's tricky."));
				spawnTarget(700,720)
			elseif score == 12 then
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
				blowUp(1198,913)
				spawnTarget(1200,730)
			elseif score == 13 then
				spawnTarget(1200,830)
			elseif score == 14 then
				spawnTarget(1430,450)
			elseif score == 15 then
				spawnTarget(796,240)
			elseif score == 16 then
				spawnTarget(300,10)
			elseif score == 17 then
				spawnTarget(2080,820)
			elseif score == 18 then
				AddCaption(loc("Demolition is fun!"));
				blowUp(2110,920)
				blowUp(2210,920)
				blowUp(2200,305)
				blowUp(2300,305)
				blowUp(2300,400)
				blowUp(2300,500)
				blowUp(2300,600)
				blowUp(2300,700)
				blowUp(2300,800)
				blowUp(2300,900)
				blowUp(2401,305)
				blowUp(2532,305)
				blowUp(2663,305)
				spawnTarget(2300,760)
			elseif score == 19 then
				spawnTarget(2300,760)
			elseif score == 20 then
				spawnTarget(2738,190)
			elseif score == 21 then
				spawnTarget(2590,-100)
			elseif score == 22 then
				AddCaption(loc("Will this ever end?"));
				blowUp(2790,305)
				blowUp(2930,305)
				blowUp(3060,305)
				blowUp(3190,305)
				blowUp(3310,305)
				blowUp(3393,613)
				blowUp(2805,370)
				blowUp(2805,500)
				blowUp(2805,630)
				blowUp(2805,760)
				blowUp(2805,890)
				blowUp(3258,370)
				blowUp(3258,475)
				blowUp(3264,575)
				spawnTarget(3230,240)
			elseif score == 23 then
				spawnTarget(3230,290)
			elseif score == 24 then
				spawnTarget(3670,250)
			elseif score == 25 then
				spawnTarget(2620,-100)
			elseif score == 26 then
				spawnTarget(2870,300)
			elseif score == 27 then
				spawnTarget(3850,900)
			elseif score == 28 then
				spawnTarget(3780,300)
			elseif score == 29 then
				spawnTarget(3670,0)
			elseif score == 30 then
				AddCaption(loc("Last Target!"));
				spawnTarget(3480,1200)
			end
		else
			if not game_lost then
			-- Otherwise show that the goal was accomplished
			ShowMission(loc("Sniper Training"), loc("Aiming Practice"), loc("Congratulations! You've eliminated all targets|within the allowed time frame."), 0, 0)
			-- Also let the hogs shout "victory!"
			PlaySound(sndVictory)
			-- Save the time left so we may keep it.
			time_goal = TurnTimeLeft
			end
		end
	end
end

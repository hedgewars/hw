-- Hedgewars Shotgun Training
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
local score_goal = 5
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

-- This is a custom function to make it easier to
-- spawn more targets with just one line of code
-- You may define as many custom functions as you
-- like.
function spawnTarget()
	-- add a new target gear
	gear = AddGear(0, 0, gtTarget, 0, 0, 0, 0)
	
	-- move it to a random position within 0 and
	-- LAND_WIDTH - the width of the map
	FindPlace(gear, true, 0, LAND_WIDTH)
	
	-- move the target to a higher vertical position
	-- to ensure it's not somewhere down below
	x, y = GetGearPosition(gear)
	SetGearPosition(gear, x, 500)
end

function onNewTurn()
	ParseCommand("setweap " .. string.char(amShotgun))
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
	GameFlags = gfMultiWeapon + gfOneClanMode
	-- The time the player has to move each round (in ms)
	TurnTime = 25000
	-- The frequency of crate drops
	CaseFreq = 0
	-- The number of mines being placed
	MinesNum = 0
	-- The number of explosives being placed
	Explosives = 0
	-- The delay between each round
	Delay = 0
	-- The map to be played
	Map = "Mushrooms"
	-- The theme to be used
	Theme = "Nature"

	-- Create the player team
	AddTeam(loc("Shotgun Team"), 14483456, "Simple", "Island", "Default")
	-- And add a hog to it
	player = AddHog(loc("Hunter"), 0, 1, "NoHat")
	SetGearPosition(player, 2334, 1254)
end

-- This function is called when the round starts
-- it spawns the first target that has to be destroyed.
-- In addition it shows the scenario goal(s).
function onGameStart()
	-- Spawn the first target.
	spawnTarget()
	
	-- Show some nice mission goals.
	-- Parameters are: caption, sub caption, description,
	-- extra text, icon and time to show.
	-- A negative icon parameter (-n) represents the n-th weapon icon
	-- A positive icon paramter (n) represents the (n+1)-th mission icon
	-- A timeframe of 0 is replaced with the default time to show.
	ShowMission(loc("Shotgun Training"), loc("Aiming Practice"), loc("Eliminate all targets before your time runs out.|You have unlimited ammo for this mission."), -amShotgun, 0)
end

-- This function is called every game tick.
-- Note that there are 1000 ticks within one second.
-- You shouldn't try to calculate too complicated
-- code here as this might slow down your game.
function onGameTick()
	-- If time's up, set the game to be lost.
	-- We actually check the time to be "1 ms" as it
	-- will be at "0 ms" right at the start of the game.
	if TurnTimeLeft == 1 and score < score_goal then
		game_lost = true
		-- ... and show a short message.
		ShowMission(loc("Shotgun Training"), loc("Aiming Practice"), loc("Oh no! Time's up! Just try again."), -amSkip, 0)
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
			end_timer = end_timer - 1
			-- Reset the time left to stop the timer
			TurnTimeLeft = time_goal
		end
	end
end

-- This function is called when the game is initialized
-- to request the available ammo and probabilities
function onAmmoStoreInit()
	-- add an unlimited supply of shotgun ammo
	SetAmmo(amShotgun, 9, 0, 0, 0)
end

-- This function is called when a new gear is added.
-- We don't need it for this training, so we can
-- keep it empty.
function onGearAdd(gear)
end

-- This function is called before a gear is destroyed.
-- We use it to count the number of targets destroyed.
function onGearDelete(gear)
	-- We're only interested in target gears.
	if GetGearType(gear) == gtTarget then
		-- Add one point to our score/counter
		score = score + 1
		-- If we haven't reached the goal ...
		if score < score_goal then
			-- ... spawn another target.
			spawnTarget()
		else
			if not game_lost then
			-- Otherwise show that the goal was accomplished
			ShowMission(loc("Shotgun Training"), loc("Aiming Practice"), loc("Congratulations! You've eliminated all targets|within the allowed time frame."), 0, 0)
			-- Also let the hogs shout "victory!"
			PlaySound(sndVictory)
			-- Save the time left so we may keep it.
			time_goal = TurnTimeLeft
			end
		end
	end
end

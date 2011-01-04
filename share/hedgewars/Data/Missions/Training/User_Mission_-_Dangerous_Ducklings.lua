
loadfile(GetDataPath() .. "Scripts/Locale.lua")()


local player = nil -- This variable will point to the hog's gear
local instructor = nil
local enemy = nil
--local givenSpeech = false

local speechStage = 0

local gameLost = false
local gameWon = false
local notListening = false

local endTimer = 0

function onGameInit()

	-- Things we don't modify here will use their default values.

	Seed = 0 -- The base number for the random number generator
	GameFlags = gfInfAttack -- Game settings and rules
	TurnTime = 60000 -- The time the player has to move each round (in ms)
	CaseFreq = 0 -- The frequency of crate drops
	MinesNum = 0 -- The number of mines being placed
	Explosives = 0 -- The number of explosives being placed
	Delay = 0 -- The delay between each round
	Map = "Bath" -- The map to be played
	Theme = "Bath" -- The theme to be used


	AddTeam(loc("Bloody Rookies"), 14483456, "Simple", "Island", "Default")
	player = AddHog(loc("Hunter"), 0, 1, "NoHat")

	--AddTeam("Instructors", 14483456, "Simple", "Island", "Default")
	instructor = AddHog(loc("Instructor"), 1, 1, "Vega")

	AddTeam("Blue Team", 29439, "Simple", "Island", "Default")
	enemy = AddHog("Filthy Blue", 1, 100, "Skull")

	SetGearPosition(player, 1170, 1926)
	SetGearPosition(instructor, 1341, 1926)
	SetGearPosition(enemy, 2942, 1861)


	HogSay(player, ".............................", SAY_THINK)
	HogTurnLeft(instructor, true)


end


function onGameStart()

	SpawnAmmoCrate(1499,1500,amRope)
	SpawnAmmoCrate(2753,1500,amFirePunch)

	FollowGear(player)

	--spawnTarget()

	-- Show some nice mission goals.
	-- Parameters are: caption, sub caption, description,
	-- extra text, icon and time to show.
	-- A negative icon parameter (-n) represents the n-th weapon icon
	-- A positive icon paramter (n) represents the (n+1)-th mission icon
	-- A timeframe of 0 is replaced with the default time to show.
	ShowMission(loc("Dangerous Ducklings"), loc("by mikade"), loc("Eliminate the Blue Team"), -amRope, 1);

end


function onGameTick()


	-- opening speech
	if (notListening == false) and (gameLost == false) then

		if (TurnTimeLeft == 58000) and (speechStage == 0)  then
			HogSay(instructor, loc("Listen up, maggot!!"), SAY_SHOUT)
			speechStage = 1
		elseif (TurnTimeLeft == 57000) and (speechStage == 1) then
			HogSay(player,loc("!!!"),SAY_SHOUT)
		elseif (TurnTimeLeft == 55000) and (speechStage == 1) then
			HogSay(instructor, loc("The enemy is hiding out on yonder ducky!"), SAY_SAY)
			speechStage = 2

		elseif (TurnTimeLeft == 49000) and (speechStage == 2) then
			FollowGear(enemy)
		elseif (TurnTimeLeft == 46500) and (speechStage == 2) then
			FollowGear(instructor)
			HogSay(instructor, loc("Get on over there and take him out!"), SAY_SAY)
			speechStage = 3
		elseif (TurnTimeLeft == 43500) and (speechStage == 3) then
			HogSay(instructor, loc("GO! GO! GO!"), SAY_SHOUT)
			speechStage = 4
			givenSpeech = true
		end

	end


	-- if player falls in water or if player ignores speech
	if (CurrentHedgehog ~= nil) and (CurrentHedgehog == player) then
		if (GetY(player) > 2060) and (gameLost == false) then
			HogSay(instructor, loc("DAMMIT, ROOKIE!"), SAY_SHOUT)
			gameLost = true
		end

		if (GetX(player) > 1324) and (GetY(player) > 1908) and (notListening == false) and (speechStage < 3) then
			HogSay(instructor, loc("DAMMIT, ROOKIE! GET OFF MY HEAD!"), SAY_SHOUT)
			notListening = true
		end

	end

	--player out of time
	if (TurnTimeLeft == 1) and (gameWon == false) then
		SetHealth(player, 0)
	end

	-- meh
	if gameLost == true then
		endTimer = endTimer + 1
		if (CurrentHedgehog ~= nil) and (CurrentHedgehog == instructor) then
			if endTimer >= 3000 then
				SetHealth(instructor,0)
				TurnTimeLeft = 0
			end
			ShowMission(loc("MISSION FAILED"), loc(":("), loc("You've failed. Try again."), -amRope, 1);
		end
	end

end


function onAmmoStoreInit()
	SetAmmo(amFirePunch, 0, 0, 0, 1)
	SetAmmo(amParachute, 1, 0, 0, 0)
	SetAmmo(amRope, 0, 0, 0, 1)
end

function onGearDelete(gear)
	if GetGearType(gear) == gtHedgehog then
		if gear == player then
			gameLost = true
		elseif gear == instructor then
			HogSay(player, loc("See ya!"), SAY_THINK)
			TurnTimeLeft = 3000
		elseif gear == enemy then
			HogSay(player, loc("Enjoy the swim..."), SAY_THINK)
			gameWon = true
			TurnTimeLeft = 3000
		end

	end
end

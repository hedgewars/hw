HedgewarsScriptLoad("/Scripts/Locale.lua")

local player = nil
local scored = 0
local end_timer = 1000
local game_lost = false
local time_goal = 0

function spawnTarget()

	gear = AddGear(0, 0, gtTarget, 0, 0, 0, 0)
	
	if scored == 0 then x = 628 end
	if scored == 1 then x = 891 end
	if scored == 2 then x = 1309 end
	if scored == 3 then x = 1128 end
	if scored == 4 then x = 410 end
	if scored == 5 then x = 1564 end
	if scored == 6 then x = 1348 end
	if scored == 7 then x = 169 end
	if scored == 8 then x = 1720 end
	if scored == 9 then x = 1441 end
	if scored == 10 then x = 599 end
	if scored == 11 then x = 1638 end

	if scored == 6 then
		SetGearPosition(gear, 1248, 476)
	else
		SetGearPosition(gear, x, 0)
	end

end

function onGameInit()

	Seed = 1
	GameFlags = gfDisableWind + gfInfAttack + gfOneClanMode
	TurnTime = 180 * 1000
	Map = "Trash"
	Theme = "Golf"
	Goals = "Take down all the targets|Achieve it using only Cluster Bomb"
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0

	AddTeam("The Hogies", 2850005, "Statue", "Island", "Hog Islands")

	player = AddHog(loc("Private Novak"), 0, 1, "war_desertGrenadier1")
	SetGearPosition(player, 756, 370)

end

function onAmmoStoreInit()

	SetAmmo(amClusterBomb, 9, 0, 0, 0)

end

function onGameStart()

	ShowMission(loc("Cluster Bomb Training"), loc("Aiming Practice"), loc("You have to destroy 12 targets in 180 seconds"), -amClusterBomb, 5000)
	spawnTarget()

end

function onGameTick20()

	if TurnTimeLeft < 40 and TurnTimeLeft > 0 and scored < 12 and game_lost == false then
		game_lost = true
		ShowMission(loc("Cluster Bomb Training"), loc("Aiming Practice"), loc("Oh no! Time's up! Just try again."), -amSkip, 0)
		SetHealth(player, 0)
		time_goal = 1
	end

	if scored == 12 or game_lost then
		if end_timer == 0 then
			EndGame()
		else
			TurnTimeLeft = time_goal
		end
        end_timer = end_timer - 20
	end

end

function onNewTurn()
	ParseCommand("setweap " .. string.char(amClusterBomb))
end

--function onGearAdd(gear)
--end

function onGearDamage(gear, damage)

	if GetGearType(gear) == gtTarget then
		scored = scored + 1
		if scored < 12 then
			spawnTarget()
		else
			if not game_lost then

				if TurnTimeLeft > 90 * 10 then
					ShowMission(loc("Cluster Bomb MASTER!"), loc("Aiming Practice"), loc("Congratulations! You needed only half of time|to eliminate all targets."), 4, 0)
				else
					ShowMission(loc("Cluster Bomb Training"), loc("Aiming Practice"), loc("Congratulations! You've eliminated all targets|within the allowed time frame."), 0, 0)
				end
				PlaySound(sndVictory)
				time_goal = TurnTimeLeft
			end
		end
	end

	if GetGearType(gear) == gtHedgehog then
		game_lost = true
		ShowMission(loc("Cluster Bomb Training"), loc("Aiming Practice"), loc("Oh no! You failed! Just try again."), -amSkip, 0)
		SetHealth(player, 0)
		time_goal = 1
	end

end

function onGearDelete(gear)
end

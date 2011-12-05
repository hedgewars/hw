loadfile(GetDataPath() .. "Scripts/Locale.lua")()

local player = nil
local scored = 0
local end_timer = 5000
local game_lost = false
local time_goal = 0

function spawnTarget()
	gear = AddGear(0, 0, gtTarget, 0, 0, 0, 0)
	FindPlace(gear, true, 0, LAND_WIDTH)
	x, y = GetGearPosition(gear)
	SetGearPosition(gear, x, 500)
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

	player = AddHog("Private Novak", 0, 100, "war_desertGrenadier1")
	SetGearPosition(player, 1780, 1300)

end

function onAmmoStoreInit()

	SetAmmo(amClusterBomb, 9, 0, 0, 0)
	SetAmmo(amGrenade, 9, 0, 0, 0)

end

function onGameStart()

	ShowMission("Cluster Bomb Training", loc("Aiming Practice"), "You have to destroy 12 targets in 120 seconds|Timer is set to 3 seconds", -amClusterBomb, 5000)
	spawnTarget()

end

function onGameTick()

	if TurnTimeLeft == 1 and scored < 12 then
		game_lost = true
		ShowMission("Cluster Bomb Training", loc("Aiming Practice"), loc("Oh no! Time's up! Just try again."), -amSkip, 0)
		SetHealth(player, 0)
		time_goal = 1
	end

	if scored == 12 or game_lost then
		if end_timer == 0 then
			EndGame()
		else
			end_timer = end_timer - 1
			TurnTimeLeft = time_goal
		end
	end

end

function onNewTurn()
end

function onGearAdd(gear)
end

function onGearDamage(gear, damage)

	if GetGearType(gear) == gtTarget then
		scored = scored + 1
		if scored < 12 then
			spawnTarget()
		else
			if not game_lost then
				ShowMission("Cluster Bomb Training", loc("Aiming Practice"), loc("Congratulations! You've eliminated all targets|within the allowed time frame."), 0, 0)
				PlaySound(sndVictory)
				time_goal = TurnTimeLeft
			end
		end
	end
end

function onGearDelete(gear)
end

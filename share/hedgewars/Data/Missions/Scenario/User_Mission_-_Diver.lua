
HedgewarsScriptLoad("/Scripts/Locale.lua")

local player = nil -- This variable will point to the hog's gear
local enemy = nil

local GameOver = false

local jetpackFuel = 1000

function onGameInit()

	-- Things we don't modify here will use their default values.

	Seed = 0 -- The base number for the random number generator
	GameFlags = gfInfAttack + gfDisableWind-- Game settings and rules
	TurnTime = 90000 -- The time the player has to move each round (in ms)
	CaseFreq = 0 -- The frequency of crate drops
	MinesNum = 0 -- The number of mines being placed
	MinesTime  = 1000
	Explosives = 0 -- The number of explosives being placed
	Map = "Hydrant" -- The map to be played
	Theme = "City" -- The theme to be used

	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0

	AddMissionTeam(-1)
	player = AddMissionHog(1)
			
	AddTeam(loc("Toxic Team"), -6, "skull", "Island", "Default_qau", "cm_magicskull")
	enemy = AddHog(loc("Poison"), 1, 100, "Skull")

	SetGearPosition(player,430,516)
	SetGearPosition(enemy,1464,936)

end


function onGameStart()


	SpawnSupplyCrate(426,886,amJetpack)
	SpawnSupplyCrate(1544,690,amFirePunch)
	SpawnSupplyCrate(950,851,amBlowTorch)
	SpawnSupplyCrate(1032,853,amParachute)

	AddGear(579, 296, gtMine, 0, 0, 0, 0)

	ShowMission(loc("Diver"), loc("Scenario"),
		loc("Eliminate the enemy before the time runs out.") .. "|" .. 
		loc("Unlimited Attacks: Attacks don't end your turn") .. "|" ..
		loc("Mines time: 1 second"), -amFirePunch, 0);
	--SetTag(AddGear(0, 0, gtATSmoothWindCh, 0, 0, 0, 1), -70)

	SetAmmoDescriptionAppendix(amJetpack, string.format(loc("In this mission you get %d%% fuel."), div(jetpackFuel, 20)))

	SetWind(-100)

end


function onGameTick()


	if (TotalRounds == 3) and (GameOver == false) then
		SetHealth(player, 0)
		GameOver = true
	end

	if TurnTimeLeft == 1 then
		SetHealth(player, 0)
		GameOver = true
	end

end


function onAmmoStoreInit()
	SetAmmo(amFirePunch, 1, 0, 0, 1)
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amGirder, 1, 0, 0, 0)
	SetAmmo(amParachute, 0, 0, 0, 1)
	SetAmmo(amJetpack, 0, 0, 0, 1)
end


function onGearAdd(gear)

	if GetGearType(gear) == gtJetpack then
		SetHealth(gear, jetpackFuel)
	end

end

function onGameResult(winner)

	if winner == 0 then
		ShowMission(loc("Diver"), loc("MISSION SUCCESSFUL"), loc("Congratulations!"), 0, 0)
		SaveMissionVar("Won", "true")
		GameOver = true
	else
		ShowMission(loc("Diver"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)		
		GameOver = true
	end

end


HedgewarsScriptLoad("/Scripts/Locale.lua")

local player = nil -- This variable will point to the hog's gear
local enemy = nil

local GameOver = false

function onGameInit()

	-- Things we don't modify here will use their default values.

	Seed = 0 -- The base number for the random number generator
	GameFlags = gfInfAttack + gfDisableWind-- Game settings and rules
	TurnTime = 90000 -- The time the player has to move each round (in ms)
	CaseFreq = 0 -- The frequency of crate drops
	MinesNum = 0 -- The number of mines being placed
	MinesTime  = 1000
	Explosives = 0 -- The number of explosives being placed
	Delay = 10 -- The delay between each round
	Map = "Hydrant" -- The map to be played
	Theme = "City" -- The theme to be used

	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0

	AddTeam(loc("Bloody Rookies"), 14483456, "Simple", "Island", "Default", "cm_eyes")
	player = AddHog(loc("Hunter"), 0, 1, "NoHat")
			
	AddTeam(loc("Toxic Team"), 	1175851, "Simple", "Island", "Default", "cm_magicskull")
	enemy = AddHog(loc("Poison"), 1, 100, "Skull")

	SetGearPosition(player,430,516)
	SetGearPosition(enemy,1464,936)

end


function onGameStart()


	SpawnAmmoCrate(426,886,amJetpack)
	SpawnAmmoCrate(1544,690,amFirePunch)
	SpawnAmmoCrate(950,851,amBlowTorch)
	SpawnAmmoCrate(1032,853,amParachute)

	AddGear(579, 296, gtMine, 0, 0, 0, 0)

	ShowMission(loc("Operation Diver"), loc("Scenario"), loc("Eliminate the enemy before the time runs out.") .. loc("|- Mines Time:") .. " " .. 1 .. " " .. loc("sec"), -amFirePunch, 0);
	--SetTag(AddGear(0, 0, gtATSmoothWindCh, 0, 0, 0, 1), -70)

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
		SetHealth(gear,1000)
	end

end

function onGearDelete(gear)

	if (gear == enemy) and (GameOver == false) then
		ShowMission(loc("Operation Diver"), loc("MISSION SUCCESSFUL"), loc("Congratulations!"), 0, 0)
	elseif gear == player then
		ShowMission(loc("Operation Diver"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)		
		GameOver = true
	end

end


HedgewarsScriptLoad("/Scripts/Locale.lua")

---------------------------------------------------------------

local player = nil -- This variable will point to the hog's gear
local instructor = nil
local enemy = nil

local GameOver = false
local birdSpeech = false
local birdSqualk = false

local GirderCrate = nil

function onGameInit()

	-- Things we don't modify here will use their default values.
	Seed = 0 -- The base number for the random number generator
	GameFlags = gfInfAttack +gfDisableWind-- Game settings and rules
	TurnTime = 90000 -- The time the player has to move each round (in ms)
	CaseFreq = 0 -- The frequency of crate drops
	MinesNum = 0 -- The number of mines being placed
	MinesTime  = 1
	Explosives = 0 -- The number of explosives being placed
	Delay = 10 -- The delay between each round
	Map = "Tree" -- The map to be played
	Theme = "Halloween" -- The theme to be used
	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0

	AddTeam(loc("Bloody Rookies"), 14483456, "Simple", "Island", "Default", "cm_eyes")
	player = AddHog(loc("Hunter"), 0, 1, "NoHat")
			--852718
	AddTeam(loc("Toxic Team"), 	1175851, "Simple", "Island", "Default", "cm_magicskull")
	enemy = AddHog(loc("Poison"), 1, 10, "Skull")

	SetGearPosition(player,970,23)
	SetGearPosition(enemy,498,806)

end


function onGameStart()

	--right side mines
	AddGear(1681,359,gtMine, 0, 0, 0, 0)
	AddGear(1718,518,gtMine, 0, 0, 0, 0)
	AddGear(1648,527,gtMine, 0, 0, 0, 0)
	AddGear(1584,522,gtMine, 0, 0, 0, 0)

	--tunnel mines
	AddGear(301,569,gtSMine, 0, 0, 0, 0)
	AddGear(372,608,gtSMine, 0, 0, 0, 0)
	AddGear(453,628,gtSMine, 0, 0, 0, 0)
	AddGear(524,611,gtSMine, 0, 0, 0, 0)
	AddGear(613,611,gtSMine, 0, 0, 0, 0)

	AddGear(308,486,gtSMine, 0, 0, 0, 0)
	AddGear(372,478,gtSMine, 0, 0, 0, 0)
	AddGear(453,466,gtSMine, 0, 0, 0, 0)
	AddGear(524,471,gtSMine, 0, 0, 0, 0)
	AddGear(613,466,gtSMine, 0, 0, 0, 0)

	--above the tunnel mines
	AddGear(331,433,gtMine, 0, 0, 0, 0)
	AddGear(404,420,gtMine, 0, 0, 0, 0)
	AddGear(484,424,gtMine, 0, 0, 0, 0)
	AddGear(562,417,gtMine, 0, 0, 0, 0)
	AddGear(640,412,gtMine, 0, 0, 0, 0)

	-- crates crates and more crates
	SpawnAmmoCrate(1208,576,amBlowTorch)
	SpawnAmmoCrate(1467,376,amPickHammer)
	SpawnUtilityCrate(373,165,amGirder)
	SpawnUtilityCrate(704,623,amJetpack)
	SpawnUtilityCrate(1646,749,amLaserSight)

	SpawnAmmoCrate(745,418,amShotgun) --shotgun1
	SpawnAmmoCrate(833,432,amFirePunch) --fire punch
	GirderCrate = SpawnAmmoCrate(1789,514,amShotgun) -- final shotgun
	SpawnAmmoCrate(1181,419,amBee)

	ShowMission(loc("Spooky Tree"), loc("Scenario"),
		loc("Eliminate the enemy before the time runs out.") .. "|" ..
		loc("Unlimited Attacks: Attacks don't end your turn") .. "|" ..
		loc("Mines time: 0 seconds"), -amBee, 0)

	SetWind(-75)

end


function onGameTick()


	if CurrentHedgehog ~= nil then

		if (birdSqualk == false) and (GetX(CurrentHedgehog) == 1102) and (GetY(CurrentHedgehog) == 133)  then
			birdSqualk = true
			PlaySound(sndBirdyLay)
		end

		if (birdSpeech == false) and (GetX(CurrentHedgehog) == 1068) and (GetY(CurrentHedgehog) == 162) then
			birdSpeech = true
			HogSay(player,loc("Good birdy......"),SAY_THINK)
		end
	end

	if CurrentHedgehog ~= nil then
		--AddCaption(GetX(CurrentHedgehog) .. ";" .. GetY(CurrentHedgehog))
	end

	if (TotalRounds == 2) and (GameOver == false) then -- just in case
		SetHealth(player, 0)
		GameOver = true
	end

	if TurnTimeLeft == 1 then
		--ShowMission(loc(caption), loc(subcaption), loc(timeout), -amSkip, 0);
		SetHealth(player, 0)
		GameOver = true
	end

end


function onAmmoStoreInit()
	SetAmmo(amShotgun, 0, 0, 0, 1)
	SetAmmo(amFirePunch, 0, 0, 0, 1)
	SetAmmo(amBee, 0, 0, 0, 1)
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amGirder, 0, 0, 0, 1)
	SetAmmo(amParachute, 1, 0, 0, 1)
	SetAmmo(amPickHammer, 0, 0, 0, 1)
	SetAmmo(amJetpack, 0, 0, 0, 1)
	SetAmmo(amLaserSight, 0, 0, 0, 1)
end

function onGearDelete(gear)

	if gear == GirderCrate then
		TurnTimeLeft = TurnTimeLeft + 30000
	end

	if GetGearType(gear) == gtCase then
		TurnTimeLeft = TurnTimeLeft + 5000
	end

	if (gear == enemy) and (GameOver == false) then
		ShowMission(loc("Spooky Tree"), loc("MISSION SUCCESSFUL"), loc("Congratulations!"), 0, 0);
	elseif gear == player then
		ShowMission(loc("Spooky Tree"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)
		GameOver = true
	end

end


loadfile(GetDataPath() .. "Scripts/Locale.lua")()

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

	AddTeam(loc("Bloody Rookies"), 14483456, "Simple", "Island", "Default")
	player = AddHog(loc("Hunter"), 0, 1, "NoHat")
			--852718
	AddTeam(loc("Toxic Team"), 	1175851, "Simple", "Island", "Default")
	enemy = AddHog(loc("Poison"), 1, 10, "Skull")

	SetGearPosition(player, 1994, 1047)
	SetGearPosition(enemy, 1522, 1830)

end


function onGameStart()

	--right side mines
	AddGear(2705, 1383, gtMine, 0, 0, 0, 0)
	AddGear(2742, 1542, gtMine, 0, 0, 0, 0)
	AddGear(2672, 1551, gtMine, 0, 0, 0, 0)
	AddGear(2608, 1546, gtMine, 0, 0, 0, 0)

	--tunnel mines
	AddGear(1325, 1593, gtSMine, 0, 0, 0, 0)
	AddGear(1396, 1632, gtSMine, 0, 0, 0, 0)
	AddGear(1477, 1652, gtSMine, 0, 0, 0, 0)
	AddGear(1548, 1635, gtSMine, 0, 0, 0, 0)
	AddGear(1637, 1635, gtSMine, 0, 0, 0, 0)

	AddGear(1332, 1510, gtSMine, 0, 0, 0, 0)
	AddGear(1396, 1502, gtSMine, 0, 0, 0, 0)
	AddGear(1477, 1490, gtSMine, 0, 0, 0, 0)
	AddGear(1548, 1495, gtSMine, 0, 0, 0, 0)
	AddGear(1637, 1490, gtSMine, 0, 0, 0, 0)

	--above the tunnel mines
	AddGear(1355, 1457, gtMine, 0, 0, 0, 0)
	AddGear(1428, 1444, gtMine, 0, 0, 0, 0)
	AddGear(1508, 1448, gtMine, 0, 0, 0, 0)
	AddGear(1586, 1441, gtMine, 0, 0, 0, 0)
	AddGear(1664, 1436, gtMine, 0, 0, 0, 0)

	-- crates crates and more crates
	SpawnAmmoCrate(2232,1600,amBlowTorch)
	SpawnAmmoCrate(2491,1400,amPickHammer)
	SpawnUtilityCrate(1397,1189,amGirder)
	SpawnUtilityCrate(1728,1647,amJetpack)
	SpawnUtilityCrate(2670,1773,amLaserSight)

	SpawnAmmoCrate(1769,1442,amShotgun) --shotgun1
	SpawnAmmoCrate(1857,1456,amFirePunch) --fire punch
	GirderCrate = SpawnAmmoCrate(2813,1538,amShotgun) -- final shotgun
	SpawnAmmoCrate(2205,1443,amBee)

	ShowMission(loc("Spooky Tree"), loc("by mikade"), loc("Eliminate all enemies") .. loc("|- Mines Time:") .. " " .. 0 .. " " .. loc("sec"), -amBee, 0)

	SetWind(-75)

end


function onGameTick()


	if CurrentHedgehog ~= nil then

		if (birdSqualk == false) and (GetX(CurrentHedgehog) == 2126) and (GetY(CurrentHedgehog) == 1157)  then
			birdSqualk = true
			PlaySound(sndBirdyLay)
		end

		if (birdSpeech == false) and (GetX(CurrentHedgehog) == 2092) and (GetY(CurrentHedgehog) == 1186) then
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

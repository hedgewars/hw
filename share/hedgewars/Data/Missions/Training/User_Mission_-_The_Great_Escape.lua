loadfile(GetDataPath() .. "Scripts/Locale.lua")()

local player = nil
local enemy = nil

function onGameInit()

	Map = "Castle"
	Theme = "Nature"
	Seed = 0
	GameFlags = gfInfAttack

	TurnTime = 45 * 1000

	CaseFreq = 0
	MinesNum = 0
	Explosives = 0

	AddTeam(loc("Hero Team"), 14483456, "Simple", "Island", "Default", "Hedgewars")
	player = AddHog(loc("Good Dude"), 0, 80, "NoHat") --NoHat

	AddTeam(loc("Bad Team"), 	1175851, "Simple", "Island", "Default", "Hedgewars")
	enemy = AddHog("Bad Guy", 1, 40, "NoHat")

end

function onGameStart()

ShowMission(loc("The Great Escape"), loc("Get out of there!"), loc("Elimate your captor."), -amGrenade, 0)

------ GIRDER LIST ------
PlaceGirder(2066, 1588, 0)
PlaceGirder(2052, 1498, 6)
PlaceGirder(2098, 1498, 6)
PlaceGirder(2074, 1409, 0)
PlaceGirder(2199, 1755, 7)
PlaceGirder(2476, 1929, 2)
PlaceGirder(2546, 1879, 4)
PlaceGirder(2520, 1924, 3)
PlaceGirder(2706, 1879, 4)
PlaceGirder(2797, 1911, 2)
PlaceGirder(2671, 1925, 1)
PlaceGirder(2895, 1907, 6)
PlaceGirder(2895, 1747, 6)
PlaceGirder(2798, 1792, 6)
PlaceGirder(2797, 1791, 6)
PlaceGirder(2845, 1928, 1)
PlaceGirder(2846, 1826, 3)
PlaceGirder(2844, 1747, 1)
PlaceGirder(2806, 1702, 4)
PlaceGirder(2846, 1685, 0)
PlaceGirder(2846, 1668, 0)
PlaceGirder(2766, 1668, 0)
PlaceGirder(2766, 1685, 0)
PlaceGirder(2718, 1700, 2)
PlaceGirder(2927, 1659, 0)
------ HEALTH CRATE LIST ------
SpawnHealthCrate(2500, 1193)
SpawnHealthCrate(2575, 1201)
SpawnHealthCrate(2610, 1224)
SpawnHealthCrate(2463, 1213)
SpawnHealthCrate(2425, 1235)
SpawnHealthCrate(2657, 1234)
------ MINE LIST ------
tempG = AddGear(2034, 1704, gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
tempG = AddGear(2055, 1744, gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
tempG = AddGear(2063, 1772, gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
tempG = AddGear(2075, 1801, gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
tempG = AddGear(2089, 1820, gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
tempG = AddGear(2118, 1824, gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
------ REPOSITION LIST ------
SetGearPosition(player, 2074, 1558)
SetGearPosition(enemy, 2536, 1182)
SetHealth(player, 1)
SetHealth(enemy, 1)
------ AMMO CRATE LIST ------
SpawnAmmoCrate(2656, 1967, 5)
SpawnAmmoCrate(2747, 1912, 12)
SpawnAmmoCrate(2939, 1623, 1)
------ UTILITY CRATE LIST ------
SpawnUtilityCrate(2543, 1969, 15)
SpawnUtilityCrate(2251, 1664, 6)
SpawnUtilityCrate(2440, 1937, 18)
------ END LOADING DATA ------

end

function onGameTick()

	if TurnTimeLeft == TurnTime-1 then
		SetWind(100)
	end

end

function onGearDelete(gear)
	if (GetGearType(gear) == gtCase) and (CurrentHedgehog == player) then
		if GetHealth(gear) > 0 then
			AddGear(GetX(gear), GetY(gear), gtGrenade, 0, 0, 0, 1)
		end
	elseif gear == player then
		ShowMission(loc("The Great Escape"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)
	elseif gear == enemy then
		ShowMission(loc("The Great Escape"), loc("MISSION SUCCESSFUL"), loc("Congratulations!"), 0, 0)
	end
end

function onAmmoStoreInit()
	SetAmmo(amGrenade, 1, 0, 0, 1)
	SetAmmo(amParachute, 1, 0, 0, 1)
	SetAmmo(amFirePunch, 0, 0, 0, 3)
	SetAmmo(amPickHammer, 0, 0, 0, 1)
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amShotgun, 0, 0, 0, 1)
	SetAmmo(amSkip, 9, 0, 0, 0)
end

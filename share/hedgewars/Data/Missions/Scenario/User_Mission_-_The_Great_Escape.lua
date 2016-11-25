HedgewarsScriptLoad("/Scripts/Locale.lua")

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

	AddTeam(loc("Hero Team"), 14483456, "Simple", "Island", "Default", "cm_swordshield")
	player = AddHog(loc("Good Dude"), 0, 80, "NoHat") --NoHat

	AddTeam(loc("Bad Team"), 	1175851, "Simple", "Island", "Default", "cm_dragonrb")
	enemy = AddHog(loc("Bad Guy"), 1, 40, "NoHat")

end

function onGameStart()

ShowMission(loc("The Great Escape"), loc("Scenario"), loc("Elimate your captor."), -amGrenade, 0)

------ GIRDER LIST ------
PlaceGirder(1042,564,0)
PlaceGirder(1028,474,6)
PlaceGirder(1074,474,6)
PlaceGirder(1050,385,0)
PlaceGirder(1175,731,7)
PlaceGirder(1452,905,2)
PlaceGirder(1522,855,4)
PlaceGirder(1496,900,3)
PlaceGirder(1682,855,4)
PlaceGirder(1773,887,2)
PlaceGirder(1647,901,1)
PlaceGirder(1871,883,6)
PlaceGirder(1871,723,6)
PlaceGirder(1774,768,6)
PlaceGirder(1773,767,6)
PlaceGirder(1821,904,1)
PlaceGirder(1822,802,3)
PlaceGirder(1820,723,1)
PlaceGirder(1782,678,4)
PlaceGirder(1822,661,0)
PlaceGirder(1822,644,0)
PlaceGirder(1742,644,0)
PlaceGirder(1742,661,0)
PlaceGirder(1694,676,2)
PlaceGirder(1903,635,0)
------ HEALTH CRATE LIST ------
SpawnHealthCrate(1476,169)
SpawnHealthCrate(1551,177)
SpawnHealthCrate(1586,200)
SpawnHealthCrate(1439,189)
SpawnHealthCrate(1401,211)
SpawnHealthCrate(1633,210)
------ MINE LIST ------
tempG = AddGear(1010,680,gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
tempG = AddGear(1031,720,gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
tempG = AddGear(1039,748,gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
tempG = AddGear(1051,777,gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
tempG = AddGear(1065,796,gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
tempG = AddGear(1094,800,gtMine, 0, 0, 0, 0)
SetTimer(tempG, 1)
------ REPOSITION LIST ------
SetGearPosition(player,1050,534)
SetGearPosition(enemy,1512,158)
SetHealth(player, 1)
SetHealth(enemy, 1)
------ AMMO CRATE LIST ------
SpawnAmmoCrate(1632,943,5)
SpawnAmmoCrate(1723,888,12)
SpawnAmmoCrate(1915,599,1)
------ UTILITY CRATE LIST ------
SpawnUtilityCrate(1519,945,15)
SpawnUtilityCrate(1227,640,6)
SpawnUtilityCrate(1416,913,18)
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

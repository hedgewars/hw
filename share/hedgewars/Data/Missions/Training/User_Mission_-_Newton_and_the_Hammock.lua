
loadfile(GetDataPath() .. "Scripts/Locale.lua")()

local player = nil 
local enemy = nil
local failed = false

local hhs = {}
local numhhs = 0

function onGameInit()

	Seed = 0
	TurnTime = 60000 
	CaseFreq = 0
	MinesTime  = 1000
	SuddenDeathTurns = 999999
	HealthCaseProb = 35
	Explosives = 0
	MinesNum = 0
	Map = "Hammock" 
	Theme = "Nature"

	AddTeam(loc("Pathetic Resistance"), 14483456, "Simple", "Island", "Default")
	player = AddHog("Ikeda", 0, 48, "StrawHat")
			
	AddTeam(loc("Cybernetic Empire"), 	1175851, "Simple", "Island", "Default")
	enemy = AddHog(loc("Unit") .. " 811", 1, 100, "cyborg1")

	SetGearPosition(player, 1454, 1540)
	SetGearPosition(enemy, 2488, 1960)

end


function onGameStart()

	AddAmmo(enemy, amShotgun, 100)
	AddAmmo(enemy, amFirePunch, 100)

	--GIRDER LIST. 
	PlaceGirder(2097,2009,0)
	PlaceGirder(1548,1487,3)
	PlaceGirder(1662,1453,4)
	PlaceGirder(1785,1453,0)
	PlaceGirder(1864,1421,3)
	PlaceGirder(1326,1388,6)
	PlaceGirder(1351,1506,1)
	PlaceGirder(2693,1832,3)
	--MINE LIST. 
	AddGear(2080,1987,gtMine, 0, 0, 0, 0)
	AddGear(2110,1988,gtMine, 0, 0, 0, 0)
	--STICKY MINE LIST. 
	AddGear(2113,965,gtSMine, 0, 0, 0, 0)
	AddGear(2157,945,gtSMine, 0, 0, 0, 0)	
	AddGear(2034,1081,gtSMine, 0, 0, 0, 0)
	AddGear(2060,1049,gtSMine, 0, 0, 0, 0)
	AddGear(2081,1004,gtSMine, 0, 0, 0, 0)
	AddGear(1808,1252,gtSMine, 0, 0, 0, 0)
	AddGear(1865,1257,gtSMine, 0, 0, 0, 0)
	AddGear(1926,1263,gtSMine, 0, 0, 0, 0)
	AddGear(1976,1281,gtSMine, 0, 0, 0, 0)
	AddGear(1541,1546,gtSMine, 0, 0, 0, 0)
	AddGear(1583,1597,gtSMine, 0, 0, 0, 0)
	AddGear(1637,1650,gtSMine, 0, 0, 0, 0)
	AddGear(1698,1705,gtSMine, 0, 0, 0, 0)
	AddGear(1770,1692,gtSMine, 0, 0, 0, 0)
	AddGear(1834,1692,gtSMine, 0, 0, 0, 0)
	AddGear(1896,1673,gtSMine, 0, 0, 0, 0)
	AddGear(1957,1666,gtSMine, 0, 0, 0, 0)
	AddGear(2005,1662,gtSMine, 0, 0, 0, 0)
	AddGear(2040,1634,gtSMine, 0, 0, 0, 0)
	AddGear(2087,1595,gtSMine, 0, 0, 0, 0)
	AddGear(2124,1574,gtSMine, 0, 0, 0, 0)
	AddGear(2026,1461,gtSMine, 0, 0, 0, 0)
	AddGear(2076,1438,gtSMine, 0, 0, 0, 0)
	AddGear(2126,1464,gtSMine, 0, 0, 0, 0)
	--WEAPON CRATE LIST. 
	SpawnAmmoCrate(2589,642,amSineGun)
	SpawnAmmoCrate(1572,858,amBazooka)
	--UTILITY CRATE LIST.
	SpawnUtilityCrate(1503,847,amJetpack)
	SpawnUtilityCrate(2574,1715,amBlowTorch)
	SpawnUtilityCrate(2251,1941,amJetpack)
	SpawnUtilityCrate(2094,1964,amInvulnerable)
	SpawnUtilityCrate(2094,1875,amTeleport)
	--HOG POSITION LIST.
	if hhs[0] ~= nil then
       		 SetGearPosition(hhs[0],1421,865)
	end
		if hhs[1] ~= nil then
        	SetGearPosition(hhs[1],1585,1365)
	end

	ShowMission(loc("Newton's Hammock"), loc("User Challenge"), loc("Eliminate the enemy before the time runs out"), -amParachute, 0)
		
end

function onAmmoStoreInit()
	SetAmmo(amSkip, 9, 0, 0, 1)
	SetAmmo(amBazooka, 0, 0, 0, 1)
	SetAmmo(amJetpack, 0, 0, 0, 1)
	SetAmmo(amTeleport, 0, 0, 0, 1)
	SetAmmo(amSineGun, 0, 0, 0, 1)
	SetAmmo(amInvulnerable, 0, 0, 0, 1)
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
end

function onGearDamage(gear, damage)
	if (gear == player) and (damage >= 48) then
		failed = true
	end
end

function onGearAdd(gear)

	if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		numhhs = numhhs + 1
	end	

end

function onGearDelete(gear)

	if (gear == enemy) and (failed == false) then
		ShowMission(loc("Newton's Hammock"), loc("MISSION SUCCESSFUL"), loc("Congratulations!"), 0, 0)
	elseif gear == player then
		ShowMission(loc("Newton's Hammock"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)		
	end

end

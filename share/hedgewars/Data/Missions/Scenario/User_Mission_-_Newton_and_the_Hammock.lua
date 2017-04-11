
HedgewarsScriptLoad("/Scripts/Locale.lua")

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
	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0
	HealthCaseProb = 35
	Explosives = 0
	MinesNum = 0
	Map = "Hammock" 
	Theme = "Nature"

	AddTeam(loc("Pathetic Resistance"), 14483456, "Simple", "Island", "Default", "cm_duckhead")
	player = AddHog(loc("Ikeda"), 0, 48, "StrawHat")
			
	AddTeam(loc("Cybernetic Empire"), 	1175851, "Simple", "Island", "Default", "cm_cyborg")
	enemy = AddHog(loc("Unit") .. " 811", 1, 100, "cyborg1")

	SetGearPosition(player,430,1540)
	SetGearPosition(enemy,1464,1960)

end


function onGameStart()

	AddAmmo(enemy, amShotgun, 100)
	AddAmmo(enemy, amFirePunch, 100)

	--GIRDER LIST. 
	PlaceGirder(1073,2009,0)
	PlaceGirder(524,1487,3)
	PlaceGirder(638,1453,4)
	PlaceGirder(761,1453,0)
	PlaceGirder(840,1421,3)
	PlaceGirder(302,1388,6)
	PlaceGirder(327,1506,1)
	PlaceGirder(1669,1832,3)
	--MINE LIST. 
	AddGear(1056,1987,gtMine, 0, 0, 0, 0)
	AddGear(1086,1988,gtMine, 0, 0, 0, 0)
	--STICKY MINE LIST. 
	AddGear(1089,965,gtSMine, 0, 0, 0, 0)
	AddGear(1133,945,gtSMine, 0, 0, 0, 0)	
	AddGear(1010,1081,gtSMine, 0, 0, 0, 0)
	AddGear(1036,1049,gtSMine, 0, 0, 0, 0)
	AddGear(1057,1004,gtSMine, 0, 0, 0, 0)
	AddGear(784,1252,gtSMine, 0, 0, 0, 0)
	AddGear(841,1257,gtSMine, 0, 0, 0, 0)
	AddGear(902,1263,gtSMine, 0, 0, 0, 0)
	AddGear(952,1281,gtSMine, 0, 0, 0, 0)
	AddGear(517,1546,gtSMine, 0, 0, 0, 0)
	AddGear(559,1597,gtSMine, 0, 0, 0, 0)
	AddGear(613,1650,gtSMine, 0, 0, 0, 0)
	AddGear(674,1705,gtSMine, 0, 0, 0, 0)
	AddGear(746,1692,gtSMine, 0, 0, 0, 0)
	AddGear(810,1692,gtSMine, 0, 0, 0, 0)
	AddGear(872,1673,gtSMine, 0, 0, 0, 0)
	AddGear(933,1666,gtSMine, 0, 0, 0, 0)
	AddGear(981,1662,gtSMine, 0, 0, 0, 0)
	AddGear(1016,1634,gtSMine, 0, 0, 0, 0)
	AddGear(1063,1595,gtSMine, 0, 0, 0, 0)
	AddGear(1100,1574,gtSMine, 0, 0, 0, 0)
	AddGear(1002,1461,gtSMine, 0, 0, 0, 0)
	AddGear(1052,1438,gtSMine, 0, 0, 0, 0)
	AddGear(1102,1464,gtSMine, 0, 0, 0, 0)
	--WEAPON CRATE LIST. 
	SpawnAmmoCrate(1565,642,amSineGun)
	SpawnAmmoCrate(548,858,amBazooka)
	--UTILITY CRATE LIST.
	SpawnUtilityCrate(479,847,amJetpack)
	SpawnUtilityCrate(1550,1715,amBlowTorch)
	SpawnUtilityCrate(1227,1941,amJetpack)
	SpawnUtilityCrate(1070,1964,amInvulnerable)
	SpawnUtilityCrate(1070,1875,amTeleport)
	--HOG POSITION LIST.
	if hhs[0] ~= nil then
       		 SetGearPosition(hhs[0],397,865)
	end
		if hhs[1] ~= nil then
        	SetGearPosition(hhs[1],561,1365)
	end

	ShowMission(loc("Newton and the Hammock"), loc("Scenario"), loc("Eliminate the enemy.") .. "|" .. loc("Mines time: 1 second"), -amParachute, 0)
		
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

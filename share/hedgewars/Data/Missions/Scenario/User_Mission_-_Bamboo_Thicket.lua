
HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Achievements.lua")

local playerTeamName
local player = nil 
local enemy = nil
local firedShell = false
local turnNumber = 0

local hhs = {}
local numhhs = 0

function onGameInit()

	Seed = 0 
	TurnTime = 20000 
	CaseFreq = 0 
	MinesNum = 0 
	Explosives = 0 
	Map = "Bamboo" 
	Theme = "Bamboo"
	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0
	GameFlags = gfDisableWind

	playerTeamName = AddMissionTeam(-1)
	player = AddMissionHog(10)
			
	AddTeam(loc("Cybernetic Empire"), -6, "ring", "Island", "Robot_qau", "cm_cyborg")
	enemy = AddHog(loc("Unit 835"), 1, 10, "cyborg1")

	SetGearPosition(player,142,656)
	SetGearPosition(enemy,1824,419)

end

function onGameStart()

	ShowMission(loc("Bamboo Thicket"), loc("Scenario"), loc("Eliminate the enemy."), -amBazooka, 0)

	-- CRATE LIST.
	SpawnSupplyCrate(891,852,amBazooka)
	SpawnSupplyCrate(962,117,amBlowTorch)

	SpawnSupplyCrate(403,503,amParachute)

	AddAmmo(enemy, amGrenade, 100)

	SetWind(100)
		
end

function onNewTurn()
	turnNumber = turnNumber + 1
end

function onAmmoStoreInit()
	SetAmmo(amSkip, 9, 0, 0, 0)
	SetAmmo(amGirder, 4, 0, 0, 0)
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amParachute, 0, 0, 0, 2)
	SetAmmo(amBazooka, 0, 0, 0, 2)
end


function onGearAdd(gear)

	if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		numhhs = numhhs + 1
	elseif GetGearType(gear) == gtShell then
		firedShell = true
	end

end

function onGameResult(winner)

	if (winner == GetTeamClan(playerTeamName)) then
		
		SaveMissionVar("Won", "true")
		SendStat(siGameResult, loc("Mission succeeded!"))
		
		if (turnNumber < 6) and (firedShell == false) then
			awardAchievement(loc("Energetic Engineer"))
		end

	else
		SendStat(siGameResult, loc("Mission failed!"))
	end

end

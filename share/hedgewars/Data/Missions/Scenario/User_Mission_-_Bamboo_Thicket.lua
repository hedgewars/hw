
HedgewarsScriptLoad("/Scripts/Locale.lua")

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
	SuddenDeathTurns = 99999

	AddTeam(loc("Pathetic Resistance"), 14483456, "Simple", "Island", "Default", "cm_yinyang")
	player = AddHog(loc("Ikeda"), 0, 10, "StrawHat")
			
	AddTeam(loc("Cybernetic Empire"), 	1175851, "Simple", "Island", "Default", "cm_cyborg")
	enemy = AddHog(loc("Unit 835"), 1, 10, "cyborg1")

	SetGearPosition(player,142,656)
	SetGearPosition(enemy,1824,419)

end


function onGameStart()

	ShowMission(loc("Bamboo Thicket"), loc("Scenario"), loc("Eliminate the enemy."), -amBazooka, 0)

	--WEAPON CRATE LIST. WCRATES: 1
	SpawnAmmoCrate(891,852,amBazooka)
	--UTILITY CRATE LIST. UCRATES: 2
	SpawnUtilityCrate(962,117,amBlowTorch)
	SpawnUtilityCrate(403,503,amParachute)

	AddAmmo(enemy, amGrenade, 100)
		
end

function onNewTurn()
	SetWind(100)
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

function onGearDelete(gear)

	if (gear == enemy) then
		
		ShowMission(loc("Bamboo Thicket"), loc("MISSION SUCCESSFUL"), loc("Congratulations!"), 0, 0)
		
		if (turnNumber < 6) and (firedShell == false) then
			AddCaption(loc("Achievement Unlocked") .. ": " .. loc("Energetic Engineer"),0xffba00ff,capgrpMessage2)
		end

	elseif gear == player then
		ShowMission(loc("Bamboo Thicket"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)
	end

end

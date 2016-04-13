HedgewarsScriptLoad("/Scripts/Locale.lua")

local player = nil -- This variable will point to the hog's gear
local p2 = nil
local enemy = nil
local bCrate = nil

local GameOver = false

function onGameInit()

	-- Things we don't modify here will use their default values.
	Seed = 0 -- The base number for the random number generator
	GameFlags = gfDisableWind-- Game settings and rules
	TurnTime = 30000 -- The time the player has to move each round (in ms)
	CaseFreq = 0 -- The frequency of crate drops
	MinesNum = 0 -- The number of mines being placed
	MinesTime  = 1
	Explosives = 0 -- The number of explosives being placed
	Delay = 10 -- The delay between each round
	Map = "Mushrooms" -- The map to be played
	Theme = "Nature" -- The theme to be used
	SuddenDeathTurns = 99999

	AddTeam(loc("Feeble Resistance"), 14483456, "Simple", "Island", "Default")
	player = AddHog(string.format(loc("Pathetic Hog #%d"), 1), 0, 50, "NoHat")
	p2 = AddHog(string.format(loc("Pathetic Hog #%d"), 2), 0, 20, "NoHat")

	--AddTeam("Toxic Team", 	1175851, "Simple", "Island", "Robot","cm_binary")
	AddTeam(loc("Cybernetic Empire"), 	1175851, "Simple", "Island", "Robot", "cm_binary")
	enemy = AddHog(loc("Unit 3378"), 5, 30, "cyborg1")

	SetGearPosition(player,1403,235)
	SetGearPosition(p2,1269,239)
	SetGearPosition(enemy,492,495)

end


function onGameStart()

	--mines
	AddGear(276,76,gtMine, 0, 0, 0, 0)
	AddGear(301,76,gtMine, 0, 0, 0, 0)
	AddGear(326,76,gtMine, 0, 0, 0, 0)
	AddGear(351,76,gtMine, 0, 0, 0, 0)
	AddGear(376,76,gtMine, 0, 0, 0, 0)
	AddGear(401,76,gtMine, 0, 0, 0, 0)
	AddGear(426,76,gtMine, 0, 0, 0, 0)
	AddGear(451,76,gtMine, 0, 0, 0, 0)
	AddGear(476,76,gtMine, 0, 0, 0, 0)

	AddGear(886,356,gtMine, 0, 0, 0, 0)
	AddGear(901,356,gtMine, 0, 0, 0, 0)
	AddGear(926,356,gtMine, 0, 0, 0, 0)
	AddGear(951,356,gtMine, 0, 0, 0, 0)
	AddGear(976,356,gtMine, 0, 0, 0, 0)
	AddGear(1001,356,gtMine, 0, 0, 0, 0)

	-- crates crates and more crates
	bCrate = SpawnAmmoCrate(1688,476,amBaseballBat)
	SpawnUtilityCrate(572,143,amGirder)
	SpawnAmmoCrate(1704,954,amPickHammer)
	SpawnAmmoCrate(704,623,amBlowTorch)
	SpawnUtilityCrate(1543,744,amJetpack)
	SpawnAmmoCrate(227,442,amDrill)

	ShowMission(loc("Codename: Teamwork"), "", loc("- Eliminate Unit 3378 |- Feeble Resistance must survive") .. loc("|- Mines Time:") .. " " .. 0 .. " " .. loc("sec"), 0, 0)

end


--function onGameTick()

	--if CurrentHedgehog ~= nil then
	--	AddCaption(GetX(CurrentHedgehog) .. ";" .. GetY(CurrentHedgehog))
	--end

--end


function onAmmoStoreInit()
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amGirder, 0, 0, 0, 1)
	SetAmmo(amPickHammer, 0, 0, 0, 2)
	SetAmmo(amJetpack, 0, 0, 0, 1)
	SetAmmo(amDrill, 0, 0, 0, 2)
	SetAmmo(amBaseballBat, 0, 0, 0, 1)
	SetAmmo(amSwitch, 9, 0, 0, 0)
	SetAmmo(amSkip, 9, 0, 0, 0)
end

function onGearDamage(gear, damage)
	if (gear == player) and (damage == 30) then
		HogSay(player,loc("T_T"),SAY_SHOUT)
	end
end

function onGearDelete(gear)

	if gear == bCrate then
		HogSay(CurrentHedgehog, loc("Hmmm..."), SAY_THINK)
	end

	if GetGearType(gear) == gtCase then
		TurnTimeLeft = TurnTimeLeft + 5000
	end

	if (gear == enemy) and (GameOver == false) then
		ShowMission(loc("Codename: Teamwork"), loc("MISSION SUCCESSFUL"), loc("Congratulations!"), 0, 0)
		GameOver = true
	elseif  ( ((gear == player) or (gear == p2)) and (GameOver == false)) then
		ShowMission(loc("Codename: Teamwork"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)
		GameOver = true
		SetHealth(p2,0)
		SetHealth(player,0)
	end

end

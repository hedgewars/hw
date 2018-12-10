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
	Map = "Mushrooms" -- The map to be played
	Theme = "Nature" -- The theme to be used
	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0

	AddTeam(loc("Feeble Resistance"), -1, "Statue", "Island", "Default", "cm_kiwi")
	player = AddHog(loc("Greg"), 0, 50, "NoHat")
	p2 = AddHog(loc("Mark"), 0, 20, "NoHat")

	AddTeam(loc("Cybernetic Empire"), -6, "ring", "Island", "Robot", "cm_cyborg")
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
	bCrate = SpawnSupplyCrate(1688,476,amBaseballBat)
	SpawnSupplyCrate(572,143,amGirder)
	SpawnSupplyCrate(1704,954,amPickHammer)
	SpawnSupplyCrate(704,623,amBlowTorch)
	SpawnSupplyCrate(1543,744,amJetpack)
	SpawnSupplyCrate(227,442,amDrill)

	ShowMission(loc("Teamwork"), loc("Scenario"), loc("Eliminate Unit 3378.") .. "|" .. loc("Both your hedgehogs must survive.") .. "|" .. loc("Mines time: 0 seconds"), 0, 0)

end

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

function onGearDelete(gear)

	if gear == bCrate then
		HogSay(CurrentHedgehog, loc("Hmmm..."), SAY_THINK)
	end

	if (GetGearType(gear) == gtCase) and (band(GetGearMessage(gear), gmDestroy) ~= 0) then
		SetTurnTimeLeft(TurnTimeLeft + 5000)
		AddCaption(string.format(loc("+%d seconds!"), 5), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage)
		PlaySound(sndExtraTime)
	end
	-- Note: The victory sequence is done automatically by Hedgewars
	if  ( ((gear == player) or (gear == p2)) and (GameOver == false)) then
		ShowMission(loc("Teamwork"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)
		GameOver = true
		SetHealth(p2,0)
		SetHealth(player,0)
	end

end

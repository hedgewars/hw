-- Teamwork 2
-- Original scenario by Arkhnen

HedgewarsScriptLoad("Scripts/Locale.lua")

local player = nil
local hlayer = nil
local enemy = nil
local Pack = nil
local help = false
local GameOver = false

function onGameInit()
	Seed = 0
	GameFlags = gfDisableWind
	TurnTime = MAX_TURN_TIME
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 0
	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0

	Explosives = 0
	Delay = 10
	Map = "CrazyMission"
	Theme = "CrazyMission"

	AddTeam(loc("Feeble Resistance"), -1, "Statue", "Island", "Default", "cm_kiwi")
	player = AddHog(loc("Greg"), 0, 30, "NoHat")
	hlayer = AddHog(loc("Mark"), 0, 40, "NoHat")

	AddTeam(loc("Cybernetic Empire"), -6, "ring", "Island", "Robot", "cm_binary")
	enemy = AddHog(loc("WatchBot 4000"), 5, 50, "cyborg1")

	SetGearPosition(player, 180, 555)
	SetGearPosition(enemy, 1500, 914)
	SetGearPosition(hlayer, 333, 555)
end

function onGameStart()
	Pack = SpawnSupplyCrate(40, 888, amPickHammer)
	SpawnSupplyCrate(90, 888, amBaseballBat)
	SpawnSupplyCrate(822, 750, amBlowTorch)
	SpawnSupplyCrate(700, 580, amJetpack)
	SpawnSupplyCrate(1400, 425, amParachute)
	SpawnSupplyCrate(1900, 770, amDynamite)
	SpawnSupplyCrate(1794, 970, amDynamite)

	ShowMission(loc("Teamwork 2"), loc("Scenario"), loc("Eliminate WatchBot 4000.") .. "|" .. loc("Both your hedgehogs must survive.") .. "|" .. loc("Land mines explode instantly."), -amBaseballBat, 0)

	AddGear(355, 822, gtSMine, 0, 0, 0, 0)
	AddGear(515, 525, gtSMine, 0, 0, 0, 0)
	AddGear(1080, 821, gtMine, 0, 0, 0, 0)
	AddGear(1055, 821, gtMine, 0, 0, 0, 0)
	AddGear(930, 587, gtMine, 0, 0, 0, 0)
	AddGear(955, 556, gtMine, 0, 0, 0, 0)
	AddGear(980, 556, gtMine, 0, 0, 0, 0)
	AddGear(1005, 556, gtMine, 0, 0, 0, 0)
	AddGear(710, 790, gtMine, 0, 0, 0, 0)
	AddGear(685, 790, gtMine, 0, 0, 0, 0)
	AddGear(660, 790, gtMine, 0, 0, 0, 0)
	AddGear(1560, 540, gtMine, 0, 0, 0, 0)
	AddGear(1610, 600, gtMine, 0, 0, 0, 0)
	AddGear(1660, 655, gtMine, 0, 0, 0, 0)
	AddGear(713, 707, gtMine, 0, 0, 0, 0)
	AddGear(1668, 969, gtExplosives, 0, 0, 0, 0)
	AddGear(1668, 906, gtExplosives, 0, 0, 0, 0)
	AddGear(1668, 842, gtExplosives, 0, 0, 0, 0)
	AddGear(1713, 969, gtExplosives, 0, 0, 0, 0)
	SetWind(90)

	-- The enemy has no weapons and can only skip
	for i=0, AmmoTypeMax do
		if i ~= amNothing and i ~= amSkip then
			AddAmmo(enemy, i, 0)
		end
	end
end

function onGearAdd(gear)
	if GetGearType(gear) == gtJetpack then
		SetHealth(gear, 300)
	end
end

function onAmmoStoreInit()
	SetAmmo(amParachute, 1, 0, 0, 2)
	SetAmmo(amSwitch, 9, 0, 0, 0)
	SetAmmo(amSkip, 9, 0, 0, 0)
	SetAmmo(amPickHammer, 0, 0, 0, 1)
	SetAmmo(amBaseballBat, 0, 0, 0, 1)
	SetAmmo(amBlowTorch, 0, 0, 0, 2)
	SetAmmo(amJetpack, 0, 0, 0, 1)
	SetAmmo(amDynamite, 0, 0, 0, 1)
end

function onGearDelete(gear)
	if gear == Pack then
		HogSay(CurrentHedgehog, loc("This will certainly come in handy."), SAY_THINK)
	end
	-- Note: The victory sequence is done automatically by Hedgewars
	if ( ((gear == player) or (gear == hlayer)) and (GameOver == false)) then
		ShowMission(loc("Teamwork 2"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)
		GameOver = true
		SetHealth(hlayer, 0)
		SetHealth(player, 0)
	end
end

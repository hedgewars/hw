-- Hedgewars - Basketball for 2+ Players

HedgewarsScriptLoad("/Scripts/Locale.lua")

local started = false

function onGameInit()
	GameFlags = gfSolidLand + gfBorder + gfInvulnerable + gfLowGravity
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0
	Delay = 500
    Map = 'BasketballField'
	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0
end

function onGameStart()
	ShowMission(loc("Basketball"), loc("Not So Friendly Match"), loc("Bat your opponents through the|baskets and out of the map!"), -amBaseballBat, 0)
	started = true
end

function onAmmoStoreInit()
	SetAmmo(amBaseballBat, 9, 0, 0, 0)
	SetAmmo(amSkip, 9, 0, 0, 0)
end

function onNewTurn()
    SetWeapon(amBaseballBat)
end

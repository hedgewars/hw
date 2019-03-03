-------------------------------------------
-- FRENZY
-- a hedgewars mode inspired by Hysteria
-------------------------------------------

HedgewarsScriptLoad("/Scripts/Locale.lua")

local cTimer = 0
local cn = 0

local frenzyAmmos = {
	amBazooka,
	amGrenade,
	amMolotov,
	amShotgun,
	amFirePunch,
	amMine,
	amJetpack,
	amBlowTorch,
	amTeleport,
	amLowGravity
}

function showStartingInfo()

	ruleSet = "" ..
	loc("RULES:") .. " |" ..
	loc("Each turn is only ONE SECOND!") .. "|" ..
	loc("Use your ready time to think.")
	if INTERFACE ~= "touch" then
		ruleSet = ruleSet .. "|" ..
		loc("Slot keys save time! (F1-F10 by default)") .. "| |"
		for i=1, #frenzyAmmos do
			ruleSet = ruleSet .. string.format(loc("Slot %d: %s"), i, GetAmmoName(frenzyAmmos[i])) .. "|"
		end
	end

	ShowMission(loc("FRENZY"),
                loc("A frenetic Hedgewars mini-game"),
                ruleSet, 0, 4000)

end

function onGameInit()

	if TurnTime > 8000 then
		Ready = 8000
	else
		Ready = TurnTime
	end

	TurnTime = 1000

	--These are the official settings, but I think I prefer allowing customization in this regard
	--MinesNum = 8
	--MinesTime = 3000
	--MinesDudPercent = 30
	--Explosives = 0

	--Supposedly official settings
	HealthCaseProb = 0
	CrateFreq = 0

	--Approximation of Official Settings
	--SuddenDeathTurns = 10
	--WaterRise = 47
	--HealthDecrease = 0

end

function onGameStart()
	showStartingInfo()
end

function onSlot(sln)
	cTimer = 8
	cn = sln
end

function onGameTick()
	if cTimer ~= 0 then
		cTimer = cTimer -1
		if cTimer == 1 then
			ChangeWep(cn)
			cn = 0
			cTimer = 0
		end
	end
end

-- Keyboard slot shortcuts
function ChangeWep(s)

	if s >= 0 and s <= 9 then
		SetWeapon(frenzyAmmos[s+1])
	end

end

function onAmmoStoreInit()
	-- Add frenzy ammos
	for i=1, #frenzyAmmos do
		SetAmmo(frenzyAmmos[i], 9, 0, 0, 0)
	end
	SetAmmo(amSkip, 9, 0, 0, 0)
end

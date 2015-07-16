-------------------------------------------
-- FRENZY
-- a hedgewars mode inspired by Hysteria
-------------------------------------------

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

local cTimer = 0
local cn = 0

function initialSetup(gear)
	SetHealth(gear, 75) -- official is 80, but that assumes bazookas/grenades that do 50 damage
end

function showStartingInfo()

	ruleSet = "" ..
	loc("RULES") .. ": " .. "|" ..
	loc("Each turn is only ONE SECOND!") .. "|" ..
	loc("Use your ready time to think.") .. "|" ..
	loc("Slot keys save time! (F1-F10 by default)") .. "|" ..
	" |" ..
	loc("SLOTS") .. ": " .. "|" ..
	loc("Slot") .. " 1 - " .. loc("Bazooka") .. "|" ..
	loc("Slot") .. " 2 - " .. loc("Grenade") .. "|" ..
	loc("Slot") .. " 3 - " .. loc("Shotgun") .. "|" ..
	loc("Slot") .. " 4 - " .. loc("Shoryuken") .. "|" ..
	loc("Slot") .. " 5 - " .. loc("Mine") .. "|" ..
	loc("Slot") .. " 6 - " .. loc("Teleport") .. "|" ..
	loc("Slot") .. " 7 - " .. loc("Blowtorch") .. "|" ..
	loc("Slot") .. " 8 - " .. loc("Flying Saucer") .. "|" ..
	loc("Slot") .. " 9 - " .. loc("Molotov") .. "|" ..
	loc("Slot") .. " 10 - " .. loc("Low Gravity")

	ShowMission(loc("FRENZY"),
                loc("a frenetic Hedgewars mini-game"),
                ruleSet, 0, 4000)

end

function onGameInit()

	if TurnTime > 10001 then
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
	runOnHogs(initialSetup)
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

function ChangeWep(s)

	if s == 0 then
		SetWeapon(amBazooka)
	elseif s == 1 then
		SetWeapon(amGrenade)
	elseif s == 2 then
		SetWeapon(amShotgun)
	elseif s == 3 then
		SetWeapon(amFirePunch)
	elseif s == 4 then
		SetWeapon(amMine)
	elseif s == 5 then
		SetWeapon(amTeleport)
	elseif s == 6 then
		SetWeapon(amBlowTorch)
	elseif s == 7 then
		SetWeapon(amJetpack)
	elseif s == 8 then
		SetWeapon(amMolotov)
	elseif s == 9 then
		SetWeapon(amLowGravity)
	end

end

function onGearAdd(gear)
	if GetGearType(gear) == gtHedgehog then
		trackGear(gear)
	end
end

function onGearDelete(gear)
	if GetGearType(gear) == gtHedgehog then
		trackDeletion(gear)
	end
end

function onAmmoStoreInit()
	SetAmmo(amBazooka, 9, 0, 0, 0)
	SetAmmo(amGrenade, 9, 0, 0, 0)
	SetAmmo(amMolotov, 9, 0, 0, 0)
	SetAmmo(amShotgun, 9, 0, 0, 0)
	--SetAmmo(amFlamethrower, 9, 0, 0, 0) -- this was suggested on hw.org but it's not present on base
	SetAmmo(amFirePunch, 9, 0, 0, 0)
	SetAmmo(amMine, 9, 0, 0, 0)
	--SetAmmo(amCake, 1, 0, 2, 0) -- maybe it's beefcake?
	SetAmmo(amJetpack, 9, 0, 0, 0)
	SetAmmo(amBlowTorch, 9, 0, 0, 0)
	SetAmmo(amTeleport, 9, 0, 0, 0)
	SetAmmo(amLowGravity, 9, 0, 0, 0)
	--SetAmmo(amSkipGo, 9, 0, 0, 0) -- not needed with 1s turn time
end

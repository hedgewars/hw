-- Hedgewars - Basketball for 2+ Players

HedgewarsScriptLoad("/Scripts/Locale.lua")

local score = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}

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

function onGameTick()
end

function onAmmoStoreInit()
	SetAmmo(amBaseballBat, 9, 0, 0, 0)
	SetAmmo(amSkip, 9, 0, 0, 0)
end

function onGearAdd(gear)
end

function onGearDelete(gear)
	if not started then
		return
	end
	if (GetGearType(gear) == gtHedgehog) and CurrentHedgehog ~= nil then
		local clan = GetHogClan(CurrentHedgehog)
		local s
		if clan ~= nil then
			if GetHogClan(CurrentHedgehog) ~= GetHogClan(gear) then
				score[clan] = score[clan] + 1
				s = string.format(loc("%s is out and Team %d|scored a point!| |Score:"), GetHogName(gear), clan + 1)
			else
				score[clan] = score[clan] - 1
				s = string.format(loc("%s is out and Team %d|scored a penalty!| |Score:"), GetHogName(gear), clan + 1)
			end
			s = s .. " " .. score[0]
			for i = 1, ClansCount - 1 do s = s .. " - " .. score[i] end
			ShowMission(loc("Basketball"), loc("Not So Friendly Match"), s, -amBaseballBat, 0)
		end
	end
end

function onNewTurn()
    SetWeapon(amBaseballBat)
end

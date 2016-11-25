-- Hedgewars - Knockball for 2+ Players

HedgewarsScriptLoad("/Scripts/Locale.lua")

local score = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}

local ball = nil

local started = false

function onGameInit()
	GameFlags = gfSolidLand + gfInvulnerable + gfDivideTeams
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0
	Delay = 500
	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0
end

function onGameStart()
	ShowMission(loc("Knockball"), loc("Not So Friendly Match"), loc("Bat balls at your enemies and|push them into the sea!"), -amBaseballBat, 0)
	started = true
end

function onGameTick()
	if ball ~= nil and GetFollowGear() ~= nil then FollowGear(ball) end
end

function onAmmoStoreInit()
	SetAmmo(amBaseballBat, 9, 0, 0, 0)
	SetAmmo(amSkip, 9, 0, 0, 0)
end

function onGearAdd(gear)
	if GetGearType(gear) == gtShover then
		ball = AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtBall, 0, 0, 0, 0)
		if ball ~= nil then
			local dx, dy = GetGearVelocity(gear)
			SetGearVelocity(ball, dx * 2, dy * 2)
			SetState(ball, 0x200) -- temporary - might change!
			SetTag(ball, 8) -- baseball skin
			FollowGear(ball)
		end
	end
end

function onGearDelete(gear)
	if not started then
		return
	end
	if gear == ball then
		ball = nil
	elseif (GetGearType(gear) == gtHedgehog) and CurrentHedgehog ~= nil then
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
			ShowMission(loc("Knockball"), loc("Not So Friendly Match"), s, -amBaseballBat, 0)
		end
	end
end

function onNewTurn()
    SetWeapon(amBaseballBat)
end

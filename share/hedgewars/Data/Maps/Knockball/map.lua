-- Hedgewars - Knockball for 2+ Players

HedgewarsScriptLoad("/Scripts/Locale.lua")

local ball = nil

function onGameInit()
	GameFlags = gfSolidLand + gfInvulnerable + gfDivideTeams
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0
	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0
end

function onGameStart()
	ShowMission(loc("Knockball"), loc("Not So Friendly Match"), loc("Bat balls at your enemies and|push them into the sea!"), -amBaseballBat, 0)
	SetAmmoTexts(amBaseballBat, loc("Baseball Bat with Ball"), loc("Knockball weapon"), loc("Throw a baseball at your foes|and send them flying!") .. "|" .. loc("Attack: Throw ball"))
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
	if gear == ball then
		ball = nil
	end
end

function onNewTurn()
    SetWeapon(amBaseballBat)
end

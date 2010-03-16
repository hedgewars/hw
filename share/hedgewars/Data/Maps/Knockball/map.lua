-- Hedgewars - Knockball for 2+ Players

local caption = {
	["en"] = "Hedgewars-Knockball",
	["de"] = "Hedgewars-Knockball"
	}

local subcaption = {
	["en"] = "Not So Friendly Match",
	["de"] = "Kein-so-Freundschaftsspiel"
	}

local goal = {
	["en"] = "Bat balls at your enemies and|push them into the sea!",
	["de"] = "Schlage Bälle auf deine Widersacher|und lass sie ins Meer fallen!"
	}

local scored = {
	["en"] = " scored a point!",
	["de"] = " erhält einen Punkt!"
	}

local failed = {
	["en"] = " scored a penalty!",
	["de"] = " erhält eine Strafe!"
	}

	local sscore = {
	["en"] = "Score",
	["de"] = "Punktestand"
	}

local team = {
	["en"] = "Team"
	}

local drowning = {
	["en"] = "is out and",
	["de"] = "ist draußen und"
	}

local function loc(text)
	if text == nil then return "**missing**"
	elseif text[L] == nil then return text["en"]
	else return text[L]
	end
end

---------------------------------------------------------------

local score = {[0] = 0, [1] = 0, [2] = 0, [3] = 0, [4] = 0, [5] = 0}

local ball = nil

function onGameInit()
	GameFlags = gfSolidLand + gfInvulnerable + gfDivideTeams
	TurnTime = 20000
	CaseFreq = 0
	LandAdds = 0
	Explosives = 0
	Delay = 500
end

function onGameStart()
	ShowMission(loc(caption), loc(subcaption), loc(goal), -amBaseballBat, 0);
end

function onGameTick()
	if ball ~= nil then FollowGear(ball) end
end

function onAmmoStoreInit()
	SetAmmo(amBaseballBat, 9, 0, 0)
	SetAmmo(amSkip, 9, 0, 0)
end

function onGearAdd(gear)
	if GetGearType(gear) == gtShover then
		ball = AddGear(GetX(gear), GetY(gear), gtBall, 0, 0, 0, 0)
		if ball ~= nil then
			CopyPV2(gear, ball)
			SetState(ball, 0x200) -- temporary - might change!
			SetTag(ball, 8) -- baseball skin
		end
	end
end

function onGearDelete(gear)
	if gear == ball then
		ball = nil
	elseif (GetGearType(gear) == gtHedgehog) and CurrentHedgehog ~= nil then
		local clan = GetHogClan(CurrentHedgehog)
		local s = GetHogName(gear) .. " " .. loc(drowning) .. "|" .. loc(team) .. " " .. (clan + 1) .. " "
		if GetHogClan(CurrentHedgehog) ~= GetHogClan(gear) then
			score[clan] = score[clan] + 1
			s = s .. loc(scored)
		else
			score[clan] = score[clan] - 1
			s = s .. loc(failed)
		end
		s = s .. "| |" .. loc(sscore) .. ": " .. score[0]
		for i = 1, ClansCount - 1 do s = s .. " - " .. score[i] end
		ShowMission(loc(caption), loc(subcaption), s, -amBaseballBat, 0)
	end
end

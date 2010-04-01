-- Hedgewars - Knockball for 2+ Players

local caption = {
	["en"] = "Hedgewars-Knockball",
	["de"] = "Hedgewars-Knockball",
	["es"] = "Hedgewars-Knockball",
	["pl"] = "Hedgewars-Knockball"
	}

local subcaption = {
	["en"] = "Not So Friendly Match",
	["de"] = "Kein-so-Freundschaftsspiel",
	["es"] = "Partido no-tan-amistoso",
	["pl"] = "Mecz Nie-Taki-Towarzyski"
	}

local goal = {
	["en"] = "Bat balls at your enemies and|push them into the sea!",
	["de"] = "Schlage Bälle auf deine Widersacher|und lass sie ins Meer fallen!",
	["es"] = "¡Batea pelotas hacia tus enemigos|y hazlos caer al agua!",
	["pl"] = "Uderzaj piłkami w swoich przeciwników|i strącaj ich do wody!"
	}

local scored = {
	["en"] = "%s is out and Team %d|scored a point!| |Score:",
	["de"] = "%s ist draußen und Team %d|erhält einen Punkt!| |Punktestand:",
	["es"] = "¡%s cayó y Equipo %d|anotó un tanto!| |Puntuación:",
	["pl"] = "%s utonął i drużyna %d|zdobyła punkt!| |Punktacja:"
	}

local failed = {
	["en"] = "%s is out and Team %d|scored a penalty!| |Score:",
	["de"] = "%s ist draußen und Team %d|erhält eine Strafe!| |Punktestand:",
	["es"] = "¡%s cayó y Equipo %d|anotó una falta!| |Puntuación:",
	["pl"] = "%s utonął i drużyna %d|dostała punkt karny!| |Punktacja:"
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
	SuddenDeathTurns = 99999 -- "disable" sudden death
end

function onGameStart()
	ShowMission(loc(caption), loc(subcaption), loc(goal), -amBaseballBat, 0);
end

function onGameTick()
	if ball ~= nil and GetFollowGear() ~= nil then FollowGear(ball) end
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
			FollowGear(ball)
		end
	end
end

function onGearDelete(gear)
	if gear == ball then
		ball = nil
	elseif (GetGearType(gear) == gtHedgehog) and CurrentHedgehog ~= nil then
		local clan = GetHogClan(CurrentHedgehog)
		local s
		if GetHogClan(CurrentHedgehog) ~= GetHogClan(gear) then
			score[clan] = score[clan] + 1
			s = string.format(loc(scored), GetHogName(gear), clan + 1)
		else
			score[clan] = score[clan] - 1
			s = string.format(loc(failed), GetHogName(gear), clan + 1)
		end
		s = s .. " " .. score[0]
		for i = 1, ClansCount - 1 do s = s .. " - " .. score[i] end
		ShowMission(loc(caption), loc(subcaption), s, -amBaseballBat, 0)
	end
end

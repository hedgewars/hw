HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Scripts/Locale.lua")

local hhs = {}
local missionWon = nil
local missionEndHandled = false
local endTimer = 1000
local hogsKilled = 0
local finishTime
local ouchies = false
local valkyriesTimer = -1

local HogData =	{
					{"amn",			"NinjaFull",false},
					{"alfadur",		"NoHat",false},
					{"Anachron",		"war_americanww2helmet",false},
					{"Bufon", 			"ShaggyYeti",false},
					{"burp", 			"lambda",false},
					{"Blue", 			"cap_blue",false},
					{"bender", 			"NoHat",false},
					{"Castell",			"NoHat",false},
					{"cekoto", 			"NoHat",false},
					{"CheezeMonkey",	"NoHat",false},
					{"claymore", 		"NoHat",false},
					{"CIA-144", 		"cyborg1",false},
					{"cri.the.grinch",	"sf_blanka",false},
					{"eldiablo",		"Evil",false},
					{"Displacer",		"fr_lemon",false},
					{"doomy", 			"NoHat",false},
					{"Falkenauge", 		"NoHat",false},
					{"FadeOne", 		"NoHat",false},
					{"hayaa", 			"NoHat",false},
					{"Hermes", 			"laurel",false},
					{"Henek", 		"WizardHat",false},
					{"HedgeKing",		"NoHat",false},
					{"Izack1535", 		"NoHat",false},
					{"Kiofspa", 		"NoHat",false},
					{"KoBeWi",		"NoHat",false},
					{"Komplex", 		"NoHat",false},
					{"koda", 			"poke_mudkip",false},
					{"Lalo", 			"NoHat",false},
					{"Logan", 			"NoHat",false},
					{"lollkiller", 		"NoHat",false},
					{"Luelle", 			"NoHat",false},
					{"mikade", 			"Skull",false},
					{"Mushi", 			"sm_daisy",false},
					{"Naboo", 			"NoHat",false},
					{"nemo", 			"bb_bub",false},
					{"practice", 		"NoHat",false},
					{"Prof. Panic",  	"NoHat",false},
					{"Randy",			"zoo_Sheep",false},
					{"rhino", 			"NinjaTriangle",false},
					{"Radissthor",  	"NoHat",false},
					{"Sami",			"sm_peach",false},
					{"soreau", 			"NoHat",false},
					{"Solar",		"pinksunhat",false},
					{"sparkle",		"NoHat",false},
					{"szczur", 		"mp3",false},
					{"sdw195", 			"NoHat",false},
					{"sphrix", 			"TeamTopHat",false},
					{"sheepluva",		"zoo_Sheep",false},
					{"Smaxx", 			"NoHat",false},
					{"shadowzero", 		"NoHat",false},
					{"Star and Moon",	"SparkleSuperFun",false},
					{"The 24",			"NoHat",false},
					{"TLD",				"NoHat",false},
					{"Tiyuri", 			"sf_ryu",false},
					{"unC0Rr", 			"cyborg1",false},
					{"Waldsau", 		"cyborg1",false},
					{"wolfmarc", 		"knight",false},
					{"Wuzzy",		"fr_orange",false},
					{"Xeli", 			"android",false}

				}

local playerTeamName

function GetKillScore()
	return math.ceil((hogsKilled / 16)*6000)
end

function ProtectEnemies()
	for i=1, 16 do
		if hhs[i] and GetHealth(hhs[i]) then
			SetEffect(hhs[i], heInvulnerable, 1)
		end
	end
end

function GameOverMan()
	StopMusicSound(sndRideOfTheValkyries)
	valkyriesTimer = -1
	missionWon = false
	ProtectEnemies()
	ShowMission(loc("Rope-knocking Challenge"), loc("Challenge over!"), loc("Oh no! Just try again!"), -amSkip, 0)
	SendStat(siGameResult, loc("Challenge over!"))
	local score = GetKillScore()
	SendStat(siCustomAchievement, string.format(loc("You have killed %d of 16 hedgehogs (+%d points)."), hogsKilled, score))
	SendStat(siPointType, loc("points"))
	SendStat(siPlayerKills, tostring(score), playerTeamName)
	PlaySound(sndHellish)

	-- Update highscore
	updateChallengeRecord("Highscore", score)

	EndGame()
end

function GG()
	missionWon = true
	local completeTime = (TurnTime - finishTime) / 1000
	ShowMission(loc("Rope-knocking Challenge"), loc("Challenge completed!"), loc("Congratulations!") .. "|" .. string.format(loc("Completion time: %.2fs"), completeTime), 0, 0)
	PlaySound(sndHomerun)
	SendStat(siGameResult, loc("Challenge completed!"))
	local hogScore = GetKillScore()
	local timeScore = math.ceil((finishTime/TurnTime)*6000)
	local score = hogScore + timeScore

	SendStat(siCustomAchievement, string.format(loc("You have killed %d of 16 hedgehogs (+%d points)."), hogsKilled, hogScore))
	SendStat(siCustomAchievement, string.format(loc("You have completed this challenge in %.2f s (+%d points)."), completeTime, timeScore))
	SendStat(siPointType, loc("points"))
	SendStat(siPlayerKills, tostring(score), playerTeamName)
	SetTeamLabel(playerTeamName, tostring(score))

	-- Update highscore
	updateChallengeRecord("Highscore", score)

	if hhs[0] and GetHealth(hhs[0]) then
		SetEffect(hhs[0], heInvulnerable, 1)
	end
	SetTurnTimeLeft(MAX_TURN_TIME)
end

function AssignCharacter(p)

	done = false
	sanityCheck = 0

	while(done == false) do

		i = 1+ GetRandom(#HogData)
		if HogData[i][3] == false then
			HogData[i][3] = true
			done = true
			SetHogName(hhs[p], HogData[i][1])
			SetHogHat(hhs[p], HogData[i][2])
		elseif HogData[i][3] == true then
			sanityCheck = sanityCheck +1
			if sanityCheck == 100 then
				done = true
				SetHogName(hhs[p], "Newbie")
				SetHogHat(hhs[p], "NoHat")
			end
		end

	end

end

function onGameInit()

	--Seed = 1
	GameFlags = gfBorder + gfSolidLand

	TurnTime = 180 * 1000
	Map = "Ropes"
	Theme = "Eyes"

	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0

	CaseFreq = 0
	MinesNum = 0
	Explosives = 0

	playerTeamName = AddMissionTeam(-1)
	hhs[0] = AddMissionHog(1)
	SetGearPosition(player, 1380, 1500)

	AddTeam(loc("Unsuspecting Louts"), -2, "Simple", "Island", "Default", "cm_face")
	for i = 1, 8 do
		-- The name "generic" is a placeholder and will be replaced in AssignCharacter
		hhs[i] = AddHog("generic", 0, 1, "NoHat")
	end

	AddTeam(loc("Unlucky Sods"), -2, "Simple", "Island", "Default", "cm_balrog")
	for i = 9, 16 do
		hhs[i] = AddHog("generic", 0, 1, "NoHat")
	end

end



function onGameStart()
	SendHealthStatsOff()

	local recordInfo = getReadableChallengeRecord("Highscore")
	if recordInfo == nil then
		recordInfo = ""
	else
		recordInfo = "|" .. recordInfo
	end
	ShowMission     (
                        loc("Rope-knocking Challenge"),
                        loc("Challenge"),
                        loc("Use the rope to knock your enemies to their doom.") .. "|" ..
                        loc("Finish this challenge as fast as possible to earn bonus points.").. recordInfo,
                        -amRope, 4000)
	SetTeamLabel(playerTeamName, "0")

	PlaceGirder(46,1783, 0)

	SetGearPosition(hhs[0], 2419, 1769)
	SetGearPosition(hhs[1], 3350, 570)
	SetGearPosition(hhs[2], 3039, 1300)
	SetGearPosition(hhs[3], 2909, 430)
	SetGearPosition(hhs[4], 2150, 879)
	SetGearPosition(hhs[5], 1735, 1136)
	SetGearPosition(hhs[6], 1563, 553)
	SetGearPosition(hhs[7], 679, 859)
	SetGearPosition(hhs[8], 1034, 251)
	SetGearPosition(hhs[9], 255, 67)
	SetGearPosition(hhs[10], 2671, 7)
	SetGearPosition(hhs[11], 2929, 244)
	SetGearPosition(hhs[12], 1946, 221)
	SetGearPosition(hhs[13], 3849, 1067)
	SetGearPosition(hhs[14], 3360, 659)
	SetGearPosition(hhs[15], 3885, 285)
	SetGearPosition(hhs[16], 935, 1160)

	for i = 1, 16 do
		AssignCharacter(i)
	end

end

function onGameTick()

	if (TurnTimeLeft == 1) and (missionWon == nil) then
		GameOverMan()
	end

	if missionWon ~= nil then

		endTimer = endTimer - 1
		if endTimer == 1 then
			EndGame()
		end

		if not missionEndHandled then
			if missionWon == true then
				SaveMissionVar("Won", "true")
				AddCaption(loc("Victory!"), capcolDefault, capgrpGameState)
			else
				AddCaption(loc("Challenge over!"), capcolDefault, capgrpGameState)
			end
			missionEndHandled = true
		end

	end

end

function onGameTick20()
	if (valkyriesTimer > 0) then
		valkyriesTimer = valkyriesTimer - 20
		if valkyriesTimer <= 0 then
			StopMusicSound(sndRideOfTheValkyries)
		end
	end
end

function onGearDamage(gear, damage)

	if gear == hhs[0] then
		ouchies = true
		StopMusicSound(sndRideOfTheValkyries)
		valkyriesTimer = -1
		ProtectEnemies()
	end

	if gear ~= hhs[0] and GetGearType(gear) == gtHedgehog and missionWon == nil and ouchies == false then

		AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
		DeleteGear(gear)
		PlaySound(sndExplosion)
		AddCaption(string.format(knockTaunt(), GetHogName(gear)), capcolDefault, capgrpMessage)

		hogsKilled = hogsKilled +1
		SetTeamLabel(playerTeamName, tostring(GetKillScore()))

		if hogsKilled == 15 then
			PlayMusicSound(sndRideOfTheValkyries)
			-- Time in ms after which to return to normal music
			valkyriesTimer = 20000
		elseif hogsKilled == 16 then
			finishTime = TurnTimeLeft
			GG()
		end

	end

end

function knockTaunt()
	local r = math.random(0,23)
	local taunt
	if r == 0 then taunt =		loc("%s has been knocked out.")
	elseif r == 1 then taunt =	loc("%s hit the ground.")
	elseif r == 2 then taunt =	loc("%s splatted.")
	elseif r == 3 then taunt =	loc("%s was smashed.")
	elseif r == 4 then taunt =	loc("%s felt unstable.")
	elseif r == 5 then taunt =	loc("%s exploded.")
	elseif r == 6 then taunt =	loc("%s fell from a high cliff.")
	elseif r == 7 then taunt =	loc("%s goes the way of the lemming.")
	elseif r == 8 then taunt =	loc("%s was knocked away.")
	elseif r == 9 then taunt =	loc("%s was really unlucky.")
	elseif r == 10 then taunt =	loc("%s felt victim to rope-knocking.")
	elseif r == 11 then taunt =	loc("%s had no chance.")
	elseif r == 12 then taunt =	loc("%s was a good target.")
	elseif r == 13 then taunt =	loc("%s spawned at a really bad position.")
	elseif r == 14 then taunt =	loc("%s was doomed from the beginning.")
	elseif r == 15 then taunt =	loc("%s has fallen victim to gravity.")
	elseif r == 16 then taunt =	loc("%s hates Newton.")		-- Isaac Newton
	elseif r == 17 then taunt =	loc("%s had it coming.")
	elseif r == 18 then taunt =	loc("%s is eliminated!")
	elseif r == 19 then taunt =	loc("%s fell too fast.")
	elseif r == 20 then taunt =	loc("%s flew like a rock.")
	elseif r == 21 then taunt =	loc("%s stumbled.")
	elseif r == 22 then taunt =	loc("%s was shoved away.")
	elseif r == 23 then taunt =	loc("%s didn't expect that.")
	end
	return taunt
end

function onGearDelete(gear)

	if (gear == hhs[0]) and (missionWon == nil) then
		GameOverMan()
	end

end

function onAmmoStoreInit()
	SetAmmo(amRope, 9, 0, 0, 0)
end

function onNewTurn()
 	SetWeapon(amRope)
end

HedgewarsScriptLoad("/Scripts/Locale.lua")

local hhs = {}
local missionWon = nil
local endTimer = 1000
local hogsKilled = 0

local HogData =	{
					{"Bufon", 			"ShaggyYeti",false},
					{"burp", 			"lambda",false},
					{"Blue", 			"cap_blue",false},
					{"bender", 			"NoHat",false},
					{"Castell",			"NoHat",false},
					{"cekoto", 			"NoHat",false},
					{"CheezeMonkey",	"NoHat",false},
					{"claymore", 		"NoHat",false},
					{"CIA-144", 		"cyborg1",false},
					{"doomy ", 			"NoHat",false},
					{"Falkenauge", 		"NoHat",false},
					{"FadeOne", 		"NoHat",false},
					{"hayaa", 			"NoHat",false},
					{"Hermes", 			"laurel",false},
					{"HedgeKing",		"NoHat",false},
					{"Izack1535", 		"NoHat",false},
					{"Kiofspa", 		"NoHat",false},
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
					{"Xeli", 			"android",false}

				}

function GenericEnd()
	DismissTeam(loc("Wannabe Shoppsta"))
	DismissTeam(loc("Unsuspecting Louts"))
	DismissTeam(loc("Unlucky Sods"))
end

function GameOverMan()
	missionWon = false
	ShowMission(loc("ROPE-KNOCKING"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)
	PlaySound(sndHellish)
end

function GG()
	missionWon = true
	ShowMission(loc("ROPE-KNOCKING"), loc("MISSION SUCCESS"), loc("Congratulations!") .. "|" .. loc("COMPLETION TIME") .. ": " .. (TurnTime - TurnTimeLeft) / 1000, 0, 0)
	PlaySound(sndHomerun)
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
	Delay = 500
	Map = "Ropes"
	Theme = "Eyes"

	CaseFreq = 0
	MinesNum = 0
	Explosives = 0

	AddTeam(loc("Wannabe Shoppsta"), 1175851, "Simple", "Island", "Default", "Hedgewars")
	hhs[0] = AddHog(loc("Ace"), 0, 1, "Gasmask")
	SetGearPosition(player, 1380, 1500)

	AddTeam(loc("Unsuspecting Louts"), 14483456, "Simple", "Island", "Default", "Hedgewars")
	for i = 1, 8 do
		hhs[i] = AddHog("generic", 0, 1, "NoHat")
	end

	AddTeam(loc("Unlucky Sods"), 14483456, "Simple", "Island", "Default", "Hedgewars")
	for i = 9, 16 do
		hhs[i] = AddHog("generic", 0, 1, "NoHat")
	end

end



function onGameStart()

	ShowMission     (
                        loc("ROPE-KNOCKING"),
                        loc("a Hedgewars challenge"),
                        loc("Use the rope to knock your enemies to their doom.") .. "|" ..

						"", -amRope, 4000
					)

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
			GenericEnd()
		end

		if missionWon == true then
			AddCaption(loc("GG!"), 0xffba00ff,capgrpGameState)
		else
			AddCaption(loc("Ouch!"), 0xffba00ff,capgrpGameState)
		end

	end

end

function onGearDamage(gear, damage)

	if gear ~= hhs[0] then

		AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
		DeleteGear(gear)
		PlaySound(sndExplosion)

		hogsKilled = hogsKilled +1
		if hogsKilled == 15 then
			PlaySound(sndRideOfTheValkyries)
		elseif hogsKilled == 16 then
			GG()
		end

	end

end

function onGearDelete(gear)

	if (gear == hhs[0]) and (missionWon == nil) then
		GameOverMan()
	end

end

function onAmmoStoreInit()
	SetAmmo(amRope, 9, 0, 0, 0)
end

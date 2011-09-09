

loadfile(GetDataPath() .. "Scripts/Locale.lua")()

local player
local hh = {}
local hhCount = 8
local GameOver = false
local introStage = 0
local genCounter = 0
local waterCounter = 0
local waterPix = 0
local frig = 0
local watGear = nil

-- allow skipping of the intro via hitting precise key
function onPrecise()
	if introStage < 100 then
		introStage = 110
		genCounter = 0
		FollowGear(CurrentHedgehog)
		AddCaption(loc("Good luck out there!"))
		ShowMission(loc("That Sinking Feeling"), loc("User Challenge"), loc("Save as many hapless hogs as possible!"), 4, 0)
	end
end

function onGameInit()

	Seed = 0
	GameFlags = gfInfAttack + gfInvulnerable
	TurnTime = 90000
	CaseFreq = 0
	MinesNum = 0
	MinesTime  = 3000
	Explosives = 0
	Delay = 10
	Map = "Islands"
	Theme = "City"
	SuddenDeathTurns = 1

	AddTeam(loc("Nameless Heroes"), 14483456, "Simple", "Island", "Default")
	player = AddHog(loc("The Nameless One"), 0, 1, "NoHat")

	AddTeam(loc("Hapless Hogs"), 	1175851, "Simple", "Island", "Default")
	hh[0] = AddHog(loc("Sinky"), 1, 100, "fr_lemon")
	hh[1] = AddHog(loc("Drowner"), 1, 100, "fr_orange")
	hh[2] = AddHog(loc("Heavy"), 1, 100, "dish_Teapot")
	hh[3] = AddHog(loc("Clumsy"), 1, 100, "dish_SauceBoatSilver")
	hh[4] = AddHog(loc("Silly"), 1, 100, "dish_Ladle")
	hh[5] = AddHog(loc("Careless"), 1, 100, "StrawHatEyes")
	hh[6] = AddHog(loc("Sponge"), 1, 100, "sf_chunli")
	hh[7] = AddHog(loc("Deadweight"), 1, 100, "dish_Teacup")

	SetGearPosition(player, 3992, 733)
	SetGearPosition(hh[0], 938, 1369)
	SetGearPosition(hh[1], 1301, 1439)
	SetGearPosition(hh[2], 2093, 447)
	SetGearPosition(hh[3], 2971, 926)
	SetGearPosition(hh[4], 719, 545)
	SetGearPosition(hh[5], 1630, 821)
	SetGearPosition(hh[6], 2191, 810)
	SetGearPosition(hh[7], 3799, 945)

end


function onGameStart()

	ShowMission(loc("That Sinking Feeling"), loc("User Challenge"), loc("Save as many hapless hogs as possible!"), 4, 1)

	HogTurnLeft(hh[0], false)
	HogTurnLeft(hh[1], true)

	SpawnUtilityCrate(148,265,amLowGravity)
	SpawnUtilityCrate(2124,1516,amJetpack)

end


function onNewTurn()
	TurnTimeLeft = -1
end

function onGameTick()

	-- intro sequence
	if introStage < 100 then

		frig = frig + 1
		if frig == 50 then
			frig = 0			
			AddCaption(loc("Press [Precise] to skip intro"))
			if watGear ~= nil then			
				FollowGear(watGear)
			end
		end

		
		--AddCaption(loc("Press [Precise] to skip intro"))
		genCounter = genCounter + 1

		if introStage == 0 then

						
			--FollowGear(hh[0])

			if genCounter == 2000 then
				watGear = hh[0]
				HogSay(hh[0], loc("This rain is really something..."), SAY_SAY,2)
			elseif genCounter == 5000 then
				introStage = 1
				genCounter = 0
			end

		elseif introStage == 1 then
						
			--FollowGear(hh[1])

			if genCounter == 2000 then
				watGear = hh[1]
				HogSay(hh[1], loc("Heh, it's not that bad."), SAY_SAY,2)
			elseif genCounter == 5000 then
				introStage = 2
				genCounter = 0
			end

		elseif introStage == 2 then

			--FollowGear(hh[0])

			if genCounter == 2000 then
				watGear = hh[0]
				HogSay(hh[0], loc("You'd almost swear the water was rising!"), SAY_SHOUT,2)
			elseif genCounter == 6000 then
				introStage = 3
				genCounter = 0
			end

		elseif introStage == 3 then

			--FollowGear(hh[1])

			if genCounter == 2000 then
				watGear = hh[1]
				HogSay(hh[1], loc("Haha, now THAT would be something!"), SAY_SAY,2)
			elseif genCounter == 6000 then
				introStage = 4
				genCounter = 0
			end

		elseif introStage == 4 then

			--FollowGear(hh[0])

			if genCounter == 2000 then
				watGear = hh[0]
				HogSay(hh[0], loc("Hahahaha!"), SAY_SHOUT,2)
				HogSay(hh[1], loc("Hahahaha!"), SAY_SHOUT,2)
			elseif genCounter == 3000 then
				introStage = 5
				genCounter = 0
			end

		elseif introStage == 5 then

			--FollowGear(hh[1])

			if genCounter == 2000 then
				watGear = hh[1]
				HogSay(hh[0], loc("..."), SAY_THINK,2)
				HogSay(hh[1], loc("..."), SAY_THINK,2)
			elseif genCounter == 5000 then
				introStage = 6
				genCounter = 0
			end

		elseif introStage == 6 then

			--FollowGear(hh[0])

			if genCounter == 2000 then
				watGear = hh[0]
				HogSay(hh[0], loc("It's a good thing SUDDEN DEATH is 99 turns away..."), SAY_THINK,2)
			elseif genCounter == 6000 then
				introStage = 7
				genCounter = 0
			end


		elseif introStage == 7 then

			if genCounter == 2000 then
				introStage = 110
				FollowGear(CurrentHedgehog)
				ShowMission(loc("That Sinking Feeling"), loc("User Challenge"), loc("Save as many hapless hogs as possible!"), 4, 0)
			end

		end

	end

	-- start the water rising when the intro is finished
	if introStage == 110 then

		waterCounter = waterCounter + 1
		if (waterCounter == 100) and (waterPix < 1615) then
			waterCounter = 0
			SetTag(AddGear(0, 0, gtWaterUp, 0, 0, 0, 0), 1)
			waterPix = waterPix +1
			--AddCaption(waterPix)

			if (waterPix >= 1615) and (GameOver == false) then
				GameOver = true
				SetHealth(player, 0)
				TurnTimeLeft = 1
				ShowMission(loc("That Sinking Feeling"), loc("MISSION SUCCESS"), loc("You saved") .. " " .. hhCount .. " " .. loc("Hapless Hogs") .."!", 0, 0)

				if hhCount == 8 then
					AddCaption(loc("Achievement Unlocked") .. ": " .. loc("Lively Lifeguard"),0xffba00ff,capgrpMessage2)
				end

			end

		end

	end

	if TurnTimeLeft == 1 then
		SetHealth(player, 0)
	end

end


function onAmmoStoreInit()

	SetAmmo(amBazooka, 9, 0, 0, 0)

	SetAmmo(amRope, 9, 0, 0, 0)
	SetAmmo(amParachute, 9, 0, 0, 0)
	SetAmmo(amJetpack, 2, 0, 0, 2)

	SetAmmo(amGirder, 9, 0, 0, 0)
	SetAmmo(amBaseballBat, 9, 0, 0, 0)

	SetAmmo(amTeleport, 1, 0, 0, 1)
	SetAmmo(amPortalGun, 3, 0, 0, 1)

	SetAmmo(amLowGravity, 0, 0, 0, 1)

end

function onGearDelete(gear)

	if GetGearType(gear) == gtHedgehog then
		if GetHogTeamName(gear) == "Hapless Hogs" then
			hhCount = hhCount - 1
			AddCaption(hhCount .. loc(" Hapless Hogs left!"))
		end
	end

	if ((gear == player) or (hhCount == 0)) and (GameOver == false) then
		SetHealth(player, 0)
		TurnTimeLeft = 1
		ShowMission(loc("That Sinking Feeling"), loc("MISSION FAILED"), loc("Oh no! Just try again!"), -amSkip, 0)
		GameOver = true
	end

end

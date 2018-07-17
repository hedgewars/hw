

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Achievements.lua")

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
local cinematic = false

-- allow skipping of the intro via hitting precise key
function onPrecise()
	if introStage < 100 then
		introStage = 110
		genCounter = 0
		FollowGear(CurrentHedgehog)
		AddCaption(loc("Good luck out there!"))
		ShowMission(loc("That Sinking Feeling"), loc("Challenge"), loc("Save as many hapless hogs as possible!"), 4, 0)
		SetInputMask(0xFFFFFFFF)
	end
end

function onGameInit()

	Seed = 0
	GameFlags = gfInfAttack + gfInvulnerable + gfOneClanMode
	TurnTime = 90000
	CaseFreq = 0
	MinesNum = 0
	MinesTime  = 3000
	Explosives = 0
	Delay = 10
	Map = "Islands"
	Theme = "City"
	SuddenDeathTurns = 1

	AddTeam(loc("Hapless Hogs"), 14483456, "Simple", "Island", "Default")
	hh[0] = AddHog(loc("Sinky"), 1, 100, "fr_lemon")
	hh[1] = AddHog(loc("Drowner"), 1, 100, "fr_orange")
	hh[2] = AddHog(loc("Heavy"), 1, 100, "dish_Teapot")
	hh[3] = AddHog(loc("Clumsy"), 1, 100, "dish_SauceBoatSilver")
	hh[4] = AddHog(loc("Silly"), 1, 100, "dish_Ladle")
	hh[5] = AddHog(loc("Careless"), 1, 100, "StrawHatEyes")
	hh[6] = AddHog(loc("Sponge"), 1, 100, "sf_chunli")
	hh[7] = AddHog(loc("Deadweight"), 1, 100, "dish_Teacup")

	AddTeam(loc("Nameless Heroes"), 14483456, "Simple", "Island", "Default", "cm_crossedswords")
	player = AddHog(loc("The Nameless One"), 0, 1, "NoHat")

	SetGearPosition(player, 3992, 733)
	SetGearPosition(hh[0], 938, 1369)
	SetGearPosition(hh[1], 1301, 1439)
	SetGearPosition(hh[2], 2093, 447)
	SetGearPosition(hh[3], 2971, 926)
	SetGearPosition(hh[4], 719, 545)
	SetGearPosition(hh[5], 1630, 821)
	SetGearPosition(hh[6], 2191, 810)
	SetGearPosition(hh[7], 3799, 945)

	-- Disable all input except [Precise] for the intro
	SetInputMask(gmPrecise)
end


function onGameStart()
    cinematic = true
    SetCinematicMode(true)
	SendHealthStatsOff()

	ShowMission(loc("That Sinking Feeling"), loc("Challenge"), loc("Save as many hapless hogs as possible!"), 4, 1)

	HogTurnLeft(hh[0], false)
	HogTurnLeft(hh[1], true)

	SpawnSupplyCrate(148,265,amLowGravity)
	SpawnSupplyCrate(2124,1516,amJetpack)

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
				SetInputMask(0xFFFFFFFF)
			end

		end

	end

	-- start the water rising when the intro is finished
	if introStage == 110 then

        if cinematic then
            SetCinematicMode(false)
            cinematic = false
        end

		waterCounter = waterCounter + 1
		if (waterCounter == 100) and (waterPix < 1615) then
			waterCounter = 0
			SetTag(AddGear(0, 0, gtWaterUp, 0, 0, 0, 0), 1)
			waterPix = waterPix +1
			--AddCaption(waterPix)

			if (waterPix >= 1615) and (GameOver == false) then
				GameOver = true
				AddCaption(loc("The flood has stopped! Challenge over."))
				SendStat(siGameResult, loc("Challenge completed!"))
				SendStat(siPointType, loc("rescues"))
				SendStat(siPlayerKills, tostring(hhCount), loc("Nameless Heroes"))

				-- Do not count drowning hedgehogs
				local hhLeft = hhCount
				for i=1,#hh do
					local isDrowning = band(GetState(hh[i]),gstDrowning) ~= 0
					if isDrowning then
						hhLeft = hhLeft - 1
					end
				end

				SendStat(siCustomAchievement, string.format(loc("You saved %d of 8 Hapless Hogs."), hhLeft))

				if hhLeft == 8 then
					awardAchievement(loc("Lively Lifeguard"))
				end
				EndGame()

			end

		end

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
		if GetHogTeamName(gear) == loc("Hapless Hogs") then
			hhCount = hhCount - 1
			AddCaption(string.format(loc("%d Hapless Hogs left"), hhCount))
		end
	end

	if ((gear == player) or (hhCount == 0)) and (GameOver == false) then
		SetHealth(player, 0)
		AddCaption(loc("Disqualified!"))
		if gear == player then
			SendStat(siCustomAchievement, loc("Your hedgehog died!"))
			SendStat(siCustomAchievement, loc("You must survive the flood in order to score."))
		else
			SendStat(siCustomAchievement, loc("You haven't rescued anyone."))
		end
		SendStat(siPointType, loc("points"))
		SendStat(siPlayerKills, "0", loc("Nameless Heroes"))

		SendStat(siGameResult, loc("Disqualified!"))
		GameOver = true
		EndGame()
	end

end

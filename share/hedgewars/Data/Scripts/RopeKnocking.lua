HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")

local hhs = {}
local deadHogs = {}
local missionWon = nil
local endTimer = 1000
local hogsKilled = 0
local totalEnemies = 0
local finishTime
local playerFail = false
local ropeGear = nil
local endGameCalled = false
local missionEndHandled = false
local valkyriesTimer = -1

local valkyriesDuration = 20000
local timeBonus = 6000
local killBonus = 6000
local playValkyries = false

local extraTime

local playerTeamName
local missionName = loc("Rope-knocking Challenge")
-- Mission type:
-- 0 = none (no special handling)
-- 1 = challenge (saves mission vars)
local missionType = 1

local function getKillScore()
	return div(hogsKilled * killBonus, totalEnemies)
end

local function protectEnemies()
	-- Protect enemy hogs
	for i=1, totalEnemies do
		if hhs[i] and GetHealth(hhs[i]) then
			SetEffect(hhs[i], heInvulnerable, 1)
			SetEffect(hhs[i], heResurrectable, 1)
		end
	end
end

local function killStr(killed, total, score)
	if total == 16 then
		return string.format(loc("You have killed %d of 16 hedgehogs (+%d points)."), killed, score)
	else
		return string.format(loc("You have killed %d of %d hedgehogs (+%d points)."), killed, total, score)
	end
end

local function gameOver()
	StopMusicSound(sndRideOfTheValkyries)
	valkyriesTimer = -1
	missionWon = false
	SendStat(siGameResult, loc("Challenge over!"))
	local score = getKillScore()
	SendStat(siCustomAchievement, killStr(hogsKilled, totalEnemies, score))
	SendStat(siPointType, "!POINTS")
	SendStat(siPlayerKills, tostring(score), playerTeamName)
	protectEnemies()
	if not endGameCalled then
		EndGame()
		endGameCalled = true
	end
	if missionType == 1 then
		-- Update highscore
		updateChallengeRecord("Highscore", score)
	end
end

local function victory(onVictory)
	missionWon = true
	local e = 0
	if extraTime then
		e = extraTime
	end
	local totalTime = TurnTime + e * totalEnemies
	local completeTime = (totalTime - finishTime) / 1000
	ShowMission(missionName, loc("Challenge completed!"), loc("Congratulations!") .. "|" .. string.format(loc("Completion time: %.2fs"), completeTime), 0, 0)
	PlaySound(sndHomerun)
	-- Protect player hog
	if hhs[0] and GetHealth(hhs[0]) then
		SetEffect(hhs[0], heInvulnerable, 1)
		SetEffect(hhs[0], heResurrectable, 1)
	end
	SendStat(siGameResult, loc("Challenge completed!"))
	local hogScore = getKillScore()
	local timeScore = div(finishTime * timeBonus, totalTime)
	local score = hogScore + timeScore
	SendStat(siCustomAchievement, killStr(hogsKilled, totalEnemies, hogScore))
	SendStat(siCustomAchievement, string.format(loc("You have completed this challenge in %.2f s (+%d points)."), completeTime, timeScore))
	SendStat(siPointType, "!POINTS")
	SendStat(siPlayerKills, tostring(score), playerTeamName)
	SetTeamLabel(playerTeamName, tostring(score))
	SetTurnTimeLeft(MAX_TURN_TIME)

	if missionType == 1 then
		-- Update highscore
		updateChallengeRecord("Highscore", score)
	end
	if onVictory then
		onVictory()
	end
end

local function knockTaunt()
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

local function declareEnemyKilled(gear, onVictory)
	if deadHogs[gear] or playerFail then
		return
	end
	deadHogs[gear] = true
	hogsKilled = hogsKilled + 1

	-- Award extra time, if available
	if extraTime and extraTime ~= 0 then
		SetTurnTimeLeft(TurnTimeLeft + extraTime)
		AddCaption(string.format(loc("+%d seconds!"), div(extraTime, 1000)), 0xFFFFFFFF, capgrpMessage2)
	end

	SetTeamLabel(playerTeamName, tostring(getKillScore()))

	if hogsKilled == totalEnemies - 1 then
		if playValkyries then
			PlayMusicSound(sndRideOfTheValkyries)
			valkyriesTimer = valkyriesDuration
		end
	elseif hogsKilled == totalEnemies then
		finishTime = TurnTimeLeft
		victory(onVictory)
	end
end

--[[
RopeKnocking function!

This creates a rope-knocking challenge.
The player spawns with one hog and a rope and must kill all other hogs
by rope-knocking before the time runs out.
The player wins points for each kill and gets a time bonus for killing
all enemies.

params is a table with all the required parameters.
Fields of the params table:

	MANDATORY:
	- map: Map name
	- theme: Theme name
	- turnTime: Turn time
	- playerTeam: Player team info:
		{
			x, y: Start position
			faceLeft: If true, hog faces left
		}
	- enemyTeams: Table of enemy team tables. each enemy team table has this format:
		{
			name: Team name
			flag: Flag
			hogs: Hogs table:
			{
				x, y: Position
				faceLeft: If true, hog faces left
				hat: Hat name
				name: Hog name
			}
		}

	OPTIONAL:
	- missionName: Mission name
	- missionType:
		0: None/other: No special handling
		1: Challenge: Will save mission variables at end (default)
	- killBonus: Score for killing all hogs (one hog scores ca. (killBonus/<number of enemies)) (default: 6000)
	- timeBonus: Maximum theoretically possible time bonus (default: 6000)
	- gameFlags: List of game flags, if you want to set your own
	- extraTime: Extra time awarded for each kill, in milliseconds (default: 0)
	- valkyries: If true, play "Ride of the Valkyries" at final enemy (default: false)
	- onGameInit: Custom onGameInit callback
	- onGameStart: Custom onGameStart callback
	- onVictory: Function that is called when the mission is won.

	Hint: Use onGameInit and onGameStart to place custom gears and girders
	Hint: Use onVictory to save campaign variables if using this in a campaign

]]
function RopeKnocking(params)
	if params.missionName then
		missionName = params.missionName
	end
	if params.extraTime then
		extraTime = params.extraTime
	end
	if params.valkyries then
		playValkyries = params.valkyries
	end
	if params.missionType then
		missionType = params.missionType
	end
	if params.killBonus then
		killBonus = params.killBonus
	end
	if params.timeBonus then
		timeBonus = params.timeBonus
	end

	_G.onGameInit = function()

		if params.gameFlags then
			for g=1, #params.gameFlags do
				EnableGameFlags(params.gameFlags[g])
			end
		end

		EnableGameFlags(gfBorder, gfSolidLand)

		TurnTime = params.turnTime
		Delay = 500
		Map = params.map
		Theme = params.theme

		-- Disable Sudden Death
		WaterRise = 0
		HealthDecrease = 0

		CaseFreq = 0
		MinesNum = 0
		Explosives = 0

		-- Player team
		playerTeamName = AddMissionTeam(-1)
		hhs[0] = AddMissionHog(1)
		SetGearPosition(hhs[0], params.playerTeam.x, params.playerTeam.y)
		if params.playerTeam.faceLeft == true then
			HogTurnLeft(hhs[0], true)
		end

		-- Enemy teams
		for t=1, #params.enemyTeams do
			local team = params.enemyTeams[t]
			params.enemyTeams[t].name = AddTeam(team.name, -2, "Simple", "Tank", "Default_qau", team.flag)
			for h=1, #team.hogs do
				local hogData = team.hogs[h]
				local name = hogData.name
				local hat = hogData.hat
				if not hat then
					hat = "NoHat"
				end
				local hog = AddHog(name, 0, 1, hat)
				SetGearPosition(hog, hogData.x, hogData.y)
				if hogData.faceLeft == true then
					HogTurnLeft(hog, true)
				end
				table.insert(hhs, hog)

				totalEnemies = totalEnemies + 1
			end
		end

		if params.onGameInit then
			params.onGameInit()
		end
	end

	_G.onGameStart = function()
		SendHealthStatsOff()

		local timeTxt = ""
		local displayTime = 4000
		if extraTime and extraTime ~= 0 then
			timeTxt = string.format(loc("For each kill you win %d seconds."), div(extraTime, 1000))
			displayTime = 5000
		end
		local recordInfo = getReadableChallengeRecord("Highscore")
		if recordInfo == nil then
			recordInfo = ""
		else
			recordInfo = "|" .. recordInfo
		end
		ShowMission(
			missionName,
			loc("Challenge"),
			loc("Use the rope to knock your enemies to their doom.") .. "|" ..
			loc("Finish this challenge as fast as possible to earn bonus points.") .. "|" ..
			timeTxt .. recordInfo, -amRope, displayTime)

		SetTeamLabel(playerTeamName, "0")

		if params.onGameStart then
			params.onGameStart()
		end
	end

	_G.onGameTick = function()

		if (TurnTimeLeft == 1) and (missionWon == nil) then
			PlaySound(sndBoring, CurrentHedgehog)
			gameOver()
		end

		if missionWon ~= nil then

			endTimer = endTimer - 1
			if endTimer == 1 then
				if not endGameCalled then
					EndGame()
					endGameCalled = true
				end
			end

			if not missionEndHandled then
				if missionWon == true then
					AddCaption(loc("Victory!"), 0xFFFFFFFF, capgrpGameState)
					if missionType == 1 then
						SaveMissionVar("Won", "true")
					end
				else
					AddCaption(loc("Challenge over!"), 0xFFFFFFFF, capgrpGameState)
				end
				missionEndHandled = true
			end

		end

	end

	_G.onGameTick20 = function()
		if (valkyriesTimer > 0) then
			valkyriesTimer = valkyriesTimer - 20
			if valkyriesTimer <= 0 then
				StopMusicSound(sndRideOfTheValkyries)
			end
		end
		local drown = (hhs[0]) and (band(GetState(hhs[0]), gstDrowning) ~= 0)
		if drown and missionWon == nil then
			-- Player hog drowns
			playerFail = true
			return
		end
		for i=1, totalEnemies do
			local hog = hhs[i]
			drown = (hog) and (not deadHogs[hog]) and (band(GetState(hhs[i]), gstDrowning) ~= 0)
			if drown then
				declareEnemyKilled(hog, params.onVictory)
			end
		end

		if ropeGear and not missionWon and band(GetState(ropeGear), gstCollision) ~= 0 then
			-- Hide mission on first rope attach
			HideMission()
		end
	end

	_G.onGearDamage = function(gear, damage)

		if gear == hhs[0] then
			-- Player hog hurts itself
			playerFail = true
			StopMusicSound(sndRideOfTheValkyries)
			valkyriesTimer = -1
			protectEnemies()
		end

		if gear ~= hhs[0] and GetGearType(gear) == gtHedgehog and not deadHogs[gear] and missionWon == nil and playerFail == false then
			-- Enemy hog took damage
			AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
			DeleteGear(gear)
			PlaySound(sndExplosion)
			AddCaption(string.format(knockTaunt(), GetHogName(gear)), 0xFFFFFFFF, capgrpMessage)

			declareEnemyKilled(gear, params.onVictory)
		end

	end

	_G.onGearAdd = function(gear)
		if GetGearType(gear) == gtRope then
			ropeGear = gear
		end
	end

	_G.onGearDelete = function(gear)

		if (gear == hhs[0]) and (missionWon == nil) then
			playerFail = true
			gameOver()
		end

		if GetGearType(gear) == gtHedgehog and gear ~= hhs[0] and not deadHogs[gear] then
			declareEnemyKilled(gear, params.onVictory)
		end

		if GetGearType(gear) == gtRope then
			ropeGear = nil
		end

	end

	if params.onAmmoStoreInit then
		_G.onAmmoStoreInit = params.onAmmoStoreInit
	else
		_G.onAmmoStoreInit = function()
			SetAmmo(amRope, 9, 0, 0, 0)
		end

		_G.onNewTurn = function()
			SetWeapon(amRope)
		end
	end

end

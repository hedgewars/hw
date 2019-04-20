
HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

--[[
Space Invasion

=== DOCUMENTATION ===

== SCRIPT CONFIGURATION ==
You can configure this script a little bit, you only have to edit the game scheme.
The script makes heavy use of the script parameters, but you can also use some,
but not all, of the other settings in a game scheme.

You CAN use the following options:
- disable girders (highly recommended!)
- disable land objects
- random order
- solid land
- low gravity (makes this game much easier, but this script is probably not optimized for it yet)
- bottom border
- fort mode (just changes the landscape)
- teams start at opposite parts of land
- wind affects almost everything

Those options are also possible, but have no real gameplay effect:
- disable wind
- tag team
- king mode (here it only changes hats, so this is just for fun)
- vampiric (has no real gameplay effect; just for the grapical effect)
- full border (it’s techincally possible, but the script is currently not very well optimized for this mode)

You CANNOT use any other of the on/off options in the game scheme. Those settings are simply discarded by the script.

You also can change the following settings in the game scheme:
- time per round (very important)
- script parameters, see below

The other settings are technically possible, but their effect is limited:
- damage percentage
- mines/air mines (they don’t harm the active hedgehog, however)
- number of barrels

All other variables are discarded, the script forces its own settings.
There will be never Sudden Death, any crate drops, any mines and any
barrels.


== SCRIPT PARAMETERS ==
This script can be configured mostly with the script parameters.
The script parameters are specified in a key=value format each,
and each pair is delimeted by a comma.
All values must be integer of 0 or higher. All values are optional
and have a default if unspecified

List of parameters:
- rounds: Number of rounds (default: 3)
- shield: Amount of shield you start with (default: 30)
- barrels: Amount of ammo (barrels) you start with (default: 5)
- pings: How many time you can use the radar per round (default: 2)
- barrelbonus: How many barrels you get for collecting/destroning a green invader (default: 3)
- shieldbonus: How much shield you get for collecting/destroying a purple invader (default: 30)
- timebonus: How many seconds you get for killing a drone (red) (default: 4)
- forcetheme: If set to false, the game will use your chosen theme instead of forcing EarthRise
-             Please note that the game may not be able to be played in some themes if the sky
               color is very bright (i.e. Bath)

Example input for the field “Script parameters”:

rounds=5
>>> 5 rounds, everything else is default

forcetheme=false
>>> Makes the game use whatever thme

shield=0, barrels=3, pings=0
>>> no shield, no radar pings and only 3 barrels (could be some hard mode)

(empty string)
>>> Use defaults for everything

]]

--------------------------
-- TODO list: notes for later
--------------------------
-- imitate winning animation at end instead of just ending the game

-- add support for other world edges (they are currently disabled)

-- if more weapons are added, replace primshotsfired all over the place

-- look for derp and let invaders shoot again

-- more weapons? flamer/machineballgun,
-- some kind of bomb that just drops straight down
-- "fire and forget" missile
-- shockwave

-- some kind of ability-meter that lets you do something awesome when you are
-- doing really well in a given round.
-- probably new kind of shield that pops any invaders who come near

-- new invader: golden snitch, doesn't show up on your radar

-- maybe replace (48/100*SI.vCircRadius[i])/2 with something better

-------------------
-- CAPTION TYPES --
-------------------
--[[
The captions have been carefully assigned to avoid overlapping.

capgrpMessage: Basic bonuses for a simple action, rounds complete
capgrpMessage2: Extended bonus, awarded for repeating a basic bonus
capgrpVolume: X-Hit Combo
capgrpGameState: End of turn information, kamikaze achievements
capgrpAmmoinfo: Ammo type at start of turn; Multi-shot, Shield Miser
capgrpAmmostate: Remaining ammo, depleted ammo; Accuracy Bonus, Sniper, They Call Me Bullseye, Point Blank Combo
]]

------- CODE FOLLOWS -------

----------------------------------
-- so I herd u liek wariables
----------------------------------

-- The table that holds the Space Invasion variables
local SI = {}

SI.fMod = 1000000 -- use this for dev and .16+ games

-- Tag IDs
SI.TAG_TIME = 0
SI.TAG_BARRELS = 1
SI.TAG_SHIELD = 2
SI.TAG_ROUND_SCORE = 4

-- some console stuff
SI.shellID = 0
SI.explosivesID = 0

-- gaudyRacer
SI.boosterOn = false
SI.preciseOn = false
SI.roundLimit = 3		-- can be overridden by script parameter "rounds"
SI.roundNumber = 0
SI.lastRound = -1
SI.gameOver = false
SI.gameBegun = false

-- for script parameters
-- NOTE: If you change this, also change the default “Space Invasion” game scheme
SI.startBarrels = 5		-- "barrels"
SI.startShield = 30		-- "shield"
SI.startRadShots = 2		-- "pings"
SI.shieldBonus = 30		-- "shieldbonus"
SI.barrelBonus = 3		-- "barrelbonus"
SI.timeBonus = 4		-- "timebonus"
SI.forceTheme = true		-- "forcetheme"

--------------------------
-- hog and team tracking variales
--------------------------

SI.numhhs = 0
SI.hhs = {}

SI.teamNameArr = {}
SI.teamNameArrReverse = {}
SI.teamClan = {}
SI.teamSize = {}
SI.teamIndex = {}

SI.teamScore = {}
SI.teamCircsKilled = {}
SI.teamSurfer = {}

-- stats variables
SI.roundKills = 0
SI.roundScore = 0
SI.RK = 0
SI.GK = 0
SI.BK = 0
SI.OK = 0
SI.SK = 0
SI.shieldMiser = true
SI.fierceComp = false
SI.chainCounter = 0
SI.chainLength = 0
SI.shotsFired = 0
SI.shotsHit = 0
SI.sniperHits = 0
SI.pointBlankHits = 0

---------------------
-- awards (for stats section, just for fun)
---------------------
-- global awards
SI.awardTotalKills=0	-- overall killed invaders (min. 30)

-- hog awards
SI.awardRoundScore = nil	-- hog with most score in 1 round (min. 50)
SI.awardRoundKills = nil	-- most kills in 1 round (min. 5)
SI.awardAccuracy = nil	-- awarded to hog who didn’t miss once in his round, with most kills (min. 5)
SI.awardCombo = nil	-- hog with longest combo (min. 5)



-- Taunt trackers
SI.tauntTimer = -1
SI.tauntGear = nil
SI.tauntSound = nil
SI.tauntClanShots = 0 -- hogs of same clans shot in this turn

---------------------
-- tumbler goods
---------------------

SI.moveTimer = 0
SI.leftOn = false
SI.rightOn = false
SI.upOn = false
SI.downOn = false

----------------
-- TUMBLER
SI.wep = {}
SI.wepAmmo = {}
SI.wepIndex = 0
SI.wepCount = 0
----------------



SI.primShotsMax = 5
SI.primShotsLeft = 0

SI.TimeLeftCounter = 0
SI.TimeLeft = 0
SI.stopMovement = false
SI.tumbleStarted = false

SI.beam = false
SI.pShield = nil
SI.shieldHealth = 0

SI.timer100 = 0

SI.vTag = {}

-----------------------------------------------
-- CIRCLY GOODIES
-----------------------------------------------

SI.circlesAreGo = false
SI.playerIsFine = true
SI.targetHit = false

SI.fadeAlpha = 0 -- used to fade the circles out gracefully when player dies
SI.pTimer = 0 -- tracking projectiles following player

SI.circAdjustTimer = 0		-- handle adjustment of circs direction
SI.m2Count = 0		-- handle speed of circs

SI.vCirc = {}
SI.vCCount = 0

SI.rCirc = {}
SI.rCircX = {}
SI.rCircY = {}
SI.rAlpha = 255
SI.rPingTimer = 0
SI.radShotsLeft = 0

SI.vCircActive = {}
SI.vCircHealth = {}
SI.vType = {}
SI.vCounter = {}		-- how often this circ gets to "fire" etc
SI.vCounterLim = {} -- when SI.vCounter == SI.vCounterLim circle performs its special
SI.vCircScore = {} -- how many points killing this invader gives

SI.vCircRadMax = {}
SI.vCircRadMin = {}
SI.vCircRadDir = {}
SI.vCircRadCounter = {}

SI.vCircDX = {}
SI.vCircDY = {}

SI.vCircX = {}
SI.vCircY = {}
SI.vCircMinA = {}
SI.vCircMaxA = {}
SI.vCircType = {}
SI.vCircPulse = {}
SI.vCircFuckAll = {}
SI.vCircRadius = {}
SI.vCircWidth = {}
SI.vCircCol = {}

-- Colors
-- Invaders
SI.colorDrone = 0xFF0000FF
SI.colorBoss = 0x0050FFFF
SI.colorBossParticle = SI.colorBoss
SI.colorAmmo = 0x00FF00FF
SI.colorShield = 0xA800FFFF
SI.colorShieldParticle = SI.colorShield
SI.colorDisabled = 0xFFFFFFFF -- disabled invader at end of turn

-- Other SI.colors
SI.colorMsgDepleted = 0xFF0000FF
SI.colorMsgBonus = 0xFFBA00FF
SI.colorTimer = 0xFFEE00FF
SI.colorScore = 0xFFFFFFFF

-------------------------------------------
-- some lazy copypasta/modified methods
-------------------------------------------



function HideTag(i)

	SetVisualGearValues(SI.vTag[i],0,0,0,0,0,1,0, 0, 240000, 0xFFFFFF00)

end

function DrawTag(i)

	local zoomL = 1.3
	local xOffset, yOffset, tValue, tCol

	if i == SI.TAG_TIME then
		if INTERFACE == "touch" then
			xOffset = 60
			yOffset = ScreenHeight - 35
		else
			xOffset = 40
			yOffset = 40
		end
		tCol = SI.colorTimer
		tValue = SI.TimeLeft
	elseif i == SI.TAG_BARRELS then
		zoomL = 1.1
		if INTERFACE == "touch" then
			xOffset = 126
			yOffset = ScreenHeight - 37
		else
			xOffset = 40
			yOffset = 70
		end
		tCol = SI.colorAmmo
		tValue = SI.wepAmmo[SI.wepIndex]
	elseif i == SI.TAG_SHIELD then
		zoomL = 1.1
		if INTERFACE == "touch" then
			xOffset = 126 + 35
			yOffset = ScreenHeight - 37
		else
			xOffset = 40 + 35
			yOffset = 70
		end
		tCol = SI.colorShield
		tValue = SI.shieldHealth - 80
	elseif i == SI.TAG_ROUND_SCORE then
		zoomL = 1.1
		if INTERFACE == "touch" then
			xOffset = 126 + 70
			yOffset = ScreenHeight - 37
		else
			xOffset = 40
			yOffset = 100
		end
		tCol = SI.colorScore
		tValue = SI.roundScore
	end

	DeleteVisualGear(SI.vTag[i])
	SI.vTag[i] = AddVisualGear(0, 0, vgtHealthTag, 0, false)
	SetVisualGearValues	(
				SI.vTag[i], 		--id
				-(div(ScreenWidth, 2)) + xOffset,	--xoffset
				ScreenHeight - yOffset, --yoffset
				0, 			--dx
				0, 			--dy
				zoomL, 			--zoom
				1, 			--~= 0 means align to screen
				nil, 			--frameticks
				tValue, 		--value
				240000, 		--timer
				tCol			--color
				)

end

function RebuildTeamInfo()

	-- make a list of individual team names
	for i = 0, (TeamsCount-1) do
		SI.teamSize[i] = 0
		SI.teamIndex[i] = 0
		SI.teamScore[i] = 0
		SI.teamCircsKilled[i] = 0
		SI.teamSurfer[i] = false
	end

	for i=0, TeamsCount-1 do

		local name = GetTeamName(i)
		SI.teamNameArr[i] = name
		SI.teamNameArrReverse[name] = i

	end

	-- find out how many hogs per team, and the index of the first hog in SI.hhs
	for i = 0, (TeamsCount-1) do

		for z = 0, (SI.numhhs-1) do
			if GetHogTeamName(SI.hhs[z]) == SI.teamNameArr[i] then
				SI.teamClan[i] = GetHogClan(SI.hhs[z])
				if SI.teamSize[i] == 0 then
					SI.teamIndex[i] = z -- should give starting index
				end
				SI.teamSize[i] = SI.teamSize[i] + 1
				--add a pointer so this hog appears at i in SI.hhs
			end
		end

	end

	for i=0, TeamsCount-1 do
		SetTeamLabel(SI.teamNameArr[i], SI.teamScore[i])
	end

end

-- control
function AwardPoints(p)
	SI.roundScore = SI.roundScore + p
	DrawTag(SI.TAG_ROUND_SCORE)

	for i = 0,(TeamsCount-1) do
		if SI.teamClan[i] == GetHogClan(CurrentHedgehog) then
			SI.teamScore[i] = SI.teamScore[i] + p
			SetTeamLabel(SI.teamNameArr[i], SI.teamScore[i])
		end
	end

end

function AwardKills(t)

	SI.roundKills = SI.roundKills + 1

	for i = 0,(TeamsCount-1) do
		if SI.teamClan[i] == GetHogClan(CurrentHedgehog) then
			SI.teamCircsKilled[i] = SI.teamCircsKilled[i] + 1
			SI.awardTotalKills = SI.awardTotalKills + 1

		end
	end

end

-----------------

function UpdateSimpleAward(oldAward, value, threshold)
	local awarded = false
	local newAward
	if oldAward == nil then
		if threshold == nil then
			awarded = true
		elseif value > threshold then
			awarded = true
		end
	elseif value > oldAward.value then
		if threshold == nil then
			awarded = true
		elseif value > threshold then
			awarded = true
		end
	end
	if awarded then
		newAward = {
			hogName = GetHogName(CurrentHedgehog),
			teamName = GetHogTeamName(CurrentHedgehog),
			value = value
		}
	else
		newAward = oldAward
	end
	return newAward
end

-- Update scoreboard and check victory state.
-- Returns 2 bools:
-- 1: true if game over
-- 2: true if game's not over but we're playing now in tie-breaking phase

function CommentOnScore()
	local teamStats = {}
	for i = 0,(TeamsCount-1) do
		table.insert(teamStats, {score = SI.teamScore[i], kills = SI.teamCircsKilled[i], name = SI.teamNameArr[i]})
	end

	local scorecomp = function (v1, v2)
		if v1.score > v2.score then
			return true
		else
			return false
		end
	end
	table.sort(teamStats, scorecomp)
	local teamComment = {}
	for i = TeamsCount,1,-1 do
		local comment
		if teamStats[i].name ~= " " then
			local comment = teamStats[i].name .. " |" ..
			string.format(loc("Score: %d"), teamStats[i].score) .. "|" ..
			string.format(loc("Kills: %d"), teamStats[i].kills)
			if i < TeamsCount then
				comment = comment .. "| |"
			end
			table.insert(teamComment, comment)

			SendStat(siClanHealth, tostring(teamStats[i].score), teamStats[i].name)
		else
			comment = "|"
		end
		table.insert(teamComment, comment)
	end

	local roundLimitHit = SI.roundNumber >= SI.roundLimit
	local tie = teamStats[1].score == teamStats[2].score
	local lGameOver = roundLimitHit and (not tie)

	local entireC = ""

	for i = TeamsCount,1,-1 do
		entireC = entireC .. teamComment[i]
	end

	local statusText, scoreText
	-- Game is over
	if lGameOver then
		statusText = loc("Game over!")
		scoreText = loc("Final team scores:")
	-- Round is over and game is not yet complete
	elseif not roundLimitHit then
		AddCaption(string.format(loc("Rounds complete: %d/%d"), SI.roundNumber, SI.roundLimit), capcolDefault, capgrpMessage)
		return lGameOver, false
	-- Teams are tied for the lead at the end
	elseif roundLimitHit and tie then
		local tieBreakingRound = SI.roundNumber - SI.roundLimit + 1
		local msg
		if tieBreakingRound == 1 then
			msg = loc("Teams are tied! Continue playing rounds until we have a winner!")
		else
			msg = string.format(loc("Tie-breaking round %d"), tieBreakingRound)
		end
		AddCaption(msg, capcolDefault, capgrpMessage)
		return lGameOver, true
	end

	local displayTime
	if lGameOver then
		displayTime = 20000
	else
		displayTime = 1
	end
	ShowMission(	loc("Space Invasion"),
			statusText,
			string.format(loc("Rounds complete: %d/%d"), SI.roundNumber, SI.roundLimit) .. "| " .. "|" ..
			scoreText .. " |" ..entireC, 4, displayTime)

	if lGameOver then
		local winnerTeam = teamStats[1].name
		for i = 0, (SI.numhhs-1) do
			if GetHogTeamName(SI.hhs[i]) == winnerTeam then
				SetState(SI.hhs[i], bor(GetState(SI.hhs[i]), gstWinner))
			end
		end
		AddCaption(string.format(loc("%s wins!"), winnerTeam), capcolDefault, capgrpGameState)
		SendStat(siGameResult, string.format(loc("%s wins!"), winnerTeam))

		for i = 1, TeamsCount do
			SendStat(siPointType, "!POINTS")
			SendStat(siPlayerKills, tostring(teamStats[i].score), teamStats[i].name)
		end

		local killscomp = function (v1, v2)
			if v1.kills > v2.kills then
				return true
			else
				return false
			end
		end


--[[ Award some awards (just for fun, its for the stats screen only
and has no effect on the score or game outcome. ]]
		local awardsGiven = 0

		if SI.roundNumber == SI.roundLimit + 1 then
			SendStat(siCustomAchievement,
			loc("The teams were tied, so an additional round has been played to determine the winner."))
			awardsGiven = awardsGiven + 1
		elseif SI.roundNumber > SI.roundLimit then
			SendStat(siCustomAchievement,
			string.format(loc("The teams were tied, so %d additional rounds have been played to determine the winner."),
			SI.roundNumber - SI.roundLimit))
			awardsGiven = awardsGiven + 1
		end
		if SI.awardTotalKills >= 30 then
			awardsGiven = awardsGiven + 1
			SendStat(siCustomAchievement,
				string.format(loc("%d invaders have been destroyed in this game."), SI.awardTotalKills))
		end

		table.sort(teamStats, killscomp)
		local bestKills = teamStats[1].kills
		if bestKills > 10 then
			awardsGiven = awardsGiven + 1
			local text
			if bestKills >= 50 then
				text = loc("BOOM! BOOM! BOOM! %s are the masters of destruction with %d destroyed invaders.")
			elseif bestKills >= 25 then
				text = loc("BOOM! %s really didn't like the invaders, so they decided to destroy as much as %d of them.")
			else
				text = loc("Boom! %s has destroyed %d invaders.")
			end
			SendStat(siCustomAchievement,
			string.format(text,
	                teamStats[1].name, teamStats[1].kills))
		end

		if SI.awardRoundKills ~= nil then
			awardsGiven = awardsGiven + 1
			local text
			if SI.awardRoundKills.value >= 33 then
				text = loc("%s (%s) has been invited to join the Planetary Association of the Hedgehogs, it destroyed a staggering %d invaders in just one round!")
			elseif SI.awardRoundKills.value >= 22 then
				if SI.awardRoundKills.hogName == "Rambo" then
					text = loc("The hardships of the war turned %s (%s) into a killing machine: %d invaders destroyed in one round!")
				else
					text = loc("%s (%s) is Rambo in a hedgehog costume! He destroyed %d invaders in one round.")
				end
			elseif SI.awardRoundKills.value >= 11 then
				text = loc("%s (%s) is addicted to killing: %d invaders destroyed in one round.")
			else
				text = loc("%s (%s) destroyed %d invaders in one round.")
			end
			SendStat(siCustomAchievement,
			string.format(text,
			SI.awardRoundKills.hogName, SI.awardRoundKills.teamName, SI.awardRoundKills.value))
		end
		if SI.awardRoundScore ~= nil then
			awardsGiven = awardsGiven + 1
			local text
			if SI.awardRoundScore.value >= 300 then
				text = loc("%s (%s) was undoubtedly the very best professional tumbler in this game: %d points in one round!")
			elseif SI.awardRoundScore.value >= 250 then
				text = loc("%s (%s) struck like a meteor: %d points in only one round!")
			elseif SI.awardRoundScore.value >= 200 then
				text = loc("%s (%s) is good at this: %d points in only one round!")
			elseif SI.awardRoundScore.value >= 150 then
				text = loc("%s (%s) tumbles like no other: %d points in one round.")
			elseif SI.awardRoundScore.value >= 100 then
				text = loc("%s (%s) is a tumbleweed: %d points in one round.")
			else
				text = loc("%s (%s) was the best baby tumbler: %d points in one round.")
			end
			SendStat(siCustomAchievement,
			string.format(text,
			SI.awardRoundScore.hogName, SI.awardRoundScore.teamName, SI.awardRoundScore.value))
		end
		if SI.awardAccuracy ~= nil then
			awardsGiven = awardsGiven + 1
			local text
			if SI.awardAccuracy.value >= 20 then
				text = loc("The Society of Perfectionists greets %s (%s): No misses and %d hits in its best round.")
			elseif SI.awardAccuracy.value >= 10 then
				text = loc("%s (%s) is a hardened hunter: No misses and %d hits in its best round!")
			else
				text = loc("%s (%s) shot %d invaders and never missed in the best round!")
			end
			SendStat(siCustomAchievement,
			string.format(text,
			SI.awardAccuracy.hogName, SI.awardAccuracy.teamName, SI.awardAccuracy.value))
		end
		if SI.awardCombo ~= nil then
			awardsGiven = awardsGiven + 1
			local text
			if SI.awardCombo.value >= 11 then
				text = loc("%s (%s) was lightning-fast! Longest combo of %d, absolutely insane!")
			elseif SI.awardCombo.value >= 8 then
				text = loc("%s (%s) gave short shrift to the invaders: Longest combo of %d!")
			else
				text = loc("%s (%s) was on fire: Longest combo of %d.")
			end
			SendStat(siCustomAchievement,
			string.format(text,
			SI.awardCombo.hogName, SI.awardCombo.teamName, SI.awardCombo.value))
		end
		if awardsGiven == 0 then
			local text
			local r = math.random(1,4)
			if r == 1 then text = loc("This game wasn’t really exciting.")
			elseif r == 2 then text = loc("Did I miss something?")
			elseif r == 3 then text = loc("Nothing of interest has happened.")
			elseif r == 4 then text = loc("There are no snarky comments this time.")
			end

			SendStat(siCustomAchievement, text)
		end
	end

	return lGameOver, false
end

function onNewRound()
	SI.lastRound = TotalRounds
	SI.roundNumber = SI.roundNumber + 1

	local lGameOver, lTied = CommentOnScore()
	local bestScore = 0
	local bestClan = -1

	-- Game has been determined to be over, so end it
	if lGameOver then

		-- Get winning score
		for i = 0, (TeamsCount-1) do
			if SI.teamScore[i] > bestScore then
				bestScore = SI.teamScore[i]
				bestClan = SI.teamClan[i]
			end
		end

		-- Kill off all the losers
		for i = 0, (SI.numhhs-1) do
			if GetHogClan(SI.hhs[i]) ~= bestClan then
				SetEffect(SI.hhs[i], heResurrectable, 0)
				SetHealth(SI.hhs[i],0)
				-- hilarious loser face
				SetState(SI.hhs[i], bor(GetState(SI.hhs[i]), gstLoser))
			end
		end

		-- Game over
		SI.gameOver = true
		EndTurn(true)
		SI.TimeLeft = 0
		SendStat(siGraphTitle, loc("Score graph"))

	-- Round limit passed and teams are tied!
	elseif lTied then
		-- Enter (or continue) tie-breaking phase...

		-- Rules in case of a tie:
		-- 1) All teams that are not tied for the lead are killed (they can't play anymore, but they will keep their score and be ranked normally)
		-- 2) Another round is played with the remaining teams
		-- 3) After this round, scores are checked again to determine a winner. If there's a tie again, this procedure is repeated

		-- Get leading teams
		for i = 0, (TeamsCount-1) do
			if SI.teamScore[i] > bestScore then
				bestScore = SI.teamScore[i]
			end
		end

		local tiedForTheLead = {}
		for i = 0, (TeamsCount-1) do
			if SI.teamScore[i] == bestScore then
				tiedForTheLead[i] = true
			end
		end

		local wasCurrent = false
		-- Kill teams not in the top
		for i = 0, (SI.numhhs-1) do
			local hog = SI.hhs[i]
			if GetHealth(hog) then -- check if hog is still alive
				local team = SI.teamNameArrReverse[GetHogTeamName(hog)]
				if team and tiedForTheLead[team] ~= true then
					-- hilarious loser face
					SetState(hog, bor(GetState(hog), gstLoser))
					-- die!
					SetEffect(hog, heResurrectable, 0)
					SetHealth(hog, 0)
					-- Note the death might not trigger immediately since we
					-- zero the health at the beginning of a turn rather than
					-- the end of one.
					-- It's just a minor visual thing, not a big deal.
					if hog == CurrentHedgehog then
						wasCurrent = true
					end
				end
			end
		end

		-- if current hedgehog was among the loser, end the turn
		if wasCurrent then
			EndTurn(true)
		end

		-- From that point on, the game just continues normally ...
	end
end

-- gaudy racer
function CheckForNewRound()

	if TotalRounds > 0 and TotalRounds > SI.lastRound then
		onNewRound()
	end

end


----------------------------------------
-- some tumbler/space invaders methods
----------------------------------------

function isATrackedGear(gear)
	if 	(GetGearType(gear) == gtExplosives) or
		(GetGearType(gear) == gtShell) or
		(GetGearType(gear) == gtFlame) or
		(GetGearType(gear) == gtBall)
	then
		return(true)
	else
		return(false)
	end
end

function setNewGearValues(gear)

	local lfs
	if GetGearType(gear) == gtShell then
		lfs = 50	-- roughly 5 seconds
		SI.shellID = SI.shellID + 1
		setGearValue(gear,"ID",SI.shellID)
	elseif GetGearType(gear) == gtBall then
		lfs = 5 --70	-- 7s
	elseif GetGearType(gear) == gtExplosives then
		lfs = 15	-- 1.5s
		SI.explosivesID = SI.explosivesID + 1
		setGearValue(gear,"ID",SI.explosivesID)
		setGearValue(gear,"XP", GetX(gear))
		setGearValue(gear,"YP", GetY(gear))
	elseif GetGearType(gear) == gtFlame then
		lfs = 5	-- 0.5s
	else
		lfs = 100
	end

	setGearValue(gear,"lifespan",lfs)

end

function HandleLifeSpan(gear)

	decreaseGearValue(gear,"lifespan")

	if getGearValue(gear,"lifespan") == 0 then

		if GetGearType(gear) == gtShell then
			AddVisualGear(GetX(gear), GetY(gear), vgtExplosion, 0, false)
		elseif GetGearType(gear) == gtExplosives then
			AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
			PlaySound(sndExplosion)
		elseif GetGearType(gear) == gtFlame then
			AddVisualGear(GetX(gear), GetY(gear), vgtSmoke, 0, false)
		end

		DeleteGear(gear)

	end

end

-- this prevents ugly barrel clipping sounds when a barrel flies off map limits
function DeleteFarFlungBarrel(gear)

	if GetGearType(gear) == gtExplosives then
		if 	(GetX(gear) < -1900) or
			(GetX(gear) > 6200) or
			(GetY(gear) < -3400)
		then
			AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
			DeleteGear(gear)
		end

	end

end

-----------------------
--EVENT HANDLERS
-- action keys
-----------------------

function ChangeWeapon()

	SI.wepIndex = SI.wepIndex + 1
	if SI.wepIndex == SI.wepCount then
		SI.wepIndex = 0
	end
	AddCaption(SI.wep[SI.wepIndex], GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmoinfo)
end

-- derp tumbler
function onPrecise()

	if (CurrentHedgehog ~= nil) and (SI.stopMovement == false) and (SI.tumbleStarted == true) and (SI.wepAmmo[SI.wepIndex] > 0) then

		SI.wepAmmo[SI.wepIndex] = SI.wepAmmo[SI.wepIndex] - 1

		if SI.wep[SI.wepIndex] == loc("Barrel Launcher") then
			SI.shotsFired = SI.shotsFired +1

			local morte = AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtExplosives, 0, 0, 0, 1)
			CopyPV(CurrentHedgehog, morte)
			local x,y = GetGearVelocity(morte)
			x = x*2
			y = y*2
			SetGearVelocity(morte, x, y)

			if SI.wepAmmo[SI.wepIndex] == 0 then
				PlaySound(sndSuddenDeath)
				AddCaption(loc("Ammo depleted!"),SI.colorMsgDepleted,capgrpAmmostate)
			else
				PlaySound(sndThrowRelease)
			end
			DrawTag(SI.TAG_BARRELS)

		elseif SI.wep[SI.wepIndex] == loc("Mine Deployer") then
			local morte = AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtAirBomb, 0, 0, 0, 0)
			SetTimer(morte, 1000)
			DrawTag(SI.TAG_BARRELS)
		end

	elseif (SI.wepAmmo[SI.wepIndex] == 0) and (CurrentHedgehog ~= nil) and (SI.stopMovement == false) and (SI.tumbleStarted == true) then
		PlaySound(sndDenied)
		AddCaption(loc("Ammo depleted!"),SI.colorMsgDepleted,capgrpAmmostate)
	end

	SI.preciseOn = true

end

function onPreciseUp()
	SI.preciseOn = false
end

function onLJump()

	if (CurrentHedgehog ~= nil) and (SI.stopMovement == false) and (SI.tumbleStarted == true) then
		SI.shieldMiser = false
		if SI.shieldHealth == 80 then
			AddCaption(loc("Shield depleted"),SI.colorMsgDepleted,capgrpAmmostate)
			PlaySound(sndDenied)
		elseif (SI.beam == false) and (SI.shieldHealth > 80) then
			SI.beam = true
			SetVisualGearValues(SI.pShield, GetX(CurrentHedgehog), GetY(CurrentHedgehog), 40, 255, 1, 10, 0, nil, 1, SI.colorShield-0x000000FF - -math.min(SI.shieldHealth))
			AddCaption( string.format(loc("Shield ON: %d power remaining"), SI.shieldHealth - 80), SI.colorShield, capgrpAmmostate)
			PlaySound(sndInvulnerable)
		else
			SI.beam = false
			SetVisualGearValues(SI.pShield, GetX(CurrentHedgehog), GetY(CurrentHedgehog), nil, nil, nil, nil, nil, nil, nil, 0x0)
			AddCaption( string.format(loc("Shield OFF: %d power remaining"), SI.shieldHealth - 80), SI.colorShield, capgrpAmmostate)
		end
	end
end

function onHJump()

	if (CurrentHedgehog ~= nil) and (SI.stopMovement == false) and (SI.tumbleStarted == true) and
	(SI.rAlpha == 255) then
		if SI.radShotsLeft > 0 then
			SI.rPingTimer = 0
			SI.rAlpha = 0
			SI.radShotsLeft = SI.radShotsLeft -1
			AddCaption(string.format(loc("Pings left: %d"), SI.radShotsLeft),GetClanColor(GetHogClan(CurrentHedgehog)),capgrpAmmostate)
			-- Play sonar sound
			PlaySound(sndJetpackLaunch)

		else
			AddCaption(loc("No radar pings left!"),SI.colorMsgDepleted,capgrpAmmostate)
			PlaySound(sndDenied)
		end
	end

end

-----------------
-- movement keys
-----------------

function onLeft()
	SI.leftOn = true
end

function onRight()
	SI.rightOn = true
end

function onUp()
	SI.upOn = true
end

function onDown()
	SI.downOn = true
end

function onDownUp()
	SI.downOn = false
end

function onUpUp()
	SI.upOn = false
end

function onLeftUp()
	SI.leftOn = false
end

function onRightUp()
	SI.rightOn = false
end

--------------------------
-- other event handlers
--------------------------

function onParameters()
	parseParams()
	if params["rounds"] ~= nil then
		SI.roundLimit = math.floor(tonumber(params["rounds"]))
	end
	if params["barrels"] ~= nil then
		SI.startBarrels = math.floor(tonumber(params["barrels"]))
	end
	if params["pings"] ~= nil then
		SI.startRadShots = math.floor(tonumber(params["pings"]))
	end
	if params["shield"] ~= nil then
		SI.startShield = math.min(250-80, math.floor(tonumber(params["shield"])))
	end

	if params["barrelbonus"] ~= nil then
		SI.barrelBonus = math.floor(tonumber(params["barrelbonus"]))
	end
	if params["shieldbonus"] ~= nil then
		SI.shieldBonus = math.floor(tonumber(params["shieldbonus"]))
	end
	if params["timebonus"] ~= nil then
		SI.timeBonus = math.floor(tonumber(params["timebonus"]))
	end
	if params["forcetheme"] == "false" then
		SI.forceTheme = false
	else
		SI.forceTheme = true
	end
end

function onGameInit()
	--[[ Only GameFlags which are listed here are allowed. All other game flags will be discarded.
	Nonetheless this allows for some configuration in the game scheme ]]
	local allowedFlags = 
		-- those flags are probably the most realistic one to use
		gfDisableGirders + gfRandomOrder +	-- highly recommended!
		gfDisableLandObjects + gfSolidLand + gfLowGravity +
		-- a bit unusual but may still be useful
		gfBottomBorder + gfDivideTeams +
		gfDisableWind + gfMoreWind + gfTagTeam +
		-- very unusual flags, they don’t affect gameplay really, they are mostly for funny graphical effects
		gfKing + 	-- King Mode doesn’t work like expected, since hedgehogs never really die here in this mode
		gfVampiric +	-- just for the grapical effects
		gfBorder 	-- technically possible, but not very fun to play
		-- any other flag is FORBIDDEN and will be disabled when it is on anyways!

	GameFlags = band(GameFlags, allowedFlags)

	if SI.forceTheme then
		Theme = "EarthRise"
	end
	CaseFreq = 0
	HealthCaseProb = 0
	SuddenDeathTurns = 50
	WaterRise = 0
	HealthDecrease = 0
	WorldEdge = weNone

	local tags = { SI.TAG_TIME, SI.TAG_BARRELS, SI.TAG_SHIELD, SI.TAG_ROUND_SCORE }
	for t=1, #tags do
		SI.vTag[tags[t]] = AddVisualGear(0, 0, vgtHealthTag, 0, false)
		HideTag(tags[t])
	end

	SI.wep[0] = loc("Barrel Launcher")
	SI.wep[1] = loc("Mine Deployer")
	SI.wep[2] = loc("Flamer")

	SI.wepCount = 3

end

function onGameStart()
	if ClansCount >= 2 then
		SendGameResultOff()
		SendRankingStatsOff()
		SendAchievementsStatsOff()
		SendHealthStatsOff()
	end

	ShowMission	(
				loc("SPACE INVASION"),
				loc("A Hedgewars mini-game"),

				loc("Fly into space to fight off the invaders with barrels!") .."|"..
				loc("Destroy invaders and collect bonuses to score points.") .. "|" ..
				loc("Get the highest score to win.") .. "|" ..
				" " .. "|" ..
				loc("Avoid bazookas, red and blue invaders.") .. "|" ..
				loc("Collect the green and purple invaders.") .. "|" ..
				loc("Use the shield to protect yourself from bazookas.") .. "|" ..
				" " .. "|" ..

				string.format(loc("Round Limit: %d"), SI.roundLimit) .. "|" ..
				" " .. "|" ..

				loc("Movement: [Up], [Down], [Left], [Right]") .. "|" ..
				loc("Fire: [Precise]") .. "|" ..
				loc("Toggle Shield: [Long jump]") .. "|" ..
				loc("Radar Ping: [High jump]") .. "|" ..

				"", 4, 5000
				)

	CreateMeSomeCircles()
	RebuildTeamInfo() -- control

end

function onScreenResize()

	-- redraw Tags so that their screen locations are updated
	if (SI.gameBegun == true) then
		DrawTag(SI.TAG_ROUND_SCORE)
		if (SI.stopMovement == false) then
			DrawTag(SI.TAG_BARRELS)
			DrawTag(SI.TAG_SHIELD)
			if (SI.tumbleStarted == true) then
				DrawTag(SI.TAG_TIME)
			end
		end
	end

end

function onNewTurn()

	SI.radShotsLeft = SI.startRadShots
	SI.stopMovement = false
	SI.tumbleStarted = false
	SI.boosterOn = false
	SI.beam = false
	SI.shieldHealth = SI.startShield + 80 -- 50 = 5 secs, roughly

	SI.RK = 0
	SI.GK = 0
	SI.BK = 0
	SI.OK = 0
	SI.SK = 0
	SI.roundKills = 0
	SI.roundScore = 0
	SI.shieldMiser = true
	SI.fierceComp = false
	SI.shotsFired = 0
	SI.shotsHit = 0
	SI.sniperHits = 0
	SI.pointBlankHits = 0
	SI.chainLength = 0
	SI.chainCounter = 0

	SI.tauntClanShots = 0
	SI.tauntTimer = -1

	-------------------------
	-- gaudy racer
	-------------------------
	CheckForNewRound()

	-- Handle Starting Stage of Game
	if (SI.gameOver == false) and (SI.gameBegun == false) then
		SI.gameBegun = true
		SI.roundNumber = 0 -- 0
	end

	if SI.gameOver == true then
		SI.stopMovement = true
		SI.tumbleStarted = false
		SetMyCircles(false)
	end


	-------
	-- tumbler
	----

	SI.wepAmmo[0] = SI.startBarrels
	SI.wepAmmo[1] = SI.startRadShots
	SI.wepAmmo[2] = 5000
	SI.wepIndex = 2
	ChangeWeapon()


	HideTag(SI.TAG_TIME)
	if not SI.gameOver then
		DrawTag(SI.TAG_BARRELS)
		DrawTag(SI.TAG_SHIELD)
		DrawTag(SI.TAG_ROUND_SCORE)
	else
		HideTag(SI.TAG_BARRELS)
		HideTag(SI.TAG_SHIELD)
		HideTag(SI.TAG_ROUND_SCORE)
	end

end

function ThingsToBeRunOnGears(gear)

	HandleLifeSpan(gear)
	DeleteFarFlungBarrel(gear)

	if SI.circlesAreGo == true then
		CheckVarious(gear)
		ProjectileTrack(gear)
	end

end

function onGearWaterSkip(gear)
	if gear == CurrentHedgehog then

		for i = 0,(TeamsCount-1) do
			if SI.teamClan[i] == GetHogClan(CurrentHedgehog) and (SI.teamSurfer[i] == false) then
				SI.teamSurfer[i] = true
				AddCaption(loc("Surfer! +15 points!"),SI.colorMsgBonus,capgrpMessage)
				AwardPoints(15)
			end
		end

	end
end

function onGameTick()

	HandleCircles()

	SI.timer100 = SI.timer100 + 1
	if SI.timer100 >= 100 then
		SI.timer100 = 0

		if SI.beam == true then
			SI.shieldHealth = SI.shieldHealth - 1
			if SI.shieldHealth < 80 then
				SI.shieldHealth = 80
				SI.beam = false
				AddCaption(loc("Shield depleted"),SI.colorMsgDepleted,capgrpAmmostate)
				PlaySound(sndMineTick)
				PlaySound(sndSwitchHog)
			end
		end

		if SI.tauntTimer > 0 then
			SI.tauntTimer = SI.tauntTimer - 100
			if SI.tauntTimer <= 0 and SI.tumbleStarted and not SI.stopMovement then
				PlaySound(SI.tauntSound, SI.tauntGear)
			end
		end

		runOnGears(ThingsToBeRunOnGears)

		if SI.circlesAreGo == true then
			CheckDistances()
		end

		-- white smoke trail as player falls from the sky
		if (SI.TimeLeft <= 0) and (SI.stopMovement == true) and (CurrentHedgehog ~= nil) then
			local j,k = GetGearVelocity(CurrentHedgehog)
			if (j ~= 0) and (k ~= 0) then
				AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmoke, 0, false)
			end
		end

	end


	-- start the player tumbling with a boom once their turn has actually begun
	if (SI.tumbleStarted == false) and (SI.gameOver == false) then
		if (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) then
			SI.tumbleStarted = true
			SI.TimeLeft = (TurnTime/1000)
			SI.fadeAlpha = 0
			SI.rAlpha = 255
			AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtGrenade, 0, 0, 0, 1)
			DrawTag(SI.TAG_TIME)
			DrawTag(SI.TAG_BARRELS)
			DrawTag(SI.TAG_SHIELD)
			DrawTag(SI.TAG_ROUND_SCORE)
			SetMyCircles(true)
		end
	end

	if (CurrentHedgehog ~= nil) and (SI.tumbleStarted == true) then

		-- Calculate and display turn time
		SI.TimeLeftCounter = SI.TimeLeftCounter + 1
		if SI.TimeLeftCounter == 1000 then
			SI.TimeLeftCounter = 0
			SI.TimeLeft = SI.TimeLeft - 1

			if SI.TimeLeft >= 0 then
				DrawTag(SI.TAG_TIME)
			end

		end

		if (SI.TimeLeftCounter % 1000) == 0 then
			if SI.TimeLeft == 5 then
				PlaySound(sndHurry, CurrentHedgehog)
			elseif SI.TimeLeft <= 4 and SI.TimeLeft >= 1 then
				PlaySound(_G["sndCountdown"..SI.TimeLeft])
			end
		end

		-------------------------------
		-- Player has run out of luck (out of time or hit by gtShell)
		-------------------------------
		-- checks in FloatyThings
		if PlayerIsFine() == false then
			SI.TimeLeft = 0
		end

		if (SI.TimeLeft == 0) then
			if PlayerIsFine() then
				AddCaption(loc("Time's up!"), capcolDefault, capgrpGameState)
			end
			if (SI.stopMovement == false) then	--time to stop the player
				SI.stopMovement = true
				SI.boosterOn = false
				SI.beam = false
				SI.upOn = false
				SI.downOn = false
				SI.leftOn = false
				SI.rightOn = false
				SetMyCircles(false)
				SI.rAlpha = 255
				FailGraphics()

				if SI.shieldMiser == true then

					local p = (SI.roundKills*3.5) - ((SI.roundKills*3.5)%1) + 2

					AddCaption(string.format(loc("Shield Miser! +%d points!"), p), SI.colorMsgBonus, capgrpAmmoinfo)
					AwardPoints(p)
				end

				local accuracy = (SI.shotsHit / SI.shotsFired) * 100
				if (accuracy >= 80) and (SI.shotsFired > 4) then
					AddCaption(loc("Accuracy Bonus! +15 points"),SI.colorMsgBonus,capgrpAmmostate)
					AwardPoints(15)


					-- special award for no misses
					local award = false
					if SI.awardAccuracy == nil then
						if (SI.shotsHit >= SI.shotsFired) then
							award = true
						end
					elseif (SI.shotsHit == SI.shotsFired) and SI.shotsHit > SI.awardAccuracy.value then
						award = true
					end
					if award then
						SI.awardAccuracy = {
							hogName = GetHogName(CurrentHedgehog),
							teamName = GetHogTeamName(CurrentHedgehog),
							value = SI.shotsHit, 
						}
					end

				end

				-- other awards
				SI.awardRoundScore = UpdateSimpleAward(SI.awardRoundScore, SI.roundScore, 50)
				SI.awardRoundKills = UpdateSimpleAward(SI.awardRoundKills, SI.roundKills, 5)

				HideTag(SI.TAG_TIME)
				HideTag(SI.TAG_BARRELS)
				HideTag(SI.TAG_SHIELD)

			end
		else -- remove this if you want tumbler to fall slowly on death
		-------------------------------
		-- Player is still in luck
		-------------------------------

			if SI.chainCounter > 0 then
				SI.chainCounter = SI.chainCounter -1
				if SI.chainCounter == 0 then
					SI.chainLength = 0
				end
			end

			-- handle movement based on IO
			SI.moveTimer = SI.moveTimer + 1
			if SI.moveTimer == 100 then -- 100
				SI.moveTimer = 0

				---------------
				-- new trail code
				---------------
				-- the trail lets you know you have 5s left to pilot, akin to birdy feathers
				if (SI.TimeLeft <= 5) and (SI.TimeLeft > 0) then							--vgtSmoke
					local tempE = AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmoke, 0, false)
					SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, nil, GetClanColor(GetHogClan(CurrentHedgehog)) )
				end
				--------------
				--------------

				local dx, dy = GetGearVelocity(CurrentHedgehog)

				local dxlimit, dylimit
				if SI.boosterOn == true then
					local tempE = AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtDust, 0, false)
					SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, 1, nil, GetClanColor(GetHogClan(CurrentHedgehog)) )
					dxlimit = 0.8*SI.fMod
					dylimit = 0.8*SI.fMod
				else
					dxlimit = 0.4*SI.fMod
					dylimit = 0.4*SI.fMod
				end

				if dx > dxlimit then
					dx = dxlimit
				end
				if dy > dylimit then
					dy = dylimit
				end
				if dx < -dxlimit then
					dx = -dxlimit
				end
				if dy < -dylimit then
					dy = -dylimit
				end


				if SI.leftOn == true then
					dx = dx - 0.1*SI.fMod
				end
				if SI.rightOn == true then
					dx = dx + 0.1*SI.fMod
				end

				if SI.upOn == true then
					dy = dy - 0.1*SI.fMod
				end
				if SI.downOn == true then
					dy = dy + 0.1*SI.fMod
				end

				SetGearVelocity(CurrentHedgehog, dx, dy)

			end


		end -- new end I put here to check if he's still alive or not

	end

end

function onGearDamage(gear, damage)
	if GetGearType(gear) == gtHedgehog and damage >= 60 then
		if GetHogClan(gear) ~= GetHogClan(CurrentHedgehog) then
			if (SI.fierceComp == false) then
				SI.fierceComp = true
				AddCaption(loc("Fierce Competition! +8 points!"),SI.colorMsgBonus,capgrpMessage)
				AwardPoints(8)
			end

			SI.tauntTimer = 500
			SI.tauntGear = gear
			local r = math.random(1, 2)
			if r == 1 then
				SI.tauntSound = sndIllGetYou
			else
				SI.tauntSound = sndJustYouWait
			end
		elseif gear ~= CurrentHedgehog then
			SI.tauntTimer = 500
			SI.tauntGear = gear
			if SI.tauntClanShots == 0 then
				SI.tauntSound = sndSameTeam
			else
				SI.tauntSound = sndTraitor
			end
			SI.tauntClanShots = SI.tauntClanShots + 1
		end
	end
end

function onGearResurrect(gear)

	-- did I fall into the water? well, that was a stupid thing to do
	if gear == CurrentHedgehog then
		SI.TimeLeft = 0
		SI.playerIsFine = false
	end

end

function onGearAdd(gear)

	if isATrackedGear(gear) then
		trackGear(gear)
		setNewGearValues(gear)
	end

	if GetGearType(gear) == gtHedgehog then
		SetEffect(gear, heResurrectable, 1)

		-----------
		-- control
		SI.hhs[SI.numhhs] = gear
		SI.numhhs = SI.numhhs + 1
		-----------
	end

end

function onGearDelete(gear)

	if isATrackedGear(gear) then
		trackDeletion(gear)
	end

	if CurrentHedgehog ~= nil then
		FollowGear(CurrentHedgehog)
	end

end



------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------
-- FLOATY THINGS
-- "I'll make this into a generic library and code properly
-- when I have more time and feel less lazy"
------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------
------------------------------------------------------------

function HandleRadarBlip(cUID)

	-- work out the distance to the target
	local g1X, g1Y = GetGearPosition(CurrentHedgehog)
	local g2X, g2Y = SI.vCircX[cUID], SI.vCircY[cUID]
	local q = g1X - g2X
	local w = g1Y - g2Y
	-- Floating point operations are safe, it's only for visuals
	local r = math.sqrt( (q*q) + (w*w) )	--alternate

	local opp = w
	if opp < 0 then
		opp = opp*-1
	end

	-- work out the angle (theta) to the target
	local t = math.deg ( math.asin(opp / r) )

	-- based on the radius of the radar, calculate what x/y displacement should be
	local NR = 150 -- radius at which to draw circs
	local NX = math.cos( math.rad(t) ) * NR
	local NY = math.sin( math.rad(t) ) * NR

	-- displace xy based on where this thing actually is

	if r < NR then
		SI.rCircX[cUID] = g2X
	elseif q > 0 then
		SI.rCircX[cUID] = g1X - NX
	else
		SI.rCircX[cUID] = g1X + NX
	end

	if r < NR then
		SI.rCircY[cUID] = g2Y
	elseif w > 0 then
		SI.rCircY[cUID] = g1Y - NY
	else
		SI.rCircY[cUID] = g1Y + NY
	end

end

function PlayerIsFine()
	return (SI.playerIsFine)
end

function GetDistFromXYtoXY(a, b, c, d)
	local q = a - c
	local w = b - d
	return ( (q*q) + (w*w) )
end

function GetDistFromGearToGear(gear, gear2)

	local g1X, g1Y = GetGearPosition(gear)
	local g2X, g2Y = GetGearPosition(gear2)
	local q = g1X - g2X
	local w = g1Y - g2Y

	return ( (q*q) + (w*w) )

end

function GetDistFromGearToXY(gear, g2X, g2Y)

	local g1X, g1Y = GetGearPosition(gear)
	local q = g1X - g2X
	local w = g1Y - g2Y

	return ( (q*q) + (w*w) )

end

function CreateMeSomeCircles()

	for i = 0, 7 do
		SI.vCCount = SI.vCCount +1
		SI.vCirc[i] = AddVisualGear(0,0,vgtCircle,0,true)

		SI.rCirc[i] = AddVisualGear(0,0,vgtCircle,0,true)
		SI.rCircX[i] = 0
		SI.rCircY[i] = 0

		SI.vCircDX[i] = 0
		SI.vCircDY[i] = 0

		SI.vType[i] = "generic"
		SI.vCounter[i] = 0
		SI.vCounterLim[i] = 3000
		SI.vCircScore[i] = 0
		SI.vCircHealth[i] = 1

		SI.vCircMinA[i] = 80
		SI.vCircMaxA[i] = 255
		SI.vCircType[i] = 1
		SI.vCircPulse[i] = 10
		SI.vCircFuckAll[i] = 0
		SI.vCircRadius[i] = 0
		SI.vCircWidth[i] = 3

		SI.vCircRadMax[i] = 0
		SI.vCircRadMin[i] = 0
		SI.vCircRadDir[i] = -1
		SI.vCircRadCounter[i] = 0

		SI.vCircX[i], SI.vCircY[i] = 0,0

		SI.vCircCol[i] = 0xFF00FFFF

		SetVisualGearValues(SI.vCirc[i], SI.vCircX[i], SI.vCircY[i], SI.vCircMinA[i], SI.vCircMaxA[i], SI.vCircType[i], SI.vCircPulse[i], SI.vCircFuckAll[i], SI.vCircRadius[i], SI.vCircWidth[i], SI.vCircCol[i])

		SetVisualGearValues(SI.rCirc[i], 0, 0, 100, 255, 1, 10, 0, 40, 3, SI.vCircCol[i])

	end

	SI.pShield = AddVisualGear(0,0,vgtCircle,200,true)

end

function IGotMeASafeXYValue(i)

	local acceptibleDistance = 800

	SI.vCircX[i] = GetRandom(5000)
	SI.vCircY[i] = GetRandom(2000)
	local dist = GetDistFromGearToXY(CurrentHedgehog, SI.vCircX[i], SI.vCircY[i])
	if dist > acceptibleDistance*acceptibleDistance then
		return(true)
	else
		return(false)
	end

end

function CircleDamaged(i)

	local res = ""
	SI.vCircHealth[i] = SI.vCircHealth[i] -1

	if SI.vCircHealth[i] <= 0 then
	-- circle is dead, do death effects/consequences

		SI.vCircActive[i] = false

		if (SI.vType[i] == "drone") then
			PlaySound(sndHellishImpact4)
			SI.TimeLeft = SI.TimeLeft + SI.timeBonus
			AddCaption(string.format(loc("Time extended! +%dsec"), SI.timeBonus), SI.colorDrone, capgrpMessage )
			DrawTag(SI.TAG_TIME)

			local morte = AddGear(SI.vCircX[i], SI.vCircY[i], gtExplosives, 0, 0, 0, 1)
			SetHealth(morte, 0)

			SI.RK = SI.RK + 1
			if SI.RK == 5 then
				SI.RK = 0
				AddCaption(loc("Drone Hunter! +10 points!"),SI.colorMsgBonus,capgrpMessage2)
				AwardPoints(10)
			end

		elseif (SI.vType[i] == "ammo") then
			AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtExplosion, 0, false)
			PlaySound(sndExplosion)
			PlaySound(sndShotgunReload)
			SI.wepAmmo[0] = SI.wepAmmo[0] + SI.barrelBonus
			AddCaption(string.format(loc("+%d Ammo"), SI.barrelBonus), SI.colorAmmo,capgrpMessage)
			DrawTag(SI.TAG_BARRELS)

			SI.GK = SI.GK + 1
			if SI.GK == 3 then
				SI.GK = 0
				AddCaption(loc("Ammo Maniac! +5 points!"),SI.colorMsgBonus,capgrpMessage2)
				AwardPoints(5)
			end

		elseif (SI.vType[i] == "bonus") then

			AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtExplosion, 0, false)
			PlaySound(sndExplosion)

			AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtFire, 0, false)
			AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtFire, 0, false)
			AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtFire, 0, false)
			AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtFire, 0, false)
			AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtFire, 0, false)
			AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtSmoke, 0, false)

			PlaySound(sndVaporize)

			SI.shieldHealth = SI.shieldHealth + SI.shieldBonus
			if SI.shieldHealth >= 250 then
				SI.shieldHealth = 250
				AddCaption(loc("Shield is fully recharged!"),SI.colorShield,capgrpMessage)
			else
				AddCaption(string.format(loc("Shield boosted! +%d power"),SI.shieldBonus), SI.colorShield,capgrpMessage)
			end
			DrawTag(SI.TAG_SHIELD)

			SI.OK = SI.OK + 1
			if SI.OK == 3 then
				SI.OK = 0
				AddCaption(loc("Shield Seeker! +10 points!"),SI.colorShield,capgrpMessage2)
				AwardPoints(10)
			end

		elseif (SI.vType[i] == "blueboss") then
			PlaySound(sndHellishImpact3)
			SI.tauntTimer = 300
			SI.tauntSound = sndEnemyDown
			SI.tauntGear = CurrentHedgehog
			AddCaption(loc("Boss defeated! +30 points!"), SI.colorBoss,capgrpMessage)

			local morte = AddGear(SI.vCircX[i], SI.vCircY[i], gtExplosives, 0, 0, 0, 1)
			SetHealth(morte, 0)

			SI.BK = SI.BK + 1
			if SI.BK == 2 then
				SI.BK = 0
				AddCaption(loc("Boss Slayer! +25 points!"),SI.colorMsgBonus,capgrpMessage2)
				AwardPoints(25)
			end

		end

		AwardPoints(SI.vCircScore[i])
		AwardKills()
		SetUpCircle(i)
		res = "fatal"

		SI.chainCounter = 3000
		SI.chainLength = SI.chainLength + 1
		if SI.chainLength > 1 then
			AddCaption( string.format(loc("%d-Hit Combo! +%d points!"), SI.chainLength, SI.chainLength*2),SI.colorMsgBonus,capgrpVolume)
			AwardPoints(SI.chainLength*2)
		end

		SI.awardCombo = UpdateSimpleAward(SI.awardCombo, SI.chainLength, 5)

	else
	-- circle is merely damaged
	-- do damage effects/sounds
		AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtSteam, 0, false)
		local r = math.random(1,4)
		PlaySound(_G["sndHellishImpact" .. tostring(r)])
		res = "non-fatal"

	end

	return(res)

end

function SetUpCircle(i)


	local r = GetRandom(10)
	-- 80% of spawning either drone/ammo
	if r <= 7 then

		r = GetRandom(2)
		if r == 0 then
			SI.vCircCol[i] = SI.colorDrone
			SI.vType[i] = "drone"
			SI.vCircRadMin[i] = 50	*5
			SI.vCircRadMax[i] = 90	*5
			SI.vCounterLim[i] = 3000
			SI.vCircScore[i] = 10
			SI.vCircHealth[i] = 1
		elseif r == 1 then
			SI.vCircCol[i] = SI.colorAmmo
			SI.vType[i] = "ammo"
			SI.vCircRadMin[i] = 25	*7
			SI.vCircRadMax[i] = 30	*7
			SI.vCircScore[i] = 3
			SI.vCircHealth[i] = 1
		end

	-- 20% chance of spawning boss or bonus
	else
		r = GetRandom(5)
		if r <= 1 then
			SI.vCircCol[i] = SI.colorBoss
			SI.vType[i] = "blueboss"
			SI.vCircRadMin[i] = 100*5
			SI.vCircRadMax[i] = 180*5
			SI.vCircWidth[i] = 1
			SI.vCounterLim[i] = 2000
			SI.vCircScore[i] = 30
			SI.vCircHealth[i] = 3
		else
			SI.vCircCol[i] = SI.colorShield
			SI.vType[i] = "bonus"
			SI.vCircRadMin[i] = 20 *7
			SI.vCircRadMax[i] = 40 *7
			SI.vCircScore[i] = 5
			SI.vCircHealth[i] = 1
		end

	end

	-- regenerate circle xy if too close to player or until sanity limit kicks in
	local reN = 0
	while (reN < 10) do
		if IGotMeASafeXYValue(i) == false then
			reN = reN + 1
		else
			reN = 15
		end
	end

	SI.vCircRadius[i] = SI.vCircRadMax[i] - GetRandom(SI.vCircRadMin[i])

	SetVisualGearValues(SI.vCirc[i], SI.vCircX[i], SI.vCircY[i], nil, nil, nil, nil, nil, SI.vCircRadius[i], SI.vCircWidth[i], SI.vCircCol[i]-0x000000FF)

	SetVisualGearValues(SI.rCirc[i], 0, 0, nil, nil, nil, nil, nil, nil, nil, SI.vCircCol[i]-0x000000FF)


	SI.vCircActive[i] = true

end

function SetMyCircles(s)

	SI.circlesAreGo = s
	SI.playerIsFine = s

	for i = 0,(SI.vCCount-1) do

		if s == false then
			SI.vCircActive[i] = false
		elseif s == true then
			SetUpCircle(i)
		end

	end

end

function WellHeAintGonnaJumpNoMore(x,y,explode,kamikaze)
	if explode==true then
		AddVisualGear(x, y, vgtBigExplosion, 0, false)
		PlaySound(sndExplosion)
		local r = math.random(1,3)
		PlaySound(_G["sndOoff"..r], CurrentHedgehog)
	end

	SI.playerIsFine = false
	FailGraphics()

	if not kamikaze then
		AddCaption(loc("GOTCHA!"), capcolDefault, capgrpGameState)
		PlaySound(sndHellish)
	end

	SI.targetHit = true

end

-- Turn all circles white to indicate they can't be hit anymore
function FailGraphics()
	for i = 0,(SI.vCCount-1) do
		SI.vCircCol[i] = SI.colorDisabled
	end
end

--- collision detection for weapons fire
function CheckVarious(gear)

	SI.targetHit = false

	-- if circle is hit by player fire
	if (GetGearType(gear) == gtExplosives) then
		local circsHit = 0

		for i = 0,(SI.vCCount-1) do

			local dist = GetDistFromGearToXY(gear, SI.vCircX[i], SI.vCircY[i])

			-- calculate my real radius if I am an aura
			local NR
			if SI.vCircType[i] == 0 then
				NR = SI.vCircRadius[i]
			else
				NR = (48/100*SI.vCircRadius[i])/2
			end

			if dist <= NR*NR then

				dist = (GetDistFromXYtoXY(SI.vCircX[i], SI.vCircY[i], getGearValue(gear,"XP"), getGearValue(gear,"YP")) - (NR*NR))
				if dist >= 1000000 then
					SI.sniperHits = SI.sniperHits +1
					AddCaption(loc("Sniper! +8 points!"),SI.colorMsgBonus,capgrpAmmostate)
					AwardPoints(8)
					if SI.sniperHits == 3 then
						SI.sniperHits = 0
						AddCaption(loc("They Call Me Bullseye! +16 points!"),SI.colorMsgBonus,capgrpAmmostate)
						AwardPoints(16)
					end
				elseif dist <= 6000 then
					SI.pointBlankHits = SI.pointBlankHits +1
					if SI.pointBlankHits == 3 then
						SI.pointBlankHits = 0
						AddCaption(loc("Point Blank Combo! +5 points!"),SI.colorMsgBonus,capgrpAmmostate)
						AwardPoints(5)
					end
				end

				AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)

				SI.targetHit = true
				CircleDamaged(i)

				circsHit = circsHit + 1
				if circsHit > 1 then
					AddCaption(loc("Multi-shot! +15 points!"),SI.colorMsgBonus,capgrpAmmoinfo)
					AwardPoints(15)
						circsHit = 0
				end

				SI.shotsHit = SI.shotsHit + 1

			end

		end

	-- if player is hit by circle bazooka
	elseif (GetGearType(gear) == gtShell) and (CurrentHedgehog ~= nil) then

		local dist = GetDistFromGearToGear(gear, CurrentHedgehog)

		if SI.beam == true then

			if dist < 3000 then
				local tempE = AddVisualGear(GetX(gear), GetY(gear), vgtSmoke, 0, false)
				SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0xFF00FFFF)
				PlaySound(sndVaporize)
				DeleteGear(gear)

				SI.SK = SI.SK + 1
				if SI.SK == 5 then
					SI.SK = 0
					AddCaption(loc("Shield Master! +10 points!"),SI.colorMsgBonus,capgrpMessage)
					AwardPoints(10)
				end
			end

		elseif dist < 1600 then
			WellHeAintGonnaJumpNoMore(GetX(gear), GetY(gear), true)
		end

	end

	if SI.targetHit == true then
		DeleteGear(gear)
	end

end

-- collision detection for player entering a circle
function CheckDistances()

	if not CurrentHedgehog then
		return
	end

	for i = 0,(SI.vCCount-1) do

		local g1X, g1Y = GetGearPosition(CurrentHedgehog)
		local g2X, g2Y = SI.vCircX[i], SI.vCircY[i]

		g1X = g1X - g2X
		g1Y = g1Y - g2Y
		local dist = (g1X*g1X) + (g1Y*g1Y)

		-- calculate my real radius if I am an aura
		local NR
		if SI.vCircType[i] == 0 then
			NR = SI.vCircRadius[i]
		else
			NR = (48/100*SI.vCircRadius[i])/2
		end

		if dist <= NR*NR then

			if 	(SI.vCircActive[i] == true) and
				((SI.vType[i] == "ammo") or (SI.vType[i] == "bonus") )
			then

				CircleDamaged(i)

			elseif (SI.vCircActive[i] == true) and
					( (SI.vType[i] == "drone") or (SI.vType[i] == "blueboss") )
			then

				local ss = CircleDamaged(i)
				local explosion
				if SI.vType[i] == "blueboss" then explosion = true else explosion = false end

				local kamikaze = false
				if ss == "fatal" then
					if (SI.wepAmmo[0] == 0) and (SI.TimeLeft <= 9) then
						AddCaption(loc("Kamikaze Expert! +15 points!"),SI.colorMsgBonus,capgrpGameState)
						AwardPoints(15)
						PlaySound(sndKamikaze, CurrentHedgehog)
						kamikaze = true
					elseif (SI.wepAmmo[0] == 0) then
						AddCaption(loc("Depleted Kamikaze! +5 points!"),SI.colorMsgBonus,capgrpGameState)
						AwardPoints(5)
						PlaySound(sndKamikaze, CurrentHedgehog)
						kamikaze = true
					elseif SI.TimeLeft <= 9 then
						AddCaption(loc("Timed Kamikaze! +10 points!"),SI.colorMsgBonus,capgrpGameState)
						AwardPoints(10)
						PlaySound(sndKamikaze, CurrentHedgehog)
						kamikaze = true
					end
				end
				WellHeAintGonnaJumpNoMore(GetX(CurrentHedgehog),GetY(CurrentHedgehog),explosion,kamikaze)

			end


		end

	end

end

function HandleCircles()

	if SI.rAlpha ~= 255 then

		SI.rPingTimer = SI.rPingTimer + 1
		if SI.rPingTimer == 100 then
			SI.rPingTimer = 0

			SI.rAlpha = SI.rAlpha + 5
			if SI.rAlpha >= 255 then
				SI.rAlpha = 255
			end
		end

	end

	for i = 0,(SI.vCCount-1) do

		SetVisualGearValues(SI.rCirc[i], SI.rCircX[i], SI.rCircY[i], 100, 255, 1, 10, 0, 40, 3, SI.vCircCol[i]-SI.rAlpha)

		SI.vCounter[i] = SI.vCounter[i] + 1
		if SI.vCounter[i] >= SI.vCounterLim[i] then

			SI.vCounter[i] = 0

			if 	((SI.vType[i] == "drone") or (SI.vType[i] == "blueboss") ) and
				(SI.vCircActive[i] == true) then
				AddGear(SI.vCircX[i], SI.vCircY[i], gtShell, 0, 0, 0, 1)

			end

		end

		if (SI.vCircActive[i] == true) then

			SI.vCircRadCounter[i] = SI.vCircRadCounter[i] + 1
			if SI.vCircRadCounter[i] == 100 then

				SI.vCircRadCounter[i] = 0

				-- make my radius increase/decrease faster if I am an aura
				local M
				if SI.vCircType[i] == 0 then
					M = 1
				else
					M = 10
				end

				SI.vCircRadius[i] = SI.vCircRadius[i] + SI.vCircRadDir[i]
				if SI.vCircRadius[i] > SI.vCircRadMax[i] then
					SI.vCircRadDir[i] = -M
				elseif SI.vCircRadius[i] < SI.vCircRadMin[i] then
					SI.vCircRadDir[i] = M
				end


				-- random effect test
				-- maybe use this to tell the difference between circs
				-- you can kill by shooting or not
				--vgtSmoke vgtSmokeWhite
				--vgtSteam -- nice long trail
				--vgtDust -- short trail on earthrise
				--vgtSmokeTrace
				if SI.vType[i] == "ammo" then

					local tempE = AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtSmoke, 0, false)
					SetVisualGearValues(tempE, SI.vCircX[i], SI.vCircY[i], nil, nil, nil, nil, nil, nil, nil, SI.vCircCol[i] )

				elseif SI.vType[i] == "bonus" then

					local tempE = AddVisualGear(SI.vCircX[i], SI.vCircY[i], vgtDust, 0, false)
					SetVisualGearValues(tempE, SI.vCircX[i], SI.vCircY[i], nil, nil, nil, nil, nil, 1, nil, SI.colorShieldParticle)


				elseif SI.vType[i] == "blueboss" then

					local k = 25
					local g = vgtSteam
					local trailColour = SI.colorBossParticle

					local tempE = AddVisualGear(SI.vCircX[i], SI.vCircY[i], g, 0, false)
					SetVisualGearValues(tempE, SI.vCircX[i], SI.vCircY[i]+k, nil, nil, nil, nil, nil, nil, nil, trailColour-75 )

					tempE = AddVisualGear(SI.vCircX[i], SI.vCircY[i], g, 0, false)
					SetVisualGearValues(tempE, SI.vCircX[i]+k, SI.vCircY[i]-k, nil, nil, nil, nil, nil, nil, nil, trailColour-75 )

					tempE = AddVisualGear(SI.vCircX[i], SI.vCircY[i], g, 0, false)
					SetVisualGearValues(tempE, SI.vCircX[i]-k, SI.vCircY[i]-k, nil, nil, nil, nil, nil, nil, nil, trailColour-75 )


				end


			end

		end


	end

	-- alter the circles velocities
	SI.circAdjustTimer = SI.circAdjustTimer + 1
	if SI.circAdjustTimer == 2000 then

		SI.circAdjustTimer = 0

		for i = 0,(SI.vCCount-1) do

			-- bounce the circles off the edges if they go too far
			-- or make them move in random directions

			if SI.vCircX[i] > 5500 then
				SI.vCircDX[i] = -5	--5 circmovchange
			elseif SI.vCircX[i] < -1500 then
				SI.vCircDX[i] = 5	--5 circmovchange
			else

				local z = GetRandom(2)
				if z == 1 then
					z = 1
				else
					z = -1
				end
				SI.vCircDX[i] = SI.vCircDX[i] + GetRandom(3)*z	--3 circmovchange
			end

			if SI.vCircY[i] > 1500 then
				SI.vCircDY[i] = -5	--5 circmovchange
			elseif SI.vCircY[i] < -2900 then
				SI.vCircDY[i] = 5	--5 circmovchange
			else
				local z = GetRandom(2)
				if z == 1 then
					z = 1
				else
					z = -1
				end
				SI.vCircDY[i] = SI.vCircDY[i] + GetRandom(3)*z	--3 circmovchange
			end

		end

	end

	-- move the circles according to their current velocities
	SI.m2Count = SI.m2Count + 1
	if SI.m2Count == 25 then	--25 circmovchange

		SI.m2Count = 0
		for i = 0,(SI.vCCount-1) do
			SI.vCircX[i] = SI.vCircX[i] + SI.vCircDX[i]
			SI.vCircY[i] = SI.vCircY[i] + SI.vCircDY[i]

			if (CurrentHedgehog ~= nil) and (SI.rAlpha ~= 255) then
				HandleRadarBlip(i)
			end

		end

		if (SI.TimeLeft == 0) and (SI.tumbleStarted == true) then

			SI.fadeAlpha = SI.fadeAlpha + 1
			if SI.fadeAlpha >= 255 then
				SI.fadeAlpha = 255
			end

		end

	end

	for i = 0,(SI.vCCount-1) do
		SetVisualGearValues(SI.vCirc[i], SI.vCircX[i], SI.vCircY[i], nil, nil, nil, nil, nil, SI.vCircRadius[i])
	end

	if 	(SI.TimeLeft == 0) or
		((SI.tumbleStarted == false)) then
		for i = 0,(SI.vCCount-1) do
			SetVisualGearValues(SI.vCirc[i], SI.vCircX[i], SI.vCircY[i], nil, nil, nil, nil, nil, SI.vCircRadius[i], nil, (SI.vCircCol[i]-SI.fadeAlpha))
		end
	end


	if (CurrentHedgehog ~= nil) then
		if SI.beam == true then
			SetVisualGearValues(SI.pShield, GetX(CurrentHedgehog), GetY(CurrentHedgehog), nil, nil, nil, nil, nil, nil, nil, SI.colorShield-0x000000FF - -math.min(SI.shieldHealth, 255))
			DrawTag(SI.TAG_SHIELD)
		else
			SetVisualGearValues(SI.pShield, GetX(CurrentHedgehog), GetY(CurrentHedgehog), nil, nil, nil, nil, nil, nil, nil, 0x0)
		end

	end


end

function ProjectileTrack(gear)

	if (GetGearType(gear) == gtShell) then

		local turningSpeed = 0.1*SI.fMod

		local dx, dy = GetGearVelocity(gear)

		if GetX(gear) > GetX(CurrentHedgehog) then
			dx = dx - turningSpeed
		else
			dx = dx + turningSpeed
		end

		if GetY(gear) > GetY(CurrentHedgehog) then
			dy = dy - turningSpeed
		else
			dy = dy + turningSpeed
		end


		local dxlimit = 0.4*SI.fMod
		local dylimit = 0.4*SI.fMod

		if dx > dxlimit then
			dx = dxlimit
		end
		if dy > dylimit then
			dy = dylimit
		end
		if dx < -dxlimit then
			dx = -dxlimit
		end
		if dy < -dylimit then
			dy = -dylimit
		end

		SetGearVelocity(gear, dx, dy)

	end

end


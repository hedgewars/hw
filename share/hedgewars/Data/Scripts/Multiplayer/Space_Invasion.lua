
HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

--[[
Space Invasion 1.2

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

You also can change the following settings in the game scheme
- time per round (very important)
- script parameters, see below
- terrain edge other than none (they kinda work, but they aren’t well supported by the script either)

The other settings are technically possible, but their effect is limited:
- damage percentage
- mines (they don’t harm the active hedgehog, however)
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


-- VERSION HISTORY
----------------
-- version 0.1
----------------
-- conversion of tumbler into space invasion
-- a million and one changes
-- bells and whistles

----------------
-- version 0.2
----------------
-- code slowly getting cleaner, it still looks like a spaghetti monster tho
-- lots of console tracking :/
-- all visual gears are now compulsary (will probably revert this)
-- implemented fMod to try combat desyncs and bring this in line with dev

----------------
-- version 0.3
----------------
-- values of scoring changed to 3:10, and now based on vCircScore
-- time gained from killing a red circ increased from 3 to 4
-- circles now spawn at a distance of at least 800 or until sanity limit
-- roundsLimit now based off MinesTime (kinda, its an experiment)

-----------------
--0.4
-----------------
-- commented out a lot of WriteLnToConsoles (dont need them at this point)
-- added some different WriteLnToConsoles
-- changed some of the collision detect for explosives in checkvarious()

-----------------
--0.5
-----------------
-- added implementation for a projectile shield
-- added a "bonus" orange invader that partially recharges player shield
-- added a tough "blueboss" blue invader
-- expanded user feedback
-- circles now have health and are capable of being merely "damaged"
-- redid a lot of the collision code and added CircleDamaged
-- added more sounds to events
-- added more visual gears

-----------------
--0.6
-----------------
-- removed a few WriteLns
-- added randomized grunts on circ damage
-- added (mostly) graceful fading out of circles :D:
-- changed odds for circles
-- changed user feedback
-- fixed the location of the explosion where player bashes into circ

-----------------
--0.7
-----------------
-- added PlaySound(sndSuddenDeath) when ammo gets depleted
-- added an extra "Ammo Depleted" note if user presses fire while empty
-- specified how much shield power is gained on shield powerup collection
-- changed odds for circles AGAIN, ammo is now sliiightly more common
-- switched most of the explosions/smoke effects back to non-critical vgears (with a few exceptions)
-- tumbletime is now based off turntime and is variable
-- delete explosives in DeleteFarFlungBarrel rather than explode them on map boundaries to save on performance
-- utilized the improved AddCaption to tint / prevent overrides
-- temporarily disabled bugged sort that displays teams according to their score
-- reluctantly changed the colour of the bonus circ to purple
-- standarized point notation
-- added some missing locs
-- commented out remaining WriteLnToConsoles for the meanwhile with the prefix "nw"

-- ACHIEIVEMENTS added
-- (during one turn) aka repeatable
-- Ammo Manic (Destroy 3 green circles for + 5 points)
-- Drone Hunter (Destroy 5 red circles for + 10 points)
-- Shield Seeker (Destroy 3 purple circles for +10 points)
-- Boss Slayer (Destroy 2 blue circles for +25 points)

-- Shield Master (disolve 5 shells for +10 points)
-- Shield Miser (don't use your shield at all (3.5*roundkills)+2 points)

-- Depleted Kamikaze! (kamikaze into a blue/red circ when you are out of ammo) 5pts
-- Timed Kamikaze! (kamikaze into a blue/red circ when you only have 5s left) 10pts
-- Kamikaze Expert (combination of the above two) 15pts

-- Multi-shot (destroy more than 1 invader with a single bullet) 15pts
-- X-Hit Combo (destroy another invader in less than 3 seconds) chainLength*2 points

-- Accuracy Bonus (80% accuracy at the end of your turn with more than 5 shots fired) 15pts

--(during the length of the game) aka non-repeatable
-- 10/25/50 kills (+25/+50/+100 points)

-----------------
--0.8
-----------------
-- added a HUD for turntimeleft, ammo, shield
-- shieldhealth hits 0 properly

------------------------
-- version 0.8.1
------------------------

-- stop hiding non-existant 4th Tag
-- redraw HUD on screen resolution change

------------------------
-- version 0.9
------------------------
-- time for more 'EXPERIMENTS' mwahahahahahaha D:
-- (hopefully) balanced Shield Miser
-- bosses are no longer a redunkulous 50 points, but toned down to 30
-- experimental radar (it's INTERACTIVE and math-heavy :D) (visual gears are safe... right? D:)
-- bugfix and balance for multishot

------------------------
-- version 1.0
------------------------
-- if only version numbers actually worked like this, wouldn't that be awful :D
-- added surfer achievement
-- increased value of shield miser by 1 point per kill (OP?)

------------------------
-- version 1.1
------------------------
-- fixed radar so that blips dont go past circs when you get very close
-- added a missing loc for shield depletion
-- increased delay to 1000 to try stop noobies missing their turn
-- added sniper achievement for hits from over a 1000000 away
-- added achievement for 3 "sniper" shots in a round
-- added achievement for 3 "point blank" shots in a round
-- added "fierce Competition" achievement for shooting an enemy hog (once per round)
-- some support for more weapons later

------------------------
-- version 1.2
------------------------
-- show actual scores in stats screen
-- show a couple of “awards” and more or less snarky comments in stats screen
--  for various accomplisments and events those are just for fun, they don’t
--  affect score or game outcome
-- use script parameters for configuration, see top of file for more information
-- stop overwriting game most scheme’s parameters
-- disable weapon scheme
-- play “denied” sound when trying to use empty radar, ammo or shield
-- play “Hurry!” taunt when 5 seconds are left
-- play throw sound when throwing a barrel
-- play sonar sound for using radar
-- play “Kamikaze!” taunt for receiving one of the kamikaze bonuses
-- show total team score in HUD (white number)
-- show message when trying to use empty radar
-- show message when time’s up
-- show message with round score at end of a round
-- disabled health graph, replaced with score per round
-- removed “selected weapon” message, we only have one weapon
-- removed unused bubbleSort function
-- play “Ooff” sound when hit by bazooka
-- fix explosion being drawn twice when colliding with circle
-- play explosion sound when barrel’s lifespan is over
]]

--------------------------
-- TODO list: notes for later
--------------------------
-- imitate winning animation at end instead of just ending the game

-- maybe add a check for a tie, IMPOSSIBRU THERE ARE NO TIES
-- more achievements?
-- more just-for-fun awards (for stats screen)

-- if more weps are added, replace primshotsfired all over the place

-- look for derp and let invaders shoot again

-- more weps? flamer/machineballgun,
-- some kind of bomb that just drops straight down
-- "fire and forget" missile
-- shockwave

-- some kind of ability-meter that lets you do something awesome when you are
-- doing really well in a given round.
-- probably new kind of shield that pops any invaders who come near

-- fix game never ending bug
-- fix radar
-- new invader: golden snitch, doesn't show up on your radar

-- maybe replace (48/100*vCircRadius[i])/2 with something better


------- CODE FOLLOWS -------


--[[CAPTION CATEGORIES
-----------------
capgrpGameState
-----------------
AddCaption(LOC_NOT("Sniper!") .. " +10 " .. LOC_NOT("points") .. "!",0xffba00ff,capgrpAmmostate)
--they call me bullsye
--point blank combo
--fierce Competition
-----------------
capgrpAmmostate
-----------------
AddCaption( chainLength .. LOC_NOT("-chain! +") .. chainLength*2 .. LOC_NOT(" points!"),0xffba00ff,capgrpAmmostate)
AddCaption(LOC_NOT("Multi-shot! +15 points!"),0xffba00ff,capgrpAmmostate)

-----------------
capgrpAmmoinfo
-----------------
AddCaption(LOC_NOT("Shield Miser! +20 points!"),0xffba00ff,capgrpAmmoinfo)
AddCaption(LOC_NOT("Shield Master! +10 points!"),0xffba00ff,capgrpAmmoinfo)

-----------------
capgrpVolume
-----------------
AddCaption(LOC_NOT("Boom! +25 points!"),0xffba00ff,capgrpVolume)
AddCaption(LOC_NOT("BOOM! +50 points!"),0xffba00ff,capgrpVolume)
AddCaption(LOC_NOT("BOOM! BOOM! BOOM! +100 points!"),0xffba00ff,capgrpVolume)
AddCaption(LOC_NOT("Accuracy Bonus! +15 points!"),0xffba00ff,capgrpVolume)
AddCaption(LOC_NOT("Surfer! +15 points!"),0xffba00ff,capgrpVolume)

-----------------
capgrpMessage
-----------------
AddCaption(LOC_NOT("Ammo Depleted!"),0xff0000ff,capgrpMessage)
AddCaption(LOC_NOT("Ammo: ") .. primShotsLeft)
AddCaption(LOC_NOT("Shield Depleted"),0xff0000ff,capgrpMessage)
AddCaption( LOC_NOT("Shield ON:") .. " " .. shieldHealth - 80 .. " " .. LOC_NOT("Power Remaining") )
AddCaption(LOC_NOT("Shield OFF:") .. " " .. shieldHealth - 80 .. " " .. LOC_NOT("Power Remaining") )

AddCaption(LOC_NOT("Time Extended!") .. "+" .. 4 .. LOC_NOT("s"), 0xff0000ff,capgrpMessage )
AddCaption("+" .. 3 .. " " .. LOC_NOT("Ammo"), 0x00ff00ff,capgrpMessage)
AddCaption(LOC_NOT("Shield boosted! +30 power"), 0xff00ffff,capgrpMessage)
AddCaption(LOC_NOT("Shield is fully recharged!"), 0xffae00ff,capgrpMessage)
AddCaption(LOC_NOT("Boss defeated! +50 points!"), 0x0050ffff,capgrpMessage)

AddCaption(LOC_NOT("GOTCHA!"))
AddCaption(LOC_NOT("Kamikaze Expert! +15 points!"),0xffba00ff,capgrpMessage)
AddCaption(LOC_NOT("Depleted Kamikaze! +5 points!"),0xffba00ff,capgrpMessage)
AddCaption(LOC_NOT("Timed Kamikaze! +10 points!"),0xffba00ff,capgrpMessage)

-----------------
capgrpMessage2
-----------------
AddCaption(LOC_NOT("Drone Hunter! +10 points!"),0xffba00ff,capgrpMessage2)
AddCaption(LOC_NOT("Ammo Maniac! +5 points!"),0xffba00ff,capgrpMessage2)
AddCaption(LOC_NOT("Shield Seeker! +10 points!"),0xffba00ff,capgrpMessage2)
AddCaption(LOC_NOT("Boss Slayer! +25 points!"),0xffba00ff,capgrpMessage2)
]]

----------------------------------
-- so I herd u liek wariables
----------------------------------

local fMod = 1000000 -- use this for dev and .16+ games

-- some console stuff
local shellID = 0
local explosivesID = 0
local luaGameTicks = 0

-- gaudyRacer
local boosterOn = false
local roundLimit = 3		-- can be overridden by script parameter "rounds"
local roundNumber = 0
local firstClan = 10
local gameOver = false
local gameBegun = false

local bestClan = 10
local bestScore = 0
local sdScore = {}
local sdName = {}
local sdKills = {}

local roundN = 0
local lastRound
local RoundHasChanged = true

-- for script parameters
local startBarrels = 5		-- "barrels"
local startShield = 30		-- "shield"
local startRadShots = 2		-- "pings"
local shieldBonus = 30		-- "shieldbonus"
local barrelBonus = 3		-- "barrelbonus"
local timeBonus = 4		-- "timebonus"
local forceTheme = true		-- "forcetheme"

--------------------------
-- hog and team tracking variales
--------------------------

local numhhs = 0
local hhs = {}

local numTeams
local teamNameArr = {}
local teamClan = {}
local teamSize = {}
local teamIndex = {}

local teamScore = {}
local teamCircsKilled = {}
local teamSurfer = {}

-- stats variables
local roundKills = 0
local roundScore = 0
local RK = 0
local GK = 0
local BK = 0
local OK = 0
local SK = 0
local shieldMiser = true
local fierceComp = false
local chainCounter = 0
local chainLength = 0
local shotsFired = 0
local shotsHit = 0
local sniperHits = 0
local pointBlankHits = 0

---------------------
-- awards (for stats section, just for fun)
---------------------
-- global awards
local awardTotalKills=0	-- overall killed invaders (min. 30)

-- hog awards
local awardRoundScore	-- hog with most score in 1 round (min. 50)
local awardRoundKills	-- most kills in 1 round (min. 5)
local awardAccuracy	-- awarded to hog who didn’t miss once in his round, with most kills (min. 5)
local awardCombo	-- hog with longest combo (min. 5)

---------------------
-- tumbler goods
---------------------

local moveTimer = 0
local leftOn = false
local rightOn = false
local upOn = false
local downOn = false

----------------
-- TUMBLER
local wep = {}
local wepAmmo = {}
local wepCol = {}
local wepIndex = 0
local wepCount = 0
local fireTimer = 0
----------------



local primShotsMax = 5
local primShotsLeft = 0

local TimeLeftCounter = 0
local TimeLeft = 0
local stopMovement = false
local tumbleStarted = false

local beam = false
local pShield
local shieldHealth

local shockwave
local shockwaveHealth = 0
local shockwaveRad = 300

local Timer100 = 0

local vTag = {}

-----------------------------------------------
-- CIRCLY GOODIES
-----------------------------------------------

local CirclesAreGo = false
local playerIsFine = true
local targetHit = false

local FadeAlpha = 0 -- used to fade the circles out gracefully when player dies
local pTimer = 0 -- tracking projectiles following player

local circAdjustTimer = 0		-- handle adjustment of circs direction
local m2Count = 0		-- handle speed of circs

local vCirc = {}
local vCCount = 0

local rCirc = {}
local rCircX = {}
local rCircY = {}
local rAlpha = 255
local rPingTimer = 0
local radShotsLeft = 0

local vCircActive = {}
local vCircHealth = {}
local vType = {}
local vCounter = {}		-- how often this circ gets to "fire" etc
local vCounterLim = {} -- when vCounter == vCounterLim circle performs its special
local vCircScore = {} -- how many points killing this invader gives

local vCircRadMax = {}
local vCircRadMin = {}
local vCircRadDir = {}
local vCircRadCounter = {}

local vCircDX = {}
local vCircDY = {}

local vCircX = {}
local vCircY = {}
local vCircMinA = {}
local vCircMaxA = {}
local vCircType = {}
local vCircPulse = {}
local vCircFuckAll = {}
local vCircRadius = {}
local vCircWidth = {}
local vCircCol = {}

-------------------------------------------
-- some lazy copypasta/modified methods
-------------------------------------------



function HideTags()

	for i = 0, 4 do
		SetVisualGearValues(vTag[i],0,0,0,0,0,1,0, 0, 240000, 0xffffff00)
	end

end

function DrawTag(i)

	local zoomL = 1.3
	local xOffset = 40
	local yOffset, tValue, tCol

	if i == 0 then
		yOffset = 40
		tCol = 0xffba00ff
		tValue = TimeLeft
	elseif i == 1 then
		zoomL = 1.1
		yOffset = 70
		tCol = 0x00ff00ff
		tValue = wepAmmo[wepIndex] --primShotsLeft
	elseif i == 2 then
		zoomL = 1.1
		xOffset = 40 + 35
		yOffset = 70
		tCol = 0xa800ffff
		tValue = shieldHealth - 80
	elseif i == 4 then
		zoomL = 1.1
		xOffset = 40 + 80
		yOffset = 70
		tCol = 0xffffffff
		tValue = roundScore
	end

	DeleteVisualGear(vTag[i])
	vTag[i] = AddVisualGear(0, 0, vgtHealthTag, 0, false)
	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(vTag[i])
	SetVisualGearValues	(
				vTag[i], 		--id
				-(ScreenWidth/2) + xOffset,	--xoffset
				ScreenHeight - yOffset, --yoffset
				0, 			--dx
				0, 			--dy
				zoomL, 			--zoom
				1, 			--~= 0 means align to screen
				g7, 			--frameticks
				tValue, 		--value
				240000, 		--timer
				tCol		--GetClanColor( GetHogClan(CurrentHedgehog) )
				)

end

function RebuildTeamInfo()

	-- make a list of individual team names
	for i = 0, (TeamsCount-1) do
		teamNameArr[i] = " " -- = i
		teamSize[i] = 0
		teamIndex[i] = 0
		teamScore[i] = 0
		teamCircsKilled[i] = 0
		teamSurfer[i] = false
	end
	numTeams = 0

	for i = 0, (numhhs-1) do

		z = 0
		unfinished = true
		while(unfinished == true) do

			newTeam = true
			tempHogTeamName = GetHogTeamName(hhs[i]) -- this is the new name

			if tempHogTeamName == teamNameArr[z] then
				newTeam = false
				unfinished = false
			end

			z = z + 1

			if z == (TeamsCount-1) then
				unfinished = false
				if newTeam == true then
					teamNameArr[numTeams] = tempHogTeamName
					numTeams = numTeams + 1
				end
			end

		end

	end

	-- find out how many hogs per team, and the index of the first hog in hhs
	for i = 0, (TeamsCount-1) do

		for z = 0, (numhhs-1) do
			if GetHogTeamName(hhs[z]) == teamNameArr[i] then
				teamClan[i] = GetHogClan(hhs[z])
				if teamSize[i] == 0 then
					teamIndex[i] = z -- should give starting index
				end
				teamSize[i] = teamSize[i] + 1
				--add a pointer so this hog appears at i in hhs
			end
		end

	end

end

-- control
function AwardPoints(p)
	roundScore = roundScore + p
	DrawTag(4)

	for i = 0,(TeamsCount-1) do
		if teamClan[i] == GetHogClan(CurrentHedgehog) then
			teamScore[i] = teamScore[i] + p
		end
	end

end

function AwardKills(t)

	roundKills = roundKills + 1

	for i = 0,(TeamsCount-1) do
		if teamClan[i] == GetHogClan(CurrentHedgehog) then
			teamCircsKilled[i] = teamCircsKilled[i] + 1
			awardTotalKills = awardTotalKills + 1

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

function CommentOnScore()
	local teamStats = {}
	for i = 0,(TeamsCount-1) do
		sdScore[i] = teamScore[i]
		sdKills[i] = teamCircsKilled[i]
		sdName[i] = teamNameArr[i]
		table.insert(teamStats, {score = teamScore[i], kills = teamCircsKilled[i], name = teamNameArr[i]})
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
			string.format(loc("Score: %d points"), teamStats[i].score) .. "|" ..
			string.format(loc("Kills: %d invaders destroyed"), teamStats[i].kills) .. "|" ..
			" " .. "|"
			table.insert(teamComment, comment)

			SendStat(siClanHealth, tostring(teamStats[i].score), teamStats[i].name)
		else
			comment = "|"
		end
		table.insert(teamComment, comment)
	end

	local entireC = ""
	for i = TeamsCount,1,-1 do
		entireC = entireC .. teamComment[i]
	end
	local statusText, scoreText
	if roundNumber >= roundLimit then
		if teamStats[1].score == teamStats[2].score then
			statusText = loc("Status Update")
			scoreText = loc("Team scores:")
		else
			statusText = loc("Game over!")
			scoreText = loc("Final team scores:")
		end
	else
		statusText = loc("Status Update")
		scoreText = loc("Team scores:")
	end
	ShowMission(	loc("Space Invasion"),
			statusText,
			string.format(loc("Rounds complete: %d/%d"), roundNumber, roundLimit) .. "| " .. "|" ..
			scoreText .. " |" ..entireC, 4, 1)

	if roundNumber >= roundLimit then
		local winnerTeam = teamStats[1].name
		local victorySoundPlayed = false
		for i = 0, (numhhs-1) do
			if GetHogTeamName(hhs[i]) == winnerTeam then
				if not victorySoundPlayer then
					PlaySound(sndVictory, hhs[i])
					victorySoundPlayed = true
				end
				SetState(hhs[i], bor(GetState(hhs[i]), gstWinner))
			end
		end
		AddCaption(string.format("%s wins!", winnerTeam))
		SendStat(siGameResult, string.format("%s wins!", winnerTeam))

		for i = 1, TeamsCount do
			SendStat(siPointType, loc("points"))
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
	
		if awardTotalKills >= 30 then
			awardsGiven = awardsGiven + 1
			SendStat(siCustomAchievement,
				string.format(loc("%d invaders have been destroyed in this game."), awardTotalKills))
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

		if awardRoundKills ~= nil then
			awardsGiven = awardsGiven + 1
			local text
			if awardRoundKills.value >= 33 then
				text = loc("%s (%s) has been invited to join the Planetary Association of the Hedgehogs, it destroyed a staggering %d invaders in just one round!")
			elseif awardRoundKills.value >= 22 then
				if awardRoundKills.hogName == "Rambo" then
					text = loc("The hardships of the war turned %s (%s) into a killing machine: %d invaders destroyed in one round!")
				else
					text = loc("%s (%s) is Rambo in a hedgehog costume! He destroyed %d invaders in one round.")
				end
			elseif awardRoundKills.value >= 11 then
				text = loc("%s (%s) is addicted to killing: %d invaders destoyed in one round.")
			else
				text = loc("%s (%s) destroyed %d invaders in one round.")
			end
			SendStat(siCustomAchievement,
			string.format(text,
			awardRoundKills.hogName, awardRoundKills.teamName, awardRoundKills.value))
		end
		if awardRoundScore ~= nil then
			awardsGiven = awardsGiven + 1
			local text
			if awardRoundScore.value >= 300 then
				text = loc("%s (%s) was undoubtedly the very best professional tumbler in this game: %d points in one round!")
			elseif awardRoundScore.value >= 250 then
				text = loc("%s (%s) struck like a meteor: %d points in only one round!")
			elseif awardRoundScore.value >= 200 then
				text = loc("%s (%s) is good at this: %d points in only one round!")
			elseif awardRoundScore.value >= 150 then
				text = loc("%s (%s) tumbles like no other: %d points in one round.")
			elseif awardRoundScore.value >= 100 then
				text = loc("%s (%s) is a tumbleweed: %d points in one round.")
			else
				text = loc("%s (%s) was the best baby tumbler: %d points in one round.")
			end
			SendStat(siCustomAchievement,
			string.format(text,
			awardRoundScore.hogName, awardRoundScore.teamName, awardRoundScore.value))
		end
		if awardAccuracy ~= nil then
			awardsGiven = awardsGiven + 1
			local text
			if awardAccuracy.value >= 20 then
				text = loc("The Society of Perfectionists greets %s (%s): No misses and %d hits in its best round.")
			elseif awardAccuracy.value >= 10 then
				text = loc("%s (%s) is a hardened hunter: No misses and %d hits in its best round!")
			else
				text = loc("%s (%s) shot %d invaders and never missed in the best round!")
			end
			SendStat(siCustomAchievement,
			string.format(text,
			awardAccuracy.hogName, awardAccuracy.teamName, awardAccuracy.value))
		end
		if awardCombo ~= nil then
			awardsGiven = awardsGiven + 1
			local text
			if awardCombo.value >= 11 then
				text = loc("%s (%s) was lightning-fast! Longest combo of %d, absolutely insane!")
			elseif awardCombo.value >= 8 then
				text = loc("%s (%s) gave short shrift to the invaders: Longest combo of %d!")
			else
				text = loc("%s (%s) was on fire: Longest combo of %d.")
			end
			SendStat(siCustomAchievement,
			string.format(text,
			awardCombo.hogName, awardCombo.teamName, awardCombo.value))
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
end

function onNewRound()
	roundNumber = roundNumber + 1

	CommentOnScore()

	-- end game if its at round limit
	if roundNumber >= roundLimit then

		for i = 0, (TeamsCount-1) do
			if teamScore[i] > bestScore then
				bestScore = teamScore[i]
				bestClan = teamClan[i]
			end
		end

		gameOver = true
		TurnTimeLeft = 0	--1
		TimeLeft = 0
		SendStat(siGraphTitle, "Score graph")
		EndGame()
	end
end

-- gaudy racer
function CheckForNewRound()

	if GetHogClan(CurrentHedgehog) == firstClan then
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

	if GetGearType(gear) == gtShell then
		lfs = 50	-- roughly 5 seconds
		shellID = shellID + 1
		setGearValue(gear,"ID",shellID)
		--nw WriteLnToConsole("Just assigned ID " .. getGearValue(gear,"ID") .. " to this shell")
	elseif GetGearType(gear) == gtBall then
		lfs = 5 --70	-- 7s
	elseif GetGearType(gear) == gtExplosives then
		lfs = 15	-- 1.5s
		explosivesID = explosivesID + 1
		setGearValue(gear,"ID",explosivesID)
		setGearValue(gear,"XP", GetX(gear))
		setGearValue(gear,"YP", GetY(gear))
		--nw WriteLnToConsole("Just assigned ID " .. getGearValue(gear,"ID") .. " to this explosives")
	elseif GetGearType(gear) == gtFlame then
		lfs = 5	-- 0.5s
	else
		lfs = 100
	end

	setGearValue(gear,"lifespan",lfs)
	--WriteLnToConsole("I also set its lifespan to " .. lfs)


end

function HandleLifeSpan(gear)

	decreaseGearValue(gear,"lifespan")

	--WriteLnToConsole("Just decreased the lifespan of a gear to " .. getGearValue(gear,"lifespan"))
	--WriteLnToConsole("The above event occured game Time: " .. GameTime .. "; luaTicks: " .. luaGameTicks)


	if getGearValue(gear,"lifespan") == 0 then

		if GetGearType(gear) == gtShell then
			AddVisualGear(GetX(gear), GetY(gear), vgtExplosion, 0, false)

			WriteLnToConsole("about to delete a shell due to lifespan == 0")
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
			--WriteLnToConsole("I'm setting barrel ID " .. getGearValue(gear,"ID") .. " to 0 health because it's been flung too close to the map edges. at Game Time: " .. GameTime .. "; luaTicks: " .. luaGameTicks)
		end

	end

end

-----------------------
--EVENT HANDLERS
-- action keys
-----------------------

function HandleFlameThrower()

	--
	--flamer

	fireTimer = fireTimer + 1
	if fireTimer == 6 then	-- 6
		fireTimer = 0

		if (wep[wepIndex] == loc("Flamer") ) and (preciseOn == true) and (wepAmmo[wepIndex] > 0) and (stopMovement == false) and (tumbleStarted == true) then

			wepAmmo[wepIndex] = wepAmmo[wepIndex] - 1
			AddCaption(
			loc("Flamer") .. ": " ..
			(wepAmmo[wepIndex]/800*100) - (wepAmmo[wepIndex]/800*100)%2 .. "%",
			wepCol[2],
			capgrpMessage2
			)
			DrawTag(3)

			dx, dy = GetGearVelocity(CurrentHedgehog)
			shell = AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtFlame, 0, 0, 0, 0)

			xdev = 1 + GetRandom(35)
			xdev = xdev / 100

			r = GetRandom(2)
			if r == 1 then
				xdev = xdev*-1
			end

			ydev = 1 + GetRandom(35)
			ydev = ydev / 100

			r = GetRandom(2)
			if r == 1 then
				ydev = ydev*-1
			end

			SetGearVelocity(shell, (dx*4.5)+(xdev*fMod), (dy*4.5)+(ydev*fMod))

		end

	end


end

function ChangeWeapon()

	wepIndex = wepIndex + 1
	if wepIndex == wepCount then
		wepIndex = 0
	end

--[[
	NOTE: Don’t show selected weapon as long we only have one. Remove this comment and activate this code
	again as soon as at least one other weapon appears.
	AddCaption(wep[wepIndex] .. " " .. loc("selected!"), wepCol[wepIndex],capgrpAmmoinfo )
	AddCaption(wepAmmo[wepIndex] .. " " .. loc("shots remaining."), wepCol[wepIndex],capgrpMessage2)
]]

end

-- derp tumbler
function onPrecise()

	if (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) and (wepAmmo[wepIndex] > 0) then

		wepAmmo[wepIndex] = wepAmmo[wepIndex] - 1

		if wep[wepIndex] == loc("Barrel Launcher") then
			shotsFired = shotsFired +1

			morte = AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtExplosives, 0, 0, 0, 1)
			CopyPV(CurrentHedgehog, morte) -- new addition
			x,y = GetGearVelocity(morte)
			x = x*2
			y = y*2
			SetGearVelocity(morte, x, y)

			if wepAmmo[wepIndex] == 0 then
				PlaySound(sndSuddenDeath)
				AddCaption(loc("Ammo depleted!"),0xff0000ff,capgrpMessage)
			else
				PlaySound(sndThrowRelease)
			end
			DrawTag(1)

		elseif wep[wepIndex] == loc("Mine Deployer") then
			morte = AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtAirBomb, 0, 0, 0, 0)
			SetTimer(morte, 1000)
			DrawTag(1)
		end

	elseif (wepAmmo[wepIndex] == 0) and (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) then
		PlaySound(sndDenied)
		AddCaption(loc("Ammo depleted!"),0xff0000ff,capgrpMessage)
	end

	preciseOn = true

end

function onPreciseUp()
	preciseOn = false
end

function onLJump()

	if (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) then
		shieldMiser = false
		if shieldHealth == 80 then
			AddCaption(loc("Shield depleted"),0xff0000ff,capgrpMessage)
			PlaySound(sndDenied)
		elseif (beam == false) and (shieldHealth > 80) then
			beam = true
			SetVisualGearValues(pShield, GetX(CurrentHedgehog), GetY(CurrentHedgehog), 40, 255, 1, 10, 0, 300, 1, 0xa800ffff)
			AddCaption( string.format(loc("Shield ON: %d power remaining"), shieldHealth - 80))
			PlaySound(sndWarp)
		else
			beam = false
			SetVisualGearValues(pShield, GetX(CurrentHedgehog), GetY(CurrentHedgehog), 0, 0, 1, 10, 0, 0, 0, 0xa800ffff)
			AddCaption( string.format(loc("Shield ON: %d power remaining"), shieldHealth - 80))
		end
	end
end

function onHJump()

	if (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) and
	(rAlpha == 255) then
		if radShotsLeft > 0 then
			rPingTimer = 0
			rAlpha = 0
			radShotsLeft = radShotsLeft -1
			AddCaption(string.format(loc("Pings left: %d"), radShotsLeft),GetClanColor(GetHogClan(CurrentHedgehog)),capgrpMessage)
			-- Play sonar sound
			PlaySound(sndJetpackLaunch)

		else
			AddCaption(loc("No radar pings left!"),0xFF0000FF,capgrpMessage)
			PlaySound(sndDenied)
		end
	end

end

-----------------
-- movement keys
-----------------

function onLeft()
	leftOn = true
end

function onRight()
	rightOn = true
end

function onUp()
	upOn = true
end

function onDown()
	downOn = true
end

function onDownUp()
	downOn = false
end

function onUpUp()
	upOn = false
end

function onLeftUp()
	leftOn = false
end

function onRightUp()
	rightOn = false
end

--------------------------
-- other event handlers
--------------------------

function onParameters()
	parseParams()
	if params["rounds"] ~= nil then
		roundLimit = math.floor(tonumber(params["rounds"]))
	end
	if params["barrels"] ~= nil then
		startBarrels = math.floor(tonumber(params["barrels"]))
	end
	if params["pings"] ~= nil then
		startRadShots = math.floor(tonumber(params["pings"]))
	end
	if params["shield"] ~= nil then
		startShield = math.floor(tonumber(params["shield"]))
	end

	if params["barrelbonus"] ~= nil then
		barrelBonus = math.floor(tonumber(params["barrelbonus"]))
	end
	if params["shieldbonus"] ~= nil then
		shieldBonus = math.floor(tonumber(params["shieldbonus"]))
	end
	if params["timebonus"] ~= nil then
		timeBonus = math.floor(tonumber(params["timebonus"]))
	end
	if params["forcetheme"] == "false" then
		forceTheme = false
	else
		forceTheme = true
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
		gfBottomBorder + gfForts + gfDivideTeams +
		gfDisableWind + gfMoreWind + gfTagTeam +
		-- very unusual flags, they don’t affect gameplay really, they are mostly for funny graphical effects
		gfKing + 	-- King Mode doesn’t work like expected, since hedgehogs never really die here in this mode
		gfVampiric +	-- just for the grapical effects
		gfBorder 	-- technically possible, but not very fun to play
		-- any other flag is FORBIDDEN and will be disabled when it is on anyways!

	GameFlags = band(GameFlags, allowedFlags)

	if forceTheme then
		Theme = "EarthRise"
	end
	CaseFreq = 0
	HealthCaseProb = 0
	Delay = 1000
	SuddenDeathTurns = 50
	WaterRise = 0
	HealthDecrease = 0

	for i = 0, 4 do
		vTag[0] = AddVisualGear(0, 0, vgtHealthTag, 0, false)
	end

	HideTags()

	wep[0] = loc("Barrel Launcher")
	wep[1] = loc("Mine Deployer")
	wep[2] = loc("Flamer")

	wepCol[0] = 0x78818eff
	wepCol[1] = 0xa12a77ff
	wepCol[2] = 0xf49318ff

	wepCount = 3

end

function onGameStart()
	SendHealthStatsOff()

	ShowMission	(
				loc("SPACE INVASION"),
				loc("A Hedgewars mini-game"),

				loc("Destroy invaders to score points.") .. "|" ..
				" " .. "|" ..

				string.format(loc("Round Limit: %d"), roundLimit) .. "|" ..
				string.format(loc("Turn Time: %dsec"), (TurnTime/1000)) .. "|" ..
				" " .. "|" ..

				loc("Movement: [Up], [Down], [Left], [Right]") .. "|" ..
				loc("Fire: [Precise]") .. "|" ..
				loc("Toggle Shield: [Long jump]") .. "|" ..
				loc("Radar Ping: [High jump]") .. "|" ..

				"", 4, 5000
				)

	CreateMeSomeCircles()
	RebuildTeamInfo() -- control
	lastRound = TotalRounds

end

function onScreenResize()

	-- redraw Tags so that their screen locations are updated
	if (CurrentHedgehog ~= nil) and (tumbleStarted == true) then
			DrawTag(0)
			DrawTag(1)
			DrawTag(2)
			DrawTag(4)
	end

end

function onNewTurn()

	radShotsLeft = startRadShots
	stopMovement = false
	tumbleStarted = false
	boosterOn = false
	beam = false
	shieldHealth = startShield + 80 -- 50 = 5 secs, roughly
	shockwaveHealth = 0

	RK = 0
	GK = 0
	BK = 0
	OK = 0
	SK = 0
	roundKills = 0
	roundScore = 0
	shieldMiser = true
	fierceComp = false
	shotsFired = 0
	shotsHit = 0
	sniperHits = 0
	pointBlankHits = 0
	chainLength = 0
	chainCounter = 0

	-------------------------
	-- gaudy racer
	-------------------------
	CheckForNewRound()

	-- Handle Starting Stage of Game
	if (gameOver == false) and (gameBegun == false) then
		gameBegun = true
		roundNumber = 0 -- 0
		firstClan = GetHogClan(CurrentHedgehog)
	end

	if gameOver == true then
		gameBegun = false
		stopMovement = true
		tumbleStarted = false
		SetMyCircles(false)
	end


	-------
	-- tumbler
	----

	wepAmmo[0] = startBarrels
	wepAmmo[1] = startRadShots
	wepAmmo[2] = 5000
	wepIndex = 2
	ChangeWeapon()


	HideTags()

	---------------
	---------------
	--AddCaption("num g: " .. numGears() )
	--WriteLnToConsole("onNewTurn, I just set a bunch of variables to their necessary states. This was done at:")
	--WriteLnToConsole("The above occured at Game Time: " .. GameTime .. "; luaTicks: " .. luaGameTicks)

end

function ThingsToBeRunOnGears(gear)

	HandleLifeSpan(gear)
	DeleteFarFlungBarrel(gear)

	if CirclesAreGo == true then
		CheckVarious(gear)
		ProjectileTrack(gear)
	end

end

function onGearWaterSkip(gear)
	if gear == CurrentHedgehog then

		for i = 0,(TeamsCount-1) do
			if teamClan[i] == GetHogClan(CurrentHedgehog) and (teamSurfer[i] == false) then
				teamSurfer[i] = true
				AddCaption(loc("Surfer! +15 points!"),0xffba00ff,capgrpVolume)
				AwardPoints(15)
			end
		end

	end
end

function onGameTick()


	--WriteLnToConsole("Start of GameTick")
	luaGameTicks = luaGameTicks + 1 -- GameTime

	HandleCircles()

	Timer100 = Timer100 + 1
	if Timer100 >= 100 then
		Timer100 = 0

		if beam == true then
			shieldHealth = shieldHealth - 1
			if shieldHealth < 80 then -- <= 80
				shieldHealth = 80
				beam = false
				AddCaption(loc("Shield depleted"),0xff0000ff,capgrpMessage)
				PlaySound(sndMineTick)
				PlaySound(sndSwitchHog)
			end
		end



		--nw WriteLnToConsole("Starting ThingsToBeRunOnGears()")

		runOnGears(ThingsToBeRunOnGears)

		--nw WriteLnToConsole("Finished ThingsToBeRunOnGears()")

		if CirclesAreGo == true then
			CheckDistances()
		end

		-- white smoke trail as player falls from the sky
		if (TimeLeft <= 0) and (stopMovement == true) and (CurrentHedgehog ~= nil) then
			j,k = GetGearVelocity(CurrentHedgehog)
			if (j ~= 0) and (k ~= 0) then
				AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmoke, 0, true)
			end
		end

		--nw WriteLnToConsole("Finished 100Timer")

	end


	-- start the player tumbling with a boom once their turn has actually begun
	if (tumbleStarted == false) and (gameOver == false) then
		if (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) then
			tumbleStarted = true
			TimeLeft = (TurnTime/1000)
			FadeAlpha = 0
			rAlpha = 255
			AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtGrenade, 0, 0, 0, 1)
			DrawTag(0)
			DrawTag(1)
			DrawTag(2)
			DrawTag(4)
			SetMyCircles(true)
		end
	end

	--WriteLnToConsole("Finished initial check")

	if (CurrentHedgehog ~= nil) and (tumbleStarted == true) then

		-- Calculate and display turn time
		TimeLeftCounter = TimeLeftCounter + 1
		if TimeLeftCounter == 1000 then
			TimeLeftCounter = 0
			TimeLeft = TimeLeft - 1

			if TimeLeft >= 0 then
				DrawTag(0)
			end

		end

		if (TimeLeftCounter % 1000) == 0 then
			if TimeLeft == 5 then
				PlaySound(sndHurry, CurrentHedgehog)
			elseif TimeLeft <= 4 and TimeLeft >= 1 then
				PlaySound(_G["sndCountdown"..TimeLeft])
			end
		end

		--WriteLnToConsole("Finished timeleft calculations")

		-------------------------------
		-- Player has run out of luck (out of time or hit by gtShell)
		-------------------------------
		-- checks in FloatyThings
		if PlayerIsFine() == false then
			TimeLeft = 0
		end

		--WriteLnToConsole("successfully checked playerIsFine")

		if (TimeLeft == 0) then
			if PlayerIsFine() then AddCaption(loc("Time's up!")) end
			if (stopMovement == false) then	--time to stop the player
				stopMovement = true
				boosterOn = false
				beam = false
				upOn = false
				down = false
				leftOn = false
				rightOn = false
				SetMyCircles(false)
				rAlpha = 255
				--nw WriteLnToConsole("Player is out of luck")

				if shieldMiser == true then

					p = (roundKills*3.5) - ((roundKills*3.5)%1) + 2

					AddCaption(string.format(loc("Shield Miser! +%d points!"), p),0xffba00ff,capgrpAmmoinfo)
					AwardPoints(p)
				end

				local accuracy = (shotsHit / shotsFired) * 100
				if (accuracy >= 80) and (shotsFired > 4) then
					AddCaption(loc("Accuracy Bonus! +15 points"),0xffba00ff,capgrpVolume)
					AwardPoints(15)


					-- special award for no misses
					local award = false
					if awardAccuracy == nil then
						if (shotsHit >= shotsFired) then
							award = true
						end
					elseif (shotsHit == shotsFired) and shotsHit > awardAccuracy.value then
						award = true
					end
					if award then
						awardAccuracy = {
							hogName = GetHogName(CurrentHedgehog),
							teamName = GetHogTeamName(CurrentHedgehog),
							value = shotsHit, 
						}
					end
		
				end

				AddCaption(loc(string.format("Round score: %d", roundScore)), 0xFFFFFFFF, capgrpMessage2)

				-- other awards
				awardRoundScore = UpdateSimpleAward(awardRoundScore, roundScore, 50)
				awardRoundKills = UpdateSimpleAward(awardRoundKills, roundKills, 5)

				HideTags()

			end
		else -- remove this if you want tumbler to fall slowly on death
		-------------------------------
		-- Player is still in luck
		-------------------------------


			--WriteLnToConsole("about to do chainCounter checks")
			if chainCounter > 0 then
				chainCounter = chainCounter -1
				if chainCounter == 0 then
					chainLength = 0
				end
			end

			-- handle movement based on IO
			moveTimer = moveTimer + 1
			if moveTimer == 100 then -- 100
				--nw WriteLnToConsole("Start of Player MoveTimer")
				moveTimer = 0

				---------------
				-- new trail code
				---------------
				-- the trail lets you know you have 5s left to pilot, akin to birdy feathers
				if (TimeLeft <= 5) and (TimeLeft > 0) then							--vgtSmoke
					tempE = AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmoke, 0, true)
					g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
					SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, GetClanColor(GetHogClan(CurrentHedgehog)) )
				end
				--------------
				--------------

				dx, dy = GetGearVelocity(CurrentHedgehog)

				--WriteLnToConsole("I just got the velocity of currenthedgehog. It is dx: " .. dx .. "; dy: " .. dy)
				--WriteLnToConsole("The above event occured game Time: " .. GameTime .. "; luaTicks: " .. luaGameTicks)

				if boosterOn == true then
					tempE = AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtDust, 0, false)
					g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
					SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, 1, g9, GetClanColor(GetHogClan(CurrentHedgehog)) )
					dxlimit = 0.8*fMod
					dylimit = 0.8*fMod
				else
					dxlimit = 0.4*fMod
					dylimit = 0.4*fMod
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


				if leftOn == true then
					dx = dx - 0.1*fMod
				end
				if rightOn == true then
					dx = dx + 0.1*fMod
				end

				if upOn == true then
					dy = dy - 0.1*fMod
				end
				if downOn == true then
					dy = dy + 0.1*fMod
				end

				SetGearVelocity(CurrentHedgehog, dx, dy)

				--WriteLnToConsole("I just SET the velocity of currenthedgehog. It is now dx: " .. dx .. "; dy: " .. dy)
				--WriteLnToConsole("The above event occured game Time: " .. GameTime .. "; luaTicks: " .. luaGameTicks)
				--nw WriteLnToConsole("End of Player MoveTimer")

			end


			HandleFlameThrower()


		end -- new end I put here to check if he's still alive or not

	end

	--WriteLnToConsole("End of GameTick")

end

function onGearDamage(gear, damage)
	if GetGearType(gear) == gtHedgehog then
		if (fierceComp == false) and (damage >= 60) and (GetHogClan(gear) ~= GetHogClan(CurrentHedgehog)) then
			fierceComp = true
			AddCaption(loc("Fierce Competition! +8 points!"),0xffba00ff,capgrpGameState)
			AwardPoints(8)
		end
	end
end

function onGearResurrect(gear)

	-- did I fall into the water? well, that was a stupid thing to do
	if gear == CurrentHedgehog then
		TimeLeft = 0
		playerIsFine = false
		--WriteLnToConsole("Current hedgehog just drowned himself")
		--WriteLnToConsole("The above event occured game Time: " .. GameTime .. "; luaTicks: " .. luaGameTicks)
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
		hhs[numhhs] = gear
		numhhs = numhhs + 1
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

function DoHorribleThings(cUID)

	-- work out the distance to the target
	g1X, g1Y = GetGearPosition(CurrentHedgehog)
	g2X, g2Y = vCircX[cUID], vCircY[cUID]
	q = g1X - g2X
	w = g1Y - g2Y
	r = math.sqrt( (q*q) + (w*w) )	--alternate

	opp = w
	if opp < 0 then
		opp = opp*-1
	end

	-- work out the angle (theta) to the target
	t = math.deg ( math.asin(opp / r) )

	-- based on the radius of the radar, calculate what x/y displacement should be
	NR = 150 -- radius at which to draw circs
	NX = math.cos( math.rad(t) ) * NR
	NY = math.sin( math.rad(t) ) * NR

	-- displace xy based on where this thing actually is

	if r < NR then
		rCircX[cUID] = g2X
	elseif q > 0 then
		rCircX[cUID] = g1X - NX
	else
		rCircX[cUID] = g1X + NX
	end

	if r < NR then
		rCircY[cUID] = g2Y
	elseif w > 0 then
		rCircY[cUID] = g1Y - NY
	else
		rCircY[cUID] = g1Y + NY
	end

end

function PlayerIsFine()
	return (playerIsFine)
end

function GetDistFromXYtoXY(a, b, c, d)
	q = a - c
	w = b - d
	return ( (q*q) + (w*w) )
end

function GetDistFromGearToGear(gear, gear2)

	g1X, g1Y = GetGearPosition(gear)
	g2X, g2Y = GetGearPosition(gear2)
	q = g1X - g2X
	w = g1Y - g2Y

	return ( (q*q) + (w*w) )

end

function GetDistFromGearToXY(gear, g2X, g2Y)

	g1X, g1Y = GetGearPosition(gear)
	q = g1X - g2X
	w = g1Y - g2Y

	return ( (q*q) + (w*w) )

end

function CreateMeSomeCircles()

	for i = 0, 7 do
		vCCount = vCCount +1
		vCirc[i] = AddVisualGear(0,0,vgtCircle,0,true)

		rCirc[i] = AddVisualGear(0,0,vgtCircle,0,true)
		rCircX[i] = 0
		rCircY[i] = 0

		vCircDX[i] = 0
		vCircDY[i] = 0

		vType[i] = "generic"
		vCounter[i] = 0
		vCounterLim[i] = 3000
		vCircScore[i] = 0
		vCircHealth[i] = 1

		vCircMinA[i] = 80
		vCircMaxA[i] = 255
		vCircType[i] = 1
		vCircPulse[i] = 10
		vCircFuckAll[i] = 0
		vCircRadius[i] = 0
		vCircWidth[i] = 3

		vCircRadMax[i] = 0
		vCircRadMin[i] = 0
		vCircRadDir[i] = -1
		vCircRadCounter[i] = 0

		vCircX[i], vCircY[i] = 0,0

		vCircCol[i] = 0xff00ffff

		SetVisualGearValues(vCirc[i], vCircX[i], vCircY[i], vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], vCircCol[i])

		SetVisualGearValues(rCirc[i], 0, 0, 100, 255, 1, 10, 0, 40, 3, vCircCol[i])

	end

	pShield = AddVisualGear(0,0,vgtCircle,0,true)

	shockwave = AddVisualGear(0,0,vgtCircle,0,true)

end

function IGotMeASafeXYValue(i)

	acceptibleDistance = 800

	vCircX[i] = GetRandom(5000)
	vCircY[i] = GetRandom(2000)
	dist = GetDistFromGearToXY(CurrentHedgehog, vCircX[i], vCircY[i])
	if dist > acceptibleDistance*acceptibleDistance then
		return(true)
	else
		return(false)
	end

end

function CircleDamaged(i)

	res = ""
	vCircHealth[i] = vCircHealth[i] -1

	if vCircHealth[i] <= 0 then
	-- circle is dead, do death effects/consequences

		vCircActive[i] = false

		if (vType[i] == "drone") then
			PlaySound(sndHellishImpact4)
			TimeLeft = TimeLeft + timeBonus
			AddCaption(string.format(loc("Time Extended! +%dsec"), timeBonus), 0xff0000ff,capgrpMessage )
			DrawTag(0)

			morte = AddGear(vCircX[i], vCircY[i], gtExplosives, 0, 0, 0, 1)
			SetHealth(morte, 0)

			RK = RK + 1
			if RK == 5 then
				RK = 0
				AddCaption(loc("Drone Hunter! +10 points!"),0xffba00ff,capgrpMessage2)
				AwardPoints(10)
			end

		elseif (vType[i] == "ammo") then
			AddVisualGear(vCircX[i], vCircY[i], vgtExplosion, 0, false)
			PlaySound(sndExplosion)
			PlaySound(sndShotgunReload)
			wepAmmo[0] = wepAmmo[0] + barrelBonus
			AddCaption(string.format("+%d Ammo", barrelBonus), 0x00ff00ff,capgrpMessage)
			DrawTag(1)

			GK = GK + 1
			if GK == 3 then
				GK = 0
				AddCaption(loc("Ammo Maniac! +5 points!"),0xffba00ff,capgrpMessage2)
				AwardPoints(5)
			end

		elseif (vType[i] == "bonus") then

			AddVisualGear(vCircX[i], vCircY[i], vgtExplosion, 0, false)
			PlaySound(sndExplosion)

			AddVisualGear(vCircX[i], vCircY[i], vgtFire, 0, false)
			AddVisualGear(vCircX[i], vCircY[i], vgtFire, 0, false)
			AddVisualGear(vCircX[i], vCircY[i], vgtFire, 0, false)
			AddVisualGear(vCircX[i], vCircY[i], vgtFire, 0, false)
			AddVisualGear(vCircX[i], vCircY[i], vgtFire, 0, false)
			AddVisualGear(vCircX[i], vCircY[i], vgtSmoke, 0, false)

			PlaySound(sndVaporize)

			shieldHealth = shieldHealth + shieldBonus
			AddCaption(string.format(loc("Shield boosted! +%d power"),shieldBonus), 0xa800ffff,capgrpMessage)
			if shieldHealth >= 250 then
				shieldHealth = 250
				AddCaption(loc("Shield is fully recharged!"),0xa800ffff,capgrpMessage)
			end
			DrawTag(2)

			OK = OK + 1
			if OK == 3 then
				OK = 0
				AddCaption(loc("Shield Seeker! +10 points!"),0xffba00ff,capgrpMessage2)
				AwardPoints(10)
			end

		elseif (vType[i] == "blueboss") then
			PlaySound(sndHellishImpact3)
			AddCaption(loc("Boss defeated! +30 points!"), 0x0050ffff,capgrpMessage)

			morte = AddGear(vCircX[i], vCircY[i], gtExplosives, 0, 0, 0, 1)
			SetHealth(morte, 0)

			BK = BK + 1
			if BK == 2 then
				BK = 0
				AddCaption(loc("Boss Slayer! +25 points!"),0xffba00ff,capgrpMessage2)
				AwardPoints(25)
			end

		end

		AwardPoints(vCircScore[i])
		AwardKills()
		SetUpCircle(i)
		res = "fatal"

		chainCounter = 3000
		chainLength = chainLength + 1
		if chainLength > 1 then
			AddCaption( string.format(loc("%d-Hit Combo! +%d points!"), chainLength, chainLength*2),0xffba00ff,capgrpAmmostate)
			AwardPoints(chainLength*2)
		end

		awardCombo = UpdateSimpleAward(awardCombo, chainLength, 5)

	else
	-- circle is merely damaged
	-- do damage effects/sounds
		AddVisualGear(vCircX[i], vCircY[i], vgtSteam, 0, false)
		r = math.random(1,4)
		PlaySound(_G["sndHellishImpact" .. tostring(r)])
		res = "non-fatal"

	end

	return(res)

end

function SetUpCircle(i)


	r = GetRandom(10)
	-- 80% of spawning either red/green
	if r <= 7 then

		r = GetRandom(2)
		if r == 0 then
			vCircCol[i] = 0xff0000ff -- red
			vType[i] = "drone"
			vCircRadMin[i] = 50	*5
			vCircRadMax[i] = 90	*5
			vCounterLim[i] = 3000
			vCircScore[i] = 10
			vCircHealth[i] = 1
		elseif r == 1 then
			vCircCol[i] = 0x00ff00ff -- green
			vType[i] = "ammo"
			vCircRadMin[i] = 25	*7
			vCircRadMax[i] = 30	*7
			vCircScore[i] = 3
			vCircHealth[i] = 1
		end

	-- 20% chance of spawning boss or bonus
	else
		r = GetRandom(5)
		if r <= 1 then
			vCircCol[i] = 0x0050ffff -- sexy blue
			vType[i] = "blueboss"
			vCircRadMin[i] = 100*5
			vCircRadMax[i] = 180*5
			vCircWidth[i] = 1
			vCounterLim[i] = 2000
			vCircScore[i] = 30
			vCircHealth[i] = 3
		else
			vCircCol[i] = 0xa800ffff -- purp
			vType[i] = "bonus"
			vCircRadMin[i] = 20 *7
			vCircRadMax[i] = 40 *7
			vCircScore[i] = 5
			vCircHealth[i] = 1
		end

	end

	-- regenerate circle xy if too close to player or until sanity limit kicks in
	reN = 0
	while (reN < 10) do
		if IGotMeASafeXYValue(i) == false then
			reN = reN + 1
		else
			reN = 15
		end
	end

	vCircRadius[i] = vCircRadMax[i] - GetRandom(vCircRadMin[i])

	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(vCirc[i])
	SetVisualGearValues(vCirc[i], vCircX[i], vCircY[i], g3, g4, g5, g6, g7, vCircRadius[i], vCircWidth[i], vCircCol[i]-0x000000ff)

	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(rCirc[i])
	SetVisualGearValues(rCirc[i], 0, 0, g3, g4, g5, g6, g7, g8, g9, vCircCol[i]-0x000000ff)


	vCircActive[i] = true

	--nw WriteLnToConsole("CIRC " .. i .. ": X: " .. vCircX[i] .. "; Y: " .. vCircY[i])
	--nw WriteLnToConsole("CIRC " .. i .. ": dX: " .. vCircDX[i] .. "; dY: " .. vCircDY[i])
	--nw WriteLnToConsole("CIRC " .. i .. ": RAD:" .. vCircRadius[i])

end

function SetMyCircles(s)

	CirclesAreGo = s
	playerIsFine = s

	if s == true then
		--nw WriteLnToConsole("About to set up all circles, old values are here:")
		for i = 0,(vCCount-1) do
			--nw WriteLnToConsole("CIRC " .. i .. ": X: " .. vCircX[i] .. "; Y: " .. vCircY[i])
			--nw WriteLnToConsole("CIRC " .. i .. ": dX: " .. vCircDX[i] .. "; dY: " .. vCircDY[i])
			--nw WriteLnToConsole("CIRC " .. i .. ": RAD:" .. vCircRadius[i])
		end
		--nw WriteLnToConsole("Old values given, new values to follow...")
	end

	for i = 0,(vCCount-1) do

		if s == false then
			--vCircCol[i] = 0xffffffff
			vCircActive[i] = false
		elseif s == true then
			SetUpCircle(i)
		end

	end

end

function WellHeAintGonnaJumpNoMore(x,y,explode)
	if explode==true then
		AddVisualGear(x, y, vgtBigExplosion, 0, false)
		PlaySound(sndExplosion)
		local r = math.random(1,3)
		PlaySound(_G["sndOoff"..r], CurrentHedgehog)
	end

	playerIsFine = false
	AddCaption(loc("GOTCHA!"))
	PlaySound(sndHellish)

	targetHit = true

end

--- collision detection for weapons fire
function CheckVarious(gear)

	targetHit = false

	-- if circle is hit by player fire
	if (GetGearType(gear) == gtExplosives) then
		circsHit = 0

		for i = 0,(vCCount-1) do

			--nw WriteLnToConsole("Is it neccessary to check for collision with circ " .. i)

			--nw WriteLnToConsole("YES. about to calc distance between gtExplosives and circ " .. i)

			dist = GetDistFromGearToXY(gear, vCircX[i], vCircY[i])

			-- calculate my real radius if I am an aura
			if vCircType[i] == 0 then
				NR = vCircRadius[i]
			else
				NR = (48/100*vCircRadius[i])/2
			end

			if dist <= NR*NR then


				--nw WriteLnToConsole("Collision confirmed. The gtExplosives is within the circ radius!")

				dist = (GetDistFromXYtoXY(vCircX[i], vCircY[i], getGearValue(gear,"XP"), getGearValue(gear,"YP")) - (NR*NR))
				--AddCaption(loc("Dist: ") .. dist .. "!",0xffba00ff,capgrpGameState)
				if dist >= 1000000 then
					sniperHits = sniperHits +1
					AddCaption(loc("Sniper! +8 points!"),0xffba00ff,capgrpGameState)
					AwardPoints(8)
					if sniperHits == 3 then
						sniperHits = 0
						AddCaption(loc("They Call Me Bullseye! +16 points!"),0xffba00ff,capgrpGameState)
						AwardPoints(16)
					end
				elseif dist <= 6000 then
					pointBlankHits = pointBlankHits +1
					if pointBlankHits == 3 then
						pointBlankHits = 0
						AddCaption(loc("Point Blank Combo! +5 points!"),0xffba00ff,capgrpGameState)
						AwardPoints(5)
					end
				end

				AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)

				targetHit = true
				--WriteLnToConsole("set " .. "Exp ID: " .. getGearValue(gear,"ID") .. " health to 0")
				--WriteLnToConsole("targetHit set to true, explosive is at distance " .. dist .. "(within range " .. NR*NR.. ") of circ" )

				CircleDamaged(i)

				circsHit = circsHit + 1
				if circsHit > 1 then
					AddCaption(loc("Multi-shot! +15 points!"),0xffba00ff,capgrpAmmostate)
					AwardPoints(15)
						circsHit = 0
				end

				shotsHit = shotsHit + 1

			end

		end

	-- if player is hit by circle bazooka
	elseif (GetGearType(gear) == gtShell) then

		dist = GetDistFromGearToGear(gear, CurrentHedgehog)

		if beam == true then

			if dist < 3000 then
				tempE = AddVisualGear(GetX(gear), GetY(gear), vgtSmoke, 0, true)
				g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
				SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, 0xff00ffff )
				PlaySound(sndVaporize)
				DeleteGear(gear)

				SK = SK + 1
				if SK == 5 then
					SK = 0
					AddCaption(loc("Shield Master! +10 points!"),0xffba00ff,capgrpAmmoinfo)
					AwardPoints(10)
				end
			end

		elseif dist < 1600 then
			WellHeAintGonnaJumpNoMore(GetX(gear), GetY(gear), true)
		end

	end

	if targetHit == true then
			--nw WriteLnToConsole("about to delete something due to targetHit being set to true earlier")
			DeleteGear(gear)
			--nw WriteLnToConsole("there, I deleted it")
	end

	--nw WriteLnToConsole("End of CheckVarious()")

end

-- collision detection for player entering a circle
function CheckDistances()

	--nw WriteLnToConsole("Start of CheckDistances()")

	for i = 0,(vCCount-1) do


		--nw WriteLnToConsole("Attempting to calculate dist of circ " .. i)

		g1X, g1Y = GetGearPosition(CurrentHedgehog)
		g2X, g2Y = vCircX[i], vCircY[i]

		g1X = g1X - g2X
		g1Y = g1Y - g2Y
		dist = (g1X*g1X) + (g1Y*g1Y)

		--nw WriteLnToConsole("Calcs done. Dist to CurrentHedgehog is " .. dist)

		-- calculate my real radius if I am an aura
		if vCircType[i] == 0 then
			NR = vCircRadius[i]
		else
			NR = (48/100*vCircRadius[i])/2
		end

		if dist <= NR*NR then

			if 	(vCircActive[i] == true) and
				((vType[i] == "ammo") or (vType[i] == "bonus") )
			then

				CircleDamaged(i)

			elseif (vCircActive[i] == true) and
					( (vType[i] == "drone") or (vType[i] == "blueboss") )
			then

				ss = CircleDamaged(i)
				local explosion
				if vType[i] == "blueboss" then explosion = true else explosion = false end
				WellHeAintGonnaJumpNoMore(GetX(CurrentHedgehog),GetY(CurrentHedgehog),explosion)

				if ss == "fatal" then

					if (wepAmmo[0] == 0) and (TimeLeft <= 9) then
						AddCaption(loc("Kamikaze Expert! +15 points!"),0xffba00ff,capgrpMessage)
						AwardPoints(15)
						PlaySound(sndKamikaze, CurrentHedgehog)
					elseif (wepAmmo[0] == 0) then
						AddCaption(loc("Depleted Kamikaze! +5 points!"),0xffba00ff,capgrpMessage)
						AwardPoints(5)
						PlaySound(sndKamikaze, CurrentHedgehog)
					elseif TimeLeft <= 9 then
						AddCaption(loc("Timed Kamikaze! +10 points!"),0xffba00ff,capgrpMessage)
						AwardPoints(10)
						PlaySound(sndKamikaze, CurrentHedgehog)
					end
				end

			end


		end

	end

	--nw WriteLnToConsole("End of CheckDistances()")

end

function HandleCircles()

	if rAlpha ~= 255 then

		rPingTimer = rPingTimer + 1
		if rPingTimer == 100 then
			rPingTimer = 0

			rAlpha = rAlpha + 5
			if rAlpha >= 255 then
				rAlpha = 255
			end
		end

	end

	for i = 0,(vCCount-1) do

		SetVisualGearValues(rCirc[i], rCircX[i], rCircY[i], 100, 255, 1, 10, 0, 40, 3, vCircCol[i]-rAlpha)

		vCounter[i] = vCounter[i] + 1
		if vCounter[i] >= vCounterLim[i] then

			vCounter[i] = 0

			if 	((vType[i] == "drone") or (vType[i] == "blueboss") ) and
				(vCircActive[i] == true) then
				AddGear(vCircX[i], vCircY[i], gtShell, 0, 0, 0, 1)

			end

		end

		if (vCircActive[i] == true) then

			vCircRadCounter[i] = vCircRadCounter[i] + 1
			if vCircRadCounter[i] == 100 then

				vCircRadCounter[i] = 0

				-- make my radius increase/decrease faster if I am an aura
				if vCircType[i] == 0 then
					M = 1
				else
					M = 10
				end

				vCircRadius[i] = vCircRadius[i] + vCircRadDir[i]
				if vCircRadius[i] > vCircRadMax[i] then
					vCircRadDir[i] = -M
				elseif vCircRadius[i] < vCircRadMin[i] then
					vCircRadDir[i] = M
				end


				-- random effect test
				-- maybe use this to tell the difference between circs
				-- you can kill by shooting or not
				--vgtSmoke vgtSmokeWhite
				--vgtSteam -- nice long trail
				--vgtDust -- short trail on earthrise
				--vgtSmokeTrace
				if vType[i] == "ammo" then

					tempE = AddVisualGear(vCircX[i], vCircY[i], vgtSmoke, 0, true)
					g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
					SetVisualGearValues(tempE, vCircX[i], vCircY[i], g3, g4, g5, g6, g7, g8, g9, vCircCol[i] )

				elseif vType[i] == "bonus" then

					tempE = AddVisualGear(vCircX[i], vCircY[i], vgtDust, 0, true)
					g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
					SetVisualGearValues(tempE, vCircX[i], vCircY[i], g3, g4, g5, g6, g7, 1, g9, 0xff00ffff )


				elseif vType[i] == "blueboss" then

					k = 25
					g = vgtSteam
					trailColour = 0xae00ffff

					-- 0xffae00ff -- orange
					-- 0xae00ffff -- purp

					tempE = AddVisualGear(vCircX[i], vCircY[i], g, 0, true)
					g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
					SetVisualGearValues(tempE, vCircX[i], vCircY[i]+k, g3, g4, g5, g6, g7, g8, g9, trailColour-75 )

					tempE = AddVisualGear(vCircX[i], vCircY[i], g, 0, true)
					g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
					SetVisualGearValues(tempE, vCircX[i]+k, vCircY[i]-k, g3, g4, g5, g6, g7, g8, g9, trailColour-75 )

					tempE = AddVisualGear(vCircX[i], vCircY[i], g, 0, true)
					g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
					SetVisualGearValues(tempE, vCircX[i]-k, vCircY[i]-k, g3, g4, g5, g6, g7, g8, g9, trailColour-75 )


				end


			end

		end


	end

	-- alter the circles velocities
	circAdjustTimer = circAdjustTimer + 1
	if circAdjustTimer == 2000 then

		circAdjustTimer = 0

		for i = 0,(vCCount-1) do

			-- bounce the circles off the edges if they go too far
			-- or make them move in random directions

			if vCircX[i] > 5500 then
				vCircDX[i] = -5	--5 circmovchange
			elseif vCircX[i] < -1500 then
				vCircDX[i] = 5	--5 circmovchange
			else

				z = GetRandom(2)
				if z == 1 then
					z = 1
				else
					z = -1
				end
				vCircDX[i] = vCircDX[i] + GetRandom(3)*z	--3 circmovchange
			end

			if vCircY[i] > 1500 then
				vCircDY[i] = -5	--5 circmovchange
			elseif vCircY[i] < -2900 then
				vCircDY[i] = 5	--5 circmovchange
			else
				z = GetRandom(2)
				if z == 1 then
					z = 1
				else
					z = -1
				end
				vCircDY[i] = vCircDY[i] + GetRandom(3)*z	--3 circmovchange
			end

		end

	end

	-- move the circles according to their current velocities
	m2Count = m2Count + 1
	if m2Count == 25 then	--25 circmovchange

		m2Count = 0
		for i = 0,(vCCount-1) do
			vCircX[i] = vCircX[i] + vCircDX[i]
			vCircY[i] = vCircY[i] + vCircDY[i]

			if (CurrentHedgehog ~= nil) and (rAlpha ~= 255) then
				DoHorribleThings(i)
			end

		end

		if (TimeLeft == 0) and (tumbleStarted == true) then

			FadeAlpha = FadeAlpha + 1
			if FadeAlpha >= 255 then
				FadeAlpha = 255
			end

		end


		-- derp
		if shockwaveHealth > 0 then
			shockwaveHealth = shockwaveHealth - 1
			shockwaveRad = shockwaveRad + 80
		end

	end

	for i = 0,(vCCount-1) do
		g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(vCirc[i])
		SetVisualGearValues(vCirc[i], vCircX[i], vCircY[i], g3, g4, g5, g6, g7, vCircRadius[i], g9, g10)
	end

	if 	(TimeLeft == 0) or
		((tumbleStarted == false)) then
		for i = 0,(vCCount-1) do
			g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(vCirc[i])
			SetVisualGearValues(vCirc[i], vCircX[i], vCircY[i], g3, g4, g5, g6, g7, vCircRadius[i], g9, (vCircCol[i]-FadeAlpha))
		end
	end


	if (CurrentHedgehog ~= nil) then
		if beam == true then
			g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(pShield)
			SetVisualGearValues(pShield, GetX(CurrentHedgehog), GetY(CurrentHedgehog), g3, g4, g5, g6, g7, 200, g9, 0xa800ffff-0x000000ff - -shieldHealth )
			DrawTag(2)
		else
			SetVisualGearValues(pShield, GetX(CurrentHedgehog), GetY(CurrentHedgehog), g3, g4, g5, g6, g7, 0, g9, g10 )
		end

		if shockwaveHealth > 0 then
			g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(shockwave)
			SetVisualGearValues(shockwave, GetX(CurrentHedgehog), GetY(CurrentHedgehog), g3, g4, g5, g6, g7, shockwaveRad, g9, 0xff3300ff-0x000000ff - -shockwaveHealth )
		else
			SetVisualGearValues(shockwave, GetX(CurrentHedgehog), GetY(CurrentHedgehog), g3, g4, g5, g6, g7, 0, g9, g10 )
		end

	end


end

function ProjectileTrack(gear)

	if (GetGearType(gear) == gtShell) then

		--nw WriteLnToConsole("ProjectileTrack() for Shell ID: " .. getGearValue(gear,"ID"))

		if (GetGearType(gear) == gtShell) then
			turningSpeed = 0.1*fMod
		end

		dx, dy = GetGearVelocity(gear)

		--WriteLnToConsole("I'm trying to track currenthedge with shell ID: " .. getGearValue(gear,"ID"))
		--WriteLnToConsole("I just got the velocity of the shell. It is dx: " .. dx .. "; dy: " .. dy)
		--WriteLnToConsole("CurrentHedgehog is at X: " .. GetX(CurrentHedgehog) .. "; Y: " .. GetY(CurrentHedgehog) )

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


		if (GetGearType(gear) == gtShell) then
			dxlimit = 0.4*fMod
			dylimit = 0.4*fMod
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

		SetGearVelocity(gear, dx, dy)

		--WriteLnToConsole("I just SET the velocity of shell towards currenthegdge. It is now dx: " .. dx .. "; dy: " .. dy)
		--WriteLnToConsole("The above events occured game Time: " .. GameTime .. "; luaTicks: " .. luaGameTicks)
		--nw WriteLnToConsole("ProjectileTrack() finished successfully")

	end

end


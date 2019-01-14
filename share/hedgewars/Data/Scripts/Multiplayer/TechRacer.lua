--------------
-- TECH RACER
--------------

-- DEVELOPER WARNING - FOR OFFICIAL DEVELOPMENT --
-- Be careful when editig this script, do not introduce changes lightly!
-- This script is used for time records on the official Hedgewars server.
-- Introducing breaking changes means we have to invalidate past time records!

--------------
-- TO DO
--------------
-- allow scrolling of maps (was going to add this in the engine itself, but it can be done now by refreshing preview)

-----------------------------
-- SCRIPT BEGINS
-----------------------------

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/OfficialChallenges.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Scripts/TechMaps.lua")

------------------
-- Got Variables?
------------------

local atkArray = {
	{amBazooka, 	"amBazooka",		0},
	{amBee, 	"amBee",		0},
	{amMortar, 	"amMortar",		0},
	{amDrill, 	"amDrill",		0},
	{amSnowball, 	"amSnowball",		0},
	{amGrenade,	"amGrenade",		0},
	{amClusterBomb,	"amClusterBomb",	0},
	{amMolotov, 	"amMolotov",		0},
	{amWatermelon, 	"amWatermelon",		0},
	{amHellishBomb,	"amHellishBomb",	0},
	{amGasBomb, 	"amGasBomb",		0},

	{amShotgun,	"amShotgun",		0},
	{amDEagle,	"amDEagle",		0},
	{amFlamethrower,"amFlamethrower",	0},
	{amSniperRifle,	"amSniperRifle",	0},
	{amSineGun, 	"amSineGun",		0},
	{amIceGun, 	"amIceGun",		0},
	{amLandGun,	"amLandGun",		0},

	{amFirePunch, 	"amFirePunch",		0},
	{amWhip,	"amWhip",		0},
	{amBaseballBat, "amBaseballBat",	0},
	{amKamikaze, 	"amKamikaze",		0},
	{amSeduction, 	"amSeduction",		0},
	{amHammer,	"amHammer",		0},

	{amMine, 	"amMine",		0},
	{amDynamite, 	"amDynamite",		0},
	{amCake, 	"amCake",		0},
	{amBallgun, 	"amBallgun",		0},
	{amRCPlane,	"amRCPlane",		0},
	{amSMine,	"amSMine",		0},
	{amAirMine,	"amAirMine",		0},

	{amAirAttack,	"amAirAttack",		0},
	{amMineStrike,	"amMineStrike",		0},
	{amDrillStrike,	"amDrillStrike",	0},
	{amAirMine,	"amAirMine",		0},
	{amNapalm, 	"amNapalm",		0},
	{amPiano,	"amPiano",		0},

	{amKnife,	"amKnife",		0},

	{amBirdy,	"amBirdy",		0}
}

local utilArray = {
	{amBlowTorch, 	"amBlowTorch",		0},
	{amPickHammer,	"amPickHammer",		0},
	{amGirder, 	"amGirder",		0},
	{amRubber, 	"amRubber",		0},
	{amPortalGun,	"amPortalGun",		0},

	{amRope, 	"amRope",		0},
	{amParachute, 	"amParachute",		0},
	{amTeleport,	"amTeleport",		0},
	{amJetpack,	"amJetpack",		0},

	{amInvulnerable,"amInvulnerable",	0},
	{amLaserSight,	"amLaserSight",		0},
	{amVampiric,	"amVampiric",		0},

	{amLowGravity, 	"amLowGravity",		0},
	{amExtraDamage, "amExtraDamage",	0},
	{amExtraTime,	"amExtraTime",		0},

	{amResurrector, "amResurrector",	0},
	{amTardis, 	"amTardis",		0},

	{amSwitch,	"amSwitch",		0}
}

local activationStage = 0
local jet = nil
portalDistance = 5000
ufoFuel = 0
local roundLimit = 3
local roundNumber = 0
local firstClan = 10

local fastX = {}
local fastY = {}
local fastCount = 0
local fastIndex = 0
local fastColour = 0xffffffff

local currX = {}
local currY = {}
local currCount = 0

local specialPointsX = {}
local specialPointsY = {}
local specialPointsFlag = {}
local specialPointsCount = 0

mapID = nil

--------------------------
-- hog and team tracking variales
--------------------------

local numhhs = 0 -- store number of hedgehogs
local hhs = {} -- store hedgehog gears

local numTeams --  store the number of teams in the game
local teamNameArr = {}  -- store the list of teams
local teamClan = {}
local teamSize = {}     -- store how many hogs per team
local teamIndex = {} -- at what point in the hhs{} does each team begin

local teamComment = {}
local teamScore = {}

-------
-- racer vars
--------

local cGear = nil
local cameraGear = nil

local bestClan = 10
local bestTime = MAX_TURN_TIME

local gameBegun = false
local gameOver = false
local racerActive = false
local trackTime = 0

local wpCirc = {}
local wpX = {}
local wpY = {}
local wpCol = {}
local wpActive = {}
local wpRad = 450
local wpCount = 0
local wpLimit = 20

local usedWeapons = {}

local roundN
local lastRound
local RoundHasChanged

local cnthhs = 0

-------------------
-- general methods
-------------------

function RebuildTeamInfo()

	-- make a list of individual team names
	for i = 0, (TeamsCount-1) do
		teamNameArr[i] = " " -- = i
		teamSize[i] = 0
		teamIndex[i] = 0
		teamScore[i] = MAX_TURN_TIME
	end
	numTeams = 0

	for i = 0, (numhhs-1) do

		local z = 0
		local unfinished = true
		while(unfinished == true) do

			local newTeam = true
			local tempHogTeamName = GetHogTeamName(hhs[i]) -- this is the new name

			if tempHogTeamName == teamNameArr[z] then
				newTeam = false
				unfinished = false
			end

			z = z + 1

			if z == TeamsCount then
				unfinished = false
				if newTeam == true then
					teamNameArr[numTeams] = tempHogTeamName
					numTeams = numTeams + 1
				end
			end

		end

	end

	-- find out how many hogs per team, and the index of the first hog in hhs
	for i = 0, (numTeams-1) do
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


-----------------
-- RACER METHODS
-----------------

-- Returns min opacity, max opacity and flashing speed (`FrameTicks`)
-- for the waypoint visual gears
function FlashingHelper(wpIndex)
	local minO, maxO, flashing
	if wpIndex == 0 then
		-- Notable flashing of first waypoint
		minO, maxO = 92, 255
		flashing = 2
	else
		-- Slow pulsation
		minO, maxO = 164, 224
		flashing = 10
	end
	return minO, maxO, flashing
end

function CheckWaypoints()

	trackFinished = true

	for i = 0, (wpCount-1) do

		local g1X, g1Y = GetGearPosition(CurrentHedgehog)
		local g2X, g2Y = wpX[i], wpY[i]

		local g1X = g1X - g2X
		local g1Y = g1Y - g2Y
		local dist = (g1X*g1X) + (g1Y*g1Y)

		local NR = (48/100*wpRad)/2

		if dist < (NR*NR) and not gameOver then
			wpCol[i] = GetClanColor(GetHogClan(CurrentHedgehog))
			SetVisualGearValues(wpCirc[i], wpX[i], wpY[i], 64, 64, 1, 10, 0, wpRad, 5, wpCol[i])

			local wpRem = 0
			for k = 0, (wpCount-1) do
				if wpActive[k] == false then
					wpRem = wpRem + 1
				end
			end

			if not wpActive[i] then
				local wpMessage = ""
				if wpRem-1 == 0 then
					wpMessage = loc("Track completed!")
				else
					wpMessage = string.format(loc("Waypoints remaining: %d"), wpRem-1)
				end
				AddCaption(wpMessage, 0xffba00ff, capgrpGameState)
			end

			wpActive[i] = true

		end

		if wpActive[i] == false then
			trackFinished = false
		end

	end

	return(trackFinished)

end

function AdjustScores()

	local bestTimeComment = loc("Did not finish")

	local newScore = false

	-- update this clan's time if the new track is better
	for i = 0, (numTeams-1) do
		if teamClan[i] == GetHogClan(CurrentHedgehog) then
			if trackTime < teamScore[i] then
				teamScore[i] = trackTime
				newScore = true
			else
				newScore = false
			end
		end
	end

	-- find the best time out of those so far
	for i = 0, (numTeams-1) do
		if teamScore[i] < bestTime then
			bestTime = teamScore[i]
			bestClan = teamClan[i]
		end
	end

	if bestTime ~= MAX_TURN_TIME then
		bestTimeComment = string.format(loc("%.1fs"), (bestTime/1000))
	end

	if newScore == true then
		if trackTime == bestTime then -- best time of the race
			ShowMission(loc("TechRacer"),
			loc("Track completed!"),
			string.format(loc("New race record: %.1fs"), (trackTime/1000)) .. "|" ..
			string.format(loc("Winning time: %s"), bestTimeComment), 0, 4000)
			PlaySound(sndHomerun)
		else    -- best time for the clan
			ShowMission(loc("TechRacer"),
			loc("Track completed!"),
			string.format(loc("New clan record: %.1fs"), (trackTime/1000)) .. "|" ..
			string.format(loc("Winning time: %s"), bestTimeComment), 4, 4000)
		end
	else -- not any kind of new score
		ShowMission(loc("TechRacer"),
			loc("Track completed!"),
			string.format(loc("Time: %.1fs"), (trackTime/1000)) .. "|" ..
			string.format(loc("Winning time: %s"), bestTimeComment), -amSkip, 4000)
		PlaySound(sndHellish)
	end

	for i = 0, (TeamsCount-1) do
		if teamNameArr[i] ~= " " and teamScore[i] ~= MAX_TURN_TIME then
			SetTeamLabel(teamNameArr[i], string.format(loc("%.1fs"), teamScore[i]/1000))
		end
	end

	if bestTime == trackTime then
		fastColour = GetClanColor(GetHogClan(CurrentHedgehog))

		for i = 0, (currCount-1) do
			fastX[i] = currX[i]
			fastY[i] = currY[i]
		end

		fastCount = currCount
		fastIndex = 0

	else
		currCount = 0
		fastIndex = 0
	end


end

function onNewRound()

	roundNumber = roundNumber + 1

	local totalComment = ""
	for i = 0, (TeamsCount-1) do
		if teamNameArr[i] ~= " " then
			if teamScore[i] ~= MAX_TURN_TIME then
				teamComment[i] = string.format(loc("%s: %.1fs"), teamNameArr[i], (teamScore[i]/1000)) .. "|"
			else
				teamComment[i] = string.format(loc("%s: Did not finish"), teamNameArr[i]) .. "|"
			end
			totalComment = totalComment .. teamComment[i]
		elseif teamNameArr[i] == " " then
			teamComment[i] = "|"
		end
	end

	ShowMission(loc("TechRacer"),
		loc("Status update"),
		string.format(loc("Rounds complete: %d/%d"), roundNumber, roundLimit) .. "| |" ..
		loc("Best team times: ") .. "|" ..
		totalComment,
		0, 4000)

	-- end game if its at round limit
	if roundNumber >= roundLimit then
		-- Sort the scores for the ranking list
		local unfinishedArray = {}
		local sortedTeams = {}
		local k = 1
		local c = 1
		local clanScores = {}
		local previousClan
		for i = 0, TeamsCount-1 do
			local clan = GetTeamClan(teamNameArr[i])
			if not clanScores[clan+1] then
				clanScores[clan+1] = {}
				clanScores[clan+1].index = clan
				clanScores[clan+1].score = teamScore[i]
			end
			if teamScore[i] ~= MAX_TURN_TIME and teamNameArr[i] ~= " " then
				sortedTeams[k] = {}
				sortedTeams[k].name = teamNameArr[i]
				sortedTeams[k].score = teamScore[i]
				sortedTeams[k].clan = clan
				k = k + 1
			else
				table.insert(unfinishedArray, string.format(loc("%s did not finish the race."), teamNameArr[i]))
			end
		end
		table.sort(sortedTeams, function(team1, team2)
			if team1.score == team2.score then
				return team1.clan < team2.clan
			else
				return team1.score < team2.score
			end
		end)
		table.sort(clanScores, function(clan1, clan2) return clan1.score < clan2.score end)
		local rank = 0
		local rankPlus = 0
		local prevScore
		local clanRanks = {}
		for c = 1, #clanScores do
			rankPlus = rankPlus + 1
			if clanScores[c].score ~= prevScore then
				rank = rank + rankPlus
				rankPlus = 0
			end
			prevScore = clanScores[c].score
			clanRanks[clanScores[c].index] = rank
		end

		-- Write all the stats!
		for i = 1, #sortedTeams do
			SendStat(siPointType, "!TIME")
			SendStat(siTeamRank, tostring(clanRanks[GetTeamClan(sortedTeams[i].name)]))
			SendStat(siPlayerKills, sortedTeams[i].score, sortedTeams[i].name)
		end

		local roundDraw = false
		if #clanScores >= 2 and clanScores[1].score == clanScores[2].score and clanScores[1].score ~= MAX_TURN_TIME then
			roundDraw = true
			SendStat(siGameResult, loc("Round draw"))
			SendStat(siCustomAchievement, loc("The teams are tied for the fastest time."))
		elseif #sortedTeams >= 1 then
			SendStat(siGameResult, string.format(loc("%s wins!"), sortedTeams[1].name))
			SendStat(siCustomAchievement, string.format(loc("%s wins with a best time of %.1fs."), sortedTeams[1].name, (sortedTeams[1].score/1000)))
			for i=1,#unfinishedArray do
				 SendStat(siCustomAchievement, unfinishedArray[i])
			end
		else
			roundDraw = true
			SendStat(siGameResult, loc("Round draw"))
			SendStat(siCustomAchievement, loc("Nobody managed to finish the race. What a shame!"))
			SendStat(siCustomAchievement, loc("Maybe you should try an easier TechRacer map."))
		end

		-- Kill all the losers
		for i = 0, (numhhs-1) do
			if GetHogClan(hhs[i]) ~= bestClan or roundDraw then
				SetEffect(hhs[i], heResurrectable, 0)
				SetHealth(hhs[i],0)
			end
		end

		gameOver = true
		for i=0, wpCount-1 do
			 -- Fade out waypoints
			 SetVisualGearValues(wpCirc[i], nil, nil, 0, 0, nil, 6)
		end
		EndTurn(true)
	end

end

function CheckForNewRound()

	if GetHogClan(CurrentHedgehog) == firstClan then
		onNewRound()
	end

end

function DisableTumbler(endTurn)
	if endTurn == nil then endTurn = true end
	if racerActive then
		currCount = 0
		fastIndex = 0
		racerActive = false -- newadd
		if endTurn then
			 EndTurn(true)
		end
		if trackFinished and not gameOver then
			 for i=0, wpCount-1 do
		       		 SetVisualGearValues(wpCirc[i], nil, nil, 255, 255, nil, 2)
			 end
		elseif not gameOver then
			 for i=0, wpCount-1 do
		       		 SetVisualGearValues(wpCirc[i], nil, nil, 32, 32, nil, 1)
			 end
		end
	end
end

function HandleGhost()

	-- get the current xy of the racer at this point
	currX[currCount] = GetX(CurrentHedgehog)
	currY[currCount] = GetY(CurrentHedgehog)
	currCount = currCount + 1

	-- draw a ping of smoke where the fastest player was at this point
	if (fastCount ~= 0) and (fastIndex < fastCount) then

		fastIndex = fastIndex + 1

		local tempE = AddVisualGear(fastX[fastIndex], fastY[fastIndex], vgtSmoke, 0, false)
		SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, nil, fastColour )

	end

end

function BoomGirder(x,y,rot)
	local girTime = 1
	if rot < 4 then
		AddGear(x, y, gtGrenade, 0, 0, 0, girTime)
	elseif rot == 4 then
		AddGear(x-45, y, gtGrenade, 0, 0, 0, girTime) -- needed?
		AddGear(x-30, y, gtGrenade, 0, 0, 0, girTime)
		AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
		AddGear(x+30, y, gtGrenade, 0, 0, 0, girTime)
		AddGear(x+45, y, gtGrenade, 0, 0, 0, girTime) -- needed?
	elseif rot == 5 then ------- diag
		AddGear(x+45, y+45, gtGrenade, 0, 0, 0, girTime) --n
		AddGear(x+30, y+30, gtGrenade, 0, 0, 0, girTime)
		AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
		AddGear(x-30, y-30, gtGrenade, 0, 0, 0, girTime)
		AddGear(x-45, y-45, gtGrenade, 0, 0, 0, girTime) --n
	elseif rot == 6 then
		AddGear(x, y-45, gtGrenade, 0, 0, 0, girTime) -- needed?
		AddGear(x, y+30, gtGrenade, 0, 0, 0, girTime)
		AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
		AddGear(x, y-30, gtGrenade, 0, 0, 0, girTime)
		AddGear(x, y+45, gtGrenade, 0, 0, 0, girTime) -- needed?
	elseif rot == 7 then -------
		AddGear(x+45, y-45, gtGrenade, 0, 0, 0, girTime) --n
		AddGear(x+30, y-30, gtGrenade, 0, 0, 0, girTime)
		AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
		AddGear(x-30, y+30, gtGrenade, 0, 0, 0, girTime)
		AddGear(x-45, y+45, gtGrenade, 0, 0, 0, girTime) --n
	end
end

function RemoveGear(gear)
	if (isATrackedGear(gear) == true) and (GetGearType(gear) ~= gtHedgehog) then
		DeleteGear(gear)
	end
end

function ClearMap()
	runOnGears(RemoveGear)
end

function CallBob(x,y)
	if not racerActive and not gameOver then
		if wpCount == 0 or wpX[wpCount - 1] ~= x or wpY[wpCount - 1] ~= y then

			wpX[wpCount] = x
			wpY[wpCount] = y
			wpCol[wpCount] = 0xffffffff
			wpCirc[wpCount] = AddVisualGear(wpX[wpCount],wpY[wpCount],vgtCircle,0,true)

			local minO, maxO, flashing = FlashingHelper(wpCount)
			-- Make first waypoint flash very noticably before the hog starts racing
			SetVisualGearValues(wpCirc[wpCount], wpX[wpCount], wpY[wpCount], minO, maxO, 1, flashing, 0, wpRad, 5, wpCol[wpCount])

			wpCount = wpCount + 1
		end
	end
end



function HandleFreshMapCreation()

	if activationStage ~= 1 then
		return
	end

	-- the boom stage, boom girders, reset ammo, and delete other map objects
	ClearMap()

	-- the creation stage, place girders and needed gears, grant ammo
	InterpretPoints()

	-- these are from onParameters()
	if (mapID == nil) or (mapID == 0) then
		LoadMap(2000)
	else
		LoadMap(mapID)
	end

	if gameOver then
		for i = 0,(wpCount-1) do
			SetVisualGearValues(wpCirc[wpCount], wpX[wpCount], wpY[wpCount], 164, 224, 1, 10, 0, wpRad, 5, wpCol[wpCount])
		end

	else
		for i = 0,(wpCount-1) do
			DeleteVisualGear(wpCirc[i])
		end
		wpCount = 0

		for i = 1, techCount-1 do
			CallBob(techX[i],techY[i])
		end
	end

	if ufoFuel == 2000 then
		SetAmmoDescriptionAppendix(amJetpack, loc("On this map you get infinite fuel."))
	elseif ufoFuel ~= nil and ufoFuel ~= 0 then
		SetAmmoDescriptionAppendix(amJetpack, string.format(loc("On this map you get %d%% fuel."), div(ufoFuel, 20)))
	end

	activationStage = 200

end

function TryRepositionHogs()

	if MapHasBorder() == true then

		for i = 0, (numhhs-1) do
			if hhs[i] ~= nil then
				SetGearPosition(hhs[i],GetX(hhs[i]), TopY-10)
			end
		end

	end

end

----------------------------------
-- GAME METHODS / EVENT HANDLERS
----------------------------------

function onParameters()

	parseParams()
	mapID = tonumber(params["m"])

	roundLimit = tonumber(params["rounds"])

	if (roundLimit == 0) or (roundLimit == nil) then
		roundLimit = 3
	end

	if mapID == nil then
		mapID = 2 + GetRandom(7)
	end

end

function onGameInit()

	TemplateFilter = 0

	if MapGen == mgDrawn then
		eraseMap(false)
	else
		MapGen = mgDrawn
	end
	MapFeatureSize = 12

	if mapID == nil then
		mapID = 2 + GetRandom(7)
	end

	addHashData(mapID)

	Theme = "Cave"
	Map = ""

	EnableGameFlags(gfInfAttack, gfDisableWind, gfBorder)
	DisableGameFlags(gfSolidLand)
	CaseFreq = 0
	TurnTime = 90000
	WaterRise = 0
	HealthDecrease = 0

	for x = 1, 16 do
		AddPoint(x*100,100,5)
	end

	FlushPoints()

end

function limitHogs(gear)

	cnthhs = cnthhs + 1
	if cnthhs > 1 then
		DeleteGear(gear)
	end

end

function onSpecialPoint(x,y,flag)
	if flag == 99 then
		fastX[fastCount] = x
		fastY[fastCount] = y
		fastCount = fastCount + 1
	elseif flag == 0 then
		techX[techCount], techY[techCount] = x, y
		techCount = techCount + 1
	else
		addHashData(x)
		addHashData(y)
		addHashData(flag)
		specialPointsX[specialPointsCount] = x
		specialPointsY[specialPointsCount] = y
		specialPointsFlag[specialPointsCount] = flag
		specialPointsCount = specialPointsCount + 1
	end
end

function InterpretPoints()

	-- flags run from 0 to 127
	for i = 0, (specialPointsCount-1) do

		-- Mines
		if specialPointsFlag[i] == 1 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 1)
		elseif specialPointsFlag[i] == 2 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 1000)
		elseif specialPointsFlag[i] == 3 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 2000)
		elseif specialPointsFlag[i] == 4 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 3000)
		elseif specialPointsFlag[i] == 5 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 4000)
		elseif specialPointsFlag[i] == 6 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 5000)

		-- Sticky Mines
		elseif specialPointsFlag[i] == 7 then
			AddGear(specialPointsX[i], specialPointsY[i], gtSMine, 0, 0, 0, 0)

		-- Air Mines
		elseif specialPointsFlag[i] == 8 then
			AddGear(specialPointsX[i], specialPointsY[i], gtAirMine, 0, 0, 0, 0)

		-- Health Crates
		elseif specialPointsFlag[i] == 9 then
			SetHealth(SpawnHealthCrate(specialPointsX[i],specialPointsY[i]),25)
		elseif specialPointsFlag[i] == 10 then
			SetHealth(SpawnHealthCrate(specialPointsX[i],specialPointsY[i]),50)
		elseif specialPointsFlag[i] == 11 then
			SetHealth(SpawnHealthCrate(specialPointsX[i],specialPointsY[i]),75)
		elseif specialPointsFlag[i] == 12 then
			SetHealth(SpawnHealthCrate(specialPointsX[i],specialPointsY[i]),100)

		-- Cleaver
		elseif specialPointsFlag[i] == 13 then
			AddGear(specialPointsX[i], specialPointsY[i], gtKnife, 0, 0, 0, 0)

		-- Target
		elseif specialPointsFlag[i] == 14 then
			AddGear(specialPointsX[i], specialPointsY[i], gtTarget, 0, 0, 0, 0)

		--Barrels
		elseif specialPointsFlag[i] == 15 then
			SetHealth(AddGear(specialPointsX[i], specialPointsY[i], gtExplosives, 0, 0, 0, 0),1)
		elseif specialPointsFlag[i] == 16 then
			SetHealth(AddGear(specialPointsX[i], specialPointsY[i], gtExplosives, 0, 0, 0, 0),25)
		elseif specialPointsFlag[i] == 17 then
			SetHealth(AddGear(specialPointsX[i], specialPointsY[i], gtExplosives, 0, 0, 0, 0),50)
		elseif specialPointsFlag[i] == 18 then
			SetHealth(AddGear(specialPointsX[i], specialPointsY[i], gtExplosives, 0, 0, 0, 0),75)
		elseif specialPointsFlag[i] == 19 then
			SetHealth(AddGear(specialPointsX[i], specialPointsY[i], gtExplosives, 0, 0, 0, 0),100)

		-- There are about 58+- weps / utils
		-- Weapon Crates
		elseif (specialPointsFlag[i] >= 20) and (specialPointsFlag[i] < (#atkArray+20)) then
			SpawnAmmoCrate(specialPointsX[i],specialPointsY[i],atkArray[specialPointsFlag[i]-19][1])


		-- Utility Crates
		elseif (specialPointsFlag[i] >= (#atkArray+20)) and (specialPointsFlag[i] < (#atkArray+20+#utilArray)) then
			SpawnUtilityCrate(specialPointsX[i],specialPointsY[i],utilArray[specialPointsFlag[i]-19-#atkArray][1])

		--79-82 (reserved for future wep crates)
		--89,88,87,86 and 85,84,83,82 (reserved for the 2 custom sprites and their landflags)

		--90-99 reserved for scripted structures

		elseif specialPointsFlag[i] == 98 then
			portalDistance = specialPointsX[i]
			ufoFuel = specialPointsY[i]

		-- Normal Girders
		elseif specialPointsFlag[i] == 100 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 0, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 101 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 1, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 102 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 2, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 103 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 3, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 104 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 105 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 106 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 107 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)

		-- Invulnerable Girders
		elseif specialPointsFlag[i] == 108 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 0, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 109 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 1, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 110 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 2, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 111 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 3, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 112 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 113 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 114 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 6, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 115 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)

		-- Icy Girders
		elseif specialPointsFlag[i] == 116 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 0, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 117 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 1, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 118 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 2, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 119 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 3, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 120 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 4, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 121 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 5, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 121 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 6, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 123 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 7, 16448250, nil, nil, nil, lfIce)

		-- Rubber Bands
		elseif specialPointsFlag[i] == 124 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmRubber, 0, 4294967295, nil, nil, nil, lfBouncy)
		elseif specialPointsFlag[i] == 125 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmRubber, 1, 4294967295, nil, nil, nil, lfBouncy)
		elseif specialPointsFlag[i] == 126 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmRubber, 2, 4294967295, nil, nil, nil, lfBouncy)
		elseif specialPointsFlag[i] == 127 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmRubber, 3, 4294967295, nil, nil, nil, lfBouncy)

		-- Waypoints
		else -- 0 / no value
			CallBob(specialPointsX[i], specialPointsY[i])
		end

	end

end

function onGameStart()
	if ClansCount >= 2 then
		SendGameResultOff()
		SendRankingStatsOff()
		SendAchievementsStatsOff()
		SendHealthStatsOff()
	end

	trackTeams()

	roundN = 0
	lastRound = TotalRounds
	RoundHasChanged = false
	WriteLnToConsole("TechRacer: Using map #"..tostring(mapID-1).." (mapID="..tostring(mapID)..")")
	officialChallenge = detectMapWithDigest()

	RebuildTeamInfo()

	for i=0 , TeamsCount - 1 do
		cnthhs = 0
		runOnHogsInTeam(limitHogs, teamNameArr[i])
	end

	ShowMission(
		loc("TechRacer"),
		loc("A Hedgewars mini-game"),

		loc("Complete the track as fast as you can!") .. "|" ..
		loc("Round limit:") .. " " .. roundLimit .. "|" ..
		loc("You can further customize the race by changing the scheme script parameter.") .. "|",
		4, 4000
		)

	TryRepositionHogs()

	activationStage = 1
	HandleFreshMapCreation()

end



function onNewTurn()

	CheckForNewRound()
	TryRepositionHogs()

	racerActive = false

	activationStage = 1

	trackTime = 0

	currCount = 0 -- hopefully this solves problem

	-- Set the waypoints to unactive on new round
	if not gameOver then
		for i = 0,(wpCount-1) do
			wpActive[i] = false
			wpCol[i] = 0xffffffff
			local minO, maxO, flashing = FlashingHelper(i)
			SetVisualGearValues(wpCirc[i], wpX[i], wpY[i], minO, maxO, 1, flashing, 0, wpRad, 5, wpCol[i])
		end
	end

	-- Handle Starting Stage of Game
	if (gameOver == false) and (gameBegun == false) then
		gameBegun = true
		roundNumber = 0
		firstClan = GetHogClan(CurrentHedgehog)
	end

	if gameOver == true then
		gameBegun = false
		racerActive = false
	end

	AddAmmo(CurrentHedgehog, amTardis, 0)
	AddAmmo(CurrentHedgehog, amDrillStrike, 0)
	AddAmmo(CurrentHedgehog, amMineStrike, 0)
	AddAmmo(CurrentHedgehog, amNapalm, 0)
	AddAmmo(CurrentHedgehog, amPiano, 0)

end

function onGameTick20()

	if (jet ~= nil) and (ufoFuel ~= 0) then
		if ufoFuel == 2000 then
			SetHealth(jet, 2000)
		end
	end

	runOnGears(PortalEffects)

	-- airstrike detected, convert this into a potential waypoint spot
	if cGear ~= nil then
		local x,y = GetGearPosition(cGear)
		if x > -9000 then
			x,y = GetGearTarget(cGear)

			if TestRectForObstacle(x-20, y-20, x+20, y+20, true) then
				AddCaption(loc("Please place the waypoint in the air and within the map boundaries"))
				PlaySound(sndDenied)
			elseif (y > WaterLine-50) then
				AddCaption(loc("Please place the waypoint further away from the waterline"))
				PlaySound(sndDenied)
			else
				CallBob(x, y)
				if wpCount == wpLimit then
					AddCaption(loc("Race complexity limit reached"))
					DisableTumbler()
				end
			end
		else
			DeleteGear(cGear)
		end
		SetGearPosition(cGear, -10000, 0)
	end


	if activationStage < 200 then
		HandleFreshMapCreation()

		if not gameOver and gameBegun and not racerActive then
			if cameraGear then
				DeleteGear(cameraGear)
			end
			-- Move camera to first waypoint.
			-- We use a dummy gear to feed FollowGear. It does not affect the race.
			cameraGear = AddGear(wpX[0], wpY[0], gtGenericFaller, 0, 0, 0, 5000)
			SetState(cameraGear, bor(GetState(cameraGear), gstNoGravity+gstInvisible))
			FollowGear(cameraGear)
		end

	end


	-- start the player tumbling with a boom once their turn has actually begun
	if racerActive == false then

		if (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) then

			-- if the gamehas started put the player in the middle of the first
			-- waypoint that was placed
			if gameBegun == true then
				AddCaption(loc("Good to go!"))
				racerActive = true
				trackTime = 0


				SetGearPosition(CurrentHedgehog, wpX[0], wpY[0])
				SetGearMessage(CurrentHedgehog,gmLeft)

				FollowGear(CurrentHedgehog)

				HideMission()
				activationStage = 201
			end

		end

	elseif (activationStage == 201) and (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) then
		SetGearMessage(CurrentHedgehog,0)
		activationStage = 202
	end

	-- has the player started his tumbling spree?
	if (CurrentHedgehog ~= nil) then

		-- if the RACE has started, show tracktimes and keep tabs on waypoints
		if (racerActive == true) and (activationStage == 202) then

			--ghost
			if GameTime%40 == 0 then
				HandleGhost()
			end

			trackTime = trackTime + 20

			if GameTime%100 == 0 then

				AddCaption(string.format(loc("Time: %.1fs"), (trackTime/1000)), GetClanColor(GetHogClan(CurrentHedgehog)),capgrpMessage2)

				if (CheckWaypoints() == true) then
					AdjustScores()
					DisableTumbler()
				end

			end

			-- If hedgehog is not controlled anymore, stop racing mode
			if band(GetState(CurrentHedgehog), gstHHDriven) == 0 then
				DisableTumbler(false)
			end

		end

	end

end

-- handle short range portal gun
function PortalEffects(gear)

	if GetGearType(gear) == gtPortal then

		local tag = GetTag(gear)
		local col
		if tag == 0 then
			col = 0xfab02aFF -- orange ball
		elseif tag == 1 then
			col = 0x00FF00FF -- orange portal
		elseif tag == 2 then
			col = 0x364df7FF  -- blue ball
		elseif tag == 3 then
			col = 0xFFFF00FF  -- blue portal
		end

		if (tag == 0) or (tag == 2) then -- i.e ball form
			local remLife = getGearValue(gear,"life")
			remLife = remLife - 1
			setGearValue(gear, "life", remLife)

			-- Limited range portal ball dies
			if remLife == 0 then

				-- Make portal ball disappear in a puff of smoke
				local tempE = AddVisualGear(GetX(gear)+15, GetY(gear), vgtSmoke, 0, false)
				SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, nil, col)

				tempE = AddVisualGear(GetX(gear)-15, GetY(gear), vgtSmoke, 0, false)
				SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, nil, col)

				tempE = AddVisualGear(GetX(gear), GetY(gear)+15, vgtSmoke, 0, false)
				SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, nil, col)

				tempE = AddVisualGear(GetX(gear), GetY(gear)-15, vgtSmoke, 0, false)
				SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, nil, col)

				PlaySound(sndVaporize)
				DeleteGear(gear)

			end

		end

	end

end

function onGearResurrect(gear, vGear)

	if gear == CurrentHedgehog then
	       DisableTumbler(false)
	end
	if vGear then
		DeleteVisualGear(vGear)
	end

end

function isATrackedGear(gear)
	if 	(GetGearType(gear) == gtHedgehog) or
		(GetGearType(gear) == gtGrenade) or
		(GetGearType(gear) == gtTarget) or
		(GetGearType(gear) == gtFlame) or
		(GetGearType(gear) == gtExplosives) or
		(GetGearType(gear) == gtPortal) or
		(GetGearType(gear) == gtMine) or
		(GetGearType(gear) == gtSMine) or
		(GetGearType(gear) == gtAirMine) or
		(GetGearType(gear) == gtCase)
	then
		return(true)
	else
		return(false)
	end
end

function onGearAdd(gear)

       if isATrackedGear(gear) then
		trackGear(gear)

		if GetGearType(gear) == gtPortal then
			setGearValue(gear,"life",portalDistance)
		elseif GetGearType(gear) == gtHedgehog then
			hhs[numhhs] = gear
			numhhs = numhhs + 1
			SetEffect(gear, heResurrectable, 1)
		end

	end

	if GetGearType(gear) == gtAirAttack then
		cGear = gear
	elseif GetGearType(gear) == gtJetpack then
		jet = gear
		if (ufoFuel ~= 0) then
			SetHealth(jet, ufoFuel)
		end
	end


end

function onGearDelete(gear)

	if isATrackedGear(gear) then
		trackDeletion(gear)
	elseif GetGearType(gear) == gtAirAttack then
		cGear = nil
	elseif GetGearType(gear) == gtJetpack then
		jet = nil
	elseif gear == cameraGear then
		cameraGear = nil
	end

end

function onAttack()
	local at = GetCurAmmoType()

	usedWeapons[at] = 0
end

function onAchievementsDeclaration()
	usedWeapons[amSkip] = nil
	usedWeapons[amExtraTime] = nil

	local usedRope = usedWeapons[amRope] ~= nil
	local usedPortal = usedWeapons[amPortalGun] ~= nil
	local usedSaucer = usedWeapons[amJetpack] ~= nil

	usedWeapons[amRope] = nil
	usedWeapons[amPortalGun] = nil
	usedWeapons[amJetpack] = nil

	local usedOther = next(usedWeapons) ~= nil

	local raceType
	if usedOther then -- smth besides skip, rope, portal or saucer used
		raceType = "unknown race"
	elseif usedRope and not usedPortal and not usedSaucer then
		raceType = "rope race"
	elseif not usedRope and usedPortal and not usedSaucer then
		raceType = "portal race"
	elseif not usedRope and not usedPortal and usedSaucer then
		raceType = "saucer race"
	elseif (usedRope or usedPortal or usedSaucer or usedOther) == false then -- no weapons used at all?
		raceType = "no tools race"
	else -- at least two of rope, portal and saucer used
		raceType = "mixed race"
	end

	for i = 0, (numTeams-1) do
		if teamScore[i] < MAX_TURN_TIME then
			DeclareAchievement(raceType, teamNameArr[i], officialChallenge, teamScore[i])
		end
	end

	if officialChallenge ~= nil and fastCount > 0 then
		StartGhostPoints(fastCount)

		for i = 0, (fastCount - 1) do
			DumpPoint(fastX[i], fastY[i])
		end
	end

end

function onAmmoStoreInit()

	SetAmmo(amSkip, 9, 0, 0, 0)

	for i = 1, #atkArray do
		SetAmmo(atkArray[i][1], 0, 0, 0, 1)
	end

	for i = 1, #utilArray do
		SetAmmo(utilArray[i][1], 0, 0, 0, 1)
	end

end

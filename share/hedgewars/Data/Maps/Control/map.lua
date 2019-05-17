-------------
-- CONTROL --
-------------

-- Goal: Stand on pillars to score points over time.
-- First clan to hit the score limit wins!

-- Rules:
-- * Each pillar you control generates 1 point every 2 seconds.
-- * If multiple clans compete for a pillar, no one generates points for this pillar.
-- * If you skip turn, you win the same points as if you would have just waited out the turn
-- * Hogs get revived.

-----------------
-- script begins
-----------------

HedgewarsScriptLoad("/Scripts/Locale.lua")

---------------------------------------------------------------
-- lots variables and things
---------------------------------------------------------------

local TimeCounter = 0

local gameWon = false
local pointLimit = 300

local missionName = loc("Control")
local missionCaption = loc("Domination game")
local missionHelp

local vCirc = {}
local vCircCount = 0

--local hGCount = 0

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

--------------------------
-- hog and team tracking variales
--------------------------

local numhhs = 0 -- store number of hedgehogs
local hhs = {} -- store hedgehog gears

local numTeams --  store the number of teams in the game
local teamNameArr = {}	-- store the list of teams
local teamClan = {}
local teamSize = {}	-- store how many hogs per team
local teamIndex = {} -- at what point in the hhs{} does each team begin

local teamComment = {}
local teamScore = {}

--------------------------------
--zone and teleporter variables
--------------------------------

local cPoint = {}
local cOwnerClan = {}

local zXMin = {}
local zWidth = {}
local zYMin = {}
local zHeight = {}
local zOccupied = {}
local zCount = 0

------------------------
-- zone methods
------------------------
-- see on gameTick also

function CreateZone(xMin, yMin, width, height)


	zXMin[zCount] = xMin
	zYMin[zCount] = yMin
	zWidth[zCount] = width
	zHeight[zCount] = height
	zOccupied[zCount] = false
	zCount = zCount + 1

	return (zCount-1)

end

function GearIsInZone(gear, zI)

	if (GetX(gear) > zXMin[zI]) and (GetX(gear) < (zXMin[zI]+zWidth[zI])) and (GetY(gear) > zYMin[zI]) and (GetY(gear) < (zYMin[zI]+zHeight[zI])) then
		zOccupied[zI] = true
	else
		zOccupied[zI] = false
	end

	return zOccupied[zI]

end

function ZonesAreEmpty()

	okay = true

	for i = 0,(zCount-1) do

		for k = 0, (numhhs-1) do
			if (hhs[k] ~= nil) then
				if (GearIsInZone(hhs[k],i)) == true then
					FindPlace(hhs[k], false, 0, LAND_WIDTH, true)
					okay = false
				end
			end
		end
	end

	return(okay)

end

function CheckZones()

	for i = 0,(zCount-1) do
		SetVisualGearValues(vCirc[i], vCircX[i], vCircY[i], vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], 0xffffffff)
		cOwnerClan[i] = nil
		for k = 0, (numhhs-1) do
			if (hhs[k] ~= nil) then
				if (GearIsInZone(hhs[k],i)) == true then
					if cOwnerClan[i] ~= nil then
						if cOwnerClan[i] ~= GetHogClan(hhs[k]) then
							--if the hog now being compared is different to one that is also here and was previously compared
							SetVisualGearValues(vCirc[i], vCircX[i], vCircY[i], vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], 0xffffffff)

							cOwnerClan[i] = 10 -- this means conflicted
						end
					elseif cOwnerClan[i] == nil then
						cOwnerClan[i] = GetHogClan(hhs[k])
						SetVisualGearValues(vCirc[i], vCircX[i], vCircY[i], vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], GetClanColor( GetHogClan(hhs[k])))
					end

				end
			end
		end
	end

end

function AwardPoints()

	for i = 0,(zCount-1) do
		-- give score to all players controlling points

		-- only give score to the player currently in control
		if CurrentHedgehog ~= nil then
			if cOwnerClan[i] == GetHogClan(CurrentHedgehog) then
				teamScore[cOwnerClan[i]] = teamScore[cOwnerClan[i]] + 1
			end
		end
	end

	-- i want to show all the tags at once as having the SAME score not 1,2,3,4 so alas, repeating the loop seems needed
	for i = 0,(zCount-1) do
		if CurrentHedgehog ~= nil then
			if cOwnerClan[i] == GetHogClan(CurrentHedgehog) then
				local g = AddVisualGear(vCircX[i], vCircY[i]-100, vgtHealthTag, 100, false)
				SetVisualGearValues(g, vCircX[i], vCircY[i]-100, 0, 0, 0, 0, 0, teamScore[cOwnerClan[i]], 1500, GetClanColor(cOwnerClan[i]))
			end
		end
	end

	-- Update team labels and graph
	local clanGraphPointWritten = {}
	for i = 0,(TeamsCount-1) do
		if teamNameArr[i] ~= " " then
			SetTeamLabel(teamNameArr[i], teamScore[teamClan[i]])
			if not clanGraphPointWritten[teamClan[i]] then
				SendStat(siClanHealth, teamScore[teamClan[i]], teamNameArr[i])
				clanGraphPointWritten[teamClan[i]] = true
			end
		end
	end

end

-----------------
-- general methods
------------------

function RebuildTeamInfo()


	-- make a list of individual team names
	for i = 0, (TeamsCount-1) do
		teamNameArr[i] = " " -- = i
		teamSize[i] = 0
		teamIndex[i] = 0
		teamScore[i] = 0
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
		SetTeamLabel(GetTeamName(i), "0")
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

------------------------
-- game methods
------------------------

function onSkipTurn()

	if CurrentHedgehog ~= nil then
		z = (TurnTimeLeft / 2000) - (TurnTimeLeft / 2000)%2
		for i = 0, z do
			AwardPoints()
		end
	end

end

function onGameInit()

	-- Things we don't modify here will use their default values.

	EnableGameFlags(gfInfAttack, gfSolidLand)
	DisableGameFlags(gfKing, gfAISurvival)
	WaterRise = 0
	HealthDecrease = 0

	SendHealthStatsOff()
	SendRankingStatsOff()

end


function onGameStart()

	-- build zones
	cPoint[0] = CreateZone(571,47,120,80)
	cPoint[1] = CreateZone(1029,643,120,80)
	cPoint[2] = CreateZone(322,1524,120,80)
	cPoint[3] = CreateZone(1883,38,120,80)
	cPoint[4] = CreateZone(3821,46,120,80)
	cPoint[5] = CreateZone(2679,1338,120,80)

	vCircX[0], vCircY[0] = 631, 82
	vCircX[1], vCircY[1] = 1088, 684
	vCircX[2], vCircY[2] = 381, 1569
	vCircX[3], vCircY[3] = 1942, 77
	vCircX[4], vCircY[4] = 3883, 89
	vCircX[5], vCircY[5] = 2739, 1378

	for i = 0, 5 do
		vCirc[i] = AddVisualGear(0,0,vgtCircle,0,true)
		vCircMinA[i] = 20
		vCircMaxA[i] = 255
		vCircType[i] = 1
		vCircPulse[i] = 10
		vCircFuckAll[i] = 0
		vCircRadius[i] = 300
		vCircWidth[i] = 5
		vCircCol[i] = 0xffffffff

		SetVisualGearValues(vCirc[i], vCircX[i], vCircY[i], vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], vCircCol[i])
	end

	--new improved placement schematics aw yeah
	RebuildTeamInfo()

	for i = 0, (numTeams-1) do
		pointLimit = pointLimit - 25
	end

	missionHelp = loc("Control pillars to score points.") .. "|" ..
		loc("Hedgehogs will be revived after their death.") .. "|" ..
		string.format(loc("Score goal: %d"), pointLimit)

	-- reposition hogs if they are on control points until they are not or sanity limit kicks in
	reN = 0
	while (reN < 10) do
		if ZonesAreEmpty() == false then
			reN = reN + 1
		else
			reN = 15
		end
	end

	for h=1, numhhs do
		-- Tardis screws up the game too much, teams might not get killed correctly after victory
		-- if a hog is still in time-travel.
		-- This could be fixed, removing the Tardis is just a simple and lazy fix.
		AddAmmo(hhs[h], amTardis, 0)
		-- Resurrector is pointless, all hogs are already automatically resurrected.
		AddAmmo(hhs[h], amResurrector, 0)
	end

	ShowMission(missionName, missionCaption, missionHelp, 0, 0)

end


function onNewTurn()

	-- reset the time counter so that it will get set to TurnTimeLeft in onGameTick
	TimeCounter = 0

	if lastTeam ~= GetHogTeamName(CurrentHedgehog) then
		lastTeam = GetHogTeamName(CurrentHedgehog)
	end

	if gameWon == false then

		for i = 0, (numTeams-1) do
			if teamScore[i] >= pointLimit then --150
				gameWon = true
				winnerClan = i
			end
		end

		if gameWon == true then
			for i = 0, (numhhs-1) do
				if hhs[i] ~= nil then
					if GetHogClan(hhs[i]) ~= winnerClan then
						SetEffect(hhs[i], heResurrectable, 0)
						SetHealth(hhs[i],0)
					end
				end
			end
			EndTurn(true)

			-- Rankings
			local teamList = {}
			for i=0, TeamsCount-1 do
				local name = GetTeamName(i)
				local clan = GetTeamClan(name)
				table.insert(teamList, { score = teamScore[teamClan[i]], name = name, clan = clan })
			end
			local teamRank = function(a, b)
				return a.score > b.score
			end
			table.sort(teamList, teamRank)

			for i=1, #teamList do
				SendStat(siPointType, "!POINTS")
				SendStat(siPlayerKills, tostring(teamList[i].score), teamList[i].name)
			end
			SendStat(siGraphTitle, loc("Score graph"))

		end

	end

end

function onGameTick()

	vCircCount = vCircCount + 1
	if (vCircCount >= 500) and (gameWon == false) then
		vCircCount = 0
		CheckZones()
	end

	-- set TimeCounter to starting time if it is uninitialised (from onNewTurn)
	if (TimeCounter == 0) and (TurnTimeLeft > 0) then
		TimeCounter = TurnTimeLeft
	end

	-- has it ACTUALLY been 2 seconds since we last did this?
	if (TimeCounter - TurnTimeLeft) >= 2000 then
		TimeCounter = TurnTimeLeft

		if (gameWon == false) then
			AwardPoints()
		end
	end

end

function onHogAttack(ammoType)
	-- Update TimeCounter after using extra time
	if ammoTime == amExtraTime then
		if (TimeCounter == 0) and (TurnTimeLeft > 0) then
			TimeCounter = TurnTimeLeft
		end
		TimeCounter = TimeCounter + 30000
	end
end

function InABetterPlaceNow(gear)
	for i = 0, (numhhs-1) do
		if gear == hhs[i] then
			hhs[i] = nil
		end
	end
end

function onGearAdd(gear)

	if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		numhhs = numhhs + 1
		SetEffect(gear, heResurrectable, 1)
	end

end

function onGearDelete(gear)

	if GetGearType(gear) == gtHedgehog then
		InABetterPlaceNow(gear)
	end

end

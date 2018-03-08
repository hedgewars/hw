---------------------------------------
-- CAPTURE_THE_FLAG GAMEPLAY MODE 0.5
-- by mikade
---------------------------------------

---- Script parameter
-- With “captures=<number>” you can set your own capture limit, e.g. “captures=5” for 5 captures.

-- Version History
---------
-- 0.1
---------

-- [conversion from map-dependant CTF_Blizzard to map independant Capture the Flag]
-- added an intial starting stage where flagspawn is decided by the players (weapon set will require a jetpack unless I set)
-- changed the flag from a crate to a visual gear, and all associated methods and checks relating to flags (five hours later, lol)
-- changed starting/respawning positioning to accommodate different map sizes
-- added another circle to mark flag spawn
-- added gameFlag filter
-- changed scoring feedback
-- cleaned up some code

-- removing own flag from spawning point no longer possible
-- destroying flags no longer possible.
-- added basic glowing circle effect to spawn area
-- added expanding circle to fgear itself

-- removed teleporters
-- removed random crate drops (this should be decided by scheme)
-- removed set map criteria like minesNum, turnTime, explosives etc. except for sudden death
-- removed weapon defintions
-- removed placement and respawning methods, hopefully divideTeams will have this covered

---------
-- 0.2
---------

-- [now with user friendliness]
-- flag is now placed wherever you end up at the end of your first turn, this ensures that it is always placed by turn 3
-- removed a bunch of backup code and no-longer needed variables / methods from CTF_Blizzard days
-- removed an aura that was still mistakenly hanging about
-- added an in-game note about placements
-- added an in-game note about the rules of the game
-- added translation support and loc()'ed everything
-- changed things so the seed is no longer always the same...

-- In this version:
---------
-- 0.3
---------
-- [fufufufu kamikaze fix]
-- added nill checks to make sure the player doesn't generate errors by producing a nil value in hhs[] when he uses kamikaze
-- added a check to make sure the player doesn't kamikaze straight down and make the flag's starting point underwater
-- added a check to make sure the player drops the flag if he has it and he uses kamikaze

--------
-- 0.4
--------

-- remove user-branding and version numbers
-- removed some stuff that wasn't needed
-- fix piano strike exploit
-- changed delay to allow for better portals
-- changed starting feedback a little
-- increased the radius around the circle indicating the flag thief so that it doesn't obscure his health

--------
-- 0.5
--------

-- add support for more players
-- allow limited sudden death
-- stop TimeBox ruining my life
-- profit???

-----------------
--SCRIPT BEGINS
-----------------

-- enable awesome translaction support so we can use loc() wherever we want
HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

---------------------------------------------------------------
----------lots of bad variables and things
----------because someone is too lazy
----------to read about tables properly
------------------ "Oh well, they probably have the memory"

local gameStarted = false
local gameOver = false
local captureLimit = 3

--------------------------
-- hog and team tracking variales
--------------------------

local numhhs = 0 -- store number of hedgehogs
local hhs = {} -- store hedgehog gears

local teamSize = {}	-- store how many hogs per team
local teamIndex = {} -- at what point in the hhs{} does each team begin

-------------------
-- flag variables
-------------------

local fGear = {}	-- pointer to the visual gears that represent the flag
local fGearX = {}
local fGearY = {}

local fThief = {}	-- pointer to the hogs who stole the flags
local fThiefFlag = {}   -- contains the stolen flag type of fThief
local fIsMissing = {}	-- have the flags been destroyed or captured
local fNeedsRespawn = {}	-- do the flags need to be respawned
local fCaptures = {}	-- the team "scores" how many captures
local fSpawnX = {}		-- spawn X for flags
local fSpawnY = {}		-- spawn Y for flags

local fThiefX = {}
local fThiefY = {}

local fSpawnC = {} -- spawn circle marker
local fCirc = {} -- flag/carrier marker circles
local fCol = {} -- colour of the clans

local fGearRad = 0
local fGearRadMin = 5
local fGearRadMax = 33
local fGearTimer = 0

------------------------
--flag methods
------------------------

function CheckScore(clanID)

	if fCaptures[clanID] == captureLimit then
		gameOver = true
		-- Capture limit reached! We have a winner!
		for i = 0, (numhhs-1) do
			if hhs[i] ~= nil then
				-- Kill all losers
				if GetHogClan(hhs[i]) ~= clanID then
					SetEffect(hhs[i], heResurrectable, 0)
					SetHealth(hhs[i],0)
				end
			end
		end
		if CurrentHedgehog ~= nil then
			AddCaption(string.format(loc("Victory for %s!"), GetHogTeamName(CurrentHedgehog)), 0xFFFFFFFF, capgrpGameState)
			updateScores()
		end

		-- Calculate team rankings

		local teamList = {}
		for i=0, TeamsCount-1 do
			local name = GetTeamName(i)
			local clan = GetTeamClan(name)
			table.insert(teamList, { score = fCaptures[clan], name = name, clan = clan })
		end
		local teamRank = function(a, b)
			return a.score > b.score
		end
		table.sort(teamList, teamRank)

		for i=1, #teamList do
			SendStat(siPointType, loc("point(s)"))
			SendStat(siPlayerKills, tostring(teamList[i].score), teamList[i].name)
		end
	end

end

function DoFlagStuff(flag, flagClan)

	if not CurrentHedgehog then
		return
	end
	local wtf = flagClan

	local thiefClan
	for i=0, ClansCount - 1 do
		if CurrentHedgehog == fThief[i] then
			thiefClan = i
		end
	end

	-- player has successfully captured the enemy flag
	if (GetHogClan(CurrentHedgehog) == flagClan) and (thiefClan ~= nil) and (fIsMissing[flagClan] == false) then

		fIsMissing[thiefClan] = false
		fNeedsRespawn[thiefClan] = true
		fCaptures[flagClan] = fCaptures[flagClan] +1
		AddCaption(string.format(loc("%s has scored!"), GetHogName(CurrentHedgehog)), 0xFFFFFFFF, capgrpGameState)
		updateScores()
		PlaySound(sndHomerun)
		fThief[thiefClan] = nil -- player no longer has the enemy flag
		fThiefFlag[flagClan] = nil
		CheckScore(flagClan)

	--if the player is returning the flag
	elseif (GetHogClan(CurrentHedgehog) == flagClan) and (fIsMissing[flagClan] == true) then

		DeleteVisualGear(fGear[flagClan])
		fGear[flagClan] = nil -- the flag has now disappeared

		fNeedsRespawn[flagClan] = true
		HandleRespawns() -- this will set fIsMissing[flagClan] to false :)
		AddCaption(loc("Flag returned!"), 0xFFFFFFFF, capgrpMessage2)

	--if the player is taking the enemy flag (not possible if already holding a flag)
	elseif GetHogClan(CurrentHedgehog) ~= flagClan and (thiefClan == nil) then

		DeleteVisualGear(fGear[flagClan])
		fGear[flagClan] = nil -- the flag has now disappeared

		fIsMissing[flagClan] = true
		for i = 0,numhhs-1 do
			if CurrentHedgehog ~= nil then
				if CurrentHedgehog == hhs[i] then
					fThief[flagClan] = hhs[i]
					fThiefFlag[flagClan] = flagClan
				end
			end
		end
		AddCaption(loc("Flag captured!"), 0xFFFFFFFF, capgrpMessage2)

	end

end

function CheckFlagProximity()

	for i = 0, ClansCount-1 do
		if fGear[i] ~= nil then

			local g1X = fGearX[i]
			local g1Y = fGearY[i]

			local g2X, g2Y = GetGearPosition(CurrentHedgehog)

			local q = g1X - g2X
			local w = g1Y - g2Y
			local dist = (q*q) + (w*w)

			if dist < 500 then
				DoFlagStuff(fGear[i], i)
			end
		end
	end

end


function HandleRespawns()

	for i = 0, ClansCount-1 do

		if fNeedsRespawn[i] == true then
			fGear[i] = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)
			fGearX[i] = fSpawnX[i]
			fGearY[i] = fSpawnY[i]

			fNeedsRespawn[i] = false
			fIsMissing[i] = false -- new, this should solve problems of a respawned flag being "returned" when a player tries to score
			AddCaption(loc("Flag respawned!"), 0xFFFFFFFF, capgrpMessage2)
		end

	end

end

-- Advance the clan score graph by one step
function DrawScores()
	local clansUsed = {}
	for i=0, TeamsCount-1 do
		local team = GetTeamName(i)
		local clan = GetTeamClan(team)
		if not clansUsed[clan] then
			local captures = fCaptures[clan]
			SendStat(siClanHealth, captures, team)
			clansUsed[clan] = true
		end
	end
end

function FlagThiefDead(gear)

	local thiefClan
	local stolenFlagClan
	for i=0, ClansCount-1 do
		if (gear == fThief[i]) then
			thiefClan = i
			stolenFlagClan = fThiefFlag[i]
			break
		end
	end

	if stolenFlagClan ~= nil then
		-- falls into water
		if (LAND_HEIGHT - fThiefY[thiefClan]) < 15 then
			fIsMissing[stolenFlagClan] = true
			fNeedsRespawn[stolenFlagClan] = true
			HandleRespawns()
		else	--normally
			fGearX[stolenFlagClan] = fThiefX[thiefClan]
			fGearY[stolenFlagClan] = fThiefY[thiefClan]
			fGear[stolenFlagClan] = AddVisualGear(fGearX[stolenFlagClan], fGearY[stolenFlagClan], vgtCircle, 0, true)
		end

		AddVisualGear(fThiefX[thiefClan], fThiefY[thiefClan], vgtBigExplosion, 0, false)
		fThief[thiefClan] = nil
	end

end

function HandleCircles()

	fGearTimer = fGearTimer + 1
	if fGearTimer == 50 then
		fGearTimer = 0
		fGearRad = fGearRad + 1
		if fGearRad > fGearRadMax then
			fGearRad = fGearRadMin
		end
	end

	for i = 0, ClansCount-1 do

		if fIsMissing[i] == false then -- draw a flag marker at the flag's spawning place
			SetVisualGearValues(fCirc[i], fSpawnX[i],fSpawnY[i], 20, 20, 0, 10, 0, 33, 3, fCol[i])
			if fGear[i] ~= nil then -- draw the flag gear itself
				SetVisualGearValues(fGear[i], fSpawnX[i],fSpawnY[i], 20, 200, 0, 0, 100, fGearRad, 2, fCol[i])
			end
		elseif (fIsMissing[i] == true) and (fNeedsRespawn[i] == false) then
			if fThief[i] ~= nil then -- draw circle round flag carrier			-- 33
				SetVisualGearValues(fCirc[i], fThiefX[i], fThiefY[i], 20, 200, 0, 0, 100, 50, 3, fCol[i])
			elseif fThief[i] == nil then -- draw cirle round dropped flag
				SetVisualGearValues(fCirc[i], fGearX[i], fGearY[i], 20, 200, 0, 0, 100, 33, 3, fCol[i])
				if fGear[i] ~= nil then -- flag gear itself
					SetVisualGearValues(fGear[i], fGearX[i], fGearY[i], 20, 200, 0, 0, 100, fGearRad, 2, fCol[i])
				end
			end
		end

		if fNeedsRespawn[i] == true then -- if the flag has been destroyed, no need for a circle
			SetVisualGearValues(fCirc[i], fSpawnX[i],fSpawnY[i], 20, 200, 0, 0, 100, 0, 0, fCol[i])
		end
	end

end

------------------------
-- general methods
------------------------

function CheckDistance(gear1, gear2)

	local g1X, g1Y = GetGearPosition(gear1)
	local g2X, g2Y = GetGearPosition(gear2)

	g1X = g1X - g2X
	g1Y = g1Y - g2Y
	local dist = (g1X*g1X) + (g1Y*g1Y)

	return dist

end

function RebuildTeamInfo()

	-- make a list of teams
	for i = 0, (TeamsCount-1) do
		teamSize[i] = 0
		teamIndex[i] = 0
	end

	-- find out how many hogs per team, and the index of the first hog in hhs
	for i = 0, (TeamsCount-1) do
		for z = 0, numhhs-1 do
			if GetHogTeamName(hhs[z]) == GetTeamName(i) then
				if teamSize[i] == 0 then
					teamIndex[i] = z -- should give starting index
				end
				teamSize[i] = teamSize[i] + 1
				--add a pointer so this hog appears at i in hhs
			end
		end
	end

end

function StartTheGame()

	gameStarted = true
	AddCaption(loc("Game Started!"), 0xFFFFFFFF, capgrpGameState)

	for i = 0, ClansCount-1 do

		fGear[i] = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)
		fCirc[i] = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)
		fSpawnC[i] = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)

		fGearX[i] = fSpawnX[i]
		fGearY[i] = fSpawnY[i]

		fCol[i] = GetClanColor(i)
		fIsMissing[i] = false
		fNeedsRespawn[i] = false
		fCaptures[i] = 0

		SetVisualGearValues(fSpawnC[i], fSpawnX[i],fSpawnY[i], 20, 100, 0, 10, 0, 75, 5, fCol[i])

	end

end

------------------------
-- game methods
------------------------

function onParameters()
	parseParams()
	if params["captures"] ~= nil then
		local s = string.match(params["captures"], "(%d*)")
		if s ~= nil then
			captureLimit = math.max(1, tonumber(s))
		end
	end
end

function onGameInit()

	DisableGameFlags(gfKing, gfAISurvival)
	EnableGameFlags(gfDivideTeams)

	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0
end

function showCTFMission()
	local captures
	if captureLimit == 1 then
		captures = string.format(loc("- First team to capture the flag wins"), captureLimit)
	else
		captures = string.format(loc("- First team to score %d captures wins"), captureLimit)
	end

	local rules = loc("Rules:") .. " |" ..
		loc("- Place your team flag at the end of your first turn") .. "|" ..
		loc("- Return the enemy flag to your base to score") .."|"..
		captures .. "|" ..
		loc("- You may only score when your flag is in your base") .."|"..
		loc("- Hogs will drop the flag when killed") .."|"..
		loc("- Dropped flags may be returned or recaptured").."|"..
		loc("- Hogs will be revived")

	ShowMission(loc("Capture The Flag"), loc("A Hedgewars minigame"), rules, 0, 0)
end

function updateScores()
	for i=0, TeamsCount-1 do
		local team = GetTeamName(i)
		local clan = GetTeamClan(team)
		SetTeamLabel(team, tostring(fCaptures[clan]))
	end
end

function onGameStart()

	showCTFMission()

	RebuildTeamInfo()

	for i=0, ClansCount-1 do
		fCaptures[i] = 0
	end

	for h=1, numhhs do
		-- Hogs are resurrected for free, so this is pointless
		AddAmmo(hhs[h], amResurrector, 0)
	end

	updateScores()

	SendStat(siGraphTitle, loc("Score graph"))
	SendHealthStatsOff()
	SendRankingStatsOff()

end


function onNewTurn()

	if gameStarted == true and not gameOver then
		HandleRespawns()
	end

	local flagsPlaced = 0
	for i=0, ClansCount-1 do
		if fSpawnX[i] and fSpawnY[i] then
			flagsPlaced = flagsPlaced + 1
		end
	end
	if not gameStarted and flagsPlaced == ClansCount then
		StartTheGame()
	end
end

function onEndTurn()
	 -- if the game hasn't started yet, keep track of where we are gonna put the flags on turn end
	if not gameStarted and CurrentHedgehog ~= nil then
		local clan = GetHogClan(CurrentHedgehog)

		if GetX(CurrentHedgehog) and not fSpawnX[clan] then
			fSpawnX[clan] = GetX(CurrentHedgehog)
			fSpawnY[clan] = GetY(CurrentHedgehog)
		end
	end

	if gameStarted == true then
		DrawScores()
	end
end

function onGameTick()

	for i = 0, ClansCount-1 do
		if fThief[i] ~= nil then
			fThiefX[i] = GetX(fThief[i])
			fThiefY[i] = GetY(fThief[i])
		end
	end

	if gameStarted == true and not gameOver then
		HandleCircles()
		if CurrentHedgehog ~= nil then
			CheckFlagProximity()
		end
	end

end

function onGearResurrect(gear)

	if GetGearType(gear) == gtHedgehog then
		-- mark the flag thief as dead if he needed a respawn
		for i = 0, ClansCount-1 do
			if gear == fThief[i] then
				FlagThiefDead(gear)
			end
		end
		AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
	end

end

function InABetterPlaceNow(gear)
	for h = 0, (numhhs-1) do
		if gear == hhs[h] then
			for i = 0, ClansCount-1 do
				if gear == fThief[i] then
					FlagThiefDead(gear)
				end
			end
			hhs[h] = nil
		end
	end
end

function onHogHide(gear)
	 InABetterPlaceNow(gear)
end

function onHogRestore(gear)
	for i = 0, (numhhs-1) do
		if (hhs[i] == nil) then
			hhs[i] = gear
			break
		end
	end
end

function onHogAttack(ammoType)
	if not gameStarted and ammoType == amTardis then
		local i = GetHogClan(CurrentHedgehog)
		fSpawnX[i] = GetX(CurrentHedgehog)
		fSpawnY[i] = GetY(CurrentHedgehog)
	end
end

function onGearAdd(gear)

	if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		numhhs = numhhs + 1
		SetEffect(gear, heResurrectable, 1)

	elseif GetGearType(gear) == gtPiano then
		for i = 0, ClansCount-1 do
			if CurrentHedgehog == fThief[i] then
				FlagThiefDead(CurrentHedgehog)
			end
		end

	end

end

function onGearDelete(gear)

	if GetGearType(gear) == gtHedgehog then
		InABetterPlaceNow(gear)
	elseif GetGearType(gear) == gtKamikaze and not gameStarted then
		local i = GetHogClan(CurrentHedgehog)
		if i <= 1 then
			fSpawnX[i] = GetX(CurrentHedgehog)
			fSpawnY[i] = GetY(CurrentHedgehog)
		end
	end

end

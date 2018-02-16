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
local gameTurns = 0
local captureLimit = 3

--------------------------
-- hog and team tracking variales
--------------------------

local numhhs = 0 -- store number of hedgehogs
local hhs = {} -- store hedgehog gears

local numTeams --  store the number of teams in the game
local teamNameArr = {}	-- store the list of teams
local teamSize = {}	-- store how many hogs per team
local teamIndex = {} -- at what point in the hhs{} does each team begin

-------------------
-- flag variables
-------------------

local fPlaced = {} -- has the flag been placed TRUE/FALSE

local fGear = {}	-- pointer to the visual gears that represent the flag
local fGearX = {}
local fGearY = {}

local fThief = {}	-- pointer to the hogs who stole the flags
local fIsMissing = {}	-- have the flags been destroyed or captured
local fNeedsRespawn = {}	-- do the flags need to be respawned
local fCaptures = {}	-- the team "scores" how many captures
local fSpawnX = {}		-- spawn X for flags
local fSpawnY = {}		-- spawn Y for flags

local fThiefX = {}
local fThiefY = {}
local FTTC = 0 -- flag thief tracker counter

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

function CheckScore(teamID)

	if teamID == 0 then
		alt = 1
	elseif teamID == 1 then
		alt = 0
	end

	if fCaptures[teamID] == captureLimit then
		for i = 0, (numhhs-1) do
			if hhs[i] ~= nil then
				if GetHogClan(hhs[i]) == alt then
					SetEffect(hhs[i], heResurrectable, 0)
					SetHealth(hhs[i],0)
				end
			end
		end
		if CurrentHedgehog ~= nil then
			AddCaption(string.format(loc("Victory for %s!"), GetHogTeamName(CurrentHedgehog)))
			updateScores()
		end
	end

end

function DoFlagStuff(gear)

	if (gear == fGear[0]) then
		wtf = 0
		bbq = 1
	elseif (gear == fGear[1]) then
		wtf = 1
		bbq = 0
	end

	-- player has successfully captured the enemy flag
	if (GetHogClan(CurrentHedgehog) == wtf) and (CurrentHedgehog == fThief[bbq]) and (fIsMissing[wtf] == false) then

		DeleteVisualGear(fGear[wtf])
		fGear[wtf] = nil -- the flag has now disappeared

		fIsMissing[wtf] = false
		fNeedsRespawn[wtf] = true
		fIsMissing[bbq] = false
		fNeedsRespawn[bbq] = true
		fCaptures[wtf] = fCaptures[wtf] +1
		AddCaption(string.format(loc("%s has scored!"), GetHogName(CurrentHedgehog)))
		updateScores()
		PlaySound(sndHomerun)
		fThief[bbq] = nil -- player no longer has the enemy flag
		CheckScore(wtf)

	--if the player is returning the flag
	elseif (GetHogClan(CurrentHedgehog) == wtf) and (fIsMissing[wtf] == true) then

		DeleteVisualGear(fGear[wtf])
		fGear[wtf] = nil -- the flag has now disappeared

		fNeedsRespawn[wtf] = true
		HandleRespawns() -- this will set fIsMissing[wtf] to false :)
		AddCaption(loc("Flag returned!"))

	--if the player is taking the enemy flag
	elseif GetHogClan(CurrentHedgehog) == bbq then

		DeleteVisualGear(fGear[wtf])
		fGear[wtf] = nil -- the flag has now disappeared

		fIsMissing[wtf] = true
		for i = 0,numhhs-1 do
			if CurrentHedgehog ~= nil then
				if CurrentHedgehog == hhs[i] then
					fThief[wtf] = hhs[i]
				end
			end
		end
		AddCaption(loc("Flag captured!"))

	end

end

function CheckFlagProximity()

	for i = 0, 1 do
		if fGear[i] ~= nil then

			g1X = fGearX[i]
			g1Y = fGearY[i]

			g2X, g2Y = GetGearPosition(CurrentHedgehog)

			q = g1X - g2X
			w = g1Y - g2Y
			dist = (q*q) + (w*w)

			if dist < 500 then --1600
				DoFlagStuff(fGear[i])
			end
		end
	end

end


function HandleRespawns()

	for i = 0, 1 do

		if fNeedsRespawn[i] == true then
			fGear[i] = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)
			fGearX[i] = fSpawnX[i]
			fGearY[i] = fSpawnY[i]

			fNeedsRespawn[i] = false
			fIsMissing[i] = false -- new, this should solve problems of a respawned flag being "returned" when a player tries to score
			AddCaption(loc("Flag respawned!"))
		end

	end

end


function FlagThiefDead(gear)

	if (gear == fThief[0]) then
		wtf = 0
		bbq = 1
	elseif (gear == fThief[1]) then
		wtf = 1
		bbq = 0
	end

	if fThief[wtf] ~= nil then
		-- falls into water
		--ShowMission(LAND_HEIGHT,  fThiefY[wtf], (LAND_HEIGHT - fThiefY[wtf]), 0, 0)
		if (LAND_HEIGHT - fThiefY[wtf]) < 15 then
			fIsMissing[wtf] = true
			fNeedsRespawn[wtf] = true
			HandleRespawns()
		else	--normally
			fGearX[wtf]  =  fThiefX[wtf]
			fGearY[wtf]  =  fThiefY[wtf]
			fGear[wtf] = AddVisualGear(fGearX[wtf],fGearY[wtf],vgtCircle,0,true)
		end

		AddVisualGear(fThiefX[wtf], fThiefY[wtf], vgtBigExplosion, 0, false)
		fThief[wtf] = nil
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

	for i = 0, 1 do

		--SetVisualGearValues(fSpawnC[i], fSpawnX[i],fSpawnY[i], 20, 200, 0, 0, 100, 50, 3, fCol[i]) -- draw a circ for spawning area

		if fIsMissing[i] == false then -- draw a flag marker at the flag's spawning place
			SetVisualGearValues(fCirc[i], fSpawnX[i],fSpawnY[i], 20, 20, 0, 10, 0, 33, 3, fCol[i])
			if fGear[i] ~= nil then -- draw the flag gear itself
				SetVisualGearValues(fGear[i], fSpawnX[i],fSpawnY[i], 20, 200, 0, 0, 100, fGearRad, 2, fCol[i])
			end
		elseif (fIsMissing[i] == true) and (fNeedsRespawn[i] == false) then
			if fThief[i] ~= nil then -- draw circle round flag carrier			-- 33
				SetVisualGearValues(fCirc[i], fThiefX[i], fThiefY[i], 20, 200, 0, 0, 100, 50, 3, fCol[i])
				--AddCaption("circle marking carrier")
			elseif fThief[i] == nil then -- draw cirle round dropped flag
				--g1X,g1Y,g4,g5,g6,g7,g8,g9,g10,g11 =  GetVisualGearValues(fGear[i])
				--SetVisualGearValues(fCirc[i], g1X, g1Y, 20, 200, 0, 0, 100, 33, 2, fCol[i])
				SetVisualGearValues(fCirc[i], fGearX[i], fGearY[i], 20, 200, 0, 0, 100, 33, 3, fCol[i])
				--AddCaption('dropped circle marker')
				if fGear[i] ~= nil then -- flag gear itself
					--SetVisualGearValues(fGear[i], g1X, g1Y, 20, 200, 0, 0, 100, 10, 4, fCol[i])
					SetVisualGearValues(fGear[i], fGearX[i], fGearY[i], 20, 200, 0, 0, 100, fGearRad, 2, fCol[i])
					--AddCaption('dropped flag itself')
				end
			end
		end

		if fNeedsRespawn[i] == true then -- if the flag has been destroyed, no need for a circle
			SetVisualGearValues(fCirc[i], fSpawnX[i],fSpawnY[i], 20, 200, 0, 0, 100, 0, 0, fCol[i])
			--AddCaption("needs respawn = true. flag 'destroyed'?")
		end
	end

end

------------------------
-- general methods
------------------------

function CheckDistance(gear1, gear2)

	g1X, g1Y = GetGearPosition(gear1)
	g2X, g2Y = GetGearPosition(gear2)

	g1X = g1X - g2X
	g1Y = g1Y - g2Y
	z = (g1X*g1X) + (g1Y*g1Y)

	dist = z

	return dist

end

function RebuildTeamInfo()


	-- make a list of individual team names
	for i = 0, (TeamsCount-1) do
		teamNameArr[i] = i
		teamSize[i] = 0
		teamIndex[i] = 0
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
	for i = 0, numTeams-1 do

		for z = 0, numhhs-1 do
			if GetHogTeamName(hhs[z]) == teamNameArr[i] then
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
	AddCaption(loc("Game Started!"))

	for i = 0, 1 do

		-- if someone uses kamikaze downwards, this can happen as the hog won't respawn
		if (LAND_HEIGHT - fSpawnY[i]) < 0 then
			tempG = AddGear(0, 0, gtTarget, 0, 0, 0, 0)
     			FindPlace(tempG, true, 0, LAND_WIDTH, true)
			fSpawnX[i], fSpawnY[i] = GetGearPosition(tempG)
			DeleteGear(tempG)
		end

		fGear[i] = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)
		fCirc[i] = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)
		fSpawnC[i] = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)

		fGearX[i] = fSpawnX[i]
		fGearY[i] = fSpawnY[i]

		fCol[i] = GetClanColor(i)
		fIsMissing[i] = false
		fNeedsRespawn[i] = false
		fCaptures[i] = 0

		--SetVisualGearValues(zxc, 1000,1000, 20, 100, 0,    10,                     1,         100,        5,      GetClanColor(0))

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

	DisableGameFlags(gfKing)
	EnableGameFlags(gfDivideTeams)

	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0

	Delay = 10

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
	for i=0, 1 do
		SetTeamLabel(teamNameArr[i], tostring(fCaptures[i]))
	end
end

function onGameStart()

	showCTFMission()

	RebuildTeamInfo()

	-- should gfDivideTeams do this automatically?
	--[[for i = 0, (TeamsCount-1) do
		for g = teamIndex[i], (teamIndex[i]+teamSize[i]-1) do
			if GetHogClan(hhs[g]) == 0 then
				FindPlace(hhs[g], false, 0, LAND_WIDTH/2)
			elseif GetHogClan(hhs[g]) == 1 then
				FindPlace(hhs[g], false, LAND_WIDTH/2, LAND_WIDTH)
			end
		end
	end]]

	fPlaced[0] = false
	fPlaced[1] = false

	--zxc = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)


	--SetVisualGearValues(zxc, 1000,1000, 20, 255, 1,    10,                     0,         200,        1,      GetClanColor(0))
					--minO,max0 -glowyornot	--pulsate timer	 -- fuckall      -- radius -- width  -- colour
end


function onNewTurn()

	gameTurns = gameTurns + 1

	if lastTeam ~= GetHogTeamName(CurrentHedgehog) then
		lastTeam = GetHogTeamName(CurrentHedgehog)
	end

	--AddCaption("Handling respawns")
	if gameStarted == true then
		HandleRespawns()
	--new method of placing starting flags
	elseif gameTurns == 1 then
		showCTFMission()
	elseif gameTurns == 2 then
		fPlaced[0] = true
	elseif gameTurns == 3 then
		fPlaced[1] = true
		StartTheGame()
	end

end

function onGameTick()

	-- onRessurect calls AFTER you have resurrected,
	-- so keeping track of x,y a few milliseconds before
	-- is useful
	--FTTC = FTTC + 1
	--if FTTC == 100 then
	--	FTTC = 0
		for i = 0,1 do
			if fThief[i] ~= nil then
				fThiefX[i] = GetX(fThief[i])
				fThiefY[i] = GetY(fThief[i])
			end
		end
	--end

	-- things we wanna check often
	if (CurrentHedgehog ~= nil) then
		--AddCaption(LAND_HEIGHT - GetY(CurrentHedgehog))
		--AddCaption(GetX(CurrentHedgehog) .. "; " .. GetY(CurrentHedgehog))
		--CheckTeleporters()

	end

	if gameStarted == true then
		HandleCircles()
		if CurrentHedgehog ~= nil then
			CheckFlagProximity()
		end
	elseif CurrentHedgehog ~= nil then -- if the game hasn't started yet, keep track of where we are gonna put the flags on turn end

		if GetHogClan(CurrentHedgehog) == 0 then
			i = 0
		elseif GetHogClan(CurrentHedgehog) == 1 then
			i = 1
		end

		if TurnTimeLeft == 0 then
			fSpawnX[i] = GetX(CurrentHedgehog)
			fSpawnY[i] = GetY(CurrentHedgehog)
		end

	end

end

function onGearResurrect(gear)

	--AddCaption("A gear has been resurrected!")

	-- mark the flag thief as dead if he needed a respawn
	for i = 0,1 do
		if gear == fThief[i] then
			FlagThiefDead(gear)
		end
	end

	-- should be covered by gfDivideTeams, actually
	-- place hogs belonging to each clan either left or right side of map
	--if GetHogClan(gear) == 0 then
	--	FindPlace(gear, false, 0, LAND_WIDTH/2)
	--elseif GetHogClan(gear) == 1 then
	--	FindPlace(gear, false, LAND_WIDTH/2, LAND_WIDTH)
	--end

	AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)

end

function InABetterPlaceNow(gear)
	for i = 0, (numhhs-1) do
		if gear == hhs[i] then

			for i = 0,1 do
				if gear == fThief[i] then
					FlagThiefDead(gear)
				end
			end
			hhs[i] = nil
		end
	end
end

function onHogHide(gear)
	 InABetterPlaceNow(gear)
end

function onHogRestore(gear)
	match = false
	for i = 0, (numhhs-1) do
		if (hhs[i] == nil) and (match == false) then
			hhs[i] = gear
			--AddCaption(GetHogName(gear) .. " has reappeared it seems!")
			match = true
		end
	end
end


function onGearAdd(gear)

	if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		numhhs = numhhs + 1
		SetEffect(gear, heResurrectable, 1)

	elseif GetGearType(gear) == gtPiano then

		for i = 0, 1 do
			if CurrentHedgehog == fThief[i] then
				FlagThiefDead(gear)
			end
		end

	end

end

function onGearDelete(gear)

	if GetGearType(gear) == gtHedgehog then
		InABetterPlaceNow(gear)
	end

end

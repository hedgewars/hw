
------------------------------------------
-- RACER 0.5
-- map-independant racing script
-- by mikade
-----------------------------------------

-----------------------------------
--0.1: took all the code from crazy racer and scrapped most of it
-----------------------------------

-- Removed tumbler system
-- Removed extra adds like boosters etc
-- Added experimental waypoint placement system
-- More user feedback
-- Reduced race complexity limit to 5 waypoints
-- stop placement at complexity limit reached and end turn
-- guys dont keep racing after dying
-- invulnerable feasibility
-- reverted time keeping method
-- reduced feedback display time
-- colour-coded addcaptions
-- cleaned up code
-- support for more players properly added
-- tardis fix
-- remove airstrikes

-- i think the remainder 0 .456 sec of the tracktime isnt getting reset on newturn

-- update feedback

-------
-- 0.2
-------

-- allow gameflags
-- extend time to 90s
-- remove other air-attack based weps
-- turn off water rise for sd

-------
-- 0.3
-------

-- prevent WP being placed in land
-- prevent waypoints being placed outside border

-------
-- 0.4
-------

-- update user feedback
-- add more sounds

-------
-- 0.5
-------

-- fix ghost disappearing if hog falls in water or somehow dies
-- lengthen ghost tracking interval to improve performance on slower machines
-- increase waypoint limit to 8
-- allow for persistent showmission information

-----------------------------
-- SCRIPT BEGINS
-----------------------------

loadfile(GetDataPath() .. "Scripts/Locale.lua")()

------------------
-- Got Variables?
------------------

local fMod = 1000000 -- 1
local roundLimit = 3
local roundNumber = 0
local firstClan = 10

local fastX = {}
local fastY = {}
local fastCount = 0
local fastIndex = 0
local fastColour

local currX = {}
local currY = {}
local currCount = 0

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

-------
-- racer vars
--------

local cGear = nil

local bestClan = nil
local bestTime = nil

local gameBegun = false
local gameOver = false
local racerActive = false
local trackTime = 0

local wpCirc = {}
local wpX = {}
local wpY = {}
local wpCol = {}
local wpActive = {}
local wpRad = 450 --75
local wpCount = 0
local wpLimit = 8

local roundN
local lastRound
local RoundHasChanged

-------------------
-- general methods
-------------------

function RebuildTeamInfo()


	-- make a list of individual team names
	for i = 0, (TeamsCount-1) do
		teamNameArr[i] = " " -- = i
		teamSize[i] = 0
		teamIndex[i] = 0
		teamScore[i] = 100000
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

function CheckWaypoints()

	trackFinished = true

	for i = 0, (wpCount-1) do

		g1X, g1Y = GetGearPosition(CurrentHedgehog)
		g2X, g2Y = wpX[i], wpY[i]

		g1X = g1X - g2X
		g1Y = g1Y - g2Y
		dist = (g1X*g1X) + (g1Y*g1Y)

		--if i == 0 then
		--	AddCaption(dist .. "/" .. (wpRad*wpRad) )
		--end

		NR = (48/100*wpRad)/2

		if dist < (NR*NR) then
		--if dist < (wpRad*wpRad) then
			--AddCaption("howdy")
			wpActive[i] = true
			wpCol[i] = GetClanColor(GetHogClan(CurrentHedgehog)) -- new				--GetClanColor(1)
			SetVisualGearValues(wpCirc[i], wpX[i], wpY[i], 20, 100, 1, 10, 0, wpRad, 5, wpCol[i])

			wpRem = 0
			for k = 0, (wpCount-1) do
				if wpActive[k] == false then
					wpRem = wpRem + 1
				end
			end

			AddCaption(loc("Way-Points Remaining") .. ": " .. wpRem,0xffba00ff,capgrpAmmoinfo)

		end

		if wpActive[i] == false then
			trackFinished = false
		end

	end

	return(trackFinished)

end

function AdjustScores()

	if bestTime == nil then
		bestTime = 100000
		bestClan = 10
		bestTimeComment = "N/A"
	end

	newScore = false

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

	--bestTime = 100000
	--bestClan = 10

	-- find the best time out of those so far
	for i = 0, (numTeams-1) do
		if teamScore[i] < bestTime then
			bestTime = teamScore[i]
			bestClan = teamClan[i]
		end
	end

	if bestTime ~= 100000 then
		bestTimeComment = (bestTime/1000) ..loc("s")
	end

	if newScore == true then
		if trackTime == bestTime then -- best time of the race
			ShowMission(loc("RACER"),
			loc("TRACK COMPLETED"),
			loc("NEW RACE RECORD: ") .. (trackTime/1000) ..loc("s") .. "|" ..
			loc("WINNING TIME: ") .. bestTimeComment, 0, 4000)
			PlaySound(sndHomerun)
		else	-- best time for the clan
			ShowMission(loc("RACER"),
			loc("TRACK COMPLETED"),
			loc("NEW CLAN RECORD: ") .. (trackTime/1000) ..loc("s") .. "|" ..
			loc("WINNING TIME: ") .. bestTimeComment, 4, 4000)
		end
	else -- not any kind of new score
		ShowMission(loc("RACER"),
		loc("TRACK COMPLETED"),
		loc("TIME: ") .. (trackTime/1000) ..loc("s") .. "|" ..
		loc("WINNING TIME: ") .. bestTimeComment, -amSkip, 4000)
		PlaySound(sndHellish)
	end


	--------
	--new
	--------

	if bestTime == trackTime then
		--AddCaption("wooooooooooooooooooooooooooooo")

		fastColour = GetClanColor(GetHogClan(CurrentHedgehog))

		for i = 0, (currCount-1) do
			fastX[i] = currX[i]
			fastY[i] = currY[i]
		end

		fastCount = currCount
		fastIndex = 0

		--currCount = 0 -- is this needed?

	else
		currCount = 0
		fastIndex = 0
	end


end

function onNewRound()

	roundNumber = roundNumber + 1

	totalComment = ""
	for i = 0, (TeamsCount-1) do
			if teamNameArr[i] ~= " " then				-- teamScore[teamClan[i]]
				teamComment[i] = teamNameArr[i] .. ": " .. (teamScore[i]/1000) .. loc("s|")
				totalComment = totalComment .. teamComment[i]
			elseif teamNameArr[i] == " " then
				teamComment[i] = "|"
			end
	end

	ShowMission(	loc("RACER"),
					loc("STATUS UPDATE"),
					loc("Rounds Complete: ") .. roundNumber .. "/" .. roundLimit .. "|" .. " " .. "|" ..
					loc("Best Team Times: ") .. "|" .. totalComment, 0, 4000)

	-- end game if its at round limit
	if roundNumber == roundLimit then
		for i = 0, (numhhs-1) do
			if GetHogClan(hhs[i]) ~= bestClan then
				SetEffect(hhs[i], heResurrectable, false)
				SetHealth(hhs[i],0)
			end
		end
		gameOver = true
		TurnTimeLeft = 1
	end

end

function CheckForNewRound()

	-------------
	------ new
	-------------

	--[[turnN = turnN + 1
	if gameBegun == false then
		if turnN == 2 then
			for i = 0, (numhhs-1) do
				if hhs[i] ~= nil then
					SetEffect(hhs[i], heResurrectable, false)
					SetHealth(hhs[i],0)
				end
			end
			gameOver = true
			TurnTimeLeft = 1
		end
	else


	end]]

	--[[if roundBegun == true then

		if RoundHasChanged == true then
			roundN = roundN + 1
			RoundHasChanged = false
			onNewRound()
		end

		if lastRound ~= TotalRounds then -- new round, but not really

			if RoundHasChanged == false then
				RoundHasChanged = true
			end

		end

		AddCaption("RoundN:" .. roundN .. "; " .. "TR: " .. TotalRounds)

		lastRound = TotalRounds

	end]]

	------------
	----- old
	------------

	if GetHogClan(CurrentHedgehog) == firstClan then
		onNewRound()
	end

end

function DisableTumbler()
	currCount = 0
	fastIndex = 0
	TurnTimeLeft = 0
	racerActive = false -- newadd
end

function HandleGhost()

	-- get the current xy of the racer at this point
	currX[currCount] = GetX(CurrentHedgehog)
	currY[currCount] = GetY(CurrentHedgehog)
	currCount = currCount + 1

	-- draw a ping of smoke where the fastest player was at this point
	if (fastCount ~= 0) and (fastIndex < fastCount) then

		fastIndex = fastIndex + 1

		tempE = AddVisualGear(fastX[fastIndex], fastY[fastIndex], vgtSmoke, 0, false)
		g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
		SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, fastColour )

		--AddCaption("fC: " .. fastIndex .. " / " .. fastCount)

	else

		--AddCaption("excep fC: " .. fastIndex .. " / " .. fastCount)

	end



end

----------------------------------
-- GAME METHODS / EVENT HANDLERS
----------------------------------

function onGameInit()
	GameFlags = GameFlags + gfInfAttack + gfInvulnerable
	CaseFreq = 0
	TurnTime = 90000
	WaterRise = 0
end


function onGameStart()

	roundN = 0
	lastRound = TotalRounds
	RoundHasChanged = false -- true

	RebuildTeamInfo()

	ShowMission	(
				loc("RACER"),
				loc("a Hedgewars mini-game"),

				loc("Build a track and race.") .. "|" ..
				loc("Round Limit:") .. " " .. roundLimit .. "|" ..

				"", 4, 4000
				)
end

function PlaceWayPoint(x,y)

	if (wpCount < wpLimit) then -- seems to not work with a hedgehog nil chek

		wpX[wpCount] = x
		wpY[wpCount] = y
		wpCol[wpCount] = 0xffffffff
		wpCirc[wpCount] = AddVisualGear(wpX[wpCount],wpY[wpCount],vgtCircle,0,true)
																		--100
		SetVisualGearValues(wpCirc[wpCount], wpX[wpCount], wpY[wpCount], 20, 100, 1, 10, 0, wpRad, 5, wpCol[wpCount])

		wpCount = wpCount + 1

		AddCaption(loc("Waypoint placed.") .. " " .. loc("Available points remaining: ") .. (wpLimit-wpCount))

	end

end

function onNewTurn()

	CheckForNewRound()

	racerActive = false

	trackTime = 0

	currCount = 0 -- hopefully this solves problem
	AddAmmo(CurrentHedgehog, amAirAttack, 0)
	gTimer = 0

	-- Set the waypoints to unactive on new round
	for i = 0,(wpCount-1) do
		wpActive[i] = false
		wpCol[i] = 0xffffffff
		SetVisualGearValues(wpCirc[i], wpX[i], wpY[i], 20, 100, 1, 10, 0, wpRad, 5, wpCol[i])
	end

	-- Handle Starting Stage of Game
	if (gameOver == false) and (gameBegun == false) then
		if wpCount >= 3 then
			gameBegun = true
			roundNumber = 0
			firstClan = GetHogClan(CurrentHedgehog)
			ShowMission(loc("RACER"),
			loc("GAME BEGUN!!!"),
			loc("Complete the track as fast as you can!"), 2, 4000)
		else
			ShowMission(loc("RACER"),
			loc("NOT ENOUGH WAYPOINTS"),
			loc("Place more waypoints using the 'Air Attack' weapon."), 2, 4000)
			AddAmmo(CurrentHedgehog, amAirAttack, 4000)
            ParseCommand("setweap " .. string.char(amAirAttack))
		end
	end

	if gameOver == true then
		gameBegun = false
		racerActive = false -- newadd
	end

	AddAmmo(CurrentHedgehog, amTardis, 0)
	AddAmmo(CurrentHedgehog, amDrillStrike, 0)
	AddAmmo(CurrentHedgehog, amMineStrike, 0)
	AddAmmo(CurrentHedgehog, amNapalm, 0)
	AddAmmo(CurrentHedgehog, amPiano, 0)

end

function onGameTick20()

	-- airstrike detected, convert this into a potential waypoint spot
	if cGear ~= nil then
		x,y = GetGearPosition(cGear)
        if x > -9000 then
            x,y = GetGearTarget(cGear)


            if TestRectForObstacle(x-20, y-20, x+20, y+20, true) then
                AddCaption(loc("Please place the way-point in the open, within the map boundaries."))
                PlaySound(sndDenied)
            elseif (y > WaterLine-50) then
                AddCaption(loc("Please place the way-point further from the waterline."))
                PlaySound(sndDenied)
            else
                PlaceWayPoint(x, y)
                if wpCount == wpLimit then
                    AddCaption(loc("Race complexity limit reached."))
                    DisableTumbler()
                end
            end
        else
            DeleteGear(cGear)
        end
        SetGearPosition(cGear, -10000, 0)
	end


	-- start the player tumbling with a boom once their turn has actually begun
	if racerActive == false then

		if (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) then

			-- if the gamehas started put the player in the middle of the first
			--waypoint that was placed
			if gameBegun == true then
				AddCaption(loc("Good to go!"))
				racerActive = true
				trackTime = 0

				SetGearPosition(CurrentHedgehog, wpX[0], wpY[0])
				AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtGrenade, 0, 0, 0, 1)
				FollowGear(CurrentHedgehog)

				HideMission()

			else
				-- still in placement mode
			end

		end
	end



	-- has the player started his tumbling spree?
	if (CurrentHedgehog ~= nil) then

		--airstrike conversion used to be here

		-- if the RACE has started, show tracktimes and keep tabs on waypoints
		if (racerActive == true) and (gameBegun == true) then

			--ghost
			if GameTime%40 == 0 then
				HandleGhost()
			end

			trackTime = trackTime + 20

			if GameTime%100 == 0 then
                
                if trackTime%1000 == 0 then
                    AddCaption((trackTime/1000)..'.0',GetClanColor(GetHogClan(CurrentHedgehog)),capgrpMessage2)
                else
                    AddCaption(trackTime/1000,GetClanColor(GetHogClan(CurrentHedgehog)),capgrpMessage2)
                end

				if (CheckWaypoints() == true) then
					AdjustScores()
					racerActive = false
					DisableTumbler()
				end

			end

		end



		-- if the player has expended his tunbling time, stop him tumbling
		if TurnTimeLeft <= 20 then
			DisableTumbler()
		end

	end

end

function onGearResurrect(gear)

	AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)

	if gear == CurrentHedgehog then
		DisableTumbler()
	end

	-- if the player stops and "dies" or flies into water, stop him racing
	--[[if gear == CurrentHedgehog then
		DisableTumbler()
		ShowMission(loc("RACER"),
		loc("TRACK FAILED!"),
		loc("WINNING TIME: ") .. bestTimeComment, -amSkip, 4000)
	end]]

end

function onGearAdd(gear)

	if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		numhhs = numhhs + 1
		SetEffect(gear, heResurrectable, true)
	end

	if GetGearType(gear) == gtAirAttack then
		cGear = gear
	end

end

function onGearDelete(gear)

	if GetGearType(gear) == gtAirAttack then
		cGear = nil
	end

end

--[[function onAmmoStoreInit()
	SetAmmo(amRope, 9, 0, 0, 0)
	SetAmmo(amJetpack, 9, 0, 0, 0)
	SetAmmo(amSkip, 9, 0, 0, 0)
end]]



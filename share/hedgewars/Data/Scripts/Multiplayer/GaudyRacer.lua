
------------------------------------------
-- RACER
-- a crazy, map-independant racing script
-- by mikade
-----------------------------------------

-----------------------------------
--0.1: with apologies to tumbler
-----------------------------------
-- added tumbler movement system
-- added weapon systems
-- added timer to stop tumbler
-- added racer circle arrays
-- added changing of circs on contact
-- added a "track complete" etc

-----------------------------------
--0.2: for your racing convenience
-----------------------------------

-- added resurrection
-- added team tracking
-- added proper scoring (hopefully, finally)
-- changed showmission icons to match feedback
-- changed circles to be netural colours, and then change to team col
-- cleaned up code
-- cleaned up gameplay: removing control on resurrect, trackcomplete, maxpointset etc
-- improved player feedback: race record, clan record, no record etc.

-----------------------------------
--0.3: user-requested features
-----------------------------------

-- hogs now start at the location of the first waypoint \o/
-- added sticky camera. Hog will no longer lose focus on explosions etc.
-- increased maximum complexity for tracks

-----------------------------------
--0.4: user-requested features
-----------------------------------

-- added movement trail
-- removed exploder weapon
-- removed mortar weapon

-----------------------------------
-- 0.5 gaudy feature experimentation
-----------------------------------
-- added a booster
-- added flame trail for booster
-- added and removed dx/dy on mortar launch
-- added and removed keypress-based mortar fire
-- changed mortar for a gtShell, probably more useful for tunneling
-- added dx/dy *2 shell fire

----------------------------------
-- 0.6 modesty / display mod
----------------------------------
-- author branding removed
-- version numbers removed

-----------------------------
-- SCRIPT BEGINS
-----------------------------

-- enable awesome translaction support so we can use loc() wherever we want
loadfile(GetDataPath() .. "Scripts/Locale.lua")()

------------------
-- Got Variables?
------------------

local roundLimit = 3
local roundNumber = 0
local firstClan = 10

local versionNo = loc("v.06")

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

---------
-- tumbler stuff
---------

local moveTimer = 0
local leftOn = false
local rightOn = false
local upOn = false
local downOn = false

local shotsMax = 30	--10
local shotsLeft = 10

local TimeLeftCounter = 0
local TimeLeft = 60
local stopMovement = false
local tumbleStarted = false

-------
-- racer vars
--------

local boosterOn = false
local boosterFuel = 75
local boosterPower = 0.3
local boosterTimer = 0

local bestClan = nil
local bestTime = nil

local gameBegun = false
local gameOver = false
local racerActive = false
local trackTime = 0
local wpCheckCounter = 0

local wpCirc = {}
local wpX = {}
local wpY = {}
local wpCol = {}
local wpActive = {}
local wpRad = 75
local wpCount = 0
local wpLimit = 20

-------------------
-- general methods
-------------------

function RebuildTeamInfo()


	-- make a list of individual team names
	for i = 0, 7 do
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

function GetSpeed()

	dx, dy = GetGearVelocity(CurrentHedgehog)

	x = dx*dx
	y = dy*dy
	z = x+y

	z = z*100

	k = z%1

	if k ~= 0 then
	 z = z - k
	end

	return(z)

end

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

		if dist < (wpRad*wpRad) then
			--AddCaption("howdy")
			wpActive[i] = true
			wpCol[i] = GetClanColor(GetHogClan(CurrentHedgehog)) -- new				--GetClanColor(1)
			SetVisualGearValues(wpCirc[i], wpX[i], wpY[i], 20, 100, 0, 10, 0, wpRad, 5, wpCol[i])
		end

		if wpActive[i] == false then
			trackFinished = false
		end

	end

	return(trackFinished)

end

function AdjustScores()

	--[[if bestTime == nil then
		bestTime = 100000
		bestClan = 10
		bestTimeComment = "N/A"
	else
		bestTimeComment = (bestTime/1000) ..loc("s")
	end]]

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
			ShowMission(loc("RACER"), loc("TRACK COMPLETED"), loc("NEW RACE RECORD: ") .. (trackTime/1000) ..loc("s") .. "|" .. loc("WINNING TIME: ") .. bestTimeComment, 0, 4000)
		else	-- best time for the clan
			ShowMission(loc("RACER"), loc("TRACK COMPLETED"), loc("NEW CLAN RECORD: ") .. (trackTime/1000) ..loc("s") .. "|" .. loc("WINNING TIME: ") .. bestTimeComment, 4, 4000)
		end
	else -- not any kind of new score
		ShowMission(loc("RACER"), loc("TRACK COMPLETED"), loc("TIME: ") .. (trackTime/1000) ..loc("s") .. "|" .. loc("WINNING TIME: ") .. bestTimeComment, -amSkip, 4000)
	end

end

function CheckForNewRound()

	if GetHogClan(CurrentHedgehog) == firstClan then

		roundNumber = roundNumber + 1

		for i = 0, 7 do
				if teamNameArr[i] ~= " " then				-- teamScore[teamClan[i]]
					teamComment[i] = teamNameArr[i] .. ": " .. (teamScore[i]/1000) .. loc("s|")
				elseif teamNameArr[i] == " " then
					teamComment[i] = "|"
				end
		end
		ShowMission(loc("RACER"), loc("STATUS UPDATE"), loc("Rounds Complete: ") .. roundNumber .. "/" .. roundLimit .. "|" .. " " .. "|" .. loc("Best Team Times: ") .. "|" .. teamComment[0] .. teamComment[1] .. teamComment[2] .. teamComment[3] .. teamComment[4] .. teamComment[5] .. teamComment[6] .. teamComment[7], 0, 1600)

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

end

function DisableTumbler()
	stopMovement = true
	upOn = false
	down = false
	leftOn = false
	rightOn = false
	boosterOn = false
end

----------------------------------
-- GAME METHODS / EVENT HANDLERS
----------------------------------

function onGameInit()
	--Theme = "Hell"
	--GameFlags
	--GameFlags = gfDisableWind
end


function onGameStart()
	RebuildTeamInfo()
	ShowMission(loc("RACER"), "", "", 4, 4000)
end

function onHJump()
	if (shotsLeft > 0) and (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) then -- seems to not work with a hedgehog nil chek

		shotsLeft = shotsLeft - 1
		morte = AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtShell, 0, 0, 0, 1)
		AddCaption(loc("Shots Left: ") .. shotsLeft)


		-- based on player movement already
		CopyPV(CurrentHedgehog, morte) -- new addition

		--x2
		x,y = GetGearVelocity(morte)
		x = x*2
		y = y*2
		SetGearVelocity(morte, x, y)

		--- or based on keys?
		--[[x = 0
		y = 0

		launchPower = 0.5

		if leftOn == true then
			x = x - launchPower
		end
		if rightOn == true then
			x = x + launchPower
		end

		if upOn == true then
			y = y - launchPower
		end
		if downOn == true then
			y = y + launchPower
		end

		SetGearVelocity(morte, x, y)]]


	end
end

function onLJump()


	if (wpCount < wpLimit) and (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) and (gameBegun == false) then -- seems to not work with a hedgehog nil chek

		wpX[wpCount] = GetX(CurrentHedgehog)
		wpY[wpCount] = GetY(CurrentHedgehog)
		wpCol[wpCount] = 0xffffffff
		wpCirc[wpCount] = AddVisualGear(wpX[wpCount],wpY[wpCount],vgtCircle,0,true)
																		--100	  --0		--75	--wpCol[wpCount]
		SetVisualGearValues(wpCirc[wpCount], wpX[wpCount], wpY[wpCount], 20, 100, 0, 10, 0, wpRad, 5, wpCol[wpCount])

		wpCount = wpCount + 1

		AddCaption(loc("Waypoint placed.") .. " " .. loc("Available points remaining: ") .. (wpLimit-wpCount))

		if wpCount == wpLimit then
			AddCaption(loc("Race complexity limit reached."))
			DisableTumbler()
		end

	end


	if (boosterFuel > 0) and (CurrentHedgehog ~= nil) and (stopMovement == false) and (tumbleStarted == true) and (gameBegun == true) then

		if boosterOn == false then
			boosterOn = true
		else
			boosterOn = false
		end

	end

end

function onLeft()
	if (CurrentHedgehog ~= nil) and (stopMovement == false) then
		leftOn = true
	end
end

function onRight()
	if (CurrentHedgehog ~= nil) and (stopMovement == false) then
		rightOn = true
	end
end

function onUp()
	if (CurrentHedgehog ~= nil) and (stopMovement == false) then
		upOn = true
	end
end

function onDown()
	if (CurrentHedgehog ~= nil) and (stopMovement == false) then
		downOn = true
	end
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

function onNewTurn()

	CheckForNewRound()

	--if gameOver == false then
		shotsLeft = shotsMax
		stopMovement = false
		tumbleStarted = false
		boosterOn = false
		boosterFuel = 75
		SetTag(AddGear(0, 0, gtATSmoothWindCh, 0, 0, 0, 1), boosterFuel)
		--SetInputMask(band(0xFFFFFFFF, bnot(gmAnimate+gmAttack+gmDown+gmHJump+gmLeft+gmLJump+gmPrecise+gmRight+gmSlot+gmSwitch+gmTimer+gmUp+gmWeapon)))
		--AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtGrenade, 0, 0, 0, 1)
	--end



	-- Set the waypoints to unactive on new round
	for i = 0,(wpCount-1) do
		wpActive[i] = false
		wpCol[i] = 0xffffffff
		SetVisualGearValues(wpCirc[i], wpX[i], wpY[i], 20, 100, 0, 10, 0, wpRad, 5, wpCol[i])
	end

	-- Handle Starting Stage of Game
	if (gameOver == false) and (gameBegun == false) then
		if wpCount >= 3 then
			gameBegun = true
			racerActive = true
			roundNumber = 0 -- 0
			firstClan = GetHogClan(CurrentHedgehog)
			ShowMission(loc("RACER"), loc("GAME BEGUN!!!"), loc("Complete the track as fast as you can!"), 2, 4000)
		else
			ShowMission(loc("RACER"), loc("NOT ENOUGH WAYPOINTS"), loc("Place more waypoints using [ENTER]"), 2, 4000)
		end
	end

	if gameOver == true then
		gameBegun = false
		stopMovement = true
		tumbleStarted = false
	end

end

function onGameTick()

	-- start the player tumbling with a boom once their turn has actually begun
	if tumbleStarted == false then
		if (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) then
			AddCaption("Good to go!")
			tumbleStarted = true
			racerActive = true
			trackTime = 0
			TimeLeft = 60

			-- if the gamehas started put the player in the middle of the first
			--waypoint that was placed
			if gameBegun == true then
				SetGearPosition(CurrentHedgehog, wpX[0], wpY[0])
				AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtGrenade, 0, 0, 0, 1)
				FollowGear(CurrentHedgehog)
			else -- otherwise just start him tumbling from wherever he is
				AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtGrenade, 0, 0, 0, 1)
			end

		end
	end

	-- has the player started his tumbling spree?
	if (CurrentHedgehog ~= nil) and (tumbleStarted == true) then

		--AddCaption(loc("Speed: ") .. GetSpeed())

		-- if the RACE has started, show tracktimes and keep tabs on waypoints
		if (racerActive == true) and (gameBegun == true) then

			trackTime = trackTime + 1

			wpCheckCounter = wpCheckCounter + 1
			if (wpCheckCounter == 100) then

				AddCaption(loc("Track Time: ") .. (trackTime/1000) .. loc("s") )
				wpCheckCounter = 0
				if (CheckWaypoints() == true) then
					AdjustScores()
					racerActive = false
					DisableTumbler()
				end

			end

		end

		if boosterOn == true then
			boosterTimer = boosterTimer + 1
			if boosterTimer == 150 then --200
				boosterTimer = 0
				boosterFuel = boosterFuel - 1
				SetTag(AddGear(0, 0, gtATSmoothWindCh, 0, 0, 0, 1), boosterFuel)
				if boosterFuel == 0 then
					boosterOn = false
				end
			end
		end

		-- Calculate and display turn time
		TimeLeftCounter = TimeLeftCounter + 1
		if TimeLeftCounter == 1000 then
			TimeLeftCounter = 0
			TimeLeft = TimeLeft - 1

			if TimeLeft >= 0 then
				--TurnTimeLeft = TimeLeft
				--AddCaption(loc("Time Left: ") .. TimeLeft)
			end

		end

		-- if the player has expended his tunbling time, stop him tumbling
		if TimeLeft == 0 then
			DisableTumbler()
		end


		-- handle movement based on IO
		moveTimer = moveTimer + 1
		if moveTimer == 100 then -- 100
			moveTimer = 0

			-- keep in mind gravity is acting on the hog
			-- so his down is more powerful than his up

			dx, dy = GetGearVelocity(CurrentHedgehog)

			dxlimit = 0.4 --0.4
			dylimit = 0.4 --0.4

			if boosterOn == true then

				--flame trail, now removed
				AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtFlame, 0, 0, 0, 0)
				--tempE = AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtDust, 0, false)

				dxlimit = dxlimit + boosterPower
				dylimit = dylimit + boosterPower
			else
				tempE = AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtDust, 0, false)
				g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
				SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, GetClanColor(GetHogClan(CurrentHedgehog)) )
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


			dxPower = 0.1 --0.1
			dyPower = 0.1 --0.1

			if leftOn == true then
				dx = dx - dxPower
			end
			if rightOn == true then
				dx = dx + dxPower
			end

			if upOn == true then
				dy = dy - dyPower -- -0.1 -- new addition
			end
			if downOn == true then
				dy = dy + dyPower
			end

			--if leftOn == true then
			--	dx = dx - 0.04
			--end
			--if rightOn == true then
			--	dx = dx + 0.04
			--end

			--if upOn == true then
			--	dy = dy - 0.1
			--end
			--if downOn == true then
			--	dy = dy + 0.06
			--end

			SetGearVelocity(CurrentHedgehog, dx, dy)

		end

	end

end

function onGearDamage(gear, damage)
	--if gear == CurrentHedgehog then
		-- You are now tumbling
	--end
end

function onGearResurrect(gear)

	AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)

	-- if the player stops and "dies" or flies into water, stop him tumbling
	if gear == CurrentHedgehog then
		DisableTumbler()
	end

end

function onGearAdd(gear)

	if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		numhhs = numhhs + 1
		SetEffect(gear, heResurrectable, true)
	end

end

function onGearDelete(gear)
	--not needed today, yet

	--sticky camera
	if CurrentHedgehog ~= nil then
		FollowGear(CurrentHedgehog)
	end

end

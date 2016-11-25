--------------------------------
-- CONTROL 0.6
--------------------------------

---------
-- 0.2
---------
-- fixed score display errrors
-- added missing resurrection effects
-- moved hogs off control points if thats where they started
-- added sanity limit for the above
-- added tint tags to display clan score on each point as it scors
-- added gameflags filter
-- changed scoring rate
-- hogs now only score point DURING THEIR TURN
-- map now accepts custom weaponsets and themes 
-- changed win limit

---------
-- 0.3
---------

-- added translation support

--------
-- 0.4
--------

-- added scaling scoring based on clans: 300 points to win - 25 per team in game

--------
-- 0.5
--------

-- removed user branding
-- fixed infinite attack time exploit

--------
-- 0.6
--------

-- timebox fix
-- support for more players
-- remove version numbers
-- enable limited sudden death
-- using skip go generates as many points as you would have gotten had you sat and waited

-----------------
--script begins
-----------------

HedgewarsScriptLoad("/Scripts/Locale.lua")

---------------------------------------------------------------
----------lots of bad variables and things
----------because someone is too lazy
----------to read about tables properly
------------------ "Oh well, they probably have the memory"

local TimeCounter = 0

local gameWon = false
local pointLimit = 300

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
			if (hhs[k] ~= nil) then --and (GetGearType(hhs[k]) ~= nil) then
                if (GearIsInZone(hhs[k],i)) == true then

                    if cOwnerClan[i] ~= nil then
                        if cOwnerClan[i] ~= GetHogClan(hhs[k]) then 
                            --if the hog now being compared is different to one that is also here and was previously compared
                            
                            SetVisualGearValues(vCirc[i], vCircX[i], vCircY[i], vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], 0xffffffff)						
                            --SetVisualGearValues(vCirc[i], 2739, 1378, 20, 255, 1, 10, 0, 300, 5, 0xffffffff)
        
                            cOwnerClan[i] = 10 -- this means conflicted
                        end
                    elseif cOwnerClan[i] == nil then
                        cOwnerClan[i] = GetHogClan(hhs[k])
                        --SetVisualGearValues(vCirc[i], 2739, 1378, 20, 255, 1, 10, 0, 300, 5, GetClanColor( GetHogClan(hhs[k])) )
                        SetVisualGearValues(vCirc[i], vCircX[i], vCircY[i], vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], GetClanColor( GetHogClan(hhs[k])))
        
                    end

                end
           -- else hhs[k] = nil
			end
		end

	end

end

function AwardPoints()
		
	for i = 0,(zCount-1) do
		-- give score to all players controlling points		
		--if (cOwnerClan[i] ~= nil) and (cOwnerClan[i] ~= 10) then
		--	teamScore[cOwnerClan[i]] = teamScore[cOwnerClan[i]] + 1
		--end
		
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
				g = AddVisualGear(vCircX[i], vCircY[i]-100, vgtHealthTag, 100, False)
                if g ~= 0 then
				    SetVisualGearValues(g, vCircX[i], vCircY[i]-100, 0, 0, 0, 0, 0, teamScore[cOwnerClan[i]], 1500, GetClanColor(cOwnerClan[i]))
                end
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

function onAttack()

	if CurrentHedgehog ~= nil then
		if GetCurAmmoType() == amSkip then
			z = (TurnTimeLeft / 2000) - (TurnTimeLeft / 2000)%2 
			--AddCaption("scored: " .. z,GetClanColor(GetHogClan(CurrentHedgehog)),capgrpMessage2)
			for i = 0, z do
				AwardPoints()
			end
		end
	end

end

function onGameInit()

	-- Things we don't modify here will use their default values.
	--GameFlags = gfInfAttack + gfSolidLand -- Game settings and rules
	
	GameFlags = band(bor(GameFlags, gfInfAttack + gfSolidLand), bnot(gfKing + gfForts))
	WaterRise = 0

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

	--zxc = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)
	--SetVisualGearValues(zxc, 1000,1000, 20, 255, 1,    10,                     0,         100,        1,      GetClanColor(0))
					--minO,max0 -glowyornot	--pulsate timer	 -- fuckall      -- radius -- width  -- colour

	--new improved placement schematics aw yeah
	RebuildTeamInfo()

	for i = 0, (numTeams-1) do
		pointLimit = pointLimit - 25
	end
	
	-- reposition hogs if they are on control points until they are not or sanity limit kicks in
	reN = 0
	--zz = 0
	while (reN < 10) do
		if ZonesAreEmpty() == false then
			reN = reN + 1	
			--zz = zz + 1	
			--SetGearPosition(hhs[0], 631, 82) -- put this in here to thwart attempts at repositioning and test sanity limit	
		else
			reN = 15		
		end
		--AddCaption(zz) -- number of times it took to work
	end

	ShowMission(loc("Control"), 
	loc("Domination game"), 
	loc("Control pillars to score points.") .. "|" .. 
	loc("Goal") .. ": " .. pointLimit .. " " .. loc("points"), 0, 0)


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
			TurnTimeLeft = 1
		end

		totalComment = ""		
		for i = 0,(TeamsCount-1) do
				if teamNameArr[i] ~= " " then				-- i
					teamComment[i] = teamNameArr[i] .. ": " .. teamScore[teamClan[i]] .. " " .. loc("points") .. "|"
					totalComment = totalComment .. teamComment[i]			
				elseif teamNameArr[i] == " " then
					teamComment[i] = "|"
				end
			end
			
			ShowMission(loc("Control"), 
			loc("Domination game"),
			loc("Team Scores") .. ":" .. "|" ..
			totalComment, 0, 1600)
	
	end

end

function onGameTick()

	vCircCount = vCircCount + 1
	if (vCircCount >= 500) and (gameWon == false) then
		vCircCount = 0
		CheckZones()
	end	

	-- things we wanna check often
	if (CurrentHedgehog ~= nil) then
	--	AddCaption(GetX(CurrentHedgehog) .. "; " .. GetY(CurrentHedgehog))
		--AddCaption(teamNameArr[0] .. " : " .. teamScore[0])
		--AddCaption(GetHogTeamName(CurrentHedgehog) .. " : " .. teamScore[GetHogClan(CurrentHedgehog)]) -- this end up 1?
		
		-- huh? the first clan added seems to be clan 1, not 0 ??

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
	
	--AddCaption(TimeCounter)	
	--hGCount = hGCount + 1
	--if (hGCount >= 2000) and (gameWon == false) then
	--	hGCount = 0
	--	AwardPoints()
	--end

end

function onGearResurrect(gear)
	AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
end

function InABetterPlaceNow(gear)
	for i = 0, (numhhs-1) do
		if gear == hhs[i] then
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
			--FollowGear(gear)
			match = true
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

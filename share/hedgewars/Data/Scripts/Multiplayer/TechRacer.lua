------------------------------------------
-- TECH RACER v0.3
-----------------------------------------

--------------
--0.2
--------------
-- should work better "out the box"
-- changed map generation
-- put a hog limiter in place
-- removed parsecommand
-- fix one of the test maps
-- hopefully added some support for future official challenges etc
-- changed theme
-- minor cleanups?

--------------
--0.3
--------------
-- ehh, scrap everything? those old maps probably still desync so they can die for now
-- hopefully fix map 3
-- add two new crappy map to test an idea.

-----------------------------
-- SCRIPT BEGINS
-----------------------------

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/OfficialChallenges.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

------------------
-- Got Variables?
------------------

local activationStage = 0
local jet = nil
local infUFO = nil

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

local specialPointsX = {}
local specialPointsY = {}
local specialPointsCount = 0

mapID = 22

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

local usedWeapons = {}

local roundN
local lastRound
local RoundHasChanged

-------------------
-- general methods
-------------------

--function onPrecise()
--end

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
                --      AddCaption(dist .. "/" .. (wpRad*wpRad) )
                --end

                NR = (48/100*wpRad)/2

                if dist < (NR*NR) then
                --if dist < (wpRad*wpRad) then
                        --AddCaption("howdy")
                        wpActive[i] = true
                        wpCol[i] = GetClanColor(GetHogClan(CurrentHedgehog)) -- new                             --GetClanColor(1)
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
                else    -- best time for the clan
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
                        if teamNameArr[i] ~= " " then                           -- teamScore[teamClan[i]]
                                teamComment[i] = teamNameArr[i] .. ": " .. (teamScore[i]/1000) .. loc("s|")
                                totalComment = totalComment .. teamComment[i]
                        elseif teamNameArr[i] == " " then
                                teamComment[i] = "|"
                        end
        end

        ShowMission(    loc("RACER"),
                                        loc("STATUS UPDATE"),
                                        loc("Rounds Complete: ") .. roundNumber .. "/" .. roundLimit .. "|" .. " " .. "|" ..
                                        loc("Best Team Times: ") .. "|" .. totalComment, 0, 4000)

        -- end game if its at round limit
        if roundNumber >= roundLimit then
                for i = 0, (numhhs-1) do
                        if GetHogClan(hhs[i]) ~= bestClan then
                                SetEffect(hhs[i], heResurrectable, 0)
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
                                        SetEffect(hhs[i], heResurrectable, 0)
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

function BoomGirder(x,y,rot)
	girTime = 1
	if rot < 4 then
				AddGear(x, y, gtGrenade, 0, 0, 0, girTime)
	elseif rot == 4 then
				g = AddGear(x-45, y, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x-30, y, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x+30, y, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x+45, y, gtGrenade, 0, 0, 0, girTime) -- needed?
	elseif rot == 5 then ------- diag
				g = AddGear(x+45, y+45, gtGrenade, 0, 0, 0, girTime) --n
				g = AddGear(x+30, y+30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x-30, y-30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x-45, y-45, gtGrenade, 0, 0, 0, girTime) --n
	elseif rot == 6 then
				g = AddGear(x, y-45, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x, y+30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x, y-30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y+45, gtGrenade, 0, 0, 0, girTime) -- needed?
	elseif rot == 7 then -------
				g = AddGear(x+45, y-45, gtGrenade, 0, 0, 0, girTime) --n
				g = AddGear(x+30, y-30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x-30, y+30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x-45, y+45, gtGrenade, 0, 0, 0, girTime) --n
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

function HandleFreshMapCreation()

	-- the boom stage, boom girders, reset ammo, and delete other map objects
	if activationStage == 1 then


		ClearMap()
		activationStage = activationStage + 1

	-- the creation stage, place girders and needed gears, grant ammo
	elseif activationStage == 2 then

		-- these are from onParameters()
		if mapID == "0" then
			--AddCaption("don't load any map")
		--[[elseif mapID == "1" then

			--simple testmap
			------ GIRDER LIST ------
			PlaceSprite(306, 530, sprAmGirder, 7)
			PlaceSprite(451, 474, sprAmGirder, 4)
			PlaceSprite(595, 531, sprAmGirder, 5)
			PlaceSprite(245, 679, sprAmGirder, 6)
			PlaceSprite(305, 822, sprAmGirder, 5)
			PlaceSprite(449, 887, sprAmGirder, 4)
			PlaceSprite(593, 825, sprAmGirder, 7)
			PlaceSprite(657, 681, sprAmGirder, 6)
			PlaceSprite(1063, 682, sprAmGirder, 6)
			PlaceSprite(1121, 532, sprAmGirder, 7)
			PlaceSprite(1266, 476, sprAmGirder, 4)
			PlaceSprite(1411, 535, sprAmGirder, 5)
			PlaceSprite(1472, 684, sprAmGirder, 6)
			PlaceSprite(1415, 828, sprAmGirder, 7)
			PlaceSprite(1271, 892, sprAmGirder, 4)
			PlaceSprite(1126, 827, sprAmGirder, 5)
			PlaceSprite(841, 1079, sprAmGirder, 4)
			PlaceSprite(709, 1153, sprAmGirder, 7)
			PlaceSprite(975, 1154, sprAmGirder, 5)
			PlaceSprite(653, 1265, sprAmGirder, 2)
			PlaceSprite(1021, 1266, sprAmGirder, 2)
			PlaceSprite(713, 1369, sprAmGirder, 5)
			PlaceSprite(960, 1371, sprAmGirder, 7)
			PlaceSprite(835, 1454, sprAmGirder, 4)
			PlaceSprite(185, 1617, sprAmGirder, 2)
			PlaceSprite(1317, 1399, sprAmGirder, 2)
			PlaceSprite(1711, 1811, sprAmGirder, 2)
			PlaceSprite(2087, 1424, sprAmGirder, 2)
			PlaceSprite(2373, 1804, sprAmGirder, 2)
			PlaceSprite(2646, 1434, sprAmGirder, 2)
			PlaceSprite(1876, 667, sprAmGirder, 6)
			PlaceSprite(1934, 517, sprAmGirder, 7)
			PlaceSprite(2079, 461, sprAmGirder, 4)
			PlaceSprite(2224, 519, sprAmGirder, 5)
			PlaceSprite(1935, 810, sprAmGirder, 5)
			PlaceSprite(2080, 875, sprAmGirder, 4)
			PlaceSprite(2224, 811, sprAmGirder, 7)
			PlaceSprite(2370, 582, sprAmGirder, 4)
			PlaceSprite(2370, 759, sprAmGirder, 4)
			PlaceSprite(2530, 582, sprAmGirder, 4)
			PlaceSprite(2690, 582, sprAmGirder, 4)
			PlaceSprite(2530, 759, sprAmGirder, 4)
			PlaceSprite(2690, 759, sprAmGirder, 4)
			PlaceSprite(2836, 634, sprAmGirder, 5)
			PlaceSprite(2835, 822, sprAmGirder, 5)
			PlaceSprite(2951, 751, sprAmGirder, 5)
			PlaceSprite(2950, 939, sprAmGirder, 5)
			PlaceSprite(2964, 1054, sprAmGirder, 7)
			PlaceSprite(2978, 1172, sprAmGirder, 5)
			PlaceSprite(3095, 1185, sprAmGirder, 7)
			PlaceSprite(3211, 1069, sprAmGirder, 7)
			PlaceSprite(3038, 843, sprAmGirder, 1)
			PlaceSprite(3126, 825, sprAmGirder, 7)
			PlaceSprite(3271, 768, sprAmGirder, 4)
			PlaceSprite(3357, 1014, sprAmGirder, 4)
			PlaceSprite(3416, 826, sprAmGirder, 5)
			PlaceSprite(3454, 969, sprAmGirder, 6)
			PlaceSprite(3439, 369, sprAmGirder, 6)
			PlaceSprite(3500, 220, sprAmGirder, 7)
			PlaceSprite(3502, 513, sprAmGirder, 5)
			PlaceSprite(3646, 162, sprAmGirder, 4)
			PlaceSprite(3791, 224, sprAmGirder, 5)
			PlaceSprite(3851, 374, sprAmGirder, 6)
			PlaceSprite(3792, 518, sprAmGirder, 7)
			PlaceSprite(3994, 1731, sprAmGirder, 7)
			PlaceSprite(3877, 1848, sprAmGirder, 7)
			PlaceSprite(3789, 1942, sprAmGirder, 3)
			PlaceSprite(3986, 1929, sprAmGirder, 2)
			PlaceSprite(2837, 1937, sprAmGirder, 4)
			PlaceSprite(2997, 1938, sprAmGirder, 4)
			PlaceSprite(3157, 1938, sprAmGirder, 4)
			PlaceSprite(1152, 1844, sprAmGirder, 4)
			PlaceSprite(1299, 1898, sprAmGirder, 5)
			PlaceSprite(1005, 1900, sprAmGirder, 7)
			PlaceSprite(3578, 575, sprAmGirder, 6)
			PlaceSprite(3714, 576, sprAmGirder, 6)
			PlaceSprite(3579, 740, sprAmGirder, 6)
			PlaceSprite(3714, 741, sprAmGirder, 6)
			PlaceSprite(3580, 903, sprAmGirder, 6)
			PlaceSprite(3715, 904, sprAmGirder, 6)
			PlaceSprite(3552, 452, sprAmGirder, 1)
			PlaceSprite(3528, 370, sprAmGirder, 2)
			PlaceSprite(3568, 297, sprAmGirder, 3)
			PlaceSprite(3736, 455, sprAmGirder, 3)
			PlaceSprite(3757, 378, sprAmGirder, 2)
			PlaceSprite(3725, 299, sprAmGirder, 1)
			PlaceSprite(3646, 261, sprAmGirder, 0)
			PlaceSprite(3648, 997, sprAmGirder, 4)
			PlaceSprite(3649, 1275, sprAmGirder, 2)
			PlaceSprite(3514, 1750, sprAmGirder, 0)

			------ AMMO CRATE LIST ------
			tempG = SpawnAmmoCrate(1707, 1755, amBazooka)
			tempG = SpawnAmmoCrate(3983, 1873, amBazooka)
			tempG = SpawnAmmoCrate(184, 1561, amBazooka)
			tempG = SpawnAmmoCrate(2644, 1378, amBazooka)
			tempG = SpawnAmmoCrate(2914, 865, amBazooka)

			------ MINE LIST ------
			SetTimer(AddGear(2340, 580, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2399, 580, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2448, 580, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2517, 579, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2575, 581, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2647, 582, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2720, 582, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2760, 581, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2331, 757, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2409, 758, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2477, 758, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2545, 759, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2613, 760, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2679, 758, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2744, 757, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2813, 610, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2855, 650, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2887, 686, gtMine, 0, 0, 0, 0), 1)

		elseif mapID == "2" then

			-- simple land flags test map, really shit, can delete
			------ GIRDER LIST ------
			PlaceSprite(335, 622, sprAmGirder, 16, nil, nil, nil, nil, 16384)
			PlaceSprite(474, 569, sprAmGirder, 13, nil, nil, nil, nil, 16384)
			PlaceSprite(343, 748, sprAmGirder, 14, nil, nil, nil, nil, 16384)
			PlaceSprite(466, 756, sprAmGirder, 16, nil, nil, nil, nil, 16384)
			PlaceSprite(609, 702, sprAmGirder, 13, nil, nil, nil, nil, 16384)
			PlaceSprite(635, 570, sprAmGirder, 13, nil, nil, nil, nil, 16384)
			PlaceSprite(770, 702, sprAmGirder, 13, nil, nil, nil, nil, 16384)
			PlaceSprite(960, 730, sprAmGirder, 18, nil, nil, nil, nil, 2048)
			PlaceSprite(1061, 608, sprAmGirder, 16, nil, nil, nil, nil, 16384)
			PlaceSprite(1207, 552, sprAmGirder, 13, nil, nil, nil, nil, 16384)
			PlaceSprite(1205, 409, sprAmGirder, 13, nil, nil, nil, nil, 16384)
			PlaceSprite(2312, 637, sprAmGirder, 6)
			PlaceSprite(2312, 472, sprAmGirder, 6)
			PlaceSprite(2311, 308, sprAmGirder, 6)
			PlaceSprite(2292, 155, sprAmGirder, 6)
			PlaceSprite(727, 611, sprAmGirder, 6)
			PlaceSprite(1298, 480, sprAmGirder, 6)

			------ RUBBER BAND LIST ------
			PlaceSprite(1411, 625, sprAmRubber, 1, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(1525, 739, sprAmRubber, 1, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(1638, 852, sprAmRubber, 1, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(1754, 963, sprAmRubber, 1, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(1870, 1076, sprAmRubber, 1, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(2013, 1131, sprAmRubber, 0, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(2159, 1070, sprAmRubber, 3, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(2268, 952, sprAmRubber, 3, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(2315, 802, sprAmRubber, 2, nil, nil, nil, nil, lfBouncy)

			------ AMMO CRATE LIST ------
			tempG = SpawnAmmoCrate(472, 711, amBazooka)
			tempG = SpawnUtilityCrate(540, 660, amParachute)
			tempG = SpawnAmmoCrate(1155, 528, amBazooka)

			------ UTILITY CRATE LIST ------
			tempG = SpawnUtilityCrate(2006, 1102, amRope)]]

		elseif mapID == "3" then

			-- more detailed landflag test map, should hopefully work now
			PlaceSprite(402, 1863, sprAmGirder, 0, 16448250, nil, nil, nil, lfIce)
			PlaceSprite(442, 1863, sprAmGirder, 4, 16448250, nil, nil, nil, lfIce)

			PlaceSprite(2067, 1945, sprAmGirder, 6, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(1943, 1653, sprAmGirder, 6, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(1999, 1504, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2143, 1445, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2432, 1565, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2593, 1565, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2752, 1565, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2206, 1949, sprAmGirder, 6, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2262, 1800, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2407, 1745, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2569, 1745, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2005, 1797, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2288, 1503, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2715, 1802, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2898, 1624, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3014, 1740, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2830, 1919, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3131, 1856, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3191, 1968, sprAmGirder, 2, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3264, 2021, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2840, 2006, sprAmGirder, 3, 2516582650, nil, nil, nil, lfIndestructible)


			PlaceSprite(396, 665, sprAmGirder, 1, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(619, 665, sprAmGirder, 3, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(696, 635, sprAmGirder, 0, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(319, 637, sprAmGirder, 0, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(268, 604, sprAmGirder, 2, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(746, 603, sprAmGirder, 2, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(325, 495, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(689, 493, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(504, 422, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(595, 422, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(412, 422, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(320, 696, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(249, 786, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(249, 948, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(191, 785, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(191, 946, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(191, 1107, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(249, 1109, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(130, 1251, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(306, 1251, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(72, 1360, sprAmGirder, 2, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(364, 1360, sprAmGirder, 2, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(132, 1462, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(304, 1463, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(182, 1616, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(255, 1613, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(217, 1796, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(221, 1381, sprAmGirder, 0, 4294967295, nil, nil, nil, lfNormal)--
			PlaceSprite(154, 669, sprAmGirder, 1, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(124, 553, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(326, 467, sprAmGirder, 3, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(223, 592, sprAmGirder, 3, 4294967295, nil, nil, nil, lfNormal)

			PlaceSprite(638, 791, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(752, 907, sprAmGirder,  5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(866, 1022, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)

			PlaceSprite(1505, 395, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1445, 544, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1506, 686, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1650, 339, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1797, 397, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1857, 547, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1797, 688, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1652, 754, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(3326, 863, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(3474, 921, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(3180, 921, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(3120, 1071, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(3183, 1214, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(3536, 1071, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(3480, 1214, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(3330, 1279, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1481, 1133, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1626, 1078, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1772, 1135, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1422, 1280, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1831, 1286, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1773, 1429, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1627, 1492, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(1482, 1427, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(587, 855, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(425, 855, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
			PlaceSprite(302, 822, sprAmGirder, 1, 4294967295, nil, nil, nil, lfNormal)

			PlaceSprite(2502, 556, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2601, 634, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2616, 441, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2716, 519, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3469, 556, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3696, 763, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)


			PlaceSprite(2756, 379, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2862, 466, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(2918, 379, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3023, 467, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3080, 378, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3616, 503, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3552, 828, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)

			PlaceSprite(3172, 527, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3232, 428, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3289, 647, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3350, 545, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3406, 764, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)

			PlaceSprite(3708, 575, sprAmGirder, 6, 2516582650, nil, nil, nil, lfIndestructible)
			PlaceSprite(3705, 680, sprAmGirder, 1, 2516582650, nil, nil, nil, lfIndestructible)

			------ RUBBER BAND LIST ------
			PlaceSprite(505, 708, sprAmRubber, 0, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(175, 451, sprAmRubber, 0, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(822, 1693, sprAmRubber, 0, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(982, 1691, sprAmRubber, 0, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(1142, 1688, sprAmRubber, 0, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(1302, 1684, sprAmRubber, 0, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(1450, 1750, sprAmRubber, 1, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(1566, 1860, sprAmRubber, 1, nil, nil, nil, nil, lfBouncy)
			PlaceSprite(1680, 1973, sprAmRubber, 1, nil, nil, nil, nil, lfBouncy)

			------ AMMO CRATE LIST ------
			tempG = SpawnAmmoCrate(324, 613, amFirePunch)
			tempG = SpawnAmmoCrate(2361, 1721, amBazooka)
			tempG = SpawnAmmoCrate(2430, 1721, amBazooka)
			tempG = SpawnAmmoCrate(2510, 1721, amBazooka)
			tempG = SpawnAmmoCrate(2581, 1721, amBazooka)
			tempG = SpawnAmmoCrate(405, 1839, amSineGun)
			tempG = SpawnAmmoCrate(481, 1839, amSineGun)

			------ UTILITY CRATE LIST ------
			tempG = SpawnUtilityCrate(696, 611, amParachute)
			tempG = SpawnUtilityCrate(825, 1664, amJetpack)
			tempG = SpawnUtilityCrate(919, 1657, amJetpack)
			tempG = SpawnUtilityCrate(1015, 1662, amJetpack)
			tempG = SpawnUtilityCrate(1095, 1654, amJetpack)
			tempG = SpawnUtilityCrate(1166, 1659, amJetpack)
			tempG = SpawnUtilityCrate(1250, 1650, amJetpack)
			tempG = SpawnUtilityCrate(1335, 1655, amJetpack)

			------ MINE LIST ------
			SetTimer(AddGear(221, 1373, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(609, 661, gtMine, 0, 0, 0, 0), 3000)

			------ STICKY MINE LIST ------
			tempG = AddGear(190, 756, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(191, 810, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(189, 868, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(190, 923, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(192, 984, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(192, 1045, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(189, 1097, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(192, 1159, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(248, 753, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(248, 808, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(249, 868, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(250, 921, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(246, 982, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(247, 1041, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(249, 1094, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(249, 1156, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2571, 665, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2614, 623, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2658, 580, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2704, 533, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2751, 484, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2830, 466, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2912, 465, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2992, 465, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3072, 468, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2465, 592, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2518, 540, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2580, 477, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2635, 425, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2713, 381, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2796, 378, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2892, 379, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(2988, 379, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3061, 377, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3136, 377, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(627, 770, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(661, 804, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(705, 850, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(754, 899, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(805, 950, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(850, 996, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(902, 1048, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(888, 1034, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(788, 933, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(839, 985, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(736, 881, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(686, 829, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(649, 792, gtSMine, 0, 0, 0, 0)

		elseif mapID == "4" then

			------ GIRDER LIST ------
	PlaceSprite(3942, 116, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3999, 270, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3925, 407, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3777, 470, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3791, 65, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3644, 121, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3629, 413, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)

	------ AMMO CRATE LIST ------
	tempG = SpawnAmmoCrate(3772, 446, amWatermelon)
	tempG = SpawnAmmoCrate(3769, 415, amWatermelon)
	tempG = SpawnAmmoCrate(3773, 384, amWatermelon)
	tempG = SpawnAmmoCrate(3771, 353, amWatermelon)
	tempG = SpawnAmmoCrate(3770, 322, amWatermelon)
	tempG = SpawnAmmoCrate(3775, 291, amWatermelon)
	tempG = SpawnAmmoCrate(3776, 260, amWatermelon)
	tempG = SpawnAmmoCrate(3775, 229, amWatermelon)
	tempG = SpawnAmmoCrate(3772, 198, amWatermelon)
	tempG = SpawnAmmoCrate(3776, 167, amWatermelon)

	------ UTILITY CRATE LIST ------
	tempG = SpawnUtilityCrate(3723, 446, amJetpack)
	tempG = SpawnUtilityCrate(3725, 415, amJetpack)
	tempG = SpawnUtilityCrate(3814, 446, amJetpack)
	tempG = SpawnUtilityCrate(3814, 415, amJetpack)
	tempG = SpawnUtilityCrate(3815, 384, amJetpack)
	tempG = SpawnUtilityCrate(3728, 384, amJetpack)

	------ AIR MINE LIST ------
	SetTimer(AddGear(3489, 110, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3509, 366, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3399, 114, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3438, 383, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3322, 113, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3369, 384, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3290, 379, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3253, 112, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3178, 111, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3228, 375, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3173, 384, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3115, 118, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3039, 126, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2954, 139, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3121, 404, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2918, 414, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2880, 144, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2815, 146, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2731, 140, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2867, 408, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2802, 394, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2733, 392, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2661, 392, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2672, 147, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2608, 144, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2558, 117, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2495, 86, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2425, 49, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2373, 79, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2313, 104, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2256, 156, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2218, 226, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2205, 318, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2218, 419, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2255, 479, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2290, 522, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2343, 557, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2413, 540, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2500, 514, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2572, 471, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2618, 436, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2926, 478, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2926, 548, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2924, 615, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3126, 472, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3128, 553, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3136, 623, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3139, 683, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2927, 657, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2919, 720, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3132, 746, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2920, 771, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3137, 798, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2926, 820, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3140, 848, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(945, 441, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(900, 477, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(899, 540, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(915, 631, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1013, 616, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(970, 533, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1062, 458, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1060, 537, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1094, 640, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1029, 692, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(928, 718, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(831, 592, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(860, 666, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(823, 493, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1032, 427, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(953, 351, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(845, 375, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1101, 326, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1128, 565, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1126, 446, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1208, 703, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1139, 726, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1024, 777, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(918, 775, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(812, 758, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3171, 887, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3222, 939, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3273, 977, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3330, 1011, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3401, 1051, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2928, 899, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2935, 966, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2959, 1021, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2999, 1077, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3050, 1136, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3108, 1184, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3159, 1221, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3214, 1243, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3289, 1279, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3453, 1087, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3515, 1136, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3566, 1202, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3604, 1275, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3618, 1345, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3608, 1436, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3582, 1505, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3528, 1565, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3456, 1610, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3368, 1651, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3289, 1666, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3205, 1668, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3132, 1672, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3270, 1325, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3192, 1346, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3140, 1346, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3067, 1359, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2997, 1373, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2918, 1391, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2839, 1406, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3078, 1672, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3019, 1659, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2936, 1667, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2859, 1675, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(975, 722, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(967, 636, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1078, 687, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(868, 740, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(863, 453, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1010, 494, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1080, 590, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(869, 589, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1013, 569, gtAirMine, 0, 0, 0, 0), 1)


	elseif mapID == "5" then

	------ GIRDER LIST ------
	PlaceSprite(3703, 157, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3846, 100, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3991, 162, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(4049, 311, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3648, 308, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3988, 454, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3843, 515, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3616, 429, sprAmGirder, 3, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3725, 548, sprAmGirder, 3, 4294967295, nil, nil, nil, lfNormal)

	------ RUBBER BAND LIST ------

	------ LAND SPRITE LIST ------

	------ HEALTH CRATE LIST ------

	------ AMMO CRATE LIST ------

	------ UTILITY CRATE LIST ------
	tempG = SpawnUtilityCrate(3846, 491, amJetpack)
	tempG = SpawnUtilityCrate(3847, 460, amJetpack)
	tempG = SpawnUtilityCrate(3844, 429, amJetpack)
	tempG = SpawnUtilityCrate(3845, 398, amJetpack)
	tempG = SpawnUtilityCrate(3848, 367, amJetpack)

	------ BARREL LIST ------

	------ MINE LIST ------

	------ STICKY MINE LIST ------

	------ AIR MINE LIST ------
	SetTimer(AddGear(3684, 595, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3648, 641, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3613, 695, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3575, 733, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3537, 781, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3505, 829, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3476, 881, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3447, 930, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3418, 979, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3388, 1021, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3356, 1072, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3561, 469, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3528, 500, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3496, 545, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3467, 584, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3444, 619, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3404, 656, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3373, 693, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3351, 726, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3329, 756, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3306, 798, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3339, 1115, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3321, 1163, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3298, 1206, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3281, 1250, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3259, 1302, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3238, 1343, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3220, 1397, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3269, 810, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3225, 788, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3188, 762, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3149, 735, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3106, 709, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3064, 682, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3023, 652, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2983, 619, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3164, 983, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3143, 1029, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3130, 1077, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3122, 1127, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3100, 1174, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3069, 1226, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3042, 1287, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3178, 1440, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3125, 1480, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3088, 1521, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2988, 1326, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2944, 1357, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2884, 1356, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2813, 1356, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2755, 1356, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2677, 1347, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2591, 1354, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2532, 1354, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3045, 1553, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2974, 1588, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2901, 1584, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2850, 1569, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2782, 1570, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2708, 1577, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2648, 1579, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2585, 1576, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2525, 1581, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2490, 1338, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2435, 1306, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2386, 1283, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2344, 1242, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3126, 942, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3070, 919, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3005, 897, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2962, 865, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2907, 838, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2858, 803, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2807, 769, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2764, 741, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2714, 703, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2665, 671, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2613, 629, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2557, 591, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2513, 545, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2450, 537, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2390, 569, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2341, 603, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2299, 649, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2271, 700, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2243, 754, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2185, 783, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2125, 801, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2084, 864, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2113, 933, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2154, 974, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2191, 1016, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2223, 1061, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2257, 1113, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2283, 1153, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2316, 1202, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2479, 1553, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2422, 1513, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2363, 1477, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2302, 1446, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2243, 1388, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2188, 1335, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2136, 1273, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2086, 1204, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2033, 1132, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1992, 1085, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1967, 1022, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2943, 560, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2890, 511, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2834, 477, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2774, 451, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2710, 428, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2652, 410, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2578, 375, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2482, 342, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2380, 335, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2302, 359, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2256, 409, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2183, 469, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2111, 513, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2049, 558, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1986, 586, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1949, 651, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1925, 704, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1923, 769, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1925, 841, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1946, 930, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1953, 975, gtAirMine, 0, 0, 0, 0), 1)

	elseif mapID == "6" then

	---newish airmine landflag testmap
	------ GIRDER LIST ------
	PlaceSprite(194, 388, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(338, 334, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(484, 390, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(139, 543, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(544, 540, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(201, 687, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(485, 684, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(259, 839, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(426, 837, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(259, 999, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(426, 998, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(259, 1159, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(426, 1158, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(259, 1318, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(426, 1318, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(426, 1478, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(259, 1478, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(515, 1477, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(659, 1537, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(774, 1652, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(836, 1799, sprAmGirder, 6, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(907, 1890, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(1067, 1890, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(1212, 1823, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(1359, 1764, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(1504, 1822, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(1647, 1886, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(1807, 1886, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(1362, 1869, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1968, 1885, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(2111, 1823, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(2257, 1769, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(2403, 1825, sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(2549, 1887, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(2709, 1887, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(2868, 1887, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(2958, 1854, sprAmGirder, 2, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(2928, 1773, sprAmGirder, 1, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(2898, 1692, sprAmGirder, 2, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(2928, 1613, sprAmGirder, 3, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3045, 1584, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3162, 1619, sprAmGirder, 1, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3192, 1697, sprAmGirder, 2, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3160, 1777, sprAmGirder, 3, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3128, 1857, sprAmGirder, 2, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3218, 1886, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3379, 1885, sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3524, 1818, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3641, 1702, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3756, 1585, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(4021, 1316, sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3842, 1503, sprAmGirder, 3, 2516582650, nil, nil, nil, lfIndestructible)
	PlaceSprite(3899, 1409, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3694, 1974, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3809, 1858, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3925, 1741, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(4022, 1613, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2256, 1877, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3046, 1728, sprAmGirder, 0, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(501, 1777, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(572, 1868, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3372, 771, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3517, 715, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3663, 774, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3313, 923, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3373, 1066, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3518, 1128, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3662, 1065, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3723, 924, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2474, 1373, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2474, 1252, sprAmGirder, 2, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2507, 1200, sprAmGirder, 0, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2626, 1200, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2716, 1270, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2505, 1464, sprAmGirder, 0, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2625, 1464, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2716, 1391, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1544, 300, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1691, 245, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1838, 304, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1487, 453, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1548, 597, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1692, 657, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1835, 593, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1900, 451, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3527, 93, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3586, 238, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3703, 354, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3820, 471, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3938, 588, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(4044, 651, sprAmGirder, 0, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3618, 22, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3779, 22, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(3939, 22, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(4047, 22, sprAmGirder, 0, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(936, 1198, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1080, 1143, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1225, 1202, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1278, 1352, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(881, 1351, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(943, 1496, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1219, 1495, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1160, 1645, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(998, 1649, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1160, 1766, sprAmGirder, 2, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(998, 1770, sprAmGirder, 2, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1077, 1824, sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1824, 1138, sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(834, 606, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(950, 593, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1035, 683, sprAmGirder, 1, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(748, 696, sprAmGirder, 3, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(764, 780, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(850, 870, sprAmGirder, 1, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(937, 850, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(1018, 768, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2589, 444, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2704, 329, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2604, 560, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2719, 675, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2832, 689, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2947, 573, sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2820, 317, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2936, 433, sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
	PlaceSprite(2987, 489, sprAmGirder, 1, 4294967295, nil, nil, nil, lfNormal)



	------ AMMO CRATE LIST ------
	tempG = SpawnAmmoCrate(1314, 1845, amBazooka)
	tempG = SpawnAmmoCrate(1413, 1845, amBazooka)
	tempG = SpawnAmmoCrate(2202, 1853, amBazooka)
	tempG = SpawnAmmoCrate(2309, 1853, amBazooka)
	tempG = SpawnAmmoCrate(3024, 1704, amBazooka)
	tempG = SpawnAmmoCrate(3076, 1704, amBazooka)
	tempG = SpawnAmmoCrate(2252, 1853, amBazooka)
	tempG = SpawnAmmoCrate(1363, 1845, amBazooka)
	tempG = SpawnAmmoCrate(548, 1844, amBazooka)
	tempG = SpawnAmmoCrate(606, 1844, amBazooka)
	tempG = SpawnAmmoCrate(576, 1820, amBazooka)
	tempG = SpawnAmmoCrate(1824, 1042, amBazooka)


	------ AIR MINE LIST ------
	SetTimer(AddGear(3517, 995, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3448, 858, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3582, 848, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3758, 158, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(3964, 297, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2772, 506, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(2602, 1339, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1638, 370, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1743, 522, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(894, 726, gtAirMine, 0, 0, 0, 0), 1)
	SetTimer(AddGear(1080, 1690, gtAirMine, 0, 0, 0, 0), 1)

		else



			-- first test epic multi map
			------ GIRDER LIST ------
			PlaceSprite(430, 1871, sprAmGirder, 2)
			PlaceSprite(1249, 1914, sprAmGirder, 4)
			PlaceSprite(1394, 1849, sprAmGirder, 7)
			PlaceSprite(1522, 1848, sprAmGirder, 5)
			PlaceSprite(1578, 1959, sprAmGirder, 2)
			PlaceSprite(1545, 2011, sprAmGirder, 0)
			PlaceSprite(430, 1749, sprAmGirder, 6)
			PlaceSprite(430, 1589, sprAmGirder, 6)
			PlaceSprite(358, 1499, sprAmGirder, 4)
			PlaceSprite(198, 1499, sprAmGirder, 4)
			PlaceSprite(72, 1571, sprAmGirder, 7)
			PlaceSprite(339, 1618, sprAmGirder, 4)
			PlaceSprite(520, 1499, sprAmGirder, 4)
			PlaceSprite(680, 1499, sprAmGirder, 4)
			PlaceSprite(839, 1499, sprAmGirder, 4)
			PlaceSprite(1000, 1499, sprAmGirder, 4)
			PlaceSprite(1404, 1730, sprAmGirder, 5)
			PlaceSprite(1288, 1613, sprAmGirder, 5)
			PlaceSprite(1200, 1529, sprAmGirder, 1)
			PlaceSprite(1125, 1495, sprAmGirder, 0)
			PlaceSprite(1667, 2011, sprAmGirder, 4)
			PlaceSprite(1812, 1951, sprAmGirder, 7)
			PlaceSprite(1964, 2024, sprAmGirder, 0)
			PlaceSprite(1957, 1892, sprAmGirder, 4)
			PlaceSprite(2103, 1949, sprAmGirder, 5)
			PlaceSprite(2242, 2017, sprAmGirder, 4)
			PlaceSprite(2404, 2017, sprAmGirder, 4)
			PlaceSprite(2548, 1955, sprAmGirder, 7)
			PlaceSprite(2635, 1871, sprAmGirder, 3)
			PlaceSprite(2749, 1836, sprAmGirder, 4)
			PlaceSprite(2751, 1999, sprAmGirder, 2)
			PlaceSprite(2749, 1947, sprAmGirder, 0)
			PlaceSprite(2865, 1870, sprAmGirder, 1)
			PlaceSprite(2954, 1954, sprAmGirder, 5)
			PlaceSprite(3061, 2017, sprAmGirder, 0)
			PlaceSprite(3137, 1984, sprAmGirder, 3)
			PlaceSprite(3169, 1864, sprAmGirder, 6)
			PlaceSprite(3169, 1702, sprAmGirder, 6)
			PlaceSprite(3170, 1540, sprAmGirder, 6)
			PlaceSprite(3170, 1418, sprAmGirder, 2)
			PlaceSprite(3138, 1339, sprAmGirder, 1)
			PlaceSprite(3107, 1260, sprAmGirder, 2)
			PlaceSprite(3153, 1194, sprAmGirder, 3)
			PlaceSprite(3230, 1163, sprAmGirder, 0)
			PlaceSprite(3305, 1201, sprAmGirder, 1)
			PlaceSprite(3334, 1277, sprAmGirder, 2)
			PlaceSprite(3227, 1540, sprAmGirder, 6)
			PlaceSprite(3228, 1419, sprAmGirder, 2)
			PlaceSprite(3334, 1358, sprAmGirder, 2)
			PlaceSprite(3280, 1387, sprAmGirder, 0)
			PlaceSprite(3227, 1702, sprAmGirder, 6)
			PlaceSprite(3227, 1864, sprAmGirder, 6)
			PlaceSprite(3253, 1981, sprAmGirder, 1)
			PlaceSprite(3366, 2017, sprAmGirder, 4)
			PlaceSprite(3528, 2018, sprAmGirder, 4)
			PlaceSprite(3689, 2018, sprAmGirder, 4)
			PlaceSprite(246, 1262, sprAmGirder, 4)
			PlaceSprite(407, 1262, sprAmGirder, 4)
			PlaceSprite(568, 1262, sprAmGirder, 4)
			PlaceSprite(731, 1262, sprAmGirder, 4)
			PlaceSprite(894, 1261, sprAmGirder, 4)
			PlaceSprite(1056, 1261, sprAmGirder, 4)
			PlaceSprite(1179, 1262, sprAmGirder, 0)
			PlaceSprite(1288, 1314, sprAmGirder, 5)
			PlaceSprite(1406, 1433, sprAmGirder, 5)
			PlaceSprite(1525, 1549, sprAmGirder, 5)
			PlaceSprite(1642, 1666, sprAmGirder, 5)
			PlaceSprite(1749, 1728, sprAmGirder, 0)
			PlaceSprite(1956, 1802, sprAmGirder, 6)
			PlaceSprite(1956, 1640, sprAmGirder, 6)
			PlaceSprite(1782, 1638, sprAmGirder, 6)
			PlaceSprite(1835, 1487, sprAmGirder, 7)
			PlaceSprite(1942, 1430, sprAmGirder, 0)
			PlaceSprite(2051, 1486, sprAmGirder, 5)
			PlaceSprite(2109, 1639, sprAmGirder, 6)
			PlaceSprite(2177, 1778, sprAmGirder, 5)
			PlaceSprite(2323, 1840, sprAmGirder, 4)
			PlaceSprite(49, 1029, sprAmGirder, 0)
			PlaceSprite(499, 1172, sprAmGirder, 6)
			PlaceSprite(527, 1054, sprAmGirder, 3)
			PlaceSprite(604, 1026, sprAmGirder, 0)
			PlaceSprite(680, 1056, sprAmGirder, 1)
			PlaceSprite(719, 1168, sprAmGirder, 6)
			PlaceSprite(89, 728, sprAmGirder, 4)
			PlaceSprite(251, 728, sprAmGirder, 4)
			PlaceSprite(412, 728, sprAmGirder, 4)
			PlaceSprite(572, 728, sprAmGirder, 4)
			PlaceSprite(733, 728, sprAmGirder, 4)
			PlaceSprite(894, 728, sprAmGirder, 4)
			PlaceSprite(1016, 728, sprAmGirder, 0)
			PlaceSprite(1067, 799, sprAmGirder, 6)
			PlaceSprite(1139, 891, sprAmGirder, 4)
			PlaceSprite(1067, 1171, sprAmGirder, 6)
			PlaceSprite(1067, 1049, sprAmGirder, 2)
			PlaceSprite(1136, 999, sprAmGirder, 4)
			PlaceSprite(1005, 854, sprAmGirder, 2)
			PlaceSprite(972, 803, sprAmGirder, 0)
			PlaceSprite(920, 780, sprAmGirder, 2)
			PlaceSprite(891, 1206, sprAmGirder, 2)
			PlaceSprite(887, 1150, sprAmGirder, 0)
			PlaceSprite(3018, 1311, sprAmGirder, 4)
			PlaceSprite(2871, 1369, sprAmGirder, 7)
			PlaceSprite(2809, 1523, sprAmGirder, 6)
			PlaceSprite(2809, 1647, sprAmGirder, 2)
			PlaceSprite(2469, 1777, sprAmGirder, 7)
			PlaceSprite(2612, 1715, sprAmGirder, 4)
			PlaceSprite(2809, 1702, sprAmGirder, 0)
			PlaceSprite(2727, 1694, sprAmGirder, 0)

			PlaceSprite(3334, 1481, sprAmGirder, 6)
			PlaceSprite(3334, 1643, sprAmGirder, 6)
			PlaceSprite(3334, 1804, sprAmGirder, 6)
			PlaceSprite(3403, 1940, sprAmGirder, 5)
			PlaceSprite(1120, 944, sprAmGirder, 2)
			PlaceSprite(1163, 945, sprAmGirder, 2)
			PlaceSprite(1141, 781, sprAmGirder, 5)
			PlaceSprite(81, 629, sprAmGirder, 1)
			PlaceSprite(102, 498, sprAmGirder, 3)
			PlaceSprite(81, 373, sprAmGirder, 1)
			PlaceSprite(179, 453, sprAmGirder, 6)
			PlaceSprite(100, 260, sprAmGirder, 3)
			PlaceSprite(179, 330, sprAmGirder, 2)
			PlaceSprite(249, 544, sprAmGirder, 4)
			PlaceSprite(410, 545, sprAmGirder, 4)
			PlaceSprite(571, 543, sprAmGirder, 4)
			PlaceSprite(731, 543, sprAmGirder, 4)
			PlaceSprite(891, 544, sprAmGirder, 4)
			PlaceSprite(1014, 544, sprAmGirder, 0)
			PlaceSprite(1779, 1321, sprAmGirder, 6)
			PlaceSprite(1779, 1159, sprAmGirder, 6)
			PlaceSprite(1779, 997, sprAmGirder, 6)
			PlaceSprite(1779, 836, sprAmGirder, 6)
			PlaceSprite(1722, 684, sprAmGirder, 5)
			PlaceSprite(1137, 545, sprAmGirder, 4)
			PlaceSprite(1298, 545, sprAmGirder, 4)
			PlaceSprite(1460, 546, sprAmGirder, 4)
			PlaceSprite(1608, 600, sprAmGirder, 5)
			PlaceSprite(1508, 1005, sprAmGirder, 4)
			PlaceSprite(160, 246, sprAmGirder, 1)
			PlaceSprite(1821, 1356, sprAmGirder, 3)
			PlaceSprite(1938, 1323, sprAmGirder, 4)
			PlaceSprite(2086, 1381, sprAmGirder, 5)
			PlaceSprite(4004, 2018, sprAmGirder, 4)
			PlaceSprite(3934, 1926, sprAmGirder, 6)
			PlaceSprite(3965, 1835, sprAmGirder, 0)
			PlaceSprite(4015, 1763, sprAmGirder, 6)
			PlaceSprite(4015, 1603, sprAmGirder, 6)
			PlaceSprite(4015, 1442, sprAmGirder, 6)
			PlaceSprite(4015, 1280, sprAmGirder, 6)
			PlaceSprite(4014, 1118, sprAmGirder, 6)
			PlaceSprite(4014, 956, sprAmGirder, 6)
			PlaceSprite(4014, 793, sprAmGirder, 6)
			PlaceSprite(4014, 632, sprAmGirder, 6)
			PlaceSprite(4014, 469, sprAmGirder, 6)
			PlaceSprite(3981, 351, sprAmGirder, 1)
			PlaceSprite(3985, 204, sprAmGirder, 3)
			PlaceSprite(4045, 156, sprAmGirder, 0)
			PlaceSprite(3667, 344, sprAmGirder, 0)
			PlaceSprite(4016, 1925, sprAmGirder, 6)
			PlaceSprite(3998, 1926, sprAmGirder, 6)
			PlaceSprite(3980, 1925, sprAmGirder, 6)
			PlaceSprite(3957, 1926, sprAmGirder, 6)
			PlaceSprite(3843, 1832, sprAmGirder, 4)
			PlaceSprite(3682, 1832, sprAmGirder, 4)
			PlaceSprite(3561, 1833, sprAmGirder, 0)
			PlaceSprite(3484, 1796, sprAmGirder, 1)
			PlaceSprite(3455, 1675, sprAmGirder, 6)
			PlaceSprite(3455, 1513, sprAmGirder, 6)
			PlaceSprite(3455, 1351, sprAmGirder, 6)
			PlaceSprite(1601, 476, sprAmGirder, 7)
			PlaceSprite(1706, 421, sprAmGirder, 0)
			PlaceSprite(1888, 366, sprAmGirder, 6)

			PlaceSprite(3997, 1743, sprAmGirder, 6)
			PlaceSprite(3979, 1742, sprAmGirder, 6)
			PlaceSprite(3962, 1741, sprAmGirder, 6)
			PlaceSprite(3943, 1741, sprAmGirder, 6)
			PlaceSprite(2199, 393, sprAmGirder, 7)
			PlaceSprite(2304, 337, sprAmGirder, 0)
			PlaceSprite(2409, 392, sprAmGirder, 5)
			PlaceSprite(2470, 502, sprAmGirder, 2)
			PlaceSprite(2412, 606, sprAmGirder, 7)
			PlaceSprite(2308, 673, sprAmGirder, 0)
			PlaceSprite(2202, 612, sprAmGirder, 5)
			PlaceSprite(2138, 507, sprAmGirder, 2)
			PlaceSprite(2739, 378, sprAmGirder, 7)
			PlaceSprite(2847, 322, sprAmGirder, 0)
			PlaceSprite(2953, 378, sprAmGirder, 5)
			PlaceSprite(2680, 489, sprAmGirder, 2)
			PlaceSprite(3012, 489, sprAmGirder, 2)
			PlaceSprite(2736, 594, sprAmGirder, 5)
			PlaceSprite(2841, 657, sprAmGirder, 0)
			PlaceSprite(2949, 594, sprAmGirder, 7)
			PlaceSprite(2448, 837, sprAmGirder, 7)
			PlaceSprite(2594, 779, sprAmGirder, 4)
			PlaceSprite(2739, 836, sprAmGirder, 5)
			PlaceSprite(2390, 950, sprAmGirder, 2)
			PlaceSprite(2789, 950, sprAmGirder, 2)
			PlaceSprite(2593, 904, sprAmGirder, 4)
			PlaceSprite(2727, 1056, sprAmGirder, 7)
			PlaceSprite(2452, 1058, sprAmGirder, 5)
			PlaceSprite(2510, 1215, sprAmGirder, 6)
			PlaceSprite(2663, 1208, sprAmGirder, 6)
			PlaceSprite(2510, 1378, sprAmGirder, 6)
			PlaceSprite(2664, 1369, sprAmGirder, 6)
			PlaceSprite(300, 275, sprAmGirder, 0)
			PlaceSprite(439, 274, sprAmGirder, 0)
			PlaceSprite(628, 273, sprAmGirder, 4)
			PlaceSprite(811, 271, sprAmGirder, 0)
			PlaceSprite(737, 373, sprAmGirder, 4)
			PlaceSprite(934, 440, sprAmGirder, 0)
			PlaceSprite(1075, 439, sprAmGirder, 0)
			PlaceSprite(1209, 438, sprAmGirder, 0)
			PlaceSprite(1383, 439, sprAmGirder, 4)
			--PlaceSprite(2159, 1525, sprAmGirder, 6)
			PlaceSprite(3547, 344, sprAmGirder, 4)
			PlaceSprite(3584, 254, sprAmGirder, 6)
			PlaceSprite(3508, 132, sprAmGirder, 5)
			PlaceSprite(3335, 1117, sprAmGirder, 6)
			PlaceSprite(3335, 956, sprAmGirder, 6)
			PlaceSprite(3335, 795, sprAmGirder, 6)
			PlaceSprite(3335, 634, sprAmGirder, 6)
			PlaceSprite(3335, 513, sprAmGirder, 2)
			PlaceSprite(3401, 404, sprAmGirder, 7)
			PlaceSprite(3455, 1190, sprAmGirder, 6)
			PlaceSprite(3455, 1029, sprAmGirder, 6)
			PlaceSprite(3455, 868, sprAmGirder, 6)
			PlaceSprite(3455, 705, sprAmGirder, 6)
			PlaceSprite(3455, 582, sprAmGirder, 2)
			PlaceSprite(3485, 503, sprAmGirder, 3)
			PlaceSprite(3601, 475, sprAmGirder, 4)
			PlaceSprite(3719, 444, sprAmGirder, 3)
			PlaceSprite(3094, 828, sprAmGirder, 5)
			PlaceSprite(2064, 947, sprAmGirder, 7)
			PlaceSprite(1826, 512, sprAmGirder, 7)

			PlaceSprite(3420, 49, sprAmGirder, 1)
			PlaceSprite(410, 682, sprAmGirder, 3)
			PlaceSprite(528, 653, sprAmGirder, 4)
			PlaceSprite(688, 653, sprAmGirder, 4)
			PlaceSprite(805, 684, sprAmGirder, 1)
			PlaceSprite(528, 672, sprAmGirder, 4)
			PlaceSprite(688, 672, sprAmGirder, 4)
			PlaceSprite(500, 696, sprAmGirder, 4)
			PlaceSprite(701, 696, sprAmGirder, 4)

			------ AMMO CRATE LIST ------
			tempG = SpawnAmmoCrate(889, 1126, amBaseballBat)
			tempG = SpawnAmmoCrate(1211, 975, amSineGun)
			tempG = SpawnAmmoCrate(3619, 451, amFirePunch)

			------ UTILITY CRATE LIST ------
			tempG = SpawnUtilityCrate(304, 1594, amRope)
			tempG = SpawnUtilityCrate(1538, 1987, amJetpack)
			tempG = SpawnUtilityCrate(1958, 2000, amExtraTime)
			tempG = SpawnUtilityCrate(2744, 1923, amJetpack)
			tempG = SpawnUtilityCrate(3283, 1363, amParachute)
			tempG = SpawnUtilityCrate(2749, 1812, amRope)
			tempG = SpawnUtilityCrate(970, 779, amJetpack)

			tempG = SpawnUtilityCrate(3284, 1332, amExtraTime)
			tempG = SpawnUtilityCrate(1082, 975, amBlowTorch)
			tempG = SpawnUtilityCrate(1547, 981, amJetpack)
			tempG = SpawnUtilityCrate(1707, 397, amRope)
			tempG = SpawnUtilityCrate(2309, 649, amExtraTime)
			tempG = SpawnUtilityCrate(1116, 867, amExtraTime)

			------ AMMO CRATE LIST ------
			tempG = SpawnAmmoCrate(2559, 880, amBazooka)
			tempG = SpawnAmmoCrate(2630, 880, amBazooka)
			tempG = SpawnAmmoCrate(1951, 1406, amGrenade)

			------ UTILITY CRATE LIST ------
			tempG = SpawnUtilityCrate(3536, 320, amBlowTorch)
			tempG = SpawnUtilityCrate(3582, 1994, amJetpack)
			tempG = SpawnUtilityCrate(682, 349, amExtraTime)
			tempG = SpawnUtilityCrate(2842, 633, amExtraTime)

			------ BARREL LIST ------
			SetHealth(AddGear(506, 1034, gtExplosives, 0, 0, 0, 0), 1)
			SetHealth(AddGear(556, 1002, gtExplosives, 0, 0, 0, 0), 1)
			SetHealth(AddGear(615, 1002, gtExplosives, 0, 0, 0, 0), 1)
			SetHealth(AddGear(676, 1010, gtExplosives, 0, 0, 0, 0), 1)
			SetHealth(AddGear(716, 1050, gtExplosives, 0, 0, 0, 0), 1)
			SetHealth(AddGear(67, 1005, gtExplosives, 0, 0, 0, 0), 50)

			------ MINE LIST ------
			SetTimer(AddGear(1187, 1908, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1235, 1908, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1283, 1908, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1323, 1908, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1361, 1875, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1399, 1837, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1426, 1810, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(234, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(308, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(377, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(460, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(550, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(633, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(722, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(795, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(881, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(975, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1060, 1493, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1127, 1489, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1207, 1526, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1261, 1580, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1315, 1634, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1372, 1692, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1416, 1736, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1465, 1792, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1518, 1838, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1566, 1886, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1623, 2005, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1686, 2005, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1799, 1957, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1839, 1917, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1902, 1886, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1933, 1886, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2076, 1916, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2138, 1978, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2221, 2011, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2305, 2011, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2390, 2011, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2578, 1918, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(2494, 2002, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1758, 1728, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1683, 1707, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1635, 1657, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1572, 1596, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1517, 1542, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1447, 1477, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1401, 1432, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1338, 1365, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1290, 1310, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1230, 1266, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1149, 1260, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1054, 1257, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(978, 1257, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(895, 1258, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(819, 1257, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(753, 1258, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(671, 1260, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(599, 1260, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(526, 1259, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(466, 1259, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(408, 1261, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(336, 1260, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(290, 1259, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(218, 1260, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1777, 1263, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1776, 1198, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1778, 1141, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1781, 1078, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1778, 1027, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1778, 985, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1779, 925, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(1777, 882, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(4052, 2010, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(3965, 226, gtMine, 0, 0, 0, 0), 1)
			SetTimer(AddGear(3962, 326, gtMine, 0, 0, 0, 0), 1)

				------ STICKY MINE LIST ------
			tempG = AddGear(3170, 1907, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3170, 1860, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3169, 1809, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3170, 1761, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3170, 1711, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3172, 1668, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3170, 1624, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3169, 1579, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3171, 1526, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3168, 1469, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3171, 1418, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3227, 1416, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3226, 1465, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3225, 1523, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3224, 1576, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3225, 1624, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3228, 1667, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3228, 1707, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3230, 1757, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3228, 1803, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3229, 1856, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3228, 1910, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(258, 534, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(329, 534, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(410, 535, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(482, 535, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(565, 533, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(670, 533, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(763, 533, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(858, 534, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(917, 534, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(1012, 534, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(1147, 535, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(1102, 535, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(1220, 535, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(1293, 535, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(1368, 535, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(1440, 536, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(223, 534, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(814, 534, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3909, 1822, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3867, 1822, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3824, 1822, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3784, 1822, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3732, 1822, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3682, 1822, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3627, 1822, gtSMine, 0, 0, 0, 0)
			tempG = AddGear(3557, 1823, gtSMine, 0, 0, 0, 0)
		end


		activationStage = 200

		--runOnHogs(RestoreHog)

	end

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
	mapID = params["m"]
	infUFO = params["ufo"]
end

function onPreviewInit()
	onGameInit()
end

function onGameInit()

		Theme = "Cave"

		MapGen = mgDrawn
		TemplateFilter = 0

		EnableGameFlags(gfInfAttack, gfDisableWind)
		DisableGameFlags(gfSolidLand)
		CaseFreq = 0
        TurnTime = 90000
        WaterRise = 0

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

function onGameStart()


		trackTeams()

		roundN = 0
        lastRound = TotalRounds
        RoundHasChanged = false -- true

        for i = 0, (specialPointsCount-1) do
                PlaceWayPoint(specialPointsX[i], specialPointsY[i])
        end

        RebuildTeamInfo()

		for i=0 , TeamsCount - 1 do
			cnthhs = 0
			runOnHogsInTeam(limitHogs, teamNameArr[i])
		end

        ShowMission     (
                                loc("RACER"),
                                loc("a Hedgewars mini-game"),

                                loc("Build a track and race.") .. "|" ..
                                loc("Round Limit:") .. " " .. roundLimit .. "|" ..

                                "", 4, 4000
                                )

        TryRepositionHogs()

end

function PlaceWayPoint(x,y)
    if not racerActive then
        if wpCount == 0 or wpX[wpCount - 1] ~= x or wpY[wpCount - 1] ~= y then

            wpX[wpCount] = x
            wpY[wpCount] = y
            wpCol[wpCount] = 0xffffffff
            wpCirc[wpCount] = AddVisualGear(wpX[wpCount],wpY[wpCount],vgtCircle,0,true)

            SetVisualGearValues(wpCirc[wpCount], wpX[wpCount], wpY[wpCount], 20, 100, 1, 10, 0, wpRad, 5, wpCol[wpCount])

            wpCount = wpCount + 1

            AddCaption(loc("Waypoint placed.") .. " " .. loc("Available points remaining: ") .. (wpLimit-wpCount))
        end
    end
end

function onSpecialPoint(x,y,flag)
    specialPointsX[specialPointsCount] = x
    specialPointsY[specialPointsCount] = y
    specialPointsCount = specialPointsCount + 1
end



function onNewTurn()

        CheckForNewRound()
        TryRepositionHogs()

        racerActive = false

		activationStage = 1

		--AddAmmo(CurrentHedgehog, amBazooka, 100)
		--AddAmmo(CurrentHedgehog, amJetpack, 100)

		--ClearMap()


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
						--activationStage = 200
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
						SetWeapon(amAirAttack)
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


		if (jet ~= nil) and (infUFO == "true") then
			SetHealth(ufoGear, 2000)
		end

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


		if activationStage < 10 then
				HandleFreshMapCreation()
		end


        -- start the player tumbling with a boom once their turn has actually begun
        if racerActive == false then

                if (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) then

                        -- if the gamehas started put the player in the middle of the first
                        --waypoint that was placed
                        --if activationStage == 200 then
						if gameBegun == true then
                                AddCaption(loc("Good to go!"))
                                racerActive = true
                                trackTime = 0


								SetGearPosition(CurrentHedgehog, wpX[0], wpY[0])
                                --AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), gtGrenade, 0, 0, 0, 1)
                                --SetGearVelocity(CurrentHedgehog,1000000,1000000)
								SetGearMessage(CurrentHedgehog,gmLeft)


								FollowGear(CurrentHedgehog)

                                HideMission()
								activationStage = 201

						else
                                -- still in placement mode
                        end

                end

        elseif (activationStage == 201) and (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) then
			SetGearMessage(CurrentHedgehog,0)
			activationStage = 202
		end



        -- has the player started his tumbling spree?
        if (CurrentHedgehog ~= nil) then

                --airstrike conversion used to be here

                -- if the RACE has started, show tracktimes and keep tabs on waypoints
                if (racerActive == true) and (activationStage == 202) then

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

end

function isATrackedGear(gear)
	if 	(GetGearType(gear) == gtHedgehog) or
		(GetGearType(gear) == gtGrenade) or
		(GetGearType(gear) == gtTarget) or
		(GetGearType(gear) == gtFlame) or
		(GetGearType(gear) == gtExplosives) or
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
		end

		if GetGearType(gear) == gtHedgehog then
                hhs[numhhs] = gear
                numhhs = numhhs + 1
                SetEffect(gear, heResurrectable, 1)
        end

        if GetGearType(gear) == gtAirAttack then
                cGear = gear
        elseif GetGearType(gear) == gtJetpack then
			jet = gear
		end

end

function onGearDelete(gear)

        if isATrackedGear(gear) then
			trackDeletion(gear)
		elseif GetGearType(gear) == gtAirAttack then
                cGear = nil
        elseif GetGearType(gear) == gtJetpack then
			jet = nil
		end

end

function onAttack()
    at = GetCurAmmoType()

    usedWeapons[at] = 0
end

function onAchievementsDeclaration()
    usedWeapons[amSkip] = nil

    usedRope = usedWeapons[amRope] ~= nil
    usedPortal = usedWeapons[amPortalGun] ~= nil
    usedSaucer = usedWeapons[amJetpack] ~= nil

    usedWeapons[amRope] = nil
    usedWeapons[amPortalGun] = nil
    usedWeapons[amJetpack] = nil

    usedOther = next(usedWeapons) ~= nil

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

    map = detectMap()

    for i = 0, (numTeams-1) do
        if teamScore[i] < 100000 then
            DeclareAchievement(raceType, teamNameArr[i], map, teamScore[i])
        end
    end
end




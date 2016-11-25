--------------------------------
-- CTF_BLIZZARD 0.9
--------------------------------

---------
-- 0.2
---------

-- disabled super weapons

-- theme modifications

-- improved hog placement system: teams can now be put
-- in any order and be of any size

---------
-- 0.3
---------

-- In this version:

-- changed starting weapons
-- changed crate drop contents and rate of drops

-- completely removed super weapons and super weapon scripts

-- removed custom respawning
-- removed set respawn points

-- added AIRespawn-esque respawning
-- added simple left vs right respawn points

-- added non-lethal poison to flag carriers as an indicator

-- improved flag mechanics and player-flag feedback
-- flag now instantly respawns if you kill enemy hog and return it,
-- or if the flag falls in water, _BUT_ not if it is blown up

---------
-- 0.4
---------

-- tweaked crate drop rates and crate contents
-- improved the teleporters, they should now be able to handle rope... hopefully
-- updated SetEffect calls to be in line with 0.9.15 definitions
-- added visual gears when hogs respawn
-- added visual gears when hogs teleport
-- added visual gear to track flag and flag carriers
-- removed poisoning of flag carriers
-- removed health adjustments for flag carriers due to aforementioned poisons

---------
-- 0.5
---------

-- added translation support, hopefully
-- added ctf rules
-- added effects to the teleporters
-- added aura round spawning area
-- changed the aura around the flag carrier / flag to an aura and added some support for this
-- changed things so the seed is no longer always the same...

---------
-- 0.6
---------

-- removed branding and version number
-- removed teleport from starting weapons
-- increased captures to 3

------------
-- 0.7
------------

-- hopefully fixed a bug with the teleporters
-- added a fix for crate possibly getting imbedded in land when it was near the water line

------------
-- 0.8
------------

-- fixed version control fail with missing check on onGearDelete

-- changed hog placements code so that they start in the same place for both teams
-- and hogs move in the same order, not backwards to each other.

-----------
-- 0.9
------------

-- add support for more players
-- re-enable sudden death, but set water rise to 0

HedgewarsScriptLoad("/Scripts/Locale.lua")

---------------------------------------------------------------
----------lots of bad variables and things
----------because someone is too lazy
----------to read about tables properly
------------------ "Oh well, they probably have the memory"

local actionReset = 0 -- used in CheckTeleporters()

local roundsCounter = 0	-- used to determine when to spawn more crates
						-- currently every 6 TURNS, should this work
						-- on ROUNDS instead?
local effectTimer = 0

local ropeGear = nil

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

local fGear = {}	-- pointer to the case gears that represent the flag
local fThief = {}	-- pointer to the hogs who stole the flags
local fIsMissing = {}	-- have the flags been destroyed or captured
local fNeedsRespawn = {}	-- do the flags need to be respawned
local fCaptures = {}	-- the team "scores" how many captures
local fSpawnX = {}		-- spawn X for flags
local fSpawnY = {}		-- spawn Y for flags

local fThiefX = {}
local fThiefY = {}
local FTTC = 0 -- flag thief tracker counter
--local fThiefsHealed = false

local fSpawnC = {}
local fCirc = {} -- flag/carrier marker circles
local fCol = {} -- colour of the clans

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


--------------------------------
--zone and teleporter variables
--------------------------------

local redTel
local orangeTel
--local areaArr = {} -- no longer used

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

function ManageTeleporterEffects()
	effectTimer = effectTimer + 1
	if effectTimer > 50 then -- 100
		effectTimer = 0

		for i = 0,1 do
			eX = 10 + zXMin[i] + GetRandom(zWidth[i]-10)
			eY = 50 + zYMin[i] + GetRandom(zHeight[i]-110)

	-- steam and smoke and DUST look good, smokering looks trippy
	-- smoketrace and eviltrace are not effected by wind?
	-- chunk is a LR falling gear
			tempE = AddVisualGear(eX, eY, vgtDust, 0, false)
			if tempE ~= 0 then
				g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
				SetVisualGearValues(tempE, eX, eY, g3, g4, g5, g6, g7, g8, g9, fCol[i])
			end
		end
	end
end

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

------------------------
--flag methods
------------------------

function CheckScore(teamID)

	if teamID == 0 then
		alt = 1
		winner = "Red"

	elseif teamID == 1 then
		alt = 0
		winner = "Blue"
	end

	if fCaptures[teamID] == 3 then
		for i = 0, (numhhs-1) do
			if GetHogClan(hhs[i]) == alt then
				SetEffect(hhs[i], heResurrectable, 0)
				SetHealth(hhs[i],0)
			end
		end
		--ShowMission("GAME OVER!", "Victory for the " .. winner .. " Team!", "Hooray!", 0, 0)
		ShowMission(loc("GAME OVER!"), loc("Victory for the ") .. GetHogTeamName(CurrentHedgehog), loc("Hooray!"), 0, 0)
	end

end

function HandleRespawns()

	for i = 0, 1 do

		if fNeedsRespawn[i] == true then
			fGear[i] = SpawnAmmoCrate(fSpawnX[i],fSpawnY[i],amSkip)
			--fGear[i] = SpawnHealthCrate(fSpawnX[i],fSpawnY[i])
			fNeedsRespawn[i] = false
			fIsMissing[i] = false -- new, this should solve problems of a respawned flag being "returned" when a player tries to score
			AddCaption(loc("Flag respawned!"))
		end

	end

end

function FlagDeleted(gear)

	if (gear == fGear[0]) then
		wtf = 0
		bbq = 1
	elseif (gear == fGear[1]) then
		wtf = 1
		bbq = 0
	end

	--ShowMission("OH HAI!", "FlagDeleted was called", "Oh noes!", -amBazooka, 0)

	if CurrentHedgehog ~= nil then

		--ShowMission("GUESS WAT?", "I'm not nil", "Oh noes!", -amBazooka, 0)
		--if the player picks up the flag
		if CheckDistance(CurrentHedgehog, fGear[wtf]) < 1600 then

			fGear[wtf] = nil -- the flag has now disappeared and we shouldnt be pointing to it

			-- player has successfully captured the enemy flag
			if (GetHogClan(CurrentHedgehog) == wtf) and (CurrentHedgehog == fThief[bbq]) and (fIsMissing[wtf] == false) then
				fIsMissing[wtf] = false
				fNeedsRespawn[wtf] = true
				fIsMissing[bbq] = false
				fNeedsRespawn[bbq] = true
				fCaptures[wtf] = fCaptures[wtf] +1					--fCaptures[wtf]

				--ShowMission(LOC_NOT("You have SCORED!!"), "Red Team: " .. fCaptures[0], "Blue Team: " .. fCaptures[1], -amBazooka, 0)
				ShowMission(loc("You have SCORED!!"), GetHogTeamName(CurrentHedgehog) .. ": " .. fCaptures[wtf], loc("Opposing Team: ") .. fCaptures[bbq], 0, 0)

				PlaySound(sndVictory)
				--SetEffect(fThief[bbq], hePoisoned, false)
				fThief[bbq] = nil -- player no longer has the enemy flag
				CheckScore(wtf)

			--if the player is returning the flag
			elseif GetHogClan(CurrentHedgehog) == wtf then

				fNeedsRespawn[wtf] = true

				-- NEW ADDIITON, does this work? Should make it possible to return your flag and then score in the same turn
				if fIsMissing[wtf] == true then
					HandleRespawns() -- this will set fIsMissing[wtf] to false :)
					AddCaption(loc("Flag returned!"))
				elseif fIsMissing[wtf] == false then
					AddCaption(loc("That was pointless.") .. loc("The flag will respawn next round."))
				end

				--fIsMissing[wtf] = false
				--ShowMission("Flag returned!", "Hooray", "", -amBazooka, 0)

			--if the player is taking the enemy flag
			elseif GetHogClan(CurrentHedgehog) == bbq then
				fIsMissing[wtf] = true
				for i = 0,numhhs-1 do
					if CurrentHedgehog == hhs[i] then
						fThief[wtf] = hhs[i]
						--SetEffect(fThief[wtf], hePoisoned, true)
					end
				end

				AddCaption(loc("Flag captured!"))

			else --below line doesnt usually get called
				AddCaption("Hmm... that wasn't supposed to happen...")

			end

		-- if flag has been destroyed, probably
		else

			if GetY(fGear[wtf]) > 2025 then
				fGear[wtf] = nil
				fIsMissing[wtf] = true
				fNeedsRespawn[wtf] = true
				HandleRespawns()
			else
				fGear[wtf] = nil
				fIsMissing[wtf] = true
				fNeedsRespawn[wtf] = true
				AddCaption(loc("Boom!") .. " " .. loc("The flag will respawn next round."))
			end

		end

	-- if flag has been destroyed deep underwater and player is now nil
	-- probably only gets called if the flag thief drowns himself
	-- otherwise the above one will work fine
	else
		--ShowMission("NIL PLAYER!", "Oh snap", "Oh noes!", -amBazooka, 0)
		fGear[wtf] = nil
		fIsMissing[wtf] = true
		fNeedsRespawn[wtf] = true
		AddCaption(loc("The flag will respawn next round."))
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
		
		if fThiefY[wtf] > 2040 then
			fGear[wtf] = SpawnAmmoCrate(fThiefX[wtf],(fThiefY[wtf]+10),amSkip)
		else
			fGear[wtf] = SpawnAmmoCrate(fThiefX[wtf],(fThiefY[wtf]-50),amSkip)
		end

		AddVisualGear(fThiefX[wtf], fThiefY[wtf], vgtBigExplosion, 0, false)
		fThief[wtf] = nil
	end

end

function HandleCircles()

	for i = 0, 1 do
		if fIsMissing[i] == false then -- draw a circle at the flag's spawning place
			--SetVisualGearValues(fCirc[i], fSpawnX[i],fSpawnY[i], 20, 200, 0, 0, 100, 33, 2, fCol[i])
			SetVisualGearValues(fCirc[i], fSpawnX[i],fSpawnY[i], vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], vCircCol[i])
		elseif (fIsMissing[i] == true) and (fNeedsRespawn[i] == false) then
			if fThief[i] ~= nil then -- draw circle round flag carrier
				--SetVisualGearValues(fCirc[i], fThiefX[i], fThiefY[i], 20, 200, 0, 0, 100, 33, 2, fCol[i])
				SetVisualGearValues(fCirc[i], fThiefX[i], fThiefY[i], vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], vCircCol[i])
			elseif fThief[i] == nil then -- draw cirle round dropped flag
				--SetVisualGearValues(fCirc[i], GetX(fGear[i]), GetY(fGear[i]), 20, 200, 0, 0, 100, 33, 2, fCol[i])
				SetVisualGearValues(fCirc[i], GetX(fGear[i]),GetY(fGear[i]), vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], vCircCol[i])
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

	g1X, g1Y = GetGearPosition(gear1)
	g2X, g2Y = GetGearPosition(gear2)

	g1X = g1X - g2X
	g1Y = g1Y - g2Y
	z = (g1X*g1X) + (g1Y*g1Y)

	--dist = math.sqrt(z)

	dist = z

	return dist

end

function CheckTeleporters()

	teleportActive = false

	if (GearIsInZone(CurrentHedgehog, redTel) == true) and (GetHogClan(CurrentHedgehog) == 0) then
		teleportActive = true
		destinationX = 1402
		destinationY = 321
	elseif (GearIsInZone(CurrentHedgehog, orangeTel) == true) and (GetHogClan(CurrentHedgehog) == 1) then
		teleportActive = true
		destinationX = 2692
		destinationY = 321
	end

	if teleportActive == true then
		if actionReset == 0 then
			if ropeGear ~= nil then
				if GetGearElasticity(ropeGear) ~= 0 then
					SetGearMessage(CurrentHedgehog, gmAttack)
				end
			end
			--AddCaption(actionReset .. ";" .. "attack")
		elseif actionReset == 10 then
			SetGearMessage(CurrentHedgehog, 0)
			--AddCaption(actionReset .. ";" .. "reset")
		elseif actionReset == 20 then
			AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtBigExplosion, 0, false)
			SetGearPosition(CurrentHedgehog,destinationX,destinationY)
			AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtBigExplosion, 0, false)
			--AddCaption(actionReset .. ";" .. "teleport")
		end

		actionReset = actionReset + 1
		if actionReset >= 30 then
			actionReset = 0
		end

	end

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

function HandleCrateDrops()

	roundsCounter = roundsCounter +1

	if roundsCounter == 5 then

		roundsCounter = 0

		r = GetRandom(8)
		if r == 0 then
			SpawnUtilityCrate(0,0,amSwitch)
		elseif r == 1 then
			SpawnUtilityCrate(0,0,amTeleport)
		elseif r == 2 then
			SpawnUtilityCrate(0,0,amJetpack)
		elseif r == 3 then
			SpawnUtilityCrate(0,0,amExtraTime)
		elseif r == 4 then
			SpawnUtilityCrate(0,0,amGirder)
		elseif r == 5 then
			SpawnAmmoCrate(0,0,amDynamite)
		elseif r == 6 then
			SpawnAmmoCrate(0,0,amFlamethrower)
		elseif r == 7 then
			SpawnUtilityCrate(0,0,amPortalGun)
		end

	end

end

------------------------
-- game methods
------------------------

function onGameInit()

	-- Things we don't modify here will use their default values.
	GameFlags = gfDivideTeams -- Game settings and rules
	TurnTime = 30000 -- (was 30) The time the player has to move each round (in ms)
	CaseFreq = 0 -- The frequency of crate drops
	MinesNum = 0 -- The number of mines being placed
	MinesTime  = 2000
	Explosives = 0 -- The number of explosives being placed
	Delay = 10 -- The delay between each round
	WaterRise = 0 -- I sure hope this works	
	--SuddenDeathTurns = 99 -- suddendeath is off, effectively
	Map = "Blizzard" -- The map to be played
	Theme = "Snow" -- The theme to be used "Nature"

end


function onGameStart()

	ShowMission(loc("CTF_Blizzard"), loc("Capture The Flag"), loc(" - Return the enemy flag to your base to score | - First team to 3 captures wins | - You may only score when your flag is in your base | - Hogs will drop the flag if killed, or drowned | - Dropped flags may be returned or recaptured | - Hogs respawn when killed"), 0, 0)


	-- initialize teleporters
	redTel = CreateZone(342,1316,42,449)	-- red teleporter
	orangeTel = CreateZone(3719,1330,45,449)	-- orange teleporter


	--new improved placement schematics aw yeah
	RebuildTeamInfo()
	--ShowMission("Team Info Rebuilt", "Here you go:", "TeamCount: " .. TeamsCount .. "|" .. teamNameArr[0] .. ": " .. teamSize[0] .. " Hogs|" .. teamNameArr[1] .. ": " .. teamSize[1] .. " Hogs|" .. teamNameArr[2] .. ": " .. teamSize[2] .. " Hogs|", 0, 0)
	team1Placed = 0
	team2Placed = 0
	for i = 0, (TeamsCount-1) do
		for g = teamIndex[i], (teamIndex[i]+teamSize[i]-1) do
			if GetHogClan(hhs[g]) == 0 then
				SetGearPosition(hhs[g],1403+ ((team1Placed+1)*50),1570)
				team1Placed = team1Placed +1
				if team1Placed > 6 then
					team1Placed = 0
				end
			elseif GetHogClan(hhs[g]) == 1 then
				SetGearPosition(hhs[g],2691- ((team2Placed+1)*50),1570)
				team2Placed = team2Placed +1
				if team2Placed > 6 then
					team2Placed = 0
				end
			end
		end
	end



	--spawn starting ufos and or super weapons
	SpawnAmmoCrate(2048,1858,amJetpack)
	--SpawnUtilityCrate(2048,1858,amExtraTime)

	--set flag spawn points and spawn the flags
	fSpawnX[0] = 957
	fSpawnY[0] = 1747
	fSpawnX[1] = 3123
	fSpawnY[1] = 1747

	for i = 0, 1 do
		fGear[i] = SpawnAmmoCrate(fSpawnX[i],fSpawnY[i],amSkip)
		fCirc[i] = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)
		fCol[i] = GetClanColor(i)

		fSpawnC[i] = AddVisualGear(fSpawnX[i],fSpawnY[i],vgtCircle,0,true)
		SetVisualGearValues(fSpawnC[i], fSpawnX[i],fSpawnY[i], 10, 200, 1, 10, 0, 300, 5, fCol[i])


		fIsMissing[i] = false
		fNeedsRespawn[i] = false
		fCaptures[i] = 0

		vCircMinA[i] = 20
		vCircMaxA[i] = 255
		vCircType[i] = 1
		vCircPulse[i] = 10
		vCircFuckAll[i] = 0
		vCircRadius[i] = 150
		vCircWidth[i] = 5
		vCircCol[i] = fCol[i]

		SetVisualGearValues(fCirc[i], fSpawnX[i],fSpawnY[i], vCircMinA[i], vCircMaxA[i], vCircType[i], vCircPulse[i], vCircFuckAll[i], vCircRadius[i], vCircWidth[i], vCircCol[i])

	end

end


function onNewTurn()

	if lastTeam ~= GetHogTeamName(CurrentHedgehog) then
		lastTeam = GetHogTeamName(CurrentHedgehog)
	end

	for i = 0, 1 do
		if fThief[i] ~= nil then
			--adjust = 5 + GetHealth(fThief[i])
			--SetHealth(fThief[i], adjust)
			--AddCaption('Helped out the flag poisoned flag thiefs')
		end
	end

	--AddCaption("Handling respawns")
	HandleRespawns()
	HandleCrateDrops()

	--myC = AddVisualGear(GetX(CurrentHedgehog),GetY(CurrentHedgehog),vgtCircle,0,true)
	--SetVisualGearValues(myC, GetX(CurrentHedgehog),GetY(CurrentHedgehog), 20, 200, 0, 0, 100, 50, 3, GetClanColor(GetHogClan(CurrentHedgehog)))

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
		--AddCaption(GetX(CurrentHedgehog) .. "; " .. GetY(CurrentHedgehog))
		--AddCaption("Checking Teleporters")
		CheckTeleporters()
	end

	HandleCircles()
	ManageTeleporterEffects()

end


function onAmmoStoreInit()

	SetAmmo(amDrill,9,0,0,0)
	SetAmmo(amMortar,9,0,0,0)

	SetAmmo(amGrenade,9,0,0,0)
	SetAmmo(amClusterBomb,4,0,0,0)

	--SetAmmo(amDEagle, 4, 0, 0, 0)
	SetAmmo(amShotgun, 9, 0, 0, 0)
	SetAmmo(amFlamethrower, 1, 0, 0, 1)

	SetAmmo(amFirePunch, 9, 0, 0, 0)
	SetAmmo(amBaseballBat, 2, 0, 0, 0)
	--SetAmmo(amKamikaze, 2, 0, 0, 0)


	SetAmmo(amDynamite,2,0,0,1)
	SetAmmo(amSMine,4,0,0,0)

	SetAmmo(amBlowTorch, 9, 0, 0, 0)
	SetAmmo(amPickHammer, 9, 0, 0, 0)
	SetAmmo(amGirder, 2, 0, 0, 2)
	SetAmmo(amPortalGun, 2, 0, 0, 2)

	SetAmmo(amParachute, 9, 0, 0, 0)
	SetAmmo(amRope, 9, 0, 0, 0)
	SetAmmo(amTeleport, 0, 0, 0, 1)
	SetAmmo(amJetpack, 1, 0, 0, 1)

	SetAmmo(amSwitch, 2, 0, 0, 1)
	SetAmmo(amExtraTime,1,0,0,1)
	SetAmmo(amLowGravity,1,0,0,0)
	SetAmmo(amSkip, 9, 0, 0, 0)

end


function onGearResurrect(gear)

	--AddCaption("A gear has been resurrected!")

	-- mark the flag thief as dead if he needed a respawn
	for i = 0,1 do
		if gear == fThief[i] then
			FlagThiefDead(gear)
		end
	end

	-- place hogs belonging to each clan either left or right side of map
	if GetHogClan(gear) == 0 then
		FindPlace(gear, false, 0, 2048)
	elseif GetHogClan(gear) == 1 then
		FindPlace(gear, false, 2048, LAND_WIDTH)
	end

	AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)

end

function onGearDamage(gear, damage)

	-- >_< damn, occurs too fast, before the hog has finished moving / updated his health
	--if GetGearType(gear) == gtHedgehog then
	--	if damage > GetHealth(gear) then
	--		AddVisualGear(GetX(gear), GetY(gear), vgtExplosion, 0, false)
	--	end
	--end

end

function onGearAdd(gear)

	if GetGearType(gear) == gtHedgehog then

		hhs[numhhs] = gear
		numhhs = numhhs + 1
		SetEffect(gear, heResurrectable, 1)

	end

	if GetGearType(gear) == gtRope then
		ropeGear = gear
	end

end

function onGearDelete(gear)

	if (gear == fGear[0]) or (gear == fGear[1]) then
		FlagDeleted(gear)
	end

	if GetGearType(gear) == gtRope then
		ropeGear = nil
	end

	if GetGearType(gear) == gtHedgehog then
		for i = 0, (numhhs-1) do
			if gear == hhs[i] then
				
				for k = 0,1 do
					if gear == fThief[k] then
						FlagThiefDead(gear)
					end
				end				
				hhs[i] = nil	
			end		
		end
	end

end

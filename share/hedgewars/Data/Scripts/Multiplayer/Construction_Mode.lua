---------------------------------------------------------
--- LE CONSTRUCTION MODE 0.7+ (badly adapted from Hedge Editor 0.5)
---------------------------------------------------------
-- a hedgewars gameplay mode by mikade
-- special thanks to all who helped test and offered suggestions
-- additional thanks to sheepluva/nemo for adding some extra hooks

-- (to do)
-- investigate loc not working on addcaptions
-- check for parsecommands before porting to dev
-- test onUpDown more extensively as it may need revision (check for amRubber etc)
-- test localization of weapons and utils and stuff

-- try posistion grenades in Harmer so it blows hogs away from the struc
-- and don't explode too close to the struc

-- additional/previous balance ideas
-- based on your money?
-- based on the number of strucs/gens you own?
-- based on your existing arsenal?
-- limit number of crates spawned per round perhaps (done)
-- limit number of generators?

------------------------------------------------------------------------------
-- SCRIPT PARAMETER
------------------------------------------------------------------------------
-- The script parameter can be used to configure the energy
-- of the game. It is a comma-seperated list of key=value pairs, where each
-- key is a word and each value is an integer between 0 and 4294967295.
--
-- Possible keys:
--- initialenergy: Amount of energy that each team starts with (default: 550)
---                Note: Must be smaller than or equal to maxenergy
--- energyperround: Amount of energy that each team gets per round (default: 50)
--- maxenergy: Maximum amount of energy each team can hold (default: 1000)
--- cratesperround: Maximum number of crates you can place per round (default: 5)

-- For the previous 2 keys, you can use the value “inf” for an unlimited amount

-- Example: “initialenergy=750, maxenergy=2000” starts thee game with 750 energy
--          and sets the maximum energy to 2000.
-- Example: “craterperround=inf” disables the crate placement limit.

------------------------------------------------------------------------------
--version history
------------------------------------------------------------------------------
--v0.1
-- concept test

--v0.2
-- improved documentation (in script and in game)
-- improved localisation (or is it? at any rate, crate placement should now say e.g. Bazooka and not amBazooka)
-- added variable weapon costs (based on the values from Vatten's Consumerism script)

-- added reflector shield (still needs work and balancing)
-- added weapon-filter (probably ok)

-- enabled super weapons like ballgun, rcplane, watermelon, hellish to test balance
-- reduce max money to 1000

--v0.3
-- some /s removed

--v0.4
-- added support for per hog ammo (hopefully)

--v0.5 (dev)
-- added somewhat horribly implemented support for different structure sprites
-- added override pictures for ammo menu
-- added override message on wep select to aid understanding
-- split menu into/between weps/parts: struc, crates, gears
-- add a limit on crates per turn
-- add a limit on extra time per turn
-- add a test level
-- restored rubber placement
-- cleaned up some of the code a bit and removed about 280 lines of code I didn't need, lol

--v0.6 (dev)
-- added magic dance

--v0.7 (pushed to repo)
-- added a cfg file
-- removed another 903 lines of code we weren't using (lol)

--v0.7+ (merged in repo)
-- applied Wuzzy's patches:
--   script parameters: initialenergy, energyperround, maxenergy
--   fix crate costs
--   various minor tweaks and fixes
--   (see commits in official repo)
-- make Construction Mode play well together with fort mode (clan order = fort order)

--------------------------------
-- STRUCTURES LIST / IDEAS
--------------------------------

--Healing Station: heals hogs to 150 life
--Teleportation Node: allows teleporting to any other teleporter nodes
--Bio-filter: explodes enemy hogs
--Respawner: if you have one of these, any slain hogs are resurrected here :D
--Generator: generates energy (used to buy stuff, and possibly later other strucs might have upkeep costs)
--Support Station: allows purchasing of weapons, utilities, and med-crates
--Construction Station: allows purchasing of girders, rubber, mines, sticky mines, barrels
--Reflector Shield: reflect projectiles
--Weapon Filter: kill all equipement of enemy hogs passing through this area.


--to make the grill more attractive make it vaporize flying saucers
--and also rope, and maybe incoming gears

-- make healing thing also cure poison
-- maybe make poison more virulent and dangerous

--(not implemented / abandoned ideas)
-- Core: allows construction of other structures.
-- Automated Turret (think red drones from space invasion)
-- Canon (gives access to 3 fireballs per turn while near)
-- something that allows control of wind/water
-- Gravity Field generator : triggers world gravity change

-- structures consume power over time and
-- maybe you can turn structures OFF/ON, manually to save power.

-- hacking
-- allow hacking of structures, either being able to use enemy structures,
-- or turning a team's structures against them.

-- pylons
-- allow hogs to put down a pylon-like gear which then allows the core
-- to place other structures/objects within the pylon's sphere of influence
-- this would allow aggressive structure advancement

-- resouce mining?
-- you could designate something like mines, that you could get close to,
-- "pick up", and then "drop" back at a central location to simulate
-- resource mining. bit complicated/meh, normal power generators probably easier

-- it would be cool to have a red mask we could apply over girders
-- that would indicate they were Indestructible

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

----------------------------------------------
-- STRUC CRAP
----------------------------------------------

strucID = {}
strucGear = {}
strucClan = {}
strucType = {}
strucCost = {}
strucHealth = {}

strucCirc = {}
strucCircCol = {}
strucCircRadius = {}
strucCircType = {}
strucAltDisplay = {}

fortMode = false

placedExpense = 0

tempID = nil

sUID = 0

colorRed = 0xff0000ff
colorGreen = 0x00ff00ff

clanBoundsSX = {}
clanBoundsSY = {}
clanBoundsEX = {}
clanBoundsEY = {}

clanPower = {}
clanID = {}
clanLStrucIndex = {}

clanLWepIndex = {} -- for ease of use let's track this stuff
clanLUtilIndex = {}
clanLGearIndex = {}
clanUsedExtraTime = {}
clanCratesSpawned = {}
clanFirstTurn = {}

effectTimer = 0

wallsVisible = false
wX = {}
wY = {}
wWidth = {}
wHeight = {}
wCol = {}
margin = 20

clanPowerTag = nil
lastWep = nil

checkForSpecialWeaponsIn = -1

-- Fake ammo types, for the overwritten weapons in Construction Mode
amCMStructurePlacer = amAirAttack
amCMCratePlacer = amNapalm
amCMObjectPlacer = amDrillStrike

-- Config variables (script parameter)
conf_initialEnergy = 550
conf_energyPerRound = 50
conf_maxEnergy = 1000
conf_cratesPerRound = 5

function DrawClanPowerTag()

	zoomL = 1.3

	xOffset = 40

	zoomL = 1.1
	xOffset = 45
	yOffset = 70
	tCol = 0x00ff00ff
	tValue = clanPower[GetHogClan(CurrentHedgehog)]

	DeleteVisualGear(clanPowerTag)
	clanPowerTag = AddVisualGear(0, 0, vgtHealthTag, 0, false)
	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(clanPowerTag)
	SetVisualGearValues	(
				clanPowerTag, 		--id
				-div(ScreenWidth,2) + xOffset,	--xoffset
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

function onScreenResize()

	-- redraw Tags so that their screen locations are updated
	if (CurrentHedgehog ~= nil) then
		DrawClanPowerTag()
	end

end

function XYisInRect(px, py, psx, psy, pex, pey)

	if (px > psx) and (px < pex) and (py > psy) and (py < pey) then
		return(true)
	else
		return(false)
	end

end

function AddWall(zXMin,zYMin, zWidth, zHeight, zCol)

	table.insert(wX, zXMin)
	table.insert(wY, zYMin)
	table.insert(wWidth, zWidth)
	table.insert(wHeight, zHeight)
	table.insert(wCol, zCol)

end

function BorderSpark(zXMin,zYMin, zWidth, zHeight, bCol)

	eX = zXMin + GetRandom(zWidth+10)
	eY = zYMin + GetRandom(zHeight+10)
	tempE = AddVisualGear(eX, eY, vgtDust, 0, false)
	if tempE ~= 0 then
		g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
		SetVisualGearValues(tempE, eX, eY, g3, g4, g5, g6, g7, 1, g9, bCol )
	end

end

function HandleBorderEffects()

	effectTimer = effectTimer + 1
	if effectTimer > 15 then
		effectTimer = 1
		for i = 1, #wX do
			BorderSpark(wX[i],wY[i],wWidth[i],wHeight[i], wCol[i])
		end
	end

end

----
-- old reflecting stuff from like 3 years ago lol
---

function gearCanBeDeflected(gear)

	if 	(GetGearType(gear) == gtShell) or
		(GetGearType(gear) == gtGrenade) or
		(GetGearType(gear) == gtAirBomb) or
		(GetGearType(gear) == gtClusterBomb) or
		(GetGearType(gear) == gtCluster) or
		(GetGearType(gear) == gtGasBomb) or
		(GetGearType(gear) == gtMine) or
		(GetGearType(gear) == gtMortar) or
		(GetGearType(gear) == gtHellishBomb) or
		(GetGearType(gear) == gtWatermelon) or
		(GetGearType(gear) == gtMelonPiece)	or
		(GetGearType(gear) == gtEgg) or
		(GetGearType(gear) == gtDrill) or
		(GetGearType(gear) == gtBall) or
		(GetGearType(gear) == gtExplosives) or
			(GetGearType(gear) == gtFlame) or
			(GetGearType(gear) == gtPortal) or
			(GetGearType(gear) == gtDynamite) or
			(GetGearType(gear) == gtSMine) or
		(GetGearType(gear) == gtKnife) or
		(GetGearType(gear) == gtJetpack) or -- test this and birdy plz
		(GetGearType(gear) == gtBirdy) or -- test this and birdy plz
		(GetGearType(gear) == gtSnowball) or
		(GetGearType(gear) == gtMolotov)
	then
		return(true)
	else
		return(false)
	end

end

function getThreatDamage(gear)

	--- damage amounts for weapons
	if 	(GetGearType(gear) == gtGrenade) or
		(GetGearType(gear) == gtClusterBomb) or
		(GetGearType(gear) == gtGasBomb) or
		(GetGearType(gear) == gtKnife) or
		(GetGearType(gear) == gtEgg) or
		(GetGearType(gear) == gtMolotov) or
		(GetGearType(gear) == gtHellishBomb) or
		(GetGearType(gear) == gtWatermelon) or
		(GetGearType(gear) == gtSMine)
	then
		dmg = 30

	elseif (GetGearType(gear) == gtMelonPiece) then
		dmg = 40

	elseif (GetGearType(gear) == gtAirBomb) or
			(GetGearType(gear) == gtDrill) or
			(GetGearType(gear) == gtMine) or
			(GetGearType(gear) == gtCluster) then
		dmg = 20

	elseif (GetGearType(gear) == gtFlame) or
			(GetGearType(gear) == gtPortal) or
			(GetGearType(gear) == gtDynamite)
	then
		dmg = 0

	elseif (GetGearType(gear) == gtBall) then
		dmg = 1

	else	--normal shell, snowball etc
		dmg = 65
	end

	return(dmg)

end

function setGearReflectionValues(gear)

	dmg = getThreatDamage(gear)
	setGearValue(gear,"damage",dmg)
	setGearValue(gear,"deflects",0)

	if (CurrentHedgehog ~= nil) then
		setGearValue(gear,"owner",GetHogClan(CurrentHedgehog)) -- NEW NEEDS CHANGE?
	else
		setGearValue(gear,"owner",10)
	end

end

function AddStruc(pX,pY, pType, pClan)

	sUID = sUID + 1

	tempG = AddGear(0, 0, gtTarget, 0, 0, 0, 0)
	SetGearPosition(tempG, pX, pY)
	setGearValue(tempG, "sUID", sUID)

	tempCirc = AddVisualGear(0,0,vgtCircle,0,true)

	SetVisualGearValues(tempCirc, 0, 0, 100, 255, 1, 100, 0, 500, 1, 0xFFFFFF00)

	table.insert(strucID, sUID)
	table.insert(strucType, pType)
	table.insert(strucGear,tempG)
	table.insert(strucClan,pClan)
	table.insert(strucCost,2)

	frameID = 0
	visualSprite = sprTarget
	madness = AddVisualGear(GetX(tempG), GetY(tempG), vgtStraightShot, 1, true,1)
	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(madness)	--g9


	if pType == loc("Reflector Shield") then
		table.insert(strucHealth,255)

	else
		table.insert(strucHealth,1)
	end

	table.insert(strucCirc,tempCirc)

	table.insert(strucCircType, 1)
	if pType == loc("Bio-Filter") then
		table.insert(strucCircCol,colorRed)
		table.insert(strucCircRadius,1000)
		frameID = 7
	elseif pType == loc("Healing Station") then
		table.insert(strucCircCol,0xFF00FF00)
		table.insert(strucCircRadius,500)
		frameID = 3
	elseif pType == loc("Respawner") then
		table.insert(strucCircCol,0xFF00FF00)
		table.insert(strucCircRadius,75)
		runOnHogs(EnableHogResurrectionForThisClan)
		frameID = 1
	elseif pType == loc("Teleportation Node") then
		table.insert(strucCircCol,0x0000FFFF)
		table.insert(strucCircRadius,350)
		frameID = 6
	elseif pType == loc("Generator") then
		table.insert(strucCircCol,0xFFFF00FF)
		table.insert(strucCircRadius,75)
		setGearValue(tempG, "power", 0)
		frameID = 2
	elseif pType == loc("Support Station") then
		table.insert(strucCircCol,0xFFFF00FF)
		table.insert(strucCircRadius,500)
		frameID = 4
	elseif pType == loc("Construction Station") then
		table.insert(strucCircCol,0xFFFFFFFF)
		table.insert(strucCircRadius,500)
		frameID = 8
	elseif pType == loc("Reflector Shield") then
		table.insert(strucCircCol,0xffae00ff)
		table.insert(strucCircRadius,750)
		frameID = 9
	elseif pType == loc("Weapon Filter") then
		table.insert(strucCircCol,0xa800ffff)
		table.insert(strucCircRadius,750)
		frameID = 5
	end


	SetVisualGearValues(madness, g1, g2, 0, 0, g5, frameID, g7, visualSprite, g9, g10 )
	SetState(tempG, bor(GetState(tempG),gstInvisible) )
	table.insert(strucAltDisplay, madness)

end

-- this is basically onStructureDelete
-- we may need to expand it for non-gear structures later
function CheckGearForStructureLink(gear)

	respawnerDestroyed = false

	for i = 1, #strucID do
		if strucID[i] == getGearValue(gear,"sUID") then

			if strucType[i] == loc("Respawner") then
				respawnerDestroyed = true
			end

			table.remove(strucID,i)
			table.remove(strucGear,i)
			table.remove(strucClan,i)
			table.remove(strucType,i)
			table.remove(strucCost,i)
			table.remove(strucHealth,i)

			DeleteVisualGear(strucCirc[i])
			table.remove(strucCirc,i)

			table.remove(strucCircCol,i)
			table.remove(strucCircRadius,i)
			table.remove(strucCircType,i)

			if strucAltDisplay[i] ~= 1 then
				DeleteVisualGear(strucAltDisplay[i])
			end
			table.remove(strucAltDisplay,i)

		end
	end

	if respawnerDestroyed == true then
		runOnHogs(RecalibrateRespawn)
	end

end

-- called when we add a new respawner
function EnableHogResurrectionForThisClan(gear)
	if GetHogClan(gear) == GetHogClan(CurrentHedgehog) then
		SetEffect(gear, heResurrectable, 1)
	end
end

-- this is called when a respawner blows up
function RecalibrateRespawn(gear)

	respawnerList = {}
	for i = 1, #strucID do
		if (strucType[i] == loc("Respawner")) and (strucClan[i] == GetHogClan(gear)) then
			table.insert(respawnerList, i)
		end
	end

	if #respawnerList >= 1 then
		SetEffect(gear, heResurrectable, 1)
	else
		SetEffect(gear, heResurrectable, 0)
	end

end

--resposition dead hogs at a respawner if they own one
function FindRespawner(gear)

	respawnerList = {}
	for i = 1, #strucID do
		if (strucType[i] == loc("Respawner")) and (strucClan[i] == GetHogClan(gear)) then
			table.insert(respawnerList, i)
		end
	end

	if #respawnerList >= 1 then
		i = GetRandom(#respawnerList)+1
		SetGearPosition(gear,GetX(strucGear[respawnerList[i]]),GetY(strucGear[respawnerList[i]])-25)
		AddVisualGear(GetX(gear), GetY(gear), vgtExplosion, 0, false)
	else	-- (this should never happen, but just in case)
		SetEffect(gear, heResurrectable, 0)
		DeleteGear(gear)
	end

end

function onGearResurrect(gear)
	AddVisualGear(GetX(gear), GetY(gear), vgtExplosion, 0, false)
	FindRespawner(gear)
end


function CheckTeleport(gear, tX, tY)

	teleportOriginSuccessful = false
	teleportDestinationSuccessful = false

	for i = 1, #strucID do

		if (strucType[i] == loc("Teleportation Node")) and (strucClan[i] == GetHogClan(CurrentHedgehog)) then

			dist = GetDistFromGearToXY(CurrentHedgehog,GetX(strucGear[i]), GetY(strucGear[i]))
			if strucCircType[i] == 0 then
				NR = strucCircRadius[i]
			else
				NR = (48/100*strucCircRadius[i])/2
			end
			if dist <= NR*NR then
				teleportOriginSuccessful = true
			end

			dist = GetDistFromXYtoXY(tX,tY,GetX(strucGear[i]), GetY(strucGear[i]))
			if strucCircType[i] == 0 then
				NR = strucCircRadius[i]
			else
				NR = (48/100*strucCircRadius[i])/2
			end
			if dist <= NR*NR then
				teleportDestinationSuccessful = true
			end

		end


	end

	if ((teleportDestinationSuccessful == false) or (teleportOriginSuccessful == false)) then
		AddCaption(loc("Teleport Unsuccessful. Please teleport within a clan teleporter's sphere of influence."))
		SetGearTarget(gear, GetX(CurrentHedgehog), GetY(CurrentHedgehog))
	end

end

--Check for proximity of gears to structures, and make structures behave accordingly
function CheckProximity(gear)

	dist = GetDistFromGearToXY(gear, GetX(strucGear[tempID]), GetY(strucGear[tempID]))
	if not dist then
		return
	end

	-- calculate my real radius if I am an aura
	if strucCircType[tempID] == 0 then
		NR = strucCircRadius[tempID]
	else
		NR = (48/100*strucCircRadius[tempID])/2
	end

	-- we're in business
	if dist <= NR*NR then


		-- heal clan hogs
		if strucType[tempID] == loc("Healing Station") then

			if GetGearType(gear) == gtHedgehog then
				if GetHogClan(gear) == strucClan[tempID] then

					local hogLife = GetHealth(gear)
					-- Heal hog by 1 HP, up to 150 HP total
					if hogLife < 150 then
						if ((hogLife + 1) % 5) == 0 then
							-- Health anim every 5 HP
							HealHog(gear, 1, false)
						else
							SetHealth(gear, hogLife+1)
						end
					end

					-- change this to the med kit sprite health ++++s later
					tempE = AddVisualGear(GetX(strucGear[tempID]), GetY(strucGear[tempID]), vgtSmoke, 0, true)
					g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
					SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, colorGreen )

				end
			end

		-- explode enemy clan hogs
		elseif strucType[tempID] == loc("Bio-Filter") then

			if GetGearType(gear) == gtHedgehog then
				if (GetHogClan(gear) ~= strucClan[tempID]) and (GetHealth(gear) > 0) then
					AddGear(GetX(gear), GetY(gear), gtGrenade, 0, 0, 0, 1)
				end
			end

		-- were those weapons in your pocket, or were you just happy to see me?
		elseif strucType[tempID] == loc("Weapon Filter") then

			if GetGearType(gear) == gtHedgehog then
				if (GetHogClan(gear) ~= strucClan[tempID]) then

					for wpnIndex = 1, #atkArray do
						AddAmmo(gear, atkArray[wpnIndex][1], 0)
					end

					for wpnIndex = 1, #utilArray do
						AddAmmo(gear, utilArray[wpnIndex][1], 0)
					end

					AddAmmo(gear, amCMStructurePlacer, 100)
					AddAmmo(gear, amSwitch, 100)
					AddAmmo(gear, amSkip, 100)

				end
			end

		-- BOUNCE! POGO! POGO! POGO! POGO!
		elseif strucType[tempID] == loc("Reflector Shield") then

			-- add check for whose projectile it is
			if gearCanBeDeflected(gear) == true then

				gOwner = getGearValue(gear,"owner")
				gDeflects = getGearValue(gear,"deflects")
				gDmg = getGearValue(gear,"damage")

				if gDeflects >= 3 then
					DeleteGear(gear)
					AddVisualGear(GetX(gear), GetY(gear), vgtSmoke, 0, false)
					PlaySound(sndVaporize)
				elseif gOwner ~= strucClan[tempID] then
					--whether to vaporize gears or bounce them
					if gDmg ~= 0 then
						dx, dy = GetGearVelocity(gear)

						if (dx == 0) and (dy == 0) then
							-- static mine, explosive, etc encountered
							-- do nothing
							else

							--let's bounce something!

							dx = dx*(-1)
							dy = dy*(-1)
							SetGearVelocity(gear,dx,dy)
							setGearValue(gear,"deflects",(gDeflects+1))

							AddVisualGear(GetX(gear), GetY(gear), vgtExplosion, 0, false)
							PlaySound(sndExplosion)

							strucHealth[tempID] = strucHealth[tempID] - gDmg
							strucCircCol[tempID] = strucCircCol[tempID] - gDmg

							if strucHealth[tempID] <= 0 then
								AddVisualGear(GetX(strucGear[tempID]), GetY(strucGear[tempID]), vgtExplosion, 0, false)
								DeleteGear(strucGear[tempID])
								PlaySound(sndExplosion)
							end

						end

					else
						DeleteGear(gear)
						AddVisualGear(GetX(gear), GetY(gear), vgtSmoke, 0, false)
						PlaySound(sndVaporize)
					end
				end
			end

		--mark as within range of a teleporter node
		elseif strucType[tempID] == loc("Teleportation Node") then

			if GetGearType(gear) == gtHedgehog then
				if GetHogClan(gear) == strucClan[tempID] then

					for i = 1, #sProx do
						if sProx[i][1] == loc("Teleportation Mode") then
							sProx[i][2] = true
						end
					end

				end
			end

		-- mark as within range of construction station
		-- and thus allow menu access to placement modes
		-- for girders, mines, sticky mines and barrels
		elseif strucType[tempID] == loc("Construction Station") then

			if GetGearType(gear) == gtHedgehog then
				if GetHogClan(gear) == strucClan[tempID] then
					tempE = AddVisualGear(GetX(strucGear[tempID]), GetY(strucGear[tempID]), vgtSmoke, 0, true)

					for i = 1, #sProx do
						if ((sProx[i][1] == loc("Girder Placement Mode"))
						or (sProx[i][1] == loc("Rubber Placement Mode"))
						or (sProx[i][1] == loc("Mine Placement Mode"))
						or (sProx[i][1] == loc("Sticky Mine Placement Mode"))
						or (sProx[i][1] == loc("Barrel Placement Mode")))
						then
							sProx[i][2] = true
						end
					end


				end
			end

		-- mark as within stupport station range
		-- and thus allow menu access to placement modes
		-- for weapon, utility, and med crates
		elseif strucType[tempID] == loc("Support Station") then

			if GetGearType(gear) == gtHedgehog then
				if GetHogClan(gear) == strucClan[tempID] then
					tempE = AddVisualGear(GetX(strucGear[tempID]), GetY(strucGear[tempID]), vgtSmoke, 0, true)

					for i = 1, #sProx do
						if ((sProx[i][1] == loc("Health Crate Placement Mode"))
						or (sProx[i][1] == loc("Weapon Crate Placement Mode"))
						or (sProx[i][1] == loc("Utility Crate Placement Mode")))
						then
							sProx[i][2] = true
						end
					end


				end
			end
		end

	end

end

-- used to check if we need to run through all hogs or just currenthedgehog
function isAStructureThatAppliesToMultipleGears(pID)
	if 	strucType[pID] == loc("Healing Station") or
		strucType[pID] == loc("Reflector Shield") or
		strucType[pID] == loc("Weapon Filter") or
		strucType[pID] == loc("Bio-Filter")
	then
		return(true)
	else
		return(false)
	end
end

function HandleStructures()

	if GameTime % 100 == 0 then
		for i = 1, #sProx do
			sProx[i][2] = false

			if sProx[i][1] == loc("Structure Placement Mode") then
				sProx[i][2] = true
			end

		end
	end

	for i = 1, #strucID do

		SetVisualGearValues(strucCirc[i], GetX(strucGear[i]), GetY(strucGear[i]), nil, nil, nil, nil, nil, strucCircRadius[i], nil, strucCircCol[i])

		tempID = i

		SetVisualGearValues(strucAltDisplay[i], GetX(strucGear[i]), GetY(strucGear[i]), 0, 0, nil, nil, 800000, sprTarget)

		if GameTime % 100 == 0 then
			-- Check For proximity of stuff to our structures
			if isAStructureThatAppliesToMultipleGears(i) then
				runOnGears(CheckProximity)
			else -- only check prox on CurrentHedgehog
				if CurrentHedgehog ~= nil then
					CheckProximity(CurrentHedgehog)
				end
			end

			if strucType[i] == loc("Generator") then

				for z = 0, ClansCount-1 do
					if z == strucClan[i] then
						increaseGearValue(strucGear[i],"power")
						if getGearValue(strucGear[i],"power") == 10 then
							setGearValue(strucGear[i],"power",0)
							clanPower[z] = clanPower[z] + 1
							if conf_maxEnergy ~= "inf" and clanPower[z] > conf_maxEnergy then
								clanPower[z] = conf_maxEnergy
							end
						end

					end
				end
			end

		end

	end



	-- this is kinda messy and gross (even more than usual), fix it up at some point
	-- it just assumes that if you have access to girders, it works for rubbers
	-- as that is what the struc implemenation means due to construction station
	if GameTime % 100 == 0 and CurrentHedgehog ~= nil then
		anyUIProx = false
		for i = 1, #sProx do

			if sProx[i][1] == loc("Girder Placement Mode") then
				if sProx[i][2] == true then
					AddAmmo(CurrentHedgehog, amGirder, 100)
					AddAmmo(CurrentHedgehog, amRubber, 100)
					AddAmmo(CurrentHedgehog, amCMObjectPlacer, 100)
				else
					AddAmmo(CurrentHedgehog, amGirder, 0)
					AddAmmo(CurrentHedgehog, amRubber, 0)
					AddAmmo(CurrentHedgehog, amCMObjectPlacer, 0) -- new
				end
			elseif sProx[i][1] == loc("Teleportation Mode") then
				if sProx[i][2] == true then
					AddAmmo(CurrentHedgehog, amTeleport, 100)
				else
					AddAmmo(CurrentHedgehog, amTeleport, 0)
				end
			elseif sProx[i][1] == loc("Weapon Crate Placement Mode") then
				-- this is new stuff
				if sProx[i][2] == true then
					AddAmmo(CurrentHedgehog, amCMCratePlacer, 100)
				else
					AddAmmo(CurrentHedgehog, amCMCratePlacer, 0)
				end
			end

			if (sProx[i][2] == true) then
				anyUIProx = true
			end

		end
	end

end


function checkForSpecialWeapons()

	if (GetCurAmmoType() == amCMObjectPlacer) then
		AddCaption(loc("Object Placer"),GetClanColor(GetHogClan(CurrentHedgehog)),capgrpAmmoinfo)
	end

	lastWep = GetCurAmmoType()

end

----------------------------------------------------------
-- EXCERPTS OF ADAPTED HEDGE_EDITOR CODE FOLLOWS
----------------------------------------------------------
-- experimental crap

local landType = 0
-----------------------------------------
-- tracking vars for save slash load purposes
-----------------------------------------

local hhs = {}

---------------------------------
-- crates are made of this stuff
---------------------------------
placeholder = 20
 atkArray =
				{
				{amBazooka, 	"amBazooka",		0, 2*placeholder},
				--{amBee, 		"amBee",			0, loc("Homing Bee"), 		4*placeholder},
				{amMortar, 		"amMortar",			0, 1*placeholder},
				{amDrill, 		"amDrill",			0, 3*placeholder},
				{amSnowball, 	"amSnowball",		0, 3*placeholder},

				{amGrenade,		"amGrenade",		0, 2*placeholder},
				{amClusterBomb,	"amClusterBomb",	0, 3*placeholder},
				{amWatermelon, 	"amWatermelon",		0, 25*placeholder},
				{amHellishBomb,	"amHellishBomb",	0, 25*placeholder},
				{amMolotov, 	"amMolotov",		0, 3*placeholder},
				{amGasBomb, 	"amGasBomb",		0, 3*placeholder},

				{amShotgun,		"amShotgun",		0, 2*placeholder},
				{amDEagle,		"amDEagle",			0, 2*placeholder},
				{amSniperRifle,	"amSniperRifle",	0, 3*placeholder},
				--{amSineGun, 	"amSineGun",		0, loc("Sine Gun"), 			6*placeholder},
				{amFlamethrower,"amFlamethrower",	0, 4*placeholder},
				{amIceGun, 		"amIceGun",			0, 15*placeholder},

				{amFirePunch, 	"amFirePunch",		0, 3*placeholder},
				{amWhip,		"amWhip",			0, 1*placeholder},
				{amBaseballBat, "amBaseballBat",	0, 7*placeholder},
				--{amKamikaze, 	"amKamikaze",		0, loc("Kamikaze"),			1*placeholder},
				{amSeduction, 	"amSeduction",		0, 1*placeholder},
				{amHammer,		"amHammer",			0, 1*placeholder},

				{amMine, 		"amMine",			0, 1*placeholder},
				{amDynamite, 	"amDynamite",		0, 9*placeholder},
				{amCake, 		"amCake",			0, 25*placeholder},
				{amBallgun, 	"amBallgun",		0, 40*placeholder},
				--{amRCPlane,		"amRCPlane",		0, loc("RC Plane"), 	25*placeholder},
				{amSMine,		"amSMine",			0, 5*placeholder},

				-- Careful! Some airborne attacks are overwritten by the special Construction Mode tools

				--{amAirAttack,	"amAirAttack",		0, loc("Air Attack"), 		10*placeholder},
				--{amMineStrike,	"amMineStrike",		0, loc("Mine Strike"), 		15*placeholder},
				--{amNapalm, 		"amNapalm",			0, loc("Napalm"), 		15*placeholder},
				--{amPiano,		"amPiano",			0, loc("Piano Strike"), 	40*placeholder},
				--{amDrillStrike,	"amDrillStrike",	0, loc("Drill Strike"), 15*placeholder},

				{amPickHammer,		"amPickHammer",		0, 2*placeholder},
				{amBlowTorch, 		"amBlowTorch",		0, 4*placeholder},
				{amKnife,		"amKnife",			0, 2*placeholder},

				{amBirdy,		"amBirdy",			0, 7*placeholder},

				{amDuck,		"amDuck",			0, 2*placeholder}

				}

 utilArray =
				{
				--{amGirder, 			"amGirder",			0, loc("Girder"), 		4*placeholder},
				{amLandGun,		"amLandGun",		0, 5*placeholder},
				--{amRubber, 			"amRubber",			0, loc("Rubber"), 	5*placeholder},

				{amRope, 			"amRope",	0, 7*placeholder},
				{amParachute, 		"amParachute",		0, 2*placeholder},
				--{amTeleport,		"amTeleport",		0, loc("Teleport"), 		6*placeholder},
				{amJetpack,			"amJetpack",	0, 8*placeholder},
				{amPortalGun,		"amPortalGun",		0, 15*placeholder},

				{amInvulnerable,	"amInvulnerable",	0, 5*placeholder},
				{amLaserSight,		"amLaserSight",		0, 2*placeholder},
				{amVampiric,		"amVampiric",		0, 6*placeholder},
				--{amResurrector, 	"amResurrector",	0, loc("Resurrector"), 		8*placeholder},
				--{amTardis, 			"amTardis",			0, loc("Time Box"), 			2*placeholder},

				--{amSwitch,			"amSwitch",			0, loc("Switch Hog"), 		4*placeholder}
				{amLowGravity, 		"amLowGravity",		0, 4*placeholder},
				{amExtraDamage, 	"amExtraDamage",	0, 6*placeholder},
				{amExtraTime,		"amExtraTime",		0, 8*placeholder}

				}

----------------------------
-- placement shite
----------------------------

local cGear = nil -- detects placement of girders and objects (using airattack)
local curWep = amNothing

-- primary placement categories
local cIndex = 1 -- category index
local cat = 	{
				"Girder Placement Mode",
				"Rubber Placement Mode",
				"Mine Placement Mode",
				"Sticky Mine Placement Mode",
				"Barrel Placement Mode",
				"Weapon Crate Placement Mode",
				"Utility Crate Placement Mode",
				"Health Crate Placement Mode",
				"Structure Placement Mode"
				}


 sProx = 	{
				{loc("Girder Placement Mode"),false},
				{loc("Rubber Placement Mode"),false},
				{loc("Mine Placement Mode"),false},
				{loc("Sticky Mine Placement Mode"),false},
				{loc("Barrel Placement Mode"),false},
				{loc("Weapon Crate Placement Mode"),false},
				{loc("Utility Crate Placement Mode"),false},
				{loc("Health Crate Placement Mode"),false},
				{loc("Structure Placement Mode"),false},
				{loc("Teleportation Mode"),false}
				}


local pMode = {}	-- pMode contains custom subsets of the main categories
local pIndex = 1

local CGR = 1 -- current girder rotation, we actually need this as HW remembers what rotation you last used

local placedX = {}
local placedY = {}
local placedSpec = {}
local placedSuperSpec = {}
local placedType = {}
local placedCount = 0

local sCirc -- circle that appears around selected gears
local sGear = nil
local closestDist
local closestGear = nil

local tCirc = {} -- array of circles that appear around tagged gears

------------------------
-- SOME GENERAL METHODS
------------------------

function GetDistFromGearToXY(gear, g2X, g2Y)

	g1X, g1Y = GetGearPosition(gear)
	if not g1X then
		return nil
	end
	q = g1X - g2X
	w = g1Y - g2Y

	return ( (q*q) + (w*w) )

end

function GetDistFromXYtoXY(a, b, c, d)
	q = a - c
	w = b - d
	return ( (q*q) + (w*w) )
end

function SelectGear(gear)

	d = GetDistFromGearToXY(gear, placedX[placedCount], placedY[placedCount])

	if d < closestDist then
		closestDist = d
		closestGear = gear
	end

end

-- essentially called when user clicks the mouse
-- with girders or an airattack
function PlaceObject(x,y)

	placedX[placedCount] = x
	placedY[placedCount] = y
	placedType[placedCount] = cat[cIndex]
	placedSpec[placedCount] = pMode[pIndex]

	if (clanUsedExtraTime[GetHogClan(CurrentHedgehog)] == true) and (cat[cIndex] == "Utility Crate Placement Mode") and (utilArray[pIndex][1] == amExtraTime) then
		AddCaption(loc("You may only place 1 Extra Time crate per turn."),0xffba00ff,capgrpVolume)
		PlaySound(sndDenied)
	elseif (conf_cratesPerRound ~= "inf" and clanCratesSpawned[GetHogClan(CurrentHedgehog)] >= conf_cratesPerRound) and ( (cat[cIndex] == "Health Crate Placement Mode") or (cat[cIndex] == "Utility Crate Placement Mode") or (cat[cIndex] == "Weapon Crate Placement Mode")  )  then
		AddCaption(string.format(loc("You may only place %d crates per round."), conf_cratesPerRound),0xffba00ff,capgrpVolume)
		PlaySound(sndDenied)
	elseif (XYisInRect(x,y, clanBoundsSX[GetHogClan(CurrentHedgehog)],clanBoundsSY[GetHogClan(CurrentHedgehog)],clanBoundsEX[GetHogClan(CurrentHedgehog)],clanBoundsEY[GetHogClan(CurrentHedgehog)]) == true)
	and (clanPower[GetHogClan(CurrentHedgehog)] >= placedExpense)
	then
		-- For checking if the actual placement succeeded
		local placed = false
		if cat[cIndex] == "Girder Placement Mode" then
			placed = PlaceGirder(x, y, CGR)
			placedSpec[placedCount] = CGR
		elseif cat[cIndex] == "Rubber Placement Mode" then
			placed = PlaceRubber(x, y, CGR)
			placedSpec[placedCount] = CGR
		elseif cat[cIndex] == "Health Crate Placement Mode" then
			gear = SpawnHealthCrate(x,y)
			if gear ~= nil then
				placed = true
				SetHealth(gear, pMode[pIndex])
				setGearValue(gear,"caseType","med")
				clanCratesSpawned[GetHogClan(CurrentHedgehog)] = clanCratesSpawned[GetHogClan(CurrentHedgehog)] +1
			end
		elseif cat[cIndex] == "Weapon Crate Placement Mode" then
			gear = SpawnAmmoCrate(x, y, atkArray[pIndex][1])
			if gear ~= nil then
				placed = true
				placedSpec[placedCount] = atkArray[pIndex][2]
				setGearValue(gear,"caseType","ammo")
				setGearValue(gear,"contents",atkArray[pIndex][2])
				clanCratesSpawned[GetHogClan(CurrentHedgehog)] = clanCratesSpawned[GetHogClan(CurrentHedgehog)] +1
			end
		elseif cat[cIndex] == "Utility Crate Placement Mode" then
			gear = SpawnUtilityCrate(x, y, utilArray[pIndex][1])
			if gear ~= nil then
				placed = true
				placedSpec[placedCount] = utilArray[pIndex][2]
				setGearValue(gear,"caseType","util")
				setGearValue(gear,"contents",utilArray[pIndex][2])
				if utilArray[pIndex][1] == amExtraTime then
					clanUsedExtraTime[GetHogClan(CurrentHedgehog)] = true
				end
				clanCratesSpawned[GetHogClan(CurrentHedgehog)] = clanCratesSpawned[GetHogClan(CurrentHedgehog)] +1
			end
		elseif cat[cIndex] == "Barrel Placement Mode" then
			gear = AddGear(x, y, gtExplosives, 0, 0, 0, 0)
			if gear ~= nil then
				placed = true
				SetHealth(gear, pMode[pIndex])
			end
		elseif cat[cIndex] == "Mine Placement Mode" then
			gear = AddGear(x, y, gtMine, 0, 0, 0, 0)
			if gear ~= nil then
				placed = true
				SetTimer(gear, pMode[pIndex])
			end
		elseif cat[cIndex] == "Sticky Mine Placement Mode" then
			gear = AddGear(x, y, gtSMine, 0, 0, 0, 0)
			placed = gear ~= nil
		elseif cat[cIndex] == "Structure Placement Mode" then
			AddStruc(x,y, pMode[pIndex],GetHogClan(CurrentHedgehog))
			placed = true
		end

		if placed then
			clanPower[GetHogClan(CurrentHedgehog)] = clanPower[GetHogClan(CurrentHedgehog)] - placedExpense
			placedCount = placedCount + 1
		else
			AddCaption(loc("Invalid Placement"),0xffba00ff,capgrpVolume)
			PlaySound(sndDenied)
		end

	else
	    if (clanPower[GetHogClan(CurrentHedgehog)] >= placedExpense) then
            AddCaption(loc("Invalid Placement"),0xffba00ff,capgrpVolume)
        else
            AddCaption(loc("Insufficient Power"),0xffba00ff,capgrpVolume)
        end
		PlaySound(sndDenied)
	end


end

-- called when user changes primary selection
-- either via up/down keys
-- or selecting girder/airattack
function RedefineSubset()

	pIndex = 1
	pMode = {}
	placedExpense = 1

	if cat[cIndex] == "Girder Placement Mode" then
		pIndex = CGR
		pMode = {loc("Girder")}
	elseif cat[cIndex] == "Rubber Placement Mode" then
		pIndex = CGR
		pMode = {loc("Rubber")}
		placedExpense = 3
	elseif cat[cIndex] == "Barrel Placement Mode" then
		pMode = {60}
		placedExpense = 10
	elseif cat[cIndex] == "Health Crate Placement Mode" then
		pMode = {HealthCaseAmount}
		placedExpense = 5
	elseif cat[cIndex] == "Weapon Crate Placement Mode" then
		for i = 1, #atkArray do
			pMode[i] = GetAmmoName(atkArray[i][1])
		end
		placedExpense = atkArray[pIndex][4]
	elseif cat[cIndex] == "Utility Crate Placement Mode" then
		for i = 1, #utilArray do
			pMode[i] = GetAmmoName(utilArray[i][1])
		end
		placedExpense = utilArray[pIndex][4]
	elseif cat[cIndex] == "Mine Placement Mode" then
		pMode = {0,1000,2000,3000,4000,5000}
		placedExpense = 15
	elseif cat[cIndex] == "Sticky Mine Placement Mode" then
		pMode = {loc("Sticky Mine")}
		placedExpense = 20
	elseif cat[cIndex] == "Structure Placement Mode" then
		pMode = {loc("Healing Station"), loc("Bio-Filter"), loc("Weapon Filter"), loc("Reflector Shield"), loc("Respawner"),loc("Teleportation Node"),loc("Generator"),loc("Construction Station"),loc("Support Station")}
	end




end

-- called in onGameTick()
function HandleHedgeEditor()

	HandleStructures()

	if CurrentHedgehog ~= nil then

		if wallsVisible == true then
			HandleBorderEffects()
		end

		if (CurrentHedgehog ~= nil) and (TurnTimeLeft ~= TurnTime) then
			if (lastWep ~= GetCurAmmoType()) then
				checkForSpecialWeapons()
			elseif checkForSpecialWeaponsIn == 0 then
				checkForSpecialWeapons()
				checkForSpecialWeaponsIn = -1
			else
				checkForSpecialWeaponsIn = checkForSpecialWeaponsIn - 1
			end
		end

		if GameTime % 100 == 0 then

			DrawClanPowerTag()

			curWep = GetCurAmmoType()

			-- change to girder mode on weapon swap
			if (cIndex ~= 1) and (curWep == amGirder) then
				cIndex = 1
				RedefineSubset()
			elseif (cIndex ~=2) and (curWep == amRubber) then
				cIndex = 2
				RedefineSubset()
			-- change to generic mode if girder no longer selected
			elseif (cIndex == 1) and (curWep ~= amGirder) then
				cIndex = 3
				RedefineSubset()
			elseif (cIndex == 2) and (curWep ~= amRubber) then
				cIndex = 3
				RedefineSubset()

			end

			-- update display selection criteria
			if ((curWep == amGirder) or (curWep == amCMStructurePlacer) or (curWep == amCMCratePlacer) or (curWep == amCMObjectPlacer) or (curWep == amRubber))
				and (CurrentHedgehog ~= nil or band(GetState(CurrentHedgehog), gstHHDriven) ~= 0) then

				---------------hooolllllyyyy fucking shit this
				-- code is a broken mess now
				-- it was redesigned and compromised three times
				-- so now it is a mess trying to do what it was
				-- never designed to do
				-- needs to be rewritten badly sadface
				-- this bit here catches the new 3 types of weapons
				if ((sProx[cIndex][1] == loc("Structure Placement Mode") and (curWep ~= amCMStructurePlacer))) then
					updatePlacementDisplay(1)
				elseif (sProx[cIndex][1] == loc("Health Crate Placement Mode")) or
							(sProx[cIndex][1] == loc("Weapon Crate Placement Mode")) or
							(sProx[cIndex][1] == loc("Utility Crate Placement Mode")) then
								if curWep ~= amCMCratePlacer then
									updatePlacementDisplay(1)
								end

				elseif (sProx[cIndex][1] == loc("Mine Placement Mode")) or
							(sProx[cIndex][1] == loc("Sticky Mine Placement Mode")) or
							(sProx[cIndex][1] == loc("Barrel Placement Mode")) then
								if curWep ~= amCMObjectPlacer then
									updatePlacementDisplay(1)
								end

				end

				--this is called when it happens that we have placement
				--mode selected and we are looking at something
				--we shouldn't be allowed to look at, as would be the case
				--when you WERE allowed to look at it, but then maybe
				--a bomb blows up the structure that was granting you
				--that ability
				if (sProx[cIndex][2] ~= true) then
					updatePlacementDisplay(1)
				else
					updateCost()
				end


				AddCaption(loc(cat[cIndex]),0xffba00ff,capgrpMessage)
				showModeMessage()
				wallsVisible = true
			else
				wallsVisible = false
			end

		end

	end

	-- some kind of target detected, tell me your story
	if cGear ~= nil then

		x,y = GetGearTarget(cGear)

		if GetGearType(cGear) == gtAirAttack then
			DeleteGear(cGear)
			PlaceObject(x, y)
		elseif GetGearType(cGear) == gtTeleport then

				CheckTeleport(cGear, x, y)
				cGear = nil
		elseif GetGearType(cGear) == gtGirder then

			CGR = GetState(cGear)

			PlaceObject(x, y)
		end

	end

end

---------------------------------------------------------------
-- Cycle through selection subsets (by changing pIndex, pMode)
-- i.e 	health of barrels, medikits,
--		timer of mines
--		contents of crates
--		gears to reposition etc.
---------------------------------------------------------------

function updateCost()

	if CurrentHedgehog == nil or band(GetState(CurrentHedgehog), gstHHDriven) == 0 then return end

	if pMode[pIndex] == loc("Healing Station") then
		placedExpense = 50
	elseif pMode[pIndex] == loc("Weapon Filter") then
		placedExpense = 50
	elseif pMode[pIndex] == loc("Bio-Filter") then
		placedExpense = 100
	elseif pMode[pIndex] == loc("Respawner") then
		placedExpense = 300
	elseif pMode[pIndex] == loc("Teleportation Node") then
		placedExpense = 30
	elseif pMode[pIndex] == loc("Support Station") then
		placedExpense = 50
	elseif pMode[pIndex] == loc("Construction Station") then
		placedExpense = 50
	elseif pMode[pIndex] == loc("Generator") then
			placedExpense = 300
	elseif pMode[pIndex] == loc("Reflector Shield") then
			placedExpense = 200
	elseif cat[cIndex] == "Weapon Crate Placement Mode" then
		placedExpense = atkArray[pIndex][4]
	elseif cat[cIndex] == "Utility Crate Placement Mode" then
		placedExpense = utilArray[pIndex][4]
	end

	AddCaption(loc("Cost") .. ": " .. placedExpense,0xffba00ff,capgrpAmmostate)

end

function onTimer(key)

	-- Hacky workaround for object placer: Since this is based on the drill strike, it
	-- allows the 5 timer keys to be pressed, causing the announcer to show up
	-- This triggers code in 1 tick to send other message to mask the earlier one.
	checkForSpecialWeaponsIn = 1

	if (curWep == amCMStructurePlacer) then
		-- Select structure directly in structure placer
		-- [Timer X] selects structures 1-5
		-- [Precise]+[Timer X] selects structures 6-10

		local structureID = key
		local precise = band(GetGearMessage(CurrentHedgehog), gmPrecise) ~= 0
		if precise then
			structureID = structureID + 5
		end
		-- Check for valid pIndex
		if structureID <= #pMode then
			pIndex = structureID
			showModeMessage()
			updateCost()
		end
	elseif (curWep == amCMObjectPlacer) then
		-- [Timer X]: Set mine time 1-5
		if cat[cIndex] == "Mine Placement Mode" then
			local index = key + 1
			if key <= #pMode then
				pIndex = index
				showModeMessage()
				updateCost()
			end
		end
	end

end

function onSwitch()
	if (curWep == amCMObjectPlacer) then
		-- [Switch]: Set mine time to 0
		pIndex = 1
		showModeMessage()
		updateCost()
	end
end

function onLeft()

	pIndex = pIndex - 1
	if pIndex == 0 then
		pIndex = #pMode
	end

	if (curWep == amGirder) or (curWep == amCMStructurePlacer) or (curWep == amCMCratePlacer) or (curWep == amCMObjectPlacer) then
		showModeMessage()
		updateCost()
	end


end

function onRight()

	pIndex = pIndex + 1
	if pIndex > #pMode then
		pIndex = 1
	end

	if (curWep == amGirder) or (curWep == amCMStructurePlacer) or (curWep == amCMCratePlacer) or (curWep == amCMObjectPlacer) then
		showModeMessage()
		updateCost()
	end

end

function showModeMessage()
	if CurrentHedgehog == nil or band(GetState(CurrentHedgehog), gstHHDriven) == 0 then return end
	local val = pMode[pIndex]
	local str
	if cat[cIndex] == "Mine Placement Mode" then
		-- timer in seconds
		str = string.format(loc("%d sec"), div(val, 1000))
	elseif cat[cIndex] == "Girder Placement Mode" then
		str = loc("Girder")
	elseif cat[cIndex] == "Rubber Placement Mode" then
		str = loc("Rubber")
	else
		str = tostring(val)
	end
	AddCaption(str,0xffba00ff,capgrpMessage2)
end

function updatePlacementDisplay(pDir)

	foundMatch = false
	while(foundMatch == false) do
		cIndex = cIndex + pDir

		if (cIndex == 1) or (cIndex == 2) then --1	--we no longer hit girder by normal means
			cIndex = #cat
		elseif cIndex > #cat then
			cIndex = 3	 -- 2 ----we no longer hit girder by normal means
		end

		if sProx[cIndex][2] == true then
			if (GetCurAmmoType() == amCMCratePlacer) then
				if (sProx[cIndex][1] == loc("Health Crate Placement Mode")) or
					(sProx[cIndex][1] == loc("Weapon Crate Placement Mode")) or
					(sProx[cIndex][1] == loc("Utility Crate Placement Mode"))
					then
						foundMatch = true
					end
			elseif (GetCurAmmoType() == amCMObjectPlacer) then
				if (sProx[cIndex][1] == loc("Mine Placement Mode")) or
					(sProx[cIndex][1] == loc("Sticky Mine Placement Mode")) or
					(sProx[cIndex][1] == loc("Barrel Placement Mode"))
					then
						foundMatch = true
					end
			elseif (GetCurAmmoType() == amCMStructurePlacer) then
				if sProx[cIndex][1] == loc("Structure Placement Mode") then
					foundMatch = true
				end
			end
		end


		if foundMatch == true then
			RedefineSubset()
			updateCost()
		end

	end

end

---------------------------------------------------------
-- Cycle through primary categories (by changing cIndex)
-- i.e 	mine, sticky mine, barrels
--		health/weapon/utility crate, placement of gears
---------------------------------------------------------
function onUp()

	if ( (curWep == amCMCratePlacer) or (curWep == amCMObjectPlacer) ) then
		if CurrentHedgehog ~= nil or band(GetState(CurrentHedgehog), gstHHDriven) ~= 0 then
			updatePlacementDisplay(-1)
		end
	end

end

function onDown()

	if ( (curWep == amCMCratePlacer) or (curWep == amCMObjectPlacer) ) then
		if CurrentHedgehog ~= nil or band(GetState(CurrentHedgehog), gstHHDriven) ~= 0 then
			updatePlacementDisplay(1)
		end
	end

end

----------------------------
-- standard event handlers
----------------------------

-- Parses a positive integer
function parseInt(str, default, infinityPermitted)
	if str == "inf" and infinityPermitted then
		return "inf"
	end
	if str == nil then return default end
	local s = string.match(str, "(%d*)")
	if s ~= nil then
		return math.min(4294967295, math.max(0, tonumber(s)))
	else
		return nil
	end
end

-- Parse parameters
function onParameters()
	parseParams()
	conf_initialEnergy = parseInt(params["initialenergy"], conf_initialEnergy)
	conf_energyPerRound = parseInt(params["energyperround"], conf_energyPerRound)
	conf_maxEnergy = parseInt(params["maxenergy"], conf_maxEnergy, true)
	conf_cratesPerRound = parseInt(params["cratesperround"], conf_cratesPerRound, true)
end

function onGameInit()

	Explosives = 0
	MinesNum = 0

	EnableGameFlags(gfInfAttack)
	-- This is a hack to make sure all girder/rubber placement is handled by Construction Mode to overwrite the default behaviour
	SetMaxBuildDistance(1)

	fortMode = MapGen == mgForts

	-- if there are forts, let engine place the hogs on them
	if fortMode then
		EnableGameFlags(gfDivideTeams)
	end

	RedefineSubset()

end

function initialSetup(gear)

	-- engine already placed hogs in fort mode
	if not fortMode then
		FindPlace(gear, false, clanBoundsSX[GetHogClan(gear)], clanBoundsEX[GetHogClan(gear)],true)
	end

	-- for now, everyone should have this stuff
	AddAmmo(gear, amCMStructurePlacer, 100)
	AddAmmo(gear, amSwitch, 100)
	AddAmmo(gear, amSkip, 100)

end

function onGameStart()

	trackTeams()

	ShowMission	(
				loc("CONSTRUCTION MODE"),
				loc("a Hedgewars mini-game"),
				loc("Build a fortress and destroy your enemy.") .. "|" ..
				loc("There are a variety of structures available to aid you.") .. "|" ..
				loc("Use the structure placer to place structures.")
				, 4, 5000
				)

	SetAmmoTexts(amCMStructurePlacer, loc("Structure Placer"), loc("Construction Mode tool"), loc("Build one of multiple different structures|to aid you in victory, at the cost of energy.") .. "| |" ..
	loc("Healing Station: Heals nearby hogs.")  .. "|" ..
	loc("Bio-Filter: Aggressively removes enemies.")  .. "|" ..
	loc("Weapon Filter: Dematerializes all ammo|    carried by enemies entering it.")  .. "|" ..
	loc("Reflector Shield: Reflects enemy projectiles.")  .. "|" ..
	loc("Respawner: Resurrects dead hogs.")  .. "|" ..
	loc("Teleportation Node: Allows teleportation|    between other nodes.")  .. "|" ..
	loc("Generator: Generates energy.")  .. "|" ..
	loc("Construction Station: Allows placement of|    girders, rubber, mines, sticky mines|    and barrels.")  .. "|" ..
	loc("Support Station: Allows placement of crates.") .. "| |" ..

	loc("Left/right: Choose structure type").."|"..
	loc("1-5, Precise + 1-4: Choose structure type").."|"..
	loc("Cursor: Build structure"))

	local txt_crateLimit = ""
	if conf_cratesPerRound ~= "inf" then
		txt_crateLimit = string.format(loc("You may only place %d crates per round."), conf_cratesPerRound) .. "|"
	end

	SetAmmoTexts(amCMCratePlacer, loc("Crate Placer"), loc("Construction Mode tool"),
		loc("This allows you to create a crate anywhere|within your clan's area of influence,|at the cost of energy.") .. "|" ..
		txt_crateLimit ..
		loc("Up/down: Choose crate type") .. "|" .. 
		loc("Left/right: Choose crate contents") .. "|" ..
		loc("|Cursor: Place crate"))
	SetAmmoTexts(amCMObjectPlacer, loc("Object Placer"), loc("Construction Mode tool"),
		loc("This allows you to create and place mines,|sticky mines and barrels anywhere within your|clan's area of influence at the cost of energy.").."|"..
		loc("Up/down: Choose object type|1-5/Switch/Left/Right: Choose mine timer|Cursor: Place object")
	)

	SetAmmoDescriptionAppendix(amTeleport, loc("It only works in teleportation nodes of your own clan."))
	
	sCirc = AddVisualGear(0,0,vgtCircle,0,true)
	SetVisualGearValues(sCirc, 0, 0, 100, 255, 1, 10, 0, 40, 3, 0x00000000)

	for i = 0, ClansCount-1 do
		clanPower[i] = math.min(conf_initialEnergy, conf_maxEnergy)
		clanLWepIndex[i] = 1 -- for ease of use let's track this stuff
		clanLUtilIndex[i] = 1
		clanLGearIndex[i] = 1
		clanUsedExtraTime[i] = false
		clanCratesSpawned[i] = 0
		clanFirstTurn[i] = true

	end

	tMapWidth = RightX - LeftX
	tMapHeight = WaterLine - TopY
	clanInterval = div(tMapWidth,ClansCount)

	-- define construction areas for each clan
	-- if there are forts-based spawn locations, adjust areas around them
	for i = 0, ClansCount-1 do
		local slot
		if fortMode then
			slot = div(GetX(getFirstHogOfClan(i))-LeftX,clanInterval)
		else
			slot = i
		end

		local color = GetClanColor(i)

		clanBoundsSX[i] = LeftX+(clanInterval*slot)+20
		clanBoundsSY[i] = TopY
		clanBoundsEX[i] = LeftX+(clanInterval*slot)+clanInterval-20
		clanBoundsEY[i] = WaterLine

		--top and bottom
		AddWall(LeftX+(clanInterval*slot),TopY,clanInterval,margin,color)
		AddWall(LeftX+(clanInterval*slot),WaterLine-25,clanInterval,margin,color)

		--add a wall to the left and right
		AddWall(LeftX+(clanInterval*slot)+20,TopY,margin,WaterLine,color)
		AddWall(LeftX+(clanInterval*slot)+clanInterval-20,TopY,margin,WaterLine,color)

	end

	runOnHogs(initialSetup)

end


function onNewTurn()

	local clan = GetHogClan(CurrentHedgehog)
	if clanFirstTurn[clan] then
		clanFirstTurn[clan] = false
	else
		clanPower[clan] = clanPower[clan] + conf_energyPerRound
		if conf_maxEnergy ~= "inf" and clanPower[clan] > conf_maxEnergy then
			clanPower[clan] = conf_maxEnergy
		end
	end
	clanUsedExtraTime[clan] = false
	clanCratesSpawned[clan] = 0

end

function onGameTick()
	HandleHedgeEditor()
end

function isATrackedGear(gear)
	if 	(GetGearType(gear) == gtHedgehog) or
		(GetGearType(gear) == gtTarget) or
		(GetGearType(gear) == gtCase)
	then
		return(true)
	else
		return(false)
	end
end

-- track hedgehogs and placement gears
function onGearAdd(gear)

	if GetGearType(gear) == gtHedgehog then
	elseif (GetGearType(gear) == gtAirAttack) or (GetGearType(gear) == gtTeleport) or (GetGearType(gear) == gtGirder) then
		cGear = gear

	end

	if isATrackedGear(gear) then
		trackGear(gear)
	elseif gearCanBeDeflected(gear) then
		trackGear(gear)
		setGearReflectionValues(gear)
	end

end

function onGearDelete(gear)

	if GetGearType(gear) == gtTarget then
		CheckGearForStructureLink(gear)
	end

	if (GetGearType(gear) == gtAirAttack) or (GetGearType(gear) == gtTeleport) or (GetGearType(gear) == gtGirder) then
		cGear = nil
	end

	if (isATrackedGear(gear) or gearCanBeDeflected(gear)) then

		if getGearValue(gear, "tCirc") ~= nil then
			DeleteVisualGear(getGearValue(gear, "tCirc"))
		end

		trackDeletion(gear)

	end

end

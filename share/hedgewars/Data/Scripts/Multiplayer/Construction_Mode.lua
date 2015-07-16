---------------------------------------------------------
--- LE CONSTRUCTION MODE 0.7 (badly adapted from Hedge Editor 0.5)
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

--v.07 (pushed to repo)
-- added a cfg file
-- removed another 903 lines of code we weren't using (lol)

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
clanBoon = {}
clanID = {}
clanLStrucIndex = {}

clanLWepIndex = {} -- for ease of use let's track this stuff
clanLUtilIndex = {}
clanLGearIndex = {}
clanUsedExtraTime = {}
clanCratesSpawned = {}

effectTimer = 0

wallsVisible = false
wX = {}
wY = {}
wWidth = {}
wHeight = {}
wCol = {}
margin = 20

tauntString = ""

vTag = {}
lastWep = nil

function HideTags()

	for i = 0, 2 do
		SetVisualGearValues(vTag[i],0,0,0,0,0,1,0, 0, 240000, 0xffffff00)
	end

end

function DrawTag(i)

	zoomL = 1.3

	xOffset = 40

	if i == 0 then
		yOffset = 40
		tCol = 0xffba00ff
		tValue = 30--TimeLeft
	elseif i == 1 then
		zoomL = 1.1
		xOffset = 45
		yOffset = 70
		tCol = 0x00ff00ff
		tValue = clanPower[GetHogClan(CurrentHedgehog)]
	elseif i == 2 then
		zoomL = 1.1
		xOffset = 60 + 35
		yOffset = 70
		tCol = 0xa800ffff
		tValue = 10--shieldHealth - 80
	end

	DeleteVisualGear(vTag[i])
	vTag[i] = AddVisualGear(0, 0, vgtHealthTag, 0, false)
	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(vTag[i])
	SetVisualGearValues	(
				vTag[i], 		--id
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
			DrawTag(0)
			DrawTag(1)
			DrawTag(2)
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
	if effectTimer > 15 then --25
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
		--(GetGearType(gear) == gtBee) or
		(GetGearType(gear) == gtGrenade) or
		(GetGearType(gear) == gtAirBomb) or
		--(GetGearType(gear) == gtRCPlane) or
		--(GetGearType(gear) == gtRope) or
		(GetGearType(gear) == gtClusterBomb) or
		(GetGearType(gear) == gtCluster) or
		(GetGearType(gear) == gtGasBomb) or
		--(GetGearType(gear) == gtSeduction) or
		(GetGearType(gear) == gtMine) or	-------
		(GetGearType(gear) == gtMortar) or
		(GetGearType(gear) == gtHellishBomb) or
		(GetGearType(gear) == gtWatermelon) or
		(GetGearType(gear) == gtMelonPiece)	or
		(GetGearType(gear) == gtEgg) or
		(GetGearType(gear) == gtDrill) or
		(GetGearType(gear) == gtBall) or
		(GetGearType(gear) == gtExplosives) or	------
			(GetGearType(gear) == gtFlame) or
			(GetGearType(gear) == gtPortal) or
			(GetGearType(gear) == gtDynamite) or
			(GetGearType(gear) == gtSMine) or
			--(GetGearType(gear) == gtKamikaze) or
			--(GetGearType(gear) == gtRCPlane) or
			--(GetGearType(gear) == gtCake) or
			--(GetGearType(gear) == gtHedgehog) or ------
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
			--(GetGearType(gear) == gtKamikaze) or
			--(GetGearType(gear) == gtRCPlane) or

			--(GetGearType(gear) == gtCake)
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

	if (CurrentHedgehog ~= nil) then --and (gameStarted == true) then
		setGearValue(gear,"owner",GetHogClan(CurrentHedgehog)) -- NEW NEEDS CHANGE?
	else
		setGearValue(gear,"owner",10) -- nil
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

		--SetVisualGearValues(madness, g1, g2, 0, 0, g5, frameID, g7, visualSprite, g9, g10 )
		--SetState(tempG, bor(GetState(tempG),gstInvisible) )
		--table.insert(strucAltDisplay, madness)

	else
		table.insert(strucHealth,1)
		--table.insert(strucAltDisplay, 1)
	end

	table.insert(strucCirc,tempCirc)

	table.insert(strucCircType, 1)
	if pType == loc("Bio-Filter") then
		table.insert(strucCircCol,colorRed)
		table.insert(strucCircRadius,1000)
		frameID = 7
	elseif pType == loc("Healing Station") then
		table.insert(strucCircCol,0xFF00FF00)
		--table.insert(strucCircCol,colorGreen)
		table.insert(strucCircRadius,500)
		frameID = 3
	elseif pType == loc("Respawner") then
		table.insert(strucCircCol,0xFF00FF00)
		--table.insert(strucCircCol,0xFF00FFFF)
		table.insert(strucCircRadius,75)
		runOnHogs(EnableHogResurrectionForThisClan)
		frameID = 1
	elseif pType == loc("Teleportation Node") then
		table.insert(strucCircCol,0x0000FFFF)
		table.insert(strucCircRadius,350)
		frameID = 6
	elseif pType == loc("Core") then
		table.insert(strucCircCol,0xFFFFFFFF)
		table.insert(strucCircRadius,350)
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

	-- may be needed for non gear-based structures
	--table.insert(strucX, GetX(tempG))
	--table.insert(strucY, GetY(tempG))

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
				--NR = div((div(48,100) * strucCircRadius[tempID]),2)
			end
			if dist <= NR*NR then
				teleportOriginSuccessful = true
			end

			dist = GetDistFromXYtoXY(tX,tY,GetX(strucGear[i]), GetY(strucGear[i]))
			if strucCircType[i] == 0 then
				NR = strucCircRadius[i]
			else
				NR = (48/100*strucCircRadius[i])/2
				--NR = div((div(48,100) * strucCircRadius[tempID]),2)
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

	--if isAStructureEffectingGear(gear) then

		dist = GetDistFromGearToXY(gear, GetX(strucGear[tempID]), GetY(strucGear[tempID]))

		-- calculate my real radius if I am an aura
		if strucCircType[tempID] == 0 then
			NR = strucCircRadius[tempID]
		else
			NR = (48/100*strucCircRadius[tempID])/2
			--NR = div((div(48,100) * strucCircRadius[tempID]),2) -- doesn't work ffff
				--NR = div((48/100*strucCircRadius[tempID]),2) -- still works

		end

		-- we're in business
		if dist <= NR*NR then


			-- heal clan hogs
			if strucType[tempID] == loc("Healing Station") then

				if GetGearType(gear) == gtHedgehog then
					if GetHogClan(gear) == strucClan[tempID] then

						hogLife = GetHealth(gear) + 1
						if hogLife > 150 then
							hogLife = 150
						end
						SetHealth(gear, hogLife)

						-- change this to the med kit sprite health ++++s later
						tempE = AddVisualGear(GetX(strucGear[tempID]), GetY(strucGear[tempID]), vgtSmoke, 0, true)
						g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
						SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, colorGreen )


					end
				end

			-- explode enemy clan hogs
			elseif strucType[tempID] == loc("Bio-Filter") then

				--tempE = AddVisualGear(GetX(strucGear[tempID]), GetY(strucGear[tempID]), vgtSmoke, 0, true)
				--g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
				--SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, colorRed )

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

						AddAmmo(gear, amAirAttack, 100)
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

								--if dx == 0 then
									-- bounce away eggs
								--	dx = 0.5
								--end

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
						--tempE = AddVisualGear(GetX(strucGear[tempID]), GetY(strucGear[tempID]), vgtSmoke, 0, true)

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
								--AddCaption("wahey in a support station")
							end
						end


					end
				end

			-- doesn't do shit
			elseif strucType[tempID] == loc("Core") then

				if GetGearType(gear) == gtHedgehog then
					if GetHogClan(gear) == strucClan[tempID] then

						tempE = AddVisualGear(GetX(strucGear[tempID]), GetY(strucGear[tempID]), vgtSmoke, 0, true)
						g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
						SetVisualGearValues(tempE, g1+20, g2, g3, g4, g5, g6, g7, g8, g9, GetClanColor(strucClan[tempID]) )

						tempE = AddVisualGear(GetX(strucGear[tempID]), GetY(strucGear[tempID]), vgtSmoke, 0, true)
						g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
						SetVisualGearValues(tempE, g1-20, g2, g3, g4, g5, g6, g7, g8, g9, GetClanColor(strucClan[tempID]) )

					end
				end

			end

		end

	--end

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

	for i = 1, #sProx do
		sProx[i][2] = false

		if sProx[i][1] == loc("Structure Placement Mode") then
			sProx[i][2] = true
		end

	end

	for i = 1, #strucID do

		g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(strucCirc[i])
		SetVisualGearValues(strucCirc[i], GetX(strucGear[i]), GetY(strucGear[i]), g3, g4, g5, g6, g7, strucCircRadius[i], g9, strucCircCol[i])

		tempID = i

		g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(strucAltDisplay[i])				--8000
		SetVisualGearValues(strucAltDisplay[i], GetX(strucGear[i]), GetY(strucGear[i]), 0, 0, g5, g6, 800000, sprTarget, g9, g10 )



		-- Check For proximity of stuff to our structures
		if isAStructureThatAppliesToMultipleGears(i) then
			runOnGears(CheckProximity)
		else -- only check prox on CurrentHedgehog
			CheckProximity(CurrentHedgehog)
		end

		if strucType[i] == loc("Core") then
			tempE = AddVisualGear(GetX(strucGear[i]), GetY(strucGear[i]), vgtSmoke, 0, true)
			g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
			SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, GetClanColor(strucClan[i]) )
		elseif strucType[i] == loc("Reflector Shield") then



			--frameID = 1
			--visualSprite = sprTarget
			--g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(strucAltDisplay[i])			--frameID / g6
			--SetVisualGearValues(strucAltDisplay[i], GetX(strucGear[i]), GetY(strucGear[i]), 0, 0, g5, g6, 8000, visualSprite, g9, g10 )

		elseif strucType[i] == loc("Generator") then

			--frameID = 1
			--visualSprite = sprTarget
																									--layer
			--tempE = AddVisualGear(GetX(strucGear[i]), GetY(strucGear[i]), vgtStraightShot, 1, true,1)
			--g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)	--g9
			--SetVisualGearValues(tempE, g1, g2, 0, 0, g5, frameID, g7, visualSprite, g9, g10 )
			--SetState(strucGear[i], bor(GetState(strucGear[i]),gstInvisible) )

			--currently generate power for all clans.
			-- or should power only be generated for current clan?
			for z = 0, ClansCount-1 do
				if z == strucClan[i] then
					increaseGearValue(strucGear[i],"power")
					if getGearValue(strucGear[i],"power") == 10 then
						setGearValue(strucGear[i],"power",0)
						clanPower[z] = clanPower[z] + 1
						if clanPower[z] > 1000 then
							clanPower[z] = 1000
						end
					end

				end
			end

		end

	end



	-- this is kinda messy and gross (even more than usual), fix it up at some point
	-- it just assumes that if you have access to girders, it works for rubbers
	-- as that is what the struc implemenation means due to construction station
	anyUIProx = false
	for i = 1, #sProx do

		if sProx[i][1] == loc("Girder Placement Mode") then
			if sProx[i][2] == true then
				AddAmmo(CurrentHedgehog, amGirder, 100)
				AddAmmo(CurrentHedgehog, amRubber, 100)
				AddAmmo(CurrentHedgehog, amDrillStrike, 100)
			else
				AddAmmo(CurrentHedgehog, amGirder, 0)
				AddAmmo(CurrentHedgehog, amRubber, 0)
				AddAmmo(CurrentHedgehog, amDrillStrike, 0) -- new
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
				AddAmmo(CurrentHedgehog, amNapalm, 100)
			else
				AddAmmo(CurrentHedgehog, amNapalm, 0)
			end
		end

		if (sProx[i][2] == true) then
			anyUIProx = true
		end

	end

	-- doesn't do shit atm, maybe later when we add cores we can use this
	--if anyUIProx == true then --(and core is placed)
	--	AddAmmo(CurrentHedgehog, amAirAttack, 100)
	--else
	--	AddAmmo(CurrentHedgehog, amAirAttack, 0)
	--end


end


function checkForSpecialWeapons()



	if (GetCurAmmoType() == amAirAttack) then
		AddCaption(loc("Structure Placement Tool"),GetClanColor(GetHogClan(CurrentHedgehog)),capgrpAmmoinfo)
	elseif (GetCurAmmoType() == amDrillStrike) then
		AddCaption(loc("Object Placement Tool"),GetClanColor(GetHogClan(CurrentHedgehog)),capgrpAmmoinfo)
	elseif (GetCurAmmoType() == amNapalm) then
		AddCaption(loc("Crate Placement Tool"),GetClanColor(GetHogClan(CurrentHedgehog)),capgrpAmmoinfo)
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
				{amBazooka, 	"amBazooka",		0, loc("Bazooka"), 			2*placeholder},
				--{amBee, 		"amBee",			0, loc("Homing Bee"), 		4*placeholder},
				{amMortar, 		"amMortar",			0, loc("Mortar"), 			1*placeholder},
				{amDrill, 		"amDrill",			0, loc("Drill Rocket"), 	3*placeholder},
				{amSnowball, 	"amSnowball",		0, loc("Mudball"), 			3*placeholder},

				{amGrenade,		"amGrenade",		0, loc("Grenade"), 			2*placeholder},
				{amClusterBomb,	"amClusterBomb",	0, loc("Cluster Bomb"), 	3*placeholder},
				{amMolotov, 	"amMolotov",		0, loc("Molotov Cocktail"), 3*placeholder},
				{amWatermelon, 	"amWatermelon",		0, loc("Watermelon Bomb"), 25*placeholder},
				{amHellishBomb,	"amHellishBomb",	0, loc("Hellish Handgrenade"), 25*placeholder},
				{amGasBomb, 	"amGasBomb",		0, loc("Limburger"), 		3*placeholder},

				{amShotgun,		"amShotgun",		0, loc("Shotgun"), 			2*placeholder},
				{amDEagle,		"amDEagle",			0, loc("Desert Eagle"), 	2*placeholder},
				{amFlamethrower,"amFlamethrower",	0, loc("Flamethrower"), 	4*placeholder},
				{amSniperRifle,	"amSniperRifle",	0, loc("Sniper Rifle"), 	3*placeholder},
				--{amSineGun, 	"amSineGun",		0, loc("SineGun"), 			6*placeholder},
				{amIceGun, 		"amIceGun",			0, loc("Freezer"), 			15*placeholder},
				{amLandGun,		"amLandGun",		0, loc("Land Sprayer"), 	5*placeholder},

				{amFirePunch, 	"amFirePunch",		0, loc("Shoryuken"), 		3*placeholder},
				{amWhip,		"amWhip",			0, loc("Whip"), 			1*placeholder},
				{amBaseballBat, "amBaseballBat",	0, loc("Baseball Bat"), 	7*placeholder},
				--{amKamikaze, 	"amKamikaze",		0, loc("Kamikaze"),			1*placeholder},
				{amSeduction, 	"amSeduction",		0, loc("Seduction"),		1*placeholder},
				{amHammer,		"amHammer",			0, loc("Hammer"), 			1*placeholder},

				{amMine, 		"amMine",			0, loc("Mine"), 			1*placeholder},
				{amDynamite, 	"amDynamite",		0, loc("Dynamite"),			9*placeholder},
				{amCake, 		"amCake",			0, loc("Cake"), 			25*placeholder},
				{amBallgun, 	"amBallgun",		0, loc("Ballgun"), 			40*placeholder},
				--{amRCPlane,		"amRCPlane",		0, loc("RC Plane"), 	25*placeholder},
				{amSMine,		"amSMine",			0, loc("Sticky Mine"), 		5*placeholder},

				--{amAirAttack,	"amAirAttack",		0, loc("Air Attack"), 		10*placeholder},
				--{amMineStrike,	"amMineStrike",		0, loc("Mine Strike"), 		15*placeholder},
				--{amDrillStrike,	"amDrillStrike",	0, loc("Drill Strike"), 15*placeholder},
				--{amNapalm, 		"amNapalm",			0, loc("Napalm"), 		15*placeholder},
				--{amPiano,		"amPiano",			0, loc("Piano Strike"), 	40*placeholder},

				{amKnife,		"amKnife",			0, loc("Cleaver"), 			2*placeholder},

				{amBirdy,		"amBirdy",			0, loc("Birdy"), 			7*placeholder}

				}

 utilArray =
				{
				{amBlowTorch, 		"amBlowTorch",		0, loc("Blowtorch"), 		4*placeholder},
				{amPickHammer,		"amPickHammer",		0, loc("Pickhammer"), 		2*placeholder},
				--{amGirder, 			"amGirder",			0, loc("Girder"), 		4*placeholder},
				--{amRubber, 			"amRubber",			0, loc("Rubber Band"), 	5*placeholder},
				{amPortalGun,		"amPortalGun",		0, loc("Personal Portal Device"), 15*placeholder},

				{amRope, 			"amRope",			0, loc("Rope"), 			7*placeholder},
				{amParachute, 		"amParachute",		0, loc("Parachute"), 		2*placeholder},
				--{amTeleport,		"amTeleport",		0, loc("Teleport"), 		6*placeholder},
				{amJetpack,			"amJetpack",		0, loc("Flying Saucer"), 	8*placeholder},

				{amInvulnerable,	"amInvulnerable",	0, loc("Invulnerable"), 	5*placeholder},
				{amLaserSight,		"amLaserSight",		0, loc("Laser Sight"), 		2*placeholder},
				{amVampiric,		"amVampiric",		0, loc("Vampirism"), 		6*placeholder},

				{amLowGravity, 		"amLowGravity",		0, loc("Low Gravity"), 		4*placeholder},
				{amExtraDamage, 	"amExtraDamage",	0, loc("Extra Damage"), 	6*placeholder},
				{amExtraTime,		"amExtraTime",		0, loc("Extra Time"), 		8*placeholder}

				--{amResurrector, 	"amResurrector",	0, loc("Resurrector"), 		8*placeholder},
				--{amTardis, 			"amTardis",			0, loc("Tardis"), 			2*placeholder},

				--{amSwitch,			"amSwitch",			0, loc("Switch Hog"), 		4*placeholder}
				}

----------------------------
-- hog and map editting junk
----------------------------

 local reducedSpriteIDArray = {
  sprBigDigit, sprKowtow, sprBee, sprExplosion50, sprGirder
  }

  local reducedSpriteTextArray = {
  "sprBigDigit", "sprKowtow", "sprBee", "sprExplosion50", "sprGirder"
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
				"Health Crate Placement Mode",
				"Weapon Crate Placement Mode",
				"Utility Crate Placement Mode",
				--"Target Placement Mode",
				--"Cleaver Placement Mode",

				--"Advanced Repositioning Mode",
				--"Tagging Mode",
				--"Sprite Testing Mode",
				--"Sprite Placement Mode",
				"Structure Placement Mode"
				}


 sProx = 	{
				{loc("Girder Placement Mode"),false},
				{loc("Rubber Placement Mode"),false},
				{loc("Mine Placement Mode"),false},
				{loc("Sticky Mine Placement Mode"),false},
				{loc("Barrel Placement Mode"),false},
				{loc("Health Crate Placement Mode"),false},
				{loc("Weapon Crate Placement Mode"),false},
				{loc("Utility Crate Placement Mode"),false},
				--{loc("Target Placement Mode"),false},
				--{loc("Cleaver Placement Mode"),false},

				--{loc("Advanced Repositioning Mode"),false},
				--{loc("Tagging Mode"),false},
				--{loc("Sprite Testing Mode"),false},
				--{loc("Sprite Placement Mode"),false},
				{loc("Structure Placement Mode"),false},
				{loc("Teleportation Mode"),false}
				}


local pMode = {}	-- pMode contains custom subsets of the main categories
local pIndex = 1

local genTimer = 0

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
		AddCaption(loc("You may only use 1 Extra Time per turn."),0xffba00ff,capgrpVolume)
		PlaySound(sndDenied)
	elseif (clanCratesSpawned[GetHogClan(CurrentHedgehog)] > 4) and ( (cat[cIndex] == "Health Crate Placement Mode") or (cat[cIndex] == "Utility Crate Placement Mode") or (cat[cIndex] == "Weapon Crate Placement Mode")  )  then
		AddCaption(loc("You may only spawn 5 crates per turn."),0xffba00ff,capgrpVolume)
		PlaySound(sndDenied)
	elseif (XYisInRect(x,y, clanBoundsSX[GetHogClan(CurrentHedgehog)],clanBoundsSY[GetHogClan(CurrentHedgehog)],clanBoundsEX[GetHogClan(CurrentHedgehog)],clanBoundsEY[GetHogClan(CurrentHedgehog)]) == true)
	and (clanPower[GetHogClan(CurrentHedgehog)] >= placedExpense)
	then



		if cat[cIndex] == "Girder Placement Mode" then
			PlaceGirder(x, y, CGR)
			placedSpec[placedCount] = CGR
		elseif cat[cIndex] == "Rubber Placement Mode" then
			PlaceSprite(x,y, sprAmRubber, CGR, nil, nil, nil, nil, lfBouncy)
			--PlaceGirder(x, y, CGR)
			placedSpec[placedCount] = CGR
		elseif cat[cIndex] == "Target Placement Mode" then
			gear = AddGear(x, y, gtTarget, 0, 0, 0, 0)
		elseif cat[cIndex] == "Cleaver Placement Mode" then
			gear = AddGear(x, y, gtKnife, 0, 0, 0, 0)
		elseif cat[cIndex] == "Health Crate Placement Mode" then
			gear = SpawnHealthCrate(x,y)
			SetHealth(gear, pMode[pIndex])
			setGearValue(gear,"caseType","med")
			clanCratesSpawned[GetHogClan(CurrentHedgehog)] = clanCratesSpawned[GetHogClan(CurrentHedgehog)] +1
		elseif cat[cIndex] == "Weapon Crate Placement Mode" then
			gear = SpawnAmmoCrate(x, y, atkArray[pIndex][1])
			placedSpec[placedCount] = atkArray[pIndex][2]
			setGearValue(gear,"caseType","ammo")
			setGearValue(gear,"contents",atkArray[pIndex][2])
			clanCratesSpawned[GetHogClan(CurrentHedgehog)] = clanCratesSpawned[GetHogClan(CurrentHedgehog)] +1
		elseif cat[cIndex] == "Utility Crate Placement Mode" then
			gear = SpawnUtilityCrate(x, y, utilArray[pIndex][1])
			placedSpec[placedCount] = utilArray[pIndex][2]
			setGearValue(gear,"caseType","util")
			setGearValue(gear,"contents",utilArray[pIndex][2])
			if utilArray[pIndex][1] == amExtraTime then
				clanUsedExtraTime[GetHogClan(CurrentHedgehog)] = true
			end
			clanCratesSpawned[GetHogClan(CurrentHedgehog)] = clanCratesSpawned[GetHogClan(CurrentHedgehog)] +1
		elseif cat[cIndex] == "Barrel Placement Mode" then
			gear = AddGear(x, y, gtExplosives, 0, 0, 0, 0)
			SetHealth(gear, pMode[pIndex])
		elseif cat[cIndex] == "Mine Placement Mode" then
			gear = AddGear(x, y, gtMine, 0, 0, 0, 0)
			SetTimer(gear, pMode[pIndex])
		elseif cat[cIndex] == "Sticky Mine Placement Mode" then
			gear = AddGear(x, y, gtSMine, 0, 0, 0, 0)
		elseif cat[cIndex] == "Advanced Repositioning Mode" then

			if pMode[pIndex] == "Selection Mode" then
				closestDist = 999999999
				closestGear = nil -- just in case
				sGear = nil
				runOnGears(SelectGear)
				sGear = closestGear
				closestGear = nil
			elseif pMode[pIndex] == "Placement Mode" then
				if sGear ~= nil then
					SetGearPosition(sGear, x, y)
				end
			end

		elseif cat[cIndex] == "Tagging Mode" then

			closestDist = 999999999
			closestGear = nil
			sGear = nil
			runOnGears(SelectGear)


			if closestGear ~= nil then

				if getGearValue(closestGear,"tag") == nil then

					--if there is no tag, add a victory/failure tag and circle
					setGearValue(closestGear, "tCirc",AddVisualGear(0,0,vgtCircle,0,true))

					--AddCaption("circ added",0xffba00ff,capgrpVolume)

					if pMode[pIndex] == "Tag Victory Mode" then
						setGearValue(closestGear, "tag","victory")
						SetVisualGearValues(getGearValue(closestGear,"tCirc"), 0, 0, 100, 255, 1, 10, 0, 40, 3, 0xff0000ff)
					elseif pMode[pIndex] == "Tag Failure Mode" then
						setGearValue(closestGear, "tag","failure")
						SetVisualGearValues(getGearValue(closestGear,"tCirc"), 0, 0, 100, 255, 1, 10, 0, 40, 3, 0x0000ffff)
					end


				else
					-- remove tag and delete circ
					--AddCaption("circ removed",0xffba00ff,capgrpVolume)
					setGearValue(closestGear, "tag", nil)
					DeleteVisualGear(getGearValue(closestGear,"tCirc"))
					setGearValue(closestGear, "tCirc", nil)
				end

			end


		elseif cat[cIndex] == "Sprite Testing Mode" then

			frameID = 1
			visualSprite = reducedSpriteIDArray[pIndex]
			--visualSprite = spriteIDArray[pIndex]
			tempE = AddVisualGear(x, y, vgtStraightShot, 0, true)
			g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
			SetVisualGearValues(tempE, g1, g2, 0, 0, g5, frameID, g7, visualSprite, g9, g10 )
	--sprHorizonLong crashes game, so does skyL, as does flake

		-- reduced list of cool sprites
		-- sprBigDigit, sprKnife, sprFrozenHog, sprKowtow, sprBee, sprExplosion50, sprPiano, sprChunk, sprHHTelepMask, sprSeduction, sprSwitch, sprGirder,
		--sprAMAmmos, sprAMSlotKeys, sprTurnsLeft, sprExplosivesRoll + maybe some others like the health case, arrows, etc

		elseif cat[cIndex] == "Sprite Placement Mode" then

			PlaceSprite(x,y, reducedSpriteIDArray[pIndex], 1, nil, nil, nil, nil, landType)
			--PlaceGirder(x, y, CGR)
			placedSpec[placedCount] = reducedSpriteTextArray[pIndex]
			placedSuperSpec[placedCount] = landType

			if landType == lfIce then
				placedSuperSpec[placedCount] = "lfIce"
			elseif landType == lfIndestructible then
				placedSuperSpec[placedCount] = "lfIndestructible"
			elseif landType == lfBouncy then
				placedSuperSpec[placedCount] = "lfBouncy"
			else
				placedSuperSpec[placedCount] = "lfNormal"
			end

		elseif cat[cIndex] == "Structure Placement Mode" then

			AddStruc(x,y, pMode[pIndex],GetHogClan(CurrentHedgehog))

		end

		clanPower[GetHogClan(CurrentHedgehog)] = clanPower[GetHogClan(CurrentHedgehog)] - placedExpense
		placedCount = placedCount + 1

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
		pMode = {"Girder"}
		--	pCount = 1
	elseif cat[cIndex] == "Rubber Placement Mode" then
		pIndex = CGR
		pMode = {"Rubber"}
		placedExpense = 3
	--	pCount = 1???
	elseif cat[cIndex] == "Target Placement Mode" then
		pMode = {"Standard Target"}
	elseif cat[cIndex] == "Cleaver Placement Mode" then
		pMode = {"Standard Cleaver"}
	elseif cat[cIndex] == "Barrel Placement Mode" then
		--pMode = {1,50,75,100}
		pMode = {50}
		placedExpense = 10
	elseif cat[cIndex] == "Health Crate Placement Mode" then
		--pMode = {25,50,75,100}
		pMode = {25}
		placedExpense = 5
	elseif cat[cIndex] == "Weapon Crate Placement Mode" then
		for i = 1, #atkArray do
			pMode[i] = atkArray[i][4] -- was [2]
			--placedExpense = atkArray[5]
		end
		placedExpense = 30
	elseif cat[cIndex] == "Utility Crate Placement Mode" then
		for i = 1, #utilArray do
			pMode[i] = utilArray[i][4] -- was [2]
			--placedExpense = utilArray[5]
		end
		placedExpense = 20
	elseif cat[cIndex] == "Mine Placement Mode" then
		--pMode = {1,1000,2000,3000,4000,5000,0}
		pMode = {1,1000,2000,3000,4000,5000}
		-- 0 is dud right, or is that nil?
		placedExpense = 15
	elseif cat[cIndex] == "Sticky Mine Placement Mode" then
		pMode = {"Normal Sticky Mine"}
	--elseif cat[cIndex] == "Gear Repositioning Mode" then
	--	for i = 1, #hhs do
	--		pMode[i] = GetHogName(hhs[i])
	--	end
		placedExpense = 20
	elseif cat[cIndex] == "Advanced Repositioning Mode" then
		pMode = {"Selection Mode","Placement Mode"}
	elseif cat[cIndex] == "Tagging Mode" then
		pMode = {"Tag Victory Mode","Tag Failure Mode"}
	elseif cat[cIndex] == "Sprite Testing Mode" or cat[cIndex] == "Sprite Placement Mode" then
		--for i = 1, #spriteTextArray do
		--	pMode[i] = spriteTextArray[i]
		--end
		for i = 1, #reducedSpriteTextArray do
			pMode[i] = reducedSpriteTextArray[i]
		end
		placedExpense = 100
	elseif cat[cIndex] == "Structure Placement Mode" then
		pMode = {loc("Healing Station"), loc("Bio-Filter"), loc("Weapon Filter"), loc("Reflector Shield"), loc("Respawner"),loc("Teleportation Node"),--[[loc("Core"),]]loc("Generator"),loc("Construction Station"),loc("Support Station")}
		--placedExpense = 100
	end




end

-- called in onGameTick()
function HandleHedgeEditor()

	if CurrentHedgehog ~= nil then

		if wallsVisible == true then
			HandleBorderEffects()
		end

		if (CurrentHedgehog ~= nil) and (TurnTimeLeft ~= TurnTime) then
			if (lastWep ~= GetCurAmmoType()) then
				checkForSpecialWeapons()
			end
		end

		genTimer = genTimer + 1

		if genTimer >= 100 then

			genTimer = 0

			DrawTag(1)

			HandleStructures()

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
				cIndex = 3 -- was 2
				RedefineSubset()
			elseif (cIndex == 2) and (curWep ~= amRubber) then
				cIndex = 3 --new
				RedefineSubset()

			end

			-- update display selection criteria
			if (curWep == amGirder) or (curWep == amAirAttack) or (curWep == amNapalm) or (curWep == amDrillStrike) or (curWep == amRubber) then

				---------------hooolllllyyyy fucking shit this
				-- code is a broken mess now
				-- it was redesigned and compromised three times
				-- so now it is a mess trying to do what it was
				-- never designed to do
				-- needs to be rewritten badly sadface
				-- this bit here catches the new 3 types of weapons
				if ((sProx[cIndex][1] == loc("Structure Placement Mode") and (curWep ~= amAirAttack))) then
					updatePlacementDisplay(1)
				elseif (sProx[cIndex][1] == loc("Health Crate Placement Mode")) or
							(sProx[cIndex][1] == loc("Weapon Crate Placement Mode")) or
							(sProx[cIndex][1] == loc("Utility Crate Placement Mode")) then
								if curWep ~= amNapalm then
									updatePlacementDisplay(1)
								end

				elseif (sProx[cIndex][1] == loc("Mine Placement Mode")) or
							(sProx[cIndex][1] == loc("Sticky Mine Placement Mode")) or
							(sProx[cIndex][1] == loc("Barrel Placement Mode")) then
								if curWep ~= amDrillStrike then
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


				AddCaption(cat[cIndex],0xffba00ff,capgrpMessage)
				AddCaption(pMode[pIndex],0xffba00ff,capgrpMessage2)
				wallsVisible = true
			else
				wallsVisible = false
			end

		end

	end

	--update selected gear display
	if (cat[cIndex] == "Advanced Repositioning Mode") and (sGear ~= nil) then
		SetVisualGearValues(sCirc, GetX(sGear), GetY(sGear), 100, 255, 1, 10, 0, 300, 3, 0xff00ffff)
	elseif (cat[cIndex] == "Tagging Mode") then
		if (sGear ~= nil) or (closestGear ~= nil) then
			SetVisualGearValues(sCirc, GetX(sGear), GetY(sGear), 0, 1, 1, 10, 0, 1, 1, 0x00000000)
			closestGear = nil
			sGear = nil
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

			-- improve rectangle test based on CGR when you can be bothered
			--if TestRectForObstacle(x-20, y-20, x+20, y+20, true) then
			--	AddCaption("Invalid Girder Placement",0xffba00ff,capgrpVolume)
			--else
				PlaceObject(x, y)
			--end

			-- this allows the girder tool to be used like a mining laser

		--[[

			if CGR < 4 then
				AddGear(x, y, gtGrenade, 0, 0, 0, 1)
			elseif CGR == 4 then
				g = AddGear(x-30, y, gtGrenade, 0, 0, 0, 1)
				g = AddGear(x+30, y, gtGrenade, 0, 0, 0, 1)
			elseif CGR == 5 then -------
				g = AddGear(x+30, y+30, gtGrenade, 0, 0, 0, 1)
				g = AddGear(x-30, y-30, gtGrenade, 0, 0, 0, 1)
			elseif CGR == 6 then
				g = AddGear(x, y+30, gtGrenade, 0, 0, 0, 1)
				g = AddGear(x, y-30, gtGrenade, 0, 0, 0, 1)
			elseif CGR == 7 then -------
				g = AddGear(x+30, y-30, gtGrenade, 0, 0, 0, 1)
				g = AddGear(x-30, y+30, gtGrenade, 0, 0, 0, 1)
			end
]]
		end

	end

end

--------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------

function onTaunt(t)
	tauntString = tauntString .. t
	if (tauntString == "101") and (clanPower[GetHogClan(CurrentHedgehog)] < 300) and (clanBoon[GetHogClan(CurrentHedgehog)] == false) then
		clanBoon[GetHogClan(CurrentHedgehog)] = true
		clanPower[GetHogClan(CurrentHedgehog)] = 1000
		AddCaption(loc("The Great Hog in the sky sees your sadness and grants you a boon."))
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
	elseif pMode[pIndex] == loc("Core") then
		placedExpense = 1
	elseif cat[cIndex] == loc("Weapon Crate Placement Mode") then
		placedExpense = atkArray[pIndex][5]
	elseif cat[cIndex] == loc("Utility Crate Placement Mode") then
		placedExpense = utilArray[pIndex][5]
	end

	AddCaption(loc("Cost") .. ": " .. placedExpense,0xffba00ff,capgrpAmmostate)

end

function onLeft()

	pIndex = pIndex - 1
	if pIndex == 0 then
		pIndex = #pMode
	end

	if (curWep == amGirder) or (curWep == amAirAttack) or (curWep == amNapalm) or (curWep == amDrillStrike) then
		AddCaption(pMode[pIndex],0xffba00ff,capgrpMessage2)
		updateCost()
	end


end

function onRight()

	pIndex = pIndex + 1
	if pIndex > #pMode then
		pIndex = 1
	end

	if (curWep == amGirder) or (curWep == amAirAttack) or (curWep == amNapalm) or (curWep == amDrillStrike) then
		AddCaption(pMode[pIndex],0xffba00ff,capgrpMessage2)
		updateCost()
	end

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

		-- new way of doing things
		-- sProx[cIndex][2] == true just basically means we have ACCESS to something
		-- but that doesn't neccessarily mean we are in the correct content menu, anymore
		-- so we need to refine this a little
		if sProx[cIndex][2] == true then
			if (GetCurAmmoType() == amNapalm) then
				if (sProx[cIndex][1] == loc("Health Crate Placement Mode")) or
					(sProx[cIndex][1] == loc("Weapon Crate Placement Mode")) or
					(sProx[cIndex][1] == loc("Utility Crate Placement Mode"))
					then
						foundMatch = true
					end
			elseif (GetCurAmmoType() == amDrillStrike) then
				if (sProx[cIndex][1] == loc("Mine Placement Mode")) or
					(sProx[cIndex][1] == loc("Sticky Mine Placement Mode")) or
					(sProx[cIndex][1] == loc("Barrel Placement Mode"))
					then
						foundMatch = true
					end
			elseif (GetCurAmmoType() == amAirAttack) then
				if sProx[cIndex][1] == loc("Structure Placement Mode") then
					foundMatch = true
				end
			end
		end


		if foundMatch == true then
		--if sProx[cIndex][2] == true then
			-- normal case (scrolling through)
			--foundMatch = true
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

	if ((curWep == amAirAttack) or (curWep == amNapalm) or (curWep == amDrillStrike) ) then
		updatePlacementDisplay(-1)
	end

end

function onDown()

	if ((curWep == amAirAttack) or (curWep == amNapalm) or (curWep == amDrillStrike) ) then
		updatePlacementDisplay(1)
	end

end

----------------------------
-- standard event handlers
----------------------------

function onGameInit()

	Explosives = 0
	MinesNum = 0

	EnableGameFlags(gfInfAttack)


	RedefineSubset()

end

function initialSetup(gear)

	FindPlace(gear, false, clanBoundsSX[GetHogClan(gear)], clanBoundsEX[GetHogClan(gear)],true)

	-- for now, everyone should have this stuff
	AddAmmo(gear, amAirAttack, 100)
	AddAmmo(gear, amSwitch, 100)
	AddAmmo(gear, amSkip, 100)

end

function onGameStart()

	trackTeams()

	ShowMission	(
				loc("CONSTRUCTION MODE"),
				loc("a Hedgewars mini-game"),
				" " .. "|" ..
				loc("Build a fortress and destroy your enemy.") .. "|" ..
				--loc("Defend your core from the enemy.") .. "|" ..
				loc("There are a variety of structures available to aid you.") .. "|" ..
				loc("Use the air-attack weapons and the arrow keys to select structures.") .. "|" ..
				" " .. "|" ..
				--loc("Core") .. ": " .. loc("Allows placement of structures.")  .. "|" ..
				loc("Healing Station") .. ": " .. loc("Grants nearby hogs life-regeneration.")  .. "|" ..
				loc("Bio-Filter") .. ": " .. loc("Aggressively removes enemy hedgehogs.")  .. "|" ..
				loc("Weapon Filter") .. ": " .. loc("Dematerializes weapons and equipment carried by enemy hedgehogs.")  .. "|" ..
				loc("Reflector Shield") .. ": " .. loc("Reflects enemy projectiles.")  .. "|" ..

				loc("Generator") .. ": " .. loc("Generates power.")  .. "|" ..
				loc("Respawner") .. ": " .. loc("Resurrects dead hedgehogs.")  .. "|" ..
				loc("Teleporation Node") .. ": " .. loc("Allows free teleportation between other nodes.")  .. "|" ..
				loc("Construction Station") .. ": " .. loc("Allows placement of girders, rubber-bands, mines, sticky mines and barrels.")  .. "|" ..
				loc("Support Station") .. ": " .. loc("Allows the placement of weapons, utiliites, and health crates.")  .. "|" ..


				" " .. "|" ..
				--" " .. "|" ..
				"", 4, 5000
				)


	sCirc = AddVisualGear(0,0,vgtCircle,0,true)
	SetVisualGearValues(sCirc, 0, 0, 100, 255, 1, 10, 0, 40, 3, 0x00000000)

	for i = 0, ClansCount-1 do
		clanPower[i] = 500
		clanBoon[i] = false
		clanLWepIndex[i] = 1 -- for ease of use let's track this stuff
		clanLUtilIndex[i] = 1
		clanLGearIndex[i] = 1
		clanUsedExtraTime[i] = false
		clanCratesSpawned[i] = 0


	end

	tMapWidth = RightX - LeftX
	tMapHeight = WaterLine - TopY
	clanInterval = div(tMapWidth,ClansCount)

	for i = 1, ClansCount do

		clanBoundsSX[i-1] = LeftX+(clanInterval*i)-clanInterval+20
		clanBoundsSY[i-1] = TopY
		clanBoundsEX[i-1] = LeftX+(clanInterval*i)-20
		clanBoundsEY[i-1] = WaterLine

		--top and bottom
		AddWall(LeftX+(clanInterval*i)-clanInterval,TopY,clanInterval,margin,GetClanColor(i-1))
		AddWall(LeftX+(clanInterval*i)-clanInterval,WaterLine-25,clanInterval,margin,GetClanColor(i-1))

		--add a wall to the left and right
		AddWall(LeftX+(clanInterval*i)-clanInterval+20,TopY,margin,WaterLine,GetClanColor(i-1))
		AddWall(LeftX+(clanInterval*i)-20,TopY,margin,WaterLine,GetClanColor(i-1))

	end

	runOnHogs(initialSetup)

end


function onNewTurn()

	tauntString = ""
	clanPower[GetHogClan(CurrentHedgehog)] = clanPower[GetHogClan(CurrentHedgehog)] + 50
	clanUsedExtraTime[GetHogClan(CurrentHedgehog)] = false
	clanCratesSpawned[GetHogClan(CurrentHedgehog)] = 0

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
		--table.insert(hhs, gear)
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

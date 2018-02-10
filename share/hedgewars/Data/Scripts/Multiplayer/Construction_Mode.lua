--[[-----------------------------------------------------
-- CONSTRUCTION MODE --
---------------------------------------------------------
A Hedgewars gameplay mode by mikade.
Special thanks to all who helped test and offered suggestions.
Additional thanks to sheepluva/nemo for adding some extra hooks.

---------------------
-- STRUCTURES LIST --
---------------------

* Healing Station: Heals hogs to 150 health
* Teleportation Node: Allows teleporting to any other teleporter nodes
* Bio-filter: Explodes enemy hogs
* Respawner: If you have one of these, any slain hogs are resurrected here
* Generator: Generates power (used to buy stuff)
* Support Station: Allows purchasing crates
* Construction Station: Allows purchasing girders, rubber, mines, sticky mines, barrels
* Reflector Shield: Reflect projectiles
* Weapon Filter: Removes all equipement of enemy hogs passing through this area

---------------------------------------------------------
-- SCRIPT PARAMETER
---------------------------------------------------------
The script parameter can be used to configure the energy
of the game. It is a comma-seperated list of key=value pairs, where each
key is a word and each value is an integer between 0 and 4294967295.

Possible keys:
* initialenergy:  Amount of energy that each team starts with (default: 550)
                  Note: Must be smaller than or equal to maxenergy
* energyperround: Amount of energy that each team gets per round (default: 50)
* maxenergy:      Maximum amount of energy each team can hold (default: 1000)
* cratesperround: Maximum number of crates you can place per round (default: 5)

For the previous 2 keys, you can use the value “inf” for an unlimited amount.

Example: “initialenergy=750, maxenergy=2000” starts thee game with 750 energy
         and sets the maximum energy to 2000.
Example: “craterperround=inf” disables the crate placement limit.

---------------------------------------------------------
-- Ideas list --
---------------------------------------------------------

* To make the weapon filter more attractive, make it vaporize flying saucers
  and also rope, and maybe incoming gears

* Make healing thing also cure poison?
* Maybe make poison more virulent and dangerous

]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

-- Structures stuff
local strucID = {}
local strucGear = {}
local strucClan = {}
local strucType = {}
local strucCost = {}
local strucHealth = {}

local strucCirc = {}
local strucCircCol = {}
local strucCircRadius = {}
local strucAltDisplay = {}

-- Clan stuff
local clanPower = {} -- current power for each clan. Used to build stuff
local clanPowerTag = nil -- visual gear ID of displayed clan power

local clanUsedExtraTime = {} -- has used extra time in this round?
local clanCratesSpawned = {} -- number of crates spawned in this round
local clanFirstTurn = {}

local clanBoundsSX = {}
local clanBoundsSY = {}
local clanBoundsEX = {}
local clanBoundsEY = {}

-- For tracking previous mode selection per-team
local teamLStructIndex = {}
local teamLObjectMode = {}
local teamLCrateMode = {}
local teamLMineIndex = {}
local teamLWeapIndex = {}
local teamLUtilIndex = {}

-- Wall stuff
local wallsVisible = false
local wX = {}
local wY = {}
local wWidth = {}
local wHeight = {}
local wCol = {}
local wMargin = 20
local borderEffectTimer = 0 -- timer for border clan sparkles

-- Other stuff
local placedExpense = 0 -- Cost of current selected thing
local curWep = amNothing -- current weapon, used to reduce # of calls to GetCurAmmoType()

local fortMode = false -- is using a fort map?
local tempID_CheckProximity = nil -- temporary structure variable for CheckProximity
local cGear = nil -- detects placement of girders and objects (using airattack)
local uniqueStructureID = 0 -- Counter and ID for structures. Is incremented each time a structure spawns

--[[ Hacky workaround for object placer: Since this thing is
based on the drill strike, it allows the 5 timer keys to be
pressed, causing the announcer to show up.
This variable counts the number of ticks to count down until
to overwrite this anouncer message.
-1 means “do nothing”. ]]
local checkForSpecialWeaponsIn = -1
local lastWep = amNothing -- helper variable to track the previous hack

-- Colors
local colorClanTag = 0x00ff00ff

local colorSupportStation = 0xFFFF00FF
local colorConstructionStation = 0xFFFFFFFF
local colorTeleportationNode = 0x0000FFFF
local colorHealingStation = 0xFF808040 -- Just a slight glow
local colorBioFilter = 0xFF0000FF
local colorReflectorShield = 0xFFAE00FF
local colorWeaponFilter =  0xA800FFFF

local colorHealingStationParticle = 0x00FF00FF

local colorMessageError = 0xFFFFFFFF

-- Fake ammo types, for the overwritten weapons in Construction Mode
local amCMStructurePlacer = amAirAttack
local amCMCratePlacer = amNapalm
local amCMObjectPlacer = amDrillStrike

-- Config variables (script parameter)
local conf_initialEnergy = 550
local conf_energyPerRound = 50
local conf_maxEnergy = 1000
local conf_cratesPerRound = 5

-----------------------
-- CRATE DEFINITIONS --
-----------------------
-- format:
-- { ammoType, cost }

local costFactor = 20

-- WEAPON CRATES
-- Weapons which shouldn't be aded:
-- Air attack, napalm, drillstrike: Overwritten weapons for the Construction Mode tools
-- Mine strike: Is currently broken
-- Piano strike: Hog is resurrected by respawner. Not strictly prohibited, however.
local atkArray = {
	{amBazooka,	 2*costFactor},
	--{amBee,	 4*costFactor},
	{amMortar,	 1*costFactor},
	{amDrill,	 3*costFactor},
	{amSnowball,	 3*costFactor},
	{amDuck,	 2*costFactor},

	{amGrenade,	 2*costFactor},
	{amClusterBomb,	 3*costFactor},
	{amWatermelon,	25*costFactor},
	{amHellishBomb,	25*costFactor},
	{amMolotov,	 3*costFactor},
	{amGasBomb,	 3*costFactor},

	{amShotgun,	 2*costFactor},
	{amDEagle,	 2*costFactor},
	{amSniperRifle,	 3*costFactor},
	--{amSineGun,	 6*costFactor},
	{amFlamethrower, 4*costFactor},
	{amIceGun,	15*costFactor},
	{amMinigun,	13*costFactor},

	{amFirePunch,	 3*costFactor},
	{amWhip,	 1*costFactor},
	{amBaseballBat,	 7*costFactor},
	--{amKamikaze,	 1*costFactor},
	{amSeduction,	 1*costFactor},
	{amHammer,	 1*costFactor},

	{amMine,	 1*costFactor},
	{amDynamite,	 9*costFactor},
	{amCake,	25*costFactor},
	{amBallgun,	40*costFactor},
	--{amRCPlane,	25*costFactor},
	{amSMine,	 5*costFactor},

	--{amMineStrike,15*costFactor},
	--{amPiano,	40*costFactor},

	{amPickHammer,	 2*costFactor},
	{amBlowTorch,	 4*costFactor},
	{amKnife,	 2*costFactor},

	{amBirdy,	 7*costFactor},
}

-- UTILITY CRATES --

-- Utilities which shouldn't be added:
-- * Teleport: We have teleportation node
-- * Switch: Infinite in default Construction Mode weapons scheme
-- * Girder, rubber: Requires construction station
-- * Resurrector: We have the resurrector structure for this

-- Utilities which might be weird for this mode:
-- * Tardis: Randomly teleports hog, maybe even into enemy clan's area
local utilArray = {
 	{amLandGun,	 5*costFactor},

	{amRope,	 7*costFactor},
	{amParachute,	 2*costFactor},
	{amJetpack,	 8*costFactor},
	{amPortalGun,	 15*costFactor},

	{amInvulnerable, 5*costFactor},
	{amLaserSight,	 2*costFactor},
	{amVampiric,	 6*costFactor},

	{amLowGravity,	 4*costFactor},
	{amExtraDamage,	 6*costFactor},
	{amExtraTime,	 8*costFactor}
}

----------------------------
-- Placement stuff
----------------------------

-- primary placement categories
local cIndex = 1 -- category index
local cat = {
	loc_noop("Girder Placement Mode"),
	loc_noop("Rubber Placement Mode"),
	loc_noop("Mine Placement Mode"),
	loc_noop("Sticky Mine Placement Mode"),
	loc_noop("Barrel Placement Mode"),
	loc_noop("Weapon Crate Placement Mode"),
	loc_noop("Utility Crate Placement Mode"),
	loc_noop("Health Crate Placement Mode"),
	loc_noop("Structure Placement Mode"),
}

local catReverse = {}
for c=1, #cat do
	catReverse[cat[c]] = c
end

-- Track girders in proximity of CurrentHedgehog
local sProx = {
	["Girder Placement Mode"] = false,
	["Rubber Placement Mode"] = false,
	["Mine Placement Mode"] = false,
	["Sticky Mine Placement Mode"] = false,
	["Barrel Placement Mode"] = false,
	["Weapon Crate Placement Mode"] = false,
	["Utility Crate Placement Mode"] = false,
	["Health Crate Placement Mode"] = false,
	["Structure Placement Mode"] = false,
	["Teleportation Mode"] = false,
}

local pMode = {}	-- pMode contains custom subsets of the main categories
local pIndex = 1

local currentGirderRotation = 1 -- current girder rotation, we actually need this as HW remembers what rotation you last used

function DrawClanPowerTag()

	local zoomL = 1.1
	local xOffset = 45
	local yOffset = 70
	local tValue = clanPower[GetHogClan(CurrentHedgehog)]
	local tCol = colorClanTag
	-- alternatively:  tCol = GetClanColor(GetHogClan(CurrentHedgehog))

	DeleteVisualGear(clanPowerTag)
	clanPowerTag = AddVisualGear(-div(ScreenWidth, 2) + xOffset, ScreenHeight - yOffset, vgtHealthTag, tValue, false)

	SetVisualGearValues(
		clanPowerTag, 	-- id
		nil,		-- x offset (set above)
		nil,		-- y offset (set above)
		0, 		-- dx
		0, 		-- dy
		zoomL, 		-- zoom
		1, 		-- ~= 0 means align to screen
		nil, 		-- frameticks
		nil, 		-- value (set above)
		240000, 	-- timer
		tCol		-- color
	)

end

function XYisInRect(px, py, psx, psy, pex, pey)

	if (px > psx) and (px < pex) and (py > psy) and (py < pey) then
		return(true)
	else
		return(false)
	end

end

function AddWall(zXMin, zYMin, zWidth, zHeight, zCol)

	table.insert(wX, zXMin)
	table.insert(wY, zYMin)
	table.insert(wWidth, zWidth)
	table.insert(wHeight, zHeight)
	table.insert(wCol, zCol)

end

function BorderSpark(zXMin,zYMin, zWidth, zHeight, bCol)

	local eX = zXMin + GetRandom(zWidth+10)
	local eY = zYMin + GetRandom(zHeight+10)
	local tempE = AddVisualGear(eX, eY, vgtDust, 0, false)
	if tempE ~= 0 then
		SetVisualGearValues(tempE, eX, eY, nil, nil, nil, nil, nil, 1, nil, bCol)
	end

end

function HandleBorderEffects()

	borderEffectTimer = borderEffectTimer + 1
	if borderEffectTimer > 15 then
		borderEffectTimer = 1
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
		(GetGearType(gear) == gtJetpack) or
		(GetGearType(gear) == gtBirdy) or
		(GetGearType(gear) == gtSnowball) or
		(GetGearType(gear) == gtMolotov)
	then
		return(true)
	else
		return(false)
	end

end

function getThreatDamage(gear)

	local dmg
	--- damage amounts for weapons
	if 	(GetGearType(gear) == gtGrenade) or
		(GetGearType(gear) == gtClusterBomb) or
		(GetGearType(gear) == gtGasBomb) or
		(GetGearType(gear) == gtKnife) or
		(GetGearType(gear) == gtEgg) or
		(GetGearType(gear) == gtMolotov) or
		(GetGearType(gear) == gtHellishBomb) or
		(GetGearType(gear) == gtWatermelon) or
		(GetGearType(gear) == gtSMine) then
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
			(GetGearType(gear) == gtDynamite) then
		dmg = 0

	elseif (GetGearType(gear) == gtBall) then
		dmg = 1

	else	-- normal shell, snowball etc
		dmg = 65
	end

	return(dmg)

end

function setGearReflectionValues(gear)

	local dmg = getThreatDamage(gear)
	setGearValue(gear,"damage",dmg)
	setGearValue(gear,"deflects",0)

	if (CurrentHedgehog ~= nil) then
		setGearValue(gear,"owner",GetHogClan(CurrentHedgehog)) -- NEW NEEDS CHANGE?
	else
		setGearValue(gear,"owner",10)
	end

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

function AddStruc(pX,pY, pType, pClan)

	uniqueStructureID = uniqueStructureID + 1

	local tempG = AddGear(0, 0, gtTarget, 0, 0, 0, 0)
	SetGearPosition(tempG, pX, pY)
	setGearValue(tempG, "uniqueStructureID", uniqueStructureID)

	local tempCirc = AddVisualGear(0,0,vgtCircle,0,true)

	if pType ~= "Respawner" and pType ~= "Generator" then
		SetVisualGearValues(tempCirc, 0, 0, 100, 255, 1, 100, 0, 500, 1, 0xFFFFFF00)
		table.insert(strucCirc, tempCirc)
	else
		table.insert(strucCirc, false)
	end

	table.insert(strucID, uniqueStructureID)
	table.insert(strucType, pType)
	table.insert(strucGear,tempG)
	table.insert(strucClan,pClan)
	table.insert(strucCost,2)

	local frameID = 0
	local visualSprite = sprTarget
	local madness = AddVisualGear(GetX(tempG), GetY(tempG), vgtStraightShot, 1, true,1)

	if pType == "Reflector Shield" then
		table.insert(strucHealth,255)

	else
		table.insert(strucHealth,1)
	end

	if pType == "Bio-Filter" then
		table.insert(strucCircCol, colorBioFilter)
		table.insert(strucCircRadius,1000)
		frameID = 7
	elseif pType == "Healing Station" then
		table.insert(strucCircCol, colorHealingStation)
		table.insert(strucCircRadius,500)
		frameID = 3
	elseif pType == "Respawner" then
		table.insert(strucCircCol, 0)
		table.insert(strucCircRadius,0)
		runOnHogs(EnableHogResurrectionForThisClan)
		frameID = 1
	elseif pType == "Teleportation Node" then
		table.insert(strucCircCol, colorTeleportationNode)
		table.insert(strucCircRadius,350)
		frameID = 6
	elseif pType == "Generator" then
		table.insert(strucCircCol, 0)
		table.insert(strucCircRadius,0)
		setGearValue(tempG, "power", 0)
		frameID = 2
	elseif pType == "Support Station" then
		table.insert(strucCircCol, colorSupportStation)
		table.insert(strucCircRadius,500)
		frameID = 4
	elseif pType == "Construction Station" then
		table.insert(strucCircCol, colorConstructionStation)
		table.insert(strucCircRadius,500)
		frameID = 8
	elseif pType == "Reflector Shield" then
		table.insert(strucCircCol, colorReflectorShield)
		table.insert(strucCircRadius,750)
		frameID = 9
	elseif pType == "Weapon Filter" then
		table.insert(strucCircCol, colorWeaponFilter)
		table.insert(strucCircRadius,750)
		frameID = 5
	end


	SetVisualGearValues(madness, nil, nil, 0, 0, nil, frameID, nil, visualSprite, nil, nil)
	SetState(tempG, bor(GetState(tempG),gstInvisible) )
	table.insert(strucAltDisplay, madness)

end

-- this is basically onStructureDelete
-- we may need to expand it for non-gear structures later
function CheckGearForStructureLink(gear)

	local respawnerDestroyed = false

	for i = 1, #strucID do
		if strucID[i] == getGearValue(gear,"uniqueStructureID") then

			if strucType[i] == "Respawner" then
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

	local respawnerList = {}
	for i = 1, #strucID do
		if (strucType[i] == "Respawner") and (strucClan[i] == GetHogClan(gear)) then
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

	local respawnerList = {}
	for i = 1, #strucID do
		if (strucType[i] == "Respawner") and (strucClan[i] == GetHogClan(gear)) then
			table.insert(respawnerList, i)
		end
	end

	if #respawnerList >= 1 then
		local i = GetRandom(#respawnerList)+1
		SetGearPosition(gear,GetX(strucGear[respawnerList[i]]),GetY(strucGear[respawnerList[i]])-25)
		AddVisualGear(GetX(gear), GetY(gear), vgtExplosion, 0, false)
	else	-- (this should never happen, but just in case)
		SetEffect(gear, heResurrectable, 0)
		DeleteGear(gear)
	end

end

function CheckTeleport(gear, tX, tY)

	local teleportOriginSuccessful = false
	local teleportDestinationSuccessful = false

	for i = 1, #strucID do

		if (strucType[i] == "Teleportation Node") and (strucClan[i] == GetHogClan(CurrentHedgehog)) then

			local dist = GetDistFromGearToXY(CurrentHedgehog,GetX(strucGear[i]), GetY(strucGear[i]))
			local NR
			NR = (48/100*strucCircRadius[i])/2
			if dist <= NR*NR then
				teleportOriginSuccessful = true
			end

			dist = GetDistFromXYtoXY(tX,tY,GetX(strucGear[i]), GetY(strucGear[i]))
			NR = (48/100*strucCircRadius[i])/2
			if dist <= NR*NR then
				teleportDestinationSuccessful = true
			end

		end


	end

	if ((teleportDestinationSuccessful == false) or (teleportOriginSuccessful == false)) then
		AddCaption(loc("Teleport unsuccessful. Please teleport within a clan teleporter's sphere of influence."), colorMessageError, capgrpMessage)
		SetGearTarget(gear, GetX(CurrentHedgehog), GetY(CurrentHedgehog))
	end

end

--Check for proximity of gears to structures, and make structures behave accordingly
function CheckProximity(gear)

	local sID = tempID_CheckProximity

	local dist = GetDistFromGearToXY(gear, GetX(strucGear[sID]), GetY(strucGear[sID]))
	if not dist then
		return
	end

	-- calculate my real radius if I am an aura
	local NR
	NR = (48/100*strucCircRadius[sID])/2

	-- we're in business
	if dist <= NR*NR then

		-- heal clan hogs
		if strucType[sID] == "Healing Station" then

			if GetGearType(gear) == gtHedgehog then
				if GetHogClan(gear) == strucClan[sID] then

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
					local tempE = AddVisualGear(GetX(strucGear[sID]), GetY(strucGear[sID]), vgtSmoke, 0, true)
					SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, nil, colorHealingStationParticle)

				end
			end

		-- explode enemy clan hogs
		elseif strucType[sID] == "Bio-Filter" then

			if GetGearType(gear) == gtHedgehog then
				if (GetHogClan(gear) ~= strucClan[sID]) and (GetHealth(gear) > 0) then
					AddGear(GetX(gear), GetY(gear), gtGrenade, 0, 0, 0, 1)
				end
			end

		-- were those weapons in your pocket, or were you just happy to see me?
		elseif strucType[sID] == "Weapon Filter" then

			if GetGearType(gear) == gtHedgehog then
				if (GetHogClan(gear) ~= strucClan[sID]) then

					for wpnIndex = 1, #atkArray do
						AddAmmo(gear, atkArray[wpnIndex][1], 0)
					end

					for wpnIndex = 1, #utilArray do
						AddAmmo(gear, utilArray[wpnIndex][1], 0)
					end

					AddAmmo(gear, amCMStructurePlacer, 100)
					AddAmmo(gear, amSkip, 100)

				end
			end

		-- BOUNCE! POGO! POGO! POGO! POGO!
		elseif strucType[sID] == "Reflector Shield" then

			-- add check for whose projectile it is
			if gearCanBeDeflected(gear) == true then

				local gOwner = getGearValue(gear,"owner")
				local gDeflects = getGearValue(gear,"deflects")
				local gDmg = getGearValue(gear,"damage")

				if gDeflects >= 3 then
					DeleteGear(gear)
					AddVisualGear(GetX(gear), GetY(gear), vgtSmoke, 0, false)
					PlaySound(sndVaporize)
				elseif gOwner ~= strucClan[sID] then
					--whether to vaporize gears or bounce them
					if gDmg ~= 0 then
						local dx, dy = GetGearVelocity(gear)

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

							strucHealth[sID] = strucHealth[sID] - gDmg
							if strucCirc[sID] then
								strucCircCol[sID] = strucCircCol[sID] - gDmg
							end

							if strucHealth[sID] <= 0 then
								AddVisualGear(GetX(strucGear[sID]), GetY(strucGear[sID]), vgtExplosion, 0, false)
								DeleteGear(strucGear[sID])
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
		elseif strucType[sID] == "Teleportation Node" then

			if GetGearType(gear) == gtHedgehog then
				if GetHogClan(gear) == strucClan[sID] then

					sProx["Teleportation Mode"] = true

				end
			end

		-- mark as within range of construction station
		-- and thus allow menu access to placement modes
		-- for girders, mines, sticky mines and barrels
		elseif strucType[sID] == "Construction Station" then

			if GetGearType(gear) == gtHedgehog then
				if GetHogClan(gear) == strucClan[sID] then
					AddVisualGear(GetX(strucGear[sID]), GetY(strucGear[sID]), vgtSmoke, 0, true)

					sProx["Girder Placement Mode"] = true
					sProx["Rubber Placement Mode"] = true
					sProx["Mine Placement Mode"] = true
					sProx["Sticky Mine Placement Mode"] = true
					sProx["Barrel Placement Mode"] = true

				end
			end

		-- mark as within stupport station range
		-- and thus allow menu access to placement modes
		-- for weapon, utility, and med crates
		elseif strucType[sID] == "Support Station" then

			if GetGearType(gear) == gtHedgehog then
				if GetHogClan(gear) == strucClan[sID] then
					AddVisualGear(GetX(strucGear[sID]), GetY(strucGear[sID]), vgtSmoke, 0, true)

					sProx["Health Crate Placement Mode"] = true
					sProx["Weapon Crate Placement Mode"] = true
					sProx["Utility Crate Placement Mode"] = true

				end
			end
		end

	end

end

-- used to check if we need to run through all hogs or just currenthedgehog
function isAStructureThatAppliesToMultipleGears(pID)
	if 	strucType[pID] == "Healing Station" or
		strucType[pID] == "Reflector Shield" or
		strucType[pID] == "Weapon Filter" or
		strucType[pID] == "Bio-Filter"
	then
		return(true)
	else
		return(false)
	end
end

function HandleStructures()

	if GameTime % 100 == 0 then
		for k, _ in pairs(sProx) do
			if k ~= "Structure Placement Mode" then
				sProx[k] = false
			end
		end
	end

	for i = 1, #strucID do

		if strucCirc[i] then
			SetVisualGearValues(strucCirc[i], GetX(strucGear[i]), GetY(strucGear[i]), nil, nil, nil, nil, nil, strucCircRadius[i], nil, strucCircCol[i])
		end

		tempID_CheckProximity = i

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

			if strucType[i] == "Generator" then

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

	-- Add and remove ammo based on structure proximity
	if GameTime % 100 == 0 and CurrentHedgehog ~= nil then
		if sProx["Girder Placement Mode"] then
			AddAmmo(CurrentHedgehog, amGirder, 100)
		else
			AddAmmo(CurrentHedgehog, amGirder, 0)
		end
		if sProx["Rubber Placement Mode"] then
			AddAmmo(CurrentHedgehog, amRubber, 100)
		else
			AddAmmo(CurrentHedgehog, amRubber, 0)
		end
		if sProx["Mine Placement Mode"] or sProx["Sticky Mine Placement Mode"] or sProx["Barrel Placement Mode"] then
			AddAmmo(CurrentHedgehog, amCMObjectPlacer, 100)
		else
			AddAmmo(CurrentHedgehog, amCMObjectPlacer, 0)
		end
		if sProx["Teleportation Mode"] then
			AddAmmo(CurrentHedgehog, amTeleport, 100)
		else
			AddAmmo(CurrentHedgehog, amTeleport, 0)
		end
		if sProx["Weapon Crate Placement Mode"] or sProx["Utility Crate Placement Mode"] or sProx["Health Crate Placement Mode"] then
			AddAmmo(CurrentHedgehog, amCMCratePlacer, 100)
		else
			AddAmmo(CurrentHedgehog, amCMCratePlacer, 0)
		end
	end

end

function checkForSpecialWeapons()

	if (GetCurAmmoType() == amCMObjectPlacer) then
		AddCaption(loc("Object Placer"),GetClanColor(GetHogClan(CurrentHedgehog)),capgrpAmmoinfo)
	end

	lastWep = GetCurAmmoType()

end

------------------------
-- SOME GENERAL METHODS
------------------------

function GetDistFromGearToXY(gear, g2X, g2Y)

	local g1X, g1Y = GetGearPosition(gear)
	if not g1X then
		return nil
	end
	local q = g1X - g2X
	local w = g1Y - g2Y

	return ( (q*q) + (w*w) )

end

function GetDistFromXYtoXY(a, b, c, d)
	local q = a - c
	local w = b - d
	return ( (q*q) + (w*w) )
end

-- essentially called when user clicks the mouse
-- with girders or an airattack
function PlaceObject(x,y)

	if (clanUsedExtraTime[GetHogClan(CurrentHedgehog)] == true) and (cat[cIndex] == "Utility Crate Placement Mode") and (utilArray[pIndex][1] == amExtraTime) then
		AddCaption(loc("You may only place 1 Extra Time crate per turn."), colorMessageError, capgrpVolume)
		PlaySound(sndDenied)
	elseif (conf_cratesPerRound ~= "inf" and clanCratesSpawned[GetHogClan(CurrentHedgehog)] >= conf_cratesPerRound) and ( (cat[cIndex] == "Health Crate Placement Mode") or (cat[cIndex] == "Utility Crate Placement Mode") or (cat[cIndex] == "Weapon Crate Placement Mode")  )  then
		AddCaption(string.format(loc("You may only place %d crates per round."), conf_cratesPerRound), colorMessageError, capgrpVolume)
		PlaySound(sndDenied)
	elseif (XYisInRect(x,y, clanBoundsSX[GetHogClan(CurrentHedgehog)],clanBoundsSY[GetHogClan(CurrentHedgehog)],clanBoundsEX[GetHogClan(CurrentHedgehog)],clanBoundsEY[GetHogClan(CurrentHedgehog)]) == true)
	and (clanPower[GetHogClan(CurrentHedgehog)] >= placedExpense)
	then
		-- For checking if the actual placement succeeded
		local placed = false
		local gear
		if cat[cIndex] == "Girder Placement Mode" then
			placed = PlaceGirder(x, y, currentGirderRotation)
		elseif cat[cIndex] == "Rubber Placement Mode" then
			placed = PlaceRubber(x, y, currentGirderRotation)
		elseif cat[cIndex] == "Health Crate Placement Mode" then
			gear = SpawnHealthCrate(x,y)
			if gear ~= nil then
				placed = true
				SetHealth(gear, pMode[pIndex])
				clanCratesSpawned[GetHogClan(CurrentHedgehog)] = clanCratesSpawned[GetHogClan(CurrentHedgehog)] +1
			end
		elseif cat[cIndex] == "Weapon Crate Placement Mode" then
			gear = SpawnAmmoCrate(x, y, atkArray[pIndex][1])
			if gear ~= nil then
				placed = true
				clanCratesSpawned[GetHogClan(CurrentHedgehog)] = clanCratesSpawned[GetHogClan(CurrentHedgehog)] +1
			end
		elseif cat[cIndex] == "Utility Crate Placement Mode" then
			gear = SpawnUtilityCrate(x, y, utilArray[pIndex][1])
			if gear ~= nil then
				placed = true
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
		else
			AddCaption(loc("Invalid Placement"), colorMessageError, capgrpVolume)
			PlaySound(sndDenied)
		end

	else
		if (clanPower[GetHogClan(CurrentHedgehog)] >= placedExpense) then
			AddCaption(loc("Invalid Placement"), colorMessageError, capgrpVolume)
		else
			AddCaption(loc("Insufficient Power"), colorMessageError, capgrpVolume)
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

	if (CurrentHedgehog == nil or band(GetState(CurrentHedgehog), gstHHDriven) == 0) then
		return false
	end

	local team = GetHogTeamName(CurrentHedgehog)

	if cat[cIndex] == "Girder Placement Mode" then
		pIndex = currentGirderRotation
		pMode = {amGirder}
	elseif cat[cIndex] == "Rubber Placement Mode" then
		pIndex = currentGirderRotation
		pMode = {amRubber}
		placedExpense = 3
	elseif cat[cIndex] == "Barrel Placement Mode" then
		pMode = {60}
		placedExpense = 10
		teamLObjectMode[team] = cat[cIndex]
	elseif cat[cIndex] == "Health Crate Placement Mode" then
		pMode = {HealthCaseAmount}
		placedExpense = 5
		teamLCrateMode[team] = cat[cIndex]
	elseif cat[cIndex] == "Weapon Crate Placement Mode" then
		for i = 1, #atkArray do
			pMode[i] = atkArray[i][1]
		end
		placedExpense = atkArray[pIndex][2]
		teamLCrateMode[team] = cat[cIndex]
		pIndex = teamLWeapIndex[team]
	elseif cat[cIndex] == "Utility Crate Placement Mode" then
		for i = 1, #utilArray do
			pMode[i] = utilArray[i][1]
		end
		placedExpense = utilArray[pIndex][2]
		teamLCrateMode[team] = cat[cIndex]
		pIndex = teamLUtilIndex[team]
	elseif cat[cIndex] == "Mine Placement Mode" then
		pMode = {0,1000,2000,3000,4000,5000}
		placedExpense = 15
		teamLObjectMode[team] = cat[cIndex]
		pIndex = teamLMineIndex[team]
	elseif cat[cIndex] == "Sticky Mine Placement Mode" then
		pMode = {amSMine}
		placedExpense = 20
		teamLObjectMode[team] = cat[cIndex]
	elseif cat[cIndex] == "Structure Placement Mode" then
		pMode = {
			loc_noop("Support Station"),
			loc_noop("Construction Station"),
			loc_noop("Healing Station"),
			loc_noop("Teleportation Node"),
			loc_noop("Weapon Filter"),

			loc_noop("Bio-Filter"),
			loc_noop("Reflector Shield"),
			loc_noop("Respawner"),
			loc_noop("Generator"),
		}
		pIndex = teamLStructIndex[team]
	end

	return true
end

-- Updates the handling of the main construction mode tools:
-- Structure Placer, Crate Placer, Object Placer.
-- This handles the internal category state,
-- the HUD display and the clans outline.
function HandleConstructionModeTools()
	-- Update display selection criteria
	if (CurrentHedgehog ~= nil and band(GetState(CurrentHedgehog), gstHHDriven) ~= 0) then
		curWep = GetCurAmmoType()

		local updated = false
		local team = GetHogTeamName(CurrentHedgehog)
		if (curWep == amGirder) then
			cIndex = 1
			RedefineSubset()
			updated = true
		elseif (curWep == amRubber) then
			cIndex = 2
			RedefineSubset()
			updated = true
		elseif (curWep == amCMStructurePlacer) then
			cIndex = 9
			RedefineSubset()
			updateCost()
			updated = true
		elseif (curWep == amCMCratePlacer) then
			cIndex = catReverse[teamLCrateMode[team]]
			RedefineSubset()
			updateCost()
			updated = true
		elseif (curWep == amCMObjectPlacer) then
			cIndex = catReverse[teamLObjectMode[team]]
			RedefineSubset()
			updateCost()
			updated = true
		end

		if updated then
			AddCaption(loc(cat[cIndex]), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage)
			showModeMessage()
			wallsVisible = true
		else
			wallsVisible = false
		end
	else
		curWep = amNothing
		wallsVisible = false
	end
end


-- called in onGameTick()
function HandleConstructionMode()

	HandleStructures()

	if CurrentHedgehog ~= nil then

		if wallsVisible == true then
			HandleBorderEffects()
		end

		if (TurnTimeLeft ~= TurnTime) then
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

			-- Force-update the construction mode tools every 100ms.
			-- This makes sure the announcer messages don't disappear
			-- while the tool is selected.
			if (band(GetState(CurrentHedgehog), gstHHDriven) ~= 0) then
				curWep = GetCurAmmoType()
				HandleConstructionModeTools()
			else
				curWep = amNothing
			end

		end

	end

	-- some kind of target detected, tell me your story
	if cGear ~= nil then

		local x,y = GetGearTarget(cGear)

		if GetGearType(cGear) == gtAirAttack then
			DeleteGear(cGear)
			PlaceObject(x, y)
		elseif GetGearType(cGear) == gtTeleport then

				CheckTeleport(cGear, x, y)
				cGear = nil
		elseif GetGearType(cGear) == gtGirder then

			currentGirderRotation = GetState(cGear)

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

	if pMode[pIndex] == "Healing Station" then
		placedExpense = 50
	elseif pMode[pIndex] == "Weapon Filter" then
		placedExpense = 50
	elseif pMode[pIndex] == "Bio-Filter" then
		placedExpense = 100
	elseif pMode[pIndex] == "Respawner" then
		placedExpense = 300
	elseif pMode[pIndex] == "Teleportation Node" then
		placedExpense = 30
	elseif pMode[pIndex] == "Support Station" then
		placedExpense = 50
	elseif pMode[pIndex] == "Construction Station" then
		placedExpense = 50
	elseif pMode[pIndex] == "Generator" then
		placedExpense = 300
	elseif pMode[pIndex] == "Reflector Shield" then
		placedExpense = 200
	elseif cat[cIndex] == "Weapon Crate Placement Mode" then
		placedExpense = atkArray[pIndex][2]
	elseif cat[cIndex] == "Utility Crate Placement Mode" then
		placedExpense = utilArray[pIndex][2]
	end

	AddCaption(string.format(loc("Cost: %d"), placedExpense), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmostate)

end

-- Should be called when the index of the mode was changed by the player.
-- E.g. new weapon crate contents or structure type
function updateIndex()
	if (curWep == amGirder) or (curWep == amRubber) or (curWep == amCMStructurePlacer) or (curWep == amCMCratePlacer) or (curWep == amCMObjectPlacer) then
		showModeMessage()
		updateCost()
	end

	-- Update team variables so the previous state can be restored later
	if CurrentHedgehog == nil or band(GetState(CurrentHedgehog), gstHHDriven) == 0 then return end
	local val = pMode[pIndex]
	local team = GetHogTeamName(CurrentHedgehog)
	if cat[cIndex] == "Structure Placement Mode" then
		teamLStructIndex[team] = pIndex
	elseif cat[cIndex] == "Mine Placement Mode" then
		teamLMineIndex[team] = pIndex
	elseif cat[cIndex] == "Weapon Crate Placement Mode" then
		teamLWeapIndex[team] = pIndex
	elseif cat[cIndex] == "Utility Crate Placement Mode" then
		teamLUtilIndex[team] = pIndex
	end
end

function showModeMessage()
	if CurrentHedgehog == nil or band(GetState(CurrentHedgehog), gstHHDriven) == 0 then return end
	local val = pMode[pIndex]
	local str
	if cat[cIndex] == "Mine Placement Mode" then
		-- timer in seconds
		str = string.format(loc("%d sec"), div(val, 1000))
	elseif cat[cIndex] == "Structure Placement Mode" then
		str = loc(val)
	elseif cat[cIndex] == "Girder Placement Mode" then
		str = GetAmmoName(amGirder)
	elseif cat[cIndex] == "Rubber Placement Mode" then
		str = GetAmmoName(amRubber)
	elseif cat[cIndex] == "Weapon Crate Placement Mode"
	or cat[cIndex] == "Utility Crate Placement Mode"
	or cat[cIndex] == "Sticky Mine Placement Mode" then
		str = GetAmmoName(val)
	else
		str = tostring(val)
	end
	AddCaption(str, GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage2)
end

function rotateMode(pDir)
	curWep = GetCurAmmoType()
	local foundMatch = false
	while(foundMatch == false) do
		cIndex = cIndex + pDir

		if (cIndex == 1) or (cIndex == 2) then -- we no longer hit girder by normal means
			cIndex = #cat
		elseif cIndex > #cat then
			cIndex = 3       -- we no longer hit girder by normal means
		end

		if (GetCurAmmoType() == amCMCratePlacer) then
			if (cat[cIndex] == "Health Crate Placement Mode") or
				(cat[cIndex] == "Weapon Crate Placement Mode") or
				(cat[cIndex] == "Utility Crate Placement Mode") then
					foundMatch = true
			end
		elseif (GetCurAmmoType() == amCMObjectPlacer) then
			if (cat[cIndex] == "Mine Placement Mode") or
				(cat[cIndex] == "Sticky Mine Placement Mode") or
				(cat[cIndex] == "Barrel Placement Mode") then
				foundMatch = true
			end
		elseif (GetCurAmmoType() == amCMStructurePlacer) then
			if cat[cIndex] == "Structure Placement Mode" then
				foundMatch = true
			end
		end
	end

	if foundMatch == true then
		RedefineSubset()
		--updateCost()
		HandleConstructionModeTools()
	end
end

---------------------
-- PLAYER CONTROLS --
---------------------

-- [Timer X]: Used as shortcut key for faster selection of stuff
function onTimer(key)
	curWep = GetCurAmmoType()

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
			updateIndex()
		end
	elseif (curWep == amCMObjectPlacer) then
		-- [Timer X]: Set mine time 1-5
		if cat[cIndex] == "Mine Placement Mode" then
			local index = key + 1
			if key <= #pMode then
				pIndex = index
				updateIndex()
			end
		end
	end

	checkForSpecialWeaponsIn = 1

end

-- [Switch]: Set mine time to 0 (only in mine placement mode)
function onSwitch()
	curWep = GetCurAmmoType()
	if (curWep == amCMObjectPlacer) then
		pIndex = 1
		updateIndex()
	end
end

-- [Left]/[Right]: Change submode (e.g. structure type) of any Construction Mode tool or rotate girder/rubber
function onLeft()
	curWep = GetCurAmmoType()
	if (curWep == amGirder) or (curWep == amRubber) or (curWep == amCMStructurePlacer) or (curWep == amCMCratePlacer) or (curWep == amCMObjectPlacer) then
		pIndex = pIndex - 1
		if pIndex == 0 then
			pIndex = #pMode
		end
		updateIndex()
	end
end
function onRight()
	curWep = GetCurAmmoType()
	if (curWep == amGirder) or (curWep == amRubber) or (curWep == amCMStructurePlacer) or (curWep == amCMCratePlacer) or (curWep == amCMObjectPlacer) then
		pIndex = pIndex + 1
		if pIndex > #pMode then
			pIndex = 1
		end
		updateIndex()
	end
end

-- [Up]/[Down]
-- Cycle through the primary categories
-- (by changing cIndex) i.e. mine, sticky mine,
-- barrels, health/weapon/utility crate.
function onUp()
	curWep = GetCurAmmoType()
	if ( (curWep == amCMCratePlacer) or (curWep == amCMObjectPlacer) ) then
		if CurrentHedgehog ~= nil and band(GetState(CurrentHedgehog), gstHHDriven) ~= 0 then
			rotateMode(-1)
		end
	end

end
function onDown()
	curWep = GetCurAmmoType()
	if ( (curWep == amCMCratePlacer) or (curWep == amCMObjectPlacer) ) then
		if CurrentHedgehog ~= nil and band(GetState(CurrentHedgehog), gstHHDriven) ~= 0 then
			rotateMode(1)
		end
	end
end

-- [Set weapon]/[Slot X]: Just update internal stuff
onSetWeapon = HandleConstructionModeTools()
onSlot = onSetWeapon

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

	-- Engine already placed hogs in fort mode
	if not fortMode then
		FindPlace(gear, false, clanBoundsSX[GetHogClan(gear)], clanBoundsEX[GetHogClan(gear)],true)
	end

	-- Add core ammo
	AddAmmo(gear, amCMStructurePlacer, 100)
	AddAmmo(gear, amSkip, 100)

	-- Remove special Construction Mode stuff.
	-- This stuff is added and removed dynamically based on
	-- proximity to structures.
	AddAmmo(gear, amCMObjectPlacer, 0)
	AddAmmo(gear, amCMCratePlacer, 0)
	AddAmmo(gear, amGirder, 0)
	AddAmmo(gear, amRubber, 0)
	AddAmmo(gear, amTeleport, 0)

	-- Mine strike is broken, so we force-remove it
	AddAmmo(gear, amMineStrike, 0)

	-- Everything else is set by the weapon scheme.
	-- Infinite switch is recommended.
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
	loc("Support Station: Allows placement of crates.") .. "|"..
	loc("Construction Station: Allows placement of|    girders, rubber, mines, sticky mines|    and barrels.")  .. "|" ..
	loc("Healing Station: Heals nearby hogs.")  .. "|" ..
	loc("Teleportation Node: Allows teleportation|    between other nodes.")  .. "|" ..
	loc("Weapon Filter: Dematerializes all ammo|    carried by enemies entering it.")  .. "|" ..
	loc("Bio-Filter: Aggressively removes enemies.")  .. "|" ..
	loc("Reflector Shield: Reflects enemy projectiles.")  .. "|" ..
	loc("Respawner: Resurrects dead hogs.")  .. "|" ..
	loc("Generator: Generates energy.")  .. "|" ..
	" |" ..

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
	
	local sCirc = AddVisualGear(0,0,vgtCircle,0,true)
	SetVisualGearValues(sCirc, 0, 0, 100, 255, 1, 10, 0, 40, 3, 0x00000000)

	for i = 0, ClansCount-1 do
		clanPower[i] = math.min(conf_initialEnergy, conf_maxEnergy)

		clanUsedExtraTime[i] = false
		clanCratesSpawned[i] = 0
		clanFirstTurn[i] = true

	end
	for i = 0, TeamsCount-1 do
		local team = GetTeamName(i)
		teamLStructIndex[team] = 1
		teamLObjectMode[team] = "Mine Placement Mode"
		teamLCrateMode[team] = "Weapon Crate Placement Mode"
		teamLMineIndex[team] = 1
		teamLWeapIndex[team] = 1
		teamLUtilIndex[team] = 1
	end

	local tMapWidth = RightX - LeftX
	local tMapHeight = WaterLine - TopY
	local clanInterval = div(tMapWidth,ClansCount)

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
		AddWall(LeftX+(clanInterval*slot),TopY,clanInterval,wMargin,color)
		AddWall(LeftX+(clanInterval*slot),WaterLine-25,clanInterval,wMargin,color)

		--add a wall to the left and right
		AddWall(LeftX+(clanInterval*slot)+20,TopY,wMargin,WaterLine,color)
		AddWall(LeftX+(clanInterval*slot)+clanInterval-20,TopY,wMargin,WaterLine,color)

	end

	runOnHogs(initialSetup)

end


function onNewTurn()

	curWep = GetCurAmmoType()

	HandleConstructionModeTools()

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

function onEndTurn()
	curWep = amNothing
	HandleConstructionModeTools()
end

function onGameTick()
	HandleConstructionMode()
end

function onScreenResize()
	-- redraw Tags so that their screen locations are updated
	if (CurrentHedgehog ~= nil) then
		DrawClanPowerTag()
	end
end


function onGearResurrect(gear)
	AddVisualGear(GetX(gear), GetY(gear), vgtExplosion, 0, false)
	FindRespawner(gear)
end

-- track hedgehogs and placement gears
function onGearAdd(gear)

	local gt = GetGearType(gear)
	if (gt == gtAirAttack) or (gt == gtTeleport) or (gt == gtGirder) then
		cGear = gear
	elseif (gt == gtMine) or (gt == gtExplosives) or (gt == gtSMine) then
		curWep = GetCurAmmoType()
		if curWep == amCMObjectPlacer then
			checkForSpecialWeaponsIn = 1
		end
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

		trackDeletion(gear)

	end

end

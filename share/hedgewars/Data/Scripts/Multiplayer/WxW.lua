
----------------------
-- WALL TO WALL 0.4
----------------------
-- a shoppa minigame
-- by mikade

-- feel free to add map specific walls to LoadConfig, or post additional
-- wall suggestions on our forum at: http://www.hedgewars.org/forum

----------------
--0.1
----------------
-- concept test

----------------
--0.2
----------------
-- unhardcoded turntimeleft, now uses shoppa default of 45s
-- changed some things behind the scenes
-- fixed oooooold radar bug
-- added radar / script support for multiple crates
-- tweaked weapons tables
-- added surfing and changed crate spawn requirements a bit

----------------
--0.3
----------------
-- stuffed dirty clothes into cupboard
-- improved user feedback
-- added/improved experimental config system, input masks included :D

----------------
--0.4
----------------
-- for version 0.9.18, now detects border in correct location
-- fix 0.3 config constraint
-- remove unnecessary vars
-- oops, remove hardcoding of minesnum,explosives
-- ... and unhardcode turntime (again)... man, 30s is hard :(
-- move some initialisations around
-- numerous improvements to user feedback
-- walls disappear after being touched
-- added backwards compatibility with 0.9.17

----------------
--TO DO
----------------
-- achievements / try detect shoppa moves? :|
-- maybe add ability for the user to place zones like in Racer?
-- add more hard-coded values for specific maps

-----------------------------
-- GO PONIES, GO PONIES, GO!
-----------------------------

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")

-- experimental menu stuff
local menuIndex = 1
local menu = {}
local preMenuCfg
local postMenuCfg
local roundN = 0

-- config and wall variables
local AFR = false
local allowCrazyWeps = false
local requireSurfer = true
local wX = {}
local wY = {}
local wWidth = {}
local wHeight = {}
local wTouched = {}
--local margin
local wallsLeft = 0

local hasSurfed = false
local allWallsHit = false

local gTimer = 1
local effectTimer = 1

local ropeG = nil
local crateG = nil
local allowCrate = true

-- crate radar vars
local rCirc = {}
local rAlpha = 255
local rPingTimer = 0
local m2Count = 0

local weapons = {}

--[[local unlisted = {amTardis, amLandGun,amExtraTime,amExtraDamage,
				amVampiric, amSwitch, amInvulnerable, amGirder, amJetpack,
				amPortalGun, amTeleport, amResurrector, amLaserSight, amLowGravity,
				amAirAttack, amNapalm, amMineStrike, amDrillStrike,
				amKamikaze, amSnowball, amSeduction}]]

local crazyWeps = {amWatermelon, amHellishBomb, amBallgun, amRCPlane}

local groundWeps = 	{amBee, amShotgun,amDEagle,amFirePunch, amWhip,
				amPickHammer, amBaseballBat, amCake,amBallgun,
				amRCPlane, amSniperRifle, amBirdy, amBlowTorch, amGasBomb,
				amFlamethrower, amSMine, amMortar, amHammer}

local ropeWeps = {amGrenade, amClusterBomb, amBazooka, amMine, amDynamite,
				amWatermelon, amHellishBomb, amDrill, amMolotov}

-- 0.9.18+ extra custom data for preset maps
local MapList =
	{
	--name,      						surfer, roof, 	LRwalls
	{"Atlantis Shoppa", 			    true, 	false, true},
	{"BambooPlinko", 				    true,	false, true},
	{"BrickShoppa", 				    false, 	false, true},
	{"BubbleFlow",   					true, 	false, true},
	{"Cave",       						false, 	false, true},
	{"Glass Shoppa",      				true, 	false, true},
	{"HardIce",      					false, 	false, true},
	{"Industrial",       				false,	false, true},
	{"Islands",       					true, 	false, true},
	{"Hedgelove",       				true, 	false, true},
	{"NeonStyle",       				false, 	false, true},
	{"Octorama",       					false, 	false, true},
	{"red vs blue - Castle",     		true, 	false, true},
	{"red vs blue - castle2",     		true, 	false, true},
	{"red vs blue - True Shoppa Sky",   true, 	false, true},
	{"Ropes",       					false, 	false, true},
	{"Ropes Rearranged",      			false, 	false, true},
	{"RopesRevenge Flipped",    		true, 	false, true},
	{"Ropes Three",      				false, 	false, true},
	{"RopesTwo",      					false, 	false, true},
	{"ShapeShoppa1.0",     				true, 	false, true},
	{"ShappeShoppa Darkhow",      		true, 	false, true},
	{"ShoppaCave2",      				true, 	false, true},
	{"ShoppaFun",      					true, 	false, true},
	{"ShoppaGolf",      				false, 	false,  true},
	{"ShoppaHell",      				false, 	true,  false},
	{"ShoppaKing",       				false, 	false, false},
	{"ShoppaNeon",       				false, 	false, true},
	{"ShoppaSky",       				false, 	false, true},
	{"Shoppawall",       				false, 	false, true},
	{"SkatePark",       				false, 	false, true},
	{"SloppyShoppa",      				false, 	false, true},
	{"Sticks",       					true, 	false, true},
	{"Symmetrical Ropes ",       		false, 	false, true},
	{"Tetris",       					false, 	false, true},
	{"TransRopes2",      				false, 	false, true},
	{"Wildmap",      					false, 	false, true},
	{"Winter Shoppa",      				false, 	false, true},
	{"2Cshoppa",      					true, 	false, true}
	}

function BoolToCfgTxt(p)
	if p == false then
		return loc("Disabled")
	else
		return loc("Enabled")
	end
end

function LoadConfig(p)

	margin = 20
	mapID = nil

	-- 0.9.17
	if Map == "CHANGE_ME" then
		AddCaption(loc("For improved features/stability, play 0.9.18+"))
		--AddWall(10,10,4085,margin)
		AddWall(10,10,margin,2025)
		AddWall(4085-margin,10,margin,2025)
	end

	--0.9.18+
	for i = 1, #MapList do
		if Map == MapList[i][1] then
			mapID = i
			--AddCaption(MapList[i][1] .. " found. reqSurf is " .. BoolToCfgTxt(MapList[i][2]))
		end
	end

	if (p == 1) and (mapID ~= nil) then
		requireSurfer = MapList[mapID][2]
	end

	if mapID ~= nil then

		-- add a wall to the roof
		if MapList[mapID][3] == true then
			AddWall(LeftX+10,TopY+10,RightX-LeftX-20,margin)
		end

		-- add walls on the left and right border
		if MapList[mapID][4] == true then
			AddWall(LeftX+10,TopY+10,margin,WaterLine)
			AddWall(RightX-10-margin,TopY+10,margin,WaterLine)
		end

		-- add map specific walls
		if Map == "Ropes" then
			AddWall(1092,934,54,262)
			AddWall(2822,323,33,137)
		elseif Map == "ShoppaKing" then
			AddWall(3777,1520,50,196)
			AddWall(1658,338,46,670)
		elseif Map == "ShoppaHell" then
			AddWall(2035,831,30,263)
			AddWall(3968,1668,31,383)
		elseif Map == "ShoppaNeon" then
			AddWall(980,400,20,300)
			AddWall(1940,400,20,300)
			AddWall(3088,565,26,284)
			AddWall(187,270,28,266)
		end

	-- if map is unrecognized, add two walls on the side borders
	-- also, if version of hw is not 0.9.17 or lower
	elseif Map ~= "CHANGE_ME" then
		AddWall(LeftX+10,TopY+10,margin,WaterLine)
		AddWall(RightX-10-margin,TopY+10,margin,WaterLine)
	end


end

function AddWall(zXMin,zYMin, zWidth, zHeight)

	table.insert(wX, zXMin)
	table.insert(wY, zYMin)
	table.insert(wWidth, zWidth)
	table.insert(wHeight, zHeight)
	table.insert(wTouched, false)

end

function DrawBlip(gear)
	SetVisualGearValues(getGearValue(gear,"CIRC"), getGearValue(gear,"RX"), getGearValue(gear,"RY"), 100, 255, 1, 10, 0, 40, 3, GetClanColor(GetHogClan(CurrentHedgehog))-rAlpha)
end

function TrackRadarBlip(gear)

	-- work out the distance to the target
	g1X, g1Y = GetGearPosition(CurrentHedgehog)
	g2X, g2Y = GetX(gear), GetY(gear)
	q = g1X - g2X
	w = g1Y - g2Y
	r = math.sqrt( (q*q) + (w*w) )	--alternate

	RCX = getGearValue(gear,"RX")
	RCY = getGearValue(gear,"RY")

	rCircDistance = r -- distance to circle

	opp = w
	if opp < 0 then
		opp = opp*-1
	end

	-- work out the angle (theta) to the target
	t = math.deg ( math.asin(opp / r) )

	-- based on the radius of the radar, calculate what x/y displacement should be
	NR = 150 -- radius at which to draw circs
	NX = math.cos( math.rad(t) ) * NR
	NY = math.sin( math.rad(t) ) * NR

	if rCircDistance < NR then
		RCX = g2X
	elseif q > 0 then
		RCX = g1X - NX
	else
		RCX = g1X + NX
	end

	if rCircDistance < NR then
		RCY = g2Y
	elseif w > 0 then
		RCY = g1Y - NY
	else
		RCY = g1Y + NY
	end

	setGearValue(gear, "RX", RCX)
	setGearValue(gear, "RY", RCY)

end


function HandleCircles()

	-- enable this if you want the radar to only show for a few seconds
	-- after you spawn the crate
	--[[if rAlpha ~= 255 then

		rPingTimer = rPingTimer + 1
		if rPingTimer == 100 then
			rPingTimer = 0

			rAlpha = rAlpha + 5
			if rAlpha >= 255 then
				rAlpha = 255
			end
		end

	end]]

	runOnGears(DrawBlip)

	m2Count = m2Count + 1
	if m2Count == 25 then
		m2Count = 0

		if (CurrentHedgehog ~= nil) and (rAlpha ~= 255) then
			runOnGears(TrackRadarBlip)
		end

	end

end


function CheckCrateConditions()

	crateSpawn = true

	if requireSurfer == true then
		if hasSurfed == false then
			crateSpawn = false
		end
	end

	if #wTouched > 0 then
		if allWallsHit == false then
			crateSpawn = false
		end
	end

	if crateSpawn == true then
		if allowCrate == true then
		--if (crateG == nil) and (allowCrate == true) then
			--AddCaption("")
			SpawnAmmoCrate(0, 0, weapons[1+GetRandom(#weapons)] )
			rPingTimer = 0
			rAlpha = 0
			PlaySound(sndWarp)
		end
	end

end

function onGearWaterSkip(gear)
	if gear == CurrentHedgehog then
		hasSurfed = true
		AddCaption(loc("Surfer!"),0xffba00ff,capgrpMessage2)
	end
end


function WallHit(id, zXMin,zYMin, zWidth, zHeight)

	if wTouched[id] == false then
		tempE = AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtBigExplosion, 0, false)
		PlaySound(sndExplosion)
		wallsLeft = wallsLeft - 1

		if wallsLeft == 0 then
			AddCaption(loc("All walls touched!"))
			allWallsHit = true
			if (requireSurfer == true) and (hasSurfed == false) then
				AddCaption(loc("Go surf!"),0xffba00ff,capgrpMessage2)
			end
		else
			AddCaption(loc("Walls Left") .. ": " .. wallsLeft)
		end

	end

	wTouched[id] = true
	tempE = AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmoke, 0, false)
	--PlaySound(sndVaporize) -- yeah, this is just annoying as shit

end

function CheckForWallCollision()

	for i = 1, #wTouched do
		if gearIsInBox(CurrentHedgehog, wX[i],wY[i],wWidth[i],wHeight[i]) then
			WallHit(i, wX[i],wY[i],wWidth[i],wHeight[i])
		end
	end

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

		for i = 1, #wTouched do
			if wTouched[i] == true then
				--bCol = GetClanColor(GetHogClan(CurrentHedgehog))
			else
				--bCol = 0xFFFFFFFF
				bCol = GetClanColor(GetHogClan(CurrentHedgehog))
				BorderSpark(wX[i],wY[i],wWidth[i],wHeight[i], bCol)
			end
			--BorderSpark(wX[i],wY[i],wWidth[i],wHeight[i], bCol)
		end

	end

end

function onLJump()
	if roundN < 2 then
		roundN = 100
		SetInputMask(0xFFFFFFFF)
		TurnTimeLeft = 1
		AddCaption(loc("Configuration accepted."),0xffba00ff,capgrpMessage)
		HideMission()
	end
end

function onAttack()

	if roundN < 2 then

		if menuIndex == 1 then

			if #wTouched > 0 then
				for i = 1, #wTouched do
					wTouched[i] = nil
					wX[i] = nil
					wY[i] = nil
					wWidth[i] = nil
					wHeight[i] = nil
				end
			else
				LoadConfig(2)
			end

		elseif menuIndex == 2 then
			requireSurfer = not(requireSurfer)
		elseif menuIndex == 3 then
			AFR = not(AFR)
		elseif menuIndex == 4 then
			allowCrazyWeps = not(allowCrazyWeps)
		end

		UpdateMenu()
		configureWeapons()
		HandleStartingStage()

	elseif (AFR == true) then

		if (GetCurAmmoType() ~= amRope) and
			(GetCurAmmoType() ~= amSkip) and
			(GetCurAmmoType() ~= amNothing)
		then
			AddCaption(loc("You may only attack from a rope!"),0xffba00ff,capgrpMessage2)
		end

	end

end

function onDown()
	if roundN < 2 then
		menuIndex = menuIndex +1
		if menuIndex > #menu then
			menuIndex = 1
		end
		HandleStartingStage()
	end
end

function onUp()
	if roundN < 2 then
		menuIndex = menuIndex -1
		if 	menuIndex == 0 then
			menuIndex = #menu
		end
		HandleStartingStage()
	end
end

function onGameInit()

	ClearGameFlags()
	EnableGameFlags(gfRandomOrder, gfBorder, gfSolidLand) --, gfInfAttack
	HealthCaseProb = 0
	CaseFreq = 0

end

function configureWeapons()

	-- reset wep array
	for i = 1, #weapons do
		weapons[i] = nil
	end

	-- add rope weps
	for i, w in pairs(ropeWeps) do
        table.insert(weapons, w)
	end

	-- add ground weps
	for i, w in pairs(groundWeps) do
        table.insert(weapons, w)
	end

	-- remove ground weps if attacking from rope is mandatory
	if AFR == true then
		for i = 1, #weapons do
			for w = 1, #groundWeps do
				if groundWeps[w] == weapons[i] then
					table.remove(weapons, i)
				end
			end
		end
	end

	-- remove crazy weps is crazy weps aren't allowed
	if allowCrazyWeps == false then
		for i = 1, #weapons do
			for w = 1, #crazyWeps do
				if crazyWeps[w] == weapons[i] then
					table.remove(weapons, i)
				end
			end
		end
	end

end

function onGameStart()

	LoadConfig(1)
	configureWeapons()
	UpdateMenu()
	HandleStartingStage()

end

function onNewTurn()

	wallsLeft = #wTouched

	for i = 1, #wTouched do
		wTouched[i] = false
	end

	allowCrate = true

	hasSurfed = false
	allWallsHit = false

	crateG = nil

	-- new config stuff
	roundN = roundN + 1
	if roundN < 2 then
		TurnTimeLeft = -1
		SetInputMask(0)
		allowCrate = false
		HandleStartingStage() -- new
	end

end

function UpdateMenu()

	preMenuCfg = loc("Spawn the crate, and attack!") .. "|"
	postMenuCfg = loc("Press [Enter] to accept this configuration.")

	menu = 	{
			loc("Walls Required") .. ": " .. #wTouched .. "|",
			loc("Surf Before Crate") .. ": " .. BoolToCfgTxt(requireSurfer) .. "|",
			loc("Attack From Rope") .. ": " .. BoolToCfgTxt(AFR) .. "|",
			loc("Super Weapons") .. ": " .. BoolToCfgTxt(allowCrazyWeps) .. "|"
			}
end

function HandleStartingStage()

	temp = menu[menuIndex]
	menu[menuIndex] = "--> " .. menu[menuIndex]

	missionComment = ""
	for i = 1, #menu do
		missionComment = missionComment .. menu[i]
	end

	ShowMission	(
				loc("WALL TO WALL") .. " 0.4",
				loc("a shoppa minigame"),
				preMenuCfg..
				missionComment ..
				postMenuCfg ..
				--" " .. "|" ..
				"", 4, 300000
				)

	menu[menuIndex] = temp

end

function onGameTick()

	if CurrentHedgehog ~= nil then

		--AddCaption(Map)
		--AddCaption(RightX ..";" .. GetX(CurrentHedgehog))

		gTimer = gTimer + 1
		if gTimer == 25 then
			gTimer = 1

			CheckForWallCollision()
			CheckCrateConditions()

			if (crateG == GetFollowGear()) and (crateG ~= nil) then
				FollowGear(CurrentHedgehog)
			end

			-- if attackfromrope is set, forbid firing unless using rope
			if (AFR == true) and (roundN >= 2) then
				if (GetCurAmmoType() == amRope) or
					(GetCurAmmoType() == amSkip) or
					(GetCurAmmoType() == amNothing)
				then
					SetInputMask(0xFFFFFFFF)
				elseif ropeG == nil then
					SetInputMask(bnot(gmAttack))
				end
			end

		end

		HandleBorderEffects()
		HandleCircles()

	end

end

function onGearAdd(gear)

	if GetGearType(gear) == gtRope then
		ropeG = gear
	elseif GetGearType(gear) == gtCase then

		crateG = gear
		trackGear(gear)

		table.insert(rCirc, AddVisualGear(0,0,vgtCircle,0,true) )
		setGearValue(gear,"CIRC",rCirc[#rCirc])
		setGearValue(gear,"RX",0)
		setGearValue(gear,"RY",0)
		SetVisualGearValues(rCirc[#rCirc], 0, 0, 100, 255, 1, 10, 0, 40, 3, 0xff00ffff)

		allowCrate = false

		rPingTimer = 0
		rAlpha = 0

	end

end

function onGearDelete(gear)

	if gear == ropeG then
		ropeG = nil
	elseif GetGearType(gear) == gtCase then

		if gear == crateG then
			crateG = nil
		--	rAlpha = 255
		end

		for i = 1, #rCirc do
			if rCirc[i] == getGearValue(gear,"CIRC") then
				DeleteVisualGear(rCirc[i])
				table.remove(rCirc, i)
			end
		end

		trackDeletion(gear)

	end

end

function onAmmoStoreInit()

	for i, w in pairs(ropeWeps) do
        SetAmmo(w, 0, 0, 0, 1)
    end

    for i, w in pairs(groundWeps) do
        SetAmmo(w, 0, 0, 0, 1)
    end

    for i, w in pairs(crazyWeps) do
        SetAmmo(w, 0, 0, 0, 1)
    end

	SetAmmo(amRope, 9, 0, 0, 0)
	SetAmmo(amSkip, 9, 0, 0, 0)

end

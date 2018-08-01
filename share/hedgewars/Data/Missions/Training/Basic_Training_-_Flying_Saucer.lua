--[[
	Flying Saucer Training
	This is a training mission which teaches many basic (and not-so-basic) moves
	with the flying saucer.

	Lesson plan:
	- Taking off
	- Basic flight
	- Landing safely
	- Managing fuel
	- Changing saucers in mid-flight
	- Diving
	- Dropping weapons from flying saucer
	- Firing from flying saucer with [Precise] + [Attack]
	- Aiming in flying saucer with [Precise] + [Up]/[Down]
	- Underwater attack
	- Free flight with inf. fuel and some weapons at end of training

	FIXME:
	- Bad respawn animation ("explosion" just happens randomly because of the way the resurrection effect works)
	- Hide fuel if infinite (probably needs engine support)
]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

local Player = nil -- Pointer to hog created in: onGameInit
local Target = nil -- Pointer to target hog
local Objective = false -- Get to the target

local TargetNumber = 0 -- The current target number
local GrenadeThrown = false -- Used for the Boom Target
local BazookasLeft = 0 -- Used by the Launch Target and the Unterwater Attack Target

local InfFuel = false -- If true, flying saucer has infinite fuel
local SaucerGear = nil -- Store flying saucer gear here (if one exists)
local TargetGears = {} -- List of remaining gears to collect or destroy in the current round
local TargetsRemaining = 0
local Barrels = {} -- Table contraining the explosive barrel gears

local CheckTimer = 500 -- Time to wait at least before checking safe landing
local Check = false -- The last target has recently been collected/destroyed and the CheckTimer is running
local GrenadeTimer = 0 -- Time after a grenade has been thrown

local TargetPos = {} -- Table of targets

local StartPos = { X = 742, Y = 290 }

--[[
List of all targets (or "objectives"). The player has to complete them one-by-one and must always land safely afterwards.
Some target numbers have names for easier reference.
]]
TargetPos[1] =  {
	Targets = {{ X = 1027, Y = 217 }},
	Ammo = { },
	Message = loc("Here you will learn how to fly the flying saucer|and get so learn some cool tricks.") .. "|" ..
	loc("Collect the first crate to begin!"),
	MessageIcon = -amJetpack, }
TargetPos[2] = {
	Targets = {{ X = 1369, Y = 265 }},
	Ammo = { [amJetpack] = 100 },
	InfFuel = true,
	MessageTime = 10000,
	Message = loc("Get to the crate using your flying saucer!") .. "|" ..
	loc("Press [Attack] (space bar by default) to start,|repeatedly tap the up, left and right movement keys to accelerate.") .. "|" ..
	loc("Try to land softly, as you can still take fall damage!"), }
TargetPos[3] = {
	Targets = {{ X = 689, Y = 58 }},
	Ammo = { [amJetpack] = 100 },
	MessageTime = 5000,
	Message = loc("Now collect the next crate!") .. "|" .. loc("Be careful, your fuel is limited from now on!") .."|" ..
	loc("Tip: If you get stuck in this training, use \"Skip turn\" to restart the current objective.") }

-- The Double Target
local DoubleTarget = 4
TargetPos[4] = {
	Targets = { { X = 84, Y = -20 }, { X = 1980 , Y = -20 } },
	Ammo = { [amJetpack] = 2 },
	MessageTime = 9000,
	Message = loc("Now collect the 2 crates to the far left and right.") .. "|" ..
	loc("You only have 2 flying saucers this time.") .. "|" ..
	loc("Tip: You can change your flying saucer|in mid-flight by hitting the [Attack] key twice."), }
TargetPos[5] = {
	Targets = {{ X = 47, Y = 804 }},
	Ammo = { [amJetpack] = 100 },
	MessageTime = 5000,
	Message = loc("Time for a more interesting stunt, but first just collect the next crate!"), }
TargetPos[6] = {
	Targets = {{ X = 604, Y = 871}},
	MessageTime = 15000,
	Message = loc("You can dive with your flying saucer!") .. "|" ..
	loc("Try it now and dive here to collect the crate on the right girder.") .. "|" ..
	loc("You only have one flying saucer this time.") .. "|" ..
	loc("Beware, though, you will only be able to move slowly through the water.") .. "|" ..
	loc("Warning: Never ever leave the flying saucer while in water!"),
	Ammo = { [amJetpack] = 1 }, }

TargetPos[7] = { 
	Targets = {{ X = 1884, Y = 704 }},
	MessageTime = 6500,
	Message = loc("Now dive just one more time and collect the next crate.") .. "|" ..
		loc("Tip: Don't remain for too long in the water, or you won't make it."),
	Ammo = { [amJetpack] = 1}, }

-- The Boom Target
local BoomTarget = 8
TargetPos[8] = {
	Modifier = true, Func = function()
		Info(loc("Instructions"),
		loc("Now let's try to drop weapons while flying!") .. "|" ..
		loc("You have to destroy the target above by dropping a grenade on it from your flying saucer.") .. "|" ..
		loc("It's not that easy, so listen carefully:") .. "|" ..
		loc("Step 1: Activate your flying saucer but do NOT move yet!") .. "|" ..
		loc("Step 2: Select your grenade.") .. "|" ..
		loc("Step 3: Start flying and get yourself right above the target.") .. "|" ..
		loc("Step 4: Drop your grenade by pressing the [Long jump] key.") .. "|" ..
		loc("Step 5: Get away quickly and land safely anywhere.") .. "| |" ..
		loc("Note: We only give you grenades if you stay in your flying saucer."), nil, 20000)

		SpawnBoomTarget()

		if SaucerGear ~= nil then
			AddAmmo(Player, amGrenade, 1)
		else
			AddAmmo(Player, amGrenade, 0)
		end
		GrenadeThrown = false

	end,
	Ammo = { [amJetpack] = 100 },
	Respawn = { X = 2000, Y = 742 }, }

-- The Launch Target
local LaunchTarget = 9
TargetPos[9] = {
	Targets = {{ X = 1700, Y = 640, Type = gtTarget }, { X = 1460, Y = 775, Type = gtTarget }},
	MessageTime = 20000,
	Message = loc("Only the best pilots can master the following stunts.") .. "|" ..
		loc("As you've seen, the dropped grenade roughly fell into your flying direction.") .. "|" ..
		loc("You have to destroy two targets, but the previous technique would be very difficult or dangerous to use.") .. "|" ..
		loc("So you are able to launch projectiles into your aiming direction, always at full power.") .."|"..
		loc("To launch a projectile in mid-flight, hold [Precise] and press [Long jump].") .. "|" ..
		loc("You can even change your aiming direction in mid-flight if you first hold [Precise] and then press [Up] or [Down].") .. "|" ..
		loc("Tip: Changing your aim while flying is very difficult, so adjust it before you take off."),
	Ammo = { [amJetpack] = 1, },
	Respawn = { X = 1764, Y = 916 },
	ExtraFunc = function()
		HogTurnLeft(Player, true)
		if SaucerGear ~= nil then
			AddAmmo(Player, amBazooka, 2)
		else
			AddAmmo(Player, amBazooka, 0)
		end
		BazookasLeft = 2

	end }

-- The Underwater Attack Target
local UnderwaterAttackTarget = 10
TargetPos[10] = {
	MessageTime = 17000,
	Message = loc("Now for the supreme discipline of saucer flying, the underwater attack.") .. "|" ..
	loc("Basically this is a combination of diving and launching.") .. "|" ..
	loc("Dropping a weapon while in water would just drown it, but launching one would work.") .."|" ..
	loc("Based on what you've learned, destroy the target on the girder and as always, land safely!"), 
	Targets = {{ X = 1200, Y = 930, Type = gtTarget }},
	Ammo = { [amJetpack] = 1, },
	Respawn = { X = 1027, Y = 217 },
	ExtraFunc = function()
		if SaucerGear ~= nil then
			AddAmmo(Player, amBazooka, 1)
		else
			AddAmmo(Player, amBazooka, 0)
		end
		BazookasLeft = 1
	end }
TargetPos[11] = {
	Targets = {{ X = 742, Y = 290 }},
	MessageTime = 5000,
	Message = loc("This almost concludes our tutorial.") .. "|" ..
	loc("You now have infinite fuel, grenades and bazookas for fun.") .. "|" ..
	loc("Collect or destroy the final crate to finish the training."),
	Ammo = { [amJetpack] = 100, [amGrenade] = 100, [amBazooka] = 100 },
	InfFuel = true, }
TargetPos[12] = { Modifier = true, Func = function()
	Objective = true
	AddCaption(loc("Training complete!"), 0xFFFFFFFF, capgrpGameState)
	Info(loc("Training complete!"), loc("Good bye!"), 4, 5000)

	if SaucerGear ~= nil then
		DeleteGear(SaucerGear)
	end
	SetState(Player, band(GetState(Player), bnot(gstHHDriven)))
	SetState(Player, bor(GetState(Player), gstWinner))
	PlaySound(sndVictory, Player)

	SendStat(siGameResult, loc("You have finished the Flying Saucer Training!"))
	SendStat(siCustomAchievement, loc("Good job!"))
	SendStat(siPlayerKills, "0", loc("Hogonauts"))

	TurnTimeLeft = 0
	EndGame()
end,
}

-- Just a wrapper for ShowMission
function Info(Title, Text, Icon, Time)
	if Time == nil then Time = 0 end
	if Icon == nil then Icon = 2 end
	ShowMission(loc("Flying Saucer Training"), Title, Text, Icon, Time)
end

-- Spawn all the gears for the Boom Target
function SpawnBoomTarget()
	if TargetsRemaining < 1 then
		TargetGears[1] = AddGear(1602, 507, gtTarget, 0, 0, 0, 0)
		TargetsRemaining = TargetsRemaining + 1
	end

	if Barrels[1] == nil then
		Barrels[1] = AddGear(1563, 532, gtExplosives, 0, 0, 0, 0)
	end
	if Barrels[2] == nil then
		Barrels[2] = AddGear(1648, 463, gtExplosives, 0, 0, 0, 0)
	end

	for i=1,#Barrels do
		SetHealth(Barrels[i], 1)
	end
end

-- Generic target spawning for the current target
function SpawnTargets()
	for i=1,#TargetPos[TargetNumber].Targets do
		if TargetGears[i] == nil then
			SpawnTarget(TargetPos[TargetNumber].Targets[i].X, TargetPos[TargetNumber].Targets[i].Y,
				TargetPos[TargetNumber].Targets[i].Type, i)
		end
	end
end

function SpawnTarget( PosX, PosY, Type, ID )
	if Type ~= nil and Type ~= gtCase then
		if Type == gtTarget then
			TargetGears[ID] = AddGear(PosX, PosY, gtTarget, 0, 0, 0, 0)
		end
	else
		TargetGears[ID] = SpawnFakeUtilityCrate(PosX, PosY, false, false)
	end
	TargetsRemaining = TargetsRemaining + 1
end

function AutoSpawn() -- Auto-spawn the next target after you've obtained the current target!
	TargetNumber = TargetNumber + 1
	TargetsRemaining = 0

	if TargetPos[TargetNumber].Ammo then
		for ammoType, count in pairs(TargetPos[TargetNumber].Ammo) do
			AddAmmo(Player, ammoType, count)
		end
		if GetCurAmmoType() ~= amJetpack then
			SetWeapon(amJetpack)
		end
	end
	if TargetPos[TargetNumber].InfFuel then
		InfFuel = true
	else
		InfFuel = false
	end

	-- Func (if present) will be run instead of the ordinary spawning handling
	if TargetPos[TargetNumber].Modifier then -- If there is a modifier, run the function
		TargetPos[TargetNumber].Func()
		return true
	end

	-- ExtraFunc is for additional events for a target
	if TargetPos[TargetNumber].ExtraFunc ~= nil then
		TargetPos[TargetNumber].ExtraFunc()
	end

	local subcap
	if TargetNumber == 1 then
		subcap = loc("Training")
	else
		subcap = loc("Instructions")
	end
	Info(subcap, TargetPos[TargetNumber].Message, TargetPos[TargetNumber].MessageIcon, TargetPos[TargetNumber].MessageTime)

	-- Spawn targets on the next position
	SpawnTargets()

	if TargetNumber > 1 then
		AddCaption(loc("Next target is ready!"), 0xFFFFFFFF, capgrpMessage2)
	end
end

-- Returns true if the hedgehog has safely "landed" (alive, no flying saucer gear and not moving)
-- This is to ensure the training only continues when the player didn't screw up and to restart the current target
function HasHedgehogLandedYet()
	if band(GetState(Player), gstMoving) == 0 and SaucerGear == nil and GetHealth(Player) > 0 then
		return true
	else
		return false
	end
end

-- Clean up the gear mess left behind when the player failed to get a clean state after restarting
function CleanUpGears()
	-- (We track flames, grenades, bazooka shells)
	runOnGears(DeleteGear)
end

-- Completely restarts the current target/objective; the hedgehog is spawned at the last "checkpoint"
-- Called when hedgeghog is resurrected or skips turn
function ResetCurrentTarget()
	GrenadeThrown = false
	GrenadeTimer = 0
	if TargetNumber == LaunchTarget then
		BazookasLeft = 2
	elseif TargetNumber == UnderwaterAttackTarget then
		BazookasLeft = 1
	else
		BazookasLeft = 0
	end
	Check = false

	CleanUpGears()

	local X, Y
	if TargetNumber == 1 then
		X, Y = StartPos.X, StartPos.Y
	else
		if TargetPos[TargetNumber-1].Modifier or TargetPos[TargetNumber-1].Respawn ~= nil then
			X, Y = TargetPos[TargetNumber-1].Respawn.X, TargetPos[TargetNumber-1].Respawn.Y
		else
			X, Y = TargetPos[TargetNumber-1].Targets[1].X, TargetPos[TargetNumber-1].Targets[1].Y
		end
	end
	if TargetNumber == BoomTarget then
		SpawnBoomTarget()
	end
	if TargetPos[TargetNumber].Modifier ~= true then
		SpawnTargets()
	end
	if TargetPos[TargetNumber].Ammo then
		for ammoType, count in pairs(TargetPos[TargetNumber].Ammo) do
			AddAmmo(Player, ammoType, count)
		end
		if GetCurAmmoType() ~= amJetpack then
			SetWeapon(amJetpack)
		end
	end
	if TargetPos[TargetNumber].InfFuel then
		InfFuel = true
	else
		InfFuel = false
	end

	SetGearPosition(Player, X, Y)
end

function onGameInit()
	Seed = 1
	GameFlags = gfInfAttack + gfOneClanMode + gfSolidLand + gfDisableWind
	TurnTime = 2000000 --[[ This rffectively hides the turn time; a turn time above 1000s is not displayed.
				We will also ensure this timer always stays above 999s later ]]
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0
	Map = "Eyes"
	Theme = "EarthRise"
	SuddenDeathTurns = 50
	WaterRise = 0
	HealthDecrease = 0

	-- Team name is a pun on “hedgehog” and “astronauts”
	AddTeam( loc( "Hogonauts" ), -9, "earth", "Earth", "Default", "cm_galaxy" )

	-- Hedgehog name is a pun on “Neil Armstrong”
	Player = AddHog( loc( "Neil Hogstrong" ), 0, 1, "NoHat" )
	SetGearPosition( Player, StartPos.X, StartPos.Y)
	SetEffect( Player, heResurrectable, 1 )
end

function onGameStart()
	SendHealthStatsOff()

	-- Girder near first crate
	PlaceGirder(1257, 204, 6)

	-- The upper girders
	PlaceGirder(84, 16, 0)
	PlaceGirder(1980, 16, 0)

	-- The lower girder platform at the water pit
	PlaceGirder(509, 896, 4)
	PlaceGirder(668, 896, 4)
	PlaceGirder(421, 896, 2)
	PlaceGirder(758, 896, 2)

	-- Girders for the Launch Target and the Underwater Attack Target
	PlaceGirder(1191, 960, 4)
	PlaceGirder(1311, 960, 0)
	PlaceGirder(1460, 827, 3)
	PlaceGirder(1509, 763, 2)
	PlaceGirder(1605, 672, 4)
	PlaceGirder(1764, 672, 4)
	PlaceGirder(1803, 577, 6)

	-- Spawn our 1st target using the wrapper function
	AutoSpawn()
end

function onAmmoStoreInit()
	SetAmmo(amJetpack, 0, 0, 0, 0)
	SetAmmo(amGrenade, 0, 0, 0, 0)
	SetAmmo(amBazooka, 0, 0, 0, 0)

	-- Added for resetting current target/objective when player is stuck somehow
	SetAmmo(amSkip, 9, 0, 0, 0)
end

function onGearAdd(Gear)
	if GetGearType(Gear) == gtJetpack then
		SaucerGear = Gear
		if TargetNumber == BoomTarget and GrenadeThrown == false then
			AddAmmo(Player, amGrenade, 1)
		end
		if (TargetNumber == LaunchTarget or TargetNumber == UnderwaterAttackTarget) and BazookasLeft > 0 then
			AddAmmo(Player, amBazooka, BazookasLeft)
		end
		-- If player starts using saucer, the player probably finished reading and the mission panel
		-- would just get in the way. So we hide it!
		HideMission()
	end
	if GetGearType(Gear) == gtGrenade then
		GrenadeThrown = true
		GrenadeTimer = 0
	end
	if GetGearType(Gear) == gtShell then
		BazookasLeft = BazookasLeft - 1
	end
	if GetGearType(Gear) == gtFlame or GetGearType(Gear) == gtGrenade or GetGearType(Gear) == gtShell then
		trackGear(Gear)
	end
end

function onGearDelete(Gear)
	if GetGearType(Player) ~= nil and (GetGearType(Gear) == gtTarget or GetGearType(Gear) == gtCase) then
		for i=1, #TargetGears do
			if Gear == TargetGears[i] then
				TargetGears[i] = nil
				TargetsRemaining = TargetsRemaining - 1
			end
		end
		if TargetsRemaining <= 0 then
			if TargetNumber == BoomTarget or not HasHedgehogLandedYet() then
				if SaucerGear then
					AddCaption(loc("Objective completed! Now land safely."), 0xFFFFFFFF, capgrpMessage2)
				end
				Check = true
				CheckTimer = 500
			else
				AutoSpawn()
			end
		end
	end
	if GetGearType(Gear) == gtGrenade then
		GrenadeTimer = 0
		GrenadeExploded = true
	end
	if GetGearType(Gear) == gtJetpack then
		SaucerGear = nil
		if TargetNumber == BoomTarget then
			AddAmmo(Player, amGrenade, 0)
		end
		if TargetNumber == LaunchTarget or TargetNumber == UnderwaterAttackTarget then
			AddAmmo(Player, amBazooka, 0)
		end
	end
	if GetGearType(Gear) == gtCase and GetGearType(Player) ~= nil then
		PlaySound(sndShotgunReload)
	end
	if Gear == Barrels[1] then
		Barrels[1] = nil
	end
	if Gear == Barrels[2] then
		Barrels[2] = nil
		AddCaption(loc("Kaboom!"), 0xFFFFFFFF, capgrpMessage)
	end
end



function onNewTurn()
	if GetAmmoCount(CurrentHedgehog, amJetpack) > 0 then
		SetWeapon(amJetpack)
	end
end

function onGameTick20()
	if (TurnTimeLeft < 1500000 and not Objective) then
		TurnTimeLeft = TurnTime
	end
	if Check then
		CheckTimer = CheckTimer - 20
		if CheckTimer <= 0 then
			if HasHedgehogLandedYet() then
				AutoSpawn()
				Check = false
				GrenadeThrown = false
			end
		end
	end
	if GrenadeExploded and TargetNumber == BoomTarget then
		GrenadeTimer = GrenadeTimer + 20
		if GrenadeTimer > 1500 then
			GrenadeTimer = 0
			GrenadeThrown = false
			GrenadeExploded = false
			if SaucerGear and TargetNumber == BoomTarget and TargetsRemaining > 0 then
				PlaySound(sndShotgunReload)
				AddCaption(loc("+1 Grenade"), 0xDDDD00FF, capgrpAmmoinfo)
				AddAmmo(Player, amGrenade, 1)
			end
		end
	end
	ResetFuel()
end

-- Used to ensure infinite fuel
function ResetFuel()
	if SaucerGear and InfFuel then
		SetHealth(SaucerGear, 2000)
	end
end

onUp = ResetFuel
onLeft = ResetFuel
onRight = ResetFuel

function onGearDamage(Gear)
	if Gear == Player then
		CleanUpGears()
		GrenadeThrown = false
		Check = false
	end
end

function onGearResurrect(Gear)
	if Gear == Player then
		AddCaption(loc("Oh no! You have died. Try again!"), 0xFFFFFFFF, capgrpMessage2)
		ResetCurrentTarget()
	end
end

function onSkipTurn()
	AddCaption(loc("Try again!"), 0xFFFFFFFF, capgrpMessage2)
	ResetCurrentTarget()
end

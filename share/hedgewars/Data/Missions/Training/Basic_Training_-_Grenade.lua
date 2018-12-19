--[[
	Basic Grenade Training

	This training mission teaches players how to use the grenade.
	Lesson plan:
	- Selecting grenade
	- Aiming and shooting
	- Timer
	- No wind
	- Bounciness
]]

HedgewarsScriptLoad("/Scripts/Locale.lua")

local hog			-- Hog gear
local weaponSelected = false	-- Player has selected the weapon
local gamePhase = 0		-- Used to track progress
local targetsLeft = 0		-- # of targets left in this round
local targetGears = {}		-- list of target gears
local gameOver = false		-- If true, game has ended
local shotsFired = 0		-- Total # of grenades fired
local maxTargets = 0		-- Target counter, used together with flawless
local flawless = true		-- track flawless victory (100% accuracy, no hurt, no death)
local missedTauntTimer = -1	-- Wait timer for playing sndMissed. -1 = no-op

function onGameInit()

	ClearGameFlags()
	EnableGameFlags(gfDisableWind, gfOneClanMode, gfInfAttack, gfSolidLand, gfArtillery)
	Map = "Mushrooms"
	Seed = 0
	Theme = "Nature"
	TurnTime = MAX_TURN_TIME
	Explosives = 0
	MinesNum = 0
	CaseFreq = 0
	WaterRise = 0
	HealthDecrease = 0

	------ TEAM LIST ------

	AddMissionTeam(-1)
	hog = AddMissionHog(1)
	SetGearPosition(hog, 570, 157)
	SetEffect(hog, heResurrectable, 1)

	SendHealthStatsOff()
end

function onGearResurrect(gear, vGear)
	if gear == hog then
		flawless = false
		SetGearPosition(hog, 570, 157)
		if vGear then
			SetVisualGearValues(vGear, GetX(hog), GetY(hog))
		end
		AddCaption(loc("Your hedgehog has been revived!"))
	end
end

local function placeGirders()
	PlaceGirder(918, 248, 1)
	PlaceGirder(888, 129, 6)
	PlaceGirder(844, 35, 1)
	PlaceGirder(932, 37, 3)
	PlaceGirder(926, 148, 6)
	PlaceGirder(73, 812, 5)
	PlaceGirder(189, 930, 5)
	PlaceGirder(15, 669, 6)
	PlaceGirder(15, 507, 6)
	PlaceGirder(15, 344, 6)
	PlaceGirder(62, 27, 0)
	PlaceGirder(229, 115, 0)
	PlaceGirder(1195, 250, 7)
	PlaceGirder(1285, 205, 1)
	PlaceGirder(1358, 201, 3)
	PlaceGirder(1756, 415, 6)
	PlaceGirder(1893, 95, 6)
	PlaceGirder(1005, 333, 5)
	PlaceGirder(1860, 187, 0)
end

local function spawnTargets()
	-- Warm-up
	if gamePhase == 0 then
		AddGear(882, 39, gtTarget, 0, 0, 0, 0)
	-- Timer
	elseif gamePhase == 2 then
		AddGear(233, 97, gtTarget, 0, 0, 0, 0)
		AddGear(333, 255, gtTarget, 0, 0, 0, 0)
		AddGear(753, 225, gtTarget, 0, 0, 0, 0)
	-- No Wind
	elseif gamePhase == 3 then
		AddGear(15, 240, gtTarget, 0, 0, 0, 0)
		AddGear(61, 9, gtTarget, 0, 0, 0, 0)
		AddGear(945, 498, gtTarget, 0, 0, 0, 0)
	-- Bounciness
	elseif gamePhase == 4 then
		AddGear(1318, 208, gtTarget, 0, 0, 0, 0)
		AddGear(1697, 250, gtTarget, 0, 0, 0, 0)
		if INTERFACE ~= "touch" then
			-- These targets may be too hard in touch interface because you cannot set bounciness yet
			-- FIXME: Allow these targets in touch when bounciness can be set
			AddGear(323, 960, gtTarget, 0, 0, 0, 0)
			AddGear(1852, 100, gtTarget, 0, 0, 0, 0)
		end
	-- Grand Final
	elseif gamePhase == 5 then
		AddGear(186, 473, gtTarget, 0, 0, 0, 0)
		AddGear(950, 250, gtTarget, 0, 0, 0, 0)
		AddGear(1102, 345, gtTarget, 0, 0, 0, 0)
		AddGear(1556, 297, gtTarget, 0, 0, 0, 0)
	end
end

function onGameStart()
	placeGirders()
	spawnTargets()
	ShowMission(loc("Basic Grenade Training"), loc("Basic Training"), loc("Destroy all the targets!"), -amGrenade, 0)
end

function newGamePhase()
	-- Spawn targets, update wind and ammo, show instructions
	local ctrl = ""
	if gamePhase == 0 then
		if INTERFACE == "desktop" then
			ctrl = loc("Open ammo menu: [Right click]").."|"..
			loc("Select weapon: [Left click]")
		else
			ctrl = loc("Open ammo menu: Tap the [Suitcase]")
		end
		ShowMission(loc("Basic Grenade Training"), loc("Select Weapon"), loc("To begin with the training, select the grenade from the ammo menu!").."|"..
		ctrl, 2, 5000)
	elseif gamePhase == 1 then
		if INTERFACE == "desktop" then
			ctrl = loc("Attack: [Space]").."|"..
			loc("Aim: [Up]/[Down]").."|"..
			loc("Change direction: [Left]/[Right]")
		elseif INTERFACE == "touch" then
			ctrl = loc("Attack: Tap the [Bomb]").."|"..
			loc("Aim: [Up]/[Down]").."|"..
			loc("Change direction: [Left]/[Right]")
		end
		ShowMission(loc("Basic Grenade Training"), loc("Warming Up"),
		loc("Throw a grenade to destroy the target!").."|"..
		loc("Hold the Attack key pressed for more power.").."|"..
		ctrl.."|"..
		loc("Note: Walking is disabled in this mission."), 2, 20000)
		spawnTargets()
	elseif gamePhase == 2 then
		if INTERFACE == "desktop" then
			ctrl = loc("Set detonation timer: [1]-[5]")
		elseif INTERFACE == "touch" then
			ctrl = loc("Change detonation timer: Tap the [Clock]")
		end
		ShowMission(loc("Basic Grenade Training"), loc("Timer"),
		loc("You can change the detonation timer of grenades.").."|"..
		loc("Grenades explode after 1 to 5 seconds (you decide).").."|"..
		ctrl, 2, 15000)
		spawnTargets()
	elseif gamePhase == 3 then
		ShowMission(loc("Basic Grenade Training"), loc("No Wind Influence"), loc("Unlike bazookas, grenades are not influenced by wind.").."|"..
		loc("Destroy the targets!"), 2, 6000)
		SetWind(50)
		spawnTargets()
	elseif gamePhase == 4 then
		local caption = loc("Bounciness")
		if INTERFACE == "desktop" then
			ctrl = loc("You can set the bounciness of grenades (and grenade-like weapons).").."|"..
			loc("Grenades with high bounciness bounce a lot and behave chaotic.").."|"..
			loc("With low bounciness, it barely bounces at all, but it is much more predictable.").."|"..
			loc("Try out different bounciness levels to reach difficult targets.").."|"..
			loc("Set bounciness: [Left Shift] + [1]-[5]")
		elseif INTERFACE == "touch" then
			-- FIXME: Bounciness can't be set in touch yet. :(
			caption = loc("Well done.")
			ctrl = loc("You're doing well! Here are more targets for you.")
		end

		ShowMission(loc("Basic Grenade Training"), caption, ctrl, 2, 20000)
		spawnTargets()
	elseif gamePhase == 5 then
		if INTERFACE == "desktop" then
			ctrl = loc("Precise Aim: [Left Shift] + [Up]/[Down]")
			-- FIXME: No precise aim in touch interface yet :(
		end
		ShowMission(loc("Basic Grenade Training"), loc("Final Targets"), loc("Good job! Now destroy the final targets to finish the training.").."|"..
		ctrl,
		2, 7000)
		spawnTargets()
	elseif gamePhase == 6 then
		SaveMissionVar("Won", "true")
		ShowMission(loc("Basic Grenade Training"), loc("Training complete!"), loc("Congratulations!"), 0, 0)
		SetInputMask(0)
		AddAmmo(CurrentHedgehog, amGrenade, 0)
		if shotsFired > maxTargets then
			flawless = false
		end
		if flawless then
			PlaySound(sndFlawless, hog)
		else
			PlaySound(sndVictory, hog)
		end
		SendStat(siCustomAchievement, loc("Good job!"))
		SendStat(siGameResult, loc("You have completed the Basic Grenade Training!"))
		SendStat(siPlayerKills, "0", GetHogTeamName(hog))
		EndGame()
		gameOver = true
	end
	gamePhase = gamePhase + 1
end

function onNewTurn()
	if gamePhase == 0 then
		newGamePhase()
	end
end

function onGameTick20()
	if not weaponSelected and gamePhase == 1 and GetCurAmmoType() == amGrenade then
		newGamePhase()
		weaponSelected = true
	end
end

function onHogAttack(ammoType)
	if ammoType == amGrenade then
		HideMission()
	end
end

function onAttack()
	if GetCurAmmoType() == amGrenade then
		HideMission()
	end
end

function onGearAdd(gear)
	if GetGearType(gear) == gtTarget then
		targetsLeft = targetsLeft + 1
		maxTargets = maxTargets + 1
		targetGears[gear] = true
	elseif GetGearType(gear) == gtGrenade then
		shotsFired = shotsFired + 1
	end
end

function onGearDelete(gear)
	if GetGearType(gear) == gtTarget then
		targetsLeft = targetsLeft - 1
		targetGears[gear] = nil
		if targetsLeft <= 0 then
			newGamePhase()
		end
	end
end

function onGearDamage(gear)
	if gear == hog then
		flawless = false
	end
end

function onAmmoStoreInit()
	SetAmmo(amGrenade, 9, 0, 0, 0)
end

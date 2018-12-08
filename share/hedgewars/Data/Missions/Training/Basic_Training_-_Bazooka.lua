--[[
	Basic Bazooka Training

	This training missions teaches players how to use the bazooka.
	Lesson plan:
	- Selecting bazooka
	- Aiming and shooting
	- Wind
	- Limited ammo
	- “Bouncing bomb” / water skip
	- Precise aiming
]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Achievements.lua")

local hog			-- Hog gear
local weaponSelected = false	-- Player has selected the weapon
local gamePhase = 0		-- Used to track progress
local targetsLeft = 0		-- # of targets left in this round
local targetGears = {}		-- list of target gears
local bazookasInGame = 0	-- # of bazookas currently flying
local bazookaGears = {}		-- list of bazooka gears
local limitedAmmo = 10		-- amount of ammo for the limited ammo challenge
local limitedAmmoReset = -1	-- Timer for resetting ammo if player fails in
				-- limited ammo challenge. -1 = no-op
local gameOver = false		-- If true, game has ended
local shotsFired = 0		-- Total # of bazookas fired
local maxTargets = 0		-- Target counter, used together with flawless
local flawless = true		-- track flawless victory (100% accuracy, no hurt, no death)
local missedTauntTimer = -1	-- Wait timer for playing sndMissed. -1 = no-op

function onGameInit()

	ClearGameFlags()
	EnableGameFlags(gfDisableWind, gfOneClanMode, gfInfAttack, gfSolidLand)
	Map = ""
	Seed = 0
	Theme = "Nature"
	MapGen = mgDrawn
	TurnTime = MAX_TURN_TIME
	Explosives = 0
	MinesNum = 0
	CaseFreq = 0
	WaterRise = 0
	HealthDecrease = 0

	------ TEAM LIST ------

	AddTeam(loc("Bazooka Team"), -1, "Flower", "Earth", "Default", "hedgewars")
	hog = AddHog(loc("Greenhorn"), 0, 100, "NoHat")
	SetGearPosition(hog, 1485, 2001)
	SetEffect(hog, heResurrectable, 1)

	SendHealthStatsOff()
end

function onGearResurrect(gear, vGear)
	if gear == hog then
		flawless = false
		SetGearPosition(hog, 1485, 2001)
		if vGear then
			SetVisualGearValues(vGear, GetX(hog), GetY(hog))
		end
		AddCaption(loc("Your hedgehog has been revived!"))
	end
end

function placeGirders()
	PlaceGirder(1520, 2018, 4)
	PlaceGirder(1449, 1927, 6)
	PlaceGirder(1341, 1989, 0)
	PlaceGirder(1141, 1990, 0)
	PlaceGirder(2031, 1907, 6)
	PlaceGirder(2031, 1745, 6)
	PlaceGirder(2398, 1985, 4)
	PlaceGirder(2542, 1921, 7)
	PlaceGirder(2617, 1954, 6)
	PlaceGirder(2565, 2028, 0)
	PlaceGirder(2082, 1979, 0)
	PlaceGirder(2082, 1673, 0)
	PlaceGirder(1980, 1836, 0)
	PlaceGirder(1716, 1674, 0)
	PlaceGirder(1812, 1832, 0)
	PlaceGirder(1665, 1744, 6)
	PlaceGirder(2326, 1895, 6)
	PlaceGirder(2326, 1734, 6)
	PlaceGirder(2326, 1572, 6)
	PlaceGirder(2275, 1582, 0)
	PlaceGirder(1738, 1714, 7)
	PlaceGirder(1818, 1703, 0)
	PlaceGirder(1939, 1703, 4)
	PlaceGirder(2805, 1781, 3)
	PlaceGirder(2905, 1621, 3)
	PlaceGirder(3005, 1441, 3)
	PlaceGirder(945, 1340, 5)
end

function spawnTargets(phase)
	if not phase then
		phase = gamePhase
	end
	if phase == 0 then
		AddGear(1734, 1656, gtTarget, 0, 0, 0, 0)
		AddGear(1812, 1814, gtTarget, 0, 0, 0, 0)
		AddGear(1974, 1818, gtTarget, 0, 0, 0, 0)
	elseif phase == 2 then
		AddGear(2102, 1655, gtTarget, 0, 0, 0, 0)
		AddGear(2278, 1564, gtTarget, 0, 0, 0, 0)
		AddGear(2080, 1961, gtTarget, 0, 0, 0, 0)
	elseif phase == 3 then
		AddGear(1141, 1972, gtTarget, 0, 0, 0, 0)
		AddGear(1345, 1971, gtTarget, 0, 0, 0, 0)
		AddGear(1892, 1680, gtTarget, 0, 0, 0, 0)
	elseif phase == 4 then
		AddGear(2584, 2010, gtTarget, 0, 0, 0, 0)
	elseif phase == 5 then
		AddGear(955, 1320, gtTarget, 0, 0, 0, 0)
	elseif phase == 6 then
		AddGear(2794, 1759, gtTarget, 0, 0, 0, 0)
		AddGear(2894, 1599, gtTarget, 0, 0, 0, 0)
		AddGear(2994, 1419, gtTarget, 0, 0, 0, 0)
	end
end

function onGameStart()
	placeGirders()
	spawnTargets()
	ShowMission(loc("Basic Bazooka Training"), loc("Basic Training"), loc("Destroy all the targets!"), -amBazooka, 0)
end

function newGamePhase()
	local ctrl = ""
	-- Spawn targets, update wind and ammo, show instructions
	if gamePhase == 0 then
		if INTERFACE == "desktop" then
			ctrl = loc("Open ammo menu: [Right click]").."|"..
			loc("Select weapon: [Left click]")
		elseif INTERFACE == "touch" then
			ctrl = loc("Open ammo menu: Tap the [Suitcase]")
		end
		ShowMission(loc("Basic Bazooka Training"), loc("Select Weapon"), loc("To begin with the training, select the bazooka from the ammo menu!").."|"..
		ctrl, 2, 5000)
	elseif gamePhase == 1 then
		if INTERFACE == "desktop" then
			ctrl = loc("Attack: [Space]").."|"..
			loc("Aim: [Up]/[Down]").."|"..
			loc("Walk: [Left]/[Right]")
		elseif INTERFACE == "touch" then
			ctrl = loc("Attack: Tap the [Bomb]").."|"..
			loc("Aim: [Up]/[Down]").."|"..
			loc("Walk: [Left]/[Right]")
		end
		ShowMission(loc("Basic Bazooka Training"), loc("My First Bazooka"),
		loc("Let's get started!").."|"..
		loc("Launch some bazookas to destroy the targets!").."|"..
		loc("Hold the Attack key pressed for more power.").."|"..
		loc("Don't hit yourself!").."|"..
		ctrl, 2, 10000)
		spawnTargets()
	elseif gamePhase == 2 then
		if INTERFACE == "desktop" then
			ctrl = loc("You see the wind strength at the bottom right corner.")
		elseif INTERFACE == "touch" then
			ctrl = loc("You see the wind strength at the top.")
		end
		ShowMission(loc("Basic Bazooka Training"), loc("Wind"), loc("Bazookas are influenced by wind.").."|"..
		ctrl.."|"..
		loc("Destroy the targets!"), 2, 5000)
		SetWind(50)
		spawnTargets()
	elseif gamePhase == 3 then
		-- Vaporize any bazookas still in the air
		for gear, _ in pairs(bazookaGears) do
			AddVisualGear(GetX(gear), GetY(gear), vgtSteam, 0, false)
			DeleteGear(gear)
			PlaySound(sndVaporize)
		end
		ShowMission(loc("Basic Bazooka Training"), loc("Limited Ammo"), loc("Your ammo is limited this time.").."|"..
		loc("Destroy all targets with no more than 10 bazookas."),
		2, 8000)
		SetWind(-20)
		AddAmmo(hog, amBazooka, limitedAmmo)
		spawnTargets()
	elseif gamePhase == 4 then
		ShowMission(loc("Basic Bazooka Training"), loc("Bouncing Bomb"), loc("The next target can only be reached by something called “bouncing bomb”.").."|"..
		loc("Hint: Launch the bazooka horizontally at full power."),
		2, 8000)
		SetWind(90)
		spawnTargets()
		AddAmmo(hog, amBazooka, 100)
		if GetCurAmmoType() ~= amBazooka then
			SetWeapon(amBazooka)
		end
	elseif gamePhase == 5 then
		ShowMission(loc("Basic Bazooka Training"), loc("High Target"),
		loc("By the way, not only bazookas will bounce on water, but also grenades and many other things.").."|"..
		loc("The next target is high in the sky."),
		2, 8000)
		SetWind(-33)
		spawnTargets()
	elseif gamePhase == 6 then
		if INTERFACE == "desktop" then
			ctrl = loc("Precise Aim: [Left Shift] + [Up]/[Down]").."|"
		end
		ShowMission(loc("Basic Bazooka Training"), loc("Final Targets"),
		loc("The final targets are quite tricky. You need to aim well.").."|"..
		ctrl..
		loc("Hint: It might be easier if you vary the angle only slightly."),
		2, 12000)
		SetWind(75)
		spawnTargets()
	elseif gamePhase == 7 then
		ShowMission(loc("Basic Bazooka Training"), loc("Training complete!"), loc("Congratulations!"), 0, 0)
		SetInputMask(0)
		AddAmmo(CurrentHedgehog, amBazooka, 0)
		if shotsFired > maxTargets then
			flawless = false
		else
			-- For 100% accuracy
			awardAchievement(loc("Bazooka Master"))
		end
		if flawless then
			PlaySound(sndFlawless, hog)
		else
			PlaySound(sndVictory, hog)
		end
		SendStat(siCustomAchievement, loc("Good job!"))
		SendStat(siGameResult, loc("You have completed the Basic Bazooka Training!"))
		SendStat(siPlayerKills, "0", loc("Bazooka Team"))
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

function onHogAttack(ammoType)
	if ammoType == amBazooka then
		HideMission()
	end
end

function onAttack()
	if GetCurAmmoType() == amBazooka then
		HideMission()
	end
end

function onGearAdd(gear)
	if GetGearType(gear) == gtTarget then
		targetsLeft = targetsLeft + 1
		maxTargets = maxTargets + 1
		targetGears[gear] = true
	elseif GetGearType(gear) == gtShell then
		bazookasInGame = bazookasInGame + 1
		bazookaGears[gear] = true
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
	elseif GetGearType(gear) == gtShell then
		bazookasInGame = bazookasInGame - 1
		bazookaGears[gear] = nil
		if bazookasInGame == 0 and GetAmmoCount(hog, amBazooka) == 0 then
			limitedAmmoReset = 20
			flawless = false
		end
	end
end

function onGearDamage(gear)
	if gear == hog then
		flawless = false
	end
end

function onGameTick20()
	-- Reset targets and ammo if ammo depleted
	if limitedAmmoReset > 0 then
		limitedAmmoReset = limitedAmmoReset - 20
	end
	if limitedAmmoReset == 0 then
		if not gameOver and bazookasInGame == 0 and GetAmmoCount(hog, amBazooka) == 0 then
			for gear, _ in pairs(targetGears) do
				DeleteGear(gear)
			end
			spawnTargets(3)
			AddCaption(loc("Out of ammo! Try again!"))
			AddAmmo(hog, amBazooka, limitedAmmo)
			SetWeapon(amBazooka)
			missedTauntTimer = 1000
		end
		limitedAmmoReset = -1
	end
	if missedTauntTimer > 0 then
		missedTauntTimer = missedTauntTimer - 20
	end
	if missedTauntTimer == 0 then
		PlaySound(sndMissed, hog)
		missedTauntTimer = -1
	end

	if not weaponSelected and gamePhase == 1 and GetCurAmmoType() == amBazooka then
		newGamePhase()
		weaponSelected = true
	end
end

function onAmmoStoreInit()
	SetAmmo(amBazooka, 9, 0, 0, 0)
end

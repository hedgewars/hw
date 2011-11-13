--------------------------------
-- HIGHLANDER / HOGS OF WAR
-- version 0.3
-- by mikade
--------------------------------

-----------
--0.1
-----------

-- concept test

-----------
--0.2
-----------

-- remove tardis till Henek fixes his tracker
-- change wep crates to health crates
-- reset arb turntimevalue
-- include randomOrder
-- Until fixed .17 methods come out, remove switches and resurrector
-- on request, removed kamikaze and piano weapons
-- provisional fixing of bugs that can't actually be fixed yet

-----------
--0.3
-----------

-- meh, update incorrect display
-- may change this in the future to have switches
-- but for now people are used to it without, so~

-- mudball is now counted as a utility

----------------
-- other ideas
----------------

-- circles to mark hogs with more than 4 weapons
-- health crate and switch drops
-- hogs start with 1 weap and 1 utility each (some are rarer than others?)
-- could always create a "donor card" mini circle instead of automatic disposal


loadfile(GetDataPath() .. "Scripts/Locale.lua")()
loadfile(GetDataPath() .. "Scripts/Tracker.lua")()

local wepArray = {}
local wepArrayCount = 0

local atkArray = {}
local atkCount = 0

local utilArray = {}
local utilArrayCount = 0

local currName
local lastName
local started = false
local switchStage = 0

function StartingSetUp(gear)

	for i = 0, (wepArrayCount-1) do
		setGearValue(gear,wepArray[i],0)
	end

	i = GetRandom(atkArrayCount)
	setGearValue(gear,atkArray[i],1)

	i = GetRandom(utilArrayCount)
	setGearValue(gear,utilArray[i],1)

	SetHealth(gear, 100)

end

--[[function SaveWeapons(gear)

	-
	for i = 0, (wepArrayCount-1) do
		setGearValue(gear, wepArray[i], GetAmmoCount(gear, wepArray[i]) )
		 --AddAmmo(gear, wepArray[i], getGearValue(gear,wepArray[i]) )
	end

end]]

function ConvertValues(gear)

	for i = 0, (wepArrayCount-1) do
		AddAmmo(gear, wepArray[i], getGearValue(gear,wepArray[i]) )
	end


end


function TransferWeps(gear)

	if CurrentHedgehog ~= nil then

		for i = 0, (wepArrayCount-1) do
			val = getGearValue(gear,wepArray[i])
			if val ~= 0 then
				setGearValue(CurrentHedgehog, wepArray[i], val)
				AddAmmo(CurrentHedgehog, wepArray[i], val)
			end
		end

	end

end



function onGameInit()
	GameFlags = gfInfAttack + gfRandomOrder
	HealthCaseProb = 100
end

function onGameStart()


	ShowMission	(
				loc("HIGHLANDER"),
				loc("Not all hogs are born equal."),

				"- " .. loc("Eliminate enemy hogs and take their weapons.") .. "|" ..
				"- " .. loc("Per-Hog Ammo") .. "|" ..
				"- " .. loc("Weapons reset.") .. "|" ..
				"- " .. loc("Unlimited Attacks") .. "|" ..
				"", 4, 4000
				)

	atkArray[0] = amBazooka
	atkArray[1] = amBee
	atkArray[2] = amMortar
	atkArray[3] = amDrill
	--atkArray[4] = amSnowball

	atkArray[4] = amGrenade
	atkArray[5] = amClusterBomb
	atkArray[6] = amMolotov
	atkArray[7] = amWatermelon
	atkArray[8] = amHellishBomb
	atkArray[9] = amGasBomb

	atkArray[10] = amShotgun
	atkArray[11] = amDEagle
	atkArray[12] = amFlamethrower
	atkArray[13] = amSniperRifle
	atkArray[14] = amSineGun

	atkArray[15] = amFirePunch
	atkArray[16] = amWhip
	atkArray[17] = amBaseballBat
	--atkArray[19] = amKamikaze
	atkArray[18] = amBirdy
	atkArray[19] = amSeduction
	atkArray[20] = amHammer

	atkArray[21] = amMine
	atkArray[22] = amDynamite
	atkArray[23] = amCake
	atkArray[24] = amBallgun
	atkArray[25] = amRCPlane
	atkArray[26] = amSMine

	atkArray[27] = amAirAttack
	atkArray[28] = amMineStrike
	atkArray[29] = amDrillStrike
	atkArray[30] = amNapalm
	--atkArray[32] = amPiano
	atkArray[31] = amLandGun

	--atkArray[33] = amBirdy
	--atkArray[34] = amLandGun

	atkArrayCount = 32

	-------------------------------


	wepArray[0] = amBazooka
	wepArray[1] = amBee
	wepArray[2] = amMortar
	wepArray[3] = amDrill
	wepArray[4] = amSnowball

	wepArray[5] = amGrenade
	wepArray[6] = amClusterBomb
	wepArray[7] = amMolotov
	wepArray[8] = amWatermelon
	wepArray[9] = amHellishBomb
	wepArray[10] = amGasBomb

	wepArray[11] = amShotgun
	wepArray[12] = amDEagle
	wepArray[13] = amFlamethrower
	wepArray[14] = amSniperRifle
	wepArray[15] = amSineGun

	wepArray[16] = amFirePunch
	wepArray[17] = amWhip
	wepArray[18] = amBaseballBat
	--wepArray[19] = amKamikaze
	wepArray[19] = amExtraTime
	wepArray[20] = amSeduction
	wepArray[21] = amHammer

	wepArray[22] = amMine
	wepArray[23] = amDynamite
	wepArray[24] = amCake
	wepArray[25] = amBallgun
	wepArray[26] = amRCPlane
	wepArray[27] = amSMine

	wepArray[28] = amAirAttack
	wepArray[29] = amMineStrike
	wepArray[30] = amDrillStrike
	wepArray[31] = amNapalm
	--wepArray[32] = amPiano
	wepArray[32] = amExtraDamage

	wepArray[33] = amBirdy
	wepArray[34] = amLandGun

	wepArray[35] = amBlowTorch
	wepArray[36] = amPickHammer
	wepArray[37] = amGirder
	wepArray[38] = amPortalGun

	wepArray[39] = amRope
	wepArray[40] = amParachute
	wepArray[41] = amTeleport
	wepArray[42] = amJetpack

	wepArray[43] = amInvulnerable
	wepArray[44] = amLaserSight
	wepArray[45] = amVampiric
	----resurrector used to be here

	wepArray[46] = amLowGravity

	--wepArray[47] = amExtraDamage -- see 19
	--wepArray[48] = amExtraTime	-- see 32

	--wepArray[49] = amResurrector
	--wepArray[50] = amTardis

	wepArrayCount = 47

	----------------------------

	utilArray[0] = amBlowTorch
	utilArray[1] = amPickHammer
	utilArray[2] = amGirder
	utilArray[3] = amPortalGun

	utilArray[4] = amRope
	utilArray[5] = amParachute
	utilArray[6] = amTeleport
	utilArray[7] = amJetpack

	utilArray[8] = amInvulnerable
	utilArray[9] = amLaserSight
	utilArray[10] = amVampiric

	utilArray[11] = amLowGravity
	utilArray[12] = amExtraDamage
	utilArray[13] = amExtraTime

	utilArray[14] = amSnowball

	--utilArray[14] = amResurrector
	--utilArray[15] = amTardis

	utilArrayCount = 15

	runOnGears(StartingSetUp)
	runOnGears(ConvertValues)


end

function onNewTurn()
--
end


function onGameTick()

	if (CurrentHedgehog ~= nil) then

		currName = GetHogName(CurrentHedgehog)

		if (currName ~= lastName) then
			AddCaption(loc("Switched to ") .. currName .. "!")
			ConvertValues(CurrentHedgehog)
		end

		lastName = currName
	end

end

--[[function onHogHide(gear)
	-- waiting for Henek
end

function onHogRestore(gear)
	-- waiting for Henek
end]]

function onGearAdd(gear)

	--if GetGearType(gear) == gtSwitcher then
	--	SaveWeapons(CurrentHedgehog)
	--end

	if (GetGearType(gear) == gtHedgehog) then
		trackGear(gear)
	end

end

function onGearDelete(gear)

	if (GetGearType(gear) == gtHedgehog) then --or (GetGearType(gear) == gtResurrector) then
		TransferWeps(gear)
		trackDeletion(gear)
	end

end

function onAmmoStoreInit()
	SetAmmo(amSkip, 9, 0, 0, 0)
	--SetAmmo(amSwitch, 9, 0, 0, 0) -------1
end


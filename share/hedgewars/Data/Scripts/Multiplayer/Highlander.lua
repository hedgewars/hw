--------------------------------
-- HIGHLANDER / HOGS OF WAR
-- version 0.3c
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

-----------
--0.3b
-----------

-- cleaned up code and got rid of unneccessary vars
-- mudball is a weapon again
-- landgun is now a utility
-- extra time, vampirism utility removed
-- hammer wep removed
-- all hogs have kamikaze

-----------
--0.3c
-----------

-- restructured some code
-- added napalm (whoops) to list of possible weapons you can get
-- hogs no longer recieve airstrike-related weps on border maps

loadfile(GetDataPath() .. "Scripts/Locale.lua")()
loadfile(GetDataPath() .. "Scripts/Tracker.lua")()

local airWeapons = 	{amAirAttack, amMineStrike, amNapalm, amDrillStrike --[[,amPiano]]}

local atkArray = 	{
					amBazooka, amBee, amMortar, amDrill, --[[amSnowball,]]
					amGrenade, amClusterBomb, amMolotov, amWatermelon, amHellishBomb, amGasBomb,
					amShotgun, amDEagle, amFlamethrower, amSniperRifle, amSineGun,
					amFirePunch, amWhip, amBaseballBat, --[[amKamikaze,]] amSeduction, --[[amHammer,]]
					amMine, amDynamite, amCake, amBallgun, amRCPlane, amSMine,
					amRCPlane, amSMine,
					amBirdy
					}

local utilArray = 	{
					amBlowTorch, amPickHammer, amGirder, amPortalGun,
					amRope, amParachute, amTeleport, amJetpack,
					amInvulnerable, amLaserSight, --[[amVampiric,]]
					amLowGravity, amExtraDamage, --[[amExtraTime,]]
					amLandGun
					--[[,amTardis, amResurrector, amSwitch]]
					}

local wepArray = 	{}

local currName
local lastName
local started = false
local switchStage = 0

function StartingSetUp(gear)

	for i = 1, #wepArray do
		setGearValue(gear,wepArray[i],0)
	end

	setGearValue(gear,amKamikaze,1)

	i = 1 + GetRandom(#atkArray)
	setGearValue(gear,atkArray[i],1)

	i = 1 + GetRandom(#utilArray)
	setGearValue(gear,utilArray[i],1)

	SetHealth(gear, 100)

end

--[[function SaveWeapons(gear)

	-
	for i = 1, (#wepArray) do
		setGearValue(gear, wepArray[i], GetAmmoCount(gear, wepArray[i]) )
		 --AddAmmo(gear, wepArray[i], getGearValue(gear,wepArray[i]) )
	end

end]]

function ConvertValues(gear)

	for i = 1, #wepArray do
		AddAmmo(gear, wepArray[i], getGearValue(gear,wepArray[i]) )
	end


end


function TransferWeps(gear)

	if CurrentHedgehog ~= nil then

		for i = 1, #wepArray do
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

	if MapHasBorder() == false then
        for i, w in pairs(airWeapons) do
            table.insert(atkArray, w)
        end
    end

	for i, w in pairs(atkArray) do
        table.insert(wepArray, w)
	end

	for i, w in pairs(utilArray) do
        table.insert(wepArray, w)
	end

	runOnGears(StartingSetUp)
	runOnGears(ConvertValues)


end

--function onNewTurn()
--
--end


function onGameTick20()

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
	SetAmmo(amKamikaze, 9, 0, 0, 0)
	--SetAmmo(amSwitch, 9, 0, 0, 0) -------1
end


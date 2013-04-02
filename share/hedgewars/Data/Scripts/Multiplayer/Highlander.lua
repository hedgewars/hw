--------------------------------
-- HIGHLANDER / HOGS OF WAR
-- version 0.4
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

-----------
--0.4
-----------
-- fix same name/blank weapon transfer bug (issue 541)
-- show next hog ammo set in full (issue 312)
-- allow mid-kill multi-shot weapon transfers (issue 503)
-- allow users to configure hog health
-- remove 'switched to' message
-- remove some extraeneous code
-- add more whitespace
-- break everything

-------------------------
-- ideas for the future
-------------------------
-- add ice gun, structure
-- allow switcher, resurrector
-- add abuse
-- nerf teleport
-- allow more customization
-- poison hogs using the default team? :/
-- balance weapon distribution across entire team / all teams
-- add other inequalities/bonuses like... ???
-- some hogs start off with an extra 25 health?
-- some hogs start off poisoned?
-- some hogs start off with a rope and 2 drills but die after their turn?

-------------------------------
-- derp, script follows
-------------------------------

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

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

local currHog
local lastHog
local started = false
local switchStage = 0

local lastWep = amNothing
local shotsFired = 0

function CheckForWeaponSwap()
	if GetCurAmmoType() ~= lastWep then
		shotsFired = 0
	end
	lastWep = GetCurAmmoType()
end

function onSlot()
	CheckForWeaponSwap()
end

function onSetWeapon()
	CheckForWeaponSwap()
end

function onHogAttack()
	CheckForWeaponSwap()
	shotsFired = shotsFired + 1
end

function StartingSetUp(gear)

	for i = 1, #wepArray do
		setGearValue(gear,wepArray[i],0)
	end

	setGearValue(gear,amKamikaze,100)
	setGearValue(gear,amSkip,100)

	i = 1 + GetRandom(#atkArray)
	setGearValue(gear,atkArray[i],1)

	i = 1 + GetRandom(#utilArray)
	setGearValue(gear,utilArray[i],1)

end

--[[function SaveWeapons(gear)
-- er, this has no 0 check so presumably if you use a weapon then when it saves  you wont have it

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

-- this is called when a hog dies
function TransferWeps(gear)

	if CurrentHedgehog ~= nil then

		for i = 1, #wepArray do
			val = getGearValue(gear,wepArray[i])
			if val ~= 0 then

				setGearValue(CurrentHedgehog, wepArray[i], val)

				-- if you are using multi-shot weapon, gimme one more
				if (GetCurAmmoType()  == wepArray[i]) and (shotsFired ~= 0) then
					AddAmmo(CurrentHedgehog, wepArray[i], val+1)
				-- assign ammo as per normal
				else
					AddAmmo(CurrentHedgehog, wepArray[i], val)
				end

			end
		end

	end

end

function onGameInit()
	GameFlags = bor(GameFlags,gfInfAttack + gfRandomOrder + gfPerHogAmmo)
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

	table.insert(wepArray, amSkip)
	table.insert(wepArray, amKamikaze)

	runOnGears(StartingSetUp)
	runOnGears(ConvertValues)


end

function CheckForHogSwitch()

	if (CurrentHedgehog ~= nil) then

		currHog = CurrentHedgehog

		if currHog ~= lastHog then

			-- re-assign ammo to this guy, so that his entire ammo set will
			-- be visible during another player's turn
			if lastHog ~= nil then
				ConvertValues(lastHog)
			end

			-- give the new hog what he is supposed to have, too
			ConvertValues(CurrentHedgehog)

		end

		lastHog = currHog

	end

end

function onNewTurn()
	CheckForHogSwitch()
end

--function onGameTick20()
--CheckForHogSwitch()
-- if we use gfPerHogAmmo is this even needed? Err, well, weapons reset, so... yes?
-- orrrr, should we rather call the re-assignment of weapons onNewTurn()? probably not because
-- then you cant switch hogs... unless we add a thing in onSwitch or whatever
-- ye, that is probably better actually, but I'll add that when/if I add switch
--end

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
	-- no, you can't set your own ammo scheme
end


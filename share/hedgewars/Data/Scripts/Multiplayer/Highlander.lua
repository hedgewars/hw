--------------------------------
-- HIGHLANDER / HOGS OF WAR
-- version 0.4c
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

-----------
--0.4b
-----------
-- as per request, add ice-gun


-----------
--0.4c / terror
-----------
-- Information about collected weapons

-------------------------
-- ideas for the future
-------------------------
-- add structure
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
HedgewarsScriptLoad("/Scripts/Params.lua")

-- These define weps allowed by the script. At present Tardis and Resurrection is banned for example
-- These were arbitrarily defined out-of-order in initial script, so that was preserved here, resulting 
-- in a moderately odd syntax.
local atkWeps = 	{
					[amBazooka]=true, [amBee]=true, [amMortar]=true, [amDrill]=true, [amSnowball]=true,
                    [amGrenade]=true, [amClusterBomb]=true, [amMolotov]=true, [amWatermelon]=true,
                    [amHellishBomb]=true, [amGasBomb]=true, [amShotgun]=true, [amDEagle]=true,
                    [amFlamethrower]=true, [amSniperRifle]=true, [amSineGun]=true, 
					[amFirePunch]=true, [amWhip]=true, [amBaseballBat]=true, [amKamikaze]=true,
                    [amSeduction]=true, [amHammer]=true, [amMine]=true, [amDynamite]=true, [amCake]=true,
                    [amBallgun]=true, [amSMine]=true, [amRCPlane]=true, [amBirdy]=true, [amKnife]=true,
                    [amAirAttack]=true, [amMineStrike]=true, [amNapalm]=true, [amDrillStrike]=true, [amPiano]=true, [amAirMine] = true,
					}

local utilWeps =  {
					[amBlowTorch]=true, [amPickHammer]=true, [amGirder]=true, [amPortalGun]=true,
					[amRope]=true, [amParachute]=true, [amTeleport]=true, [amJetpack]=true,
					[amInvulnerable]=true, [amLaserSight]=true, [amVampiric]=true,
					[amLowGravity]=true, [amExtraDamage]=true, [amExtraTime]=true,
					[amLandGun]=true, [amRubber]=true, [amIceGun]=true,
					}

local wepArray = {}

local atkChoices = {}
local utilChoices = {}

local currHog
local lastHog
local started = false
local switchStage = 0

local lastWep = amNothing
local shotsFired = 0

local probability = {1,2,5,10,20,50,200,500,1000000};
local atktot = 0
local utiltot = 0
local maxWep = 57 -- game crashes if you exceed supported #

local someHog = nil -- just for looking up the weps

local mode = nil

function onParameters()
    parseParams()
    mode = params["mode"]
end

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
    for i = 1,maxWep do
        setGearValue(gear,i,0)
    end
    for w,c in pairs(wepArray) do
        if c == 9 and (atkWeps[w] or utilWeps[w])  then
            setGearValue(gear,w,1)
        end
	end

	setGearValue(gear,amSkip,100)
   
    local r = 0
    if atktot > 0 then
        r = GetRandom(atktot)+1
        for i = 1,maxWep do
        --for w,c in pairs(atkChoices) do
            --WriteLnToConsole('     c: '..c..' w:'..w..' r:'..r)
            if atkChoices[i] >= r then
                setGearValue(gear,i,1)
                break
            end
        end
    end
    if utiltot > 0 then
        r = GetRandom(utiltot)+1
        for i = 1,maxWep do
       -- for w,c in pairs(utilChoices) do
            --WriteLnToConsole('util c: '..c..' w:'..w..' r:'..r)
            if utilChoices[i] >= r then
                setGearValue(gear,i,1)
                break
            end
        end
    end
end

--[[function SaveWeapons(gear)
-- er, this has no 0 check so presumably if you use a weapon then when it saves  you wont have it

	for i = 1, (#wepArray) do
		setGearValue(gear, wepArray[i], GetAmmoCount(gear, wepArray[i]) )
		 --AddAmmo(gear, wepArray[i], getGearValue(gear,wepArray[i]) )
	end

end]]

function ConvertValues(gear)
    for w,c in pairs(wepArray) do
		AddAmmo(gear, w, getGearValue(gear,w) )
    end
end

local function getWeaponName(s)
    if s == 1 then s = "CLUSTER"
    elseif s == 2 then s = "GRENADE"  -- 
    elseif s == 3 then s = "BAZOOKA" -- 
    elseif s == 4 then s = "BEE" -- 
    elseif s == 5 then s = "SHOTGUN" -- 
    elseif s == 6 then s = "PNEUMATIC" -- 
    elseif s == 8 then s = "ROPE" -- 
    elseif s == 9 then s = "MINE" -- 
    elseif s == 10 then s = "DEAGLE" -- 
    elseif s == 11 then s = "DYNAMITE" -- 
    elseif s == 12 then s = "PUNCH" -- 
    elseif s == 13 then s = "WHIP" --  
    elseif s == 14 then s = "BASEBALL" -- 
    elseif s == 15 then s = "PARACHUTE" -- 
    elseif s == 16 then s = "AIRSTRIKE" -- 
    elseif s == 17 then s = "AIRMINESTRIKE" -- 
    elseif s == 18 then s = "TORCH" -- 
    elseif s == 19 then s = "GIRDER"  -- 
    elseif s == 20 then s = "TELEPORT" -- 
    elseif s == 22 then s = "MORTAR" --  
    elseif s == 24 then s = "CAKE" -- 
    elseif s == 25 then s = "SEDUCTION" -- 
    elseif s == 26 then s = "MELON" -- 
    elseif s == 27 then s = "666" -- 
    elseif s == 28 then s = "NAPALM" -- 
    elseif s == 29 then s = "DRILL ROCKET" -- 
    elseif s == 30 then s = "BALLGUN" -- 
    elseif s == 31 then s = "RCP" --
    elseif s == 32 then s = "GRAVITY" -- 
    elseif s == 33 then s = "DAMAGE" -- 
    elseif s == 34 then s = "IMMORTAL?" -- 
    elseif s == 36 then s = "LASER" -- 
    elseif s == 38 then s = "SNIPER" -- 
    elseif s == 39 then s = "UFO" -- 
    elseif s == 40 then s = "MOLOTOV" -- 
    elseif s == 41 then s = "BIRD" -- 
    elseif s == 42 then s = "PORTAL" -- 
    elseif s == 43 then s = "???" -- 
    elseif s == 44 then s = "CHEESE" -- 
    elseif s == 45 then s = "SINEGUN" -- 
    elseif s == 46 then s = "FLAME" -- 
    elseif s == 47 then s = "STICKY" -- 
    elseif s == 48 then s = "HAMMER" -- 
    elseif s == 50 then s = "AIRDRILL" -- 
    elseif s == 53 then s = "LANDSPR" -- 
    elseif s == 54 then s = "ICEGUN" -- 
    elseif s == 55 then s = "HAMMER?" -- 
    elseif s == 56 then s = "RUBBER" -- 
   	elseif s == 57 then s = "AIRMINE"
    end
    return tostring(s)
end

-- this is called when a hog dies
function TransferWeps(gear)
	local wep = "";

	if CurrentHedgehog ~= nil then

        for w,c in pairs(wepArray) do
			val = getGearValue(gear,w)
			if val ~= 0 and (mode == "orig" or (wepArray[w] ~= 9 and getGearValue(CurrentHedgehog, w) == 0))  then
				setGearValue(CurrentHedgehog, w, val)

				-- if you are using multi-shot weapon, gimme one more
				if (GetCurAmmoType() == w) and (shotsFired ~= 0) then
					AddAmmo(CurrentHedgehog, w, val+1)
				-- assign ammo as per normal
				else
					AddAmmo(CurrentHedgehog, w, val)
					wep = wep .. getWeaponName(w) .. ", "
				end

			end
		end

	end

	AddCaption("Weapons: " .. showWeapon(wep),0xffba00ff,capgrpAmmoinfo)
end

function onGameInit()
	EnableGameFlags(gfInfAttack, gfRandomOrder, gfPerHogAmmo)
	DisableGameFlags(gfResetWeps, gfSharedAmmo)
	HealthCaseProb = 100
	Goals = loc("Highlander: Eliminate enemy hogs and take their weapons.") .."|" ..
	loc("Weapons are reset on end of turn.")
end

function onGameStart()
    utilChoices[amSkip] = 0
    local c = 0
    for i = 1,maxWep do
        atkChoices[i] = 0
        utilChoices[i] = 0
        if i ~= 7 then
            wepArray[i] = 0
            c = GetAmmoCount(someHog, i)
            if c > 8 then c = 9 end
            wepArray[i] = c
            if c < 9 and c > 0 then
                if atkWeps[i] then
                    --WriteLnToConsole('a    c: '..c..' w:'..i)
                    atktot = atktot + probability[c]
                    atkChoices[i] = atktot
                elseif utilWeps[i] then
                    --WriteLnToConsole('u    c: '..c..' w:'..i)
                    utiltot = utiltot + probability[c]
                    utilChoices[i] = utiltot
                end
            end
        end
    end

    --WriteLnToConsole('utiltot:'..utiltot..' atktot:'..atktot)
        

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
        if someHog == nil then someHog = gear end
	end

end

function onGearDelete(gear)

	if (GetGearType(gear) == gtHedgehog) then --or (GetGearType(gear) == gtResurrector) then
		TransferWeps(gear)
		trackDeletion(gear)
	end

end

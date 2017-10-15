--------------------------------
-- HIGHLANDER / HOGS OF WAR
-- by mikade
--------------------------------

-- Ancient changelog:

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

local someHog = nil -- just for looking up the weps

-- Script parameter stuff
local mode = nil

-- If true, killing hogs of your own clan doesn't give you their weapons.
-- Otherwise, killing any hog gives you their weapons.
local loyal = false

function onParameters()
    parseParams()
    mode = params["mode"]
    loyal = params["loyal"] == "true"
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
    for i = 0, AmmoTypeMax do
        if i ~= amNothing then
            setGearValue(gear,i,0)
        end
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
        for i = 0, AmmoTypeMax do
            if i ~= amNothing then
                if atkChoices[i] >= r then
                    setGearValue(gear,i,1)
                    break
                end
            end
        end
    end
    if utiltot > 0 then
        r = GetRandom(utiltot)+1
        for i = 0, AmmoTypeMax do
            if i ~= amNothing then
                if utilChoices[i] >= r then
                    setGearValue(gear,i,1)
                    break
                end
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

-- this is called when a hog dies
function TransferWeps(gear)

	if CurrentHedgehog ~= nil and CurrentHedgehog ~= gear and (not loyal or (GetHogClan(CurrentHedgehog) ~= GetHogClan(gear))) then

        local x,y,color
        local vgear
        local vgtX, vgtY, vgtdX, vgtdY, vgtAngle, vgtFrame, vgtFrameTicks, vgtState, vgtTimer, vgtTint
        local dspl = IsHogLocal(CurrentHedgehog)
        local ammolist = ''

        if dspl then
            x,y = GetGearPosition(CurrentHedgehog)
            color = GetClanColor(GetHogClan(CurrentHedgehog))
        end

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
				end
                if dspl then
                    if ammolist == '' then
                        ammolist = GetAmmoName(w)
                    else
                        ammolist = ammolist .. ' • ' .. GetAmmoName(w)
                    end
                    x = x + 2
                    y = y + 32
                    vgear = AddVisualGear(x, y, vgtAmmo, 0, true)
                    if vgear ~= nil then
                        vgtX,vgtY,vgtdX,vgtdY,vgtAngle,vgtFrame,vgtFrameTicks,vgtState,vgtTimer,vgtTint = GetVisualGearValues(vgear)
                        vgtFrame = w
                        SetVisualGearValues(vgear,vgtX,vgtY,vgtdX,vgtdY,vgtAngle,vgtFrame,vgtFrameTicks,vgtState,vgtTimer,vgtTint)
                    end
                end

			end
		end

        if dspl and ammolist ~= '' then
            PlaySound(sndShotgunReload);
            AddCaption(ammolist, color, capgrpAmmoinfo)
        end
	end

end

function onGameInit()
	EnableGameFlags(gfInfAttack, gfRandomOrder, gfPerHogAmmo)
	DisableGameFlags(gfResetWeps, gfSharedAmmo)
	HealthCaseProb = 100
	if loyal then
		Goals = loc("Loyal Highlander: Eliminate enemy hogs to take their weapons") .. "|"
	else
		Goals = loc("Highlander: Eliminate hogs to take their weapons") .. "|"
	end
	Goals = Goals .. loc("Replenishment: Weapons are restocked on turn start of a new hog")
end

function onGameStart()
    utilChoices[amSkip] = 0
    local c = 0
    for i = 0, AmmoTypeMax do
        if i ~= amNothing then
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
    end

    --WriteLnToConsole('utiltot:'..utiltot..' atktot:'..atktot)
        

	runOnGears(StartingSetUp)
	runOnGears(ConvertValues)
end

function CheckForHogSwitch()

	--[[ Restock the weapons of the hog on turn start, provided it is not the same hog as before.
	This exception is done do avoid a single hog receiving tons of weapons when it is the only unfrozen
	hog and takes consecutive turns. ]]

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

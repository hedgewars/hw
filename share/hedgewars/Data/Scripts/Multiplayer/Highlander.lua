--------------------------------
-- HIGHLANDER / HOGS OF WAR
-- by mikade
--------------------------------

-------------------------
-- ideas for the future
-------------------------
-- add structure
-- allow switcher, resurrector
-- nerf teleport
-- balance weapon distribution across entire team / all teams
-- add other inequalities/bonuses like... ???
-- * some hogs start off with an extra 25 health?
-- * some hogs start off poisoned?
-- * some hogs start off with a rope and 2 drills but die after their turn?

------------------
-- script follows
------------------

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

-- These define weps allowed by the script.
-- These were arbitrarily defined out-of-order in initial script, so that was preserved here, resulting 
-- in a moderately odd syntax.
local atkWeps = {
	[amBazooka]=true, [amBee]=true, [amMortar]=true, [amDrill]=true, [amSnowball]=true,
	[amGrenade]=true, [amClusterBomb]=true, [amMolotov]=true, [amWatermelon]=true,
	[amHellishBomb]=true, [amGasBomb]=true, [amShotgun]=true, [amDEagle]=true,
	[amFlamethrower]=true, [amSniperRifle]=true, [amSineGun]=true, [amMinigun]=true,
	[amFirePunch]=true, [amWhip]=true, [amBaseballBat]=true, [amKamikaze]=true,
	[amSeduction]=true, [amHammer]=true, [amMine]=true, [amDynamite]=true, [amCake]=true,
	[amBallgun]=true, [amSMine]=true, [amRCPlane]=true, [amBirdy]=true, [amKnife]=true,
	[amAirAttack]=true, [amMineStrike]=true, [amNapalm]=true, [amDrillStrike]=true, [amPiano]=true, [amAirMine] = true,
	[amDuck]=true,
}

local utilWeps =  {
	[amBlowTorch]=true, [amPickHammer]=true, [amGirder]=true, [amPortalGun]=true,
	[amRope]=true, [amParachute]=true, [amTeleport]=true, [amJetpack]=true,
	[amInvulnerable]=true, [amLaserSight]=true, [amVampiric]=true,
	[amLowGravity]=true, [amExtraDamage]=true, [amExtraTime]=true,
	[amLandGun]=true, [amRubber]=true, [amIceGun]=true,
}

-- Intentionally left out:
-- * Resurrector (guaranteed to screw up the game)
-- * Time Box
-- * Switch Hedgehog (not sure why)

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

--[[ Loyal Highlander.
If true, killing hogs of your own clan doesn't give you their weapons.
Otherwise, killing any hog gives you their weapons. ]]
local loyal = false


--[[ Multiple weapon usages.
This is a bit tricky to explain.
First, remind yourselves that hogs can never hold more than 1 of the same ammo type.

This param changes how ammo will be restocked after killing a hog if you
already owned this ammo.
Basically this is about if you can use the same weapon multiple times in a
turn by killing enemies in a clever way.
We need to distinguish between your current inventory and the “reset inventory”,
that is, the state to which your inventory will get reset in the next turn.

No Multi-Use (default):
	If you kill a hog who owns a weapon you currently have in your reset inventory,
	but not your inventory, you DO NOT get this weapon again.

Multi-Use:
	If you kill a hog who owns a weapon you currently have in your reset inventory,
	but not your inventory, you DO get this weapon.

Example 1:
	You have a ballgun, and use it to kill a hog who also owns a ballgun.
	No Multi-Use: You will NOT get another ballgun, since it's in your
	reset inventory.
	Multi-Use: You get another ballgun.

Example 2:
	You have a grenade and a bazooka in your inventory. You use the bazooka
	to kill a hedgehog who owns a grenade.
	In both ammo limit modes, you do NOT win any ammo since you already have
	a grenade in your inventory (not just your reset inventory), and the
	rule “no more than 1 ammo per type” applies.
]]
local multiUse = false

function onParameters()
	parseParams()
	multiUse = params["multiuse"] == "true"
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
			local val = getGearValue(gear,w)
			if val ~= 0 and (multiUse or (wepArray[w] ~= 9 and getGearValue(CurrentHedgehog, w) == 0))  then
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
	Goals = Goals .. loc("Replenishment: Weapons are restocked on turn start of a new hog") .. "|" ..
	loc("Ammo Limit: Hogs can’t have more than 1 ammo per type") .. "|"
	if multiUse then
		Goals = Goals .. loc("Multi-Use: You can take and use the same ammo type multiple times in a turn")
	else
		Goals = Goals .. loc("No Multi-Use: Once you used an ammo, you can’t take it again in this turn")
	end
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
				if c > 8 then
					c = 9
				end
				wepArray[i] = c
				if c < 9 and c > 0 then
					if atkWeps[i] then
						atktot = atktot + probability[c]
						atkChoices[i] = atktot
					elseif utilWeps[i] then
						utiltot = utiltot + probability[c]
						utilChoices[i] = utiltot
					end
				end
			end
		end
	end

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

function onGearAdd(gear)

	if (GetGearType(gear) == gtHedgehog) then
		trackGear(gear)
		if someHog == nil then
			someHog = gear
		end
	end

end

function onGearDelete(gear)

	if (GetGearType(gear) == gtHedgehog) then
		TransferWeps(gear)
		trackDeletion(gear)
	end

end

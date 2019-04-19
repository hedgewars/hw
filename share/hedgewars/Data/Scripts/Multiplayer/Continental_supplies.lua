--[[
	=== Continental supplies ===
	Created by Vatten in 2012.
	Further worked on by the Hedgewars Team and contributors.

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
-- fix selection increase delay (weapons to compesate)

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

-- returns 1 or -1 depending on where it is
function GetIfNegative(num)
	if(num<0)
	then
		return -1
	else
		return 1
	end
end

--Will end the turn + give escape time
function EndTurnCS(seconds)
	-- Set attacked state to prevent “Boring” sound to be played
	SetState(CurrentHedgehog, bor(GetState(CurrentHedgehog), gstAttacked))
	--set escape time
	local escapeTime = GetAwayTime*10*seconds
	if escapeTime > 0 then
		Retreat(escapeTime, false)
	else
		SetTurnTimeLeft(escapeTime)
	end
 end

 --show health tag (will mostly be used when a hog is damaged)
function ShowDamageTag(hog,damage)
	local healthtag=AddVisualGear(GetX(hog), GetY(hog), vgtHealthTag, damage, false)
	SetVisualGearValues(healthtag, nil, nil, nil, nil, nil, nil, nil, nil, nil, GetClanColor(GetHogClan(hog)))
end

function FireGear(hedgehog,geartype,vx,vy,timer)
	local hypo=integerHypotenuse(vx,vy)
	return AddGear(div((GetGearRadius(hedgehog)*2*vx),hypo)+GetX(hedgehog), div((GetGearRadius(hedgehog)*2*vy),hypo)+GetY(hedgehog), geartype, 0, vx, vy, timer)
end

function CollectMultiAmmo(hog, ammoList, noAddAmmo)
	local x, y = GetGearPosition(hog)
	x = x + 2
	y = y + 32
	local ammoStr = ""
	local ammoLength = 0
	for _, _ in pairs(ammoList) do
		ammoLength = ammoLength + 1
	end
	local a = 1
	for ammo, count in pairs(ammoList) do
		if not noAddAmmo then
			local oldCount = GetAmmoCount(hog, ammo)
			local newCount = oldCount + count
			-- Make sure that finite ammo stays finite
			if count < 100 and oldCount < 100 and newCount >= 100 then
				newCount = 99
			end
			AddAmmo(hog, ammo, newCount)
		end
		if IsHogLocal(hog) then
			x = x + 2
			y = y + 32
			local vgear = AddVisualGear(x, y, vgtAmmo, 0, true)
			if vgear ~= nil then
				local vgtFrame = ammo
				SetVisualGearValues(vgear, nil, nil, nil, nil, nil, vgtFrame)
			end

			ammoStr = ammoStr .. string.format(loc("%s (+%d)"), GetAmmoName(ammo), count)
			if a < ammoLength then
				ammoStr = ammoStr .. " • "
			end
		end
		a = a + 1
	end
	if ammoLength > 0 then
		PlaySound(sndShotgunReload)
		-- Show collected ammo
		if IsHogLocal(hog) then
			AddCaption(ammoStr, GetClanColor(GetHogClan(hog)), capgrpAmmoinfo)
		end
	end
end

function SetAttackState(state)
	if state==true then
		SetInputMask(bor(GetInputMask(), gmAttack))
	else
		SetInputMask(band(GetInputMask(), bnot(gmAttack)))
	end
end

--====MISC_TIMER GLOBALS====
local CS = {}

--for selecting continent

CS.INIT_TEAMS = {}
CS.GAME_STARTED = false
CS.SELECT_CONTINENT_CHECK=false
CS.START_TIME=0
CS.HOG_HEALTH=100
CS.TEAM_CONTINENT = {}

--variables for seeing if you have swaped around on a weapon
CS.AUSTRALIAN_SPECIAL=0
CS.AFRICAN_SPECIAL_SEDUCTION=0
CS.AFRICAN_SPECIAL_STICKY=0
CS.SOUTH_AMERICAN_SPECIAL=false
CS.NORTH_AMERICAN_SPECIAL_SNIPER=1
CS.NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON=false
CS.KERGUELEN_SPECIAL=1
CS.NORTH_AMERICAN_SPECIAL_SHOTGUN=false
CS.EUROPE_SPECIAL=0
CS.ANTARCTICA_SPECIAL=0
CS.SEDUCTION_INCREASER=0

--detection if something is activated
CS.SWITCH_HOG_IS_ON=false
CS.VAMPIRIC_IS_ON=0
CS.EXTRA_DAMAGE_IS_ON=100
CS.PARACHUTE_IS_ON=false
CS.PRECISE=false

CS.CONTINENT_LABEL_TIMER=-1
CS.SPEECH_TIMER=-1
CS.HANDLE_SPECIAL_WEAPON_MISC_TIMER=-1
CS.HANDLE_SOUTH_AMERICAN_SPECIAL_TIMER=-1
CS.CONFIRM_CONTINENT_SELECTION=-1

--the visual circle for kerguelen
CS.VISUAL_CIRCLE=nil

--the global temporary value
CS.TEMP_VALUE=0

--true if player used any sticky mine mine mode besides hedgehog projectile in this turn
CS.AFRICAN_SPECIAL_NON_PROJECTILE_USED=false

-- “constants”
CS.SABOTAGE_GRAVITY=350
CS.SABOTAGE_GRAVITY_LOW=175
CS.SABOTAGE_DAMAGE=2
CS.SABOTAGE_FREQUENCY=100

--for sabotage
CS.SABOTAGE_COUNTER=0
CS.SABOTAGE_HOGS={}
CS.SABOTAGE_FREQUENCY_NOW=0

--for sundaland
CS.SUNDALAND_END_HOG_CONTINENT_NAME=nil

--misc.
CS.OPTION_NO_SPECIALS=false

--====GENERAL GLOBALS (useful for handling continents)====

CS.SNIPER_SPECIAL_NAME = loc("Green Lipstick Bullet")
CS.BASEBALLBAT_BOOMERANG_NAME = loc("Bouncy Boomerang")
CS.CHEESE_SPECIAL_NAME = loc("Anno 1032")
CS.SEDUCTION_SPECIAL_NAME = loc("Dust Storm")
CS.BASEBALLBAT_CRICKET_NAME = loc("Cricket Time")
CS.PARACHUTE_SPECIAL_NAME = loc("Heroic Wind")
CS.HAMMER_ROAR_NAME = loc("Penguin Roar")
CS.HAMMER_SWAP_NAME = loc("Disguise as a Rockhopper Penguin")
CS.HAMMER_LONELY_NAME = loc("Lonely Cries")
CS.STICKY_PROJECTILE_NAME = loc("Hedgehog Projectile")
CS.STICKY_NAPALM_NAME = loc("Napalm Rocket")
CS.SHOTGUN_SPECIAL_NAME = loc("Eagle Eye")
CS.MOLOTOV_SPECIAL_NAME = loc("Medicine")
CS.HAMMER_SABOTAGE_NAME = loc("Flare")
CS.PICKHAMMER_SPECIAL_NAME = loc("Upside-Down World")

CS.SNIPER_SPECIAL_DESC = loc("Poisonous, deals no damage.")
CS.BASEBALLBAT_BOOMERANG_DESC = loc("Launch a bouncy ball which explodes into a crate.")
CS.CHEESE_SPECIAL_DESC = loc("Strong knockback, but no poison.")
CS.SEDUCTION_SPECIAL_DESC = loc("Deals 15 damage to all enemies in the circle.")
CS.BASEBALLBAT_CRICKET_DESC = loc("Throw a 1 second mine!")
CS.PARACHUTE_SPECIAL_DESC = loc("Drop a ball of dirt which turns into a|cluster on impact. Doesn’t end turn.")
CS.HAMMER_ROAR_DESC = loc("Deal 15 damage + 10% of your hog’s health to all hogs around you and get 2/3 back.")
CS.HAMMER_SWAP_DESC = loc("Swap place with a random enemy in the circle.")
CS.HAMMER_LONELY_DESC = loc("Rise the water if nobody else is in the circle and deal 6 damage to all enemy hogs.")
CS.STICKY_PROJECTILE_DESC = loc("Fire your hedgehog like a sticky mine.")
CS.STICKY_NAPALM_DESC = loc("Fire a rocket with napalm.")
CS.SHOTGUN_SPECIAL_DESC = loc("Teleport to the impact location.")
CS.MOLOTOV_SPECIAL_DESC = loc("Fire some exploding medicine that will heal 15 health to all hogs in its effect radius.")
CS.HAMMER_SABOTAGE_DESC = loc("Sabotage all hogs in the circle and fire a cluster above you.|Sabotaged hogs lose health and have to deal with a very high gravity during their turn.")
CS.PICKHAMMER_SPECIAL_DESC = loc("Teleport to the top of the map, expect fall damage!")

CS.INVULNERABLE_SPECIAL_CAPTION = loc("15+%d damage, %d invulnerable left")
-- Make info
local minfo = function(name, desc)
	return string.format(loc("%s: %s"), name, desc)
end
CS.SNIPER_SPECIAL_INFO = minfo(CS.SNIPER_SPECIAL_NAME, CS.SNIPER_SPECIAL_DESC)
CS.BASEBALLBAT_BOOMERANG_INFO = minfo(CS.BASEBALLBAT_BOOMERANG_NAME, CS.BASEBALLBAT_BOOMERANG_DESC)
CS.CHEESE_SPECIAL_INFO = minfo(CS.CHEESE_SPECIAL_NAME, CS.CHEESE_SPECIAL_DESC)
CS.SEDUCTION_SPECIAL_INFO = minfo(CS.SEDUCTION_SPECIAL_NAME, CS.SEDUCTION_SPECIAL_DESC)
CS.INVULNERABLE_SPECIAL_INFO = loc("Increase the dust storm damage by sacrificing|your invulnerable ammo.")
CS.INVULNERABLE_SPECIAL_CTRL = loc("Up/Down: Adjust dust storm damage")
CS.BASEBALLBAT_CRICKET_INFO = minfo(CS.BASEBALLBAT_CRICKET_NAME, CS.BASEBALLBAT_CRICKET_DESC)
CS.PARACHUTE_SPECIAL_INFO = minfo(CS.PARACHUTE_SPECIAL_NAME, CS.PARACHUTE_SPECIAL_DESC)
CS.HAMMER_ROAR_INFO = minfo(CS.HAMMER_ROAR_NAME, CS.HAMMER_ROAR_DESC)
CS.HAMMER_SWAP_INFO = minfo(CS.HAMMER_SWAP_NAME, CS.HAMMER_SWAP_DESC)
CS.HAMMER_LONELY_INFO = minfo(CS.HAMMER_LONELY_NAME, CS.HAMMER_LONELY_DESC)
CS.STICKY_PROJECTILE_INFO = minfo(CS.STICKY_PROJECTILE_NAME, CS.STICKY_PROJECTILE_DESC)
CS.STICKY_NAPALM_INFO = minfo(CS.STICKY_NAPALM_NAME, CS.STICKY_NAPALM_DESC)
CS.SHOTGUN_SPECIAL_INFO = minfo(CS.SHOTGUN_SPECIAL_NAME, CS.SHOTGUN_SPECIAL_DESC)
CS.MOLOTOV_SPECIAL_INFO = minfo(CS.MOLOTOV_SPECIAL_NAME, CS.MOLOTOV_SPECIAL_DESC)
CS.HAMMER_SABOTAGE_INFO = minfo(CS.HAMMER_SABOTAGE_NAME, CS.HAMMER_SABOTAGE_DESC)
CS.PICKHAMMER_SPECIAL_INFO = minfo(CS.PICKHAMMER_SPECIAL_NAME, CS.PICKHAMMER_SPECIAL_DESC)

CS.SELECT_WEP_INFORMATION=loc("Select your continent with [Up]/[Down] or by selecting a representative weapon.").."|"..
	loc("Press [Attack] to confirm.")
CS.SELECT_WEP_INFORMATION_SHORT=loc("%s, select your continent!")

function GeneralInformation()
	local select_wep, quit_hint
	if not CS.GAME_STARTED then
		select_wep = "| |"..CS.SELECT_WEP_INFORMATION
		quit_hint = "|"..loc("Hint: Use the quit key to see the team’s continent.")
	else
		select_wep = ""
		quit_hint = ""
	end
	local general_information =
		loc("Continents: Select a continent at the beginning.").."|"..
		loc("Supplies: Each continent gives you unique weapons, specials and health.").."|"..
		loc("Weapon specials: Some weapons have special modes (see weapon description).")..
		select_wep..
		quit_hint
	return general_information
end

CS.CONTINENT_INFORMATION =
{
{loc("North America"),
loc("The continent of firearms"),
loc("The Union: You can select a hedgehog at the start of your turns.").."| |"..
loc("Special weapons:").." |"..
GetAmmoName(amShotgun)..": "..CS.SHOTGUN_SPECIAL_INFO.."|"..
GetAmmoName(amSniperRifle)..": "..CS.SNIPER_SPECIAL_INFO,
{amSniperRifle,1},
{{amShotgun,100},{amDEagle,100},{amLaserSight,2},{amSniperRifle,100},{amCake,1},{amAirAttack,2},{amSwitch,2}},
{sndShotgunFire,sndCover},100},

{loc("South America"),
loc("The continent of guerilla tactics"),
"| |"..loc("Special weapons:").." |"
..GetAmmoName(amGasBomb)..": "..CS.CHEESE_SPECIAL_INFO,
{amGasBomb,2},
{{amBirdy,100},{amHellishBomb,1},{amBee,100},{amGasBomb,100},{amFlamethrower,100},{amNapalm,2},{amExtraDamage,3}},
{sndEggBreak,sndLaugh},125},

{loc("Europe"),
loc("The continent of medicine"),
"| |"..loc("Special weapons:").." |"
..GetAmmoName(amMolotov)..": "..CS.MOLOTOV_SPECIAL_INFO,
{amBazooka,3},
{{amBazooka,100},{amGrenade,100},{amMortar,100},{amMolotov,100},{amVampiric,4},{amPiano,1},{amResurrector,2},{amJetpack,4}},
{sndExplosion,sndEnemyDown},100},

{loc("Africa"),
loc("The continent of dust"),
"| |"..loc("Special weapons:").." |"..
GetAmmoName(amSeduction)..": "..CS.SEDUCTION_SPECIAL_INFO.."|"..
CS.INVULNERABLE_SPECIAL_INFO.."|"..
GetAmmoName(amSMine)..": "..CS.STICKY_PROJECTILE_INFO.."|"..
GetAmmoName(amSMine)..": "..CS.STICKY_NAPALM_INFO,
{amSMine,4},
{{amSMine,100},{amWatermelon,1},{amDrillStrike,1},{amDrill,100},{amInvulnerable,7},{amSeduction,100},{amLandGun,3}},
{sndMelonImpact,sndCoward},125},

{loc("Asia"),
loc("The continent of ninjas"),
loc("Textile industry: Will give you a parachute every second turn.").."| |"..
loc("Special weapons:").." |"..
GetAmmoName(amParachute)..": "..CS.PARACHUTE_SPECIAL_INFO,
{amRope,5},
{{amRope,100},{amFirePunch,100},{amParachute,1},{amKnife,2},{amDynamite,1}},
{sndRopeAttach,sndComeonthen},50},

{loc("Australia"),
loc("The continent of sports"),
"| |"..loc("Special weapons:").." |"..
GetAmmoName(amBaseballBat)..": "..CS.BASEBALLBAT_CRICKET_INFO.."|"..
GetAmmoName(amBaseballBat)..": "..CS.BASEBALLBAT_BOOMERANG_INFO.."|"..
loc("Baseball bat specials cannot be used close to other hogs."),
{amBaseballBat,6},
{{amBaseballBat,100},{amMine,100},{amLowGravity,4},{amBlowTorch,100},{amRCPlane,2},{amRubber,4}},
{sndBaseballBat,sndNooo},100},

{loc("Antarctica"),
loc("The continent of ice and science"),
loc("Antarctic summer: Every 4th turn you get 1 girder, 1 mudball, 2 sine guns and 1 portable portal device.").."| |"..
loc("Special weapons:").." |"..
GetAmmoName(amPickHammer)..": "..CS.PICKHAMMER_SPECIAL_INFO,
{amIceGun,7},
{{amSnowball,2},{amPickHammer,100},{amSineGun,4},{amGirder,1},{amExtraTime,1},{amIceGun,1},{amPortalGun,2}},
{sndSineGun,sndOops},75},

{loc("Kerguelen"),
loc("The continent of cowards"),
"| |"..loc("Special weapons:").." |"..
GetAmmoName(amHammer)..": "..CS.HAMMER_ROAR_INFO.."|"..
GetAmmoName(amHammer)..": "..CS.HAMMER_SWAP_INFO.."|"..
GetAmmoName(amHammer)..": "..CS.HAMMER_LONELY_INFO.."|"..
GetAmmoName(amHammer)..": "..CS.HAMMER_SABOTAGE_INFO,
{amHammer,8},
{{amHammer,100},{amMineStrike,1},{amBallgun,1},{amTeleport,1}},
{sndPiano5,sndStupid},75},

{loc("Zealandia"),
loc("The forgotten continent"),
loc("Surprise supplies: Get 1-3 random weapons each turn.") .. "|" ..
loc("Treasure: Massive weapon bonus in first turn.").."|"..
loc("Forgetfulness: You will lose all your weapons each turn."),
{amInvulnerable,9},
{{amBazooka,1},{amGrenade,1},{amBlowTorch,1},{amSwitch,1},{amRope,1},{amDrill,1},{amDEagle,1},{amPickHammer,1},{amFirePunch,1},{amWhip,1},{amMortar,1},{amSnowball,1},{amExtraTime,1},{amInvulnerable,1},{amVampiric,1},{amFlamethrower,1},{amBee,1},{amClusterBomb,1},{amTeleport,1},{amLowGravity,1},{amJetpack,1},{amGirder,1},{amLandGun,1},{amBirdy,1},{amAirMine,1},{amTardis,1},{amLaserSight,1},{amAirMine,1}},
{sndSplash,sndFirstBlood},100},

{loc("Sundaland"),
loc("The continent of greed"),
loc("Bounty: Get 6 weapons for each kill (even on own hogs)."),
{amTardis,10},
{{amClusterBomb,5},{amTardis,100},{amWhip,100},{amKamikaze,100},{amAirMine,2}},
{sndWarp,sndSameTeam},100}

}

--weapontype,ammo,?,duration,*times your choice,affect on random team (should be placed with 1,0,1,0,1 on the 6th option for better randomness)
CS.WEAPONS_DAMAGE = {
	{amKamikaze,    0, 1, 0, 1, 0},
	{amSineGun,     0, 1, 0, 1, 0},
	{amMineStrike,  0, 1, 6, 1, 1},
	{amGrenade,     0, 1, 0, 1, 0},
	{amPiano,       0, 1, 7, 1, 0},
	{amClusterBomb, 0, 1, 0, 1, 0},
	{amBee,         0, 1, 0, 1, 0},
	{amShotgun,     0, 1, 0, 1, 0},
	{amSniperRifle, 0, 1, 0, 1, 0},
	{amDynamite,    0, 1, 6, 1, 1},
	{amFirePunch,   0, 1, 0, 1, 0},
	{amHellishBomb, 0, 1, 6, 1, 2},
	{amWhip,        0, 1, 0, 1, 0},
	{amNapalm,      0, 1, 6, 1, 1},
	{amPickHammer,  0, 1, 0, 1, 0},
	{amBaseballBat, 0, 1, 0, 1, 1},
	{amMortar,      0, 1, 0, 1, 0},
	{amCake,        0, 1, 5, 1, 2},
	{amSeduction,   0, 1, 0, 1, 0},
	{amWatermelon,  0, 1, 6, 1, 2},
	{amDrill,       0, 1, 0, 1, 0},
	{amBallgun,     0, 1, 8, 1, 2},
	{amDEagle,      0, 1, 0, 1, 0},
	{amMolotov,     0, 1, 0, 1, 0},
	{amHammer,      0, 1, 0, 1, 1},
	{amBirdy,       0, 1, 0, 1, 0},
	{amRCPlane,     0, 1, 6, 1, 2},
	{amMine,        0, 1, 0, 1, 0},
	{amGasBomb,     0, 1, 0, 1, 0},
	{amAirAttack,   0, 1, 5, 1, 1},
	{amBlowTorch,   0, 1, 0, 1, 0},
	{amFlamethrower,0, 1, 0, 1, 0},
	{amSMine,       0, 1, 0, 1, 0},
	{amSnowball,    0, 1, 0, 1, 0},
	{amKnife,       0, 1, 0, 1, 0},
	{amDrillStrike, 0, 1, 5, 1, 1},
	{amBazooka,     0, 1, 0, 1, 0},
	{amAirMine,     0, 1, 0, 1, 0},
}
CS.WEAPONS_SUPPORT = {
	{amParachute,   0, 1, 0, 1, 0},
	{amGirder,      0, 1, 0, 1, 0},
	{amSwitch,      0, 1, 0, 1, 0},
	{amLowGravity,  0, 1, 0, 1, 0},
	{amExtraDamage, 0, 1, 2, 1, 0},
	{amRope,        0, 1, 0, 1, 0},
	{amInvulnerable,0, 1, 0, 1, 0},
	{amExtraTime,   0, 1, 0, 1, 0},
	{amLaserSight,  0, 1, 0, 1, 0},
	{amVampiric,    0, 1, 0, 1, 0},
	{amJetpack,     0, 1, 0, 1, 0},
	{amPortalGun,   0, 1, 3, 1, 1},
	{amResurrector, 0, 1, 2, 1, 0},
	{amTeleport,    0, 1, 0, 1, 0},
	{amLandGun,     0, 1, 0, 1, 0},
	{amTardis,      0, 1, 0, 1, 0},
	{amIceGun,      0, 1, 0, 1, 0},
	{amRubber,      0, 1, 0, 1, 0}

}

--check if weps valid
function wepNotValidBorder(weapon)
	if(MapHasBorder() == false or (weapon ~= amAirAttack and weapon ~= amMineStrike and weapon ~= amNapalm and weapon ~= amDrillStrike and weapon ~= amPiano))
	then
		return true
	end

	return false
end

--will check after borders and stuff
function ValidateWeapon(hog,weapon,amount)
	if(wepNotValidBorder(weapon))
	then
		if(amount==1)
		then
			AddAmmo(hog, weapon)
		else
			AddAmmo(hog, weapon,amount)
		end
	end
end

function SpawnRandomCrate(x,y,strength)
	local tot=#CS.WEAPONS_SUPPORT + #CS.WEAPONS_DAMAGE
	local rand=GetRandom(tot)+1

	if(rand > #CS.WEAPONS_SUPPORT)
	then
		local weapon = rand - #CS.WEAPONS_SUPPORT

		while(wepNotValidBorder(CS.WEAPONS_DAMAGE[weapon][1])==false)
		do
			if(weapon >= #CS.WEAPONS_DAMAGE)
			then
				weapon=0
			end
			weapon = weapon+1
		end

		SpawnAmmoCrate(x, y, CS.WEAPONS_DAMAGE[weapon][1])
	else
		SpawnUtilityCrate(x, y, CS.WEAPONS_SUPPORT[rand][1])
	end
end

--removes one weapon
function RemoveWeapon(hog,weapon)

	if(GetAmmoCount(hog, weapon)<100)
	then
		AddAmmo(hog,weapon,GetAmmoCount(hog, weapon)-1)
	end
end

--reset all weapons for a team
function CleanWeapons(hog)

	for w=1, #CS.WEAPONS_SUPPORT do
		AddAmmo(hog, CS.WEAPONS_SUPPORT[w][1], 0)
	end
	for w=1, #CS.WEAPONS_DAMAGE do
		AddAmmo(hog, CS.WEAPONS_DAMAGE[w][1], 0)
	end
end

--get the weapons from a weaponset
function LoadWeaponset(hog, num)
	for v,w in pairs(CS.CONTINENT_INFORMATION[num][5])
	do
		ValidateWeapon(hog, w[1],w[2])
	end

	CS.TEMP_VALUE=CS.CONTINENT_INFORMATION[num][7]
	runOnGears(SetHogHealth)
end

--list up all weapons from the icons for each continent
function InitWeaponsMenu(hog)

	if(GetHogLevel(hog)==0 or CS.CONTINENT_INFORMATION[1][6][1]==sndFrozenHogImpact)
	then
		for v,w in pairs(CS.CONTINENT_INFORMATION)
		do
			ValidateWeapon(hog, CS.CONTINENT_INFORMATION[v][4][1], 100)
		end
		AddAmmo(hog, amSwitch, 100) --random continent

	--for the computers
	else
		--europe
		ValidateWeapon(hog, CS.CONTINENT_INFORMATION[3][4][1], 100)
		--north america
		ValidateWeapon(hog, CS.CONTINENT_INFORMATION[1][4][1], 100)
	end
end

--shows the continent info
function ShowContinentInfo(continent,time,generalinf)
	local geninftext=""
	local ns=false
	if(time==-1)
	then
		time=0
		ns=true
	end
	if(generalinf)
	then
		geninftext="| |"..loc("General information:").."|"..GeneralInformation()
	else
		geninftext="| |"..loc("Press [Attack] to select this continent!")
	end

	ShowMission(CS.CONTINENT_INFORMATION[continent][1],
		CS.CONTINENT_INFORMATION[continent][2],
		string.format(loc("Initial health: %d"), CS.CONTINENT_INFORMATION[continent][7]) .. "|"..
		CS.CONTINENT_INFORMATION[continent][3]..geninftext,
		CS.CONTINENT_INFORMATION[continent][4][2], time)
	if(ns)
	then
		HideMission()
	elseif not CS.GAME_STARTED then
		AddCaption(CS.CONTINENT_INFORMATION[continent][1], GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmoinfo)
	end
end

--will show a circle of gears (eye candy)
function VisualExplosion(range,xpos,ypos,gear1,gear2)
	local degr=0
	local lap=30
	while(lap<range)
	do
		while(degr < 6.2831)
		do
			AddVisualGear(xpos+math.cos(degr+0.1)*(lap+5), ypos+math.sin(degr+0.1)*(lap+5), gear1, 0, false)
			if(gear2~=false)
			then
				AddVisualGear(xpos+math.cos(degr)*lap, ypos+math.sin(degr)*lap, gear2, 0, false)
			end
			degr=degr+((3.1415*3)*0.125) --1/8 = 0.125
		end
		lap=lap+30
		degr=degr-6.2831
	end
end

--give one random weapon
function GetRandomWeapon(hog, weptype, power, onlyonewep, getdelayedweps, mypower)

	local wepout=nil
	local rand_weaponset_power=mypower

	if(rand_weaponset_power < power)
	then
		local numberofweapons = #weptype

		local random_weapon = math.abs(GetRandom(numberofweapons)+1)

		while((weptype[random_weapon][4]>TotalRounds and getdelayedweps==false) or rand_weaponset_power+weptype[random_weapon][6]>power
				or (wepNotValidBorder(weptype[random_weapon][1])==false) or GetAmmoCount(hog,weptype[random_weapon][1])>=100
				or (GetAmmoCount(hog,weptype[random_weapon][1])>=1 and onlyonewep==true))
		do
			if(random_weapon>=numberofweapons)
			then
				random_weapon=0
			end
			random_weapon = random_weapon+1
		end

		wepout=weptype[random_weapon][1]

		ValidateWeapon(hog, wepout,1)
		rand_weaponset_power=mypower+weptype[random_weapon][6]
	end

	return rand_weaponset_power , wepout
end

--zealandia (generates weapons from the weaponinfo above) and sundaland
function RandomContinentsGetWeapons(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		local currCont=CS.TEAM_CONTINENT[GetHogTeamName(hog)]

		if(currCont~=0)
		then
			local checkDefCont=CS.CONTINENT_INFORMATION[currCont][4][2]

			--for sunda
			local wepamount=getTeamValue(GetHogTeamName(hog), "sundaland-count")

			if(checkDefCont==9 and getTeamValue(GetHogTeamName(hog), "rand-done-turn")==false)
			then
				CleanWeapons(hog)

				local rand_weaponset_power = 0

				rand_weaponset_power=GetRandomWeapon(hog,CS.WEAPONS_DAMAGE,100,true,false,rand_weaponset_power)
				rand_weaponset_power=GetRandomWeapon(hog,CS.WEAPONS_SUPPORT,2,true,false,rand_weaponset_power)
				rand_weaponset_power=GetRandomWeapon(hog,CS.WEAPONS_DAMAGE,1,true,false,rand_weaponset_power)

				setTeamValue(GetHogTeamName(hog), "rand-done-turn", true)

			elseif(checkDefCont==10 and wepamount~=nil)
			then
				local loci=0

				while(loci<wepamount)
				do
					local _
					local wep = {}
					--6 random weapons
					_, wep[1] = GetRandomWeapon(hog,CS.WEAPONS_DAMAGE,100,false,true,0)
					_, wep[2] = GetRandomWeapon(hog,CS.WEAPONS_DAMAGE,100,false,true,0)
					_, wep[3] = GetRandomWeapon(hog,CS.WEAPONS_DAMAGE,2,false,true,1)

					_, wep[4] = GetRandomWeapon(hog,CS.WEAPONS_SUPPORT,100,false,true,0)
					_, wep[5] = GetRandomWeapon(hog,CS.WEAPONS_SUPPORT,100,false,true,0)
					_, wep[6] = GetRandomWeapon(hog,CS.WEAPONS_SUPPORT,100,false,true,0)

					-- Don't give weapons directly, only insert them into the global temp. value
					-- We expect this function to be called by runOnGears for Sundaland.
					if CS.TEMP_VALUE[hog] == nil then
						CS.TEMP_VALUE[hog] = {}
					end
					for w=1, #wep do
						local ammoList = CS.TEMP_VALUE[hog]
						if ammoList[wep[w]] == nil then
							ammoList[wep[w]] = 1
						else
							ammoList[wep[w]] = math.min(99, ammoList[wep[w]] + 1)
						end
					end

					loci=loci+1
				end

				setTeamValue(GetHogTeamName(hog), "sundaland-count",nil)
			end
		end
	end
end

--this will take that hogs settings for the weapons and add them
function SetContinentWeapons()

	CleanWeapons(CurrentHedgehog)
	LoadWeaponset(CurrentHedgehog,CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)])

	local visualstuff=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-5, vgtDust,0, false)
	SetVisualGearValues(visualstuff, nil, nil, nil, nil, nil, nil, nil, 2, nil, GetClanColor(GetHogClan(CurrentHedgehog)))

	SetCSAmmoDescriptions("weapons")
	ShowContinentInfo(CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)],5000,false)
end

--count hogs in team
function CountHogsInTeam(hog)
	if(GetHogTeamName(hog)==GetHogTeamName(CurrentHedgehog))
	then
		CS.TEMP_VALUE=CS.TEMP_VALUE+1
	end
end

--==========================run throw all hog/gear weapons ==========================

function SetHogHealth(hog)
	if(GetGearType(hog) == gtHedgehog and GetHogClan(hog) == GetHogClan(CurrentHedgehog))
	then
		SetHealth(hog, div(CS.TEMP_VALUE*CS.HOG_HEALTH,100))
	end
end

--will check if the mine is nicely placed
function AustraliaSpecialCheckHogs(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 40, false)==true and hog ~= CurrentHedgehog)
		then
			CS.TEMP_VALUE=1
		end
	end
end

function HogOuch(hog, ouchType)
	local r
	if ouchType == "moan" then
		r = math.random(1, 2)
		if r == 1 then
			PlaySound(sndPoisonMoan, hog, true)
		else
			PlaySound(sndPoisonCough, hog, true)
		end
	else
		local r = math.random(1, 4)
		PlaySound(_G["sndOw"..r], hog)
	end
end

--african special on sedunction
function AfricaSpecialSeduction(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		local dmg=div((15+CS.SEDUCTION_INCREASER)*CS.EXTRA_DAMAGE_IS_ON,100)
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 250, false)==true and GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			if(GetHealth(hog) > dmg)
			then
				CS.TEMP_VALUE=CS.TEMP_VALUE+div(dmg*CS.VAMPIRIC_IS_ON,100)
				SetHealth(hog, GetHealth(hog)-dmg)
			else
				CS.TEMP_VALUE=CS.TEMP_VALUE+div(GetHealth(hog)*CS.VAMPIRIC_IS_ON,100)
				SetHealth(hog, 0)
			end
			HogOuch(hog)
			ShowDamageTag(hog,dmg)
		end
	end
end

--kerguelen special on structure
function KerguelenSpecialRed(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 120, false)==true and GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			local dmg=div((15+div(GetHealth(CurrentHedgehog)*10,100))*CS.EXTRA_DAMAGE_IS_ON,100)

			if(GetHealth(hog)>dmg)
			then
				CS.TEMP_VALUE=CS.TEMP_VALUE+div(dmg*2,3)+div(dmg*CS.VAMPIRIC_IS_ON*2,100*3)
				SetHealth(hog, GetHealth(hog)-dmg)
			else
				CS.TEMP_VALUE=CS.TEMP_VALUE+(div(GetHealth(hog)*75,100))+(div(GetHealth(CurrentHedgehog)*10,100))+div((GetHealth(hog)+div(GetHealth(CurrentHedgehog)*10,100))*CS.VAMPIRIC_IS_ON,100)
				SetHealth(hog, 0)
			end
			HogOuch(hog)
			ShowDamageTag(hog,dmg)
			AddVisualGear(GetX(hog), GetY(hog), vgtExplosion, 0, false)
			AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmokeWhite, 0, false)
		end
	end
end

--will count the hogs, used to get one random hog.
function KerguelenSpecialYellowCountHogs(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(GetHogClan(hog) ~= GetHogClan(CurrentHedgehog) and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 390, false))
		then
			CS.TEMP_VALUE=CS.TEMP_VALUE+1
		end
	end
end
--kerguelen special swap hog
function KerguelenSpecialYellowSwap(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(CS.KERGUELEN_SPECIAL ~= -1 and GetHogClan(hog) ~= GetHogClan(CurrentHedgehog) and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 420, false))
		then
			if(CS.TEMP_VALUE==0)
			then
				local thisX=GetX(CurrentHedgehog)
				local thisY=GetY(CurrentHedgehog)
				SetGearPosition(CurrentHedgehog, GetX(hog), GetY(hog))
				SetGearPosition(hog, thisX, thisY)
				CS.KERGUELEN_SPECIAL=-1
			else
				CS.TEMP_VALUE=CS.TEMP_VALUE-1
			end
		end
	end
end

--kerguelen special will apply sabotage
function KerguelenSpecialGreen(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(CurrentHedgehog~=hog and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 80, false))
		then
			CS.TEMP_VALUE=1
			CS.SABOTAGE_HOGS[hog]=1
			AddGear(GetX(hog), GetY(hog), gtCluster, 0, 0, 0, 1)
			PlaySound(sndNooo,hog)
		end
	end
end

--first part on kerguelen special (lonely cries)
function KerguelenSpecialBlueCheck(hog)
	if(GetGearType(hog) == gtHedgehog and hog ~= CurrentHedgehog and GetHealth(CurrentHedgehog) and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 500, false))
	then
		CS.TEMP_VALUE=1
	end
end

--second part on kerguelen special (lonely cries)
function KerguelenSpecialBlueActivate(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		local dmg=div(6*CS.EXTRA_DAMAGE_IS_ON,100)
		if(GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			if(GetHealth(hog) > dmg)
			then
				CS.TEMP_VALUE=CS.TEMP_VALUE+div(dmg*CS.VAMPIRIC_IS_ON,100)
				SetHealth(hog, GetHealth(hog)-dmg)
			else
				CS.TEMP_VALUE=CS.TEMP_VALUE+div(GetHealth(hog)*CS.VAMPIRIC_IS_ON,100)
				SetHealth(hog, 0)
			end
			HogOuch(hog, "moan")
			ShowDamageTag(hog,dmg)

			AddVisualGear(GetX(hog), GetY(hog)-30, vgtEvilTrace, 0, false)
		end
	end
end

--south american special (used fire gear)
function SouthAmericaSpecialCheeseExplosion(hog)
	if(GetGearType(hog) == gtHedgehog or GetGearType(hog) == gtMine or GetGearType(hog) == gtExplosives)
	then
		local power_radius_outer=230
		local power_sa=700000
		local hypo=0
		if(gearIsInCircle(hog,GetX(CS.TEMP_VALUE), GetY(CS.TEMP_VALUE), power_radius_outer, false))
		then
			if(hog == CurrentHedgehog)
			then
				SetState(CurrentHedgehog, gstMoving)
			end
			SetGearPosition(hog, GetX(hog),GetY(hog)-3)
			hypo=integerHypotenuse(math.abs(GetX(hog)-GetX(CS.TEMP_VALUE)),math.abs(GetY(hog)-GetY(CS.TEMP_VALUE)))
			SetGearVelocity(hog, div((power_radius_outer-hypo)*power_sa*GetIfNegative(GetX(hog)-GetX(CS.TEMP_VALUE)),power_radius_outer), div((power_radius_outer-hypo)*power_sa*GetIfNegative(GetY(hog)-GetY(CS.TEMP_VALUE)),power_radius_outer))
		end
	end
end

--north american special on sniper
function NorthAmericaSpecialSniper(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(CS.TEMP_VALUE,GetX(hog), GetY(hog), 20, false))
		then
			SetEffect(hog, hePoisoned, 5)
			PlaySound(sndBump)
			SetSoundMask(sndMissed, true)
		end
	end
end

--european special on molotov (used fire gear)
function EuropeSpecialMolotovHit(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(CS.TEMP_VALUE,GetX(hog), GetY(hog), 100, false))
		then
			local healthadd=15
			HealHog(hog, healthadd+(div(healthadd*CS.VAMPIRIC_IS_ON,100)), hog == CurrentHedgehog)
			SetEffect(hog, hePoisoned, false)
			CS.SABOTAGE_HOGS[hog]=0
			SetSoundMask(sndMissed, true)
		end
	end
end

--a weaponset string to something readable by the script
function transferableParamToWeaponSet(string,icon)
	local continentinfo={}
	local numb=0
	local wepcodes=0
	local where=0

	local x=0
	local i=1

	--default icon
	continentinfo[4]={}
	if(icon==1000)
	then
		local mid = #CS.WEAPONS_DAMAGE
		local max = mid + #CS.WEAPONS_SUPPORT
		local ic=(string.byte(string) % max)+1

		if(ic>mid)
		then
			ic=CS.WEAPONS_SUPPORT[ic-mid][1]
		else
			ic=CS.WEAPONS_DAMAGE[ic][1]
		end

		continentinfo[4][1]=ic
		continentinfo[4][2]=-ic
	else
		continentinfo[4][1]=icon
		continentinfo[4][2]=-icon
	end

	continentinfo[6]={sndFrozenHogImpact,sndUhOh}
	continentinfo[7]=100

	for c in string:gmatch"."
	do
		--first part, eg name of the weaponset
		if(where==0)
		then
			if(string.byte(c)==126)
			then
				continentinfo[1]=string.sub(string,0,numb)
				wepcodes=numb
				where=1
			end
		--second part, subname of the weaponset
		elseif(where==1)
		then
			if(string.byte(c)==126)
			then
				continentinfo[2]=string.sub(string,wepcodes+2,numb)
				continentinfo[5]={}
				wepcodes=numb
				where=2
			end
		--insert all weapons
		elseif(where==2)
		then
			x=string.byte(c)-35
			if(x>90)
			then
				break
			elseif(x>80)
			then
				if(x-80<10)
				then
					i=x-80
				else
					i=100
				end
			else
				table.insert(continentinfo[5],{x,i})
			end
		end
		numb=numb+1
	end

	if(continentinfo[5]~=nil and continentinfo[5][1]~=nil)
	then
		continentinfo[3] =
			string.format(loc("%s was extracted from the scheme"), continentinfo[1])

		table.insert(CS.CONTINENT_INFORMATION, continentinfo)
	end

	return nil
end

--add a weaponset from a hogname
function HogNameToWeaponset(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		local string=GetHogName(hog)
		local numb=0

		for c in string:gmatch"."
		do
			if(string.byte(c)==126)
			then
				local name=string.sub(string,0,numb)
				SetHogName(hog,name)
				local weaponcode=string.sub(string,numb+2)
				local continentinfo=transferableParamToWeaponSet(weaponcode,1000)

				if(continentinfo~=nil)
				then
					table.insert(CS.CONTINENT_INFORMATION, continentinfo)
				end
				return
			end
			numb=numb+1
		end
	end
end

--============================================================================

--Parameters -> [options],[global-continent]
--wt=yes			allow to search for weaponsets on hog names
--spec=off		disable specials (will make stuff unbalanced)
--cont=no		remove the pre-defined continents

--for custom made continent, follows the same standards as the globalism one. You can make your continent with <Name>~<Information>~<Weapons>. Take the weapons generated from globalism, if you want a GUI :P
--weapons=<ammo><types>, ammo = ascii[116(1 ammo) to 125(inf ammo)] types = ascii[36(Grenade), 37(Clusterbomb) to 90(knife)] see https://hedgewars.org/kb/AmmoTypes
--ex "Own continent~this continent rocks!~tZ}$" will get 1 knife and inf grenades
function onParameters()

	local searchfor="wt=yes"
	local match=string.find(ScriptParam,searchfor, 1)

	if(match~=nil)
	then
		CS.TEMP_VALUE=1

		ScriptParam=string.gsub(ScriptParam,"(,?)"..searchfor.."(,?)","")
	end

	searchfor="spec=off"
	match=string.find(ScriptParam,searchfor, 1)

	if(match~=nil)
	then
		CS.OPTION_NO_SPECIALS=true

		ScriptParam=string.gsub(ScriptParam,"(,?)"..searchfor.."(,?)","")
	end

	searchfor="cont=no"
	match=string.find(ScriptParam,searchfor, 1)

	if(match~=nil)
	then
		CS.CONTINENT_INFORMATION={}

		ScriptParam=string.gsub(ScriptParam,"(,?)"..searchfor.."(,?)","")
	end

	if(ScriptParam~=nil)
	then
		local continentinfo=transferableParamToWeaponSet(ScriptParam,amLowGravity)

		if(continentinfo~=nil)
		then
			table.insert(CS.CONTINENT_INFORMATION, continentinfo)
		end
	end
end

--set each weapons settings
function onAmmoStoreInit()

	SetAmmo(amSkip, 9, 0, 0, 0)

	for v,w in pairs(CS.WEAPONS_DAMAGE)
	do
		SetAmmo(w[1], w[2], w[3], w[4], w[5])
	end

	for v,w in pairs(CS.WEAPONS_SUPPORT)
	do
		SetAmmo(w[1], w[2], w[3], w[4], w[5])
	end
end

function SetCSAmmoDescriptions(mode)
	if mode == "continents" then
		for c=1, #CS.CONTINENT_INFORMATION do
			local cont = CS.CONTINENT_INFORMATION[c]
			local hp = string.format(loc("Initial health: %d"), cont[7])
			SetAmmoTexts(cont[4][1], cont[1], cont[2], hp .."|" .. cont[3], false)
			SetAmmoDescriptionAppendix(cont[4][1], nil)
		end
		SetAmmoTexts(amSwitch, loc("Random continent"), loc("If you just don’t care …"), loc("Select this item for a random continent."), false)

	elseif mode == "weapons" then
		local specSelect = loc("Switch: Select weapon special")
		local specHeader = loc("Available weapon specials:") .. " "
		local specText="|"..
			specSelect.."| |"..
			specHeader.."|"

		SetAmmoDescriptionAppendix(amSniperRifle,
			specText..
			CS.SNIPER_SPECIAL_INFO)
		SetAmmoDescriptionAppendix(amBaseballBat,
			specText..
			CS.BASEBALLBAT_BOOMERANG_INFO .. "|" ..
			CS.BASEBALLBAT_CRICKET_INFO .. "|" ..
			loc("These weapon specials cannot be used close to other hogs."))
		SetAmmoDescriptionAppendix(amGasBomb,
			specText..
			CS.CHEESE_SPECIAL_INFO)
		SetAmmoDescriptionAppendix(amSeduction,
			specSelect .. "|" ..
			CS.INVULNERABLE_SPECIAL_CTRL .. "| |" ..
			specHeader .. "|" ..
			CS.SEDUCTION_SPECIAL_INFO .. "|" ..
			CS.INVULNERABLE_SPECIAL_INFO)
		SetAmmoDescriptionAppendix(amParachute,
			loc("Switch: Drop ball of dirt from parachute (once)") .. "| |" ..
			specHeader .. "|" ..
			CS.PARACHUTE_SPECIAL_INFO)
		SetAmmoDescriptionAppendix(amHammer,
			specText..
			CS.HAMMER_ROAR_INFO .. "|" ..
			CS.HAMMER_SWAP_INFO .. "|" ..
			CS.HAMMER_LONELY_INFO .. "|" ..
			CS.HAMMER_SABOTAGE_INFO)
		SetAmmoDescriptionAppendix(amSMine,
			specText..
			CS.STICKY_PROJECTILE_INFO .. "|" ..
			CS.STICKY_NAPALM_INFO)
		SetAmmoDescriptionAppendix(amShotgun,
			specText..
			CS.SHOTGUN_SPECIAL_INFO)
		SetAmmoDescriptionAppendix(amMolotov,
			specText..
			CS.MOLOTOV_SPECIAL_INFO)
		SetAmmoDescriptionAppendix(amPickHammer,
			specText..
			CS.PICKHAMMER_SPECIAL_INFO)
		SetAmmoDescriptionAppendix(amVampiric,
			loc("This also increases the effectiveness of Medicine.")
			)
		for c=1, #CS.CONTINENT_INFORMATION do
			local cont = CS.CONTINENT_INFORMATION[c]
			SetAmmoTexts(cont[4][1], nil, nil, nil)
		end
		SetAmmoTexts(amSwitch, nil, nil, nil)
	end

	if mode == "continents" or not CS.GAME_STARTED then
		SetAmmoTexts(amSkip, loc("Select continent"), loc("Continent selection"), loc("Select the current continent.") .. "|" .. loc("Choose your continent wisely, as your decision will be permanent.") .. "|" .. loc("Up/Down: Browse through continents") .. "|" .. loc("Attack: Select this continent"))
	else
		SetAmmoTexts(amSkip, nil, nil, nil)
	end
end

--on game start
function onGameStart()
	ShowMission(loc("Continental supplies"),loc("Let a continent provide your weapons!"),GeneralInformation(), 0, 0)
	SetCSAmmoDescriptions("continents")

	if(CS.TEMP_VALUE==1)
	then
		runOnGears(HogNameToWeaponset)
	end
end

function onGameInit()
	SuddenDeathTurns= SuddenDeathTurns+1
end

--what happen when a turn starts
function onNewTurn()
	--will refresh the info on each tab weapon
	CS.AUSTRALIAN_SPECIAL=0
	CS.AFRICAN_SPECIAL_SEDUCTION=0
	CS.SEDUCTION_INCREASER=0
	CS.SOUTH_AMERICAN_SPECIAL=false
	CS.AFRICAN_SPECIAL_STICKY=0
	CS.KERGUELEN_SPECIAL=1
	CS.NORTH_AMERICAN_SPECIAL_SNIPER=1
	CS.NORTH_AMERICAN_SPECIAL_SHOTGUN=false
	CS.NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON=false
	CS.EUROPE_SPECIAL=0
	CS.VAMPIRIC_IS_ON=0
	CS.EXTRA_DAMAGE_IS_ON=100
	CS.SABOTAGE_COUNTER=0
	CS.ANTARCTICA_SPECIAL=0

	CS.TEMP_VALUE=0

	CS.SUNDALAND_END_HOG_CONTINENT_NAME=GetHogTeamName(CurrentHedgehog)

	if TotalRounds >= 1 then
		CS.GAME_STARTED = true
	end

	SetSoundMask(sndLaugh, false)
	SetSoundMask(sndMissed, false)
	CS.AFRICAN_SPECIAL_NON_PROJECTILE_USED=false
	SetAttackState(true)

	--when all hogs are "placed"
	if(GetCurAmmoType()~=amTeleport)
	then
		--will run once when the game really starts (after placing hogs and so on
		if(CS.INIT_TEAMS[GetHogTeamName(CurrentHedgehog)] == nil)
		then
			SetInputMask(band(GetInputMask(), gmWeapon))

			if(CS.START_TIME==0)
			then
				CS.START_TIME=TurnTimeLeft
				CS.HOG_HEALTH=GetHealth(CurrentHedgehog)
			end

			SetTurnTimeLeft(100000)

			AddCaption(string.format(CS.SELECT_WEP_INFORMATION_SHORT, GetHogTeamName(CurrentHedgehog)), capcolDefault, capgrpGameState)
			AddCaption(loc("No continent selected"), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmoinfo)
			CS.SELECT_CONTINENT_CHECK=true
			ShowMission(loc("Continental supplies"),loc("Let a continent provide your weapons!"),GeneralInformation(), 0, 0)
			SetCSAmmoDescriptions("continents")

			InitWeaponsMenu(CurrentHedgehog)
			CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=0
			CS.INIT_TEAMS[GetHogTeamName(CurrentHedgehog)] = 2

		else
			--if its not the initialization turn
			CS.SELECT_CONTINENT_CHECK=false
			SetInputMask(bor(GetInputMask(), bnot(gmWeapon)))

			if(CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==0)
			then
				CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=GetRandom(#CS.CONTINENT_INFORMATION)+1
				SetContinentWeapons()
			end
			local currCont=CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]
			local checkDefCont=CS.CONTINENT_INFORMATION[currCont][4][2]

			--give zeelandia-teams new weapons so they can plan for the next turn
			-- Use temporary value to store list of collected weapons
			CS.TEMP_VALUE = {}
			runOnGears(RandomContinentsGetWeapons)
			for hog, ammoList in pairs(CS.TEMP_VALUE) do
				CollectMultiAmmo(hog, ammoList, true)
			end

			--some specials for some continents (CS.TEMP_VALUE is from get random weapons)
			if(checkDefCont==9)
			then
				setTeamValue(GetHogTeamName(CurrentHedgehog), "rand-done-turn", false)
			elseif(checkDefCont==7)
			then
				--this will be set on the second turn
				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick")==nil)
				then
					setTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick", 1)
				end

				-- Antarctic summer
				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick")>=4)
				then
					CollectMultiAmmo(CurrentHedgehog, {[amPortalGun] = 1, [amSineGun] = 2, [amGirder] = 1, [amSnowball] = 1})
					setTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick", 0)
				end
				setTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick", getTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick")+1)

			elseif(checkDefCont==5)
			then
				--this will be set on the second turn
				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick")==nil)
				then
					setTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick", 1)
				end

				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick")>=2)
				then
					CollectMultiAmmo(CurrentHedgehog, {[amParachute] = 1})
					setTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick", 0)
				end
				setTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick", getTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick")+1)
			elseif(checkDefCont==1)
			then
				CS.TEMP_VALUE=0
				runOnGears(CountHogsInTeam)

				if(CS.TEMP_VALUE>1)
				then
					-- Enable switch hog on turn start (North America)
					EnableSwitchHog()
				end
			end

			ShowContinentInfo(currCont,-1,true)
			SetCSAmmoDescriptions("weapons")
		end
	end
end

function WeaponCaption(ammoType, customName)
	local caption
	if not customName then
		customName = GetAmmoName(ammoType)
	end
	local count = GetAmmoCount(CurrentHedgehog, ammoType)
	local timer = GetAmmoTimer(CurrentHedgehog, ammoType)
	local secs
	if type(timer) == "number" then
		secs = div(timer, 1000)
	end
	if count ~= 100 then
		strCount = tostring(count)
	end
	-- Finite count, timerable
	if type(timer) == "number" and count ~= 100 then
		-- e.g. “Grenade (5), 3 sec”
		caption = string.format(loc("%s (%d), %d sec"), customName, count, secs)
	-- Infinite count, timerable
	elseif type(timer) == "number" and count == 100 then
		-- e.g. “Grenade, 3 sec”
		caption = string.format(loc("%s, %d sec"), customName, secs)
	-- Finite count, non-timerable
	elseif type(timer) ~= "number" and count ~= 100 then
		-- e.g. “Bazooka (5)”
		caption = string.format(loc("%s (%d)"), customName, count)
	-- Infinite count, non-timerable
	else
		-- e.g. “Bazooka”
		caption = customName
	end

	AddCaption(caption, GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmoinfo)
end

function ShowSpecialWeaponCaption(ammoType)
	--place mine (australia)
	if(ammoType == amBaseballBat)
	then
		if(CS.AUSTRALIAN_SPECIAL==1)
		then
			WeaponCaption(amBaseballBat, CS.BASEBALLBAT_CRICKET_NAME)
		elseif(CS.AUSTRALIAN_SPECIAL==2)
		then
			WeaponCaption(amBaseballBat, CS.BASEBALLBAT_BOOMERANG_NAME)
		else
			WeaponCaption(amBaseballBat)
		end

	--africa
	elseif(ammoType == amSeduction)
	then
		if(CS.AFRICAN_SPECIAL_SEDUCTION==1)
		then
			WeaponCaption(amSeduction, CS.SEDUCTION_SPECIAL_NAME)
			AddCaption(string.format(CS.INVULNERABLE_SPECIAL_CAPTION, CS.SEDUCTION_INCREASER, GetAmmoCount(CurrentHedgehog,amInvulnerable)), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmostate)
		else
			WeaponCaption(amSeduction)
		end

	--south america
	elseif(ammoType == amGasBomb)
	then
		if(CS.SOUTH_AMERICAN_SPECIAL==true)
		then
			WeaponCaption(amGasBomb, CS.CHEESE_SPECIAL_NAME)
		else
			WeaponCaption(amGasBomb)
		end

	--africa
	elseif(ammoType == amSMine)
	then
		if(CS.AFRICAN_SPECIAL_STICKY==1)
		then
			WeaponCaption(amSMine, CS.STICKY_PROJECTILE_NAME)
		elseif(CS.AFRICAN_SPECIAL_STICKY == 2)
		then
			WeaponCaption(amSMine, CS.STICKY_NAPALM_NAME)
		else
			WeaponCaption(amSMine)
		end

	--north america (sniper)
	elseif(ammoType == amSniperRifle and CS.NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON==false)
	then
		if(CS.NORTH_AMERICAN_SPECIAL_SNIPER==1)
		then
			WeaponCaption(amSniperRifle)
		elseif(CS.NORTH_AMERICAN_SPECIAL_SNIPER==2)
		then
			WeaponCaption(amSniperRifle, CS.SNIPER_SPECIAL_NAME)
		end

	--north america (shotgun)
	elseif(ammoType == amShotgun)
	then
		if(CS.NORTH_AMERICAN_SPECIAL_SHOTGUN==true)
		then
			WeaponCaption(amShotgun, CS.SHOTGUN_SPECIAL_NAME)
		else
			WeaponCaption(amShotgun)
		end

	--europe
	elseif(ammoType == amMolotov)
	then
		if(CS.EUROPE_SPECIAL==1)
		then
			WeaponCaption(amMolotov, CS.MOLOTOV_SPECIAL_NAME)
		else
			WeaponCaption(amMolotov)
		end

	--antarctica
	elseif(ammoType == amPickHammer)
	then
		if(CS.ANTARCTICA_SPECIAL==1)
		then
			WeaponCaption(amPickHammer, CS.PICKHAMMER_SPECIAL_NAME)
		else
			WeaponCaption(amPickHammer)
		end

	--kerguelen
	elseif(ammoType == amHammer)
	then
		if(CS.KERGUELEN_SPECIAL==1)
		then
			WeaponCaption(amHammer)
		elseif(CS.KERGUELEN_SPECIAL==2)
		then
			WeaponCaption(amHammer, CS.HAMMER_ROAR_NAME)
		elseif(CS.KERGUELEN_SPECIAL==3)
		then
			WeaponCaption(amHammer, CS.HAMMER_SWAP_NAME)
		elseif(CS.KERGUELEN_SPECIAL==5)
		then
			WeaponCaption(amHammer, CS.HAMMER_LONELY_NAME)
		elseif(CS.KERGUELEN_SPECIAL==6)
		then
			WeaponCaption(amHammer, CS.HAMMER_SABOTAGE_NAME)
		end
	end
end

function onPrecise()
	CS.PRECISE = true
end
function onPreciseUp()
	CS.PRECISE = false
end

--what happens when you press "tab" (common button)
function onSwitch()

	if(CS.SWITCH_HOG_IS_ON==false)
	then
		if(CS.OPTION_NO_SPECIALS==false and CS.SELECT_CONTINENT_CHECK==false and
		band(GetState(CurrentHedgehog), gstAttacked) == 0 and
		band(GetState(CurrentHedgehog), gstHHDriven) ~= 0)
		then
			--place mine (australia)
			if(GetCurAmmoType() == amBaseballBat)
			then
				CS.AUSTRALIAN_SPECIAL = CS.AUSTRALIAN_SPECIAL + 1
				CS.AUSTRALIAN_SPECIAL = CS.AUSTRALIAN_SPECIAL % 3

				SetAttackState(CS.AUSTRALIAN_SPECIAL == 0)

			--Asian special
			elseif(CS.PARACHUTE_IS_ON==1)
			then
				local asiabomb=AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)+3, gtSnowball, 0, 0, 0, 0)
				SetGearMessage(asiabomb, 1)

				CS.PARACHUTE_IS_ON=2
				CS.SELECT_CONTINENT_CHECK=false

			--africa
			elseif(GetCurAmmoType() == amSeduction)
			then
				if(CS.AFRICAN_SPECIAL_SEDUCTION==0)
				then
					CS.AFRICAN_SPECIAL_SEDUCTION = 1
				else
					CS.AFRICAN_SPECIAL_SEDUCTION = 0
				end

			--south america
			elseif(GetCurAmmoType() == amGasBomb)
			then
				if(CS.SOUTH_AMERICAN_SPECIAL==false)
				then
					CS.SOUTH_AMERICAN_SPECIAL = true
				else
					CS.SOUTH_AMERICAN_SPECIAL = false
				end

			--africa
			elseif(GetCurAmmoType() == amSMine)
			then
				CS.AFRICAN_SPECIAL_STICKY = CS.AFRICAN_SPECIAL_STICKY + 1
				CS.AFRICAN_SPECIAL_STICKY = CS.AFRICAN_SPECIAL_STICKY % 3
				SetSoundMask(sndLaugh, CS.AFRICAN_SPECIAL_STICKY ~= 0)

			--north america (sniper)
			elseif(GetCurAmmoType() == amSniperRifle and CS.NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON==false)
			then
				if(CS.NORTH_AMERICAN_SPECIAL_SNIPER==2)
				then
					CS.NORTH_AMERICAN_SPECIAL_SNIPER = 1
				elseif(CS.NORTH_AMERICAN_SPECIAL_SNIPER==1)
				then
					CS.NORTH_AMERICAN_SPECIAL_SNIPER = 2
				end

			--north america (shotgun)
			elseif(GetCurAmmoType() == amShotgun)
			then
				if(CS.NORTH_AMERICAN_SPECIAL_SHOTGUN==false)
				then
					CS.NORTH_AMERICAN_SPECIAL_SHOTGUN = true
				else
					CS.NORTH_AMERICAN_SPECIAL_SHOTGUN = false
				end

			--europe
			elseif(GetCurAmmoType() == amMolotov)
			then
				if(CS.EUROPE_SPECIAL==0)
				then
					CS.EUROPE_SPECIAL = 1
				else
					CS.EUROPE_SPECIAL = 0
				end

			--antarctica
			elseif(GetCurAmmoType() == amPickHammer)
			then
				if(CS.ANTARCTICA_SPECIAL==0)
				then
					CS.ANTARCTICA_SPECIAL = 1
				else
					CS.ANTARCTICA_SPECIAL = 0
				end

			--kerguelen
			elseif(GetCurAmmoType() == amHammer)
			then
				if(CS.KERGUELEN_SPECIAL==6)
				then
					CS.KERGUELEN_SPECIAL = 1
				elseif(CS.KERGUELEN_SPECIAL==1)
				then
					CS.KERGUELEN_SPECIAL = 2
				elseif(CS.KERGUELEN_SPECIAL==2)
				then
					CS.KERGUELEN_SPECIAL = 3
				elseif(CS.KERGUELEN_SPECIAL==3)
				then
					CS.KERGUELEN_SPECIAL = 5
				elseif(CS.KERGUELEN_SPECIAL==5)
				then
					CS.KERGUELEN_SPECIAL = 6
				end
				SetAttackState(CS.KERGUELEN_SPECIAL == 1)
			end
			ShowSpecialWeaponCaption(GetCurAmmoType())
		end
		--for selecting weaponset, this is mostly for old players.
		-- Switch: Next continent
		-- Precise+Switch: Previous continent
		TrySelectNextContinent(CS.PRECISE)
	--if switching out from sabotage.
	elseif(CS.SABOTAGE_HOGS[CurrentHedgehog]~=nil and CS.SABOTAGE_HOGS[CurrentHedgehog]==2)
	then
		CS.SABOTAGE_HOGS[CurrentHedgehog]=1
	end
end

function TrySelectNextContinent(reverse)
	local direction = 1
	if reverse then
		direction = -1
	end
	if(GetHogLevel(CurrentHedgehog)==0 and CS.SELECT_CONTINENT_CHECK==true and (GetCurAmmoType() == amSkip or GetCurAmmoType() == amNothing))
	then
		CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)] + direction

		if(CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]> #CS.CONTINENT_INFORMATION)
		then
			CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=1
		end
		if(CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]<=0)
		then
			CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)] = #CS.CONTINENT_INFORMATION
		end
		SetContinentWeapons()

		PlaySound(sndSwitchHog)
	end
end

function onUp()
	--swap forward in the weaponmenu (1.0 style)
	TrySelectNextContinent(false)

	if(GetCurAmmoType() == amSeduction and CS.AFRICAN_SPECIAL_SEDUCTION == 1 and GetAmmoCount(CurrentHedgehog,amInvulnerable)>0)
	then
		CS.SEDUCTION_INCREASER=CS.SEDUCTION_INCREASER+7

		RemoveWeapon(CurrentHedgehog,amInvulnerable)

		AddCaption(string.format(CS.INVULNERABLE_SPECIAL_CAPTION, CS.SEDUCTION_INCREASER, GetAmmoCount(CurrentHedgehog,amInvulnerable)), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmostate)
	end
end

function onDown()
	--swap backwards in the weaponmenu (1.0 style)
	TrySelectNextContinent(true)

	if(GetCurAmmoType() == amSeduction and CS.AFRICAN_SPECIAL_SEDUCTION == 1 and CS.SEDUCTION_INCREASER>0)
	then
		CS.SEDUCTION_INCREASER=CS.SEDUCTION_INCREASER-7

		AddAmmo(CurrentHedgehog,amInvulnerable,GetAmmoCount(CurrentHedgehog, amInvulnerable)+1)

		AddCaption(string.format(CS.INVULNERABLE_SPECIAL_CAPTION, CS.SEDUCTION_INCREASER, GetAmmoCount(CurrentHedgehog,amInvulnerable)), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmostate)
	end
end

-- Spawn sabotage smoke for inactive hogs (red smoke, more subtle than for active hogs)
function SabotageSmokeInactive(gear)
	if GetGearType(gear) == gtHedgehog and (gear ~= CurrentHedgehog or ReadyTimeLeft > 0) and CS.SABOTAGE_HOGS[gear]~=nil and CS.SABOTAGE_HOGS[gear]>=1 then
		local vg = AddVisualGear(GetX(gear), GetY(gear), vgtSmokeWhite, 0, false)
		SetVisualGearValues(vg, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0xFF8080B0)
	end
end

function ShowContinentLabel(continent)
	if not continent then
		continent = CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]
	end
	if continent == 0 then
		AddCaption(loc("Random continent"), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmoinfo)
	else
		AddCaption(CS.CONTINENT_INFORMATION[CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]][1], GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmoinfo)
	end
end

function onGameTick()
	-- This is a trick to show the continent label delayed by 1 tick
	if CS.CONTINENT_LABEL_TIMER > 0 then
		CS.CONTINENT_LABEL_TIMER = CS.CONTINENT_LABEL_TIMER - 1
	end
	if CS.CONTINENT_LABEL_TIMER == 0 then
		ShowContinentLabel()
		CS.CONTINENT_LABEL_TIMER = -1
	end

	if CS.HANDLE_SPECIAL_WEAPON_MISC_TIMER > 0 then
		CS.HANDLE_SPECIAL_WEAPON_MISC_TIMER = CS.HANDLE_SPECIAL_WEAPON_MISC_TIMER - 1
	end
	if CS.HANDLE_SPECIAL_WEAPON_MISC_TIMER == 0 then
		HandleSpecialWeaponMisc()
		CS.HANDLE_SPECIAL_WEAPON_MISC_TIMER = -1
	end

	if CS.HANDLE_SOUTH_AMERICAN_SPECIAL_TIMER > 0 then
		CS.HANDLE_SOUTH_AMERICAN_SPECIAL_TIMER = CS.HANDLE_SOUTH_AMERICAN_SPECIAL_TIMER - 1
	end
	if CS.HANDLE_SOUTH_AMERICAN_SPECIAL_TIMER == 0 then
		WeaponCaption(amGasBomb, CS.CHEESE_SPECIAL_NAME)
		CS.HANDLE_SOUTH_AMERICAN_SPECIAL_TIMER = -1
	end


	-- See onAttack()
	if CS.CONFIRM_CONTINENT_SELECTION > 0 then
		CS.CONFIRM_CONTINENT_SELECTION = CS.CONFIRM_CONTINENT_SELECTION - 1
	end
	if CS.CONFIRM_CONTINENT_SELECTION == 0 then
		CS.SELECT_CONTINENT_CHECK=false
		EndTurnCS(0)
		PlaySound(sndPlaced)
		if(CurrentHedgehog and CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==0)
		then
			CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=GetRandom(#CS.CONTINENT_INFORMATION)+1
			SetContinentWeapons()
			HideMission()
			ShowContinentLabel(0)
		else
			ShowContinentLabel()
		end
		CS.CONFIRM_CONTINENT_SELECTION = -1
	end

	if GameTime % 600 == 0 then
		runOnGears(SabotageSmokeInactive)
	end
end

function onGameTick20()
	--if you picked a weaponset from the weaponmenu (icon)
	if(CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==0)
	then
		if(GetCurAmmoType()==amSwitch)
		then
			CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=GetRandom(#CS.CONTINENT_INFORMATION)+1
			SetContinentWeapons()
			SetWeapon(amSkip)
			PlaySound(sndMineTick)
			CS.CONTINENT_LABEL_TIMER = 1
		else
			for v,w in pairs(CS.CONTINENT_INFORMATION)
			do
				if(GetCurAmmoType()==CS.CONTINENT_INFORMATION[v][4][1])
				then
					CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=v
					SetContinentWeapons()
					SetWeapon(amSkip)
					PlaySound(CS.CONTINENT_INFORMATION[v][6][1])
					PlaySound(CS.CONTINENT_INFORMATION[v][6][2],CurrentHedgehog)
					CS.CONTINENT_LABEL_TIMER = 1
					break
				end
			end
		end
	end

	--show the kerguelen ring
	if(CS.KERGUELEN_SPECIAL > 1 and GetCurAmmoType() == amHammer and
		band(GetState(CurrentHedgehog), gstAttacked) == 0 and
		band(GetState(CurrentHedgehog), gstHHDriven) ~= 0)
	then
		if(CS.VISUAL_CIRCLE==nil)
		then
			CS.VISUAL_CIRCLE=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtCircle, 0, true)
		end

		if(CS.KERGUELEN_SPECIAL == 2) --walrus scream
		then
			SetVisualGearValues(CS.VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 120, 4, 0xff0000ee)
		elseif(CS.KERGUELEN_SPECIAL == 3) --swap hog
		then
			SetVisualGearValues(CS.VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 390, 3, 0xffff00ee)
		elseif(CS.KERGUELEN_SPECIAL == 5) --cries
		then

			CS.TEMP_VALUE=0
			runOnGears(KerguelenSpecialBlueCheck)
			if(CS.TEMP_VALUE==0)
			then
				SetVisualGearValues(CS.VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 500, 1, 0x0000ffee)
			else
				SetVisualGearValues(CS.VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 500, 10, 0x0000ffee)
			end

		elseif(CS.KERGUELEN_SPECIAL == 6) --sabotage
		then
			SetVisualGearValues(CS.VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 80, 10, 0x00ff00ee)
		end

	elseif(CS.VISUAL_CIRCLE~=nil)
	then
		DeleteVisualGear(CS.VISUAL_CIRCLE)
		CS.VISUAL_CIRCLE=nil
	end

	--sabotage
	if(CS.SABOTAGE_HOGS[CurrentHedgehog]~=nil and CS.SABOTAGE_HOGS[CurrentHedgehog]>=1)
	then
		--for sabotage
		if(CS.SABOTAGE_HOGS[CurrentHedgehog]==1 and ReadyTimeLeft == 0)
		then
			AddCaption(loc("You are sabotaged, RUN!"))

			PlaySound(sndHellish)
			--update the constant at the top also to something in between
			CS.SABOTAGE_FREQUENCY_NOW=CS.SABOTAGE_FREQUENCY
			SetGravity(CS.SABOTAGE_GRAVITY)

			CS.SABOTAGE_HOGS[CurrentHedgehog]=2
		end

		if(CS.SABOTAGE_HOGS[CurrentHedgehog]==2 and CS.SABOTAGE_COUNTER % 20 == 0)
		then
			-- Sabotage effect (red smoke)
			local vg = AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmokeWhite, 0, false)
			SetVisualGearValues(vg, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0xFF4040FF)
		end

		if(TurnTimeLeft<(GetAwayTime*10) or band(GetState(CurrentHedgehog),gstAttacked)==1)
		then
			CS.SABOTAGE_HOGS[CurrentHedgehog]=0
		elseif(CS.SABOTAGE_COUNTER >= CS.SABOTAGE_FREQUENCY_NOW)
		then
			-- Sabotage decreases hog health regularily,
			-- but invulnerable protects.
			-- Also do not decrease health while retreating, attacking or in ready phase.
			if(GetEffect(CurrentHedgehog, heInvulnerable) == 0 and
			band(GetState(CurrentHedgehog), gstHHDriven) ~= 0 and
			band(GetState(CurrentHedgehog), gstAttacked+gstAttacking) == 0) and
			(ReadyTimeLeft == 0)
			then
				if(GetHealth(CurrentHedgehog)<=CS.SABOTAGE_DAMAGE)
				then
					-- All health lost! Sabotage is cruel.
					PlaySound(sndPoisonMoan, CurrentHedgehog)
					SetHealth(CurrentHedgehog, 0)
					CS.SABOTAGE_HOGS[CurrentHedgehog]=0
					-- Take away control so the hog can die in peace.
					SetState(CurrentHedgehog, band(GetState(CurrentHedgehog), bnot(gstHHDriven)))
				else
					local newHealth = GetHealth(CurrentHedgehog)-CS.SABOTAGE_DAMAGE
					-- Start moaning if health is at a critical level
					if newHealth <= 16 then
						PlaySound(sndPoisonMoan, CurrentHedgehog)
					elseif newHealth <= 32 then
						PlaySound(sndPoisonCough, CurrentHedgehog)
					end
					SetHealth(CurrentHedgehog, newHealth)
				end
				ShowDamageTag(CurrentHedgehog,CS.SABOTAGE_DAMAGE)
			end

			CS.SABOTAGE_COUNTER=0
		else
			CS.SABOTAGE_COUNTER=CS.SABOTAGE_COUNTER+1
		end
	elseif((GetGravity()==CS.SABOTAGE_GRAVITY or GetGravity()==CS.SABOTAGE_GRAVITY_LOW) and (CS.SABOTAGE_HOGS[CurrentHedgehog]==0 or CS.SABOTAGE_HOGS[CurrentHedgehog]==nil))
	then
		-- Reset gravity
		SetGravity(100)
	end

	if(CS.SPEECH_TIMER > 0) then
		CS.SPEECH_TIMER = CS.SPEECH_TIMER - 20
	end
end

function HandleSpecialWeaponMisc(ammoType)
	if not ammoType then
		ammoType = GetCurAmmoType()
	end
	ShowSpecialWeaponCaption(ammoType)
	if ammoType == amSMine and CS.AFRICAN_SPECIAL_STICKY ~= 0 then
		SetSoundMask(sndLaugh, true)
	else
		SetSoundMask(sndLaugh, false)
	end
	if (ammoType == amHammer and CS.KERGUELEN_SPECIAL > 1) or (ammoType == amBaseballBat and CS.AUSTRALIAN_SPECIAL ~= 0) then
		SetAttackState(false)
	else
		SetAttackState(true)
	end

end

--some ppl complained :P
function onSlot(slot)
	if(CS.TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==0)
	then
		SetWeapon(amSkip)
	end
	if CS.GAME_STARTED then
		-- Delay calling HandleSpecialWeaponMisc because
		-- the CurAmmoType is not updated yet.
		CS.HANDLE_SPECIAL_WEAPON_MISC_TIMER = 2
	end
end

function onSetWeapon(ammoType)
	if CS.GAME_STARTED then
		HandleSpecialWeaponMisc(ammoType)
	end
end

--if you used hogswitch or any similar weapon, dont enable any weaponchange
function onAttack()
	if(CS.SELECT_CONTINENT_CHECK==true)
	then
		if(GetCurAmmoType() == amSkip or GetCurAmmoType() == amNothing)
		then
			SetWeapon(amNothing)
			-- Delay the real continent selection so the SetWeapon
			-- has time to take effect.
			CS.CONFIRM_CONTINENT_SELECTION=2
		else
			SetWeapon(amSkip)
		end
	end

	--african special
	if(CS.AFRICAN_SPECIAL_SEDUCTION == 1 and GetCurAmmoType() == amSeduction and band(GetState(CurrentHedgehog),gstAttacked)==0)
	then
		EndTurnCS(3)

		CS.TEMP_VALUE=0
		runOnGears(AfricaSpecialSeduction)
		SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+CS.TEMP_VALUE)

		--visual stuff
		VisualExplosion(250,GetX(CurrentHedgehog), GetY(CurrentHedgehog),vgtSmoke,vgtSmokeWhite)
		PlaySound(sndParachute)

		RemoveWeapon(CurrentHedgehog,amSeduction)

	elseif(CS.ANTARCTICA_SPECIAL == 1 and GetCurAmmoType() == amPickHammer and band(GetState(CurrentHedgehog),gstAttacked)==0)
	then
		EndTurnCS(10)
		local dx, dy = GetGearVelocity(CurrentHedgehog)
		local isLeft = dx < 0
		-- Cave map / map has border
		if not MapHasBorder() then
			-- Place hog at Y = 0
			SetGearPosition(CurrentHedgehog, GetX(CurrentHedgehog), 0)
			ParseCommand("hjump")
			SetGearVelocity(CurrentHedgehog, 0, 100000000)

		-- Open air map
		else
			-- Place hog just below the top border, erase a bit of land as well
			local x = GetX(CurrentHedgehog)
			Explode(x, TopY + 6, 32, EXPLNoDamage + EXPLDoNotTouchAny + EXPLNoGfx)
			Explode(x, TopY + 20, 24, EXPLNoDamage + EXPLDoNotTouchAny)
			SetGearPosition(CurrentHedgehog, x, TopY + 26)
			local dx, dy = GetGearVelocity(CurrentHedgehog)
			SetGearVelocity(CurrentHedgehog, 0, dy)
			ParseCommand("hjump")
		end
		if isLeft then
			HogTurnLeft(CurrentHedgehog, true)
		end
		PlaySound(sndPiano8)
		PlaySound(sndWarp)

		RemoveWeapon(CurrentHedgehog,amPickHammer)

	--Kerguelen specials
	elseif(GetCurAmmoType() == amHammer and CS.KERGUELEN_SPECIAL > 1 and band(GetState(CurrentHedgehog),gstAttacked)==0)
	then
		local escapetime=3

		--scream
		if(CS.KERGUELEN_SPECIAL == 2)
		then
			CS.TEMP_VALUE=0
			runOnGears(KerguelenSpecialRed)
			HealHog(CurrentHedgehog, CS.TEMP_VALUE)
			PlaySound(sndHellish)

		--swap
		elseif(CS.KERGUELEN_SPECIAL == 3)
		then
			CS.TEMP_VALUE=0
			runOnGears(KerguelenSpecialYellowCountHogs)
			if(CS.TEMP_VALUE>0)
			then
				CS.TEMP_VALUE=GetRandom(CS.TEMP_VALUE)
				runOnGears(KerguelenSpecialYellowSwap)
				PlaySound(sndPiano3)
			else
				PlaySound(sndPiano6)
			end

		--cries
		elseif(CS.KERGUELEN_SPECIAL == 5)
		then
			CS.TEMP_VALUE=0
			runOnGears(KerguelenSpecialBlueCheck)
			if(CS.TEMP_VALUE==0)
			then
				AddGear(0, 0, gtWaterUp, 0, 0,0,0)
				PlaySound(sndWarp)
				PlaySound(sndMolotov)

				runOnGears(KerguelenSpecialBlueActivate)
				SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+CS.TEMP_VALUE)
			else
				PlaySound(sndDenied)
				escapetime = -1
				if CS.SPEECH_TIMER <= 0 then
					HogSay(CurrentHedgehog, loc("Hogs in sight!"), SAY_SAY)
					CS.SPEECH_TIMER = 5000
				end
			end

		--flare/sabotage
		elseif(CS.KERGUELEN_SPECIAL == 6)
		then
			CS.TEMP_VALUE=0
			runOnGears(KerguelenSpecialGreen)

			PlaySound(sndThrowRelease)
			AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-20, gtCluster, 0, 0, -1000000, 32)

			if(CS.TEMP_VALUE==1)
			then
				escapetime=10
			end
		end

		if escapetime >= 0 then
			EndTurnCS(escapetime)

			DeleteVisualGear(CS.VISUAL_CIRCLE)
			CS.VISUAL_CIRCLE=nil
			CS.KERGUELEN_SPECIAL=0

			RemoveWeapon(CurrentHedgehog,amHammer)
		end

	elseif(GetCurAmmoType() == amBaseballBat)
	then
		if CS.AUSTRALIAN_SPECIAL ~= 0
		then
			CS.TEMP_VALUE=0
			runOnGears(AustraliaSpecialCheckHogs)
			if CS.TEMP_VALUE == 0 then
				SetGearMessage(CurrentHedgehog, bor(GetGearMessage(CurrentHedgehog), gmAttack))
			else
				PlaySound(sndDenied)
			end
		end

	elseif(GetCurAmmoType() == amVampiric)
	then
		CS.VAMPIRIC_IS_ON=75
	elseif(GetCurAmmoType() == amExtraDamage)
	then
		CS.EXTRA_DAMAGE_IS_ON=150
	end
end

function onTimer()
	-- This hack makes sure the correct weapon label + timer is displayed for the GasBomb special
	if GetCurAmmoType() == amGasBomb and (CS.SOUTH_AMERICAN_SPECIAL==true) then
		CS.HANDLE_SOUTH_AMERICAN_SPECIAL_TIMER = 2
	end
end

function onHogAttack(ammoType)
	-- When a sabotaged hog uses low gravity, overwrite the default low gravity,
	-- otherwise it would be too easy.
	if(ammoType == amLowGravity and CS.SABOTAGE_HOGS[CurrentHedgehog]~=nil and CS.SABOTAGE_HOGS[CurrentHedgehog]>=1)
	then
		SetGravity(CS.SABOTAGE_GRAVITY_LOW)
	end
end

function onGearAdd(gearUid)
	CS.SELECT_CONTINENT_CHECK=false

	--track the gears im using
	if(GetGearType(gearUid) == gtHedgehog or GetGearType(gearUid) == gtMine or GetGearType(gearUid) == gtExplosives)
	then
		trackGear(gearUid)
	end

	--remove gasclouds on gasbombspecial
	if(GetGearType(gearUid)==gtPoisonCloud and CS.SOUTH_AMERICAN_SPECIAL == true)
	then
		DeleteGear(gearUid)
	--african special
	elseif(GetGearType(gearUid)==gtSMine)
	then
		local vx,vy=GetGearVelocity(gearUid)
		if(CS.AFRICAN_SPECIAL_STICKY == 1)
		then
			SetState(CurrentHedgehog, gstHHDriven+gstMoving)
			SetGearPosition(CurrentHedgehog, GetX(CurrentHedgehog),GetY(CurrentHedgehog)-3)
			SetGearVelocity(CurrentHedgehog, vx, vy)
			PlaySound(sndJump2, CurrentHedgehog)
			DeleteGear(gearUid)
			if (not CS.AFRICAN_SPECIAL_NON_PROJECTILE_USED) then
				SetSoundMask(sndMissed, true)
			end

		elseif(CS.AFRICAN_SPECIAL_STICKY == 2)
		then
			FireGear(CurrentHedgehog,gtNapalmBomb, vx, vy, 0)
			DeleteGear(gearUid)
			CS.AFRICAN_SPECIAL_NON_PROJECTILE_USED=true
			SetSoundMask(sndMissed, false)
		else
			CS.AFRICAN_SPECIAL_NON_PROJECTILE_USED=true
			SetSoundMask(sndMissed, false)
		end
	--north american special
	elseif(GetGearType(gearUid)==gtSniperRifleShot)
	then
		CS.NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON=true
		if(CS.NORTH_AMERICAN_SPECIAL_SNIPER~=1)
		then
			SetHealth(gearUid, 1)
			SetGearValues(gearUid, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 0)
		end
	--north american special
	elseif(GetGearType(gearUid)==gtShotgunShot)
	then
		if(CS.NORTH_AMERICAN_SPECIAL_SHOTGUN==true)
		then
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtFeather, 0, false)
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtFeather, 0, false)
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtFeather, 0, false)
			PlaySound(sndBirdyLay)
		end
	--european special
	elseif(GetGearType(gearUid)==gtMolotov and CS.EUROPE_SPECIAL==1)
	then
		local vx,vy=GetGearVelocity(gearUid)
		local e_health=FireGear(CurrentHedgehog,gtCluster, vx, vy, 1)
		SetGearMessage(e_health, 2)
		DeleteGear(gearUid)
	--australian specials
	elseif(GetGearType(gearUid)==gtShover and CS.AUSTRALIAN_SPECIAL~=0)
	then
		CS.TEMP_VALUE=0
		runOnGears(AustraliaSpecialCheckHogs)

		if(CS.TEMP_VALUE==0)
		then
			local vx,vy=GetGearVelocity(gearUid)

			if(CS.AUSTRALIAN_SPECIAL==1)
			then
				local austmine=FireGear(CurrentHedgehog,gtMine, vx, vy, 0)
				SetHealth(austmine, 100)
				SetTimer(austmine, 1000)
				PlaySound(sndLaugh, CurrentHedgehog)
			else
				local austmine=FireGear(CurrentHedgehog,gtBall, vx, vy, 1)
				SetTimer(austmine, 1000)
				SetGearMessage(austmine, 3)
			end
		else
			PlaySound(sndDenied)
		end
	elseif(GetGearType(gearUid)==gtParachute)
	then
		CS.PARACHUTE_IS_ON=1
	elseif(GetGearType(gearUid)==gtSwitcher)
	then
		CS.SWITCH_HOG_IS_ON=true
	end
end

function onGearDamage(gearUid, damage)
	if(gearUid==CurrentHedgehog and CS.SABOTAGE_HOGS[CurrentHedgehog]==1)
	then
		CS.SABOTAGE_HOGS[CurrentHedgehog]=0
	end
end

function onGearDelete(gearUid)

	if(GetGearType(gearUid) == gtHedgehog or GetGearType(gearUid) == gtMine or GetGearType(gearUid) == gtExplosives)
	then
		--sundaland special
		if(GetGearType(gearUid) == gtHedgehog and CS.TEAM_CONTINENT[CS.SUNDALAND_END_HOG_CONTINENT_NAME]==10)
		then
			local currvalue=getTeamValue(CS.SUNDALAND_END_HOG_CONTINENT_NAME, "sundaland-count")

			if(currvalue==nil)
			then
				currvalue=0
			end

			setTeamValue(CS.SUNDALAND_END_HOG_CONTINENT_NAME, "sundaland-count", currvalue+1)
		end

		trackDeletion(gearUid)
	end

	--if picking up a health crate, heal sabotage
	if(CS.SABOTAGE_HOGS[CurrentHedgehog]~=0 and GetGearType(gearUid) == gtCase and GetGearPos(gearUid)==2 and band(GetGearMessage(gearUid), gmDestroy) ~= 0)
	then
		CS.SABOTAGE_HOGS[CurrentHedgehog]=0
	end

	--north american lipstick
	if(GetGearType(gearUid)==gtSniperRifleShot )
	then
		CS.NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON=false
		if(CS.NORTH_AMERICAN_SPECIAL_SNIPER==2)
		then
			CS.TEMP_VALUE=gearUid
			runOnGears(NorthAmericaSpecialSniper)
		end
	--north american eagle eye
	elseif(GetGearType(gearUid)==gtShotgunShot and CS.NORTH_AMERICAN_SPECIAL_SHOTGUN==true)
	then
		SetGearPosition(CurrentHedgehog, GetX(gearUid), GetY(gearUid)+7)
		PlaySound(sndWarp)
	--south american special
	elseif(GetGearType(gearUid)==gtGasBomb and CS.SOUTH_AMERICAN_SPECIAL == true)
	then
		if band(GetState(gearUid), gstDrowning) == 0 then
			CS.TEMP_VALUE=gearUid
			runOnGears(SouthAmericaSpecialCheeseExplosion)
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtExplosion, 0, false)
		end

	--asian special
	elseif(GetGearType(gearUid)==gtSnowball and GetGearMessage(gearUid)==1)
	then
		AddGear(GetX(gearUid), GetY(gearUid), gtCluster, 0, 0, 0, 22)

	--europe special
	elseif(GetGearType(gearUid)==gtCluster and GetGearMessage(gearUid)==2)
	then
		if band(GetState(gearUid), gstDrowning) == 0 then
			CS.TEMP_VALUE=gearUid
			runOnGears(EuropeSpecialMolotovHit)
			VisualExplosion(100,GetX(gearUid), GetY(gearUid),vgtSmokeWhite,vgtSmokeWhite)
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtExplosion, 0, false)
			PlaySound(sndGraveImpact)
		end
	--australian special
	elseif(GetGearType(gearUid)==gtBall and GetGearMessage(gearUid)==3)
	then
		if band(GetState(gearUid), gstDrowning) == 0 then
			SpawnRandomCrate(GetX(gearUid), GetY(gearUid))
		end

	--asia (using para)
	elseif(GetGearType(gearUid)==gtParachute)
	then
		CS.PARACHUTE_IS_ON=false
	elseif(GetGearType(gearUid)==gtSwitcher)
	then
		CS.SWITCH_HOG_IS_ON=false
	end
end


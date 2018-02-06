--[[
	version 1.3n

	The expat (MIT) license

	Copyright (C) 2012 Vatten

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

--approximative version of square root. This function follows the babylonian method.
function IntegerSqrt(num)
	local temp=num
	while(temp*temp-div(temp,2)>num)
	do
		temp=div((temp+div(num,temp)),2)
	end

	return math.abs(temp)
end

-- sqrt(x^2,y^2), work without desyncs. is approximative
function Norm(xx,yy)
	--to fix overflows
	if(((math.abs(xx)^2)+(math.abs(yy)^2))>2^26)
	then
		local bitr=2^13
		return IntegerSqrt((div(math.abs(xx),bitr)^2)+(div(math.abs(yy),bitr)^2))*bitr
	else
		return IntegerSqrt((math.abs(xx)^2)+(math.abs(yy)^2))
	end
end

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
function EndTurn()
	SetState(CurrentHedgehog,bor(GetState(CurrentHedgehog),gstAttacked))
	--3 sec espace time
	TurnTimeLeft = GetAwayTime*10*3
 end

 --show health tag (will mostly be used when a hog is damaged)
function ShowDamageTag(hog,damage)
	healthtag=AddVisualGear(GetX(hog), GetY(hog), vgtHealthTag, damage, false)
	v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 = GetVisualGearValues(healthtag)
	SetVisualGearValues(healthtag, v1, v2, v3, v4, v5, v6, v7, v8, v9, GetClanColor(GetHogClan(hog)))
end

--will use IntegerSqrt
function FireGear(hedgehog,geartype,vx,vy,timer)
	local hypo=Norm(vx,vy)
	return AddGear(div((GetGearRadius(hedgehog)*2*vx),hypo)+GetX(hedgehog), div((GetGearRadius(hedgehog)*2*vy),hypo)+GetY(hedgehog), geartype, 0, vx, vy, timer)
end

--This function will set the gravity on a scale from 0->100, where 50 is the standard one.
 function SetGravityFromScale(grav)
	if(grav>100)
	then
		grav=100
	elseif(grav<0)
	then
		grav=0
	end

	if(grav>50)
	then
		SetGravity(100+((grav-50)*12))
	else
		SetGravity(25+grav+div(grav,2))
	end
 end

--====MISC GLOBALS====

--for selecting continent
local GLOBAL_INIT_TEAMS = {}
local GLOBAL_SELECT_CONTINENT_CHECK=false
local GLOBAL_TEAM_CONTINENT = {}

--variables for seeing if you have swaped around on a weapon
local GLOBAL_AUSTRALIAN_SPECIAL=0
local GLOBAL_AFRICAN_SPECIAL_SEDUCTION=0
local GLOBAL_AFRICAN_SPECIAL_STICKY=0
local GLOBAL_SOUTH_AMERICAN_SPECIAL=false
local GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER=1
local GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON=false
local GLOBAL_KERGUELEN_SPECIAL=1
local GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN=false
local GLOBAL_EUROPE_SPECIAL=0

--detection if something is activated
local GLOBAL_SWITCH_HOG_IS_ON=false
local GLOBAL_VAMPIRIC_IS_ON=0
local GLOBAL_EXTRA_DAMAGE_IS_ON=100
local GLOBAL_PARACHUTE_IS_ON=false

--the visual circle for kerguelen
local GLOBAL_VISUAL_CIRCLE=nil

--the global temp value
local GLOBAL_TEMP_VALUE=0

--for sabotage
local GLOBAL_SABOTAGE_COUNTER=0
local GLOBAL_SABOTAGE_HOGS={}
local GLOBAL_SABOTAGE_FREQUENCY=0
local GLOBAL_SABOTAGE_GRAVITY_SWITCH=true

--for sundaland
local GLOBAL_SUNDALAND_END_HOG=0

--====GENERAL GLOBALS (useful for handling continents)====

local GLOBAL_GENERAL_INFORMATION="- "..loc("Per team weapons").."|- "..loc("10 weapon schemes").."|- "..loc("Unique new weapons").."| |"..loc("Select your continent/weaponset: with the \"Up\" or \"Down\" keys. You can also select one with the weapons menu.").."|"..string.format(loc("Note: Some weapons have a second option (See continent information). Find and use them with the \"%s\" key."), loc("switch")).."|"..loc("Tip: See the \"Esc\" key (this menu) if you want to see the currently playing teams continent, or that continents specials.")

local GLOBAL_SHOW_SMALL_INFO=0

local GLOBAL_WEAPON_TEXTS = {
loc("Green lipstick bullet: [Poisonous, deals no damage]"),
loc("Cluck-cluck time: [Fire an egg ~ Sabotages and cures poison ~ Cannot be fired close to another hog]"),
loc("Anno 1032: [The explosion will make a strong push ~ Wide range, wont affect hogs close to the target]"),
loc("Dust storm: [Deals 15 damage to all enemies in the circle]"),
loc("Cricket time: [Fire away a 1 sec mine! ~ Cannot be fired close to another hog]"),
loc("Drop a bomb: [Drop some heroic wind that will turn into a bomb on impact]"),
loc("Penguin roar: [Deal 15 damage + 10% of your hog’s health to all hogs around you and get 2/3 back]"),
loc("Disguise as a Rockhopper Penguin: [Swap place with a random enemy hog in the circle]"),
nil,
loc("Lonely Cries: [Rise the water if no hog is in the circle and deal 6 damage to all enemy hogs.]"),
loc("Hedgehog projectile: [Fire your hog like a Sticky Bomb]"),
loc("Napalm rocket: [Fire a bomb with napalm!]"),
loc("Eagle Eye: [Blink to the impact ~ One shot]"),
loc("Medicine: [Fire some exploding medicine that will heal all hogs effected by the explosion]"),
loc("Sabotage/Flare: [Sabotage all hogs in the circle and deal ~1 dmg OR Fire a cluster up into the air]")
}

local GLOBAL_CONTINENT_INFORMATION =
{
{loc("North America"),"["..loc("Difficulty: ")..loc("EASY").."] "..loc("Area")..": 24,709,000 km2, "..loc("Population")..": 529,000,000",loc("- You can switch between hogs at the start of your turns. (Not first one)").."|"..loc("Special Weapons:").."|"..loc("Shotgun")..": "..GLOBAL_WEAPON_TEXTS[13].."|"..loc("Sniper Rifle")..": "..GLOBAL_WEAPON_TEXTS[1],amSniperRifle,
{{amShotgun,100},{amDEagle,100},{amLaserSight,2},{amSniperRifle,100},{amCake,1},{amAirAttack,2},{amSwitch,2}}},

{loc("South America"),"["..loc("Difficulty: ")..loc("MEDIUM").."] "..loc("Area")..": 17,840,000 km2, "..loc("Population")..": 387,000,000",loc("Special Weapons:").."|"..loc("GasBomb")..": "..GLOBAL_WEAPON_TEXTS[3],amGasBomb,
{{amBirdy,100},{amHellishBomb,1},{amBee,100},{amGasBomb,100},{amFlamethrower,100},{amNapalm,1},{amExtraDamage,2}}},

{loc("Europe"),"["..loc("Difficulty: ")..loc("EASY").."] "..loc("Area")..": 10,180,000 km2, "..loc("Population")..": 740,000,000",loc("Special Weapons:").."|"..loc("Molotov")..": "..GLOBAL_WEAPON_TEXTS[14],amBazooka,
{{amBazooka,100},{amGrenade,100},{amMortar,100},{amMolotov,100},{amVampiric,3},{amPiano,1},{amResurrector,2},{amJetpack,4}}},

{loc("Africa"),"["..loc("Difficulty: ")..loc("MEDIUM").."] "..loc("Area")..": 30,222,000 km2, "..loc("Population")..": 1,033,000,000",loc("Special Weapons:").."|"..loc("Seduction")..": "..GLOBAL_WEAPON_TEXTS[4].."|"..loc("Sticky Mine")..": "..GLOBAL_WEAPON_TEXTS[11].."|"..loc("Sticky Mine")..": "..GLOBAL_WEAPON_TEXTS[12],amSMine,
{{amSMine,100},{amWatermelon,1},{amDrillStrike,1},{amDrill,100},{amInvulnerable,5},{amSeduction,100},{amLandGun,2}}},

{loc("Asia"),"["..loc("Difficulty: ")..loc("MEDIUM").."] "..loc("Area")..": 44,579,000 km2, "..loc("Population")..": 3,880,000,000",loc("- Will give you a parachute every second turn.").."|"..loc("Special Weapons:").."|"..loc("Parachute")..": "..GLOBAL_WEAPON_TEXTS[6],amRope,
{{amRope,100},{amFirePunch,100},{amParachute,2},{amKnife,2},{amDynamite,1}}},

{loc("Australia"),"["..loc("Difficulty: ")..loc("EASY").."] "..loc("Area")..": 8,468,000 km2, "..loc("Population")..": 31,000,000",loc("Special Weapons:").."|"..loc("Baseballbat")..": "..GLOBAL_WEAPON_TEXTS[5].."|"..loc("Baseballbat")..": "..GLOBAL_WEAPON_TEXTS[2],amBaseballBat,
{{amBaseballBat,100},{amMine,100},{amLowGravity,4},{amBlowTorch,100},{amRCPlane,2},{amTeleport,2},{amRubber,2}}},

{loc("Antarctica"),"["..loc("Difficulty: ")..loc("HARD").."] "..loc("Area")..": 14,000,000 km2, "..loc("Population")..": ~1,000",loc("Antarctic summer: - Will give you one girder/mudball and two sineguns/portals every fourth turn."),amIceGun,
{{amSnowball,2},{amIceGun,2},{amPickHammer,100},{amSineGun,5},{amGirder,2},{amExtraTime,1},{amPortalGun,2}}},

{loc("Kerguelen"),"["..loc("Difficulty: ")..loc("EASY").."] "..loc("Area")..": 1,100,000 km2, "..loc("Population")..": ~100",loc("Special Weapons:").."|"..loc("Hammer")..": "..GLOBAL_WEAPON_TEXTS[7].."|"..loc("Hammer")..": "..GLOBAL_WEAPON_TEXTS[8].." ("..loc("Duration")..": 2)|"..loc("Hammer")..": "..GLOBAL_WEAPON_TEXTS[10].."|"..loc("Hammer")..": "..GLOBAL_WEAPON_TEXTS[15],amHammer,
{{amHammer,100},{amMineStrike,1},{amBallgun,1}}},

{loc("Zealandia"),"["..loc("Difficulty: ")..loc("MEDIUM").."] "..loc("Area")..": 3,500,000 km2, "..loc("Population")..": 5,000,000",loc("- Will get 1-3 random weapons") .. "|" .. loc("- Massive weapon bonus on first turn"),amInvulnerable,
{{amBazooka,1},{amGrenade,1},{amBlowTorch,1},{amSwitch,100},{amRope,1},{amDrill,1},{amDEagle,1},{amPickHammer,1},{amFirePunch,1},{amWhip,1},{amMortar,1},{amSnowball,1},{amExtraTime,1},{amInvulnerable,1},{amVampiric,1},{amFlamethrower,1},{amBee,1},{amClusterBomb,1},{amTeleport,1},{amLowGravity,1},{amJetpack,1},{amGirder,1},{amLandGun,1},{amBirdy,1}}},

{loc("Sundaland"),"["..loc("Difficulty: ")..loc("HARD").."] "..loc("Area")..": 1,850,000 km2, "..loc("Population")..": 290,000,000",loc("- You will recieve 2-4 weapons on each kill! (Even on own hogs)"),amTardis,
{{amClusterBomb,4},{amTardis,4},{amWhip,100},{amKamikaze,4}}}

}

local GLOBAL_CONTINENT_SOUNDS=
{
	{sndShotgunFire,sndCover},
	{sndEggBreak,sndLaugh},
	{sndExplosion,sndEnemyDown},
	{sndMelonImpact,sndCoward},
	{sndRopeAttach,sndComeonthen},
	{sndBaseballBat,sndNooo},
	{sndSineGun,sndOops},
	{sndPiano5,sndStupid},
	{sndSplash,sndFirstBlood},
	{sndWarp,sndSameTeam},
	{sndFrozenHogImpact,sndUhOh}
}

--weapontype,ammo,?,duration,*times your choice,affect on random team (should be placed with 1,0,1,0,1 on the 6th option for better randomness)
local GLOBAL_WEAPONS_DAMAGE = {
	{amKamikaze, 0, 1, 0, 1, 0},
	{amSineGun, 0, 1, 0, 1, 1},
	{amBazooka, 0, 1, 0, 1, 0},
	{amMineStrike, 0, 1, 5, 1, 2},
	{amGrenade, 0, 1, 0, 1, 0},
	{amPiano, 0, 1, 5, 1, 0},
	{amClusterBomb, 0, 1, 0, 1, 0},
	{amBee, 0, 1, 0, 1, 0},
	{amShotgun, 0, 0, 0, 1, 1},
	{amMine, 0, 1, 0, 1, 0},
	{amSniperRifle, 0, 1, 0, 1, 1},
	{amDEagle, 0, 1, 0, 1, 0},
	{amDynamite, 0, 1, 5, 1, 1},
	{amFirePunch, 0, 1, 0, 1, 0},
	{amHellishBomb, 0, 1, 5, 1, 2},
	{amWhip, 0, 1, 0, 1, 0},
	{amNapalm, 0, 1, 5, 1, 2},
	{amPickHammer, 0, 1, 0, 1, 0},
	{amBaseballBat, 0, 1, 0, 1, 1},
	{amMortar, 0, 1, 0, 1, 0},
	{amCake, 0, 1, 4, 1, 2},
	{amSeduction, 0, 0, 0, 1, 0},
	{amWatermelon, 0, 1, 5, 1, 2},
	{amDrill, 0, 1, 0, 1, 0},
	{amBallgun, 0, 1, 5, 1, 2},
	{amMolotov, 0, 1, 0, 1, 0},
	{amHammer, 0, 1, 0, 1, 2},
	{amBirdy, 0, 1, 0, 1, 0},
	{amBlowTorch, 0, 1, 0, 1, 0},
	{amRCPlane, 0, 1, 5, 1, 2},
	{amGasBomb, 0, 0, 0, 1, 0},
	{amAirAttack, 0, 1, 4, 1, 1},
	{amFlamethrower, 0, 1, 0, 1, 0},
	{amSMine, 0, 1, 0, 1, 1},
	{amDrillStrike, 0, 1, 4, 1, 2},
	{amSnowball, 0, 1, 0, 1, 0}
}
local GLOBAL_WEAPONS_SUPPORT = {
	{amParachute, 0, 1, 0, 1, 0},
	{amGirder, 0, 1, 0, 1, 0},
	{amSwitch, 0, 1, 0, 1, 0},
	{amLowGravity, 0, 1, 0, 1, 0},
	{amExtraDamage, 0, 1, 2, 1, 0},
	{amRope, 0, 1, 0, 1, 1},
	{amInvulnerable, 0, 1, 0, 1, 0},
	{amExtraTime, 0, 1, 0, 1, 0},
	{amLaserSight, 0, 1, 0, 1, 0},
	{amVampiric, 0, 1, 0, 1, 0},
	{amJetpack, 0, 1, 0, 1, 1},
	{amPortalGun, 0, 1, 2, 1, 1},
	{amResurrector, 0, 1, 3, 1, 0},
	{amTeleport, 0, 1, 0, 1, 0},
	{amLandGun, 0, 1, 0, 1, 0},
	{amTardis, 0, 1, 0, 1, 0},
	{amIceGun, 0, 1, 0, 1, 0},
	{amKnife, 0, 1, 0, 1, 0},
	{amRubber, 0, 1, 0, 1, 0}

}

--will check after borders and stuff
function ValidateWeapon(hog,weapon,amount)
	if(MapHasBorder() == false or (MapHasBorder() == true and weapon ~= amAirAttack and weapon ~= amMineStrike and weapon ~= amNapalm and weapon ~= amDrillStrike and weapon ~= amPiano))
	then
		if(amount==1)
		then
			AddAmmo(hog, weapon)
		else
			AddAmmo(hog, weapon,amount)
		end
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

	local i=1
	--+1 for skip
	while(i<=table.maxn(GLOBAL_WEAPONS_SUPPORT)+table.maxn(GLOBAL_WEAPONS_DAMAGE)+1)
	do
		AddAmmo(hog,i,0)
		i=i+1
	end

	AddAmmo(hog,amSkip,100)
end

--get the weapons from a weaponset
function LoadWeaponset(hog, num)
	for v,w in pairs(GLOBAL_CONTINENT_INFORMATION[num][5])
	do
		ValidateWeapon(hog, w[1],w[2])
	end
end

--list up all weapons from the icons for each continent
function InitWeaponsMenu(hog)

	if(GetHogLevel(hog)==0)
	then
		for v,w in pairs(GLOBAL_CONTINENT_INFORMATION)
		do
			ValidateWeapon(hog, GLOBAL_CONTINENT_INFORMATION[v][4],1)
		end
		AddAmmo(hog,amSwitch) --random continent

	--for the computers
	else
		--europe
		ValidateWeapon(hog, GLOBAL_CONTINENT_INFORMATION[3][4],1)
		--north america
		ValidateWeapon(hog, GLOBAL_CONTINENT_INFORMATION[1][4],1)
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
		geninftext="| |"..loc("General information")..": |"..GLOBAL_GENERAL_INFORMATION
	end

	GLOBAL_SHOW_SMALL_INFO=div(time,40)

	ShowMission(GLOBAL_CONTINENT_INFORMATION[continent][1],GLOBAL_CONTINENT_INFORMATION[continent][2],GLOBAL_CONTINENT_INFORMATION[continent][3]..geninftext, -GLOBAL_CONTINENT_INFORMATION[continent][4], time)
	if(ns)
	then
		HideMission()
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

--zealandia (generates weapons from the weaponinfo above
function ZealandiaGetWeapons(hog)
	if(GetGearType(hog) == gtHedgehog and GLOBAL_TEAM_CONTINENT[GetHogTeamName(hog)]==9 and getTeamValue(GetHogTeamName(hog), "rand-done-turn")==nil)
	then
		CleanWeapons(hog)

		local random_weapon = 0
		local old_rand_weap = 0
		local rand_weaponset_power = 0

		local numberofweaponssupp=table.maxn(GLOBAL_WEAPONS_SUPPORT)
		local numberofweaponsdmg=table.maxn(GLOBAL_WEAPONS_DAMAGE)

		local rand1=math.abs(GetRandom(numberofweaponssupp)+1)
		local rand2=math.abs(GetRandom(numberofweaponsdmg)+1)

		random_weapon = math.abs(GetRandom(table.maxn(GLOBAL_WEAPONS_DAMAGE))+1)

		while(GLOBAL_WEAPONS_DAMAGE[random_weapon][4]>TotalRounds or (MapHasBorder() == true and (GLOBAL_WEAPONS_DAMAGE[random_weapon][1]== amAirAttack or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amMineStrike or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amNapalm or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amDrillStrike or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amPiano)))
		do
			if(random_weapon>=numberofweaponsdmg)
			then
				random_weapon=0
			end
			random_weapon = random_weapon+1
		end
		ValidateWeapon(hog, GLOBAL_WEAPONS_DAMAGE[random_weapon][1],1)
		rand_weaponset_power=GLOBAL_WEAPONS_DAMAGE[random_weapon][6]
		old_rand_weap = random_weapon

		if(rand_weaponset_power <2)
		then
			random_weapon = rand1
			while(GLOBAL_WEAPONS_SUPPORT[random_weapon][4]>TotalRounds or rand_weaponset_power+GLOBAL_WEAPONS_SUPPORT[random_weapon][6]>2)
			do
				if(random_weapon>=numberofweaponssupp)
				then
					random_weapon=0
				end
				random_weapon = random_weapon+1
			end
			ValidateWeapon(hog, GLOBAL_WEAPONS_SUPPORT[random_weapon][1],1)
			rand_weaponset_power=rand_weaponset_power+GLOBAL_WEAPONS_SUPPORT[random_weapon][6]
		end
		--check again if  the power is enough
		if(rand_weaponset_power <1)
		then
			random_weapon = rand2
			while(GLOBAL_WEAPONS_DAMAGE[random_weapon][4]>TotalRounds or old_rand_weap == random_weapon or GLOBAL_WEAPONS_DAMAGE[random_weapon][6]>0 or (MapHasBorder() == true and (GLOBAL_WEAPONS_DAMAGE[random_weapon][1]== amAirAttack or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amMineStrike or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amNapalm or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amDrillStrike or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amPiano)))
			do
				if(random_weapon>=numberofweaponsdmg)
				then
					random_weapon=0
				end
				random_weapon = random_weapon+1
			end
			ValidateWeapon(hog, GLOBAL_WEAPONS_DAMAGE[random_weapon][1],1)
		end

		setTeamValue(GetHogTeamName(hog), "rand-done-turn", true)
	end
end

--sundaland add weps
function SundalandGetWeapons(hog)

		local random_weapon = 0
		local old_rand_weap = 0
		local rand_weaponset_power = 0

		local firstTurn=0

		local numberofweaponssupp=table.maxn(GLOBAL_WEAPONS_SUPPORT)
		local numberofweaponsdmg=table.maxn(GLOBAL_WEAPONS_DAMAGE)

		local rand1=GetRandom(numberofweaponssupp)+1
		local rand2=GetRandom(numberofweaponsdmg)+1
		local rand3=GetRandom(numberofweaponsdmg)+1

		random_weapon = GetRandom(numberofweaponsdmg)+1

		if(TotalRounds<0)
		then
			firstTurn=-TotalRounds
		end

		while(GLOBAL_WEAPONS_DAMAGE[random_weapon][4]>(TotalRounds+firstTurn) or (MapHasBorder() == true and (GLOBAL_WEAPONS_DAMAGE[random_weapon][1]== amAirAttack or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amMineStrike or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amNapalm or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amDrillStrike or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amPiano)))
		do
			if(random_weapon>=numberofweaponsdmg)
			then
				random_weapon=0
			end
			random_weapon = random_weapon+1
		end
		ValidateWeapon(hog, GLOBAL_WEAPONS_DAMAGE[random_weapon][1],1)
		rand_weaponset_power=GLOBAL_WEAPONS_DAMAGE[random_weapon][6]
		old_rand_weap = random_weapon

		random_weapon = rand1
		while(GLOBAL_WEAPONS_SUPPORT[random_weapon][4]>(TotalRounds+firstTurn) or rand_weaponset_power+GLOBAL_WEAPONS_SUPPORT[random_weapon][6]>2)
		do
			if(random_weapon>=numberofweaponssupp)
			then
				random_weapon=0
			end
			random_weapon = random_weapon+1
		end
		ValidateWeapon(hog, GLOBAL_WEAPONS_SUPPORT[random_weapon][1],1)
		rand_weaponset_power=rand_weaponset_power+GLOBAL_WEAPONS_SUPPORT[random_weapon][6]

		--check again if  the power is enough
		if(rand_weaponset_power <2)
		then
			random_weapon = rand2
			while(GLOBAL_WEAPONS_DAMAGE[random_weapon][4]>(TotalRounds+firstTurn) or old_rand_weap == random_weapon or GLOBAL_WEAPONS_DAMAGE[random_weapon][6]>0 or (MapHasBorder() == true and (GLOBAL_WEAPONS_DAMAGE[random_weapon][1]== amAirAttack or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amMineStrike or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amNapalm or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amDrillStrike or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amPiano)))
			do
				if(random_weapon>=numberofweaponsdmg)
				then
					random_weapon=0
				end
				random_weapon = random_weapon+1
			end
			ValidateWeapon(hog, GLOBAL_WEAPONS_DAMAGE[random_weapon][1],1)
			rand_weaponset_power=GLOBAL_WEAPONS_DAMAGE[random_weapon][6]
		end

		if(rand_weaponset_power <1)
		then
			random_weapon = rand3
			while(GLOBAL_WEAPONS_DAMAGE[random_weapon][4]>(TotalRounds+firstTurn) or old_rand_weap == random_weapon or GLOBAL_WEAPONS_DAMAGE[random_weapon][6]>0 or (MapHasBorder() == true and (GLOBAL_WEAPONS_DAMAGE[random_weapon][1]== amAirAttack or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amMineStrike or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amNapalm or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amDrillStrike or GLOBAL_WEAPONS_DAMAGE[random_weapon][1] == amPiano)))
			do
				if(random_weapon>=numberofweaponsdmg)
				then
					random_weapon=0
				end
				random_weapon = random_weapon+1
			end
			ValidateWeapon(hog, GLOBAL_WEAPONS_DAMAGE[random_weapon][1],1)
		end

		AddVisualGear(GetX(hog), GetY(hog)-30, vgtEvilTrace,0, false)
		PlaySound(sndReinforce,hog)
end


--this will take that hogs settings for the weapons and add them
function SetContinentWeapons()

	CleanWeapons(CurrentHedgehog)
	LoadWeaponset(CurrentHedgehog,GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)])

	visualstuff=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-5, vgtDust,0, false)
	v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 = GetVisualGearValues(visualstuff)
	SetVisualGearValues(visualstuff, v1, v2, v3, v4, v5, v6, v7, 2, v9, GetClanColor(GetHogClan(CurrentHedgehog)))

	ShowContinentInfo(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)],3000,false)
end

--==========================run throw all hog/gear weapons ==========================
--will check if the mine is nicely placed
function AustraliaSpecialCheckHogs(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 40, false)==true and hog ~= CurrentHedgehog)
		then
			GLOBAL_TEMP_VALUE=1
		end
	end
end

--african special on sedunction
function AfricaSpecialSeduction(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		local dmg=div(15*GLOBAL_EXTRA_DAMAGE_IS_ON,100)
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 250, false)==true and GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			if(GetHealth(hog) > dmg)
			then
				GLOBAL_TEMP_VALUE=GLOBAL_TEMP_VALUE+div(dmg*GLOBAL_VAMPIRIC_IS_ON,100)
				SetHealth(hog, GetHealth(hog)-dmg)
			else
				GLOBAL_TEMP_VALUE=GLOBAL_TEMP_VALUE+div(GetHealth(hog)*GLOBAL_VAMPIRIC_IS_ON,100)
				SetHealth(hog, 0)
			end
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
			local dmg=div((15+div(GetHealth(CurrentHedgehog)*10,100))*GLOBAL_EXTRA_DAMAGE_IS_ON,100)

			if(GetHealth(hog)>dmg)
			then
				GLOBAL_TEMP_VALUE=GLOBAL_TEMP_VALUE+div(dmg*2,3)+div(dmg*GLOBAL_VAMPIRIC_IS_ON*2,100*3)
				SetHealth(hog, GetHealth(hog)-dmg)
			else
				GLOBAL_TEMP_VALUE=GLOBAL_TEMP_VALUE+(div(GetHealth(hog)*75,100))+(div(GetHealth(CurrentHedgehog)*10,100))+div((GetHealth(hog)+div(GetHealth(CurrentHedgehog)*10,100))*GLOBAL_VAMPIRIC_IS_ON,100)
				SetHealth(hog, 0)
			end
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
		if(GetHogClan(hog) ~= GetHogClan(CurrentHedgehog) and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 420, false))
		then
			GLOBAL_TEMP_VALUE=GLOBAL_TEMP_VALUE+1
		end
	end
end
--kerguelen special swap hog
function KerguelenSpecialYellowSwap(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(GLOBAL_KERGUELEN_SPECIAL ~= -1 and GetHogClan(hog) ~= GetHogClan(CurrentHedgehog) and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 420, false))
		then
			if(GLOBAL_TEMP_VALUE==0)
			then
				local thisX=GetX(CurrentHedgehog)
				local thisY=GetY(CurrentHedgehog)
				SetGearPosition(CurrentHedgehog, GetX(hog), GetY(hog))
				SetGearPosition(hog, thisX, thisY)
				GLOBAL_KERGUELEN_SPECIAL=-1
			else
				GLOBAL_TEMP_VALUE=GLOBAL_TEMP_VALUE-1
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
			GLOBAL_TEMP_VALUE=1
			GLOBAL_SABOTAGE_HOGS[hog]=1
			AddGear(GetX(hog), GetY(hog), gtCluster, 0, 0, 0, 1)
			PlaySound(sndNooo,hog)
		end
	end
end

--first part on kerguelen special (lonely cries)
function KerguelenSpecialBlueCheck(hog)
	if(GetGearType(hog) == gtHedgehog and hog ~= CurrentHedgehog and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 550, false))
	then
		GLOBAL_KERGUELEN_SPECIAL=-1
	end
end

--second part on kerguelen special (lonely cries)
function KerguelenSpecialBlueActivate(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		local dmg=div(6*GLOBAL_EXTRA_DAMAGE_IS_ON,100)
		if(GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			if(GetHealth(hog) > dmg)
			then
				GLOBAL_TEMP_VALUE=GLOBAL_TEMP_VALUE+div(dmg*GLOBAL_VAMPIRIC_IS_ON,100)
				SetHealth(hog, GetHealth(hog)-dmg)
			else
				GLOBAL_TEMP_VALUE=GLOBAL_TEMP_VALUE+div(GetHealth(hog)*GLOBAL_VAMPIRIC_IS_ON,100)
				SetHealth(hog, 0)
			end
			ShowDamageTag(hog,dmg)

			AddVisualGear(GetX(hog), GetY(hog)-30, vgtEvilTrace, 0, false)
		end
	end
end

--australia
function AustraliaSpecialEggHit(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(hog,GetX(GLOBAL_TEMP_VALUE), GetY(GLOBAL_TEMP_VALUE), 18, false))
		then
			GLOBAL_SABOTAGE_HOGS[hog]=1
			PlaySound(sndNooo,hog)
			SetEffect(hog, hePoisoned, false)
		end
	end
end

--south american special (used fire gear)
function SouthAmericaSpecialCheeseExplosion(hog)
	if(GetGearType(hog) == gtHedgehog or GetGearType(hog) == gtMine or GetGearType(hog) == gtExplosives)
	then
		local power_radius_outer=230
		local power_radius_inner=45
		local power_sa=500000
		local hypo=0
		if(gearIsInCircle(hog,GetX(GLOBAL_TEMP_VALUE), GetY(GLOBAL_TEMP_VALUE), power_radius_outer, false) and gearIsInCircle(hog,GetX(GLOBAL_TEMP_VALUE), GetY(GLOBAL_TEMP_VALUE), power_radius_inner, false)==false)
		then
			if(hog == CurrentHedgehog)
			then
				SetState(CurrentHedgehog, gstMoving)
			end
			SetGearPosition(hog, GetX(hog),GetY(hog)-3)
			hypo=Norm(math.abs(GetX(hog)-GetX(GLOBAL_TEMP_VALUE)),math.abs(GetY(hog)-GetY(GLOBAL_TEMP_VALUE)))
			SetGearVelocity(hog, div((power_radius_outer-hypo)*power_sa*GetIfNegative(GetX(hog)-GetX(GLOBAL_TEMP_VALUE)),power_radius_outer), div((power_radius_outer-hypo)*power_sa*GetIfNegative(GetY(hog)-GetY(GLOBAL_TEMP_VALUE)),power_radius_outer))
		end
	end
end

--north american special on sniper
function NorthAmericaSpecialSniper(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(GLOBAL_TEMP_VALUE,GetX(hog), GetY(hog), 20, false))
		then
			SetEffect(hog, hePoisoned, 1)
			PlaySound(sndBump)
		end
	end
end

--european special on molotov (used fire gear)
function EuropeSpecialMolotovHit(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(GLOBAL_TEMP_VALUE,GetX(hog), GetY(hog), 100, false))
		then
			SetHealth(hog, GetHealth(hog)+25+(div(25*GLOBAL_VAMPIRIC_IS_ON,100)))
			SetEffect(hog, hePoisoned, false)
			GLOBAL_SABOTAGE_HOGS[hog]=0
		end
	end
end

--for sundaland
function SundalandFindOtherHogInTeam(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(GetHogTeamName(GLOBAL_SUNDALAND_END_HOG)==GetHogTeamName(hog))
		then
			GLOBAL_SUNDALAND_END_HOG=hog
		end
	end
end
--============================================================================

--for custom made continent, follows the same standards as the globalism one. You can make your continent with <Name>~<Information>~<Weapons>. Take the weapons generated from globalism, if you want a GUI :P
--weapons=<ammo><types>, ammo = ascii[116(1 ammo) to 125(inf ammo)] types = ascii[36(Grenade), 37(Clusterbomb) to 90(knife)] see http://hedgewars.org/kb/AmmoTypes
--ex "Own continent~this continent rocks!~tZ}$" will get 1 knife and inf grenades
function onParameters()

	if(ScriptParam~=nil)
	then
		local continentinfo={}
		local numb=0
		local wepcodes=0
		local where=0

		local x=0
		local i=1

		--default icon
		continentinfo[4]=amLowGravity

		for c in ScriptParam:gmatch"."
		do
			if(where==0)
			then
				if(string.byte(c)==126)
				then
					continentinfo[1]=string.sub(ScriptParam,0,numb)
					wepcodes=numb
					where=1
				end
			elseif(where==1)
			then
				if(string.byte(c)==126)
				then
					continentinfo[2]=string.sub(ScriptParam,wepcodes+2,numb)
					continentinfo[5]={}
					wepcodes=numb
					where=2
				end
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
			continentinfo[3]="- "..continentinfo[1]..loc(" was extracted from the scheme|- This continent will be able to use the specials from the other continents!")

			table.insert(GLOBAL_CONTINENT_INFORMATION, continentinfo)
		end
	end
end

--set each weapons settings
function onAmmoStoreInit()

	SetAmmo(amSkip, 9, 0, 0, 0)

	for v,w in pairs(GLOBAL_WEAPONS_DAMAGE)
	do
		SetAmmo(w[1], w[2], w[3], w[4], w[5])
	end

	for v,w in pairs(GLOBAL_WEAPONS_SUPPORT)
	do
		SetAmmo(w[1], w[2], w[3], w[4], w[5])
	end
end

--on game start
function onGameStart()
	ShowMission(loc("Continental supplies"),loc("Let a continent provide your weapons!"),
	GLOBAL_GENERAL_INFORMATION, -amLowGravity, 0)
end

--what happen when a turn starts
function onNewTurn()

	--will refresh the info on each tab weapon
	GLOBAL_AUSTRALIAN_SPECIAL=0
	GLOBAL_AFRICAN_SPECIAL_SEDUCTION=0
	GLOBAL_SOUTH_AMERICAN_SPECIAL=false
	GLOBAL_AFRICAN_SPECIAL_STICKY=0
	GLOBAL_KERGUELEN_SPECIAL=1
	GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER=1
	GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN=false
	GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON=false
	GLOBAL_EUROPE_SPECIAL=0
	GLOBAL_VAMPIRIC_IS_ON=0
	GLOBAL_EXTRA_DAMAGE_IS_ON=100

	GLOBAL_TEMP_VALUE=0

	GLOBAL_SUNDALAND_END_HOG=CurrentHedgehog

	--when all hogs are "placed"
	if(GetCurAmmoType()~=amTeleport)
	then
		--will run once when the game really starts (after placing hogs and so on
		if(GLOBAL_INIT_TEAMS[GetHogTeamName(CurrentHedgehog)] == nil)
		then
			AddCaption("["..loc("Select continent!").."]")
			InitWeaponsMenu(CurrentHedgehog)
			GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=0
			GLOBAL_SELECT_CONTINENT_CHECK=true
			GLOBAL_INIT_TEAMS[GetHogTeamName(CurrentHedgehog)] = 2

			if(GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]~=nil and GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]==1)
			then
				GLOBAL_SABOTAGE_COUNTER=-750
			end
		else
			--if its not the initialization turn
			GLOBAL_SELECT_CONTINENT_CHECK=false
			if(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==0)
			then
				GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=GetRandom(table.maxn(GLOBAL_CONTINENT_INFORMATION))+1
				SetContinentWeapons()
			end
			ShowContinentInfo(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)],-1,true)

			--give zeelandia-teams new weapons so they can plan for the next turn
			runOnGears(ZealandiaGetWeapons)

			--some specials for some continents (GLOBAL_TEMP_VALUE is from get random weapons)
			if(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==9)
			then
				setTeamValue(GetHogTeamName(CurrentHedgehog), "rand-done-turn", nil)
			elseif(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==7)
			then
				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick")==nil)
				then
					setTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick", 1)
				end

				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick")>=4)
				then
					AddAmmo(CurrentHedgehog,amPortalGun)
					AddAmmo(CurrentHedgehog,amPortalGun)
					AddAmmo(CurrentHedgehog,amSineGun)
					AddAmmo(CurrentHedgehog,amSineGun)
					AddAmmo(CurrentHedgehog,amGirder)
					AddAmmo(CurrentHedgehog,amSnowball)
					setTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick", 0)
				end
				setTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick", getTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick")+1)

			elseif(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==5)
			then
				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick")==nil)
				then
					setTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick", 1)
				end

				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick")>=2)
				then
					AddAmmo(CurrentHedgehog,amParachute)
					setTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick", 0)
				end
				setTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick", getTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick")+1)
			elseif(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==1)
			then
				AddAmmo(CurrentHedgehog,amSwitch,GetAmmoCount(CurrentHedgehog, amSwitch)+1)

				SetWeapon(amSwitch)
				GLOBAL_TEMP_VALUE=87
			end
		end
	end
end

--what happens when you press "tab" (common button)
function onSwitch()

	if(GLOBAL_SWITCH_HOG_IS_ON==false)
	then
		--place mine (australia)
		if(GetCurAmmoType() == amBaseballBat)
		then
			if(GLOBAL_AUSTRALIAN_SPECIAL==0)
			then
				GLOBAL_AUSTRALIAN_SPECIAL = 1
				AddCaption(GLOBAL_WEAPON_TEXTS[5])
			elseif(GLOBAL_AUSTRALIAN_SPECIAL==1)
			then
				GLOBAL_AUSTRALIAN_SPECIAL = 2
				AddCaption(GLOBAL_WEAPON_TEXTS[2])
			else
				GLOBAL_AUSTRALIAN_SPECIAL = 0
				AddCaption(loc("NORMAL"))
			end

		--Asian special
		elseif(GLOBAL_PARACHUTE_IS_ON==1)
		then
			asiabomb=AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)+3, gtSnowball, 0, 0, 0, 0)
			SetGearMessage(asiabomb, 1)

			GLOBAL_PARACHUTE_IS_ON=2
			GLOBAL_SELECT_CONTINENT_CHECK=false

		--africa
		elseif(GetCurAmmoType() == amSeduction)
		then
			if(GLOBAL_AFRICAN_SPECIAL_SEDUCTION==0)
			then
				GLOBAL_AFRICAN_SPECIAL_SEDUCTION = 1
				AddCaption(GLOBAL_WEAPON_TEXTS[4])
			else
				GLOBAL_AFRICAN_SPECIAL_SEDUCTION = 0
				AddCaption(loc("NORMAL"))
			end

		--south america
		elseif(GetCurAmmoType() == amGasBomb)
		then
			if(GLOBAL_SOUTH_AMERICAN_SPECIAL==false)
			then
				GLOBAL_SOUTH_AMERICAN_SPECIAL = true
				AddCaption(GLOBAL_WEAPON_TEXTS[3])
			else
				GLOBAL_SOUTH_AMERICAN_SPECIAL = false
				AddCaption(loc("NORMAL"))
			end

		--africa
		elseif(GetCurAmmoType() == amSMine)
		then
			if(GLOBAL_AFRICAN_SPECIAL_STICKY==0)
			then
				GLOBAL_AFRICAN_SPECIAL_STICKY = 1
				AddCaption(GLOBAL_WEAPON_TEXTS[11])
			elseif(GLOBAL_AFRICAN_SPECIAL_STICKY == 1)
			then
				GLOBAL_AFRICAN_SPECIAL_STICKY = 2
				AddCaption(GLOBAL_WEAPON_TEXTS[12])
			elseif(GLOBAL_AFRICAN_SPECIAL_STICKY == 2)
			then
				GLOBAL_AFRICAN_SPECIAL_STICKY = 0
				AddCaption(loc("NORMAL"))
			end

		--north america (sniper)
		elseif(GetCurAmmoType() == amSniperRifle and GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON==false)
		then
			if(GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER==2)
			then
				GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER = 1
				AddCaption(loc("NORMAL"))
			elseif(GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER==1)
			then
				GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER = 2
				AddCaption(GLOBAL_WEAPON_TEXTS[1])
			end

		--north america (shotgun)
		elseif(GetCurAmmoType() == amShotgun and GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN~=nil)
		then
			if(GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN==false)
			then
				GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN = true
				AddCaption(GLOBAL_WEAPON_TEXTS[13])
			else
				GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN = false
				AddCaption(loc("NORMAL"))
			end

		--europe
		elseif(GetCurAmmoType() == amMolotov)
		then
			if(GLOBAL_EUROPE_SPECIAL==0)
			then
				GLOBAL_EUROPE_SPECIAL = 1
				AddCaption(GLOBAL_WEAPON_TEXTS[14])
			else
				GLOBAL_EUROPE_SPECIAL = 0
				AddCaption(loc("NORMAL"))
			end

		--kerguelen
		elseif(GetCurAmmoType() == amHammer)
		then
			if(GLOBAL_KERGUELEN_SPECIAL==6)
			then
				GLOBAL_KERGUELEN_SPECIAL = 1
				AddCaption("Normal")
			elseif(GLOBAL_KERGUELEN_SPECIAL==1)
			then
				GLOBAL_KERGUELEN_SPECIAL = 2
				AddCaption("#"..GLOBAL_WEAPON_TEXTS[7])
			elseif(GLOBAL_KERGUELEN_SPECIAL==2 and TotalRounds>=1)
			then
				GLOBAL_KERGUELEN_SPECIAL = 3
				AddCaption("##"..GLOBAL_WEAPON_TEXTS[8])
			elseif(GLOBAL_KERGUELEN_SPECIAL==3 or (GLOBAL_KERGUELEN_SPECIAL==2 and TotalRounds<1))
			then
				GLOBAL_KERGUELEN_SPECIAL = 5
				AddCaption("###"..GLOBAL_WEAPON_TEXTS[10])
			elseif(GLOBAL_KERGUELEN_SPECIAL==5)
			then
				GLOBAL_KERGUELEN_SPECIAL = 6
				AddCaption("####"..GLOBAL_WEAPON_TEXTS[15])
			end
		--for selecting weaponset, this is mostly for old players.
		elseif(GetHogLevel(CurrentHedgehog)==0 and GLOBAL_SELECT_CONTINENT_CHECK==true and (GetCurAmmoType() == amSkip or GetCurAmmoType() == amNothing))
		then
			GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]+1

			if(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]> table.maxn(GLOBAL_CONTINENT_INFORMATION))
			then
				GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=1
			end
			SetContinentWeapons()
		end
	--if switching out from sabotage.
	elseif(GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]~=nil and GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]==2)
	then
		GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]=1
	end
end

function onUp()
	--swap forward in the weaponmenu (1.0 style)
	if(GetHogLevel(CurrentHedgehog)==0 and GLOBAL_SELECT_CONTINENT_CHECK==true and (GetCurAmmoType() == amSkip or GetCurAmmoType() == amNothing))
	then
		GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]+1

		if(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]> table.maxn(GLOBAL_CONTINENT_INFORMATION))
		then
			GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=1
		end
		SetContinentWeapons()
	end
end

function onDown()
	--swap backwards in the weaponmenu (1.0 style)
	if(GetHogLevel(CurrentHedgehog)==0 and GLOBAL_SELECT_CONTINENT_CHECK==true and (GetCurAmmoType() == amSkip or GetCurAmmoType() == amNothing))
	then
		GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]-1

		if(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]<=0)
		then
			GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=table.maxn(GLOBAL_CONTINENT_INFORMATION)
		end
		SetContinentWeapons()
	end
end

function onGameTick20()
	--if you picked a weaponset from the weaponmenu (icon)
	if(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==0)
	then
		if(GetCurAmmoType()==amSwitch)
		then
			GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=GetRandom(table.maxn(GLOBAL_CONTINENT_INFORMATION))+1
			SetContinentWeapons()
			PlaySound(sndMineTick)
		else
			for v,w in pairs(GLOBAL_CONTINENT_INFORMATION)
			do
				if(GetCurAmmoType()==GLOBAL_CONTINENT_INFORMATION[v][4])
				then
					GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=v
					SetContinentWeapons()
					PlaySound(GLOBAL_CONTINENT_SOUNDS[v][1])
					PlaySound(GLOBAL_CONTINENT_SOUNDS[v][2],CurrentHedgehog)
				end
			end
		end
	end

	--show the kerguelen ring
	if(GLOBAL_KERGUELEN_SPECIAL > 1 and GetCurAmmoType() == amHammer)
	then
		if(GLOBAL_VISUAL_CIRCLE==nil)
		then
			GLOBAL_VISUAL_CIRCLE=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtCircle, 0, true)
		end

		if(GLOBAL_KERGUELEN_SPECIAL == 2) --walrus scream
		then
			SetVisualGearValues(GLOBAL_VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 120, 4, 0xff0000ee)
		elseif(GLOBAL_KERGUELEN_SPECIAL == 3) --swap hog
		then
			SetVisualGearValues(GLOBAL_VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 420, 3, 0xffff00ee)
		elseif(GLOBAL_KERGUELEN_SPECIAL == 5) --cries
		then
			SetVisualGearValues(GLOBAL_VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 550, 1, 0x0000ffee)
		elseif(GLOBAL_KERGUELEN_SPECIAL == 6) --sabotage
		then
			SetVisualGearValues(GLOBAL_VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 80, 10, 0x00ff00ee)
		end

	elseif(GLOBAL_VISUAL_CIRCLE~=nil)
	then
		DeleteVisualGear(GLOBAL_VISUAL_CIRCLE)
		GLOBAL_VISUAL_CIRCLE=nil
	end

	--sabotage
	if(GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]~=nil and GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]>=1)
	then
		--for sabotage
		if(GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]==1)
		then
			local RND=GetRandom(2)
			if(RND==0)
			then
				AddCaption(loc("You are sabotaged, RUN!"))
			else
				AddCaption(loc("WARNING: Sabotage detected!"))
			end
			PlaySound(sndHellish)
			GLOBAL_SABOTAGE_COUNTER=-50
			--update the constant at the top also to something in between
			GLOBAL_SABOTAGE_FREQUENCY=(25*(RND))+70
			GLOBAL_SABOTAGE_GRAVITY_SWITCH=true

			GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]=2
		end

		if(GLOBAL_SABOTAGE_COUNTER >0)
		then
			if(GLOBAL_SABOTAGE_GRAVITY_SWITCH)
			then
				SetGravityFromScale(div(100*GLOBAL_SABOTAGE_COUNTER,GLOBAL_SABOTAGE_FREQUENCY))
			else
				SetGravityFromScale(100-div(100*GLOBAL_SABOTAGE_COUNTER,GLOBAL_SABOTAGE_FREQUENCY))
			end

			if(GLOBAL_SABOTAGE_COUNTER % 20 == 0)
			then
				AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmokeWhite, 0, false)
			end
		end

		if(TurnTimeLeft<(GetAwayTime*10) or band(GetState(CurrentHedgehog),gstAttacked)==1)
		then
			GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]=0
			SetGravity(100)
		elseif(GLOBAL_SABOTAGE_COUNTER >= GLOBAL_SABOTAGE_FREQUENCY)
		then
			if(GLOBAL_SABOTAGE_GRAVITY_SWITCH==true)
			then
				GLOBAL_SABOTAGE_GRAVITY_SWITCH=false
			else
				--AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-10, gtCluster, 0, 0, -160000, 30)
				GLOBAL_SABOTAGE_GRAVITY_SWITCH=true
			end

			if(GetHealth(CurrentHedgehog)<=2)
			then
				SetHealth(CurrentHedgehog, 0)
				GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]=0
				SetGravity(100)
			else
				SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)-2)
			end
			ShowDamageTag(CurrentHedgehog,2)

			GLOBAL_SABOTAGE_COUNTER=0
		else
			GLOBAL_SABOTAGE_COUNTER=GLOBAL_SABOTAGE_COUNTER+1
		end
	end

	if(GetCurAmmoType() == amSwitch and GLOBAL_TEMP_VALUE==87)
	then
		SetGearMessage(CurrentHedgehog,gmAttack)
		GLOBAL_TEMP_VALUE=0
	end

	if(GLOBAL_SHOW_SMALL_INFO>0)
	then
		if(GLOBAL_SHOW_SMALL_INFO==1)
		then
			ShowContinentInfo(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)],-1,true)
		end

		GLOBAL_SHOW_SMALL_INFO=GLOBAL_SHOW_SMALL_INFO-1
	end
end

--some ppl complained :P
function onSlot(slot)
	if(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==0)
	then
		SetWeapon(amSkip)
	end
end

--if you used hogswitch or any similar weapon, dont enable any weaponchange
function onAttack()
	GLOBAL_SELECT_CONTINENT_CHECK=false

	--african special
	if(GLOBAL_AFRICAN_SPECIAL_SEDUCTION == 1 and GetCurAmmoType() == amSeduction and band(GetState(CurrentHedgehog),gstAttacked)==0)
	then
		EndTurn()

		GLOBAL_TEMP_VALUE=0
		runOnGears(AfricaSpecialSeduction)
		SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+GLOBAL_TEMP_VALUE)

		--visual stuff
		VisualExplosion(250,GetX(CurrentHedgehog), GetY(CurrentHedgehog),vgtSmoke,vgtSmokeWhite)
		PlaySound(sndParachute)

		RemoveWeapon(CurrentHedgehog,amSeduction)

	--Kerguelen specials
	elseif(GetCurAmmoType() == amHammer and GLOBAL_KERGUELEN_SPECIAL > 1 and band(GetState(CurrentHedgehog),gstAttacked)==0)
	then
		--scream
		if(GLOBAL_KERGUELEN_SPECIAL == 2)
		then
			GLOBAL_TEMP_VALUE=0
			runOnGears(KerguelenSpecialRed)
			SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+GLOBAL_TEMP_VALUE)
			PlaySound(sndHellish)

		--swap
		elseif(GLOBAL_KERGUELEN_SPECIAL == 3 and TotalRounds>=1)
		then
			GLOBAL_TEMP_VALUE=0
			runOnGears(KerguelenSpecialYellowCountHogs)
			if(GLOBAL_TEMP_VALUE>0)
			then
				GLOBAL_TEMP_VALUE=GetRandom(GLOBAL_TEMP_VALUE)
				runOnGears(KerguelenSpecialYellowSwap)
				PlaySound(sndPiano3)
			else
				PlaySound(sndPiano6)
			end

		--cries
		elseif(GLOBAL_KERGUELEN_SPECIAL == 5)
		then
			runOnGears(KerguelenSpecialBlueCheck)
			if(GLOBAL_KERGUELEN_SPECIAL~=-1)
			then
				AddGear(0, 0, gtWaterUp, 0, 0,0,0)
				PlaySound(sndWarp)
				PlaySound(sndMolotov)

				GLOBAL_TEMP_VALUE=0
				runOnGears(KerguelenSpecialBlueActivate)
				SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+GLOBAL_TEMP_VALUE)
			else
				HogSay(CurrentHedgehog, loc("Hogs in sight!"), SAY_SAY)
			end

		--sabotage
		elseif(GLOBAL_KERGUELEN_SPECIAL == 6)
		then
			GLOBAL_TEMP_VALUE=0
			runOnGears(KerguelenSpecialGreen)
			if(GLOBAL_TEMP_VALUE==0)
			then
				PlaySound(sndThrowRelease)
				AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-20, gtCluster, 0, 0, -1000000, 32)
			end
		end

		EndTurn()

		DeleteVisualGear(GLOBAL_VISUAL_CIRCLE)
		GLOBAL_VISUAL_CIRCLE=nil
		GLOBAL_KERGUELEN_SPECIAL=0

		RemoveWeapon(CurrentHedgehog,amHammer)

	elseif(GetCurAmmoType() == amVampiric)
	then
		GLOBAL_VAMPIRIC_IS_ON=75
	elseif(GetCurAmmoType() == amExtraDamage)
	then
		GLOBAL_EXTRA_DAMAGE_IS_ON=150
	end
end

function onGearAdd(gearUid)
	GLOBAL_SELECT_CONTINENT_CHECK=false

	--track the gears im using
	if(GetGearType(gearUid) == gtHedgehog or GetGearType(gearUid) == gtMine or GetGearType(gearUid) == gtExplosives)
	then
		trackGear(gearUid)
	end

	--remove gasclouds on gasbombspecial
	if(GetGearType(gearUid)==gtPoisonCloud and GLOBAL_SOUTH_AMERICAN_SPECIAL == true)
	then
		DeleteGear(gearUid)
	--african special
	elseif(GetGearType(gearUid)==gtSMine)
	then
		vx,vy=GetGearVelocity(gearUid)
		if(GLOBAL_AFRICAN_SPECIAL_STICKY == 1)
		then
			SetState(CurrentHedgehog, gstHHDriven+gstMoving)
			SetGearPosition(CurrentHedgehog, GetX(CurrentHedgehog),GetY(CurrentHedgehog)-3)
			SetGearVelocity(CurrentHedgehog, vx, vy)
			DeleteGear(gearUid)

		elseif(GLOBAL_AFRICAN_SPECIAL_STICKY == 2)
		then
			FireGear(CurrentHedgehog,gtNapalmBomb, vx, vy, 0)
			DeleteGear(gearUid)
		end
	--north american special
	elseif(GetGearType(gearUid)==gtSniperRifleShot)
	then
		GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON=true
		if(GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER~=1)
		then
			SetHealth(gearUid, 1)
		end
	--north american special
	elseif(GetGearType(gearUid)==gtShotgunShot)
	then
		if(GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN==true)
		then
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtFeather, 0, false)
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtFeather, 0, false)
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtFeather, 0, false)
			PlaySound(sndBirdyLay)
		else
			GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN=nil
		end
	--european special
	elseif(GetGearType(gearUid)==gtMolotov and GLOBAL_EUROPE_SPECIAL==1)
	then
		vx,vy=GetGearVelocity(gearUid)
		e_health=FireGear(CurrentHedgehog,gtCluster, vx, vy, 1)
		SetGearMessage(e_health, 2)
		DeleteGear(gearUid)
	--australian specials
	elseif(GetGearType(gearUid)==gtShover and GLOBAL_AUSTRALIAN_SPECIAL~=0)
	then
		GLOBAL_TEMP_VALUE=0
		runOnGears(AustraliaSpecialCheckHogs)

		if(GLOBAL_TEMP_VALUE==0)
		then
			vx,vy=GetGearVelocity(gearUid)

			if(GLOBAL_AUSTRALIAN_SPECIAL==1)
			then
				local austmine=FireGear(CurrentHedgehog,gtMine, vx, vy, 0)
				SetHealth(austmine, 100)
				SetTimer(austmine, 1000)
			else
				local austmine=FireGear(CurrentHedgehog,gtEgg, vx, vy, 10)
				--SetHealth(austmine, 2000)
				SetTimer(austmine, 6000)
				SetGearMessage(austmine, 3)
			end
		else
			PlaySound(sndDenied)
		end
	elseif(GetGearType(gearUid)==gtParachute)
	then
		GLOBAL_PARACHUTE_IS_ON=1
	elseif(GetGearType(gearUid)==gtSwitcher)
	then
		GLOBAL_SWITCH_HOG_IS_ON=true
	end
end

function onGearDelete(gearUid)

	if(GetGearType(gearUid) == gtHedgehog or GetGearType(gearUid) == gtMine or GetGearType(gearUid) == gtExplosives)
	then
		trackDeletion(gearUid)

		--sundaland special
		if(GetGearType(gearUid) == gtHedgehog and GLOBAL_TEAM_CONTINENT[GetHogTeamName(GLOBAL_SUNDALAND_END_HOG)]==10)
		then
			if(GLOBAL_SUNDALAND_END_HOG==CurrentHedgehog)
			then
				runOnGears(SundalandFindOtherHogInTeam)
			end

			SundalandGetWeapons(GLOBAL_SUNDALAND_END_HOG)
		end
	end

	--north american lipstick
	if(GetGearType(gearUid)==gtSniperRifleShot )
	then
		GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON=false
		if(GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER==2)
		then
			GLOBAL_TEMP_VALUE=gearUid
			runOnGears(NorthAmericaSpecialSniper)
		end
	--north american eagle eye
	elseif(GetGearType(gearUid)==gtShotgunShot and GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN==true)
	then
		EndTurn()
		SetGearPosition(CurrentHedgehog, GetX(gearUid), GetY(gearUid)+7)
		PlaySound(sndWarp)
	--south american special
	elseif(GetGearType(gearUid)==gtGasBomb and GLOBAL_SOUTH_AMERICAN_SPECIAL == true)
	then
		GLOBAL_TEMP_VALUE=gearUid
		runOnGears(SouthAmericaSpecialCheeseExplosion)
		AddVisualGear(GetX(gearUid), GetY(gearUid), vgtExplosion, 0, false)

	--asian special
	elseif(GetGearType(gearUid)==gtSnowball and GetGearMessage(gearUid)==1)
	then
		AddGear(GetX(gearUid), GetY(gearUid), gtCluster, 0, 0, 0, 22)

	--europe special
	elseif(GetGearType(gearUid)==gtCluster and GetGearMessage(gearUid)==2)
	then
		GLOBAL_TEMP_VALUE=gearUid
		runOnGears(EuropeSpecialMolotovHit)
		VisualExplosion(100,GetX(gearUid), GetY(gearUid),vgtSmokeWhite,vgtSmokeWhite)
		AddVisualGear(GetX(gearUid), GetY(gearUid), vgtExplosion, 0, false)
		PlaySound(sndGraveImpact)
	--australian special
	elseif(GetGearType(gearUid)==gtEgg and GetGearMessage(gearUid)==3)
	then
		GLOBAL_TEMP_VALUE=gearUid
		runOnGears(AustraliaSpecialEggHit)
		GLOBAL_TEMP_VALUE=0
	--asia (using para)
	elseif(GetGearType(gearUid)==gtParachute)
	then
		GLOBAL_PARACHUTE_IS_ON=false
	elseif(GetGearType(gearUid)==gtSwitcher)
	then
		GLOBAL_SWITCH_HOG_IS_ON=false
	end
end

--[[
	sources (populations & area):
	Own calculations from wikipedia.
	Some are approximations.
]]

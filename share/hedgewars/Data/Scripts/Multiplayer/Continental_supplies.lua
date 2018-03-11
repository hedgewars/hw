--[[
	Copyright (C) 2012 Vatten

	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
-- fix selection increase delay (weapons to compesate)

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
function EndTurn(seconds)
	SetState(CurrentHedgehog,bor(GetState(CurrentHedgehog),gstAttacked))
	--set espace time
	TurnTimeLeft = GetAwayTime*10*seconds
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

--====MISC GLOBALS====
 
--for selecting continent
local GLOBAL_INIT_TEAMS = {}
local GLOBAL_SELECT_CONTINENT_CHECK=false
local GLOBAL_START_TIME=0
local GLOBAL_HOG_HEALTH=100
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
local GLOBAL_ANTARCTICA_SPECIAL=0
local GLOBAL_SEDUCTION_INCREASER=0

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

local GLOBAL_CRATE_TEST=-1

--for sundaland
local GLOBAL_SUNDALAND_END_HOG_CONTINENT_NAME

local OPTION_NO_SPECIALS=false

--====GENERAL GLOBALS (useful for handling continents)====

local GLOBAL_SNIPER_SPECIAL_INFO = loc("Green lipstick bullet: [Poisonous, deals no damage]")
local GLOBAL_BASEBALLBAT_BOOMERANG_INFO = loc("Bouncy boomerang: [Launch your bouncy boomerang ~ Turns into a present on explosion]")
local GLOBAL_CHEESE_SPECIAL_INFO = loc("Anno 1032: [The explosion will make a strong push ~ No poison]")
local GLOBAL_SEDUCTION_SPECIAL_INFO = loc("Dust storm: [Deals 15 + %s damage to all enemies in the circle]")
local GLOBAL_INVULNERABLE_SPECIAL_INFO = loc("Temporarily increase the damage of duststorm with +7%s, Removes 1 Invurnurable%s")
local GLOBAL_BASEBALLBAT_CRICKET_INFO = loc("Cricket time: [Fire away a 1 sec mine! ~ Cannot be fired close to another hog]")
local GLOBAL_PARACHUTE_SPECIAL_INFO = loc("Drop a bomb: [Drop some heroic wind that will turn into a bomb on impact ~ wont end turn]")
local GLOBAL_HAMMER_ROAR_INFO = loc("Penguin roar: [Deal 15 damage + 10% of your hog’s health to all hogs around you and get 2/3 back]")
local GLOBAL_HAMMER_SWAP_INFO = loc("Disguise as a Rockhopper Penguin: [Swap place with a random enemy hog in the circle]")
local GLOBAL_HAMMER_LONELY_INFO = loc("Lonely Cries: [Rise the water if no hog is in the circle and deal 6 damage to all enemy hogs.]")
local GLOBAL_STICKY_PROJECTILE_INFO = loc("Hedgehog projectile: [Fire your hog like a Sticky Bomb]")
local GLOBAL_STICKY_NAPALM_INFO = loc("Napalm rocket: [Fire a bomb with napalm!]")
local GLOBAL_SHOTGUN_SPECIAL_INFO = loc("Eagle Eye: [Blink to the impact ~ One shot]")
local GLOBAL_MOLOTOV_SPECIAL_INFO = loc("Medicine: [Fire some exploding medicine that will heal 15 hp to all hogs effected by the explosion]")
local GLOBAL_HAMMER_SABOTAGE_INFO = loc("Flare: [Sabotage all hogs in the circle (dmg over time and high gravity) and fire one cluster above you]")
local GLOBAL_PICKHAMMER_SPECIAL_INFO = loc("World wrap: [Will teleport you to the top of the map, expect fall damage]")

local GLOBAL_ALL_SPECIALS_INFO = loc("Weapons with specials: ")..loc("Shotgun")..", "..loc("Sniper Rifle")..", "..loc("GasBomb")..", "..loc("Molotov")..", "..loc("Parachute")..", "..loc("Seduction")..", "..loc("Sticky Mine").." (2),"..loc("Baseballbat (2)")..", "..loc("Hammer (4)")

local GLOBAL_SELECT_WEP_INFORMATION=loc("Select your continent with: the \"Up\" or \"Down\" keys, or by selecting a representative weapon.")
local GLOBAL_GENERAL_INFORMATION="- "..loc("Per team weapons").."|- "..loc("10 weapon schemes").."|- "..loc("Unique new weapons").."| |"..GLOBAL_SELECT_WEP_INFORMATION.."|"..loc("Note: Some weapons have a second option (See continent information). Find and use them with the \"")..loc("switch").."\" "..loc("key").." (↹).|"..GLOBAL_ALL_SPECIALS_INFO.."|"..loc("Tip: See the \"esc\" key (this menu) if you want to see the currently playing teams continent, or that continents specials." .. "|")

local GLOBAL_CONTINENT_INFORMATION = 
{
{loc("North America"),"["..loc("Difficulty: ")..loc("EASY").."] ",loc("- You can switch between hogs at the start of your turns. (Not first one)").."|"..loc("Special Weapons:").."|"..loc("Shotgun")..": "..GLOBAL_SHOTGUN_SPECIAL_INFO.."|"..loc("Sniper Rifle")..": "..GLOBAL_SNIPER_SPECIAL_INFO,{amSniperRifle,1},
{{amShotgun,100},{amDEagle,100},{amLaserSight,2},{amSniperRifle,100},{amCake,1},{amAirAttack,2},{amSwitch,2}},
},
--{sndShotgunFire,sndCover},100},

{loc("South America"),"["..loc("Difficulty: ")..loc("MEDIUM").."] ",loc("Special Weapons:").."|"..loc("GasBomb")..": "..GLOBAL_CHEESE_SPECIAL_INFO,{amGasBomb,2},
{{amBirdy,100},{amHellishBomb,1},{amBee,100},{amGasBomb,100},{amFlamethrower,100},{amNapalm,2},{amExtraDamage,3}},
{sndEggBreak,sndLaugh},125},

{loc("Europe"),"["..loc("Difficulty: ")..loc("EASY").."] ",loc("Special Weapons:").."|"..loc("Molotov")..": "..GLOBAL_MOLOTOV_SPECIAL_INFO,{amBazooka,3},
{{amBazooka,100},{amGrenade,100},{amMortar,100},{amMolotov,100},{amVampiric,4},{amPiano,1},{amResurrector,2},{amJetpack,4}},
{sndExplosion,sndEnemyDown},100},

{loc("Africa"),"["..loc("Difficulty: ")..loc("MEDIUM").."] ",loc("Special Weapons:").."|"..loc("Seduction")..": "..string.format(GLOBAL_SEDUCTION_SPECIAL_INFO,loc("(*see below)")).."|- "..string.format(GLOBAL_INVULNERABLE_SPECIAL_INFO,"","").."|- "..loc("You can modify the damage/invulnerables with the up/down keys on dust storm.").."|"..loc("Sticky Mine")..": "..GLOBAL_STICKY_PROJECTILE_INFO.."|"..loc("Sticky Mine")..": "..GLOBAL_STICKY_NAPALM_INFO,{amSMine,4},
{{amSMine,100},{amWatermelon,1},{amDrillStrike,1},{amDrill,100},{amInvulnerable,7},{amSeduction,100},{amLandGun,3}},
{sndMelonImpact,sndCoward},125},

{loc("Asia"),"["..loc("Difficulty: ")..loc("MEDIUM").."] ",loc("- Will give you a parachute every third turn.").."|"..loc("Special Weapons:").."|"..loc("Parachute")..": "..GLOBAL_PARACHUTE_SPECIAL_INFO,{amRope,5},
{{amRope,100},{amFirePunch,100},{amParachute,1},{amKnife,2},{amDynamite,1}},
{sndRopeAttach,sndComeonthen},50},

{loc("Australia"),"["..loc("Difficulty: ")..loc("EASY").."] ",loc("Special Weapons:").."|"..loc("Baseballbat")..": "..GLOBAL_BASEBALLBAT_CRICKET_INFO.."|"..loc("Baseballbat")..": "..GLOBAL_BASEBALLBAT_BOOMERANG_INFO,{amBaseballBat,6},
{{amBaseballBat,100},{amMine,100},{amLowGravity,4},{amBlowTorch,100},{amRCPlane,2},{amRubber,4}},
{sndBaseballBat,sndNooo},100},

{loc("Antarctica"),"["..loc("Difficulty: ")..loc("HARD").."] ",loc("Antarctic summer: - Will give you girders=1,mudballs=1,sineguns=2,portals=1 every fourth turn.").."|"..loc("Special Weapons:").."|"..loc("Pick hammer")..": "..GLOBAL_PICKHAMMER_SPECIAL_INFO,{amIceGun,7},
{{amSnowball,2},{amPickHammer,100},{amSineGun,4},{amGirder,1},{amExtraTime,1},{amIceGun,1},{amPortalGun,2}},
{sndSineGun,sndOops},75},

{loc("Kerguelen"),"["..loc("Difficulty: ")..loc("EASY").."] ",loc("Special Weapons:").."|"..loc("Hammer")..": "..GLOBAL_HAMMER_ROAR_INFO.."|"..loc("Hammer")..": "..GLOBAL_HAMMER_SWAP_INFO.."|"..loc("Hammer")..": "..GLOBAL_HAMMER_LONELY_INFO.."|"..loc("Hammer")..": "..GLOBAL_HAMMER_SABOTAGE_INFO,{amHammer,8},
{{amHammer,100},{amMineStrike,1},{amBallgun,1},{amTeleport,1}},
{sndPiano5,sndStupid},75},

{loc("Zealandia"),"["..loc("Difficulty: ")..loc("MEDIUM").."] ",loc("- Will Get 1-3 random weapons") .. "|" .. loc("- Massive weapon bonus on first turn|You will lose all your weapons each turn."),{amInvulnerable,9},
{{amBazooka,1},{amGrenade,1},{amBlowTorch,1},{amSwitch,1},{amRope,1},{amDrill,1},{amDEagle,1},{amPickHammer,1},{amFirePunch,1},{amWhip,1},{amMortar,1},{amSnowball,1},{amExtraTime,1},{amInvulnerable,1},{amVampiric,1},{amFlamethrower,1},{amBee,1},{amClusterBomb,1},{amTeleport,1},{amLowGravity,1},{amJetpack,1},{amGirder,1},{amLandGun,1},{amBirdy,1},{amAirMine,1},{amTardis,1},{amLaserSight,1},{amAirMine,1}},
{sndSplash,sndFirstBlood},100},

{loc("Sundaland"),"["..loc("Difficulty: ")..loc("HARD").."] ",loc("- You will recieve 6 weapons on each kill! (Even on own hogs)"),{amTardis,10},
{{amClusterBomb,5},{amTardis,100},{amWhip,100},{amKamikaze,100},{amAirMine,2},{amDuck,2}},
{sndWarp,sndSameTeam},100}

}

--very strange bug
GLOBAL_CONTINENT_INFORMATION[1][7]=100
GLOBAL_CONTINENT_INFORMATION[1][6]={sndShotgunFire,sndCover}

--weapontype,ammo,?,duration,*times your choice,affect on random team (should be placed with 1,0,1,0,1 on the 6th option for better randomness)
local GLOBAL_WEAPONS_DAMAGE = {
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
	{amDuck,        0, 1, 0, 1, 0}
}
local GLOBAL_WEAPONS_SUPPORT = {
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
	local tot=table.maxn(GLOBAL_WEAPONS_SUPPORT)+table.maxn(GLOBAL_WEAPONS_DAMAGE)
	local rand=GetRandom(tot)+1
	
	if(rand>table.maxn(GLOBAL_WEAPONS_SUPPORT))
	then
		local weapon=rand-table.maxn(GLOBAL_WEAPONS_SUPPORT)
	
		while(wepNotValidBorder(GLOBAL_WEAPONS_DAMAGE[weapon][1])==false)
		do
			if(weapon>=table.maxn(GLOBAL_WEAPONS_DAMAGE))
			then
				weapon=0
			end
			weapon = weapon+1
		end
	
		SpawnAmmoCrate(x, y, GLOBAL_WEAPONS_DAMAGE[weapon][1])
	else
		SpawnUtilityCrate(x, y, GLOBAL_WEAPONS_SUPPORT[rand][1])
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
	
	GLOBAL_TEMP_VALUE=GLOBAL_CONTINENT_INFORMATION[num][7]
	runOnGears(SetHogHealth)
end

--list up all weapons from the icons for each continent
function InitWeaponsMenu(hog)

	if(GetHogLevel(hog)==0 or GLOBAL_CONTINENT_INFORMATION[1][6][1]==sndFrozenHogImpact)
	then
		for v,w in pairs(GLOBAL_CONTINENT_INFORMATION) 
		do
			ValidateWeapon(hog, GLOBAL_CONTINENT_INFORMATION[v][4][1],1)
		end
		AddAmmo(hog,amSwitch) --random continent
	
	--for the computers
	else
		--europe
		ValidateWeapon(hog, GLOBAL_CONTINENT_INFORMATION[3][4][1],1)
		--north america
		ValidateWeapon(hog, GLOBAL_CONTINENT_INFORMATION[1][4][1],1)
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
	
	ShowMission(GLOBAL_CONTINENT_INFORMATION[continent][1],GLOBAL_CONTINENT_INFORMATION[continent][2]..loc(" Starting HP: ")..GLOBAL_CONTINENT_INFORMATION[continent][7],GLOBAL_CONTINENT_INFORMATION[continent][3]..geninftext, GLOBAL_CONTINENT_INFORMATION[continent][4][2], time)
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

--give one random weapon
function GetRandomWeapon(hog, weptype, power, onlyonewep, getdelayedweps, mypower)

	local wepout=nil
	local rand_weaponset_power=mypower

	if(rand_weaponset_power < power)
	then
		local numberofweapons=table.maxn(weptype)
	
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
		local currCont=GLOBAL_TEAM_CONTINENT[GetHogTeamName(hog)]
		
		if(currCont~=0)
		then
			local checkDefCont=GLOBAL_CONTINENT_INFORMATION[currCont][4][2]
		
			--for sunda
			local wepamount=getTeamValue(GetHogTeamName(hog), "sundaland-count")
		
			if(checkDefCont==9 and getTeamValue(GetHogTeamName(hog), "rand-done-turn")==false)
			then
				CleanWeapons(hog)

				local rand_weaponset_power = 0
				local currwep
		
				rand_weaponset_power, currwep=GetRandomWeapon(hog,GLOBAL_WEAPONS_DAMAGE,100,true,false,rand_weaponset_power)
				rand_weaponset_power, currwep=GetRandomWeapon(hog,GLOBAL_WEAPONS_SUPPORT,2,true,false,rand_weaponset_power)
				rand_weaponset_power, currwep=GetRandomWeapon(hog,GLOBAL_WEAPONS_DAMAGE,1,true,false,rand_weaponset_power)
			
				setTeamValue(GetHogTeamName(hog), "rand-done-turn", true)
		
			elseif(checkDefCont==10 and wepamount~=nil)
			then
				local loci=0
	
				while(loci<wepamount)
				do
					--6 random weapons
					GetRandomWeapon(hog,GLOBAL_WEAPONS_DAMAGE,100,false,true,0)
					GetRandomWeapon(hog,GLOBAL_WEAPONS_DAMAGE,100,false,true,0)
					GetRandomWeapon(hog,GLOBAL_WEAPONS_DAMAGE,2,false,true,1)
	
					GetRandomWeapon(hog,GLOBAL_WEAPONS_SUPPORT,100,false,true,0)
					GetRandomWeapon(hog,GLOBAL_WEAPONS_SUPPORT,100,false,true,0)
					GetRandomWeapon(hog,GLOBAL_WEAPONS_SUPPORT,100,false,true,0)
		
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
	LoadWeaponset(CurrentHedgehog,GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)])
	
	visualstuff=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-5, vgtDust,0, false)
	v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 = GetVisualGearValues(visualstuff)
	SetVisualGearValues(visualstuff, v1, v2, v3, v4, v5, v6, v7, 2, v9, GetClanColor(GetHogClan(CurrentHedgehog)))
	
	ShowContinentInfo(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)],3000,false)
end

--count hogs in team
function CountHogsInTeam(hog)
	if(GetHogTeamName(hog)==GetHogTeamName(CurrentHedgehog))
	then
		GLOBAL_TEMP_VALUE=GLOBAL_TEMP_VALUE+1
	end
end

--==========================run throw all hog/gear weapons ==========================

function SetHogHealth(hog)
	if(GetGearType(hog) == gtHedgehog and GetHogClan(hog) == GetHogClan(CurrentHedgehog))
	then
		SetHealth(hog, div(GLOBAL_TEMP_VALUE*GLOBAL_HOG_HEALTH,100))
	end
end

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
		local dmg=div((15+GLOBAL_SEDUCTION_INCREASER)*GLOBAL_EXTRA_DAMAGE_IS_ON,100)
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
		if(GetHogClan(hog) ~= GetHogClan(CurrentHedgehog) and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 390, false))
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
	if(GetGearType(hog) == gtHedgehog and hog ~= CurrentHedgehog and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 500, false))
	then
		GLOBAL_TEMP_VALUE=1
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

--south american special (used fire gear)
function SouthAmericaSpecialCheeseExplosion(hog)
	if(GetGearType(hog) == gtHedgehog or GetGearType(hog) == gtMine or GetGearType(hog) == gtExplosives)
	then
		local power_radius_outer=230
		local power_sa=700000
		local hypo=0
		if(gearIsInCircle(hog,GetX(GLOBAL_TEMP_VALUE), GetY(GLOBAL_TEMP_VALUE), power_radius_outer, false))
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
			SetEffect(hog, hePoisoned, 5)
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
			local healthadd=15
			HealHog(hog, healthadd+(div(healthadd*GLOBAL_VAMPIRIC_IS_ON,100)), hog == CurrentHedgehog)
			SetEffect(hog, hePoisoned, false)
			GLOBAL_SABOTAGE_HOGS[hog]=0
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
		local mid=table.maxn(GLOBAL_WEAPONS_DAMAGE)
		local max=mid+table.maxn(GLOBAL_WEAPONS_SUPPORT)
		local ic=(string.byte(string) % max)+1
		
		if(ic>mid)
		then
			ic=GLOBAL_WEAPONS_SUPPORT[ic-mid][1]
		else
			ic=GLOBAL_WEAPONS_DAMAGE[ic][1]
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
		continentinfo[3]="- "..continentinfo[1]..loc(" was extracted from the scheme|- This continent will be able to use the specials from the other continents!")
		
		table.insert(GLOBAL_CONTINENT_INFORMATION, continentinfo)
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
					table.insert(GLOBAL_CONTINENT_INFORMATION, continentinfo)
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
--weapons=<ammo><types>, ammo = ascii[116(1 ammo) to 125(inf ammo)] types = ascii[36(Grenade), 37(Clusterbomb) to 90(knife)] see http://hedgewars.org/kb/AmmoTypes
--ex "Own continent~this continent rocks!~tZ}$" will get 1 knife and inf grenades
function onParameters()
	
	local searchfor="wt=yes"
	local match=string.find(ScriptParam,searchfor, 1)
	
	if(match~=nil)
	then
		GLOBAL_TEMP_VALUE=1

		ScriptParam=string.gsub(ScriptParam,"(,?)"..searchfor.."(,?)","")
	end
	
	searchfor="spec=off"
	match=string.find(ScriptParam,searchfor, 1)
	
	if(match~=nil)
	then
		OPTION_NO_SPECIALS=true

		ScriptParam=string.gsub(ScriptParam,"(,?)"..searchfor.."(,?)","")
	end
	
	searchfor="cont=no"
	match=string.find(ScriptParam,searchfor, 1)
	
	if(match~=nil)
	then
		GLOBAL_CONTINENT_INFORMATION={}

		ScriptParam=string.gsub(ScriptParam,"(,?)"..searchfor.."(,?)","")
	end
	
	if(ScriptParam~=nil)
	then
		local continentinfo=transferableParamToWeaponSet(ScriptParam,amLowGravity)
	
		if(continentinfo~=nil)
		then
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
	ShowMission(loc("Continental supplies"),loc("Let a continent provide your weapons!"),GLOBAL_GENERAL_INFORMATION, -amLowGravity, 0)
	
	local specText="| |"..loc("Additional feautures for this weapon: (Switch/Tab)").."|"
	
	SetAmmoDescriptionAppendix(amSniperRifle,specText..GLOBAL_SNIPER_SPECIAL_INFO)
	SetAmmoDescriptionAppendix(amBaseballBat,specText..GLOBAL_BASEBALLBAT_BOOMERANG_INFO .. "|" .. GLOBAL_BASEBALLBAT_CRICKET_INFO)
	SetAmmoDescriptionAppendix(amGasBomb,specText..GLOBAL_CHEESE_SPECIAL_INFO)
	SetAmmoDescriptionAppendix(amSeduction,specText..GLOBAL_SEDUCTION_SPECIAL_INFO)
	SetAmmoDescriptionAppendix(amInvulnerable,specText..GLOBAL_INVULNERABLE_SPECIAL_INFO)
	SetAmmoDescriptionAppendix(amParachute,specText..GLOBAL_PARACHUTE_SPECIAL_INFO)
	SetAmmoDescriptionAppendix(amHammer,specText..GLOBAL_HAMMER_ROAR_INFO .. "|" .. GLOBAL_HAMMER_SWAP_INFO .. "|" .. GLOBAL_HAMMER_LONELY_INFO .. "|" .. GLOBAL_HAMMER_SABOTAGE_INFO)
	SetAmmoDescriptionAppendix(amSMine,specText..GLOBAL_STICKY_PROJECTILE_INFO .. "|" .. GLOBAL_STICKY_NAPALM_INFO)
	SetAmmoDescriptionAppendix(amShotgun,specText..GLOBAL_SHOTGUN_SPECIAL_INFO)
	SetAmmoDescriptionAppendix(amMolotov,specText..GLOBAL_MOLOTOV_SPECIAL_INFO)
	SetAmmoDescriptionAppendix(amPickHammer,specText..GLOBAL_PICKHAMMER_SPECIAL_INFO)
	
	if(GLOBAL_TEMP_VALUE==1)
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
	GLOBAL_AUSTRALIAN_SPECIAL=0
	GLOBAL_AFRICAN_SPECIAL_SEDUCTION=0
	GLOBAL_SEDUCTION_INCREASER=0
	GLOBAL_SOUTH_AMERICAN_SPECIAL=false
	GLOBAL_AFRICAN_SPECIAL_STICKY=0
	GLOBAL_KERGUELEN_SPECIAL=1
	GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER=1
	GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN=false
	GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON=false
	GLOBAL_EUROPE_SPECIAL=0
	GLOBAL_VAMPIRIC_IS_ON=0
	GLOBAL_EXTRA_DAMAGE_IS_ON=100
	GLOBAL_CRATE_TEST=-1
	GLOBAL_SABOTAGE_COUNTER=0
	GLOBAL_ANTARCTICA_SPECIAL=0
	
	GLOBAL_TEMP_VALUE=0
	
	GLOBAL_SUNDALAND_END_HOG_CONTINENT_NAME=GetHogTeamName(CurrentHedgehog)
	
	--when all hogs are "placed"
	if(GetCurAmmoType()~=amTeleport)
	then
		--will run once when the game really starts (after placing hogs and so on
		if(GLOBAL_INIT_TEAMS[GetHogTeamName(CurrentHedgehog)] == nil)
		then
			SetInputMask(band(0xFFFFFFFF,gmWeapon))
			
			if(GLOBAL_START_TIME==0)
			then
				GLOBAL_START_TIME=TurnTimeLeft
				GLOBAL_HOG_HEALTH=GetHealth(CurrentHedgehog)
			end
			
			TurnTimeLeft=100000
			
			AddCaption(GLOBAL_SELECT_WEP_INFORMATION, GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage)
			ShowMission(loc("Continental supplies"),loc("Let a continent provide your weapons!"),GLOBAL_GENERAL_INFORMATION, -amLowGravity, 0)
			HideMission()
			
			InitWeaponsMenu(CurrentHedgehog)
			GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=0
			GLOBAL_SELECT_CONTINENT_CHECK=true
			GLOBAL_INIT_TEAMS[GetHogTeamName(CurrentHedgehog)] = 2
			
--			if(GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]==1)
--			then
--				GLOBAL_SABOTAGE_COUNTER=-750
--			end
		else
			--if its not the initialization turn
			GLOBAL_SELECT_CONTINENT_CHECK=false
			SetInputMask(0xFFFFFFFF)
			
			if(GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]==0)
			then
				GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=GetRandom(table.maxn(GLOBAL_CONTINENT_INFORMATION))+1
				SetContinentWeapons()
			end
			local currCont=GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]
			local checkDefCont=GLOBAL_CONTINENT_INFORMATION[currCont][4][2]
			
			--give zeelandia-teams new weapons so they can plan for the next turn
			runOnGears(RandomContinentsGetWeapons)
			
			--some specials for some continents (GLOBAL_TEMP_VALUE is from get random weapons)
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
				
				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "Antarctica2-turntick")>=4)
				then
					AddAmmo(CurrentHedgehog,amPortalGun)
					AddAmmo(CurrentHedgehog,amSineGun)
					AddAmmo(CurrentHedgehog,amSineGun)
					AddAmmo(CurrentHedgehog,amGirder)
					AddAmmo(CurrentHedgehog,amSnowball)
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
					AddAmmo(CurrentHedgehog,amParachute)
					setTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick", 0)
				end
				setTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick", getTeamValue(GetHogTeamName(CurrentHedgehog), "Asia-turntick")+1)
			elseif(checkDefCont==1)
			then
				GLOBAL_TEMP_VALUE=0
				runOnGears(CountHogsInTeam)
				
				if(GLOBAL_TEMP_VALUE>1)
				then
					AddAmmo(CurrentHedgehog,amSwitch,GetAmmoCount(CurrentHedgehog, amSwitch)+1)
				
					SetWeapon(amSwitch)
					GLOBAL_TEMP_VALUE=87
				end
			end
			
			ShowContinentInfo(currCont,-1,true)
		end
	end
end

--what happens when you press "tab" (common button)
function onSwitch()
	
	if(GLOBAL_SWITCH_HOG_IS_ON==false)
	then
		if(OPTION_NO_SPECIALS==false and GLOBAL_SELECT_CONTINENT_CHECK==false)
		then
			--place mine (australia)
			if(GetCurAmmoType() == amBaseballBat)
			then
				if(GLOBAL_AUSTRALIAN_SPECIAL==0)
				then
					GLOBAL_AUSTRALIAN_SPECIAL = 1
					AddCaption(GLOBAL_BASEBALLBAT_CRICKET_INFO)
				elseif(GLOBAL_AUSTRALIAN_SPECIAL==1)
				then
					GLOBAL_AUSTRALIAN_SPECIAL = 2
					AddCaption(GLOBAL_BASEBALLBAT_BOOMERANG_INFO)
				else
					GLOBAL_AUSTRALIAN_SPECIAL = 0
					AddCaption(loc("DEFAULT"))
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
				
					AddCaption(string.format(GLOBAL_SEDUCTION_SPECIAL_INFO,GLOBAL_SEDUCTION_INCREASER))
				else
					GLOBAL_AFRICAN_SPECIAL_SEDUCTION = 0
					AddCaption(loc("DEFAULT"))
				end
		
			--south america
			elseif(GetCurAmmoType() == amGasBomb)
			then
				if(GLOBAL_SOUTH_AMERICAN_SPECIAL==false)
				then
					GLOBAL_SOUTH_AMERICAN_SPECIAL = true
					AddCaption(GLOBAL_CHEESE_SPECIAL_INFO)
				else
					GLOBAL_SOUTH_AMERICAN_SPECIAL = false
					AddCaption(loc("DEFAULT"))
				end

			--africa
			elseif(GetCurAmmoType() == amSMine)
			then
				if(GLOBAL_AFRICAN_SPECIAL_STICKY==0)
				then
					GLOBAL_AFRICAN_SPECIAL_STICKY = 1
					AddCaption(GLOBAL_STICKY_PROJECTILE_INFO)
				elseif(GLOBAL_AFRICAN_SPECIAL_STICKY == 1)
				then
					GLOBAL_AFRICAN_SPECIAL_STICKY = 2
					AddCaption(GLOBAL_STICKY_NAPALM_INFO)
				elseif(GLOBAL_AFRICAN_SPECIAL_STICKY == 2)
				then
					GLOBAL_AFRICAN_SPECIAL_STICKY = 0
					AddCaption(loc("DEFAULT"))
				end

			--north america (sniper)
			elseif(GetCurAmmoType() == amSniperRifle and GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER_IS_ON==false)
			then
				if(GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER==2)
				then
					GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER = 1
					AddCaption(loc("DEFAULT"))
				elseif(GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER==1)
				then
					GLOBAL_NORTH_AMERICAN_SPECIAL_SNIPER = 2
					AddCaption(GLOBAL_SNIPER_SPECIAL_INFO)
				end

			--north america (shotgun)
			elseif(GetCurAmmoType() == amShotgun)
			then
				if(GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN==false)
				then
					GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN = true
					AddCaption(GLOBAL_SHOTGUN_SPECIAL_INFO)
				else
					GLOBAL_NORTH_AMERICAN_SPECIAL_SHOTGUN = false
					AddCaption(loc("DEFAULT"))
				end

			--europe
			elseif(GetCurAmmoType() == amMolotov)
			then
				if(GLOBAL_EUROPE_SPECIAL==0)
				then
					GLOBAL_EUROPE_SPECIAL = 1
					AddCaption(GLOBAL_MOLOTOV_SPECIAL_INFO)
				else
					GLOBAL_EUROPE_SPECIAL = 0
					AddCaption(loc("DEFAULT"))
				end
			
			--antarctica
			elseif(GetCurAmmoType() == amPickHammer)
			then
				if(GLOBAL_ANTARCTICA_SPECIAL==0)
				then
					GLOBAL_ANTARCTICA_SPECIAL = 1
					AddCaption(GLOBAL_PICKHAMMER_SPECIAL_INFO)
				else
					GLOBAL_ANTARCTICA_SPECIAL = 0
					AddCaption(loc("DEFAULT"))
				end

			--kerguelen
			elseif(GetCurAmmoType() == amHammer)
			then
				if(GLOBAL_KERGUELEN_SPECIAL==6)
				then
					GLOBAL_KERGUELEN_SPECIAL = 1
					AddCaption("DEFAULT")
				elseif(GLOBAL_KERGUELEN_SPECIAL==1)
				then
					GLOBAL_KERGUELEN_SPECIAL = 2
					AddCaption("#"..GLOBAL_HAMMER_ROAR_INFO)
				elseif(GLOBAL_KERGUELEN_SPECIAL==2)
				then
					GLOBAL_KERGUELEN_SPECIAL = 3
					AddCaption("##"..GLOBAL_HAMMER_SWAP_INFO)
				elseif(GLOBAL_KERGUELEN_SPECIAL==3)
				then
					GLOBAL_KERGUELEN_SPECIAL = 5
					AddCaption("###"..GLOBAL_HAMMER_LONELY_INFO)
				elseif(GLOBAL_KERGUELEN_SPECIAL==5)
				then
					GLOBAL_KERGUELEN_SPECIAL = 6
					AddCaption("####"..GLOBAL_HAMMER_SABOTAGE_INFO)
				end
			end
		end
		--for selecting weaponset, this is mostly for old players.
		if(GetHogLevel(CurrentHedgehog)==0 and GLOBAL_SELECT_CONTINENT_CHECK==true and (GetCurAmmoType() == amSkip or GetCurAmmoType() == amNothing))
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
	
	if(GetCurAmmoType() == amSeduction and GLOBAL_AFRICAN_SPECIAL_SEDUCTION == 1 and GetAmmoCount(CurrentHedgehog,amInvulnerable)>0)
	then
		GLOBAL_SEDUCTION_INCREASER=GLOBAL_SEDUCTION_INCREASER+7
		
		RemoveWeapon(CurrentHedgehog,amInvulnerable)
		
		AddCaption(string.format(GLOBAL_INVULNERABLE_SPECIAL_INFO," ("..(GLOBAL_SEDUCTION_INCREASER+15)..")"," ("..GetAmmoCount(CurrentHedgehog,amInvulnerable)..")"))
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
	
	if(GetCurAmmoType() == amSeduction and GLOBAL_AFRICAN_SPECIAL_SEDUCTION == 1 and GLOBAL_SEDUCTION_INCREASER>0)
	then
		GLOBAL_SEDUCTION_INCREASER=GLOBAL_SEDUCTION_INCREASER-7
		
		AddAmmo(CurrentHedgehog,amInvulnerable,GetAmmoCount(CurrentHedgehog, amInvulnerable)+1)
		
		AddCaption(string.format(GLOBAL_INVULNERABLE_SPECIAL_INFO," ("..(GLOBAL_SEDUCTION_INCREASER+15)..")"," ("..GetAmmoCount(CurrentHedgehog,amInvulnerable)..")"))
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
				if(GetCurAmmoType()==GLOBAL_CONTINENT_INFORMATION[v][4][1])
				then
					GLOBAL_TEAM_CONTINENT[GetHogTeamName(CurrentHedgehog)]=v
					SetContinentWeapons()
					PlaySound(GLOBAL_CONTINENT_INFORMATION[v][6][1])
					PlaySound(GLOBAL_CONTINENT_INFORMATION[v][6][2],CurrentHedgehog)
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
			SetVisualGearValues(GLOBAL_VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 390, 3, 0xffff00ee)
		elseif(GLOBAL_KERGUELEN_SPECIAL == 5) --cries
		then
			
			GLOBAL_TEMP_VALUE=0
			runOnGears(KerguelenSpecialBlueCheck)
			if(GLOBAL_TEMP_VALUE==0)
			then
				SetVisualGearValues(GLOBAL_VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 500, 1, 0x0000ffee)
			else
				SetVisualGearValues(GLOBAL_VISUAL_CIRCLE, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 500, 10, 0x0000ffee)
			end
			
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
			AddCaption(loc("You are sabotaged, RUN!"))
			
			PlaySound(sndHellish)
			--update the constant at the top also to something in between
			GLOBAL_SABOTAGE_FREQUENCY=100
			SetGravity(350)
			
			GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]=2
		end
		
		if(GLOBAL_SABOTAGE_COUNTER % 20 == 0)
		then
			AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmokeWhite, 0, false)
		end
		
		if(TurnTimeLeft<(GetAwayTime*10) or band(GetState(CurrentHedgehog),gstAttacked)==1)
		then
			GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]=0
		elseif(GLOBAL_SABOTAGE_COUNTER >= GLOBAL_SABOTAGE_FREQUENCY)
		then
			
			if(GetHealth(CurrentHedgehog)<=2)
			then
				SetHealth(CurrentHedgehog, 0)
				GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]=0
			else
				SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)-2)
			end
			ShowDamageTag(CurrentHedgehog,2)
			
			GLOBAL_SABOTAGE_COUNTER=0
		else
			GLOBAL_SABOTAGE_COUNTER=GLOBAL_SABOTAGE_COUNTER+1
		end
	elseif(GetGravity()==350 and (GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]==0 or GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]==nil))
	then
		SetGravity(100)
	end
	
	--enable switch (north america)
	if(GetCurAmmoType() == amSwitch and GLOBAL_TEMP_VALUE==87)
	then
		SetGearMessage(CurrentHedgehog,gmAttack)
		GLOBAL_TEMP_VALUE=0
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
	if(GLOBAL_SELECT_CONTINENT_CHECK==true)
	then
		if(GetCurAmmoType() == amSkip or GetCurAmmoType() == amNothing)
		then
			GLOBAL_SELECT_CONTINENT_CHECK=false
			EndTurn(0)
		else
			SetWeapon(amSkip)
		end
	end
	
	--african special
	if(GLOBAL_AFRICAN_SPECIAL_SEDUCTION == 1 and GetCurAmmoType() == amSeduction and band(GetState(CurrentHedgehog),gstAttacked)==0)
	then
		EndTurn(3)
		
		GLOBAL_TEMP_VALUE=0
		runOnGears(AfricaSpecialSeduction)
		SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+GLOBAL_TEMP_VALUE)

		--visual stuff
		VisualExplosion(250,GetX(CurrentHedgehog), GetY(CurrentHedgehog),vgtSmoke,vgtSmokeWhite)
		PlaySound(sndParachute)
		
		RemoveWeapon(CurrentHedgehog,amSeduction)
	
	elseif(GLOBAL_ANTARCTICA_SPECIAL == 1 and GetCurAmmoType() == amPickHammer and band(GetState(CurrentHedgehog),gstAttacked)==0)
	then
		EndTurn(10)
		SetGearPosition(CurrentHedgehog,GetX(CurrentHedgehog),0)
		ParseCommand("hjump")
		SetGearVelocity(CurrentHedgehog, 0, 100000000)
		
		PlaySound(sndPiano8)
		
		RemoveWeapon(CurrentHedgehog,amPickHammer)
	
	--Kerguelen specials
	elseif(GetCurAmmoType() == amHammer and GLOBAL_KERGUELEN_SPECIAL > 1 and band(GetState(CurrentHedgehog),gstAttacked)==0)
	then
		local escapetime=3
	
		--scream
		if(GLOBAL_KERGUELEN_SPECIAL == 2)
		then
			GLOBAL_TEMP_VALUE=0
			runOnGears(KerguelenSpecialRed)
			HealHog(CurrentHedgehog, GLOBAL_TEMP_VALUE)
			PlaySound(sndHellish)
		
		--swap
		elseif(GLOBAL_KERGUELEN_SPECIAL == 3)
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
			GLOBAL_TEMP_VALUE=0
			runOnGears(KerguelenSpecialBlueCheck)
			if(GLOBAL_TEMP_VALUE==0)
			then
				AddGear(0, 0, gtWaterUp, 0, 0,0,0)
				PlaySound(sndWarp)
				PlaySound(sndMolotov)
				
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
			
			PlaySound(sndThrowRelease)
			AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-20, gtCluster, 0, 0, -1000000, 32)
			
			if(GLOBAL_TEMP_VALUE==1)
			then
				escapetime=10
			end
		end
		
		EndTurn(escapetime)
		
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
				local austmine=FireGear(CurrentHedgehog,gtBall, vx, vy, 1)
				--SetHealth(austmine, 1)
				SetTimer(austmine, 1000)
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

function onGearDamage(gearUid, damage)
	if (GetGearType(gearUid) == gtCase)
	then
		GLOBAL_CRATE_TEST=gearUid
	end
	
	if(gearUid==CurrentHedgehog and GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]==1)
	then
		GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]=0
	end
end

function onGearDelete(gearUid)

	if(GetGearType(gearUid) == gtHedgehog or GetGearType(gearUid) == gtMine or GetGearType(gearUid) == gtExplosives) 
	then
		--sundaland special
		if(GetGearType(gearUid) == gtHedgehog and GLOBAL_TEAM_CONTINENT[GLOBAL_SUNDALAND_END_HOG_CONTINENT_NAME]==10)
		then		
			local currvalue=getTeamValue(GLOBAL_SUNDALAND_END_HOG_CONTINENT_NAME, "sundaland-count")
			
			if(currvalue==nil)
			then
				currvalue=0
			end
			
			setTeamValue(GLOBAL_SUNDALAND_END_HOG_CONTINENT_NAME, "sundaland-count", currvalue+1)
			PlaySound(sndReinforce,CurrentHedgehog)
		end
	
		trackDeletion(gearUid)
	end
	
	--if picking up a health crate
	if(GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]~=0 and GetGearType(gearUid) == gtCase and GetHealth(gearUid)~=0 and gearUid~=GLOBAL_CRATE_TEST and gearIsInCircle(CurrentHedgehog,GetX(gearUid), GetY(gearUid), 50, false)==true)
	then
		GLOBAL_SABOTAGE_HOGS[CurrentHedgehog]=0
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
	elseif(GetGearType(gearUid)==gtBall and GetGearMessage(gearUid)==3)
	then
		SpawnRandomCrate(GetX(gearUid), GetY(gearUid))
		
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

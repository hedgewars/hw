--[[
Made for 0.9.20

Copyright (C) 2012 Vatten

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

function int_sqrt(num)
	local temp=num
	while(temp*temp-div(temp,2)>num)
	do
		temp=div((temp+div(num,temp)),2)
	end
	
	return math.abs(temp)
end

function norm(xx,yy)
	--to fix overflows
	if(((math.abs(xx)^2)+(math.abs(yy)^2))>2^26)
	then
		local bitr=2^13
		return int_sqrt((div(math.abs(xx),bitr)^2)+(div(math.abs(yy),bitr)^2))*bitr
	else
		return int_sqrt((math.abs(xx)^2)+(math.abs(yy)^2))
	end
end

function positive(num)
	if(num<0)
	then
		return -1
	else
		return 1
	end
end

function EndTurn(baseRetreatTime)
	local retreatTimePercentage = 100
	SetState(CurrentHedgehog,bor(GetState(CurrentHedgehog),gstAttacked))
	TurnTimeLeft = baseRetreatTime / 100 * retreatTimePercentage
 end

--for sundaland
local turnhog=0

local teams_ok = {}
local wepcode_teams={}
local swapweps=false

--variables for seeing if you have swaped around on a weapon
local australianSpecial=false
local africanSpecial=0
local africaspecial2=0
local samericanSpecial=false
local namericanSpecial=1
local sniper_s_in_use=false
local kergulenSpecial=1
local shotgun_s=false
local europe_s=0
local VampOn=0

local austmine=nil
local inpara=false
local asianflame=0

local visualcircle=nil

local temp_val=0

--for sabotage
local disallowattack=0
local disable_moving={}
local disableRand=0
--local disableoffsetai=0
local onsabotageai=false

local continent = {}

local generalinfo="- "..loc("Per team weapons").."|- 10 "..loc("weaponschemes").."|- "..loc("Unique new weapons").."| |"..loc("Select continent first round with the Weapon Menu or by").." (["..loc("switch").."/"..loc("tab").."]="..loc("Increase")..",["..loc("presice").."/"..loc("left shift").."]="..loc("Decrease")..") "..loc("on Skip").."|"..loc("Some weapons have a second option. Find them with").." ["..loc("switch").."/"..loc("tab").."]"

local weapontexts = {
loc("Green lipstick bullet: [Poisonous, deals no damage]"),
loc("REMOVED"),
loc("Anno 1032: [The explosion will make a strong push ~ Wide range, wont affect hogs close to the target]"),
loc("Dust storm: [Deals 15 damage to all enemies in the circle]"),
loc("Cricket time: [Drop a fireable mine! ~ Will work if fired close to your hog & far away from enemy ~ 1 sec]"),
loc("Drop a bomb: [Drop some heroic wind that will turn into a bomb on impact]"),
loc("Penguin roar: [Deal 15 damage + 15% of your hogs health to all hogs around you and get 2/3 back]"),
loc("Disguise as a Rockhopper Penguin: [Swap place with a random enemy hog in the circle]"),
loc("REMOVED"),
loc("Lonely Cries: [Rise the water if no hog is in the circle and deal 7 damage to all enemy hogs]"),
loc("Hedgehog projectile: [Fire your hog like a Sticky Bomb]"),
loc("Napalm rocket: [Fire a bomb with napalm!]"),
loc("Eagle Eye: [Blink to the impact ~ One shot]"),
loc("Medicine: [Fire some exploding medicine that will heal all hogs effected by the explosion]"),
loc("Sabotage/Flare: [Sabotage all hogs in the circle and deal ~1 dmg OR Fire a cluster up into the air]")
}

local weaponsets = 
{
{loc("North America"),loc("Area")..": 24,709,000 km2, "..loc("Population")..": 529,000,000",loc("- Will give you an airstrike every fifth turn.").."|"..loc("Special Weapons:").."|"..loc("Shotgun")..": "..weapontexts[13].."|"..loc("Sniper Rifle")..": "..weapontexts[1],amSniperRifle,
{{amShotgun,100},{amDEagle,100},{amLaserSight,4},{amSniperRifle,100},{amCake,1},{amAirAttack,2},{amSwitch,5}}},

{loc("South America"),loc("Area")..": 17,840,000 km2, "..loc("Population")..": 387,000,000",loc("Special Weapons:").."|"..loc("GasBomb")..": "..weapontexts[3],amGasBomb,
{{amBirdy,100},{amHellishBomb,1},{amBee,100},{amGasBomb,100},{amFlamethrower,100},{amNapalm,1},{amExtraDamage,3}}},

{loc("Europe"),loc("Area")..": 10,180,000 km2, "..loc("Population")..": 740,000,000",loc("Special Weapons:").."|"..loc("Molotov")..": "..weapontexts[14],amBazooka,
{{amBazooka,100},{amGrenade,100},{amMortar,100},{amMolotov,100},{amVampiric,3},{amPiano,1},{amResurrector,2},{amJetpack,4}}},

{loc("Africa"),loc("Area")..": 30,222,000 km2, "..loc("Population")..": 1,033,000,000",loc("Special Weapons:").."|"..loc("Seduction")..": "..weapontexts[4].."|"..loc("Sticky Mine")..": "..weapontexts[11].."|"..loc("Sticky Mine")..": "..weapontexts[12],amSMine,
{{amSMine,100},{amWatermelon,1},{amDrillStrike,1},{amDrill,100},{amInvulnerable,4},{amSeduction,100},{amLandGun,2}}},

{loc("Asia"),loc("Area")..": 44,579,000 km2, "..loc("Population")..": 3,880,000,000",loc("- Will give you a parachute every second turn.").."|"..loc("Special Weapons:").."|"..loc("Parachute")..": "..weapontexts[6],amRope,
{{amRope,100},{amFirePunch,100},{amParachute,1},{amKnife,2},{amDynamite,1}}},

{loc("Australia"),loc("Area")..": 8,468,000 km2, "..loc("Population")..": 31,000,000",loc("Special Weapons:").."|"..loc("Baseballbat")..": "..weapontexts[5],amBaseballBat,
{{amBaseballBat,100},{amMine,100},{amLowGravity,4},{amBlowTorch,100},{amRCPlane,2},{amTeleport,3}}},

{loc("Antarctica"),loc("Area")..": 14,000,000 km2, "..loc("Population")..": ~1,000",loc("Antarctic summer: - Will give you one girder/mudball and two sineguns/portals every fourth turn."),amIceGun,
{{amSnowball,2},{amIceGun,2},{amPickHammer,100},{amSineGun,4},{amGirder,2},{amExtraTime,2},{amPortalGun,2}}},

{loc("Kerguelen"),loc("Area")..": 1,100,000 km2, "..loc("Population")..": ~100",loc("Special Weapons:").."|"..loc("Hammer")..": "..weapontexts[7].."|"..loc("Hammer")..": "..weapontexts[8].." ("..loc("Duration")..": 2)|"..loc("Hammer")..": "..weapontexts[10].."|"..loc("Hammer")..": "..weapontexts[15],amHammer,
{{amHammer,100},{amMineStrike,2},{amBallgun,1}}},

{loc("Zealandia"),loc("Area")..": 3,500,000 km2, "..loc("Population")..": 5,000,000",loc("- Will Get 1-3 random weapons") .. "|" .. loc("- Massive weapon bonus on first turn"),amInvulnerable,
{{amBazooka,1},{amGrenade,1},{amBlowTorch,1},{amSwitch,100},{amRope,1},{amDrill,1},{amDEagle,1},{amPickHammer,1},{amFirePunch,1},{amWhip,1},{amMortar,1},{amSnowball,1},{amExtraTime,1},{amInvulnerable,1},{amVampiric,1},{amFlamethrower,1},{amBee,1},{amClusterBomb,1},{amTeleport,1},{amLowGravity,1},{amJetpack,1},{amGirder,1},{amLandGun,1},{amBirdy,1}}},

{loc("Sundaland"),loc("Area")..": 1,850,000 km2, "..loc("Population")..": 290,000,000",loc("- You will recieve 2-4 weapons on each kill! (Even on own hogs)"),amTardis,
{{amClusterBomb,3},{amTardis,4},{amWhip,100},{amKamikaze,4}}}

}

local weaponsetssounds=
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
	{sndWarp,sndSameTeam}
}

--weapontype,ammo,?,duration,*times your choice,affect on random team (should be placed with 1,0,1,0,1 on the 6th option for better randomness)
local weapons_dmg = {
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
	{amBirdy, 0, 1, 0, 1, 0},
	{amBlowTorch, 0, 1, 0, 1, 0},
	{amRCPlane, 0, 1, 5, 1, 2},
	{amGasBomb, 0, 0, 0, 1, 0},
	{amAirAttack, 0, 1, 4, 1, 1},
	{amFlamethrower, 0, 1, 0, 1, 0},
	{amSMine, 0, 1, 0, 1, 1},
	{amHammer, 0, 1, 0, 1, 0},
	{amDrillStrike, 0, 1, 4, 1, 2},
	{amSnowball, 0, 1, 0, 1, 0}
}
local weapons_supp = {
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
	{amKnife, 0, 1, 0, 1, 0}
}

--will check after borders and stuff
function validate_weapon(hog,weapon,amount)
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

function RemoveWeapon(hog,weapon)

	if(GetAmmoCount(hog, weapon)<100)
	then
		AddAmmo(hog,weapon,GetAmmoCount(hog, weapon)-1)
	end
end

--reset all weapons for a team
function cleanweps(hog)

	local i=1
	--+1 for skip +1 for freezer
	while(i<=table.maxn(weapons_supp)+table.maxn(weapons_dmg)+2)
	do
		AddAmmo(hog,i,0)
		i=i+1
	end
	
	AddAmmo(hog,amSkip,100)
end

--get the weapons from a weaponset
function load_weaponset(hog, num)
	for v,w in pairs(weaponsets[num][5]) 
	do
		validate_weapon(hog, w[1],w[2])
	end
end

--list up all weapons from the icons for each continent
function load_continent_selection(hog)

	if(GetHogLevel(hog)==0)
	then
		for v,w in pairs(weaponsets) 
		do
			validate_weapon(hog, weaponsets[v][4],1)
		end
		AddAmmo(hog,amSwitch) --random continent
	
	--for the computers
	else
		--europe
		validate_weapon(hog, weaponsets[3][4],1)
		--north america
		validate_weapon(hog, weaponsets[1][4],1)
	end
end

--shows the continent info
function show_continent_info(continent,time,generalinf)
	local geninftext=""
	local ns=false
	if(time==-1)
	then
		time=0
		ns=true
	end
	if(generalinf)
	then
		geninftext="| |"..loc("General information")..": |"..generalinfo
	end
	ShowMission(weaponsets[continent][1],weaponsets[continent][2],weaponsets[continent][3]..geninftext, -weaponsets[continent][4], time)
	if(ns)
	then
		HideMission()
	end
end

--will show a circle of gears (eye candy)
function visual_gear_explosion(range,xpos,ypos,gear1,gear2)
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
function get_random_weapon(hog)
	if(GetGearType(hog) == gtHedgehog and continent[GetHogTeamName(hog)]==9 and getTeamValue(GetHogTeamName(hog), "rand-done-turn")==nil)
	then
		cleanweps(hog)
	
		local random_weapon = 0
		local old_rand_weap = 0
		local rand_weaponset_power = 0
		
		local numberof_weapons_supp=table.maxn(weapons_supp)
		local numberof_weapons_dmg=table.maxn(weapons_dmg)
		
		local rand1=math.abs(GetRandom(numberof_weapons_supp)+1)
		local rand2=math.abs(GetRandom(numberof_weapons_dmg)+1)
		
		random_weapon = math.abs(GetRandom(table.maxn(weapons_dmg))+1)
		
		while(weapons_dmg[random_weapon][4]>TotalRounds or (MapHasBorder() == true and (weapons_dmg[random_weapon][1]== amAirAttack or weapons_dmg[random_weapon][1] == amMineStrike or weapons_dmg[random_weapon][1] == amNapalm or weapons_dmg[random_weapon][1] == amDrillStrike or weapons_dmg[random_weapon][1] == amPiano)))
		do
			if(random_weapon>=numberof_weapons_dmg)
			then
				random_weapon=0
			end
			random_weapon = random_weapon+1
		end
		validate_weapon(hog, weapons_dmg[random_weapon][1],1)
		rand_weaponset_power=weapons_dmg[random_weapon][6]
		old_rand_weap = random_weapon
		
		if(rand_weaponset_power <2)
		then
			random_weapon = rand1
			while(weapons_supp[random_weapon][4]>TotalRounds or rand_weaponset_power+weapons_supp[random_weapon][6]>2)
			do
				if(random_weapon>=numberof_weapons_supp)
				then
					random_weapon=0
				end
				random_weapon = random_weapon+1
			end
			validate_weapon(hog, weapons_supp[random_weapon][1],1)
			rand_weaponset_power=rand_weaponset_power+weapons_supp[random_weapon][6]
		end
		--check again if  the power is enough
		if(rand_weaponset_power <1)
		then
			random_weapon = rand2
			while(weapons_dmg[random_weapon][4]>TotalRounds or old_rand_weap == random_weapon or weapons_dmg[random_weapon][6]>0 or (MapHasBorder() == true and (weapons_dmg[random_weapon][1]== amAirAttack or weapons_dmg[random_weapon][1] == amMineStrike or weapons_dmg[random_weapon][1] == amNapalm or weapons_dmg[random_weapon][1] == amDrillStrike or weapons_dmg[random_weapon][1] == amPiano)))
			do
				if(random_weapon>=numberof_weapons_dmg)
				then
					random_weapon=0
				end
				random_weapon = random_weapon+1
			end
			validate_weapon(hog, weapons_dmg[random_weapon][1],1)
		end
			
		setTeamValue(GetHogTeamName(hog), "rand-done-turn", true)
	end
end

--sundaland add weps
function get_random_weapon_on_death(hog)
	
		local random_weapon = 0
		local old_rand_weap = 0
		local rand_weaponset_power = 0
		
		local firstTurn=0
		
		local numberof_weapons_supp=table.maxn(weapons_supp)
		local numberof_weapons_dmg=table.maxn(weapons_dmg)
		
		local rand1=GetRandom(numberof_weapons_supp)+1
		local rand2=GetRandom(numberof_weapons_dmg)+1
		local rand3=GetRandom(numberof_weapons_dmg)+1
		
		random_weapon = GetRandom(numberof_weapons_dmg)+1
		
		if(TotalRounds<0)
		then
			firstTurn=-TotalRounds
		end
		
		while(weapons_dmg[random_weapon][4]>(TotalRounds+firstTurn) or (MapHasBorder() == true and (weapons_dmg[random_weapon][1]== amAirAttack or weapons_dmg[random_weapon][1] == amMineStrike or weapons_dmg[random_weapon][1] == amNapalm or weapons_dmg[random_weapon][1] == amDrillStrike or weapons_dmg[random_weapon][1] == amPiano)))
		do
			if(random_weapon>=numberof_weapons_dmg)
			then
				random_weapon=0
			end
			random_weapon = random_weapon+1
		end
		validate_weapon(hog, weapons_dmg[random_weapon][1],1)
		rand_weaponset_power=weapons_dmg[random_weapon][6]
		old_rand_weap = random_weapon
		
		random_weapon = rand1
		while(weapons_supp[random_weapon][4]>(TotalRounds+firstTurn) or rand_weaponset_power+weapons_supp[random_weapon][6]>2)
		do
			if(random_weapon>=numberof_weapons_supp)
			then
				random_weapon=0
			end
			random_weapon = random_weapon+1
		end
		validate_weapon(hog, weapons_supp[random_weapon][1],1)
		rand_weaponset_power=rand_weaponset_power+weapons_supp[random_weapon][6]
		
		--check again if  the power is enough
		if(rand_weaponset_power <2)
		then
			random_weapon = rand2
			while(weapons_dmg[random_weapon][4]>(TotalRounds+firstTurn) or old_rand_weap == random_weapon or weapons_dmg[random_weapon][6]>0 or (MapHasBorder() == true and (weapons_dmg[random_weapon][1]== amAirAttack or weapons_dmg[random_weapon][1] == amMineStrike or weapons_dmg[random_weapon][1] == amNapalm or weapons_dmg[random_weapon][1] == amDrillStrike or weapons_dmg[random_weapon][1] == amPiano)))
			do
				if(random_weapon>=numberof_weapons_dmg)
				then
					random_weapon=0
				end
				random_weapon = random_weapon+1
			end
			validate_weapon(hog, weapons_dmg[random_weapon][1],1)
			rand_weaponset_power=weapons_dmg[random_weapon][6]
		end
		
		if(rand_weaponset_power <1)
		then
			random_weapon = rand3
			while(weapons_dmg[random_weapon][4]>(TotalRounds+firstTurn) or old_rand_weap == random_weapon or weapons_dmg[random_weapon][6]>0 or (MapHasBorder() == true and (weapons_dmg[random_weapon][1]== amAirAttack or weapons_dmg[random_weapon][1] == amMineStrike or weapons_dmg[random_weapon][1] == amNapalm or weapons_dmg[random_weapon][1] == amDrillStrike or weapons_dmg[random_weapon][1] == amPiano)))
			do
				if(random_weapon>=numberof_weapons_dmg)
				then
					random_weapon=0
				end
				random_weapon = random_weapon+1
			end
			validate_weapon(hog, weapons_dmg[random_weapon][1],1)
		end
		
		AddVisualGear(GetX(hog), GetY(hog)-30, vgtEvilTrace,0, false)
		PlaySound(sndReinforce,hog)
end


--this will take that hogs settings for the weapons and add them
function setweapons()

	cleanweps(CurrentHedgehog)
	load_weaponset(CurrentHedgehog,continent[GetHogTeamName(CurrentHedgehog)])
	
	visualstuff=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-5, vgtDust,0, false)
	v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 = GetVisualGearValues(visualstuff)
	SetVisualGearValues(visualstuff, v1, v2, v3, v4, v5, v6, v7, 2, v9, GetClanColor(GetHogClan(CurrentHedgehog)))
	
	show_continent_info(continent[GetHogTeamName(CurrentHedgehog)],0,false)
end

--show health tag (will mostly be used when a hog is damaged)
function show_damage_tag(hog,damage)
	healthtag=AddVisualGear(GetX(hog), GetY(hog), vgtHealthTag, damage, false)
	v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 = GetVisualGearValues(healthtag)
	SetVisualGearValues(healthtag, v1, v2, v3, v4, v5, v6, v7, v8, v9, GetClanColor(GetHogClan(hog)))
end

--will use int_sqrt
function fire_gear(hedgehog,geartype,vx,vy,timer)
	local hypo=norm(vx,vy)
	return AddGear(div((GetGearRadius(hedgehog)*2*vx),hypo)+GetX(hedgehog), div((GetGearRadius(hedgehog)*2*vy),hypo)+GetY(hedgehog), geartype, 0, vx, vy, timer)
end

--==========================run throw all hog/gear weapons ==========================
--will check if the mine is nicely placed 
function weapon_aust_check(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 50, false)==true and hog ~= CurrentHedgehog)
		then
			temp_val=1
		end
	end
end

--african special on sedunction
function weapon_duststorm(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		local dmg=15
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 250, false)==true and GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			if(GetHealth(hog) > dmg)
			then
				temp_val=temp_val+div(dmg*VampOn,100)
				SetHealth(hog, GetHealth(hog)-dmg)
			else
				temp_val=temp_val+div(GetHealth(hog)*VampOn,100)
				SetHealth(hog, 0)
			end
			show_damage_tag(hog,dmg)
		end
	end
end

--kerguelen special on structure 
function weapon_scream_pen(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 120, false)==true and GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			local dmg=15+GetHealth(CurrentHedgehog)*0.15
		
			if(GetHealth(hog)>dmg)
			then
				temp_val=temp_val+div(dmg*2,3)+div(dmg*VampOn*2,100*3)
				SetHealth(hog, GetHealth(hog)-dmg)
			else
				temp_val=temp_val+(GetHealth(hog)*0.75)+(GetHealth(CurrentHedgehog)*0.1)+div((GetHealth(hog)+(GetHealth(CurrentHedgehog)*0.15))*VampOn,100)
				SetHealth(hog, 0)
			end
			show_damage_tag(hog,dmg)
			AddVisualGear(GetX(hog), GetY(hog), vgtExplosion, 0, false)
			AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmokeWhite, 0, false)
		end
	end
end

--kerguelen special swap hog
function weapon_swap_kerg(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(kergulenSpecial ~= -1 and GetHogClan(hog) ~= GetHogClan(CurrentHedgehog) and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 450, false))
		then
			local thisX=GetX(CurrentHedgehog)
			local thisY=GetY(CurrentHedgehog)
			SetGearPosition(CurrentHedgehog, GetX(hog), GetY(hog))
			SetGearPosition(hog, thisX, thisY)
			kergulenSpecial=-1
		end
	end
end

--kerguelen special will apply sabotage
function weapon_sabotage(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(CurrentHedgehog~=hog and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 80, false))
		then
			temp_val=1
			disable_moving[hog]=true
			AddGear(GetX(hog), GetY(hog), gtCluster, 0, 0, 0, 1)
			PlaySound(sndNooo,hog)
		end
	end
end

--south american special (used fire gear)
function weapon_anno_south(hog)
	local power_radius_outer=230
	local power_radius_inner=45
	local power_sa=500000
	local hypo=0
	if(gearIsInCircle(hog,GetX(temp_val), GetY(temp_val), power_radius_outer, false) and gearIsInCircle(hog,GetX(temp_val), GetY(temp_val), power_radius_inner, false)==false)
	then
		if(hog == CurrentHedgehog)
		then
			SetState(CurrentHedgehog, gstMoving)
		end
		SetGearPosition(hog, GetX(hog),GetY(hog)-3)
		hypo=norm(math.abs(GetX(hog)-GetX(temp_val)),math.abs(GetY(hog)-GetY(temp_val)))
		SetGearVelocity(hog, div((power_radius_outer-hypo)*power_sa*positive(GetX(hog)-GetX(temp_val)),power_radius_outer), div((power_radius_outer-hypo)*power_sa*positive(GetY(hog)-GetY(temp_val)),power_radius_outer))
	end
end

--first part on kerguelen special (lonely cries)
function weapon_cries_a(hog)
	if(GetGearType(hog) == gtHedgehog and hog ~= CurrentHedgehog and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 500, false))
	then
		kergulenSpecial=-1
	end
end

--second part on kerguelen special (lonely cries)
function weapon_cries_b(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		local dmg=7
		if(GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			if(GetHealth(hog) > dmg)
			then
				temp_val=temp_val+div(dmg*VampOn,100)
				SetHealth(hog, GetHealth(hog)-dmg)
			else
				temp_val=temp_val+div(GetHealth(hog)*VampOn,100)
				SetHealth(hog, 0)
			end
			show_damage_tag(hog,dmg)
			AddVisualGear(GetX(hog), GetY(hog)-30, vgtEvilTrace, 0, false)
		end
	end
end

--north american special on sniper
function weapon_lipstick(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(temp_val,GetX(hog), GetY(hog), 20, false))
		then
			SetEffect(hog, hePoisoned, 1)
			PlaySound(sndBump)
		end
	end
end

--european special on molotov (used fire gear)
function weapon_health(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(temp_val,GetX(hog), GetY(hog), 100, false))
		then
			SetHealth(hog, GetHealth(hog)+25+(div(25*VampOn,100)))
			SetEffect(hog, hePoisoned, false)
		end
	end
end

--for sundaland
function find_other_hog_in_team(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(GetHogTeamName(turnhog)==GetHogTeamName(hog))
		then
			turnhog=hog
		end
	end
end
--============================================================================

--set each weapons settings
function onAmmoStoreInit()

	SetAmmo(amSkip, 9, 0, 0, 0)
	
	for v,w in pairs(weapons_dmg) 
	do
		SetAmmo(w[1], w[2], w[3], w[4], w[5])
	end
	
	for v,w in pairs(weapons_supp) 
	do
		SetAmmo(w[1], w[2], w[3], w[4], w[5])
	end
end

function onGameStart()
	--trackTeams()

	ShowMission(loc("Continental supplies"),loc("Let a Continent provide your weapons!"),
	generalinfo, -amLowGravity, 0)
end

--what happen when a turn starts
function onNewTurn()
	
	--will refresh the info on each tab weapon
	australianSpecial=true
	austmine=nil
	africanSpecial=0
	samericanSpecial=false
	africaspecial2=0
	kergulenSpecial=1
	namericanSpecial=1
	asianflame=0
	shotgun_s=false
	sniper_s_in_use=false
	europe_s=0
	VampOn=0
	
	temp_val=0
	
	turnhog=CurrentHedgehog
	
	--for sabotage
	if(disable_moving[CurrentHedgehog]==true)
	then
		disallowattack=-100
		disableRand=GetRandom(3)+5
	end
	
	--when all hogs are "placed"
	if(GetCurAmmoType()~=amTeleport)
	then
		--will run once when the game really starts (after placing hogs and so on
		if(teams_ok[GetHogTeamName(CurrentHedgehog)] == nil)
		then
			AddCaption("["..loc("Select continent!").."]")
			load_continent_selection(CurrentHedgehog)
			continent[GetHogTeamName(CurrentHedgehog)]=0
			swapweps=true
			teams_ok[GetHogTeamName(CurrentHedgehog)] = 2
			
			if(disable_moving[CurrentHedgehog]==true)
			then
				disallowattack=-1000
			end
		else
			--if its not the initialization turn
			swapweps=false
			if(continent[GetHogTeamName(CurrentHedgehog)]==0)
			then
				continent[GetHogTeamName(CurrentHedgehog)]=GetRandom(table.maxn(weaponsets))+1
				setweapons()
			end
			show_continent_info(continent[GetHogTeamName(CurrentHedgehog)],-1,true)
			
			--give zeelandia-teams new weapons so they can plan for the next turn
			runOnGears(get_random_weapon)
			
			--some specials for some continents (temp_val is from get random weapons)
			if(continent[GetHogTeamName(CurrentHedgehog)]==9)
			then
				setTeamValue(GetHogTeamName(CurrentHedgehog), "rand-done-turn", nil)
			elseif(continent[GetHogTeamName(CurrentHedgehog)]==7)
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
				
			elseif(continent[GetHogTeamName(CurrentHedgehog)]==5)
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
			elseif(continent[GetHogTeamName(CurrentHedgehog)]==1)
			then
				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "NA-turntick")==nil)
				then
					setTeamValue(GetHogTeamName(CurrentHedgehog), "NA-turntick", 1)
				end
				
				if(getTeamValue(GetHogTeamName(CurrentHedgehog), "NA-turntick")>=5)
				then
					validate_weapon(CurrentHedgehog,amAirAttack,1)
					setTeamValue(GetHogTeamName(CurrentHedgehog), "NA-turntick", 0)
				end
				setTeamValue(GetHogTeamName(CurrentHedgehog), "NA-turntick", getTeamValue(GetHogTeamName(CurrentHedgehog), "NA-turntick")+1)
			end
		end
	end
end

--what happens when you press "tab" (common button)
function onSwitch()
	
	--place mine (australia)
	if(GetCurAmmoType() == amBaseballBat and australianSpecial==true)
	then
		temp_val=0
		runOnGears(weapon_aust_check)
		
		if(temp_val==0)
		then
			austmine=AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)+5, gtMine, 0, 0, 0, 0)
			SetHealth(austmine, 100)
			SetTimer(austmine, 1000)
			australianSpecial=false
			swapweps=false
		else
			PlaySound(sndDenied)
		end

	--Asian special
	elseif(inpara==1)
	then
		asiabomb=AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)+3, gtSnowball, 0, 0, 0, 0)
		SetGearMessage(asiabomb, 1)

		inpara=2
		swapweps=false

	--africa
	elseif(GetCurAmmoType() == amSeduction)
	then
		if(africanSpecial==0)
		then
			africanSpecial = 1
			AddCaption(weapontexts[4])
		else
			africanSpecial = 0
			AddCaption(loc("NORMAL"))
		end

	--south america
	elseif(GetCurAmmoType() == amGasBomb)
	then
		if(samericanSpecial==false)
		then
			samericanSpecial = true
			AddCaption(weapontexts[3])
		else
			samericanSpecial = false
			AddCaption(loc("NORMAL"))
		end

	--africa
	elseif(GetCurAmmoType() == amSMine)
	then
		if(africaspecial2==0)
		then
			africaspecial2 = 1
			AddCaption(weapontexts[11])
		elseif(africaspecial2 == 1)
		then
			africaspecial2 = 2
			AddCaption(weapontexts[12])
		elseif(africaspecial2 == 2)
		then
			africaspecial2 = 0
			AddCaption(loc("NORMAL"))
		end

	--north america (sniper)
	elseif(GetCurAmmoType() == amSniperRifle and sniper_s_in_use==false)
	then
		if(namericanSpecial==2)
		then
			namericanSpecial = 1
			AddCaption(loc("NORMAL"))
		elseif(namericanSpecial==1)
		then
			namericanSpecial = 2
			AddCaption("#"..weapontexts[1])
		end

	--north america (shotgun)
	elseif(GetCurAmmoType() == amShotgun and shotgun_s~=nil)
	then
		if(shotgun_s==false)
		then
			shotgun_s = true
			AddCaption(weapontexts[13])
		else
			shotgun_s = false
			AddCaption(loc("NORMAL"))
		end

	--europe
	elseif(GetCurAmmoType() == amMolotov)
	then
		if(europe_s==0)
		then
			europe_s = 1
			AddCaption(weapontexts[14])
		else
			europe_s = 0
			AddCaption(loc("NORMAL"))
		end

	--swap forward in the weaponmenu (1.0 style)
	elseif(swapweps==true and (GetCurAmmoType() == amSkip or GetCurAmmoType() == amNothing))
	then
		continent[GetHogTeamName(CurrentHedgehog)]=continent[GetHogTeamName(CurrentHedgehog)]+1
		
		if(continent[GetHogTeamName(CurrentHedgehog)]> table.maxn(weaponsets))
		then
			continent[GetHogTeamName(CurrentHedgehog)]=1
		end
		setweapons()

	--kerguelen
	elseif(GetCurAmmoType() == amHammer)
	then
		if(kergulenSpecial==6)
		then
			kergulenSpecial = 1
			AddCaption("Normal")
		elseif(kergulenSpecial==1)
		then
			kergulenSpecial = 2
			AddCaption("#"..weapontexts[7])
		elseif(kergulenSpecial==2 and TotalRounds>=1)
		then
			kergulenSpecial = 3
			AddCaption("##"..weapontexts[8])
		elseif(kergulenSpecial==3 or (kergulenSpecial==2 and TotalRounds<1))
		then
			kergulenSpecial = 5
			AddCaption("###"..weapontexts[10])
		elseif(kergulenSpecial==5)
		then
			kergulenSpecial = 6
			AddCaption("####"..weapontexts[15])
		end
	end
end

function onPrecise()
	--swap backwards in the weaponmenu (1.0 style)
	if(swapweps==true and (GetCurAmmoType() == amSkip or GetCurAmmoType() == amNothing))
	then
		continent[GetHogTeamName(CurrentHedgehog)]=continent[GetHogTeamName(CurrentHedgehog)]-1
		
		if(continent[GetHogTeamName(CurrentHedgehog)]<=0)
		then
			continent[GetHogTeamName(CurrentHedgehog)]=table.maxn(weaponsets)
		end
		setweapons()
	end
end

function onGameTick20()
	--if you picked a weaponset from the weaponmenu (icon)
	if(continent[GetHogTeamName(CurrentHedgehog)]==0)
	then
		if(GetCurAmmoType()==amSwitch)
		then
			continent[GetHogTeamName(CurrentHedgehog)]=GetRandom(table.maxn(weaponsets))+1
			setweapons()
			PlaySound(sndMineTick)
		else
			for v,w in pairs(weaponsets) 
			do
				if(GetCurAmmoType()==weaponsets[v][4])
				then
					continent[GetHogTeamName(CurrentHedgehog)]=v
					setweapons()
					PlaySound(weaponsetssounds[v][1])
					PlaySound(weaponsetssounds[v][2],CurrentHedgehog)
				end
			end
		end
	end
	
	--show the kerguelen ring
	if(kergulenSpecial > 1 and GetCurAmmoType() == amHammer)
	then
		if(visualcircle==nil)
		then
			visualcircle=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtCircle, 0, true)
		end
		
		if(kergulenSpecial == 2) --walrus scream
		then
			SetVisualGearValues(visualcircle, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 120, 4, 0xff0000ee)
		elseif(kergulenSpecial == 3) --swap hog
		then
			SetVisualGearValues(visualcircle, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 450, 3, 0xffff00ee)
		elseif(kergulenSpecial == 5) --cries
		then
			SetVisualGearValues(visualcircle, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 500, 1, 0x0000ffee)
		elseif(kergulenSpecial == 6) --sabotage
		then
			SetVisualGearValues(visualcircle, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 80, 10, 0x00ff00ee)
		end
	
	elseif(visualcircle~=nil)
	then
		DeleteVisualGear(visualcircle)
		visualcircle=nil
	end
	
	--sabotage
	if(disable_moving[CurrentHedgehog]==true)
	then
	
		if(TurnTimeLeft<=150)
		then
			disable_moving[CurrentHedgehog]=false
			SetInputMask(0xFFFFFFFF)
		elseif(disallowattack >= (25*disableRand)+5)
		then
			temp_val=0
			
			AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-10, gtCluster, 0, 0, -160000, 40)
			
			disallowattack=0
		elseif(disallowattack % 20 == 0 and disallowattack>0)
		then
			SetInputMask(band(0xFFFFFFFF, bnot(gmLJump + gmHJump)))
			AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmokeWhite, 0, false)
			disallowattack=disallowattack+1
		else
			SetInputMask(0xFFFFFFFF)
			disallowattack=disallowattack+1
		end
	
	end
	
end

--if you used hogswitch or any similar weapon, dont enable any weaponchange
function onAttack()
	swapweps=false
	
	--african special
	if(africanSpecial == 1 and GetCurAmmoType() == amSeduction and band(GetState(CurrentHedgehog),gstAttacked)==0)
	then
		--SetState(CurrentHedgehog, gstAttacked)
		EndTurn(3000)
		
		temp_val=0
		runOnGears(weapon_duststorm)
		SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+temp_val)

		--visual stuff
		visual_gear_explosion(250,GetX(CurrentHedgehog), GetY(CurrentHedgehog),vgtSmoke,vgtSmokeWhite)
		PlaySound(sndParachute)
		
		RemoveWeapon(CurrentHedgehog,amSeduction)

	--Kerguelen specials
	elseif(GetCurAmmoType() == amHammer and kergulenSpecial > 1 and band(GetState(CurrentHedgehog),gstAttacked)==0)
	then
		--SetState(CurrentHedgehog, gstAttacked)
		
		
		--scream
		if(kergulenSpecial == 2)
		then
			temp_val=0
			runOnGears(weapon_scream_pen)
			SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+temp_val)
			PlaySound(sndHellish)
		
		--swap
		elseif(kergulenSpecial == 3 and TotalRounds>=1)
		then
			runOnGears(weapon_swap_kerg)
			PlaySound(sndPiano3)
			
		--cries
		elseif(kergulenSpecial == 5)
		then
			runOnGears(weapon_cries_a)
			if(kergulenSpecial~=-1)
			then
				AddGear(0, 0, gtWaterUp, 0, 0,0,0)
				PlaySound(sndWarp)
				PlaySound(sndMolotov)
				
				temp_val=0
				runOnGears(weapon_cries_b)
				SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+temp_val)
			else
				HogSay(CurrentHedgehog, loc("Hogs in sight!"), SAY_SAY)
			end
		
		--sabotage
		elseif(kergulenSpecial == 6)
		then
			temp_val=0
			runOnGears(weapon_sabotage)
			if(temp_val==0)
			then
				PlaySound(sndThrowRelease)
				AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-20, gtCluster, 0, 0, -1000000, 32)
			end
		end
		
		EndTurn(3000)
		
		DeleteVisualGear(visualcircle)
		visualcircle=nil
		kergulenSpecial=0
		
		RemoveWeapon(CurrentHedgehog,amHammer)
		
	elseif(GetCurAmmoType() == amVampiric)
	then
		VampOn=75
	end
	--Australian special
	if(GetGearType(austmine) == gtMine and austmine ~= nil)
	then
		temp_val=0
		runOnGears(weapon_aust_check)
		
		if(gearIsInCircle(austmine,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 30, false)==false or temp_val==1)
		then
			AddVisualGear(GetX(austmine), GetY(austmine), vgtDust, 0, false)
			DeleteGear(austmine)
			PlaySound(sndDenied)
		end
		
		austmine=nil
	end
	
	australianSpecial=false
end

function onGearAdd(gearUid)
	swapweps=false
	
	--track the gears im using
	if(GetGearType(gearUid) == gtHedgehog or GetGearType(gearUid) == gtMine or GetGearType(gearUid) == gtExplosives) 
	then
		trackGear(gearUid)
	end
	
	--remove gasclouds on gasbombspecial
	if(GetGearType(gearUid)==gtPoisonCloud and samericanSpecial == true)
	then
		DeleteGear(gearUid)

	elseif(GetGearType(gearUid)==gtSMine)
	then
		vx,vy=GetGearVelocity(gearUid)
		if(africaspecial2 == 1)
		then
			SetState(CurrentHedgehog, gstHHDriven+gstMoving)
			SetGearPosition(CurrentHedgehog, GetX(CurrentHedgehog),GetY(CurrentHedgehog)-3)
			SetGearVelocity(CurrentHedgehog, vx, vy)
			DeleteGear(gearUid)
			
		elseif(africaspecial2 == 2)
		then
			fire_gear(CurrentHedgehog,gtNapalmBomb, vx, vy, 0)
			DeleteGear(gearUid)
		end

	elseif(GetGearType(gearUid)==gtSniperRifleShot)
	then
		sniper_s_in_use=true
		if(namericanSpecial~=1)
		then
			SetHealth(gearUid, 1)
		end

	elseif(GetGearType(gearUid)==gtShotgunShot)
	then
		if(shotgun_s==true)
		then
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtFeather, 0, false)
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtFeather, 0, false)
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtFeather, 0, false)
			PlaySound(sndBirdyLay)
		else
			shotgun_s=nil
		end
		
	elseif(GetGearType(gearUid)==gtMolotov and europe_s==1)
	then
		vx,vy=GetGearVelocity(gearUid)
		e_health=fire_gear(CurrentHedgehog,gtCluster, vx, vy, 1)
		SetGearMessage(e_health, 2)
		DeleteGear(gearUid)
		
	elseif(GetGearType(gearUid)==gtParachute)
	then
		inpara=1
	end
end

function onGearDelete(gearUid)

	if(GetGearType(gearUid) == gtHedgehog or GetGearType(gearUid) == gtMine or GetGearType(gearUid) == gtExplosives) 
	then
		trackDeletion(gearUid)
		
		--sundaland special
		if(GetGearType(gearUid) == gtHedgehog and continent[GetHogTeamName(turnhog)]==10)
		then
			if(turnhog==CurrentHedgehog)
			then
				runOnGears(find_other_hog_in_team)
			end
		
			get_random_weapon_on_death(turnhog)
		end
	end
	
	--north american lipstick
	if(GetGearType(gearUid)==gtSniperRifleShot )
	then
		sniper_s_in_use=false
		if(namericanSpecial==2)
		then
			temp_val=gearUid
			runOnGears(weapon_lipstick)
		end
	--north american eagle eye
	elseif(GetGearType(gearUid)==gtShotgunShot and shotgun_s==true)
	then
		SetState(CurrentHedgehog, gstMoving)
		SetGearPosition(CurrentHedgehog, GetX(gearUid), GetY(gearUid)+7)
		PlaySound(sndWarp)

	--south american special
	elseif(GetGearType(gearUid)==gtGasBomb and samericanSpecial == true)
	then
		temp_val=gearUid
		runOnGears(weapon_anno_south)
		AddVisualGear(GetX(gearUid), GetY(gearUid), vgtExplosion, 0, false)
	
	--asian special
	elseif(GetGearType(gearUid)==gtSnowball and GetGearMessage(gearUid)==1)
	then
		AddGear(GetX(gearUid), GetY(gearUid), gtCluster, 0, 0, 0, 22)
	
	--europe special
	elseif(GetGearType(gearUid)==gtCluster and GetGearMessage(gearUid)==2)
	then
		temp_val=gearUid
		runOnGears(weapon_health)
		visual_gear_explosion(100,GetX(gearUid), GetY(gearUid),vgtSmokeWhite,vgtSmokeWhite)
		AddVisualGear(GetX(gearUid), GetY(gearUid), vgtExplosion, 0, false)
		PlaySound(sndGraveImpact)
	
	--asia (using para)
	elseif(GetGearType(gearUid)==gtParachute)
	then
		inpara=false
	end
end
--[[sources (populations & area):
Own calculations
Some are approximations.]]

--[[
Continental Supplies version 1.1a

Copyright (C) 2012 Vatten

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

function int_sqrt(num)
	temp=num
	while(temp*temp-div(temp,2)>num)
	do
		temp=div((temp+div(num,temp)),2)
	end
	return math.abs(temp)
end

function norm(xx,yy)
	return int_sqrt((xx^2)+(yy^2))
end

function positive(num)
	if(num<0)
	then
		return -1
	else
		return 1
	end
end

local teams_ok = {}
local wepcode_teams={}
local swapweps=false

--run when game starts on real
local australianSpecial=false
local africanSpecial=0
local africaspecial2=0
local asianSpecial=false
local samericanSpecial=false
local namericanSpecial=1
local sniper_s_in_use=false
local kergulenSpecial=1
local shotgun_s=false
local europe_s=0

local austmine=nil
local inpara=false
local asianflame=0

local temp_val=0

--f?r sabotage
local disallowattack=0
local disallowleft=true
local disable_moving={}

--skall bytas till f?r alla teams
local continent = {}

local weapontexts = {
loc("Green lipstick bullet: [Is poisonous]"),
loc("Piñata bullet: [Contains some sweet candy!]"),
loc("Anno 1032: [The explosion will make a strong push ~ wide range, wont affect hogs close to the target]"),
loc("Dust storm: [Deals 20 damage to all enemies in the circle]"),
loc("Fire a mine: [Does what it says ~ Cant be dropped close to an enemy ~ 1 sec]"),
loc("Drop a bomb: [drop some heroic wind that will turn into a bomb on impact]"),
loc("Scream from a Walrus: [Deal 20 damage + 10% of your hogs health to all hogs around you and get half back]"),
loc("Disguise as a Rockhopper Penguin: [Swap place with a random enemy hog in the circle]"),
loc("Flare: [fire up some bombs depending on hogs depending on hogs in the circle"),
loc("Lonely Cries: [Rise the water if no hog is in the circle and deal 1 damage to all hogs]"),
loc("Hedgehog projectile: [fire your hog like a Sticky Bomb]"),
loc("Napalm rocket: [Fire a bomb with napalm!]"),
loc("Eagle Eye: [Blink to the impact ~ one shot]"),
loc("Medicine: [Fire some exploding medicine that will heal all hogs effected by the explosion]"),
loc("Sabotage: [Sabotage all hogs in the circle and deal ~10 dmg]")
}

local weaponsets = 
{
{loc("North America"),"Area: 24,709,000 km2, Population: 528,720,588",loc("Special Weapons:").."|"..loc("Shotgun")..": "..weapontexts[13].."|"..loc("Sniper Rifle")..": "..weapontexts[1].."|"..loc("Sniper Rifle")..": "..weapontexts[2],amSniperRifle,
{{amShotgun,100},{amDEagle,100},{amLaserSight,4},{amSniperRifle,100},{amCake,1},{amAirAttack,2},{amSwitch,6}}},

{loc("South America"),"Area: 17,840,000 km2, Population: 387,489,196 ",loc("Special Weapons:").."|"..loc("GasBomb")..": "..weapontexts[3],amGasBomb,
{{amBirdy,5},{amHellishBomb,1},{amBee,100},{amWhip,100},{amGasBomb,100},{amFlamethrower,100},{amNapalm,1},{amExtraDamage,2}}},

{loc("Europe"),"Area: 10,180,000 km2, Population: 739,165,030",loc("Special Weapons:").."|"..loc("Molotov")..": "..weapontexts[14],amBazooka,
{{amBazooka,100},{amGrenade,100},{amMortar,100},{amClusterBomb,5},{amMolotov,5},{amVampiric,4},{amPiano,1},{amResurrector,2},{amJetpack,2}}},

{loc("Africa"),"Area: 30,221,532 km2, Population: 1,032,532,974",loc("Special Weapons:").."|"..loc("Seduction")..": "..weapontexts[4].."|"..loc("Sticky Mine")..": "..weapontexts[11].."|"..loc("Sticky Mine")..": "..weapontexts[12],amSMine,
{{amSMine,6},{amWatermelon,1},{amDrillStrike,1},{amExtraTime,2},{amDrill,100},{amLandGun,3},{amSeduction,100}}},

{loc("Asia"),"Area: 44,579,000 km2, Population: 3,879,000,000",loc("- Will refresh Parachute each turn.").."|"..loc("Special Weapons:").."|"..loc("Parachute")..": "..weapontexts[6],amRope,
{{amKamikaze,4},{amRope,100},{amFirePunch,100},{amParachute,1},{amKnife,4},{amDynamite,1}}},

{loc("Australia"),"Area:  8,468,300 km2, Population: 31,260,000",loc("Special Weapons:").."|"..loc("Baseballbat")..": "..weapontexts[5],amBaseballBat,
{{amBaseballBat,100},{amMine,100},{amLowGravity,6},{amBlowTorch,100},{amRCPlane,2},{amTardis,100}}},

{loc("Antarctica"),"Area: 14,000,000 km2, Population: ~1,000",loc("- Will refresh portalgun each turn."),amTeleport,
{{amSnowball,4},{amTeleport,2},{amInvulnerable,6},{amPickHammer,100},{amSineGun,100},{amGirder,4},{amPortalGun,1}}},

{loc("Kerguelen"),"Area: 1,100,000 km2, Population: ~70",loc("Special Weapons:").."|"..loc("Structure")..": "..weapontexts[7].."|"..loc("Structure")..": "..weapontexts[8].." ("..loc("Duration")..": 2)|"..loc("Structure")..": "..weapontexts[9].."|"..loc("Structure")..": "..weapontexts[10],amStructure,
{{amHammer,100},{amMineStrike,2},{amBallgun,1},{amStructure,100}}},
--no ,{amIceGun,4} for 0.9.18

{loc("Zealandia"),"Area: 3,500,000 km2, Population: 4,650,000",loc("- Will Get 1-3 random weapons"),amInvulnerable,
{{amBazooka,1},{amBlowTorch,1},{amSwitch,1}}}
}

--weapontype,ammo,?,duration,*times your choice,affect on random team (should be placed with 1,0,1,0,1 on the 6th option for better randomness)
local weapons_dmg = {
	{amKamikaze, 0, 1, 0, 1, 0},
	{amSineGun, 0, 1, 0, 1, 1},
	{amBazooka, 0, 1, 0, 1, 0},
	{amMineStrike, 0, 1, 5, 1, 2},
	{amGrenade, 0, 1, 0, 1, 0},
	{amPiano, 0, 1, 5, 1, 1},
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
	{amBirdy, 0, 1, 1, 1, 1},
	{amBlowTorch, 0, 1, 0, 1, 0},
	{amRCPlane, 0, 1, 5, 1, 2},
	{amGasBomb, 0, 0, 0, 1, 0},
	{amAirAttack, 0, 1, 4, 1, 1},
	{amFlamethrower, 0, 1, 0, 1, 0},
	{amSMine, 0, 1, 0, 1, 1},
	{amHammer, 0, 1, 0, 1, 0},
	{amDrillStrike, 0, 1, 4, 1, 2},
	{amSnowball, 0, 1, 0, 1, 0},
	{amStructure, 0, 0, 0, 1, 1}
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
	
function validate_weapon(hog,weapon,amount)
	if(MapHasBorder() == false or (MapHasBorder() == true and weapon ~= amAirAttack and weapon ~= amMineStrike and weapon ~= amNapalm and weapon ~= amDrillStrike and weapon ~= amPiano))
	then
		AddAmmo(hog, weapon,amount)
	end
end

--reset all weapons for a team
function cleanweps(hog)

	local i=1
	--+1 for skip
	while(i<=table.getn(weapons_supp)+table.getn(weapons_dmg)+1)
	do
		AddAmmo(hog,i,0)
		i=i+1
	end
	
	AddAmmo(hog,amSkip,100)
end

function load_weaponset(hog, num)
	for v,w in pairs(weaponsets[num][5]) 
	do
		validate_weapon(hog, w[1],w[2])
	end
end

function load_continent_selection(hog)
	for v,w in pairs(weaponsets) 
	do
		validate_weapon(hog, weaponsets[v][4],1)
	end
	AddAmmo(hog,amSwitch) --random continent
end

function show_continent_info(continent,time)
	local ns=false
	if(time==-1)
	then
		time=0
		ns=true
	end
	ShowMission(weaponsets[continent][1],weaponsets[continent][2],weaponsets[continent][3], -weaponsets[continent][4], time)
	if(ns)
	then
		HideMission()
	end
end

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

--zealandia
function get_random_weapon(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		local random_weapon = 0
		local old_rand_weap = 0
		local rand_weaponset_power = 0
		
		if(continent[GetHogTeamName(hog)]==9 and (getTeamValue(GetHogTeamName(hog), "rand-done-turn")==false or getTeamValue(GetHogTeamName(hog), "rand-done-turn")==nil))
		then
			cleanweps(hog)
		
			random_weapon = GetRandom(table.getn(weapons_dmg))+1
			while(weapons_dmg[random_weapon][4]>TotalRounds)
			do
				if(random_weapon>=table.getn(weapons_dmg))
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
				random_weapon = GetRandom(table.getn(weapons_supp))+1
				while(weapons_supp[random_weapon][4]>TotalRounds or rand_weaponset_power+weapons_supp[random_weapon][6]>2)
				do
					if(random_weapon>=table.getn(weapons_supp))
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
				random_weapon = GetRandom(table.getn(weapons_dmg))+1
				while(weapons_dmg[random_weapon][4]>TotalRounds or old_rand_weap == random_weapon or weapons_dmg[random_weapon][6]>0)
				do
					if(random_weapon>=table.getn(weapons_dmg))
					then
						random_weapon=0
					end
					random_weapon = random_weapon+1
				end
				validate_weapon(hog, weapons_dmg[random_weapon][1],1)
			end
				
			setTeamValue(GetHogTeamName(hog), "rand-done-turn", true)
			
			if(GetHogTeamName(hog)==GetHogTeamName(CurrentHedgehog))
			then
				temp_val=false
			end
		end
	end
end


function setweapons(skipafter)

	cleanweps(CurrentHedgehog)
	load_weaponset(CurrentHedgehog,continent[GetHogTeamName(CurrentHedgehog)])
	if(skipafter==true)
	then
		ParseCommand("setweap " .. string.char(amSkip))
	end

	show_continent_info(continent[GetHogTeamName(CurrentHedgehog)],0)
end

function show_damage_tag(hog,damage)
	healthtag=AddVisualGear(GetX(hog), GetY(hog), vgtHealthTag, damage, false)
	v1, v2, v3, v4, v5, v6, v7, v8, v9, v10 = GetVisualGearValues(healthtag)
	SetVisualGearValues(healthtag, v1, v2, v3, v4, v5, v6, v7, v8, v9, GetClanColor(GetHogClan(hog)))
end

function fire_gear(hedgehog,geartype,vx,vy,timer)
	return AddGear(div((GetGearRadius(hedgehog)*2*vx),norm(vx,vy))+GetX(hedgehog), div((GetGearRadius(hedgehog)*2*vy),norm(vx,vy))+GetY(hedgehog), geartype, 0, vx, vy, timer)
end

--==========================run throw all hog/gear weapons ==========================
function weapon_aust_check(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 50, false)==true and hog ~= CurrentHedgehog)
		then
			temp_val=1
		end
	end
end

function weapon_duststorm(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		local dmg=20
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 250, false)==true and GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			if(GetHealth(hog) > dmg)
			then
				SetHealth(hog, GetHealth(hog)-dmg)
			else
				SetHealth(hog, 0)
			end
			show_damage_tag(hog,dmg)
		end
	end
end

function weapon_scream_walrus(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 120, false)==true and GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			if(GetHealth(hog)>(20+GetHealth(CurrentHedgehog)*0.1))
			then
				SetHealth(hog, GetHealth(hog)-(20+GetHealth(CurrentHedgehog)*0.1))
				temp_val=temp_val+10+GetHealth(CurrentHedgehog)*0.05
			else
				SetHealth(hog, 0)
				temp_val=temp_val+(GetHealth(hog)*0.5)+(GetHealth(CurrentHedgehog)*0.05)
			end
			show_damage_tag(hog,(20+GetHealth(CurrentHedgehog)*0.1))
			AddVisualGear(GetX(hog), GetY(hog), vgtExplosion, 0, false)
			AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmokeWhite, 0, false)
		end
	end
end

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

function weapon_flare(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(GetHogClan(hog) ~= GetHogClan(CurrentHedgehog) and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 45, false))
		then
			if(GetX(hog)<=GetX(CurrentHedgehog))
			then
				dirker=1
			else
				dirker=-1
			end
			AddVisualGear(GetX(hog), GetY(hog), vgtFire, 0, false)
			SetGearPosition(CurrentHedgehog, GetX(CurrentHedgehog), GetY(CurrentHedgehog)-5)
			SetGearVelocity(CurrentHedgehog, 100000*dirker, -300000)
			AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-20, gtCluster, 0, -10000*dirker, -1000000, 35)
			PlaySound(sndHellishImpact2)
		end
	end
end

function weapon_sabotage(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(GetHogClan(hog) ~= GetHogClan(CurrentHedgehog) and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 100, false))
		then
			disable_moving[hog]=true
			AddGear(GetX(hog), GetY(hog), gtCluster, 0, 0, 0, 10)
			PlaySound(sndNooo,hog)
		end
	end
end

function weapon_anno_south(hog)
	local power_radius_outer=250
	local power_radius_inner=40
	local power_sa=500000
	if(gearIsInCircle(hog,GetX(temp_val), GetY(temp_val), power_radius_outer, false) and gearIsInCircle(hog,GetX(temp_val), GetY(temp_val), power_radius_inner, false)==false)
	then
		if(hog == CurrentHedgehog)
		then
			SetState(CurrentHedgehog, gstMoving)
		end
		SetGearPosition(hog, GetX(hog),GetY(hog)-3)
		SetGearVelocity(hog, div((power_radius_outer-norm(math.abs(GetX(hog)-GetX(temp_val)),math.abs(GetY(hog)-GetY(temp_val))))*power_sa*positive(GetX(hog)-GetX(temp_val)),power_radius_outer), div((power_radius_outer-norm(math.abs(GetX(hog)-GetX(temp_val)),math.abs(GetY(hog)-GetY(temp_val))))*power_sa*positive(GetY(hog)-GetY(temp_val)),power_radius_outer))
	end
end

function weapon_cries_a(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(GetHogClan(hog) ~= GetHogClan(CurrentHedgehog) and gearIsInCircle(hog,GetX(CurrentHedgehog), GetY(CurrentHedgehog), 500, false))
		then
			kergulenSpecial=-1
		end
	end
end

function weapon_cries_b(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(GetHogClan(hog) ~= GetHogClan(CurrentHedgehog))
		then
			SetHealth(hog, GetHealth(hog)-1)
			show_damage_tag(hog,1)
			AddVisualGear(GetX(hog), GetY(hog)-30, vgtEvilTrace, 0, false)
		end
	end
end

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

function weapon_health(hog)
	if(GetGearType(hog) == gtHedgehog)
	then
		if(gearIsInCircle(temp_val,GetX(hog), GetY(hog), 100, false))
		then
			SetHealth(hog, GetHealth(hog)+25)
			SetEffect(hog, hePoisoned, false)
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

	ShowMission(loc("Continental supplies").." 1.1a",loc("Let a Continent provide your weapons!"),
	loc("- Per team weapons|- 9 weaponschemes|- Unique new weapons| |Select continent first round with the Weapon Menu or by ([switch/tab]=Increase,[precise/left shift]=Decrease) on Skip|Some weapons have a second option. Find them with [switch/tab]"), -amLowGravity, 0)
end

--what happen when a turn starts
function onNewTurn()

	australianSpecial=true
	asianSpecial=false
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
	
	temp_val=0
	
	disallowattack=0
	disallowleft=true
	--when all hogs are "placed"
	
	if(GetCurAmmoType()~=amTeleport)
	then
		--will run once when the game really starts (after placing hogs and so on
		if(teams_ok[GetHogTeamName(CurrentHedgehog)] == nil)
		then
			disable_moving[CurrentHedgehog]=false
			AddCaption("["..loc("Select continent!").."]")
			load_continent_selection(CurrentHedgehog)
			continent[GetHogTeamName(CurrentHedgehog)]=0
			swapweps=true
			teams_ok[GetHogTeamName(CurrentHedgehog)] = 2
		else
			swapweps=false
			if(continent[GetHogTeamName(CurrentHedgehog)]==0)
			then
				continent[GetHogTeamName(CurrentHedgehog)]=GetRandom(table.getn(weaponsets))+1
				setweapons(false)
			end
			show_continent_info(continent[GetHogTeamName(CurrentHedgehog)],-1)
		end
	end
	
	if(continent[GetHogTeamName(CurrentHedgehog)]==7)
	then
		AddAmmo(CurrentHedgehog,amPortalGun,0)
		AddAmmo(CurrentHedgehog,amPortalGun,1)
	elseif(continent[GetHogTeamName(CurrentHedgehog)]==5)
	then
		AddAmmo(CurrentHedgehog,amParachute,0)
		AddAmmo(CurrentHedgehog,amParachute,1)
	end
	
	temp_val=true
	runOnGears(get_random_weapon)
	
	if(temp_val==true and continent[GetHogTeamName(CurrentHedgehog)]==9 and getTeamValue(GetHogTeamName(CurrentHedgehog), "rand-done-turn")==true)
	then
		setTeamValue(GetHogTeamName(CurrentHedgehog), "rand-done-turn", false)
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
	end
	
	--Asian special
	if(asianSpecial==false and inpara~=false)
	then
		asiabomb=AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)+3, gtSnowball, 0, 0, 0, 0)
		SetGearMessage(asiabomb, 1)
		asianSpecial=true
		swapweps=false
	end
	
	--africa
	if(GetCurAmmoType() == amSeduction)
	then
		if(africanSpecial==0)
		then
			africanSpecial = 1
			AddCaption(weapontexts[4])
		else
			africanSpecial = 0
			AddCaption(loc("NORMAL"))
		end
	end
	--south america
	if(GetCurAmmoType() == amGasBomb)
	then
		if(samericanSpecial==false)
		then
			samericanSpecial = true
			AddCaption(weapontexts[3])
		else
			samericanSpecial = false
			AddCaption(loc("NORMAL"))
		end
	end
	--africa
	if(GetCurAmmoType() == amSMine)
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
	end
	
	--north america
	if(GetCurAmmoType() == amSniperRifle and sniper_s_in_use==false)
	then
		if(namericanSpecial==3)
		then
			namericanSpecial = 1
			AddCaption(loc("NORMAL"))
		elseif(namericanSpecial==1)
		then
			namericanSpecial = 2
			AddCaption("#"..weapontexts[1])
		elseif(namericanSpecial==2)
		then
			namericanSpecial = 3
			AddCaption("##"..weapontexts[2])
		end
	end
	
	if(GetCurAmmoType() == amShotgun and shotgun_s~=nil)
	then
		if(shotgun_s==false)
		then
			shotgun_s = true
			AddCaption(weapontexts[13])
		else
			shotgun_s = false
			AddCaption(loc("NORMAL"))
		end
	end
	
	if(GetCurAmmoType() == amMolotov)
	then
		if(europe_s==0)
		then
			europe_s = 1
			AddCaption(weapontexts[14])
		else
			europe_s = 0
			AddCaption(loc("NORMAL"))
		end
	end
	
	if(swapweps==true and GetCurAmmoType() == amSkip)
	then
		continent[GetHogTeamName(CurrentHedgehog)]=continent[GetHogTeamName(CurrentHedgehog)]+1
		
		if(continent[GetHogTeamName(CurrentHedgehog)]> table.getn(weaponsets))
		then
			continent[GetHogTeamName(CurrentHedgehog)]=1
		end
		setweapons(true)
	end
	
	if(GetCurAmmoType() == amStructure)
	then
		if(kergulenSpecial==5)
		then
			kergulenSpecial = 1
			AddCaption("#"..weapontexts[7])
		elseif(kergulenSpecial==1 and TotalRounds>=1)
		then
			kergulenSpecial = 2
			AddCaption("##"..weapontexts[8])
		elseif(kergulenSpecial==2 or (kergulenSpecial==1 and TotalRounds<1))
		then
			kergulenSpecial = 3
			AddCaption("###"..weapontexts[9])
		elseif(kergulenSpecial==3)
		then
			kergulenSpecial = 4
			AddCaption("####"..weapontexts[10])
		elseif(kergulenSpecial==4)
		then
			kergulenSpecial = 5
			AddCaption("#####"..weapontexts[15])
		end
	end
end

function onPrecise()
	if(swapweps==true and GetCurAmmoType() == amSkip)
	then
		continent[GetHogTeamName(CurrentHedgehog)]=continent[GetHogTeamName(CurrentHedgehog)]-1
		
		if(continent[GetHogTeamName(CurrentHedgehog)]<=0)
		then
			continent[GetHogTeamName(CurrentHedgehog)]=9
		end
		setweapons(true)
	end
end

function onSlot()
	if(continent[GetHogTeamName(CurrentHedgehog)]==0) then
		ParseCommand("setweap " .. string.char(amSkip))
	end
end

function onGameTick20()

	if(teams_ok[GetHogTeamName(CurrentHedgehog)] == 2)
	then
		if(GetCurAmmoType()~=amTeleport and swapweps==true and TurnTime-TurnTimeLeft>=100)
		then
			teams_ok[GetHogTeamName(CurrentHedgehog)] = true
			ParseCommand("setweap " .. string.char(amSkip))
		end
	end
	
	if(continent[GetHogTeamName(CurrentHedgehog)]==0)
	then
		if(GetCurAmmoType()==amSniperRifle) then
			continent[GetHogTeamName(CurrentHedgehog)]=1
			setweapons(false)
		elseif(GetCurAmmoType()==amGasBomb) then
			continent[GetHogTeamName(CurrentHedgehog)]=2
			setweapons(false)
		elseif(GetCurAmmoType()==amBazooka) then
			continent[GetHogTeamName(CurrentHedgehog)]=3
			setweapons(false)
		elseif(GetCurAmmoType()==amSMine) then
			continent[GetHogTeamName(CurrentHedgehog)]=4
			setweapons(false)
		elseif(GetCurAmmoType()==amRope) then
			continent[GetHogTeamName(CurrentHedgehog)]=5
			setweapons(false)
		elseif(GetCurAmmoType()==amBaseballBat) then
			continent[GetHogTeamName(CurrentHedgehog)]=6
			setweapons(false)
		elseif(GetCurAmmoType()==amTeleport) then
			continent[GetHogTeamName(CurrentHedgehog)]=7
			setweapons(false)
		elseif(GetCurAmmoType()==amStructure) then
			continent[GetHogTeamName(CurrentHedgehog)]=8
			setweapons(false)
		elseif(GetCurAmmoType()==amInvulnerable) then
			continent[GetHogTeamName(CurrentHedgehog)]=9
			setweapons(false)
		elseif(GetCurAmmoType()==amSwitch) then
			continent[GetHogTeamName(CurrentHedgehog)]=GetRandom(table.getn(weaponsets))+1
			setweapons(false)
		end
	end
	
	if(kergulenSpecial ~= 0 and GetCurAmmoType() == amStructure)
	then
		if(kergulenSpecial == 1)
		then
			if(visualcircle==nil)
			then
				visualcircle=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtCircle, 120, false)
			end
			SetVisualGearValues(visualcircle, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 120, 4, 0xff0000ee)
		elseif(kergulenSpecial == 2)
		then
			if(visualcircle==nil)
			then
				visualcircle=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtCircle, 450, false)
			end
			SetVisualGearValues(visualcircle, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 450, 3, 0xffff00ee)
		elseif(kergulenSpecial == 3)
		then
			if(visualcircle==nil)
			then
				visualcircle=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtCircle, 45, false)
			end
			SetVisualGearValues(visualcircle, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 45, 6, 0x00ff00ee)
		elseif(kergulenSpecial == 4)
		then
			if(visualcircle==nil)
			then
				visualcircle=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtCircle, 500, false)
			end
			SetVisualGearValues(visualcircle, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 500, 1, 0x0000ffee)
		elseif(kergulenSpecial == 5)
		then
			if(visualcircle==nil)
			then
				visualcircle=AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtCircle, 100, false)
			end
			SetVisualGearValues(visualcircle, GetX(CurrentHedgehog), GetY(CurrentHedgehog),20, 200, 0, 0, 100, 100, 10, 0xeeeeeeee)
		end
	
	elseif(visualcircle~=nil)
	then
		DeleteVisualGear(visualcircle)
		visualcircle=nil
	end
	
	if(disable_moving[CurrentHedgehog]==true)
	then
	
		if(TurnTimeLeft<=150)
		then
			disable_moving[CurrentHedgehog]=false
			SetHogLevel(CurrentHedgehog,0)
		elseif(disallowattack>=15 and disallowattack >= 20)
		then
			disallowattack=0
			SetHogLevel(CurrentHedgehog,1)
			AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmokeWhite, 0, false)
		elseif(GetHogLevel(CurrentHedgehog)==1)
		then
			SetHogLevel(CurrentHedgehog,0)
		else
			disallowattack=disallowattack+1
		end
	
	end
	
end

--if you used hogswitch or any similar weapon, dont enable any weaponchange
function onAttack()
	swapweps=false
	local around=false
	
	--african special
	if(africanSpecial == 1 and GetCurAmmoType() == amSeduction)
	then
		SetState(CurrentHedgehog, gstAttacked)
		
		runOnGears(weapon_duststorm)

		--visual stuff
		visual_gear_explosion(250,GetX(CurrentHedgehog), GetY(CurrentHedgehog),vgtSmoke,vgtSmokeWhite)
		PlaySound(sndParachute)
	end
	
	--Kerguelen specials
	if(GetCurAmmoType() == amStructure)
	then
		SetState(CurrentHedgehog, gstAttacked)
		if(kergulenSpecial == 1)
		then
			temp_val=0
			runOnGears(weapon_scream_walrus)
			SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+temp_val)
			PlaySound(sndHellish)
			
		elseif(kergulenSpecial == 2 and TotalRounds>=1)
		then
			runOnGears(weapon_swap_kerg)
			PlaySound(sndPiano3)
		elseif(kergulenSpecial == 3)
		then
			runOnGears(weapon_flare)
			PlaySound(sndThrowRelease)
			AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmokeWhite, 0, false)
			AddGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog)-20, gtCluster, 0, 0, -1000000, 30)
				
		elseif(kergulenSpecial == 4)
		then
			runOnGears(weapon_cries_a)
			if(kergulenSpecial~=-1)
			then
				AddGear(0, 0, gtWaterUp, 0, 0,0,0)
				PlaySound(sndWarp)
				PlaySound(sndMolotov)
				
				runOnGears(weapon_cries_b)
			else
				HogSay(CurrentHedgehog, loc("Hogs in sight!"), SAY_SAY)
			end
		elseif(kergulenSpecial == 5)
		then
			runOnGears(weapon_sabotage)
		end
		DeleteVisualGear(visualcircle)
		visualcircle=nil
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
	
	if(disable_moving[CurrentHedgehog]==true)
	then
		disable_moving[CurrentHedgehog]=false
		SetHogLevel(CurrentHedgehog,0)
	end
	
	australianSpecial=false
end

function onGearAdd(gearUid)
	swapweps=false
	
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
		inpara=gearUid
	end
end

function onGearDelete(gearUid)

	if(GetGearType(gearUid) == gtHedgehog or GetGearType(gearUid) == gtMine or GetGearType(gearUid) == gtExplosives) 
	then
		trackDeletion(gearUid)
	end
	--north american specials
	if(GetGearType(gearUid)==gtSniperRifleShot )
	then
		sniper_s_in_use=false
		if(namericanSpecial==2)
		then
			temp_val=gearUid
			runOnGears(weapon_lipstick)
			
		elseif(namericanSpecial==3)
		then
			AddVisualGear(GetX(gearUid), GetY(gearUid), vgtExplosion, 0, false)
			
			pinata=AddGear(GetX(gearUid), GetY(gearUid), gtCluster, 0, 0, 0, 5)
			SetGearMessage(pinata,1)
		end
		
	elseif(GetGearType(gearUid)==gtCluster and GetGearMessage(gearUid)==1 and namericanSpecial==3)
	then
		AddGear(GetX(gearUid), GetY(gearUid), gtCluster, 0, 0, 0, 20)
	
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

	elseif(GetGearType(gearUid)==gtSnowball and GetGearMessage(gearUid)==1)
	then
		AddGear(GetX(gearUid), GetY(gearUid)+3, gtCluster, 0, 0, 0, 22)
		
	elseif(GetGearType(gearUid)==gtCluster and GetGearMessage(gearUid)==2)
	then
		temp_val=gearUid
		runOnGears(weapon_health)
		visual_gear_explosion(100,GetX(gearUid), GetY(gearUid),vgtSmokeWhite,vgtSmokeWhite)
		AddVisualGear(GetX(gearUid), GetY(gearUid), vgtExplosion, 0, false)
		PlaySound(sndGraveImpact)
		
	elseif(GetGearType(gearUid)==gtParachute)
	then
		inpara=false
	end
end

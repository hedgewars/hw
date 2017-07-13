------------------- ABOUT ----------------------
--
-- In this adventure hero gets the lost part with
-- the help of the green bananas hogs.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("Getting to the device")
local inBattle = false
local tookPartInBattle = false
local previousHog = -1
local checkPointReached = 1 -- 1 is normal spawn
local permitCaptainLimeDeath = false
-- dialogs
local dialog01 = {}
local dialog02 = {}
local dialog03 = {}
local dialog04 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Exploring the tunnel"), loc("Search for the device with the help of the other hedgehogs ").."|"..loc("Hog Solo has to reach the last crates"), 1, 4000},
	[dialog02] = {missionName, loc("Exploring the tunnel"), loc("Explore the tunnel with the other hedgehogs and search for the device").."|"..loc("Hog Solo has to reach the last crates"), 1, 4000},
	[dialog03] = {missionName, loc("Return to the Surface"), loc("Go to the surface!").."|"..loc("Attack Captain Lime before he attacks back"), 1, 4000},
	[dialog04] = {missionName, loc("Return to the Surface"), loc("Go to the surface!").."|"..loc("Attack the assassins before they attack back"), 1, 4000},
}
-- crates
local eagleCrate = {name = amDEagle, x = 1680, y = 1650}
local girderCrate =	{name = amGirder, x = 1680, y = 1160}
local ropeCrate = {name = amRope, x = 1400, y = 1870}
local weaponCrate = { x = 1360, y = 1870}
-- hogs
local hero = {}
local green1 = {}
local green2 = {}
local green3 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
-- hedgehogs values
hero.name = loc("Hog Solo")
hero.x = 1200
hero.y = 820
hero.dead = false
green1.name = loc("Captain Lime")
green1.x = 1050
green1.y = 820
green1.dead = false
green2.name = loc("Mister Pear")
green2.x = 1350
green2.y = 820
green3.name = loc("Lady Mango")
green3.x = 1450
green3.y = 820
local redHedgehogs = {
	{ name = loc("Poisonous Apple") },
	{ name = loc("Dark Strawberry") },
	{ name = loc("Watermelon Heart") },
	{ name = loc("Deadly Grape") }
}
teamA.name = loc("Hog Solo and GB")
teamA.color = tonumber("38D61C",16) -- green
teamB.name = loc("Captain Lime")
teamB.color = tonumber("38D61D",16) -- greenish
teamC.name = loc("Fruit Assassins")
teamC.color = tonumber("FF0000",16) -- red

function onGameInit()
	GameFlags = gfDisableWind
	Seed = 1
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Delay = 3
	SuddenDeathTurns = 200
	Map = "fruit02_map"
	Theme = "Fruit"

	-- load checkpoints, problem getting the campaign variable
	local health = 100
	checkPointReached = initCheckpoint("fruit02")
	if checkPointReached ~= 1 then
		loadHogsPositions()
		health = tonumber(GetCampaignVar("HeroHealth"))
	end

	-- Hog Solo and Green Bananas
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, health, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	green2.gear = AddHog(green2.name, 0, 100, "war_britmedic")
	AnimSetGearPosition(green2.gear, green2.x, green2.y)
	HogTurnLeft(green2.gear, true)
	green3.gear = AddHog(green3.name, 0, 100, "hair_red")
	AnimSetGearPosition(green3.gear, green3.x, green3.y)
	HogTurnLeft(green3.gear, true)
	-- Captain Lime
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	green1.human = AddHog(green1.name, 0, 100, "war_desertofficer")
	AnimSetGearPosition(green1.human, green1.x, green1.y)
	green1.bot = AddHog(green1.name, 1, 100, "war_desertofficer")
	AnimSetGearPosition(green1.bot, green1.x, green1.y)
	green1.gear = green1.human
	-- Fruit Assassins
	local assasinsHats = { "NinjaFull", "NinjaStraight", "NinjaTriangle" }
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	for i=1,table.getn(redHedgehogs) do
		redHedgehogs[i].gear =  AddHog(redHedgehogs[i].name, 1, 100, assasinsHats[GetRandom(3)+1])
		AnimSetGearPosition(redHedgehogs[i].gear, 2010 + 50*i, 630)
	end

	AnimInit()
	AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)

	if GetCampaignVar("Fruit01JoinedBattle") and GetCampaignVar("Fruit01JoinedBattle") == "true" then
		tookPartInBattle = true
	end

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onDeviceCrates, {hero.gear}, deviceCrates, {hero.gear}, 0)

	-- Hog Solo and GB weapons
	AddAmmo(hero.gear, amSwitch, 100)
	-- Captain Lime weapons
	AddAmmo(green1.bot, amBazooka, 6)
	AddAmmo(green1.bot, amGrenade, 6)
	AddAmmo(green1.bot, amDEagle, 2)
	HideHog(green1.bot)
	-- Assassins weapons
	AddAmmo(redHedgehogs[1].gear, amBazooka, 6)
	AddAmmo(redHedgehogs[1].gear, amGrenade, 6)
	AddAmmo(redHedgehogs[1].bot, amDEagle, 6)
	for i=1,table.getn(redHedgehogs) do
		HideHog(redHedgehogs[i].gear)
	end

	-- explosives
	-- I wanted to use FindPlace but doesn't accept height values...
	local x1 = 950
	local x2 = 1306
	local y1 = 1210
	local y2 = 1620
	while true do
		if y2<y1 then
			break
		end
		if x2<x1 then
			x2 = 1305
			y2 = y2 - 50
		end
		if not TestRectForObstacle(x2+25, y2+25, x2-25, y2-25, true) then
			AddGear(x2, y2, gtExplosives, 0, 0, 0, 0)
		end
		x2 = x2 - 25
	end
	AddGear(3128, 1680, gtExplosives, 0, 0, 0, 0)

	--mines
	AddGear(3135, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3145, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3155, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3165, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3175, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3115, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3105, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3095, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3085, 1680, gtMine, 0, 0, 0, 0)
	AddGear(3075, 1680, gtMine, 0, 0, 0, 0)

	if checkPointReached == 1 then
		AddAmmo(hero.gear, amFirePunch, 3)
		AddEvent(onCheckPoint1, {hero.gear}, checkPoint1, {hero.gear}, 0)
		AddEvent(onCheckPoint2, {hero.gear}, checkPoint2, {hero.gear}, 0)
		AddEvent(onCheckPoint3, {hero.gear}, checkPoint3, {hero.gear}, 0)
		AddEvent(onCheckPoint4, {hero.gear}, checkPoint4, {hero.gear}, 0)
		if tookPartInBattle then
			AddAnim(dialog01)
		else
			AddAnim(dialog02)
		end
	elseif checkPointReached == 2 then
		AddEvent(onCheckPoint2, {hero.gear}, checkPoint2, {hero.gear}, 0)
		AddEvent(onCheckPoint3, {hero.gear}, checkPoint3, {hero.gear}, 0)
		AddEvent(onCheckPoint4, {hero.gear}, checkPoint4, {hero.gear}, 0)
	elseif checkPointReached == 3 then
		AddEvent(onCheckPoint1, {hero.gear}, checkPoint1, {hero.gear}, 0)
		AddEvent(onCheckPoint3, {hero.gear}, checkPoint3, {hero.gear}, 0)
		AddEvent(onCheckPoint4, {hero.gear}, checkPoint4, {hero.gear}, 0)
	elseif checkPointReached == 4 then
		AddEvent(onCheckPoint4, {hero.gear}, checkPoint4, {hero.gear}, 0)
	elseif checkPointReached == 5 then
		-- EMPTY
	end
	if checkPointReached ~= 1 then
		loadWeapons()
	end

	-- girders
	if checkPointReached > 1 then
		PlaceGirder(1580, 875, 4)
		PlaceGirder(1800, 875, 4)
	end

	-- place crates
	if checkPointReached < 2 then
		SpawnAmmoCrate(girderCrate.x, girderCrate.y, girderCrate.name)
	end
	if checkPointReached < 5 then
		SpawnAmmoCrate(eagleCrate.x, eagleCrate.y, eagleCrate.name)
	end
	SpawnAmmoCrate(ropeCrate.x, ropeCrate.y, ropeCrate.name)

	if tookPartInBattle then
		SpawnAmmoCrate(weaponCrate.x, weaponCrate.y, amWatermelon)
	else
		SpawnAmmoCrate(weaponCrate.x, weaponCrate.y, amSniperRifle)
	end

	SendHealthStatsOff()
end

function onNewTurn()
	if not inBattle and CurrentHedgehog == green1.gear then
		TurnTimeLeft = 0
	elseif CurrentHedgehog == green2.gear or CurrentHedgehog == green3.gear then
		TurnTimeLeft = 0
	elseif inBattle then
		if CurrentHedgehog == green1.gear and previousHog ~= hero.gear then
			TurnTimeLeft = 0
			return
		end
		for i=1,table.getn(redHedgehogs) do
			if CurrentHedgehog == redHedgehogs[i].gear and previousHog ~= hero.gear then
				TurnTimeLeft = 0
				return
			end
		end
		TurnTimeLeft = 20000
		wind()
	elseif not inBattle and CurrentHedgehog == hero.gear then
		TurnTimeLeft = -1
		wind()
	else
		TurnTimeLeft = 0
	end
	previousHog = CurrentHedgehog
end

function onGameTick()
	AnimUnWait()
	if ShowAnimation() == false then
		return
	end
	ExecuteAfterAnimations()
	CheckEvents()
end

function onGameTick20()
	if not permitCaptainLimeDeath and not GetHealth(green1.gear) then
		-- game ends with the according stat messages
		heroDeath()
		permitCaptainLimeDeath = true
	end
	if CurrentHedgehog and GetY(CurrentHedgehog) > 1350 then
		SetWind(-40)
	end
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	elseif gear == green1.bot then
		green1.dead = true
	end
end

function onGearDamage(gear, damage)
	if GetGearType(gear) == gtCase then
		-- in this mode every crate is essential in order to complete the mission
		-- destroying a crate ends the game
		heroDeath()
	end
end

function onAmmoStoreInit()
	SetAmmo(amDEagle, 0, 0, 0, 6)
	SetAmmo(amGirder, 0, 0, 0, 2)
	SetAmmo(amRope, 0, 0, 0, 1)
	if tonumber(getBonus(2)) == 1 then
		SetAmmo(amWatermelon, 0, 0, 0, 2)
		SetAmmo(amSniperRifle, 0, 0, 0, 2)
	else
		SetAmmo(amWatermelon, 0, 0, 0, 1)
		SetAmmo(amSniperRifle, 0, 0, 0, 1)
	end
end

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)
	end
end

-------------- EVENTS ------------------

function onHeroDeath(gear)
	if hero.dead then
		return true
	end
	return false
end

function onDeviceCrates(gear)
	if not hero.dead and GetY(hero.gear)>1850 and GetX(hero.gear)>1340 and GetX(hero.gear)<1640 then
		return true
	end
	return false
end

function onSurface(gear)
	if not hero.dead and GetY(hero.gear)<850 and  StoppedGear(hero.gear) then
		return true
	end
	return false
end

function onGaptainLimeDeath(gear)
	if green1.dead then
		return true
	end
	return false
end

function onRedTeamDeath(gear)
	local redDead = true
	for i=1,table.getn(redHedgehogs) do
		if GetHealth(redHedgehogs[i].gear) then
			redDead = false
			break
		end
	end
	return redDead
end

function onCheckPoint1(gear)
	-- before barrel jump
	if not hero.dead and GetX(hero.gear) > 2850 and GetX(hero.gear) < 2945
			and GetY(hero.gear) > 808 and GetY(hero.gear) < 852 and	not isHeroAtWrongPlace() then
		return true
	end
	return false
end

function onCheckPoint2(gear)
	-- before barrel jump
	if ((GetHealth(green2.gear) and GetX(green2.gear) > 2850 and GetX(green2.gear) < 2945 and GetY(green2.gear) > 808 and GetY(green2.gear) < 852)
			or (GetHealth(green3.gear) and GetX(green3.gear) > 2850 and GetX(green3.gear) < 2945 and GetY(green3.gear) > 808 and GetY(green3.gear) < 852))
			and not isHeroAtWrongPlace() then
		return true
	end
	return false
end

function onCheckPoint3(gear)
	-- after barrel jump
	if ((GetHealth(green2.gear) and GetY(green2.gear) > 1550 and GetX(green2.gear) < 3000 and StoppedGear(green2.gear))
			or (GetHealth(green3.gear) and GetY(green3.gear) > 1550 and GetX(green3.gear) < 3000 and StoppedGear(green2.gear)))
			and not isHeroAtWrongPlace() then
		return true
	end
	return false
end

function onCheckPoint4(gear)
	-- hero at crates
	if not hero.dead and GetX(hero.gear) > 1288 and GetX(hero.gear) < 1420
			and GetY(hero.gear) > 1840 and	not isHeroAtWrongPlace() then
		return true
	end
	return false
end

-------------- ACTIONS ------------------
ended = false

function heroDeath(gear)
	if not ended then
		SendStat(siGameResult, loc("Hog Solo lost, try again!"))
		SendStat(siCustomAchievement, loc("To win the game, Hog Solo has to get the bottom crates and come back to the surface."))
		SendStat(siCustomAchievement, loc("You can use the other 2 hogs to assist you."))
		SendStat(siCustomAchievement, loc("Do not destroy the crates!"))
		if tookPartInBattle then
			SendStat(siCustomAchievement, loc("You'll have to eliminate the Strawberry Assassins at the end."))
		else
			SendStat(siCustomAchievement, loc("You'll have to eliminate Captain Lime at the end."))
		SendStat(siCustomAchievement, loc("Don't eliminate Captain Lime before collecting the last crate!"))
		end
		SendStat(siPlayerKills,'0',teamA.name)
		EndGame()
		ended = true
	end
end

function deviceCrates(gear)
	TurnTimeLeft = 0
	if not tookPartInBattle then
		AddAnim(dialog03)
	else
		for i=1,table.getn(redHedgehogs) do
			RestoreHog(redHedgehogs[i].gear)
		end
		AddAnim(dialog04)
	end
	-- needs to be set to true for both plots
	permitCaptainLimeDeath = true
	AddAmmo(hero.gear, amSwitch, 0)
	AddEvent(onSurface, {hero.gear}, surface, {hero.gear}, 0)
end

function surface(gear)
	previousHog = -1
	if tookPartInBattle then
		if GetHealth(green1.gear) then
			HideHog(green1.gear)
		end
		AddEvent(onRedTeamDeath, {green1.gear}, redTeamDeath, {green1.gear}, 0)
	else
		DeleteGear(green1.human)
		RestoreHog(green1.bot)
		green1.gear = green1.bot
		AddEvent(onGaptainLimeDeath, {green1.gear}, captainLimeDeath, {green1.gear}, 0)
	end
	if GetHealth(green2.gear) then
		HideHog(green2.gear)
	end
	if GetHealth(green3.gear) then
		HideHog(green3.gear)
	end
	inBattle = true
end

function captainLimeDeath(gear)
	-- hero win in scenario of escape in 1st part
	saveCompletedStatus(3)
	SendStat(siGameResult, loc("Congratulations, you won!"))
	SendStat(siCustomAchievement, loc("You retrieved the lost part."))
	SendStat(siCustomAchievement, loc("You defended yourself against Captain Lime."))
	SendStat(siPlayerKills,'1',teamA.name)
	SendStat(siPlayerKills,'0',teamB.name)
	EndGame()
end

function redTeamDeath(gear)
	-- hero win in battle scenario
	saveCompletedStatus(3)
	SendStat(siGameResult, loc("Congratulations, you won!"))
	SendStat(siCustomAchievement, loc("You retrieved the lost part."))
	SendStat(siCustomAchievement, loc("You defended yourself against the Strawberry Assassins."))
	SendStat(siPlayerKills,'1',teamA.name)
	SendStat(siPlayerKills,'0',teamC.name)
	EndGame()
end

function checkPoint1(gear)
	saveCheckPointLocal(2)
end

function checkPoint2(gear)
	saveCheckPointLocal(3)
end

function checkPoint3(gear)
	saveCheckPointLocal(4)
end

function checkPoint4(gear)
	saveCheckPointLocal(5)
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
    TurnTimeLeft = 0
end

function AnimationSetup()
	-- DIALOG 01 - Start, Captain Lime helps Hog Solo because he took part in the battle
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Somewhere else on the planet of fruits, Captain Lime helps Hog Solo"), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("You fought bravely and you helped us win this battle!"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("So, as promised I have brought you where I think that the device you are looking for is hidden."), SAY_SAY, 7000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("I know that your resources are low due to the battle but I'll send two of my best hogs to assist you."), SAY_SAY, 7000}})
	table.insert(dialog01, {func = AnimSay, args = {green1.gear, loc("Good luck!"), SAY_SAY, 2000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG02 - Start, Hog Solo escaped from the previous battle
	AddSkipFunction(dialog02, Skipanim, {dialog02})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog02, {func = AnimCaption, args = {hero.gear, loc("Somewhere else on the planet of fruits Hog Solo gets closer to the device"), 5000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("You are the one who fled! So, you are alive."), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("I'm still low on hogs. If you are not afraid I could use a set of extra hands."), SAY_SAY, 4000}})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 8000}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("I am sorry but I was looking for a device that may be hidden somewhere around here."), SAY_SAY, 4500}})
	table.insert(dialog02, {func = AnimWait, args = {green1.gear, 12500}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("Many long forgotten things can be found in the same tunnels that we are about to explore!"), SAY_SAY, 7000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("If you help us you can keep the device if you find it but we'll keep everything else."), SAY_SAY, 7000}})
	table.insert(dialog02, {func = AnimSay, args = {green1.gear, loc("What do you say? Are you in?"), SAY_SAY, 3000}})
	table.insert(dialog02, {func = AnimWait, args = {hero.gear, 1800}})
	table.insert(dialog02, {func = AnimSay, args = {hero.gear, loc("Okay then!"), SAY_SAY, 2000}})
	table.insert(dialog02, {func = AnimSwitchHog, args = {hero.gear}})
	-- DIALOG03 - At crates, hero learns that Captain Lime is bad
	AddSkipFunction(dialog03, Skipanim, {dialog03})
	table.insert(dialog03, {func = AnimWait, args = {hero.gear, 4000}})
	table.insert(dialog03, {func = FollowGear, args = {hero.gear}})
	table.insert(dialog03, {func = AnimSay, args = {hero.gear, loc("Hooray! I've found it, now I have to get back to Captain Lime!"), SAY_SAY, 4000}})
	table.insert(dialog03, {func = AnimWait, args = {green1.gear, 4000}})
	table.insert(dialog03, {func = AnimSay, args = {green1.gear, loc("This Hog Solo is so naive! When he returns I'll shoot him and keep that device for myself!"), SAY_THINK, 4000}})
	table.insert(dialog03, {func = goToThesurface, args = {hero.gear}})
	-- DIALOG04 - At crates, hero learns about the Assassins ambush
	AddSkipFunction(dialog04, Skipanim, {dialog04})
	table.insert(dialog04, {func = AnimWait, args = {hero.gear, 4000}})
	table.insert(dialog04, {func = FollowGear, args = {hero.gear}})
	table.insert(dialog04, {func = AnimSay, args = {hero.gear, loc("Hooray! I've found it, now I have to get back to Captain Lime!"), SAY_SAY, 4000}})
	table.insert(dialog04, {func = AnimWait, args = {redHedgehogs[1].gear, 4000}})
	table.insert(dialog04, {func = AnimSay, args = {redHedgehogs[1].gear, loc("We have spotted the enemy! We'll attack when the enemies start gathering!"), SAY_THINK, 4000}})
	table.insert(dialog04, {func = goToThesurface, args = {hero.gear}})
end

------------- OTHER FUNCTIONS ---------------

function goToThesurface()
	TurnTimeLeft = 0
end

function wind()
	SetWind(GetRandom(201)-100)
end

function saveHogsPositions()
	local positions;
	positions = GetX(hero.gear)..","..GetY(hero.gear)
	if GetHealth(green2.gear) then
		positions = positions..","..GetX(green2.gear)..","..GetY(green2.gear)
	else
		positions = positions..",1,1"
	end
	if GetHealth(green3.gear) then
		positions = positions..","..GetX(green3.gear)..","..GetY(green3.gear)
	else
		positions = positions..",1,1"
	end
	SaveCampaignVar("HogsPosition", positions)
end

function loadHogsPositions()
	local positions;
	if GetCampaignVar("HogsPosition") then
		positions = GetCampaignVar("HogsPosition")
	else
		return
	end
	positions = split(positions,",")
	if positions[1] then
		hero.x = positions[1]
		hero.y = positions[2]
	end
	if positions[3] then
		green2.x = tonumber(positions[3])
		green2.y = tonumber(positions[4])
	end
	if positions[5] then
		green3.x = tonumber(positions[5])
		green3.y = tonumber(positions[6])
	end
end

function saveWeapons()
	-- firepunch - gilder - deagle - watermelon - sniper
	SaveCampaignVar("HeroAmmo", GetAmmoCount(hero.gear, amFirePunch)..GetAmmoCount(hero.gear, amGirder)..
			GetAmmoCount(hero.gear, amDEagle)..GetAmmoCount(hero.gear, amWatermelon)..GetAmmoCount(hero.gear, amSniperRifle))
end

function loadWeapons()
	local ammo = GetCampaignVar("HeroAmmo")
	AddAmmo(hero.gear, amFirePunch, tonumber(ammo:sub(1,1)))
	AddAmmo(hero.gear, amGirder, tonumber(ammo:sub(2,2)))
	AddAmmo(hero.gear, amDEagle, tonumber(ammo:sub(3,3)))
	AddAmmo(hero.gear, amWatermelon, tonumber(ammo:sub(4,4)))
	AddAmmo(hero.gear, amSniperRifle, tonumber(ammo:sub(5,5)))
end

function isHeroAtWrongPlace()
	if GetX(hero.gear) > 1480 and GetX(hero.gear) < 1892 and GetY(hero.gear) > 1000 and GetY(hero.gear) < 1220 then
		return true
	end
	return false
end

function saveCheckPointLocal(cpoint)
	AnimCaption(hero.gear, loc("Checkpoint reached!"), 3000)
	saveCheckpoint(cpoint)
	SaveCampaignVar("HeroHealth", GetHealth(hero.gear))
	saveHogsPositions()
	saveWeapons()
end

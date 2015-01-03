------------------- ABOUT ----------------------
--
-- In the desert planet Hero will have to explore
-- the dunes below the surface and find the hidden
-- crates. It is told that one crate contains the
-- lost part.

-- Idea: game will be successfully end when the 2 lower crates are collected
-- it would be more defficult (and sadistic) if one should collect *all* the crates

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Searching in the dust")
local heroIsInBattle = false
local ongoingBattle = 0
local cratesFound = 0
local checkPointReached = 1 -- 1 is normal spawn
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("The device part is hidden in one of the crates! Go and get it!").."|"..
			loc("Most of the destructible terrain in marked with blue color"), 1, 4500},
}
-- crates
local btorch1Y = 60
local btorch1X = 2700
local btorch2Y = 1900
local btorch2X = 2150
local btorch3Y = 980
local btorch3X = 3260
local rope1Y = 970
local rope1X = 3200
local rope2Y = 1900
local rope2X = 680
local rope3Y = 1850
local rope3X = 2460
local portalY = 480
local portalX = 1465
local girderY = 1630
local girderX = 3350
-- win crates
local btorch2 = {}
local girder = {}
-- hogs
local hero = {}
local ally = {}
local smuggler1 = {}
local smuggler2 = {}
local smuggler3 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
-- hedgehogs values
hero.name = loc("Hog Solo")
hero.x = 1740
hero.y = 40
hero.dead = false
ally.name = loc("Chief Sandologist")
ally.x = 1660
ally.y = 40
smuggler1.name = loc("Sandy")
smuggler1.x = 400
smuggler1.y = 235
smuggler2.name = loc("Spike")
smuggler2.x = 736
smuggler2.y = 860
smuggler3.name = loc("Sandstorm")
smuggler3.x = 1940
smuggler3.y = 1625
teamA.name = loc("PAotH")
teamA.color = tonumber("FF0000",16) -- red
teamB.name = loc("Smugglers")
teamB.color = tonumber("0033FF",16) -- blues
teamC.name = loc("Hog Solo")
teamC.color = tonumber("38D61C",16) -- green

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Delay = 3
	HealthCaseAmount = 30
	Map = "desert01_map"
	Theme = "Desert"

	-- get the check point
	checkPointReached = initCheckpoint("desert01")
	-- get hero health
	local heroHealth = 100
	if checkPointReached > 1 and tonumber(GetCampaignVar("HeroHealth")) then
		heroHealth = tonumber(GetCampaignVar("HeroHealth"))
	end

	-- Hog Solo
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, heroHealth, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	-- PAotH undercover scientist and chief Sandologist
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	ally.gear = AddHog(ally.name, 0, 100, "Cowboy")
	AnimSetGearPosition(ally.gear, ally.x, ally.y)
	-- Smugglers
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	smuggler1.gear = AddHog(smuggler1.name, 1, 100, "hair_orange")
	AnimSetGearPosition(smuggler1.gear, smuggler1.x, smuggler1.y)
	smuggler2.gear = AddHog(smuggler2.name, 1, 100, "lambda")
	AnimSetGearPosition(smuggler2.gear, smuggler2.x, smuggler2.y)
	smuggler3.gear = AddHog(smuggler3.name, 1, 100, "beefeater")
	AnimSetGearPosition(smuggler3.gear, smuggler3.x, smuggler3.y)

	if checkPointReached == 1 then
		-- Start of the game
	elseif checkPointReached == 2 then
		AnimSetGearPosition(hero.gear, 1050, 615)
		HogTurnLeft(hero.gear, true)
	elseif checkPointReached == 3 then
		AnimSetGearPosition(hero.gear, 1680, 920)
		HogTurnLeft(hero.gear, true)
	elseif checkPointReached == 4 then
		AnimSetGearPosition(hero.gear, 1160, 1180)
	elseif checkPointReached == 5 then
		local positions = GetCampaignVar("HogsPosition")
		positions = split(positions,",")
		local x
		local y
		if positions[1] then
			x = positions[1]
			y = positions[2]
		else
			-- this should *NEVER* happen, remove?
			x = girderX+40
			y = girderY-30
		end
		AnimSetGearPosition(hero.gear, x, y)
	end

	AnimInit()
	AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onHeroAtFirstBattle, {hero.gear}, heroAtFirstBattle, {hero.gear}, 1)
	AddEvent(onHeroAtCheckpoint4, {hero.gear}, heroAtCheckpoint4, {hero.gear}, 0)
	AddEvent(onHeroAtThirdBattle, {hero.gear}, heroAtThirdBattle, {hero.gear}, 0)
	AddEvent(onCheckForWin1, {hero.gear}, checkForWin1, {hero.gear}, 0)
	AddEvent(onCheckForWin2, {hero.gear}, checkForWin2, {hero.gear}, 0)
	AddEvent(onCrateDestroyed, {hero.gear}, crateDestroyed, {hero.gear}, 0)

	-- smugglers ammo
	AddAmmo(smuggler1.gear, amBazooka, 2)
	AddAmmo(smuggler1.gear, amGrenade, 2)
	AddAmmo(smuggler1.gear, amDEagle, 2)
	AddAmmo(smuggler3.gear, amRope, 2)

	-- spawn crates
	SpawnAmmoCrate(btorch2X, btorch2Y, amBlowTorch)
	SpawnAmmoCrate(btorch3X, btorch3Y, amBlowTorch)
	SpawnAmmoCrate(rope1X, rope1Y, amRope)
	SpawnAmmoCrate(rope2X, rope2Y, amRope)
	SpawnAmmoCrate(rope3X, rope3Y, amRope)
	SpawnAmmoCrate(portalX, portalY, amPortalGun)
	SpawnAmmoCrate(girderX, girderY, amGirder)

	SpawnHealthCrate(3300, 970)

	-- adding mines - BOOM!
	AddGear(1280, 460, gtMine, 0, 0, 0, 0)
	AddGear(270, 460, gtMine, 0, 0, 0, 0)
	AddGear(3460, 60, gtMine, 0, 0, 0, 0)
	AddGear(3500, 240, gtMine, 0, 0, 0, 0)
	AddGear(3410, 670, gtMine, 0, 0, 0, 0)
	AddGear(3450, 720, gtMine, 0, 0, 0, 0)

	local x = 800
	while x < 1630 do
		AddGear(x, 900, gtMine, 0, 0, 0, 0)
		x = x + GetRandom(13)+8
	end
	x = 1890
	while x < 2988 do
		AddGear(x, 760, gtMine, 0, 0, 0, 0)
		x = x + GetRandom(13)+8
	end
	x = 2500
	while x < 3300 do
		AddGear(x, 1450, gtMine, 0, 0, 0, 0)
		x = x + GetRandom(13)+8
	end
	x = 1570
	while x < 2900 do
		AddGear(x, 470, gtMine, 0, 0, 0, 0)
		x = x + GetRandom(13)+8
	end

	if checkPointReached == 1 then
		AddEvent(onHeroFleeFirstBattle, {hero.gear}, heroFleeFirstBattle, {hero.gear}, 1)
		AddEvent(onHeroAtCheckpoint2, {hero.gear}, heroAtCheckpoint2, {hero.gear}, 0)
		AddEvent(onHeroAtCheckpoint3, {hero.gear}, heroAtCheckpoint3, {hero.gear}, 0)
		-- crates
		SpawnAmmoCrate(btorch1X, btorch1Y, amBlowTorch)
		SpawnHealthCrate(680, 460)
		-- hero ammo
		AddAmmo(hero.gear, amRope, 2)
		AddAmmo(hero.gear, amBazooka, 3)
		AddAmmo(hero.gear, amParachute, 1)
		AddAmmo(hero.gear, amGrenade, 6)
		AddAmmo(hero.gear, amDEagle, 4)
		AddAmmo(hero.gear, amRCPlane, tonumber(getBonus(1)))

		AddAnim(dialog01)
	elseif checkPointReached == 2 or checkPointReached == 3 then
		ShowMission(campaignName, missionName, loc("The device part is hidden in one of the crates! Go and get it!"), -amSkip, 0)
		loadHeroAmmo()

		secondBattle()
	elseif checkPointReached == 4 or checkPointReached == 5 then
		ShowMission(campaignName, missionName, loc("The part device is hidden in one of the crates! Go and get it!"), -amSkip, 0)
		loadHeroAmmo()
	end

	SendHealthStatsOff()
end

function onNewTurn()
	if CurrentHedgehog ~= hero.gear and not heroIsInBattle then
		TurnTimeLeft = 0
	elseif CurrentHedgehog == hero.gear and not heroIsInBattle then
		TurnTimeLeft = -1
	elseif (CurrentHedgehog == smuggler2.gear or CurrentHedgehog == smuggler3.gear) and ongoingBattle == 1 then
		AnimSwitchHog(hero.gear)
		TurnTimeLeft = 0
	elseif (CurrentHedgehog == smuggler1.gear or CurrentHedgehog == smuggler3.gear) and ongoingBattle == 2 then
		AnimSwitchHog(hero.gear)
		TurnTimeLeft = 0
	elseif (CurrentHedgehog == smuggler1.gear or CurrentHedgehog == smuggler2.gear) and ongoingBattle == 3 then
		AnimSwitchHog(hero.gear)
		TurnTimeLeft = 0
	elseif CurrentHedgehog == ally.gear then
		TurnTimeLeft = 0
	end
end

function onGameTick()
	AnimUnWait()
	if ShowAnimation() == false then
		return
	end
	ExecuteAfterAnimations()
	CheckEvents()
end

function onAmmoStoreInit()
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amRope, 0, 0, 0, 1)
	SetAmmo(amPortalGun, 0, 0, 0, 1)
	SetAmmo(amGirder, 0, 0, 0, 3)
end

function onGearAdd(gear)
	if GetGearType(gear) == gtCase then
		if GetX(gear) == btorch2X and GetY(gear) == btorch2Y then
			btorch2.gear = gear
			btorch2.destroyed = false
			btorch2.deleted = false
		elseif GetX(gear) == girderX and GetY(gear) == girderY then
			girder.gear = gear
			girder.destroyed = false
			girder.deleted = false
		end
	end
end

function onGearDamage(gear, damage)
	if gear == girder.gear then
		girder.destroyed = true
	elseif gear == btorch2.gear then
		btorch2.destroyed = true
	end
end

function onGearDelete(gear)
	if gear == girder.gear then
		girder.deleted = true
	elseif gear == btorch2.gear then
		btorch2.deleted = true
	end
	if gear == hero.gear then
		hero.dead = true
	elseif (gear == smuggler1.gear or gear == smuggler2.gear or gear == smuggler3.gear) and heroIsInBattle then
		heroIsInBattle = false
		ongoingBattle = 0
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

function onHeroAtFirstBattle(gear)
	if not hero.dead and not heroIsInBattle and GetHealth(smuggler1.gear) and GetX(hero.gear) <= 1450 and GetX(hero.gear) > 80
			and GetY(hero.gear) <= GetY(smuggler1.gear)+5 and GetY(hero.gear) >= GetY(smuggler1.gear)-40 and StoppedGear(hero.gear) then
		return true
	end
	return false
end

function onHeroFleeFirstBattle(gear)
	if GetHealth(hero.gear) and GetHealth(smuggler1.gear) and heroIsInBattle
			and not gearIsInCircle(smuggler1.gear, GetX(hero.gear), GetY(hero.gear), 1400, false)
			and StoppedGear(hero.gear) then
		return true
	end
	return false
end

-- saves the location of the hero and prompts him for the second battle
function onHeroAtCheckpoint2(gear)
	if not hero.dead and GetX(hero.gear) > 1000 and GetX(hero.gear) < 1100
			and GetY(hero.gear) > 590 and GetY(hero.gear) < 700 and StoppedGear(hero.gear) then
		return true
	end
	return false
end

function onHeroAtCheckpoint3(gear)
	if not hero.dead and GetX(hero.gear) > 1610 and GetX(hero.gear) < 1680
			and GetY(hero.gear) > 850 and GetY(hero.gear) < 1000 and StoppedGear(hero.gear) then
		return true
	end
	return false
end

function onHeroAtCheckpoint4(gear)
	if not hero.dead and GetX(hero.gear) > 1110 and GetX(hero.gear) < 1300
			and GetY(hero.gear) > 1100 and GetY(hero.gear) < 1220 then
		return true
	end
	return false
end

function onHeroAtThirdBattle(gear)
	if not hero.dead and GetX(hero.gear) > 2000 and GetX(hero.gear) < 2200
			and GetY(hero.gear) > 1430 and GetY(hero.gear) < 1670 then
		return true
	end
	return false
end

function onCheckForWin1(gear)
	if not hero.dead and not btorch2.destroyed and btorch2.deleted then
		return true
	end
	return false
end

function onCheckForWin2(gear)
	if not hero.dead and not girder.destroyed and girder.deleted then
		return true
	end
	return false
end

function onCrateDestroyed(gear)
	if not hero.dead and girder.destroyed or btorch2.destroyed then
		return true
	end
	return false
end

-------------- ACTIONS ------------------

function heroDeath(gear)
	lose()
end

function heroAtFirstBattle(gear)
	AnimCaption(hero.gear, loc("A smuggler! Prepare for battle"), 5000)
	TurnTimeLeft = 0
	heroIsInBattle = true
	ongoingBattle = 1
	AnimSwitchHog(smuggler1.gear)
	TurnTimeLeft = 0
end

function heroFleeFirstBattle(gear)
	AnimSay(smuggler1.gear, loc("Run away you coward!"), SAY_SHOUT, 4000)
	TurnTimeLeft = 0
	heroIsInBattle = false
	ongoingBattle = 0
end

function heroAtCheckpoint2(gear)
	if GetAmmoCount(hero.gear, amRope) > 0 or GetAmmoCount(hero.gear, amParachute) > 0 then
		saveCheckPointLocal("2")
	end
	secondBattle()
end

function heroAtCheckpoint3(gear)
	if GetAmmoCount(hero.gear, amRope) > 0 then
		saveCheckPointLocal("3")
	end
	secondBattle()
end

function heroAtCheckpoint4(gear)
	saveCheckPointLocal("4")
end

function heroAtThirdBattle(gear)
	heroIsInBattle = true
	ongoingBattle = 3
	AnimSay(smuggler3.gear, loc("Who's there?! I'll get you..."), SAY_SHOUT, 5000)
	AnimSwitchHog(smuggler3.gear)
	TurnTimeLeft = 0
end

function crateDestroyed(gear)
	lose()
end

-- for some weird reson I couldn't call the same action for both events
function checkForWin1(gear)
	checkForWin()
end

function checkForWin2(gear)
	-- ok lets place one more checkpoint as next part seems challenging without rope
	if cratesFound ==  0 then
		saveCheckPointLocal("5")
		SaveCampaignVar("HogsPosition", GetX(hero.gear)..","..GetY(hero.gear))
	end

	checkForWin()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
    AnimSwitchHog(hero.gear)
	if anim == dialog01 then
		startMission()
	end
end

function AnimationSetup()
	-- DIALOG 01 - Start, getting info about the device
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("In the Planet of Sand, you have to double check your moves..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Finally you are here..."), SAY_SAY, 2000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Thank you for meeting me on such a short notice!"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {ally.gear, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("No problem, I would do anything for H!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Now listen carefully! Below us there are tunnels that have been created naturally over the years"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("I have heard that the local tribes say that many years ago some PAotH scientists were dumping their waste here"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("H confirmed that there isn't such a PAotH activity logged"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("So, I believe that it's a good place to start"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Beware though! Many smugglers come often to explore these tunnels and scavenge whatever valuable items they can find"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("They won't hesitate to attack you in order to rob you!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 6000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("OK, I'll be extra careful!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimWait, args = {ally.gear, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("There is the tunnel entrance"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Good luck!"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = startMission, args = {hero.gear}})
end

--------------- OTHER FUNCTIONS ------------------

function startMission()
	AnimSwitchHog(ally.gear)
	TurnTimeLeft = 0
end

function secondBattle()
	-- second battle
	if heroIsInBattle and ongoingBattle == 1 then
		AnimSay(smuggler1.gear, loc("Get him Spike!"), SAY_SHOUT, 4000)
	end
	heroIsInBattle = true
	ongoingBattle = 2
	AnimSay(smuggler2.gear, loc("This is seems like a wealthy hedgehog, nice..."), SAY_THINK, 5000)
	AnimSwitchHog(smuggler2.gear)
	TurnTimeLeft = 0
end

function saveCheckPointLocal(cpoint)
	-- save checkpoint
	saveCheckpoint(cpoint)
	SaveCampaignVar("HeroHealth", GetHealth(hero.gear))
	-- bazooka - grenade - rope - parachute - deagle - btorch - construct - portal - rcplane
	SaveCampaignVar("HeroAmmo", GetAmmoCount(hero.gear, amBazooka)..GetAmmoCount(hero.gear, amGrenade)..
			GetAmmoCount(hero.gear, amRope)..GetAmmoCount(hero.gear, amParachute)..GetAmmoCount(hero.gear, amDEagle)..
			GetAmmoCount(hero.gear, amBlowTorch)..GetAmmoCount(hero.gear, amGirder)..
			GetAmmoCount(hero.gear, amPortalGun)..GetAmmoCount(hero.gear, amRCPlane))
	AnimCaption(hero.gear, loc("Checkpoint reached!"), 5000)
end

function loadHeroAmmo()
	-- hero ammo
	local ammo = GetCampaignVar("HeroAmmo")
	AddAmmo(hero.gear, amRope, tonumber(ammo:sub(3,3)))
	AddAmmo(hero.gear, amBazooka, tonumber(ammo:sub(1,1)))
	AddAmmo(hero.gear, amParachute, tonumber(ammo:sub(4,4)))
	AddAmmo(hero.gear, amGrenade, tonumber(ammo:sub(2,2)))
	AddAmmo(hero.gear, amDEagle, tonumber(ammo:sub(5,5)))
	AddAmmo(hero.gear, amBlowTorch, tonumber(ammo:sub(6,6)))
	-- weird, if 0 bazooka isn't displayed in the weapons menu
	if tonumber(ammo:sub(7,7)) > 0 then
		AddAmmo(hero.gear, amGirder, tonumber(ammo:sub(7,7)))
	end
	AddAmmo(hero.gear, amPortalGun, tonumber(ammo:sub(8,8)))
	AddAmmo(hero.gear, amRCPlane, tonumber(ammo:sub(9,9)))
end

function checkForWin()
	if cratesFound ==  0 then
		-- have to look more
		AnimSay(hero.gear, loc("Haven't found it yet..."), SAY_THINK, 5000)
		cratesFound = cratesFound + 1
	elseif cratesFound == 1 then
		-- end game
		saveCompletedStatus(5)
		AnimSay(hero.gear, loc("Hoorah!!!"), SAY_SHOUT, 5000)
		SendStat(siGameResult, loc("Congratulations, you won!"))
		SendStat(siCustomAchievement, loc("To win the game you had to collect the 2 crates with no specific order"))
		SendStat(siPlayerKills,'1',teamC.name)
		SendStat(siPlayerKills,'0',teamB.name)
		EndGame()
	end
end

function lose()
	SendStat(siGameResult, loc("Hog Solo lost, try again!"))
	SendStat(siCustomAchievement, loc("To win the game you have to find the right crate"))
	SendStat(siCustomAchievement, loc("You can avoid some battles"))
	SendStat(siCustomAchievement, loc("Use your ammo wisely"))
	SendStat(siCustomAchievement, loc("Don't destroy the device crate!"))
	SendStat(siPlayerKills,'1',teamB.name)
	SendStat(siPlayerKills,'0',teamC.name)
	EndGame()
end

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
local ropeGear = nil
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("The device part is hidden in one of the crates! Go and get it!").."|"..
			loc("Most of the destructible terrain is marked with dashed lines.").."|"..loc("Mines time: 0 seconds"), 1, 6000},
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
local btorch2 = { gear = nil, destroyed = false, deleted = false}
local girder = { gear = nil, destroyed = false, deleted = false}
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
teamA.color = -6
teamB.name = loc("Smugglers")
teamB.color = -7
teamC.name = loc("Hog Solo")
teamC.color = -6

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	TurnTime = 20000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	HealthCaseAmount = 30
	-- Disable Sudden Death
	HealthDecrease = 0
	WaterRise = 0
	Map = "desert01_map"
	Theme = "Desert"

	-- get hero health
	local heroHealth = 100

	-- Hog Solo
	AddTeam(teamC.name, teamC.color, "Simple", "Island", "Default", "hedgewars")
	hero.gear = AddHog(hero.name, 0, heroHealth, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	-- PAotH undercover scientist and chief Sandologist
	AddTeam(teamA.name, teamA.color, "Earth", "Island", "Default", "cm_galaxy")
	ally.gear = AddHog(ally.name, 0, 100, "Cowboy")
	AnimSetGearPosition(ally.gear, ally.x, ally.y)
	-- Smugglers
	AddTeam(teamB.name, teamB.color, "chest", "Island", "Default", "cm_bloodyblade")
	smuggler1.gear = AddHog(smuggler1.name, 1, 100, "hair_orange")
	AnimSetGearPosition(smuggler1.gear, smuggler1.x, smuggler1.y)
	smuggler2.gear = AddHog(smuggler2.name, 1, 100, "lambda")
	AnimSetGearPosition(smuggler2.gear, smuggler2.x, smuggler2.y)
	smuggler3.gear = AddHog(smuggler3.name, 1, 100, "beefeater")
	AnimSetGearPosition(smuggler3.gear, smuggler3.x, smuggler3.y)

	AnimInit(true)
	AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onHeroAtFirstBattle, {hero.gear}, heroAtFirstBattle, {hero.gear}, 1)
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
	SpawnSupplyCrate(btorch3X, btorch3Y, amBlowTorch)
	SpawnSupplyCrate(rope1X, rope1Y, amRope)
	SpawnSupplyCrate(rope2X, rope2Y, amRope)
	SpawnSupplyCrate(rope3X, rope3Y, amRope)
	SpawnSupplyCrate(portalX, portalY, amPortalGun)
	SpawnHealthCrate(3300, 970)

	-- the win crates, collect both to win
	btorch2.gear = SpawnSupplyCrate(btorch2X, btorch2Y, amBlowTorch)
	girder.gear = SpawnSupplyCrate(girderX, girderY, amGirder)

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

	AddEvent(onHeroFleeFirstBattle, {hero.gear}, heroFleeFirstBattle, {hero.gear}, 1)
	AddEvent(onHeroAtBattlePoint1, {hero.gear}, heroAtBattlePoint1, {hero.gear}, 0)
	AddEvent(onHeroAtBattlePoint2, {hero.gear}, heroAtBattlePoint2, {hero.gear}, 0)
	-- crates
	SpawnSupplyCrate(btorch1X, btorch1Y, amBlowTorch)
	SpawnHealthCrate(680, 460)
	-- hero ammo
	AddAmmo(hero.gear, amRope, 2)
	AddAmmo(hero.gear, amBazooka, 3)
	AddAmmo(hero.gear, amParachute, 1)
	AddAmmo(hero.gear, amGrenade, 6)
	AddAmmo(hero.gear, amDEagle, 4)
	AddAmmo(hero.gear, amRCPlane, tonumber(getBonus(1)))
	AddAmmo(hero.gear, amSkip, 0)

	AddAnim(dialog01)

	SendHealthStatsOff()
end

function onNewTurn()
	local function getReady(hog)
		-- This clears the "Get ready, Hog!" caption from the engine, because it will name the
		-- false hog because we immediately switch the hog after the turn start.
		-- TODO: Find a better method for this and show the real hog name (preferably using an engine string)
		AddCaption("")
	end

	if CurrentHedgehog ~= hero.gear and not heroIsInBattle then
		AnimSwitchHog(hero.gear)
		getReady(hero.gear)
		SetTurnTimeLeft(MAX_TURN_TIME)
	elseif CurrentHedgehog == hero.gear and not heroIsInBattle then
		SetTurnTimeLeft(MAX_TURN_TIME)
	elseif (CurrentHedgehog == smuggler2.gear or CurrentHedgehog == smuggler3.gear) and ongoingBattle == 1 then
		AnimSwitchHog(smuggler1.gear)
		getReady(smuggler1.gear)
	elseif (CurrentHedgehog == smuggler1.gear or CurrentHedgehog == smuggler3.gear) and ongoingBattle == 2 then
		AnimSwitchHog(smuggler2.gear)
		getReady(smuggler2.gear)
	elseif (CurrentHedgehog == smuggler1.gear or CurrentHedgehog == smuggler2.gear) and ongoingBattle == 3 then
		AnimSwitchHog(smuggler3.gear)
		getReady(smuggler3.gear)
	elseif CurrentHedgehog == ally.gear then
		AnimSwitchHog(hero.gear)
		getReady(hero.gear)
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
	SetAmmo(amSkip, 9, 0, 0, 1)
end

function onGearAdd(gear)
	if GetGearType(gear) == gtRope then
		ropeGear = gear
	end
end

function onGearDelete(gear)
	if GetGearType(gear) == gtRope then
		ropeGear = nil
	end
	local foundDeviceCrateCandidate = function(candidate_crate_table, other_crate_table)
		candidate_crate_table.deleted = true
		-- Evaluates to false if crate has been collected
		if (band(GetGearMessage(candidate_crate_table.gear), gmDestroy) == 0) then
			candidate_crate_table.destroyed = true
		end

		if cratesFound == 0 then
			-- First win crate collected:
			-- Turn the other crate into a fake crate; this will “contain” the device.
			SetGearPos(other_crate_table.gear, bor(GetGearPos(other_crate_table.gear), 0x8))
		elseif cratesFound == 1 then
			if not candidate_crate_table.destroyed then
				-- Second win crate collected:
				-- This crate contains the anti-gravity part! VICTORY!
				PlaySound(sndShotgunReload)
				-- It's displayed as if collecting a normal ammo/utility crate. :-)
				AddCaption(loc("Anti-Gravity Device Part (+1)"), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmoinfo)
			end
		end
	end

	if gear == girder.gear then
		foundDeviceCrateCandidate(girder, btorch2)
	elseif gear == btorch2.gear then
		foundDeviceCrateCandidate(btorch2, girder)
	end
	if gear == hero.gear then
		hero.dead = true
	elseif (gear == smuggler1.gear or gear == smuggler2.gear or gear == smuggler3.gear) and heroIsInBattle then
		heroIsInBattle = false
		AddAmmo(hero.gear, amSkip, 0)
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
	if not hero.dead and not heroIsInBattle and GetHealth(smuggler1.gear) and GetX(hero.gear) <= 1233 and GetX(hero.gear) > 80
			and GetY(hero.gear) <= GetY(smuggler1.gear)+5 and GetY(hero.gear) >= GetY(smuggler1.gear)-40 and
			-- If hero is standing or at a rope
			(StoppedGear(hero.gear) or GetGearElasticity(hero.gear) ~= 0) then
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
function onHeroAtBattlePoint1(gear)
	if not hero.dead and GetX(hero.gear) > 1000 and GetX(hero.gear) < 1100
			and GetY(hero.gear) > 590 and GetY(hero.gear) < 700 and StoppedGear(hero.gear)
			and (StoppedGear(hero.gear) or GetGearElasticity(hero.gear) ~= 0) then
		return true
	end
	return false
end

function onHeroAtBattlePoint2(gear)
	if not hero.dead and GetX(hero.gear) > 1610 and GetX(hero.gear) < 1680
			and GetY(hero.gear) > 850 and GetY(hero.gear) < 1000
			and (StoppedGear(hero.gear) or GetGearElasticity(hero.gear) ~= 0) then
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
	-- Remember velocity to restore it later
	local dx, dy = GetGearVelocity(hero.gear)
	-- Hog gets scared if on rope
	if isOnRope() then
		PlaySound(sndRopeRelease)
		HogSay(hero.gear, loc("Gasp! A smuggler!"), SAY_SHOUT)
		dx = div(dx, 3)
		dy = div(dy, 3)
	end
	EndTurn(true)
	heroIsInBattle = true
	AddAmmo(hero.gear, amSkip, 100)
	ongoingBattle = 1
	AnimSwitchHog(smuggler1.gear)
	EndTurn(true)
	SetGearVelocity(hero.gear, dx, dy)
end

function heroFleeFirstBattle(gear)
	AnimSay(smuggler1.gear, loc("Run away, you coward!"), SAY_SHOUT, 4000)
	EndTurn(true)
	heroIsInBattle = false
	AddAmmo(hero.gear, amSkip, 0)
	ongoingBattle = 0
end

function heroAtBattlePoint1(gear)
	secondBattle()
end

function heroAtBattlePoint2(gear)
	secondBattle()
end

function heroAtThirdBattle(gear)
	heroIsInBattle = true
	AddAmmo(hero.gear, amSkip, 100)
	ongoingBattle = 3
	AnimSay(smuggler3.gear, loc("Who's there?! I'll get you!"), SAY_SHOUT, 5000)
	local dx, dy = GetGearVelocity(hero.gear)
	-- Hog gets scared and falls from rope
	if isOnRope() then
		PlaySound(sndRopeRelease)
		HogSay(hero.gear, loc("Yikes!"), SAY_SHOUT)
		dx = div(dx, 3)
		dy = div(dy, 3)
	end
	AnimSwitchHog(smuggler3.gear)
	EndTurn(true)
	SetGearVelocity(hero.gear, dx, dy)
end

function crateDestroyed(gear)
	lose()
end

-- for some weird reson I couldn't call the same action for both events
function checkForWin1(gear)
	checkForWin()
end

function checkForWin2(gear)
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
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("On the Planet of Sand, you have to double check your moves ..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Finally you are here!"), SAY_SAY, 2000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Thank you for meeting me on such a short notice!"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {ally.gear, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("No problem, I would do anything for H!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Now listen carefully! Below us there are tunnels that have been created naturally over the years"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("I have heard that the local tribes say that many years ago some PAotH scientists were dumping their waste here."), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("H confirmed that there isn't such a PAotH activity logged."), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("So, I believe that it's a good place to start."), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Beware, though! Many smugglers come often to explore these tunnels and scavenge whatever valuable items they can find."), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("They won't hesitate to attack you in order to rob you!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 6000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Okay, I'll be extra careful!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimWait, args = {ally.gear, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("The tunnel entrance is over there."), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Good luck!"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = ShowMission, args = goals[dialog01]})
	table.insert(dialog01, {func = startMission, args = {hero.gear}})
end

--------------- OTHER FUNCTIONS ------------------

function isOnRope()
	if ropeGear then
		return true
	end
	return false
end

function startMission()
	AnimSwitchHog(ally.gear)
	EndTurn(true)
end

function secondBattle()
	-- second battle
	if heroIsInBattle and ongoingBattle == 1 then
		AnimSay(smuggler1.gear, loc("Get him, Spike!"), SAY_SHOUT, 4000)
	end
	local dx, dy = GetGearVelocity(hero.gear)
	-- Hog gets scared if on rope
	if isOnRope() then
		PlaySound(sndRopeRelease)
		HogSay(hero.gear, loc("Gasp!"), SAY_SHOUT)
		dx = div(dx, 3)
		dy = div(dy, 3)
	end
	heroIsInBattle = true
	AddAmmo(hero.gear, amSkip, 100)
	ongoingBattle = 2
	AnimSay(smuggler2.gear, loc("This seems like a wealthy hedgehog, nice ..."), SAY_THINK, 5000)
	AnimSwitchHog(smuggler2.gear)
	EndTurn(true)
	SetGearVelocity(hero.gear, dx, dy)
end

function checkForWin()
	if cratesFound ==  0 then
		-- have to look more
		AnimSay(hero.gear, loc("Haven't found it yet ..."), SAY_THINK, 5000)
		cratesFound = cratesFound + 1
	elseif cratesFound == 1 then
		-- end game
		saveCompletedStatus(5)
		AnimSay(hero.gear, loc("I found it! Hooray!"), SAY_SHOUT, 5000)
		PlaySound(sndVictory, hero.gear)
		SendStat(siGameResult, loc("Congratulations, you won!"))
		SendStat(siCustomAchievement, loc("To win the game you had to collect the 2 crates with no specific order."))
		sendSimpleTeamRankings({teamC.name, teamA.name, teamB.name})
		EndGame()
	end
end

function lose()
	SendStat(siGameResult, loc("Hog Solo lost, try again!"))
	SendStat(siCustomAchievement, loc("To win the game you have to find the right crate."))
	SendStat(siCustomAchievement, loc("You can avoid some battles."))
	SendStat(siCustomAchievement, loc("Use your ammo wisely."))
	SendStat(siCustomAchievement, loc("Don't destroy the device crate!"))
	sendSimpleTeamRankings({teamB.name, teamC.name, teamA.name})
	EndGame()
end

------------------- ABOUT ----------------------
--
-- Hero has collected all the anti-gravity device
-- parts but because of the size of the meteorite
-- he needs to detonate some faulty explosives that
-- PAotH have previously placed on it.

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("The big bang")
local challengeObjectives = loc("Find a way to detonate all the explosives and stay alive!").."|"..
							loc("Areas with a security outline are indestructible.").."|"..
							loc("Areas with a green dashed outline are portal-proof.").."|"..
							loc("Mines time: 0 seconds")

local dialog01 = {}
local explosives = {}
local currentHealth = 1
local currentDamage = 0
-- hogs
local hero = {
	name = loc("Hog Solo"),
	x = 790,
	y = 70
}
-- teams
local teamA = {
	name = loc("Hog Solo"),
	color = -6
}

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	GameFlags = gfDisableWind + gfOneClanMode
	Seed = 1
	TurnTime = MAX_TURN_TIME
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	HealthCaseAmount = 35
	Map = "final_map"
	Theme = "EarthRise"
	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0

	-- Hero
	teamA.name = AddMissionTeam(teamA.color)
	hero.gear = AddMissionHog(1)
	hero.name = GetHogName(hero.gear)
	AnimSetGearPosition(hero.gear, hero.x, hero.y)

	initCheckpoint("final")

	AnimInit()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	ShowMission(missionName, loc("Challenge objectives"), challengeObjectives, -amSkip, 7500)

	-- explosives
	x = 400
	while x < 815 do
		local gear = AddGear(x, 500, gtExplosives, 0, 0, 0, 0)
		x = x + GetRandom(26) + 15
		table.insert(explosives, gear)
	end
	-- mines
	local x = 360
	while x < 815 do
		AddGear(x, 480, gtMine, 0, 0, 0, 0)
		x = x + GetRandom(16) + 5
	end
	-- health crate
	SpawnHealthCrate(910, 5)
	-- ammo crates
	SpawnSupplyCrate(930, 1000, amRCPlane)
	SpawnSupplyCrate(1260, 652, amGirder)
	SpawnSupplyCrate(1220, 652, amPickHammer)

	-- ammo
	AddAmmo(hero.gear, amPortalGun, 1)
	AddAmmo(hero.gear, amFirePunch, 1)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onBoom, {hero.gear}, heroBoomReaction, {hero.gear}, 0)
	AnimationSetup()

	SendHealthStatsOff()
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
	SetAmmo(amRCPlane, 0, 0, 0, 1)
	SetAmmo(amPickHammer, 0, 0, 0, 2)
	SetAmmo(amGirder, 0, 0, 0, 1)
end

function onNewTurn()
	currentDamage = 0
	currentHealth = GetHealth(hero.gear)
	if onBoom(hero.gear) then
		heroWin(hero.gear)
	end
end

function onGearDamage(gear, damage)
	if gear == hero.gear then
		currentDamage = currentDamage + damage
	end
end

-------------- EVENTS ------------------

function onHeroDeath(gear)
	if not GetHealth(hero.gear) then
		return true
	end
	return false
end

function onBoom(gear)
	local win = true
	for i=1,table.getn(explosives) do
		if GetHealth(explosives[i]) then
			win = false
			break
		end
	end
	if currentHealth <= currentDamage then
		win = false
	end
	return win
end

-------------- ACTIONS ------------------

function heroDeath(gear)
	SendStat(siGameResult, string.format(loc("%s lost, try again!"), hero.name))
	SendStat(siCustomAchievement, loc("You have to destroy all the explosives without dying!"))
	SendStat(siCustomAchievement, loc("Areas surrounded by a security border are indestructible."))
	SendStat(siCustomAchievement, loc("Areas surrounded by a green dashed outline are portal-proof and repel portals."))
	sendSimpleTeamRankings({teamA.name})
	EndGame()
end

function heroBoomReaction(gear)
	SetSoundMask(sndMissed, true)
	SetSoundMask(sndYesSir, true)
	if GetHealth(gear) and GetHealth(gear) > 0 then
		HogSay(gear, loc("Kaboom! Hahahaha! Take this, stupid meteorite!"), SAY_SHOUT, 2)
	end
end

function heroWin(gear)
	AddAnim(dialog01)
end

function win()
	SetWeapon(amNothing)
	AnimSetInputMask(0)
	saveCompletedStatus(7)
	SaveCampaignVar("Won", "true")
	checkAllMissionsCompleted()
	SendStat(siGameResult, loc("Congratulations, you have saved Hogera!"))
	SendStat(siCustomAchievement, loc("Hogera is safe!"))
	sendSimpleTeamRankings({teamA.name})
	EndGame()
end

------------ ANIMATION STUFF ------------

function Skipanim(anim)
	if anim == dialog01 then
		win()
	end
end

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)
	end
end

function AnimationSetup()
	-- DIALOG 01 - Start, welcome to moon
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 100}})
	table.insert(dialog01, {func = FollowGear, args = {hero.gear}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Hooray! I actually did it! Hogera is safe!"), SAY_SHOUT, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("I'm so glad this is finally over!"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Wait a moment …"), SAY_THINK, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("If some good old explosives were enough to save Hogera …"), SAY_THINK, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("… why did I risk my life to collect all the parts of the anti-gravity device?"), SAY_THINK, 6000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("It was completely useless!"), SAY_THINK, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("We could just have blown up the meteorite from the the beginning!"), SAY_THINK, 5000}})
        -- Hogerian =  Inhabitant of the planet Hogera
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Stupid, stupid Hogerians!"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Or maybe this was all part of an evil plan, so evil that even Prof. Hogevil can't think of it!"), SAY_THINK, 9000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Nah, probably everyone was just stupid."), SAY_THINK, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Except me, of course! I just saved a whole planet!"), SAY_THINK, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("But one thing's for sure:"), SAY_THINK, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Hogera is definitely the last planet I saved!"), SAY_THINK, 4000}})
	table.insert(dialog01, {func = win, args = {hero.gear}})
end


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
							loc("Red areas are indestructible").."|"..
							loc("Green areas are portal-proof")
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
	color = tonumber("38D61C",16) -- green
}

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	GameFlags = gfDisableWind + gfOneClanMode
	Seed = 1
	TurnTime = -1
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	HealthCaseAmount = 35
	Map = "final_map"
	Theme = "EarthRise"

	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 1, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)

	initCheckpoint("final")

	AnimInit()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	ShowMission(missionName, loc("Challenge objectives"), challengeObjectives, -amSkip, 0)

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
	SpawnAmmoCrate(930, 1000,amRCPlane)
	SpawnAmmoCrate(1220, 672,amPickHammer)
	SpawnAmmoCrate(1220, 672,amGirder)

	-- ammo
	AddAmmo(hero.gear, amPortalGun, 1)
	AddAmmo(hero.gear, amFirePunch, 1)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)
	AddEvent(onHeroWin, {hero.gear}, heroWin, {hero.gear}, 0)

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

function onHeroWin(gear)
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
	SendStat(siGameResult, loc("Hog Solo lost, try again!"))
	SendStat(siCustomAchievement, loc("You have to destroy all the explosives without dying!"))
	SendStat(siCustomAchievement, loc("Red areas are indestructible."))
	SendStat(siCustomAchievement, loc("Green areas are portal-proof and repel portals."))
	SendStat(siPlayerKills,'0',teamA.name)
	EndGame()
end

function heroWin(gear)
	saveCompletedStatus(7)
	SendStat(siGameResult, loc("Congratulations, you have saved Hogera!"))
	SendStat(siCustomAchievement, loc("Hogera is safe!"))
	SendStat(siPlayerKills,'1',teamA.name)
	EndGame()
end

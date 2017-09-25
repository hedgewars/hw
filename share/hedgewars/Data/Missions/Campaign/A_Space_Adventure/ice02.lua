------------------- ABOUT ----------------------
--
-- Hero has to pass as fast as possible inside the
-- rings as in the racer mode

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Missions/Campaign/A_Space_Adventure/global_functions.lua")

----------------- VARIABLES --------------------
-- globals
local missionName = loc("Hard flying")
local challengeStarted = false
local currentWaypoint = 1
local radius = 75
local totalTime = 15000
local totalSaucers = 3
local gameEnded = false
local RED = 0xff0000ff
local GREEN = 0x38d61cff
local challengeObjectives = loc("To win the game you have to pass into the rings in time.")..
	"|"..loc("You'll get extra time in case you need it when you pass a ring.").."|"..
	loc("Every 2 rings, the ring color will be green and you'll get an extra flying saucer.").."|"..
	loc("Use the attack key twice to change the flying saucer while floating in mid-air.")
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), challengeObjectives, 1, 4500},
}
-- hogs
local hero = {}
local ally = {}
-- teams
local teamA = {}
local teamB = {}
-- hedgehogs values
hero.name = loc("Hog Solo")
hero.x = 750
hero.y = 130
hero.dead = false
ally.name = loc("Paul McHoggy")
ally.x = 860
ally.y = 130
teamA.name = loc("Hog Solo")
teamA.color = tonumber("38D61C",16) -- green
teamB.name = loc("Allies")
teamB.color = tonumber("FF0000",16) -- red
-- way points
local current waypoint = 1
local waypoints = {
	[1] = {x=1450, y=140},
	[2] = {x=990, y=580},
	[3] = {x=1650, y=950},
	[4] = {x=620, y=630},
	[5] = {x=1470, y=540},
	[6] = {x=1960, y=60},
	[7] = {x=1600, y=400},
	[8] = {x=240, y=940},
	[9] = {x=200, y=530},
	[10] = {x=1180, y=120},
	[11] = {x=1950, y=660},
	[12] = {x=1280, y=980},
	[13] = {x=590, y=1100},
	[14] = {x=20, y=620},
	[15] = {x=hero.x, y=hero.y}
}

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	GameFlags = gfInvulnerable
	Seed = 1
	TurnTime = 15000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Map = "ice02_map"
	Theme = "Snow"
	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0

	-- Hog Solo
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "hedgewars")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	-- Ally
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_face")
	ally.gear = AddHog(ally.name, 0, 100, "war_airwarden02")
	AnimSetGearPosition(ally.gear, ally.x, ally.y)
	HogTurnLeft(ally.gear, true)

	initCheckpoint("ice02")

	AnimInit(true)
	AnimationSetup()
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	ShowMission(missionName, loc("Challenge objectives"), challengeObjectives, -amSkip, 0)

	AddEvent(onHeroDeath, {hero.gear}, heroDeath, {hero.gear}, 0)

	AddAmmo(hero.gear, amJetpack, 3)

	-- place a waypoint
	placeNextWaypoint()

	SendHealthStatsOff()
	AddAnim(dialog01)
end

function onNewTurn()
	if not hero.dead and CurrentHedgehog == ally.gear and challengeStarted then
		heroLost()
	elseif not hero.dead and CurrentHedgehog == hero.gear and challengeStarted then
		SetWeapon(amJetpack)
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

function onGameTick20()
	if checkIfHeroInWaypoint() then
		if not gameEnded and not placeNextWaypoint() then
			gameEnded = true
			-- GAME OVER, WIN!
			totalTime = totalTime - TurnTimeLeft
			local totalTimePrinted  = totalTime / 1000
			local saucersLeft = GetAmmoCount(hero.gear, amJetpack)
			local saucersUsed = totalSaucers - saucersLeft
			SendStat(siGameResult, loc("Hooray! You are a champion!"))
			SendStat(siCustomAchievement, string.format(loc("You completed the mission in %.3f seconds."), totalTimePrinted))
			local record = tonumber(GetCampaignVar("IceStadiumBestTime"))
			if record ~= nil and totalTime >= record then
				SendStat(siCustomAchievement, string.format(loc("Your personal best time so far: %.3f seconds"), record/1000))
			end
			if record == nil or totalTime < record then
				SaveCampaignVar("IceStadiumBestTime", tostring(totalTime))
				if record ~= nil then
					SendStat(siCustomAchievement, loc("This is a new personal best time, congratulations!"))
				end
			end
			SendStat(siCustomAchievement, string.format(loc("You have used %d flying saucers."), saucersUsed))
			SendStat(siCustomAchievement, string.format(loc("You had %d additional flying saucers left."), saucersLeft))

			record = tonumber(GetCampaignVar("IceStadiumLeastSaucersUsed"))
			if record == nil or saucersUsed < record then
				SaveCampaignVar("IceStadiumLeastSaucersUsed", tostring(saucersUsed))
			end

			SendStat(siPlayerKills,'0',teamA.name)
			SaveCampaignVar("Mission6Won", "true")
			checkAllMissionsCompleted()
			EndGame()
		end
	end
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
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

-------------- ACTIONS ------------------

function heroDeath(gear)
	heroLost()
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
    startFlying()
end

function AnimationSetup()
	-- DIALOG 01 - Start, some story telling
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("In the Ice Planet Flying Saucer Stadium ..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("This is the Olympic stadium of saucer flying."), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("All the saucer pilots dream to come here one day in order to compete with the best!"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Now you have the chance to try and claim the place that you deserve among the best."), SAY_SAY, 6000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Use the saucer and pass through the rings."), 5000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("Pause the game by pressing the pause key (default \"P\") for more details"), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Can you do it?"), SAY_SAY, 2000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = startFlying, args = {hero.gear}})
end

------------------ Other Functions -------------------

function startFlying()
	AnimSwitchHog(ally.gear)
	EndTurn(true)
	challengeStarted = true
end

function placeNextWaypoint()
	if currentWaypoint > 1 then
		local wp = waypoints[currentWaypoint-1]
		DeleteVisualGear(wp.gear)
	end
	if currentWaypoint < 16 then
		local wp = waypoints[currentWaypoint]
		wp.gear = AddVisualGear(1,1,vgtCircle,1,true)
		-- add bonus time and "fuel"
		if currentWaypoint % 2 == 0 then
			PlaySound(sndShotgunReload)
			SetVisualGearValues(wp.gear, wp.x,wp.y, 20, 200, 0, 0, 100, radius, 3, RED)
			AddAmmo(hero.gear, amJetpack, GetAmmoCount(hero.gear, amJetpack)+1)
			totalSaucers = totalSaucers + 1
			local vgear = AddVisualGear(GetX(hero.gear), GetY(hero.gear), vgtAmmo, 0, true)
			if vgear ~= nil then
				SetVisualGearValues(vgear,nil,nil,nil,nil,nil,amJetpack)
			end
			local message 
			if TurnTimeLeft <= 22000 then
				TurnTimeLeft = TurnTimeLeft + 8000
				totalTime = totalTime + 8000
				PlaySound(sndExtraTime)
				message = loc("Got 1 more saucer and 8 more seconds added to the clock")
			else
				message = loc("Got 1 more saucer")
			end
			AnimCaption(hero.gear, message, 4000)
		else
			SetVisualGearValues(wp.gear, wp.x,wp.y, 20, 200, 0, 0, 100, radius, 3, GREEN)
			if TurnTimeLeft <= 16000 then
				TurnTimeLeft = TurnTimeLeft + 6000
				totalTime = totalTime + 6000
				if currentWaypoint ~= 1 then
					PlaySound(sndExtraTime)
					AnimCaption(hero.gear, loc("6 more seconds added to the clock"), 4000)
				end
			end
		end
		radius = radius - 4
		currentWaypoint = currentWaypoint + 1
		return true
	else
		AnimCaption(hero.gear, loc("Congratulations, you won!"), 4000)
		PlaySound(sndVictory, hero.gear)
	end
	return false
end

function checkIfHeroInWaypoint()
	if not hero.dead then
		local wp = waypoints[currentWaypoint-1]
		if gearIsInCircle(hero.gear, wp.x, wp.y, radius+4, false) then
			SetWind(GetRandom(201)-100)
			return true
		end
	end
	return false
end

function heroLost()
	SendStat(siGameResult, loc("Oh man! Learn how to fly!"))
	SendStat(siCustomAchievement, loc("To win the game you have to pass into the rings in time."))
	SendStat(siCustomAchievement, loc("You'll get extra time in case you need it when you pass a ring."))
	SendStat(siCustomAchievement, loc("Every 2 rings you'll get extra flying saucers."))
	SendStat(siCustomAchievement, loc("Use the attack key twice to change the flying saucer while being in air."))
	SendStat(siPlayerKills,'0',teamA.name)
	EndGame()
end

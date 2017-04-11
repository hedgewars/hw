HedgewarsScriptLoad("/Scripts/Locale.lua")

local playerHog
local playerTeamName = loc("Pro Killers")
local enemyTeamName = loc("Galaxy Guardians")
local enemyTeam1 = {
	{name=loc("Rocket"), x=796, y=1184},
	{name=loc("Star"), x=733, y=1525},
	{name=loc("Asteroid"), x=738, y=1855},
	{name=loc("Comet"), x=937, y=1318},
	{name=loc("Sunflame"), x=3424, y=1536},
	{name=loc("Eclipse"), x=3417, y=1081},
	{name=loc("Jetpack"), x=2256, y=1246},
	{name=loc("Void"), x=1587, y=1231},
}
local gameStarted = false
local turnNo = 0
local toleranceTimer = nil
local enemyHogsLeft = #enemyTeam1
local pendingDeaths = {}
local enemyHogs = {}
local gameEnded = false
local waitGears = 0
local hasAttacked = false
local minePlaced = false
local delayGear = nil

function onGameInit()
	Seed = "{7e34a56b-ee7b-4fe1-8f30-352a998f3f6a}"
	GameFlags = gfDisableWind + gfDisableLandObjects
	TurnTime= 45000
	CaseFreq = 0 
	MinesNum = 0 
	Explosives = 0 
	Theme = "EarthRise" 
	MapGen = mgRandom
	MapFeatureSize = 12
	-- Disable Sudden Death
	WaterRise = 0
	HealthDecrease = 0
	
	AddTeam(playerTeamName, 0xFF0000, "Bone", "Island", "Classic", "cm_scout")
	playerHog = AddHog(loc("Ultrasoldier"), 0, 100, "Terminator_Glasses")
	SetGearPosition(playerHog, 543, 1167)

	AddTeam(enemyTeamName, 0xF5F808, "Earth", "Island", "Classic", "cm_galaxy")
	for i=1,8 do
		local hogID = AddHog(enemyTeam1[i].name, 0, 100, "NoHat")
		table.insert(enemyHogs, hogID)
		SetGearPosition(hogID, enemyTeam1[i].x, enemyTeam1[i].y)
	end
end

function onAmmoStoreInit()

	SetAmmo(amGrenade, 9, 0, 0, 1)
	SetAmmo(amClusterBomb, 9, 0, 0, 1)
	SetAmmo(amBazooka, 9, 0, 0, 1)
	SetAmmo(amBee, 9, 0, 0, 1)
	SetAmmo(amShotgun, 9, 0, 0, 1)
	SetAmmo(amPickHammer, 9, 0, 0, 1)
	SetAmmo(amSkip, 9, 0, 0, 1)
	SetAmmo(amRope, 9, 0, 0, 1)
	SetAmmo(amMine, 9, 0, 0, 1)
	SetAmmo(amDEagle, 9, 0, 0, 1)
	SetAmmo(amDynamite, 9, 0, 0, 1)
	SetAmmo(amFirePunch, 9, 0, 0, 1)
	SetAmmo(amWhip, 9, 0, 0, 1)
	SetAmmo(amBaseballBat, 9, 0, 0, 1)
	SetAmmo(amParachute, 9, 0, 0, 1)
	SetAmmo(amAirAttack, 9, 0, 0, 1)
	SetAmmo(amMineStrike, 9, 0, 0, 1)
	SetAmmo(amBlowTorch, 9, 0, 0, 1)
	SetAmmo(amGirder, 9, 0, 0, 1)
	SetAmmo(amTeleport, 9, 0, 0, 1)
	SetAmmo(amSwitch, 9, 0, 0, 1)
	SetAmmo(amMortar, 9, 0, 0, 1)
	SetAmmo(amKamikaze, 9, 0, 0, 1)
	SetAmmo(amCake, 9, 0, 0, 1)
	SetAmmo(amSeduction, 9, 0, 0, 1)
	SetAmmo(amWatermelon, 9, 0, 0, 1)
	SetAmmo(amHellishBomb, 9, 0, 0, 1)
	SetAmmo(amNapalm, 9, 0, 0, 1)
	SetAmmo(amDrill, 9, 0, 0, 1)
	SetAmmo(amBallgun, 9, 0, 0, 1)
	SetAmmo(amRCPlane, 9, 0, 0, 1)
	SetAmmo(amLowGravity, 9, 0, 0, 1)
	SetAmmo(amExtraDamage, 9, 0, 0, 1)
	SetAmmo(amInvulnerable, 9, 0, 0, 1)
	SetAmmo(amLaserSight, 9, 0, 0, 1)
	SetAmmo(amVampiric, 9, 0, 0, 1)
	SetAmmo(amSniperRifle, 9, 0, 0, 1)
	SetAmmo(amJetpack, 9, 0, 0, 1)
	SetAmmo(amMolotov, 9, 0, 0, 1)
	SetAmmo(amBirdy, 9, 0, 0, 1)
	SetAmmo(amPortalGun, 9, 0, 0, 1)
	SetAmmo(amPiano, 9, 0, 0, 1)
	SetAmmo(amGasBomb, 9, 0, 0, 1)
	SetAmmo(amSineGun, 9, 0, 0, 1)
	SetAmmo(amFlamethrower, 9, 0, 0, 1)
	SetAmmo(amSMine, 9, 0, 0, 1)
	SetAmmo(amHammer, 9, 0, 0, 1)
	SetAmmo(amResurrector, 9, 0, 0, 1)
	SetAmmo(amDrillStrike, 9, 0, 0, 1)
	SetAmmo(amSnowball, 9, 0, 0, 1)
	SetAmmo(amTardis, 9, 0, 0, 1)
	SetAmmo(amLandGun, 9, 0, 0, 1)
	SetAmmo(amIceGun, 9, 0, 0, 1)
	SetAmmo(amKnife, 9, 0, 0, 1)
	SetAmmo(amRubber, 9, 0, 0, 1)
	SetAmmo(amAirMine, 9, 0, 0, 1)
	SetAmmo(amDuck, 9, 0, 0, 1)

	SetAmmo(amExtraTime, 2, 0, 0, 0)

end

function onGameStart()
	SendHealthStatsOff()
	ShowMission(loc("Big Armory"), loc("Scenario"), loc("Kill all enemy hedgehogs in a single turn."), -amBazooka, 0) 
	SetWind(15)
end

function onGameTick20()
	if not gameStarted and turnNo == 1 and TurnTimeLeft < TurnTime then
		gameStarted = true
	elseif gameStarted and not gameEnded then
		if isPlayerAlive() then
			if enemyHogsLeft - countPending() <= 0 then
				TurnTimeLeft = 0
				if delayGear then
					DeleteGear(delayGear)
				end
				return
			elseif (enemyHogsLeft > 0) and TurnTimeLeft < 40 then
				if not toleranceTimer and waitGears <= 0 then
					SetInputMask(0)
					SetGearMessage(playerHog, 0)
					if not minePlaced then
						TurnTimeLeft = 10000000
					end
					if hasAttacked then
						if minePlaced then
							toleranceTimer = 12000
						else
							toleranceTimer = 7500
						end
					else
						PlaySound(sndBoring, playerHog)
						toleranceTimer = 5020
					end
					return
				end
			end
			if toleranceTimer ~= nil then
				if toleranceTimer % 1000 == 0 and toleranceTimer > 0 and toleranceTimer <= 5000 then
					AddCaption(string.format(loc("Mission failure in %d s"), div(toleranceTimer, 1000)), 0xFFFFFFFF, capgrpGameState)
				end
				if toleranceTimer == 4000 then
					PlaySound(sndCountdown4)
				elseif toleranceTimer == 3000 then
					PlaySound(sndCountdown3)
				elseif toleranceTimer == 2000 then
					PlaySound(sndCountdown2)
				elseif toleranceTimer == 1000 then
					PlaySound(sndCountdown1)
				end
				if waitGears <= 0 then
					if toleranceTimer <= 0 then
						lose()
						return
					end
					toleranceTimer = toleranceTimer - 20
				end
				return
			end
		end
	end
end

function onGearAdd(gear)
	local gt = GetGearType(gear)
	if gt == gtIceGun or gt == gtPickHammer or gt == gtSineGunShot or gt == gtCake
	or gt == gtTeleport or gt == gtFlamethrower or gt == gtBallGun or gt == gtSeduction
	or gt == gtAirAttack or gt == gtMine or gt == gtSMine or gt == gtAirMine
	or (isWaitGear(gear) and gt ~= gtFlame) then
		--[[ This is a hack to prevent the turn from instantly ending
		after using a weapon with a retreat time of 0. For some reason, there would be
		are also problems with the hellish-hand grenade without this hack.
		It spawns an invisible grenade with disabled gravity at (0,0) with a
		high timer, which will delay the end of the turn. ]]
		if delayGear == nil then
			delayGear = AddGear(0, 0, gtGrenade, gstNoGravity + gstInvisible, 0, 0, 2147483647)
		end
	end
	if gt == gtMine or gt == gtSMine or gt == gtAirMine then
		minePlaced = true
	end
	if isWaitGear(gear) then
		waitGears = waitGears + 1
	end
	if gt == gtAirAttack then
		hasAttacked = true
	end
end

function onGearDelete(gear)
	if isWaitGear(gear) then
		waitGears = waitGears - 1
	end
	if GetGearType(gear) == gtHedgehog then
		if GetHogTeamName(gear) == enemyTeamName then
			enemyHogsLeft = enemyHogsLeft - 1
			pendingDeaths[gear] = nil
			if enemyHogsLeft <= 0 then
				win()
			end
		end
	end
end

function countPending()
	local p = 0
	for h, v in pairs(pendingDeaths) do
		if v then
			p = p + 1
		end
	end
	return p
end

function isPlayerAlive()
	if GetGearType(playerHog) == gtHedgehog then
		if GetHealth(playerHog) == 0 then
			return false
		else
			local _, gearDamage
			_, _, _, _, _, _, _, _, _, _, _, gearDamage = GetGearValues(playerHog)
			return (GetHealth(playerHog) - gearDamage) > 0
		end
	else
		return false
	end
end

function onGearDamage(gear, damage)
	if GetGearType(gear) == gtHedgehog then
		if GetHogTeamName(gear) == enemyTeamName then
			local _, gearDamage
			_, _, _, _, _, _, _, _, _, _, _, gearDamage = GetGearValues(gear)
			if (GetHealth(gear) - gearDamage) <= 0 then
				pendingDeaths[gear] = true
			end
		end
	end
end

function isWaitGear(gear)
	local gt = GetGearType(gear)
	return gt == gtBall or gt == gtHellishBomb or gt == gtWatermelon or gt == gtMelonPiece
		or (gt == gtFlame and band(GetState(gear), gsttmpFlag) == 0)
		or gt == gtDrill or gt == gtAirAttack or gt == gtAirBomb or gt == gtCluster
		or gt == gtEgg or gt == gtHammerHit or gt == gtNapalmBomb or gt == gtPoisonCloud
		or gt == gtGasBomb
end

function onNewTurn()
	turnNo = turnNo + 1
	if turnNo > 1 then
		PlaySound(sndBoring, playerHog)
		lose()
	end
end

function onHogAttack(ammoType)
	-- Set hasAttacked if hog attacked NOT with a non-turn ending weapon
	if ammoType ~= amNothing and ammoType ~= amSkip and ammoType ~= amJetpack and ammoType ~= amGirder and ammoType ~= amRubber
		and ammoType ~= amLandGun and ammoType ~= amParachute and ammoType ~= amResurrector and ammoType ~= amRope and ammoType ~= amSwitcher
		and ammoType ~= amExtraDamage and ammoType ~= amExtraTime and ammoType ~= amLowGravity and ammoType ~= amInvulnerable
		and ammoType ~= amLaserSight and ammoType ~= amVampiric and ammoType ~= amPortalGun and ammoType ~= amSnowball then
		hasAttacked = true
	end
	if ammoType == amSkip and enemyHogsLeft > 0 then
		PlaySound(sndCoward, playerHog)
		lose()
		return
	end
end

function lose()
	if not gameEnded then
		PlaySound(sndStupid, playerHog)
		local mission, achievement
		mission = loc("You failed to kill all enemies in this turn.")
		achievement = loc("You failed to kill all enemies in a single turn.")
		AddCaption(loc("Mission failed!"), 0xFFFFFFFF, capgrpGameState)
		ShowMission(loc("Big Armory"), loc("Scenario"), mission, -amBazooka, 5000) 
		SendStat(siGameResult, loc("You lose!"))
		SendStat(siCustomAchievement, achievement)
		SendStat(siPlayerKills, tostring(0), enemyTeamName)
		SendStat(siPlayerKills, tostring(8-enemyHogsLeft), playerTeamName)
		gameEnded = true
		EndGame()
	end
end

function win()
	if not gameEnded then
		AddCaption(loc("Victory!"), 0xFFFFFFFF, capgrpGameState)
		ShowMission(loc("Big Armory"), loc("Scenario"), loc("Congratulations! You win."), 4, 5000) 
		PlaySound(sndVictory, playerHog)
		SendStat(siGameResult, loc("You win!"))
		SendStat(siCustomAchievement, loc("You have killed all enemies."))
		SendStat(siPlayerKills, tostring(8-enemyHogsLeft), playerTeamName)
		SendStat(siPlayerKills, tostring(0), enemyTeamName)
		gameEnded = true
		EndGame()
	end
end

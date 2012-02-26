----------------------------------
-- THE SPECIALISTS MODE 0.7
-- by mikade
----------------------------------

-- version history
-----------------
-- version 0.1
-----------------
-- concept test

----------------
-- version 0.2
----------------
-- added gfRandomOrder to gameflags
-- removed some deprecated variables/methods
-- fixed lack of portal reset

----------------
-- version 0.3
----------------
-- added switching on start
-- removed switch from engineer weaponset

----------------
-- version 0.4
----------------
-- Attempted to:
-- fix potential switch explit
-- improve user feedback on start

----------------
-- version 0.5
----------------
-- provision for variable minetimer / demo mines set to 5000ms
-- don't autoswitch if player only has 1 hog on his team

----------------
-- version 0.6
----------------
-- for the meanwhile, don't drop any crates except health crates

----------------
-- version 0.7
----------------
-- perhogadmsdf :D :D :D :D

--------------------
--TO DO
--------------------

-- balance hog health, maybe
-- add proper gameflag checking, maybe (so that we can throw in a .cfg and let the users break everything)

loadfile(GetDataPath() .. "Scripts/Locale.lua")()
loadfile(GetDataPath() .. "Scripts/Tracker.lua")()

local numhhs = 0
local hhs = {}

local currName
local lastName
local started = false
local switchStage = 0

local hogCounter

function CountHog(gear)
	hogCounter = hogCounter +1
end

function onNewAmmoStore(groupIndex, hogIndex)

	SetAmmo(amSkip, 9, 0, 0, 0)

	if hogIndex == 0 then
		SetAmmo(amBazooka, 1, 0, 0, 0)
		SetAmmo(amGrenade, 1, 0, 0, 0)
		SetAmmo(amShotgun, 1, 0, 0, 0)
	elseif hogIndex == 1 then
		SetAmmo(amGirder, 2, 0, 0, 0)
		SetAmmo(amBlowTorch, 1, 0, 0, 0)
		SetAmmo(amPickHammer, 1, 0, 0, 0)
	elseif hogIndex == 2 then
		SetAmmo(amRope, 9, 0, 0, 0)
		SetAmmo(amParachute, 9, 0, 0, 0)
		SetAmmo(amFirePunch, 1, 0, 0, 0)
	elseif hogIndex == 3 then
		SetAmmo(amDynamite, 1, 0, 0, 0)
		SetAmmo(amMine, 1, 0, 0, 0)
		SetAmmo(amDrill, 1, 0, 0, 0)
	elseif hogIndex == 4 then
		SetAmmo(amSniperRifle, 1, 0, 0, 0)
		SetAmmo(amDEagle, 1, 0, 0, 0)
		SetAmmo(amPortalGun, 2, 0, 0, 0)
	elseif hogIndex == 5 then
		SetAmmo(amSeduction, 9, 0, 0, 0)
		SetAmmo(amResurrector, 1, 0, 0, 0)
		SetAmmo(amInvulnerable, 1, 0, 0, 0)
	elseif hogIndex == 6 then
		SetAmmo(amFlamethrower, 1, 0, 0, 0)
		SetAmmo(amMolotov, 1, 0, 0, 0)
		SetAmmo(amNapalm, 1, 0, 0, 0)
	elseif hogIndex == 7 then
		SetAmmo(amBaseballBat, 1, 0, 0, 0)
		SetAmmo(amGasBomb, 1, 0, 0, 0)
		SetAmmo(amKamikaze, 1, 0, 0, 0)
	end

end

function CreateTeam()

	currTeam = ""
	lastTeam = ""
	z = 0

	for i = 0, (numhhs-1) do

			currTeam = GetHogTeamName(hhs[i])

			if currTeam == lastTeam then
					z = z + 1
			else
					z = 1
			end

			if z == 1 then

					SetHogName(hhs[i],"Soldier")
					SetHogHat(hhs[i], "sf_vega")
					SetHealth(hhs[i],200)

			elseif z == 2 then

					SetHogHat(hhs[i], "Glasses")
					SetHogName(hhs[i],"Engineer")

			elseif z == 3 then

					SetHogName(hhs[i],"Ninja")
					SetHogHat(hhs[i], "NinjaFull")
					SetHealth(hhs[i],80)

			elseif z == 4 then

					SetHogName(hhs[i],"Demo")
					SetHogHat(hhs[i], "Skull")
					SetHealth(hhs[i],200)

			elseif z == 5 then

					SetHogName(hhs[i],"Sniper")
					SetHogHat(hhs[i], "Sniper")
					SetHealth(hhs[i],120)

			elseif z == 6 then

					SetHogName(hhs[i],"Saint")
					SetHogHat(hhs[i], "angel")
					SetHealth(hhs[i],300)

			elseif z == 7 then

					SetHogName(hhs[i],"Pyro")
					SetHogHat(hhs[i], "Gasmask")
					SetHealth(hhs[i],150)

			elseif z == 8 then

					SetHogName(hhs[i],"Loon")
					SetHogHat(hhs[i], "clown")
					SetHealth(hhs[i],100)

			end

			lastTeam = GetHogTeamName(hhs[i])

	end

end

function onGameInit()
	GameFlags = gfRandomOrder + gfResetWeps + gfInfAttack + gfPlaceHog +gfPerHogAmmo
	Delay = 10
	HealthCaseProb = 100
end

function onGameStart()

	CreateTeam()

	ShowMission     (
                                loc("THE SPECIALISTS"),
                                loc("a Hedgewars mini-game"),

                                loc("Eliminate the enemy specialists.") .. "|" ..
                                " " .. "|" ..

                                loc("Game Modifiers: ") .. "|" ..
                                loc("Per-Hog Ammo") .. "|" ..
                                loc("Weapons Reset") .. "|" ..
                                loc("Unlimited Attacks") .. "|" ..

                                "", 4, 4000
                                )

	trackTeams()

end


function onNewTurn()
	currName = GetHogName(CurrentHedgehog)
	lastName = GetHogName(CurrentHedgehog)
	started = true
	switchStage = 0
end

function onGameTick()

	if (CurrentHedgehog ~= nil) then

		currName = GetHogName(CurrentHedgehog)

		if (currName ~= lastName) and (switchStage > 100) then
			AddCaption(loc("Switched to ") .. currName .. "!")
		end

		if (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) and (switchStage < 100) then

			AddCaption(loc("Prepare yourself") .. ", " .. currName .. "!")

			hogCounter = 0
			runOnHogsInTeam(CountHog, GetHogTeamName(CurrentHedgehog) )

			if hogCounter > 1 then

				switchStage = switchStage + 1

				if switchStage == 1 then
					AddAmmo(CurrentHedgehog, amSwitch, 1)

				elseif switchStage == 2 then
					ParseCommand("setweap " .. string.char(amSwitch))
				elseif switchStage == 3 then
					SetGearMessage(CurrentHedgehog,gmAttack)
				elseif switchStage == 4 then
					switchStage = 110
					AddAmmo(CurrentHedgehog, amSwitch, 0)
				end

			else
				switchStage = 110
			end


		end

		lastName = currName

	end

end

function onGearAdd(gear)

    if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		numhhs = numhhs + 1
	elseif (GetGearType(gear) == gtMine) and (started == true) then
		SetTimer(gear,5000)
	end

	if (GetGearType(gear) == gtHedgehog) or (GetGearType(gear) == gtResurrector) then
		trackGear(gear)
	end


end

function onGearDelete(gear)
	if (GetGearType(gear) == gtHedgehog) or (GetGearType(gear) == gtResurrector) then
		trackDeletion(gear)
	end
end

function onAmmoStoreInit()
--
end


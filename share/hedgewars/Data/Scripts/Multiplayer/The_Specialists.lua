----------------------------------
-- THE SPECIALISTS
-- original style by mikade
----------------------------------

-- SCRIPT PARAMETER SYNTAX
--[[
With the script parameter, you can change the order of specialists per team.

Valid keys: t1, t2, ... t8
  One per team (team 1, team 2, ... team 8)

The value is a sequence of “specialist letters”.
Each letter stands for a hedgehog.

Specialist letters:

  S = Soldier
  E = Engineer
  N = Ninja
  D = Demo
  I = Sniper
  A = Saint
  P = Pyro
  L = Loon

Example 1:

    t1=SENDIAPL,t2=SENDIAPL

Team 1 and team 2 have the standard specialists.

Example 2:

    t1=SSSSPPPP

4 soldiers and 4 pyros for team 1.


]]

--------------------
-- TODO
--------------------
-- add proper gameflag checking, maybe (so that we can throw in a .cfg and let the users break everything)


HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

-- default team values
local currTeamIdx = 0;
local teamRoles = {
	{'S','E','N','D','I','A','P','L'},
	{'S','E','N','D','I','A','P','L'},
	{'S','E','N','D','I','A','P','L'},
	{'S','E','N','D','I','A','P','L'},
	{'S','E','N','D','I','A','P','L'},
	{'S','E','N','D','I','A','P','L'},
	{'S','E','N','D','I','A','P','L'},
	{'S','E','N','D','I','A','P','L'}
};

local numhhs = 0
local hhs = {}

local started = false

function onParameters()
	parseParams()
	for i = 1, 8 do
		if params['t'..i] ~= nil then
			for j = 1, 8 do
				if string.len(params['t'..i]) >= j  then
					teamRoles[i][j] = string.upper(string.sub(params['t'..i],j,j));
				end
			end
		end
	end
end

function onNewAmmoStore(groupIndex, hogIndex)

	SetAmmo(amSkip, 9, 0, 0, 0)
	groupIndex = groupIndex + 1
	hogIndex = hogIndex + 1

	if teamRoles[groupIndex][hogIndex] == 'S' then
		SetAmmo(amBazooka, 1, 0, 0, 0)
		SetAmmo(amGrenade, 1, 0, 0, 0)
		SetAmmo(amShotgun, 1, 0, 0, 0)
	elseif teamRoles[groupIndex][hogIndex] == 'E' then
		SetAmmo(amGirder, 2, 0, 0, 0)
		SetAmmo(amBlowTorch, 1, 0, 0, 0)
		SetAmmo(amPickHammer, 1, 0, 0, 0)
	elseif teamRoles[groupIndex][hogIndex] == 'N' then
		SetAmmo(amRope, 9, 0, 0, 0)
		SetAmmo(amParachute, 9, 0, 0, 0)
		SetAmmo(amFirePunch, 1, 0, 0, 0)
	elseif teamRoles[groupIndex][hogIndex] == 'D' then
		SetAmmo(amDynamite, 1, 0, 0, 0)
		SetAmmo(amMine, 1, 0, 0, 0)
		SetAmmo(amDrill, 1, 0, 0, 0)
	elseif teamRoles[groupIndex][hogIndex] == 'I' then
		SetAmmo(amSniperRifle, 1, 0, 0, 0)
		SetAmmo(amDEagle, 1, 0, 0, 0)
		SetAmmo(amPortalGun, 2, 0, 0, 0)
	elseif teamRoles[groupIndex][hogIndex] == 'A' then
		SetAmmo(amSeduction, 9, 0, 0, 0)
		SetAmmo(amResurrector, 1, 0, 0, 0)
		SetAmmo(amInvulnerable, 1, 0, 0, 0)
		SetAmmo(amLowGravity, 1, 0, 0, 0)
	elseif teamRoles[groupIndex][hogIndex] == 'P' then
		SetAmmo(amFlamethrower, 1, 0, 0, 0)
		SetAmmo(amMolotov, 1, 0, 0, 0)
		SetAmmo(amNapalm, 1, 0, 0, 0)
	elseif teamRoles[groupIndex][hogIndex] == 'L' then
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
			currTeamIdx = currTeamIdx + 1;
		end

		if teamRoles[currTeamIdx][z] == 'S' then

			SetHogName(hhs[i],loc("Soldier"))
			SetHogHat(hhs[i], "sf_vega")
			SetHealth(hhs[i],200)

		elseif teamRoles[currTeamIdx][z] == 'E' then

			SetHogHat(hhs[i], "Glasses")
			SetHogName(hhs[i],loc("Engineer"))

		elseif teamRoles[currTeamIdx][z] == 'N' then

			SetHogName(hhs[i],loc("Ninja"))
			SetHogHat(hhs[i], "NinjaFull")
			SetHealth(hhs[i],80)

		elseif teamRoles[currTeamIdx][z] == 'D' then

			SetHogName(hhs[i],loc("Demo"))
			SetHogHat(hhs[i], "Skull")
			SetHealth(hhs[i],200)

		elseif teamRoles[currTeamIdx][z] == 'I' then

			SetHogName(hhs[i],loc("Sniper"))
			SetHogHat(hhs[i], "Sniper")
			SetHealth(hhs[i],120)

		elseif teamRoles[currTeamIdx][z] == 'A' then

			SetHogName(hhs[i],loc("Saint"))
			SetHogHat(hhs[i], "angel")
			SetHealth(hhs[i],300)

		elseif teamRoles[currTeamIdx][z] == 'P' then

			SetHogName(hhs[i],loc("Pyro"))
			SetHogHat(hhs[i], "Gasmask")
			SetHealth(hhs[i],150)

		elseif teamRoles[currTeamIdx][z] == 'L' then

			SetHogName(hhs[i],loc("Loon"))
			SetHogHat(hhs[i], "clown")
			SetHealth(hhs[i],100)

		end

		lastTeam = GetHogTeamName(hhs[i])

	end

end

function onGameInit()
	ClearGameFlags()
	EnableGameFlags(gfResetWeps, gfInfAttack, gfPlaceHog, gfPerHogAmmo, gfSwitchHog)
	HealthCaseProb = 100
end

function onGameStart()

	CreateTeam()

	ShowMission(
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

	started = true
	AddCaption(loc("Prepare yourself") .. ", " .. GetHogName(CurrentHedgehog).. "!")

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


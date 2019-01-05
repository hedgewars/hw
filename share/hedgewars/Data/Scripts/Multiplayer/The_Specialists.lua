----------------------------------
-- THE SPECIALISTS
-- original style by mikade
----------------------------------

-- SCRIPT PARAMETER SYNTAX
--[[
With the script parameter, you can change the order of specialists per team.

== Changing the specialists for all teams ==
In the script parameter, put:

    t=XXXXXXXX

Where 'X' is a “specialist letter” (see below). Each letter stands for
the role of a hedgehog in the team (in that order).
If you leave out a letter, that hedgehog will be the default.

== Changing the specialists for on a per-team basis ==
Same as above, but instead of “t”, you use “t1”, “t2”, ... “t8” for
each of the teams (team 1 to team 8).

== Specialist letters ==

  S = Soldier
  E = Engineer
  N = Ninja
  D = Demo
  I = Sniper
  A = Saint
  P = Pyro
  L = Loon

== Examples ==
Example 1:

    t=SSSSPPPP

4 soldiers and 4 pyros for all teams.

Example 2:

    t1=LPAIDNES,t2=NNNNNNNN

Team 1: Loon, Pyro, Saint, Sniper, Demo, Ninja, Engineer, Soldier.
Team 2: All-ninja team.
All other teams use the default settings.

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
	-- All teams
	if params['t'] ~= nil then
		for i = 1, 8 do
			for j = 1, 8 do
				if string.len(params['t']) >= j  then
					teamRoles[i][j] = string.upper(string.sub(params['t'],j,j));
				end
			end
		end
	end
	-- Specific team
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

		-- Scale health of each hog with “initial health” setting from game scheme.
		-- 100 = default health
		-- 200 = double health for all hogs
		-- 50 = half health for all hogs
		local function scaleHealth(health)
			local newHealth = div(health * InitHealth, 100)
			-- At least 1 health
			if newHealth <= 0 then
				newHealth = 1
			end
			return newHealth
		end

		if teamRoles[currTeamIdx][z] == 'S' then

			SetHogName(hhs[i],loc("Soldier"))
			SetHogHat(hhs[i], "sf_vega")
			SetHealth(hhs[i], scaleHealth(200))

		elseif teamRoles[currTeamIdx][z] == 'E' then

			SetHogHat(hhs[i], "Glasses")
			SetHogName(hhs[i],loc("Engineer"))
			SetHealth(hhs[i], scaleHealth(100))

		elseif teamRoles[currTeamIdx][z] == 'N' then

			SetHogName(hhs[i],loc("Ninja"))
			SetHogHat(hhs[i], "NinjaFull")
			SetHealth(hhs[i], scaleHealth(80))

		elseif teamRoles[currTeamIdx][z] == 'D' then

			SetHogName(hhs[i],loc("Demo"))
			SetHogHat(hhs[i], "Skull")
			SetHealth(hhs[i], scaleHealth(200))

		elseif teamRoles[currTeamIdx][z] == 'I' then

			SetHogName(hhs[i],loc("Sniper"))
			SetHogHat(hhs[i], "Sniper")
			SetHealth(hhs[i], scaleHealth(120))

		elseif teamRoles[currTeamIdx][z] == 'A' then

			SetHogName(hhs[i],loc("Saint"))
			SetHogHat(hhs[i], "angel")
			SetHealth(hhs[i], scaleHealth(300))

		elseif teamRoles[currTeamIdx][z] == 'P' then

			SetHogName(hhs[i],loc("Pyro"))
			SetHogHat(hhs[i], "Gasmask")
			SetHealth(hhs[i], scaleHealth(150))

		elseif teamRoles[currTeamIdx][z] == 'L' then

			SetHogName(hhs[i],loc("Loon"))
			SetHogHat(hhs[i], "clown")
			SetHealth(hhs[i], scaleHealth(100))

		end

		lastTeam = GetHogTeamName(hhs[i])

	end

end

function onGameInit()
	-- Force-disable harmful game flags
	DisableGameFlags(gfSharedAmmo, gfKing)
	-- Force-enable game-critical game flags
	EnableGameFlags(gfPerHogAmmo, gfResetWeps)
	-- NOTE: For your game scheme, these game flags are recommended: gfResetWeps, gfPlaceHog, gfSwitchHog, gfInfAttack

	-- No weapon crates
	HealthCaseProb = 100

	-- Instructions
	Goals = loc("The Specialists: Each hedgehog starts with its own weapon set")
end

function onGameStart()

	CreateTeam()
	trackTeams()

end


function onNewTurn()

	started = true
	AddCaption(string.format(loc("Prepare yourself, %s!"), GetHogName(CurrentHedgehog)))

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


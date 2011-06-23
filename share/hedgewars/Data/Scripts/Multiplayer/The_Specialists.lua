----------------------------------
-- THE SPECIALISTS MODE 0.2
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

--------------------
--TO DO
--------------------

-- add proper gameflag checking, maybe
-- set crate drops etc.
-- assuming place hog mode + gfinfattack doesn't get the fix: somehow end turn after teleport

loadfile(GetDataPath() .. "Scripts/Locale.lua")()

local numhhs = 0 
local hhs = {} 

local currName 
local lastName

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
			SetHogHat(hhs[i], "Vega")
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

function ResetAllAmmo()

	AddAmmo(CurrentHedgehog, amBazooka, 0)
	AddAmmo(CurrentHedgehog, amGrenade, 0)
	AddAmmo(CurrentHedgehog, amShotgun, 0)
	
	AddAmmo(CurrentHedgehog, amGirder, 0)
	AddAmmo(CurrentHedgehog, amBlowTorch, 0)
	AddAmmo(CurrentHedgehog, amPickHammer, 0)
	AddAmmo(CurrentHedgehog, amSwitch, 0)

	AddAmmo(CurrentHedgehog, amRope, 0)
	AddAmmo(CurrentHedgehog, amParachute, 0)
	AddAmmo(CurrentHedgehog, amFirePunch, 0)

	AddAmmo(CurrentHedgehog, amDynamite, 0)
	AddAmmo(CurrentHedgehog, amDrill, 0)
	AddAmmo(CurrentHedgehog, amMine, 0)

	AddAmmo(CurrentHedgehog, amSniperRifle, 0)
	AddAmmo(CurrentHedgehog, amDEagle, 0)
	AddAmmo(CurrentHedgehog, amPortalGun, 0)

	AddAmmo(CurrentHedgehog, amSeduction, 0)
	AddAmmo(CurrentHedgehog, amResurrector, 0)
	AddAmmo(CurrentHedgehog, amInvulnerable, 0)
	
	AddAmmo(CurrentHedgehog, amFlamethrower, 0)
	AddAmmo(CurrentHedgehog, amMolotov, 0)
	AddAmmo(CurrentHedgehog, amNapalm, 0)
	
	AddAmmo(CurrentHedgehog, amBaseballBat, 0)
	AddAmmo(CurrentHedgehog, amGasBomb, 0)
	AddAmmo(CurrentHedgehog, amKamikaze, 0)

end

function AssignAmmo()

	ResetAllAmmo()	
	n = GetHogName(CurrentHedgehog)

	AddAmmo(CurrentHedgehog, amSkip,100)

	if n == "Soldier" then 
		AddAmmo(CurrentHedgehog, amBazooka,1)
		AddAmmo(CurrentHedgehog, amGrenade,1)
		AddAmmo(CurrentHedgehog, amShotgun,1)
	elseif n == "Engineer" then
		AddAmmo(CurrentHedgehog, amGirder, 2)
		AddAmmo(CurrentHedgehog, amBlowTorch, 1)
		AddAmmo(CurrentHedgehog, amPickHammer, 1)	
		AddAmmo(CurrentHedgehog, amSwitch, 2)	
	elseif n == "Ninja" then
		AddAmmo(CurrentHedgehog, amRope, 100)
		AddAmmo(CurrentHedgehog, amParachute, 100)
		AddAmmo(CurrentHedgehog, amFirePunch, 1)
	elseif n == "Demo" then
		AddAmmo(CurrentHedgehog, amDynamite, 1)
		AddAmmo(CurrentHedgehog, amMine, 1)
		AddAmmo(CurrentHedgehog, amDrill, 1)
	elseif n == "Sniper" then
		AddAmmo(CurrentHedgehog, amSniperRifle, 1)
		AddAmmo(CurrentHedgehog, amDEagle, 1)
		AddAmmo(CurrentHedgehog, amPortalGun, 2)
	elseif n == "Saint" then
		AddAmmo(CurrentHedgehog, amSeduction, 100)
		AddAmmo(CurrentHedgehog, amResurrector, 1)
		AddAmmo(CurrentHedgehog, amInvulnerable, 1)
	elseif n == "Pyro" then
		AddAmmo(CurrentHedgehog, amFlamethrower, 1)
		AddAmmo(CurrentHedgehog, amMolotov, 1)
		AddAmmo(CurrentHedgehog, amNapalm, 1)
	elseif n == "Loon" then
		AddAmmo(CurrentHedgehog, amBaseballBat, 1)
		AddAmmo(CurrentHedgehog, amGasBomb, 1)
		AddAmmo(CurrentHedgehog, amKamikaze, 1)
	end

end

function onGameInit()
	GameFlags = gfRandomOrder + gfResetWeps + gfInfAttack + gfPlaceHog
	Delay = 10
end

function onGameStart()
   	
	CreateTeam()

	ShowMission	(
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

end


function onNewTurn()
	currName = GetHogName(CurrentHedgehog)
	lastName = GetHogName(CurrentHedgehog)
	AssignAmmo()
	AddAmmo(CurrentHedgehog, amSwitch, 1)
end

function onGameTick()

	if (CurrentHedgehog ~= nil) then

		currName = GetHogName(CurrentHedgehog)
		
		if currName ~= lastName then
			AddCaption(loc("Switched to ") .. currName .. "!")
			AssignAmmo()		
		end

		lastName = currName

	end

end

function onGearAdd(gear)
    
	if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		numhhs = numhhs + 1
	end

end

function onGearDelete(gear)
--
end

function onAmmoStoreInit()

end




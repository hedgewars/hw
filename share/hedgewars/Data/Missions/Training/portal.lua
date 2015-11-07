HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")

local MineArray = {}
local player 
local adviceGiven = false
local adviceGiven2 = false

function onGameInit()
	Seed = 0 -- The base number for the random number generator
	GameFlags = gfInfAttack +gfBorder +gfDisableWind +gfSolidLand 
	TurnTime = 1500000 -- The time the player has to move each round (in ms)
	CaseFreq = 0 -- The frequency of crate drops
	MinesNum = 0 -- The number of mines being placed
	Explosives = 0 -- The number of explosives being placed
	Delay = 10 -- The delay between each round
	Map = "portal" -- The map to be played
	Theme = "Hell" -- The theme to be used
	Goals = loc("Use the portal to move fast and far, use it to kill, use it with caution!")  --the goal ...
	
	
----AddTeam(teamname, color, grave, fort, voicepack, flag)--
	AddTeam(loc("Subject"), 14483406, "Simple", "Island", "Default", "cm_star")
	player = AddHog(loc("player"), 0, 10, "Terminator_Glasses")

	AddTeam(loc("Hell Army"), 1170801, "Simple", "Island", "Default", "cm_galaxy")
	enemy1 = AddHog(loc("Lucifer"), 1, 200, "thinkingcap")
	enemy2 = AddHog(loc("voldemort"), 1, 150, "WizardHat")
	enemy3 = AddHog(loc("zombi"), 1, 100, "zombi")
	enemy4 = AddHog(loc("Predator"), 1, 14, "predator")
	enemy5 = AddHog(loc("oneye"), 1, 50, "cyclops")
	enemy6 = AddHog(loc("razac"), 1, 50, "plaguemask")
	enemy7 = AddHog(loc("C-2"), 1, 50, "cyborg1")
	enemy8 = AddHog(loc("Rider"), 1, 50, "scif_SparkssHelmet")

	AddTeam(loc("badmad"), 1170801, "Simple", "Island", "Default", "cm_jupiter")
	enemy9 = AddHog(loc("C-1"), 1, 50, "cyborg2")
	enemy10 = AddHog(loc("hiden"), 1, 40, "daftpunkguymanuel")
	enemy11 = AddHog(loc("ronald"), 1, 70, "clown")
	enemy12 = AddHog(loc("phosphatoglucidique"), 1, 50, "chef")
	enemy13 = AddHog(loc("Lestat"), 1, 30, "draculakz")

	SetGearPosition(player, 350, 1820)
    SetGearPosition(enemy1, 2037, 1313)
	SetGearPosition(enemy2, 1369, 1605)
	SetGearPosition(enemy3, 1750, 1937)
	SetGearPosition(enemy4, 3125, 89)
	SetGearPosition(enemy5, 743, 900)
	SetGearPosition(enemy6, 130, 360)
	SetGearPosition(enemy7, 1333, 640)
	SetGearPosition(enemy8, 1355, 200)
	SetGearPosition(enemy9, 2680, 225)
	SetGearPosition(enemy10, 2970, 800)
	SetGearPosition(enemy11, 4050, 1964)
	SetGearPosition(enemy12, 2666, 950)
	SetGearPosition(enemy13, 3306, 1205)



end

function onAmmoStoreInit()

	SetAmmo(amFirePunch, 0,0,0,1)
	SetAmmo(amParachute, 0, 0, 0, 2)
	SetAmmo(amGirder, 0, 0, 0, 3)
	SetAmmo(amTeleport, 0, 0, 0, 1)
	SetAmmo(amLaserSight,0,0,0,1)
	SetAmmo(amHellishBomb,0,0,0,1)
	SetAmmo(amGrenade,0,0,0,1)
	SetAmmo(amRope,0,0,0,1)
	SetAmmo(amDEagle,0,0,0,1)
	SetAmmo(amExtraTime,0,0,0,2)
	SetAmmo(amSkip,9,0,0,0)
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amPickHammer, 0, 0, 0, 1)
	SetAmmo(amSnowball, 0, 0, 0, 1)

end

function onGameStart()

	SetWind(100)-- SetWind(windSpeed) Sets the current wind in the range of -100 to 100. Use together with gfDisableWind for full control.
                -- -100to0 is to the left, and 0to100 is to the right  (of course more its far from 0, more the speed is high
				--  -100.............................0..................................+100
				-- <<<<<<<<--<<--<<<<<<<<<<<<<--<<<<<|||-->>>>>>>>-->>>>>>>>>>>>>>>-->>>>>>          =  wind direction


	MineArray[0] = AddGear(840, 1847, gtMine, 0, 0, 0, 0)
	MineArray[1] = AddGear(900, 1847, gtMine, 0, 0, 0, 0)
	MineArray[2] = AddGear(1000, 1847, gtMine, 0, 0, 0, 0)
	MineArray[3] = AddGear(1100, 1847, gtMine, 0, 0, 0, 0)
	MineArray[4] = AddGear(1140, 1847, gtMine, 0, 0, 0, 0)
	MineArray[5] = AddGear(1170, 1847, gtMine, 0, 0, 0, 0)
	MineArray[6] = AddGear(1200, 1847, gtMine, 0, 0, 0, 0)
	MineArray[7] = AddGear(1200, 1847, gtMine, 0, 0, 0, 0)
	MineArray[8] = AddGear(1230, 1847, gtMine, 0, 0, 0, 0)
	MineArray[9] = AddGear(1280, 1847, gtMine, 0, 0, 0, 0)
	MineArray[10] = AddGear(1302, 1847, gtMine, 0, 0, 0, 0)
	MineArray[11] = AddGear(1350, 1847, gtMine, 0, 0, 0, 0)
	MineArray[12] = AddGear(1383, 1847, gtMine, 0, 0, 0, 0)
	MineArray[13] = AddGear(1400, 1847, gtMine, 0, 0, 0, 0)
	MineArray[14] = AddGear(1423, 1847, gtMine, 0, 0, 0, 0)
	MineArray[15] = AddGear(1470, 1847, gtMine, 0, 0, 0, 0)
	MineArray[16] = AddGear(1480, 1847, gtMine, 0, 0, 0, 0)
	MineArray[17] = AddGear(1311, 1847, gtMine, 0, 0, 0, 0)

	MineArray[18] = AddGear(840, 1785, gtMine, 0, 0, 0, 0)
	MineArray[19] = AddGear(900, 1785, gtMine, 0, 0, 0, 0)
	MineArray[20] = AddGear(1000, 1785, gtMine, 0, 0, 0, 0)
	MineArray[21] = AddGear(1100, 1785, gtMine, 0, 0, 0, 0)
	MineArray[22] = AddGear(1140, 1785, gtMine, 0, 0, 0, 0)
	MineArray[23] = AddGear(1170, 1785, gtMine, 0, 0, 0, 0)
	MineArray[24] = AddGear(1200, 1785, gtMine, 0, 0, 0, 0)
	MineArray[25] = AddGear(1230, 1785, gtMine, 0, 0, 0, 0)
	MineArray[26] = AddGear(1280, 1785, gtMine, 0, 0, 0, 0)
	MineArray[27] = AddGear(1302, 1785, gtMine, 0, 0, 0, 0)
	MineArray[28] = AddGear(1350, 1785, gtMine, 0, 0, 0, 0)
	MineArray[29] = AddGear(1383, 1785, gtMine, 0, 0, 0, 0)
	MineArray[30] = AddGear(1400, 1785, gtMine, 0, 0, 0, 0)
	MineArray[31] = AddGear(1423, 1785, gtMine, 0, 0, 0, 0)
	MineArray[32] = AddGear(1470, 1785, gtMine, 0, 0, 0, 0)
	MineArray[33] = AddGear(1480, 1785, gtMine, 0, 0, 0, 0)
	MineArray[34] = AddGear(1311, 1785, gtMine, 0, 0, 0, 0)

	MineArray[35] = AddGear(4029, 89, gtMine, 0, 0, 0, 120)
	--MineArray[36] = AddGear(3376, 1947, gtMine, 0, 0, 0, 10)

		for i = 0,#MineArray do
			SetTimer(MineArray[i],050)
			SetState(MineArray[i],544)
		end
				--needed this MineArray cause timer didn't work, its was always 3sec, i wanna instant mines


				--UTILITY CRATE--
	parachute = SpawnUtilityCrate(1670, 1165, amParachute)
	girder = SpawnUtilityCrate(2101, 1297, amGirder)
	SpawnUtilityCrate(3965, 625, amBlowTorch)
	SpawnUtilityCrate(2249, 93, amBlowTorch)
	SpawnUtilityCrate(2181, 829, amBlowTorch)
	SpawnUtilityCrate(1820, 567, amBlowTorch)
	SpawnUtilityCrate(1375, 900, amTeleport)
	SpawnUtilityCrate(130, 600, amPickHammer)
	SpawnUtilityCrate(1660,1820, amLaserSight)
	SpawnUtilityCrate(4070,1840, amLaserSight)
	
	
				--AMMO CRATE--
	portalgun = SpawnAmmoCrate(505, 1943, amPortalGun, 1000)
	extratime = SpawnAmmoCrate(4020, 785, amExtraTime, 2)
	SpawnAmmoCrate(425, 613, amSnowball)
	SpawnAmmoCrate(861, 633, amHellishBomb)
	SpawnAmmoCrate(2510, 623, amSnowball)
	SpawnAmmoCrate(2900, 1600, amGrenade)
	SpawnAmmoCrate(2680, 320, amGrenade)
	SpawnAmmoCrate(2650, 80, amDEagle)
	SpawnAmmoCrate(3000, 100, amDEagle)
	SpawnAmmoCrate(2900, 1400, amRope)
	SpawnAmmoCrate(4025, 1117, amFirePunch)

	
				--HEALTH CRATE--
	SpawnHealthCrate(2000, 780)
	
				--GIRDER--
	PlaceGirder(3363, 1323, 4)


	ShowMission (loc("Portal mission"), loc("training"), "", -amPortalGun, 5000)
	HogSay(player, loc("I should get myself a portal gun, maybe this crate has one"), SAY_THINK)
	



end

function onGameTick()

    if (player ~= nil)  then
		if (gearIsInBox(player, 1650, 1907, 200, 60) and (adviceGiven == false)) then
			adviceGiven = true
				HogSay(player, loc("Hmmm, I'll have to find some way of moving him off this anti-portal surface..."), SAY_THINK)
		elseif (gearIsInBox(player, 2960, 790, 200, 60) and (adviceGiven2 == false)) then
			adviceGiven2 = true
				HogSay(player, loc("The anti-portal zone is all over the floor, and I have nothing to kill him...Droping something could hurt him enough to kill him..."), SAY_THINK)
 end
 end
	
	end
	




function onNewturn()
end


function onGearAdd(gear)
end

function onGearDelete(gear)

	if gear == portalgun then
		--AddAmmo(player, amPortalGun, 10000)
		HogSay(player, loc("GREAT ! Let's kill all this enemies, using portals"), SAY_THINK)
	end

	if gear == girder then 
		HogSay(player, loc("Will be useful if I need a new plateform or if I want to rise...."), SAY_THINK)
	end
	
	if gear == parachute then
		HogSay(player, loc("You can't fire a portal on the blue surface"), SAY_THINK)
	end
--if you wanted to check for collection only
--you could probably say
--if (gear == myParachuteGear) and (band(GetGearMessage(gear), gmDestroy) ~= 0) then

	if gear == extratime then
		HogSay(player, loc(" What !! For all of this struggle i just win some ... TIME o0"), SAY_SHOUT)
	end

	
	if gear == player then
        player = nil
    end
end







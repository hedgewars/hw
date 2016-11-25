--------------------------------------
-- NOBODY LAUGH
-- a hilarious (not really) adventure
--------------------------------------

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

local hhs = {}

function onGameInit()

	Seed = 0
	GameFlags = gfInfAttack + gfPerHogAmmo +gfDisableWind
	SuddenDeathTurns = 9999
	TurnTime = 180000
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0
	Map = "Bath"
	Theme = "Nature"

	AddTeam(loc("Nameless Heroes"), 14483456, "eyecross", "Wood", "HillBilly", "cm_crossedswords")
	hhs[1] = AddHog(loc( "Hunter" ), 0, 1, "Skull")
	SetGearPosition(hhs[1], 1267, 451)
	hhs[2] = AddHog(loc("Drowner"), 0, 31, "mp3")
	SetGearPosition(hhs[2], 1332, 451)

	AddTeam(loc("Clowns"), 1175851, "Duck2", "Tank", "Mobster", "cm_face")
	hhs[3] = AddHog(loc("Poison"), 5, 100, "WhySoSerious")
	SetGearPosition(hhs[3], 1133, 446)
	hhs[4] = AddHog(loc("Bobo"), 5, 100, "clown")
	SetGearPosition(hhs[4], 1215, 553)
	hhs[5] = AddHog(loc("Copper"), 5, 10, "clown-copper")
	SetGearPosition(hhs[5], 414, 376)
	hhs[6] = AddHog(loc("Derp"), 5, 100, "clown-crossed")
	SetGearPosition(hhs[6], 1590, 886)
	hhs[7] = AddHog(loc("Eckles"), 5, 100, "clown-copper")
	SetGearPosition(hhs[7], 772, 754)
	hhs[8] = AddHog(loc("Frank"), 5, 50, "clown-copper")
	SetGearPosition(hhs[8], 1688, 714)
	hhs[9] = AddHog(loc("Harry"), 5, 50, "clown-copper")
	SetGearPosition(hhs[9], 1932, 837)
	hhs[10] = AddHog(loc("Igmund"), 5, 50, "WhySoSerious")
	SetGearPosition(hhs[10], 1601, 733)

end

function onGameStart()

	AddAmmo(enemy, amAirAttack, 100)

	ShowMission(	loc("Nobody Laugh"),
					loc("Scenario"),
					loc("Eliminate the enemy before the time runs out")
					, 0, 0
				)

	-- GIRDERS
	PlaceGirder(1212, 710, 7)
	PlaceGirder(1215, 570, 4)
	PlaceGirder(1288, 520, 2)
	PlaceGirder(1184, 468, 4)
	PlaceGirder(1344, 468, 4)
	PlaceGirder(1247, 346, 4)

	PlaceGirder(667, 438, 4)
	PlaceGirder(507, 438, 4)
	PlaceGirder(434, 487, 2)
	PlaceGirder(505, 537, 4)
	PlaceGirder(665, 537, 4)
	PlaceGirder(737, 487, 2)

	PlaceGirder(416, 465, 6)
	PlaceGirder(1415, 378, 6)
	PlaceGirder(1300, 625, 3)
	PlaceGirder(1359, 566, 3)
	PlaceGirder(1436, 538, 0)
	PlaceGirder(1505, 468, 4)

	------ AMMO CRATE LIST ------
	tempG = SpawnAmmoCrate(1242, 315, amBaseballBat)
	tempG = SpawnAmmoCrate(1309, 315, amAirAttack)
	tempG = SpawnAmmoCrate(144, 895, amAirAttack)
	tempG = SpawnAmmoCrate(664, 699, amIceGun)
	tempG = SpawnAmmoCrate(1572, 444, amFirePunch)
	tempG = SpawnAmmoCrate(1574, 382, amDynamite)

	------ UTIL CRATE LIST ------
	tempG = SpawnUtilityCrate(654, 513, amParachute)
	tempG = SpawnUtilityCrate(1569, 413, amParachute)

	-- HOG AMMO
	AddAmmo(hhs[1],amParachute,1)
	AddAmmo(hhs[1],amHammer,1)
	AddAmmo(hhs[2],amWhip,1)

	for i = 3, 10 do
		AddAmmo(hhs[i], amDEagle, 100)
		AddAmmo(hhs[i], amShotgun, 100)
		AddAmmo(hhs[i], amGrenade, 100)
		AddAmmo(hhs[i], amBazooka, 100)
		AddAmmo(hhs[i], amDrill, 100)
	end

end

function onNewTurn()
	SetWind(100)
end

function onAmmoStoreInit()

	SetAmmo(amBaseballBat, 0, 0, 0, 1)
	SetAmmo(amAirAttack, 0, 0, 0, 1)
	SetAmmo(amFirePunch, 0, 0, 0, 1)
	SetAmmo(amDynamite, 0, 0, 0, 1)
	SetAmmo(amHammer, 0, 0, 0, 1)
	SetAmmo(amIceGun, 0, 0, 0, 1)

	SetAmmo(amParachute, 0, 0, 0, 1)

	SetAmmo(amSwitch, 9, 0, 0, 0)
	SetAmmo(amSkip, 9, 0, 0, 0)

end

------------------------------
--                  I'm in         whitesppaaaaaaaaaacceeeee           :D
------------------------------

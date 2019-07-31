HedgewarsScriptLoad("/Scripts/SimpleMission.lua")
HedgewarsScriptLoad("/Scripts/Locale.lua")

local enemyAmmo = {
	[amDEagle] = 100, [amShotgun] = 100, [amGrenade] = 100, [amBazooka] = 100, [amDrill] = 100
}

SimpleMission({
	missionTitle = loc("Nobody Laugh"),
	missionIcon = -amHammer,
	goalText = 
		loc("Eliminate the enemy.") .. "|" ..
		loc("Unlimited Attacks: Attacks don't end your turn") .. "|"..
		loc("Per-hog Ammo: Weapons are not shared between hogs"),
	wind = 100,
	initVars = {
		TurnTime = 180000,
		Map = "Bath",
		Theme = "Nature",
		Seed = 0,
		GameFlags = gfInfAttack + gfPerHogAmmo + gfDisableWind,
	},
	ammoConfig = {
		[amSwitch] = { count = 9 },
	},
	teams = {
		{ isMissionTeam = true,
		clanID = 0,
		hogs = {
			{
			health = 1,
			x = 1267, y = 451,
			ammo = { [amParachute] = 1, [amHammer] = 1 },
			},
			{
			health = 31,
			x = 1332, y = 451,
			ammo = { [amWhip] = 1 },
			},
		}},
		{ name = loc("Clowns"),
		flag = "cm_face",
		grave = "Duck2",
		voice = "Mobster_qau",
		clanID = 5,
		hogs = {
			{ name = loc("Poison"), health = 100, x = 1133, y = 446, hat = "WhySoSerious", botLevel = 1, ammo = enemyAmmo },
			{ name = loc("Bobo"), health = 100, x = 1215, y = 553, hat = "clown", botLevel = 1, ammo = enemyAmmo },
			{ name = loc("Copper"), health = 10, x = 414, y = 376, hat = "clown-copper", botLevel = 1, ammo = enemyAmmo },
			{ name = loc("Derp"), health = 100, x = 1590, y = 886, hat = "clown-crossed", botLevel = 1, ammo = enemyAmmo },
			{ name = loc("Eckles"), health = 100, x = 772, y = 754, hat = "clown-copper", botLevel = 1, ammo = enemyAmmo },
			{ name = loc("Frank"), health = 50, x = 1688, y = 714, hat = "clown-copper", botLevel = 1, ammo = enemyAmmo },
			{ name = loc("Harry"), health = 50, x = 1932, y = 837, hat = "clown-copper", botLevel = 1, ammo = enemyAmmo },
			{ name = loc("Igmund"), health = 50, x = 1601, y = 733, hat = "WhySoSerious", botLevel = 1, ammo = enemyAmmo },
		}},
	},
	girders = {
		{ x = 1212, y = 710, frameIdx = 7 },
		{ x = 1215, y = 570, frameIdx = 4 },
		{ x = 1288, y = 520, frameIdx = 2 },
		{ x = 1184, y = 468, frameIdx = 4 },
		{ x = 1344, y = 468, frameIdx = 4 },
		{ x = 1247, y = 346, frameIdx = 4 },
		{ x = 667, y = 438, frameIdx = 4 },
		{ x = 507, y = 438, frameIdx = 4 },
		{ x = 434, y = 487, frameIdx = 2 },
		{ x = 505, y = 537, frameIdx = 4 },
		{ x = 665, y = 537, frameIdx = 4 },
		{ x = 737, y = 487, frameIdx = 2 },
		{ x = 416, y = 465, frameIdx = 6 },
		{ x = 1415, y = 378, frameIdx = 6 },
		{ x = 1300, y = 625, frameIdx = 3 },
		{ x = 1359, y = 566, frameIdx = 3 },
		{ x = 1436, y = 538, frameIdx = 0 },
		{ x = 1505, y = 468, frameIdx = 4 },
	},

	gears = {
		{ type = gtCase, crateType = "supply", x = 1242, y = 315, ammoType = amBaseballBat },
		{ type = gtCase, crateType = "supply", x = 1309, y = 315, ammoType = amAirAttack },
		{ type = gtCase, crateType = "supply", x = 144, y = 895, ammoType = amAirAttack },
		{ type = gtCase, crateType = "supply", x = 664, y = 699, ammoType = amIceGun },
		{ type = gtCase, crateType = "supply", x = 1572, y = 444, ammoType = amFirePunch },
		{ type = gtCase, crateType = "supply", x = 1574, y = 382, ammoType = amDynamite },
		{ type = gtCase, crateType = "supply", x = 654, y = 513, ammoType = amParachute },
		{ type = gtCase, crateType = "supply", x = 1569, y = 413, ammoType = amParachute },
	}
})

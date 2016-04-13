HedgewarsScriptLoad("/Scripts/TargetPractice.lua")

local params = {
	ammoType = amGrenade,
	gearType = gtGrenade,
	missionTitle = loc("Target Practice: Grenade (hard)"),
	solidLand = true,
	artillery = true,
	map = "SB_Crystal",
	theme = "Cave",
	hog_x = 1456,
	hog_y = 669,
	hogName = loc("Grenadier"),
	hogHat = "war_desertgrenadier2",
	teamName = loc("Grenade Group"),
	targets = {
		{ x = 1190, y = 694 },
		{ x = 962, y = 680 },
		{ x = 1090, y = 489 },
		{ x = 1664, y = 666 },
		{ x = 1584, y = 580 },
		{ x = 2160, y = 738 },
		{ x = 1836, y = 726 },
		{ x = 618, y = 753 },
		{ x = 837, y = 668 },
		{ x = 2424, y = 405 },
		{ x = 2310, y = 742 },
		{ x = 294, y = 897 },
		{ x = 472, y = 855 },
		{ x = 2949, y = 724},
		{ x = 3356, y = 926 },
		{ x = 3734, y = 918 },
		{ x = 170, y = 874 },
		
		
	},
	time = 180000,
	shootText = loc("You have thrown %d grenades."),
}

TargetPracticeMission(params)

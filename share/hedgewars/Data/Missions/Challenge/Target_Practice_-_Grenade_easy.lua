HedgewarsScriptLoad("/Scripts/TargetPractice.lua")

local params = {
	ammoType = amGrenade,
	gearType = gtGrenade,
	missionTitle = loc("Target Practice: Grenade (easy)"),
	solidLand = true,
	artillery = true,
	map = "SB_Crystal",
	theme = "Cave",
	hog_x = 2039,
	hog_y = 701,
	faceLeft = true,
	targets = {
		{ x = 1834, y = 747 },
		{ x = 2308, y = 729 },
		{ x = 1659, y = 718 },
		{ x = 1196, y = 704 },
		{ x = 2650, y = 826 },
		{ x = 1450, y = 705 },
		{ x = 2774, y = 848 },
		{ x = 2970, y = 704 },
	},
	time = 80000,
	shootText = loc("You have thrown %d grenades."),
}

TargetPracticeMission(params)

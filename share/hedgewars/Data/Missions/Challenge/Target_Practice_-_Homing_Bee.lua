HedgewarsScriptLoad("/Scripts/TargetPractice.lua")

local params = {
	ammoType = amBee,
	gearType = gtBee,
	missionTitle = loc("Target Practice: Homing Bee"),
	solidLand = true,
	map = "Hedgewars",
	theme = "Nature",
	hog_x = 1990,
	hog_y = 514,
	hogHat = "NoHat",
	teamGrave = "bp2",
	teamFlag = "cm_flower",
	targets = {
		{ x = 1949, y = 273 },
		{ x = 1734, y = 322 },
		{ x = 1574, y = 340 },
		{ x = 1642, y = 474 },
		{ x = 2006, y = 356 },
		{ x = 1104, y = 285 },
		{ x = 565, y = 440 },
		{ x = 732, y = 350 },
		{ x = 2022, y = 396 },
		{ x = 366, y = 360 },
		{ x = 556, y = 300 },
		{ x = 902, y = 306 },
		{ x = 924, y = 411 },
		{ x = 227, y = 510 },
		{ x = 150, y = 300 },
	},
	time = 120000,
	shootText = loc("You have launched %d homing bees."),
}

TargetPracticeMission(params)

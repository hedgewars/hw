HedgewarsScriptLoad("/Scripts/TargetPractice.lua")

local params = {
	ammoType = amShotgun,
	gearType = gtShotgunShot,
	missionTitle = loc("Target Practice: Shotgun"),
	solidLand = false,
	map = "SB_Haunty",
	theme = "Halloween",
	hog_x = 320,
	hog_y = 324,
	hogHat = "NoHat",
	hogGrave = "Bones",
	targets = {
		{ x = 495, y = 501 },
		{ x = 227, y = 530 },
		{ x = 835, y = 934 },
		{ x = 1075, y = 889 },
		{ x = 887, y = 915 },
		{ x = 1148, y = 750 },
		{ x = 916, y = 915 },
		{ x = 1211, y = 700 },
		{ x = 443, y = 505 },
		{ x = 822, y = 964 },
		{ x = 1092, y = 819 },
		{ x = 1301, y = 683 },
		{ x = 1480, y = 661 },
		{ x = 1492, y = 786 },
		{ x = 1605, y = 562 },
		{ x = 1545, y = 466 },
		{ x = 1654, y = 392 },
		{ x = 1580, y = 334 },
		{ x = 1730, y = 222 },
	},
	time = 90000,
}

TargetPracticeMission(params)

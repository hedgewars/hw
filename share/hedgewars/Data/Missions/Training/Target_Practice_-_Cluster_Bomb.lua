HedgewarsScriptLoad("/Scripts/TargetPractice.lua")

local params = {
	ammoType = amClusterBomb,
	gearType = gtClusterBomb,
	missionTitle = loc("Cluster Bomb Training"),
	solidLand = false,
	map = "Trash",
	theme = "Golf",
	hog_x = 756,
	hog_y = 370,
	hogName = loc("Private Nolak"),
	hogHat = "war_desertgrenadier1",
	teamName = loc("The Hogies"),
	targets = {
		{ x = 628, y = 0 },
		{ x = 891, y = 0 },
		{ x = 1309, y = 0 },
		{ x = 1128, y = 0 },
		{ x = 410, y = 0 },
		{ x = 1564, y = 0 },
		{ x = 1248, y = 476 },
		{ x = 169, y = 0 },
		{ x = 1720, y = 0 },
		{ x = 1441, y = 0 },
		{ x = 599, y = 0 },
		{ x = 1638, y = 0 },
	},
	time = 180000,
	shootText = loc("You have thrown %d cluster bombs."),
}

TargetPracticeMission(params)

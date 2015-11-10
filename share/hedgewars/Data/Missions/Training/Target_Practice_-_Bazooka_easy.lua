HedgewarsScriptLoad("/Scripts/TargetPractice.lua")

local params = {
	ammoType = amBazooka,
	gearType = gtShell,
	missionTitle = loc("Target Practice: Bazooka (easy)"),
	wind = 50,
	solidLand = true,
	map = "Lonely_Island",
	theme = "Island",
	hog_x = 1439,
	hog_y = 482,
	hogName = loc("Zook"),
	hogHat = "war_americanww2helmet",
	teamName = loc("Team Zook"),
	targets = {
		{ x = 1310, y = 756 },
		{ x = 1281, y = 893 },
		{ x = 1376, y = 670 },
		{ x = 1725, y = 907 },
		{ x = 1971, y = 914 },
		{ x = 1098, y = 955 },
		{ x = 1009, y = 877 },
		{ x = 930, y = 711 },
		{ x = 771, y = 744 },
		{ x = 385, y = 405 },
		{ x = 442, y = 780 },
		{ x = 620, y = 639 },
		{ x = 311, y = 239 },
	},
	time = 80000,
	shootText = loc("You have launched %d bazookas."),
}

TargetPracticeMission(params)

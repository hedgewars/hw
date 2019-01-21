HedgewarsScriptLoad("/Scripts/SpeedShoppa.lua")

local params = {}
params.missionTitle = loc("Ropes and Crates")
params.faceLeft = true

params.time = 115000
params.map = "Ropes"
params.theme = "City"

params.hog_x = 3754
params.hog_y = 1779
params.crates = {
	{ x = 3533, y = 1404 },
	{ x = 3884, y = 1048 },
	{ x = 3366, y = 664 },
	{ x = 3162, y = 630 },
	{ x = 2872, y = 402 },
	{ x = 3812, y = 322 },
	{ x = 3685, y = 34 },
	{ x = 3324, y = 540 },
	{ x = 2666, y = 224 },
	{ x = 2380, y = 1002 },
	{ x = 2224, y = 1008 },
	{ x = 2226, y = 854 },
	{ x = 3274, y = 1754 },
	{ x = 3016, y = 1278 },
	{ x = 2756, y = 1716 },
	{ x = 2334, y = 1756 },
	{ x = 1716, y = 1752 },
	{ x = 1526, y = 1464 },
	{ x = 356, y = 1734 },
	{ x = 598, y = 1444 },
	{ x = 1084, y = 1150 },
	{ x = 358, y = 834 },
	{ x = 936, y = 200 },
	{ x = 1540, y = 514 },
}

SpeedShoppaMission(params)

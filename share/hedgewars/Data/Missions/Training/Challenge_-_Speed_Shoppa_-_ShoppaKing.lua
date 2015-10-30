HedgewarsScriptLoad("/Scripts/SpeedShoppa.lua")

local params = {}
params.missionTitle = loc("The Customer is King")
params.teamName = loc("Shoppa Union")
params.hogName = loc("King Customer")
params.teamFlag = "cm_shoppa"
params.teamGrave = "money"
params.hogHat = "crown"

params.time = 160000
params.map = "ShoppaKing"
params.theme = "Castle"

params.hog_x = 543
params.hog_y = 1167
params.crates = {
	{ x = 170, y = 172 },
	{ x = 216, y = 478 },
	{ x = 616, y = 966 },
	{ x = 291, y = 1898 },
	{ x = 486, y = 1965 },
	{ x = 852, y = 1289 },
	{ x = 1224, y = 1625 },
	{ x = 925, y = 584 },
	{ x = 2013, y = 141 },
	{ x = 2250, y = 351 },
	{ x = 2250, y = 537 },
	{ x = 2472, y = 513 },
	{ x = 1974, y = 459 },
	{ x = 1995, y = 1068 },
	{ x = 2385, y = 1788 },
	{ x = 1698, y = 1725 },
	{ x = 2913, y = 1092 },
	{ x = 3972, y = 1788 },
	{ x = 3762, y = 1635 },
	{ x = 2577, y = 1473 },
	{ x = 3612, y = 1068 },
	{ x = 3945, y = 687 },
	{ x = 2883, y = 618 },
	{ x = 3543, y = 471 },
	{ x = 3636, y = 306 },
	{ x = 3210, y = 321 },
	{ x = 3426, y = 126 },
	{ x = 3033, y = 1590 },
	{ x = 3774, y = 1341 },
	{ x = 1254, y = 297 },
	{ x = 1300, y = 1022 },
	{ x = 1410, y = 1292 },
	{ x = 868, y = 1812 },
	{ x = 3426, y = 954 },
}

SpeedShoppaMission(params)

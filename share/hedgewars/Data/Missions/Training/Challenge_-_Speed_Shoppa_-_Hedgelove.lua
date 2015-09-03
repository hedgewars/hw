HedgewarsScriptLoad("/Scripts/SpeedShoppa.lua")

local params = {}
params.missionTitle = loc("Shoppa Love")
params.teamName = loc("Team of Hearts")
params.hogName = loc("Heartful")
params.teamFlag = "cm_iluvu"
params.teamGrave = "heart"
params.hogHat = "pinksunhat"
params.crateType = "health"
params.faceLeft = true

params.time = 45000
params.map = "Hedgelove"
params.theme = "Nature"

params.hog_x = 410
params.hog_y = 934
params.crates = {
	{ x = 183, y = 710 },
	{ x = 202, y = 519 },
	{ x = 336, y = 356 },
	{ x = 658, y = 363 },
	{ x = 1029, y = 39 },
	{ x = 758, y = 879 },
	{ x = 1324, y = 896 },
	{ x = 1410, y = 390 },
	{ x = 1746, y = 348 },
	{ x = 1870, y = 538 },
	{ x = 1884, y = 723 },
	{ x = 1682, y = 970 },
}
params.extra_onGameStart = function()
	PlaceGirder(394, 1000, 0)
	PlaceGirder(1696, 1000, 0)
end

SpeedShoppaMission(params)

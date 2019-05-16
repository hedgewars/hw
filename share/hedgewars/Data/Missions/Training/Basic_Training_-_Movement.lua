-- Basic Movement Training
-- Teaches the basic movement controls.

--[[ Lessons:
* How to show the mission panel again
* Walking
* Collecting crates
* Health basics
* Jumping
* Fall damage
* Walking and staying on ice
* Switching hedgehogs
* Bouncing on rubber
]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")

local hhs = {}
local hog_greenhorn, hog_cappy
local crates = {}
local switcherGear
local tookDamage = false
local switchTextDelay = -1
local missionPanelConfirmed = false
local missionPanelConfirmedTimer = 0
local turnStarted = false

local map = {
"\1\74\7\29\135\1\74\8\11\0\1\83\7\135\135",
"\1\250\7\135\0\1\204\7\137\135\1\238\7\135\0",
"\2\17\7\130\0\2\42\7\110\0\2\74\7\94\0",
"\2\106\7\89\0\2\99\7\121\0\2\76\7\128\0",
"\2\115\7\98\135\2\147\7\98\0\2\179\7\94\0",
"\2\147\7\96\0\2\174\7\89\0\2\145\7\91\135",
"\2\115\7\87\0\2\122\7\89\135\2\154\7\89\0",
"\2\170\7\89\0\2\179\7\105\135\2\179\7\107\135",
"\2\177\7\142\135\2\177\8\105\0\3\74\7\94\135",
"\3\74\8\50\0\3\88\7\89\135\3\129\7\89\0",
"\3\161\7\91\0\3\193\7\98\0\3\225\7\100\0",
"\4\1\7\91\0\4\33\7\89\0\4\65\7\98\0",
"\4\97\7\100\0\4\134\7\103\0\4\166\7\100\0",
"\4\200\7\98\0\4\232\7\96\0\5\8\7\96\0",
"\5\40\7\98\0\5\72\7\98\0\5\107\7\100\0",
"\5\139\7\98\0\5\173\7\89\0\5\207\7\94\0",
"\5\239\7\100\0\6\15\7\100\0\6\47\7\100\0",
"\6\86\7\100\0\6\118\7\100\0\6\153\7\94\0",
"\6\185\7\91\0\6\219\7\91\0\6\251\7\98\0",
"\7\27\7\103\0\7\61\7\100\0\7\94\7\96\0",
"\7\126\7\91\0\7\160\7\94\0\7\192\7\105\0",
"\7\224\7\116\0\7\254\7\126\0\8\34\7\123\0",
"\8\66\7\119\0\8\98\7\114\0\8\133\7\119\0",
"\8\165\7\132\0\8\195\7\142\0\8\229\7\146\0",
"\9\5\7\151\0\9\37\7\155\0\9\69\7\164\0",
"\9\101\7\174\0\9\131\7\190\0\9\160\7\208\0",
"\9\186\7\226\0\9\215\7\240\0\9\250\7\238\0",
"\10\26\7\233\0\10\58\7\233\0\10\90\7\235\0",
"\10\122\7\238\0\10\154\7\238\0\10\186\7\249\0",
"\10\213\8\14\0\10\245\8\9\0\11\3\8\39\0",
"\11\24\8\66\0\11\10\8\62\0\10\213\8\5\135",
"\10\245\8\7\0\11\21\8\14\0\11\56\8\25\0",
"\11\92\8\37\0\11\106\8\43\0\9\85\8\0\147",
"\9\83\8\0\0\8\208\7\233\147\3\168\7\197\147",
"\8\94\7\197\0\2\83\7\210\147\1\179\7\238\0",
"\1\44\7\84\139\1\12\7\87\0\0\238\7\98\0",
"\0\211\7\119\0\0\190\7\144\0\0\165\7\164\0",
"\0\146\7\190\0\0\140\7\222\0\0\142\7\254\0",
"\0\153\8\30\0\0\156\8\37\0\1\7\7\178\139",
"\0\247\7\210\0\0\224\7\238\0\0\215\8\14\0",
"\0\215\8\18\0\1\5\7\238\139\1\19\8\11\0",
"\1\32\8\43\0\1\39\8\62\0\1\67\7\32\136",
"\1\69\6\253\0\1\69\6\219\0\1\69\6\187\0",
"\1\74\6\155\0\1\80\6\123\0\1\51\6\109\0",
"\1\35\6\80\0\1\12\6\105\0\0\243\6\132\0",
"\0\233\6\176\0\0\252\6\212\0\1\14\6\240\0",
"\0\252\7\13\0\0\233\6\219\0\0\238\6\182\0",
"\0\238\6\148\0\1\12\6\164\0\1\9\6\201\0",
"\0\236\6\224\0\0\206\6\251\0\0\165\7\32\0",
"\0\144\7\57\0\0\124\7\82\0\0\103\7\107\0",
"\0\96\7\144\0\0\92\7\176\0\0\112\7\139\0",
"\0\121\7\105\0\0\130\7\61\0\0\142\7\25\0",
"\0\156\6\251\0\0\188\6\247\0\0\201\6\217\0",
"\0\167\6\224\0\0\146\6\251\0\0\130\7\25\0",
"\0\112\7\66\0\0\98\7\110\0\0\98\7\142\0",
"\0\98\7\174\0\0\101\7\206\0\0\101\7\238\0",
"\0\126\8\7\0\0\137\8\14\0\10\46\7\245\136",
"\10\14\7\247\0\9\241\7\229\0\9\209\7\222\0",
"\9\176\7\226\0\9\138\7\233\0\9\94\7\233\0",
"\9\62\7\233\0\9\46\7\235\0\2\53\7\139\136",
"\2\21\7\137\0\1\250\7\119\0\1\218\7\116\0",
"\1\186\7\119\0\1\151\7\119\0\1\119\7\114\0",
"\1\92\7\135\0\1\78\7\132\0" }

local function drawMap()
	for m=1, #map do
		ParseCommand("draw "..map[m])
	end
end

function onGameInit()
	GameFlags = gfDisableWind + gfDisableGirders + gfDisableLandObjects + gfOneClanMode + gfInfAttack
	Map = ""
	Seed = 0
	Theme = "Brick"
	MapGen = mgDrawn
	TurnTime = MAX_TURN_TIME
	Explosives = 0
	MinesNum = 0
	CaseFreq = 0
	WaterRise = 0
	HealthDecrease = 0

	-- DRAW MAP --
	drawMap()

	------ HOG LIST ------
	AddMissionTeam(-1)
	
	hhs[1] = AddMissionHog(100)
	SetGearPosition(hhs[1], 404, 1714)
	SetEffect(hhs[1], heResurrectable, 1)

	hhs[2] = AddMissionHog(100)
	SetGearPosition(hhs[2], 620, 1538)
	SetEffect(hhs[2], heResurrectable, 1)
	HogTurnLeft(hhs[2], true)

	hhs[3] = AddMissionHog(100)
	SetGearPosition(hhs[3], 1573, 1824)
	SetEffect(hhs[3], heResurrectable, 1)
	
	hhs[4] = AddHog(loc("Cappy"), 0, 100, "cap_red")
	SetGearPosition(hhs[4], 2114, 1411)
	SetEffect(hhs[4], heResurrectable, 1)
	HogTurnLeft(hhs[4], true)
	
	hhs[5] = AddMissionHog(100)
	SetGearPosition(hhs[5], 1813, 1285)
	SetEffect(hhs[5], heResurrectable, 1)

	hog_greenhorn = hhs[1]
	hog_cappy = hhs[4]

	for i=1,#hhs do
		if hhs[i] ~= hog_cappy then
			if GetHogName(hhs[i]) == loc("Cappy") then
				SetHogName(hhs[i], loc("Greenhorn"))
			end
			if GetHogHat(hhs[i]) == "cap_red" then
				SetHogHat(hhs[i], "NoHat")
			end
		end
	end
	
	SendHealthStatsOff()
	SendRankingStatsOff()
end

local function LoadGearData()

	--BEGIN CORE DATA--

	------ GIRDER LIST ------
	PlaceSprite(292, 1488, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(454, 1731, sprAmGirder, 4, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(467, 1653, sprAmGirder, 4, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(611, 1702, sprAmGirder, 5, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(426, 1558, sprAmGirder, 7, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(555, 1558, sprAmGirder, 5, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(649, 1600, sprAmGirder, 7, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1072, 1809, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1040, 1831, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1124, 1805, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1175, 1772, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1226, 1738, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1275, 1705, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1325, 1700, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1342, 1638, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1368, 1560, sprAmGirder, 3, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1390, 1665, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1481, 1716, sprAmGirder, 4, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1625, 1652, sprAmGirder, 7, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(1729, 1596, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1762, 1545, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1563, 1536, sprAmGirder, 5, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(1506, 1392, sprAmGirder, 6, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(1591, 1450, sprAmGirder, 3, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(1650, 1463, sprAmGirder, 1, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(1766, 1492, sprAmGirder, 4, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(1925, 1492, sprAmGirder, 4, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(2114, 1428, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2187, 1435, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2135, 1478, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2284, 1650, sprAmGirder, 4, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2005, 1724, sprAmGirder, 4, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1885, 1562, sprAmGirder, 7, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2252, 1700, sprAmGirder, 2, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(2308, 1803, sprAmGirder, 5, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(2394, 1893, sprAmGirder, 1, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(605, 1761, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1813, 1312, sprAmGirder, 4, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1742, 1260, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1812, 1210, sprAmGirder, 4, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1884, 1260, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1545, 1811, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1577, 1761, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1610, 1811, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1440, 1511, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2082, 1337, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2187, 1273, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2097, 1246, sprAmGirder, 4, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(593, 1465, sprAmGirder, 7, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(684, 1505, sprAmGirder, 5, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2046, 1492, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2064, 1442, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1849, 1426, sprAmGirder, 4, U_LAND_TINT_ICE, nil, nil, nil, lfIce)
	PlaceSprite(3051, 1957, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(3101, 1956, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(3150, 1954, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(3233, 1962, sprAmGirder, 5, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(3322, 2004, sprAmGirder, 3, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(3391, 2001, sprAmGirder, 1, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(3483, 1982, sprAmGirder, 7, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2770, 1980, sprAmGirder, 4, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2886, 2005, sprAmGirder, 1, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2698, 1891, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2843, 1891, sprAmGirder, 6, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2834, 1771, sprAmGirder, 5, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2706, 1771, sprAmGirder, 7, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2768, 1818, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(2768, 1899, sprAmGirder, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(1760, 1393, sprAmGirder, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)
	PlaceSprite(516, 1795, sprAmGirder, 4, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)

	------ RUBBER LIST ------
	PlaceSprite(2151, 1659, sprAmRubber, 3, U_LAND_TINT_NORMAL, nil, nil, nil, lfBouncy)
	PlaceSprite(2399, 1698, sprAmRubber, 3, U_LAND_TINT_NORMAL, nil, nil, nil, lfBouncy)
	PlaceSprite(2467, 1553, sprAmRubber, 2, U_LAND_TINT_NORMAL, nil, nil, nil, lfBouncy)
	PlaceSprite(2279, 1497, sprAmRubber, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfBouncy)
	PlaceSprite(2414, 1452, sprAmRubber, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfBouncy)
	PlaceSprite(1860, 1687, sprAmRubber, 1, U_LAND_TINT_NORMAL, nil, nil, nil, lfBouncy)

	------ SPRITE LIST ------
	PlaceSprite(1297, 1732, sprTargetBee, 0, U_LAND_TINT_NORMAL, nil, nil, nil, lfNormal)

	------ CRATE LIST ------
	crates[1] = SpawnHealthCrate(401, 1850)			-- Jumping
	crates[2] = SpawnHealthCrate(2639, 1973)		-- Final crate
	crates[3] = SpawnHealthCrate(1969, 1698)		-- Rubber
	crates[4] = SpawnHealthCrate(889, 1829)			-- Back Jumping
	crates[5] = SpawnHealthCrate(1486, 1694)		-- Walking on Ice
	crates[6] = SpawnHealthCrate(2033, 1470)		-- Walking on Ice completed
	crates[7] = SpawnHealthCrate(1198, 1750)		-- Back Jumping 2
	crates[8] = SpawnSupplyCrate(1851, 1402, amSwitch, 100)	-- Switch Hedgehog
	crates[9] = SpawnHealthCrate(564, 1772)			-- Health
	-- FIXME: Not available in touch because no “precise” button
	if INTERFACE ~= "touch" then
		crates[10] = SpawnHealthCrate(2290, 1622)		-- Turning Around
	end
end

local function victory()
	SaveMissionVar("Won", "true")
	ShowMission(loc("Basic Movement Training"), loc("Training complete!"),loc("Congratulations! You have completed the obstacle course!"), 0, 0)
	SendStat(siGameResult, loc("You have completed the Basic Movement Training!"))
	SendStat(siCustomAchievement, loc("Congratulations!"))
	SendStat(siCustomAchievement, loc("Return to the training menu by pressing the “Go back” button."))
	PlaySound(sndVictory, CurrentHedgehog)
	-- Disable controls, end game
	SetInputMask(0)
	SetWeapon(amNothing)
	SetGearMessage(CurrentHedgehog, band(GetGearMessage(CurrentHedgehog), bnot(gmAllStoppable)))
	EndGame()
	for i=1,#hhs do
		SetState(hhs[i], gstWinner)
	end
end

local function switchHedgehogText()
	if CurrentHedgehog == hog_cappy then
		ShowMission(loc("Basic Movement Training"), loc("Switch Hedgehog (3/3)"),
		loc("This is Cappy.").."|"..
		loc("To finish hedgehog selection, just do anything|with him, like walking."),
		2, 20000)
	else
		local ctrl = ""
		if INTERFACE == "desktop" then
			ctrl = loc("Hit the “Switch Hedgehog” key until you have|selected Cappy, the hedgehog with the cap!").."|"..
			loc("Switch hedgehog: [Tabulator]")
		else
			ctrl = loc("Tap the “rotating arrow” button on the left|until you have selected Cappy, the hedgehog with the cap!")
		end
		ShowMission(loc("Basic Movement Training"), loc("Switch Hedgehog (2/3)"),
		loc("You have activated Switch Hedgehog!").."|"..
		loc("The spinning arrows above your hedgehog show|which hedgehog is selected right now.").."|"..
		ctrl, 2, 20000)
	end
end

function onGearAdd(gear)
	if GetGearType(gear) == gtSwitcher then
		switcherGear = gear
		switchHedgehogText()
	end
end

function onGearDelete(gear)
	local ctrl = ""
	-- Switching done
	if GetGearType(gear) == gtSwitcher then
		switcherGear = nil
		if CurrentHedgehog == hog_cappy then
			ShowMission(loc("Basic Movement Training"), loc("Leap of Faith"),
			loc("Good! You now control Cappy.").."|"..
			loc("Collect the remaining crates to complete the training."),
			2, 0)
		else
			if INTERFACE == "desktop" then
				ctrl = loc("Open ammo menu: [Right click]").."|"..
				loc("Attack: [Space]")
			elseif INTERFACE == "touch" then
				ctrl = loc("Open ammo menu: Tap the [Suitcase]").."|"..
				loc("Attack: Tap the [Bomb]")
			end
			ShowMission(loc("Basic Movement Training"), loc("Switch Hedgehog (Failed!)"),
			loc("Oops! You have selected the wrong hedgehog! Just try again.").."|"..
			loc("Select “Switch Hedgehog” from the ammo menu and|hit the “Attack” key to proceed.").."|"..
			ctrl, 2, 0)
		end

	-- Crate collected (or destroyed, but this should not be possible)
	elseif gear == crates[1] then
		if INTERFACE == "desktop" then
			ctrl = loc("Long Jump: [Enter]")
		elseif INTERFACE == "touch" then
			ctrl = loc("Long Jump: Tap the [Curvy Arrow] button for long")
		end
		ShowMission(loc("Basic Movement Training"), loc("Jumping"),
		loc("Get the next crate by jumping over the abyss.").."|"..
		loc("Careful, hedgehogs can't swim!").."|"..
		ctrl, 2, 5000)
	elseif gear == crates[2] then
		victory()
	elseif gear == crates[4] then
		if INTERFACE == "desktop" then
			ctrl = loc("High Jump: [Backspace]").."|"..loc("Back Jump: [Backspace] ×2")
		elseif INTERFACE == "touch" then
			ctrl = loc("High Jump: Tap the [Curvy Arrow] shortly").."|"..loc("Back Jump: Double-tap the [Curvy Arrow]")
		end
		ShowMission(loc("Basic Movement Training"), loc("Back Jumping (1/2)"),
		loc("For the next crate, you have to do back jumps.") .. "|" ..
		loc("To reach higher ground, walk to a ledge, look to the left, then do a back jump.") .. "|" ..
		ctrl, 2, 6600)
	elseif gear == crates[7] then
		if INTERFACE == "desktop" then
			ctrl = loc("High Jump: [Backspace]").."|"..loc("Back Jump: [Backspace] ×2")
		elseif INTERFACE == "touch" then
			ctrl = loc("High Jump: Tap the [Curvy Arrow] shortly").."|"..loc("Back Jump: Double-tap the [Curvy Arrow]")
		end
		ShowMission(loc("Basic Movement Training"), loc("Back Jumping (2/2)"),
		loc("To get over the next obstacles, keep some distance from the wall before you back jump.").."|"..
		loc("Hint: To jump higher, wait a bit before you hit “High Jump” a second time.").."|"..
		ctrl, 2, 15000)
	elseif gear == crates[5] then
		-- FIXME: Touch doesn't have precise aim yet :(
		if INTERFACE == "desktop" then
			ctrl = "|" ..
			loc("You can also hold down the key for “Precise Aim” to prevent slipping.") .. "|" ..
			loc("Precise Aim: [Left Shift]")
		end
		ShowMission(loc("Basic Movement Training"), loc("Walking on Ice"),
		loc("These girders are slippery, like ice.").."|"..
		loc("And you need to move to the top!").."|"..
		loc("If you don't want to slip away, you have to keep moving!")..
		ctrl, 2, 9000)
	elseif gear == crates[6] then
		-- FIXME: Touch doesn't have precise aim yet :(
		if INTERFACE == "desktop" then
			ctrl = "|" .. loc("Remember: Hold down [Left Shift] to prevent slipping")
		end
		ShowMission(loc("Basic Movement Training"), loc("A mysterious Box"),
		loc("The next crate is an utility crate.").."|"..loc("What's in the box, you ask? Let's find out!")..
		ctrl, 2, 6000)
	elseif gear == crates[8] then
		if INTERFACE == "desktop" then
			ctrl = loc("Open ammo menu: [Right click]").."|"..
			loc("Attack: [Space]")
		elseif INTERFACE == "touch" then
			ctrl = loc("Open ammo menu: Tap the [Suitcase]").."|"..
			loc("Attack: Tap the [Bomb]")
		end
		ShowMission(loc("Basic Movement Training"), loc("Switch Hedgehog (1/3)"),
		loc("You have collected the “Switch Hedgehog” utility!").."|"..
		loc("This allows to select any hedgehog in your team!").."|"..
		loc("Select “Switch Hedgehog” from the ammo menu and|hit the “Attack” key.").."|"..
		ctrl, 2, 30000)
	elseif gear == crates[3] then
		ShowMission(loc("Basic Movement Training"), loc("Rubber"), loc("As you probably noticed, these rubber bands|are VERY elastic. Hedgehogs and many other|things will bounce off without taking any damage.").."|"..
		loc("Now try to get out of this bounce house|and take the next crate."), 2, 8000)
	elseif gear == crates[9] then
		if INTERFACE == "desktop" then
			ctrl = loc("Look around: [Mouse movement]") .. "|" ..
			loc("Zoom: [Rotate mouse wheel]")
		elseif INTERFACE == "touch" then
			ctrl = loc("Look around: [Tap or swipe on the screen]") .. "|" ..
			-- multi-touch gesture
			loc("Zoom: [Pinch] with 2 fingers")
		end
		ShowMission(loc("Basic Movement Training"), loc("Health"), loc("You just got yourself some extra health.|The more health your hedgehogs have, the better!").."|"..
		loc("The health of your current hedgehog|is shown at the top right corner.").."|"..
		loc("Now go to the next crate.").."|"..
		ctrl, 2, 11500)
	elseif gear == crates[10] then
		-- FIXME: This crate is unused in touch atm
		ShowMission(loc("Basic Movement Training"), loc("Turning Around"),
		loc("By the way, you can turn around without walking|by holding down Precise when you hit a walk control.").."|"..
		loc("Get the final crate to the right to complete the training.").."|"..
		loc("Turn around: [Left Shift] + [Left]/[Right]")
		, 2, 8000)
	end
end

function onGearDamage(gear)
	if GetGearType(gear) == gtHedgehog and tookDamage == false and GetX(gear) > 1362 then
		ShowMission(loc("Basic Movement Training"), loc("Fall Damage"), loc("Ouch! You just took fall damage.").."|"..
		loc("Better get yourself another health crate to heal your wounds."), 2, 5000)
		tookDamage = true
	end
end

function onSwitch()
	-- Update help while switching hogs
	if switcherGear then
		-- Delay for CurrentHedgehog to update
		switchTextDelay = 1
	end
end

local function firstMission()
	-- Here we teach player must know how to show the current mission texts again.
	-- We force the player to hit Attack before the actual training begins.
	-- Later, the mission panel key is perma-shown as caption.
	local ctrl = ""
	if INTERFACE == "desktop" then
		ctrl = loc("IMPORTANT: To see the mission panel again, hold the mission panel key.").."| |"..
		loc("Note: This basic training assumes default controls.").."|"..
		loc("Mission panel: [M]").."|"..
		loc("Quit: [Esc]").."|"..
		loc("Pause: [P]").."| |"..
		loc("To begin with the training, hit the attack key!").."|"..
		loc("Attack: [Space]")
	elseif INTERFACE == "touch" then
		ctrl = loc("IMPORTANT: To see the mission panel again, pause the game.").."| |"..
		loc("Pause: Tap the [Pause] button").."| |"..
		loc("To begin with the training, tap the attack button!").."|"..
		loc("Attack: Tap the [Bomb]")
	end
	ShowMission(loc("Basic Movement Training"), loc("Mission Panel"),
	loc("This is the mission panel.").."|"..
	loc("Here you will find the current mission instructions.").."|"..
	loc("Normally, the mission panel disappears after a few seconds.").."|"..
	ctrl, 2, 900000, true)

	-- TODO: This and other training missions are currently hardcoding control names.
	-- This should be fixed eventually.
end

function onGameTick20()
	if switchTextDelay > 0 then
		switchTextDelay = switchTextDelay - 1
	elseif switchTextDelay == 0 then
		switchHedgehogText()
		switchTextDelay = -1
	end
	if turnStarted and GameTime % 10000 == 0 and not missionPanelConfirmed then
		-- Forces the first mission panel to be displayed without time limit
		firstMission()
	end
	if missionPanelConfirmed then
		missionPanelConfirmedTimer = missionPanelConfirmedTimer + 20
		--[[ After confirming the initial mission panel,
		show the mission panel key as permanent caption
		so the player can't overlook or forget it. ]]
		if missionPanelConfirmedTimer > 7000 then
			if INTERFACE == "desktop" then
				AddCaption(loc("Press [M] to see the mission texts"), capcolDefault, capgrpMessage2)
			elseif INTERFACE == "touch" then
				AddCaption(loc("Tap [Pause] to see the mission texts"), capcolDefault, capgrpMessage2)
			end
		end
	end
end

function onGearResurrect(gear, vGear)
	AddCaption(loc("Your hedgehog has been revived!"))
	if gear == hog_cappy then
		SetGearPosition(gear, 404, 1714)
	elseif gear == hog_greenhorn then
		SetGearPosition(gear, 401, 1850)
	else
		-- Generic teleport to Rhombus' cage
		SetGearPosition(gear, 619, 1559)
	end
	if vGear then
		SetVisualGearValues(vGear, GetX(gear), GetY(gear))
	end
	FollowGear(gear)
end

function onNewTurn()
	SwitchHog(hog_greenhorn)
	FollowGear(hog_greenhorn)
	if not missionPanelConfirmed then
		turnStarted = true
		PlaySound(sndHello, hog_greenhorn)
		firstMission()
	end
end

function onAttack()
	if not missionPanelConfirmed then
		-- Mission panel confirmed, release controls
		PlaySound(sndPlaced)
		SetInputMask(0xFFFFFFFF)
		SetSoundMask(sndYesSir, false)
		PlaySound(sndYesSir, hog_greenhorn)
		-- First mission: How to walk
		ShowMission(loc("Basic Movement Training"), loc("First Steps"), loc("Complete the obstacle course.") .."|"..
		loc("To begin, walk to the crate to the right.").."|"..
		loc("Walk: [Left]/[Right]"), 2, 7000)
		missionPanelConfirmed = true
	end
end

function onGameStart()
	-- Disable input to force player to confirm first message
	SetInputMask(0)
	SetSoundMask(sndYesSir, true)
	LoadGearData()
	ShowMission(loc("Basic Movement Training"), loc("Basic Training"), loc("Complete the obstacle course."), 1, 0)
	FollowGear(hog_greenhorn)
end


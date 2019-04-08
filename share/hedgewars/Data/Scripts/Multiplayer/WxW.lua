
----------------------
-- WALL TO WALL 0.7
----------------------
-- a shoppa minigame
-- by mikade

-- feel free to add map specific walls to LoadConfig, or post additional
-- wall suggestions on our forum at: https://www.hedgewars.org/forum

----------------
--0.1
----------------
-- concept test

----------------
--0.2
----------------
-- unhardcoded turntimeleft, now uses shoppa default of 45s
-- changed some things behind the scenes
-- fixed oooooold radar bug
-- added radar / script support for multiple crates
-- tweaked weapons tables
-- added surfing and changed crate spawn requirements a bit

----------------
--0.3
----------------
-- stuffed dirty clothes into cupboard
-- improved user feedback
-- added/improved experimental config system, input masks included :D

----------------
--0.4
----------------
-- for version 0.9.18, now detects border in correct location
-- fix 0.3 config constraint
-- remove unnecessary vars
-- oops, remove hardcoding of minesnum,explosives
-- ... and unhardcode turntime (again)... man, 30s is hard :(
-- move some initialisations around
-- numerous improvements to user feedback
-- walls disappear after being touched
-- added backwards compatibility with 0.9.17

----------------
--0.5
----------------
-- Support for multiple sets of walls per map (instead of “all or nothing”)
-- Ropes, ShoppaKing, ShoppaHell and ShoppaNeon can now be played with the classic left and right walls
-- New wall sets for Ropes, ShoppaNeon, ShoppaDesert, ShoppaWild, ShoppaKing and ShoppaHell, and more.
-- Basic support for a bunch of Shoppa maps
-- Alternative configuration method with Script parameter
-- Possible to set max. number of weapons in game (script parameter only)
-- Possible to set number of crates per turn
-- Menu can be disabled (with script parameter) for insant game start
-- WxW is now fully functional even without a map border.
-- WxW now allows for almost all game modifiers and game settings to be changed
-- More sound effects
-- No smoke when hog is near near a WxW wall but Walls Before Crate rule is not in place
-- More readable mission display after configuration has been accepted
-- Hide “Surf Before Crate” setting if surfing is disabled for this map, or the bottom is active and water never rises
-- Hide walls setting if script does not provide walls for map yet
-- Bugfix: Other player was able to change the menu config in the short period before the first "turn"
-- Lots of refactoring

----------------
--0.6
----------------
-- Bugfix: 2 crates spawned at the 1st turn if script parameter was set to “menu=false, walls=none” or similar
-- Bugfix: Annoying faulty error message appeared when hitting attack when on a rope with a weapon selected


----------------
--0.7
----------------
-- To enforce the rules more strictly, all crates will be frozen at turn start if WBC or SBC rule is in place.
--	The crates are unfrozen if you met the crate criteria (that is, surfed and/or bounced off all walls).
--      Frozen crates can't be collected and appear as small white dots in the radar.
-- Add support for the “Crate Before Attack” rule
-- Add support for the “All But Last” rule
-- Add support for the “Kill The Leader” rule
-- Allow toggling crate radar with “switch hog” key while roping
-- The game continues now with the first team after the menu has been closed (rather than the second team)

----------------
--TODO
----------------
-- achievements / try detect shoppa moves? :|
-- maybe add ability for the user to place zones like in Racer?
-- add more hard-coded values for specific maps


--[[
# CONFIGURATION

By default, this script is easily configured via the in-game menu. The player of the first team can choose the rules and
required walls (or none at all). After accepted, the game will start with the second team (!).

= SCRIPT PARAMETER =

Using the script parameter is optional, it mostly is just an alternative way for configuration and for convenience
reasons, so often-used configurations can be saved and loaded.

The script parameter is specified as a comma-sperated list of “key=value” pairs (see examples below).

Truth values can be set true or false, and numeric values always use a whole number.

== Basic parameters ==

key		default	description
----------------------------------------
menu		true	Show configuration menu at the beginning. If no menu is used, a random wall set is used (see wall filters below)
SBC		false	Surf Before Crate: Player must bounce off the water (“surfing”) before crates can be collected
AFR		false	Attack From Rope: Players must attack from the rope. Weapons which can't be fired from rope are removed
CBA		false	Crate Before Attack: Player must collect at least one crate before attacking
attackrule	off	If present, enable one of the attack rules “ABL” or “KTL”:
			ABL: All But Last: Players must not only attack the team with the lowest total health
			KTL: Kill The Leader: If players hit some enemy hedgehog, at least one of them must be a hog from
			the team with the highest total health.
			The ABL and KTL rules exclude each other. If a player breaks the rule (if enabled), he must
			skip in the next round.
SW		false	Super Weapons: A few crates may contain very powerful weapons (melon, hellish grenade, RC plane, ballgun)
maxcrates	12	Number of crates which can be at maximum in the game (limited to up to 100 to avoid lag)
cratesperturn	1	Number of crates which appear each turn

== Advanced parameters ==

Wall filters: The following parameters allow you to filter out wall sets based on their type and number of walls.
If this is used together with the menu, the filtered wall sets can't be selected. Without a menu, the wall set
will be randomly selected among the wall sets that meet all criteria.

If the criteria filter out all available wall sets of the map, the game is played without the Walls Before Crate rule.

parameter	default	description
----------------------------------------
walls		N/A	

Permitted values:
- leftright:		The left and right part of the border. Traditional W2W-style.
- roof:			Only the top part of the border
- leftrightroof:	Combination of the two above
- inside:		Map-specific wall set where all walls are part of the terrain
- mixed:		Map-specific wall set where some walls are part of the terrain, and some are part of the map border
- none:			No walls required.
- all:			Shorthand: All wall sets are allowed.

Combination of multiple types is possible by concatenating the names with plus signs (see examples below).


Restrict wall numbers: With the following parameters you can restrict the pool of wall sets to only those with a certain
number of walls. Note that 2 walls are the most common type of wall set, as this is often available by default.

parameter	default	description
----------------------------------------
minwalls	N/A	Filter out wall sets with less than this
maxwalls	N/A	Filter out wall sets with more than this

wallsnum	N/A	Shorthand: Combintion of minwalls and maxwalls if they are the equal.


== Examples ==


SBC=true
--> Keep the menu, enable Surf Before Crate by default (if available).

SBC=true, menu=false
--> Enable Surf Before Crate (if available) and use the defaul walls set.

AFR=true, menu=false, wallsnum=2
--> Attack From Rope rule active, and use a random wall set with 2 walls

menu=false, walls=leftright
--> Always use the classic left/right wall set automatically. Traditional W2W-style.

walls=none, menu=false
--> Like classic Shoppa

walls=leftright+inside+mixed, menu=false
--> Randomly use either the left/right wall set, an Inside or Mixed wall set.



= MORE GAME SCHEME CONFIGURATION =
You can almost set everything in the game scheme freely, and the script will work just fine together with it.
Feel free to experiment a bit.
The only exception are the crate frequencies. Setting them has no effect, crates are handled uniquiely in this game.

At this stage, the script does not allow for custom weapon sets.
]]



-----------------------------
-- GO PONIES, GO PONIES, GO!
-----------------------------

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

-- HARDCODED values
local ammoTypesNum = 58	-- number of weapon types (permanent TODO: Check this number for each Hedgewars version)
local PlacementTime = 15000

-- menu stuff
local menuIndex = 1
local menu = {}
local preMenuCfg
local postMenuCfg

--[[ WxW preparation phase.
0 = Game not started yet
1 = Configuration phase
2 = Hedgehog placement phase
100 = Game phase
]]
local roundN = 0

-- Used to select one of the wall sets
-- 0: no walls
-- 1 and above: ID of wall sets
local wallSetID = 0

-- Store the wall sets here
local wallSets = {}

-- Wall set types and wall number limits for filtering
local allWallSetTypes = {"roof", "leftright", "leftrightroof", "mixed", "inside"}
local allowedWallSetTypes = {roof=true, leftright=true, leftrightroof=true, mixed=true, inside=true}
local minWalls, maxWalls = nil, nil

-- config and wall variables
local useMenu = true
local AFR = false		-- Attack From Rope
local WBC = true		-- Wall(s) Before Crate, will later only be set again in script parameter
local CBA = false		-- Crate Before Attack
local attackRule = nil		-- Either nil, "KTL" (Kill The Leader) or "ABL" (All But Last)
local allowCrazyWeps = false	-- Super weapons
local requireSurfer = false	-- Surf Before Crate
local crateSpawned = false	-- Has the crate (or crates) been spawned in this turn yet?
local cratesPerTurn = 1		-- How many crates appear per turn (respects crate limit)
local maxCrates = 12		-- default crate limit, can be configured with params
local maxCratesHard = 100	-- "hard" crate limit, to avoid extreme lagging due to many crates
local crateGearsInGame = 0
local wX = {}
local wY = {}
local wWidth = {}
local wHeight = {}
local wTouched = {}
local wallsLeft = 0

local hasSurfed = false
local allWallsHit = false
local crateCollected = false

-- ABL and KTL stuff
local teamNames = {}		-- List of all teams
local teamsAttacked = {}	-- List of attacked teams (in this turn)
local lastTeam = nil		-- Team with the least health. Determined only at start of turn. If it's a tie, use nil.
local leaderTeam = nil		-- Team with the most health. Determined only at start of turn. If it's a tie, use nil.
local runnerUpTeam = nil	-- Team with the second-most health
local previousTeam = nil	-- Remember the name of the team in the previous turn

local gTimer = 1
local effectTimer = 1

local ropeG = nil
local allowCrate = true
local crates = {}

-- Variables for place hedgehogs mode
local hogCount = 0		-- Used to detect the end of the hog placement phase
local turnsCount = 0

-- crate radar vars

-- Set the initial radar mode here
-- 0: Radar is always active
-- 1: Radar is only active shortly after crate spawn
-- 2: Radar is disabled
local radarMode = 0

local rCirc = {}
local rAlpha = 255
local rPingTimer = 0
local m2Count = 0

local weapons = {}

local crazyWeps = {amWatermelon, amHellishBomb, amBallgun, amRCPlane}

local groundWeps = 	{amBee, amShotgun,amDEagle,amFirePunch, amWhip,
				amPickHammer, amBaseballBat, amCake,amBallgun,
				amRCPlane, amSniperRifle, amBirdy, amBlowTorch,
				amFlamethrower, amMortar, amHammer}

local ropeWeps = {amGrenade, amClusterBomb, amBazooka, amMine, amDynamite,
				amWatermelon, amHellishBomb, amDrill, amMolotov,
				amSMine, amGasBomb}

local msgColorTech = 0xFFBA00FF
local msgColorWarn = 0xFF4000FF

-- 0.9.18+ extra custom data for preset maps
local MapList =
	{
	--name,					surfer, roof, 	LRwalls
	{"Alien",				true, 	true,  true},
	{"Atlantis Shoppa",			true, 	true,  true},
	{"BasketballField",			false,  false, false},
	{"BattleCity_v1",			true,	true, true},
	{"BIGshoppa",				true,	true, true},
	{"BambooPlinko",			true,	false, true},
	{"BoatWxW",				true,	true,  true},
	{"BrickShoppa",				false, 	false, true},
	{"BubbleFlow",				true, 	false, true},
	{"Citrouille",				true, 	true,  true},
	{"Cave",				false, 	false, true},
	{"Cheese_Ropes", 			false, 	true,  true},
	{"CookieShoppa", 			true, 	false, true},
	{"CrossRopes",				false,	false, true},
	{"FutuShoppa",				true,	false, true},
	{"Garden",				false,	false, true},
	{"Glass Shoppa",			true, 	false, true},
	{"GlassShoppa2",			true, 	false, true},
	{"HardIce",      			false, 	false, true},
	{"Industrial",       			false,	false, true},
	{"Islands",       			true, 	false, true},
	{"IslandsFlipped",     			true, 	false, true},
	{"IslandsRearranged",  			true, 	false, true},
	{"Hedgelove",       			true, 	false, true},
	{"HellishRopes",       			false, 	false, true},
	{"Hedgeland_v1",			true,	false, true},
	{"HeyLandShoppa",			false,	false, true},
	{"NeonStyle",       			false, 	false, true},
	{"MaskedRopes",       			false, 	false, true},
	{"Octorama",       			false, 	false, true},
	{"Octoropisloppaking0.4",		true,   true,  true},
	{"Pacman_v2",       			true,   false, true},
	{"Purple",       			false, 	true,  true},
	{"Purple_v2",       			false, 	true,  true},
	{"RacerPlayground1",			false,  true,  true},
	{"RacerPlayground2",			false,  true,  true},
	{"RacerPlayground3",			false,  true,  true},
	{"RacerPlayground4",			false,  true,  true},
	{"red vs blue - Castle",     		true, 	false, true},
	{"red vs blue - castle2",     		true, 	false, true},
	{"red vs blue - True Shoppa Sky",	true,	false, true},
	{"Ropes",       			false, 	true, true},
	{"RopeLikeAKingInHellWithNeon",		false, 	true,  true},
	{"Ropes Flipped",      			false, 	false, true},
	{"Ropes Rearranged",      		false, 	false, true},
	{"RopesRevenge0.1",    			false, 	true,  true},
	{"RopesRevenge Flipped",    		true, 	false, true},
	{"RopesThree",      			false, 	false, true},
	{"RopesTwo",      			false, 	false, true},
	{"Ruler",	      			false, 	false, true},
	{"SandShoppa",				false,	false, true},
	{"ShapeShoppa1.0",     			true, 	false, true},
	{"ShapeShoppa Darkhow",      		true, 	false, true},
	{"SheepyShoppa_v2",      		true, 	false, true},
	{"shopppa",				false,  true,  true},
	{"ShoppaCave2",      			true, 	false, true},
	{"ShoppaChallenge",    			false, 	true, true},
	{"ShoppaDesert",    			false, 	false, true},
	{"ShoppaEvoRope_v1",			true, 	false, true},
	{"ShoppaFun",      			true, 	false, true},
	{"ShoppaFun2",      			true, 	false, true},
	{"ShoppaGolf",      			false, 	false, true},
	{"ShoppaHalloween",    			false, 	false, true},
	{"ShoppaHell",      			false,	true,  false},
	{"ShoppaHellFlipped",  			true,	true,  false},
	{"ShoppaHellRemake",			false,	true,  false},
	{"ShoppaKing",       			false, 	true, false},
	{"ShoppaKingFlipped",      		true, 	false, false},
	{"ShoppaKingSideways",      		true, 	true,  false},
	{"ShoppaMeme",				false,	true, false},
	{"ShoppaNeon",       			false, 	false, true},
	{"ShoppaNeonFlipped",			true, 	false, true},
	{"ShoppaOnePiece2",			false, 	true, false},
	{"ShoppaQuotes2",			false,  true,  true},
	{"ShoppaRainbow",			false,  false, false},
	{"ShoppaRadigme",			false,  true,  true},
	{"ShoppaSilhouette",			false,  false, true},
	{"ShoppaSpace",				true,   false, true},
	{"ShoppaSea",				true,  false, false},
	{"ShoppaShapex_v1",			false,  true, true},
	{"ShoppaSparkle",			true,  true, true},
	{"ShoppaSky",				false,  false, true},
	{"ShoppaSky2",				true,  false, true},
	{"ShoppaSsion",				false,  false, true},
	{"ShoppaStyle2",			true,  false, true},
	{"ShoppaThology",			false,  false, true},
	{"ShoppaTournament2012",		false,  false, true},
	{"ShoppaWild",				false,  false, true},
	{"Shoppawall",				false,  false, false},
	{"ShoppaWall2",				false,  false, false},
	{"ShBall",				false,  true, false},
	{"ShHell",				false,  true, false},
	{"ShNeon",       			false, 	false, true},
	{"ShoppaSky",       			false, 	false, true},
	{"SloppyShoppa",       			false, 	true,  true},
	{"SloppyShoppa2",      			false, 	true,  true},
	{"SkatePark",       			false, 	true,  true},
	{"Snow_Ropes",       			false, 	true, false},
	{"Sticks",       			true, 	false, true},
	{"Symmetrical Ropes",       		false, 	false, true},
	{"SpartanShoppa",       		false, 	true,  true},
	{"TERRORmap",				false,  false,false},
	{"Tetris",       			false, 	false, true},
	{"TransRopes2",      			false, 	false, true},
	{"TRBShoppa",      			false, 	false, true},
	{"TrickyShoppa",      			false, 	true, false},
	{"Towers",      			false, 	true,  true},
	{"Wildmap",      			false, 	false, true},
	{"Winter Shoppa",      			false, 	false, true},
	{"WarShoppa",      			false, 	true,  true},
	{"2Cshoppa",      			true, 	false, true},
	}

local Ropes_WallSet = {
	{ add="none", {299,932,20,856}, {4056,0,30,1788} },
	{ add="none", {299,109,20,779}, {4056,0,30,1788} },
	{ add="none", {299,109,20,779}, {299,932,20,856}, {4056,0,30,1788} },
	{ add="default", {2253,326,20,574}, {3280,326,33,253}, needsborder=false },
	{ add="roof", {2322,326,457,20} },
	{ add="default", {1092,934,54,262}, {2822,323,33,137}, needsborder=false },
	{ add="none", {203,1193,20,595}, {3280,326,20,253}, needsborder=false },
}
local Shoppawall_WallSet = {
	{ add="none", {80+290,61+878,20,1018}, {3433+290,61+878,20,1018}, default=true, needsborder=false },
}

-- List of map with special wall settings
local SpecialMapList = {
	["Ropes"] = Ropes_WallSet,
	["HellishRopes"] = Ropes_WallSet,
	["MaskedRopes"] = Ropes_WallSet,
	["TransRopes2"] = Ropes_WallSet,
	["ShoppaKing"] = {
		{ add="none", {3777,1520,50,196}, {1658,338,46,670}, needsborder=false },
		{ add="none", {125,0,30,2048}, {4066,515,30,1528}, default=true},
	},
	["ShoppaHell"] = {
		{ add="none", {3491,697,30,1150}, {0,0,30,1847}, default=true},
		{ add="none", {3810,0,30,1616}, {0,0,30,1847}, },
		{ add="none", {2045,832,20,260}, {2107,832,20,260}, needsborder=false },
		{ add="default", {2035,831,30,263}, {3968,1668,31,383}, needsborder=false },
	},
	["ShoppaNeon"] = {
		{ add="default", {980,400,20,300}, {1940,400,20,300}, {3088,565,26,284}, {187,270,28,266}, needsborder=false },
	},
	["Shoppawall"] = Shoppawall_WallSet,
	["ShoppaWall2"] = Shoppawall_WallSet,
	["ShoppaDesert"] = {
		{ add="none", {2322,349,20,471}, {295,93,24,1479}, needsborder=false },
		{ add="none", {3001,1535,20,232}, {2264,349,20,495},{716,696,20,119}, needsborder=false },
		{ add="leftright", {209,656,20,367},{2810,838,20,96}, needsborder=false},
		{ add="none", {2649,0,445,20}, {2322,349,947,20},{299,696,381,20}},
	},
	["ShoppaOnePiece2"] = {
		{ add="default", {42,0,20,2048}, {4048,0,20,2048}, needsborder=false, },
		{ add="default", {42,0,20,2048}, {3852,273,20,1637}, needsborder=false, default="noborder" },
	},
	["ShoppaWild"] = {
		{ add="default", {2123,1365,20,293}, {3102,1365,20,293}, {1215,1391,20,291}, needsborder=false },
		{ add="none", {144,167,1904,20}, {2350,167,753,20}, {3793,167,303,20}, needsborder=false},
	},
	["ShoppaRainbow"] = {
		{ add="none", {67+602,61+80,20,1847}, {2779+602,61+80,20,1847}, needsborder=false },
	},
}

function BoolToCfgTxt(p)
	if p == false then
		return loc("Disabled")
	else
		return loc("Enabled")
	end
end

function AttackRuleToCfgTxt(attackRule)
	if attackRule == nil then
		return loc("Disabled")
	elseif attackRule == "ABL" then
		return loc("All But Last")
	elseif attackRule == "KTL" then
		return loc("Kill The Leader")
	else
		return "ERROR"
	end
end

function NewWallSet(newWallSet, wType)
	-- Filter out wall sets which are not in allowed categories or have too many or few walls
	if allowedWallSetTypes[wType] == true then
		local inBounds = true
		if minWalls ~= nil and #newWallSet < minWalls then
			inBounds = false
		end
		if maxWalls ~= nil and #newWallSet > maxWalls then
			inBounds = false
		end
		if inBounds then
			table.insert(wallSets, newWallSet)
		end
	end
end

function MapsInit()
	mapID = nil
	margin = 20

	--0.9.18+
	for i = 1, #MapList do
		if Map == MapList[i][1] then
			mapID = i
		end
	end

	-- Border conditions
	-- Just a wrapper for MapHasBorder()
	local border = MapHasBorder() == true
	-- Left and right walls are available
	local leftRight = (WorldEdge == weBounce) or (WorldEdge == weNone and border)

	local left, right, roof

	local startY, height
	if (not border) and (WorldEdge == weBounce) then
		-- Higher left/right walls for bouncy world edge without roof
		local h = math.max(1024, LAND_HEIGHT)
		height = h * 2
		startY = TopY - h
	else
		-- Standard left/right wall height
		height = WaterLine
		startY = TopY + 10
	end
	left = {LeftX+10, startY, margin, height}
	right = {RightX-10-margin, startY, margin, height}
	roof = {LeftX+10, TopY+10, RightX-LeftX-20, margin}

	if mapID ~= nil then
		if border and MapList[mapID][3] == true then
			NewWallSet({roof, desc=loc("Roof")}, "roof")
			wallSetID = #wallSets
		end
		if leftRight and MapList[mapID][4] == true then
			NewWallSet({left, right, desc=loc("Left and right")}, "leftright")
			wallSetID = #wallSets
		end
		if leftRight and border and MapList[mapID][3] == true and MapList[mapID][4] == true then
			NewWallSet({left, right, roof, desc=loc("Left, right and roof")}, "leftrightroof")
		end

		-- add map specific walls
		if SpecialMapList[Map] ~= nil then
			local insideID = 1
			local previousInside = nil
			local mixedID = 1
			local previousMixed = nil

			-- Helper function to build the wall set name.
			-- Basically just to ensure that names like "Inside 1" are only used when there are at least 2 "Insides"
			local function newInsideOrMixed(ws, previous_ws, id, string, stringD)
				if id == 1 then
					ws.desc = string
				else
					ws.desc = string.format(stringD, id)
				end
				if id == 2 then
					previous_ws.desc = string.format(stringD, id-1)
				end
				id = id + 1
				previous_ws = ws
				return id, previous_ws
			end
			for ws=1,#SpecialMapList[Map] do
				local walls = SpecialMapList[Map][ws]
				if walls.needsborder == false then
					local newwallset2 = {}
					for w=1,#walls do
						table.insert(newwallset2, walls[w])
					end
					insideID, previousInside = newInsideOrMixed(newwallset2, previousInside, insideID, loc("Inside"), loc("Inside %d"))
					newwallset2.custom = true
					NewWallSet(newwallset2, "inside")
					if SpecialMapList[Map][ws].default == "noborder" then
						wallSetID = #wallSets
					end
				end
				local newwallset = {}
				if border and leftRight and walls.add == "all" then
					table.insert(newwallset, roof)
					table.insert(newwallset, left)
					table.insert(newwallset, right)
				elseif walls.add == "default" then
					if border and MapList[mapID][3] == true then
						table.insert(newwallset, roof)
					end
					if leftRight and MapList[mapID][4] == true then
						table.insert(newwallset, left)
						table.insert(newwallset, right)
					end
				elseif border and walls.add == "roof" then
					table.insert(newwallset, roof)
				elseif leftRight and walls.add == "leftright" then
					table.insert(newwallset, left)
					table.insert(newwallset, right)
				end
				for w=1,#walls do
					table.insert(newwallset, walls[w])
				end
				if border and leftRight and ((walls.add ~= "none" and walls.add ~= nil) or walls.needsborder ~= false) then
					mixedID, previousMixed = newInsideOrMixed(newwallset, previousMixed, mixedID, loc("Mixed"), loc("Mixed %d"))
					newwallset.custom = true
					NewWallSet(newwallset, "mixed")
				end
				if SpecialMapList[Map][ws].default == true then
					wallSetID = #wallSets
				end
			end
		end

	else
		if border then
			NewWallSet({roof, desc=loc("Roof")}, "roof")
			wallSetID = #wallSets
		end
		if leftRight then
			NewWallSet({left, right, desc=loc("Left and right")}, "leftright")
			wallSetID = #wallSets
		end
		if leftRight and border then
			NewWallSet({left, right, roof, desc=loc("Left, right and roof")}, "leftrightroof")
		end
	end

	-- Choose random map when without without menu
	if useMenu == false and #wallSets > 0 then
		wallSetID = GetRandom(#wallSets)+1
	end
	-- Select first wall set by default if we still haven't selected anything for some reason
	if wallSetID == 0 and #wallSets > 0 then
		wallSetID = 1	
	end
	-- But disabled walls from script parameter have higher priority
	if WBC == false then
		wallSetID = 0
	end

	if CanSurf() == false then
		requireSurfer = false
	end
end

function LoadConfig(p)
	ClearWalls()
	if p > 0 then
		local walls = wallSets[p]
		for i=1,#walls do
			AddWall(walls[i][1], walls[i][2], walls[i][3], walls[i][4])
		end
	end

end

function AddWall(zXMin,zYMin, zWidth, zHeight)

	table.insert(wX, zXMin)
	table.insert(wY, zYMin)
	table.insert(wWidth, zWidth)
	table.insert(wHeight, zHeight)
	table.insert(wTouched, false)

end

function ClearWalls()

	wX = {}
	wY = {}
	wWidth = {}
	wHeight = {}
	wTouched = {}

end

-- Draw a single point for the crate radar
function DrawBlip(gear)
	if GetGearType(gear) ~= gtCase then
		return
	end

	local baseColor, radius, alpha
	if CurrentHedgehog == nil or band(GetState(CurrentHedgehog), gstHHDriven) == 0 then
		radius = 40
		baseColor = 0xFFFFFFFF
		alpha = 255
	elseif getGearValue(gear, "frozen") then
		radius = 25
		baseColor = 0xFFFFFFFF
		alpha = math.min(255, rAlpha+127)
	else
		radius = 40
		baseColor = GetClanColor(GetHogClan(CurrentHedgehog))
		alpha = rAlpha
	end
	if getGearValue(gear,"CIRC") ~= nil then
		SetVisualGearValues(getGearValue(gear,"CIRC"), getGearValue(gear,"RX"), getGearValue(gear,"RY"), 100, 255, 1, 10, 0, radius, 3, baseColor-alpha)
	end
end

function TrackRadarBlip(gear)
	if GetGearType(gear) ~= gtCase then
		return
	end

	-- work out the distance to the target
	g1X, g1Y = GetGearPosition(CurrentHedgehog)
	g2X, g2Y = GetX(gear), GetY(gear)
	q = g1X - g2X
	w = g1Y - g2Y
	r = math.sqrt( (q*q) + (w*w) )	--alternate

	RCX = getGearValue(gear,"RX")
	RCY = getGearValue(gear,"RY")

	rCircDistance = r -- distance to circle

	opp = w
	if opp < 0 then
		opp = opp*-1
	end

	-- work out the angle (theta) to the target
	t = math.deg ( math.asin(opp / r) )

	-- based on the radius of the radar, calculate what x/y displacement should be
	NR = 150 -- radius at which to draw circs
	NX = math.cos( math.rad(t) ) * NR
	NY = math.sin( math.rad(t) ) * NR

	if rCircDistance < NR then
		RCX = g2X
	elseif q > 0 then
		RCX = g1X - NX
	else
		RCX = g1X + NX
	end

	if rCircDistance < NR then
		RCY = g2Y
	elseif w > 0 then
		RCY = g1Y - NY
	else
		RCY = g1Y + NY
	end

	setGearValue(gear, "RX", RCX)
	setGearValue(gear, "RY", RCY)

end


function HandleCircles()

	if radarMode == 0 then
		rAlpha = 0
	elseif radarMode == 1 then
		-- Only show radar for a short time after a crate spawn
		if rAlpha ~= 255 then
			rPingTimer = rPingTimer + 1
			if rPingTimer == 100 then
				rPingTimer = 0
	
				rAlpha = rAlpha + 5
				if rAlpha >= 255 then
					rAlpha = 255
				end
			end
		end
	elseif radarMode == 2 then
		rAlpha = 255
	end

	runOnGears(DrawBlip)

	m2Count = m2Count + 1
	if m2Count == 25 then
		m2Count = 0

		if (CurrentHedgehog ~= nil) and (rAlpha ~= 255) then
			runOnGears(TrackRadarBlip)
		end

	end

end

-- Returns true if crates are allowed to be accessed right now (used for unfreezing and spawning)
function AreCratesUnlocked()

	local crateSpawn = true

	if requireSurfer == true then
		if hasSurfed == false then
			crateSpawn = false
		end
	end

	if #wTouched > 0 then
		if allWallsHit == false then
			crateSpawn = false
		end
	end

	return crateSpawn

end

-- Freeze all crates,
function FreezeCrates()

	local cratesFrozen = 0
	for crate, isCrate in pairs(crates) do
		local state = GetState(crate)
		-- Freeze crate if it wasn't already frozen
		if band(state, gstFrozen) == 0 then
			cratesFrozen = cratesFrozen + 1
			SetState(crate, bor(GetState(crate), gstFrozen))
			setGearValue(crate, "frozen", true)
		end
	end
	-- Play sound if at least one new (!) crate was frozen
	if cratesFrozen > 0 then
		PlaySound(sndHogFreeze)
	end

end

-- Unfreeze all crates
function UnfreezeCrates()

	for crate, isCrate in pairs(crates) do
		SetState(crate, band(GetState(crate), bnot(gstFrozen)))
		setGearValue(crate, "frozen", false)
	end

end

function onCaseDrop()
	if roundN == 100 then
		allowCrate = crateGearsInGame < maxCrates
		CheckCrateConditions()
	end
end

function CheckCrateConditions()

	local crateSpawn = AreCratesUnlocked()

	if crateSpawn == true and crateSpawned == false then
		UnfreezeCrates()
		if allowCrate == true then
			local cratesInGame = crateGearsInGame
			local toSpawn = cratesPerTurn
			if cratesInGame + toSpawn > maxCrates then
				toSpawn = maxCrates - cratesInGame
			end
			for i=1,toSpawn do
				SpawnSupplyCrate(0, 0, weapons[1+GetRandom(#weapons)] )
			end
			rPingTimer = 0
			rAlpha = 0
			if toSpawn > 0 then
				PlaySound(sndWarp)
			end
		end
	end

end

function onGearWaterSkip(gear)
	if gear == CurrentHedgehog then
		hasSurfed = true
		AddCaption(loc("Surfer!"), capcolDefault, capgrpMessage2)
	end
end


function WallHit(id, zXMin,zYMin, zWidth, zHeight)

	if wTouched[id] == false then
		AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtBigExplosion, 0, false)
		PlaySound(sndExplosion)
		wallsLeft = wallsLeft - 1

		if wallsLeft == 0 then
			AddCaption(loc("All walls touched!"))
			allWallsHit = true
			if (requireSurfer == true) and (hasSurfed == false) then
				AddCaption(loc("Go surf!"), capcolDefault, capgrpMessage2)
			end
		else
			AddCaption(string.format(loc("Walls left: %d"), wallsLeft))
		end

	end

	wTouched[id] = true
	if #wTouched > 0 then
		AddVisualGear(GetX(CurrentHedgehog), GetY(CurrentHedgehog), vgtSmoke, 0, false)
	end

end

function CheckForWallCollision()

	for i = 1, #wTouched do
		if gearIsInBox(CurrentHedgehog, wX[i],wY[i],wWidth[i],wHeight[i]) then
			WallHit(i, wX[i],wY[i],wWidth[i],wHeight[i])
		end
	end

end

function BorderSpark(zXMin,zYMin, zWidth, zHeight, bCol)

	local size = zWidth * zHeight
	-- Add multiple sparks for very large walls
	sparkRuns = math.min(10, math.max(1, div(size, 10240)))
	for i=1, sparkRuns do
		local eX = zXMin + GetRandom(zWidth+10)
		local eY = zYMin + GetRandom(zHeight+10)

		local tempE = AddVisualGear(eX, eY, vgtDust, 0, false)
		SetVisualGearValues(tempE, eX, eY, nil, nil, nil, nil, nil, 1, nil, bCol )
	end

end


function HandleBorderEffects()

	if CurrentHedgehog == nil or band(GetState(CurrentHedgehog), gstHHDriven) == 0 then
		return
	end
	effectTimer = effectTimer + 1
	if effectTimer > 15 then --25

		effectTimer = 1

		for i = 1, #wTouched do
			if wTouched[i] == false then
				bCol = GetClanColor(GetHogClan(CurrentHedgehog))
				BorderSpark(wX[i],wY[i],wWidth[i],wHeight[i], bCol)
			end
		end

	end

end

function PlaceWarn()
	PlaySound(sndDenied)
	AddCaption(loc("Please place your hedgehog first!"), msgColorWarn, capgrpMessage2)
end

function onLJump()
	if roundN == 1 then
		PlaySound(sndPlaced)
		SetInputMask(0xFFFFFFFF)
		AddCaption(loc("Configuration accepted."), msgColorTech, capgrpMessage)
		if GetGameFlag(gfPlaceHog) then
			SetTurnTimeLeft(PlacementTime)
			AddAmmo(CurrentHedgehog, amTeleport, 100)
			SetWeapon(amTeleport)
			AddCaption(
				string.format(loc("%s, place the first hedgehog!"), GetHogTeamName(CurrentHedgehog)),
				0xFFFFFFFF,
				capgrpMessage2
			)
			roundN = 2
		else
			SetTurnTimeLeft(TurnTime)
			AddCaption(string.format(loc("Let's go, %s!"), GetHogTeamName(CurrentHedgehog)), capcolDefault, capgrpMessage2)
			roundN = 100
			wallsLeft = #wTouched
			allowCrate = true
		end
		PlaySound(sndYesSir, CurrentHedgehog)
		FinalizeMenu()
	elseif roundN == 2 then
		PlaceWarn()
	elseif roundN == 100 then
		if CBA and not crateCollected then
			if (GetCurAmmoType() ~= amRope) and
				(GetCurAmmoType() ~= amSkip) and
				(GetCurAmmoType() ~= amNothing) and
				(ropeG ~= nil)
			then
				AddCaption(loc("You must first collect a crate before you attack!"), msgColorWarn, capgrpMessage2)
				PlaySound(sndDenied)
			end
		end
	end
end

function onAttack()
	if roundN == 1 then
		if menu[menuIndex].activate ~= nil then
			menu[menuIndex].activate()
		else
			menu[menuIndex].doNext()
		end

		UpdateMenu()
		configureWeapons()
		HandleStartingStage()

		PlaySound(sndSwitchHog)

	elseif roundN == 2 then
		if GetCurAmmoType() ~= amSkip and GetCurAmmoType() ~= amNothing then
			PlaceWarn()
		end

	elseif roundN == 100 then
		local weaponSelected = (GetCurAmmoType() ~= amRope) and
			(GetCurAmmoType() ~= amSkip) and
			(GetCurAmmoType() ~= amNothing) and
			(ropeG == nil)

		if weaponSelected then
			if AFR and CBA and not crateCollected then
				AddCaption(loc("You must attack from a rope, after you collected a crate!"), msgColorWarn, capgrpMessage2)
				PlaySound(sndDenied)
			elseif AFR then
				AddCaption(loc("You may only attack from a rope!"), msgColorWarn, capgrpMessage2)
				PlaySound(sndDenied)
			elseif CBA and not crateCollected then
				AddCaption(loc("You must first collect a crate before you attack!"), msgColorWarn, capgrpMessage2)
				PlaySound(sndDenied)
			end
		end
	end
end

function onSwitch()
	-- Must be in-game, hog must be controlled by player and hog must be on rope or have rope selected
	if roundN == 100 and CurrentHedgehog ~= nil and band(GetState(CurrentHedgehog), gstHHDriven) ~= 0 and (ropeG ~= nil or GetCurAmmoType() == amRope) then
		-- Toggle radar mode
		radarMode = radarMode + 1
		if radarMode > 2 then
			radarMode = 0
		end
		local message
		if radarMode == 0 then
			message = loc("Radar: On")
		elseif radarMode == 1 then
			message = loc("Radar: Show after crate drop")
		elseif radarMode == 2 then
			message = loc("Radar: Off")
		end
		AddCaption(message, GetClanColor(GetHogClan(CurrentHedgehog)), capgrpAmmostate)
		-- Remember the radar mode for this team to restore it on the team's next turn
		setTeamValue(GetHogTeamName(CurrentHedgehog), "radarMode", radarMode)
	end
end

function onLeft()
	if roundN == 1 then
		if menu[menuIndex].doPrev ~= nil then
			menu[menuIndex].doPrev()
		else
			menu[menuIndex].activate()
		end

		UpdateMenu()
		configureWeapons()
		HandleStartingStage()

		PlaySound(sndSwitchHog)
	end
end

function onRight()
	if roundN == 1 then
		if menu[menuIndex].doNext ~= nil then
			menu[menuIndex].doNext()
		else
			menu[menuIndex].activate()
		end

		UpdateMenu()
		configureWeapons()
		HandleStartingStage()

		PlaySound(sndSwitchHog)
	end
end

function onDown()
	if roundN == 1 then
		PlaySound(sndSteps)
		menuIndex = menuIndex +1
		if menuIndex > #menu then
			menuIndex = 1
		end
		HandleStartingStage()
	end
end

function onUp()
	if roundN == 1 then
		PlaySound(sndSteps)
		menuIndex = menuIndex -1
		if 	menuIndex == 0 then
			menuIndex = #menu
		end
		HandleStartingStage()
	end
end

function parseBool(key, default)
	if params[key]=="true" then
		return true
	elseif params[key]=="false" then
		return false
	else
		return default
	end
end

function parseInt(key, default, min, max)
	local num = tonumber(params[key])
	if type(num) ~= "number" then
		return default
	end
	if min ~= nil then
		num = math.max(min, num)
	end
	if max ~= nil then
		num = math.min(max, num)
	end
	return num
end

function onParameters()
	parseParams()
	local tmpParam
	useMenu = parseBool("menu", useMenu)
	requireSurfer = parseBool("SBC", requireSurfer)
	AFR = parseBool("AFR", AFR)
	CBA = parseBool("CBA", CBA)
	if params["attackrule"] == "ABL" then
		attackRule = "ABL"
	elseif params["attackrule"] == "KTL" then
		attackRule = "KTL"
	end
	allowCrazyWeps = parseBool("SW", allowCrazyWeps)
	maxCrates = parseInt("maxcrates", maxCrates, 1, maxCratesHard)
	cratesPerTurn = parseInt("cratesperturn", cratesPerTurn, 1, maxCrates)
	local wallsParam = params["walls"]
	local wallsParamSelection = false
	if wallsParam ~= nil then
		if wallsParam == "all" then
			wallsParamSelection = true
			allowedWallSetTypes = {}
			for i=1,#allWallSetTypes do
				allowedWallSetTypes[allWallSetTypes[i]] = true
			end
		elseif wallsParam == "none" then
			WBC = false
			allowedWallSetTypes = {}
		else
			wallsParamSelection = true
			allowedWallSetTypes = {}
			local parsedWords = {}
			for k,v in string.gmatch(wallsParam, "(%w+)") do
				table.insert(parsedWords, k)
			end
			for i=1,#allWallSetTypes do
				for j=1,#parsedWords do
					if allWallSetTypes[i] == parsedWords[j] then
						allowedWallSetTypes[allWallSetTypes[i]] = true
					end
				end
			end
		end
	end

	-- Upper and lower bounds
	local wallsNum = parseInt("wallsnum", nil, 0)
	if wallsNum == 0 then
		WBC = false
	end
	minWalls = wallsNum
	maxWalls = wallsNum
	-- minwalls and maxwalls take precedence over wallsnum
	minWalls = parseInt("minwalls", minWalls, 1)
	maxWalls = parseInt("maxwalls", maxWalls, 1)
end

function onGameInit()

	HealthCaseProb = 0
	CaseFreq = 0
	SetAmmoDescriptionAppendix(amRope, loc("Switch: Toggle crate radar"))

end

function configureWeapons()

	-- reset wep array
	for i = 1, #weapons do
		weapons[i] = nil
	end

	-- add rope weps
	for i, w in pairs(ropeWeps) do
        table.insert(weapons, w)
	end

	-- add ground weps
	for i, w in pairs(groundWeps) do
        table.insert(weapons, w)
	end

	-- remove ground weps if attacking from rope is mandatory
	if AFR == true then
		for i = 1, #weapons do
			for w = 1, #groundWeps do
				if groundWeps[w] == weapons[i] then
					table.remove(weapons, i)
				end
			end
		end
	end

	-- remove crazy weps is crazy weps aren't allowed
	if allowCrazyWeps == false then
		for i = 1, #weapons do
			for w = 1, #crazyWeps do
				if crazyWeps[w] == weapons[i] then
					table.remove(weapons, i)
				end
			end
		end
	end

end

function onGameStart()

	trackTeams()

	MapsInit()
	LoadConfig(wallSetID)
	configureWeapons()

	-- ABL or KTL only make sense with at least 3 teams, otherwise we disable it
	if TeamsCount < 3 or ClansCount < 3 then
		attackRule = nil
	end

	if useMenu then
		ShowMission(loc("Wall to wall"), loc("Please wait …"), "", 2, 300000)
		UpdateMenu()
	else
		if GetGameFlag(gfPlaceHog) then
			roundN = 2
			FinalizeMenu()
		else
			allowCrate = false
			roundN = 100
			FinalizeMenu()
		end
	end
end

function onEndTurn()
	crateSpawned = false
	crateCollected = false
	wallsLeft = #wTouched
	for i = 1, #wTouched do
		wTouched[i] = false
	end
	hasSurfed = false
	allWallsHit = false
end

function onNewTurn()
	turnsCount = turnsCount + 1

	if roundN == 0 then
		roundN = 1
	end

	if GetGameFlag(gfPlaceHog) then
		if roundN < 2 then
			SetWeapon(amSkip)
			AddAmmo(CurrentHedgehog, amTeleport, 0)
			SetTurnTimeLeft(MAX_TURN_TIME)
			SetInputMask(0)
		end
		if roundN == 2 then
			if turnsCount > hogCount then
				roundN = 100
			end
		end
	end

	if roundN == 100 then

		local teamName = GetHogTeamName(CurrentHedgehog)

		-- Restore team's radar mode
		radarMode = getTeamValue(teamName, "radarMode")
		if radarMode == nil then
			radarMode = 0
		end

		if not AreCratesUnlocked() then
			FreezeCrates()
		end

		-- Check the attack rule violation of the *previous* team and apply penalties
		-- This function will do nothiong in the first turn since previousTeam is still nil
		CheckAttackRuleViolation(previousTeam)

		previousTeam = teamName

		-- Update attack rule information for this turn
		UpdateLastAndLeaderTeams()
		teamsAttacked = {}

		-- Was the team violating the attackRule the last time?
		if getTeamValue(teamName, "skipPenalty") then
			-- Then take away this turn
			AddCaption(string.format(loc("%s must skip this turn for rule violation."), teamName), msgColorWarn, capgrpMessage)
			EndTurn(true)
			setTeamValue(teamName, "skipPenalty", false)
		end

	end

	if roundN == 1 then
		SetTurnTimeLeft(MAX_TURN_TIME)
		SetInputMask(0)
		allowCrate = false
		UpdateMenu()
		AddCaption(string.format(loc("%s may choose the rules."), GetHogTeamName(CurrentHedgehog)), msgColorTech, capgrpGameState)
		HandleStartingStage()
	end

end

function CanSurf()
	if mapID ~= nil then
		if GetGameFlag(gfBottomBorder) and WaterRise == 0 then
			return false
		else
			return MapList[mapID][2]
		end
	else
		return nil
	end
end

function UpdateMenu()
	local teamInfo
	if roundN == 1 and CurrentHedgehog ~= nil then
		teamInfo = string.format(loc("%s, you may choose the rules."), GetHogTeamName(CurrentHedgehog)) 
	else
		teamInfo = ""
	end
	preMenuCfg =	teamInfo .. "|" ..
			loc("Press [Up] and [Down] to move between menu items.|Press [Attack], [Left], or [Right] to toggle.") .. "|"
	if GetGameFlag(gfPlaceHog) then
		postMenuCfg = loc("Press [Long jump] to accept this configuration and begin placing hedgehogs.")
	else
		postMenuCfg = loc("Press [Long jump] to accept this configuration and start the game.")
	end

	-- This table contains the menu strings and functions to be called when the entry is activated.
	menu = {}

	-- Walls required (hidden if the current settings don't allow for any walls)
	if #wallSets > 0 then
		local line
		if #wTouched > 0 then
			if wallSets[wallSetID].custom then
				line = string.format(loc("Wall set: %s (%d walls)"), wallSets[wallSetID].desc, #wTouched) .. "|"
			else
				line = string.format(loc("Wall set: %s"), wallSets[wallSetID].desc) .. "|"
			end
		else
			line = loc("Wall set: No walls") .. "|"
		end
		table.insert(menu, {
			line = line,
			doNext = function()
				wallSetID = wallSetID + 1
				if wallSetID > #wallSets then
					wallSetID = 0
				end
				LoadConfig(wallSetID)
			end,
			doPrev = function()
				wallSetID = wallSetID - 1
				if wallSetID < 0 then
					wallSetID = #wallSets
				end
				LoadConfig(wallSetID)
			end,
		})
	end

	-- Surf Before Crate (hidden if map disabled it)
	if CanSurf() == true or CanSurf() == nil then
		local toggleSurf = function() requireSurfer = not(requireSurfer) end
		table.insert(menu, {
			line = string.format(loc("Surf Before Crate: %s"), BoolToCfgTxt(requireSurfer)) .. "|",
			activate = function() requireSurfer = not requireSurfer end,
		})
	end

	-- Attack From Rope
	table.insert(menu, {
		line = string.format(loc("Attack From Rope: %s"), BoolToCfgTxt(AFR)) .. "|",
		activate = function() AFR = not AFR end,
	})

	-- Crate Before Attack
	table.insert(menu, {
		line = string.format(loc("Crate Before Attack: %s"), BoolToCfgTxt(CBA)) .. "|",
		activate = function() CBA = not CBA end,
	})

	if TeamsCount >= 3 then
		-- Attack rule (Disabled / All But Last / Kill The Leader)
		table.insert(menu, {
			line = string.format(loc("Attack rule: %s"), AttackRuleToCfgTxt(attackRule)) .. "|",
			doNext = function()
				if attackRule == nil then
					attackRule = "ABL"
				elseif attackRule == "ABL" then
					attackRule = "KTL"
				elseif attackRule == "KTL" then
					attackRule = nil
				end
			end,
			doPrev = function()
				if attackRule == nil then
					attackRule = "KTL"
				elseif attackRule == "ABL" then
					attackRule = nil 
				elseif attackRule == "KTL" then
					attackRule = "ABL"
				end
			end,
		})
	end

	-- Super weapons
	table.insert(menu, {
		line = string.format(loc("Super weapons: %s"), BoolToCfgTxt(allowCrazyWeps)) .. "|",
		activate = function() allowCrazyWeps = not allowCrazyWeps end,
	})

	-- Number of crates which appear per turn
	if maxCrates > 1 then
		table.insert(menu, {
			line = string.format(loc("Crates per turn: %d"), cratesPerTurn) .. "|",
			doNext = function()
				cratesPerTurn = cratesPerTurn + 1
				if cratesPerTurn > maxCrates then
					cratesPerTurn = 1
				end
			end,
			doPrev = function()
				cratesPerTurn = cratesPerTurn - 1
				if cratesPerTurn < 1 then
					cratesPerTurn = maxCrates
				end
			end,
		})
	end
end

function FinalizeMenu()
	local text = ""
	local showTime = 3000
	if #wTouched == 0 and not requireSurfer then
		text = text .. loc("Collect the crate and attack!") .. "|"
	else
		text = text .. loc("Spawn the crate and attack!") .. "|"
	end

	-- Expose a few selected game flags
	if GetGameFlag(gfPlaceHog)  then
		text = text .. loc("Place hedgehogs: Place your hedgehogs at the start of the game.") .. "|"
		showTime = 6000
	end
	if GetGameFlag(gfResetWeps) then
		text = text .. loc("Weapons reset: The weapons are reset after each turn.") .. "|"
	end

	-- Show the WxW rules
	if #wTouched == 1 then
		text = text .. loc("Wall Before Crate: You must touch the marked wall before you can get crates.") .. "|"
	elseif #wTouched > 0 then
		text = text .. string.format(loc("Walls Before Crate: You must touch the %d marked walls before you can get crates."), #wTouched) .. "|"
	end

	if requireSurfer then
		text = text .. loc("Surf Before Crate: You must bounce off the water once before you can get crates.") .. "|"
	end

	if AFR then
		text = text .. loc("Attack From Rope: You may only attack from a rope.") .. "|"
	end

	if CBA then
		text = text .. loc("Crate Before Attack: You must collect a crate before you can attack.") .. "|"
	end

	if attackRule == "ABL" then
		text = text .. loc("All But Last: You must not solely attack the team with the least health") .. "|"
	elseif attackRule == "KTL" then
		text = text .. loc("Kill The Leader: You must also hit the team with the most health.") .. "|"
	end
	if attackRule ~= nil then
		text = text .. loc("Penalty: If you violate above rule, you have to skip in the next turn.") .. "|"
	end

	if allowCrazyWeps then
		text = text .. loc("Super weapons: A few crates contain very powerful weapons.") .. "|"
	end

	ShowMission(loc("Wall to wall"), loc("A Shoppa minigame"), text, 1, showTime)
end

function HandleStartingStage()

	local renderedLines = {}
	for m = 1, #menu do
		local marker
		local line = menu[m].line
		if m == menuIndex then
			marker = "▶"
		else
			marker = "▷"
			line = string.gsub(line, ":", "\\:")
		end
		table.insert(renderedLines, marker .. " " .. line)
	end

	missionComment = ""
	for l = 1, #renderedLines do
		missionComment = missionComment .. renderedLines[l]
	end

	ShowMission	(
				loc("Wall to wall"),
				loc("Configuration phase"),
				preMenuCfg..
				missionComment ..
				postMenuCfg ..
				"", 2, 9999000, true
				)

end

function onGameTick()

	if CurrentHedgehog ~= nil and roundN >= 0 then

		gTimer = gTimer + 1
		if gTimer == 25 then
			gTimer = 1

			if roundN == 100 then
				CheckForWallCollision()
				if band(GetState(CurrentHedgehog), gstHHDriven) ~= 0 then
					CheckCrateConditions()
				end

				if (GetGearType(GetFollowGear()) == gtCase) then
					FollowGear(CurrentHedgehog)
				end
				
				-- AFR and CBA handling
				local allowAttack = true
				local shootException
				shootException = (GetCurAmmoType() == amRope) or
					(GetCurAmmoType() == amSkip) or
					(GetCurAmmoType() == amNothing)
				-- If Attack From Rope is set, forbid firing unless using rope
				if AFR then
					if ropeG == nil then
						allowAttack = false
					end
				end
				-- If Crate Before Attack is set, forbid firing if crate is not collected
				if CBA then
					if not crateCollected then
						allowAttack = false
					end
				end
				if allowAttack or shootException then
					SetInputMask(bor(GetInputMask(), gmAttack))
					if CBA then
						SetInputMask(bor(GetInputMask(), gmLJump))
					end
				else
					if CBA then
						if ropeG == nil then
							SetInputMask(band(GetInputMask(), bnot(gmAttack)))
							SetInputMask(bor(GetInputMask(), gmLJump))
						else
							SetInputMask(bor(GetInputMask(), gmAttack))
							SetInputMask(band(GetInputMask(), bnot(gmLJump)))
						end
					else
						SetInputMask(band(GetInputMask(), bnot(gmAttack)))
					end
				end
			end

		end


	end

	HandleBorderEffects()
	HandleCircles()

end

local menuRepeatTimer = 0
function onGameTick20()
  -- Make sure the menu doesn't disappear while it is active
  if roundN == 1 then
    menuRepeatTimer = menuRepeatTimer + 20
    if menuRepeatTimer > 9990000 then
      HandleStartingStage()
      menuRepeatTimer = 0
    end
  end
end

function onGearAdd(gear)

	if GetGearType(gear) == gtRope then
		ropeG = gear
	elseif GetGearType(gear) == gtCase then

		crates[gear] = true
		crateGearsInGame = crateGearsInGame + 1

		trackGear(gear)

		local vg = AddVisualGear(0, 0, vgtCircle, 0, true)
		if vg then
			table.insert(rCirc, vg)
			setGearValue(gear,"CIRC",vg)
			SetVisualGearValues(vg, 0, 0, 100, 255, 1, 10, 0, 40, 3, 0x0)
		end
		setGearValue(gear,"RX",0)
		setGearValue(gear,"RY",0)

		allowCrate = false
		crateSpawned = true

		rPingTimer = 0
		rAlpha = 0

	elseif GetGearType(gear) == gtHedgehog then
		trackGear(gear)
		local teamName = GetHogTeamName(gear)
		-- Initialize radar mode to “on” and set other team values
		setTeamValue(teamName, "radarMode", 0)
		setTeamValue(teamName, "skipPenalty", false)

		if getTeamValue(teamName, "hogs") == nil then
			setTeamValue(teamName, "hogs", 1)
		else
			increaseTeamValue(teamName, "hogs")
		end
		hogCount = hogCount + 1
		teamNames[GetHogTeamName(gear)] = true
	end

end

function onGearDelete(gear)

	local gt = GetGearType(gear)
	if gt == gtRope then
		ropeG = nil
	elseif gt == gtCase then

		crates[gear] = nil
		crateGearsInGame = crateGearsInGame - 1

		for i = 1, #rCirc do
			local CIRC = getGearValue(gear,"CIRC")
			if CIRC ~= nil and rCirc[i] == CIRC then
				DeleteVisualGear(rCirc[i])
				table.remove(rCirc, i)
			end
		end

		trackDeletion(gear)

		-- Was crate collected?
		if band(GetGearMessage(gear), gmDestroy) ~= 0 then
			crateCollected = true
		end

	elseif gt == gtHedgehog then
		teamsAttacked[GetHogTeamName(gear)] = true
		decreaseTeamValue(GetHogTeamName(gear), "hogs")
		trackDeletion(gear)
	end

end

function onGearDamage(gear)

	if GetGearType(gear) == gtHedgehog then
		teamsAttacked[GetHogTeamName(gear)] = true
	end

end

-- Check which team is the last and which is the leader (used for ABL and KTL)
function UpdateLastAndLeaderTeams()
	local teamHealths = {}

	for team, x in pairs(teamNames) do
		UpdateTeamHealth(team)
		local totalHealth = getTeamValue(team, "totalHealth")
		if totalHealth > 0 then
			table.insert(teamHealths, {name = team, health = totalHealth } )
		end
	end

	-- Sort the table by health, lowest health comes first
	table.sort(teamHealths, function(team1, team2) return team1.health < team2.health end)

	-- ABL and KTL rules are only active at 3 teams; when there are only 2 teams left, it's “everything goes”.
	if #teamHealths >= 3 then
		if teamHealths[1].health == teamHealths[2].health then
			-- ABL rule is disabled if it's a tie for “least health”
			lastTeam = nil
		else
			-- Normal assignment of ABL variable
			lastTeam = teamHealths[1].name
		end
		if teamHealths[#teamHealths].health == teamHealths[#teamHealths-1].health then
			-- KTL rule is disabled if it's a tie for “most health”
			leaderTeam = nil
			runnerUpTeam = nil
		else
			-- Normal assignment of KTL variables
			leaderTeam = teamHealths[#teamHealths].name
			runnerUpTeam = teamHealths[#teamHealths-1].name
		end
	else
		-- The KTL and ABL rules are disabled with only 2 teams left
		lastTeam = nil
		runnerUpTeam = nil
		leaderTeam = nil
	end
end

function UpdateTeamHealth(team)
	setTeamValue(team, "totalHealth", 0)
	runOnHogsInTeam(function(hog)
		if(GetGearType(hog) ~= gtHedgehog) then return end
		local h = getTeamValue(GetHogTeamName(hog), "totalHealth")
		setTeamValue(GetHogTeamName(hog), "totalHealth", h + GetHealth(hog))
	end, team)
end

-- Check if the ABL or KTL rule (if active) has been violated by teamToCheck
function CheckAttackRuleViolation(teamToCheck)

	if teamToCheck == nil then return end

	local violated = false
	if attackRule == "ABL" then
		-- We don't care if the last team hurts itself
		if lastTeam ~= nil and lastTeam ~= teamToCheck then
			local lastAttacked = false
			local attackNum = 0	-- count the attacked teams but we'll ignore the attacking team
			for team, wasAttacked in pairs(teamsAttacked) do
				-- Ignore the attacking team
				if team ~= teamToCheck then
					attackNum = attackNum + 1
					if team == lastTeam then
						lastAttacked = true
					end
				end
			end
			-- Rule is violated iff only the last team is attacked (damage to attacking team is ignored)
			if attackNum == 1 and lastAttacked then
				violated = true
			end
		end
		if violated then
			AddCaption(string.format(loc("%s violated the “All But Last” rule and will be penalized."), teamToCheck), msgColorWarn, capgrpGameState)
		end
	elseif attackRule == "KTL" then
		local leaderAttacked = false
		if leaderTeam ~= nil then
			local attackNum = 0
			local selfHarm = false
			for team, wasAttacked in pairs(teamsAttacked) do
				attackNum = attackNum + 1
				if team == teamToCheck then
					selfHarm = true
				end
				-- The leader must attack the runner-up, everyone else must attack the leader
				if (teamToCheck ~= leaderTeam and team == leaderTeam) or (teamToCheck == leaderTeam and team == runnerUpTeam) then
					leaderAttacked = true
					break
				end
			end
			-- If teams were attacked but not the leader, it is a violation,
			-- but we don't care if the team *only* harmed itself.
			if (attackNum >= 2 and not leaderAttacked) or (attackNum == 1 and not selfHarm and not leaderAttacked) then
				violated = true
			end
		end
		if violated then
			AddCaption(string.format(loc("%s violated the “Kill The Leader” rule and will be penalized."), teamToCheck), msgColorWarn, capgrpGameState)
		end
	end
	if violated then
		setTeamValue(teamToCheck, "skipPenalty", true)
	end

end

function onAmmoStoreInit()

	for i, w in pairs(ropeWeps) do
        SetAmmo(w, 0, 0, 0, 1)
    end

    for i, w in pairs(groundWeps) do
        SetAmmo(w, 0, 0, 0, 1)
    end

    for i, w in pairs(crazyWeps) do
        SetAmmo(w, 0, 0, 0, 1)
    end

	SetAmmo(amRope, 9, 0, 0, 0)
	SetAmmo(amSkip, 9, 0, 0, 0)

end

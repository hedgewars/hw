-----------------------------------------------------------
--- HEDGE EDITOR (for use with Hedgewars 0.9.22 and up) ---
-----------------------------------------------------------
-- A not-so-horrible mission editor.
-- Place gears like a boss!

-- Original author: mikade

-- feel free to shower me with your adoration and/or hate mail
-- more info can be found at http://hedgewars.org/HedgeEditor

-- special thanks to nemo, unC0Rr, sheepluva and koda for their assistance

---------------------------------------
-- GETTING STARTED (for best results!)
---------------------------------------
-- create a weaponset that has NO DELAYS on any weapons, and that gives you 1 ammo per crate

-- (optional) copy GameLogExtractor.html, jquery-1.js
-- into your Documents/Hedgewars/Logs folder

-- (optional) copy hwpmapconverter somewhere easily accessible

-- (optional) profit??

---------------------------------------
-- CORE FEATURES as of latest version
---------------------------------------
-- togglable help (press PRECISE + 1, while you have a tool (e.g. airstrike) selected)
-- you can also the set the ScriptParameter in scheme, e.g: helpDisabled="true"

-- place girders, rubberbands and custom sprites anywhere on the map.
-- the above objects may be destructible, indestructible, icy, or bouncy.

-- place mines, sticky mines, air mines, barrels, weapon crates, utility crates,
-- health crates, targets, and cleavers anywhere on the map.

-- select, reposition, modify, or delete placed objects.

-- read in data from a previously generated map and allow the map to be edited/saved again

-- contextual cursor and menu graphics
-- placement sounds that are slightly more soothing

-- upon saving, all level data will be output to logs/game0.log.
-- game0.log also includes a lot of other data so if you only want to see the relevant lines of code
-- you can use GameLogExtractor.html to extract and prune the log into a cleaner form of data,
-- specifically: either as an automagically generated template mission, just core data, or hwmap points.
-- from there, please copy and paste any lines relevant to your interest into an existing
-- (or totally empty!) script and edit them according to taste.

--------------------------
-- MODE SPECIFIC SUPPORT
--------------------------
-- FOR CUSTOM MISSIONS/CAMPAIGN LEVELS:
-- the names/hats/flags/voices/graves of any teams/hogs that you use to play this script can be saved,
-- as can (most of) the settings from your scheme and weapons selection.
-- HOWEVER, you can also use the 'hog identity' tool to give hogs preset names/hats/weapons/health
-- or use the 'team identity' tool to give an entire team themed names/hats.
-- give hogs differing health by using the health modification tool
-- create goals by tagging gears with victory/defeat/collection markers (somewhat implemented)
-- flavor text, as well as victory/defeat conditions will be generated based on these tags.

-- SHOPPA BALANCE / CONSTRUCTION MODE (partial and/or possibly decremented):
-- Press 1-5 while repositioning hogs with the reposition tool to assign them (their position) a rank.
-- This value will be expressed as a colour that is intended to represent how "good" or "bad"
-- a position on the map is. These ranks/points will be output along with other game data to game0.log
-- This data could be pasted into the ShoppaBalance script to create balances for additional maps.

-- TECH RACER / HEDGE EDITOR / POINT INTERPRETER:
-- place/remove waypoints/special points
-- use the ScriptParameter in the frontend scheme editor to set additional options, e.g.
-- ufoFuel=1000 (Flying Saucer will start with half the normal fuel. A value of 2000 is infinite fuel)
-- portalDistance=15 (This is the distance portals can travel before fizzling)
-- m=3 (load a particular map from the map library of Data/Scripts/TechMaps
-- helpDisabled="true" (the help pop-up overlay will be disabled by default)

-- when saving data, points for conversion to HWMAP are also generated and placed inside block comments.
-- copy paste/these points at the START of a converted HWMAP and then convert the map back to HWMAP format.
-- following the above procedure it is then possible to load the map in frontend and play it using a
-- script like TechRacer (or HedgeEditor itself) that can interpret the points using InterpretPoints()

---------------------------------------
-- MIKADE'S DISCLAIMER
---------------------------------------
-- well, I really just made this for myself, so it's usage might be a little complicated for others.
-- it also probably has a million errors, and has grown rather bloated over time due to the addition of
-- more and more features that my initial design didn't take into account.

-- anyway, I've tried to make it more user-friendly by including more comments and gradually adding
-- some basic guidelines such as those listed above, and also the in-game Help displays for each tool.

-----------------------------------------
-- GIANT "TO DO" LIST / OTHER NOTES
-----------------------------------------

-- try to prune waypoint list and portal/ufo fuel in the mission template
-- for gamelog extractor

-- I should probably check if there are tagged gears on save
-- and if there are enable gfOneClanMode so that user can't
-- just destroy all hogs to win map.
-- (what happens if we lose all our hogs?)

-- I might be able to make the flavor text even better (assassinate hogName) by
-- checking if there is only 1 hog, etc.

-- possibly try show landflag addcaption constantly like we do for superdelete when
-- using girders / rubbers.

-- How about a weapons profile tool that is used with team ammo
-- and then hog identity tool would only be available if gfPerHogAmmo is set

-- [high]       check if we lose a mission when the enemy collects our crate (we should)

-- [high] 	waypoints don't reload yet

-- [high] 	add missing ammo types as they appear

-- [med] 	add a limited form of save/load within level before mass-output

-- [med]	maybe incorporate portal effects / ufo tracking into the template generated script if
-- 			you want the missions to use it

-- [med]	improve ammo handling (if possible, take more scheme settings into account)

-- [low] 	break up the division of labor of the tools into airstrike, minestrike, napalm, etc.
			--[[
			girder =		"Girder Placement Mode",
			rubber =		"Rubber Placement Mode",

			airstrike =		(target sprite) (gear placement)
							"Mine Placement Mode",
							"Sticky Mine Placement Mode",
							"Air Mine Placement Mode",
							"Barrel Placement Mode",
							"Target Placement Mode",
							"Cleaver Placement Mode",

			drillstrike =	crate sprite (crate placement mode)
							"Health Crate Placement Mode",
							"Weapon Crate Placement Mode",
							"Utility Crate Placement Mode",


			napalm =		arrow sprite (selection/modification/deletion mode)
							"Repositioning Mode",  -- also include a delete
							"Goal Editing Mode",
							"Hog Identity Mode",
							"Team Identity Mode",
							"Health Modification Mode",
							"Sprite Testing Mode",
							"Sprite Modification Mode",
							"Sprite Placement Mode",
							"Waypoint Editing Mode"
							}]]

-- [low]	improve support for ShoppaBalance and ConstructionMode, see ranking)

-- [low]	eventually incorporate scripted structures into the editor / mission mode

-- [low] 	some kind of support for single team training missions
-- 			we could possibly add gfOneClanMode and kill the other team we're playing with?

-- [never?] more detailed goal tagging and multi-stage triggers

-- [never?]	add a pulsing glow thing for sprites you have selected,
--			kind of like the invaders in SpaceInvader (currently they are just displayed as purple)

-- [never?]	add GUIs for editing ammo, init settings, additional gear attributes
-- 			perhaps using precise with timer to enable/disable certain features

--[[ gui menu ideas that have long since been abandoned
INITIALISATION MENU
	--gameFlags, etc

	Map
	Theme
	TurnTime
	Explosives
	MinesNum
	CaseFreq
	Delay

	HealthCaseProb
	HealthCaseAmount
	DamagePercent
	MinesTime
	MineDudPercent
	SuddenDeathTurns
	WaterRise
	HealthDecrease
HOG MENU
	health
	name (can be randomly generated from the list of hog names already in localisation)
	poisoned (true/false)
	hat
	hog level?
TEAM MENU
	name (can be randomly generated as above?) should there be an array of teams with an array of names
	colour
	grave
	fort
	voicepack
	flag

-- this below stuff is less important
STICKY MINE MENU
	timer?
MINE MENU
	timer / dud
MEDKIT MENU / EXPLOSIVE MENU
	health amount
WEP AND UTIL CRATE MENU
	contents

----------------------------------------
-- MAP IDEAS
----------------------------------------
-- try to create a portal race (limit portal distance)
-- for portal race, include barriers that you need to drill shoot through to get lazer site crates

-- try make a map that uses sinegun to jump between bouncy boxes (not easy until we get better control over landflags)

-- how about a mission where you have to trap / freeze all the enemy hogs
-- and aren't allowed to kill them?
-- can set it on the islands map.
-- landgun
-- girder
-- mudball
-- hammer
-- seduction? (call a hog who has firepunch into a ditch
-- icegun (do this so you can freeze guys in an area and then blowtorch/explode an obstacle)
-- jump across a bridge that has been mined and then bat the enemy to the other side.

-- possibly the same as part of the above, possibly different, what about a heist mission
-- the objective is to steal 3 enemy crates
-- the first one you have to fall through an invul tunnel of sticky mines and then parachute.
-- the second one you have to drill rocket / portal.
-- the third one you have to underwater ufo into, but only after opening it up with an underwater bee.

]]

---------------------------------------------------------
-- HEDGE EDITOR, SCRIPT BEGINS (Hey yo, it's about time)
---------------------------------------------------------

-- Tell other scripts that we exist
HedgeEditor = true

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")
HedgewarsScriptLoad("/Scripts/TechMaps.lua")

-- Fake ammo type for the gear placement tool
local amCMGearPlacementTool = amAirAttack

-- Special frames in Ammos.png/Ammos_bw.png
local ammoFrameAirAttack = 63

-- Caption colors
local colorErrorMessage = 0xFFFFFFFF
local colorInfoMessage = 0xFFFFFFFF
local colorPlaceMode1 = 0xFFBA00FF -- Main placement mode
local colorPlaceMode2 = 0xFFDE85FF -- Secondary mode

-----------------------------------------
-- tracking vars for save/load purposes
-----------------------------------------

local teamCounter = 0
local lastRecordedTeam = ""
local hhs = {}

local waypointList = {}
local girderList = {}
local rubberList = {}
local spriteList = {}

local mineList = {}
local sMineList = {}
local airMineList = {}
local targetList = {}
local knifeList = {}
local explosivesList = {}
local healthCrateList = {}
local wepCrateList = {}
local utilCrateList = {}
local hogDataList = {}
local AIHogDataList = {}
local hFlagList = {}
local previewDataList = {}

local shoppaPointList = {}
local shoppaPX = {}
local shoppaPY = {}
local shoppaPR = {}

-- Misc. state variables
local hedgeEditorMissionPanelShown = false
local tagGears = {}
local showGearTags = true

local tagCursorX, tagCursorY

---------------------------------
-- crates are made of this stuff
---------------------------------

local atkArray =
				{

				{amBazooka, 	"amBazooka"},
				{amBee, 	"amBee"},
				{amMortar, 	"amMortar"},
				{amDrill, 	"amDrill"},
				{amSnowball, 	"amSnowball"},
				{amDuck,	"amDuck"},

				{amGrenade,	"amGrenade"},
				{amClusterBomb,	"amClusterBomb"},
				{amWatermelon, 	"amWatermelon"},
				{amHellishBomb,	"amHellishBomb"},
				{amMolotov, 	"amMolotov"},
				{amGasBomb, 	"amGasBomb"},

				{amShotgun,	"amShotgun"},
				{amDEagle,	"amDEagle"},
				{amSniperRifle,	"amSniperRifle"},
				{amSineGun, 	"amSineGun"},
				{amFlamethrower,"amFlamethrower"},
				{amIceGun, 	"amIceGun"},
				{amMinigun, 	"amMinigun"},

				{amFirePunch, 	"amFirePunch"},
				{amWhip,	"amWhip"},
				{amBaseballBat, "amBaseballBat"},
				{amKamikaze, 	"amKamikaze"},
				{amSeduction, 	"amSeduction"},
				{amHammer,	"amHammer"},

				{amMine, 	"amMine"},
				{amDynamite, 	"amDynamite"},
				{amCake, 	"amCake"},
				{amBallgun, 	"amBallgun"},
				{amRCPlane,	"amRCPlane"},
				{amSMine,	"amSMine"},

				{amAirAttack,	"amAirAttack", ammoFrameAirAttack}, -- overwritten icon in Ammos.png
				{amMineStrike,	"amMineStrike"},
				{amNapalm, 	"amNapalm"},
				{amPiano,	"amPiano"},
				{amDrillStrike,	"amDrillStrike"},
				{amAirMine,	"amAirMine"},

				{amPickHammer,	"amPickHammer"},
				{amBlowTorch, 	"amBlowTorch"},
				{amKnife,	"amKnife"},

				{amBirdy,	"amBirdy"},

				}

local utilArray =
				{
				{amGirder, 	"amGirder"},
				{amLandGun,	"amLandGun"},
				{amRubber, 	"amRubber"},

				{amRope, 	"amRope"},
				{amParachute, 	"amParachute"},
				{amTeleport,	"amTeleport"},
				{amJetpack,	"amJetpack"},
				{amPortalGun,	"amPortalGun"},

				{amInvulnerable,"amInvulnerable"},
				{amLaserSight,	"amLaserSight"},
				{amVampiric,	"amVampiric"},
				{amResurrector, "amResurrector"},
				{amTardis, 	"amTardis"},

				{amSwitch,	"amSwitch"},
				{amLowGravity, 	"amLowGravity"},
				{amExtraDamage, "amExtraDamage"},
				{amExtraTime,	"amExtraTime"},

				}

				--skiphog is 6

local effectArray = { heInvulnerable, hePoisoned, heResurrectable, heResurrected, heFrozen }
local effectStr = { "heInvulnerable", "hePoisoned", "heResurrectable", "heResurrected", "heFrozen" }

----------------------------
-- hog and map editing junk
----------------------------

local preMadeTeam = 	{

				{
				loc_noop("Clowns"),
				{"WhySoSerious","clown-copper","clown-crossed","clown","Joker"},
				{loc_noop("Baggy"),loc_noop("Bingo"),loc_noop("Bobo"),loc_noop("Bozo"),loc_noop("Buster"),loc_noop("Chester"),loc_noop("Copper"),loc_noop("Heckles"),loc_noop("Giggles"),loc_noop("Jingo"),loc_noop("Molly"),loc_noop("Loopy"),loc_noop("Patches"),loc_noop("Tatters")},
				"R","cm_balls","Mobster","Rubberduck","Castle"
				},

				{
				loc_noop("Street Fighters"),
				{"sf_balrog","sf_blanka","sf_chunli","sf_guile","sf_honda","sf_ken","sf_ryu","sf_vega"},
				{loc_noop("Balrog"),loc_noop("Blanka"),loc_noop("Chunli"),loc_noop("Guile"),loc_noop("Honda"),loc_noop("Ken"),loc_noop("Ryu"),loc_noop("Vega")},
				"F","cm_balrog","Surfer","dragonball","Castle"
				},

				{
				loc_noop("Cybernetic Empire"),
				{"cyborg1","cyborg2"},
				{loc_noop("Unit 189"),loc_noop("Unit 234"),loc_noop("Unit 333"),loc_noop("Unit 485"),loc_noop("Unit 527"),loc_noop("Unit 638"),loc_noop("Unit 709"),loc_noop("Unit 883")},
				"R","cm_binary","Robot","Grave","Castle"
				},

				{
				loc_noop("Color Squad"),
				{"hair_blue","hair_green","hair_red","hair_yellow","hair_purple","hair_grey","hair_orange","hair_pink"},
				{loc_noop("Blue"),loc_noop("Green"),loc_noop("Red"),loc_noop("Yellow"),loc_noop("Purple"),loc_noop("Grey"),loc_noop("Orange"),loc_noop("Pink")},
				"F","mauritius","Singer","Grave","Castle"
				},

				{
				loc_noop("Fruit"),
				{"fr_apple","fr_banana","fr_lemon","fr_orange","fr_pumpkin","fr_tomato"},
				{loc_noop("Juicy"),loc_noop("Squishy"),loc_noop("Sweet"),loc_noop("Sour"),loc_noop("Bitter"),loc_noop("Ripe"),loc_noop("Rotten"),loc_noop("Fruity")},
				"R","cm_mog","Default","Cherry","Castle"
				},

				{
				loc_noop("The Police"),
				{"bobby","bobby2v","policecap","policegirl","royalguard"},
				{loc_noop("Hightower"),loc_noop("Lassard"),loc_noop("Callahan"),loc_noop("Jones"),loc_noop("Harris"),loc_noop("Thompson"),loc_noop("Mahoney"),loc_noop("Hooks"),loc_noop("Tackleberry")},
				"R","cm_star","British","Statue","Castle"
				},

				{
				loc_noop("The Ninja-Samurai Alliance"),
				{"NinjaFull","NinjaStraight","NinjaTriangle","Samurai","StrawHat","StrawHatEyes","StrawHatFacial","naruto"},
				{loc_noop("Bushi"),loc_noop("Tatsujin"),loc_noop("Itami"),loc_noop("Arashi"),loc_noop("Shinobi"),loc_noop("Ukemi"),loc_noop("Godai"),loc_noop("Kenshi"),loc_noop("Ninpo")},
				"R","japan","Default","octopus","Castle"
				},

				{
				loc_noop("Pokémon"),
				{"poke_ash","poke_charmander","poke_chikorita","poke_jigglypuff","poke_lugia","poke_mudkip","poke_pikachu","poke_slowpoke","poke_squirtle","poke_voltorb"},
				{loc_noop("Ash"),loc_noop("Charmander"),loc_noop("Chikorita"),loc_noop("Jigglypuff"),loc_noop("Lugia"),loc_noop("Mudkip"),loc_noop("Pikachu"),loc_noop("Slowpoke"),loc_noop("Squirtle"),loc_noop("Voltorb")},
				"FR","cm_pokemon","Default","pokeball","Castle"
				},

				{
				loc_noop("The Zoo"),
				{"zoo_Bat","zoo_Beaver","zoo_Bunny","zoo_Deer","zoo_Hedgehog","zoo_Moose","zoo_Pig","zoo_Porkey","zoo_Sheep","zoo_chicken","zoo_elephant","zoo_fish","zoo_frog","zoo_snail","zoo_turtle"},
				{loc_noop("Batty"),loc_noop("Tails"),loc_noop("Bunny"),loc_noop("Deer"),loc_noop("Spikes"),loc_noop("Horns"),loc_noop("Bacon"),loc_noop("Porkey"),loc_noop("Sheepy"),loc_noop("Chicken"),loc_noop("Trunks"),loc_noop("Fishy"),loc_noop("Legs"),loc_noop("Slimer"),loc_noop("Roshi")},
				"FR","cm_birdy","Default","Bone","Castle"
				},

				{
				loc_noop("The Devs"),
				{"ushanka","zoo_Sheep","bb_bob","Skull","poke_mudkip","lambda","WizardHat","sf_ryu","android","fr_lemon","mp3"},
				{loc_noop("unC0Rr"), loc_noop("sheepluva"), loc_noop("nemo"), loc_noop("mikade"), loc_noop("koda"), loc_noop("burp"),loc_noop("HeneK"),loc_noop("Tiyuri"),loc_noop("Xeli"),loc_noop("Displacer"),loc_noop("szczur")},
				"FR","cm_hw","Classic","Statue","Castle"
				},

				{
				loc_noop("Mushroom Kingdom"),
				{"sm_daisy","sm_luigi","sm_mario","sm_peach","sm_toad","sm_wario","NoHat","NoHat"},
				{loc_noop("Daisy"),loc_noop("Luigi"),loc_noop("Mario"),loc_noop("Princess Peach"),loc_noop("Toad"),loc_noop("Wario"),loc_noop("Yoshi"),loc_noop("Waluigi")},
				"FR","comoros","Default","Badger","Castle"
				},

				{
				loc_noop("Pirates"),
				{"pirate_jack","pirate_jack_bandana"},
				{loc_noop("Rusted Diego"),loc_noop("Fuzzy Beard"),loc_noop("Al.Kaholic"),loc_noop("Morris"),loc_noop("Yumme Gunpowder"),loc_noop("Cutlass Cain"),loc_noop("Jim Morgan"),loc_noop("Silver"),loc_noop("Dubloon Devil"),loc_noop("Ugly Mug"),loc_noop("Fair Wind"),loc_noop("Scallywag"),loc_noop("Salty Dog"),loc_noop("Bearded Beast"),loc_noop("Timbers"),loc_noop("Both Barrels"),loc_noop("Jolly Roger")},
				"R","cm_pirate","Pirate","chest","Castle"
				},

				{
				loc_noop("Gangsters"),
				{"Moustache","Cowboy","anzac","Bandit","thug","Jason","NinjaFull","chef"},
				{loc_noop("The Boss"),loc_noop("Jimmy"),loc_noop("Frankie"),loc_noop("Morris"),loc_noop("Mooney"),loc_noop("Knives"),loc_noop("Tony"),loc_noop("Meals")},
				"F","cm_anarchy","Mobster","deadhog","Castle"
				},


				{
				loc_noop("Twenty-Twenty"),
				{"Glasses","lambda","SunGlasses","Sniper","Terminator_Glasses","Moustache_glasses","doctor","punkman","rasta"},
				{loc_noop("Specs"),loc_noop("Speckles"),loc_noop("Spectator"),loc_noop("Glasses"),loc_noop("Glassy"),loc_noop("Harry Potter"),loc_noop("Goggles"),loc_noop("Clark Kent"),loc_noop("Goggs"),loc_noop("Lightbender"),loc_noop("Specs Appeal"),loc_noop("Four Eyes")},
				"R","cm_face","Default","eyecross","Castle"
				},


				{
				loc_noop("Monsters"),
				{"Skull","Jason","ShaggyYeti","Zombi","cyclops","Mummy","hogpharoah","vampirichog"},
				{loc_noop("Bones"),loc_noop("Jason"),loc_noop("Yeti"),loc_noop("Zombie"),loc_noop("Old One Eye"),loc_noop("Ramesses"),loc_noop("Xerxes"),loc_noop("Count Hogula")},
				"FR","cm_vampire","Default","octopus","Castle"
				},

				{
				loc_noop("The Iron Curtain"),
				{"ushanka","war_sovietcomrade1","war_sovietcomrade1","ushanka"},
				{loc_noop("Alex"),loc_noop("Sergey"),loc_noop("Vladimir"),loc_noop("Andrey"),loc_noop("Dimitry"),loc_noop("Ivan"),loc_noop("Oleg"),loc_noop("Kostya"),loc_noop("Anton"),loc_noop("Eugene")},
				"R","cm_soviet","Russian","skull","Castle"
				},

				{
				loc_noop("Desert Storm"),
				{"war_desertofficer","war_desertgrenadier1","war_desertmedic","war_desertsapper1","war_desertgrenadier2","war_desertgrenadier4","war_desertsapper2","war_desertgrenadier5"},
				{loc_noop("Brigadier Briggs"),loc_noop("Lt. Luke"),loc_noop("Sgt. Smith"),loc_noop("Corporal Calvin"),loc_noop("Frank"),loc_noop("Joe"),loc_noop("Sam"),loc_noop("Donald")},
				"F","bhutan","Default","Grave","Castle"
				},

				{
				loc_noop("The Hospital"),
				{"doctor","nurse","war_britmedic","war_desertmedic","war_germanww2medic"},
				{loc_noop("Dr. Blackwell"),loc_noop("Dr. Drew"),loc_noop("Dr. Harvey"),loc_noop("Dr. Crushing"),loc_noop("Dr. Jenner"),loc_noop("Dr. Barnard"),loc_noop("Dr. Parkinson"),loc_noop("Dr. Banting"),loc_noop("Dr. Horace"),loc_noop("Dr. Hollows"),loc_noop("Dr. Jung")},
				"R","cm_firstaid","Default","heart","Castle"
				}

				}

local preMadeTeamNamesTranslated = {}
local preMadeTeamNamesOriginal = {}
for i=1, #preMadeTeam do
	table.insert(preMadeTeamNamesOriginal, preMadeTeam[i][1])
	table.insert(preMadeTeamNamesTranslated, loc(preMadeTeam[i][1]))
end

local gameFlagList =	{
			{"gfMultiWeapon", false, gfMultiWeapon},
			{"gfBorder", false, gfBorder},
			{"gfSolidLand", false, gfSolidLand},
			{"gfDivideTeams", false, gfDivideTeams},
			{"gfLowGravity", false, gfLowGravity},
			{"gfLaserSight", true, gfLaserSight},
			{"gfInvulnerable", false, gfInvulnerable},
			{"gfMines", false, gfMines},
			{"gfVampiric", false, gfVampiric},
			{"gfKarma", false, gfKarma},
			{"gfArtillery", false, gfArtillery},
			{"gfOneClanMode", false, gfOneClanMode},
			{"gfRandomOrder", false, gfRandomOrder},
			{"gfKing", false, gfKing},
			{"gfPlaceHog", false, gfPlaceHog},
			{"gfSharedAmmo", false, gfSharedAmmo},
			{"gfDisableGirders", false, gfDisableGirders},
			{"gfExplosives", false, gfExplosives},
			{"gfDisableLandObjects", false, gfDisableLandObjects},
			{"gfAISurvival", false, gfAISurvival},
			{"gfInfAttack", true, gfInfAttack},
			{"gfResetWeps", false, gfResetWeps},
			{"gfResetHealth", false, gfResetHealth},
			{"gfPerHogAmmo", false, gfPerHogAmmo},
			{"gfDisableWind", false, gfDisableWind},
			{"gfMoreWind", false, gfMoreWind},
			{"gfTagTeam", false, gfTagTeam}
			}

 local reducedSpriteIDArray = {
  sprTargetBee, sprAmGirder, sprAmRubber, sprIceTexture, sprHHTelepMask,
  sprAMAmmos, sprAMAmmosBW, sprAMSlot, sprAMCorners, sprTurnsLeft, sprBotlevels,
  sprSpeechCorner, sprSpeechEdge, sprSpeechTail, sprThoughtCorner, sprThoughtEdge, sprThoughtTail,
  sprShoutCorner, sprShoutEdge, sprShoutTail, }

 -- Set in onGameInit
 local reducedSpriteIDArrayFrames

 local reducedSpriteTextArray = {
  "sprTargetBee", "sprAmGirder", "sprAmRubber", "sprIceTexture", "sprHHTelepMask",
  "sprAMAmmos", "sprAMAmmosBW", "sprAMSlot",  "sprAMCorners", "sprTurnsLeft", "sprBotlevels",
  "sprSpeechCorner", "sprSpeechEdge", "sprSpeechTail", "sprThoughtCorner", "sprThoughtEdge", "sprThoughtTail",
  "sprShoutCorner", "sprShoutEdge", "sprShoutTail", }

----------------------------
-- placement shite
----------------------------

local landType = 0
local superDelete = false
local ufoGear = nil
ufoFuel = 0
mapID = 1
local portalDistance = 5000/5
local helpDisabled = false  --determines whether help popups pop up
local CG = nil -- this is the visual gear displayed at CursorX, CursorY
local crateSprite = nil-- this is a visual gear aid for crate placement
local crateSpriteBorer = nil
local waypointPreviewSprite = nil

local cGear = nil -- detects placement of girders and objects (using airattack)
local curWep = amNothing
local leftHeld = false
local rightHeld = false
local preciseOn = false

-- primary placement categories
local cIndex = 1 -- category index
local cat = 	{
				loc("Girder Placement Mode"),
				loc("Rubber Placement Mode"),
				loc("Mine Placement Mode"),
				loc("Dud Mine Placement Mode"),
				loc("Sticky Mine Placement Mode"),
				loc("Air Mine Placement Mode"),
				loc("Barrel Placement Mode"),
				loc("Health Crate Placement Mode"),
				loc("Weapon Crate Placement Mode"),
				loc("Utility Crate Placement Mode"),
				loc("Target Placement Mode"),
				loc("Cleaver Placement Mode"),
				loc("Repositioning Mode"),
				loc("Goal Definition Mode"),
				loc("Hog Identity Mode"),
				loc("Team Identity Mode"),
				loc("Health Modification Mode"),
				loc("Sprite Placement Mode"),
				loc("Sprite Modification Mode"),
				loc("Waypoint Editing Mode")
				}


local pMode = {}	-- pMode contains custom subsets of the main categories
local pIndex = 1
local sFrame = 0	-- frame in sprite placement mode

local genTimer = 0

local CGR = 1 -- current girder rotation, we actually need this as HW remembers what rotation you last used

local placedX = {} -- x coord of placed object
local placedY = {} -- y coord of placed object
local placedSpec = {} -- this is different depending on what was placed, for mines it is their time, for crates it is their content, (for girders/rubbers it used to be their rotation, and for sprites, their name, but this has been moved to different variables to allow more complex / smooth editing)
local placedType = {} -- what kind of object was placed: mine, crate, girder, rubber, barrel, etc.

local placedTint = {} -- only girders/rubbers/sprites use this, it is their tint / colouration
local placedSprite = {} -- what sprite was placed
local placedFrame = {} -- what frame of sprite was placed (rotation for girders / rubber)
local placedLandFlags = {}
local placedHWMapFlag = {} -- this is what HWMapConverter uses
local placedCount = 0 -- do we really need this?

local sSprite -- sprite overlay that glows to show selected sprites
local sCirc -- circle that appears around selected gears
local sGear = nil
local closestDist
local closestGear = nil
local closestSpriteID = nil

local wpRadius = 450

------------------------
-- SOME GENERAL METHODS
------------------------

function BoolToString(boo)
	if boo == true then
		return("true")
	else
		return("false")
	end
end

function GetDistFromGearToXY(gear, g2X, g2Y)

	g1X, g1Y = GetGearPosition(gear)
	q = g1X - g2X
	w = g1Y - g2Y

	return ( (q*q) + (w*w) )

end

------------------------------------------------------------
-- STUFF FOR LOADING SPECIAL POINTS / HWMAP CONVERSION
------------------------------------------------------------

local specialPointsX = {}
local specialPointsY = {}
local specialPointsFlag = {}
local specialPointsCount = 0

function onSpecialPoint(x,y,flag)
    specialPointsX[specialPointsCount] = x
    specialPointsY[specialPointsCount] = y
	specialPointsFlag[specialPointsCount] = flag
    specialPointsCount = specialPointsCount + 1
end

-- you know you could probably add multiple layers to this to get more points
-- after the first set is expended have the last 1 be 127
-- and then increment some other counter so like

-- this function interprets special points that have been embedded into an HWPMAP
function InterpretPoints()

	-- flags run from 0 to 127
	for i = 0, (specialPointsCount-1) do

		-- Mines
		if specialPointsFlag[i] == 1 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 1)
		elseif specialPointsFlag[i] == 2 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 1000)
		elseif specialPointsFlag[i] == 3 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 2000)
		elseif specialPointsFlag[i] == 4 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 3000)
		elseif specialPointsFlag[i] == 5 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 4000)
		elseif specialPointsFlag[i] == 6 then
			SetTimer(AddGear(specialPointsX[i], specialPointsY[i], gtMine, 0, 0, 0, 0), 5000)

		-- Sticky Mines
		elseif specialPointsFlag[i] == 7 then
			AddGear(specialPointsX[i], specialPointsY[i], gtSMine, 0, 0, 0, 0)

		-- Air Mines
		elseif specialPointsFlag[i] == 8 then
			AddGear(specialPointsX[i], specialPointsY[i], gtAirMine, 0, 0, 0, 0)

		-- Health Crates
		elseif specialPointsFlag[i] == 9 then
			SetHealth(SpawnHealthCrate(specialPointsX[i],specialPointsY[i]),25)
		elseif specialPointsFlag[i] == 10 then
			SetHealth(SpawnHealthCrate(specialPointsX[i],specialPointsY[i]),50)
		elseif specialPointsFlag[i] == 11 then
			SetHealth(SpawnHealthCrate(specialPointsX[i],specialPointsY[i]),75)
		elseif specialPointsFlag[i] == 12 then
			SetHealth(SpawnHealthCrate(specialPointsX[i],specialPointsY[i]),100)

		-- Cleaver
		elseif specialPointsFlag[i] == 13 then
			AddGear(specialPointsX[i], specialPointsY[i], gtKnife, 0, 0, 0, 0)

		-- Target
		elseif specialPointsFlag[i] == 14 then
			AddGear(specialPointsX[i], specialPointsY[i], gtTarget, 0, 0, 0, 0)

		--Barrels
		elseif specialPointsFlag[i] == 15 then
			SetHealth(AddGear(specialPointsX[i], specialPointsY[i], gtExplosives, 0, 0, 0, 0),1)
		elseif specialPointsFlag[i] == 16 then
			SetHealth(AddGear(specialPointsX[i], specialPointsY[i], gtExplosives, 0, 0, 0, 0),25)
		elseif specialPointsFlag[i] == 17 then
			SetHealth(AddGear(specialPointsX[i], specialPointsY[i], gtExplosives, 0, 0, 0, 0),50)
		elseif specialPointsFlag[i] == 18 then
			SetHealth(AddGear(specialPointsX[i], specialPointsY[i], gtExplosives, 0, 0, 0, 0),75)
		elseif specialPointsFlag[i] == 19 then
			SetHealth(AddGear(specialPointsX[i], specialPointsY[i], gtExplosives, 0, 0, 0, 0),100)

		-- There are about 58+- weps / utils
		-- Weapon Crates
		elseif (specialPointsFlag[i] >= 20) and (specialPointsFlag[i] < (#atkArray+20)) then
			tempG = SpawnAmmoCrate(specialPointsX[i],specialPointsY[i],atkArray[specialPointsFlag[i]-19][1])
			setGearValue(tempG,"contents",atkArray[specialPointsFlag[i]-19][2])


		-- Utility Crates
		elseif (specialPointsFlag[i] >= (#atkArray+20)) and (specialPointsFlag[i] < (#atkArray+20+#utilArray)) then
			tempG = SpawnUtilityCrate(specialPointsX[i],specialPointsY[i],utilArray[specialPointsFlag[i]-19-#atkArray][1])
			setGearValue(tempG,"contents",utilArray[specialPointsFlag[i]-19-#atkArray][2])

		--79-82 (reserved for future wep crates)
		--89,88,87,86 and 85,84,83,82 (reserved for the 2 custom sprites and their landflags)

		--90-99 reserved for scripted structures

		elseif specialPointsFlag[i] == 98 then
			portalDistance = div(specialPointsX[i],5)
			ufoFuel = specialPointsY[i]

		-- Normal Girders
		elseif specialPointsFlag[i] == 100 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 0, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 101 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 1, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 102 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 2, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 103 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 3, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 104 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 4, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 105 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 5, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 106 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 6, 4294967295, nil, nil, nil, lfNormal)
		elseif specialPointsFlag[i] == 107 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 7, 4294967295, nil, nil, nil, lfNormal)

		-- Invulnerable Girders
		elseif specialPointsFlag[i] == 108 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 0, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 109 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 1, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 110 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 2, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 111 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 3, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 112 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 4, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 113 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 5, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 114 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 6, 2516582650, nil, nil, nil, lfIndestructible)
		elseif specialPointsFlag[i] == 115 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 7, 2516582650, nil, nil, nil, lfIndestructible)

		-- Icy Girders
		elseif specialPointsFlag[i] == 116 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 0, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 117 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 1, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 118 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 2, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 119 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 3, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 120 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 4, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 121 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 5, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 121 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 6, 16448250, nil, nil, nil, lfIce)
		elseif specialPointsFlag[i] == 123 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmGirder, 7, 16448250, nil, nil, nil, lfIce)

		-- Rubber Bands
		elseif specialPointsFlag[i] == 124 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmRubber, 0, 4294967295, nil, nil, nil, lfBouncy)
		elseif specialPointsFlag[i] == 125 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmRubber, 1, 4294967295, nil, nil, nil, lfBouncy)
		elseif specialPointsFlag[i] == 126 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmRubber, 2, 4294967295, nil, nil, nil, lfBouncy)
		elseif specialPointsFlag[i] == 127 then
			PlaceSprite(specialPointsX[i], specialPointsY[i], sprAmRubber, 3, 4294967295, nil, nil, nil, lfBouncy)

		-- Waypoints
		else -- 0 / no value
			PlaceWaypoint(specialPointsX[i],specialPointsY[i])
		end

	end

end

--shoppabalance crap
function AddShoppaPoint(x,y,c)
	table.insert(shoppaPX, x)
	table.insert(shoppaPY, y)
	table.insert(shoppaPR, c)
end

function GetRankedColour(r)
	if r == 1 then
		return(0xFF0000FF)
	elseif r == 2 then
		return(0xFFFF00FF)
	elseif r == 3 then
		return(0x00FF00FF)
	elseif r == 4 then
		return(0x0000FFFF)
	elseif r == 5 then
		return(0xFF00FFFF)
	end
end

-----------------------------------------
-- PRIMARY HEDGE EDITOR PLACEMENT STUFF
-----------------------------------------

function GetClosestGear()
	closestDist = 999999999
	closestGear = nil
	runOnGears(SelectGear)
	return(closestGear)
end

function SelectGear(gear)

	d = GetDistFromGearToXY(gear, placedX[placedCount], placedY[placedCount])

	if d < closestDist then
		closestDist = d
		closestGear = gear
	end

end

function PlaceWaypoint(x,y)

	placedX[placedCount] = x
	placedY[placedCount] = y
	placedType[placedCount] = loc("Waypoint Editing Mode")
	placedLandFlags[placedCount] = nil -- use this to specify waypoint type maybe
	placedHWMapFlag[placedCount] = 0

	placedSprite[placedCount] = vgtCircle
	placedSpec[placedCount] = AddVisualGear(x,y,vgtCircle,0,true)
	placedTint[placedCount] = 0xFF0000FF
	placedFrame[placedCount] = 1
	SetVisualGearValues(placedSpec[placedCount], x, y, 164, 224, 1, 10, 0, wpRadius, 5, placedTint[placedCount])
	placedCount = placedCount +1

end

function LoadSprite(pX, pY, pSprite, pFrame, pTint, p1, p2, p3, pLandFlags)

	placedX[placedCount] = pX
	placedY[placedCount] = pY
	placedSpec[placedCount] = nil

	if pSprite == sprAmGirder then

		placedType[placedCount] = loc("Girder Placement Mode")

		--newHWMapStuff
		if pLandFlags == lfIndestructible then	specialMod = 1
		elseif pLandFlags == lfIce then	specialMod = 2
		else specialMod = 0
		end
		placedHWMapFlag[placedCount] = pFrame+100+(8*specialMod)


	elseif pSprite == sprAmRubber then

		placedType[placedCount] = loc("Rubber Placement Mode")

		--newHWMapStuff
		if pFrame == 0 then placedHWMapFlag[placedCount] = 124
		elseif pFrame == 1 then placedHWMapFlag[placedCount] = 125
		elseif pFrame == 2 then placedHWMapFlag[placedCount] = 126
		elseif pFrame == 3 then placedHWMapFlag[placedCount] = 127
		end

	else
		placedType[placedCount] = loc("Sprite Placement Mode")
	end

	if pLandFlags == lfIce then
		placedLandFlags[placedCount] = "lfIce"
	elseif pLandFlags == lfIndestructible then
		placedLandFlags[placedCount] = "lfIndestructible"
	elseif pLandFlags == lfBouncy then
		placedLandFlags[placedCount] = "lfBouncy"
	else
		placedLandFlags[placedCount] = "lfNormal"
	end

	placedTint[placedCount] = pTint
	placedFrame[placedCount] = pFrame

	placedSprite[placedCount] = pSprite

	local success = PlaceSprite(pX, pY, pSprite, pFrame, pTint, nil, nil, nil, pLandFlags)
	if succcess then
		placedCount = placedCount + 1
	end

end

function CallPlaceSprite(pID, silent)

	if silent == nil then
		silent = false
	end

	if landType == lfIce then
		placedLandFlags[pID] = "lfIce"
		placedTint[pID] = 250 + (250*0x100) + (250*0x10000) + (0*0x1000000) -- A BGR
	elseif landType == lfIndestructible then
		placedLandFlags[pID] = "lfIndestructible"
		placedTint[pID] = 250 + (0*0x100) + (0*0x10000) + (150*0x1000000) -- A BGR
	elseif landType == lfBouncy then
		placedLandFlags[pID] = "lfBouncy"
		placedTint[pID] = 250 + (0*0x100) + (250*0x10000) + (0*0x1000000) -- A BGR
	else
		placedLandFlags[pID] = "lfNormal"
		--placedTint[pID] = nil
		placedTint[pID] = 255 + (255*0x100) + (255*0x10000) + (255*0x1000000) -- A BGR
	end

	-- Special case: Placing amAirAttack of the ammos sprite (since this one is overwritten)
	local actualDisplayedImage = placedFrame[pID]
	if (placedSprite[pID] == sprAMAmmos or placedSprite[pID] == sprAMAmmosBW) and (actualDisplayedImage == (amAirAttack - 1)) then
		actualDisplayedImage = ammoFrameAirAttack
	end

	local success = PlaceSprite(placedX[pID], placedY[pID], placedSprite[pID], actualDisplayedImage,
		placedTint[pID],
		nil, -- overrite existing land
		nil, nil, -- this stuff specifies flipping
		landType)

	if not silent then
		if success then
			PlaySound(sndPlaced)
		else
			PlaySound(sndDenied)
		end
	end

	return success

end

function SelectClosestSprite()

	closestDist = 999999999
	closestSpriteID = nil -- just in case

	for i = 0, (placedCount-1) do
		if (placedType[i] == loc("Girder Placement Mode"))
			or (placedType[i] == loc("Rubber Placement Mode"))
			or (placedType[i] == loc("Sprite Placement Mode"))
		then
				q = placedX[i] - placedX[placedCount]
				w = placedY[i] - placedY[placedCount]
				d = ( (q*q) + (w*w) )
				if d < closestDist then
					closestDist = d
					closestSpriteID = i

					newTint = 0xFF00FFFF

					SetVisualGearValues(sSprite, placedX[i], placedY[i], 0, 0, nil, placedFrame[i], 10000, placedSprite[i], 10000, newTint )

				end
		end
	end

end

function EraseClosestSprite()
	if closestSpriteID ~= nil then
		EraseSprite(placedX[closestSpriteID], placedY[closestSpriteID], placedSprite[closestSpriteID], placedFrame[closestSpriteID],
                    nil, -- erase land only where the pixels match the land flag provided
                    nil, -- only erase the provided land flags. don't touch other land flags or LandPixels
                    nil, -- flip sprite horizontally
                    nil, -- flip sprite vertically
                    placedLandFlags[closestSpriteID])

                PlaySound(sndBump)

		placedX[closestSpriteID] = nil
		placedY[closestSpriteID] = nil
		placedSpec[closestSpriteID] = nil
		placedType[closestSpriteID] = nil
		placedTint[closestSpriteID] = nil
		placedSprite[closestSpriteID] = nil
		placedFrame[closestSpriteID] = nil
		placedLandFlags[closestSpriteID] = nil
		closestSpriteID = nil
		SetVisualGearValues(sSprite, 0, 0, 0, 0, 0, 1, 10000, sprAmGirder, 10000, 0x00000000 )
	else
		PlaySound(sndDenied)
	end
end

-- work this into the above two functions and edit them, later
function EraseClosestWaypoint()

	closestDist = 999999999
	closestSpriteID = nil -- just in case

	for i = 0, (placedCount-1) do
		if (placedType[i] == loc("Waypoint Editing Mode")) then
			local q = placedX[i] - placedX[placedCount]
			local w = placedY[i] - placedY[placedCount]
			local d = ( (q*q) + (w*w) )
			if d < closestDist then
				closestDist = d
				closestSpriteID = i

				SetVisualGearValues(sSprite, placedX[i], placedY[i], 0, 0, nil, placedFrame[i], 10000, placedSprite[i], 10000, newTint )
			end
		end
	end

	if closestSpriteID ~= nil then
		DeleteVisualGear(placedSpec[closestSpriteID])
		placedX[closestSpriteID] = nil
		placedY[closestSpriteID] = nil
		placedSpec[closestSpriteID] = nil
		placedType[closestSpriteID] = nil
		placedTint[closestSpriteID] = nil
		placedSprite[closestSpriteID] = nil
		placedFrame[closestSpriteID] = nil
		placedLandFlags[closestSpriteID] = nil
		closestSpriteID = nil
		SetVisualGearValues(sSprite, 0, 0, 0, 0, 0, 1, 10000, sprAmGirder, 10000, 0x00000000 )
		PlaySound(sndBump)
	else
		PlaySound(sndDenied)
	end
end


-- essentially called when user clicks the mouse
-- with girders or an airattack
function PlaceObject(x,y)

	placedX[placedCount] = x
	placedY[placedCount] = y
	placedType[placedCount] = cat[cIndex]
	placedSpec[placedCount] = pMode[pIndex]
	placedTint[placedCount] = nil
	placedFrame[placedCount] = nil
	placedLandFlags[placedCount] = nil
	placedSprite[placedCount] = nil
	placedHWMapFlag[placedCount] = nil
	placementSucceeded = true		-- We assume success unless the placement logic said otherwise

	if cat[cIndex] == loc("Girder Placement Mode") then

		if superDelete == false then
			--lfObject and lfBasic
			placedFrame[placedCount] = CGR
			placedSprite[placedCount] = sprAmGirder
			placementSucceeded = CallPlaceSprite(placedCount)

			if placementSucceeded then
				if landType == lfIndestructible then	specialMod = 1
				elseif landType == lfIce then	specialMod = 2
				else specialMod = 0
				end
				placedHWMapFlag[placedCount] = CGR+100+(8*specialMod)
			else
				placedType[placedCount] = "bogus"
			end
		else
			placedType[placedCount] = "bogus" -- we need this so we don't think we've placed a new girder and are trying to erase the things we just placed??
			SelectClosestSprite()
			EraseClosestSprite()
		end

	elseif cat[cIndex] == loc("Rubber Placement Mode") then

		if superDelete == false then
			placedFrame[placedCount] = CGR
			placedSprite[placedCount] = sprAmRubber

			--new ermagerd
			placedLandFlags[placedCount] = "lfBouncy"
			placedTint[placedCount] = 255 + (255*0x100) + (255*0x10000) + (255*0x1000000) -- A BGR
			placementSucceeded = PlaceSprite(placedX[placedCount], placedY[placedCount], placedSprite[placedCount], placedFrame[placedCount],
				placedTint[placedCount],
				nil,
				nil, nil,
				landType)

			if placementSucceeded then
				if CGR == 0 then placedHWMapFlag[placedCount] = 124
				elseif CGR == 1 then placedHWMapFlag[placedCount] = 125
				elseif CGR == 2 then placedHWMapFlag[placedCount] = 126
				elseif CGR == 3 then placedHWMapFlag[placedCount] = 127
				end
				PlaySound(sndPlaced)
			else
				placedType[placedCount] = "bogus"
				PlaySound(sndDenied)
			end
		else
			placedType[placedCount] = "bogus"
			SelectClosestSprite()
			EraseClosestSprite()
		end

	elseif cat[cIndex] == loc("Target Placement Mode") then
		gear = AddGear(x, y, gtTarget, 0, 0, 0, 0)
	elseif cat[cIndex] == loc("Cleaver Placement Mode") then
		gear = AddGear(x, y, gtKnife, 0, 0, 0, 0)
	elseif cat[cIndex] == loc("Health Crate Placement Mode") then
		gear = SpawnHealthCrate(x,y)
		SetHealth(gear, pMode[pIndex])
	elseif cat[cIndex] == loc("Weapon Crate Placement Mode") then
		gear = SpawnAmmoCrate(x, y, atkArray[pIndex][1])
		placedSpec[placedCount] = atkArray[pIndex][2]
		setGearValue(gear,"contents",atkArray[pIndex][2])
	elseif cat[cIndex] == loc("Utility Crate Placement Mode") then
		gear = SpawnUtilityCrate(x, y, utilArray[pIndex][1])
		placedSpec[placedCount] = utilArray[pIndex][2]
		setGearValue(gear,"contents",utilArray[pIndex][2])
	elseif cat[cIndex] == loc("Barrel Placement Mode") then
		gear = AddGear(x, y, gtExplosives, 0, 0, 0, 0)
		SetHealth(gear, pMode[pIndex])
	elseif cat[cIndex] == loc("Mine Placement Mode") then
		gear = AddGear(x, y, gtMine, 0, 0, 0, 0)
		SetTimer(gear, pMode[pIndex])
	elseif cat[cIndex] == loc("Dud Mine Placement Mode") then
		gear = AddGear(x, y, gtMine, 0, 0, 0, 0)
		SetHealth(gear, 0)
		SetGearValues(gear, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 36 - pMode[pIndex])
	elseif cat[cIndex] == loc("Sticky Mine Placement Mode") then
		gear = AddGear(x, y, gtSMine, 0, 0, 0, 0)
		SetTimer(gear, pMode[pIndex])
	elseif cat[cIndex] == loc("Air Mine Placement Mode") then
		gear = AddGear(x, y, gtAirMine, 0, 0, 0, 0)
		SetTimer(gear, pMode[pIndex])
		SetGearValues(gear, nil, nil, pMode[pIndex])
	elseif cat[cIndex] == loc("Repositioning Mode") then

		if pMode[pIndex] == loc("Selection Mode") then
			sGear = GetClosestGear()
			if sGear ~= nil then
				PlaySound(sndPortalSwitch)
			end
		elseif pMode[pIndex] == loc("Placement Mode") then
			if sGear ~= nil then
				SetGearPosition(sGear, x, y)
				PlaySound(sndWarp)
			end
		elseif pMode[pIndex] == loc("Deletion Mode") then
			sGear = GetClosestGear()
			if (sGear == nil) then
				AddCaption(loc("Please click on a gear."), colorErrorMessage, capgrpVolume)
				PlaySound(sndDenied)
			elseif (GetGearType(sGear) == gtHedgehog) then
				AddCaption(loc("Hedgehogs can not be deleted."), colorErrorMessage, capgrpVolume)
				PlaySound(sndDenied)
			else
				DeleteGear(sGear)
				PlaySound(sndBump)
			end
			sGear = nil
		end

	elseif (cat[cIndex] == loc("Hog Identity Mode")) or (cat[cIndex] == loc("Team Identity Mode")) then

		sGear = GetClosestGear()
		if (sGear ~= nil) and (GetGearType(sGear) == gtHedgehog) then
			if (cat[cIndex] == loc("Hog Identity Mode")) then
				SetHogProfile(sGear, pMode[pIndex])
			else -- set for the whole team
				SetTeamIdentity(sGear)
			end
			PlaySound(sndHello, sGear)
		else
			AddCaption(loc("Please click on a hedgehog."), colorErrorMessage, capgrpVolume)
			PlaySound(sndDenied)
		end



	elseif cat[cIndex] == loc("Health Modification Mode") then

		sGear = GetClosestGear()
		local gt = GetGearType(sGear)
		if gt == gtHedgehog or gt == gtExplosives or (gt == gtCase and GetGearPos(sGear) == 0x2) then
			local oldHealth, hDiff = GetHealth(sGear)
			if pMode[pIndex][2] == "set" then
				SetHealth(sGear, pMode[pIndex][1])
				hDiff = pMode[pIndex][1] - oldHealth
			elseif pMode[pIndex][2] == "mod" then
				local min
				if gt == gtCase then min = 0 else min = 1 end
				local newHealth = math.max(min, GetHealth(sGear) + tonumber(pMode[pIndex][1]))
				SetHealth(sGear, newHealth)
				hDiff = newHealth - oldHealth
			end
			PlaySound(sndPortalSwitch)
			if gt == gtHedgehog and hDiff < 0 then
				local snd = { sndOw1, sndOw2, sndOw3 }
				PlaySound(snd[math.random(1, #snd)], sGear)
			end
		elseif gt == gtMine and GetHealth(sGear) == 0 then
			local newHealth 
			if pMode[pIndex][2] == "set" then
				newHealth =  pMode[pIndex][1]
			elseif pMode[pIndex][2] == "mod" then
				local _, oldHealth
				_,_,_,_,_,_,_,_,_,_,_, oldHealth = GetGearValues(sGear)
				oldHealth = 36 - oldHealth
				newHealth = math.max(1, oldHealth + tonumber(pMode[pIndex][1]))
			end
			if newHealth ~= nil then
				SetGearValues(sGear, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 36 - newHealth)
				PlaySound(sndPortalSwitch)
			end
		else
			AddCaption(loc("Please click on a hedgehog, barrel, health crate or dud mine."), colorErrorMessage, capgrpVolume)
			PlaySound(sndDenied)
		end

	elseif cat[cIndex] == loc("Sprite Modification Mode") then

		SelectClosestSprite()

		if closestSpriteID ~= nil then
			if pMode[pIndex] == loc("LandFlag Modification Mode") then
				EraseSprite(placedX[closestSpriteID], placedY[closestSpriteID], placedSprite[closestSpriteID], placedFrame[closestSpriteID], nil, nil, nil, nil, placedLandFlags[closestSpriteID])
				placementSucceeded = CallPlaceSprite(closestSpriteID, true)
				if placementSucceeded then
					closestSpriteID = nil
					SetVisualGearValues(sSprite, 0, 0, 0, 0, 0, 1, 10000, sprAmGirder, 10000, 0x00000000 )
					PlaySound(sndPortalSwitch)
				else
					PlaySound(sndDenied)
				end
			elseif pMode[pIndex] == loc("Sprite Erasure Mode") then

				EraseClosestSprite()

			end
		else
			PlaySound(sndDenied)
		end


	elseif cat[cIndex] == loc("Goal Definition Mode") then

		sGear = GetClosestGear()
		if sGear ~= nil then  -- used to be closestGear

			if getGearValue(sGear,"tag") == nil then

				if pMode[pIndex] == loc("Victory Condition: Collect") then
					if GetGearType(sGear) == gtCase then
						setGearValue(sGear, "tag","collection")
						PlaySound(sndPortalSwitch)
					else
						AddCaption(loc("Please click on a crate."), colorErrorMessage, capgrpVolume)
						PlaySound(sndDenied)
					end
				else
					if pMode[pIndex] == loc("Victory Condition: Destroy") then
						setGearValue(sGear, "tag","victory")
						PlaySound(sndPortalSwitch)
					elseif pMode[pIndex] == loc("Losing Condition: Destroy") then
						setGearValue(sGear, "tag","failure")
						PlaySound(sndPortalSwitch)
					end
				end

			else
				-- remove tag and delete circ
				setGearValue(sGear, "tag", nil)
				DeleteVisualGear(getGearValue(sGear,"tCirc"))
				setGearValue(sGear, "tCirc", nil)
				PlaySound(sndBump)
			end



		end


	elseif cat[cIndex] == loc("Sprite Placement Mode") then

		if superDelete == false then
			placedFrame[placedCount] = sFrame
			placedSprite[placedCount] = reducedSpriteIDArray[pIndex]
			placementSucceeded = CallPlaceSprite(placedCount)
		else
			placedType[placedCount] = "bogus"
			SelectClosestSprite()
			EraseClosestSprite()
		end

	elseif cat[cIndex] == loc("Waypoint Editing Mode") then


		if pMode[pIndex] == loc("Delete Waypoint") then
			placedType[placedCount] = "bogus"
			EraseClosestWaypoint()
		else
			PlaceWaypoint(x,y)
			placedCount = placedCount - 1
			PlaySound(sndPlaced)
		end

	end

	placedCount = placedCount + 1
end

-- called when user changes primary selection
-- either via up/down keys
-- or selecting girder/airattack
function RedefineSubset()

	superDelete = false -- fairly new addition
	landType = 0 --- fairly new addition
	pIndex = 1
	pMode = {}

	if cat[cIndex] == loc("Girder Placement Mode") then
		pIndex = CGR
		pMode = {loc("Girder")}
	elseif cat[cIndex] == loc("Rubber Placement Mode") then
		pIndex = CGR
		pMode = {loc("Rubber")}
		landType = lfBouncy -- for now, let's not allow anything else (-- fairly new addition)
	elseif cat[cIndex] == loc("Target Placement Mode") then
		pMode = {loc("Target")}
	elseif cat[cIndex] == loc("Cleaver Placement Mode") then
		pMode = {loc("Cleaver")}
	elseif cat[cIndex] == loc("Barrel Placement Mode") then
		pMode = {60,80,100,120,160,200,240,1,10,20,30,40,50}
	elseif cat[cIndex] == loc("Health Crate Placement Mode") then
		pMode = {25,30,40,50,75,100,150,200,0,5,10,15,20}
	elseif cat[cIndex] == loc("Weapon Crate Placement Mode") then
		for i = 1, #atkArray do
			pMode[i] = GetAmmoName(atkArray[i][1], true)
		end
	elseif cat[cIndex] == loc("Utility Crate Placement Mode") then
		for i = 1, #utilArray do
			pMode[i] = GetAmmoName(utilArray[i][1], true)
		end
	elseif cat[cIndex] == loc("Mine Placement Mode") then
		pMode = {3000,4000,5000,0,1000,2000}
	elseif cat[cIndex] == loc("Dud Mine Placement Mode") then
		pMode = {36,48,60,72,96,1,6,12,18,24}
	elseif cat[cIndex] == loc("Mine Placement Mode") then
		pMode = {3000,4000,5000,0,1000,2000}
	elseif cat[cIndex] == loc("Sticky Mine Placement Mode") then
		pMode = {500,1000,1500,2000,2500,0}
	elseif cat[cIndex] == loc("Air Mine Placement Mode") then
		pMode = {750,1000,1250,0,250,500}
	elseif cat[cIndex] == loc("Repositioning Mode") then
		pMode = {loc("Selection Mode"),loc("Placement Mode"), loc("Deletion Mode")}
	elseif cat[cIndex] == loc("Goal Definition Mode") then
		pMode = {loc("Victory Condition: Destroy"),loc("Losing Condition: Destroy"),loc("Victory Condition: Collect")}
	elseif cat[cIndex] == loc("Hog Identity Mode") then
		pMode = {loc("Soldier"),loc("Grenadier"),loc("Sniper"),loc("Pyro"),loc("Ninja"),loc("Commander"),loc("Chef"),loc("Engineer"),loc("Physicist"),loc("Trapper"),loc("Saint"),loc("Clown")}
	elseif cat[cIndex] == loc("Team Identity Mode") then
		pMode = preMadeTeamNamesTranslated
	elseif cat[cIndex] == loc("Health Modification Mode") then
		pMode = { {100, "set"}, {125, "set"}, {150, "set"}, {200, "set"}, {300, "set"}, {1000, "set"},
			{"-100", "mod"}, {"-10", "mod"}, {"-1", "mod"}, {"+1", "mod"}, {"+10", "mod"}, {"+100", "mod"},
			{1, "set"}, {10, "set"}, {15, "set"}, {20, "set"}, {25, "set"}, {30, "set"}, {40, "set"}, {50, "set"}, {75, "set"}, 
} 
	elseif cat[cIndex] == loc("Sprite Modification Mode") then
		pMode = {loc("LandFlag Modification Mode"),loc("Sprite Erasure Mode")}
	elseif cat[cIndex] == loc("Sprite Testing Mode") or cat[cIndex] == loc("Sprite Placement Mode") then
		for i = 1, #reducedSpriteTextArray do
			pMode[i] = reducedSpriteTextArray[i]
		end
		sFrame = 0
	elseif cat[cIndex] == loc("Waypoint Editing Mode") then
		pMode = {loc("Place Waypoint"), loc("Delete Waypoint")}
	end

end

------------------------------------------------
-- LOADING AND SAVING DATA STUFF
------------------------------------------------

-- paste data you have saved previously here
function LoadLevelData()

	if (mapID == nil) or (mapID == 0) then
		LoadMap(1)
	else
		LoadMap(mapID)
	end

	for i = 1, techCount-1 do
		PlaceWaypoint(techX[i],techY[i])
	end

end

-- When you save your level, this function
-- generates the AddTeam and AddHog function calls for onGameInit()
function GetDataForSavingHogs(gear)

	--this is a quick hack so that the human team(s) will always be
	--given the first move ahead of the AI
	local tempDataList = {}
	if GetHogLevel(gear) == 0 then
		tempDataList = hogDataList
	else
		tempDataList = AIHogDataList
	end

	if GetHogTeamName(gear) ~= lastRecordedTeam then

		teamCounter = teamCounter + 1
		if teamCounter == 9 then
			teamCounter = 1
		end

		-- Convert color to string
		local rgba = GetClanColor(GetHogClan(gear))
		local rgb = div(band(rgba, 0xFFFFFF00), 0x100)
		local tColor = string.format("0x%X", rgb)

		local tFort, tGrave, tFlag, tVoice
		if getGearValue(gear,"grave") == nil then
			tFort = GetHogFort(gear)
			tGrave = GetHogGrave(gear)
			tFlag = GetHogFlag(gear)
			tVoice = GetHogVoicepack(gear)
		else
			tGrave = getGearValue(gear,"grave")
			tFort = getGearValue(gear,"fort")
			tFlag = getGearValue(gear,"flag")
			tVoice = getGearValue(gear,"voice")
		end
		if not tFort then tFort = "Castle" end
		if not tGrave then tGrave = "Statue" end
		if not tFlag then tFlag= "hedgewars" end
		if not tVoice then tVoice = "Default" end

		lastRecordedTeam = GetHogTeamName(gear)

		table.insert(tempDataList, "")

		local oTeamName = getGearValue(gear, "originalTeamName")
		if oTeamName == nil or oTeamName == "" then
			oTeamName = GetHogTeamName(gear)
		end
		table.insert	(tempDataList,
						"	AddTeam(loc(\"" ..
						oTeamName  .. "\")" ..
						", " .. tColor ..
						", " .. "\"" .. tGrave .. "\"" ..
						", " .. "\"" .. tFort .. "\"" ..
						", " .. "\"" .. tVoice .. "\"" ..
						", " .. "\"" .. tFlag .. "\"" ..
						")"
						)

	end

	table.insert(hhs, gear)

	local oName = getGearValue(gear, "originalName")
	if oName == nil or oName == "" then
		oName = GetHogName(gear)
	end
	table.insert	(tempDataList,	"	hhs[" .. #hhs .."] = AddHog(loc(\"" ..
					oName .. "\"), " ..
					GetHogLevel(gear) .. ", " ..
					GetHealth(gear) .. ", \"" ..
					GetHogHat(gear) .. "\"" ..
					")"
			)

	table.insert	(tempDataList,"	SetGearPosition(hhs[" .. #hhs .. "], " .. GetX(gear) .. ", " .. GetY(gear) .. ")")

	for e=1, #effectArray do
		if GetEffect(gear, effectArray[e]) ~= 0 then
			table.insert	(tempDataList,"	SetEffect(hhs[" .. #hhs .. "], " .. effectStr[e] .. ", " .. GetEffect(gear, effectArray[e]) .. ")")
		end
	end
	local dX, _ = GetGearVelocity(gear)
	if dX < 0 then
		table.insert	(tempDataList,"	HogTurnLeft(hhs[" .. #hhs .. "], true)")
	end

	if getGearValue(gear,"tag") ~= nil then
		table.insert	(tempDataList,"	setGearValue(hhs[" .. #hhs .. "], \"tag\", \"" .. getGearValue(gear,"tag") .. "\")")
	end

	-- save the ammo values for each gear, we will call this later
	-- when we want to output it to console

	if getGearValue(gear,"ranking") ~= nil then
		table.insert(shoppaPointList, "AddShoppaPoint(" .. GetX(gear) .. ", " .. GetY(gear) .. ", " .. getGearValue(gear,"ranking") .. ")")
	end

	for i = 1, #atkArray do
		setGearValue(gear, atkArray[i][1], GetAmmoCount(gear, atkArray[i][1]))
	end

	for i = 1, #utilArray do
		setGearValue(gear, utilArray[i][1], GetAmmoCount(gear, utilArray[i][1]))
	end

	if GetHogLevel(gear) == 0 then
		hogDataList = tempDataList
	else
		AIHogDataList = tempDataList
	end

end

-- output hog and team data to the console
function SaveHogData()

	teamCounter = 0
	lastRecordedTeam = ""
	hhs = {}

	runOnHogs(GetDataForSavingHogs)

	WriteLnToConsole("	------ TEAM LIST ------")

	for i = 1, #hogDataList do
		WriteLnToConsole(hogDataList[i])
	end

	for i = 1, #AIHogDataList do
		WriteLnToConsole(AIHogDataList[i])
	end

	WriteLnToConsole("")

	if #shoppaPointList > 0 then
		WriteLnToConsole("	------ SHOPPA POINT LIST ------")
		for i = 1, #shoppaPointList do
			WriteLnToConsole(shoppaPointList[i])
		end
	end


end

-- generates an onGameInit() template with scheme data, team adds, and hogs
function SaveConfigData()

	WriteLnToConsole("function onGameInit()")
	WriteLnToConsole("")

	temp = "	EnableGameFlags(gfDisableWind"
	for i = 1, #gameFlagList do
		if gameFlagList[i][2] == true then
			temp = temp .. ", ".. gameFlagList[i][1]
		end
	end

	WriteLnToConsole("	ClearGameFlags()")
	WriteLnToConsole(temp .. ")")

	WriteLnToConsole("	Map = \"" .. Map .. "\"")
	WriteLnToConsole("	Seed = \"" .. Seed .. "\"")
	WriteLnToConsole("	Theme = \"" .. Theme .. "\"")
	WriteLnToConsole("	MapGen = " .. MapGen)
	WriteLnToConsole("	MapFeatureSize = " .. MapFeatureSize)
	WriteLnToConsole("	TemplateFilter = " .. TemplateFilter)
	WriteLnToConsole("	TemplateNumber = " .. TemplateNumber)
	WriteLnToConsole("	TurnTime = " .. TurnTime)
	WriteLnToConsole("	Explosives = " .. Explosives)
	WriteLnToConsole("	MinesNum = " .. MinesNum)
	WriteLnToConsole("	CaseFreq = " .. CaseFreq)
	WriteLnToConsole("	Delay = " .. Delay)

	WriteLnToConsole("	HealthCaseProb = " .. HealthCaseProb)
	WriteLnToConsole("	HealthCaseAmount = " .. HealthCaseAmount)
	WriteLnToConsole("	DamagePercent = " .. DamagePercent)
	WriteLnToConsole("	RopePercent = " .. RopePercent)
	WriteLnToConsole("	MinesTime = " .. MinesTime)
	WriteLnToConsole("	MineDudPercent  = " .. MineDudPercent)
	WriteLnToConsole("	SuddenDeathTurns = " .. SuddenDeathTurns)
	WriteLnToConsole("	WaterRise = " .. WaterRise)
	WriteLnToConsole("	HealthDecrease = " .. HealthDecrease)

	WriteLnToConsole("	Ready = " .. Ready)
	WriteLnToConsole("	AirMinesNum = " .. AirMinesNum)
	WriteLnToConsole("	GetAwayTime = " .. GetAwayTime)
	WriteLnToConsole("	WorldEdge = " .. WorldEdge)

	-- ScriptParam intentionally left out, it doesn't make sense for missions.

	WriteLnToConsole("")

	SaveHogData()

	WriteLnToConsole("")
	WriteLnToConsole("end")

end

-- output gear data as special points to be placed in a converted HWMAP, readable by InterpretPoints()
function ConvertGearDataToHWPText()

	WriteLnToConsole("")
	WriteLnToConsole("--BEGIN HWMAP CONVERTER POINTS--")
	WriteLnToConsole("-- You can paste this data into the HWMAP converter if needed.")
	WriteLnToConsole("--[[")
	WriteLnToConsole("")

	for i = 1, #hFlagList do
		WriteLnToConsole(hFlagList[i])
	end

	WriteLnToConsole("")
	WriteLnToConsole("]]")
	WriteLnToConsole("--END HWMAP CONVERTER POINTS--")
	WriteLnToConsole("")

end

-- sigh
-- gradually got more bloated with the addition of hwpoint tracking and
-- distinction betweeen the need to track victory/win conditions or not
function GetDataForGearSaving(gear)

	local temp = nil
	local specialFlag = nil
	local arrayList = nil

	if GetGearType(gear) == gtMine then

		temp = 	"	tempG = AddGear(" ..
			GetX(gear) .. ", " ..
			GetY(gear) .. ", gtMine, 0, 0, 0, 0)"
		table.insert(mineList, temp)
		table.insert(mineList, "	SetTimer(tempG, " .. GetTimer(gear) .. ")")
		if (GetHealth(gear) == 0) then
			table.insert(mineList, "	SetHealth(tempG, 0)")
			local _, damage
			_,_,_,_,_,_,_,_,_,_,_,damage = GetGearValues(gear)
			if damage ~= 0 then
				table.insert(mineList, "	SetGearValues(tempG, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "..damage..")")
			end
		end
		if (getGearValue(gear, "tag") ~= nil) then
			table.insert(mineList, "	setGearValue(tempG, \"tag\", \"" .. getGearValue(gear,"tag") .. "\")")
		end

		if 		GetTimer(gear) == 0 then specialFlag = 1
		elseif	GetTimer(gear) == 1000 then specialFlag = 2
		elseif	GetTimer(gear) == 2000 then specialFlag = 3
		elseif	GetTimer(gear) == 3000 then specialFlag = 4
		elseif	GetTimer(gear) == 4000 then specialFlag = 5
		elseif	GetTimer(gear) == 5000 then specialFlag = 6
		end

	elseif GetGearType(gear) == gtSMine then

		arrayList = sMineList
		temp = 	"	tempG = AddGear(" ..
				GetX(gear) .. ", " ..
				GetY(gear) .. ", gtSMine, 0, 0, 0, 0)"
		table.insert(sMineList, temp)
		table.insert(sMineList, "	SetTimer(tempG, " .. GetTimer(gear) .. ")")
		specialFlag = 7

	elseif GetGearType(gear) == gtAirMine then

		temp = 	"	tempG = AddGear(" ..
			GetX(gear) .. ", " ..
			GetY(gear) .. ", gtAirMine, 0, 0, 0, 0)"
		table.insert(airMineList, temp)
		table.insert(airMineList, "	SetTimer(tempG, " .. GetTimer(gear) .. ")")
		table.insert(airMineList, "	SetGearValues(tempG, nil, nil, " .. GetTimer(gear) .. ")")
		if (getGearValue(gear, "tag") ~= nil) then
			table.insert(airMineList, "	setGearValue(tempG, \"tag\", \"" .. getGearValue(gear,"tag") .. "\")")
		end

		table.insert(previewDataList, "	PreviewPlacedGear(" .. GetX(gear) ..", " ..	GetY(gear) .. ")")
		specialFlag = 8

	elseif GetGearType(gear) == gtExplosives then

		temp = 	"	tempG = AddGear(" ..
			GetX(gear) .. ", " ..
			GetY(gear) .. ", gtExplosives, 0, 0, 0, 0)"
		table.insert(explosivesList, temp)
		table.insert(explosivesList, "	SetHealth(tempG, " .. GetHealth(gear) .. ")")
		if (getGearValue(gear, "tag") ~= nil) then
			table.insert(explosivesList, "	setGearValue(tempG, \"tag\", \"" .. getGearValue(gear,"tag") .. "\")")
		end

		table.insert(previewDataList, "	PreviewPlacedGear(" .. GetX(gear) ..", " ..	GetY(gear) .. ")")

		if 		GetHealth(gear) == 1 then specialFlag = 15
		elseif	GetHealth(gear) == 25 then specialFlag = 16
		elseif	GetHealth(gear) == 50 then specialFlag = 17
		elseif	GetHealth(gear) == 75 then specialFlag = 18
		elseif	GetHealth(gear) == 100 then specialFlag = 19
		end

	elseif GetGearType(gear) == gtTarget then

		arrayList = targetList
		temp = 	"	tempG = AddGear(" ..
				GetX(gear) .. ", " ..
				GetY(gear) .. ", gtTarget, 0, 0, 0, 0)"
		table.insert(targetList, temp)
		specialFlag = 14

	elseif GetGearType(gear) == gtKnife then

		arrayList = knifeList
		temp = 	"	tempG = AddGear(" ..
				GetX(gear) .. ", " ..
				GetY(gear) .. ", gtKnife, 0, 0, 0, 0)"
		table.insert(knifeList, temp)
		specialFlag = 13

	elseif GetGearType(gear) == gtCase then

		table.insert(previewDataList, "	PreviewPlacedGear(" .. GetX(gear) ..", " ..	GetY(gear) .. ")")

		-- Health crate
		if band(GetGearPos(gear), 0x2) ~= 0 then

			temp = 	"	tempG = SpawnHealthCrate(" ..
				GetX(gear) ..", " ..
				GetY(gear) ..", " ..
				GetHealth(gear) .. ")"
			table.insert(healthCrateList, temp)
			if (getGearValue(gear, "tag") ~= nil) then
				table.insert(healthCrateList, "	setGearValue(tempG, \"tag\", \"" .. getGearValue(gear,"tag") .. "\")")
			end

			if 		GetHealth(gear) == 25 then specialFlag = 9
			elseif	GetHealth(gear) == 50 then specialFlag = 10
			elseif	GetHealth(gear) == 75 then specialFlag = 11
			elseif	GetHealth(gear) == 100 then specialFlag = 12
			end

		-- Ammo crate
		elseif band(GetGearPos(gear), 0x1) ~= 0 then

			arrayList = wepCrateList
			temp = 	"	tempG = SpawnAmmoCrate(" ..
					GetX(gear) ..", " ..
					GetY(gear) ..", " ..
					getGearValue(gear,"contents") ..
					")"
			table.insert(wepCrateList, temp)

			tempV = getGearValue(gear,"contents")
			for i = 1, #atkArray do
				if tempV == atkArray[i][2] then
					specialFlag = i + 19
				end
			end

			--dammit, we probably need more entries if we want to allow editing of existing maps
			table.insert(wepCrateList, "	setGearValue(tempG, \"contents\", \"" .. getGearValue(gear,"contents") .. "\")")

		-- Utility crate
		elseif band(GetGearPos(gear), 0x4) ~= 0 then

			arrayList = utilCrateList
			temp = 	"	tempG = SpawnUtilityCrate(" ..
					GetX(gear) ..", " ..
					GetY(gear) ..", " ..
					getGearValue(gear,"contents") ..
					")"
			table.insert(utilCrateList, temp)

			tempV = getGearValue(gear,"contents")
			for i = 1, #utilArray do
				if tempV == utilArray[i][2] then
					specialFlag = i + 19 + #atkArray
				end
			end

			--dammit, we probably need more entries if we want to allow editing of existing maps
			table.insert(utilCrateList, "	setGearValue(tempG, \"contents\", \"" .. getGearValue(gear,"contents") .. "\")")

		end

	end

	-- add tracking of simple win/lose for simpler gears that have a tempG = listed above
	if (getGearValue(gear, "tag") ~= nil) and (arrayList ~= nil) then
		table.insert(arrayList, "	setGearValue(tempG, \"tag\", \"" .. getGearValue(gear,"tag") .. "\")")
	end

	-- this creates a big, messy list of special flags for use in hwmaps
	if specialFlag ~= nil then
		table.insert(hFlagList, "	" .. GetX(gear) .. " " .. GetY(gear) .. " " .. specialFlag)
	end

end

-- generate a title and list all the gears if there is at least 1 of them in the list
function AppendGearList(gearList, consoleLine)
	if #gearList > 0 then
		WriteLnToConsole(consoleLine)
		for i = 1, #gearList do
			WriteLnToConsole(gearList[i])
		end
		WriteLnToConsole("")
	end
end

-- new attempt at doing shit a bit cleaner:
-- it may be a bit verbose, but this should generate a comprehensive, human-readable
-- list of gears, broken up into sections and output it to the console
function SaveGearData()

	runOnGears(GetDataForGearSaving)

	AppendGearList(healthCrateList, "	------ HEALTH CRATE LIST ------")
	AppendGearList(wepCrateList, "	------ AMMO CRATE LIST ------")
	AppendGearList(utilCrateList, "	------ UTILITY CRATE LIST ------")
	AppendGearList(explosivesList, "	------ BARREL LIST ------")
	AppendGearList(mineList, "	------ MINE LIST ------")
	AppendGearList(sMineList, "	------ STICKY MINE LIST ------")
	AppendGearList(airMineList, "	------ AIR MINE LIST ------")
	AppendGearList(targetList, "	------ TARGET LIST ------")
	AppendGearList(knifeList, "	------ CLEAVER LIST ------")

end

function DoAmmoLoop(i)

	for x = 1, #atkArray do
		if getGearValue(hhs[i],atkArray[x][1]) ~= 0 then
			WriteLnToConsole("	AddAmmo(hhs[" .. i .. "], " .. atkArray[x][2] .. ", " .. getGearValue(hhs[i],atkArray[x][1]) .. ")")
		end
	end

	for x = 1, #utilArray do
		if getGearValue(hhs[i],utilArray[x][1]) ~= 0 then
			WriteLnToConsole("	AddAmmo(hhs[" .. i .. "], " .. utilArray[x][2] .. ", " .. getGearValue(hhs[i],utilArray[x][1]) .. ")")
		end
	end

	WriteLnToConsole("")

end

-- this is called when a tagged gear is deleted during a mission
-- it determines if the game is ready to conclude in victory/defeat
function CheckForConclusion(gear)

	-- failure gears must always all be protected, so if any of them are destroyed the player loses
	if getGearValue(gear,"tag") == "failure" then
		EndGameIn("failure")
	else

		-- the presence of other tagged gears means that the goal of this mission is not
		-- simply to kill every hedgehog. Thus, we need to count the remaining tagged objects
		-- to see how close we are to completing the mission successfully.
		victoryObj = 0
		failObj = 0
		collectObj = 0
		runOnGears(CheckForConditions)

		if GetGearType(gear) ~= gtCase then

			-- non-crates can only be tagged as victory or failure, and as this wasn't tagged
			-- "failure" in our earlier check, this must be a victory tagged gear. Let's adust
			-- the number of objects accordingly as it's in the process of being destroyed.
			victoryObj = victoryObj - 1

			-- if there are no objectives left to complete, end the game in victory
			if (victoryObj == 0) and (collectObj == 0) then
				EndGameIn("victory")
			end

		else
			-- this crate was deleted, but was it collected or destroyed, and how does that match
			-- the goals of our mission?
			if (GetGearMessage(gear) == 256) and (getGearValue(gear,"tag") == "collection") then
				if GetHogLevel(CurrentHedgehog) == 0 then
					-- the enemy stole our crate
					EndGameIn("failure")
				else
					collectObj = collectObj - 1
					if (victoryObj == 0) and (collectObj == 0) then
						EndGameIn("victory")
					end
				end
			elseif (GetGearMessage(gear) == 0) and (getGearValue(gear,"tag") == "victory") then
				victoryObj = victoryObj - 1
				if (victoryObj == 0) and (collectObj == 0) then
					EndGameIn("victory")
				end
			else
				-- unfortunately, we messed up our mission.
				EndGameIn("failure")
			end

		end

	end

end

---------------------------------
-- THE BIG ONE
---------------------------------
-- saving process starts here
-- saves all level data to logs/game0.log and generates a simple script template
function SaveLevelData()

	waypointList = {}
	girderList = {}
	rubberList = {}
	spriteList = {}
	mineList = {}
	sMineList = {}
	airMineList = {}
	targetList = {}
	knifeList = {}
	explosivesList = {}
	healthCrateList = {}
	wepCrateList = {}
	utilCrateList = {}
	hFlagList = {}
	previewDataList = {}
	shoppaPointList = {}
	hogDataList = {}
	AIHogDataList = {}

	WriteLnToConsole("------ BEGIN SCRIPT ------")
	WriteLnToConsole("-- Copy and Paste this text into an empty text file, and save it as")
	WriteLnToConsole("-- YOURTITLEHERE.lua, in your Data/Missions/Training/ folder.")

	WriteLnToConsole("")

	WriteLnToConsole("HedgewarsScriptLoad(\"/Scripts/Locale.lua\")")
	WriteLnToConsole("HedgewarsScriptLoad(\"/Scripts/Tracker.lua\")")

	WriteLnToConsole("")
	WriteLnToConsole("local hhs = {}")
	WriteLnToConsole("")

	SaveConfigData()


	WriteLnToConsole("")
	WriteLnToConsole("function LoadHogWeapons()")
	WriteLnToConsole("")

	if band(GameFlags, gfPerHogAmmo) ~= 0 then -- per hog ammo
		for i = 1, #hhs do
			DoAmmoLoop(i)
		end

	else	-- team-based ammo

		teamCounter = 0
		lastRecordedTeam = ""
		for i = 1, #hhs do

			if GetHogTeamName(hhs[i]) ~= lastRecordedTeam then
				lastRecordedTeam = GetHogTeamName(hhs[i])
				teamCounter = teamCounter + 1
				if teamCounter == 9 then
					teamCounter = 1
				end
				DoAmmoLoop(i)
			end

		end

	end


	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("")
	WriteLnToConsole("function LoadSprite(pX, pY, pSprite, pFrame, pTint, p1, p2, p3, pLandFlags)")
	WriteLnToConsole("	PlaceSprite(pX, pY, pSprite, pFrame, pTint, p1, p2, p3, pLandFlags)")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("")
	WriteLnToConsole("function LoadGearData()")
	WriteLnToConsole("")

	WriteLnToConsole("	--BEGIN CORE DATA--")
	WriteLnToConsole("")

	WriteLnToConsole("	------ PORTAL DISTANCE and UFO FUEL ------")
	WriteLnToConsole("	ufoFuel = " .. ufoFuel)
	WriteLnToConsole("	portalDistance = " .. portalDistance*5)
	table.insert(hFlagList, "	" .. portalDistance*5 .. " " .. ufoFuel .. " " .. 98)
	WriteLnToConsole("")

	for i = 0, (placedCount-1) do
		if placedType[i] == loc("Waypoint Editing Mode") then
			--[[ TODO/FIXME: Somehow incorporate the waypoints in an actual useful manner.
			The functions AddWayPoint and PreviewWayPoint do not exist and will thus be commented-out
			in the output code. They are added anyway so the user sees the coordinates
			]]
			table.insert(waypointList,
			"--	AddWayPoint(" ..
				placedX[i] ..", " ..
				placedY[i] ..")"
				)
			table.insert(hFlagList, "	" .. placedX[i] .. " " .. placedY[i] .. " " .. "0")
			table.insert(previewDataList, "--	PreviewWayPoint(" .. placedX[i] ..", " ..	placedY[i] .. ")")
		end
	end

	for i = 0, (placedCount-1) do
		if placedType[i] == loc("Girder Placement Mode") then
			table.insert(girderList,
			"	LoadSprite(" ..
				placedX[i] ..", " ..
				placedY[i] ..", sprAmGirder, " ..
				placedFrame[i] ..			-- the rotation/frame
				", " ..
				placedTint[i] ..", " .. -- color
				"nil, nil, nil, " ..
				placedLandFlags[i] .. ")" --the landType
				)
			table.insert(hFlagList, "	" .. placedX[i] .. " " .. placedY[i] .. " " .. placedHWMapFlag[i])
			table.insert(previewDataList, "	PreviewGirder(" .. placedX[i] ..", " ..	placedY[i] .. ", " .. placedFrame[i] .. ")")
		end
	end

	for i = 0, (placedCount-1) do
		if placedType[i] == loc("Rubber Placement Mode") then
			table.insert(rubberList,
				"	LoadSprite(" ..
				placedX[i] ..", " ..
				placedY[i] ..", sprAmRubber, " ..
				placedFrame[i] ..
				", " ..
				placedTint[i] ..", " .. -- color
				"nil, nil, nil, " ..
				"lfBouncy)" --the landType
				)
			table.insert(hFlagList, "	" .. placedX[i] .. " " .. placedY[i] .. " " .. placedHWMapFlag[i])
			table.insert(previewDataList, "	PreviewRubber(" .. placedX[i] ..", " ..	placedY[i] .. ", " .. placedFrame[i] .. ")")
		end
	end

	for i = 0, (placedCount-1) do
		if placedType[i] == loc("Sprite Placement Mode") then
				table.insert(spriteList,
				"	LoadSprite(" ..
				placedX[i] ..", " ..
				placedY[i] ..", " .. placedSprite[i] .. ", " ..
				placedFrame[i] .. -- I think this is the frame, can't remember
				", " ..
				placedTint[i] ..", " .. -- color
				"nil, nil, nil, " ..
				placedLandFlags[i] .. ")" --the landType
				)
		end
	end

	AppendGearList(waypointList, "	------ WAYPOINT LIST ------")
	AppendGearList(girderList, "	------ GIRDER LIST ------")
	AppendGearList(rubberList, "	------ RUBBER LIST ------")
	AppendGearList(spriteList, "	------ SPRITE LIST ------")

	SaveGearData()

	WriteLnToConsole("	--END CORE DATA--")


	WriteLnToConsole("")
	WriteLnToConsole("	LoadHogWeapons()")
	WriteLnToConsole("")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("")
	WriteLnToConsole("function onGameStart()")
	WriteLnToConsole("")
	WriteLnToConsole("	LoadGearData()")
	WriteLnToConsole("	DetermineMissionGoal()")
	WriteLnToConsole("")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("")
	WriteLnToConsole("function onNewTurn()")
	WriteLnToConsole("	--insert code according to taste")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("")
	WriteLnToConsole("function onGameTick()")
	WriteLnToConsole("	runOnGears(UpdateTagCircles)")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("function UpdateTagCircles(gear)")
	WriteLnToConsole("	if getGearValue(gear,\"tag\") ~= nil then")
	WriteLnToConsole("		if getGearValue(gear,\"tCirc\") == nil then")
	WriteLnToConsole("			setGearValue(gear, \"tCirc\",AddVisualGear(0,0,vgtCircle,0,true))")
	WriteLnToConsole("		end")
	WriteLnToConsole("")
	WriteLnToConsole("		if getGearValue(gear,\"tag\") == \"victory\" then")
	WriteLnToConsole("			SetVisualGearValues(getGearValue(gear,\"tCirc\"), GetX(gear), GetY(gear), 100, 255, 1, 10, 0, 150, 3, 0xff0000ff)")
	WriteLnToConsole("		elseif getGearValue(gear,\"tag\") == \"failure\" then")
	WriteLnToConsole("			SetVisualGearValues(getGearValue(gear,\"tCirc\"), GetX(gear), GetY(gear), 100, 255, 1, 10, 0, 150, 3, 0x00ff00ff)")
	WriteLnToConsole("		elseif getGearValue(gear,\"tag\") == \"collection\" then")
	WriteLnToConsole("			SetVisualGearValues(getGearValue(gear,\"tCirc\"), GetX(gear), GetY(gear), 100, 255, 1, 10, 0, 150, 3, 0x0000ffff)")
	WriteLnToConsole("		end")
	WriteLnToConsole("	end")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("function CheckForConditions(gear)")
	WriteLnToConsole("	if getGearValue(gear,\"tag\") == \"victory\" then")
	WriteLnToConsole("		victoryObj = victoryObj +1")
	WriteLnToConsole("	elseif getGearValue(gear,\"tag\") == \"failure\" then")
	WriteLnToConsole("		failObj = failObj +1")
	WriteLnToConsole("	elseif getGearValue(gear,\"tag\") == \"collection\" then")
	WriteLnToConsole("		collectObj = collectObj +1")
	WriteLnToConsole("	end")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("function CheckForConclusion(gear)")
	WriteLnToConsole("")
	WriteLnToConsole("	if getGearValue(gear,\"tag\") == \"failure\" then ")
	WriteLnToConsole("		EndGameIn(\"failure\")")
	WriteLnToConsole("	else ")
	WriteLnToConsole("")
	WriteLnToConsole("		victoryObj = 0")
	WriteLnToConsole("		failObj = 0")
	WriteLnToConsole("		collectObj = 0")
	WriteLnToConsole("		runOnGears(CheckForConditions)")
	WriteLnToConsole("")
	WriteLnToConsole("		if GetGearType(gear) ~= gtCase then")
	WriteLnToConsole("")
	WriteLnToConsole("			victoryObj = victoryObj - 1 ")
	WriteLnToConsole("")
	WriteLnToConsole("			if (victoryObj == 0) and (collectObj == 0) then")
	WriteLnToConsole("				EndGameIn(\"victory\")")
	WriteLnToConsole("			end")
	WriteLnToConsole("")
	WriteLnToConsole("		else")
	WriteLnToConsole("")
	WriteLnToConsole("			if (GetGearMessage(gear) == 256) and (getGearValue(gear,\"tag\") == \"collection\") then ")
	WriteLnToConsole("				if GetHogLevel(CurrentHedgehog) ~= 0 then")
	WriteLnToConsole("					EndGameIn(\"failure\")")
	WriteLnToConsole("				else")
	WriteLnToConsole("					collectObj = collectObj - 1")
	WriteLnToConsole("					if (victoryObj == 0) and (collectObj == 0) then")
	WriteLnToConsole("						EndGameIn(\"victory\")")
	WriteLnToConsole("					end")
	WriteLnToConsole("				end")
	WriteLnToConsole("			elseif (GetGearMessage(gear) == 0) and (getGearValue(gear,\"tag\") == \"victory\") then")
	WriteLnToConsole("				victoryObj = victoryObj - 1")
	WriteLnToConsole("				if (victoryObj == 0) and (collectObj == 0) then ")
	WriteLnToConsole("					EndGameIn(\"victory\")")
	WriteLnToConsole("				end")
	WriteLnToConsole("			else")
	WriteLnToConsole("				EndGameIn(\"failure\")")
	WriteLnToConsole("			end")
	WriteLnToConsole("")
	WriteLnToConsole("		end")
	WriteLnToConsole("")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("function DetermineMissionGoal()")
	WriteLnToConsole("")
	WriteLnToConsole("	victoryObj = 0")
	WriteLnToConsole("	failObj = 0")
	WriteLnToConsole("	collectObj = 0")
	WriteLnToConsole("	vComment = \"\"")
	WriteLnToConsole("	fComment = \"\"")
	WriteLnToConsole("	collectComment = \"\"")
	WriteLnToConsole("")
	WriteLnToConsole("	runOnGears(CheckForConditions)")
	WriteLnToConsole("")
	WriteLnToConsole("	if victoryObj > 0 then ")
	WriteLnToConsole("		if victoryObj == 1 then ")
	WriteLnToConsole("			vComment = loc(\"- Destroy the red target\") .. \"|\"")
	WriteLnToConsole("		else ")
	WriteLnToConsole("			vComment = loc(\"- Destroy the red targets\") .. \"|\"")
	WriteLnToConsole("		end")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("	if collectObj > 0 then ")
	WriteLnToConsole("		if collectObj == 1 then ")
	WriteLnToConsole("			collectComment = loc(\"- Collect the blue crate\") .. \"|\"")
	WriteLnToConsole("		else ")
	WriteLnToConsole("			collectComment = loc(\"- Collect all the blue crates\") .. \"|\"")
	WriteLnToConsole("		end")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("	if (collectObj == 0) and (victoryObj == 0) then")
	WriteLnToConsole("		vComment = loc(\"- Destroy the enemy\") .. \"|\"")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("	if failObj > 0 then ")
	WriteLnToConsole("		if failObj == 1 then ")
	WriteLnToConsole("			fComment = loc(\"- The green target must survive\") .. \"|\"")
	WriteLnToConsole("		else ")
	WriteLnToConsole("			fComment = loc(\"- The green targets must survive\") .. \"|\"")
	WriteLnToConsole("		end")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("	ShowMission(loc(\"User Mission\"), loc(\"Mission\"), collectComment .. vComment .. fComment, 1, 0)")
	WriteLnToConsole("")
	WriteLnToConsole("end")

	WriteLnToConsole("")
	WriteLnToConsole("function isATrackedGear(gear)")
	WriteLnToConsole("	if 	(GetGearType(gear) == gtHedgehog) or")
	WriteLnToConsole("		(GetGearType(gear) == gtExplosives) or")
	WriteLnToConsole("		(GetGearType(gear) == gtMine) or")
	WriteLnToConsole("		(GetGearType(gear) == gtSMine) or")
	WriteLnToConsole("		(GetGearType(gear) == gtAirMine) or")
	WriteLnToConsole("		(GetGearType(gear) == gtTarget) or")
	WriteLnToConsole("		(GetGearType(gear) == gtKnife) or")
	WriteLnToConsole("		(GetGearType(gear) == gtPortal) or")
	WriteLnToConsole("		(GetGearType(gear) == gtCase)")
	WriteLnToConsole("	then")
	WriteLnToConsole("		return(true)")
	WriteLnToConsole("	else")
	WriteLnToConsole("		return(false)")
	WriteLnToConsole("	end")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("")
	WriteLnToConsole("function onGearAdd(gear)")


	WriteLnToConsole("	if isATrackedGear(gear) then")
	WriteLnToConsole("		trackGear(gear)")

	WriteLnToConsole("	end")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("")
	WriteLnToConsole("function EndGameIn(c)")
	WriteLnToConsole("")
	WriteLnToConsole("	teamCounter = 0")
	WriteLnToConsole("	lastRecordedTeam = \"\" ")
	WriteLnToConsole("	for i = 1, #hhs do")
	WriteLnToConsole("")
	WriteLnToConsole("		if GetHogTeamName(hhs[i]) ~= lastRecordedTeam then --er, is this okay without nill checks?")
	WriteLnToConsole("")
	WriteLnToConsole("			lastRecordedTeam = GetHogTeamName(hhs[i])")
	WriteLnToConsole("			teamCounter = teamCounter + 1")
	WriteLnToConsole("			if teamCounter == 9 then")
	WriteLnToConsole("				teamCounter = 1")
	WriteLnToConsole("			end")
	WriteLnToConsole("")
	WriteLnToConsole("			if (c ==  \"victory\") and (GetHogLevel(hhs[i]) ~= 0) then")
	WriteLnToConsole("				DismissTeam(GetHogTeamName(hhs[i]))")
	WriteLnToConsole("				AddCaption(loc(\"Victory!\"), 0xFFFFFFFF, capgrpGameState)")
	WriteLnToConsole("				ShowMission(loc(\"User Mission\"), loc(\"Mission\"), loc(\"Mission succeeded!\"), 0, 0)")
	WriteLnToConsole("			elseif (c ==  \"failure\") and (GetHogLevel(hhs[i]) == 0) then")
	WriteLnToConsole("				DismissTeam(GetHogTeamName(hhs[i]))")
	WriteLnToConsole("				AddCaption(loc(\"Defeat!\"), 0xFFFFFFFF, capgrpGameState)")
	WriteLnToConsole("				ShowMission(loc(\"User Mission\"), loc(\"Mission\"), loc(\"Mission failed!\"), -amSkip, 0)")
	WriteLnToConsole("			elseif (c ==  \"victory\") and (GetHogLevel(hhs[i]) == 0) then")
	WriteLnToConsole("				PlaySound(sndVictory,hhs[i]) -- check if we actually need this")
	WriteLnToConsole("			end")
	WriteLnToConsole("")
	WriteLnToConsole("		end")
	WriteLnToConsole("")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("")
	WriteLnToConsole("function onGearDelete(gear)")
	WriteLnToConsole("")
	WriteLnToConsole("	--insert code according to taste")
	WriteLnToConsole("")
	WriteLnToConsole("	if isATrackedGear(gear) then")
	WriteLnToConsole("")
	WriteLnToConsole("		if getGearValue(gear,\"tag\") ~= nil then")
	WriteLnToConsole("			CheckForConclusion(gear)")
	WriteLnToConsole("		end")

	WriteLnToConsole("")
	WriteLnToConsole("		if getGearValue(gear, \"tCirc\") ~= nil then")
	WriteLnToConsole("			DeleteVisualGear(getGearValue(gear, \"tCirc\"))")
	WriteLnToConsole("		end")
	WriteLnToConsole("")
	WriteLnToConsole("		trackDeletion(gear)")
	WriteLnToConsole("")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("")
	WriteLnToConsole("--enable and/or alter code according to taste")
	WriteLnToConsole("function onAmmoStoreInit()")
	WriteLnToConsole("")

	WriteLnToConsole("	for i = 0, AmmoTypeMax do")
	WriteLnToConsole("		if i ~= amNothing then")
	WriteLnToConsole("			SetAmmo(i, 0, 0, 0, 1)")
	WriteLnToConsole("		end")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("	SetAmmo(amSkip, 9, 0, 0, 0)")
	WriteLnToConsole("")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	WriteLnToConsole("------ END GENERATED MISSION ------")

	-- at this point, generation for the missions/training output is intended to stop

	WriteLnToConsole("")
	WriteLnToConsole("function GeneratePreviewData()")
	WriteLnToConsole("")
	for i = 1, #previewDataList do
		WriteLnToConsole(previewDataList[i])
	end
	WriteLnToConsole("")
	WriteLnToConsole("end")
	WriteLnToConsole("")

	ConvertGearDataToHWPText()

	WriteLnToConsole("------ END GENERATED SCRIPT ------")

	AddCaption(loc("Level Data Saved!"), colorInfoMessage, capgrpGameState)

end

----------------------------------
-- some special effects handling
----------------------------------
function SmokePuff(x,y,c)
	tempE = AddVisualGear(x, y, vgtSmoke, 0, false)
	SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, 1, nil, c )
end

function HandleGearBasedRankingEffects(gear)
	if getGearValue(gear, "ranking") ~= nil then
		SmokePuff(GetX(gear), GetY(gear),GetRankedColour(getGearValue(gear, "ranking")))
	end
end

function HandleRankingEffects()
	for i = 1, #shoppaPX do
		SmokePuff(shoppaPX[i], shoppaPY[i], GetRankedColour(shoppaPR[i]))
	end
	runOnHogs(HandleGearBasedRankingEffects)
end

function UpdateTagCircles(gear)

	if getGearValue(gear,"tag") ~= nil then

		if cat[cIndex] == loc("Goal Definition Mode") then

			-- generate circs for tagged gears that don't have a circ yet (new)
			if getGearValue(gear,"tCirc") == nil then
				setGearValue(gear, "tCirc",AddVisualGear(0,0,vgtCircle,0,true))
			end

			if getGearValue(gear,"tag") == "victory" then
				SetVisualGearValues(getGearValue(gear,"tCirc"), GetX(gear), GetY(gear), 100, 255, 1, 10, 0, 150, 3, 0xff0000ff)
			elseif getGearValue(gear,"tag") == "failure" then
				SetVisualGearValues(getGearValue(gear,"tCirc"), GetX(gear), GetY(gear), 100, 255, 1, 10, 0, 150, 3, 0x00ff00ff)
			elseif getGearValue(gear,"tag") == "collection" then
				SetVisualGearValues(getGearValue(gear,"tCirc"), GetX(gear), GetY(gear), 100, 255, 1, 10, 0, 150, 3, 0x0000ffff)
			end

		else
			SetVisualGearValues(getGearValue(gear,"tCirc"), GetX(gear), GetY(gear), 0, 1, 1, 10, 0, 1, 1, 0x00000000)
		end

	end

end

-- handle short range portal gun
function PortalEffects(gear)

	if GetGearType(gear) == gtPortal then

		tag = GetTag(gear)
		if tag == 0 then
			col = 0xfab02aFF -- orange ball
		elseif tag == 1 then
			col = 0x00FF00FF -- orange portal
		elseif tag == 2 then
			col = 0x364df7FF  -- blue ball
		elseif tag == 3 then
			col = 0xFFFF00FF  -- blue portal
		end

		if (tag == 0) or (tag == 2) then -- i.e ball form
			tempE = AddVisualGear(GetX(gear), GetY(gear), vgtDust, 0, true)
			SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, 1, nil, col )

			remLife = getGearValue(gear,"life")
			remLife = remLife - 1
			setGearValue(gear, "life", remLife)

			if remLife == 0 then

				tempE = AddVisualGear(GetX(gear)+15, GetY(gear), vgtSmoke, 0, true)
				SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, col)

				tempE = AddVisualGear(GetX(gear)-15, GetY(gear), vgtSmoke, 0, true)
				SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, col)

				tempE = AddVisualGear(GetX(gear), GetY(gear)+15, vgtSmoke, 0, true)
				SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, col)

				tempE = AddVisualGear(GetX(gear), GetY(gear)-15, vgtSmoke, 0, true)
				SetVisualGearValues(tempE, nil, nil, nil, nil, nil, nil, nil, nil, col)


				PlaySound(sndVaporize)
				DeleteGear(gear)

			end

		end

	end

end

function updateHelp(curAmmoType)
	if curAmmoType == nil then
		curAmmoType = GetCurAmmoType()
	end

	if (curAmmoType ~= amGirder) and (curAmmoType ~= amRubber) and (curAmmoType ~= amCMGearPlacementTool) then

		if not hedgeEditorMissionPanelShown then
			showHedgeEditorMissionPanel()
		end

	elseif cat[cIndex] == loc("Girder Placement Mode") then

		ShowMission	(
				loc("GIRDER PLACEMENT MODE"),
				loc("Place girders"),
				loc("Place Girder: [Left Click]") .. "|" ..
				loc("Change Rotation: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Normal Girder: [1]") .. "|" ..
				loc("Indestructible Girder: [2]") .. "|" ..
				loc("Icy Girder: [3]") .. "|" ..
				loc("Bouncy Girder: [4]") .. "|" ..
				" " .. "|" ..
				loc("Deletion Mode: [5]") .. "|" ..
				" " .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", -amGirder, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Rubber Placement Mode") then

		ShowMission	(
				loc("RUBBER PLACEMENT MODE"),
				loc("Place rubber"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Rotation: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Normal Rubber: [1]") .. "|" ..
				" " .. "|" ..
				loc("Deletion Mode: [5]") .. "|" ..
				" " .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", -amRubber, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Barrel Placement Mode") then

		ShowMission	(
				loc("BARREL PLACEMENT MODE"),
				loc("Place barrels"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Health: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 8, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Cleaver Placement Mode") then

		ShowMission	(
				loc("CLEAVER PLACEMENT MODE"),
				loc("Place cleavers"),
				loc("Place Object: [Left Click]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", -amKnife, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Target Placement Mode") then

		ShowMission	(
				loc("TARGET PLACEMENT MODE"),
				loc("Place targets"),
				loc("Place Object: [Left Click]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 1, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Waypoint Editing Mode") then

		ShowMission	(
				loc("WAYPOINT EDITING MODE"),
				loc("Place or delete waypoints"),
				loc("Place/Delete Waypoint: [Left Click]") .. "|" ..
				loc("Toggle Placement/Deletion: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", -amCMGearPlacementTool, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Mine Placement Mode") then

		ShowMission	(
				loc("MINE PLACEMENT MODE"),
				loc("Place mines"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Timer: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", -amMine, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Dud Mine Placement Mode") then

		ShowMission	(
				loc("DUD MINE PLACEMENT MODE"),
				loc("Place dud mines"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Health: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 9, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Sticky Mine Placement Mode") then

		ShowMission	(
				loc("STICKY MINE PLACEMENT MODE"),
				loc("Place sticky mines"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Timer: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", -amSMine, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Air Mine Placement Mode") then

		ShowMission	(
				loc("AIR MINE PLACEMENT MODE"),
				loc("Place air mines"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Timer: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", -amAirMine, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Weapon Crate Placement Mode") then

		ShowMission	(
				loc("WEAPON CRATE PLACEMENT MODE"),
				loc("Place weapon crates"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Content: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 7, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Utility Crate Placement Mode") then

		ShowMission	(
				loc("UTILITY CRATE PLACEMENT MODE"),
				loc("Place utility crates"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Content: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 5, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Health Crate Placement Mode") then

		ShowMission	(
				loc("HEALTH CRATE PLACEMENT MODE"),
				loc("Place health crates"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Health Boost: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 6, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Repositioning Mode") then

		ShowMission	(
				loc("REPOSITIONING MODE"),
				loc("Select, reposition and delete gears"),
				loc("Select/Place/Delete Gear: [Left Click]") .. "|" ..
				loc("Choose Selection/Placement/Deletion: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", -amCMGearPlacementTool, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Sprite Modification Mode") then

		ShowMission	(
				loc("SPRITE MODIFICATION MODE"),
				loc("Select, modify, or delete girders, rubbers and sprites"),
				loc("Modify Sprite under Cursor: [Left Click]") .. "|" ..
				loc("Change modification mode: [Left], [Right]") .."|"..
				loc("While in modification mode, you can change|the LandFlag by clicking on an object.") .. "|" ..
				" " .. "|" ..
				loc("Normal Land: [1]") .. "|" ..
				loc("Indestructible Land: [2]") .. "|" ..
				loc("Icy Land: [3]") .. "|" ..
				loc("Bouncy Land: [4]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 2, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Sprite Placement Mode") then

		ShowMission	(
				loc("SPRITE PLACEMENT MODE"),
				loc("Place sprites to build land"),
				loc("Place Sprite: [Left Click]") .. "|" ..
				loc("Change Sprite: [Left], [Right]") .. "|" ..
				loc("Change Sprite Frame: [Precise]+[Left], [Precise]+[Right]") .. "|" ..
				" " .. "|" ..
				loc("Normal Land: [1]") .. "|" ..
				loc("Indestructible Land: [2]") .. "|" ..
				loc("Icy Land: [3]") .. "|" ..
				loc("Bouncy Land: [4]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", -amCMGearPlacementTool, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Goal Definition Mode") then

		ShowMission	(
				loc("GOAL DEFINITION MODE"),
				loc("Mark gears for win/lose conditions"),
				loc("Mark/unmark gear: [Left Click]") .. "|" ..
				loc("Select win/lose condition: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 0, 60000
				)
		hedgeEditorMissionPanelShown = false
	elseif cat[cIndex] == loc("Hog Identity Mode") then

		ShowMission	(
				loc("HOG IDENTITY MODE"),
				loc("Give a hog a preset identity and weapons"),
				loc("Set Identity: [Left Click]") .. "|" ..
				loc("[Left], [Right]: Change between identities.") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 3, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Team Identity Mode") then

		ShowMission	(
				loc("TEAM IDENTITY MODE"),
				loc("Give an entire team themed hats and names"),
				loc("Set Identity: [Left Click]") .. "|" ..
				loc("[Left], [Right]: Change between identities.") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 3, 60000
				)
		hedgeEditorMissionPanelShown = false

	elseif cat[cIndex] == loc("Health Modification Mode") then

		ShowMission	(
				loc("HEALTH MODIFICATION MODE"),
				loc("Set the health of hogs, health crates, barrels and duds"),
				loc("Set Health: [Left Click]") .. "|" ..
				loc("[Left], [Right]: Change health value.") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: [Precise]+[1]") .. "|" ..
				loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
				"", 2, 60000
				)
		hedgeEditorMissionPanelShown = false

	end


	if helpDisabled == true then
		HideMission()
		hedgeEditorMissionPanelShown = false
	end

end

function onSetWeapon(ammoType)
	curWep = ammoType
	updateHelp(ammoType)
end

function onSlot()
	curWep = GetCurAmmoType()
	updateHelp(ammoType)
end

function onScreenResize()
	updateCursorCoords()
end

-- Display the X and Y coordinates of the cursor while the cursor is active
function updateCursorCoords()
	if band(GetState(CurrentHedgehog), gstChooseTarget) ~= 0 and CursorX ~= -2147483648 then
		local x1, y = 12, 24
		if tagCursorX then
			DeleteVisualGear(tagCursorX)
		end
		tagCursorX = AddVisualGear(-div(ScreenWidth, 2)+x1, y, vgtHealthTag, CursorX, true)
		SetVisualGearValues(tagCursorX, nil, nil, 0, 0, nil, 1, nil, nil, 240000, 0xFFFFFFFF)

		local x2
		if string.len(tostring(CursorX)) > 6 then
			x2 = x1 + 100
		else
			x2 = x1 + 60
		end
		if tagCursorY then
			DeleteVisualGear(tagCursorY)
		end
		tagCursorY = AddVisualGear(-div(ScreenWidth, 2)+x2, y, vgtHealthTag, CursorY, true)
		SetVisualGearValues(tagCursorY, nil, nil, 0, 0, nil, 1, nil, nil, 240000, 0xFFFFFFFF)
	else
		if tagCursorX then
			DeleteVisualGear(tagCursorX)
		end
		if tagCursorY then
			DeleteVisualGear(tagCursorY)
		end
	end
end

-- called in onGameTick()
function HandleHedgeEditor()
	if CurrentHedgehog ~= nil then

		genTimer = genTimer + 1

		tSprCol = 0x00000000
		tempFrame = 0
		xDisplacement = 42
		yDisplacement = 42

		if (curWep == amCMGearPlacementTool) then

			SetSoundMask(sndIncoming, true)

			--wowaweewa, holyeeeee shite this is badly hacked (please rewrite when less lazy/morefeatures)
			dCol = 0xFFFFFFFF
			dFrame = 0
			dAngle = 0
			if (cat[cIndex] == loc("Mine Placement Mode")) then
				dSprite = sprCustom2
			elseif (cat[cIndex] == loc("Dud Mine Placement Mode")) then
				dSprite = sprCustom4
			elseif (cat[cIndex] == loc("Sticky Mine Placement Mode")) then
				dSprite = sprCustom3
			elseif (cat[cIndex] == loc("Air Mine Placement Mode")) then
				dSprite = sprAirMine
			elseif (cat[cIndex] == loc("Barrel Placement Mode")) then
				dSprite = sprExplosives
			elseif (cat[cIndex] == loc("Health Crate Placement Mode")) then
				dSprite = sprFAid
			elseif (cat[cIndex] == loc("Weapon Crate Placement Mode")) then
				dSprite = sprCase
			elseif (cat[cIndex] == loc("Utility Crate Placement Mode")) then
				dSprite = sprUtility
			elseif (cat[cIndex] == loc("Target Placement Mode")) then
				dSprite = sprTarget
			elseif (cat[cIndex] == loc("Cleaver Placement Mode")) then
				dAngle = 270
				dSprite = sprKnife
			elseif (cat[cIndex] == loc("Sprite Placement Mode")) then
				dSprite = reducedSpriteIDArray[pIndex]
				dFrame = sFrame
				if ((dSprite == sprAMAmmos) or (dSprite == sprAMAmmosBW)) and (dFrame == (amCMGearPlacementTool - 1)) then
					-- Special case: Air attack icon of ammos sprite needs to be fixed (since this icon is overwritten)
					dFrame = ammoFrameAirAttack
				end
			else
				dCol = 0xFFFFFF00
				dSprite = sprArrow
			end

			if CG == nil then
				CG = AddVisualGear(CursorX, CursorY, vgtStraightShot,0,true,3)
			end
			SetVisualGearValues(CG, CursorX, CursorY, 0, 0, dAngle, dFrame, 1000, dSprite, 1000, dCol)



			if crateSprite == nil then
				crateSprite = AddVisualGear(CursorX, CursorY-35, vgtStraightShot,0,true,3)
				crateSpriteBorder = AddVisualGear(CursorX, CursorY-35, vgtStraightShot,0,true,3)
			end


			if (cat[cIndex] == loc("Weapon Crate Placement Mode")) or (cat[cIndex] == loc("Utility Crate Placement Mode")) then
				if (cat[cIndex] == loc("Weapon Crate Placement Mode")) then
					tArr = atkArray
				else
					tArr = utilArray
				end

				tSprCol = 0xFFFFFFFF
				-- Get ammo icon
				if tArr[pIndex][3] then
					-- Overwritten ammo icon
					tempFrame = tArr[pIndex][3]
				else
					-- Use default ammo icon
					tempFrame = tArr[pIndex][1] - 1
				end
			end

			-- Waypoint outline
			if (cat[cIndex] == loc("Waypoint Editing Mode")) and (pMode[pIndex] == loc("Place Waypoint")) then
				if not waypointPreviewSprite then
					waypointPreviewSprite = AddVisualGear(CursorX, CursorY, vgtCircle, 0, true)
					SetVisualGearValues(waypointPreviewSprite, CursorX, CursorY, 244, 224, 0, 0, 0, div(wpRadius, 5), 5, 0xFF0000FF)
				end
			elseif waypointPreviewSprite then
				DeleteVisualGear(waypointPreviewSprite)
				waypointPreviewSprite = nil
			end
			if waypointPreviewSprite then
				SetVisualGearValues(waypointPreviewSprite, CursorX, CursorY)
			end

		else
			SetSoundMask(sndIncoming, false)
			if CG ~= nil then
				SetVisualGearValues(CG, 0, 0, 0, 0, 0, 0, 1000, sprArrow, 1000, 0xFFFFFF00)
			end
		end

		SetVisualGearValues(crateSprite, CursorX+xDisplacement, CursorY+yDisplacement, 0, 0, dAngle, tempFrame, 1000, sprAMAmmos, 1000, tSprCol)
		SetVisualGearValues(crateSpriteBorder, CursorX+xDisplacement, CursorY+yDisplacement, 0, 0, 0, 0, 1000, sprCustom1, 1000, tSprCol)

		if genTimer >= 100 then

			genTimer = 0

			curWep = GetCurAmmoType()

			HandleRankingEffects()
			runOnGears(PortalEffects)

			-- change to girder mode on weapon swap
			if (cIndex ~= 1) and (curWep == amGirder) then
				cIndex = 1
				RedefineSubset()
				updateHelp()
			elseif (cIndex ~=2) and (curWep == amRubber) then
				cIndex = 2
				RedefineSubset()
				updateHelp()
			-- change to generic mode if girder no longer selected
			elseif (cIndex == 1) and (curWep ~= amGirder) then
				cIndex = 3 -- was 2
				RedefineSubset()
			elseif (cIndex == 2) and (curWep ~= amRubber) then
				cIndex = 3 --new
				RedefineSubset()
			end

			if curWep == amGirder or curWep == amRubber then
				SetSoundMask(sndDenied, true)
			else
				SetSoundMask(sndDenied, false)
			end

			-- update display selection criteria
			if (curWep == amGirder) or (curWep == amRubber) or (curWep == amCMGearPlacementTool) then
				AddCaption(cat[cIndex], colorPlaceMode1, capgrpMessage)
				showSecondaryMessage()
				if superDelete == true then
					AddCaption(loc("Deletition Mode"), colorPlaceMode1, capgrpAmmoinfo)
				end
			end


			if sSprite ~= nil then
				SetVisualGearValues(sSprite, nil, nil, 0, 0, nil, nil, 10000, nil, 10000 )
			end

			updateHelp()

		end

	end


	if (ufoFuel ~= 0) then
		if ufoFuel == 2000 then
			SetHealth(ufoGear, 2000)
		end
	end

	-- kinda lazy, but at least we don't have to do elaborate tacking elsewhere
	SetVisualGearValues(sCirc, 0, 0, 0, 1, 1, 10, 0, 1, 1, 0x00000000)
	--update selected gear display
	if (cat[cIndex] == loc("Repositioning Mode")) and (sGear ~= nil) then
		SetVisualGearValues(sCirc, GetX(sGear), GetY(sGear), 100, 255, 1, 10, 0, 300, 3, 0xff00ffff)
	elseif (cat[cIndex] == loc("Sprite Modification Mode")) and (sSprite ~= nil) then
		SetVisualGearValues(sSprite, nil, nil, 0, 0, nil, nil, 10000, nil, 10000)
	elseif (cat[cIndex] == loc("Goal Definition Mode")) then
		if (sGear ~= nil) or (closestGear ~= nil) then
			closestGear = nil
			sGear = nil
		end
	end


	runOnGears(UpdateTagCircles)


	-- some kind of target detected, tell me your story
	if cGear ~= nil then

		x,y = GetGearTarget(cGear)

		if GetGearType(cGear) == gtAirAttack and GetCurAmmoType() == amCMGearPlacementTool then
			DeleteGear(cGear)
			PlaceObject(x, y)
		elseif GetGearType(cGear) == gtGirder then

			CGR = GetState(cGear)

			-- improve rectangle test based on CGR when you can be bothered
			PlaceObject(x, y)
		end

	end

	-- Show cursor coords
	updateCursorCoords()

	-- Barrel health tags, mine timer tags and health crate health tags
	do
		local actualValue	-- internal value
		local printedValue	-- value exposed to HUD
		for g, v in pairs(tagGears) do
			local gt = GetGearType(g)
			if v == -1 then
				if gt == gtCase then
					if(band(GetGearPos(g), 0x2) ~= 0) then
						v = AddVisualGear(0, 0, vgtHealthTag, GetHealth(g), true)
						SetVisualGearValues(v, nil, nil, 0, 0, nil, nil, nil, nil, 240000, 0x808080FF)
						tagGears[g] = v
					else
						tagGears[g] = nil
					end
				else
					if gt == gtMine and GetHealth(g) == 0 then
						local _, damage, health
						_, _, _, _, _, _, _, _, _, _, _, damage = GetGearValues(g)
						health = 36 - damage
						v = AddVisualGear(0, 0, vgtHealthTag, health, true)
						SetVisualGearValues(v, nil, nil, 0, 0, nil, nil, nil, nil, 240000, 0x808080FF)
						tagGears[g] = v
					end
				end
			end
			-- Delete tag for drowning gears
			if(band(GetState(g), gstDrowning) ~= 0) then
				DeleteVisualGear(v)
				tagGears[g] = nil
			elseif(tagGears[g] ~= nil and tagGears[g] ~= -1) then
				local tag, actualvalue, offset_x, offset_y
				tag = GetState(v)
				if(gt == gtExplosives) then
					actualValue = GetHealth(g)
					printedValue = actualValue
					offset_y = -20
					offset_x = 0
				elseif(gt == gtAirMine) then
					if(band(GetState(g), gstAttacking) ~= 0) then
						actualValue = GetTimer(g)
						printedValue = actualValue
					else
						local _
						_, _, actualValue = GetGearValues(g)
						printedValue = actualValue
					end
					offset_y = 28
					offset_x = 16
				elseif(gt == gtCase) then
					actualValue = GetHealth(g)
					printedValue = actualValue
					offset_y = -20
					offset_x = 1
				elseif(gt == gtMine) then
					if(GetHealth(g) ~= 0) then
						-- Non-dud: Show timer
						actualValue = GetTimer(g)
						printedValue = actualValue
						offset_y = 28
						offset_x = 16
					else
						-- Dud: Show health
						local _
						_, _, _, _, _, _, _, _, _, _, _, actualValue = GetGearValues(g)
						printedValue = 36 - actualValue
						offset_y = -12
						offset_x = 0
					end
				elseif(gt == gtSMine) then
					actualValue = GetTimer(g)
					printedValue = actualValue
					offset_y = 28
					offset_x = 16
				end
				--[[ The timer tag normally disappears near the water line, this is a really
				ugly hack to adjust the position of the tag so it is always displayed.
				FIXME: Find a better solution to fix this. ]]
				if (GetY(g) + offset_y) > WaterLine and (GetY(g) + offset_y) < WaterLine + 30 then
					offset_y = (WaterLine - GetY(g))
				end
				local tint
				if(not showGearTags) then
					-- Hide the tags
					tint = 0x00000000
				elseif(gt == gtCase) then
					tint = 0x80FF80FF
				elseif(gt == gtExplosives or (gt == gtMine and GetHealth(g) == 0)) then
					tint = 0x808080FF
				elseif(band(GetState(g), gstAttacking) ~= 0) then
					if(actualValue % 1000 > 500) then
						tint = 0xFFA0A0FF
					else
						tint = 0xFF4040FF
					end
				else
					tint = 0xFFFFFFFF
				end
				if(actualValue ~= tag) then
					--[[ If timer/health changed, delete visual gear and add it again.
					Changing the visual gear state does not have any effect, so we need this hack ]]
					DeleteVisualGear(v)
					v = AddVisualGear(GetX(g)+offset_x, GetY(g)+offset_y, vgtHealthTag, printedValue, true)
					SetVisualGearValues(v, nil, nil, 0, 0, nil, nil, nil, nil, 240000, tint)
					tagGears[g] = v
				else
					-- Just update position if the health did not change
					SetVisualGearValues(v, GetX(g)+offset_x, GetY(g)+offset_y, 0, 0, nil, nil, nil, nil, 240000, tint)
				end
			end
		end
	end
end

--------------------------------------------------
-- EVENT HANDLERS
--------------------------------------------------

function commandMode()
	if (preciseOn == true) and ((GetCurAmmoType() == amNothing) or (GetCurAmmoType() == amSkip)) then
		return(true)
	else
		return(false)
	end
end

function onTimer(s)

	superDelete = false
	if (commandMode() == true) and (s == 4) then
		SaveLevelData() -- positions of crates, etc
	elseif (commandMode() == true) and (s == 2) then
		if GetAmmoCount(CurrentHedgehog, amCMGearPlacementTool) == 100 then
			SetEditingWeps(0)
			AddCaption(loc("The editor weapons and tools have been removed!"), colorInfoMessage, capgrpGameState)
		else
			SetEditingWeps(100)
			AddCaption(loc("The editor weapons and tools have been added!"), colorInfoMessage, capgrpGameState)
		end
	elseif (preciseOn == true) and (s == 1) then
		helpDisabled = not(helpDisabled)
		if helpDisabled then
			AddCaption(loc("Help Disabled"), colorInfoMessage, capgrpVolume)
		else
			AddCaption(loc("Help Enabled"), colorInfoMessage, capgrpVolume)
		end
		updateHelp()
	elseif (preciseOn == true) and (s == 3) then
		showGearTags = not(showGearTags)
		if showGearTags then
			AddCaption(loc("Gear information shown"), colorInfoMessage, capgrpVolume)
		else
			AddCaption(loc("Gear information hidden"), colorInfoMessage, capgrpVolume)
		end

	elseif (cat[cIndex] == loc("Sprite Placement Mode")) or (cat[cIndex] == loc("Girder Placement Mode")) or (cat[cIndex] == loc("Rubber Placement Mode")) or (cat[cIndex] == loc("Sprite Modification Mode")) then

		if (cat[cIndex] == loc("Rubber Placement Mode")) then
			if s == 1 then
				landType = lfBouncy
				AddCaption(loc("Bouncy Land"), colorPlaceMode1, capgrpAmmoinfo)
			elseif s == 5 then
				superDelete = true
			end
		elseif s == 1 then
			landType = 0
			AddCaption(loc("Normal Land"), colorPlaceMode1, capgrpAmmoinfo)
		elseif s == 2 then
			landType = lfIndestructible
			AddCaption(loc("Indestructible Land"), colorPlaceMode1, capgrpAmmoinfo)
		elseif s == 3 then
			landType = lfIce
			AddCaption(loc("Icy Land"), colorPlaceMode1, capgrpAmmoinfo)
		elseif (s == 4) then
			landType = lfBouncy
			AddCaption(loc("Bouncy Land"), colorPlaceMode1, capgrpAmmoinfo)
		elseif (s == 5) and (cat[cIndex] ~= loc("Sprite Modification Mode")) and (cat[cIndex] ~= loc("Sprite Placement Mode")) then
			superDelete = true
		end
	elseif pMode[pIndex] == loc("Selection Mode") then
		if sGear ~= nil and GetGearType(sGear) == gtHedgehog then
			setGearValue(sGear, "ranking", s)
		end
	end

end

function onPrecise()

	preciseOn = true

end

function onPreciseUp()
	preciseOn = false
end

function showSecondaryMessage()
	local caption2
	if curWep == amGirder then
		caption2 = loc("Girder")
	elseif curWep == amRubber then
		caption2 = loc("Rubber")
	elseif cat[cIndex] == loc("Mine Placement Mode") or cat[cIndex] == loc("Sticky Mine Placement Mode") or cat[cIndex] == loc("Air Mine Placement Mode") then
		caption2 = string.format(loc("%d ms"), pMode[pIndex])
	elseif cat[cIndex] == loc("Dud Mine Placement Mode") or cat[cIndex] == loc("Barrel Placement Mode") or cat[cIndex] == loc("Health Crate Placement Mode") then
		caption2 = string.format(loc("Health: %d"), pMode[pIndex])
	elseif cat[cIndex] == loc("Health Modification Mode") then
		local health = tonumber(pMode[pIndex][1])
		local mode = pMode[pIndex][2]
		if mode == "set" then
			caption2 = string.format(loc("Set to %d"), health)
		elseif mode == "mod" then
			if health < 0 then
				caption2 = string.format(loc("Subtract %d"), math.abs(health))
			else
				caption2 = string.format(loc("Add %d"), health)
			end
		else
			caption2 = "ERROR"
		end
	elseif type(pMode[pIndex]) == "table" then
		caption2 = tostring(pMode[pIndex][1])
	else
		caption2 = tostring(pMode[pIndex])
	end
	AddCaption(caption2, colorPlaceMode2, capgrpMessage2)
end

---------------------------------------------------------------
-- Cycle through selection subsets (by changing pIndex, pMode)
-- i.e 	health of barrels, medikits,
--		timer of mines
--		contents of crates etc.
---------------------------------------------------------------
function onLeft()

	if (curWep == amCMGearPlacementTool) then
		leftHeld = true
		rightHeld = false

		if preciseOn then
			if cat[cIndex] == loc("Sprite Placement Mode") then
				sFrame = sFrame - 1
				if sFrame < 0 then
					sFrame = reducedSpriteIDArrayFrames[pIndex] - 1
				end
			end
		else
			pIndex = pIndex - 1
			if pIndex == 0 then
				pIndex = #pMode
			end
			if cat[cIndex] == loc("Sprite Placement Mode") then
				sFrame = math.min(sFrame, reducedSpriteIDArrayFrames[pIndex] - 1)
			end

			if (curWep == amGirder) or (curWep == amRubber) or (curWep == amCMGearPlacementTool) then
				showSecondaryMessage()
			end
		end
	end

end

function onRight()

	if (curWep == amCMGearPlacementTool) then
		leftHeld = false
		rightHeld = true

		if preciseOn then
			if cat[cIndex] == loc("Sprite Placement Mode") then
				sFrame = sFrame + 1
				if sFrame >= reducedSpriteIDArrayFrames[pIndex] then
					sFrame = 0
				end
			end
		else
			pIndex = pIndex + 1
			if pIndex > #pMode then
				pIndex = 1
			end
			if cat[cIndex] == loc("Sprite Placement Mode") then
				sFrame = math.min(sFrame, reducedSpriteIDArrayFrames[pIndex] - 1)
			end

			if (curWep == amGirder) or (curWep == amRubber) or (curWep == amCMGearPlacementTool) then
				showSecondaryMessage()
			end
		end
	end

end

---------------------------------------------------------
-- Cycle through primary categories (by changing cIndex)
-- i.e 	mine, sticky mine, barrels
--		health/weapon/utility crate, placement of gears
---------------------------------------------------------
function onUp()

	if (curWep == amCMGearPlacementTool) then
		cIndex = cIndex - 1
		if (cIndex == 1) or (cIndex == 2) then --1	--we no longer hit girder by normal means
			cIndex = #cat
		end

		RedefineSubset()
		updateHelp()

	end

end

function onDown()

	if (curWep == amCMGearPlacementTool) then
		cIndex = cIndex + 1
		if cIndex > #cat then
			cIndex = 3	 -- 2 ----we no longer hit girder by normal means
		end

		RedefineSubset()
		updateHelp()

	end

end

function onParameters()

    parseParams()

	ufoFuel = tonumber(params["ufoFuel"])
	if ufoFuel == nil then
		ufoFuel = 0
	end

	mapID = tonumber(params["m"])

	--15 is a good short range portal, for what it's worth
	if tonumber(params["portalDistance"]) ~= nil then
		portalDistance = div(tonumber(params["portalDistance"]),5)
	end

	if portalDistance == nil then
		portalDistance = 5000
	end

	if params["helpDisabled"] == "true" then
		helpDisabled = true
	end

	if mapID == nil then
		mapID = 1
	end

end

function onGameInit()

	-- perhaps we can get some of this better info in parsecommandoverride

	if mapID == nil then
		mapID = 1
	end

	-- read gameflags and assign their values to the gameflaglist array
	for i = 1, #gameFlagList do
		if band(GameFlags, gameFlagList[i][3]) ~= 0 then
			gameFlagList[i][2] = true
		else
			gameFlagList[i][2] = false
		end
	end

	reducedSpriteIDArrayFrames = {
		1, 8, 4, 1, 1,
		AmmoTypeMax, AmmoTypeMax, 3, 4, 8, 1,
		1, 1, 1, 1, 1, 1,
		1, 1, 1, 1, 1,
	}

	Explosives = 0
	MinesNum = 0

	EnableGameFlags(gfInfAttack, gfDisableWind)

	RedefineSubset()

end

function showHedgeEditorMissionPanel()
	ShowMission	(
		loc("HEDGEEDITOR"),
		loc("An experimental (and buggy!) editing tool for missions and more"),
		loc("Manual: https://hedgewars.org/hedgeeditor") .. "|" ..
		" " .. "|" ..
		loc("Place Girder: Girder") .. "|" ..
		loc("Place Rubber: Rubber") .. "|" ..
		loc("Place Gears (and more): Gear Placement Tool") .. "|" ..
		loc("Toggle Help: [Precise]+[1]") .. "|" ..
		loc("Toggle Gear Information: [Precise]+[3]") .. "|" ..
		" " .. "|" ..
		loc("Editing Commands: (Use while no weapon is selected)") .. "|" ..
		loc("Save Level: [Precise]+[4]") .. "|" ..
		loc("Toggle Editing Weapons and Tools: [Precise]+[2]")
		, 4, 5000
		)

	SetAmmoTexts(amCMGearPlacementTool,
		loc("Gear Placement Tool"),
		loc("HedgeEditor tool"),
		loc("Place, modify and delete gears (e.g. objects)|and waypoints, edit hedgehog settings, values,|victory conditions, and more.") .. "|" ..
		loc("Select a placement mode and read the infos|in the mission panel to learn how to use it.") .. "|" ..
		loc("Up/Down: Change placement mode") .. "|" ..
		loc("Cursor: Mode action"))

	hedgeEditorMissionPanelShown = true
end

function onGameStart()

	trackTeams()


	InterpretPoints()
	LoadLevelData()

	showHedgeEditorMissionPanel()

	sCirc = AddVisualGear(0,0,vgtCircle,0,true)
	SetVisualGearValues(sCirc, 0, 0, 100, 255, 1, 10, 0, 40, 3, 0xffba00ff)

	--[[ This is a small hack to disable Hedgewars' girder placement since we do it on our own;
	this will remove the "girder circle" and gets rid of the placement failure animation ]]
	SetMaxBuildDistance(1)

	frameID = 1
	visualSprite = sprAmGirder
	sSprite = AddVisualGear(0, 0, vgtStraightShot, 0, true,1)
	SetVisualGearValues(sSprite, 1, 1, 0, 0, nil, frameID, 20000, visualSprite, 20000, 0 )

	SetAmmoDelay(amCMGearPlacementTool,0)
	SetAmmoDelay(amGirder,0)
	SetAmmoDelay(amRubber,0)

end

function SetEditingWeps(ammoCount)

	AddAmmo(CurrentHedgehog, amCMGearPlacementTool, ammoCount)
	AddAmmo(CurrentHedgehog, amGirder, ammoCount)
	AddAmmo(CurrentHedgehog, amRubber, ammoCount)
	AddAmmo(CurrentHedgehog, amTeleport, ammoCount)
	AddAmmo(CurrentHedgehog, amRope, ammoCount)
	AddAmmo(CurrentHedgehog, amSwitch, 100)
	AddAmmo(CurrentHedgehog, amSkip, 100)

end

function clearAmmo(gear)
	for i = 1, #atkArray do
		AddAmmo(gear,atkArray[i][1],0)
	end
	for i = 1, #utilArray do
		AddAmmo(gear,utilArray[i][1],0)
	end
end

-- the below two functions allow you to set up a themed team.
-- one day, it'd be nice to be able to set their voice/flag/grave
-- ingame at this point, too, but for now, this is impossible
function SetTeamIdentity(gear)
	tName = pMode[pIndex]
	hIndex = 1
	hArr = {}
	for i = 1,#preMadeTeam[pIndex][2] do
		table.insert(hArr,preMadeTeam[pIndex][2][i])
	end
	nArr = {}
	for i = 1,#preMadeTeam[pIndex][3] do
		table.insert(nArr,preMadeTeam[pIndex][3][i])
	end
	SetHogTeamName(gear, tName)
	runOnHogs(AssignTeam)
end

function AssignTeam(gear)

	if GetHogTeamName(gear) == tName then

		setGearValue(gear,"flag",preMadeTeam[pIndex][5])
		setGearValue(gear,"voice",preMadeTeam[pIndex][6])
		setGearValue(gear,"grave",preMadeTeam[pIndex][7])
		setGearValue(gear,"fort",preMadeTeam[pIndex][8])
		setGearValue(gear,"originalTeamName",preMadeTeamNamesOriginal[pIndex])

		if preMadeTeam[pIndex][4] == "R" then -- random team

			if #hArr > 0 then
				--if there are unchosen hats left, choose one
				--then remove it from the available list of hats
				i = 1+GetRandom(#hArr)
				SetHogHat(gear,hArr[i])
				table.remove(hArr,i)
			else
				-- choose any hat randomly
				SetHogHat(gear,preMadeTeam[pIndex][2][1+GetRandom(#preMadeTeam[pIndex][2])])
			end

			if #nArr > 0 then
				i = 1+GetRandom(#nArr)
				SetHogNameAndTranslate(gear, nArr[i])
				table.remove(nArr,i)
			else
				SetHogNameAndTranslate(gear, preMadeTeam[pIndex][3][1+GetRandom(#preMadeTeam[pIndex][3])])
			end

		elseif preMadeTeam[pIndex][4] == "F" then -- fixed team w/ exactly 8 guys
			SetHogNameAndTranslate(gear, preMadeTeam[pIndex][3][hIndex])
			SetHogHat(gear,preMadeTeam[pIndex][2][hIndex])
			hIndex = hIndex +1
		else -- FR fixed random team with more or less than 8 guys

			if #hArr > 0 then
				i = 1+GetRandom(#hArr)
				SetHogHat(gear,hArr[i])
				SetHogNameAndTranslate(gear, nArr[i])
				table.remove(hArr,i)
				table.remove(nArr,i)
			else
				SetHogHat(gear,"NoHat")
				SetHogNameAndTranslate(gear,loc_noop("Hedgehog"))
			end

		end

	end

end

-- allows you to set a sort of identity and weapon profile for a given hog
-- this should only really be used when perHogAmmo is enabled
function SetHogProfile(gear, pro)

	clearAmmo(gear)

	if pro == loc("Sniper") then

		SetHogNameAndTranslate(gear, "Sniper")
		SetHogHat(gear, "Sniper")
		SetHealth(gear, 50)
		AddAmmo(gear, amSniperRifle, 100)
		AddAmmo(gear, amDEagle, 100)

	elseif pro == loc("Pyro") then

		SetHogNameAndTranslate(gear, "Pyro")
		SetHogHat(gear, "Gasmask")
		SetHealth(gear, 80)
		AddAmmo(gear, amFlamethrower, 100)
		AddAmmo(gear, amMolotov, 100)
		AddAmmo(gear, amNapalm, 1)

	elseif pro == loc("Soldier") then

		SetHogNameAndTranslate(gear, "Soldier")
		SetHogHat(gear, "war_americanww2helmet")
		SetHealth(gear, 100)
		AddAmmo(gear, amBazooka, 100)
		AddAmmo(gear, amShotgun, 100)
		AddAmmo(gear, amMortar, 100)

	elseif pro == loc("Grenadier") then

		SetHogNameAndTranslate(gear, "Grenadier")
		SetHogHat(gear, "war_desertgrenadier1")
		SetHealth(gear, 100)
		AddAmmo(gear, amGrenade, 100)
		AddAmmo(gear, amClusterBomb, 100)
		AddAmmo(gear, amGasBomb, 100)

	elseif pro == loc("Chef") then

		SetHogNameAndTranslate(gear, "Chef")
		SetHogHat(gear, "chef")
		SetHealth(gear, 65)
		AddAmmo(gear, amGasBomb, 100)
		AddAmmo(gear, amKnife, 100)
		AddAmmo(gear, amCake, 1)

	elseif pro == loc("Ninja") then

		SetHogNameAndTranslate(gear, "Ninja")
		SetHogHat(gear, "NinjaFull")
		SetHealth(gear, 80)
		AddAmmo(gear, amRope, 100)
		AddAmmo(gear, amFirePunch, 100)
		AddAmmo(gear, amParachute, 1)

	elseif pro == loc("Commander") then

		SetHogNameAndTranslate(gear, "Commander")
		SetHogHat(gear, "sf_vega")
		SetHealth(gear, 120)
		AddAmmo(gear, amDEagle, 100)
		AddAmmo(gear, amAirAttack, 2)
		AddAmmo(gear, amNapalm, 1)
		AddAmmo(gear, amDrillStrike, 1)
		AddAmmo(gear, amMineStrike, 1)

	elseif pro == loc("Engineer") then

		SetHogNameAndTranslate(gear, "Engineer")
		SetHogHat(gear, "Glasses")
		SetHealth(gear, 45)
		AddAmmo(gear, amGirder, 4)
		AddAmmo(gear, amRubber, 2)
		AddAmmo(gear, amLandGun, 2)
		AddAmmo(gear, amBlowTorch, 100)
		AddAmmo(gear, amPickHammer, 100)

	elseif pro == loc("Physicist") then

		SetHogNameAndTranslate(gear, "Physicist")
		SetHogHat(gear, "lambda")
		SetHealth(gear, 80)
		AddAmmo(gear, amIceGun, 2)
		AddAmmo(gear, amSineGun, 100)
		AddAmmo(gear, amBee, 2)
		AddAmmo(gear, amLowGravity, 100)

	elseif pro == loc("Trapper") then

		SetHogNameAndTranslate(gear, "Trapper")
		SetHogHat(gear, "Skull")
		SetHealth(gear, 100)
		AddAmmo(gear, amMine, 100)
		AddAmmo(gear, amSMine, 4)
		AddAmmo(gear, amAirMine, 2)
		AddAmmo(gear, amMolotov, 100)

	elseif pro == loc("Saint") then

		SetHogNameAndTranslate(gear, "Saint")
		SetHogHat(gear, "angel")
		SetHealth(gear, 200)
		AddAmmo(gear, amSeduction, 100)
		AddAmmo(gear, amInvulnerable, 100)
		AddAmmo(gear, amIceGun, 2)
		AddAmmo(gear, amHammer, 100)
		AddAmmo(gear, amResurrector, 100)

	elseif pro == loc("Clown") then

		SetHogNameAndTranslate(gear, "Clown")
		SetHogHat(gear, "clown-copper")
		SetHealth(gear, 70)
		AddAmmo(gear, amBaseballBat, 100)
		AddAmmo(gear, amGasBomb, 100)
		AddAmmo(gear, amBallgun, 1)
		AddAmmo(gear, amKamikaze, 1)

	-- some other ideas/roles
	-- relocator: portal, teleport, tardis, extra time, lasersite
	-- vampire: vampire, whip, birdy, extra damage, seduction
	-- flyboy: rc plane, deagle, whip, parachute, kamikaze
	-- demo: drill, dynamite, mine, smine, blowtorch
	-- alien: ufo, sine-gun, drill rocket
	-- terminator: tardis, shotgun, cake, girder
	-- yeti: ice-gun, firepunch, blowtorch

	end

	AddAmmo(gear, amSwitch, 100)
	AddAmmo(gear, amSkip, 100)

end

function onNewTurn()

	-- regardless of our other ammo, give stuff that is useful for editing
	SetEditingWeps(100)
	if GetHogLevel(CurrentHedgehog) == 0 then
		TurnTimeLeft = -1	-- is that turntime in your pocket? :D
	else
		ParseCommand("skip") -- skip the computer's turn
	end

end

function onGameTick()
	HandleHedgeEditor()
end

function isATrackedGear(gear)
	if 	(GetGearType(gear) == gtHedgehog) or
		(GetGearType(gear) == gtGrenade) or
		(GetGearType(gear) == gtExplosives) or
		(GetGearType(gear) == gtTarget) or
		(GetGearType(gear) == gtKnife) or
		(GetGearType(gear) == gtMine) or
		(GetGearType(gear) == gtSMine) or
		(GetGearType(gear) == gtPortal) or
		(GetGearType(gear) == gtAirMine) or
		(GetGearType(gear) == gtCase)
	then
		return(true)
	else
		return(false)
	end
end

function SetHogNameAndTranslate(gear, originalName)
	SetHogName(gear, loc(originalName))
	--[[ Store the original (usually English) hog name, since we need it for exporting.
	This way, we can display the translated name in the editor and export the properly
	loc()'ed original name afterwards ]]
	setGearValue(gear, "originalName", originalName)
end

-- track hedgehogs and placement gears
function onGearAdd(gear)

	if GetGearType(gear) == gtJetpack then
		ufoGear = gear
		if (ufoFuel ~= 0) then
			SetHealth(ufoGear, ufoFuel)
		end
	end

	if (GetGearType(gear) == gtAirAttack and GetCurAmmoType() == amCMGearPlacementTool) or (GetGearType(gear) == gtGirder) then
		cGear = gear
	end

	local tagTint
	if showGearTags then
		tagTint = 0xFFFFFFFF
	else
		tagTint = 0x00000000
	end
	if ((GetGearType(gear) == gtMine and GetHealth(gear) ~= 0) or GetGearType(gear) == gtSMine) then
		local v = AddVisualGear(0, 0, vgtHealthTag, GetTimer(gear), true)
		SetVisualGearValues(v, nil, nil, 0, 0, nil, nil, nil, nil, 240000, tagTint)
		tagGears[gear] = v
	elseif ((GetGearType(gear) == gtMine and GetHealth(gear) == 0)) then
		local _, dmg
		_, _, _, _, _, _, _, _, _, _, dmg = GetGearValues(gear)
		local v = AddVisualGear(0, 0, vgtHealthTag, 36 - dmg, true)
		SetVisualGearValues(v, nil, nil, 0, 0, nil, nil, nil, nil, 240000, tagTint)
		tagGears[gear] = v
	elseif (GetGearType(gear) == gtAirMine) then
		local _, wdTimer
		_, _, wdTimer = GetGearValues(gear)
		local v = AddVisualGear(0, 0, vgtHealthTag, wdTimer, true)
		SetVisualGearValues(v, nil, nil, 0, 0, nil, nil, nil, nil, 240000, tagTint)
		tagGears[gear] = v
	elseif (GetGearType(gear) == gtCase) then
		tagGears[gear] = -1
	elseif (GetGearType(gear) == gtExplosives) then 
		local v = AddVisualGear(0, 0, vgtHealthTag, GetHealth(gear), true)
		SetVisualGearValues(v, nil, nil, 0, 0, nil, nil, nil, nil, 240000, tagTint)
		tagGears[gear] = v
	end

	if isATrackedGear(gear) then
		trackGear(gear)

		if GetGearType(gear) == gtPortal then
			setGearValue(gear,"life",portalDistance)
		end

	end

end

function onGearDelete(gear)
	local gt = GetGearType(gear)

	if gt == gtJetpack then
		ufoGear = nil
	end

	if (gt == gtAirAttack and GetGearPos(gear) == 0) or gt == gtGirder then
		cGear = nil
	end

	if (gt == gtMine or gt == gtSMine or gt == gtAirMine or gt == gtExplosives or gt == gtCase) then 
		if(tagGears[gear] ~= -1) then
			DeleteVisualGear(tagGears[gear])
		end
		tagGears[gear] = nil
	end


	if isATrackedGear(gear) then

		if getGearValue(gear, "tCirc") ~= nil then
			DeleteVisualGear(getGearValue(gear, "tCirc"))
		end

		trackDeletion(gear)

	end

end

function onVisualGearDelete(vGear)
	if vGear == tagCursorX then
		tagCursorX = nil
	end
	if vGear == tagCursorY then
		tagCursorY = nil
	end
end

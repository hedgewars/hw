---------------------------------------------------------------
--- HEDGE EDITOR 0.9 (for use with Hedgewars 0.9.22 and up)
---------------------------------------------------------------
-- a horrible mission editor by mikade
-- place gears like a boss

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

-- meaningless version number
-- extra whitespace
-- fewer capital letters than ideal

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
-- DISCLAIMER
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

-- check to what extent hog info is preserved on saving (does health/weps really save correctly?)
-- atm I think it's only for missions so I don't think it is preserved in core data

-- check if we lose a mission when the enemy collects our crate (we should)

-- How about a weapons profile tool that is used with team ammo
-- and then hog identity tool would only be available if gfPerHogAmmo is set

-- INVESTIGATE when you can bother to do so
-- is airmine still missing anywhere, e.g. the weplist generated FOR THE TEMPLATE SCRIPT

-- [high] 	waypoints don't reload yet

-- [high] 	add missing weps/utils/gears as they appear
--			some gameflags and settings are probably missing, too (diff border types etc)
--			some themes are also probably missing: cake, hoggywood?
-- 			the ongameinit stuff is probaably missing something akin to numAirMines
--			and also probably scriptParam and gravity etc.

-- [med] 	add a limited form of save/load within level before mass-output

-- [med] 	rework gameflag handling to use the newer API methods (done?)

-- [med]	maybe incorporate portal effects / ufo tracking into the template generated script if
-- 			you want the missions to use it

-- [med]	improve ammo handling (if possible, take more scheme settings into account)
-- 			also be sure to generate wep data so crates don't have 0 in them (done?)

-- [low] 	match the user picked color to the color array

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
							"Advanced Repositioning Mode",  -- also include a delete
							"Tagging Mode",
							"Hog Identity Mode",
							"Team Identity Mode",
							"Health Modification Mode",
							"Sprite Testing Mode",
							"Sprite Modification Mode",
							"Sprite Placement Mode",
							"Waypoint Placement Mode"
							}]]

-- [low]	improve support for ShoppaBalance and ConstructionMode, see ranking)

-- [low] 	consider combining landflags

-- [low] 	periodically rework the code to make it less terrible (hahahahahaha!)

-- [low]	eventually incorporate scripted structures into the editor / mission mode

-- [low] 	some kind of support for single team training missions
-- 			we could possibly add gfOneClanMode and kill the other team we're playing with?

-- [never?]	set all actors to heresurrectible (why did I want this?)

-- [never?] more detailed goal tagging and multi-stage triggers

-- [never?]	theoretically might be possible to create forts (and other grouped objects)
--			that can be mirrored and generated/placed in a big enough space

-- [never?]	add a pulsing glow thing for sprites you have selected,
--			kind of like the invaders in SpaceInvader (currently they are just displayed as purple)

-- [never?] add the thing that would be useful for this editor, but that others might use to cheat

-- [never?]	improve "illegal" placement detection (pretty sure should just let people do what they want)

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

-- experimental crap
--local destroyMap = false

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

---------------------------------
-- crates are made of this stuff
---------------------------------

local atkArray =
				{
				{amBazooka, 	"amBazooka",		2, 	loc("Bazooka")},
				{amBee, 		"amBee",			3, 	loc("Homing Bee")},
				{amMortar, 		"amMortar",			21, loc("Mortar")},
				{amDrill, 		"amDrill",			28, loc("Drill Rocket")},
				{amSnowball, 	"amSnowball",		50, loc("Mudball")},

				{amGrenade,		"amGrenade",		0, 	loc("Grenade")},
				{amClusterBomb,	"amClusterBomb",	1, 	loc("Cluster Bomb")},
				{amMolotov, 	"amMolotov",		39, loc("Molotov Cocktail")},
				{amWatermelon, 	"amWatermelon",		25, loc("Watermelon Bomb")},
				{amHellishBomb,	"amHellishBomb",	26, loc("Hellish Handgrenade")},
				{amGasBomb, 	"amGasBomb",		43, loc("Limburger")},

				{amShotgun,		"amShotgun",		4, 	loc("Shotgun")},
				{amDEagle,		"amDEagle",			9, 	loc("Desert Eagle")},
				{amFlamethrower,"amFlamethrower",	45, loc("Flamethrower")},
				{amSniperRifle,	"amSniperRifle",	37, loc("Sniper Rifle")},
				{amSineGun, 	"amSineGun",		44, loc("SineGun")},
				{amIceGun, 		"amIceGun",			53, loc("Freezer")},
				{amLandGun,		"amLandGun",		52, loc("Land Spray")},

				{amFirePunch, 	"amFirePunch",		11, loc("Shoryuken")},
				{amWhip,		"amWhip",			12, loc("Whip")},
				{amBaseballBat, "amBaseballBat",	13, loc("Baseball Bat")},
				{amKamikaze, 	"amKamikaze",		22, loc("Kamikaze")},
				{amSeduction, 	"amSeduction",		24, loc("Seduction")},
				{amHammer,		"amHammer",			47, loc("Hammer")},

				{amMine, 		"amMine",			8, 	loc("Mine")},
				{amDynamite, 	"amDynamite",		10, loc("Dynamite")},
				{amCake, 		"amCake",			23, loc("Cake")},
				{amBallgun, 	"amBallgun",		29, loc("Ballgun")},
				{amRCPlane,		"amRCPlane",		30, loc("RC Plane")},
				{amSMine,		"amSMine",			46, loc("Sticky Mine")},

				{amAirAttack,	"amAirAttack",		15, loc("Air Attack")},
				{amMineStrike,	"amMineStrike",		16, loc("Mine Strike")},
				{amDrillStrike,	"amDrillStrike",	49, loc("Drill Strike")},
				{amAirMine,		"amAirMine",		56, loc("Air Mine")},
				{amNapalm, 		"amNapalm",			27, loc("Napalm")},
				{amPiano,		"amPiano",			42, loc("Piano Strike")},

				{amKnife,		"amKnife",			54, loc("Cleaver")},

				{amBirdy,		"amBirdy",			40, loc("Birdy")}

				}

local utilArray =
				{
				{amBlowTorch, 		"amBlowTorch",		17, loc("BlowTorch")},
				{amPickHammer,		"amPickHammer",		5, 	loc("PickHammer")},
				{amGirder, 			"amGirder",			18, loc("Girder")},
				{amRubber, 			"amRubber",			55, loc("Rubber")},
				{amPortalGun,		"amPortalGun",		41, loc("Personal Portal Device")},

				{amRope, 			"amRope",			7, 	loc("Rope")},
				{amParachute, 		"amParachute",		14, loc("Parachute")},
				{amTeleport,		"amTeleport",		19, loc("Teleport")},
				{amJetpack,			"amJetpack",		38, loc("Flying Saucer")},

				{amInvulnerable,	"amInvulnerable",	33, loc("Invulnerable")},
				{amLaserSight,		"amLaserSight",		35, loc("Laser Sight")},
				{amVampiric,		"amVampiric",		36, loc("Vampirism")},

				{amLowGravity, 		"amLowGravity",		31, loc("Low Gravity")},
				{amExtraDamage, 	"amExtraDamage",	32, loc("Extra Damage")},
				{amExtraTime,		"amExtraTime",		34, loc("Extra Time")},

				{amResurrector, 	"amResurrector",	48, loc("Resurrector")},
				{amTardis, 			"amTardis",			51, loc("Tardis")},

				{amSwitch,			"amSwitch",			20, loc("Switch Hog")}
				}

				--skiphog is 6

----------------------------
-- hog and map editing junk
----------------------------

local preMadeTeam = 	{

				{
				"Clowns",
				{"WhySoSerious","clown-copper","clown-crossed","clown","Joker"},
				{"Baggy","Bingo","Bobo","Bozo","Buster","Chester","Copper","Heckles","Giggles","Jingo","Molly","Loopy","Patches","Tatters"},
				"R","cm_birdy","Mobster","Rubberduck","Castle"
				},

				{
				"Street Fighters",
				{"sf_balrog","sf_blanka","sf_chunli","sf_guile","sf_honda","sf_ken","sf_ryu","sf_vega"},
				{"Balrog","Blanka","Chunli","Guile","Honda","Ken","Ryu","Vega"},
				"F","cm_balrog","Surfer","dragonball","Castle"
				},

				{
				"Cybernetic Empire",
				{"cyborg1","cyborg2"},
				{"Unit 189","Unit 234","Unit 333","Unit 485","Unit 527","Unit 638","Unit 709","Unit 883"},
				"R","cm_binary","Robot","Grave","Castle"
				},

				{
				"Color Squad",
				{"hair_blue","hair_green","hair_red","hair_yellow","hair_purple","hair_grey","hair_orange","hair_pink"},
				{"Blue","Green","Red","Yellow","Purple","Grey","Orange","Pink"},
				"F","cm_birdy","Singer","Grave","Castle"
				},

				{
				"Fruit",
				{"fr_apple","fr_banana","fr_lemon","fr_orange","fr_pumpkin","fr_tomato"},
				{"Juicy","Squishy","Sweet","Sour","Bitter","Ripe","Rotten","Fruity"},
				"R","cm_mog","Default","Cherry","Castle"
				},

				{
				"The Police",
				{"bobby","bobby2v","policecap","policegirl","royalguard"},
				{"Hightower","Lassard","Callahan","Jones","Harris","Thompson","Mahoney","Hooks","Tackleberry"},
				"R","cm_star","British","Statue","Castle"
				},

				{
				"The Ninja-Samurai Alliance",
				{"NinjaFull","NinjaStraight","NinjaTriangle","Samurai","StrawHat","StrawHatEyes","StrawHatFacial","naruto"},
				{"Bushi","Tatsujin","Itami","Arashi","Shinobi","Ukemi","Godai","Kenshi","Ninpo"},
				"R","japan","Default","octopus","Castle"
				},

				{
				"Pokemon",
				{"poke_ash","poke_charmander","poke_chikorita","poke_jigglypuff","poke_lugia","poke_mudkip","poke_pikachu","poke_slowpoke","poke_squirtle","poke_voltorb"},
				{"Ash","Charmander","Chikorita","Jigglypuff","Lugia","Mudkip","Pikachu","Slowpoke","Squirtle","Voltorb"},
				"FR","cm_pokemon","Default","pokeball","Castle"
				},

				{
				"The Zoo",
				{"zoo_Bat","zoo_Beaver","zoo_Bunny","zoo_Deer","zoo_Hedgehog","zoo_Moose","zoo_Pig","zoo_Porkey","zoo_Sheep","zoo_chicken","zoo_elephant","zoo_fish","zoo_frog","zoo_snail","zoo_turtle"},
				{"Batty","Tails","Bunny","Deer","Spikes","Horns","Bacon","Porkey","Sheepy","Chicken","Trunks","Fishy","Legs","Slimer","Roshi"},
				"FR","cm_hurrah","Default","Bone","Castle"
				},

				{
				"The Devs",
				{"ushanka","zoo_Sheep","bb_bob","Skull","poke_mudkip","lambda","WizardHat","sf_ryu","android","fr_lemon","mp3"},
				{"unC0Rr", "sheepluva", "nemo", "mikade", "koda", "burp","HeneK","Tiyuri","Xeli","Displacer","szczur"},
				"FR","hedgewars","Classic","Statue","Castle"
				},

				{
				"Mushroom Kingdom",
				{"sm_daisy","sm_luigi","sm_mario","sm_peach","sm_toad","sm_wario"},
				{"Daisy","Luigi","Mario","Princess Peach","Toad","Wario"},
				"FR","cm_birdy","Default","Badger","Castle"
				},

				{
				"Pirates",
				{"pirate_jack","pirate_jack_bandana"},
				{"Rusted Diego","Fuzzy Beard","Al.Kaholic","Morris","Yumme Gunpowder","Cutlass Cain","Jim Morgan","Silver","Dubloon Devil","Ugly Mug","Fair Wind","Scallywag","Salty Dog","Bearded Beast","Timbers","Both Barrels","Jolly Roger"},
				"R","cm_pirate","Pirate","chest","Castle"
				},

				{
				"Gangsters",
				{"Moustache","Cowboy","anzac","Bandit","thug","Jason","NinjaFull","chef"},
				{"The Boss","Jimmy","Frankie","Morris","Mooney","Knives","Tony","Meals"},
				"F","cm_anarchy","Mobster","deadhog","Castle"
				},


				{
				"Twenty-Twenty",
				{"Glasses","lambda","SunGlasses","Sniper","Terminator_Glasses","Moustache_glasses","doctor","punkman","rasta"},
				{"Specs","Speckles","Spectator","Glasses","Glassy","Harry Potter","Goggles","Clark Kent","Goggs","Lightbender","Specs Appeal","Four Eyes"},
				"R","cm_face","Default","eyecross","Castle"
				},


				{
				"Monsters",
				{"Skull","Jason","ShaggyYeti","Zombi","cyclops","Mummy","hogpharoah","vampirichog"},
				{"Bones","Jason","Yeti","Zombie","Old One Eye","Ramesses","Xerxes","Count Hogula"},
				"FR","cm_vampire","Default","octopus","Castle"
				},

				{
				"The Iron Curtain",
				{"ushanka","war_sovietcomrade1","war_sovietcomrade1","ushanka"},
				{"Alex","Sergey","Vladimir","Andrey","Dimitry","Ivan","Oleg","Kostya","Anton","Eugene"},
				"R","cm_soviet","Russian","skull","Castle"
				},

				{
				"Desert Storm",
				{"war_desertofficer","war_desertgrenadier1","war_desertmedic","war_desertsapper1","war_desertgrenadier2","war_desertgrenadier4","war_desertsapper2","war_desertgrenadier5"},
				{"Brigadier Briggs","Lt. Luke","Sgt. Smith","Corporal Calvin","Frank","Joe","Sam","Donald"},
				"F","cm_birdy","Default","Grave","Castle"
				},

				--{
				--"Sci-Fi",
				--{"scif_2001O","scif_2001Y","scif_BrainSlug","scif_BrainSlug2","scif_Geordi","scif_SparkssHelmet","scif_cosmonaut","scif_cyberpunk","scif_swDarthvader","scif_swStormtrooper"},
				--{},
				--"R","cm_birdy","Default","Grave","Castle"
				--},




				--

				--{
				--,
				--{},
				--{},
				--"R","cm_birdy","Default","Grave","Castle"
				--},

				-- don't forget new additions need to be added to:
				--pMode = {"Clowns","Street Fighters","Cybernetic Empire","Color Squad","Fruit","The Police","The Ninja-Samurai Alliance","Pokemon","The Zoo","The Devs","The Hospital"}
				-- but maybe we can just get the size of this array and automatically generate a list instead


				{
				"The Hospital",
				{"doctor","nurse","war_britmedic","war_desertmedic","war_germanww2medic"},
				{"Dr. Blackwell","Dr. Drew","Dr. Harvey","Dr. Crushing","Dr. Jenner","Dr. Barnard","Dr. Parkinson","Dr. Banting","Dr. Horace","Dr. Hollows","Dr. Jung"},
				"R","cm_birdy","Default","heart","Castle"
				}

				}


--local menuArray =	{
--			"Initialisation Menu", "Team Menu"
--			}

--local hatArray = 	{hahahaha, you're joking, right?}
--[[well, here are most of them as vaguely ordered by theme, there may be some duplicates
NoHat,
NinjaFull,NinjaStraight,NinjaTriangle,Samurai,StrawHat,StrawHatEyes,StrawHatFacial,naruto
sm_daisy,sm_luigi,sm_mario,sm_peach,sm_toad,sm_wario,
ShortHair_Black,ShortHair_Brown,ShortHair_Grey,ShortHair_Red,ShortHair_Yellow
hair_blue,hair_green,hair_red,hair_yellow,hair_purple,hair_grey,hair_orange,hair_pink
Skull,Jason,ShaggyYeti,Zombi,cyclops,Mummy,hogpharoah,vampirichog
cap_blue,cap_red,cap_green,cap_junior,cap_yellow,cap_thinking
WhySoSerious,clown-copper,clown-crossed,clown,Joker
bobby,bobby2v,policecap,policegirl,royalguard,
spcartman,spstan,spkenny,spkyle,
sf_balrog,sf_blanka,sf_blankatoothless,sf_chunli,sf_guile,sf_honda,sf_ken,sf_ryu,sf_vega
Glasses,lambda,SunGlasses,Terminator_Glasses,Moustache_glasses
Laminaria,Dragon,
cyborg1,cyborg2,
dish_Ladle,dish_SauceBoatSilver,dish_Teacup,dish_Teapot
laurel,flag_french,flag_germany,flag_italy,flag_usa
fr_apple,fr_banana,fr_lemon,fr_orange,fr_pumpkin,fr_tomato
doctor,nurse,war_britmedic,war_desertmedic,war_germanww2medic,
poke_ash,poke_charmander,poke_chikorita,poke_jigglypuff,
poke_lugia,poke_mudkip,poke_pikachu,poke_slowpoke,poke_squirtle,poke_voltorb
zoo_Bat,zoo_Beaver,zoo_Bunny,zoo_Deer,zoo_Hedgehog,zoo_Moose,zoo_Pig,zoo_Porkey,zoo_Sheep
zoo_chicken,zoo_elephant,zoo_fish,zoo_frog,zoo_snail,zoo_turtle
bushhider,cratehider,Disguise,
tf_demoman,tf_scout,Sniper,
Bandit,thug,anzac,Cowboy
pirate_jack,pirate_jack_bandana,
tiara,crown,royalguard
punkman,Einstein,
sth_Amy,sth_AmyClassic,sth_Eggman,sth_Knux,sth_Metal,sth_Shadow,sth_Sonic,sth_SonicClassic,sth_Super,sth_Tails
vc_gakupo,vc_gumi,vc_kaito,vc_len,vc_luka,vc_meiko,vc_miku,vc_rin
touhou_chen,touhou_marisa,touhou_patchouli,touhou_remelia,touhou_suwako,touhou_yukari,
TeamHeadband,TeamSoldier,TeamTopHat,TeamWheatley,cap_team,hair_team,
bb_bob,bb_bub,bb_cororon,bb_kululun,bubble,
Viking,spartan,swordsmensquire,knight,dwarf,
WizardHat,tophats,pinksunhat,ushanka,mexicansunbrero,HogInTheHat,
4gsuif,
AkuAku,
noface,
Coonskin3,
Dan,
Dauber,
Eva_00b,Eva_00y,
Evil,InfernalHorns,angel,
Gasmask,
IndianChief,Cowboy,
MegaHogX,
Meteorhelmet,
Moustache,
OldMan,
Pantsu,
Plunger,
RSR,
Rain,stormcloud,DayAndNight,
chuckl,Rambo,RobinHood,
Santa,snowhog,ShaggyYeti,eastertop,
Sleepwalker,
SparkleSuperFun,
SunWukong,
android,
beefeater,
car,
chef,
constructor,
footballhelmet,
judo,
lamp,
mechanicaltoy,
mickey_ears,
snorkel,
quotecap,
rasta,

metalband,
kiss_criss,kiss_frehley,kiss_simmons,kiss_stanley,mp3,Elvis
mv_Spidey,mv_Venom,
ntd_Falcon,ntd_Kirby,ntd_Link,ntd_Samus,
scif_2001O,scif_2001Y,scif_BrainSlug,scif_BrainSlug2,scif_Geordi,scif_SparkssHelmet,
scif_cosmonaut,scif_cyberpunk,scif_swDarthvader,scif_swStormtrooper,
war_UNPeacekeeper01,war_UNPeacekeeper02,
war_airwarden02,war_airwarden03,
war_americanww2helmet,
war_britmedic,war_britpthhelmet,war_britsapper,
war_desertgrenadier1,war_desertgrenadier2,war_desertgrenadier4,war_desertgrenadier5,war_desertmedic,
war_desertofficer,war_desertsapper1,war_desertsapper2,
war_frenchww1gasmask,war_frenchww1helmet,
war_germanww1helmet2,war_germanww1tankhelm,war_germanww2medic,war_germanww2pith,
war_grenadier1,war_trenchgrenadier1,war_trenchgrenadier2,war_trenchgrenadier3,
war_plainpith,
war_sovietcomrade1,war_sovietcomrade2,
war_trenchfrench01,war_trenchfrench02,]]

local colorArray = 	{
					--{0xff0000ff, "0xff0000ff", "Red"}, -- look up hw red
					{0xff4980c1, "0xff4980c1", "Blue"},
					{0xff1de6ba, "0xff1de6ba", "Teal"},
					{0xffb541ef, "0xffb541ef", "Purple"},
					{0xffe55bb0, "0xffe55bb0", "Pink"},
					{0xff20bf00, "0xff20bf00", "Green"},
					{0xfffe8b0e, "0xfffe8b0e", "Orange"},
					{0xff5f3605, "0xff5f3605", "Brown"},
					{0xffffff01, "0xffffff01", "Yellow"}
					}

local graveArray = 	{
					"Badger", "Bone", "bp2", "bubble", "Cherry",
					"chest", "coffin", "deadhog", "dragonball", "Duck2",
					"Earth", "Egg", "eyecross", "Flower", "Ghost",
					"Grave", "heart", "money", "mouton1", "octopus",
					"plant2", "plant3", "Plinko", "pokeball", "pyramid",
					"ring", "Rip", "Rubberduck", "Simple", "skull",
					"star", "Status"
					}

local voiceArray = 	{
					"British","Classic","Default","Default_es","Default_uk",
					"HillBilly","Mobster","Pirate","Robot","Russian","Singer",
					"Surfer"
					}

local fortArray =	{
					"Cake", "Castle", "Earth", "EvilChicken", "Flowerhog",
					"Hydrant", "Lego", "Plane", "Statue", "Tank",
					"UFO", "Wood"
					}

-- non-exhaustive list of flags, feel free to choose others
local flagArray = 	{
					"cm_binary", "cm_birdy", "cm_earth", "cm_pirate", "cm_star",
					"cm_hurrah", "cm_hax0r", "cm_balrog", "cm_spider", "cm_eyeofhorus"
					}

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

local themeList = 	{"Art", "Bamboo", "Bath", --[["Blox",]] "Brick", "Cake", "Castle", "Cave", "Cheese",
		"Christmas", "City", "Compost", --[["CrazyMission", "Deepspace",]] "Desert", "Earthrise",
		--[["Eyes",]] "Freeway", "Golf", "Halloween", "Hell", --[["HogggyWood",]] "Island", "Jungle", "Nature",
		"Olympics", "Planes", "Sheep", "Snow", "Stage", "Underwater"
		}

local mapList = 	{
		"Bamboo", "BambooPlinko", "Basketball", "Bath", "Blizzard", "Blox", "Bubbleflow",
		"Battlefield", "Cake", "Castle", "Cave", "Cheese", "Cogs", "Control", "Earthrise",
		"Eyes", "Hammock", "Hedgelove", "Hedgewars", "Hogville", "Hydrant", "Islands",
		"Knockball", "Lonely_Island", "Mushrooms", "Octorama", "PirateFlag",
		"Plane", "Ropes", "Ruler", "Sheep", "ShoppaKing", "Sticks", "Trash", "Tree",
		"TrophyRace"
		}

--local spriteArray = {
--					{sprBigDigit,			"sprBigDigit",			0}
--					}

local spriteIDArray = {sprWater, sprCloud, sprBomb, sprBigDigit, sprFrame,
sprLag, sprArrow, sprBazookaShell, sprTargetP, sprBee,
sprSmokeTrace, sprRopeHook, sprExplosion50, sprMineOff,
sprMineOn, sprMineDead, sprCase, sprFAid, sprDynamite, sprPower,
sprClusterBomb, sprClusterParticle, sprFlame,
sprHorizont, sprHorizontL, sprHorizontR, sprSky, sprSkyL, sprSkyR,
sprAMSlot, sprAMAmmos, sprAMAmmosBW, sprAMSlotKeys, sprAMCorners,
sprFinger, sprAirBomb, sprAirplane, sprAmAirplane, sprAmGirder,
sprHHTelepMask, sprSwitch, sprParachute, sprTarget, sprRopeNode,
sprQuestion, sprPowerBar, sprWindBar, sprWindL, sprWindR,

sprFireButton, sprArrowUp, sprArrowDown, sprArrowLeft, sprArrowRight,
sprJumpWidget, sprAMWidget, sprPauseButton, sprTimerButton, sprTargetButton,

sprFlake, sprHandRope, sprHandBazooka, sprHandShotgun,
sprHandDEagle, sprHandAirAttack, sprHandBaseball, sprPHammer,
sprHandBlowTorch, sprBlowTorch, sprTeleport, sprHHDeath,
sprShotgun, sprDEagle, sprHHIdle, sprMortar, sprTurnsLeft,
sprKamikaze, sprWhip, sprKowtow, sprSad, sprWave,
sprHurrah, sprLemonade, sprShrug, sprJuggle, sprExplPart, sprExplPart2,
sprCakeWalk, sprCakeDown, sprWatermelon,
sprEvilTrace, sprHellishBomb, sprSeduction, sprDress,
sprCensored, sprDrill, sprHandDrill, sprHandBallgun, sprBalls,
sprPlane, sprHandPlane, sprUtility, sprInvulnerable, sprVampiric, sprGirder,
sprSpeechCorner, sprSpeechEdge, sprSpeechTail,
sprThoughtCorner, sprThoughtEdge, sprThoughtTail,
sprShoutCorner, sprShoutEdge, sprShoutTail,
sprSniperRifle, sprBubbles, sprJetpack, sprHealth, sprHandMolotov, sprMolotov,
sprSmoke, sprSmokeWhite, sprShell, sprDust, sprSnowDust, sprExplosives, sprExplosivesRoll,
sprAmTeleport, sprSplash, sprDroplet, sprBirdy, sprHandCake, sprHandConstruction,
sprHandGrenade, sprHandMelon, sprHandMortar, sprHandSkip, sprHandCluster,
sprHandDynamite, sprHandHellish, sprHandMine, sprHandSeduction, sprHandVamp,
sprBigExplosion, sprSmokeRing, sprBeeTrace, sprEgg, sprTargetBee, sprHandBee,
sprFeather, sprPiano, sprHandSineGun, sprPortalGun, sprPortal,
sprCheese, sprHandCheese, sprHandFlamethrower, sprChunk, sprNote,
sprSMineOff, sprSMineOn, sprHandSMine, sprHammer,
sprHandResurrector, sprCross, sprAirDrill, sprNapalmBomb,
sprBulletHit, sprSnowball, sprHandSnowball, sprSnow,
sprSDFlake, sprSDWater, sprSDCloud, sprSDSplash, sprSDDroplet, sprTardis,
sprSlider, sprBotlevels, sprHandKnife, sprKnife, sprStar, sprIceTexture, sprIceGun, sprFrozenHog, sprAmRubber, sprBoing}


local spriteTextArray = {"sprWater", "sprCloud", "sprBomb", "sprBigDigit", "sprFrame",
"sprLag", "sprArrow", "sprBazookaShell", "sprTargetP", "sprBee",
"sprSmokeTrace", "sprRopeHook", "sprExplosion50", "sprMineOff",
"sprMineOn", "sprMineDead", "sprCase", "sprFAid", "sprDynamite", "sprPower",
"sprClusterBomb", "sprClusterParticle", "sprFlame", "sprHorizont",
"sprHorizontL", "sprHorizontR", "sprSky", "sprSkyL", "sprSkyR", "sprAMSlot",
"sprAMAmmos", "sprAMAmmosBW", "sprAMSlotKeys", "sprAMCorners", "sprFinger",
"sprAirBomb", "sprAirplane", "sprAmAirplane", "sprAmGirder", "sprHHTelepMask",
 "sprSwitch", "sprParachute", "sprTarget", "sprRopeNode", "sprQuestion",
 "sprPowerBar", "sprWindBar", "sprWindL", "sprWindR", "sprFireButton",
 "sprArrowUp", "sprArrowDown", "sprArrowLeft", "sprArrowRight", "sprJumpWidget",
 "sprAMWidget", "sprPauseButton", "sprTimerButton", "sprTargetButton",
 "sprFlake", "sprHandRope", "sprHandBazooka", "sprHandShotgun",
 "sprHandDEagle", "sprHandAirAttack", "sprHandBaseball", "sprPHammer",
 "sprHandBlowTorch", "sprBlowTorch", "sprTeleport", "sprHHDeath", "sprShotgun",
 "sprDEagle", "sprHHIdle", "sprMortar", "sprTurnsLeft", "sprKamikaze", "sprWhip",
 "sprKowtow", "sprSad", "sprWave", "sprHurrah", "sprLemonade", "sprShrug",
 "sprJuggle", "sprExplPart", "sprExplPart2", "sprCakeWalk", "sprCakeDown",
 "sprWatermelon", "sprEvilTrace", "sprHellishBomb", "sprSeduction", "sprDress",
 "sprCensored", "sprDrill", "sprHandDrill", "sprHandBallgun", "sprBalls", "sprPlane",
 "sprHandPlane", "sprUtility", "sprInvulnerable", "sprVampiric", "sprGirder",
 "sprSpeechCorner", "sprSpeechEdge", "sprSpeechTail", "sprThoughtCorner",
 "sprThoughtEdge", "sprThoughtTail", "sprShoutCorner", "sprShoutEdge",
 "sprShoutTail", "sprSniperRifle", "sprBubbles", "sprJetpack", "sprHealth",
 "sprHandMolotov", "sprMolotov", "sprSmoke", "sprSmokeWhite", "sprShell", "sprDust",
 "sprSnowDust", "sprExplosives", "sprExplosivesRoll", "sprAmTeleport", "sprSplash",
 "sprDroplet", "sprBirdy", "sprHandCake", "sprHandConstruction", "sprHandGrenade",
 "sprHandMelon", "sprHandMortar", "sprHandSkip", "sprHandCluster", "sprHandDynamite",
 "sprHandHellish", "sprHandMine", "sprHandSeduction", "sprHandVamp", "sprBigExplosion",
 "sprSmokeRing", "sprBeeTrace", "sprEgg", "sprTargetBee", "sprHandBee", "sprFeather",
 "sprPiano", "sprHandSineGun", "sprPortalGun", "sprPortal", "sprCheese", "sprHandCheese",
 "sprHandFlamethrower", "sprChunk", "sprNote", "sprSMineOff", "sprSMineOn", "sprHandSMine",
 "sprHammer", "sprHandResurrector", "sprCross", "sprAirDrill", "sprNapalmBomb", "sprBulletHit",
 "sprSnowball", "sprHandSnowball", "sprSnow", "sprSDFlake", "sprSDWater", "sprSDCloud",
 "sprSDSplash", "sprSDDroplet", "sprTardis", "sprSlider", "sprBotlevels", "sprHandKnife",
 "sprKnife", "sprStar", "sprIceTexture", "sprIceGun", "sprFrozenHog", "sprAmRubber", "sprBoing"}

 local reducedSpriteIDArray = {
  sprAmRubber, sprAmGirder, sprAMSlot, sprAMAmmos, sprAMAmmosBW, sprAMCorners, sprHHTelepMask, sprTurnsLeft,
  sprSpeechCorner, sprSpeechEdge, sprSpeechTail, sprThoughtCorner, sprThoughtEdge, sprThoughtTail, sprShoutCorner,
  sprShoutEdge, sprShoutTail, sprBotlevels, sprIceTexture, sprCustom1, sprCustom2, }

 local reducedSpriteTextArray = {
  "sprAmRubber", "sprAmGirder", "sprAMSlot", "sprAMAmmos", "sprAMAmmosBW", "sprAMCorners", "sprHHTelepMask", "sprTurnsLeft",
  "sprSpeechCorner", "sprSpeechEdge", "sprSpeechTail", "sprThoughtCorner", "sprThoughtEdge", "sprThoughtTail", "sprShoutCorner",
  "sprShoutEdge", "sprShoutTail", "sprBotlevels", "sprIceTexture", "sprCustom1", "sprCustom2", }

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
local tSpr = {}

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
				loc("Advanced Repositioning Mode"),
				loc("Tagging Mode"),
				loc("Hog Identity Mode"),
				loc("Team Identity Mode"),
				loc("Health Modification Mode"),
				--loc("Sprite Testing Mode"),
				loc("Sprite Placement Mode"),
				loc("Sprite Modification Mode"),
				loc("Waypoint Placement Mode")
				}


local pMode = {}	-- pMode contains custom subsets of the main categories
local pIndex = 1

local genTimer = 0

local CGR = 1 -- current girder rotation, we actually need this as HW remembers what rotation you last used

local placedX = {} -- x coord of placed object
local placedY = {} -- y coord of placed object
local placedSpec = {} -- this is different depending on what was placed, for mines it is their time, for crates it is their content, (for girders/rubbers it used to be their rotation, and for sprites, their name, but this has been moved to different variables to allow more complex / smooth editing)
--local placedSuperSpec = {} -- used to be used by girders/rubbers/sprites for their landFlag
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

------------------------
-- menu shite (more or less unused currently)
------------------------
--local menuEnabled = false
--local menuIndex = 1
--local menu = {}
--local subMenu = {}
--local sMI = 1 -- sub menu index
--local preMenuCfg
--local postMenuCfg
--local initMenu	=	{
--					{"Selected Menu",	"Initialisation Menu"},
--					{"List of Gameflags",	""},
--					{"List of Gameflags",	""}
--					}

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

-- bobCounter = 1
-- specialPoint(5)
-- specialPoint(127)
-- specialPoint(5)

-- if BobCounter = 1 then
-- 		if specialPointsFlag == 5 then createMine
--		if specialPointFlag == 127 then bobCounter = 2
-- elseif bobCounter == 2 then
-- 		if specialPointsFlag == 5 then createExlosives
-- end
--

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
			setGearValue(tempG,"caseType","ammo")
			setGearValue(tempG,"contents",atkArray[specialPointsFlag[i]-19][2])


		-- Utility Crates
		elseif (specialPointsFlag[i] >= (#atkArray+20)) and (specialPointsFlag[i] < (#atkArray+20+#utilArray)) then
			tempG = SpawnUtilityCrate(specialPointsX[i],specialPointsY[i],utilArray[specialPointsFlag[i]-19-#atkArray][1])
			setGearValue(tempG,"caseType","util")
			setGearValue(tempG,"contents",utilArray[specialPointsFlag[i]-19-#atkArray][2])

		--79-82 (reserved for future wep crates)
		--89,88,87,86 and 85,84,83,82 (reserved for the 2 custom sprites and their landflags)

		--90-99 reserved for scripted structures
		--[[elseif specialPointsFlag[i] == 90 then
			--PlaceStruc("generator")
		elseif specialPointsFlag[i] == 91 then
			--PlaceStruc("healingstation")
		elseif specialPointsFlag[i] == 92 then
			--PlaceStruc("respawner")
		elseif specialPointsFlag[i] == 93 then
			--PlaceStruc("teleportationnode")
		elseif specialPointsFlag[i] == 94 then
			--PlaceStruc("biofilter")
		elseif specialPointsFlag[i] == 95 then
			--PlaceStruc("supportstation")
		elseif specialPointsFlag[i] == 96 then
			--PlaceStruc("constructionstation")
		elseif specialPointsFlag[i] == 97 then
			--PlaceStruc("reflectorshield")
		elseif specialPointsFlag[i] == 98 then
			--PlaceStruc("weaponfilter")]]

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

----------------------------
-- just fucking around
----------------------------
-- ancient stuff that no longer has any relevance
--[[
function BoostVeloctiy(gear)

	if (GetGearType(gear) == gtSMine) or
		(GetGearType(gear) == gtMine) or
		(GetGearType(gear) == gtHedgehog) then

			dx,dy = GetGearVelocity(gear)
			SetGearVelocity(gear,dx*1.5,dy*1.5)
		end

end

-- use this stuff when you want to get some idea of land and/or blow up /everything/
function CheckGrenades(gear)

	if GetGearType(gear) == gtGrenade then
		dx, dy = GetGearVelocity(gear)
		if (dy == 0) then

		else
			DeleteGear(gear)
		end
	end

end

function BlowShitUpPartTwo()

	destroyMap = false
	runOnGears(CheckGrenades)

end

function BlowShitUp()

	destroyMap = true

	mapWidth = 4096
	mapHeight = 2048
	blockSize = 50

	mY = 0

	while (mY < WaterLine) do

		mX = 0
		mY = mY + 1*blockSize
		while (mX < mapWidth) do

			mX = mX + (1*blockSize)
			gear = AddGear(mX, mY, gtGrenade, 0, 0, 0, 5000)
			SetState(gear, bor(GetState(gear),gstInvisible) )

		end

	end

end]]


-- you know, using this it might be possible to have a self destructing track,
-- or a moving one.
-- edit: this was from the gold old days before it was possible to erase sprites)
--[[function BoomGirder(x,y,rot)
	girTime = 1
	if rot < 4 then
				AddGear(x, y, gtGrenade, 0, 0, 0, girTime)
	elseif rot == 4 then
				g = AddGear(x-45, y, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x-30, y, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x+30, y, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x+45, y, gtGrenade, 0, 0, 0, girTime) -- needed?
	elseif rot == 5 then ------- diag
				g = AddGear(x+45, y+45, gtGrenade, 0, 0, 0, girTime) --n
				g = AddGear(x+30, y+30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x-30, y-30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x-45, y-45, gtGrenade, 0, 0, 0, girTime) --n
	elseif rot == 6 then
				g = AddGear(x, y-45, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x, y+30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x, y-30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y+45, gtGrenade, 0, 0, 0, girTime) -- needed?
	elseif rot == 7 then -------
				g = AddGear(x+45, y-45, gtGrenade, 0, 0, 0, girTime) --n
				g = AddGear(x+30, y-30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y, gtGrenade, 0, 0, 0, girTime) -- needed?
				g = AddGear(x-30, y+30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x-45, y+45, gtGrenade, 0, 0, 0, girTime) --n
	end
end]]

--[[function SpecialGirderPlacement(x,y,rot)

	PlaceGirder(x, y, rot)
	girTime = 10000

	if rot < 4 then
				AddGear(x, y, gtGrenade, 0, 0, 0, girTime)
	elseif rot == 4 then
				g = AddGear(x-30, y, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x+30, y, gtGrenade, 0, 0, 0, girTime)
	elseif rot == 5 then -------
				g = AddGear(x+30, y+30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x-30, y-30, gtGrenade, 0, 0, 0, girTime)
	elseif rot == 6 then
				g = AddGear(x, y+30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x, y-30, gtGrenade, 0, 0, 0, girTime)
	elseif rot == 7 then -------
				g = AddGear(x+30, y-30, gtGrenade, 0, 0, 0, girTime)
				g = AddGear(x-30, y+30, gtGrenade, 0, 0, 0, girTime)
	end

end]]

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
	--sGear = nil
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
	placedType[placedCount] = loc("Waypoint Placement Mode")
	placedLandFlags[placedCount] = nil -- use this to specify waypoint type maybe
	placedHWMapFlag[placedCount] = 0

	placedSprite[placedCount] = vgtCircle
	placedSpec[placedCount] = AddVisualGear(x,y,vgtCircle,0,true)
	placedTint[placedCount] = 0xFF0000FF
	placedFrame[placedCount] = 1										--rad is 450
	SetVisualGearValues(placedSpec[placedCount], x, y, 20, 100, 1, 10, 0, 450, 5, placedTint[placedCount])
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

	--placedLandFlags[placedCount] = pLandFlags
	if pLandFlags == lfIce then
		placedLandFlags[placedCount] = "lfIce"
	elseif pLandFlags == lfIndestructible then
		placedLandFlags[placedCount] = "lfIndestructible"
	elseif pLandFlags == lfBouncy then
		placedLandFlags[placedCount] = "lfBouncy"
	else
		placedLandFlags[placedCount] = "lfNormal"
	end

	--placedSuperSpec[placedCount] = nil

	placedTint[placedCount] = pTint
	placedFrame[placedCount] = pFrame

	placedSprite[placedCount] = pSprite

	PlaceSprite(pX, pY, pSprite, pFrame, pTint,	nil, nil, nil, pLandFlags)

	placedCount = placedCount + 1

end

function CallPlaceSprite(pID)

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

	PlaceSprite(placedX[pID], placedY[pID], placedSprite[pID], placedFrame[pID],
		placedTint[pID],
		nil, -- overrite existing land
		nil, nil, -- this stuff specifies flipping
		landType)

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
					g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(sSprite)

					--newTint = placedTint[i]
					newTint = 0xFF00FFFF

					SetVisualGearValues(sSprite, placedX[i], placedY[i], 0, 0, g5, placedFrame[i], 10000, placedSprite[i], 10000, newTint )

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

		placedX[closestSpriteID] = nil
		placedY[closestSpriteID] = nil
		placedSpec[closestSpriteID] = nil
		--placedSuperSpec[closestSpriteID] = nil
		placedType[closestSpriteID] = nil
		placedTint[closestSpriteID] = nil
		placedSprite[closestSpriteID] = nil
		placedFrame[closestSpriteID] = nil
		placedLandFlags[closestSpriteID] = nil
		closestSpriteID = nil
		SetVisualGearValues(sSprite, 0, 0, 0, 0, 0, 1, 10000, sprAmGirder, 10000, 0x00000000 )
	end
end

-- work this into the above two functions and edit them, later
function EraseClosestWaypoint()

	closestDist = 999999999
	closestSpriteID = nil -- just in case

	for i = 0, (placedCount-1) do
		if (placedType[i] == loc("Waypoint Placement Mode")) then
				q = placedX[i] - placedX[placedCount]
				w = placedY[i] - placedY[placedCount]
				d = ( (q*q) + (w*w) )
				if d < closestDist then
					closestDist = d
					closestSpriteID = i
					g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(sSprite)

					--newTint = placedTint[i]
					newTint = 0xFF00FFFF

					SetVisualGearValues(sSprite, placedX[i], placedY[i], 0, 0, g5, placedFrame[i], 10000, placedSprite[i], 10000, newTint )

				end
		end
	end

	if closestSpriteID ~= nil then
		DeleteVisualGear(placedSpec[closestSpriteID])
		placedX[closestSpriteID] = nil
		placedY[closestSpriteID] = nil
		placedSpec[closestSpriteID] = nil
		--placedSuperSpec[closestSpriteID] = nil
		placedType[closestSpriteID] = nil
		placedTint[closestSpriteID] = nil
		placedSprite[closestSpriteID] = nil
		placedFrame[closestSpriteID] = nil
		placedLandFlags[closestSpriteID] = nil
		closestSpriteID = nil
		SetVisualGearValues(sSprite, 0, 0, 0, 0, 0, 1, 10000, sprAmGirder, 10000, 0x00000000 )
	end
end


-- essentially called when user clicks the mouse
-- with girders or an airattack
function PlaceObject(x,y)

	placedX[placedCount] = x
	placedY[placedCount] = y
	placedType[placedCount] = cat[cIndex]
	placedSpec[placedCount] = pMode[pIndex]
	--placedSuperSpec[placedCount] = nil
	placedTint[placedCount] = nil
	placedFrame[placedCount] = nil
	placedLandFlags[placedCount] = nil
	placedSprite[placedCount] = nil
	placedHWMapFlag[placedCount] = nil

	if cat[cIndex] == loc("Girder Placement Mode") then

		if superDelete == false then
			--lfObject and lfBasic
			placedFrame[placedCount] = CGR
			placedSprite[placedCount] = sprAmGirder
			CallPlaceSprite(placedCount)

			if landType == lfIndestructible then	specialMod = 1
			elseif landType == lfIce then	specialMod = 2
			else specialMod = 0
			end
			placedHWMapFlag[placedCount] = CGR+100+(8*specialMod)
		else
			placedType[placedCount] = "bogus" -- we need this so we don't think we've placed a new girder and are trying to erase the things we just placed??
			SelectClosestSprite()
			EraseClosestSprite()
		end

	elseif cat[cIndex] == loc("Rubber Placement Mode") then

		if superDelete == false then
			placedFrame[placedCount] = CGR
			placedSprite[placedCount] = sprAmRubber

			--CallPlaceSprite(placedCount)
			--new ermagerd
			placedLandFlags[placedCount] = "lfBouncy"
			placedTint[placedCount] = 255 + (255*0x100) + (255*0x10000) + (255*0x1000000) -- A BGR
			PlaceSprite(placedX[placedCount], placedY[placedCount], placedSprite[placedCount], placedFrame[placedCount],
				placedTint[placedCount],
				nil,
				nil, nil,
				landType)

			if CGR == 0 then placedHWMapFlag[placedCount] = 124
			elseif CGR == 1 then placedHWMapFlag[placedCount] = 125
			elseif CGR == 2 then placedHWMapFlag[placedCount] = 126
			elseif CGR == 3 then placedHWMapFlag[placedCount] = 127
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
		setGearValue(gear,"caseType","med")
	elseif cat[cIndex] == loc("Weapon Crate Placement Mode") then
		gear = SpawnAmmoCrate(x, y, atkArray[pIndex][1])
		placedSpec[placedCount] = atkArray[pIndex][2]
		setGearValue(gear,"caseType","ammo")
		setGearValue(gear,"contents",atkArray[pIndex][2])
	elseif cat[cIndex] == loc("Utility Crate Placement Mode") then
		gear = SpawnUtilityCrate(x, y, utilArray[pIndex][1])
		placedSpec[placedCount] = utilArray[pIndex][2]
		setGearValue(gear,"caseType","util")
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
	elseif cat[cIndex] == loc("Advanced Repositioning Mode") then

		if pMode[pIndex] == loc("Selection Mode") then
			sGear = GetClosestGear()
		elseif pMode[pIndex] == loc("Placement Mode") then
			if sGear ~= nil then
				SetGearPosition(sGear, x, y)
			end
		elseif pMode[pIndex] == loc("Deletion Mode") then
			sGear = GetClosestGear()
			if (sGear ~= nil) and (GetGearType(sGear) ~= gtHedgehog) then
				DeleteGear(sGear)
				sGear = nil
			end
		end

	elseif (cat[cIndex] == loc("Hog Identity Mode")) or (cat[cIndex] == loc("Team Identity Mode")) then

		sGear = GetClosestGear()
		if (sGear ~= nil) and (GetGearType(sGear) == gtHedgehog) then
			if (cat[cIndex] == loc("Hog Identity Mode")) then
				SetHogProfile(sGear, pMode[pIndex])
			else -- set for the whole team
				SetTeamIdentity(sGear)
			end
		else
			AddCaption(loc("Please click on a hedgehog."),0xffba00ff,capgrpVolume)
		end



	elseif cat[cIndex] == loc("Health Modification Mode") then

		sGear = GetClosestGear()
		local gt = GetGearType(sGear)
		if gt == gtHedgehog or gt == gtExplosives or (gt == gtCase and GetGearPos(sGear) == 0x2) then
			if pMode[pIndex][2] == "set" then
				SetHealth(sGear, pMode[pIndex][1])
			elseif pMode[pIndex][2] == "mod" then
				local newHealth = math.max(1, GetHealth(sGear) + tonumber(pMode[pIndex][1]))
				SetHealth(sGear, newHealth)
			end
		else
			AddCaption(loc("Please click on a hedgehog, barrel or health crate."),0xffba00ff,capgrpVolume)
		end

	elseif cat[cIndex] == loc("Sprite Modification Mode") then

		SelectClosestSprite()

		if closestSpriteID ~= nil then
			-- we have a sprite selected somewhere
			--if pMode[pIndex] == "Sprite Selection Mode" then
				-- sprite is now selected, good job
			--elseif pMode[pIndex] == "LandFlag Modification Mode" then
			if pMode[pIndex] == loc("LandFlag Modification Mode") then
				EraseSprite(placedX[closestSpriteID], placedY[closestSpriteID], placedSprite[closestSpriteID], placedFrame[closestSpriteID], nil, nil, nil, nil, placedLandFlags[closestSpriteID])
				CallPlaceSprite(closestSpriteID)
				closestSpriteID = nil
				SetVisualGearValues(sSprite, 0, 0, 0, 0, 0, 1, 10000, sprAmGirder, 10000, 0x00000000 )
			elseif pMode[pIndex] == loc("Sprite Erasure Mode") then

				EraseClosestSprite()

			end
		end


	elseif cat[cIndex] == loc("Tagging Mode") then

		sGear = GetClosestGear()
		if sGear ~= nil then  -- used to be closestGear

			if getGearValue(sGear,"tag") == nil then

				if pMode[pIndex] == loc("Tag Collection Mode") then
					if GetGearType(sGear) == gtCase then
						setGearValue(sGear, "tag","collection")
					else
						AddCaption(loc("Please click on a crate."),0xffba00ff,capgrpVolume)
					end
				else
					if pMode[pIndex] == loc("Tag Victory Mode") then
						setGearValue(sGear, "tag","victory")
					elseif pMode[pIndex] == loc("Tag Failure Mode") then
						setGearValue(sGear, "tag","failure")
					end
				end

			else
				-- remove tag and delete circ
				setGearValue(sGear, "tag", nil)
				DeleteVisualGear(getGearValue(sGear,"tCirc"))
				setGearValue(sGear, "tCirc", nil)
			end



		end


	--elseif cat[cIndex] == loc("Sprite Testing Mode") then

	--	frameID = 0
	--	visualSprite = reducedSpriteIDArray[pIndex]
	--	tempE = AddVisualGear(x, y, vgtStraightShot, 0, true,1)
	--	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
	--	SetVisualGearValues(tempE, g1, g2, 0, 0, g5, frameID, g7, visualSprite, g9, g10 )


	elseif cat[cIndex] == loc("Sprite Placement Mode") then

		if superDelete == false then
			placedFrame[placedCount] = 1
			placedSprite[placedCount] = reducedSpriteIDArray[pIndex]
			CallPlaceSprite(placedCount)
		else
			placedType[placedCount] = "bogus"
			SelectClosestSprite()
			EraseClosestSprite()
		end

	elseif cat[cIndex] == loc("Waypoint Placement Mode") then


		if pMode[pIndex] == loc("Waypoint Deletion Mode") then
			EraseClosestWaypoint()
		else
			PlaceWaypoint(x,y)
			placedCount = placedCount - 1
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
	--	pCount = 1
	elseif cat[cIndex] == loc("Rubber Placement Mode") then
		pIndex = CGR
		pMode = {loc("Rubber")}
		landType = lfBouncy -- for now, let's not allow anything else (-- fairly new addition)
	--	pCount = 1???
	elseif cat[cIndex] == loc("Target Placement Mode") then
		pMode = {loc("Standard Target")}
	elseif cat[cIndex] == loc("Cleaver Placement Mode") then
		pMode = {loc("Standard Cleaver")}
	elseif cat[cIndex] == loc("Barrel Placement Mode") then
		pMode = {60,80,100,120,160,200,240,1,10,20,30,40,50}
	elseif cat[cIndex] == loc("Health Crate Placement Mode") then
		pMode = {25,30,40,50,75,100,150,200,5,10,15,20}
	elseif cat[cIndex] == loc("Weapon Crate Placement Mode") then
		for i = 1, #atkArray do
			pMode[i] = atkArray[i][4] --pMode[i] = atkArray[i][2]
		end
	elseif cat[cIndex] == loc("Utility Crate Placement Mode") then
		for i = 1, #utilArray do
			pMode[i] = utilArray[i][4] --pMode[i] = utilArray[i][2]
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
	elseif cat[cIndex] == loc("Advanced Repositioning Mode") then
		pMode = {loc("Selection Mode"),loc("Placement Mode"), loc("Deletion Mode")}
	elseif cat[cIndex] == loc("Tagging Mode") then
		pMode = {loc("Tag Victory Mode"),loc("Tag Failure Mode"),loc("Tag Collection Mode")}
	elseif cat[cIndex] == loc("Hog Identity Mode") then
		pMode = {loc("Soldier"),loc("Grenadier"),loc("Sniper"),loc("Pyro"),loc("Ninja"),loc("Commander"),loc("Chef"),loc("Engineer"),loc("Physicist"),loc("Trapper"),loc("Saint"),loc("Clown")}
	elseif cat[cIndex] == loc("Team Identity Mode") then
		pMode = {"Clowns","Street Fighters","Cybernetic Empire","Color Squad","Fruit","The Police","The Ninja-Samurai Alliance","Pokemon","The Zoo","The Devs","Mushroom Kingdom","Pirates","Gangsters","Twenty-Twenty","Monsters","The Iron Curtain","The Hospital"}
	elseif cat[cIndex] == loc("Health Modification Mode") then
		pMode = { {100, "set"}, {125, "set"}, {150, "set"}, {200, "set"}, {300, "set"}, {1000, "set"},
			{"-100", "mod"}, {"-10", "mod"}, {"-1", "mod"}, {"+1", "mod"}, {"+10", "mod"}, {"+100", "mod"},
			{1, "set"}, {10, "set"}, {15, "set"}, {20, "set"}, {25, "set"}, {30, "set"}, {40, "set"}, {50, "set"}, {75, "set"}, 
} 
	elseif cat[cIndex] == loc("Sprite Modification Mode") then
		--pMode = {"Sprite Selection Mode","LandFlag Modification Mode","Sprite Erasure Mode"}
		pMode = {loc("LandFlag Modification Mode"),loc("Sprite Erasure Mode")}
	elseif cat[cIndex] == loc("Sprite Testing Mode") or cat[cIndex] == loc("Sprite Placement Mode") then
		--for i = 1, #spriteTextArray do
		--	pMode[i] = spriteTextArray[i]
		--end
		for i = 1, #reducedSpriteTextArray do
			pMode[i] = reducedSpriteTextArray[i]
		end
	elseif cat[cIndex] == loc("Waypoint Placement Mode") then
		pMode = {loc("Standard Waypoint"), loc("Waypoint Deletion Mode")}
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

	--AddTeam(teamname, color, grave, fort, voicepack, flag)
	--AddHog(hogname, botlevel, health, hat)

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

		-- try match team colour to the colours recorded in the colour array

		local tColor = 0x00000000
		for i = 1, #colorArray do
			if GetClanColor(GetHogClan(gear)) == colorArray[i][1] then
				tColor = colorArray[i][2]
			end
		end

		-- no match, just give him a default colour from the array, then
		if tColor == 0x00000000 then
			tColor = colorArray[teamCounter][2]
		end


		-- there is used to be no way to read this data, so
		-- I was assigning teams a random grave, fort, flag and voice
		-- but now we should be able to get the real thing
		-- so let's do it if they haven't used one of the preset teams
		if getGearValue(gear,"grave") == nil then
			tFort = fortArray[1+GetRandom(#fortArray)]
			tGrave = GetHogGrave(gear)
			tFlag = GetHogFlag(gear)
			tVoice = GetHogVoicepack(gear)
			--tGrave = graveArray[1+GetRandom(#graveArray)]
			--tFlag = flagArray[1+GetRandom(#flagArray)]
			--tVoice = voiceArray[1+GetRandom(#voiceArray)]
		else
			tGrave = getGearValue(gear,"grave")
			tFort = getGearValue(gear,"fort")
			tFlag = getGearValue(gear,"flag")
			tVoice = getGearValue(gear,"voice")
		end

		lastRecordedTeam = GetHogTeamName(gear)

		table.insert(tempDataList, "")
		table.insert	(tempDataList,
						"	AddTeam(\"" ..
						GetHogTeamName(gear) .."\"" ..
						", " .. "\"" ..tColor .. "\"" ..
						--		--", " .. colorArray[teamCounter][2] ..
						", " .. "\"" .. tGrave .. "\"" ..
						", " .. "\"" .. tFort .. "\"" ..
						", " .. "\"" .. tVoice .. "\"" ..
						", " .. "\"" .. tFlag .. "\"" ..
						")"
						)

	end

	table.insert(hhs, gear)

	table.insert	(tempDataList,	"	hhs[" .. #hhs .."] = AddHog(\"" ..
					GetHogName(gear) .. "\", " ..
					GetHogLevel(gear) .. ", " ..
					GetHealth(gear) .. ", \"" ..
					GetHogHat(gear) .. "\"" ..
					")"
			)

	table.insert	(tempDataList,"	SetGearPosition(hhs[" .. #hhs .. "], " .. GetX(gear) .. ", " .. GetY(gear) .. ")")

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
	shoppaPointList = {}
	hogDataList = {}
	AIHogDataList = {}

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
	WriteLnToConsole("	Theme = " .. Theme .. "\"")
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
	--WriteLnToConsole("	ScriptParam = " .. ScriptParam)
	WriteLnToConsole("	GetAwayTime = " .. GetAwayTime)

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

		if (getGearValue(gear, "tag") ~= nil) then
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
			table.insert(mineList, "	setGearValue(tempG, \"tag\", \"" .. getGearValue(gear,"tag") .. "\")")
		else

			temp = 	"	tempG = AddGear(" ..
				GetX(gear) .. ", " ..
				GetY(gear) .. ", gtMine, 0, 0, 0, "..GetTimer(gear) .. ")"
			table.insert(mineList, temp)
			if (GetHealth(gear) == 0) then
				table.insert(mineList, "	SetHealth(tempG, 0)")
				local _, damage
				_,_,_,_,_,_,_,_,_,_,_,damage = GetGearValues(gear)
				if damage ~= 0 then
					table.insert(mineList, "	SetGearValues(tempG, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "..damage..")")
				end
			end

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
				GetY(gear) .. ", gtSMine, 0, 0, 0, " ..
				GetTimer(gear) ..")"
		table.insert(sMineList, temp)
		specialFlag = 7

	elseif GetGearType(gear) == gtAirMine then

		if (getGearValue(gear, "tag") ~= nil) then
			temp = 	"	tempG = AddGear(" ..
				GetX(gear) .. ", " ..
				GetY(gear) .. ", gtAirMine, 0, 0, 0, 0)"
			table.insert(airMineList, temp)
			table.insert(airMineList, "	SetTimer(tempG, " .. GetTimer(gear) .. ")")
			table.insert(airMineList, "	setGearValue(tempG, \"tag\", \"" .. getGearValue(gear,"tag") .. "\")")
		else

			temp = 	"	SetTimer(" .. "AddGear(" ..
				GetX(gear) .. ", " ..
				GetY(gear) .. ", gtAirMine, 0, 0, 0, 0)" .. ", " ..
				GetTimer(gear) ..")"
			table.insert(airMineList, temp)

		end

		table.insert(previewDataList, "	PreviewPlacedGear(" .. GetX(gear) ..", " ..	GetY(gear) .. ")")
		specialFlag = 8

	elseif GetGearType(gear) == gtExplosives then

		if (getGearValue(gear, "tag") ~= nil) then
			temp = 	"	tempG = AddGear(" ..
				GetX(gear) .. ", " ..
				GetY(gear) .. ", gtExplosives, 0, 0, 0, 0)"
			table.insert(explosivesList, temp)
			table.insert(explosivesList, "	SetHealth(tempG, " .. GetHealth(gear) .. ")")
			table.insert(explosivesList, "	setGearValue(tempG, \"tag\", \"" .. getGearValue(gear,"tag") .. "\")")
		else

			temp = 	"	SetHealth(" .. "AddGear(" ..
				GetX(gear) .. ", " ..
				GetY(gear) .. ", gtExplosives, 0, 0, 0, 0)" .. ", " ..
				GetHealth(gear) ..")"
			table.insert(explosivesList, temp)

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

		if (GetHealth(gear) ~= nil) and (GetHealth(gear) ~= 0) then

			if (getGearValue(gear, "tag") ~= nil) then
				temp = 	"	tempG = SpawnHealthCrate(" ..
					GetX(gear) ..", " ..
					GetY(gear) ..
					")"
				table.insert(healthCrateList, temp)
				table.insert(healthCrateList, "	SetHealth(tempG, " .. GetHealth(gear) .. ")")
				table.insert(healthCrateList, "	setGearValue(tempG, \"tag\", \"" .. getGearValue(gear,"tag") .. "\")")
			else
				temp = 	"	SetHealth(SpawnHealthCrate(" ..
					GetX(gear) ..", " ..
					GetY(gear) ..
					"), " ..
					GetHealth(gear) ..")"
				table.insert(healthCrateList, temp)
			end

			if 		GetHealth(gear) == 25 then specialFlag = 9
			elseif	GetHealth(gear) == 50 then specialFlag = 10
			elseif	GetHealth(gear) == 75 then specialFlag = 11
			elseif	GetHealth(gear) == 100 then specialFlag = 12
			end

		elseif getGearValue(gear,"caseType") == "ammo" then

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

			--dammit, we probably need two more entries if we want to allow editing of existing maps
			table.insert(wepCrateList, "	setGearValue(tempG, \"caseType\", \"" .. getGearValue(gear,"caseType") .. "\")")
			table.insert(wepCrateList, "	setGearValue(tempG, \"contents\", \"" .. getGearValue(gear,"contents") .. "\")")


		elseif getGearValue(gear,"caseType") == "util" then

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

			--dammit, we probably need two more entries if we want to allow editing of existing maps
			table.insert(utilCrateList, "	setGearValue(tempG, \"caseType\", \"" .. getGearValue(gear,"caseType") .. "\")")
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

	WriteLnToConsole("------ BEGIN SCRIPT ------")
	WriteLnToConsole("-- Copy and Paste this text into an empty text file, and save it as")
	WriteLnToConsole("-- YOURTITLEHERE.lua, in your Data/Missions/Training/ folder.")

	WriteLnToConsole("")

	WriteLnToConsole("HedgewarsScriptLoad(\"/Scripts/Locale.lua\")")
	WriteLnToConsole("HedgewarsScriptLoad(\"/Scripts/Tracker.lua\")")

	WriteLnToConsole("")
	WriteLnToConsole("local hhs = {}")
	--WriteLnToConsole("local ufoGear = nil")
	WriteLnToConsole("")

	WriteLnToConsole("local wepArray = {")
	WriteLnToConsole("		amBazooka, amBee, amMortar, amDrill, amSnowball,")
	WriteLnToConsole("		amGrenade, amClusterBomb, amMolotov, amWatermelon, amHellishBomb, amGasBomb,")
	WriteLnToConsole("		amShotgun, amDEagle, amSniperRifle, amSineGun, amLandGun, amIceGun,")
	WriteLnToConsole("		amFirePunch, amWhip, amBaseballBat, amKamikaze, amSeduction, amHammer,")
	WriteLnToConsole("		amMine, amDynamite, amCake, amBallgun, amRCPlane, amSMine, amAirMine,")
	WriteLnToConsole("		amAirAttack, amMineStrike, amDrillStrike, amNapalm, amPiano, amBirdy,")
	WriteLnToConsole("		amBlowTorch, amPickHammer, amGirder, amRubber, amPortalGun,")
	WriteLnToConsole("		amRope, amParachute, amTeleport, amJetpack,")
	WriteLnToConsole("		amInvulnerable, amLaserSight, amVampiric,")
	WriteLnToConsole("		amLowGravity, amExtraDamage, amExtraTime, amResurrector, amTardis, amSwitch")
	WriteLnToConsole("	}")
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
		if placedType[i] == loc("Waypoint Placement Mode") then
			table.insert(waypointList,
			"	AddWayPoint(" ..
				placedX[i] ..", " ..
				placedY[i] ..")"
				)
			table.insert(hFlagList, "	" .. placedX[i] .. " " .. placedY[i] .. " " .. "0")
			table.insert(previewDataList, "	PreviewWayPoint(" .. placedX[i] ..", " ..	placedY[i] .. ")")
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
				placedTint[i] ..", " .. -- "nil, " .. -- color
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
				placedTint[i] ..", " .. -- "nil, " .. -- color
				"nil, nil, nil, " ..
				"lfBouncy)" --placedLandFlags[i] .. ")" --the landType
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
				placedTint[i] ..", " .. -- "nil, " .. -- color
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
	WriteLnToConsole("			vComment = loc(\"Destroy the red target\")")
	WriteLnToConsole("		else ")
	WriteLnToConsole("			vComment = loc(\"Destroy the red targets\")")
	WriteLnToConsole("		end")
--	WriteLnToConsole("	else")
--	WriteLnToConsole("		vComment = loc(\"Destroy the enemy.\")")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("	if collectObj > 0 then ")
	WriteLnToConsole("		if collectObj == 1 then ")
	WriteLnToConsole("			collectComment = loc(\"Collect the blue target\")")
	WriteLnToConsole("		else ")
	WriteLnToConsole("			collectComment = loc(\"Collect all the blue targets\")")
	WriteLnToConsole("		end")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("	if (collectObj == 0) and (victoryObj == 0) then")
	WriteLnToConsole("		vComment = loc(\"Destroy the enemy.\")")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("	if failObj > 0 then ")
	WriteLnToConsole("		if failObj == 1 then ")
	WriteLnToConsole("			fComment = loc(\"The green target must survive\")")
	WriteLnToConsole("		else ")
	WriteLnToConsole("			fComment = loc(\"The green targets must survive\")")
	WriteLnToConsole("		end")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("	ShowMission(loc(\"User Challenge\"), loc(\"Mission Goals\") .. \":\", collectComment .. \"|\" .. vComment .. \"|\" .. fComment, 0, 0)")
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

	--WriteLnToConsole("	if GetGearType(gear) == gtJetpack then")
	--WriteLnToConsole("		ufoGear = gear")
	--WriteLnToConsole("		if (ufoFuel ~= 0) then")
	--WriteLnToConsole("			SetHealth(ufoGear, ufoFuel)")
	--WriteLnToConsole("		end")
	--WriteLnToConsole("	end")

	WriteLnToConsole("	if isATrackedGear(gear) then")
	WriteLnToConsole("		trackGear(gear)")
	--WriteLnToConsole("		if GetGearType(gear) == gtPortal then")
	--WriteLnToConsole("			setGearValue(gear,\"life\",portalDistance)")
	--WriteLnToConsole("		end")

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
	WriteLnToConsole("				ShowMission(loc(\"User Challenge\"), loc(\"MISSION SUCCESSFUL\"), loc(\"Congratulations!\"), 0, 0)")
	WriteLnToConsole("			elseif (c ==  \"failure\") and (GetHogLevel(hhs[i]) == 0) then")
	WriteLnToConsole("				DismissTeam(GetHogTeamName(hhs[i]))")
	WriteLnToConsole("				ShowMission(loc(\"User Challenge\"), loc(\"MISSION FAILED\"), loc(\"Oh no! Just try again!\"), -amSkip, 0)")
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
	--WriteLnToConsole("	if GetGearType(gear) == gtJetpack then")
	--WriteLnToConsole("		ufoGear = nil")
	--WriteLnToConsole("	end")
	WriteLnToConsole("")
	WriteLnToConsole("	if isATrackedGear(gear) then")
	WriteLnToConsole("")
	WriteLnToConsole("		if getGearValue(gear,\"tag\") ~= nil then")
	WriteLnToConsole("			CheckForConclusion(gear)")
	WriteLnToConsole("		end")

	--WriteLnToConsole("		if getGearValue(gear,\"tag\") == \"failure\" then")
	--WriteLnToConsole("			EndGameIn(\"failure\")")
	--WriteLnToConsole("		elseif getGearValue(gear,\"tag\") == \"victory\" then")
	--WriteLnToConsole("			EndGameIn(\"victory\")")
	--WriteLnToConsole("		end")
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

	WriteLnToConsole("	for i = 1, #wepArray do")
	WriteLnToConsole("		SetAmmo(wepArray[i], 0, 0, 0, 1)")
	WriteLnToConsole("	end")
	WriteLnToConsole("")
	--WriteLnToConsole("	SetAmmo(amBazooka, 2, 0, 0, 0)")
	--WriteLnToConsole("	SetAmmo(amGrenade, 1, 0, 0, 0)")
	--WriteLnToConsole("	SetAmmo(amRope, 9, 0, 0, 0)")
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

	AddCaption(loc("Level Data Saved!"))

end

----------------------------------
-- some special effects handling
----------------------------------
function SmokePuff(x,y,c)
	tempE = AddVisualGear(x, y, vgtSmoke, 0, false)
	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
	SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, 1, g9, c )
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

		if cat[cIndex] == loc("Tagging Mode") then

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
			g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
			SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, 1, g9, col )

			remLife = getGearValue(gear,"life")
			remLife = remLife - 1
			setGearValue(gear, "life", remLife)

			if remLife == 0 then

				tempE = AddVisualGear(GetX(gear)+15, GetY(gear), vgtSmoke, 0, true)
				g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
				SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, col )

				tempE = AddVisualGear(GetX(gear)-15, GetY(gear), vgtSmoke, 0, true)
				g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
				SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, col )

				tempE = AddVisualGear(GetX(gear), GetY(gear)+15, vgtSmoke, 0, true)
				g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
				SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, col )

				tempE = AddVisualGear(GetX(gear), GetY(gear)-15, vgtSmoke, 0, true)
				g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
				SetVisualGearValues(tempE, g1, g2, g3, g4, g5, g6, g7, g8, g9, col )


				PlaySound(sndVaporize)
				DeleteGear(gear)

			end

		end

	end

end

function updateHelp()

	if (GetCurAmmoType() ~= amGirder) and (GetCurAmmoType() ~= amRubber) and (GetCurAmmoType() ~= amAirAttack) then

		ShowMission	(
				loc("HEDGE EDITOR"),
				loc("(well... kind of...)"),
				loc("Place Girder: Girder") .. "|" ..
				loc("Place Rubber: Rubber") .. "|" ..
				loc("Place Gear: Air Attack") .. "|" ..
				loc("Change Selection: [Up], [Down], [Left], [Right]") .. "|" ..
				loc("Toggle Help: Precise+1 (While a tool is selected)") .. "|" ..
				" " .. "|" ..
				loc("COMMANDS: (Use while no weapon is selected)") .. "|" ..
				loc("Save Level: Precise+4") .. "|" ..
				loc("Toggle Editing Weapons and Tools: Precise+2") .. "|" ..
				" " .. "|" ..
				--" " .. "|" ..
				"", 4, 5000
				)
						--4
	elseif cat[cIndex] == loc("Girder Placement Mode") then

		ShowMission	(
				loc("GIRDER PLACEMENT MODE"),
				loc("Use this mode to place girders"),
				loc("Place Girder: [Left Click]") .. "|" ..
				loc("Change Rotation: [Left], [Right]") .. "|" ..
				loc("Change LandFlag: [1], [2], [3], [4]") .. "|" ..
				" " .. "|" ..
				loc("1 - Normal Girder") .. "|" ..
				loc("2 - Indestructible Girder") .. "|" ..
				loc("3 - Icy Girder") .. "|" ..
				loc("4 - Bouncy Girder") .. "|" ..
				" " .. "|" ..
				loc("Deletion Mode: [5]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", -amGirder, 60000
				)

	elseif cat[cIndex] == loc("Rubber Placement Mode") then

		ShowMission	(
				loc("RUBBER PLACEMENT MODE"),
				loc("Use this mode to place rubberbands"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Rotation: [Left], [Right]") .. "|" ..
				--"Change LandFlag: [1], [2], [3]" .. "|" ..
				--" " .. "|" ..
				loc("1 - Normal Rubber") .. "|" ..
				--"2 - Indestructible Rubber" .. "|" ..
				--"3 - Icy Rubber" .. "|" ..
				" " .. "|" ..
				loc("Deletion Mode: [5]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", -amRubber, 60000
				)

	elseif cat[cIndex] == loc("Barrel Placement Mode") then

		ShowMission	(
				loc("BARREL PLACEMENT MODE"),
				loc("Use this mode to place barrels"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Health: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", 8, 60000
				)

	elseif cat[cIndex] == loc("Cleaver Placement Mode") then

		ShowMission	(
				loc("CLEAVER MINE PLACEMENT MODE"),
				loc("Use this mode to place cleavers"),
				loc("Place Object: [Left Click]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", -amKnife, 60000
				)

	elseif cat[cIndex] == loc("Target Placement Mode") then

		ShowMission	(
				loc("TARGET MINE PLACEMENT MODE"),
				loc("Use this mode to place targets"),
				loc("Place Object: [Left Click]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", 1, 60000
				)

	elseif cat[cIndex] == loc("Waypoint Placement Mode") then

		ShowMission	(
				loc("WAYPOINT PLACEMENT MODE"),
				loc("Use this mode to waypoints"),
				loc("Place Waypoint: [Left Click]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", -amAirAttack, 60000
				)

	elseif cat[cIndex] == loc("Mine Placement Mode") then

		ShowMission	(
				loc("MINE PLACEMENT MODE"),
				loc("Use this mode to place mines"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Timer (in milliseconds): [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", -amMine, 60000
				)

	elseif cat[cIndex] == loc("Dud Mine Placement Mode") then

		ShowMission	(
				loc("DUD MINE PLACEMENT MODE"),
				loc("Use this mode to place dud mines"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Health: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", -amMine, 60000
				)

	elseif cat[cIndex] == loc("Sticky Mine Placement Mode") then

		ShowMission	(
				loc("STiCKY MINE PLACEMENT MODE"),
				loc("Use this mode to place sticky mines"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Timer (in milliseconds): [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", -amSMine, 60000
				)

	elseif cat[cIndex] == loc("Air Mine Placement Mode") then

		ShowMission	(
				loc("AIR MINE PLACEMENT MODE"),
				loc("Use this mode to place air mines"),
				loc("Place Object: [Left Click]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", -amAirMine, 60000
				)

	elseif cat[cIndex] == loc("Weapon Crate Placement Mode") then

		ShowMission	(
				"WEAPON CRATE PLACEMENT MODE",
				loc("Use this mode to place weapon crates"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Content: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", 7, 60000
				)

	elseif cat[cIndex] == loc("Utility Crate Placement Mode") then

		ShowMission	(
				loc("UTILITY CRATE PLACEMENT MODE"),
				loc("Use this mode to place utility crates"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Content: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", 5, 60000
				)

	elseif cat[cIndex] == loc("Health Crate Placement Mode") then

		ShowMission	(
				loc("HEALTH CRATE PLACEMENT MODE"),
				loc("Use this mode to place utility crates"),
				loc("Place Object: [Left Click]") .. "|" ..
				loc("Change Health Boost: [Left], [Right]") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", 6, 60000
				)

	elseif cat[cIndex] == loc("Advanced Repositioning Mode") then

		ShowMission	(
				loc("ADVANCED REPOSITIONING MODE"),
				loc("Use this mode to select and reposition gears"),
				loc("[Left], [Right]: Change between selection and placement mode.") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", -amAirAttack, 60000
				)

	elseif cat[cIndex] == loc("Sprite Modification Mode") then

		ShowMission	(
				loc("SPRITE MODIFICATION MODE"),
				"",
				"Use this mode to select, modify, or delete existing girders," .. "|" ..
				"rubbers, or sprites." .. "|" ..
				"[Left], [Right]: Change between land-flag" .. "|" ..
				--"[Left], [Right]: Change between selection, land-flag" .. "|" ..
				"modification, and deletion modes." .. "|" ..
				"While in modification mode, you can " .. "|" ..
				"change land-flag by clicking on an object." .. "|" ..
				loc("Set LandFlag: [1], [2], [3], [4]") .. "|" ..
				" " .. "|" ..
				loc("1 - Normal Land") .. "|" ..
				loc("2 - Indestructible Land") .. "|" ..
				loc("3 - Icy Land") .. "|" ..
				loc("4 - Bouncy Land") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", -amAirAttack, 60000
				)

	elseif cat[cIndex] == loc("Sprite Placement Mode") then

		ShowMission	(
				loc("SPRITE PLACEMENT MODE"),
				loc("Use this mode to place custom sprites."),
				loc("[Left], [Right]: Change sprite selection") .. "|" ..
				loc("Set LandFlag: [1], [2], [3], [4]") .. "|" ..
				" " .. "|" ..
				loc("1 - Normal Land") .. "|" ..
				loc("2 - Indestructible Land") .. "|" ..
				loc("3 - Icy Land") .. "|" ..
				loc("4 - Bouncy Land") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", 2, 60000
				)

	--elseif cat[cIndex] == loc("Sprite Testing Mode") then

	--	ShowMission	(
	--			"SPRITE TESTING MODE",
	--			"Use this mode to test sprites before you place them.",
	--			"Place Temporary Visual Test: [Left Click]" .. "|" ..
	--			"[Left], [Right]: Change between sprites." .. "|" ..
	--			" " .. "|" ..
	--			loc("Change Placement Mode: [Up], [Down]") .. "|" ..
	--			loc("Toggle Help: Precise+1") .. "|" ..
	--			"", 3, 60000
	--			)

	elseif cat[cIndex] == loc("Tagging Mode") then

		ShowMission	(
				loc("TAGGING MODE"),
				loc("Use this mode to tag gears for win/lose conditions."),
				loc("Tag Gear: [Left Click]") .. "|" ..
				loc("[Left], [Right]: Change between tagging modes.") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", 3, 60000
				)
	elseif cat[cIndex] == loc("Hog Identity Mode") then

		ShowMission	(
				loc("HOG IDENTITY MODE"),
				loc("Use this mode to give a hog a preset identity and weapons."),
				loc("Set Identity: [Left Click]") .. "|" ..
				loc("[Left], [Right]: Change between identities.") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", 3, 60000
				)

	elseif cat[cIndex] == loc("Team Identity Mode") then

		ShowMission	(
				loc("TEAM IDENTITY MODE"),
				loc("Use this mode to give an entire team themed hats and names."),
				loc("Set Identity: [Left Click]") .. "|" ..
				loc("[Left], [Right]: Change between identities.") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", 3, 60000
				)

	elseif cat[cIndex] == loc("Health Modification Mode") then

		ShowMission	(
				loc("HEALTH MODIFICATION MODE"),
				loc("Use this mode to set the health of hogs, health crates and barrels."),
				loc("Set Health: [Left Click]") .. "|" ..
				loc("[Left], [Right]: Change health value.") .. "|" ..
				" " .. "|" ..
				loc("Change Placement Mode: [Up], [Down]") .. "|" ..
				loc("Toggle Help: Precise+1") .. "|" ..
				"", 3, 60000
				)

	end


	if helpDisabled == true then
		HideMission()
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

		if (curWep == amAirAttack) then

			--wowaweewa, holyeeeee shite this is badly hacked (please rewrite when less lazy/morefeatures)
			dCol = 0xFFFFFFFF
			dFrame = 0
			dAngle = 0
			if (cat[cIndex] == loc("Mine Placement Mode")) then
				dSprite = sprBotlevels--sprMineOff
				dFrame = 1
			elseif (cat[cIndex] == loc("Dud Mine Placement Mode")) then
				-- TODO: Use dud mine sprite instead of sprite of normal mine
				dSprite = sprBotlevels--sprMineOff
				dFrame = 1
			elseif (cat[cIndex] == loc("Sticky Mine Placement Mode")) then
				dSprite = sprBotlevels--sprSMineOff
				dFrame = 2
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
				dFrame = 1
			else
				dCol = 0xFFFFFF00
				dSprite = sprArrow
			end

			if CG == nil then
				CG = AddVisualGear(CursorX, CursorY, vgtStraightShot,0,true,3)
			end
			g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(CG)
			SetVisualGearValues(CG, CursorX, CursorY, 0, 0, dAngle, dFrame, 1000, dSprite, 1000, dCol)



			if crateSprite == nil then
				crateSprite = AddVisualGear(CursorX, CursorY-35, vgtStraightShot,0,true,3)
				for i = 1, 4 do
					tSpr[i] = AddVisualGear(CursorX, CursorY-35, vgtStraightShot,0,true,3)
				end
			end


			if (cat[cIndex] == loc("Weapon Crate Placement Mode")) or (cat[cIndex] == loc("Utility Crate Placement Mode")) then
				if (cat[cIndex] == loc("Weapon Crate Placement Mode")) then
					tArr = atkArray
				else
					tArr = utilArray
				end

				tSprCol = 0xFFFFFFFF
				tempFrame = tArr[pIndex][3]

			end

		else
			if CG ~= nil then
				SetVisualGearValues(CG, 0, 0, 0, 0, 0, 0, 1000, sprArrow, 1000, 0xFFFFFF00)
			end
		end

		SetVisualGearValues(crateSprite, CursorX+xDisplacement, CursorY+yDisplacement, 0, 0, dAngle, tempFrame, 1000, sprAMAmmos, 1000, tSprCol)
		SetVisualGearValues(tSpr[1], CursorX+xDisplacement-2, CursorY+yDisplacement-2, 0, 0, dAngle, 10, 1000, sprTarget, 1000, tSprCol)
		SetVisualGearValues(tSpr[2], CursorX+xDisplacement-2, CursorY+yDisplacement+2, 0, 0, dAngle, 10, 1000, sprTarget, 1000, tSprCol)
		SetVisualGearValues(tSpr[3], CursorX+xDisplacement+2, CursorY+yDisplacement-2, 0, 0, dAngle, 10, 1000, sprTarget, 1000, tSprCol)
		SetVisualGearValues(tSpr[4], CursorX+xDisplacement+2, CursorY+yDisplacement+2, 0, 0, dAngle, 10, 1000, sprTarget, 1000, tSprCol)


		if genTimer >= 100 then

			genTimer = 0

			--if destroyMap == true then
			--	BlowShitUpPartTwo()
			--end

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
				--updateHelp()
			elseif (cIndex == 2) and (curWep ~= amRubber) then
				cIndex = 3 --new
				RedefineSubset()
				--updateHelp()

			end

			-- update display selection criteria
			if (curWep == amGirder) or (curWep == amRubber) or (curWep == amAirAttack) then
				AddCaption(cat[cIndex],0xffba00ff,capgrpMessage)
				local caption2
				if type(pMode[pIndex]) == "table" then
					caption2 = tostring(pMode[pIndex][1])
				else
					caption2 = tostring(pMode[pIndex])
				end
				AddCaption(caption2,0xffba00ff,capgrpMessage2)
				if superDelete == true then
					AddCaption(loc("Warning: Deletition Mode Active"),0xffba00ff,capgrpAmmoinfo)
				end
			end


			if sSprite ~= nil then
				g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(sSprite)
				SetVisualGearValues(sSprite, g1, g2, 0, 0, g5, g6, 10000, g8, 10000, g10 )
				--AddCaption(g7)
			end

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
	if (cat[cIndex] == loc("Advanced Repositioning Mode")) and (sGear ~= nil) then
		SetVisualGearValues(sCirc, GetX(sGear), GetY(sGear), 100, 255, 1, 10, 0, 300, 3, 0xff00ffff)
	elseif (cat[cIndex] == loc("Sprite Modification Mode")) and (sSprite ~= nil) then
		g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(sSprite)
		SetVisualGearValues(sSprite, g1, g2, 0, 0, g5, g6, 10000, g8, 10000, g10 )
	elseif (cat[cIndex] == loc("Tagging Mode")) then
		if (sGear ~= nil) or (closestGear ~= nil) then
			--recently disabled
			--SetVisualGearValues(sCirc, GetX(sGear), GetY(sGear), 0, 1, 1, 10, 0, 1, 1, 0x00000000)
			closestGear = nil
			sGear = nil
		end
	end


	runOnGears(UpdateTagCircles)


	-- some kind of target detected, tell me your story
	if cGear ~= nil then

		x,y = GetGearTarget(cGear)

		if GetGearType(cGear) == gtAirAttack then
			DeleteGear(cGear)
			PlaceObject(x, y)
		elseif GetGearType(cGear) == gtGirder then

			CGR = GetState(cGear)

			-- improve rectangle test based on CGR when you can be bothered
			--if TestRectForObstacle(x-20, y-20, x+20, y+20, true) then
			--	AddCaption(loc("Invalid Girder Placement"),0xffba00ff,capgrpVolume)
			--else
				PlaceObject(x, y)
			--end

			-- this allows the girder tool to be used like a mining laser

		--[[

			if CGR < 4 then
				AddGear(x, y, gtGrenade, 0, 0, 0, 1)
			elseif CGR == 4 then
				g = AddGear(x-30, y, gtGrenade, 0, 0, 0, 1)
				g = AddGear(x+30, y, gtGrenade, 0, 0, 0, 1)
			elseif CGR == 5 then -------
				g = AddGear(x+30, y+30, gtGrenade, 0, 0, 0, 1)
				g = AddGear(x-30, y-30, gtGrenade, 0, 0, 0, 1)
			elseif CGR == 6 then
				g = AddGear(x, y+30, gtGrenade, 0, 0, 0, 1)
				g = AddGear(x, y-30, gtGrenade, 0, 0, 0, 1)
			elseif CGR == 7 then -------
				g = AddGear(x+30, y-30, gtGrenade, 0, 0, 0, 1)
				g = AddGear(x-30, y+30, gtGrenade, 0, 0, 0, 1)
			end
]]
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
		if GetAmmoCount(CurrentHedgehog, amAirAttack) == 100 then
			SetEditingWeps(0)
			AddCaption(loc("The editor weapons and tools have been removed!"))
		else
			SetEditingWeps(100)
			AddCaption(loc("The editor weapons and tools have been added!"))
		end
	elseif (preciseOn == true) and (s == 1) then
		if (GetCurAmmoType() == amGirder) or  (GetCurAmmoType() == amRubber) or  (GetCurAmmoType() == amAirAttack) then
			helpDisabled = not(helpDisabled)
			AddCaption("Help Disabled: " .. BoolToString(helpDisabled),0xffba00ff,capgrpVolume)
			updateHelp()
		end
	elseif (cat[cIndex] == loc("Sprite Placement Mode")) or (cat[cIndex] == loc("Girder Placement Mode")) or (cat[cIndex] == loc("Rubber Placement Mode")) or (cat[cIndex] == loc("Sprite Modification Mode")) then

		if (cat[cIndex] == loc("Rubber Placement Mode")) and (s ~= 5) then
			landType = lfBouncy
			AddCaption(loc("Bouncy Land"),0xffba00ff,capgrpAmmoinfo)
		elseif s == 1 then
			landType = 0
			AddCaption(loc("Normal Land"),0xffba00ff,capgrpAmmoinfo)
		elseif s == 2 then
			landType = lfIndestructible
			AddCaption(loc("Indestructible Land"),0xffba00ff,capgrpAmmoinfo)
		elseif s == 3 then
			landType = lfIce
			AddCaption(loc("Icy Land"),0xffba00ff,capgrpAmmoinfo)
		elseif (s == 4) then --and (cat[cIndex] == "Sprite Placement Mode") then
			landType = lfBouncy
			AddCaption(loc("Bouncy Land"),0xffba00ff,capgrpAmmoinfo)
		elseif (s == 5) and (cat[cIndex] ~= loc("Sprite Modification Mode")) then
			superDelete = true
			-- this and the above should probably be shown in another place where the other
			-- two add captions are displayed for this kinda thing
			--AddCaption(loc("Warning: Deletition Mode Active"),0xffba00ff,capgrpAmmoinfo)
		end
	elseif pMode[pIndex] == loc("Selection Mode") then
		setGearValue(sGear, "ranking", s)
	end

end

function onPrecise()

	preciseOn = true

	--ParseCommand("voicepack " .. "Surfer")
	--AddCaption(GetHogGrave(CurrentHedgehog))

	--if (pMode[pIndex] == "Selection Mode") and (closestGear ~= nil) then
	--	menuEnabled = not(menuEnabled)
		--showmenu
	--end

	--BlowShitUp()

--[[
	frameID = 1
	visualSprite = sprAmGirder--reducedSpriteIDArray[pIndex]
	--visualSprite = spriteIDArray[pIndex]
	tempE = AddVisualGear(1, 1, vgtStraightShot, 0, true,1)
	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tempE)
	SetVisualGearValues(tempE, g1, g2, 0, 0, g5, frameID, g7, visualSprite, g9, g10 )

]]

end

function onPreciseUp()
	preciseOn = false
end

--[[function onLJump()
end

function onHJump()
end]]

--[[function UpdateMenu()

	preMenuCfg = loc("Use the arrow keys to navigate this menu") .. "|"
	postMenuCfg = loc("Press [Fire] to accept this configuration.")

	menu = 	{
			loc("Walls Required") .. ": " .. #wTouched .. "|",
			loc("Surf Before Crate") .. ": " .. BoolToCfgTxt(requireSurfer) .. "|",
			loc("Attack From Rope") .. ": " .. BoolToCfgTxt(AFR) .. "|",
			loc("Super Weapons") .. ": " .. BoolToCfgTxt(allowCrazyWeps) .. "|"
			}
end

function HandleStartingStage()

	temp = menu[menuIndex]
	menu[menuIndex] = "--> " .. menu[menuIndex]

	missionComment = ""
	for i = 1, #menu do
		missionComment = missionComment .. menu[i]
	end

	ShowMission	(
				loc("HEDGE EDITOR") .. " 0.4",
				loc("Edit gear properties"),
				preMenuCfg..
				missionComment ..
				postMenuCfg ..
				--" " .. "|" ..
				"", 4, 300000
				)

	menu[menuIndex] = temp

end

function UpdateMenuCategoryOrSomething()
	temp = menu[1]
	menu = {}
	if temp == "Initialisation Menu" then
		for i = 1, #initMenuArray do
			menu[i] = initMenuArray[i] .. ": " .. initMenuArray[2]
		end
	elseif temp == "GameFlag Menu" then
		for i = 1, #gameFlagList do
			menu[i] = gameFlagList[1] .. ": " .. BoolToStr(gameFlagList[2])
		end
	elseif temp == "Ammo Menu" then
		for i  = 1, #atkArray do	--except, this should be per hog, not overall :(
			--menu[i] = atkArray[i][2] .. ": " .. atkArray[i][3]
			menu[i] = atkArray[i][2] .. ": " .. getGearValue(sGear,atkArray[i][1])
		end
		-- you should run through all the hogs and assign them ammo values based on the
		-- ammo set, yea, let's write that function in 5th
		for i = #menu, #utilArray do
		end
	end
end

function doMenuShit(d)

	if d == "up" then
		menuIndex = menuIndex -1
		if 	menuIndex == 0 then
			menuIndex = #menu
		end
	elseif d == "down" then
		menuIndex = menuIndex +1
		if menuIndex > #menu then
			menuIndex = 1
		end
	elseif d == "left" then

	elseif d == "right" then

	end

end]]

---------------------------------------------------------------
-- Cycle through selection subsets (by changing pIndex, pMode)
-- i.e 	health of barrels, medikits,
--		timer of mines
--		contents of crates etc.
---------------------------------------------------------------
function onLeft()

	leftHeld = true
	rightHeld = false

	--if menuEnabled == true then
		--doMenuShit("left")

	--else -- normal case

		pIndex = pIndex - 1
		if pIndex == 0 then
			pIndex = #pMode
		end

		if (curWep == amGirder) or (curWep == amRubber) or (curWep == amAirAttack) then
			AddCaption(pMode[pIndex],0xffba00ff,capgrpMessage2)
		end

	--end

end

function onRight()

	leftHeld = false
	rightHeld = true

	--if menuEnabled == true then
		--doMenuShit("right")

	--else -- normal case

		pIndex = pIndex + 1
		if pIndex > #pMode then
			pIndex = 1
		end

		if (curWep == amGirder) or (curWep == amRubber) or (curWep == amAirAttack) then
			AddCaption(pMode[pIndex],0xffba00ff,capgrpMessage2)
		end

	--end

end

---------------------------------------------------------
-- Cycle through primary categories (by changing cIndex)
-- i.e 	mine, sticky mine, barrels
--		health/weapon/utility crate, placement of gears
---------------------------------------------------------
function onUp()

	--if menuEnabled == true then
		--doMenuShit("up")

	--elseif (curWep ~= amGirder) then
	if (curWep ~= amGirder) then
		--AddCaption(cIndex)
		cIndex = cIndex - 1
		if (cIndex == 1) or (cIndex == 2) then --1	--we no longer hit girder by normal means
			cIndex = #cat
		end

		RedefineSubset()
		updateHelp()

	end

end

function onDown()

	--if menuEnabled == true then
		--doMenuShit("down")

	--elseif (curWep ~= amGirder) then
	if (curWep ~= amGirder) then
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
	--Map = "Islands"
	--Theme = "Deepspace"
	--Seed = "{bacb2f87-f316-4691-a333-3bcfc4fb3d88}"
	--MapGen = 0 -- 0:generated map, 1:generated maze, 2:hand drawn map
	--TemplateFilter = 5	-- small=1,med=2,large=3,cavern=4,wacky=5

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

	Explosives = 0
	MinesNum = 0

	--GameFlags = GameFlags + gfInfAttack
	EnableGameFlags(gfInfAttack, gfDisableWind)

	RedefineSubset()

end

function onGameStart()

	trackTeams()


	InterpretPoints()
	LoadLevelData()

	ShowMission	(
				loc("HEDGE EDITOR"),
				loc("(well... kind of...)"),
				loc("Place Girder: Girder") .. "|" ..
				loc("Place Rubber: Rubber") .. "|" ..
				loc("Place Gear: Air Attack") .. "|" ..
				loc("Change Selection: [Up], [Down], [Left], [Right]") .. "|" ..
				loc("Toggle Help: Precise+1 (While a tool is selected)") .. "|" ..
				" " .. "|" ..
				loc("COMMANDS: (Use while no weapon is selected)") .. "|" ..
				loc("Save Level: Precise+4") .. "|" ..
				loc("Toggle Editing Weapons and Tools: Precise+2") .. "|" ..
				" " .. "|" ..
				--" " .. "|" ..
				"", 4, 5000
				)


	sCirc = AddVisualGear(0,0,vgtCircle,0,true)
	SetVisualGearValues(sCirc, 0, 0, 100, 255, 1, 10, 0, 40, 3, 0xffba00ff)


	frameID = 1
	visualSprite = sprAmGirder
	sSprite = AddVisualGear(0, 0, vgtStraightShot, 0, true,1)
	g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(sSprite)
	SetVisualGearValues(sSprite, 1, 1, 0, 0, g5, frameID, 20000, visualSprite, 20000, g10 )

	SetAmmoDelay(amAirAttack,0)
	SetAmmoDelay(amGirder,0)
	SetAmmoDelay(amRubber,0)
	--SetAmmoDelay(amNapalm,0)
	--SetAmmoDelay(amDrillStrike,0)
	--SetAmmoDelay(amMineStrike,0)

end

function SetEditingWeps(ammoCount)

	AddAmmo(CurrentHedgehog, amAirAttack, ammoCount)
	AddAmmo(CurrentHedgehog, amGirder, ammoCount)
	AddAmmo(CurrentHedgehog, amRubber, ammoCount)
	--AddAmmo(CurrentHedgehog, amPortalGun, ammoCount)
	AddAmmo(CurrentHedgehog, amTeleport, ammoCount)
	AddAmmo(CurrentHedgehog, amRope, ammoCount)
	--AddAmmo(CurrentHedgehog, amJetpack, ammoCount)
	--AddAmmo(CurrentHedgehog, amParachute, ammoCount)
	AddAmmo(CurrentHedgehog, amSwitch, 100) --ammoCount
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
	--runOnHogsInTeam(AssignTeam(gear),tName)
	runOnHogs(AssignTeam)
end

function AssignTeam(gear)

	if GetHogTeamName(gear) == tName then

		setGearValue(gear,"flag",preMadeTeam[pIndex][5])
		setGearValue(gear,"voice",preMadeTeam[pIndex][6])
		setGearValue(gear,"grave",preMadeTeam[pIndex][7])
		setGearValue(gear,"fort",preMadeTeam[pIndex][8])

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
				SetHogName(gear,nArr[i])
				table.remove(nArr,i)
			else
				SetHogName(gear,preMadeTeam[pIndex][3][1+GetRandom(#preMadeTeam[pIndex][3])])
			end

		elseif preMadeTeam[pIndex][4] == "F" then -- fixed team w/ exactly 8 guys
			SetHogName(gear,preMadeTeam[pIndex][3][hIndex])
			SetHogHat(gear,preMadeTeam[pIndex][2][hIndex])
			hIndex = hIndex +1
		else -- FR fixed random team with more or less than 8 guys

			if #hArr > 0 then
				i = 1+GetRandom(#hArr)
				SetHogHat(gear,hArr[i])
				SetHogName(gear,nArr[i])
				table.remove(hArr,i)
				table.remove(nArr,i)
			else
				SetHogHat(gear,"NoHat")
				SetHogName(gear,"Uninspiring hog")
			end

		end

	end

end

-- allows you to set a sort of identity and weapon profile for a given hog
-- this should only really be used when perHogAmmo is enabled
function SetHogProfile(gear, pro)

	clearAmmo(gear)

	if pro == loc("Sniper") then

		SetHogName(gear,"Sniper")
		SetHogHat(gear, "Sniper")
		SetHealth(gear, 50)
		AddAmmo(gear, amSniperRifle, 100)
		AddAmmo(gear, amDEagle, 100)

	elseif pro == loc("Pyro") then

		SetHogName(gear,loc("Pyro"))
		SetHogHat(gear, "Gasmask")
		SetHealth(gear, 80)
		AddAmmo(gear, amFlamethrower, 100)
		AddAmmo(gear, amMolotov, 100)
		AddAmmo(gear, amNapalm, 1)

	elseif pro == loc("Soldier") then

		SetHogName(gear,loc("Soldier"))
		--SetHogHat(gear, "war_americanww2helmet")
		SetHogHat(gear, "TeamSoldier")
		SetHealth(gear, 100)
		AddAmmo(gear, amBazooka, 100)
		AddAmmo(gear, amShotgun, 100)
		AddAmmo(gear, amMortar, 100)

	elseif pro == loc("Grenadier") then

		SetHogName(gear,loc("Grenadier"))
		SetHogHat(gear, "war_desertgrenadier1")
		SetHealth(gear, 100)
		AddAmmo(gear, amGrenade, 100)
		AddAmmo(gear, amClusterBomb, 100)
		AddAmmo(gear, amGasBomb, 100)

	elseif pro == loc("Chef") then

		SetHogName(gear,loc("Chef"))
		SetHogHat(gear, "chef")
		SetHealth(gear, 65)
		AddAmmo(gear, amGasBomb, 100)
		AddAmmo(gear, amKnife, 100)
		AddAmmo(gear, amCake, 1)
		--AddAmmo(gear, amWatermelon, 1)

	elseif pro == loc("Ninja") then

		SetHogName(gear,loc("Ninja"))
		SetHogHat(gear, "NinjaFull")
		SetHealth(gear, 80)
		AddAmmo(gear, amRope, 100)
		AddAmmo(gear, amFirePunch, 100)
		AddAmmo(gear, amParachute, 1)

	elseif pro == loc("Commander") then

		SetHogName(gear,loc("Commander"))
		SetHogHat(gear, "sf_vega")
		SetHealth(gear, 120)
		AddAmmo(gear, amDEagle, 100)
		AddAmmo(gear, amAirAttack, 2)
		AddAmmo(gear, amNapalm, 1)
		AddAmmo(gear, amDrillStrike, 1)
		AddAmmo(gear, amMineStrike, 1)

	elseif pro == loc("Engineer") then

		SetHogName(gear,loc("Engineer"))
		SetHogHat(gear, "Glasses")
		SetHealth(gear, 45)
		AddAmmo(gear, amGirder, 4)
		AddAmmo(gear, amRubber, 2)
		AddAmmo(gear, amLandGun, 2)
		AddAmmo(gear, amBlowTorch, 100)
		AddAmmo(gear, amPickHammer, 100)

	elseif pro == loc("Physicist") then

		SetHogName(gear,loc("Physicist"))
		SetHogHat(gear, "lambda")
		SetHealth(gear, 80)
		AddAmmo(gear, amIceGun, 2)
		AddAmmo(gear, amSineGun, 100)
		AddAmmo(gear, amBee, 2)
		AddAmmo(gear, amLowGravity, 100)

	elseif pro == loc("Trapper") then

		SetHogName(gear,loc("Trapper"))
		SetHogHat(gear, "Skull")
		SetHealth(gear, 100)
		AddAmmo(gear, amMine, 100)
		AddAmmo(gear, amSMine, 4)
		AddAmmo(gear, amAirMine, 2)
		AddAmmo(gear, amMolotov, 100)

	elseif pro == loc("Saint") then

		SetHogName(gear,loc("Saint"))
		SetHogHat(gear, "angel")
		SetHealth(gear, 200)
		AddAmmo(gear, amSeduction, 100)
		AddAmmo(gear, amInvulnerable, 100)
		AddAmmo(gear, amIceGun, 2)
		AddAmmo(gear, amHammer, 100)
		AddAmmo(gear, amResurrector, 100)

	elseif pro == loc("Clown") then

		SetHogName(gear,loc("Clown"))
		SetHogHat(gear, "clown-copper")
		SetHealth(gear, 70)
		AddAmmo(gear, amBaseballBat, 100)
		AddAmmo(gear, amGasBomb, 100)
		AddAmmo(gear, amBallgun, 1)
		AddAmmo(gear, amKamikaze, 1)
		--AddAmmo(gear, amPiano, 1)

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
		TurnTimeLeft = 1 -- skip the computer's turn
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

-- track hedgehogs and placement gears
function onGearAdd(gear)

	if GetGearType(gear) == gtJetpack then
		ufoGear = gear
		if (ufoFuel ~= 0) then
			SetHealth(ufoGear, ufoFuel)
		end
	end

	if GetGearType(gear) == gtHedgehog then
		--table.insert(hhs, gear)
	elseif (GetGearType(gear) == gtAirAttack) or (GetGearType(gear) == gtGirder) then
		cGear = gear
	end

	if isATrackedGear(gear) then
		trackGear(gear)

		if GetGearType(gear) == gtPortal then
			setGearValue(gear,"life",portalDistance)
		end

	end

end

function onGearDelete(gear)

	if GetGearType(gear) == gtJetpack then
		ufoGear = nil
	end

	if (GetGearType(gear) == gtAirAttack) or (GetGearType(gear) == gtGirder) then
		cGear = nil
	end

	if isATrackedGear(gear) then

		if getGearValue(gear, "tCirc") ~= nil then
			DeleteVisualGear(getGearValue(gear, "tCirc"))
		end

		trackDeletion(gear)

	end

end


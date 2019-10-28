HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/RopeKnocking.lua")

-- In this mission, the names of the enemy hogs are chosen randomly from this list.
-- As a nod to the community, this list contains names of actual users/players;
-- Mostly developers, contributors, high-ranking players in a shoppa tournament,
-- highly active forum users.

-- NOTE: These names are intentionally not translated.
local hogData =	{
	{"amn",			"NinjaFull"},
	{"alfadur",		"NoHat"},
	{"Anachron",		"war_americanww2helmet"},
	{"Bufon", 		"ShaggyYeti"},
	{"burp", 		"lambda"},
	{"Blue", 		"cap_blue"},
	{"bender", 		"NoHat"},
	{"Castell",		"NoHat"},
	{"cekoto", 		"NoHat"},
	{"CheezeMonkey",	"NoHat"},
	{"claymore", 		"NoHat"},
	{"CIA-144", 		"cyborg1"},
	{"cri.the.grinch",	"sf_blanka"},
	{"eldiablo",		"Evil"},
	{"Displacer",		"fr_lemon"},
	{"doomy", 		"NoHat"},
	{"Falkenauge", 		"NoHat"},
	{"FadeOne", 		"NoHat"},
	{"hayaa", 		"NoHat"},
	{"Hermes", 		"laurel"},
	{"Henek", 		"WizardHat"},
	{"HedgeKing",		"NoHat"},
	{"Izack1535", 		"NoHat"},
	{"Kiofspa", 		"NoHat"},
	{"KoBeWi",		"NoHat"},
	{"Komplex", 		"NoHat"},
	{"koda", 		"poke_mudkip"},
	{"Lalo", 		"NoHat"},
	{"Logan", 		"NoHat"},
	{"lollkiller", 		"NoHat"},
	{"Luelle", 		"NoHat"},
	{"mikade", 		"Skull"},
	{"Mushi", 		"sm_daisy"},
	{"Naboo", 		"NoHat"},
	{"nemo", 		"bb_bub"},
	{"practice", 		"NoHat"},
	{"Prof. Panic",  	"NoHat"},
	{"Randy",		"zoo_Sheep"},
	{"rhino", 		"NinjaTriangle"},
	{"Radissthor",  	"NoHat"},
	{"Sami",		"sm_peach"},
	{"soreau", 		"NoHat"},
	{"Solar",		"pinksunhat"},
	{"sparkle",		"NoHat"},
	{"szczur", 		"mp3"},
	{"sdw195", 		"NoHat"},
	{"sphrix", 		"TeamTopHat"},
	{"sheepluva",		"zoo_Sheep"},
	{"Smaxx", 		"NoHat"},
	{"shadowzero", 		"NoHat"},
	{"Star and Moon",	"SparkleSuperFun"},
	{"The 24",		"NoHat"},
	{"TLD",			"NoHat"},
	{"Tiyuri", 		"sf_ryu"},
	{"unC0Rr", 		"cyborg1"},
	{"Waldsau", 		"cyborg1"},
	{"wolfmarc", 		"knight"},
	{"Wuzzy",		"fr_orange"},
	{"Xeli", 		"android"}
}

local function assignNamesAndHats(team)
	for t=1, #team do
		local d = 1 + GetRandom(#hogData)
		team[t].name = hogData[d][1]
		team[t].hat = hogData[d][2]
		table.remove(hogData, d)
	end
end


local enemyTeam1 = {
	{ x = 3350, y = 570 },
	{ x = 3039, y = 1300 },
	{ x = 2909, y = 430 },
	{ x = 2150, y = 879 },
	{ x = 1735, y = 1136 },
	{ x = 1563, y = 553 },
	{ x = 679, y = 859 },
	{ x = 1034, y = 251 },
}
local enemyTeam2 = {
	{ x = 255, y = 91 },
	{ x = 2671, y = 7 },
	{ x = 2929, y = 244 },
	{ x = 1946, y = 221 },
	{ x = 3849, y = 1067 },
	{ x = 3360, y = 659 },
	{ x = 3885, y = 285 },
	{ x = 935, y = 1160 },
}

assignNamesAndHats(enemyTeam1)
assignNamesAndHats(enemyTeam2)

RopeKnocking({
	missionName = loc("Rope-knocking Challenge"),
	map = "Ropes",
	theme = "Eyes",
	turnTime = 180000,
	valkyries = true,
	playerTeam = {
		x = 2419,
		y = 1769,
		faceLeft = true,
	},
	enemyTeams = {
		{
			name = loc("Unsuspecting Louts"),
			flag = "cm_face",
			hogs = enemyTeam1,
		},
		{
			name = loc("Unlucky Sods"),
			flag = "cm_balrog",
			hogs = enemyTeam2,
		},
	},
	onGameStart = function()
		PlaceGirder(46,1783, 0)
	end,
})


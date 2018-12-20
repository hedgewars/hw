HedgewarsScriptLoad("/Scripts/SimpleMission.lua")
HedgewarsScriptLoad("/Scripts/Locale.lua")

local heroAmmo = {}
for a=0, amCreeper do
	if a == amExtraTime then
		heroAmmo[a] = 2
	elseif a ~= amNothing and a ~= amCreeper then
		heroAmmo[a] = 100
	end
end

SimpleMission({
	missionTitle = loc("Big Armory"),
	missionIcon = -amBazooka,
	wind = 15,
	initVars = {
		TurnTime = 45000,
		GameFlags = gfDisableWind + gfDisableLandObjects,
		Theme = "EarthRise",
		Map = "BigArmory", -- from sidecar HWP
		--[[ Map has been generated in Hedgewars 0.9.24 and
                     then exported as PNG with these settings:
		* Seed = "{7e34a56b-ee7b-4fe1-8f30-352a998f3f6a}"
		* MapGen = mgRandom
		* MapFeatureSize = 12
		* Theme = "EarthRise"
		* relevant GameFlag: gfDisableLandObjects ]]
	},
	teams = {
		{ isMissionTeam = true,
		clanID = 0,
		hogs = {
			{
			health = 100,
			x = 543, y = 1167,
			ammo = heroAmmo,
			}
		}, },

		{ name = loc("Galaxy Guardians"),
		clanID = 8,
		flag = "cm_galaxy",
		grave = "Earth",
		hogs = {
			{name=loc("Rocket"), x=796, y=1184, faceLeft=true},
			{name=loc("Star"), x=733, y=1525, faceLeft=true},
			{name=loc("Asteroid"), x=738, y=1855, faceLeft=true},
			{name=loc("Comet"), x=937, y=1318, faceLeft=true},
			{name=loc("Sunflame"), x=3424, y=1536},
			{name=loc("Eclipse"), x=3417, y=1081},
			{name=loc("Jetpack"), x=2256, y=1246},
			{name=loc("Void"), x=1587, y=1231, faceLeft=true},
		}, },
	},
	customNonGoals = {
		{ type = "turns", turns = 1, failText = loc("You failed to kill all enemies in a single turn.") }
	},
	customGoalCheck = "turnEnd",
	goalText = loc("Kill all enemy hedgehogs in a single turn."),
})

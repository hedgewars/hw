HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------


-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	GameFlags = gfInfAttack + gfSolidLand + gfDisableWind 
	TurnTime = 100000 
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 3000
	Explosives = 0
	Delay = 10 
	Map = "moon01_map"
	Theme = "Cheese"
end

function onGameStart()

end

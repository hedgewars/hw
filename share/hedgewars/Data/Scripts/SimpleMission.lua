--[=[
= Simple Mission Framework for Hedgewars =

This is a simple library intended to make setting up simple missions an
easy task for Lua scripters. The entire game logic and coding is
abtracted away in a single function which you just need to feed
a large definition table in which you define gears, goals, etc.

This is ideal for missions in which you set up the entire scenario
from the start and don't need any complex in-mission events.
BUT! This is NOT suited for missions with scripted events, cut-scenes,
branching story, etc.

This library has the following features:
* Add teams, clans, hogs
* Spawn gears
* Sensible defaults for almost everything
* Set custom goals or use the default one (kill all enemies)
* Add non-goals to fail the mission
* Checks victory and failure automatically

To use this library, you first have to load it and to call SimpleMission once with
the appropriate parameters.
See the comment of SimpleMission for a specification of all parameters.

]=]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

--[[
SimpleMission(params)

This function sets up the *entire* mission and needs one argument: params.
The argument “params” is a table containing fields which describe the mission.

	Mandatory fields:
	- teams:		Table of teams. There must be 1-8 teams.

	Optional fields
	- ammoConfig		Table containing basic ammo values (default: infinite skip only)
	- initVars		Table where you set up environment parameters such as MinesNum.
	- wind			If set, the wind will permanently set to this value (-100..100). Implies gfDisableWind
	- gears:		Table of objects.
	- girders		Table of girders
	- rubbers		Table of rubbers

	AMMO
	- ammoType		ammo type
	- delay			delay (default: 0)
	- numberInCrate		ammo per crate (default: 1)
	- count			default starter ammo for everyone, 9 for infinite (default: 0)
	- probability		probability in crates (default: 0)

	TEAM DATA
	- hogs			table of hedgehogs in this team (must contain at least 1 hog)
	- name			team name
	- clanID		ID of the clan to which this team belongs to. Counting starts at 0.
				By default, each team goes into its own clan.
				Important: The clan of the player and allies MUST be 0.
				Important: You MUST either set the clan ID explicitly for all teams or none of them.
	- flag			flag name (default: hedgewars)
	- grave			grave name (has default grave for each team)
	- fort			fort name (default: Castle)

	HEDGEHOG DATA:
	- id			optional identifier for goals
	- name			hog name
	- x, y			hog position (default: spawns randomly on land)
	- botLevel		1-5: Bot level (lower=stronger). 0=human player (default: 0)
	- hat			hat name (default: NoHat)
	- health		hog health (default: 100)
	- poisoned		if true, hedgehog starts poisoned with 5 poison damage. Set to a number for other poison damage (default: false)
	- frozen		if true, hedgehogs starts frozen (default: false)
	- faceLeft		initial facing direction. true=left, false=false (default: false)
	- ammo			table of ammo types

	GEAR TYPES:
	- type			gear type
	ALL types:
		id		optional identifier for goals
		x		x coordinate of starting position (default: 0)
		y		y coordinate of starting position (default: 0)
		dx		initial x speed (default: 0)
		dy		initial y speed (default: 0)
	- type=gtMine		Mine
		timer 		Mine timer (only for non-duds). Default: MinesTime
		isDud		Whether the mine is a dud. default: false
		isFrozen	Whether the mine is frozen. If true, it implies being a dud as well. Default: false
		health 		Initial health of dud mines. Has no effect if isDud=false. Default: 36
	- type=gtSMine		Sticky mine
		timer		Timer. Default: 500
	- type=gtAirMine	Air mine
		timer		Timer. Default: (MinesTime/1000 * 250)
	- type=gtExplosives	Barrel
		health		Initial health. Default: 60
		isFrozen	Whether the barrel is frozen. Default: true with health > 60, false otherwise
		isRolling	Whether the barrel starts in “rolling” state. Default: false
	- type=gtCase		Crate
		crateType	"health": Health crate
				"supply": Ammo or utility crate (select crate type automatically)
				"supply_ammo_explicit": Ammo crate (not recommened)
				"supply_utility_explicit": Utility crate (not recommededn)
		ammoType	Contained ammo (only for ammo and utility crates).
		health		Contained health (only for health crates). Default: HealthCaseAmount
		isFrozen	Whether the crate is frozen. Default: false
	- type=gtKnife		Cleaver
	- type=gtTarget		Target

	GOALS:
	Note: If there are at least two opposing teams, a default goal is used, which is to defeat all the enemies of the
	player's team. If this is what you want, you can skip this section.

	The default goal is overwritten as if customGoals has been set. Set customGoals and other related parameters for
	defining your own special goals. In this case, the mission is won if all customGoals are completed.
	Note the mission will always fail if the player's hedgehogs and all their allies have been defeated.
	If there is only one team (for the player), there is no default goal and one must be set explicitly.
	- customGoals		Table of custom goals (see below). All of them must be met to win. Some goal types might fail,
				rendering the mission unwinnable and leading to the loss of the mission. An example is
				blowing up a crate which you should have collected.ed.
	- customNonGoals	Table of non-goals, the player loses if one of them is achieved
	- customGoalCheck	When to check goals and non-goals. Values: "instant" (default), "turnStart", "turnEnd"

	- missionTitle:		The name of the mission (highly recommended)
	- missionIcon:		Icon of the mission panel, see documentation of ShowMission in the Lua API
	- goalText:		A short string explaining the goal of the mission (use this if you set custom goals).

	GOAL TYPES:
	- type			name of goal type
	- failText		Optional. For non-goals, this text will be shown in the stats if mission fails due to this non-goal
				being completed. For goals which fail, this text will be displayed at failure. Note that
				all normal goals have sensible default fail texts.
	- type="destroy"	Gear must be destroyed
		- id		Gear to destroy
	- type="teamDefeat"	Team must be defeated
		- teamName	Name of team to defeat
	- type="collect"	Crate must be collected
		FAIL CONDITION:	Crate taken by enemy, or destroyed
		- id		ID of crate gear to collect
		- collectors	Optional table of gear IDs, any one of which must collect the gear (but nobody else!).
				By default, this is for the player's teams and allies.
	- type="turns"		Achieved when a number of turns has been played
		- turns 	Number of played turns 
	- type="rounds"		Achieved when a number of rounds has been played
		- rounds	Number of played rounds
	- type="suddenDeath"	Sudden Death has started
	- type="inZone"		A gear is within given coordinate bounds. Each of xMin, xMax, yMin and yMax is a sub-goal.
				Each sub-goal is only checked if not nil.
				You can use this to check if a gear left, right, above or below a given coordinate.
				To check if the gear is within a rectangle, just set all 4 sub-goals.
		FAIL CONDITION:	Gear destroyed
		- id		Gear to watch
		- xMin		gear's X coordinate must be lower than this
		- xMax		gear's X coordinate must be higher than this
		- yMin		gear's Y coordinate must be lower than this
		- yMax		gear's Y coordinate must be higher than this
	- type="distGearPos"	Distance between a gear and a fixed position
		FAIL CONDITION:	Gear destroyed
		- distance	goal distance to compare to
		- relationship	"greaterThan" or "lowerThan"
		- id		gear to watch
		- x		x coordinate to reach
		- y		y coordinate to reach
	- type="distGearGear"	Distance between two gears
		FAIL CONDITION:	Any of both gears destroyed
		- distance	goal distance to compare to
		- relationship	"greaterThan" or "lowerThan"
		- id1		first gear to compare
		- id2		second gear to compare
	- type="damage"		Gear took damage or was destroyed
		- id		Gear to watch
		- damage	Minimum amount of damage to take at a single blow. Default: 1
		- canDestroy	If false, this goal will fail if the gear was destroyed without taking the required damage
	- type="drown"		Gear has drowned
		FAIL CONDITION:	Gear destroyed by other means
		- id		Gear to watch
	- type="poison"		Gear must be poisoned
		FAIL CONDITION:	Gear destroyed
		- id		Gear to be poisoned
	- type="cure"		Gear must exist and be free from poisoning
		FAIL CONDITION:	Gear destroyed
		- id		Gear to check
	- type="freeze"		Gear must exist and be frozen
		FAIL CONDITION:	Gear destroyed
		- id		Gear to be frozen
	- type="melt"		Gear must exist and be unfrozen
		FAIL CONDITION:	Gear destroyed
		- id		Gear to check
	- type="waterSkip"	Gear must have skipped over water
		FAIL CONDITION:	Gear destroyed before it reached the required number of skips
		- id
		- skips		Total number of water skips required at least (default: 1)

]]

local goals
local teamHogs = {}

--[[
	HELPER VARIABLES
]]

local defaultGraves = {
	"Grave", "Statue", "pyramid", "Simple", "skull", "Badger", "Duck2", "Flower"
}
local defaultFlags = {
	"hedgewars", "cm_birdy", "cm_eyes", "cm_spider", "cm_kiwi", "cm_scout", "cm_skull", "cm_bars"
}

-- Utility functions

-- Returns value if it is non-nil, otherwise returns default
local function def(value, default)
	if value == nil then
		return default
	else
		return value
	end
end

-- Get hypotenuse of a triangle with legs x and y
local function hypot(x, y)
	local t
	x = math.abs(x)
	y = math.abs(y)
	t = math.min(x, y)
	x = math.max(x, y)
	if x == 0 then
		return 0
	end
	t = t / x
	return x * math.sqrt(1 + t * t)
end

local errord = false

-- This function generates the mission. See above for the meaning of params.
function SimpleMission(params)
	if params.missionTitle == nil then
		params.missionTitle = loc("Scenario")
	end
	if params.missionIcon == nil then
		params.missionIcon = 1 -- target icon
	end
	if params.goalText == nil then
		params.goalText = loc("Eliminate the enemy.")
	end
	if params.customGoalCheck == nil and (params.customGoals ~= nil or params.customNonGoals ~= nil) then
		params.customGoalCheck = "instant"
	end

	_G.sm = {}

	_G.sm.isInSuddenDeath = false

	-- Number of completed turns
	_G.sm.gameTurns = 0

	_G.sm.goalGears = {}

	_G.sm.params = params

	_G.sm.gameEnded = false

	_G.sm.playerClan = 0

	_G.sm.makeStats = function(winningClan, customAchievements)
		for t=0, TeamsCount-1 do
			local team = GetTeamName(t)
			local stats = GetTeamStats(team)
			local clan = GetTeamClan(team)
			if clan == winningClan then
				SendStat(siPlayerKills, stats.Kills, team)
			end
		end
		for t=0, TeamsCount-1 do
			local team = GetTeamName(t)
			local stats = GetTeamStats(team)
			local clan = GetTeamClan(team)
			if clan ~= winningClan then
				SendStat(siPlayerKills, stats.Kills, team)
			end
		end
		if customAchievements ~= nil then
			for a=1, #customAchievements do
				SendStat(siCustomAchievement, customAchievements[a])
			end
		end
	end

	_G.sm.criticalGearFailText = function(gearSmid)
		local gear = _G.sm.goalGears[gearSmid]
		if GetGearType(gear) == gtHedgehog then
			return string.format(loc("%s is dead, who was critical to this mission!"), GetHogName(gear))
		else
			return loc("We have lost an object which was critical to this mission.")
		end
	end

	_G.sm.checkGoal = function(goal)
		if goal.type == "destroy" then
			return getGearValue(_G.sm.goalGears[goal.id], "sm_destroyed")
		elseif goal.type == "collect" then
			local collector = getGearValue(_G.sm.goalGears[goal.id], "sm_collected")
			if collector then
				if not goal.collectors then
					if GetHogClan(collector) == _G.sm.playerClan then
						return true
					else
						-- Fail if the crate was collected by enemy
						return "fail", loc("The enemy has taken a crate which we really needed!")
					end
				else
					for c=1, #goal.collectors do
						if _G.sm.goalGears[goal.collectors[c]] == collector then
							return true
						end
					end
					-- Fail if the crate was collected by someone who was not supposed to get it
					return "fail", loc("The wrong hedgehog has taken the crate.")
				end
			else
				-- Fail goal if crate was destroyed
				if getGearValue(_G.sm.goalGears[goal.id], "sm_destroyed") then
					return "fail", loc("A crate critical to this mission has been destroyed.")
				end
				return false
			end
		elseif goal.type == "turns" then
			return sm.gameTurns >= goal.turns
		elseif goal.type == "rounds" then
			return (TotalRounds) >= goal.rounds
		elseif goal.type == "inZone" then
			if getGearValue(_G.sm.goalGears[goal.id], "sm_destroyed") then
				return "fail", criticalGearFailText(goal.id)
			end
			local gX, gY = GetGearPosition(_G.sm.goalGears[goal.id])
			-- 4 sub-goals, each optional
			local g1 = (not goal.xMin) or gX >= goal.xMin
			local g2 = (not goal.xMax) or gX <= goal.xMax
			local g3 = (not goal.yMin) or gY >= goal.yMin
			local g4 = (not goal.yMax) or gY <= goal.yMax
			return g1 and g2 and g3 and g4
		elseif goal.type == "distGearPos" or goal.type == "distGearGear" then
			local gX, tY, tX, tY
			if goal.type == "distGearPos" then
				if getGearValue(_G.sm.goalGears[goal.id], "sm_destroyed") then
					-- Fail if gear was destroyed
					return "fail", criticalGearFailText(goal.id)
				end
				gX, gY = GetGearPosition(_G.sm.goalGears[goal.id])
				tX, tY = goal.x, goal.y
			elseif goal.type == "distGearGear" then
				-- Fail if one of the gears was destroyed
				if getGearValue(_G.sm.goalGears[goal.id1], "sm_destroyed") then
					return "fail", criticalGearFailText(goal.id1)
				elseif getGearValue(_G.sm.goalGears[goal.id2], "sm_destroyed") then
					return "fail", criticalGearFailText(goal.id2)
				end
				gX, gY = GetGearPosition(_G.sm.goalGears[goal.id1])
				tX, tY = GetGearPosition(_G.sm.goalGears[goal.id2])
			end

			local h = hypot(gX - tX, gY - tY)
			if goal.relationship == "smallerThan" then
				return h < goal.distance
			elseif goal.relationship == "greaterThan" then
				return h > goal.distance
			end
			-- Invalid parameters!
			error("SimpleMission: Invalid parameters for distGearPos/distGearGear!")
			errord = true
			return false
		elseif goal.type == "suddenDeath" then
			return sm.isInSuddenDeath
		elseif goal.type == "damage" then
			local damage = goal.damage or 1
			local gear = _G.sm.goalGears[goal.id]
			local tookEnoughDamage = getGearValue(gear, "sm_maxDamage") >= damage
			if getGearValue(gear, "sm_destroyed") then
				-- Fail if gear was destroyed without taking enough damage first
				if not tookEnoughDamage and goal.canDestroy == false then
					if GetGearType(gear) == gtHedgehog then
						return "fail", string.format(loc("%s has been killed before taking enough damage first."), GetHogName(gear))
					else
						return "fail", loc("An object has been destroyed before it took enough damage.")
					end
				else
				-- By default, succeed if gear was destroyed
					return true
				end
			end
			return tookEnoughDamage
		elseif goal.type == "drown" then
			local drowned = getGearValue(_G.sm.goalGears[goal.id], "sm_drowned")
			-- Fail if gear was destroyed by something other than drowning
			if not drowned and getGearValue(_G.sm.goalGears[goal.id], "sm_destroyed") then
				return "fail", criticalGearFailText(goal.id)
			end
			return drowned
		elseif goal.type == "poison" then
			if getGearValue(_G.sm.goalGears[goal.id], "sm_destroyed") then
				return "fail", criticalGearFailText(goal.id)
			end
			return GetEffect(_G.sm.goalGears[goal.id], hePoisoned) >= 1
		elseif goal.type == "freeze" then
			if getGearValue(_G.sm.goalGears[goal.id], "sm_destroyed") then
				return "fail", criticalGearFailText(goal.id)
			end
			return GetEffect(_G.sm.goalGears[goal.id], heFrozen) >= 256
		elseif goal.type == "cure" then
			if getGearValue(_G.sm.goalGears[goal.id], "sm_destroyed") then
				return "fail", criticalGearFailText(goal.id)
			end
			return GetEffect(_G.sm.goalGears[goal.id], hePoisoned) == 0
		elseif goal.type == "melt" then
			if getGearValue(_G.sm.goalGears[goal.id], "sm_destroyed") then
				return "fail", criticalGearFailText(goal.id)
			end
			return GetEffect(_G.sm.goalGears[goal.id], heFrozen) == 0
		elseif goal.type == "waterSkip" then
			local skips = goal.skips or 1
			local hasEnoughSkips = getGearValue(_G.sm.goalGears[goal.id], "sm_waterSkips") >= skips
			-- Fail if gear was destroyed before it got the required number of skips
			if not hasEnoughSkips and getGearValue(_G.sm.goalGears[goal.id], "sm_destroyed") then
				return "fail", criticalGearFailText(goal.id)
			end
			return hasEnoughSkips
		elseif goal.type == "teamDefeat" then
			return #teamHogs[goal.teamName] == 0
		else
			return false
		end
	end

	--[[ Checks the custom goals.
	Returns true when all custom goals are met.
	Returns false when not all custom goals are met.
	Returns "fail" if any of the goals has failed (i.e. is impossible to complete).
	Returns nil when there are no custom goals ]]
	_G.sm.checkGoals = function()
		if params.customGoals ~= nil and #params.customGoals > 0 then
			for key, goal in pairs(params.customGoals) do
				local done, defaultFailText = _G.sm.checkGoal(goal)
				if done == false or done == "fail" then
					local failText
					if goal.failText then
						failText = goal.failText
					else
						failText = customFailText
					end
					return done, failText
				end
			end
			return true
		else
			return nil
		end
	end

	--[[ Checks the custom non-goals.
	Returns true when any non-goal is met.
	Returns false otherwise. ]]
	_G.sm.checkNonGoals = function()
		if params.customNonGoals ~= nil and #params.customNonGoals > 0 then
			for key, nonGoal in pairs(params.customNonGoals) do
				local done = _G.sm.checkGoal(nonGoal)
				if done == true then
					return true, nonGoal.failText
				end
			end
		end
		return false
	end

	-- Declare the game ended if all enemy teams are dead and player teams or allies are still alive
	_G.sm.checkRegularVictory = function()
		local victory = true
		for t=0, TeamsCount-1 do
			local team = GetTeamName(t)
			local defeat = _G.sm.checkGoal({type="teamDefeat", teamName=team})
			if not defeat then
				-- Deep check, also look at damage of all hogs
				local dead = 0
				for h=1, #teamHogs[team] do
					local _,_,_,_,_,_,_,_,_,_,_,Damage = GetGearValues(teamHogs[team][h])
					if Damage >= GetHealth(teamHogs[team][h]) then
						dead = dead + 1
					end
				end
				if dead >= #teamHogs[team] then
					defeat = true
				end
			end
			if (defeat == true) and (GetTeamClan(team) == _G.sm.playerClan) then
				victory = false
				break
			elseif (defeat == false) and (GetTeamClan(team) ~= _G.sm.playerClan) then
				victory = false
				break
			end
		end
		if victory then
			_G.sm.gameEnded = true
		end
	end

	-- Checks goals and non goals and wins or loses mission
	_G.sm.checkWinOrFail = function()
		if errord then
			return
		end
		local nonGoalStatus, nonGoalFailText = _G.sm.checkNonGoals()
		local goalStatus, goalFailText = _G.sm.checkGoals()
		if nonGoalStatus == true then
			_G.sm.lose(nonGoalFailText)
		elseif goalStatus == "fail" then
			_G.sm.lose(goalText)
		elseif goalStatus == true then
			_G.sm.win()
		end
	end

	_G.sm.win = function()
		if not _G.sm.gameEnded then
			_G.sm.gameEnded = true
			AddCaption(loc("Victory!"), 0xFFFFFFFF, capgrpGameState)
			SendStat(siGameResult, loc("You win!"))
			if GetHogLevel(CurrentHedgehog) == 0 then
				SetState(CurrentHedgehog, bor(GetState(CurrentHedgehog), gstWinner))
				SetState(CurrentHedgehog, band(GetState(CurrentHedgehog), bnot(gstHHDriven)))
				PlaySound(sndVictory, CurrentHedgehog)
			end
			_G.sm.makeStats(_G.sm.playerClan)
			EndGame()
		end
	end

	_G.sm.lose = function(failReason)
		if not _G.sm.gameEnded then
			_G.sm.gameEnded = true
			AddCaption(loc("Scenario failed!"), 0xFFFFFFFF, capgrpGameState)
			SendStat(siGameResult, loc("You lose!"))
			if failReason then
				SendStat(siCustomAchievement, failReason)
			end
			if GetHogLevel(CurrentHedgehog) == 0 then
				SetState(CurrentHedgehog, bor(GetState(CurrentHedgehog), gstLoser))
				SetState(CurrentHedgehog, band(GetState(CurrentHedgehog), bnot(gstHHDriven)))
			end
			local clan = ClansCount-1
			for t=0, TeamsCount-1 do
				local team = GetTeamName(t)
				-- Just declare any living team other than the player team the winner
				if (_G.sm.checkGoal({type="teamDefeat", teamName=team}) == false) and (GetTeamClan(team) ~= _G.sm.playerClan) then
					clan = GetTeamClan(team)
					break
				end
			end
			_G.sm.makeStats(clan)
			EndGame()
		end
	end

	_G.onSuddenDeath = function()
		sm.isInSuddenDeath = true
	end

	_G.onGearWaterSkip = function(gear)
		increaseGearValue(gear, "sm_waterSkips")
	end

	_G.onGearAdd = function(gear)
		if GetGearType(gear) == gtHedgehog then
			local team = GetHogTeamName(gear)
			if teamHogs[team] == nil then
				teamHogs[team] = {}
			end
			table.insert(teamHogs[GetHogTeamName(gear)], gear)
		end
		setGearValue(gear, "sm_waterSkips", 0)
		setGearValue(gear, "sm_maxDamage", 0)
		setGearValue(gear, "sm_drowned", false)
		setGearValue(gear, "sm_destroyed", false)
	end

	_G.onGearResurrect = function(gear)
		if GetGearType(gear) == gtHedgehog then
			table.insert(teamHogs[GetHogTeamName(gear)], gear)
		end
		setGearValue(gear, "sm_destroyed", false)
	end

	_G.onGearDelete = function(gear)
		if GetGearType(gear) == gtCase and band(GetGearMessage(gear), gmDestroy) ~= 0 then
			-- Set ID of collector
			setGearValue(gear, "sm_collected", CurrentHedgehog)
		end
		if GetGearType(gear) == gtHedgehog then
			local team = GetHogTeamName(gear)
			local hogList = teamHogs[team]
			for h=1, #hogList do
				if hogList[h] == gear then
					table.remove(hogList, h)
					break
				end
			end
		end
		if band(GetState(gear), gstDrowning) ~= 0 then
			setGearValue(gear, "sm_drowned", true)
		end
		setGearValue(gear, "sm_destroyed", true)
	end

	_G.onGearDamage = function(gear, damage)
		local currentDamage = getGearValue(gear, "sm_maxDamage")
		if damage > currentDamage then
			setGearValue(gear, "sm_maxDamage", damage)
		end
	end

	_G.onGameInit = function()
		CaseFreq = 0
		WaterRise = 0
		HealthDecrease = 0
		MinesNum = 0
		Explosives = 0

		for initVarName, initVarValue in pairs(params.initVars) do
			if initVarName == "GameFlags" then
				EnableGameFlags(initVarValue)
			else
				_G[initVarName] = initVarValue
			end
		end
		if #params.teams == 1 then
			EnableGameFlags(gfOneClanMode)
		end
		if params.wind then
			EnableGameFlags(gfDisableWind)
		end

		local clanCounter = 0
		for teamID, teamData in pairs(params.teams) do
			local name, clanID, grave, fort, voice, flag
			name = def(teamData.name, string.format(loc("Team %d"), teamID))
			if teamData.clanID == nil then
				clanID = clanCounter
				clanCounter = clanCounter + 1
			else
				clanID = teamData.clanID
			end
			grave = def(teamData.grave, defaultGraves[math.min(teamID, 8)])
			fort = def(teamData.fort, "Castle")
			voice = def(teamData.voice, "Default")
			flag = def(teamData.flag, defaultFlags[math.min(teamID, 8)])

			AddTeam(name, -(clanID+1), grave, fort, voice, flag)

			for hogID, hogData in pairs(teamData.hogs) do
				local name, botLevel, health, hat
				name = def(hogData.name, string.format(loc("Hog %d"), hogID))
				botLevel = def(hogData.botLevel, 0)
				health = def(hogData.health, 100)
				hat = def(hogData.hat, "NoHat")
				local hog = AddHog(name, botLevel, health, hat)
				if hogData.x ~= nil and hogData.y ~= nil then
					SetGearPosition(hog, hogData.x, hogData.y)
				end
				if hogData.faceLeft then
					HogTurnLeft(hog, true)
				end
				if hogData.poisoned == true then
					SetEffect(hog, hePoisoned, 5)
				elseif type(hogData.poisoned) == "number" then
					SetEffect(hog, hePoisoned, hogData.poisoned)
				end
				if hogData.frozen then
					SetEffect(hog, heFrozen, 199999)
				end

				if hog ~= nil and hogData.id ~= nil then
					_G.sm.goalGears[hogData.id] = hog
					setGearValue(hog, "sm_id", hogData.id)
				end

				-- Remember this hedgehog's gear ID for later use
				hogData.gearID = hog
			end
		end
	end

	_G.onNewTurn = function()
		_G.sm.gameStarted = true

		if params.customGoalCheck == "turnStart" then
			_G.sm.checkRegularVictory()
			_G.sm.checkWinOrFail()
		end
	end

	_G.onEndTurn = function()
		_G.sm.gameTurns = _G.sm.gameTurns + 1

		if params.customGoalCheck == "turnEnd" then
			_G.sm.checkRegularVictory()
			_G.sm.checkWinOrFail()
		end
	end

	_G.onAmmoStoreInit = function()
		local ammoTypesDone = {}
		-- Read script's stated ammo wishes
		if params.ammoConfig ~= nil then
			for ammoType, v in pairs(params.ammoConfig) do
				SetAmmo(ammoType, def(v.count, 0), def(v.probability, 0), def(v.delay, 0), def(v.numberInCrate, 1))
				ammoTypesDone[ammoType] = true
			end
		end
		-- Apply default values for all ammo types which have not been set
		for a=0, AmmoTypeMax do
			if a ~= amNothing and ammoTypesDone[a] ~= true then
				local count = 0
				if a == amSkip then
					count = 9
				end
				SetAmmo(a, count, 0, 0, 1)
			end
		end
	end

	_G.onGameStart = function()
		-- Mention mines timer
		if MinesTime ~= 3000 and MinesTime ~= nil then 
			if MinesTime < 0 then
				params.goalText = params.goalText .. "|" .. loc("Mines time: 0s-5s")
			elseif (MinesTime % 1000) == 0 then
				params.goalText = params.goalText .. "|" .. string.format(loc("Mines time: %ds"), MinesTime/1000)
			elseif (MinesTime % 100) == 0 then
				params.goalText = params.goalText .. "|" .. string.format(loc("Mines time: %.1fs"), MinesTime/1000)
			else
				params.goalText = params.goalText .. "|" .. string.format(loc("Mines time: %.2fs"), MinesTime/1000)
			end
		end
		if params.wind then
			SetWind(params.wind)
		end
		ShowMission(params.missionTitle, loc("Scenario"), params.goalText, params.missionIcon, 5000) 

		-- Spawn objects

		if params.gears ~= nil then
			for listGearID, gv in pairs(params.gears) do
				local timer, state, x, y, dx, dy
				local g
				state = 0
				if gv.type == gtMine then
					if gv.isFrozen then
						state = gstFrozen
					end
					g = AddGear(def(gv.x,0), def(gv.y,0), gv.type, state, def(gv.dx, 0), def(gv.dy, 0), def(gv.timer, MinesTime))
					if gv.isDud then
						SetHealth(g, 0)
						if gv.health ~= nil then
							SetGearValues(g, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, 36 - gv.health)
						end
					end
				elseif gv.type == gtSMine then
					g = AddGear(def(gv.x,0), def(gv.y,0), gv.type, 0, def(gv.dx,0), def(gv.dy,0), def(gv.timer, 500))
				elseif gv.type == gtAirMine then
					if gv.isFrozen then
						state = gstFrozen
					end
					local timer = def(gv.timer, div(MinesTime, 1000) * 250)
					g = AddGear(def(gv.x,0), def(gv.y,0), gv.type, state, def(gv.dx,0), def(gv.dy,0), timer)
					SetGearValues(g, nil, nil, timer) -- WDTimer
				elseif gv.type == gtExplosives then
					if gv.isRolling then
						state = gsttmpFlag
					end
					g = AddGear(def(gv.x,0), def(gv.y,0), gv.type, state, def(gv.dx,0), def(gv.dy,0), 0)
					if gv.health then
						SetHealth(g, gv.health)
					end
					if gv.isFrozen ~= nil then
						if gv.isFrozen == true then
							SetState(g, bor(GetState(g, gstFrozen)))
						end
					elseif GetHealth(g) > 60 then
						SetState(g, bor(GetState(g, gstFrozen)))
					end
				elseif gv.type == gtCase then
					local x, y, spawnTrick
					spawnTrick = false
					x = def(gv.x, 0)
					y = def(gv.y, 0)
					if x==0 and y==0 then
						x=1
						y=1
						spawnTrick = true
					end
					g = AddGear(x, y, gv.type, 0, def(gv.dx,0), def(gv.dy,0), 0)
					if spawnTrick then
						SetGearPosition(g, 0, 0)
					end
					if gv.crateType == "supply" then
						g = SpawnSupplyCrate(def(gv.x, 0), def(gv.y, 0), gv.ammoType)
					elseif gv.crateType == "supply_ammo_explicit" then
						g = SpawnAmmoCrate(def(gv.x, 0), def(gv.y, 0), gv.ammoType)
					elseif gv.crateType == "supply_utility_explicit" then
						g = SpawnUtilityCrate(def(gv.x, 0), def(gv.y, 0), gv.ammoType)
					elseif gv.crateType == "health" then
						g = SpawnHealthCrate(def(gv.x, 0), def(gv.y, 0))
						if gv.health ~= nil then
							SetHealth(g, gv.health)
						end
					end
					if gv.isFrozen then
						SetState(g, bor(GetState(g, gstFrozen)))
					end
				elseif gv.type == gtKnife or gv.type == gtTarget then
					g = AddGear(def(gv.x,0), def(gv.y,0), gv.type, 0, def(gv.dx,0), def(gv.dy,0), 0)
				end
				if g ~= nil and gv.id ~= nil then
					_G.sm.goalGears[gv.id] = g
					setGearValue(g, "sm_id", gv.id)
				end
			end
		end

		-- Spawn girders and rubbers
		if params.girders ~= nil then
			for i, girderData in pairs(params.girders) do
				PlaceGirder(girderData.x, girderData.y, girderData.frameIdx)
			end
		end
		if params.rubbers ~= nil then
			for i, rubberData in pairs(params.rubbers) do
				PlaceSprite(rubberData.x, rubberData.y, sprAmRubber, 0xFFFFFFFF, rubberData.frameIdx, false, false, false, lfBouncy)
			end
		end

		-- Per-hedgehog ammo loadouts
		for teamID, teamData in pairs(params.teams) do
			for hogID, hogData in pairs(teamData.hogs) do
				if hogData.ammo ~= nil then
					for ammoType, count in pairs(hogData.ammo) do
						AddAmmo(hogData.gearID, ammoType, count)
					end
				end
			end
		end
	end

	_G.onGameTick20 = function()
		if params.customGoalCheck == "instant" then
			_G.sm.checkWinOrFail()
		end
	end

end


------------------- ABOUT ----------------------
--
-- In the desert planet Hero will have to explore
-- the dunes below the surface and find the hidden
-- crates. It is told that one crate contains the
-- lost part.

-- TODO
-- maybe use same name in missionName and frontend mission name..
-- in this map I have to track the weapons the player has in checkpoints
-- GENRAL NOTE: change hats :D

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Animate.lua")

----------------- VARIABLES --------------------
-- globals
local campaignName = loc("A Space Adventure")
local missionName = loc("Desert planet, lost in sand!")
local checkPointReached = 1 -- 1 is normal spawn
-- dialogs
local dialog01 = {}
-- mission objectives
local goals = {
	[dialog01] = {missionName, loc("Getting ready"), loc("The part is hidden in one of the crates! Go and get it!"), 1, 4500},
}
-- crates
local btorch1Y = 60
local btorch1X = 2700
local btorch2Y = 1800
local btorch2X = 1010
local btorch3Y = 980
local btorch3X = 3260
local rope1Y = 970
local rope1X = 3200
local rope2Y = 1900
local rope2X = 680
local rope3Y = 1850
local rope3X = 2460
local portalY = 480
local portalX = 1465
local constructY = 1630
local constructX = 3350
-- hogs
local hero = {}
local ally = {}
local smuggler1 = {}
local smuggler2 = {}
local smuggler3 = {}
-- teams
local teamA = {}
local teamB = {}
local teamC = {}
-- hedgehogs values
hero.name = "Hog Solo"
hero.x = 1740
hero.y = 40
hero.dead = false
ally.name = "Chief Sandologist"
ally.x = 1660
ally.y = 40
smuggler1.name = "Sanndy"
smuggler1.x = 320
smuggler1.y = 235
smuggler2.name = "Spike"
smuggler2.x = 736
smuggler2.y = 860
smuggler3.name = "Sandstorm"
smuggler3.x = 1940
smuggler3.y = 1625
teamA.name = loc("PAotH")
teamA.color = tonumber("FF0000",16) -- red
teamB.name = loc("Smugglers")
teamB.color = tonumber("0033FF",16) -- blues
teamC.name = loc("Hog Solo")
teamC.color = tonumber("38D61C",16) -- green

-------------- LuaAPI EVENT HANDLERS ------------------

function onGameInit()
	Seed = 1
	TurnTime = 25000
	CaseFreq = 0
	MinesNum = 0
	MinesTime = 1
	Explosives = 0
	Delay = 3
	HealthCaseAmount = 30
	Map = "desert01_map"
	Theme = "Desert"
	
	-- Hog Solo
	AddTeam(teamC.name, teamC.color, "Bone", "Island", "HillBilly", "cm_birdy")
	hero.gear = AddHog(hero.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(hero.gear, hero.x, hero.y)
	HogTurnLeft(hero.gear, true)
	-- PAotH undercover scientist and chief Sandologist
	AddTeam(teamA.name, teamA.color, "Bone", "Island", "HillBilly", "cm_birdy")
	ally.gear = AddHog(ally.name, 0, 100, "war_desertgrenadier1")
	AnimSetGearPosition(ally.gear, ally.x, ally.y)
	-- Smugglers
	AddTeam(teamB.name, teamB.color, "Bone", "Island", "HillBilly", "cm_birdy")
	smuggler1.gear = AddHog(smuggler1.name, 1, 120, "tophats")
	AnimSetGearPosition(smuggler1.gear, smuggler1.x, smuggler1.y)
	smuggler2.gear = AddHog(smuggler2.name, 1, 120, "tophats")
	AnimSetGearPosition(smuggler2.gear, smuggler2.x, smuggler2.y)	
	smuggler3.gear = AddHog(smuggler3.name, 1, 120, "tophats")
	AnimSetGearPosition(smuggler3.gear, smuggler3.x, smuggler3.y)	
	
	AnimInit()
	AnimationSetup()	
end

function onGameStart()
	AnimWait(hero.gear, 3000)
	FollowGear(hero.gear)
	
	AddAmmo(hero.gear, amRope, 10)
	
	-- spawn crates	
	SpawnAmmoCrate(btorch1X, btorch1Y, amBlowTorch)
	SpawnAmmoCrate(btorch2X, btorch2Y, amBlowTorch)
	SpawnAmmoCrate(btorch3X, btorch3Y, amBlowTorch)
	SpawnAmmoCrate(rope1X, rope1Y, amRope)
	SpawnAmmoCrate(rope2X, rope2Y, amRope)
	SpawnAmmoCrate(rope3X, rope3Y, amRope)
	SpawnAmmoCrate(portalX, portalY, amPortalGun)
	SpawnAmmoCrate(constructX, constructY, amConstruction)
	
	SpawnHealthCrate(3300, 970)
	SpawnHealthCrate(480, 460)
	
	-- adding mines - BOOM!
	AddGear(1280, 460, gtMine, 0, 0, 0, 0)
	AddGear(270, 460, gtMine, 0, 0, 0, 0)
	AddGear(3460, 60, gtMine, 0, 0, 0, 0)
	AddGear(3500, 240, gtMine, 0, 0, 0, 0)
	AddGear(3410, 670, gtMine, 0, 0, 0, 0)
	AddGear(3450, 720, gtMine, 0, 0, 0, 0)
	
	local x = 800
	while x < 1650 do
		AddGear(x, 900, gtMine, 0, 0, 0, 0)
		x = x + math.random(8,20)
	end
	x = 1890
	while x < 2988 do
		AddGear(x, 760, gtMine, 0, 0, 0, 0)
		x = x + math.random(8,20)
	end
	x = 2480
	while x < 3300 do
		AddGear(x, 1450, gtMine, 0, 0, 0, 0)
		x = x + math.random(8,20)
	end
	x = 1570
	while x < 2900 do
		AddGear(x, 470, gtMine, 0, 0, 0, 0)
		x = x + math.random(8,20)
	end
	
	AddAnim(dialog01)
end

function onGameTick()
	AnimUnWait()
	if ShowAnimation() == false then
		return
	end
	ExecuteAfterAnimations()
	CheckEvents()
end

function onAmmoStoreInit()
	SetAmmo(amBlowTorch, 0, 0, 0, 1)
	SetAmmo(amRope, 0, 0, 0, 1)
	SetAmmo(amPortalGun, 0, 0, 0, 1)	
	SetAmmo(amConstruction, 0, 0, 0, 1)
end

function onGearDelete(gear)
	if gear == hero.gear then
		hero.dead = true
	end
end

function onPrecise()
	if GameTime > 3000 then
		SetAnimSkip(true)   
	end
end

-------------- ANIMATIONS ------------------

function Skipanim(anim)
	if goals[anim] ~= nil then
		ShowMission(unpack(goals[anim]))
    end
end

function AnimationSetup()
	-- DIALOG 01 - Start, getting info about the device
	AddSkipFunction(dialog01, Skipanim, {dialog01})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 3000}})
	table.insert(dialog01, {func = AnimCaption, args = {hero.gear, loc("In the planet of sand, you have to double check your moves..."), 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Finaly you are here..."), SAY_SAY, 2000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("Thank you for meeting me in such a short notice!"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {ally.gear, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("No problem, I would do anything for M!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Now listen carefully! Below us there are tunnels that have been created naturally over the years"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("I have heared the local tribes saying that many years ago some PAotH scientists were dumping their waste here"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("M confimed that there isn't such a PAotH activity logged"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("So, I believe that it's a good place to start"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Beware though! Many smugglers come often to explore these tunnels and scavage whatever valuable item they can find"), SAY_SAY, 5000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("They won't hesitate to attack you in order to take your valuables!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 6000}})
	table.insert(dialog01, {func = AnimSay, args = {hero.gear, loc("OK, I'll be extra careful!"), SAY_SAY, 4000}})
	table.insert(dialog01, {func = AnimWait, args = {ally.gear, 2000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("There is the tunnel entrance"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimSay, args = {ally.gear, loc("Good luck!"), SAY_SAY, 3000}})
	table.insert(dialog01, {func = AnimWait, args = {hero.gear, 500}})
	table.insert(dialog01, {func = AnimSwitchHog, args = {hero.gear}})
end

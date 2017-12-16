--[[ Stuck Cake Test

In this test, 2 hedgehogs are placed very close to each other, tightly
crammed between girders. The first hog (Cake Hog) launches a cake. Now
the test waits until the cake explodes due to time.

The cake must not take too long or forever to explode. The test succeeds
if the cake explodes before CAKE_MAX_EXPLOSION_TIME ticks (rough estimate)
after the cake spawned and fails otherwise.

This test case has been written in response to bug 194.

]]

-- Cake must explode before this many ticks for the test to succeed
local CAKE_MAX_EXPLOSION_TIME = 15000

-- Give up if cake is still running after this many ticks
local CAKE_GIVE_UP_TIME = 20000 

local hhs = {}

function onGameInit()

	ClearGameFlags()
	EnableGameFlags(gfDisableWind, gfPerHogAmmo, gfOneClanMode, gfInvulnerable, gfSolidLand)
	Map = ""
	Seed = "{84f5e62e-6a12-4444-b53c-2bc62cfd9c62}"
	Theme = "Cave"
	MapGen = mgDrawn
	MapFeatureSize = 12
	TemplateFilter = 3
	TemplateNumber = 0
	TurnTime = 9999000
	Explosives = 0
	MinesNum = 0
	CaseFreq = 0
	WaterRise = 0
	HealthDecrease = 0
	Ready = 0

	------ TEAM LIST ------

	AddTeam("Test Team", 0xFFFF02, "Statue", "Tank", "Default", "cm_test")
	
	hhs[1] = AddHog("Cake Hog", 0, 100, "NoHat")
	SetGearPosition(hhs[1], 771, 1344)
	
	hhs[2] = AddHog("Passive Hog", 0, 100, "NoHat")
	SetGearPosition(hhs[2], 772, 1344)
	HogTurnLeft(hhs[2], true)

end

function onAmmoStoreInit()
	SetAmmo(amCake, 9, 0, 0, 0)
	SetAmmo(amSkip, 9, 0, 0, 0)
end

function onGameStart()

	PlaceSprite(784, 1361, sprAmGirder, 4, 0xFFFFFFFF, nil, nil, nil, lfNormal)
	PlaceSprite(730, 1271, sprAmGirder, 6, 0xFFFFFFFF, nil, nil, nil, lfNormal)
	PlaceSprite(753, 1270, sprAmGirder, 6, 0xFFFFFFFF, nil, nil, nil, lfNormal)
	PlaceSprite(798, 1271, sprAmGirder, 6, 0xFFFFFFFF, nil, nil, nil, lfNormal)
	PlaceSprite(777, 1243, sprAmGirder, 6, 0xFFFFFFFF, nil, nil, nil, lfNormal)
	
end

local cakeTestPhase = 0
--[[ Test phases:
 0: Waiting for turn start
 1: Cake selected, waiting for attack
 2: Cake gear added
 3: Cake gead destroyed ]]

function onNewTurn()
	if cakeTestPhase == 0 then
		SetWeapon(amCake)
		cakeTestPhase = 1
	end
end

local cakeTicks = 0

function onGearAdd(gear)
	if GetGearType(gear) == gtCake then
		cakeTestPhase = 2
	end
end

function onGearDelete(gear)
	if GetGearType(gear) == gtCake and cakeTestPhase == 2 then
		WriteLnToConsole(string.format("TEST: The cake exploded after %d ticks.", cakeTicks))
		cakeTestPhase = 3
		if cakeTicks > CAKE_MAX_EXPLOSION_TIME then
			WriteLnToConsole("TEST RESULT: Failed because cake took too long to explode.")
			EndLuaTest(TEST_FAILED)
		else
			WriteLnToConsole("TEST RESULT: Succeeded because cake exploded in time.")
			EndLuaTest(TEST_SUCCESSFUL)
		end			

	end
end

function onGameTick()
	if cakeTestPhase == 1 then
		ParseCommand("+attack")
	elseif cakeTestPhase == 2 then
		cakeTicks = cakeTicks + 1
		if cakeTicks > CAKE_GIVE_UP_TIME then
			WriteLnToConsole(string.format("TEST RESULT: Failed because the cake still didn't explode after %d ticks.", CAKE_GIVE_UP_TIME))
			cakeTestPhase = 3
			EndLuaTest(TEST_FAILED)
		end
	end
end

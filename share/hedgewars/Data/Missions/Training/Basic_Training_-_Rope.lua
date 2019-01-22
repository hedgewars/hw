--[[
	Basic Rope Training
	Teaches the player how to rope! No advanced tricks, just the basics. But fun! (I hope)

	Lesson plan:
	- Select rope
	- Shoot rope, attach, detach
	- Extend, retract, swing to reach easy target
	- Multiple shots / rope re-use to go over water hazard
	- Drop grenade from rope
	- Special rules when you only got 1 rope (i.e. when the rope is officially used up)
	- Rope around obstacles
]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")

-- Map definition automatically converted from HWMAP file by hwmap2lua.sh
local map =
{'\2\30\7\126\135\2\28\5\52\0\1\211\6\203\135\3\207\6\189\0\3\1\5\205\135\4\120\5\203\0\2\30\5\31\135\2\35\4\173\0\1\170\4\216\135\4\150\4\248\0\3\230\4\138\135\4\54\6\22\0\3\205\6\189\135\4\154\7\91\0\4\154\7\91\135\6\57\7\41\0\4\79\6\38\135\4\221\6\112\0\4\221\6\112\135\6\27\6\70\0\3\175\6\196\135\4\51\5\235\0\3\17\6\178\135\3\161\5\226\0\4\33\7\4\135\4\191\6\93\0\4\200\7\75\135\5\45\6\137\0\6\29\6\66\135\6\98\5\123\0\6\107\7\32\135\6\237\5\249\0\6\102\5\95\135\7\169\5\6\0\7\0\5\237\135\7\235\6\20\0\7\233\6\13\135\7\226\8\43\0\13\66\6\47\135\13\100\8\57\0\7\167\5\15\135\7\164\4\51\0\7\71\4\109\135\13\235\4\132\0\13\4\6\75\135\14\242\6\57\0\14\169\6\166\135\15\183\4\86\0',
'\15\208\5\13\135\15\96\2\248\0\15\206\3\104\135\13\175\2\88\0\14\171\5\17\140\14\219\4\77\138\14\166\3\136\136\13\219\3\31\136\13\184\4\228\136\13\173\3\250\0\14\2\4\19\136\7\36\3\211\0\14\52\2\85\137\7\57\2\76\0\12\196\2\245\137\11\195\3\127\137\10\174\2\223\137\9\174\3\113\137\8\160\2\211\137\8\11\3\111\137\6\249\3\218\131\6\66\3\209\0\5\88\3\202\131\4\38\3\193\0\5\33\3\207\131\5\31\5\31\0\4\235\4\228\131\6\125\4\251\0\6\98\3\214\131\6\80\5\1\0\7\41\2\104\136\3\253\2\72\0\4\31\3\207\133\1\149\3\166\0\2\243\4\15\133\1\117\2\202\0\1\149\3\60\133\1\211\1\87\0\1\138\1\138\133\3\42\0\71\0\2\131\0\96\133\4\168\0\149\0\5\116\1\124\141\7\41\0\204\141\8\252\2\42\141\10\39\0\135\141\11\40\1\124\141\10\17\1\186\141',
'\12\104\0\151\141\4\29\0\156\137\14\160\0\69\0\13\182\1\133\137\13\171\2\78\0\13\201\0\78\137\13\189\0\197\0\13\194\1\195\137\15\148\2\147\0\14\189\0\59\137\15\222\0\217\0\15\226\0\215\137\15\164\2\145\0\13\217\1\211\137\15\167\1\220\0\14\208\2\37\164\8\89\1\92\139\6\146\1\211\139\8\174\2\39\203\10\19\2\7\203\11\56\1\167\203\12\106\0\217\203\7\36\1\12\203\5\182\1\163\203\6\141\1\165\203\8\71\1\135\203\8\151\3\19\203\8\7\3\70\203\9\227\3\118\203\13\66\3\113\133\13\54\4\104\0\11\200\3\26\133\11\191\4\84\0\9\160\2\255\133\9\160\4\84\0\8\16\3\163\133\8\18\4\109\0\9\108\3\53\197\10\19\3\70\0\14\25\5\228\132\14\43\4\253\130\13\237\3\241\210\13\217\3\225\210\13\95\4\74\140\7\137\4\40\0\2\209\6\75\207\3\255\6\102\0\4\1\6\107\207',
'\4\182\6\228\0\4\182\6\226\207\6\36\6\189\0\6\36\6\201\207\6\166\5\191\0\4\138\4\100\158\1\183\4\68\0\4\145\5\8\158\4\203\5\201\0\5\141\5\198\158\5\180\5\139\0\7\116\4\230\142\5\49\5\52\0\6\185\4\47\148\6\182\4\186\0\7\64\4\88\153\4\216\4\10\143\13\255\2\42\146\15\100\2\216\0\4\1\6\20\199\2\142\6\29\0\3\255\6\22\199\5\22\6\224\0\7\231\5\198\133\7\235\6\31\0\13\70\6\68\133\13\54\5\237\0\14\36\4\253\197\4\90\2\223\133\4\239\3\97\0\2\181\2\252\133\3\95\2\156\0\2\216\1\90\133\3\113\1\218\0\4\200\1\32\133\4\122\1\167\0\7\169\1\106\133\4\10\4\106\213\1\30\4\86\0\4\58\5\54\219\1\119\5\6\139\1\119\5\157\0\1\238\5\189\139\0\85\5\164\0\0\105\6\63\139\0\119\3\182\0\0\37\3\188\134\1\231\3\195\0',
'\1\142\5\13\145\1\188\5\102\0\1\199\5\59\145\3\209\5\198\134\5\59\5\102\0\4\63\5\111\134\0\121\3\225\134\4\111\3\234\0\2\255\4\106\134\3\12\4\228\0\2\58\4\120\132\13\148\2\60\132\13\146\1\106\0'}

local function drawMap()
	for m=1, #map do
		ParseCommand("draw "..map[m])
	end
end

-- Gears
local hog
local ropeGear

-- Status vars
local ropeSelected = false	-- rope was selected the first time, used for msg
local ropeAttached = false	-- rope was attached, used for msg
local target1Reached = false	-- hog near 1st first target
local barrelsBoom = false	-- barrels exploded
local wasFirstTurn = false	-- first turn msg was displayed
local gameOver = false		-- game over (only victory possible)
local currentTarget = 0		-- current target ID. First target = 1
local flawless = true		-- flawless if no damage taken and no mistake made

local cpX, cpY = 208, 1384	-- hog checkpoint, initialized with start coords

-- "Constants"
local initHogHealth = 50
local initHogHealthFinal = 1
local teamName

local girderData = {
	{2012, 1366, 6}, -- water gate
	{1156, 678, 2}, -- post-barrel gate
	{1206, 905, 2}, -- post-barrel gate
	{1064, 288, 6}, -- top level gate
	{1064, 455, 6}, -- top level gate
	{1557, 1009, 0}, -- barrel pit protection
	{1436, 1003, 4}, -- barrel pit protection
	{3607, 1307, 4}, -- post-water gate
	{3809, 1375, 0}, -- post-water gate
}

local targetData = {
	-- 1: Start
	{504, 1215},
	-- 2: Start 2
	{1082, 1348},
	-- 3: Before the water
	{1941, 1490},
	-- 4: After the water
	{3504, 1557},
	-- 5: Barrel pit
	{2060, 885},
	-- 6: Grand Finale
	{834, 381},
	-- 7: Goal
	{3802, 356},
}

function onGameInit()

	ClearGameFlags()
	EnableGameFlags(gfDisableGirders, gfDisableLandObjects, gfOneClanMode, gfInfAttack, gfSolidLand, gfDisableWind)
	Seed = "{386439b4-748a-48b1-945a-eba6a817ca83}"
	Theme = "Bamboo"
	MapGen = mgDrawn
	MapFeatureSize = 12
	TemplateFilter = 0
	TemplateNumber = 0
	TurnTime = MAX_TURN_TIME
	Explosives = 0
	MinesNum = 0
	CaseFreq = 0
	MinesTime = 0
	WaterRise = 0
	HealthDecrease = 0

	teamName = AddMissionTeam(-1)
	hog = AddMissionHog(initHogHealth)
	SetGearPosition(hog, cpX, cpY)
	SetEffect(hog, heResurrectable, 1)

	drawMap()

	SendHealthStatsOff()

end

-- The final challenge is to rope through an obstacle course with only 1 rope.
-- If the player screws up, this functinon will restart it.
local function resetFinalChallenge(setPos)
	if setPos == nil then
		setPos = true
	end
	SetHealth(hog, initHogHealthFinal)
	AddAmmo(hog, amRope, 1)
	SetGearVelocity(hog, 0, 0)

	if setPos then
		PlaySound(sndWarp)
		SetGearPosition(hog, cpX, cpY)
		AddVisualGear(cpX, cpY, vgtExplosion, 0, false)
		FollowGear(hog)
	end
end

-- Deletes girder with given girderData ID
local function eraseGirder(id)
	EraseSprite(girderData[id][1], girderData[id][2], sprAmGirder, girderData[id][3], false, false, false, false)
	PlaySound(sndVaporize)
	AddVisualGear(girderData[id][1], girderData[id][2], vgtSteam, false, 0)
	AddCaption(loc("Barrier unlocked!"))
end

local function loadGearData()
	------ GIRDERS ------
	for g=1, #girderData do
		PlaceGirder(unpack(girderData[g]))
	end

	PlaceSprite(1678, 546, sprTargetBee, 0)

	------ BARRELS ------
	local barrels = {}
	table.insert(barrels, AddGear(1370, 1223, gtExplosives, 0, 0, 0, 0))
	table.insert(barrels, AddGear(1430, 1226, gtExplosives, 0, 0, 0, 0))
	table.insert(barrels, AddGear(1489, 1218, gtExplosives, 0, 0, 0, 0))
	table.insert(barrels, AddGear(1537, 1211, gtExplosives, 0, 0, 0, 0))
	table.insert(barrels, AddGear(1578, 1206, gtExplosives, 0, 0, 0, 0))
	for b=1, #barrels do
		SetHealth(barrels[b], 1)
	end

	------ FIRST TARGET ------
	currentTarget = 1
	AddGear(targetData[currentTarget][1], targetData[currentTarget][2], gtTarget, 0, 0, 0, 0)
end

function onGameStart()
	loadGearData()

	ShowMission(loc("Basic Rope Training"), loc("Basic Training"),
	loc("Use the rope to complete the obstacle course!"), -amRope, 0)
	FollowGear(hog)
end

function onNewTurn()
	local ctrl = ""
	if not wasFirstTurn then
		if INTERFACE == "desktop" then
			ctrl = loc("Open ammo menu: [Right click]")
		elseif INTERFACE == "touch" then
			ctrl = loc("Open ammo menu: Tap the [Suitcase]")
		end
		ShowMission(loc("Basic Rope Training"), loc("Select Rope"),
		loc("Select the rope to begin!").."|"..
		ctrl, 2, 7500)
		wasFirstTurn = true
	end
end

function onGameTick()
	if gameOver or (not CurrentHedgehog) then
		return
	end

	-- First rope selection
	if not ropeSelected and GetCurAmmoType() == amRope then
		local ctrl = ""
		if INTERFACE == "desktop" then
			ctrl = loc("Aim: [Up]/[Down]").."|"..
			loc("Attack: [Space]")
		elseif INTERFACE == "touch" then
			ctrl = loc("Aim: [Up]/[Down]").."|"..
			loc("Attack: Tap the [Bomb]")
		end
		ShowMission(loc("Basic Rope Training"), loc("Getting Started"),
		loc("You can use the rope to reach new places.").."|"..
		loc("Aim at the ceiling and hold [Attack] pressed until the rope attaches.").."|"..
		ctrl, 2, 15000)
		ropeSelected = true
	-- Rope attach
	elseif ropeGear and band(GetState(ropeGear), gstCollision) ~= 0 then
		-- First rope attach
		if not ropeAttached and not target1Reached then
			ShowMission(loc("Basic Rope Training"), loc("How to Rope"),
			loc("Great!").."|"..
			loc("Use the rope to get to the target!").."|"..
			loc("Retract/Extend rope: [Up]/[Down]").."|"..
			loc("Swing: [Left]/[Right]").."|"..
			loc("Release rope: [Attack]"), 2, 15000)
			ropeAttached = true
		elseif currentTarget > 1 and (not (currentTarget == 6 and barrelsBoom)) then
			HideMission()
		end
	end

	-- Prevent grenade being thrown by hand (must use from rope instead)
	local allowAttack = true
	if GetCurAmmoType() == amGrenade and ropeGear == nil then
		allowAttack = false
	end
	if allowAttack then
		SetInputMask(bor(GetInputMask(), gmAttack))
	else
		SetInputMask(band(GetInputMask(), bnot(gmAttack)))
	end
	if isInFinalChallenge then
		local dX, dY = GetGearVelocity(CurrentHedgehog)
		local x, y = GetGearPosition(CurrentHedgehog)
		if band(GetState(CurrentHedgehog), gstHHDriven) ~= 0 and GetAmmoCount(CurrentHedgehog, amRope) == 0 and
				GetFlightTime(CurrentHedgehog) == 0 and (not ropeGear) and
				math.abs(dX) < 5 and math.abs(dY) < 5 and
				(x < 3417 or y > 471) then
			flawless = false
			AddCaption(loc("Your rope is gone! Try again!"))
			resetFinalChallenge()
			PlaySound(sndWarp)
		end
	end
end

function onGameTick20()
	if not gameOver and not target1Reached and CurrentHedgehog and gearIsInCircle(CurrentHedgehog, targetData[1][1], targetData[1][2], 48, false) then
		ShowMission(loc("Basic Rope Training"), loc("Target Puncher"),
		loc("Okay, now destroy the target|using the baseball bat.").."|"..
		loc("Release rope: [Attack]"), 2, 9000)
		target1Reached = true
	end
end

function onGearAdd(gear)
	if GetGearType(gear) == gtRope then
		ropeGear = gear
	elseif GetGearType(gear) == gtGrenade then
		if not ropeGear then
			DeleteGear(gear)
		end
	end
end

function onGearResurrect(gear, vGear)
	-- Teleport hog to previous checkpoint
	if gear == hog then
		flawless = false
		SetGearPosition(hog, cpX, cpY)
		if vGear then
			SetVisualGearValues(vGear, GetX(hog), GetY(hog))
		end
		FollowGear(hog)
		AddCaption(loc("Your hedgehog has been revived!"))
		if isInFinalChallenge then
			resetFinalChallenge(false)
		end
	end
end

function onGearDamage(gear)
	if gear == hog then
		flawless = false
	end
end

function onGearDelete(gear)
	if GetGearType(gear) == gtTarget then
		-- Update checkpoint
		cpX, cpY = GetGearPosition(gear)

		-- New message
		if currentTarget == 1 then
			ShowMission(loc("Basic Rope Training"), loc("Obstacle"),
			loc("Well done! Let's destroy the next target!").."|"..
			loc("The targets will guide you through the training.").."|"..
			loc("Use your rope to get to the next target, then destroy it!"), 2, 8000)
		elseif currentTarget == 2 then
			ShowMission(loc("Basic Rope Training"), loc("Speed Roping"),
			loc("Try to reach and destroy the next target quickly.").."|"..
			loc("Hint: When you shorten the rope, you move faster!|And when you lengthen it, you move slower."), 2, 15000)
		elseif currentTarget == 3 then
			ShowMission(loc("Basic Rope Training"), loc("Over the Water"),
			loc("When you're in mid-air, you can continue to aim|and fire another rope if you're not attached.").."|"..
			loc("To get over the water, you have to do multiple|rope shots and swings.").."|"..
			loc("It needs some practice, but you have infinite lives.").."|"..
			loc("Good luck!"), 2, 22500)
			eraseGirder(1)
		elseif currentTarget == 4 then
			ShowMission(loc("Basic Rope Training"), loc("Little Obstacle Course"),
			loc("Well done! The next target awaits.").."|"..
			loc("Hint: The rope only bends around objects.|When it doesn't hit anything, it's always straight."), 2, 7000)
			eraseGirder(8)
			eraseGirder(9)
		elseif currentTarget == 5 then
			ShowMission(loc("Basic Rope Training"), loc("Rope Weapons"),
			loc("Some weapons can be dropped from the rope.").."|"..
			loc("Collect the weapon crate and drop|a grenade from rope to destroy the barrels.").."|"..
			loc("Step 1: Start roping").."|"..
			loc("Step 2: Select grenade").."|"..
			loc("Step 3: Drop the grenade").."| |"..
			loc("Drop weapon (while on rope): [Long Jump]"), 2, 20000)
			AddAmmo(hog, amBaseballBat, 0)
			SpawnAmmoCrate(1849, 920, amGrenade, AMMO_INFINITE)
		elseif currentTarget == 6 then
			ShowMission(loc("Basic Rope Training"), loc("Finite Ropes"),
			loc("So far, you had infinite ropes, but in the|real world, ropes are usually limited.").."|"..
			loc("Rules:").." |"..
			loc("As long you don't touch the ground, you can|re-use the same rope as often as you like.").."|"..
			loc("If you miss a shot while trying to|re-attach, your rope is gone, too!").."| |"..
			loc("Final Challenge:").." |"..
			loc("Reach and destroy the final target to win.").."|"..
			loc("You only get 1 rope this time, don't waste it!"),
			2, 25000)
			eraseGirder(4)
			eraseGirder(5)
			AddAmmo(hog, amRope, 1)
			SetHealth(hog, initHogHealthFinal)
			isInFinalChallenge = true
		elseif currentTarget == 7 then
			SaveMissionVar("Won", "true")
			ShowMission(loc("Basic Rope Training"), loc("Training complete!"),
			loc("Congratulations!"), 0, 0)
			if flawless then
				PlaySound(sndFlawless, hog)
			else
				PlaySound(sndVictory, hog)
			end
			AddAmmo(hog, amBaseballBat, 0)
			AddAmmo(hog, amGrenade, 0)
			AddAmmo(hog, amRope, 0)
			SendStat(siCustomAchievement, loc("Oh yeah! You sure know how to rope!"))
			SendStat(siGameResult, loc("You have finished the Basic Rope Training!"))
			SendStat(siPlayerKills, "0", teamName)
			EndGame()
			gameOver = true
			SetInputMask(0)
		end
		currentTarget = currentTarget + 1

		if currentTarget <= #targetData then
			AddGear(targetData[currentTarget][1], targetData[currentTarget][2], gtTarget, 0, 0, 0, 0)
		end

	elseif GetGearType(gear) == gtExplosives then
		if not barrelsBoom then
			barrelsBoom = true
			AddAmmo(hog, amGrenade, 0)
			AddAmmo(hog, amBaseballBat, AMMO_INFINITE)
			eraseGirder(2)
			eraseGirder(3)
			ShowMission(loc("Basic Rope Training"),
				loc("Kaboom!"),
				loc("Follow the path and destroy the next target."),
				2, 5000)
		end
	elseif GetGearType(gear) == gtRope then
		ropeGear = nil
		if ropeAttached and not target1Reached then
			local ctrl = ""
			if INTERFACE == "desktop" then
				ctrl = loc("Aim: [Up]/[Down]").."|"..
				loc("Attack: [Space]")
			elseif INTERFACE == "touch" then
				ctrl = loc("Aim: [Up]/[Down]").."|"..
				loc("Attack: Tap the [Bomb]")
			end
			ShowMission(loc("Basic Rope Training"), loc("How to Rope"),
			loc("Go to the target.").."|"..
			loc("Hold [Attack] to attach the rope.").."|"..
			ctrl, 2, 13000)
			ropeAttached = false
		end
	elseif GetGearType(gear) == gtCase then
		eraseGirder(6)
		eraseGirder(7)
	end
end

function onAmmoStoreInit()
	SetAmmo(amRope, 9, 0, 0, 1)
	SetAmmo(amBaseballBat, 9, 0, 0, 1)
end

function onAttack()
	if GetCurAmmoType() == amGrenade and not ropeGear then
		AddCaption(loc("You have to drop the grenade from rope!"), 0xFF4000FF, capgrpMessage)
		PlaySound(sndDenied)
	end
end

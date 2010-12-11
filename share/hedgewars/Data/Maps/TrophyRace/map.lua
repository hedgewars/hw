loadfile(GetDataPath() .. "Scripts/Locale.lua")()

-- Hedgewars - Roperace for 2+ Players

-- store number of hedgehogs
local numhhs = 0

-- store hedgehog gears
local hhs = {}

-- store best time per team
local clantimes = {}

-- store best times
local times = {}

-- in milisseconds
local maxtime = 99000

-- define start area (left, top, width, height)
local start_area = {1606, 498, 356, 80}

-- define goal area (left, top, width, height)
local goal_area = {2030, 300, 56, 280}

-- last active hog
local lasthog = nil

-- active hog reached the goal?
local reached = false

-- hog with best time
local besthog = nil

-- hog with worst time (per round)
local worsthog = nil

-- best time
local besttime = maxtime + 1

-- worst time (per round)
local worsttime = 0

function onGameInit()
	GameFlags = gfSolidLand + gfInvulnerable
	TurnTime = maxtime
	CaseFreq = 0
	MinesNum = 0
	Explosives = 0
	Delay = 500
	SuddenDeathTurns = 99999 -- "disable" sudden death
	Theme = 'Olympics'
end

function onGameStart()
	ShowMission(loc("TrophyRace"), "", loc("Use your rope to get from start to finish as fast as you can!"), -amRope, 0)
	started = true
	p=1820
	for i = 0, numhhs - 1 do
	p = p + 50	
	SetGearPosition(hhs[i], p, 0)
	end
	
	for i=0, ClansCount-1 do
		clantimes[i] = 0
	end
end

function onAmmoStoreInit()
	SetAmmo(amRope, 9, 2, 0)
end

function onGameTick()
	if TurnTimeLeft == 1 and CurrentHedgehog ~= nil then
		SetHealth(CurrentHedgehog, 0)
		x, y = GetGearPosition(CurrentHedgehog)
		AddGear(x, y, gtAmmo_Grenade, 0, 0, 0, 0)
		worsttime = 99999
		worsthog = nil
	elseif TurnTimeLeft == maxtime - 1 and CurrentHedgehog ~= nil then
		if lasthog ~= nil then 
		SetGearPosition(lasthog, p , 0)
		end
		reached = false
		SetGearPosition(CurrentHedgehog, start_area[1] + start_area[3] / 2, start_area[2] + start_area[4] / 2)
	elseif CurrentHedgehog ~= nil then
		x, y = GetGearPosition(CurrentHedgehog)
		if not reached and x > goal_area[1] and x < goal_area[1] + goal_area[3] and y > goal_area[2] and y < goal_area[2] + goal_area[4] then -- hog is within goal rectangle
			reached = true
			local ttime = maxtime - TurnTimeLeft
			--give it a sound;)
			if ttime < besttime then
				PlaySound (sndHomerun)
			else
				PlaySound (sndHellish)
			end
			for i = 0, numhhs - 1 do
				if hhs[i] == CurrentHedgehog then
					times[numhhs] = ttime
				end
			end
				
			local hscore = "| |"
			local clan = GetHogClan(CurrentHedgehog)
			if ttime < clantimes[clan] or clantimes[clan] == 0 then
				clantimes[clan] = ttime
			end
			
			if ttime < besttime then
				besttime = ttime
				besthog = CurrentHedgehog
				hscore = hscore .. loc("NEW fastest lap: ")
			else
				hscore = hscore .. loc("Fastest lap: ")
			end
			if ttime > worsttime then
				worsttime = ttime
				worsthog = CurrentHedgehog
			end
			hscore = hscore .. GetHogName(besthog) .. " - " .. (besttime / 1000) .. " s | |" .. loc("Best laps per team: ")
			
			if clan == ClansCount -1 then
				-- Time for elimination - worst hog is out and the worst hog vars are reset.
				SetHealth(worsthog, 0)
				--Place a grenade to make inactive slowest hog active
				x, y = GetGearPosition(worsthog)
				AddGear(x, y, gtShell, 0, 0, 0, 0)
				worsttime = 0
				worsthog = nil
				end
			
			for i=0, ClansCount -1 do
				local tt = "" .. (clantimes[i] / 1000) .. " s"
				if clantimes[i] == 0 then
					tt = "--"
				end
				hscore = hscore .. "|" .. string.format(loc("Team %d: "), i+1) .. tt
			end
			
			ShowMission(loc("TrophyRace"), "", loc("You've reached the goal!| |Time: ") .. (ttime / 1000) .. " s" .. hscore, 0, 0)
			TurnTimeLeft = 0
		end
	end
end

function onGearAdd(gear)
	if GetGearType(gear) == gtHedgehog then
		hhs[numhhs] = gear
		times[numhhs] = 0
		numhhs = numhhs + 1
	elseif GetGearType(gear) == gtRope then -- rope is shot
		
	end
end

function onGearDelete(gear)
	if GetGearType(gear) == gtRope then -- rope deletion - hog didn't manage to rerope
		--TurnTimeLeft = 0 -- end turn or not? hm...
		lasthog = CurrentHedgehog
		
	end
end

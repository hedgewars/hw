-- Hedgewars - Roperace for 2+ Players

-- DEVELOPER WARNING - FOR OFFICIAL DEVELOPMENT --
-- Be careful when editig this script, do not introduce changes lightly!
-- This script is used for time records on the official Hedgewars server.
-- Introducing breaking changes means we have to invalidate past time records!

HedgewarsScriptLoad("/Scripts/Locale.lua")

-- store number of hedgehogs
local numhhs = 0

-- store hedgehog gears
local hhs = {}

-- count how many hogs each clan has
local hogsByClan = {}

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

-- hog with worst time (per round)
local worsthog = nil

local besthog = nil
local besthogname = ''

-- best time
local besttime = maxtime + 1

-- best time per team
local bestTimes = {}

-- worst time (per round)
local worsttime = 0
local startTime = 0;

function onGameInit()
    GameFlags = gfSolidLand + gfInvulnerable
    TurnTime = maxtime
    CaseFreq = 0
    MinesNum = 0
    Explosives = 0
    Delay = 500
    Theme = 'Olympics'
    -- Disable Sudden Death
    WaterRise = 0
    HealthDecrease = 0
end

function onGameStart()
    ShowMission(loc("TrophyRace"), loc("Race"),
        loc("Use your rope to get from start to finish as fast as you can!") .. "|" ..
        loc("In each round, the worst hedgehog of the round is eliminated.") .. "|" ..
        loc("The last surviving clan wins."),
        -amRope, 0)
    started = true
    p=1820
    for i = 0, numhhs - 1 do
    p = p + 50    
    SetGearPosition(hhs[i], p, 0)
    end
    
    for i=0, ClansCount-1 do
        clantimes[i] = 0
    end
    if ClansCount >= 2 then
        SendAchievementsStatsOff()
    end
end

function onAmmoStoreInit()
    SetAmmo(amRope, 9, 1, 0)
    SetAmmo(amSkip, 9, 1, 0)
end

function killHog()
        SetHealth(CurrentHedgehog, 0)
        SetEffect(CurrentHedgehog, heInvulnerable, 0)
        x, y = GetGearPosition(CurrentHedgehog)
        AddGear(x, y-2, gtGrenade, 0, 0, 0, 2)
        SetGearVelocity(CurrentHedgehog, 0, 0)
        worsttime = 99999
        worsthog = nil
        lasthog = nil
end

function onHogAttack(ammoType)
    if TurnTimeLeft == 0 then
        killHog()
    elseif ammoType == amRope then
        HideMission()
    end
end

function onNewTurn()
    if lasthog ~= nil then 
        SetGearPosition(lasthog, p , 0)
        if not reached then
        end
    end
    startTime = 0
    reached = false
    if CurrentHedgehog ~= nil then
        SetGearVelocity(CurrentHedgehog, 1, 0)
        SetGearPosition(CurrentHedgehog, start_area[1] + start_area[3] / 2, start_area[2] + start_area[4] / 2)
        SetWeapon(amRope)
        lasthog = CurrentHedgehog
    end
end

function onGameTick()
    if startTime == 0 and TurnTimeLeft < maxtime then
        startTime = GameTime
    end
    if CurrentHedgehog ~= nil and TurnTimeLeft == 1 then
        killHog()
        AddCaption(loc("Time's up!"), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage2)
    elseif CurrentHedgehog ~= nil then
        x, y = GetGearPosition(CurrentHedgehog)
        if not reached and x > goal_area[1] and x < goal_area[1] + goal_area[3] and y > goal_area[2] and y < goal_area[2] + goal_area[4] then -- hog is within goal rectangle
            reached = true
            local ttime = GameTime-startTime
            -- give it a sound ;)
            if ttime < besttime then
                PlaySound (sndHomerun)
            elseif ttime > worsttime then
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
            local teamname = GetHogTeamName(CurrentHedgehog)
            if bestTimes[teamname] == nil or bestTimes[teamname] > ttime then
                bestTimes[teamname] = ttime
            end
            local fastestStr
            if ttime < besttime then
                besttime = ttime
                besthog = CurrentHedgehog
                besthogname = GetHogName(besthog)
            else
            end
            fastestStr = loc("Fastest lap: %.3fs by %s")
            if ttime > worsttime then
                worsttime = ttime
                worsthog = CurrentHedgehog
            end

            if worsthog then
                hscore = hscore ..  string.format(loc("Round's slowest lap: %.3fs by %s"), (worsttime / 1000), GetHogName(worsthog))
            end

            hscore = hscore .. " |" .. string.format(fastestStr, (besttime / 1000), besthogname)
            
            if clan == ClansCount -1 then
                -- Time for elimination - worst hog is out and the worst hog vars are reset.
                if worsthog ~= nil then
                    SetHealth(worsthog, 0)
                    -- Drop a bazooka to make inactive slowest hog active.
                    x, y = GetGearPosition(worsthog)
                    AddGear(x, y, gtShell, 0, 0, 0, 0)
                end
                worsttime = 0
                worsthog = nil
            end

            ShowMission(loc("TrophyRace"), loc("Status update"),
                string.format(loc("Time: %.3fs by %s"), (ttime/1000), GetHogName(CurrentHedgehog))
                .. hscore,
                0, 0)
            AddCaption(string.format(loc("Time: %.3fs"), (ttime/1000)), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage2)
            AddCaption(loc("Track completed!"), capcolDefault, capgrpGameState)
            EndTurn(true)
        else
            if (TurnTimeLeft > 0) and (TurnTimeLeft ~= TurnTime) and CurrentHedgehog ~= nil and GetHealth(CurrentHedgehog) > 0 and (not reached) and GameTime%100 == 0 then
                local ttime = GameTime-startTime
                AddCaption(string.format(loc("Time: %.1fs"), (ttime/1000)), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage2)
            end
        end
    end
end

function WriteStats()
   if besthog then
       SendStat(siCustomAchievement, string.format(loc("The fastest hedgehog was %s from %s with a time of %.3fs."), besthogname, GetHogTeamName(besthog), besttime/1000))
   else
       SendStat(siCustomAchievement, loc("Nobody managed to finish the race. What a shame!"))
   end

   -- Write most skips
   local mostSkips = 2 -- a minimum skip threshold is required
   local mostSkipsTeam = nil
   for i=0, TeamsCount-1 do
      local teamName = GetTeamName(i)
      local stats = GetTeamStats(teamName)
      if stats.TurnSkips > mostSkips then
          mostSkips = stats.TurnSkips
          mostSkipsTeam = teamName
      end
   end
   if mostSkipsTeam then
       SendStat(siMaxTurnSkips, tostring(mostSkips) .. " " .. mostSkipsTeam)
   end
end

function onGearAdd(gear)
    if GetGearType(gear) == gtHedgehog then
        hhs[numhhs] = gear
        times[numhhs] = 0
        numhhs = numhhs + 1
        local clan = GetHogClan(gear)
        if not hogsByClan[clan] then
            hogsByClan[clan] = 0
        end
        hogsByClan[clan] = hogsByClan[clan] + 1
    end
end

function areTwoOrMoreClansLeft()
    local clans = 0
    for i=0, ClansCount-1 do
        if hogsByClan[i] >= 1 then
            clans = clans + 1
        end
        if clans >= 2 then
            return true
        end
    end
    return false
end

function onGearDelete(gear)
    if GetGearType(gear) == gtHedgehog then
        local clan = GetHogClan(gear)

        hogsByClan[clan] = hogsByClan[clan] - 1
        if not areTwoOrMoreClansLeft() then
            WriteStats()
        end
    end
end

function onAchievementsDeclaration()
    for team,time in pairs(bestTimes) do
        DeclareAchievement("rope race", team, "TrophyRace", time)
    end
end


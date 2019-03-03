-- Library for keeping track of gears in the game
-- and running functions on them
-- also keeps track of clans and teams

local trackingTeams = false
local resurrecting = false
local gears = {}
local teams = {}
local clans = {}
local resurrectedHogs = {}
local gearValues = {}
local teamValues = {}
local clanValues = {}

-- Registers when a gear is added
function trackGear(gear)
    table.insert(gears, gear)
    if trackingTeams and GetGearType(gear) == gtResurrector then
        resurrecting = true
    elseif resurrecting and GetGearType(gear) == gtHedgehog then
        table.insert(resurrectedHogs, gear)
    end
end

-- Registers when a gear is deleted
function trackDeletion(gear)
    gearValues[gear] = nil
    for k, g in ipairs(gears) do
        if g == gear then
            table.remove(gears, k)
            break
        end
    end
    if trackingTeams and GetGearType(gear) == gtHedgehog then
        local hogs = teams[GetHogTeamName(gear)]
        if hogs ~= nil then
            if #hogs == 1 then
                hogs = nil
            else
                for k, hog in ipairs(hogs) do
                    if hog == gear then
                        table.remove(hogs, k)
                        break
                    end
                end
            end
        end
    elseif resurrecting and GetGearType(gear) == gtResurrector then
        for k, gear in ipairs(resurrectedHogs) do
            local team = GetHogTeamName(gear)
            if teams[team] == nil then
                teams[team] = {}
            end
            table.insert(teams[team], gear)
        end
        resurrecting = false
        resurrectedHogs = {}
    end
end

-- Start to keep track of teams
function trackTeams()
    if not trackingTeams then
        trackingTeams = true
        for k, gear in ipairs(gears) do
            if GetGearType(gear) == gtHedgehog then
                local team = GetHogTeamName(gear)
                if teams[team] == nil then
                    teams[team] = { gear }
                    clans[team] = GetHogClan(gear)
                else
                    table.insert(teams[team], gear)
                end
            end
        end
    end
end

-- Registers when a hog is hidden
function trackHiding(gear)
    for k, g in ipairs(gears) do
        if g == gear then
            table.remove(gears, k)
            break
        end
    end

    if trackingTeams then
        local hogs = teams[GetHogTeamName(gear)]

        if hogs ~= nil then
            if #hogs == 1 then
                hogs = nil
            else
                for k, hog in ipairs(hogs) do
                    if hog == gear then
                        table.remove(hogs, k)
                        break
                    end
                end
            end
        end
    end
end

-- Registers when a hog is restored
function trackRestoring(gear)
    table.insert(gears, gear)

    if trackingTeams then
        local team = GetHogTeamName(gear)
        if teams[team] == nil then
            teams[team] = {}
        end
        table.insert(teams[team], gear)
    end
end

-- Get a value for a specific gear
function getGearValue(gear, key)
    if gearValues[gear] ~= nil then
        return gearValues[gear][key]
    end
    return nil
end

-- Set a value for a specific gear
function setGearValue(gear, key, value)
    local found = false
    for id, values in pairs(gearValues) do
        if id == gear then
            values[key] = value
            found = true
        end
    end
    if not found then
        gearValues[gear] = { [key] = value }
    end
end

-- Increase a value for a specific gear
function increaseGearValue(gear, key)
    for id, values in pairs(gearValues) do
        if id == gear then
            values[key] = values[key] + 1
        end
    end
end

-- Decrease a value for a specific gear
function decreaseGearValue(gear, key)
    for id, values in pairs(gearValues) do
        if id == gear then
            values[key] = values[key] - 1
        end
    end
end

-- Get a value for a specific team
function getTeamValue(team, key)
    if teamValues[team] ~= nil then
        return teamValues[team][key]
    end
    return nil
end

-- Set a value for a specific team
function setTeamValue(team, key, value)
    local found = false
    for name, values in pairs(teamValues) do
        if name == team then
            values[key] = value
            found = true
        end
    end
    if not found then
        teamValues[team] = { [key] = value }
    end
end

-- Increase a value for a specific team
function increaseTeamValue(team, key)
    for name, values in pairs(teamValues) do
        if name == team then
            values[key] = values[key] + 1
        end
    end
end

-- Decrease a value for a specific team
function decreaseTeamValue(team, key)
    for name, values in pairs(teamValues) do
        if name == team then
            values[key] = values[key] - 1
        end
    end
end

-- Get a value for a specific clan
function getClanValue(clan, key)
    if clanValues[clan] ~= nil then
        return clanValues[clan][key]
    end
    return nil
end

-- Set a value for a specific clan
function setClanValue(clan, key, value)
    local found = false
    for num, values in ipairs(clanValues) do
        if num == clan then
            values[key] = value
            found = true
        end
    end
    if not found then
        clanValues[clan] = { [key] = value }
    end
end

-- Increase a value for a specific clan
function increaseClanValue(clan, key)
    for num, values in ipairs(clanValues) do
        if num == clan then
            values[key] = values[key] + 1
        end
    end
end

-- Decrease a value for a specific clan
function decreaseClanValue(clan, key)
    for num, values in ipairs(clanValues) do
        if num == clan then
            values[key] = values[key] - 1
        end
    end
end

-- Run a function on all tracked gears
function runOnGears(func)
    for k, gear in ipairs(gears) do
        func(gear)
    end
end

-- Returns the first hog (alive or not) in the given clan
function getFirstHogOfClan(clan)
    for k, hogs in pairs(teams) do
        for m, hog in ipairs(hogs) do
            if GetHogClan(hog) == clan then
                return hog
            end
        end
    end
    return nil
end

-- Run a function on all tracked hogs
function runOnHogs(func)
    for k, hogs in pairs(teams) do
        for m, hog in ipairs(hogs) do
            func(hog)
        end
    end
end

-- Run a function on hogs in a team
function runOnHogsInTeam(func, team)
    if teams[team] ~= nil then
        for k, hog in ipairs(teams[team]) do
            func(hog)
        end
    end
end

-- Run a function on hogs in other teams
function runOnHogsInOtherTeams(func, team)
    for k, hogs in pairs(teams) do
        if k ~= team then
            for m, hog in ipairs(hogs) do
                func(hog)
            end
        end
    end
end

-- Run a function on hogs in a clan
function runOnHogsInClan(func, clan)
    for i = 1, ClansCount do
        if clans[i] == clan then
            for k, hog in ipairs(teams[i]) do
                func(hog)
            end
        end
    end
end

-- Run a function on hogs in other clans
function runOnHogsInOtherClans(func, clan)
    for i = 1, ClansCount do
        if clans[i] ~= clan then
            for k, hog in ipairs(teams[i]) do
                func(hog)
            end
        end
    end
end

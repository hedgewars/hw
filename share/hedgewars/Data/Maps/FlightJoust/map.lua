local hogs = {}
local spawncrate = 0

function mapM_(func, tbl)
    for i,v in pairs(tbl) do
        func(v)
    end 
end

function map(func, tbl)
    local newtbl = {}
    for i,v in pairs(tbl) do
        newtbl[i] = func(v)
    end 
    return newtbl
end

function filter(func, tbl)
    local newtbl = {}
    for i,v in pairs(tbl) do
        if func(v) then
            table.insert(newtbl, v)
        end
    end
    return newtbl
end

function onGameInit()
    GameFlags = gfSolidLand + gfDivideTeams
    TurnTime = 10000
    CaseFreq = 0 
    MinesNum = 0 
    Explosives = 0 
    SuddenDeathTurns = 99999 -- "disable" sudden death
    Theme = Compost
end

function onGameStart()
    local offset = 50
    local team1hh = filter(function(h) return GetHogClan(h) == 0 end, hogs)
    local team2hh = filter(function(h) return GetHogClan(h) == 1 end, hogs)

    for i,h in ipairs(team1hh) do
        SetGearPosition(h, 250+(i-1)*offset, 1000)
    end
    for i,h in ipairs(team2hh) do
        SetGearPosition(h, 3500-(i-1)*offset, 1000)
    end

    SpawnHealthCrate(1800, 1150)
end

function onAmmoStoreInit()
    SetAmmo(amRCPlane, 9, 0, 0, 0)
    SetAmmo(amSkip, 9, 0, 0, 0)
end

function onGearAdd(gear)
    if GetGearType(gear) == gtRCPlane then
        SetTimer(gear,60000)
    end 
    if GetGearType(gear) == gtHedgehog then
        table.insert(hogs, gear)
    end 
end

function onGameTick()
    if (TurnTimeLeft == 9999 and spawncrate == 1) then
        SpawnHealthCrate(1800, 1150)
        spawncrate = 0
    end
end

function onGearDelete(gear)
    if GetGearType(gear) == gtCase then
        spawncrate = 1
    end
end

local hogs = {}

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

function onGameInit()
    GameFlags = gfSolidLand + gfDivideTeams
    TurnTime = 10000
    CaseFreq = 0 
    LandAdds = 0 
    Explosives = 0 
    Delay = 500 
    SuddenDeathTurns = 99999 -- "disable" sudden death
    Theme = Compost
end

function setHogPositions(gear)
    if GetHogClan(gear) == 0 then
        SetGearPosition(gear, 250, 1000)
    end 
    if GetHogClan(gear) == 1 then
        SetGearPosition(gear, 3500, 1000)
    end 
end

function onGameStart()
    mapM_(setHogPositions, hogs)
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
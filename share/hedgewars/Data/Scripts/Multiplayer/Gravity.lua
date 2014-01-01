HedgewarsScriptLoad("/Scripts/Locale.lua")

local gravity = 100
local wdGameTicks = 0
local wdTTL = 0

function onNewTurn()
    SetGravity(gravity)
    wdGameTicks = GameTime
end

function onGameTick20()
    if wdGameTicks + 15000 < GameTime then
        SetGravity(100)
    elseif wdTTL ~= TurnTimeLeft then
        wdGameTicks = GameTime
        SetGravity(gravity)
    end

    wdTTL = TurnTimeLeft
end

function onGameInit()
    gravity = GetAwayTime
    GetAwayTime = 100
end

function onGameStart()
    ShowMission(loc("Gravity"),
                loc("Current value is ") .. gravity .. "%",
                loc("Set any gravity value you want by adjusting get away time"),
                0, 5000)
end
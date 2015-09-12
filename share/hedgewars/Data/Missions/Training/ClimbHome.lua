HedgewarsScriptLoad("/Scripts/Locale.lua")

local isSinglePlayer = true

-- trying to allow random theme, but fixed theme objects...
-- Also skip some ugly themes, or ones where the sky is "meh"
--local themes = { "Art","Cake","City","EarthRise","Halloween","Olympics","Underwater","Bamboo","Castle","Compost","Eyes","Hell","Planes","Bath","Cave","CrazyMission","Freeway","Island","Sheep","Blox","Cheese","Deepspace","Fruit","Jungle","Snow","Brick","Christmas","Desert","Golf","Nature","Stage" }
local themes = {"Christmas","Hell","Bamboo","City","Island","Bath","Compost","Jungle","Desert","Nature","Olympics","Brick","EarthRise","Sheep","Cake","Freeway","Snow","Castle","Fruit","Stage","Cave","Golf","Cheese","Halloween"}
local showWaterStats = true -- uses the AI team to draw water height.
local scaleGraph = true
local totalHedgehogs = 0
local HH = {}
local teams = {}
local dummyHog = nil


function onGameInit()
    -- Ensure people get same map for same theme
    Theme = themes[GetRandom(#themes)+1]
    Seed = ClimbHome
    TurnTime = 999999999
    EnableGameFlags(gfOneClanMode)
    DisableGameFlags(gfBottomBorder+gfBorder)
    CaseFreq = 0
    Explosives = 0
    MineDudPercent = 0
    Map = "ClimbHome"
    AddTeam(loc("Lonely Hog"), 0xDD0000, "Simple", "Island", "Default")
    player = AddHog(loc("Climber"), 0, 1, "NoHat")
    if showWaterStats then
        AddTeam(" ", 0x545C9D, "Simple", "Island", "Default")
    elseif scaleGraph then
        AddTeam(" ", 0x050505, "Simple", "Island", "Default")
    end
    if showWaterStats or scaleGraph then
        dummyHog = AddHog(" ", 0, 1, "NoHat")
        HH[dummyHog] = nil
        totalHedgehogs = totalHedgehogs - 1
        SendStat(siClanHealth, tostring(32640), " ")
    end
end

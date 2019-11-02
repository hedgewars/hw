HedgewarsScriptLoad("/Scripts/Locale.lua")

isSinglePlayer = true

-- trying to allow random theme, but fixed theme objects...
-- Also skip some ugly themes, or ones where the sky is "meh"
local themes = {"Christmas","Hell","Bamboo","City","Island","Bath","Compost","Jungle","Desert","Nature","Olympics","Brick","EarthRise","Sheep","Cake","Freeway","Snow","Castle","Fruit","Stage","Cave","Golf","Cheese","Halloween"}
local totalHedgehogs = 0
local HH = {}
local teams = {}
local dummyHog = nil


function onGameInit()
    Theme = themes[GetRandom(#themes)+1]
    -- Ensure people get same map for same theme
    Seed = ""
    TurnTime = MAX_TURN_TIME
    EnableGameFlags(gfOneClanMode)
    DisableGameFlags(gfBottomBorder+gfBorder)
    CaseFreq = 0
    Explosives = 0
    MineDudPercent = 0
    Map = "ClimbHome"
    AddMissionTeam(-1)
    player = AddMissionHog(1)
    if showWaterStats then
        dummyHog = AddHog(" ", 0, 1, "NoHat")
        HH[dummyHog] = nil
        totalHedgehogs = totalHedgehogs - 1
        SendStat(siClanHealth, tostring(32640), " ")
    end
end

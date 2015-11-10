HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

local gravity = 100
local mingravity
local maxgravity
local delta = 0
local period
local periodtimer = 0
local wdGameTicks = 0
local wdTTL = 0
local mln = 1000000

local script2_onNewTurn
local script2_onGameTick20
local script2_onGameStart


function grav_onNewTurn()
    if delta ~= nil and period == nil then 
      SetGravity(gravity)
    else
      SetGravity(div(gravity, mln))
    end
    
    wdGameTicks = GameTime
    
    if script2_onNewTurn ~= nil then
        script2_onNewTurn()
    end    
end

function grav_onGameTick20()
    if wdGameTicks + 15000 < GameTime then
        SetGravity(100)
    else
        if wdTTL ~= TurnTimeLeft then
            wdGameTicks = GameTime
        end

        if delta == nil then
            if periodtimer == 0 then
                periodtimer = period * 2
                SetGravity(div(GetRandom(maxgravity - mingravity + 1) + mingravity, mln))
            else
                periodtimer = periodtimer - 1
            end
        elseif delta == 0 then
            SetGravity(gravity)
        else
            if delta > 0 and gravity + delta > maxgravity then
                gravity = maxgravity
                delta = -delta
            elseif delta < 0 and gravity + delta < mingravity then
                gravity = mingravity
                delta = -delta
            else
                gravity = gravity + delta
            end

            SetGravity(div(gravity, mln))
        end
    end

    wdTTL = TurnTimeLeft
    
    if script2_onGameTick20 ~= nil then
        script2_onGameTick20()
    end    
end

function onParameters()
    parseParams()

    gravity = params["g"]

    mingravity = gravity
    maxgravity = params["g2"]
    period = params["period"]

    if mingravity ~= nil and maxgravity ~= nil then
        if period ~= nil then
            period = div(period, 40)
        else
            period = 125
        end

        mingravity = mingravity * mln
        maxgravity = maxgravity * mln

        -- note: mingravity and maxgravity MUST NOT be strings at this point
        if mingravity > maxgravity then
            mingravity, maxgravity = maxgravity, mingravity
        end

        gravity = mingravity

        if period > 0 then
            delta = div(maxgravity - mingravity, period)
        else
            period = -period
            delta = nil
        end
    end

    if gravity == nil then
        gravity = 100
    end
    
    secondScript = params["script2"]
    
    if secondScript ~= nil then
        onParameters = nil
        HedgewarsScriptLoad("/Scripts/Multiplayer/" .. secondScript .. ".lua")
        
        script2_onNewTurn = onNewTurn
        script2_onGameTick20 = onGameTick20
        script2_onGameStart = onGameStart
                
        if onParameters ~= nil then
            onParameters()
        end
    end
    
    onNewTurn = grav_onNewTurn
    onGameTick20 = grav_onGameTick20
    onGameStart = grav_onGameStart
end

function grav_onGameStart()
    if delta == nil then
        v = string.format(loc("random in range from %i%% to %i%% with period of %i msec"), div(mingravity, mln), div(maxgravity, mln), period * 40)
    elseif period ~= nil then
        v = string.format(loc("changing range from %i%% to %i%% with period of %i msec"), div(mingravity, mln), div(maxgravity, mln), period * 40)
    else
        v = gravity .. "%"
    end

    ShowMission(loc("Gravity"),
                loc("Current setting is ") .. v,
                loc("Setup:|'g=150', where 150 is 150% of normal gravity") .. "|"
                .. loc("or 'g=50, g2=150, period=4000' for gravity changing|from 50 to 150 and back with period of 4000 msec")
                .. "||" .. loc("Set period to negative value for random gravity"),
                0, 5000)
                
    if script2_onGameStart ~= nil then
        script2_onGameStart()
    end
end



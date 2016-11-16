HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

local gravity = 100
local mingravity
local maxgravity
local mingravity_normal
local maxgravity_normal
local mingravity_low
local maxgravity_low
local delta = 0
local period
local periodtimer = 0
local wdGameTicks = 0
local wdTTL = 0
local mln = 1000000
local lowGravityUsed = false

local script2_onNewTurn
local script2_onGameTick20
local script2_onGameInit
local script2_onHogAttack


function grav_onNewTurn()
    lowGravityUsed = false
    if maxgravity_normal == nil then
        gravity = mingravity_normal
    else
        mingravity = mingravity_normal
        maxgravity = maxgravity_normal
        if period > 0 then
           delta = div(maxgravity_normal - mingravity_normal, period)
        end
    end
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

    gravity = tonumber(params["g"]) or gravity

    mingravity_normal = gravity
    if mingravity_normal > 0 then
        mingravity_low = div(mingravity_normal, 2)
    else
        mingravity_low = mingravity_normal * 2
    end
    mingravity = mingravity_normal
    if type(tonumber(params["g2"])) == "number" then
        maxgravity_normal = tonumber(params["g2"])
        if maxgravity_normal > 0 then
            maxgravity_low = div(maxgravity_normal, 2)
        else
            maxgravity_low = maxgravity_normal * 2
        end
        maxgravity = maxgravity_normal
    end
    period = params["period"]

    if type(mingravity) == "number" and type(maxgravity) == "number" then
        if period ~= nil then
            period = div(period, 40)
        else
            period = 125
        end

        mingravity = mingravity * mln
        mingravity_normal = mingravity_normal * mln
        mingravity_low = mingravity_low * mln
        maxgravity = maxgravity * mln
        maxgravity_normal = maxgravity_normal * mln
        maxgravity_low = maxgravity_low * mln

        if mingravity > maxgravity then
            mingravity, maxgravity = maxgravity, mingravity
            mingravity_normal, maxgravity_normal = maxgravity_normal, mingravity_normal
            mingravity_low, maxgravity_low = maxgravity_low, mingravity_low
        end

        gravity = mingravity

        if period > 0 then
            delta = div(maxgravity_normal - mingravity_normal, period)
        else
            period = -period
            delta = nil
        end
    end
    
    secondScript = params["script2"]
    
    if secondScript ~= nil then
        onParameters = nil
        HedgewarsScriptLoad("/Scripts/Multiplayer/" .. secondScript .. ".lua")
        
        script2_onNewTurn = onNewTurn
        script2_onGameTick20 = onGameTick20
        script2_onGameInit = onGameInit
        script2_onHogAttack = onHogAttack
                
        if onParameters ~= nil then
            onParameters()
        end
    end
    
    onNewTurn = grav_onNewTurn
    onGameTick20 = grav_onGameTick20
    onGameInit = grav_onGameInit
    onHogAttack = grav_onHogAttack
end

function grav_onGameInit()
    DisableGameFlags(gfLowGravity)

    local v, printperiod
    if period ~= nil then
        local period_ms = period * 40
        if period_ms % 1000 == 0 then
            printperiod = string.format(loc("%i s"), div(period_ms, 1000))
        else
            printperiod = string.format(loc("%i ms"), period_ms)
        end
    end
    if delta == nil then
        v = string.format(loc("Crazy Gravity: Gravity randomly changes within a range from %i%% to %i%% with a period of %s"), div(mingravity_normal, mln), div(maxgravity_normal, mln), printperiod)
    elseif period ~= nil then
        v = string.format(loc("Oscillating Gravity: Gravity periodically changes within a range from %i%% to %i%% with a period of %s"), div(mingravity_normal, mln), div(maxgravity_normal, mln), printperiod)
    elseif gravity > 100 then
        v = string.format(loc("High Gravity: Gravity is %i%%"), gravity)
    elseif gravity < 100 then
        v = string.format(loc("Low Gravity: Gravity is %i%%"), gravity)
    else
        v = loc("Gravity: 100%") .. "|" ..
            loc("Script parameter examples:") .. "|" ..
            loc("“g=150”, where 150 is 150% of normal gravity.") .. "|" ..
            loc("“g=50, g2=150, period=4000” for gravity changing|from 50 to 150 and back with period of 4000 ms.") .. "|" ..
            loc("Set period to negative value for random gravity.") .. "| |"
    end
    Goals = v

    if script2_onGameInit ~= nil then
        script2_onGameInit()
    end
end

function grav_onHogAttack(ammoType)
    if ammoType == amLowGravity then
        lowGravityUsed = true
        if maxgravity_normal == nil then
            gravity = mingravity_low
        else
            mingravity = mingravity_low
            maxgravity = maxgravity_low
            if period > 0 then
                delta = div(maxgravity_low - mingravity_low, period)
            end
        end
    end
    if script2_onHogAttack ~= nil then
        script2_onHogAttack()
    end
end

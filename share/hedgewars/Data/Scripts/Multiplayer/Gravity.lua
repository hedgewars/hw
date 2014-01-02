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

function onNewTurn()
    SetGravity(gravity)
    wdGameTicks = GameTime
end

function onGameTick20()
    if wdGameTicks + 15000 < GameTime then
        SetGravity(100)
    else
        if wdTTL ~= TurnTimeLeft then
            wdGameTicks = GameTime
        end

        if delta == nil then
            if periodtimer == 0 then
                periodtimer = period * 2
                SetGravity(div(GetRandom(maxgravity - mingravity) + mingravity, mln))
            else
                periodtimer = periodtimer - 1
            end
        elseif delta == 0 then
            SetGravity(gravity)
        else
            if delta > 0 and gravity + delta > maxgravity then
                gravity = maxgravity
                delta = -delta
            elseif delta < 0 and gravity - delta < mingravity then
                gravity = mingravity
                delta = -delta
            else
                gravity = gravity + delta
            end

            SetGravity(div(gravity, mln))
        end
    end

    wdTTL = TurnTimeLeft
end

function onGameInit()
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

        if mingravity > maxgravity then
            mingravity, maxgravity = maxgravity, mingravity
        end

        mingravity = mingravity * mln
        maxgravity = maxgravity * mln
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
end

function onGameStart()
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
end

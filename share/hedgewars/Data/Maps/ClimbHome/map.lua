HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")

local hTag = nil
local hTagHeight = 33000
local tTag = nil
local rTag = nil
local startTime = 0
local MaxHeight = 32640
local RecordHeight = 33000
local Fire = {}
--local BoomFire = nil
local HH = {}
local MrMine -- in honour of sparkle's first arrival in the cabin
local YouWon = false
local WaterRise = nil
local Cake = nil
local CakeWasJustAdded = false
local CakeTries = 0
local Stars = {}

function onGameInit()
    -- Ensure people get same map for same theme
    TurnTime = 999999999
    CaseFreq = 0
    Explosives = 0
    MineDudPercent = 0
    DisableGameFlags(gfBottomBorder+gfBorder)
    --This reduced startup time by only about 15% and looked ugly
    --EnableGameFlags(gfDisableLandObjects) 
    -- force seed instead.  Some themes will still be easier, but at least you won't luck out on the same theme
    Seed = ClimbHome
end

function onGearAdd(gear)
    if GetGearType(gear) == gtHedgehog then
        HH[gear] = 1
    end
end

function onGearDelete(gear)
    if gear == MrMine then
        AddCaption("Once you set off the proximity trigger, Mr. Mine is not your friend",0xffffff,0)
        MrMine = nil
    elseif gear == Cake then
        Cake = nil
    end
end

function onGameStart()
    ShowMission(loc("Climb Home"),
                loc("Rope to safety"),
                loc("You are far from home, and the water is rising, climb up as high as you can!"),
                -amRope, 0)
    local x = 1818
    for h,i in pairs(HH) do
       -- SetGearPosition(h,x,32549)
        SetGearPosition(h,x,108)
        SetHealth(h,1)
        if x < 1978 then x = x+32 else x = 1818 end
        SetState(h,bor(GetState(h),gstInvisible))
    end
-- 1925,263 - Mr. Mine position
    MrMine = AddGear(1925,263,gtMine,0,0,0,0)
end
function onAmmoStoreInit()
    SetAmmo(amRope, 9, 0, 0, 0)
end

function onNewTurn()
    startTime = GameTime
    --disable to preserve highest over multiple turns
    --will need to change water check too ofc
    MaxHeight = 32640
    hTagHeight = 33000
    SetWaterLine(32768)
    if CurrentHedgehog ~= nil then
        SetGearPosition(CurrentHedgehog, 1951,32640)
        AddVisualGear(19531,32640,vgtExplosion,0,false)
        SetState(CurrentHedgehog,band(GetState(CurrentHedgehog),bnot(gstInvisible)))
    end
    for f,i in pairs(Fire) do
        DeleteGear(f)
    end
    for s,i in pairs(Stars) do
        DeleteVisualGear(s)
        Stars[s] = nil
    end

    for i = 0,12 do
        flame = AddGear(2000+i*2,308, gtFlame, gsttmpFlag,  0, 0, 0)
        SetTag(flame, 999999+i)
        Fire[flame]=1
    end
    if Cake ~= nil then DeleteGear(Cake) end
    CakeTries = 0
end

--function onGearDelete(gear)
--    if gear == WaterRise and MaxHeight > 500 and CurrentHedgehog ~= nil and band(GetState(CurrentHedgehog),gstHHDriven) ~= 0 then
--        WaterRise = AddGear(0,0,gtWaterUp, 0, 0, 0, 0)
--    end
--end

function FireBoom(x,y,d) -- going to add for rockets too
    AddVisualGear(x,y,vgtExplosion,0,false)
    -- going to approximate circle by removing corners
    if BoomFire == nil then BoomFire = {} end
    for i = 0,50 do
        flame = AddGear(x+GetRandom(d),y+GetRandom(d), gtFlame, gsttmpFlag,  0, 0, 0)
        SetTag(flame, 999999+i)
        Fire[flame]=1
--        BoomFire[flame]=1
    end
end


function onGameTick20()
    if math.random(20) == 1 then
        AddVisualGear(2012,56,vgtSmoke,0,false)
    end
    if CakeWasJustAdded then
        FollowGear(CurrentHedgehog)
        CakeWasJustAdded = false
    end
    --if BoomFire ~= nil then
    --    for f,i in pairs(BoomFire) do
    --        if band(GetState(f),gstCollision~=0) then DeleteGear(f) end
    --    end
    --    BoomFire = nil
    --end

    for s,i in pairs(Stars) do
        g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(s)
        if g1 > WaterLine + 500 then
            DeleteVisualGear(s)
            Stars[s] = nil
        end
        --else  wasn't really visible, pointless.
        --    g5 = g5+1
        --    if g5 > 360 then g5 = 0 end
        --    SetVisualGearValues(s, g1, g2, g3, g4, g5, g6, g7, g8, g9, g10)
        --end
    end

    if Cake ~= nil and CurrentHedgehog ~= nil then
        local cx,cy = GetGearPosition(Cake)
        local x,y = GetGearPosition(CurrentHedgehog)
        if y < cy-1500 then
            DeleteGear(Cake)
            Cake = nil
        end
        if gearIsInCircle(CurrentHedgehog,cx,cy,450) then
            FireBoom(cx,cy,350) -- todo animate
            DeleteGear(Cake)
            Cake = nil
        end
    end

    if CurrentHedgehog ~= nil and TurnTimeLeft > 0 and band(GetState(CurrentHedgehog),gstHHDriven) ~= 0 then
        if MaxHeight < 32000 and MaxHeight > 286 and WaterLine > 286  then SetWaterLine(WaterLine-2) end
        local x,y = GetGearPosition(CurrentHedgehog)
        if y > 0 and y < 30000 and MaxHeight > 286 and math.random(y) < 500 then
            local s = AddVisualGear(0, 0, vgtStraightShot, 0, true)
            local c = div(250000,y)
            if c > 255 then c = 255 end
            c = c * 0x10000 + 0xFF0000FF
            SetVisualGearValues(s,
                math.random(2048), -5000, 0, -1-(1/y*1000), 
                math.random(360),
                0,
                999999999, -- frameticks
                171, -- star
                0, c)
                --,  0xFFCC00FF) -- could be fun to make colour shift as you rise...
            Stars[s] = 1
        end    
    end
    
    if CurrentHedgehog ~= nil and band(GetState(CurrentHedgehog),gstHHDriven) == 0 then
        for f,i in pairs(Fire) do -- takes too long to fall otherwise
            DeleteGear(f)
        end
        if Cake ~= nil then
            DeleteGear(Cake)
            Cake = nil
        end
    end

    if GameTime % 500 == 0 and CurrentHedgehog ~= nil and TurnTimeLeft > 0 then
        --if isSinglePlayer and MaxHeight < 32000 and WaterRise == nil then
        --    WaterRise = AddGear(0,0,gtWaterUp, 0, 0, 0, 0)
        --end
        if isSinglePlayer and not YouWon and gearIsInBox(CurrentHedgehog, 1920, 252, 50, 50) then
            ShowMission(loc("Climb Home"),
                        loc("Made it!"),
                        string.format(loc("AHHh, home sweet home.  Made it in %d seconds."),(GameTime-startTime)/1000),
                        -amRope, 0)
            PlaySound(sndVictory,CurrentHedgehog)
            EndGame()
            YouWon = true
        end

        local x,y = GetGearPosition(CurrentHedgehog)
        if CakeTries < 10 and y < 32600 and y > 3000 and Cake == nil and band(GetState(CurrentHedgehog),gstHHDriven) ~= 0 then 
            -- doing this just after the start the first time to take advantage of randomness sources
            -- there's a small chance it'll jiggle the camera though, so trying not to do it too often
            -- Pick a clear y to start with
            if y > 31000 then cy = 24585 elseif
               y > 28000 then cy = 21500 elseif
               y > 24000 then cy = 19000 elseif
               y > 21500 then cy = 16000 elseif
               y > 19000 then cy = 12265 elseif
               y > 16000 then cy =  8800 elseif
               y > 12000 then cy =  5700 else
               cy = 400 end
            Cake = AddGear(GetRandom(2048), cy, gtCake, 0, 0, 0, 0)
            SetHealth(Cake,999999)
            CakeWasJustAdded = true
            CakeTries = CakeTries + 1  -- just try twice right now
        end
        if (y > 286) or (y < 286 and MaxHeight > 286) then
            if y < MaxHeight and y > 286 then MaxHeight = y end
            if y < 286 then MaxHeight = 286 end
            if MaxHeight < hTagHeight then
                hTagHeight = MaxHeight
                if hTag ~= nil then DeleteVisualGear(hTag) end
                hTag = AddVisualGear(0, 0, vgtHealthTag, 0, true)
                local g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(hTag)
                -- snagged from space invasion
                SetVisualGearValues (
                        hTag,        --id
                        -(ScreenWidth/2) + 40, --xoffset
                        ScreenHeight - 60, --yoffset
                        0,          --dx
                        0,          --dy
                        1.1,        --zoom
                        1,          --~= 0 means align to screen
                        g7,         --frameticks
        -- 116px off bottom for lowest rock, 286 or so off top for position of chair
        -- 32650 is "0"
                        32640-hTagHeight,    --value
                        99999999999,--timer
                        GetClanColor(GetHogClan(CurrentHedgehog))
                        )
            end
            if MaxHeight < RecordHeight then
                RecordHeight = MaxHeight
                if rTag ~= nil then DeleteVisualGear(rTag) end
                rTag = AddVisualGear(0, 0, vgtHealthTag, 0, true)
                local g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(hTag)
                -- snagged from space invasion
                SetVisualGearValues (
                        rTag,        --id
                        -(ScreenWidth/2) + 100, --xoffset
                        ScreenHeight - 60, --yoffset
                        0,          --dx
                        0,          --dy
                        1.1,        --zoom
                        1,          --~= 0 means align to screen
                        g7,         --frameticks
        -- 116px off bottom for lowest rock, 286 or so off top for position of chair
        -- 32650 is "0"
                        32640-RecordHeight,    --value
                        99999999999,--timer
                        GetClanColor(GetHogClan(CurrentHedgehog))
                        )
            end
        end
        if MaxHeight > 286 then
            if tTag ~= nil then DeleteVisualGear(tTag) end
            tTag = AddVisualGear(0, 0, vgtHealthTag, 0, true)
            local g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(tTag)
            -- snagged from space invasion
            SetVisualGearValues (
                    tTag,        --id
                    -(ScreenWidth/2) + 40, --xoffset
                    ScreenHeight - 100, --yoffset
                    0,          --dx
                    0,          --dy
                    1.1,        --zoom
                    1,          --~= 0 means align to screen
                    g7,         --frameticks
                    (GameTime-startTime)/1000,    --value
                    99999999999,--timer
                    0xffffffff
                    )
        end
    end
end

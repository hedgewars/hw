HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Utils.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

local hTag = nil
local hTagHeight = 33000
local tTag = nil
local rTag = nil
local startTime = 0
local MaxHeight = 32640
local RecordHeight = 33000
local RecordHeightHogName = nil
local Fire = {}
--local BoomFire = nil
local HH = {}
local totalHedgehogs = 0
local deadHedgehogs = 0
local currTeam = ''
local teams = {}
local teamScoreStats = {}
local teamBests = {}
local teamTimes = {}
local MrMine -- in honour of sparkle's first arrival in the cabin
local YouWon = false
local YouLost = false
local HogsAreInvulnerable = false
local WaterRise = nil
local Cake = nil
local CakeWarning = false
local CakeFireWarning = false
local CakeTries = 0
local addCake = true
local takeASeat = false
local Stars = {}
local tauntNoo = false
local jokeAwardNavy = nil
local jokeAwardSpeed = nil
local jokeAwardDamage = nil
local recordBroken = false
local dummyHog = nil
local dummySkip = 0
local baseWaterSpeed = 2
local waterSpeed = 0
local waterAccel = 0
local delayHeight = 32000
local delayTime = 0
local airMineX = {}
local airMineY = {}
local airMine = {}
local init = true
local multiplayerVictoryDelay = -1
local multiplayerWinningHogs = {}
local multiplayerWins = 0
local racing = false

-- Placement positions of winning hogs
local victoryPosses = { }
do
    local m = 0
    for y=108, 39, -32 do
        for x=1820+m, 1972-m, 22 do
            table.insert(victoryPosses, {x=x, y=y})
        end
        m = m + 32
    end
end

function onParameters()
    parseParams()

    if params["speed"] ~= nil then
        baseWaterSpeed = params["speed"]
    end
    if params["accel"] ~= nil then
        waterAccel = params["accel"]
        if waterAccel ~= 0 then waterAccel = div(32640000,waterAccel) end
    end
    if params["delaytime"] ~= nil then
        delayTime = params["delaytime"]
    end
    if params["delayheight"] ~= nil then
        delayHeight = 32768-params["delayheight"]
    end
    if params["nocake"] ~= nil then addCake = false end
end

function onGameInit()
    -- Ensure people get same map for same theme
    TurnTime = 999999999
    CaseFreq = 0
    Explosives = 0
    MineDudPercent = 0
    EnableGameFlags(gfOneClanMode)
    DisableGameFlags(gfBottomBorder+gfBorder)
    --This reduced startup time by only about 15% and looked ugly
    --EnableGameFlags(gfDisableLandObjects) 
    -- force seed instead.  Some themes will still be easier, but at least you won't luck out on the same theme
    Seed = ClimbHome
    -- Disable Sudden Death
    WaterRise = 0
    HealthDecrease = 0
end

function onGearAdd(gear)
    if GetGearType(gear) == gtHedgehog then
        HH[gear] = 1
        totalHedgehogs = totalHedgehogs + 1
        teams[GetHogTeamName(gear)] = 1
    elseif init and GetGearType(gear) == gtAirMine then
        airMine[gear] = 1
    end
end

function onGearDelete(gear)
    if gear == MrMine then
        AddCaption(loc("Once you set off the proximity trigger, Mr. Mine is not your friend"), capcolDefault, capgrpMessage2)
        MrMine = nil
    elseif GetGearType(gear) == gtCake then
        Cake = nil
        CakeWarning = false
    elseif GetGearType(gear) == gtHedgehog then
	onGameTick20()
	onGearDamage(gear, 0)
        HH[gear] = nil
    end
end

function onGameStart()
    --SetClanColor(ClansCount-1, 0x0000ffff) appears to be broken
    SendHealthStatsOff()
    ShowMission(loc("Climb Home"),
                loc("Challenge"),
                loc("You are far from home, and the water is rising, climb up as high as you can!|Your score will be based on your height."),
                -amRope, 0)
    local x = 1818
    for h,i in pairs(HH) do
        if h ~= nil then
            -- SetGearPosition(h,x,32549)
            SetGearPosition(h,x,108)
            SetHealth(h,1)
            if x < 1978 then x = x+32 else x = 1818 end
            if GetEffect(h,heInvulnerable) == 0 then
                SetEffect(h,heInvulnerable,1)
            else
                HogsAreInvulnerable = true
            end
            SetState(h,bor(GetState(h),gstInvisible))
        end
    end
-- 1925,263 - Mr. Mine position
    MrMine = AddGear(1925,263,gtMine,0,0,0,0)
    for i=0, TeamsCount-1 do
        SetTeamLabel(GetTeamName(i), "0")
    end
end

function onAmmoStoreInit()
    SetAmmo(amRope, 9, 0, 0, 0)
end

function onNewTurn()
    if init then
        init = false
        for a,i in pairs(airMine) do
            x,y = GetGearPosition(a)
            airMineX[a] = x
            airMineY[a] = y
        end
    else
        for a,i in pairs(airMine) do
            local x,y = GetGearPosition(a)
            if not x or airMineX[a] ~= x or airMineY[a] ~= y then
                DeleteGear(a)
                AddGear(airMineX[a],airMineY[a], gtAirMine, gsttmpFlag, 0, 0, 0)
            end
        end
    end
        
    startTime = GameTime
    --disable to preserve highest over multiple turns
    --will need to change water check too ofc
    MaxHeight = 32640
    hTagHeight = 33000
    SetWaterLine(32768)
    YouWon = false
    YouLost = false
    tauntNoo = false
    takeASeat = false
    recordBroken = false
    currTeam = GetHogTeamName(CurrentHedgehog)
    if CurrentHedgehog ~= nil then
        if CurrentHedgehog ~= dummyHog or multiplayerWinningHogs[CurrentHedgehog] == true then
            SetGearPosition(CurrentHedgehog, 1951,32640)
            HogTurnLeft(CurrentHedgehog, true)
            if not HogsAreInvulnerable then SetEffect(CurrentHedgehog,heInvulnerable,0) end
            AddVisualGear(1951,32640,vgtExplosion,0,false)
            SetState(CurrentHedgehog,band(GetState(CurrentHedgehog),bnot(gstInvisible)))
            SetWeapon(amRope)
        else
            dummySkip = GameTime+1
        end
    end
    for hog, _ in pairs(multiplayerWinningHogs) do
        SetEffect(hog, heInvulnerable, 1)
    end
    for f,i in pairs(Fire) do
        DeleteGear(f)
    end
    for s,i in pairs(Stars) do
        DeleteVisualGear(s)
        Stars[s] = nil
    end

    if CurrentHedgehog ~= dummyHog then
        for i = 0,12 do
            flame = AddGear(2000+i*2,308, gtFlame, gsttmpFlag,  0, 0, 0)
            SetTag(flame, 999999+i)
            Fire[flame]=1
        end
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
    PlaySound(sndExplosion)
    AddVisualGear(x,y,vgtExplosion,0,false)
    -- should approximate circle by removing corners
    --if BoomFire == nil then BoomFire = {} end
    for i = 0,50 do
	fx = GetRandom(d)-div(d,2)
	fy = GetRandom(d)-div(d,2)
	if fx<0 then
	   fdx = -5000-GetRandom(3000)
	else
	   fdx = 5000+GetRandom(3000)
	end
	if fy<0 then
	   fdy = -5000-GetRandom(3000)
	else
	   fdy = 5000+GetRandom(3000)
	end
        flame = AddGear(x+fx, y+fy, gtFlame, gsttmpFlag,  fdx, fdy, 0)
        SetTag(flame, 999999+i)
        SetFlightTime(flame, 0)
        Fire[flame]=1
--        BoomFire[flame]=1
    end
end


function onGameTick20()
    local x,y

    if math.random(20) == 1 then AddVisualGear(2012,56,vgtSmoke,0,false) end
    if CurrentHedgehog == dummyHog and dummySkip ~= 0 and dummySkip < GameTime then
        SkipTurn()
        dummySkip = 0
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

    -- This will be executed if a player reached home in multiplayer
    if multiplayerVictoryDelay > 0 then
        multiplayerVictoryDelay = multiplayerVictoryDelay - 20
        if multiplayerVictoryDelay <= 0 then
            -- If delay's over, the game will continue with the next hog
            if CurrentHedgehog then

                multiplayerWinningHogs[CurrentHedgehog] = true
                multiplayerWins = multiplayerWins + 1

                local victoryX, victoryY
                if multiplayerWins <= #victoryPosses then
                    victoryX, victoryY = victoryPosses[multiplayerWins].x, victoryPosses[multiplayerWins].y
                else
                    victoryX, victoryY = victoryPosses[#victoryPosses].x, victoryPosses[#victoryPosses].y
                end
                SetGearPosition(CurrentHedgehog, victoryX, victoryY)
                SetEffect(CurrentHedgehog, heInvulnerable, 1)
                SetHealth(CurrentHedgehog, 1)

                if (deadHedgehogs + multiplayerWins) >= totalHedgehogs then
                    makeFinalMultiPlayerStats()
                    EndGame()
                    onAchievementsDeclaration()
                else
                    EndTurn(true)
                    SetInputMask(0xFFFFFFFF)
                end
                return
            end
        end
    end

    if CurrentHedgehog ~= nil then
        x,y = GetGearPosition(CurrentHedgehog)
        if Cake ~= nil then
            local cx,cy = GetGearPosition(Cake)
            if y < cy-1500 then DeleteGear(Cake) end

            if Cake ~= nil and GetHealth(Cake) < 999980 then
                if not CakeWarning and gearIsInCircle(CurrentHedgehog,cx,cy,1350) then
                    AddCaption(loc("Warning: Fire cake detected"))
                    CakeWarning = true
                end
                if gearIsInCircle(CurrentHedgehog,cx,cy,450) then
                    if not CakeFireWarning then
                        AddCaption(loc("Don't touch the flames!"))
                        CakeFireWarning = true
                    end
                    FireBoom(cx,cy,200) -- todo animate
                    DeleteGear(Cake)
                end
            end
        end
        if band(GetState(CurrentHedgehog),gstHHDriven) == 0 then
            for f,i in pairs(Fire) do -- takes too long to fall otherwise
                DeleteGear(f)
            end
            if Cake ~= nil then
                DeleteGear(Cake)
            end
        end
     end
    

    if CurrentHedgehog ~= nil and TurnTimeLeft > 0 and band(GetState(CurrentHedgehog),gstHHDriven) ~= 0 then
        if MaxHeight < delayHeight and
           TurnTimeLeft<(999999999-delayTime) and 
            MaxHeight > 286 and WaterLine > 286 then
            if waterAccel ~= 0 then
                SetWaterLine(WaterLine-(baseWaterSpeed+div(getActualHeight(MaxHeight)*100,waterAccel)))
            else
                SetWaterLine(WaterLine-baseWaterSpeed)
            end
        end
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
                sprStar, -- star
                0, c)
                --,  0xFFCC00FF) -- could be fun to make colour shift as you rise...
            Stars[s] = 1
        end

        local vx, vy = GetGearVelocity(CurrentHedgehog)
        local distanceFromWater = WaterLine - y
	
        --[[ check joke awards ]]
        -- navy award: when distance from main map is over 1000
        local navyDistance = 1250
        if x < -navyDistance or x > LAND_WIDTH+navyDistance then
            local awarded = false
            local dist = 0
            if jokeAwardNavy == nil then
                awarded = true
            else
                if x < 0 then
                    dist = math.abs(x)
                else
                    dist = x - LAND_WIDTH
                end
                if dist > jokeAwardNavy.distance then
                    awarded = true
                end
            end
            if awarded == true then
                jokeAwardNavy = {
                    hogName = GetHogName(CurrentHedgehog),
                    teamName = GetHogTeamName(CurrentHedgehog),
                    distance = dist
                }
            end
        end

        -- Speed award for largest distance from water
        if distanceFromWater > 3000 and WaterLine < 32000 then
            local awarded = false
            if jokeAwardSpeed == nil or distanceFromWater > jokeAwardSpeed.distance then
                awarded = true
            end
            if awarded == true then
                jokeAwardSpeed = {
                    hogName = GetHogName(CurrentHedgehog),
                    teamName = GetHogTeamName(CurrentHedgehog),
                    distance = distanceFromWater
                }
            end
        end

        local finishTime = (GameTime-startTime)/1000
        local roundedFinishTime = math.ceil(math.floor(finishTime+0.5))
        if isSinglePlayer then
            if distanceFromWater < 0 and not YouLost and not YouWon then
                makeSinglePlayerLoserStats()
                YouLost = true
            end
            -- FIXME: Hog is also in winning box if it just walks into the chair from the left, touching it. Intentional?
            if not YouWon and not YouLost and gearIsInBox(CurrentHedgehog, 1920, 252, 50, 50) then
                AddCaption(loc("Victory!"), capcolDefault, capgrpGameState)
                ShowMission(loc("Climb Home"),
                            loc("Made it!"),
                            string.format(loc("Ahhh, home, sweet home. Made it in %d seconds."), roundedFinishTime),
                            -amRope, 0)
                PlaySound(sndVictory,CurrentHedgehog)
                SetState(CurrentHedgehog, gstWinner)
                SendStat(siGameResult, loc("You have beaten the challenge!"))
                SendStat(siGraphTitle, loc("Your height over time"))
                SendStat(siCustomAchievement, string.format(loc("%s reached home in %.3f seconds. Congratulations!"), GetHogName(CurrentHedgehog), finishTime))
                SendStat(siCustomAchievement, string.format(loc("%s bravely climbed up to a dizzy height of %d to reach home."), GetHogName(CurrentHedgehog), getActualHeight(RecordHeight)))
                SendStat(siPointType, loc("seconds"))
                SendStat(siPlayerKills, tostring(roundedFinishTime), GetHogTeamName(CurrentHedgehog))

                EndGame()
                onAchievementsDeclaration()
                YouWon = true
            end
        else
            if distanceFromWater < 0 and not YouLost and not YouWon then
                makeMultiPlayerLoserStat(CurrentHedgehog)
                deadHedgehogs = deadHedgehogs + 1
                YouLost = true
                if deadHedgehogs >= totalHedgehogs then
                    makeFinalMultiPlayerStats()
                    EndGame()
                    onAchievementsDeclaration()
                end
            end
            -- Check victory
            if not YouWon and not YouLost and gearIsInBox(CurrentHedgehog, 1920, 252, 50, 50) and
                    -- Delay victory if MrMine is triggered
                    (not MrMine or (MrMine and band(GetState(MrMine), gstAttacking) == 0)) then
                -- Player managed to reach home in multiplayer.
                -- Stop hog, disable controls, celebrate victory and continue the game after 4 seconds.
                AddCaption(string.format(loc("%s climbed home in %d seconds!"), GetHogName(CurrentHedgehog), roundedFinishTime), capcolDefault, capgrpGameState)
                SendStat(siCustomAchievement, string.format(loc("%s (%s) reached home in %.3f seconds."), GetHogName(CurrentHedgehog), GetHogTeamName(CurrentHedgehog), finishTime))
                makeMultiPlayerWinnerStat(CurrentHedgehog)
                PlaySound(sndVictory, CurrentHedgehog)
		SetWeapon(amNothing)
                SetGearMessage(CurrentHedgehog, band(GetGearMessage(CurrentHedgehog), bnot(gmLeft+gmRight+gmUp+gmDown+gmHJump+gmLJump+gmPrecise)))
                SetInputMask(0x00)
                -- TODO: Add stupid winner grin.
                multiplayerVictoryDelay = 4000
                YouWon = true
            end
        end

        if GameTime % 500 == 0 then
            if not isSinglePlayer then
	        for t,i in pairs(teams) do
                    if currTeam == t then
                        SendStat(siClanHealth, tostring(getActualHeight(y)), t)
                    else
                        SendStat(siClanHealth, '0', t)
                    end
                end
            else
                SendStat(siClanHealth, tostring(getActualHeight(y)), GetHogTeamName(CurrentHedgehog))
            end
            -- If player is inside home, tell player to take a seat.
            if not takeASeat and gearIsInBox(CurrentHedgehog, 1765, 131, 244, 189) then
                AddCaption(loc("Welcome home! Please take a seat"))
                takeASeat = true
            end
    
            -- play taunts
            if not YouWon and not YouLost then
                local nooDistance = 500
                if ((x < -nooDistance and vx < 0) or (x > LAND_WIDTH+nooDistance and vx > 0)) then
                    if (tauntNoo == false and distanceFromWater > 80) then
                        PlaySound(sndNooo, CurrentHedgehog)
                        tauntNoo = true
                    end
                end
            end

            if addCake and CakeTries < 10 and y < 32600 and y > 3000 and Cake == nil then 
                -- doing this just after the start the first time to take advantage of randomness sources
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
                CakeTries = CakeTries + 1 
            end

            if (y > 286) or (y < 286 and MaxHeight > 286) then
                if MaxHeight > 286 and y <= 286 then
                    -- wow, reached top
                    local teamName = GetHogTeamName(CurrentHedgehog)
                    if teamTimes[teamName] == nil or teamTimes[teamName] > GameTime - startTime then 
                        teamTimes[teamName] = GameTime - startTime 
                    end
                    MaxHeight = 286
                end
                if y < MaxHeight and y > 286 then MaxHeight = y end
                -- New maximum height of this turn?
                if MaxHeight < hTagHeight then
                    hTagHeight = MaxHeight
                    if hTag ~= nil then DeleteVisualGear(hTag) end
                    hTag = AddVisualGear(0, 0, vgtHealthTag, 0, true)
                    local g1, g2, g3, g4, g5, g6, g7, g8, g9, g10 = GetVisualGearValues(hTag)
                    local score = 32640-hTagHeight
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
                            score,    --value
                            99999999999,--timer
                            GetClanColor(GetHogClan(CurrentHedgehog))
                            )
                    local team = GetHogTeamName(CurrentHedgehog)
                    SetTeamLabel(team, math.max(score, teamBests[team] or 0))
                end

                -- New record height?
                if MaxHeight < RecordHeight then
                    RecordHeight = MaxHeight
                    local oldName = RecordHeightHogName
                    RecordHeightHogName = GetHogName(CurrentHedgehog)
                    if oldName == nil then recordBroken = true end
                    if not isSinglePlayer and RecordHeight > 1500 and not recordBroken then
                        recordBroken = true
                        AddCaption(string.format(loc("%s has passed the best height of %s!"), RecordHeightHogName, oldName))
                    end
                    if not isSinglePlayer then
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
                            getActualHeight(RecordHeight),    --value
                            99999999999,--timer
                            GetClanColor(GetHogClan(CurrentHedgehog))
                            )
                    end
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
end

function onGearDamage(gear, damage)
    if GetGearType(gear) == gtHedgehog and not YouLost and not YouWon then
        -- Joke award for largest damage to hog
        local qualifyDamage = 50
        if (damage >= qualifyDamage) then
            local awarded = false
            if jokeAwardDamage == nil or damage > jokeAwardDamage.damage then
                awarded = true
            end
            if awarded == true then
                jokeAwardDamage = {
                    hogName = GetHogName(CurrentHedgehog),
                    teamName = GetHogTeamName(CurrentHedgehog),
                    damage = damage
                }
            end
        end

        if isSinglePlayer then
            makeSinglePlayerLoserStats()
        else
            deadHedgehogs = deadHedgehogs + 1
            makeMultiPlayerLoserStat(gear)
            if (deadHedgehogs + multiplayerWins) >= totalHedgehogs then
                makeFinalMultiPlayerStats()
                EndGame()
                onAchievementsDeclaration()
            end
        end
        YouLost = true
    end
end

function makeLoserComment()
    local m
    if isSinglePlayer then m = 10 else m = 6 end
    local r = math.random(1,m)
    if r == 1 then text = loc("%s never got the ninja diploma.")
    elseif r == 2 then text = loc("You have to move upwards, not downwards, %s!")
    elseif r == 3 then text = loc("%s never wanted to reach for the sky in the first place.")
    elseif r == 4 then text = loc("%s should try the rope training mission first.")
    elseif r == 5 then text = loc("%s skipped ninja classes.")
    elseif r == 6 then text = loc("%s doesn’t really know how to handle a rope properly.")
    elseif r == 7 then text = loc("Better luck next time!")
    elseif r == 8 then text = loc("It was all just bad luck!")
    elseif r == 9 then text = loc("Well, that escalated quickly!")
    elseif r == 10 then text = loc("What? Is it over already?") end
    return text
end

function makeSinglePlayerLoserStats()
    local actualHeight = getActualHeight(RecordHeight)
    SendStat(siGameResult, loc("You lose!"))
    SendStat(siGraphTitle, loc("Your height over time"))
    local text
    if actualHeight > 30000 then text = loc("%s was damn close to home.")
    elseif actualHeight > 28000 then text = loc("%s was close to home.")
    elseif actualHeight > 24265 then text = loc("%s was good, but not good enough.")
    elseif actualHeight > 16177 then text = loc("%s managed to pass half of the distance towards home.")
    elseif actualHeight > 8088 then text = loc("%s went over a quarter of the way towards home.")
    elseif actualHeight > 5100 then text = loc("%s still had a long way to go.")
    elseif actualHeight > 2000 then text = loc("%s made it past the hogosphere.")
    elseif actualHeight > 1500  then text = loc("%s barely made it past the hogosphere.")
    else
        text = makeLoserComment()
    end
    if actualHeight > 1500 then
        SendStat(siCustomAchievement, string.format(text, RecordHeightHogName, actualHeight))
    else
        SendStat(siCustomAchievement, string.format(text, RecordHeightHogName))
    end
    SendStat(siPointType, loc("points"))
    SendStat(siPlayerKills, actualHeight, GetHogTeamName(CurrentHedgehog))
    EndGame()
    onAchievementsDeclaration()
end

function makeMultiPlayerLoserStat(gear)
    local teamName = GetHogTeamName(gear)
    local actualHeight = getActualHeight(MaxHeight)
    if teamBests[teamName] == nil then teamBests[teamName] = actualHeight end
    if teamBests[teamName] < actualHeight then teamBests[teamName] = actualHeight end
    if teamScoreStats[teamName] == nil then teamScoreStats[teamName] = {} end
    table.insert(teamScoreStats[teamName], actualHeight)
    --SendStat(siClanHealth, tostring(teamBests[teamName]), teamName)
end

function makeMultiPlayerWinnerStat(gear)
    return makeMultiPlayerLoserStat(gear)
end

function makeFinalMultiPlayerStats()
    local ranking = {}
    for k,v in pairs(teamBests) do
        table.insert(ranking, {name=k, score=v})
    end
    local comp = function(table1, table2)
        if table1.score < table2.score then
            return true
        else
            return false
        end
    end
    table.sort(ranking, comp)

    local winner = ranking[#ranking]
    local loser = ranking[1]
    SendStat(siGameResult, string.format(loc("%s wins!"), winner.name))
    SendStat(siGraphTitle, string.format(loc("Height over time")))
    
    if winner.score < 1500 then
        SendStat(siCustomAchievement, string.format(loc("This round’s award for ultimate disappointment goes to: Everyone!")))
    else
        if winner.score > 30000 then text = loc("%s (%s) reached for the sky and beyond with a height of %d!")
        elseif winner.score > 24750 then text = loc("%s (%s) was certainly not afraid of heights: Peak height of %d!")
        elseif winner.score > 16500 then text = loc("%s (%s) does not have to feel ashamed for their best height of %d.")
        elseif winner.score > 8250 then text = loc("%s (%s) reached a decent peak height of %d.")
        else text = loc("%s (%s) reached a peak height of %d.") end
        SendStat(siCustomAchievement, string.format(text, RecordHeightHogName, winner.name, winner.score))

        if loser.score < 1500 then
            text = makeLoserComment()
            SendStat(siCustomAchievement, string.format(text, loser.name))
        end
    end
    checkAwards()
    for i = #ranking, 1, -1 do
	SendStat(siPointType, loc("points"))
        SendStat(siPlayerKills, tostring(ranking[i].score), ranking[i].name)
    end
end

function checkAwards()
    if jokeAwardNavy ~= nil then
        if isSinglePlayer then
            SendStat(siCustomAchievement, string.format(loc("The Navy greets %s for managing to get in a distance of %d away from the mainland!"), jokeAwardNavy.hogName, jokeAwardNavy.distance))
        else
            SendStat(siCustomAchievement, string.format(loc("Greetings from the Navy, %s (%s), for being a distance of %d away from the mainland!"), jokeAwardNavy.hogName, jokeAwardNavy.teamName, jokeAwardNavy.distance))
        end
    end
    if jokeAwardSpeed ~= nil then
        if isSinglePlayer then
            SendStat(siCustomAchievement, string.format(loc("Your hedgehog was panicly afraid of the water and decided to go in a safe distance of %d from it."), jokeAwardSpeed.distance))
        else
            SendStat(siCustomAchievement, string.format(loc("%s (%s) was panicly afraid of the water and decided to get in a safe distance of %d from it."), jokeAwardSpeed.hogName, jokeAwardSpeed.teamName, jokeAwardSpeed.distance))
        end
    end
    if jokeAwardDamage ~= nil then
        if isSinglePlayer then
            SendStat(siCustomAchievement, string.format(loc("Ouch! That must have hurt. You mutilated your poor hedgehog hog with %d damage."), jokeAwardDamage.damage))
        else
            SendStat(siCustomAchievement, string.format(loc("Ouch! That must have hurt. %s (%s) hit the ground with %d damage points."), jokeAwardDamage.hogName, jokeAwardDamage.teamName, jokeAwardDamage.damage))
        end
    end
end

function getActualHeight(height)
    return 32640-height
end

function onAchievementsDeclaration()
    for teamname, score in pairs(teamBests) do
        DeclareAchievement("height reached", teamname, "ClimbHome", -score)
    end
    for teamname, score in pairs(teamTimes) do
        DeclareAchievement("rope race", teamname, "ClimbHome", score)
    end
end

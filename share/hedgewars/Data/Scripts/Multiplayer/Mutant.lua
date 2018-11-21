--[[                  ___                   ___
                    (   )                 (   )
___ .-. .-. ___  ___ | |_    .---. ___ .-. | |_
(   )   '   (   )(   (   __) / .-, (   )   (   __)
|  .-.  .-. | |  | | | |   (__) ; ||  .-. .| |
| |  | |  | | |  | | | | ___ .'`  || |  | || | ___
| |  | |  | | |  | | | |(   / .'| || |  | || |(   )
| |  | |  | | |  | | | | | | /  | || |  | || | | |
| |  | |  | | |  ; ' | ' | ; |  ; || |  | || ' | |
| |  | |  | ' `-'  / ' `-' ' `-'  || |  | |' `-' ;
(___)(___)(___'.__.'   `.__.`.__.'_(___)(___)`.__.


----  Recommended settings:
----    * one hedgehog per team
----    * 'Small' one-island map

--]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")
HedgewarsScriptLoad("/Scripts/Params.lua")

--[[
    MUTANT SCRIPT

    To Do:  -Clean-up this fucking piece of code
            -Debug
            -Find a girlfriend
            -Fix Sheepluva's hat  +[p]
            -Cookies
-----------------------]]

local hhs = {}
local crates = {}
local numhhs = 0
local meh = false

local gameOver=false

local mutant = nil
local mutant_base_health = 200
local mutant_base_disease = 25
local disease_timer = 2000

local kill_reward = nil
local mt_hurt=false

local killsCounter = 0

local team_fire_punishment = 3
local mutant_kill_reward = 2

local hh_weapons = { amBazooka, amGrenade, amShotgun, amMine}

local mt_weapons = {amWatermelon, amHellishBomb, amBallgun, amRCPlane, amTeleport}

local disease=0
local timer=0

local winScore = 15
local hogsLimit = 1

local teamsDead = {}

local circles = {}
local circleFrame = -1

-- Variables for custom achievements

-- Most kills in 1 turn
local recordKills = 0
local recordKillsHogName = nil
local recordKillsTeamName = nil

-- Most suicides
local recordSuicides = 0
local recordSuicidesHogName = nil
local recordSuicidesTeamName = nil

-- Most skips
local recordSkips = 0
local recordSkipsHogName = nil
local recordSkipsTeamName = nil

-- Most crates collected
local recordCrates = 0
local recordCratesHogName = nil
local recordCratesTeamName = nil

-- Most deaths
local recordDeaths = 0
local recordDeathsHogName = nil
local recordDeathsTeamName = nil

-- Total killed hedgehogs
local totalKills = 0

-- Total damage
local totalDamage = 0

local mutantHat = "WhySoSerious"
local feederHat = "poke_slowpoke"

function rules()

    local ruleSet = loc("Hedgehogs will be revived after their death.") .. "|" ..
    string.format(loc("Mines explode after %d s."), div(MinesTime, 1000)) .. "|" ..
    loc("The first hedgehog to kill someone becomes the Mutant.") .. "|" ..
    loc("The Mutant has super weapons and a lot of health.") .. "|" ..
    loc("The Mutant loses health quickly, but gains health by killing.") .. "|" ..
    " |" ..
    loc("Score points by killing other hedgehogs.") .. "|" ..
    loc("The hedgehog with least points (or most deaths) becomes the Bottom Feeder.") .. "|" ..
    loc("The score and deaths are shown next to the team bar.") .. "|" ..
    string.format(loc("Goal: Score %d points or more to win!"), winScore) .. "|" ..
        " |" ..
    loc("Scoring: ") .. "|" ..
    loc("+2 for becoming the Mutant") .. "|" ..
    loc("+1 to the Mutant for killing anyone") .. "|" ..
    loc("+1 to the Bottom Feeder for killing anyone") .. "|" ..
    loc("-1 to anyone for a suicide")

    return ruleSet

end

function showStartingInfo()

    ShowMission(loc("Mutant"), loc("A Hedgewars tag game"), rules(), 1, 5000)

end

function onGameInit()
    TurnTime = 20000
    WaterRise = 0
    HealthDecrease = 0
    EnableGameFlags(gfResetWeps, gfPerHogAmmo)
    HealthCaseProb=0
    HealthCaseAmount=0
    MinesTime=1000
    CaseFreq = 2
end


function limitHogs(gear)
    cnthhs = cnthhs + 1
    if cnthhs > 1 then
        hogLimitHit = true
        SetEffect(gear, heResurrectable, 0)
        setGearValue(gear, "excess", true)
        DeleteGear(gear)
    end
end

function onGameStart()
    if ClansCount >= 2 then
        SendHealthStatsOff()
        SendAchievementsStatsOff()
    end
    SendRankingStatsOff()
    trackTeams()
    teamScan()
    runOnHogs(saveStuff)

    hogLimitHit = false
    for i=0 , TeamsCount - 1 do
        cnthhs = 0
        runOnHogsInTeam(limitHogs, GetTeamName(i))
    end
    if hogLimitHit then
        WriteLnToChat(loc("Only one hog per team allowed! Excess hogs will be removed."))
    end
    showStartingInfo()
end



function giveWeapons(gear)
    if gear == mutant then
        AddAmmo(gear, amRope)
        for i=1, #mt_weapons do
            AddAmmo(gear, mt_weapons[i])
        end

    else
        for i=1, #hh_weapons do
            AddAmmo(gear,hh_weapons[i])
        end
    end
end

function onAmmoStoreInit()

    SetAmmo(amSkip, 9, 0, 0, 0)
    SetAmmo(amRope,0,1,0,5)
    SetAmmo(amSnowball,0,1,0,1)

    for i=1, #hh_weapons do
        SetAmmo(hh_weapons[i], 0, 0, 0, 1)
    end

    for i=1, #mt_weapons do
        SetAmmo(mt_weapons[i], 0, 3, 0, 1)
    end

end

function drawCircles()
    for i = 0, #hhs do
        if circles[hhs[i]] ~= nil then
            DeleteVisualGear(circles[hhs[i]])
            circles[hhs[i]] = nil
        end

        if hhs[i] ~= CurrentHedgehog then
            if mutant == nil then
                circles[hhs[i]] = AddVisualGear(0, 0, vgtCircle, 0, false)
                SetVisualGearValues(circles[hhs[i]], 0, 0, 0, 0, 0, 0, 0, 22, 5, 0xff000080)
            elseif CurrentHedgehog == mutant then
                circles[hhs[i]] = AddVisualGear(0, 0, vgtCircle, 0, false)
                SetVisualGearValues(circles[hhs[i]], 0, 0, 0, 0, 0, 0, 0, 22, 3, 0xaa000070)
            elseif getGearValue(CurrentHedgehog, "Feeder") and hhs[i] ~= mutant then
                circles[hhs[i]] = AddVisualGear(0, 0, vgtCircle, 0, false)
                SetVisualGearValues(circles[hhs[i]], 0, 0, 0, 0, 0, 0, 0, 22, 3, 0xaa000070)
            elseif hhs[i] == mutant then
                circles[hhs[i]] = AddVisualGear(0, 0, vgtCircle, 0, false)
                SetVisualGearValues(circles[hhs[i]], 0, 0, 0, 0, 0, 0, 0, 22, 5, 0xff000080)
            end
        end
    end
    circleFrame = 0
end

function onNewTurn()

    trackTeams()
    killsCounter = 0

    if mutant == nil then
        AddCaption( loc("First killer will mutate"), capcolDefault, capgrpGameState )
    end

    checkScore()

    for i=0, TeamsCount-1 do
        SendStat(siClanHealth, getTeamValue(GetTeamName(i), "Score"), GetTeamName(i))
    end

    giveWeapons(CurrentHedgehog)
    drawCircles()
    setAIHints()
    kill_reward= numhhs*10

    if CurrentHedgehog == mutant then
        mt_hurt=true
        disease= mutant_base_disease - numhhs
    else
        mt_hurt=false
    end

    setGearValue(CurrentHedgehog, "Alive", true)

end

function countBodies()
        if killsCounter == 2 then
            AddCaption(loc("Double kill!"), capcolDefault, capgrpGameState )
        elseif killsCounter == 3 then
            AddCaption(loc("Mega kill!"), capcolDefault, capgrpGameState )
            PlaySound(sndRegret)
        elseif killsCounter == 4 then
            AddCaption(loc("Ultra kill!"), capcolDefault, capgrpGameState )
        elseif killsCounter == 5 then
            AddCaption(loc("Monster kill!"), capcolDefault, capgrpGameState )
            PlaySound(sndIllGetYou)
        elseif killsCounter == 6 then
            AddCaption(loc("Ludicrous kill!"), capcolDefault, capgrpGameState )
            PlaySound(sndNutter)
        elseif killsCounter == 7 then
            AddCaption(loc("Holy shit!"), capcolDefault, capgrpGameState )
            PlaySound(sndLaugh)
        elseif killsCounter > 8 then
            AddCaption(loc("Insanity!"), capcolDefault, capgrpGameState )
        end

        if killsCounter > recordKills then
            recordKills = killsCounter
            recordKillsHogName = getGearValue(CurrentHedgehog, "Name")
            recordKillsTeamName = GetHogTeamName(CurrentHedgehog)
        end
end

function onGameTick()

    if circleFrame > -1 then
        for i = 0, #hhs do
            if circles[hhs[i]] ~= nil and hhs[i]~= nil then
                hhx, hhy = GetGearPosition(hhs[i])
                SetVisualGearValues(circles[hhs[i]], hhx + 1, hhy - 3, 0, 0, 0, 0, 0, 40 - (circleFrame % 25))
            end
        end

        circleFrame = circleFrame + 0.06

        if circleFrame >= 25 then
            for i = 0, #hhs do
                if circles[hhs[i]] ~= nil then
                    DeleteVisualGear(circles[hhs[i]])
                    circles[hhs[i]] = nil
                end
            end
        end
    end

    if TurnTimeLeft==0 and mt_hurt then
        mt_hurt = false
    end

    if mt_hurt and mutant~=nil then
        timer = timer + 1
            if timer > disease_timer then
                timer = 0
                SetHealth(mutant, GetHealth(mutant)-disease )
                AddVisualGear(GetX(mutant), GetY(mutant)-5, vgtHealthTag, disease, true)
                    if GetHealth(mutant)<=0 then
                        SetHealth(mutant,0)
                        mt_hurt= false
                        setGearValue(mutant,"SelfDestruct",true)
                        EndTurn()
                    end
            end
    end

end

--[[
Forces the special mutant/feeder names and hats only to be
taken by those who deserved it.
Names and hats will be changed (and ridiculed) if neccesary.
]]
function exposeIdentityTheft(gear)
    local lon = string.lower(GetHogName(gear)) -- lowercase origina name
    local name, hat
    -- Change name if hog uses a reserved one
    if lon == "mutant" or lon == string.lower(loc("Mutant")) then
       SetHogName(gear, loc("Identity Thief"))
       SetHogHat(gear, "Disguise")
    elseif lon == "bottom feeder" or lon == string.lower(loc("Bottom Feeder")) then
       -- Word play on "Bottom Feeder". Someone who is low on cotton. :D
       -- Either translate literally or make up your ow word play
       SetHogName(gear, loc("Cotton Needer"))
       SetHogHat(gear, "StrawHat")
    end
    -- Strip hog off its special hat
    if GetHogHat(gear) == mutantHat or GetHogHat(gear) == feederHat then
       SetHogHat(gear, "NoHat")
    end
end

function saveStuff(gear)
    exposeIdentityTheft(gear)
    setGearValue(gear,"Name",GetHogName(gear))
    setGearValue(gear,"Hat",GetHogHat(gear))
end

function armageddon(gear)
    SetState(gear, gstLoser)
    SetEffect(gear, heResurrectable, 0)
    SetHealth(gear, 0)
end

function renderScores()
    for i=0, TeamsCount-1 do
        local name = GetTeamName(i)
        SetTeamLabel(name, string.format(loc("%d | %d"), getTeamValue(name, "Score"), getTeamValue(name, "DeadHogs")))
    end
end

function createEndGameStats()
    SendStat(siGraphTitle, loc("Score graph"))

    local teamsSorted = {}
    for i=0, TeamsCount-1, 1 do
        teamsSorted[i+1] = GetTeamName(i)
    end

    -- Achievements stuff
    local achievements = 0
    --- Most kills per turn
    if recordKills >= 3 then
        SendStat(siMaxStepKills, string.format("%d %s (%s)", recordKills, recordKillsHogName, recordKillsTeamName))
        achievements = achievements + 1
    end
    --- Most crates collected
    if recordCrates >= 5 then
        SendStat(siCustomAchievement, string.format(loc("%s (%s) was the greediest hedgehog and collected %d crates."), recordCratesHogName, recordCratesTeamName, recordCrates))
        achievements = achievements + 1
    end
    --- Most suicides
    if recordSuicides >= 5 then
        SendStat(siCustomAchievement, string.format(loc("%s (%s) hate life and suicided %d times."), recordSuicidesHogName, recordSuicidesTeamName, recordSuicides))
        achievements = achievements + 1
    end
    --- Most deaths
    if recordDeaths >= 5 then
        SendStat(siCustomAchievement, string.format(loc("Poor %s (%s) died %d times."), recordDeathsHogName, recordDeathsTeamName, recordDeaths))
        achievements = achievements + 1
    end
    --- Most skips
    if recordSkips >= 3 then
        SendStat(siMaxTurnSkips, string.format("%d %s (%s)", recordSkips, recordSkipsHogName, recordSkipsTeamName))
        achievements = achievements + 1
    end
    --- Total damage
    if totalDamage >= 900 then
        SendStat(siCustomAchievement, string.format(loc("%d damage was dealt in this game."), totalDamage))
        achievements = achievements + 1
    end
    --- Total kills
    if totalKills >= 20 or (achievements <= 0 and totalKills >= 1) then
        SendStat(siKilledHHs, tostring(totalKills))
        achievements = achievements + 1
    end

    -- Score and stats stuff
    local showScore = ""
    table.sort(teamsSorted, function(team1, team2) return getTeamValue(team1, "Score") > getTeamValue(team2, "Score") end)
    for i=1, TeamsCount do
        SendStat(siPointType, loc("point(s)"))
        local score = getTeamValue(teamsSorted[i], "Score")
        local deaths = getTeamValue(teamsSorted[i], "DeadHogs")
        SendStat(siPlayerKills, score, teamsSorted[i])

        showScore = showScore .. string.format(loc("%s: %d (deaths: %d)"), teamsSorted[i], score, deaths) .. "|"
    end

    if getTeamValue(teamsSorted[1], "Score") == getTeamValue(teamsSorted[2], "Score") then
        -- The first two teams have the same score! Round is drawn.
        return nil
    else

    ShowMission(loc("Mutant"),
        loc("Final result"),
        string.format(loc("Winner: %s"), teamsSorted[1]) .. "| |" .. loc("Scores:") .. " |" ..
        showScore, 0, 15000)

        -- return winning team
        return teamsSorted[1]
    end
end

function checkScore()
local lowest_score_team = nil
local min_score=nil
local winTeam = nil

local only_low_score = true

    for i=0, TeamsCount-1 do
        local teamName = GetTeamName(i)
        if not teamsDead[teamName] then
            local curr_score = getTeamValue(teamName, "Score")

            runOnHogsInTeam(removeFeeder, teamName)

            if curr_score >= winScore then
                gameOver = true
                winTeam = teamName
            end

            if min_score==nil then
                min_score= curr_score
                lowest_score_team = teamName
            else
                if curr_score <= min_score then
                    if curr_score == min_score then
                        if getTeamValue(teamName, "DeadHogs") == getTeamValue(lowest_score_team, "DeadHogs") then
                            only_low_score = false
                        else
                            if getTeamValue(teamName, "DeadHogs") > getTeamValue(lowest_score_team, "DeadHogs") then
                                lowest_score_team = teamName
                            end
                            only_low_score = true
                        end

                    else
                        min_score= curr_score
                        lowest_score_team = teamName
                        only_low_score = true
                    end
                end
            end
        end
    end

    if gameOver then
        EndTurn(true)

        for i=0, TeamsCount-1 do
            local teamName = GetTeamName(i)
            if teamName~=winTeam then
                runOnHogsInTeam(armageddon, teamName)
            end
        end

        createEndGameStats()
    else

    if only_low_score then
        runOnHogsInTeam(setFeeder, lowest_score_team)
    end

    if meh == false then
        meh = true
    end

    end
end

function backToNormal(gear)
    SetHogName(gear, getGearValue(gear,"Name"))
    SetHogHat(gear, 'NoHat')
    SetHogHat(gear, getGearValue(gear,"Hat"))
    setGearValue(mutant,"SelfDestruct",false)
    mt_hurt=false
    mutant=nil
end

function setAIHints()
    for i = 0, #hhs do
        if mutant == nil or hhs[i] == mutant or CurrentHedgehog == mutant or getGearValue(CurrentHedgehog, "Feeder") then
            SetGearAIHints(hhs[i], aihUsualProcessing)
        else
            SetGearAIHints(hhs[i], aihDoesntMatter)
        end
    end
    for i = 0, #crates do
        if CurrentHedgehog == mutant and crate[i] != nil  then
            SetGearAIHints(crates[i], aihDoesntMatter)
        else
            SetGearAIHints(crates[i], aihUsualProcessing)
        end
    end
end

function removeFeeder(gear)
    if gear~=nil then
        setGearValue(gear,"Feeder",false)
        if gear~= mutant then
            SetHogName(gear, getGearValue(gear,"Name") )
            SetHogHat(gear, 'NoHat')
            SetHogHat(gear, getGearValue(gear,"Hat"))
        end
    end
end

function setFeeder(gear)
    if gear~= mutant and gear~= nil then
        SetHogName(gear, loc("Bottom Feeder"))
        SetHogHat(gear, feederHat)
        setGearValue(gear,"Feeder", true)
    end
end

function setMutantStuff(gear)
    mutant = gear

    SetHogName(gear, loc("Mutant"))
    SetHogHat(gear, mutantHat)
    SetHealth(gear, ( mutant_base_health + numhhs*25) )
    SetEffect(gear, hePoisoned, 1)
    setGearValue(mutant,"SelfDestruct",false)
    setGearValue(gear, "Feeder", false)

    AddCaption(string.format(loc("%s has mutated! +2 points"), getGearValue(gear, "Name")), GetClanColor(GetHogClan(gear)), capgrpMessage)

    if TurnTimeLeft > 0 then
        EndTurn(true)
    end

    AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
    AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
    AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
    AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
    AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
    PlaySound(sndSuddenDeath)
end

function teamScan()

        for j=0, TeamsCount-1 do
            teamName = GetTeamName(j)
            teamsDead[teamName] = false
            setTeamValue(teamName, "Score",0)
            setTeamValue(teamName, "Suicides",0)
            setTeamValue(teamName, "Skips",0)
            setTeamValue(teamName, "Crates",0)
            setTeamValue(teamName, "DeadHogs",0)
        end

        renderScores()

        ---***---
end

function set_Mutant_and_Score(gear)

local curr_team = GetHogTeamName(CurrentHedgehog)

    if gear == CurrentHedgehog then
        if CurrentHedgehog == mutant then
            PlaySound(sndHomerun)
            if getGearValue(gear, "SelfDestruct")==false then
                decreaseTeamValue(curr_team,"Score")
            end
            backToNormal(gear)
        else
            decreaseTeamValue(curr_team,"Score")
        end

    else
            if gear == mutant then
                    backToNormal(mutant)
                    if curr_team ~=GetHogTeamName(gear) then
                            if  getGearValue(CurrentHedgehog, "Alive") then
                            setMutantStuff(CurrentHedgehog)
                            setTeamValue(curr_team,"Score",(getTeamValue(curr_team,"Score") + mutant_kill_reward))
                            end
                    else
                        setTeamValue(curr_team,"Score",(getTeamValue(curr_team,"Score") - team_fire_punishment))
                        increaseTeamValue(curr_team,"Suicides")
                        if(getTeamValue(curr_team, "Suicides") > recordSuicides) then
                            recordSuicides = getTeamValue(curr_team, "Suicides")
                            recordSuicidesHogName = getGearValue(CurrentHedgehog, "Name")
                            recordSuicidesTeamName = curr_team
                        end
                        AddCaption(loc("-1 point"), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage)
                    end
            else
                if mutant==nil then
                        if curr_team ~=GetHogTeamName(gear) then
                            if getGearValue(CurrentHedgehog, "Alive") then
                                    setMutantStuff(CurrentHedgehog)
                                    setTeamValue(curr_team,"Score",(getTeamValue(curr_team,"Score") + mutant_kill_reward))
                            else
                                increaseTeamValue(curr_team,"Score")
                            end
                        else
                            setTeamValue(curr_team,"Score",(getTeamValue(curr_team,"Score") - team_fire_punishment))
                            increaseTeamValue(curr_team,"Suicides")
                            if(getTeamValue(curr_team, "Suicides") > recordSuicides) then
                                recordSuicides = getTeamValue(curr_team, "Suicides")
                                recordSuicidesHogName = getGearValue(CurrentHedgehog, "Name")
                                recordSuicidesTeamName = curr_team
                            end
                            AddCaption(loc("-1 point"), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage)
                        end
                else
                    if curr_team ~=GetHogTeamName(gear) then
                        if CurrentHedgehog==mutant and getGearValue(mutant,"SelfDestruct")==false then
                            HealHog(CurrentHedgehog, kill_reward)
                            AddCaption(loc("+1 point"), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage)
                            increaseTeamValue(curr_team,"Score")
                        end
                        if getGearValue(CurrentHedgehog,"Feeder") then
                            increaseTeamValue(curr_team,"Score")
                            AddCaption(loc("+1 point"), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage)
                        end
                    else
                        setTeamValue(curr_team,"Score",(getTeamValue(curr_team,"Score") - team_fire_punishment))
                        AddCaption(loc("+1 point"), GetClanColor(GetHogClan(CurrentHedgehog)), capgrpMessage)
                    end
                end
            end
    end
end

function onGearResurrect(gear)
if not gameOver then
    if GetGearType(gear) == gtHedgehog then

        increaseTeamValue(GetHogTeamName(gear), "DeadHogs")
        totalKills = totalKills + 1
        if(getTeamValue(GetHogTeamName(gear), "DeadHogs") > recordDeaths) then
            recordDeaths = getTeamValue(GetHogTeamName(gear), "DeadHogs")
            recordDeathsHogName = getGearValue(gear, "Name")
            recordDeathsTeamName = GetHogTeamName(gear)
        end

        if gear==CurrentHedgehog then
            setGearValue(CurrentHedgehog, "Alive", false)
        end
        set_Mutant_and_Score(gear)
        if gear~=CurrentHedgehog then
            killsCounter = killsCounter + 1
            countBodies()
        end
        AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
        PlaySound(sndWhack)
        renderScores()
    end
end
end

function onGearDamage(gear, damage)
    if not gameOver and GetGearType(gear) == gtHedgehog then
        totalDamage = totalDamage + damage
    end
end

function onSkipTurn()
    -- Record skips for achievement
    local team = GetHogTeamName(CurrentHedgehog)
    increaseTeamValue(team, "Skips")
    if(getTeamValue(team, "Skips") > recordSkips) then
        recordSkips = getTeamValue(team, "Skips")
        recordSkipsHogName = getGearValue(CurrentHedgehog, "Name")
        recordSkipsTeamName = team
    end
end

function onGearAdd(gear)

    -- Catch hedgehogs for the tracker
    if GetGearType(gear) == gtHedgehog then
        trackGear(gear)
        hhs[numhhs] = gear
        numhhs = numhhs + 1
        SetEffect(gear, heResurrectable, 1)
    elseif GetGearType(gear) == gtCase then
        crates[#crates] = gear
    elseif GetGearType(gear) == gtATFinishGame then
        if not gameOver then
            local winner = createEndGameStats()
            if winner then
                SendStat(siGameResult, string.format(loc("%s wins!"), winner))
                AddCaption(string.format(loc("%s wins!"), winner), capcolDefault, capgrpGameState)
            end
            gameOver = true
        end
    end
end

function checkEmptyTeam (teamName)
    for i=0 , #hhs do
        if hhs[i]~=nil then
            if teamName == GetHogTeamName(hhs[i]) then
                return false
            end
        end
    end
    return true
end

function onGearDelete(gear)
    -- Remove hogs that are gone
    if GetGearType(gear) == gtHedgehog then
        numhhs = numhhs - 1

        local found
        for i=0, #hhs do
            if hhs[i] == gear then
                found = i
                break
            end
        end
        for i = found, #hhs - 1 do
            hhs[i] = hhs[i + 1]
        end
        hhs[#hhs] = nil

        local t_name = GetHogTeamName(gear)
        if checkEmptyTeam(t_name) then
            for i = 0, TeamsCount - 1 do
                if GetTeamName(i) == t_name then
                    found = i
                    teamsDead[t_name] = true
                    break
                end
            end
        end
        if getGearValue(gear, "excess") ~= true and band(GetState(gear), gstDrowning) == 0 then
            AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
        end
        trackDeletion(gear)
    elseif GetGearType(gear) == gtCase then
        crates[gear] = nil
        -- Check if a crate has been collected
        if band(GetGearMessage(gear), gmDestroy) ~= 0 and CurrentHedgehog ~= nil then
            -- Update crate collection achievement
            increaseTeamValue(GetHogTeamName(CurrentHedgehog), "Crates")
            if(getTeamValue(GetHogTeamName(CurrentHedgehog), "Crates") > recordCrates) then
                recordCrates = getTeamValue(GetHogTeamName(CurrentHedgehog), "Crates")
                recordCratesHogName = getGearValue(CurrentHedgehog, "Name")
                recordCratesTeamName = GetHogTeamName(CurrentHedgehog)
            end
        end
    end
end

function onParameters()
    parseParams()
    winScore = tonumber(params["winscore"]) or winScore
end

--[[
S T A R R I N G
    prof - Coding, implementing and evangelism
    vos  - Initial idea and script improvements
    mikade - Moving the `how to play` into the game so that people know `how to play`, and whitespace :D
--]]

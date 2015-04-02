local MUTANT_VERSION = "v0.9.5"

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

local teams = {}

local circles = {}
local circleFrame = -1

function showStartingInfo()

	ruleSet = loc("RULES") .. ": " ..
	" |" .. --" |" ..
	loc("The first player to kill someone becomes the Mutant.") .. "|" ..
	loc("The Mutant has super-weapons and a lot of health.") .. "|" ..
	loc("The Mutant loses health quickly if he doesn't keep scoring kills.") .. "|" ..
	" |" ..
	loc("Normal players can only score points by killing the mutant.") .. "|" ..
	" |" .. "" ..
	loc("The player with least points (or most deaths) becomes the Bottom Feeder.") .. "|" ..
	loc("The Bottom Feeder can score points by killing anyone.") .. "|" ..
	" |" ..
	loc("POINTS") .. ": " ..
	" |" ..
	loc("+2 for becoming a Mutant") .. "|" ..
	loc("+1 to a Mutant for killing anyone") .. "|" ..
	loc("+1 to a Bottom Feeder for killing anyone") .. "|" ..
	loc("-1 to anyone for a suicide") .. "|" ..
	loc("Other kills don't give you points.")

	ShowMission(loc("Mutant"),
                loc("a Hedgewars tag game"),
                ruleSet, 0, 5000)

end

function onGameInit()
    TurnTime = 20000
    WaterRise = 0
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
            SetEffect(gear, heResurrectable, false)
            --SetHealth(gear, 0)
            SetGearPosition(gear, -100,LAND_HEIGHT)
        end
end

function onGameStart()
    trackTeams()
    teamScan()
    runOnHogs(saveStuff)
    --local str = "/say " .. MUTANT_VERSION
    --ParseCommand(str)

    hogLimitHit = false
    for i=0 , TeamsCount - 1 do
        cnthhs = 0
        runOnHogsInTeam(limitHogs, teams[i])
    end
    if hogLimitHit then
        AddCaption(loc("ONE HOG PER TEAM! KILLING EXCESS HEDGES"))
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
        AddCaption( loc("FIRST BLOOD MUTATES") )
    end

    checkScore()
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
            AddCaption(loc("DOUBLE KILL"))
        elseif killsCounter == 3 then
            AddCaption(loc("MEGA KILL"))
            PlaySound(sndRegret)
        elseif killsCounter == 4 then
            AddCaption(loc("ULTRA KILL"))
        elseif killsCounter == 5 then
            AddCaption(loc("MONSTER KILL"))
            PlaySound(sndIllGetYou)
        elseif killsCounter == 6 then
            AddCaption(loc("LUDICROUS KILL"))
            PlaySound(sndNutter)
        elseif killsCounter == 7 then
            AddCaption(loc("HOLY SHYTE!"))
            PlaySound(sndLaugh)
        elseif killsCounter > 8 then
            AddCaption(loc("INSANITY"))
        end
end

function onGameTick()

    if circleFrame > -1 then
        for i = 0, #hhs do
            if circles[hhs[i]] ~= nil and hhs[i]~= nil then
                hhx, hhy = GetGearPosition(hhs[i])
                X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint = GetVisualGearValues(circles[hhs[i]])
                SetVisualGearValues(circles[hhs[i]], hhx + 1, hhy - 3, 0, 0, 0, 0, 0, 40 - (circleFrame % 25), Timer, Tint)
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
                        TurnTimeLeft = 0
                    end
            end
    end

end

function saveStuff(gear)
    setGearValue(gear,"Name",GetHogName(gear))
    setGearValue(gear,"Hat",GetHogHat(gear))
end

function armageddon(gear)
    SetState(gear, gstLoser)
    SetEffect(gear, heResurrectable, false)
    SetHealth(gear, 0)
end

function updateScore()

    local showScore = ""

    for i=0, TeamsCount-1 do
        if teams[i]~= nil then

            local curr_score = getTeamValue(teams[i], "Score")
            showScore = showScore .. teams[i] .. ": " .. curr_score .. " (deaths: " .. getTeamValue(teams[i], "DeadHogs") .. ") " .. "|"

        end
    end

    ShowMission(loc("Score"),
                "-------",
                showScore, 0, 200)

    HideMission()

end

function checkScore()
local showScore = ""
local lowest_score_team = nil
local min_score=nil
local winTeam = nil

local only_low_score = true

    for i=0, TeamsCount-1 do
        if teams[i]~=nil then
            local curr_score = getTeamValue(teams[i], "Score")

            runOnHogsInTeam(removeFeeder, teams[i])

            showScore = showScore .. teams[i] ..": " .. curr_score .. " (deaths: " .. getTeamValue(teams[i], "DeadHogs") .. ") " .. "|"

            if curr_score >= winScore then
                gameOver = true
                winTeam = teams[i]
            end

            if min_score==nil then
                min_score= curr_score
                lowest_score_team = teams[i]
            else
                if curr_score <= min_score then
                    if curr_score == min_score then
                        if getTeamValue(teams[i], "DeadHogs") == getTeamValue(lowest_score_team, "DeadHogs") then
                            only_low_score = false
                        else
                            if getTeamValue(teams[i], "DeadHogs") > getTeamValue(lowest_score_team, "DeadHogs") then
                                lowest_score_team = teams[i]
                            end
                            only_low_score = true
                        end

                    else
                        min_score= curr_score
                        lowest_score_team = teams[i]
                        only_low_score = true
                    end
                end
            end
        end
    end

    if gameOver then
        TurnTimeLeft = 0
        for i=0, #teams do
            if teams[i]~=winTeam then
                runOnHogsInTeam(armageddon, teams[i])
            end
        end

    ShowMission(    loc("WINNER IS ") .. winTeam,
                    "~~~~~~~~~~~~~~~~~~~~~~~~~",
                    showScore, 0, 200)
    else

    if only_low_score then
        runOnHogsInTeam(setFeeder, lowest_score_team)
    end

    if meh == false then
		meh = true
	else
		ShowMission(    loc("Score"),
                    loc("-------"),
                    showScore, 0, 200)
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
            SetGearAIHints(hhs[i], aihUsual)
        else
            SetGearAIHints(hhs[i], aihDoesntMatter)
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
        SetHogName(gear,"BOTTOM FEEDER")
        SetHogHat(gear, 'poke_slowpoke')
        setGearValue(gear,"Feeder", true)
    end
end

function setMutantStuff(gear)
    mutant = gear

    SetHogName(gear,"MUTANT")
    SetHogHat(gear,'WhySoSerious')
    SetHealth(gear, ( mutant_base_health + numhhs*25) )
    SetEffect(gear, hePoisoned, 1)
    setGearValue(mutant,"SelfDestruct",false)
    setGearValue(gear, "Feeder", false)

    AddCaption(getGearValue(gear, "Name") .. loc(" HAS MUTATED"))

    TurnTimeLeft=0

    AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
    AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
    AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
    AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
    AddVisualGear(GetX(gear), GetY(gear), vgtSmokeRing, 0, false)
    PlaySound(sndSuddenDeath)
end

function teamScan()

        for i=0, TeamsCount-1 do --nil filling
        teams[i]=nil
        end

        for i=0, #hhs do
            for j=0, TeamsCount-1 do
                if teams[j] ==nil and hhs[i]~=nil then
                teams[j] = GetHogTeamName(hhs[i])
                setTeamValue(teams[j],"Score",0)
                setTeamValue(teams[j], "DeadHogs",0)
                break
                end

                if teams[j] == GetHogTeamName(hhs[i]) then
                    break
                end
            end
        end

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
                        end
                else
                    if curr_team ~=GetHogTeamName(gear) then
                        if CurrentHedgehog==mutant and getGearValue(mutant,"SelfDestruct")==false then
                            SetHealth(CurrentHedgehog, GetHealth(CurrentHedgehog)+kill_reward)
                            AddCaption("+" .. kill_reward .. loc(" HP") )
                            increaseTeamValue(curr_team,"Score")
                        end
                        if getGearValue(CurrentHedgehog,"Feeder") then
                            increaseTeamValue(curr_team,"Score")
                        end
                    else
                        setTeamValue(curr_team,"Score",(getTeamValue(curr_team,"Score") - team_fire_punishment))
                    end
                end
            end
    end
end

function onGearResurrect(gear)
if not gameOver then
    if GetGearType(gear) == gtHedgehog then

        increaseTeamValue(GetHogTeamName(gear), "DeadHogs")

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
        updateScore()
    end
end
end

function onGearAdd(gear)

    -- Catch hedgehogs for the tracker
    if GetGearType(gear) == gtHedgehog then
        trackGear(gear)
        hhs[numhhs] = gear
        numhhs = numhhs + 1
        SetEffect(gear, heResurrectable, 1)
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
                if teams[i] == t_name then
                    found = i
                    break
                end
            end
            for i = found, TeamsCount - 2 do
                teams[i] = teams[i + 1]
            end
            teams[TeamsCount - 1] = nil
            TeamsCount = TeamsCount - 1
        end
        AddVisualGear(GetX(gear), GetY(gear), vgtBigExplosion, 0, false)
        trackDeletion(gear)
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

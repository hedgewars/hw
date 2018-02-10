HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

local weapons = { amGrenade, amClusterBomb, amBazooka, amBee, amShotgun, amMine, amDEagle, amDynamite, amFirePunch, amWhip, amPickHammer, amBaseballBat, amMortar, amCake, amSeduction, amWatermelon, amHellishBomb, amDrill, amBallgun, amRCPlane, amSniperRifle, amMolotov, amBirdy, amBlowTorch, amGasBomb, amFlamethrower, amSMine, amKamikaze, amDuck, amMinigun, amAirMine, amKnife }

--                      G,C,B,B,S,M,D,D,F,W,P,B,M,C,S,W,H,D,B,R,S,M,B,B,G,F,S,K,D,M,A,K
local weapons_values = {1,1,1,2,1,1,1,2,1,1,1,2,1,3,1,3,3,2,3,3,1,1,2,1,1,2,2,1,1,3,1,2}

local airweapons = { amAirAttack, amMineStrike, amNapalm, amDrillStrike }

--                         A,M,N,D
local airweapons_values = {2,2,2,2}

local utilities = { amTeleport, amGirder, amSwitch, amLowGravity, amResurrector, amRope, amParachute, amJetpack, amPortalGun, amSnowball }

--                        T,G,S,L,R,R,P,J,P,S
local utilities_values = {1,2,2,1,2,2,1,2,2,2}

function randomAmmo()
    local n = 3   --"points" to be allocated on weapons

    --pick random weapon and subtract cost
    local r = GetRandom(table.maxn(weapons_values)) + 1
    local picked_items = {}
    table.insert(picked_items, weapons[r])
    n = n - weapons_values[r]


    --choose any weapons or utilities to use up remaining n

    while n > 0 do
        local items = {}
        local items_values = {}

        for i, w in pairs(weapons_values) do
            local used = false
            if w <= n then
                --check that this weapon hasn't been given already
                for j, k in pairs(picked_items) do
                    if weapons[i] == k then
                        used = true
                    end
                end
                if not used then
                    table.insert(items_values, w)
                    table.insert(items, weapons[i])
                end
            end
        end

        for i, w in pairs(utilities_values) do
            local used = false
            if w <= n then
                --check that this weapon hasn't been given already
                for j, k in pairs(picked_items) do
                    if utilities[i] == k then
                        used = true
                    end
                end
                if not used then
                    table.insert(items_values, w)
                    table.insert(items, utilities[i])
                end
            end
        end

        local r = GetRandom(table.maxn(items_values)) + 1
        table.insert(picked_items, items[r])
        n = n - items_values[r]
    end

    return picked_items
end

function assignAmmo(hog)
    local name = GetHogTeamName(hog)
    local processed = getTeamValue(name, "processed")
    if processed == nil or not processed then
        local ammo = getTeamValue(name, "ammo")
        if ammo == nil then
            ammo = randomAmmo()
            setTeamValue(name, "ammo", ammo)
        end
        for i, w in pairs(ammo) do
            AddAmmo(hog, w)
        end
        setTeamValue(name, "processed", true)
    end
end

function reset(hog)
    setTeamValue(GetHogTeamName(hog), "processed", false)
end

function onGameInit()
    DisableGameFlags(gfPerHogAmmo)
    EnableGameFlags(gfResetWeps)
    Goals = loc("Each turn you get 1-3 random weapons")
end

function onGameStart()
    trackTeams()
    if MapHasBorder() == false then
        for i, w in pairs(airweapons) do
            table.insert(weapons, w)
        end
        for i, w in pairs(airweapons_values) do
            table.insert(weapons_values, w)
        end
    end
end

function onAmmoStoreInit()
    SetAmmo(amSkip, 9, 0, 0, 0)

    SetAmmo(amExtraDamage, 0, 1, 0, 1)
    SetAmmo(amInvulnerable, 0, 1, 0, 1)
    SetAmmo(amExtraTime, 0, 1, 0, 1)
    SetAmmo(amLaserSight, 0, 1, 0, 1)
    SetAmmo(amVampiric, 0, 1, 0, 1)

    for i, w in pairs(utilities) do
        SetAmmo(w, 0, 0, 0, 1)
    end

    for i, w in pairs(weapons) do
        SetAmmo(w, 0, 0, 0, 1)
    end

    for i, w in pairs(airweapons) do
        SetAmmo(w, 0, 0, 0, 1)
    end
end

function onNewTurn()
    runOnGears(assignAmmo)
    runOnGears(reset)
    setTeamValue(GetHogTeamName(CurrentHedgehog), "ammo", nil)
end

function onGearAdd(gear)
    if GetGearType(gear) == gtHedgehog then
        trackGear(gear)
    end
end

function onGearDelete(gear)
    trackDeletion(gear)
end

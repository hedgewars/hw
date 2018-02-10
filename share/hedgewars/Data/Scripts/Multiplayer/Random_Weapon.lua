-- Random Weapons, example for gameplay scripts

-- Load the library for localisation ("loc" function)
HedgewarsScriptLoad("/Scripts/Locale.lua")

-- Load the gear tracker
HedgewarsScriptLoad("/Scripts/Tracker.lua")

-- List of available weapons
local weapons = { amGrenade, amClusterBomb, amBazooka, amBee, amShotgun,
            amMine, amDEagle, amDynamite, amFirePunch, amWhip, amPickHammer,
            amBaseballBat, amTeleport, amMortar, amCake, amSeduction,
            amWatermelon, amHellishBomb, amDrill, amBallgun, amRCPlane,
            amSniperRifle, amMolotov, amBirdy, amBlowTorch, amGasBomb,
            amFlamethrower, amSMine, amHammer, amDuck, amMinigun, amSineGun,
            amKnife, amAirMine }

-- List of weapons that attack from the air
local airweapons = { amAirAttack, amMineStrike, amNapalm, amDrillStrike }

-- Function that assigns the team their weapon
function assignAmmo(hog)
    -- Get name of the current team
    local name = GetHogTeamName(hog)
    -- Get whither the team has been processed
    local processed = getTeamValue(name, "processed")
    -- If it has not, process it
    if processed == nil or not processed then
        -- Get the ammo for this hog's team
        local ammo = getTeamValue(name, "ammo")
        -- If there is no ammo, get a random one from the list and store it
        if ammo == nil then
            ammo = weapons[GetRandom(table.maxn(weapons)) + 1]
            setTeamValue(name, "ammo", ammo)
        end
        -- Add the ammo for the hog
        AddAmmo(hog, ammo)
        -- Mark as processed
        setTeamValue(name, "processed", true)
    end
end

-- Mark team as not processed
function reset(hog)
    setTeamValue(GetHogTeamName(hog), "processed", false)
end

function onGameInit()
    -- Limit flags that can be set, but allow game schemes to be used
    DisableGameFlags(gfInfAttack)
    EnableGameFlags(gfResetWeps)
    -- Set a custom game goal that will show together with the scheme ones
    Goals = loc("Each turn you get one random weapon")
end

function onGameStart()
    -- Initialize the tracking of hogs and teams
    trackTeams()
    -- Add air weapons to the game if the border is not active
    if MapHasBorder() == false then
        for i, w in pairs(airweapons) do
            table.insert(weapons, w)
        end
    end
end

function onAmmoStoreInit()
    -- Allow skip at all times
    SetAmmo(amSkip, 9, 0, 0, 0)

    -- Let utilities be available through crates
    SetAmmo(amParachute, 0, 1, 0, 1)
    SetAmmo(amGirder, 0, 1, 0, 2)
    SetAmmo(amSwitch, 0, 1, 0, 1)
    SetAmmo(amLowGravity, 0, 1, 0, 1)
    SetAmmo(amExtraDamage, 0, 1, 0, 1)
    SetAmmo(amInvulnerable, 0, 1, 0, 1)
    SetAmmo(amExtraTime, 0, 1, 0, 1)
    SetAmmo(amLaserSight, 0, 1, 0, 1)
    SetAmmo(amVampiric, 0, 1, 0, 1)
    SetAmmo(amJetpack, 0, 1, 0, 1)
    SetAmmo(amPortalGun, 0, 1, 0, 1)
    SetAmmo(amResurrector, 0, 1, 0, 1)

    -- Allow weapons to be used
    for i, w in pairs(weapons) do
        SetAmmo(w, 0, 0, 0, 1)
    end

    -- Allow air weapons to be used
    for i, w in pairs(airweapons) do
        SetAmmo(w, 0, 0, 0, 1)
    end
end

function onNewTurn()
    -- Give every team their weapons, so one can plan during anothers turn
    runOnGears(assignAmmo)
    -- Mark all teams as not processed
    runOnGears(reset)
    -- Set the current teams weapons to nil so they will get new after the turn has ended
    setTeamValue(GetHogTeamName(CurrentHedgehog), "ammo", nil)
end

function onGearAdd(gear)
    -- Catch hedgehogs for the tracker
    if GetGearType(gear) == gtHedgehog then
        trackGear(gear)
    end
end

function onGearDelete(gear)
    -- Remove hogs that are gone
    trackDeletion(gear)
end

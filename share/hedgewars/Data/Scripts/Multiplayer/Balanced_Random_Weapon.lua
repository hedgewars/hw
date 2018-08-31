--[[
Balanced Random Weapon

Every turn, each hog gets 1-3 random weapons. Weapons are reset every turn.

= CUSTOMIZATION =
The weapon chances are chosen with the weapons scheme.

The "ammo count" tab is used to set the probability level that you get
equipped with the ammo at the start of a turn:

* infinity = always get this weapon
* 3-8 bullets = high probability (more bullets don't make it more likely)
* 2 bullets = medium probability
* 1 bullet = low probability
* 0 bullets = never

For utilities, the low and medium probabilities are the same.

The "probabilities" tab is, as usual, for crate probabilities.
The "ammo in crate" and "delay" tabs also work as expected.
]]

HedgewarsScriptLoad("/Scripts/Locale.lua")
HedgewarsScriptLoad("/Scripts/Tracker.lua")

local weapons = {}
local weapons_values = {}
local weapons_count = 0
local utilities = {}
local utilities_values = {}
local utilities_count = 0

local gotten_air_weapons = {}

local isUtility, isAirWeapon

function randomAmmo()
--[[
= WEAPON SELECTION ALGORITHM =
Each turn, a team gets 3 "points". Each ammo that has been activated
has a "cost" of 1-3 which is derived from the ammo probability specified
from the ammo menu (see getCost).
Utilities are forced to have a cost of 1-2.

Steps:
1. Add a random weapon to ammo and subtract cost
2. If there's still points left:
    a. Forget any item in mind
    b. Choose a random weapon and keep it in mind (but don't add it to the ammo yet)
    c. Choose a random utility and keep it in mind (but don't add it to the ammo yet)
    d. Forget any items which are either too expensive or have already been taken by this hedgehog
    e. Randomly add one of the items which are still in mind to the hedgehog's ammo and substract cost
    f. Return to step 2

If 0 points are left, the algorithm terminates.
]]
    local picked_items = {}

    local n = 3   --"points" to be allocated on weapons

    --pick random weapon and subtract cost
    if weapons_count > 0 then
        local r = GetRandom(weapons_count) + 1
        table.insert(picked_items, weapons[r])
        n = n - weapons_values[r]
    elseif utilities_count > 0 then
        local r = GetRandom(utilities_count) + 1
        table.insert(picked_items, utilities[r])
        n = n - utilities_values[r]
    else
        return picked_items
    end

    --choose any weapons or utilities to use up remaining n

    while n > 0 do
        local items = {}
        local items_values = {}
        local items_count = 0

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
                    items_count = items_count + 1
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
                    items_count = items_count + 1
                end
            end
        end

        if items_count > 0 then
            local r = GetRandom(items_count) + 1
            table.insert(picked_items, items[r])
            n = n - items_values[r]
        else
            break
        end
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
            AddAmmo(hog, w, 1)
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

    isUtility = {
        [amTeleport] = true,
        [amGirder] = true,
        [amSwitch] = true,
        [amLowGravity] = true,
        [amResurrector] = true,
        [amRope] = true,
        [amParachute] = true,
        [amJetpack] = true,
        [amPortalGun] = true,
        [amRubber] = true,
        [amTardis] = true,
        [amLandGun] = true,
        [amExtraTime] = true,
        [amVampiric] = true,
        [amLaserSight] = true,
        [amExtraDamage] = true,
        [amInvulnerable] = true,

        -- unusual classification
        [amSnowball] = true,
    }

    isAirWeapon = {
        [amAirAttack] = true,
        [amMineStrike] = true,
        [amNapalm] = true,
        [amDrillStrike] = true,
        [amPiano] = true,
    }

end

local function getCost(ammoType, ammoCount)
    if ammoCount == 0 or ammoCount == 9 then
        return 0
    else
        local max
        if isUtility[ammoType] then
            -- Force-limit cost of utilities to 2 because utilities with
            -- a cost of 3 could never be "paid"
            max = 2
        else
            max = 3
        end
        return math.max(1, math.min(max, 4 - ammoCount))
    end
end

function onGameStart()
    trackTeams()
    -- Add air weapons
    if MapHasBorder() == false then
        for a = 0, AmmoTypeMax do
            if isAirWeapon[a] then
                local gotten = gotten_air_weapons[a]
                local ammoCount, prob, delay, ammoInCrate = gotten[1], gotten[2], gotten[3], gotten[4]
                local cost = getCost(a, ammoCount)
                if cost > 0 then
                    table.insert(weapons, a)
                    table.insert(weapons_values, cost)
                    weapons_count = weapons_count + 1
                end
            end
        end
    end
end

function onAmmoStoreInit()
    SetAmmo(amSkip, 9, 0, 0, 0)

    for a=0, AmmoTypeMax do
        if a ~= amNothing and a ~= amSkip then
            local ammoCount, prob, delay, ammoInCrate = GetAmmo(a)
            if (not isAirWeapon[a]) then
                local cost = getCost(a, ammoCount)
                if cost > 0 then
                    if isUtility[a] then
                        table.insert(utilities, a)
                        table.insert(utilities_values, cost)
                        utilities_count = utilities_count + 1
                    else
                        table.insert(weapons, a)
                        table.insert(weapons_values, cost)
                        weapons_count = weapons_count + 1
                    end
                end
            else
                -- air weapons are handled in onGameStart
                gotten_air_weapons[a] = { ammoCount, prob, delay, ammoInCrate }
            end
            local realAmmoCount
            if ammoCount ~= 9 then
                realAmmoCount = 0
            else
                realAmmoCount = 1
            end
            SetAmmo(a, realAmmoCount, prob, delay, ammoInCrate)
        end
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

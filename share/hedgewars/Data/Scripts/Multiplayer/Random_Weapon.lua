loadfile(GetDataPath() .. "Scripts/Locale.lua")()

local weapons = { amGrenade, amClusterBomb, amBazooka, amBee, amShotgun,
            amMine, amDEagle, amDynamite, amFirePunch, amWhip, amPickHammer,
            amBaseballBat, amTeleport, amMortar, amCake, amSeduction,
            amWatermelon, amHellishBomb, amDrill, amBallgun, amRCPlane,
            amSniperRifle, amMolotov, amBirdy, amBlowTorch, amGasBomb,
            amFlamethrower, amSMine, amHammer, amSnowball, amTardis, amStructure }

local airweapons = { amAirAttack, amMineStrike, amNapalm, amDrillStrike }


function onGameInit()
    GameFlags = band(bor(GameFlags, gfResetWeps), bnot(gfInfAttack + gfPerHogAmmo))
    Goals = loc("Each turn you get one random weapon")
end

function onGameStart()
    if MapHasBorder() == false then
        for i, w in pairs(airweapons) do
            table.insert(weapons, w)
        end
    end
    --ShowMission(loc("Random Weapons"), loc("A game of luck"), loc("There has been a mix-up with your gear and now you|have to utilize whatever is coming your way!"), -amSkip, 0)
end

function onAmmoStoreInit()
    SetAmmo(amSkip, 9, 0, 0, 0)

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

    for i, w in pairs(weapons) do
        SetAmmo(w, 0, 0, 0, 1)
    end

    for i, w in pairs(airweapons) do
        SetAmmo(w, 0, 0, 0, 1)
    end
end

function onNewTurn()
    AddAmmo(CurrentHedgehog, weapons[GetRandom(table.maxn(weapons)) + 1])
end

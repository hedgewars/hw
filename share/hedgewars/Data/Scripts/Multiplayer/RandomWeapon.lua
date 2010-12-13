local weapons = { amGrenade, amClusterBomb, amBazooka, amBee, amShotgun,
            amMine, amDEagle, amDynamite, amFirePunch, amWhip, amPickHammer,
            amBaseballBat, amAirAttack, amMineStrike, amTeleport, amMortar, amCake,
            amSeduction, amWatermelon, amHellishBomb, amNapalm, amDrill, amBallgun,
            amRCPlane, amSniperRifle, amMolotov, amBirdy, amBlowTorch,
            amGasBomb, amFlamethrower, amSMine, amHammer, amDrillStrike }

local lastRound = -1
local weapon = 0

function onGameInit()
    GameFlags = band(bor(GameFlags, gfResetWeps), bnot(gfInfAttack + gfPerHogAmmo))
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
end

function onNewTurn()
    if lastRound ~= TotalRounds then
        weapon = GetRandom(table.maxn(weapons)) + 1
        lastRound = TotalRounds
    end
    AddAmmo(CurrentHedgehog, weapons[weapon])
end

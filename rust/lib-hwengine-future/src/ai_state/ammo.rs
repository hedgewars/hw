use strum::{EnumCount, EnumIter};

#[repr(usize)]
#[derive(EnumIter, EnumCount, Copy, Clone, Debug, PartialEq)]
pub enum AmmoType {
    Nothing,
    Grenade,
    ClusterBomb,
    Bazooka,
    Bee,
    Shotgun,
    PickHammer, // 6
    Skip,
    Rope,
    Mine,
    DEagle,
    Dynamite,
    FirePunch,
    Whip, // 13
    BaseballBat,
    Parachute,
    AirAttack,
    MineStrike,
    BlowTorch, // 18
    Girder,
    Teleport,
    Switch,
    Mortar,
    Kamikaze,
    Cake, // 24
    Seduction,
    Watermelon,
    HellishBomb,
    Napalm,
    Drill,
    Ballgun, // 30
    RCPlane,
    LowGravity,
    ExtraDamage,
    Invulnerable,
    ExtraTime, // 35
    LaserSight,
    Vampiric,
    SniperRifle,
    Jetpack,
    Molotov,
    Birdy,
    PortalGun, // 42
    Piano,
    GasBomb,
    SineGun,
    Flamethrower,
    SMine,
    Hammer, // 48
    Resurrector,
    DrillStrike,
    Snowball,
    Tardis,
    LandGun, // 53
    IceGun,
    Knife,
    Rubber,
    AirMine,
    Creeper,
    Minigun,
    Sentry, // 60
}

impl TryFrom<usize> for AmmoType {
    type Error = &'static str;

    fn try_from(value: usize) -> Result<Self, Self::Error> {
        if value < Self::COUNT {
            Ok(unsafe { std::mem::transmute(value) })
        } else {
            Err("Invalid ammo type")
        }
    }
}

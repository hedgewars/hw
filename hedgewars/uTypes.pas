{$INCLUDE "options.inc"}

unit uTypes;
interface

uses SDLh, uFloat, GLunit, uConsts, Math;

type
    HwColor4f = record
        r, g, b, a: byte
        end;

    TGameState = (gsLandGen, gsStart, gsGame, gsChat, gsConfirm, gsExit, gsSuspend);

    TGameType = (gmtLocal, gmtDemo, gmtNet, gmtSave, gmtLandPreview, gmtSyntax);

    TPathType = (ptNone, ptData, ptGraphics, ptThemes, ptCurrTheme, ptTeams, ptMaps,
            ptMapCurrent, ptDemos, ptSounds, ptGraves, ptFonts, ptForts,
            ptLocale, ptAmmoMenu, ptHedgehog, ptVoices, ptHats, ptFlags, ptMissionMaps);

    TSprite = (sprWater, sprCloud, sprBomb, sprBigDigit, sprFrame,
            sprLag, sprArrow, sprBazookaShell, sprTargetP, sprBee,
            sprSmokeTrace, sprRopeHook, sprExplosion50, sprMineOff,
            sprMineOn, sprMineDead, sprCase, sprFAid, sprDynamite, sprPower,
            sprClusterBomb, sprClusterParticle, sprFlame, sprHorizont,
            sprHorizontL, sprHorizontR, sprSky, sprSkyL,
            sprSkyR, sprAMBorderHorizontal, sprAMBorderVertical, sprAMSlot, sprAMAmmos,
            sprAMSlotKeys, sprAMCorners, sprFinger, sprAirBomb,
            sprAirplane, sprAmAirplane, sprAmGirder, sprHHTelepMask,
            sprSwitch, sprParachute, sprTarget, sprRopeNode,
            sprQuestion, sprPowerBar, sprWindBar, sprWindL, sprWindR,
            sprFlake, sprHandRope, sprHandBazooka, sprHandShotgun,
            sprHandDEagle, sprHandAirAttack, sprHandBaseball, sprPHammer,
            sprHandBlowTorch, sprBlowTorch, sprTeleport, sprHHDeath,
            sprShotgun, sprDEagle, sprHHIdle, sprMortar, sprTurnsLeft,
            sprKamikaze, sprWhip, sprKowtow, sprSad, sprWave,
            sprHurrah, sprLemonade, sprShrug, sprJuggle, sprExplPart, sprExplPart2,
            sprCakeWalk, sprCakeDown, sprAMAmmosBW, sprWatermelon,
            sprEvilTrace, sprHellishBomb, sprSeduction, sprDress,
            sprCensored, sprDrill, sprHandDrill, sprHandBallgun, sprBalls,
            sprPlane, sprHandPlane, sprUtility, sprInvulnerable, sprVampiric, sprGirder,
            sprSpeechCorner, sprSpeechEdge, sprSpeechTail,
            sprThoughtCorner, sprThoughtEdge, sprThoughtTail,
            sprShoutCorner, sprShoutEdge, sprShoutTail,
            sprSniperRifle, sprBubbles, sprJetpack, sprHealth, sprHandMolotov, sprMolotov,
            sprSmoke, sprSmokeWhite, sprShell, sprDust, sprExplosives, sprExplosivesRoll,
            sprAmTeleport, sprSplash, sprDroplet, sprBirdy, sprHandCake, sprHandConstruction,
            sprHandGrenade, sprHandMelon, sprHandMortar, sprHandSkip, sprHandCluster,
            sprHandDynamite, sprHandHellish, sprHandMine, sprHandSeduction, sprHandVamp,
            sprBigExplosion, sprSmokeRing, sprBeeTrace, sprEgg, sprTargetBee, sprHandBee,
            sprFeather, sprPiano, sprHandSineGun, sprPortalGun, sprPortal,
            sprCheese, sprHandCheese, sprHandFlamethrower, sprChunk, sprNote,
            sprSMineOff, sprSMineOn, sprHandSMine, sprHammer,
            sprHandResurrector, sprCross, sprAirDrill, sprNapalmBomb,
            sprBulletHit, sprSnowball, sprHandSnowball
            );

    // Gears that interact with other Gears and/or Land
    TGearType = (gtBomb, gtHedgehog, gtShell, gtGrave, gtBee, // 4
            gtShotgunShot, gtPickHammer, gtRope, gtMine, gtCase, // 9
            gtDEagleShot, gtDynamite, gtClusterBomb, gtCluster, gtShover, // 14
            gtFlame, gtFirePunch, gtATStartGame, gtATSmoothWindCh, // 18
            gtATFinishGame, gtParachute, gtAirAttack, gtAirBomb, gtBlowTorch, // 23
            gtGirder, gtTeleport, gtSwitcher, gtTarget, gtMortar, // 28
            gtWhip, gtKamikaze, gtCake, gtSeduction, gtWatermelon, gtMelonPiece, // 34
            gtHellishBomb, gtWaterUp, gtDrill, gtBallGun, gtBall, gtRCPlane, // 40
            gtSniperRifleShot, gtJetpack, gtMolotov, gtExplosives, gtBirdy, // 45
            gtEgg, gtPortal, gtPiano, gtGasBomb, gtSineGunShot, gtFlamethrower, // 51
            gtSMine, gtPoisonCloud, gtHammer, gtHammerHit, gtResurrector, // 56
            gtNapalmBomb, gtSnowball); // 58

    // Gears that are _only_ of visual nature (e.g. background stuff, visual effects, speechbubbles, etc.)
    TVisualGearType = (vgtFlake, vgtCloud, vgtExplPart, vgtExplPart2, vgtFire,
            vgtSmallDamageTag, vgtTeamHealthSorter, vgtSpeechBubble, vgtBubble,
            vgtSteam, vgtAmmo, vgtSmoke, vgtSmokeWhite, vgtHealth, vgtShell,
            vgtDust, vgtSplash, vgtDroplet, vgtSmokeRing, vgtBeeTrace, vgtEgg,
            vgtFeather, vgtHealthTag, vgtSmokeTrace, vgtEvilTrace, vgtExplosion,
            vgtBigExplosion, vgtChunk, vgtNote, vgtLineTrail, vgtBulletHit, vgtCircle);

    TGearsType = set of TGearType;

    TDamageSource = (dsUnknown, dsFall, dsBullet, dsExplosion, dsShove, dsPoison);

    TSound = (sndNone,
            sndGrenadeImpact, sndExplosion, sndThrowPowerUp, sndThrowRelease,
            sndSplash, sndShotgunReload, sndShotgunFire, sndGraveImpact,
            sndMineTick, sndPickhammer, sndGun, sndBee, sndJump1, sndJump2,
            sndJump3, sndYesSir, sndLaugh, sndIllGetYou, sndIncoming,
            sndMissed, sndStupid, sndFirstBlood, sndBoring, sndByeBye,
            sndSameTeam, sndNutter, sndReinforce, sndTraitor, sndRegret,
            sndEnemyDown, sndCoward, sndHurry, sndWatchIt, sndKamikaze,
            sndCake, sndOw1, sndOw2, sndOw3, sndOw4, sndFirePunch1, sndFirePunch2,
            sndFirePunch3, sndFirePunch4, sndFirePunch5, sndFirePunch6,
            sndMelon, sndHellish, sndYoohoo, sndRCPlane, sndWhipCrack,
            sndRideOfTheValkyries, sndDenied, sndPlaced, sndBaseballBat,
            sndVaporize, sndWarp, sndSuddenDeath, sndMortar, sndShutter,
            sndHomerun, sndMolotov, sndCover, sndUhOh, sndOops,
            sndNooo, sndHello, sndRopeShot, sndRopeAttach, sndRopeRelease,
            sndSwitchHog, sndVictory, sndSniperReload, sndSteps, sndLowGravity,
            sndHellishImpact1, sndHellishImpact2, sndHellishImpact3, sndHellishImpact4,
            sndMelonImpact, sndDroplet1, sndDroplet2, sndDroplet3, sndEggBreak, sndDrillRocket,
            sndPoisonCough, sndPoisonMoan, sndBirdyLay, sndWhistle, sndBeeWater,
            sndPiano0, sndPiano1, sndPiano2, sndPiano3, sndPiano4, sndPiano5, sndPiano6, sndPiano7, sndPiano8,
            sndSkip, sndSineGun, sndOoff1, sndOoff2, sndOoff3, sndWhack,
            sndComeonthen, sndParachute, sndBump, sndResurrector);

    TAmmoType  = (amNothing, amGrenade, amClusterBomb, amBazooka, amBee, amShotgun, amPickHammer, // 6
            amSkip, amRope, amMine, amDEagle, amDynamite, amFirePunch, amWhip, // 13
            amBaseballBat, amParachute, amAirAttack, amMineStrike, amBlowTorch, // 18
            amGirder, amTeleport, amSwitch, amMortar, amKamikaze, amCake, // 24
            amSeduction, amWatermelon, amHellishBomb, amNapalm, amDrill, amBallgun, // 30
            amRCPlane, amLowGravity, amExtraDamage, amInvulnerable, amExtraTime, // 35
            amLaserSight, amVampiric, amSniperRifle, amJetpack, amMolotov, amBirdy, amPortalGun, // 42
            amPiano, amGasBomb, amSineGun, amFlamethrower, amSMine, amHammer, // 48
            amResurrector, amDrillStrike, amSnowball);

    TCrateType = (HealthCrate, AmmoCrate, UtilityCrate);

    THWFont = (fnt16, fntBig, fntSmall {$IFNDEF IPHONEOS}, CJKfnt16, CJKfntBig, CJKfntSmall{$ENDIF});

    TCapGroup = (capgrpGameState, capgrpAmmoinfo, capgrpVolume,
            capgrpMessage, capgrpAmmostate);

    TStatInfoType = (siGameResult, siMaxStepDamage, siMaxStepKills, siKilledHHs,
            siClanHealth, siTeamStats, siPlayerKills, siMaxTeamDamage,
            siMaxTeamKills, siMaxTurnSkips );

    TWave = (waveRollup, waveSad, waveWave, waveHurrah, waveLemonade, waveShrug, waveJuggle);

    THHFont = record
            Handle: PTTF_Font;
            Height: LongInt;
            style: LongInt;
            Name: string[21];
            end;

    PAmmo = ^TAmmo;
    TAmmo = record
            Propz: LongWord;
            Count: LongWord;
(* Using for place hedgehogs mode, but for any other situation where the initial count would be needed I guess.
For example, say, a mode where the weaponset is reset each turn, or on sudden death *)
            NumPerTurn: LongWord;
            Timer: LongWord;
            Pos: LongWord;
            AmmoType: TAmmoType;
            AttackVoice: TSound;
            end;

    TVertex2f = record
        X, Y: GLfloat;
        end;

    TVertex2i = record
        X, Y: GLint;
        end;

    PTexture = ^TTexture;
    TTexture = record
            id: GLuint;
            w, h, scale: LongInt;
            rx, ry: GLfloat;
            priority: GLfloat;
            vb, tb: array [0..3] of TVertex2f;
            PrevTexture, NextTexture: PTexture;
            end;

    THogEffect = (heInvulnerable, heResurrectable, hePoisoned, heResurrected);

    TScreenFade = (sfNone, sfInit, sfToBlack, sfFromBlack, sfToWhite, sfFromWhite);

    PGear = ^TGear;
    PHedgehog = ^THedgehog;
    PTeam     = ^TTeam;
    PClan     = ^TClan;

    TGearStepProcedure = procedure (Gear: PGear);
    TGear = record
            NextGear, PrevGear: PGear;
            Active: Boolean;
            AdvBounce: Longword;
            Invulnerable: Boolean;
            RenderTimer: Boolean;
            AmmoType : TAmmoType;
            State : Longword;
            X : hwFloat;
            Y : hwFloat;
            dX: hwFloat;
            dY: hwFloat;
            Kind: TGearType;
            Pos: Longword;
            doStep: TGearStepProcedure;
            Radius: LongInt;
            Angle, Power : Longword;
            DirAngle: real;
            Timer : LongWord;
            Elasticity: hwFloat;
            Friction  : hwFloat;
            Message, MsgParam : Longword;
            Hedgehog: PHedgehog;
            Health, Damage, Karma: LongInt;
            CollisionIndex: LongInt;
            Tag: LongInt;
            Tex: PTexture;
            Z: Longword;
            IntersectGear: PGear;
            FlightTime: Longword;
            uid: Longword;
            ImpactSound: TSound; // first sound, others have to be after it in the sounds def.
            nImpactSounds: Word; // count of ImpactSounds
            SoundChannel: LongInt;
            PortalCounter: LongWord  // Hopefully temporary, but avoids infinite portal loops in a guaranteed fashion.
        end;
    TPGearArray = Array of PGear;

    PVisualGear = ^TVisualGear;
    TVGearStepProcedure = procedure (Gear: PVisualGear; Steps: Longword);
    TVisualGear = record
        NextGear, PrevGear: PVisualGear;
        Frame,
        FrameTicks: Longword;
        X : real;
        Y : real;
        dX: real;
        dY: real;
        tdX: real;
        tdY: real;
        State : Longword;
        Timer: Longword;
        Angle, dAngle: real;
        Kind: TVisualGearType;
        doStep: TVGearStepProcedure;
        Tex: PTexture;
        alpha, scale: GLfloat;
        Hedgehog: PHedgehog;
        Text: shortstring;
        Tint: Longword;
        uid: Longword;
        end;

    TStatistics = record
        DamageRecv,
        DamageGiven: Longword;
        StepDamageRecv,
        StepDamageGiven,
        StepKills: Longword;
        MaxStepDamageRecv,
        MaxStepDamageGiven,
        MaxStepKills: Longword;
        FinishedTurns: Longword;
        end;

    TTeamStats = record
        Kills : Longword;
        AIKills : Longword;
        TeamKills : Longword;
        TurnSkips : Longword;
        TeamDamage : Longword;
        end;

    TBinds = array[0..cKeyMaxIndex] of shortstring;
    TKeyboardState = array[0..cKeyMaxIndex] of Byte;

    PVoicepack = ^TVoicepack;
    TVoicepack = record
        name: shortstring;
        chunks: array [TSound] of PMixChunk;
        end;

    PHHAmmo = ^THHAmmo;
    THHAmmo = array[0..cMaxSlotIndex, 0..cMaxSlotAmmoIndex] of TAmmo;

    THedgehog = record
            Name: string[MAXNAMELEN];
            Gear: PGear;
            SpeechGear: PVisualGear;
            NameTagTex,
            HealthTagTex,
            HatTex: PTexture;
            Ammo: PHHAmmo;
            CurAmmoType: TAmmoType;
            AmmoStore: Longword;
            Team: PTeam;
            MultiShootAttacks: Longword;
            visStepPos: LongWord;
            BotLevel  : Byte; // 0 - Human player
            HatVisibility: GLfloat;
            stats: TStatistics;
            Hat: shortstring;
            InitialHealth: LongInt; // used for gfResetHealth
            King: boolean;  // Flag for a bunch of hedgehog attributes
            Unplaced: boolean;  // Flag for hog placing mode
            Timer: Longword;
            Effects: Array[THogEffect] of boolean;
            end;

    TTeam = record
            Clan: PClan;
            TeamName: string[MAXNAMELEN];
            ExtDriven: boolean;
            Binds: TBinds;
            Hedgehogs: array[0..cMaxHHIndex] of THedgehog;
            CurrHedgehog: LongWord;
            NameTagTex: PTexture;
            CrosshairTex,
            GraveTex,
            HealthTex,
            AIKillsTex,
            FlagTex: PTexture;
            Flag: shortstring;
            GraveName: shortstring;
            FortName: shortstring;
            TeamHealth: LongInt;
            TeamHealthBarWidth,
            NewTeamHealthBarWidth: LongInt;
            DrawHealthY: LongInt;
            AttackBar: LongWord;
            HedgehogsNumber: Longword;
            hasGone: boolean;
            voicepack: PVoicepack;
            PlayerHash: shortstring;   // md5 hash of player name. For temporary enabling of hats as thank you. Hashed for privacy of players
            stats: TTeamStats;
            end;

    TClan = record
            Color: Longword;
            Teams: array[0..Pred(cMaxTeams)] of PTeam;
            TeamsNumber: Longword;
            CurrTeam: LongWord;
            ClanHealth: LongInt;
            ClanIndex: LongInt;
            TurnNumber: LongWord;
            end;

     TAmmoStrId = (sidNothing, sidGrenade, sidClusterBomb, sidBazooka, sidBee, sidShotgun,
            sidPickHammer, sidSkip, sidRope, sidMine, sidDEagle,
            sidDynamite, sidBaseballBat, sidFirePunch, sidSeconds,
            sidParachute, sidAirAttack, sidMineStrike, sidBlowTorch,
            sidGirder, sidTeleport, sidSwitch, sidMortar, sidWhip,
            sidKamikaze, sidCake, sidSeduction, sidWatermelon,
            sidHellishBomb, sidDrill, sidBallgun, sidNapalm, sidRCPlane,
            sidLowGravity, sidExtraDamage, sidInvulnerable, sidExtraTime,
            sidLaserSight, sidVampiric, sidSniperRifle, sidJetpack,
            sidMolotov, sidBirdy, sidPortalGun, sidPiano, sidGasBomb, sidSineGun, sidFlamethrower,
            sidSMine, sidHammer, sidResurrector, sidDrillStrike, sidSnowball);

    TMsgStrId = (sidStartFight, sidDraw, sidWinner, sidVolume, sidPaused,
            sidConfirm, sidSuddenDeath, sidRemaining, sidFuel, sidSync,
            sidNoEndTurn, sidNotYetAvailable, sidRoundSD, sidRoundsSD, sidReady);

    TEventId = (eidDied, eidDrowned, eidRoundStart, eidRoundWin, eidRoundDraw,
            eidNewHealthPack, eidNewAmmoPack, eidNewUtilityPack, eidTurnSkipped, eidHurtSelf,
            eidHomerun, eidGone);

    TGoalStrId = (gidCaption, gidSubCaption, gidForts, gidLowGravity, gidInvulnerable,
            gidVampiric, gidKarma, gidKing, gidPlaceHog, gidArtillery,
            gidSolidLand, gidSharedAmmo, gidMineTimer, gidNoMineTimer, gidRandomMineTimer,
            gidDamageModifier, gidResetHealth, gidAISurvival, gidInfAttack, gidResetWeps, gidPerHogAmmo);

    TLandArray = packed array of array of LongWord;
    TCollisionArray = packed array of array of Word;
    TPreview  = packed array[0..127, 0..31] of byte;
    TDirtyTag = packed array of array of byte;


implementation

end.

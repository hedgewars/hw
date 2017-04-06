(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit uTypes;
(*
 * This unit defines various types and enumerations for usage in different
 * places in the engine code.
 *)
interface

uses SDLh, uFloat, GLunit, uConsts, Math;

// NOTE: typed const is a variable despite const qualifier
// in freepascal you may actually use var for the same purpose

type
    HwColor4f = record
        r, g, b, a: byte;
        end;

    // Possible states of the game
    TGameState = (gsLandGen, gsStart, gsGame, gsChat, gsConfirm, gsExit, gsSuspend);

    // Game types that help determining what the engine is actually supposed to do
    TGameType = (gmtLocal, gmtDemo, gmtNet, gmtSave, gmtLandPreview, gmtSyntax, gmtRecord);

    // Different files are stored in different folders, this enumeration is used to tell which folder to use
    TPathType = (ptNone, ptData, ptGraphics, ptThemes, ptCurrTheme, ptConfig, ptTeams, ptMaps,
            ptMapCurrent, ptDemos, ptSounds, ptGraves, ptFonts, ptForts, ptLocale,
            ptAmmoMenu, ptHedgehog, ptVoices, ptHats, ptFlags, ptMissionMaps,
            ptSuddenDeath, ptButtons, ptShaders);

    // Available sprites for displaying stuff
    TSprite = (sprWater, sprCloud, sprBomb, sprBigDigit, sprBigDigitGray, sprBigDigitGreen,
            sprBigDigitRed, sprFrame, sprLag, sprArrow, sprBazookaShell, sprTargetP, sprBee,
            sprSmokeTrace, sprRopeHook, sprExplosion50, sprMineOff,
            sprMineOn, sprMineDead, sprCase, sprFAid, sprDynamite, sprPower,
            sprClusterBomb, sprClusterParticle, sprFlame,
            sprHorizont, sprHorizontL, sprHorizontR, sprSky, sprSkyL, sprSkyR,
            sprAMSlot, sprAMAmmos, sprAMAmmosBW, sprAMSlotKeys, sprAMCorners,
            sprFinger, sprAirBomb, sprAirplane, sprAmAirplane, sprAmGirder,
            sprHHTelepMask, sprSwitch, sprParachute, sprTarget, sprRopeNode,
            sprQuestion, sprPowerBar, sprWindBar, sprWindL, sprWindR,
{$IFDEF USE_TOUCH_INTERFACE}
            sprFireButton, sprArrowUp, sprArrowDown, sprArrowLeft, sprArrowRight,
            sprJumpWidget, sprAMWidget, sprPauseButton, sprTimerButton, sprTargetButton,
            sprSwitchButton,
{$ENDIF}
            sprFlake, sprHandRope, sprHandBazooka, sprHandShotgun,
            sprHandDEagle, sprHandAirAttack, sprHandBaseball, sprPHammer,
            sprHandBlowTorch, sprBlowTorch, sprTeleport, sprHHDeath,
            sprShotgun, sprDEagle, sprHHIdle, sprMortar, sprTurnsLeft,
            sprKamikaze, sprWhip, sprKowtow, sprSad, sprWave,
            sprHurrah, sprLemonade, sprShrug, sprJuggle, sprExplPart, sprExplPart2,
            sprCakeWalk, sprCakeDown, sprWatermelon,
            sprEvilTrace, sprHellishBomb, sprSeduction, sprDress,
            sprCensored, sprDrill, sprHandDrill, sprHandBallgun, sprBalls,
            sprPlane, sprHandPlane, sprUtility, sprInvulnerable, sprVampiric, sprGirder,
            sprSpeechCorner, sprSpeechEdge, sprSpeechTail,
            sprThoughtCorner, sprThoughtEdge, sprThoughtTail,
            sprShoutCorner, sprShoutEdge, sprShoutTail,
            sprSniperRifle, sprBubbles, sprJetpack, sprHealth, sprHandMolotov, sprMolotov,
            sprSmoke, sprSmokeWhite, sprShell, sprDust, sprSnowDust, sprExplosives, sprExplosivesRoll,
            sprAmTeleport, sprSplash, sprDroplet, sprBirdy, sprHandCake, sprHandConstruction,
            sprHandGrenade, sprHandMelon, sprHandMortar, sprHandSkip, sprHandCluster,
            sprHandDynamite, sprHandHellish, sprHandMine, sprHandSeduction, sprHandVamp,
            sprBigExplosion, sprSmokeRing, sprBeeTrace, sprEgg, sprTargetBee, sprHandBee,
            sprFeather, sprPiano, sprHandSineGun, sprPortalGun, sprPortal,
            sprCheese, sprHandCheese, sprHandFlamethrower, sprChunk, sprNote,
            sprSMineOff, sprSMineOn, sprHandSMine, sprHammer,
            sprHandResurrector, sprCross, sprAirDrill, sprNapalmBomb,
            sprBulletHit, sprSnowball, sprHandSnowball, sprSnow,
            sprSDFlake, sprSDWater, sprSDCloud, sprSDSplash, sprSDDroplet, sprTardis,
            sprSlider, sprBotlevels, sprHandKnife, sprKnife, sprStar, sprIceTexture, sprIceGun,
            sprFrozenHog, sprAmRubber, sprBoing, sprCustom1, sprCustom2, sprAirMine, sprHandAirMine,
            sprFlakeL, sprSDFlakeL, sprCloudL, sprSDCloudL
            );

    // Gears that interact with other Gears and/or Land
    // first row of gears (<gtExplosives) should be avoided when searching a spawn place
    TGearType = (gtFlame, gtHedgehog, gtMine, gtCase, gtAirMine, gtExplosives, 
            gtGrenade, gtShell, gtGrave, gtBee, // 9
            gtShotgunShot, gtPickHammer, gtRope,  // 12
            gtDEagleShot, gtDynamite, gtClusterBomb, gtCluster, gtShover, // 17
            gtFirePunch, gtATStartGame, // 19
            gtATFinishGame, gtParachute, gtAirAttack, gtAirBomb, gtBlowTorch, // 24
            gtGirder, gtTeleport, gtSwitcher, gtTarget, gtMortar, // 29
            gtWhip, gtKamikaze, gtCake, gtSeduction, gtWatermelon, gtMelonPiece, // 35
            gtHellishBomb, gtWaterUp, gtDrill, gtBallGun, gtBall, gtRCPlane, // 41
            gtSniperRifleShot, gtJetpack, gtMolotov, gtBirdy, // 45
            gtEgg, gtPortal, gtPiano, gtGasBomb, gtSineGunShot, gtFlamethrower, // 51
            gtSMine, gtPoisonCloud, gtHammer, gtHammerHit, gtResurrector, // 56
            gtNapalmBomb, gtSnowball, gtFlake, {gtStructure,} gtLandGun, gtTardis, // 61
            gtIceGun, gtAddAmmo, gtGenericFaller, gtKnife); // 65

    // Gears that are _only_ of visual nature (e.g. background stuff, visual effects, speechbubbles, etc.)
    TVisualGearType = (vgtFlake, vgtCloud, vgtExplPart, vgtExplPart2, vgtFire,
            vgtSmallDamageTag, vgtTeamHealthSorter, vgtSpeechBubble, vgtBubble,
            vgtSteam, vgtAmmo, vgtSmoke, vgtSmokeWhite, vgtShell,
            vgtDust, vgtSplash, vgtDroplet, vgtSmokeRing, vgtBeeTrace, vgtEgg,
            vgtFeather, vgtHealthTag, vgtSmokeTrace, vgtEvilTrace, vgtExplosion,
            vgtBigExplosion, vgtChunk, vgtNote, vgtLineTrail, vgtBulletHit, vgtCircle,
            vgtSmoothWindBar, vgtStraightShot, vgtNoPlaceWarn);

    // Damage can be caused by different sources
    TDamageSource = (dsUnknown, dsFall, dsBullet, dsExplosion, dsShove, dsPoison);

    // Available sounds
    TSound = (sndNone,
            sndGrenadeImpact, sndExplosion, sndThrowPowerUp, sndThrowRelease,
            sndSplash, sndShotgunReload, sndShotgunFire, sndGraveImpact,
            sndMineImpact, sndMineTick, sndMudballImpact,
            sndPickhammer, sndGun, sndBee, sndJump1, sndJump2,
            sndJump3, sndYesSir, sndLaugh, sndIllGetYou, sndJustYouWait, sndIncoming,
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
            sndSwitchHog, sndVictory, sndFlawless, sndSniperReload, sndSteps, sndLowGravity,
            sndHellishImpact1, sndHellishImpact2, sndHellishImpact3, sndHellishImpact4,
            sndMelonImpact, sndDroplet1, sndDroplet2, sndDroplet3, sndEggBreak, sndDrillRocket,
            sndPoisonCough, sndPoisonMoan, sndBirdyLay, sndWhistle, sndBeeWater,
            sndPiano0, sndPiano1, sndPiano2, sndPiano3, sndPiano4, sndPiano5, sndPiano6, sndPiano7,
            sndPiano8, sndSkip, sndSineGun, sndOoff1, sndOoff2, sndOoff3, sndWhack,
            sndComeonthen, sndParachute, sndBump, sndResurrector, sndPlane, sndTardis, sndFrozenHogImpact,
            sndIceBeam, sndHogFreeze, sndAirMineImpact, sndKnifeImpact, sndExtraTime, sndLaserSight,
            sndInvulnerable, sndJetpackLaunch, sndJetpackBoost, sndPortalShot, sndPortalSwitch,
            sndPortalOpen, sndBlowTorch, sndCountdown1, sndCountdown2, sndCountdown3, sndCountdown4
            );

    // Available ammo types to be used by hedgehogs
    TAmmoType  = (amNothing, amGrenade, amClusterBomb, amBazooka, amBee, amShotgun, amPickHammer, // 6
            amSkip, amRope, amMine, amDEagle, amDynamite, amFirePunch, amWhip, // 13
            amBaseballBat, amParachute, amAirAttack, amMineStrike, amBlowTorch, // 18
            amGirder, amTeleport, amSwitch, amMortar, amKamikaze, amCake, // 24
            amSeduction, amWatermelon, amHellishBomb, amNapalm, amDrill, amBallgun, // 30
            amRCPlane, amLowGravity, amExtraDamage, amInvulnerable, amExtraTime, // 35
            amLaserSight, amVampiric, amSniperRifle, amJetpack, amMolotov, amBirdy, amPortalGun, // 42
            amPiano, amGasBomb, amSineGun, amFlamethrower, amSMine, amHammer, // 48
            amResurrector, amDrillStrike, amSnowball, amTardis, {amStructure,} amLandGun, // 53
            amIceGun, amKnife, amRubber, amAirMine); // 57

    // Different kind of crates that e.g. hedgehogs can pick up
    TCrateType = (HealthCrate, AmmoCrate, UtilityCrate);

    THWFont = (fnt16, fntBig, fntSmall {$IFNDEF MOBILE}, CJKfnt16, CJKfntBig, CJKfntSmall{$ENDIF});

    TCapGroup = (capgrpGameState, capgrpAmmoinfo, capgrpVolume,
            capgrpMessage, capgrpMessage2, capgrpAmmostate);

    TStatInfoType = (siGameResult, siMaxStepDamage, siMaxStepKills, siKilledHHs,
            siClanHealth, siTeamStats, siPlayerKills, siMaxTeamDamage,
            siMaxTeamKills, siMaxTurnSkips, siCustomAchievement, siGraphTitle,
            siPointType);

    // Various 'emote' animations a hedgehog can do
    TWave = (waveRollup, waveSad, waveWave, waveHurrah, waveLemonade, waveShrug, waveJuggle);

    TRenderMode = (rmDefault, rmLeftEye, rmRightEye);
    TStereoMode = (smNone, smRedCyan, smCyanRed, smRedBlue, smBlueRed, smRedGreen, smGreenRed, smHorizontal, smVertical);
    TWorldEdge = (weNone, weWrap, weBounce, weSea, weSky);
    TUIDisplay = (uiAll, uiNoTeams, uiNone);
    TMapGen = (mgRandom, mgMaze, mgPerlin, mgDrawn, mgForts);


    THHFont = record
            Handle: PTTF_Font;
            Height: LongInt;
            style: LongInt;
            Name: string[31];
            end;

    PAmmo = ^TAmmo;
    TAmmo = record
            Propz: LongWord;
            Count: LongWord;
// Using for place hedgehogs mode, but for any other situation where the initial count would be needed I guess.
// For example, say, a mode where the weaponset is reset each turn, or on sudden death
            NumPerTurn: LongWord;
            Timer: LongWord;
            Pos: LongWord;
            AmmoType: TAmmoType;
            AttackVoice: TSound;
            Bounciness: LongWord;
            end;

    TVertex2f = record
            X, Y: GLfloat;
            end;

    TVertex2i = record
            X, Y: GLint;
            end;

    TMatrix4x4f = array[0..3, 0..3] of GLfloat;

    PTexture = ^TTexture;
    TTexture = record
            id: GLuint;
            w, h, scale: LongInt;
            rx, ry: GLfloat;
            priority: GLfloat;
            vb, tb: array [0..3] of TVertex2f;
            PrevTexture, NextTexture: PTexture;
            end;

    THogEffect = (heInvulnerable, heResurrectable, hePoisoned, heResurrected, heFrozen);

    TScreenFade = (sfNone, sfInit, sfToBlack, sfFromBlack, sfToWhite, sfFromWhite);

    PGear = ^TGear;
    PHedgehog = ^THedgehog;
    PTeam     = ^TTeam;
    PClan     = ^TClan;

    TGearStepProcedure = procedure (Gear: PGear);
// So, you are here looking for variables you can (ab)use to store some gear state?
// Not all members of this structure are created equal. Comments below are my take on what can be used for what in the gear structure.
    TGear = record
// Do *not* ever override these.
            NextGear, PrevGear: PGear;  // Linked list
            Z: Longword;                // Z index. For rendering. Sets order in list
            Active: Boolean;            // Is gear Active (running step code)
            Kind: TGearType;
            doStep: TGearStepProcedure; // Code the gear is running
            AmmoType : TAmmoType;       // Ammo type associated with this kind of gear
            RenderTimer: Boolean;       // Will visually display Timer if true
            Target : TPoint;            // Gear target. Will render in uGearsRender unless a special case is added
            AIHints: LongWord;          // hints for ai.
            LastDamage: PHedgehog;      // Used to track damage source for stats
            CollisionIndex: LongInt;    // Position in collision array
            Message: LongWord;          // Game messages are stored here. See gm bitmasks in uConsts
            uid: Longword;              // Lua use this to reference gears
            Hedgehog: PHedgehog;        // set to CurrentHedgehog on gear creation.  uStats damage code appears to assume it will never be nil and never be changed.  If you override it, make sure it is set to a non-nil PHedgehog before dealing damage.
// Strongly recommended not to override these.  Will mess up generic operations like portaling
            X : hwFloat;              // X/Y/dX/dY are position/velocity. People count on these having semi-normal values
            Y : hwFloat;
            dX: hwFloat;
            dY: hwFloat;
            State : Longword;        // See gst bitmask values in uConsts
            PortalCounter: LongWord; // Necessary to interrupt portal loops.  Not possible to avoid infinite loops without it.
// Don't use these if you're using generic movement like doStepFallingGear and explosion shoves. Generally recommended not to use.
            Radius: LongInt;     // Radius. If not using uCollisions, is usually used to indicate area of effect
            CollisionMask: Word; // Masking off Land impact  FF7F for example ignores current hog and crates
            AdvBounce: Longword; // Triggers 45 bounces. Is a counter to avoid edge cases
            Elasticity: hwFloat;
            Friction  : hwFloat;
            Density   : hwFloat; // Density is kind of a mix of size and density. Impacts distance thrown, wind.
            ImpactSound: TSound; // first sound, others have to be after it in the sounds def.
            nImpactSounds: Word; // count of ImpactSounds.
// Don't use these if you want to take damage normally, otherwise health/damage are commonly used for other purposes
            Health, Damage, Karma: LongInt;
// DirAngle is a 'real' - if you do not need it for rotation of sprite in uGearsRender, you can use it for any visual-only value
            DirAngle: real;
// These are frequently overridden to serve some other purpose
            Boom: Longword;          // amount of damage caused by the gear
            Pos: Longword;           // Commonly overridden.  Example use is posCase values in uConsts.
            Angle, Power : Longword; // Used for hog aiming/firing.  Angle is rarely used as an Angle otherwise.
            Timer, WDTimer : LongWord;        // Typically used for some sort of gear timer. Time to explosion, remaining fuel...
            Tag: LongInt;            // Quite generic. Variety of uses.
            FlightTime: Longword;    // Initially added for batting of hogs to determine homerun. Used for some firing delays
            MsgParam: LongWord;      // Initially stored a set of messages. So usually gm values like Message. Frequently overriden
// These are not used generically, but should probably be used for purpose intended. Definitely shouldn't override pointer type
            Tex: PTexture;          // A texture created by the gear. Shouldn't use for anything but textures
            Tint: LongWord;         // Used to colour a texture
            LinkedGear: PGear;      // Used to track a related gear. Portal pairs for example.
            SoundChannel: LongInt;  // Used to track a sound the gear started
            Data: Pointer; // pointer to gear type specific data structure (if any)
            end;
    TPGearArray = array of PGear;
    PGearArrayS = record
        size: LongWord;
        ar: ^TPGearArray;
        end;

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
        Tag: LongInt;
        Text: shortstring;
        Tint: Longword;
        uid: Longword;
        Layer: byte;
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
        Suicides: Longword;
        AIKills : Longword;
        TeamKills : Longword;
        TurnSkips : Longword;
        TeamDamage : Longword;
        end;

    TBinds = array[0..cKbdMaxIndex] of shortstring;
    TKeyboardState = array[0..cKeyMaxIndex] of Byte;

    PVoicepack = ^TVoicepack;
    TVoicepack = record
        name: shortstring;
        chunks: array [TSound] of PMixChunk;
        end;

    TVoice = record
        snd: TSound;
        voicepack: PVoicePack;
        end;

    THHAmmo = array[0..cMaxSlotIndex, 0..cMaxSlotAmmoIndex] of TAmmo;
    PHHAmmo = ^THHAmmo;

    THedgehog = record
            Name: shortstring;
            Gear: PGear;
            GearHidden: PGear;
            SpeechGear: PVisualGear;
            NameTagTex,
            HealthTagTex,
            HatTex: PTexture;
            Ammo: PHHAmmo;
            CurAmmoType: TAmmoType;
            PickUpType: LongWord;
            PickUpDelay: LongInt;
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
            HealthBarHealth: LongInt;
            Effects: array[THogEffect] of LongInt;
            end;

    TTeam = record
            Clan: PClan;
            TeamName: shortstring;
            ExtDriven: boolean;
            Binds: TBinds;
            Hedgehogs: array[0..cMaxHHIndex] of THedgehog;
            CurrHedgehog: LongWord;
            NameTagTex,
            OwnerTex,
            GraveTex,
            AIKillsTex,
            FlagTex: PTexture;
            Flag: shortstring;
            GraveName: shortstring;
            FortName: shortstring;
            Owner: shortstring;
            TeamHealth: LongInt;
            TeamHealthBarHealth: LongInt;
            DrawHealthY: LongInt;
            AttackBar: LongWord;
            HedgehogsNumber: Longword;
            voicepack: PVoicepack;
            PlayerHash: shortstring;   // md5 hash of player name. For temporary enabling of hats as thank you. Hashed for privacy of players
            stats: TTeamStats;
            hasGone: boolean;
            skippedTurns: Longword;
            isGoneFlagPendingToBeSet, isGoneFlagPendingToBeUnset: boolean;
            end;

    TClan = record
            Color: Longword;
            Teams: array[0..Pred(cMaxTeams)] of PTeam;
            HealthTex: PTexture;
            TeamsNumber: Longword;
            TagTeamIndex: Longword;
            CurrTeam: LongWord;
            ClanHealth: LongInt;
            ClanIndex: LongInt;
            TurnNumber: LongWord;
            Flawless: boolean;
            end;

     cdeclPtr = procedure; cdecl;
     cdeclIntPtr = procedure(num: LongInt); cdecl;
     funcDoublePtr = function: Double;

     TMobileRecord = record
                     PerformRumble: cdeclIntPtr;
                     GameLoading: cdeclPtr;
                     GameLoaded: cdeclPtr;
                     SaveLoadingEnded: cdeclPtr;
                     end;

     TAmmoStrId = (sidGrenade, sidClusterBomb, sidBazooka, sidBee, sidShotgun,
            sidPickHammer, sidSkip, sidRope, sidMine, sidDEagle,
            sidDynamite, sidBaseballBat, sidFirePunch, sidSeconds,
            sidParachute, sidAirAttack, sidMineStrike, sidBlowTorch,
            sidGirder, sidTeleport, sidSwitch, sidMortar, sidWhip,
            sidKamikaze, sidCake, sidSeduction, sidWatermelon,
            sidHellishBomb, sidDrill, sidBallgun, sidNapalm, sidRCPlane,
            sidLowGravity, sidExtraDamage, sidInvulnerable, sidExtraTime,
            sidLaserSight, sidVampiric, sidSniperRifle, sidJetpack,
            sidMolotov, sidBirdy, sidPortalGun, sidPiano, sidGasBomb,
            sidSineGun, sidFlamethrower,sidSMine, sidHammer, sidResurrector,
            sidDrillStrike, sidSnowball, sidNothing, sidTardis,
            {sidStructure,} sidLandGun, sidIceGun, sidKnife, sidRubber, sidAirMine);

    TMsgStrId = (sidStartFight, sidDraw, sidWinner, sidVolume, sidPaused,
            sidConfirm, sidSuddenDeath, sidRemaining, sidFuel, sidSync,
            sidNoEndTurn, sidNotYetAvailable, sidRoundSD, sidRoundsSD, sidReady,
            sidBounce1, sidBounce2, sidBounce3, sidBounce4, sidBounce5, sidBounce,
            sidMute, sidAFK, sidAutoCameraOff, sidAutoCameraOn, sidPressTarget);

    // Events that are important for the course of the game or at least interesting for other reasons
    TEventId = (eidDied, eidDrowned, eidRoundStart, eidRoundWin, eidRoundDraw,
            eidNewHealthPack, eidNewAmmoPack, eidNewUtilityPack, eidTurnSkipped,
            eidHurtSelf, eidHomerun, eidGone, eidPoisoned, eidResurrected,
            eidKamikaze, eidTimeTravelEnd, eidTimeout, eidKingDied);

    TGoalStrId = (gidCaption, gidSubCaption, gidPlaceKing, gidLowGravity, gidInvulnerable,
            gidVampiric, gidKarma, gidKing, gidPlaceHog, gidArtillery,
            gidSolidLand, gidSharedAmmo, gidMineTimer, gidNoMineTimer,
            gidRandomMineTimer, gidDamageModifier, gidResetHealth, gidAISurvival,
            gidInfAttack, gidResetWeps, gidPerHogAmmo, gidTagTeam, gidMoreWind);


    TLandArray = packed array of array of LongWord;
    TCollisionArray = packed array of array of Word;
    TDirtyTag = packed array of array of byte;

    TPreview  = packed array[0..127, 0..31] of byte;
    TPreviewAlpha  = packed array[0..127, 0..255] of byte;

    PWidgetMovement = ^TWidgetMovement;
    TWidgetMovement = record
        animate   : Boolean;
        source    : TPoint;
        target    : TPoint;
        startTime : Longword;
        end;

    POnScreenWidget = ^TOnScreenWidget;
    TOnScreenWidget = record
        show          : boolean;            // if false widget will not be drawn
        sprite        : TSprite;            // a convenience type
        frame         : TSDL_Rect;          // graphical coordinates
        active        : TSDL_Rect;          // active touch region
        fadeAnimStart : Longword;           // time the fade started
                                            //     (0 means do not fade)
        moveAnim      : TWidgetMovement;    // animation associated to widget
        end;

    PTouch_Data = ^TTouch_Data;
    TTouch_Data = record
        id                       : TSDL_FingerId;
        x,y                      : LongInt;
        dx,dy                    : LongInt;
        historicalX, historicalY : LongInt;
        timeSinceDown            : Longword;
        pressedWidget            : POnScreenWidget;
        end;

    PSpriteData = ^TSpriteData;
    TSpriteData = record
            FileName: string[15];
            Path, AltPath: TPathType;
            Texture: PTexture;
            Surface: PSDL_Surface;
            Width, Height, imageWidth, imageHeight: LongInt;
            saveSurf: boolean;
            priority: GLfloat;
            getDimensions, getImageDimensions: boolean;
            end;

    // gear data types

    const cakeh =   27;

    type TCakeData = record
        CakeI: integer;
        CakePoints: array[0..Pred(cakeh)] of record
            x, y: hwFloat;
        end;
    end;

    PCakeData = ^TCakeData;

    TClansArray = array[0..Pred(cMaxTeams)] of PClan;

implementation

end.

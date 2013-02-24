(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
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
    TPathType = (ptNone, ptData, ptGraphics, ptThemes, ptCurrTheme, ptTeams, ptMaps,
            ptMapCurrent, ptDemos, ptSounds, ptGraves, ptFonts, ptForts,
            ptLocale, ptAmmoMenu, ptHedgehog, ptVoices, ptHats, ptFlags, ptMissionMaps, ptSuddenDeath, ptButtons);

    // Available sprites for displaying stuff
    TSprite = (sprWater, sprCloud, sprBomb, sprBigDigit, sprFrame,
            sprLag, sprArrow, sprBazookaShell, sprTargetP, sprBee,
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
            sprSlider, sprBotlevels, sprHandKnife, sprKnife, sprStar, sprIceTexture, sprIceGun, sprFrozenHog
            );

    // Gears that interact with other Gears and/or Land
    TGearType = ({-->}gtFlame, gtHedgehog, gtMine, gtCase, gtExplosives, // <-- these are gears which should be avoided when searching a spawn place
            gtGrenade, gtShell, gtGrave, gtBee, // 8
            gtShotgunShot, gtPickHammer, gtRope,  // 11
            gtDEagleShot, gtDynamite, gtClusterBomb, gtCluster, gtShover, // 16
            gtFirePunch, gtATStartGame, // 18
            gtATFinishGame, gtParachute, gtAirAttack, gtAirBomb, gtBlowTorch, // 23
            gtGirder, gtTeleport, gtSwitcher, gtTarget, gtMortar, // 28
            gtWhip, gtKamikaze, gtCake, gtSeduction, gtWatermelon, gtMelonPiece, // 34
            gtHellishBomb, gtWaterUp, gtDrill, gtBallGun, gtBall, gtRCPlane, // 40
            gtSniperRifleShot, gtJetpack, gtMolotov, gtBirdy, // 44
            gtEgg, gtPortal, gtPiano, gtGasBomb, gtSineGunShot, gtFlamethrower, // 50
            gtSMine, gtPoisonCloud, gtHammer, gtHammerHit, gtResurrector, // 55
            gtNapalmBomb, gtSnowball, gtFlake, {gtStructure,} gtLandGun, gtTardis, // 61
            gtIceGun, gtAddAmmo, gtGenericFaller, gtKnife); // 65

    // Gears that are _only_ of visual nature (e.g. background stuff, visual effects, speechbubbles, etc.)
    TVisualGearType = (vgtFlake, vgtCloud, vgtExplPart, vgtExplPart2, vgtFire,
            vgtSmallDamageTag, vgtTeamHealthSorter, vgtSpeechBubble, vgtBubble,
            vgtSteam, vgtAmmo, vgtSmoke, vgtSmokeWhite, vgtShell,
            vgtDust, vgtSplash, vgtDroplet, vgtSmokeRing, vgtBeeTrace, vgtEgg,
            vgtFeather, vgtHealthTag, vgtSmokeTrace, vgtEvilTrace, vgtExplosion,
            vgtBigExplosion, vgtChunk, vgtNote, vgtLineTrail, vgtBulletHit, vgtCircle,
            vgtSmoothWindBar, vgtStraightShot);

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
            sndPiano0, sndPiano1, sndPiano2, sndPiano3, sndPiano4, sndPiano5, sndPiano6, sndPiano7, sndPiano8,
            sndSkip, sndSineGun, sndOoff1, sndOoff2, sndOoff3, sndWhack,
            sndComeonthen, sndParachute, sndBump, sndResurrector, sndPlane, sndTardis);

    // Available ammo types to be used by hedgehogs
    TAmmoType  = (amNothing, amGrenade, amClusterBomb, amBazooka, amBee, amShotgun, amPickHammer, // 6
            amSkip, amRope, amMine, amDEagle, amDynamite, amFirePunch, amWhip, // 13
            amBaseballBat, amParachute, amAirAttack, amMineStrike, amBlowTorch, // 18
            amGirder, amTeleport, amSwitch, amMortar, amKamikaze, amCake, // 24
            amSeduction, amWatermelon, amHellishBomb, amNapalm, amDrill, amBallgun, // 30
            amRCPlane, amLowGravity, amExtraDamage, amInvulnerable, amExtraTime, // 35
            amLaserSight, amVampiric, amSniperRifle, amJetpack, amMolotov, amBirdy, amPortalGun, // 42
            amPiano, amGasBomb, amSineGun, amFlamethrower, amSMine, amHammer, // 48
            amResurrector, amDrillStrike, amSnowball, amTardis, {amStructure,} amLandGun, amIceGun, amKnife); // 54

    // Different kind of crates that e.g. hedgehogs can pick up
    TCrateType = (HealthCrate, AmmoCrate, UtilityCrate);

    THWFont = (fnt16, fntBig, fntSmall {$IFNDEF MOBILE}, CJKfnt16, CJKfntBig, CJKfntSmall{$ENDIF});

    TCapGroup = (capgrpGameState, capgrpAmmoinfo, capgrpVolume,
            capgrpMessage, capgrpMessage2, capgrpAmmostate);

    TStatInfoType = (siGameResult, siMaxStepDamage, siMaxStepKills, siKilledHHs,
            siClanHealth, siTeamStats, siPlayerKills, siMaxTeamDamage,
            siMaxTeamKills, siMaxTurnSkips );

    // Various "emote" animations a hedgehog can do
    TWave = (waveRollup, waveSad, waveWave, waveHurrah, waveLemonade, waveShrug, waveJuggle);

    TRenderMode = (rmDefault, rmLeftEye, rmRightEye);
    TStereoMode = (smNone, smRedCyan, smCyanRed, smRedBlue, smBlueRed, smRedGreen, smGreenRed, smHorizontal, smVertical);

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
(* Using for place hedgehogs mode, but for any other situation where the initial count would be needed I guess.
For example, say, a mode where the weaponset is reset each turn, or on sudden death *)
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
            Target : TPoint;
            Kind: TGearType;
            Pos: Longword;
            doStep: TGearStepProcedure;
            Radius: LongInt;
            Angle, Power : Longword;
            DirAngle: real;
            Timer : LongWord;
            Elasticity: hwFloat;
            Friction  : hwFloat;
            Density   : hwFloat;
            Message, MsgParam : Longword;
            Hedgehog: PHedgehog;
            Health, Damage, Karma: LongInt;
            CollisionIndex: LongInt;
            Tag: LongInt;
            Tex: PTexture;
            Z: Longword;
            CollisionMask: Word;
            LinkedGear: PGear;
            FlightTime: Longword;
            uid: Longword;
            ImpactSound: TSound; // first sound, others have to be after it in the sounds def.
            nImpactSounds: Word; // count of ImpactSounds
            SoundChannel: LongInt;
            PortalCounter: LongWord;  // Hopefully temporary, but avoids infinite portal loops in a guaranteed fashion.
            AIHints: LongWord; // hints for ai. haha ^^^^^^ temporary, sure
            IceTime: Longint; //time of ice beam with object some interaction  temporary
            IceState: Longint; //state of ice gun temporary
            LastDamage: PHedgehog;
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
            Effects: array[THogEffect] of LongInt;
            end;

    TTeam = record
            Clan: PClan;
            TeamName: shortstring;
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
            TagTeamIndex: Longword;
            CurrTeam: LongWord;
            ClanHealth: LongInt;
            ClanIndex: LongInt;
            TurnNumber: LongWord;
            Flawless: boolean;
            end;

     cdeclPtr = procedure; cdecl;
     cdeclIntPtr = procedure(num: LongInt); cdecl;
     functionDoublePtr = function: Double;

     TMobileRecord = record
                     getScreenDPI: functionDoublePtr;
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
            {sidStructure,} sidLandGun, sidIceGun, sidKnife);

    TMsgStrId = (sidStartFight, sidDraw, sidWinner, sidVolume, sidPaused,
            sidConfirm, sidSuddenDeath, sidRemaining, sidFuel, sidSync,
            sidNoEndTurn, sidNotYetAvailable, sidRoundSD, sidRoundsSD, sidReady, 
            sidBounce1, sidBounce2, sidBounce3, sidBounce4, sidBounce5, sidBounce,
            sidMute);

    // Events that are important for the course of the game or at least interesting for other reasons
    TEventId = (eidDied, eidDrowned, eidRoundStart, eidRoundWin, eidRoundDraw,
            eidNewHealthPack, eidNewAmmoPack, eidNewUtilityPack, eidTurnSkipped,
            eidHurtSelf, eidHomerun, eidGone);

    TGoalStrId = (gidCaption, gidSubCaption, gidForts, gidLowGravity, gidInvulnerable,
            gidVampiric, gidKarma, gidKing, gidPlaceHog, gidArtillery,
            gidSolidLand, gidSharedAmmo, gidMineTimer, gidNoMineTimer, 
            gidRandomMineTimer, gidDamageModifier, gidResetHealth, gidAISurvival, 
            gidInfAttack, gidResetWeps, gidPerHogAmmo, gidTagTeam);

    TLandArray = packed array of array of LongWord;
    TCollisionArray = packed array of array of Word;
    TPreview  = packed array[0..127, 0..31] of byte;
    TDirtyTag = packed array of array of byte;

    PWidgetMovement = ^TWidgetMovement;
    TWidgetMovement = record
        animate   : Boolean;
        source    : TPoint;
        target    : TPoint;
        startTime : Longword;
        end;

    POnScreenWidget = ^TOnScreenWidget;
    TOnScreenWidget = record
        show          : boolean;                      // if false widget will not be drawn
        sprite        : TSprite;                    // a convenience type
        frame         : TSDL_Rect;                   // graphical coordinates
        active        : TSDL_Rect;                  // active touch region
        fadeAnimStart : Longword;            // time the fade started, 0 means don't fade
        moveAnim      : TWidgetMovement;          // the animation associated to the widget
        end;

{$IFDEF SDL13}
    PTouch_Data = ^TTouch_Data;
    TTouch_Data = record
        id                       : TSDL_FingerId;
        x,y                      : LongInt;
        dx,dy                    : LongInt;
        historicalX, historicalY : LongInt;
        timeSinceDown            : Longword;
        pressedWidget            : POnScreenWidget;
        end;
{$ENDIF}

implementation

end.

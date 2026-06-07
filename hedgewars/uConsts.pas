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

unit uConsts;
interface

uses    SDLh, uFloat, GLunit;

{$INCLUDE "config.inc"}

const
    HDPIScaleFactor     =  1;

    // application return codes
    HaltNoError         =  0; // Hedgewars quits normally

    // error codes are placed in range 50-99 because that way then don't overlap with run-time errors of pascal
    // see https://www.freepascal.org/docs-html/user/userap4.html
    HaltUsageError      =  51; // Hedgewars was invoked incorrectly (e.g. bad command-line parameter)
    HaltFatalError      =  52; // Fatal internal error. See logs for more. Also reports error to frontend
    HaltStartupError    =  53; // Failure loading critical resources
    HaltFatalErrorNoIPC =  54; // Fatal internal error, IPC socket is not available

    // for automatic tests
    HaltTestSuccess     =  0;  // Test result: success
    HaltTestFailed      =  60; // Test result: failed
    HaltTestLuaError    =  61; // Lua runtime error
    HaltTestUnexpected  =  62; // Unexpected error


    // maximum ScreenFadeValue
    sfMax = 1000;

    // log message constants
    errmsgCreateSurface   = 'Error creating SDL surface';
    errmsgTransparentSet  = 'Error setting transparent color';
    errmsgUnknownCommand  = 'Unknown command';
    errmsgUnknownVariable = 'Unknown variable';
    errmsgIncorrectUse    = 'Incorrect use';
    errmsgShouldntRun     = 'This program shouldn''t be run manually';
    errmsgWrongNumber     = 'Wrong parameters number';
    errmsgLuaTestTerm     = 'WARNING: Lua test terminated before the test was properly finished with EndLuaTest()!';

    msgLoading           = 'Loading ';
    msgOK                = 'ok';
    msgFailed            = 'failed';
    msgFailedSize        = 'failed due to size';
    msgGettingConfig     = 'Getting game config...';

    // camera movement multipliers
    cameraKeyboardSpeed     : LongInt = 10;
    cameraKeyboardSpeedSlow : LongInt =  3;

    // color constants
    cWhiteColorChannels : TSDL_Color = (r:$FF; g:$FF; b:$FF; a:$FF);
    cNearBlackColorChannels : TSDL_Color = (r:$00; g:$00; b:$10; a:$FF);
    cInvertTextColorAt    : Byte = 64;

    cWhiteColor           : Longword = $FFFFFFFF; // white
    cNearBlackColor       : Longword = $FF000010; // nearly black

    capcolDefault         : Longword = $FFFFFFFF; // default caption color
    capcolSetting         : Longword = $FFCCCCCC; // caption color for changing client setting like volume or auto camera
    capcolDefaultLua      : Longword = $FFFFFFFF; // capcolDefault for Lua
    capcolSettingLua      : Longword = $CCCCCCFF; // capcolSetting for Lua

    cCentralMessageColor  : Longword = $FFFFFF00; // color of message in center of screen like quit or pause

    // reducedquality flags
    rqNone        = $00000000;  // don't reduce quality
    rqLowRes      = $00000001;  // use half land array
    rqBlurryLand  = $00000002;  // downscaled terrain
    rqNoBackground= $00000004;  // don't draw background
    rqSimpleRope  = $00000008;  // draw rope using lines only
    rq2DWater     = $00000010;  // disable 3D water effect
    rqAntiBoom    = $00000020;  // no fancy explosion effects
    rqKillFlakes  = $00000040;  // no flakes
    rqSlowMenu    = $00000080;  // ammomenu appears with no animation
    rqPlainSplash = $00000100;  // no droplets
    rqClampLess   = $00000200;  // don't clamp textures
    rqTooltipsOff = $00000400;  // tooltips are not drawn
    rqDesyncVBlank= $00000800;  // don't sync on vblank

    // image flags (for LoadImage())
    // TODO: discuss whether ifAlpha and ifColorKey are actually needed and if and where we want to support which colorkeys
    ifNone        = $00000000;  // nothing special
    ifAlpha       = $00000001;  // use alpha channel (unused right now?)
    ifCritical    = $00000002;  // image is critical for gameplay (exit game if unable to load)
    ifColorKey    = $00000004;  // image uses transparent pixels (color keying)
    ifIgnoreCaps  = $00000008;  // ignore hardware capabilities when loading (i.e. image will not be drawn using OpenGL)
    ifDigestAlpha = $00000010;  // add alpha channel to the digest
    ifDigestAll   = $00000020;  // add all channels to the digest

    // texture priority (allows OpenGL to keep frequently used textures in video memory more easily)
    tpLowest      = 0.00;
    tpLow         = 0.25;
    tpMedium      = 0.50;
    tpHigh        = 0.75;
    tpHighest     = 1.00;

// To allow these to layer, going to treat them as masks. The bottom byte is reserved for objects
// TODO - set lfBasic for all solid land, ensure all uses of the flags can handle multiple flag bits
// lfObject and lfBasic are only to be different *graphically*  in all other ways they should be treated the same
    lfBasic          = $8000;  // normal destructible terrain (mask.png: black)
    lfIndestructible = $4000;  // indestructible terrain (mask.png: red)
    lfObject         = $2000;  // destructible terrain, land object (mask.png: white)
    lfDamaged        = $1000;  //
    lfIce            = $0800;  // icy terrain (mask.png: blue)
    lfBouncy         = $0400;  // bouncy terrain (mask.png: green)
    lfLandMask       = $FF00;  // upper byte is used for terrain, not objects.

    lfCurHogCrate    = $0080;  // CurrentHedgehog, and crates, for convenience of AI.  Since an active hog would instantly collect the crate, this does not impact playj
    lfNotCurHogCrate = $FF7F;  // inverse of above. frequently used
    lfObjMask        = $007F;  // lower 7 bits used for hogs and explosives and mines 
    lfNotObjMask     = $FF80;  // inverse of above.

// breaking up hogs would makes it easier to differentiate 
// colliding with a hog from colliding with other things
// if overlapping hogs are less common than objects, the division can be altered.
// 3 bits for objects, 4 for hogs, that is, overlap 7 barrels/mines before possible dents, and 15 hogs.
    lfHHMask         = $000F;  // lower 4 bits used only for hogs
    lfNotHHObjMask   = $0070;  // next 3 bits used for non-hog things
    lfNotHHObjShift  = 4;
    lfNotHHObjSize   = lfNotHHObjMask shr lfNotHHObjShift;  

    // lower byte is for objects.
    // consists of 0-127 counted for object checkins and $80 as a bit flag for current hog.
    lfAllObjMask     = $00FF;  // lfCurHogCrate or lfObjMask

    lfAll            = $FFFF;  // everything



    cMaxPower     = 1500; // maximum power value for ammo that powers up
    cMaxAngle     = 2048; // maximum positive value for Gear angle
    cPowerDivisor = 1500;

    MAXNAMELEN = 192;
    MAXROPEPOINTS = 3840;
    MAXROPELAYERS = 16;

    {$IFNDEF PAS2C}
    // some opengl headers do not have these macros
    GL_BGR              = $80E0;
    GL_BGRA             = $80E1;
    GL_CLAMP_TO_EDGE    = $812F;
    GL_TEXTURE_PRIORITY = $8066;
    {$ENDIF}

    cVisibleWater       : LongInt = 128;
    cTeamHealthWidth    : LongInt = 128;
    cGearContourThreshold : LongInt = 179; // if water opacity is higher than this, draw contour for some gears when in water

    cifRandomize = $00000001;
    cifTheme     = $00000002;
    cifMap       = $00000002; // either theme or map (or map+theme)
    cifAllInited = cifRandomize or cifTheme or cifMap;

    RGB_LUMINANCE_RED    = 0.212671;
    RGB_LUMINANCE_GREEN  = 0.715160;
    RGB_LUMINANCE_BLUE   = 0.072169;

    // hedgehog info
    cMaxTeams        = 8; // maximum number of teams
    cMaxHHIndex      = 7; // maximum hedgehog index (counting starts at 0)
                          // NOTE: If you change cMaxHHIndex, also change cMaxHogHealth!
    cMaxHHs          = cMaxTeams * (cMaxHHIndex+1); // maximum number of hogs

    cClanColors      = 9; // number of possible clan colors

    cMaxEdgePoints = 32768;

    cBorderWidth = 6; // width of indestructible border
                      // width of 3 allowed hogs to be knocked through with grenade
    cCloudOffset = 1184; // Y offset for clouds (cloud height = LAND_HEIGHT-cCloudOffset)

    cHHRadius = 9; // hedgehog radius
    cHHStepTicks = 29;

    cMaxHogHealth = 268435455; // maximum hedgehog health
    // cMaxHogHealth was calculated by: High(LongInt) div (cMaxHHIndex+1);

    ouchDmg = 55;        // least amount of damage a hog must take in one blow for sndOuch to play

    // Z levels
    cHHZ = 1000;
    cCurrHHZ = Succ(cHHZ);

    // some gear constants
    cBarrelHealth = 60;  // initial barrel health
    cSentryHealth = 60;  // initial sentry health
    cShotgunRadius = 22; // radius of land a shotgun shot destroys
    cBlowTorchC    = 6;  // blow torch gear radius component (added to cHHRadius to get the full radius)
    cakeDmg =   75;      // default cake damage

    // key stuff
    cKeyMaxIndex = 1600;
    cKbdMaxIndex = 65536;//need more room for the modifier keys

    cDefaultBuildMaxDist = 256; // default max. building distance with girder/rubber
    cResurrectorDist = 100; // effect distance of resurrector
    cSeductionDist = 250; // effect distance of seduction

    ExtraTime = 30000; // amount of time (ms) given for using Extra Time
    MaxMoreWindTime = 5000; // amount of time (ms) for land objects like gfMine to be affected after end of turn

    // do not change this value
    cDefaultZoomLevel = 2.0; // 100% zoom

    // Maximum camera positions, values are "pixels outside the mainland"
    cCamLimitX = 1920; // X (left/right) camera limit, no border. Note: Influences sndFlyAway
                       // Note: Also make sure it's far enough from airplane spawn
    cCamLimitY = 2048; // Top Y camera limit, no border
    cCamLimitBorderX = 1920; // X (left/right) camera limit, with border
    cCamLimitBorderY = 2048; // Top Y camera limit, with border

    cFontPxToPtRatio   = 1.3281472327365;
    cBaseChatFontHeight = 12;
    cChatScaleRelDelta = 0.1;
    cMinChatScaleValue = 0.8;
    cMaxChatScaleValue = 4.0;

    cDefaultUIScaleLevel = 1.0;

    // game flags
    gfAny                = $FFFFFFFF; // mask for all possible gameflags
    gfOneClanMode        = $00000001; // Game does not end if there's only one clan in play. For missions
    gfMultiWeapon        = $00000002; // Enter multishoot mode after attack with infinite shots. For target practice
    gfSolidLand          = $00000004; // (almost) indestrutible land
    gfBorder             = $00000008; // border at top, left and right
    gfDivideTeams        = $00000010; // each clan spawns their hogs on own side of terrain
    gfLowGravity         = $00000020; // low gravity
    gfLaserSight         = $00000040; // laser sight for all
    gfInvulnerable       = $00000080; // invulerable for all
    gfResetHealth        = $00000100; // heal hogs health up to InitialHealth each turn
    gfVampiric           = $00000200; // vampirism for all
    gfKarma              = $00000400; // receive damage you deal
    gfArtillery          = $00000800; // hogs can't walk
    gfSwitchHog          = $00001000; // free switch hog at turn start
    gfRandomOrder        = $00002000; // hogs play in random order
    gfKing               = $00004000; // King Mode
    gfPlaceHog           = $00008000; // place all hogs at game start
    gfSharedAmmo         = $00010000; // ammo is shared per-clan
    gfDisableGirders     = $00020000; // disable land girders
    gfDisableLandObjects = $00040000; // disable land objects
    gfAISurvival         = $00080000; // AI is revived
    gfInfAttack          = $00100000; // infinite attack
    gfResetWeps          = $00200000; // reset weapons each turn
    gfPerHogAmmo         = $00400000; // each hog has its own ammo
    gfDisableWind        = $00800000; // don't automatically change wind
    gfMoreWind           = $01000000; // wind influences most gears
    gfTagTeam            = $02000000; // hogs of same clan share their turn time
    gfBottomBorder       = $04000000; // border at bottom
    gfShoppaBorder       = $08000000; // Surround terrain with fancy "security border". Pure eye candy
    // NOTE: When adding new game flags, ask yourself
    // if a "game start notice" would be useful. If so,
    // add one in uWorld.pas - look for "AddGoal".

    // gear states
    gstDrowning       = $00000001; // drowning
    gstHHDriven       = $00000002; // hog is controlled by current player
    gstMoving         = $00000004; // moving
    gstAttacked       = $00000008; // after attack
    gstAttacking      = $00000010; // while attacking
    gstCollision      = $00000020; // it has *just* collided
    gstChooseTarget   = $00000040; // choosing target
    gstHHJumping      = $00000100; // hog is doing long jump
    gsttmpFlag        = $00000200; // temporary wildcard flag, use it for anything you want
    gstHHThinking     = $00000800; // AI hog is thinking
    gstNoDamage       = $00001000; // gear is immune to damage
    gstHHHJump        = $00002000; // hog is doing high jump
    gstAnimation      = $00004000; // hog is playing an animation
    gstHHDeath        = $00008000; // hog is dying
    gstWinner         = $00010000; // indicates if hog did well
    gstWait           = $00020000;
    gstNotKickable    = $00040000; // gear cannot be pushed by forces
    gstLoser          = $00080000; // indicates if hog screwed up
    gstHHGone         = $00100000; // hog is gone (teamgone event)
    gstInvisible      = $00200000; // invisible
    gstSubmersible    = $00400000; // can survive in water
    gstFrozen         = $00800000; // frozen
    gstNoGravity      = $01000000; // ignores gravity
    gstInBounceEdge   = $02000000; // spawned in bounce edge

    // gear messages
    gmLeft           = $00000001; // left
    gmRight          = $00000002; // right
    gmUp             = $00000004; // up
    gmDown           = $00000008; // down
    gmSwitch         = $00000010; // switch hedgehog
    gmAttack         = $00000020; // attack
    gmLJump          = $00000040; // long jump
    gmHJump          = $00000080; // high jump
    gmDestroy        = $00000100; // request to self-destruct
    gmSlot           = $00000200; // slot key; with param
    gmWeapon         = $00000400; // direct weapon selection (SetWeapon); with param
    gmTimer          = $00000800; // set timer; with param
    gmAnimate        = $00001000; // start animation; with param
    gmPrecise        = $00002000; // precise aim

    // gmAddToList and gmRemoveFromList are used when changing order of gears in the gear list. They are used together when changing a gear's Z (drawing order)
    gmRemoveFromList = $00004000; // remove gear from gear list
    gmAddToList      = $00008000; // add gear to gear list

    gmDelete         = $00010000; // delete gear
    gmAllStoppable = gmLeft or gmRight or gmUp or gmDown or gmAttack or gmPrecise;

    // ammo slots
    cMaxSlotIndex       = 10; // maximum slot index (including hidden slot) (row in ammo menu)
    cHiddenSlotIndex    = cMaxSlotIndex; // slot for hidden ammo types, not visible and has no key
    cMaxSlotAmmoIndex   = 5; // maximum index for ammos per slot (column in ammo menu)

    // AI hints to be set for any gear
    aihUsualProcessing    = $00000000; // treat gear as usual
    aihDoesntMatter       = $00000001; // ignore gear in attack calculations and don't intentionally attack it
    aihAmmosChanged       = $00000002; // set when ammos were changed within this turn but not processed yet

    // ammo properties
    ammoprop_Timerable    = $00000001; // can set timer
    ammoprop_Power        = $00000002; // can power up fire strength
    ammoprop_NeedTarget   = $00000004; // must select target
    ammoprop_ForwMsgs     = $00000008; // received gear messages are forwarded to the spawned gear
    ammoprop_AttackInMove = $00000010; // can attack while moving / in mid-air
    ammoprop_DoesntStopTimerWhileAttacking
                          = $00000020; // doesn't stop timer while attacker is attacking
    ammoprop_NoCrosshair  = $00000040; // no crosshair rendered
    ammoprop_AttackingPut = $00000080; // selecting a target is considered an attack
    ammoprop_DontHold     = $00000100; // don't keep ammo selected in next turn
    ammoprop_AltAttack    = $00000200; // ammo can equip alternate ammo (ammoprop_AltUse)
    ammoprop_AltUse       = $00000400; // ammo can be equipped by an ammo with ammoprop_AltAttack
    ammoprop_NotBorder    = $00000800; // ammo is not available if map has border
    ammoprop_Utility      = $00001000; // ammo is considered an utility instead of a weapon
    ammoprop_Effect       = $00002000; // ammo is considered an effect like extra time or vampirism
    ammoprop_SetBounce    = $00004000; // can set bounciness
    ammoprop_NeedUpDown   = $00008000; // used by TouchInterface to show or hide up/down widgets
    ammoprop_OscAim       = $00010000; // oscillating aim
    ammoprop_NoMoveAfter  = $00020000; // can't move after attacking
    ammoprop_Track        = $00040000; // ammo follows the landscape, used by AI
    ammoprop_DoesntStopTimerInMultiShoot
                          = $00080000; // doesn't stop timer after entering multi-shoot mode
    ammoprop_DoesntStopTimerWhileAttackingInInfAttackMode
                          = $00100000; // doesn't stop timer while Attacking gear msg is set and inf. attack mode is on
    ammoprop_ForceTurnEnd = $00200000; // always ends turn after usage, ignoring inf. attack
    ammoprop_NoTargetAfter= $00400000; // disable target selection after attack
    ammoprop_NoWrapTarget = $00800000; // allow to select target beyond wrap world edge limits
    ammoprop_ShowSelIcon  = $01000000; // show icon when selected
    ammoprop_NoRoundEnd   = $10000000; // ammo doesn't end turn

    AMMO_INFINITE = 100;               // internal representation of infinite ammo count
    AMMO_FINITE_MAX = 99;              // maximum possible finite ammo count

    JETPACK_FUEL_INFINITE : LongInt = Low(LongInt); // internal representation of infinite jetpack fuel
    BIRDY_ENERGY_INFINITE : LongInt = Low(LongInt); // as above, but for Birdy

    // Special msgParam value used internally for invalid/non-existing value
    // Must not be sent over the network!
    MSGPARAM_INVALID = High(LongWord);

    // raw probability values for crate drops
    probabilityLevels: array [0..8] of LongWord = (0,20,30,60,100,200,400,600,800);

    // raw bounciness values for each of the player-selectable bounciness levels
    defaultBounciness = 1000;
    bouncinessLevels: array [0..4] of LongWord = (350, 700, defaultBounciness, 2000, 4000);

    // explosion flags
    // By default, an explosion removes land, damages and pushes gears,
    // spawns an explosion animation and plays no sound.
    //EXPLAllDamageInRadius = $00000001;  Completely unused for ages
    EXPLAutoSound         = $00000002; // enable sound (if appropriate)
    EXPLNoDamage          = $00000004; // don't damage gears
    EXPLDoNotTouchHH      = $00000008; // don't push hogs
    EXPLDontDraw          = $00000010; // don't remove land
    EXPLNoGfx             = $00000020; // don't spawn visual effects
    EXPLPoisoned          = $00000040; // poison hogs in effect radius
    EXPLDoNotTouchAny     = $00000080; // don't push anything
    EXPLForceDraw         = $00000100; // remove land even with gfSolidLand

    // Pos flags for gtCase
    posCaseAmmo    = $00000001; // ammo crate
    posCaseHealth  = $00000002; // health crate
    posCaseUtility = $00000004; // utility crate
    posCaseDummy   = $00000008; // dummy crate
    posCaseExplode = $00000010; // crate explodes when touched
    posCasePoison  = $00000020; // crate poisons hog when touched

    cCaseHealthRadius = 14;

    // hog tag mask
    //htNone        = $00;
    htTeamName    = $01;
    htName        = $02;
    htHealth      = $04;
    htTransparent = $08;

    NoPointX = Low(LongInt); // special value for CursorX/CursorY if cursor's disabled
    cTargetPointRef : TPoint = (x: NoPointX; y: 0);

    kSystemSoundID_Vibrate = $00000FFF;

    cMinPlayWidth = 200;
    cWorldEdgeDist = 200;

    cMaxLaserSightWraps = 1; // maximum number of world wraps of laser sight

    cMaxTurnTime = Pred(High(LongInt)); // maximum possible turn time

var
    cTeamHealthHeight,
    cFontBorder,
    cFontPadding: LongInt;

    cAirPlaneSpeed: hwFloat;
    cBombsSpeed   : hwFloat;

           _1div1024,
          _1div10000,
          _1div50000,
         _1div100000,
              _1div3,
                hwPi,
           _0_000004,
           _0_000064,
             _0_0002,
             _0_0005,
              _0_001,
              _0_003,
             _0_0032,
              _0_004,
              _0_005,
              _0_008,
               _0_01,
             _0_0128,
               _0_02,
               _0_03,
               _0_05,
               _0_07,
               _0_08,
                _0_1,
               _0_15,
               _0_17,
                _0_2,
               _0_25,
                _0_3,
               _0_35,
              _0_375,
               _0_39,
                _0_4,
               _0_45,
                _0_5,
               _0_55,
                _0_6,
               _0_64,
                _0_7,
                _0_8,
               _0_84,
               _0_87,
                _0_9,
               _0_93,
               _0_96,
              _0_995,
              _0_999,
                  _0,
                  _1,
                _1_2,
                _1_5,
                _1_6,
                _1_9,
                  _2,
                _2_4,
                  _3,
                _3_2,
                 _PI,
                  _4,
                _4_5,
                  _5,
                  _6,
                _6_4,
                  _7,
                 _10,
                 _12,
                 _16,
                 _19,
                 _20,
                 _24,
                 _25,
                 _30,
                 _40,
                 _41,
                 _49,
                 _50,
                 _70,
                 _90,
                _128,
                _180,
                _250,
                _256,
                _300,
                _360,
                _450,
                _500,
                _900,
               _1000,
               _1024,
               _2048,
               _4096,
              _10000,
             cLittle,
             cHHKick: hwFloat;

implementation
uses uRust;

initialization

    cTeamHealthHeight:= round(19 * HDPIScaleFactor);
    cFontBorder:= round(2 * HDPIScaleFactor);
    cFontPadding:= round(2 * HDPIScaleFactor);

    cAirPlaneSpeed:= hwf_raw(false, 3006477107);
    cBombsSpeed:= hwf_raw(false, 429496729);

   _1div1024:= hwf_new(1, 1024);
  _1div10000:= hwf_new(1, 10000);
  _1div50000:= hwf_new(1, 50000);
 _1div100000:= hwf_new(1, 100000);
      _1div3:= hwf_new(1, 3);
        hwPi:= hwf_raw(false, 13493037704);
   _0_000004:= hwf_new(1, 250000);
   _0_000064:= hwf_new(1, 15625);
     _0_0002:= hwf_new(1, 5000);
     _0_0005:= hwf_new(1, 2000);
      _0_001:= hwf_new(1, 1000);
      _0_003:= hwf_new(3, 1000);
     _0_0032:= hwf_new(32, 10000);
      _0_004:= hwf_new(4, 1000);
      _0_005:= hwf_new(5, 1000);
      _0_008:= hwf_new(8, 1000);
       _0_01:= hwf_new(1, 100);
     _0_0128:= hwf_new(128, 10000);
       _0_02:= hwf_new(2, 100);
       _0_03:= hwf_new(3, 100);
       _0_05:= hwf_new(5, 100);
       _0_07:= hwf_new(7, 100);
       _0_08:= hwf_new(8, 100);
        _0_1:= hwf_new(1, 10);
       _0_15:= hwf_new(15, 100);
       _0_17:= hwf_new(17, 100);
        _0_2:= hwf_new(2, 10);
       _0_25:= hwf_new(1, 4);
        _0_3:= hwf_new(3, 10);
       _0_35:= hwf_new(35, 100);
      _0_375:= hwf_new(3, 8);
       _0_39:= hwf_new(39, 100);
        _0_4:= hwf_new(4, 10);
       _0_45:= hwf_new(45, 100);
        _0_5:= hwf_new(1, 2);
       _0_55:= hwf_new(55, 100);
        _0_6:= hwf_new(6, 10);
       _0_64:= hwf_new(64, 100);
        _0_7:= hwf_new(7, 10);
        _0_8:= hwf_new(8, 10);
       _0_84:= hwf_new(84, 100);
       _0_87:= hwf_new(87, 100);
        _0_9:= hwf_new(9, 10);
       _0_93:= hwf_new(93, 100);
       _0_96:= hwf_new(96, 100);
      _0_995:= hwf_new(995, 1000);
      _0_999:= hwf_new(999, 1000);
          _0:= hwf_raw(false, 0);
          _1:= hwf_new(1, 1);
        _1_2:= hwf_new(12, 10);
        _1_5:= hwf_new(15, 10);
        _1_6:= hwf_new(16, 10);
        _1_9:= hwf_new(19, 10);
          _2:= hwf_new(2, 1);
        _2_4:= hwf_new(24, 10);
          _3:= hwf_new(3, 1);
        _3_2:= hwf_new(32, 10);
         _PI:= hwf_raw(false, 13493037704);
          _4:= hwf_new(4, 1);
        _4_5:= hwf_new(45, 10);
          _5:= hwf_new(5, 1);
          _6:= hwf_new(6, 1);
        _6_4:= hwf_new(64, 10);
          _7:= hwf_new(7, 1);
         _10:= int2hwFloat(10);
         _12:= int2hwFloat(12);
         _16:= int2hwFloat(16);
         _19:= int2hwFloat(19);
         _20:= int2hwFloat(20);
         _24:= int2hwFloat(24);
         _25:= int2hwFloat(25);
         _30:= int2hwFloat(30);
         _40:= int2hwFloat(40);
         _41:= int2hwFloat(41);
         _49:= int2hwFloat(49);
         _50:= int2hwFloat(50);
         _70:= int2hwFloat(70);
         _90:= int2hwFloat(90);
        _128:= int2hwFloat(128);
        _180:= int2hwFloat(180);
        _250:= int2hwFloat(250);
        _256:= int2hwFloat(256);
        _300:= int2hwFloat(300);
        _360:= int2hwFloat(360);
        _450:= int2hwFloat(450);
        _500:= int2hwFloat(500);
        _900:= int2hwFloat(900);
       _1000:= int2hwFloat(1000);
       _1024:= int2hwFloat(1024);
       _2048:= int2hwFloat(2048);
       _4096:= int2hwFloat(4096);
      _10000:= int2hwFloat(10000);

     cLittle:= hwf_min_positive();
     cHHKick:= hwf_new(1, 100);  // _0_01

end.

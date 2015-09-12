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
    HaltNoError         =  0;
    HaltUsageError      =  1;
    HaltFatalError      =  2;
    HaltStartupError    =  3;
    HaltFatalErrorNoIPC =  4;

    // for automatic tests
    HaltTestSuccess     =  0;
    HaltTestFailed      =  10;
    HaltTestLuaError    =  11;
    HaltTestUnexpected  =  12;


    sfMax = 1000;

    // message constants
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
    cameraKeyboardSpeed : ShortInt = 10;

    // color constants
    cWhiteColorChannels : TSDL_Color = (r:$FF; g:$FF; b:$FF; a:$FF);
    cNearBlackColorChannels : TSDL_Color = (r:$00; g:$00; b:$10; a:$FF);

    cWhiteColor           : Longword = $FFFFFFFF;
    cYellowColor          : Longword = $FFFFFF00;
    cNearBlackColor       : Longword = $FF000010;

{$WARNINGS OFF}
    cAirPlaneSpeed: hwFloat = (isNegative: false; QWordValue:   3006477107); // 1.4
    cBombsSpeed   : hwFloat = (isNegative: false; QWordValue:    429496729);
{$WARNINGS ON}

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
    ifNone        = $00000000;  // nothing special
    ifAlpha       = $00000001;  // use alpha channel (unused right now?)
    ifCritical    = $00000002;  // image is critical for gameplay (exit game if unable to load)
    ifTransparent = $00000004;  // image uses transparent pixels (color keying)
    ifIgnoreCaps  = $00000008;  // ignore hardware capabilities when loading (i.e. image will not be drawn using OpenGL)

    // texture priority (allows OpenGL to keep frequently used textures in video memory more easily)
    tpLowest      = 0.00;
    tpLow         = 0.25;
    tpMedium      = 0.50;
    tpHigh        = 0.75;
    tpHighest     = 1.00;

// To allow these to layer, going to treat them as masks. The bottom byte is reserved for objects
// TODO - set lfBasic for all solid land, ensure all uses of the flags can handle multiple flag bits
// lfObject and lfBasic are only to be different *graphically*  in all other ways they should be treated the same
    lfBasic          = $8000;  // black
    lfIndestructible = $4000;  // red
    lfObject         = $2000;  // white
    lfDamaged        = $1000;  //
    lfIce            = $0800;  // blue
    lfBouncy         = $0400;  // green
    lfLandMask       = $FF00;  // upper byte is used for terrain, not objects.

    lfCurrentHog     = $0080;  // CurrentHog.  It is also used to flag crates, for convenience of AI.  Since an active hog would instantly collect the crate, this does not impact play
    lfNotCurrentMask = $FF7F;  // inverse of above. frequently used
    lfObjMask        = $007F;  // lower 7 bits used for hogs
    lfNotObjMask     = $FF80;  // inverse of above.
    // lower byte is for objects.
    // consists of 0-127 counted for object checkins and $80 as a bit flag for current hog.
    lfAllObjMask     = $00FF;  // lfCurrentHog or lfObjMask


    cMaxPower     = 1500;
    cMaxAngle     = 2048;
    cPowerDivisor = 1500;

    MAXNAMELEN = 192;
    MAXROPEPOINTS = 3840;

    {$IFNDEF PAS2C}
    // some opengl headers do not have these macros
    GL_BGR              = $80E0;
    GL_BGRA             = $80E1;
    GL_CLAMP_TO_EDGE    = $812F;
    GL_TEXTURE_PRIORITY = $8066;
    {$ENDIF}

    cVisibleWater       : LongInt = 128;
    cTeamHealthWidth    : LongInt = 128;

    cifRandomize = $00000001;
    cifTheme     = $00000002;
    cifMap       = $00000002; // either theme or map (or map+theme)
    cifAllInited = cifRandomize or cifTheme or cifMap;

    RGB_LUMINANCE_RED    = 0.212671;
    RGB_LUMINANCE_GREEN  = 0.715160;
    RGB_LUMINANCE_BLUE   = 0.072169;

    cMaxTeams        = 8;
    cMaxHHIndex      = 7;
    cMaxHHs          = 48;

    cMaxEdgePoints = 32768;

    cHHRadius = 9;
    cHHStepTicks = 29;

    cHHZ = 1000;
    cCurrHHZ = Succ(cHHZ);

    cBarrelHealth = 60;
    cShotgunRadius = 22;
    cBlowTorchC    = 6;
    cakeDmg =   75;

    cKeyMaxIndex = 1600;
    cKbdMaxIndex = 65536;//need more room for the modifier keys

    cFontBorder = 2;

    cDefaultBuildMaxDist = 256;

    // do not change this value
    cDefaultZoomLevel = 2.0;

    // game flags
    gfAny                = $FFFFFFFF;
    gfOneClanMode        = $00000001;           // used in trainings
    gfMultiWeapon        = $00000002;           // used in trainings
    gfSolidLand          = $00000004;
    gfBorder             = $00000008;
    gfDivideTeams        = $00000010;
    gfLowGravity         = $00000020;
    gfLaserSight         = $00000040;
    gfInvulnerable       = $00000080;
    gfResetHealth        = $00000100;
    gfVampiric           = $00000200;
    gfKarma              = $00000400;
    gfArtillery          = $00000800;
    gfForts              = $00001000;
    gfRandomOrder        = $00002000;
    gfKing               = $00004000;
    gfPlaceHog           = $00008000;
    gfSharedAmmo         = $00010000;
    gfDisableGirders     = $00020000;
    gfDisableLandObjects = $00040000;
    gfAISurvival         = $00080000;
    gfInfAttack          = $00100000;
    gfResetWeps          = $00200000;
    gfPerHogAmmo         = $00400000;
    gfDisableWind        = $00800000;
    gfMoreWind           = $01000000;
    gfTagTeam            = $02000000;
    gfBottomBorder       = $04000000;
    gfShoppaBorder       = $08000000;
    // NOTE: When adding new game flags, ask yourself
    // if a "game start notice" would be useful. If so,
    // add one in uWorld.pas - look for "AddGoal".

    // gear states
    gstDrowning       = $00000001;
    gstHHDriven       = $00000002;
    gstMoving         = $00000004;
    gstAttacked       = $00000008;
    gstAttacking      = $00000010;
    gstCollision      = $00000020;
    gstChooseTarget   = $00000040;
    gstHHJumping      = $00000100;
    gsttmpFlag        = $00000200;
    gstHHThinking     = $00000800;
    gstNoDamage       = $00001000;
    gstHHHJump        = $00002000;
    gstAnimation      = $00004000;
    gstHHDeath        = $00008000;
    gstWinner         = $00010000;  // this, along with gstLoser, is good for indicating hedgies know they screwed up
    gstWait           = $00020000;
    gstNotKickable    = $00040000;
    gstLoser          = $00080000;
    gstHHGone         = $00100000;
    gstInvisible      = $00200000;
    gstSubmersible    = $00400000;
    gstFrozen         = $00800000;
    gstNoGravity      = $01000000;

    // gear messages
    gmLeft           = $00000001;
    gmRight          = $00000002;
    gmUp             = $00000004;
    gmDown           = $00000008;
    gmSwitch         = $00000010;
    gmAttack         = $00000020;
    gmLJump          = $00000040;
    gmHJump          = $00000080;
    gmDestroy        = $00000100;
    gmSlot           = $00000200; // with param
    gmWeapon         = $00000400; // with param
    gmTimer          = $00000800; // with param
    gmAnimate        = $00001000; // with param
    gmPrecise        = $00002000;

    gmRemoveFromList = $00004000;
    gmAddToList      = $00008000;
    gmDelete         = $00010000;
    gmAllStoppable = gmLeft or gmRight or gmUp or gmDown or gmAttack or gmPrecise;

    cMaxSlotIndex       = 9;
    cMaxSlotAmmoIndex   = 5;

    // ai hints
    aihUsualProcessing    = $00000000;
    aihDoesntMatter       = $00000001;

    // ammo properties
    ammoprop_Timerable    = $00000001;
    ammoprop_Power        = $00000002;
    ammoprop_NeedTarget   = $00000004;
    ammoprop_ForwMsgs     = $00000008;
    ammoprop_AttackInMove = $00000010;
    ammoprop_DoesntStopTimerWhileAttacking
                          = $00000020;
    ammoprop_NoCrosshair  = $00000040;
    ammoprop_AttackingPut = $00000080;
    ammoprop_DontHold     = $00000100;
    ammoprop_AltAttack    = $00000200;
    ammoprop_AltUse       = $00000400;
    ammoprop_NotBorder    = $00000800;
    ammoprop_Utility      = $00001000;
    ammoprop_Effect       = $00002000;
    ammoprop_SetBounce    = $00004000;
    ammoprop_NeedUpDown   = $00008000;//Used by TouchInterface to show or hide up/down widgets
    ammoprop_OscAim       = $00010000;
    ammoprop_NoMoveAfter  = $00020000;
    ammoprop_Track        = $00040000;
    ammoprop_DoesntStopTimerInMultiShoot
                          = $00080000;
    ammoprop_NoRoundEnd   = $10000000;

    AMMO_INFINITE = 100;

    // explosion flags
    //EXPLAllDamageInRadius = $00000001;  Completely unused for ages
    EXPLAutoSound         = $00000002;
    EXPLNoDamage          = $00000004;
    EXPLDoNotTouchHH      = $00000008;
    EXPLDontDraw          = $00000010;
    EXPLNoGfx             = $00000020;
    EXPLPoisoned          = $00000040;
    EXPLDoNotTouchAny     = $00000080;

    posCaseAmmo    = $00000001;
    posCaseHealth  = $00000002;
    posCaseUtility = $00000004;
    posCaseDummy   = $00000008;
    posCaseExplode = $00000010;
    posCasePoison  = $00000020;

    cCaseHealthRadius = 14;

    // hog tag mask
    //htNone        = $00;
    htTeamName    = $01;
    htName        = $02;
    htHealth      = $04;
    htTransparent = $08;

    NoPointX = Low(LongInt);
    cTargetPointRef : TPoint = (x: NoPointX; y: 0);

    kSystemSoundID_Vibrate = $00000FFF;

    cMinPlayWidth = 200;
    cWorldEdgeDist = 200;

implementation

end.

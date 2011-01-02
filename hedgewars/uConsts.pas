(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2008 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uConsts;
interface

uses    SDLh, uFloat, GLunit;


{$INCLUDE "config.inc"}

// typed const is a variable despite const qualifier
// in freepascal you may actually use var for the same purpose

const
    sfMax = 1000;
    cDefaultParamNum = 16;

    // message constants
    errmsgCreateSurface   = 'Error creating SDL surface';
    errmsgTransparentSet  = 'Error setting transparent color';
    errmsgUnknownCommand  = 'Unknown command';
    errmsgUnknownVariable = 'Unknown variable';
    errmsgIncorrectUse    = 'Incorrect use';
    errmsgShouldntRun     = 'This program shouldn''t be run manually';
    errmsgWrongNumber     = 'Wrong parameters number';

    msgLoading           = 'Loading ';
    msgOK                = 'ok';
    msgFailed            = 'failed';
    msgFailedSize        = 'failed due to size';
    msgGettingConfig     = 'Getting game config...';

    // color constants
    cWhiteColorChannels : TSDL_Color = (r:$FF; g:$FF; b:$FF; unused:$FF);
    cNearBlackColorChannels : TSDL_Color = (r:$00; g:$00; b:$10; unused:$FF);

    cWhiteColor           : Longword = $FFFFFFFF;
    cYellowColor          : Longword = $FFFFFF00;
    cNearBlackColor       : Longword = $FF000010;
    cExplosionBorderColor : LongWord = $FF808080;

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
    lfBasic          = $8000;  // white
    lfIndestructible = $4000;  // red
    lfObject         = $2000;  // no idea
    lfDamaged        = $1000;  // no idea

    cMaxPower     = 1500;
    cMaxAngle     = 2048;
    cPowerDivisor = 1500;

    MAXNAMELEN = 192;
    MAXROPEPOINTS = 3840;

    // some opengl headers do not have these macros
    GL_BGR              = $80E0;
    GL_BGRA             = $80E1;
    GL_CLAMP_TO_EDGE    = $812F;
    GL_TEXTURE_PRIORITY = $8066;

    cSendCursorPosTime  : LongWord = 50;
    cVisibleWater       : LongInt = 128;
    cCursorEdgesDist    : LongInt = 100;
    cTeamHealthWidth    : LongInt = 128;
    cWaterOpacity       : byte = $80;
    cSDWaterOpacity     : byte = $80;

    cifRandomize = $00000001;
    cifTheme     = $00000002;
    cifMap       = $00000002; // either theme or map (or map+theme)
    cifAllInited = cifRandomize or cifTheme or cifMap;

    cTransparentColor: Longword = $00000000;

    cMaxTeams        = 8;
    cMaxHHIndex      = 7;
    cMaxHHs          = 48;
    cMaxSpawnPoints  = 1024;

    cMaxEdgePoints = 16384;

    cHHRadius = 9;
    cHHStepTicks = 29;

    cUsualZ = 500;
    cSmokeZ = 499;
    cHHZ = 1000;
    cCurrHHZ = Succ(cHHZ);
    cOnHHZ = 2000;

    cBarrelHealth = 60;
    cShotgunRadius = 22;
    cBlowTorchC    = 6;

    cKeyMaxIndex = 1023;

    // do not change this value
    cDefaultZoomLevel = 2.0;

{$IFDEF IPHONEOS}
    cMaxZoomLevel = 0.5;
    cMinZoomLevel = 3.5;
    cZoomDelta = 0.20;
{$ELSE}
    cMaxZoomLevel = 1.0;
    cMinZoomLevel = 3.0;
    cZoomDelta = 0.25;
{$ENDIF}

    cSendEmptyPacketTime = 1000;
    trigTurns = $80000001;

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
    // NOTE: When adding new game flags, ask yourself
    // if a "game start notice" would be useful. If so,
    // add one in uWorld.pas - look for "AddGoal".

    gstDrowning       = $00000001;
    gstHHDriven       = $00000002;
    gstMoving         = $00000004;
    gstAttacked       = $00000008;
    gstAttacking      = $00000010;
    gstCollision      = $00000020;
    gstHHChooseTarget = $00000040;
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

    gmLeft   = $00000001;
    gmRight  = $00000002;
    gmUp     = $00000004;
    gmDown   = $00000008;
    gmSwitch = $00000010;
    gmAttack = $00000020;
    gmLJump  = $00000040;
    gmHJump  = $00000080;
    gmDestroy= $00000100;
    gmSlot   = $00000200; // with param
    gmWeapon = $00000400; // with param
    gmTimer  = $00000800; // with param
    gmAnimate= $00001000; // with param
    gmPrecise= $00002000;
    gmAllStoppable = gmLeft or gmRight or gmUp or gmDown or gmAttack or gmPrecise;

    cMaxSlotIndex       = 9;
    cMaxSlotAmmoIndex   = 5;

    ammoprop_Timerable    = $00000001;
    ammoprop_Power        = $00000002;
    ammoprop_NeedTarget   = $00000004;
    ammoprop_ForwMsgs     = $00000008;
    ammoprop_AttackInMove = $00000010;
    ammoprop_NoCrosshair  = $00000040;
    ammoprop_AttackingPut = $00000080;
    ammoprop_DontHold     = $00000100;
    ammoprop_AltAttack    = $00000200;
    ammoprop_AltUse       = $00000400;
    ammoprop_NotBorder    = $00000800;
    ammoprop_Utility      = $00001000;
    ammoprop_Effect       = $00002000;
    ammoprop_NoRoundEnd=$10000000;

    AMMO_INFINITE = 100;

    EXPLAllDamageInRadius = $00000001;
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

    NoPointX = Low(LongInt);
    cTargetPointRef : TPoint = (X: NoPointX; Y: 0);

    // hog tag mask
    htNone        = $00;
    htTeamName    = $01;
    htName        = $02;
    htHealth      = $04;
    htTransparent = $08;



implementation

end.

(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004-2007 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uConsts;
interface
uses SDLh, uLocale;
{$INCLUDE options.inc}
{$INCLUDE proto.inc}
type TStuff     = (sConsoleBG, sPowerBar, sQuestion, sWindBar,
                   sWindL, sWindR, sRopeNode);

     TGameState = (gsLandGen, gsStart, gsGame, gsConsole, gsExit);

     TGameType  = (gmtLocal, gmtDemo, gmtNet, gmtSave, gmtLandPreview);

     TPathType  = (ptNone, ptData, ptGraphics, ptThemes, ptCurrTheme, ptTeams, ptMaps,
                   ptMapCurrent, ptDemos, ptSounds, ptGraves, ptFonts, ptForts,
                   ptLocale, ptAmmoMenu);

     TSprite    = (sprWater, sprCloud, sprBomb, sprBigDigit, sprFrame,
                   sprLag, sprArrow, sprGrenade, sprTargetP, sprUFO,
                   sprSmokeTrace, sprRopeHook, sprExplosion50, sprMineOff,
                   sprMineOn, sprCase, sprFAid, sprDynamite, sprPower,
                   sprClusterBomb, sprClusterParticle, sprFlame, sprHorizont,
                   sprSky, sprAMBorders, sprAMSlot, sprAMSlotName, sprAMAmmos,
                   sprAMSlotKeys, sprAMSelection, sprFinger, sprAirBomb,
                   sprAirplane, sprAmAirplane, sprAmGirder);

     TGearType  = (gtCloud, gtAmmo_Bomb, gtHedgehog, gtAmmo_Grenade, gtHealthTag,
                   gtGrave, gtUFO, gtShotgunShot, gtPickHammer, gtRope,
                   gtSmokeTrace, gtExplosion, gtMine, gtCase, gtDEagleShot, gtDynamite,
                   gtTeamHealthSorter, gtClusterBomb, gtCluster, gtShover, gtFlame,
                   gtFirePunch, gtATStartGame, gtATSmoothWindCh, gtATFinishGame,
                   gtParachute, gtAirAttack, gtAirBomb, gtBlowTorch, gtGirder);

     TGearsType = set of TGearType;

     TSound     = (sndGrenadeImpact, sndExplosion, sndThrowPowerUp, sndThrowRelease,
                   sndSplash, sndShotgunReload, sndShotgunFire, sndGraveImpact,
                   sndMineTick, sndPickhammer);

     TAmmoType  = (amGrenade, amClusterBomb, amBazooka, amUFO, amShotgun, amPickHammer,
                   amSkip, amRope, amMine, amDEagle, amDynamite, amFirePunch,
                   amBaseballBat, amParachute, amAirAttack, amMineStrike, amBlowTorch,
                   amGirder);

     THWFont    = (fnt16, fntBig);

     TCapGroup  = (capgrpGameState, capgrpAmmoinfo, capgrpNetSay, capgrpVolume);

     TStatInfoType = (siGameResult, siMaxStepDamage, siKilledHHs);

     THHFont    = record
                  Handle: PTTF_Font;
                  Height: LongInt;
                  style: LongInt;
                  Name: string[15];
                  end;

     TAmmo = record
             Propz: LongWord;
             Count: LongWord;
             NumPerTurn: LongWord;
             Timer: LongWord;
             Pos: LongWord;
             AmmoType: TAmmoType;
             end;


const
      errmsgCreateSurface   = 'Error creating SDL surface';
      errmsgTransparentSet  = 'Error setting transparent color';
      errmsgUnknownCommand  = 'Unknown command';
      errmsgUnknownVariable = 'Unknown variable';
      errmsgIncorrectUse    = 'Incorrect use';
      errmsgShouldntRun     = 'This program shouldn''t be run manually';

      msgLoading           = 'Loading ';
      msgOK                = 'ok';
      msgFailed            = 'failed';
      msgGettingConfig     = 'Getting game config...';

const
      cMaxPower     = 1500;
      cMaxAngle     = 2048;
      cPowerDivisor = 1500;
      
      MAXNAMELEN = 32;

      COLOR_LAND = $00FFFFFF;

      cifRandomize = $00000001;
      cifTheme     = $00000002;
      cifMap       = $00000002; // either theme or map (or map+theme)
      cifAllInited = cifRandomize or
                     cifTheme or
                     cifMap;

      cTransparentColor: Longword = $000000;

      cMaxHHIndex      = 7;
      cMaxHHs          = 30;
      cMaxSpawnPoints  = 1024;

      cMaxEdgePoints = 16384;

      cHHRadius = 9;
      cHHStepTicks = 38;
      cHHZ = 1000;
      cCurrHHZ = Succ(cHHZ);

      cKeyMaxIndex = 1023;

      cMaxCaptions = 4;

      cInactDelay = 1500;

      gfForts = $00000001;

      gstDrowning       = $00000001;
      gstHHDriven       = $00000002;
      gstMoving         = $00000004;
      gstAttacked       = $00000008;
      gstAttacking      = $00000010;
      gstCollision      = $00000020;
      gstHHChooseTarget = $00000040;
      gstFalling        = $00000080;
      gstHHJumping      = $00000100;
      gsttmpFlag        = $00000200;
      gstHHThinking     = $00000800;
      gstNoDamage       = $00001000;
      gstHHHJump        = $00002000;

      gm_Left   = $00000001;
      gm_Right  = $00000002;
      gm_Up     = $00000004;
      gm_Down   = $00000008;
      gm_Switch = $00000010;
      gm_Attack = $00000020;
      gm_LJump  = $00000040;
      gm_HJump  = $00000080;
      gm_Destroy= $00000100;

      cMaxSlotIndex       = 8;
      cMaxSlotAmmoIndex   = 2;

      ammoprop_Timerable    = $00000001;
      ammoprop_Power        = $00000002;
      ammoprop_NeedTarget   = $00000004;
      ammoprop_ForwMsgs     = $00000008;
      ammoprop_AttackInFall = $00000010;
      ammoprop_AttackInJump = $00000020;
      ammoprop_NoCrosshair  = $00000040;
      ammoprop_AttackingPut = $00000080;
      AMMO_INFINITE = High(LongWord);

      EXPLAllDamageInRadius = $00000001;
      EXPLAutoSound         = $00000002;
      EXPLNoDamage          = $00000004;
      EXPLDoNotTouchHH      = $00000008;
      EXPLDontDraw          = $00000010;

      posCaseAmmo    = $00000001;
      posCaseHealth  = $00000002;

      NoPointX = Low(LongInt);

      cHHFileName   = 'Hedgehog';
      cCHFileName   = 'Crosshair';
      cThemeCFGFilename = 'theme.cfg';

      Fontz: array[THWFont] of THHFont = (
                                         (Handle: nil;
                                          Height: 12;
                                          style: TTF_STYLE_NORMAL;
                                          Name: 'DejaVuSans.ttf'),
                                         (Handle: nil;
                                          Height: 24;
                                          style: TTF_STYLE_NORMAL;
                                          Name: 'DejaVuSans.ttf')
                                         );

      FontBorder = 2;

      PathPrefix: string = './';
      Pathz: array[TPathType] of string      = (
                                               '',                              // ptNone      
                                               '',                              // ptData
                                               'Graphics',                      // ptGraphics
                                               'Themes',                        // ptThemes
                                               'Themes/avematan',               // ptCurrTheme
                                               'Teams',                         // ptTeams
                                               'Maps',                          // ptMaps
                                               '',                              // ptMapCurrent
                                               'Demos',                         // ptDemos
                                               'Sounds',                        // ptSounds
                                               'Graphics/Graves',               // ptGraves
                                               'Fonts',                         // ptFonts
                                               'Forts',                         // ptForts
                                               'Locale',                        // ptLocale
                                               'Graphics/AmmoMenu'              // ptAmmoMenu
                                               );

      StuffLoadData: array[TStuff] of record
                                     FileName: String[31];
                                     Path    : TPathType;
                                     end = (
                                     (FileName:  'Console'; Path: ptGraphics     ),    // sConsoleBG
                                     (FileName: 'PowerBar'; Path: ptGraphics     ),    // sPowerBar
                                     (FileName: 'thinking'; Path: ptGraphics     ),    // sQuestion
                                     (FileName:  'WindBar'; Path: ptGraphics     ),    // sWindBar
                                     (FileName:    'WindL'; Path: ptGraphics     ),    // sWindL
                                     (FileName:    'WindR'; Path: ptGraphics     ),    // sWindR
                                     (FileName: 'RopeNode'; Path: ptGraphics     )     // sRopeNode
                                     );
      StuffPoz: array[TStuff] of TSDL_Rect = (
                                      (x: 256; y: 256; w: 256; h: 256), // sConsoleBG
                                      (x: 256; y: 768; w: 256; h:  32), // sPowerBar
                                      (x: 256; y: 512; w:  32; h:  32), // sQuestion
                                      (x: 256; y: 800; w: 151; h:  17), // sWindBar
                                      (x: 256; y: 817; w:  80; h:  13), // sWindL
                                      (x: 336; y: 817; w:  80; h:  13), // sWindR
                                      (x: 256; y: 544; w:   6; h:   6)  // sRopeNode
                                      );
      SpritesData: array[TSprite] of record
                     FileName: String[31];
                     Path, AltPath: TPathType;
                     Surface : PSDL_Surface;
                     Width, Height: LongInt;
                     hasAlpha: boolean;
                     end = (
                     (FileName: 'BlueWater'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width: 256; Height: 48; hasAlpha: false),// sprWater
                     (FileName:    'Clouds'; Path: ptCurrTheme; AltPath: ptGraphics; Surface: nil;
                     Width: 256; Height:128; hasAlpha: false),// sprCloud
                     (FileName:      'Bomb'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  16; Height: 16; hasAlpha: false),// sprBomb
                     (FileName: 'BigDigits'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha:  true),// sprBigDigit
                     (FileName:     'Frame'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:   4; Height: 32; hasAlpha:  true),// sprFrame
                     (FileName:       'Lag'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  65; Height: 65; hasAlpha:  true),// sprLag
                     (FileName:     'Arrow'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  16; Height: 16; hasAlpha: false),// sprCursor
                     (FileName:   'Grenade'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha: false),// sprGrenade
                     (FileName:   'Targetp'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha: false),// sprTargetP
                     (FileName:       'UFO'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha: false),// sprUFO
                     (FileName:'SmokeTrace'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha:  true),// sprSmokeTrace
                     (FileName:  'RopeHook'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha: false),// sprRopeHook
                     (FileName:    'Expl50'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  64; Height: 64; hasAlpha: false),// sprExplosion50
                     (FileName:   'MineOff'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  16; Height: 16; hasAlpha: false),// sprMineOff
                     (FileName:    'MineOn'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  16; Height: 16; hasAlpha: false),// sprMineOn
                     (FileName:      'Case'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha: false),// sprCase
                     (FileName:  'FirstAid'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  48; Height: 48; hasAlpha: false),// sprFAid
                     (FileName:  'dynamite'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha: false),// sprDynamite
                     (FileName:     'Power'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha:  true),// sprPower
                     (FileName:    'ClBomb'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  16; Height: 16; hasAlpha: false),// sprClusterBomb
                     (FileName:'ClParticle'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  16; Height: 16; hasAlpha: false),// sprClusterParticle
                     (FileName:     'Flame'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  16; Height: 16; hasAlpha: false),// sprFlame
                     (FileName:  'horizont'; Path: ptCurrTheme; AltPath: ptNone; Surface: nil;
                     Width:   0; Height:  0; hasAlpha: false),// sprHorizont
                     (FileName:       'Sky'; Path: ptCurrTheme; AltPath: ptNone; Surface: nil;
                     Width:   0; Height:  0; hasAlpha: false),// sprSky
                     (FileName: 'BrdrLines'; Path: ptAmmoMenu; AltPath: ptNone; Surface: nil;
                     Width: 202; Height:  1; hasAlpha: false),// sprAMBorders
                     (FileName:      'Slot'; Path: ptAmmoMenu; AltPath: ptNone; Surface: nil;
                     Width: 202; Height: 33; hasAlpha: false),// sprAMSlot
                     (FileName:  'AmmoName'; Path: ptAmmoMenu; AltPath: ptNone; Surface: nil;
                     Width: 202; Height: 33; hasAlpha: false),// sprAMSlotName
                     (FileName:     'Ammos'; Path: ptAmmoMenu; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha: false),// sprAMAmmos
                     (FileName:  'SlotKeys'; Path: ptAmmoMenu; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha: false),// sprAMSlotKeys
                     (FileName: 'Selection'; Path: ptAmmoMenu; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha: false),// sprAMSelection
                     (FileName:    'Finger'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 48; hasAlpha: false),// sprFinger
                     (FileName:   'AirBomb'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  32; Height: 32; hasAlpha: false),// sprAirBomb
                     (FileName:  'Airplane'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width: 125; Height: 42; hasAlpha: false),// sprAirplane
                     (FileName:'amAirplane'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width:  64; Height: 32; hasAlpha:  true),// sprAirplane
                     (FileName:  'amGirder'; Path: ptGraphics; AltPath: ptNone; Surface: nil;
                     Width: 160; Height:160; hasAlpha: false) // sprAmGirder
                     );
      Soundz: array[TSound] of record
                                       FileName: String[31];
                                       Path    : TPathType;
                                       id      : PMixChunk;
                                       lastChan: LongInt;
                                       end = (
                                       (FileName: 'grenadeimpact.ogg'; Path: ptSounds  ),// sndGrenadeImpact
                                       (FileName:     'explosion.ogg'; Path: ptSounds  ),// sndExplosion
                                       (FileName:  'throwpowerup.ogg'; Path: ptSounds  ),// sndThrowPowerUp
                                       (FileName:  'throwrelease.ogg'; Path: ptSounds  ),// sndThrowRelease
                                       (FileName:        'splash.ogg'; Path: ptSounds  ),// sndSplash
                                       (FileName: 'shotgunreload.ogg'; Path: ptSounds  ),// sndShotgunReload
                                       (FileName:   'shotgunfire.ogg'; Path: ptSounds  ),// sndShotgunFire
                                       (FileName:   'graveimpact.ogg'; Path: ptSounds  ),// sndGraveImpact
                                       (FileName:      'minetick.ogg'; Path: ptSounds  ),// sndMineTicks
                                       (FileName:    'pickhammer.ogg'; Path: ptSounds  ) // sndPickhammer
                                       );

      Ammoz: array [TAmmoType] of record
                                  NameId: TAmmoStrId;
                                  Probability, NumberInCase: Longword;
                                  Ammo: TAmmo;
                                  Slot: 0..cMaxSlotIndex;
                                  TimeAfterTurn: Longword;
                                  minAngle, maxAngle: Longword;
                                  PosCount: Longword;
                                  PosSprite: TSprite;
                                  end = (
                                  (NameId: sidGrenade;
                                   Probability: 0;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_Timerable or
                                                 ammoprop_Power;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 0;
                                          Timer: 3000;
                                          Pos: 0;
                                          AmmoType: amGrenade);
                                   Slot: 1;
                                   TimeAfterTurn: 3000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidClusterBomb;
                                   Probability: 100;
                                   NumberInCase: 3;
                                   Ammo: (Propz: ammoprop_Timerable or
                                                 ammoprop_Power;
                                          Count: 5;
                                          NumPerTurn: 0;
                                          Timer: 3000;
                                          Pos: 0;
                                          AmmoType: amClusterBomb);
                                   Slot: 1;
                                   TimeAfterTurn: 3000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidBazooka;
                                   Probability: 0;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_Power;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amBazooka);
                                   Slot: 0;
                                   TimeAfterTurn: 3000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidUFO;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_Power or
                                                 ammoprop_NeedTarget;
                                          Count: 2;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amUFO);
                                   Slot: 0;
                                   TimeAfterTurn: 3000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidShotgun;
                                   Probability: 0;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_ForwMsgs;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 1;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amShotgun);
                                   Slot: 2;
                                   TimeAfterTurn: 3000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidPickHammer;
                                   Probability: 0;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_ForwMsgs or
                                                 ammoprop_AttackInFall or
                                                 ammoprop_AttackInJump or
                                                 ammoprop_NoCrosshair;
                                          Count: 2;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amPickHammer);
                                   Slot: 6;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidSkip;
                                   Probability: 0;
                                   NumberInCase: 1;
                                   Ammo: (Propz: 0;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amSkip);
                                   Slot: 8;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidRope;
                                   Probability: 100;
                                   NumberInCase: 3;
                                   Ammo: (Propz: ammoprop_ForwMsgs or
                                                 ammoprop_AttackInFall or
                                                 ammoprop_AttackInJump;
                                          Count: 5;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amRope);
                                   Slot: 7;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: cMaxAngle div 2;
                                   PosCount: 1),
                                  (NameId: sidMine;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_NoCrosshair;
                                          Count: 2;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amMine);
                                   Slot: 4;
                                   TimeAfterTurn: 5000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidDEagle;
                                   Probability: 100;
                                   NumberInCase: 2;
                                   Ammo: (Propz: 0;
                                          Count: 3;
                                          NumPerTurn: 3;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amDEagle);
                                   Slot: 2;
                                   TimeAfterTurn: 3000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidDynamite;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_AttackInJump or
                                                 ammoprop_AttackInFall;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amDynamite);
                                   Slot: 4;
                                   TimeAfterTurn: 5000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidFirePunch;
                                   Probability: 0;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_ForwMsgs or
                                                 ammoprop_AttackInJump or
                                                 ammoprop_AttackInFall;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amFirePunch);
                                   Slot: 3;
                                   TimeAfterTurn: 3000;
                                   MinAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidBaseballBat;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: 0;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amBaseballBat);
                                   Slot: 3;
                                   TimeAfterTurn: 5000;
                                   minAngle: 0;
                                   maxAngle: cMaxAngle div 2;
                                   PosCount: 1),
                                  (NameId: sidParachute;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_ForwMsgs or
                                                 ammoprop_AttackInJump or
                                                 ammoprop_AttackInFall;
                                          Count: 2;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amParachute);
                                   Slot: 7;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 1),
                                  (NameId: sidAirAttack;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_NeedTarget or
                                                 ammoprop_AttackingPut;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amAirAttack);
                                   Slot: 5;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 2;
                                   PosSprite: sprAmAirplane),
                                  (NameId: sidMineStrike;
                                   Probability: 400;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_NeedTarget or
                                                 ammoprop_AttackingPut;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amMineStrike);
                                   Slot: 5;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 2;
                                   PosSprite: sprAmAirplane),
                                  (NameId: sidBlowTorch;
                                   Probability: 100;
                                   NumberInCase: 2;
                                   Ammo: (Propz: ammoprop_ForwMsgs;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amBlowTorch);
                                   Slot: 6;
                                   TimeAfterTurn: 3000;
                                   minAngle: 768;
                                   maxAngle: 1280;
                                   PosCount: 1),
                                  (NameId: sidGirder;
                                   Probability: 400;
                                   NumberInCase: 3;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_NeedTarget or
                                                 ammoprop_AttackingPut;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amGirder);
                                   Slot: 6;
                                   TimeAfterTurn: 3000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   PosCount: 8;
                                   PosSprite: sprAmGirder));

implementation

end.

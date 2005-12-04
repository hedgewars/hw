(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uConsts;
interface
uses SDLh;
{$INCLUDE options.inc}
type TStuff     = (sHorizont, sSky, sConsoleBG, sPowerBar, sQuestion, sWindBar,
                   sWindL, sWindR);
     TGameState = (gsLandGen, gsStart, gsGame, gsConsole, gsExit);
     TGameType  = (gmtLocal, gmtDemo, gmtNet);
     TPathType  = (ptData, ptGraphics, ptThemes, ptThemeCurrent, ptTeams, ptMaps,
                   ptMapCurrent, ptDemos, ptSounds, ptGraves, ptFonts, ptForts);
     TSprite    = (sprWater, sprCloud, sprBomb, sprBigDigit, sprFrame,
                   sprLag, sprArrow, sprGrenade, sprTargetP, sprUFO,
                   sprSmokeTrace, sprRopeHook, sprExplosion50, sprMineOff,
                   sprMineOn, sprCase);
     TGearType  = (gtCloud, gtAmmo_Bomb, gtHedgehog, gtAmmo_Grenade, gtHealthTag,
                   gtGrave, gtUFO, gtShotgunShot, gtActionTimer, gtPickHammer, gtRope,
                   gtSmokeTrace, gtExplosion, gtMine, gtCase);
     TGearsType = set of TGearType;
     TSound     = (sndGrenadeImpact, sndExplosion, sndThrowPowerUp, sndThrowRelease, sndSplash,
                   sndShotgunReload, sndShotgunFire, sndGraveImpact, sndMineTick);
     TAmmoType  = (amGrenade, amBazooka, amUFO, amShotgun, amPickHammer, amSkip, amRope,
                   amMine);
     THWFont    = (fnt16, fntBig);
     THHFont    = record
                  Handle: PTTF_Font;
                  Height: integer;
                  Name: string[15];
                  end;
     TAmmo = record
             Propz: LongWord;
             Count: LongWord;
             NumPerTurn: LongWord;
             Timer: LongWord;
             AmmoType: TAmmoType;
             end;


resourcestring
      errmsgCreateSurface   = 'Error creating DirectDraw7 surface';
      errmsgNoDesc          = 'Unknown error';
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
      cAppName  = 'hw';
      cAppTitle = 'hw';
      cNetProtoVersion = 1;

      rndfillstr = 'hw';

      cTransparentColor: Cardinal = $000000;

      cMaxHHIndex      = 9;
      cMaxHHs          = 20;
      cMaxSpawnPoints  = 64;
      cHHSurfaceWidth     = 512;
      cHHSurfaceHeigth    = 256;

      cMaxEdgePoints = 16384;

      cHHHalfHeight = 11;

      cKeyMaxIndex = 322;

      cMaxCaptions         = 4;

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
      gstOutOfHH        = $00000400;
      gstHHThinking     = $00000800;

      gtsStartGame      = 1;
      gtsSmoothWindCh   = 2;

      gm_Left   = $00000001;
      gm_Right  = $00000002;
      gm_Up     = $00000004;
      gm_Down   = $00000008;
      gm_Switch = $00000010;
      gm_Attack = $00000020;
      gm_LJump  = $00000040;
      gm_HJump  = $00000080;
      gm_Destroy= $00000100;

      cMaxSlotIndex       = 6;
      cMaxSlotAmmoIndex   = 1;

      ammoprop_Timerable    = $00000001;
      ammoprop_Power        = $00000002;
      ammoprop_NeedTarget   = $00000004;
      ammoprop_ForwMsgs     = $00000008;
      ammoprop_AttackInFall = $00000010;
      ammoprop_AttackInJump = $00000020;
      ammoprop_NoCrosshair  = $00000040;
      AMMO_INFINITE = High(LongWord);

      capgrpStartGame     = 0;
      capgrpAmmoinfo      = 1;
      capgrpNetSay        = 2;

      EXPLAllDamageInRadius = 1;
      EXPLAutoSound         = 2;
      EXPLNoDamage          = 4;

      cToggleConsoleKey     = 39;

      NoPointX = Low(Integer); // константа для TargetPoint, показывает, что цель не указана

      cLandFileName = 'Land.bmp';
      cHHFileName   = 'Hedgehog.png';
      cCHFileName   = 'Crosshair.png';
      cThemeCFGFilename = 'theme.cfg';

      Fontz: array[THWFont] of THHFont = (
                                         (Height: 12;
                                          Name: 'UN1251N.TTF'),
                                         (Height: 24;
                                          Name: 'UN1251N.TTF')
                                         );

      Pathz: array[TPathType] of string[ 64] = (
                                               'Data/',                         // ptData
                                               'Data/Graphics/',                // ptGraphics
                                               'Data/Themes/',                  // ptThemes
                                               'Data/Themes/Default/',          // ptThemeCurrent
                                               'Data/Teams/',                   // ptTeams
                                               'Data/Maps/',                    // ptMaps
                                               'Data/Maps/Current/',            // ptMapCurrent
                                               'Data/Demos/',                   // ptDemos
                                               'Data/Sounds/',                  // ptSounds
                                               'Data/Graphics/Graves/',         // ptGraves
                                               'Data/Fonts/',                   // ptFonts
                                               'Data/Forts/'                    // ptForts
                                               );

      StuffLoadData: array[TStuff] of record
                                     FileName: String[31];
                                     Path    : TPathType;
                                     end = (
                                     (FileName: 'horizont.png'; Path: ptThemeCurrent ),    // sHorizont
                                     (FileName:      'Sky.png'; Path: ptThemeCurrent ),    // sSky
                                     (FileName:  'Console.png'; Path: ptGraphics     ),    // sConsoleBG
                                     (FileName: 'PowerBar.png'; Path: ptGraphics     ),    // sPowerBar
                                     (FileName: 'thinking.png'; Path: ptGraphics     ),    // sQuestion
                                     (FileName:  'WindBar.png'; Path: ptGraphics     ),    // sWindBar
                                     (FileName:    'WindL.png'; Path: ptGraphics     ),    // sWindL
                                     (FileName:    'WindR.png'; Path: ptGraphics     )     // sWindR
                                     );
      StuffPoz: array[TStuff] of TSDL_Rect = (
                                      (x:   0; y:   0; w: 512; h: 256), // sHorizont
                                      (x: 512; y:   0; w:  64; h:1024), // sSky
                                      (x: 256; y: 256; w: 256; h: 256), // sConsoleBG
                                      (x: 256; y: 768; w: 256; h:  32), // sPowerBar
                                      (x: 256; y: 512; w:  32; h:  32), // sQuestion
                                      (x: 256; y: 800; w: 151; h:  17), // sWindBar
                                      (x: 256; y: 817; w:  80; h:  13), // sWindL
                                      (x: 336; y: 817; w:  80; h:  13)  // sWindR
                                      );
      SpritesData: array[TSprite] of record
                                         FileName: String[31];
                                         Path    : TPathType;
                                         Surface : PSDL_Surface;
                                         Width, Height: integer;
                                         end = (
                                         (FileName: 'BlueWater.png'; Path: ptGraphics; Width: 256; Height: 48),// sprWater
                                         (FileName:    'Clouds.png'; Path: ptGraphics; Width: 256; Height:128),// sprCloud
                                         (FileName:      'Bomb.png'; Path: ptGraphics; Width:  16; Height: 16),// sprBomb
                                         (FileName: 'BigDigits.png'; Path: ptGraphics; Width:  32; Height: 32),// sprBigDigit
                                         (FileName:     'Frame.png'; Path: ptGraphics; Width:   4; Height: 32),// sprFrame
                                         (FileName:       'Lag.png'; Path: ptGraphics; Width:  64; Height: 64),// sprLag
                                         (FileName:     'Arrow.png'; Path: ptGraphics; Width:  16; Height: 16),// sprCursor
                                         (FileName:   'Grenade.png'; Path: ptGraphics; Width:  32; Height: 32),// sprGrenade
                                         (FileName:   'Targetp.png'; Path: ptGraphics; Width:  32; Height: 32),// sprTargetP
                                         (FileName:       'UFO.png'; Path: ptGraphics; Width:  32; Height: 32),// sprUFO
                                         (FileName:'SmokeTrace.png'; Path: ptGraphics; Width:  32; Height: 32),// sprSmokeTrace
                                         (FileName:  'RopeHook.png'; Path: ptGraphics; Width:  32; Height: 32),// sprRopeHook
                                         (FileName:    'Expl50.png'; Path: ptGraphics; Width:  64; Height: 64),// sprExplosion50
                                         (FileName:   'MineOff.png'; Path: ptGraphics; Width:  16; Height: 16),// sprMineOff
                                         (FileName:    'MineOn.png'; Path: ptGraphics; Width:  16; Height: 16),// sprMineOn
                                         (FileName:      'Case.png'; Path: ptGraphics; Width:  32; Height: 32) // sprCase
                                         );
      Soundz: array[TSound] of record
                                       FileName: String[31];
                                       Path    : TPathType;
                                       id      : PMixChunk;
                                       end = (
                                       (FileName: 'grenadeimpact.ogg'; Path: ptSounds  ),// sndGrenadeImpact
                                       (FileName:     'explosion.ogg'; Path: ptSounds  ),// sndExplosion
                                       (FileName:  'throwpowerup.ogg'; Path: ptSounds  ),// sndThrowPowerUp
                                       (FileName:  'throwrelease.ogg'; Path: ptSounds  ),// sndThrowRelease
                                       (FileName:        'splash.ogg'; Path: ptSounds  ),// sndSplash
                                       (FileName: 'shotgunreload.ogg'; Path: ptSounds  ),// sndShotgunReload
                                       (FileName:   'shotgunfire.ogg'; Path: ptSounds  ),// sndShotgunFire
                                       (FileName:   'graveimpact.ogg'; Path: ptSounds  ),// sndGraveImpact
                                       (FileName:      'minetick.ogg'; Path: ptSounds  ) // sndMineTicks
                                       );

      Ammoz: array [TAmmoType] of record
                                  Name: string[32];
                                  Ammo: TAmmo;
                                  Slot: Longword;
                                  TimeAfterTurn: Longword;
                                  end = (
                                  (Name: 'Grenade';
                                   Ammo: (Propz: ammoprop_Timerable or ammoprop_Power;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 0;
                                          Timer: 3000;
                                          AmmoType: amGrenade);
                                   Slot: 1;
                                   TimeAfterTurn: 3000),
                                  (Name: 'Bazooka';
                                   Ammo: (Propz: ammoprop_Power;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          AmmoType: amBazooka);
                                   Slot: 0;
                                   TimeAfterTurn: 3000),
                                  (Name: 'UFO';
                                   Ammo: (Propz: ammoprop_Power or ammoprop_NeedTarget;
                                          Count: 4;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          AmmoType: amUFO);
                                   Slot: 0;
                                   TimeAfterTurn: 3000),
                                  (Name: 'Shotgun';
                                   Ammo: (Propz: 0;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 1;
                                          Timer: 0;
                                          AmmoType: amShotgun);
                                   Slot: 2;
                                   TimeAfterTurn: 3000),
                                  (Name: 'Pneumatic pick';
                                   Ammo: (Propz: ammoprop_ForwMsgs or ammoprop_AttackInFall or ammoprop_AttackInJump;
                                          Count: 2;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          AmmoType: amPickHammer);
                                   Slot: 4;
                                   TimeAfterTurn: 0),
                                  (Name: 'Skip turn';
                                   Ammo: (Propz: 0;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          AmmoType: amSkip);
                                   Slot: 6;
                                   TimeAfterTurn: 0),
                                  (Name: 'Rope';
                                   Ammo: (Propz: ammoprop_ForwMsgs or ammoprop_AttackInFall or ammoprop_AttackInJump;
                                          Count: 5;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          AmmoType: amRope);
                                   Slot: 5;
                                   TimeAfterTurn: 0),
                                  (Name: 'Mine';
                                   Ammo: (Propz: ammoprop_NoCrosshair;
                                          Count: 5;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          AmmoType: amMine);
                                   Slot: 3;
                                   TimeAfterTurn: 3000)
                                  );
                                  
      Resolutions: array[0..3] of String = (
                                           '640 480',
                                           '800 600',
                                           '1024 768',
                                           '1280 1024'
                                           );

implementation

end.

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
uses SDLh, GL, uLocale;
{$INCLUDE options.inc}
{$INCLUDE proto.inc}
type

     TGameState = (gsLandGen, gsStart, gsGame, gsConsole, gsExit);

     TGameType  = (gmtLocal, gmtDemo, gmtNet, gmtSave, gmtLandPreview);

     TPathType  = (ptNone, ptData, ptGraphics, ptThemes, ptCurrTheme, ptTeams, ptMaps,
                   ptMapCurrent, ptDemos, ptSounds, ptGraves, ptFonts, ptForts,
                   ptLocale, ptAmmoMenu, ptHedgehog, ptVoices);

     TSprite    = (sprWater, sprCloud, sprBomb, sprBigDigit, sprFrame,
                   sprLag, sprArrow, sprGrenade, sprTargetP, sprUFO,
                   sprSmokeTrace, sprRopeHook, sprExplosion50, sprMineOff,
                   sprMineOn, sprCase, sprFAid, sprDynamite, sprPower,
                   sprClusterBomb, sprClusterParticle, sprFlame, sprHorizont,
                   sprSky, sprAMBorders, sprAMSlot, sprAMSlotName, sprAMAmmos,
                   sprAMSlotKeys, sprAMSelection, sprFinger, sprAirBomb,
                   sprAirplane, sprAmAirplane, sprAmGirder, sprHHTelepMask,
                   sprSwitch, sprParachute, sprTarget, sprRopeNode, sprConsoleBG,
                   sprQuestion, sprPowerBar, sprWindBar, sprWindL, sprWindR,
                   sprFlake, sprHandRope, sprHandBazooka, sprHandShotgun,
                   sprHandDEagle, sprHandAirAttack, sprHandBaseball, sprPHammer,
                   sprHandBlowTorch, sprBlowTorch, sprTeleport, sprHHDeath);

     TGearType  = (gtAmmo_Bomb, gtHedgehog, gtAmmo_Grenade, gtHealthTag,
                   gtGrave, gtUFO, gtShotgunShot, gtPickHammer, gtRope,
                   gtSmokeTrace, gtExplosion, gtMine, gtCase, gtDEagleShot, gtDynamite,
                   gtTeamHealthSorter, gtClusterBomb, gtCluster, gtShover, gtFlame,
                   gtFirePunch, gtATStartGame, gtATSmoothWindCh, gtATFinishGame,
                   gtParachute, gtAirAttack, gtAirBomb, gtBlowTorch, gtGirder,
                   gtTeleport, gtSmallDamage, gtSwitcher, gtTarget);

     TVisualGearType = (vgtFlake, vgtCloud);

     TGearsType = set of TGearType;

     TSound     = (sndGrenadeImpact, sndExplosion, sndThrowPowerUp, sndThrowRelease,
                   sndSplash, sndShotgunReload, sndShotgunFire, sndGraveImpact,
                   sndMineTick, sndPickhammer, sndGun, sndUFO, sndJump1, sndJump2,
                   sndJump3, sndYesSir, sndLaugh, sndIllGetYou, sndIncoming,
                   sndMissed, sndStupid, sndFirstBlood, sndBoring, sndByeBye,
                   sndSameTeam, sndNutter, sndReinforce, sndTraitor, sndRegret,
                   sndEnemyDown, sndCoward, sndHurry);

     TAmmoType  = (amGrenade, amClusterBomb, amBazooka, amUFO, amShotgun, amPickHammer,
                   amSkip, amRope, amMine, amDEagle, amDynamite, amFirePunch,
                   amBaseballBat, amParachute, amAirAttack, amMineStrike, amBlowTorch,
                   amGirder, amTeleport, amSwitch);

     THWFont    = (fnt16, fntBig, fntSmall);

     TCapGroup  = (capgrpGameState, capgrpAmmoinfo, capgrpNetSay, capgrpVolume);

     TStatInfoType = (siGameResult, siMaxStepDamage, siMaxStepKills, siKilledHHs);

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
     TTexture = record
                id: GLuint;
                w, h: LongInt;
                end;
     PTexture = ^TTexture;


const
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

      cMaxTeams        = 6;
      cMaxHHIndex      = 7;
      cMaxHHs          = 30;
      cMaxSpawnPoints  = 1024;

      cMaxEdgePoints = 16384;

      cHHRadius = 9;
      cHHStepTicks = 38;

      cHHZ = 1000;
      cCurrHHZ = Succ(cHHZ);

      cShotgunRadius = 22;
      cBlowTorchC    = 6;

      cKeyMaxIndex = 1023;

      cMaxCaptions = 4;

      gfForts       = $00000001;
      gfMultiWeapon = $00000002;
      gfSolidLand   = $00000004;
      gfOneClanMode = $10000000;

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

      gm_Left   = $00000001;
      gm_Right  = $00000002;
      gm_Up     = $00000004;
      gm_Down   = $00000008;
      gm_Switch = $00000010;
      gm_Attack = $00000020;
      gm_LJump  = $00000040;
      gm_HJump  = $00000080;
      gm_Destroy= $00000100;
      gm_Slot   = $00000200; // with param
      gm_Weapon = $00000400; // with param

      cMaxSlotIndex       = 8;
      cMaxSlotAmmoIndex   = 2;

      ammoprop_Timerable    = $00000001;
      ammoprop_Power        = $00000002;
      ammoprop_NeedTarget   = $00000004;
      ammoprop_ForwMsgs     = $00000008;
      ammoprop_AttackInMove = $00000010;
      ammoprop_NoCrosshair  = $00000040;
      ammoprop_AttackingPut = $00000080;
      ammoprop_DontHold     = $00000100;
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
                                          Name: 'DejaVuSans.ttf'),
                                         (Handle: nil;
                                          Height: 10;
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
                                               'Graphics/AmmoMenu',             // ptAmmoMenu
                                               'Graphics/Hedgehog',             // ptHedgehog
                                               'Sounds/voices'                  // ptVoices
                                               );

      SpritesData: array[TSprite] of record
                     FileName: String[31];
                     Path, AltPath: TPathType;
                     Texture: PTexture;
                     Surface: PSDL_Surface;
                     Width, Height: LongInt;
                     saveSurf: boolean;
                     end = (
                     (FileName:  'BlueWater'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width: 256; Height: 32; saveSurf: false),// sprWater
                     (FileName: 'Clouds'; Path: ptCurrTheme;AltPath: ptGraphics; Texture: nil; Surface: nil;
                      Width: 256; Height:128; saveSurf: false),// sprCloud
                     (FileName:       'Bomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:   8; Height:  8; saveSurf: false),// sprBomb
                     (FileName:  'BigDigits'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprBigDigit
                     (FileName:      'Frame'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:   4; Height: 32; saveSurf: false),// sprFrame
                     (FileName:        'Lag'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  65; Height: 65; saveSurf: false),// sprLag
                     (FileName:      'Arrow'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  16; Height: 16; saveSurf: false),// sprCursor
                     (FileName:    'Grenade'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  16; Height: 16; saveSurf: false),// sprGrenade
                     (FileName:    'Targetp'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprTargetP
                     (FileName:        'UFO'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprUFO
                     (FileName: 'SmokeTrace'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprSmokeTrace
                     (FileName:   'RopeHook'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  16; Height: 16; saveSurf: false),// sprRopeHook
                     (FileName:     'Expl50'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  64; Height: 64; saveSurf: false),// sprExplosion50
                     (FileName:    'MineOff'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:   8; Height:  8; saveSurf: false),// sprMineOff
                     (FileName:     'MineOn'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:   8; Height:  8; saveSurf: false),// sprMineOn
                     (FileName:       'Case'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprCase
                     (FileName:   'FirstAid'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  48; Height: 48; saveSurf: false),// sprFAid
                     (FileName:   'dynamite'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprDynamite
                     (FileName:      'Power'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprPower
                     (FileName:     'ClBomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  16; Height: 16; saveSurf: false),// sprClusterBomb
                     (FileName: 'ClParticle'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  16; Height: 16; saveSurf: false),// sprClusterParticle
                     (FileName:      'Flame'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  16; Height: 16; saveSurf: false),// sprFlame
                     (FileName:   'horizont'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:   0; Height:  0; saveSurf: false),// sprHorizont
                     (FileName:        'Sky'; Path: ptCurrTheme;AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:   0; Height:  0; saveSurf: false),// sprSky
                     (FileName:  'BrdrLines'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width: 202; Height:  1; saveSurf: false),// sprAMBorders
                     (FileName:       'Slot'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width: 202; Height: 33; saveSurf: false),// sprAMSlot
                     (FileName:   'AmmoName'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width: 202; Height: 33; saveSurf: false),// sprAMSlotName
                     (FileName:      'Ammos'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprAMAmmos
                     (FileName:   'SlotKeys'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprAMSlotKeys
                     (FileName:  'Selection'; Path: ptAmmoMenu; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprAMSelection
                     (FileName:     'Finger'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 48; saveSurf: false),// sprFinger
                     (FileName:    'AirBomb'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  16; Height: 16; saveSurf: false),// sprAirBomb
                     (FileName:   'Airplane'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width: 125; Height: 42; saveSurf: false),// sprAirplane
                     (FileName: 'amAirplane'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  64; Height: 32; saveSurf: false),// sprAmAirplane
                     (FileName:   'amGirder'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width: 160; Height:160; saveSurf:  true),// sprAmGirder
                     (FileName:     'hhMask'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf:  true),// sprHHTelepMask
                     (FileName:     'Switch'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprSwitch
                     (FileName:  'Parachute'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  48; Height: 48; saveSurf: false),// sprParachute
                     (FileName:     'Target'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprTarget
                     (FileName:   'RopeNode'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:   6; Height:  6; saveSurf: false),// sprRopeNode
                     (FileName:    'Console'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width: 256; Height:256; saveSurf: false),// sprConsoleBG
                     (FileName:   'thinking'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprQuestion
                     (FileName:   'PowerBar'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width: 256; Height: 32; saveSurf: false),// sprPowerBar
                     (FileName:    'WindBar'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width: 151; Height: 17; saveSurf: false),// sprWindBar
                     (FileName:      'WindL'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  80; Height: 13; saveSurf: false),// sprWindL
                     (FileName:      'WindR'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  80; Height: 13; saveSurf: false),// sprWindR
                     (FileName:      'Flake'; Path:ptCurrTheme; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  64; Height: 64; saveSurf: false),// sprFlake
                     (FileName:     'amRope'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprHandRope
                     (FileName:  'amBazooka'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprHandBazooka
                     (FileName:  'amShotgun'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprHandShotgun
                     (FileName:   'amDEagle'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprHandDEagle
                     (FileName:'amAirAttack'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprHandAirAttack
                     (FileName: 'amBaseball'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprHandBaseball
                     (FileName:     'Hammer'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 64; saveSurf: false),// sprPHammer
                     (FileName: 'amBTorch_i'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprHandBlowToch
                     (FileName: 'amBTorch_w'; Path: ptHedgehog; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 32; saveSurf: false),// sprBlowToch
                     (FileName:   'Teleport'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  64; Height: 32; saveSurf: false),// sprTeleport
                     (FileName:    'HHDeath'; Path: ptGraphics; AltPath: ptNone; Texture: nil; Surface: nil;
                      Width:  32; Height: 64; saveSurf: false) // sprHHDeath
                     );

      Soundz: array[TSound] of record
                FileName: String[31];
                Path    : TPathType;
                id      : PMixChunk;
                lastChan: LongInt;
                end = (
                (FileName: 'grenadeimpact.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndGrenadeImpact
                (FileName:     'explosion.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndExplosion
                (FileName:  'throwpowerup.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndThrowPowerUp
                (FileName:  'throwrelease.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndThrowRelease
                (FileName:        'splash.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndSplash
                (FileName: 'shotgunreload.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndShotgunReload
                (FileName:   'shotgunfire.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndShotgunFire
                (FileName:   'graveimpact.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndGraveImpact
                (FileName:      'minetick.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndMineTicks
                (FileName:    'pickhammer.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndPickhammer
                (FileName:           'gun.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndGun
                (FileName:           'ufo.ogg'; Path: ptSounds; id: nil; lastChan: 0),// sndUFO
                (FileName:         'Jump1.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndJump1
                (FileName:         'Jump2.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndJump2
                (FileName:         'Jump3.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndJump3
                (FileName:        'Yessir.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndYesSir
                (FileName:         'Laugh.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndLaugh
                (FileName:     'Illgetyou.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndIllGetYou
                (FileName:      'Incoming.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndIncoming
                (FileName:        'Missed.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndMissed
                (FileName:        'Stupid.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndStupid
                (FileName:    'Firstblood.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndFirstBlood
                (FileName:        'Boring.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndBoring
                (FileName:        'Byebye.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndByeBye
                (FileName:      'Sameteam.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndSameTeam
                (FileName:        'Nutter.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndNutter
                (FileName:'Reinforcements.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndReinforce
                (FileName:       'Traitor.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndTraitor
                (FileName:'Youllregretthat.ogg';Path: ptVoices; id: nil; lastChan: 0),// sndRegret
                (FileName:     'Enemydown.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndEnemyDown
                (FileName:        'Coward.ogg'; Path: ptVoices; id: nil; lastChan: 0),// sndCoward
                (FileName:         'Hurry.ogg'; Path: ptVoices; id: nil; lastChan: 0) // sndHurry
                );

      Ammoz: array [TAmmoType] of record
                                  NameId: TAmmoStrId;
                                  NameTex: PTexture;
                                  Probability, NumberInCase: Longword;
                                  Ammo: TAmmo;
                                  Slot: 0..cMaxSlotIndex;
                                  TimeAfterTurn: Longword;
                                  minAngle, maxAngle: Longword;
                                  isDamaging: boolean;
                                  PosCount: Longword;
                                  PosSprite: TSprite;
                                  end = (
                                  (NameId: sidGrenade;
                                   NameTex: nil;
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
                                   isDamaging: true;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidClusterBomb;
                                   NameTex: nil;
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
                                   isDamaging: true;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidBazooka;
                                   NameTex: nil;
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
                                   isDamaging: true;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidUFO;
                                   NameTex: nil;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_Power or
                                                 ammoprop_NeedTarget or
                                                 ammoprop_DontHold;
                                          Count: 2;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amUFO);
                                   Slot: 0;
                                   TimeAfterTurn: 3000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: true;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidShotgun;
                                   NameTex: nil;
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
                                   isDamaging: true;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidPickHammer;
                                   NameTex: nil;
                                   Probability: 0;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_ForwMsgs or
                                                 ammoprop_AttackInMove or
                                                 ammoprop_NoCrosshair or
                                                 ammoprop_DontHold;
                                          Count: 2;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amPickHammer);
                                   Slot: 6;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: false;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidSkip;
                                   NameTex: nil;
                                   Probability: 0;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_DontHold;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amSkip);
                                   Slot: 8;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: false;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidRope;
                                   NameTex: nil;
                                   Probability: 100;
                                   NumberInCase: 3;
                                   Ammo: (Propz: ammoprop_ForwMsgs or
                                                 ammoprop_AttackInMove or
                                                 ammoprop_DontHold;
                                          Count: 5;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amRope);
                                   Slot: 7;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: cMaxAngle div 2;
                                   isDamaging: false;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidMine;
                                   NameTex: nil;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_DontHold;
                                          Count: 2;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amMine);
                                   Slot: 4;
                                   TimeAfterTurn: 5000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: true;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidDEagle;
                                   NameTex: nil;
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
                                   isDamaging: true;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidDynamite;
                                   NameTex: nil;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_AttackInMove or
                                                 ammoprop_DontHold;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amDynamite);
                                   Slot: 4;
                                   TimeAfterTurn: 5000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: true;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidFirePunch;
                                   NameTex: nil;
                                   Probability: 0;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_ForwMsgs or
                                                 ammoprop_AttackInMove;
                                          Count: AMMO_INFINITE;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amFirePunch);
                                   Slot: 3;
                                   TimeAfterTurn: 3000;
                                   MinAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: true;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidBaseballBat;
                                   NameTex: nil;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_DontHold;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amBaseballBat);
                                   Slot: 3;
                                   TimeAfterTurn: 5000;
                                   minAngle: 0;
                                   maxAngle: cMaxAngle div 2;
                                   isDamaging: true;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidParachute;
                                   NameTex: nil;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_ForwMsgs or
                                                 ammoprop_AttackInMove or
                                                 ammoprop_NoCrosshair or
                                                 ammoprop_DontHold;
                                          Count: 2;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amParachute);
                                   Slot: 7;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: false;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidAirAttack;
                                   NameTex: nil;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_NeedTarget or
                                                 ammoprop_AttackingPut or
                                                 ammoprop_DontHold;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amAirAttack);
                                   Slot: 5;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: true;
                                   PosCount: 2;
                                   PosSprite: sprAmAirplane),
                                  (NameId: sidMineStrike;
                                   NameTex: nil;
                                   Probability: 400;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_NeedTarget or
                                                 ammoprop_AttackingPut or
                                                 ammoprop_DontHold;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amMineStrike);
                                   Slot: 5;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: true;
                                   PosCount: 2;
                                   PosSprite: sprAmAirplane),
                                  (NameId: sidBlowTorch;
                                   NameTex: nil;
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
                                   isDamaging: false;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidGirder;
                                   NameTex: nil;
                                   Probability: 400;
                                   NumberInCase: 3;
                                   Ammo: (Propz: ammoprop_NoCrosshair or
                                                 ammoprop_NeedTarget or
                                                 ammoprop_AttackingPut or
                                                 ammoprop_DontHold;
                                          Count: 1;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amGirder);
                                   Slot: 6;
                                   TimeAfterTurn: 3000;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: false;
                                   PosCount: 8;
                                   PosSprite: sprAmGirder),
                                  (NameId: sidTeleport;
                                   NameTex: nil;
                                   Probability: 400;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_ForwMsgs or
                                                 ammoprop_NoCrosshair or
                                                 ammoprop_NeedTarget or
                                                 ammoprop_AttackingPut or
                                                 ammoprop_DontHold;
                                          Count: 2;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amTeleport);
                                   Slot: 7;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: false;
                                   PosCount: 1;
                                   PosSprite: sprWater),
                                  (NameId: sidSwitch;
                                   NameTex: nil;
                                   Probability: 100;
                                   NumberInCase: 1;
                                   Ammo: (Propz: ammoprop_ForwMsgs or
                                                 ammoprop_NoCrosshair or
                                                 ammoprop_DontHold;
                                          Count: 3;
                                          NumPerTurn: 0;
                                          Timer: 0;
                                          Pos: 0;
                                          AmmoType: amSwitch);
                                   Slot: 8;
                                   TimeAfterTurn: 0;
                                   minAngle: 0;
                                   maxAngle: 0;
                                   isDamaging: false;
                                   PosCount: 1;
                                   PosSprite: sprWater));

var CountTexz: array[1..9] of PTexture;

implementation

end.

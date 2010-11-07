(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

unit PascalExports;

interface
uses uKeys, GLunit, uWorld, uMisc, uConsole, uTeams, uConsts, uChat, 
     uGears, uSound, hwengine, uAmmos, uLocale; // don't change the order!

{$INCLUDE "config.inc"}
type PPByte = ^PByte;
var dummy: boolean;  // avoid compiler hint

implementation
{$IFDEF HWLIBRARY}
var cZoomVal: GLfloat;

// retrieve protocol information
procedure HW_versionInfo(netProto: PShortInt; versionStr: PPChar); cdecl; export;
begin
// http://bugs.freepascal.org/view.php?id=16156
    if netProto <> nil then netProto^:= cNetProtoVersion;
    if versionStr <> nil then versionStr^:= cVersionString;
end;

procedure HW_click; cdecl; export;
begin
    leftClick:= true;
end;

procedure HW_ammoMenu; cdecl; export;
begin
    rightClick:= true;
end;

procedure HW_zoomSet(value: GLfloat); cdecl; export;
begin
    cZoomVal:= value;
    ZoomValue:= value;
end;

procedure HW_zoomIn; cdecl; export;
begin
    if wheelDown = false then
        wheelUp:= true;
end;

procedure HW_zoomOut; cdecl; export;
begin
    if wheelUp = false then
        wheelDown:= true;
end;

procedure HW_zoomReset; cdecl; export;
begin
    ZoomValue:= cZoomVal;
    //middleClick:= true;
    // center the camera at current hog
    if CurrentHedgehog <> nil then
        followGear:= CurrentHedgehog^.Gear;
end;

function HW_zoomFactor: GLfloat; cdecl; export;
begin
    exit( ZoomValue / cDefaultZoomLevel );
end;

function HW_zoomLevel: LongInt; cdecl; export;
begin
    exit( trunc((ZoomValue - cDefaultZoomLevel) / cZoomDelta) );
end;

procedure HW_walkingKeysUp; cdecl; export;
begin
    leftKey:= false;
    rightKey:= false;
    upKey:= false;
    downKey:= false;
    preciseKey:= false;
end;

procedure HW_otherKeysUp; cdecl; export;
begin
    spaceKey:= false;
    enterKey:= false;
    backspaceKey:= false;
end;

procedure HW_allKeysUp; cdecl; export;
begin
    // set all keys to released
    uKeys.initModule;
end;

procedure HW_walkLeft; cdecl; export;
begin
    leftKey:= true;
end;

procedure HW_walkRight; cdecl; export;
begin
    rightKey:= true;
end;

procedure HW_preciseSet(status:boolean); cdecl; export;
begin
    preciseKey:= status;
end;

procedure HW_aimUp; cdecl; export;
begin
    upKey:= true;
end;

procedure HW_aimDown; cdecl; export;
begin
    downKey:= true;
end;

procedure HW_shoot; cdecl; export;
begin
    spaceKey:= true;
end;

procedure HW_jump; cdecl; export;
begin
    enterKey:= true;
end;

procedure HW_backjump; cdecl; export;
begin
    backspaceKey:= true;
end;

procedure HW_tab; cdecl; export;
begin
    tabKey:= true;
end;

procedure HW_chat; cdecl; export;
begin
    chatAction:= true;
end;

procedure HW_chatEnd; cdecl; export;
begin
    KeyPressChat(27); // esc - cleans buffer
    KeyPressChat(13); // enter - removes chat
end;

procedure HW_pause; cdecl; export;
begin
    pauseAction:= true;
end;

procedure HW_terminate(closeFrontend: boolean); cdecl; export;
begin
    isTerminated:= true;
    if closeFrontend then alsoShutdownFrontend:= true;
end;

procedure HW_setCursor(x,y: LongInt); cdecl; export;
begin
    CursorPoint.X:= x;
    CursorPoint.Y:= y;
end;

procedure HW_getCursor(x,y: PLongInt); cdecl; export;
begin
    x^:= CursorPoint.X;
    y^:= CursorPoint.Y;
end;

function HW_isAmmoMenuOpen: boolean; cdecl; export;
begin
    exit(bShowAmmoMenu);
end;

function HW_isAmmoMenuNotAllowed: boolean; cdecl; export;
begin;
    exit ( (TurnTimeLeft = 0) or (not CurrentTeam^.ExtDriven and (((CurAmmoGear = nil) or
           ((Ammoz[CurAmmoGear^.AmmoType].Ammo.Propz and ammoprop_AltAttack) = 0)) and hideAmmoMenu)) );
end;

function HW_isPaused: boolean; cdecl; export;
begin
    exit( isPaused );
end;

function HW_isWaiting: boolean; cdecl; export;
begin
    exit( ReadyTimeLeft > 0 );
end;

function HW_isWeaponRequiringClick: boolean; cdecl; export;
begin
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) and (CurrentHedgehog^.BotLevel = 0) then
        exit( (CurrentHedgehog^.Gear^.State and gstHHChooseTarget) <> 0 )
    else
        exit(false);
end;

function HW_isWeaponTimerable: boolean; cdecl; export;
begin
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Ammo <> nil) and (CurrentHedgehog^.BotLevel = 0) then
        exit( (Ammoz[CurrentHedgehog^.CurAmmoType].Ammo.Propz and ammoprop_Timerable) <> 0)
    else
        exit(false);
end;

function HW_isWeaponSwitch: boolean cdecl; export;
begin
    if (CurAmmoGear <> nil) and (CurrentHedgehog^.BotLevel = 0) then
        exit(CurAmmoGear^.AmmoType = amSwitch)
    else
        exit(false)
end;

function HW_isWeaponRope: boolean cdecl; export;
begin
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Ammo <> nil) and (CurrentHedgehog^.BotLevel = 0) then
        exit (CurrentHedgehog^.CurAmmoType = amRope)
    else
        exit(false);
end;

procedure HW_setGrenadeTime(time: LongInt); cdecl; export;
begin
    ParseCommand('/timer ' + inttostr(time), true);
end;

procedure HW_setPianoSound(snd: LongInt); cdecl; export;
begin
    // this most likely won't work in network game
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Ammo <> nil) and (CurrentHedgehog^.BotLevel = 0)
       and (CurrentHedgehog^.CurAmmoType = amPiano) then
        case snd of
            0: PlaySound(sndPiano0);
            1: PlaySound(sndPiano1);
            2: PlaySound(sndPiano2);
            3: PlaySound(sndPiano3);
            4: PlaySound(sndPiano4);
            5: PlaySound(sndPiano5);
            6: PlaySound(sndPiano6);
            7: PlaySound(sndPiano7);
            else PlaySound(sndPiano8);
        end;
end;

function HW_getWeaponNameByIndex(whichone: LongInt): PChar; cdecl; export;
begin
    exit (str2pchar(trammo[Ammoz[TAmmoType(whichone+1)].NameId]));
end;

function HW_getWeaponCaptionByIndex(whichone: LongInt): PChar; cdecl; export;
begin
    exit (str2pchar(trammoc[Ammoz[TAmmoType(whichone+1)].NameId]));
end;

function HW_getWeaponDescriptionByIndex(whichone: LongInt): PChar; cdecl; export;
begin
    exit (str2pchar(trammod[Ammoz[TAmmoType(whichone+1)].NameId]));
end;

function HW_getNumberOfWeapons:LongInt; cdecl; export;
begin
    exit(ord(high(TAmmoType)));
end;

procedure HW_setWeapon(whichone: LongInt); cdecl; export;
begin
    if (not CurrentTeam^.ExtDriven) and (CurrentTeam^.Hedgehogs[0].BotLevel = 0) then
        SetWeapon(TAmmoType(whichone+1));
end;

function HW_isWeaponAnEffect(whichone: LongInt): boolean; cdecl; export;
begin
    exit(Ammoz[TAmmoType(whichone+1)].Ammo.Propz and ammoprop_Effect <> 0)
end;

function HW_getAmmoCounts(counts: PLongInt): LongInt; cdecl; export;
var a : PHHAmmo;
    slot, index: LongInt;
begin
    if (CurrentTeam = nil) or
       (CurrentHedgehog = nil) or
       (CurrentTeam^.ExtDriven) or
       (CurrentTeam^.Hedgehogs[0].BotLevel <> 0) then
        exit(-1);

    a:= CurrentHedgehog^.Ammo;
    for slot:= 0 to cMaxSlotIndex do
        for index:= 0 to cMaxSlotAmmoIndex do
            if a^[slot,index].Count <> 0 then // yes, ammomenu is hell
                counts[ord(a^[slot,index].AmmoType)-1]:= a^[slot,index].Count;
    exit(0);
end;

procedure HW_getAmmoDelays (skipTurns: PByte); cdecl; export;
var a : TAmmoType;
begin
    for a:= Low(TAmmoType) to High(TAmmoType) do
        skipTurns[ord(a)-1]:= byte(Ammoz[a].SkipTurns);
end;

function HW_getTurnsForCurrentTeam: LongInt; cdecl; export;
begin
    exit(CurrentTeam^.Clan^.TurnNumber);
end;

function HW_getMaxNumberOfHogs: LongInt; cdecl; export;
begin
    exit(cMaxHHIndex+1);
end;

function HW_getMaxNumberOfTeams: LongInt; cdecl; export;
begin
    exit(cMaxTeams);
end;
{$ENDIF}

end.


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

unit PascalExports;
(*
 * If the engine is compiled as library this unit will export functions
 * as C declarations for convenient library usage in your application and
 * language of choice.
 *
 * See also: C declarations on wikipedia
 *           http://en.wikipedia.org/wiki/X86_calling_conventions#cdecl
 *)
interface
uses uTypes, uConsts, uVariables, GLunit, uInputHandler, uSound, uAmmos, uUtils, uCommands;

{$INCLUDE "config.inc"}
procedure HW_versionInfo(netProto: PLongInt; versionStr: PPChar); cdecl; export;

function HW_getNumberOfWeapons:LongInt; cdecl; export;

function HW_getMaxNumberOfTeams:LongInt; cdecl; export;

function HW_getMaxNumberOfHogs:LongInt; cdecl; export;

procedure HW_terminate(closeFrontend: Boolean); cdecl; export;

implementation
{$IFDEF HWLIBRARY}
var cZoomVal: GLfloat;

// retrieve protocol information
procedure HW_versionInfo(netProto: PLongInt; versionStr: PPChar); cdecl; export;
begin
    netProto^:= cNetProtoVersion;
    versionStr^:= cVersionString;
end;

procedure HW_zoomSet(value: GLfloat); cdecl; export;
begin
    cZoomVal:= value;
    ZoomValue:= value;
end;

procedure HW_zoomReset; cdecl; export;
begin
    ZoomValue:= cZoomVal;
    // center the camera at current hog
    if CurrentHedgehog <> nil then
        followGear:= CurrentHedgehog^.Gear;
end;

function HW_zoomFactor: GLfloat; cdecl; export;
begin
    HW_zoomFactor:= ZoomValue / cDefaultZoomLevel;
end;

function HW_zoomLevel: LongInt; cdecl; export;
begin
    HW_zoomLevel:= trunc((ZoomValue - cDefaultZoomLevel) / cZoomDelta);
end;

procedure HW_screenshot; cdecl; export;
begin
    flagMakeCapture:= true;
end;

function HW_isPaused: boolean; cdecl; export;
begin
    HW_isPaused:= isPaused;
end;

// equivalent to esc+y; when closeFrontend = true the game exits after memory cleanup
procedure HW_terminate(closeFrontend: boolean); cdecl; export;
begin
    alsoShutdownFrontend:= closeFrontend;
    ParseCommand('forcequit', true);
end;

function HW_getSDLWindow: pointer; cdecl; export;
begin
    HW_getSDLWindow:={$IFDEF SDL13}SDLwindow{$ELSE}nil{$ENDIF};
end;

// cursor handling
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

// ammo menu related functions
function HW_isAmmoMenuOpen: boolean; cdecl; export;
begin
    HW_isAmmoMenuOpen:= bShowAmmoMenu;
end;

function HW_isAmmoMenuNotAllowed: boolean; cdecl; export;
begin;
    HW_isAmmoMenuNotAllowed:= ( (TurnTimeLeft = 0) or (not CurrentTeam^.ExtDriven and (((CurAmmoGear = nil) or
                                ((Ammoz[CurAmmoGear^.AmmoType].Ammo.Propz and ammoprop_AltAttack) = 0)) and hideAmmoMenu)) );
end;

function HW_isWeaponRequiringClick: boolean; cdecl; export;
begin
    HW_isWeaponRequiringClick:= false;
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) and (CurrentHedgehog^.BotLevel = 0) then
        HW_isWeaponRequiringClick:= (CurrentHedgehog^.Gear^.State and gstHHChooseTarget) <> 0;
end;

function HW_isWeaponTimerable: boolean; cdecl; export;
begin
    HW_isWeaponTimerable:= false;
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Ammo <> nil) and (CurrentHedgehog^.BotLevel = 0) then
        HW_isWeaponTimerable:= (Ammoz[CurrentHedgehog^.CurAmmoType].Ammo.Propz and ammoprop_Timerable) <> 0;
end;

function HW_isWeaponSwitch: boolean cdecl; export;
begin
    HW_isWeaponSwitch:= false;
    if (CurAmmoGear <> nil) and (CurrentHedgehog^.BotLevel = 0) then
        HW_isWeaponSwitch:= (CurAmmoGear^.AmmoType = amSwitch);
end;

function HW_isWeaponRope: boolean cdecl; export;
begin
    HW_isWeaponRope:= false
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Ammo <> nil) and (CurrentHedgehog^.BotLevel = 0) then
        HW_isWeaponRope:= (CurrentHedgehog^.CurAmmoType = amRope);
end;

procedure HW_setGrenadeTime(time: LongInt); cdecl; export;
begin
    ParseCommand('/timer ' + inttostr(time), true);
end;

function HW_getGrenadeTime: LongInt; cdecl; export;
var CurWeapon: PAmmo;
begin
    HW_getGrenadeTime:= 3;
    if HW_isWeaponTimerable then
    begin
        CurWeapon:= GetCurAmmoEntry(CurrentHedgehog^);
        HW_getGrenadeTime:= CurWeapon^.Timer div 1000;
    end;
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
    HW_getWeaponNameByIndex:= (str2pchar(trammo[Ammoz[TAmmoType(whichone+1)].NameId]));
end;

function HW_getWeaponCaptionByIndex(whichone: LongInt): PChar; cdecl; export;
begin
    HW_getWeaponCaptionByIndex:= (str2pchar(trammoc[Ammoz[TAmmoType(whichone+1)].NameId]));
end;

function HW_getWeaponDescriptionByIndex(whichone: LongInt): PChar; cdecl; export;
begin
    HW_getWeaponDescriptionByIndex:= (str2pchar(trammod[Ammoz[TAmmoType(whichone+1)].NameId]));
end;

function HW_getNumberOfWeapons: LongInt; cdecl; export;
begin
    HW_getNumberOfWeapons:= ord(high(TAmmoType));
end;

procedure HW_setWeapon(whichone: LongInt); cdecl; export;
begin
    if (CurrentTeam = nil) then exit;
    if (not CurrentTeam^.ExtDriven) and (CurrentTeam^.Hedgehogs[0].BotLevel = 0) then
        SetWeapon(TAmmoType(whichone+1));
end;

function HW_isWeaponAnEffect(whichone: LongInt): boolean; cdecl; export;
begin
    HW_isWeaponAnEffect:= Ammoz[TAmmoType(whichone+1)].Ammo.Propz and ammoprop_Effect <> 0;
end;

function HW_getAmmoCounts(counts: PLongInt): LongInt; cdecl; export;
var a : PHHAmmo;
    slot, index, res: LongInt;
begin
    HW_getAmmoCounts:= -1;
    // nil check
    if (CurrentHedgehog = nil) or (CurrentHedgehog^.Ammo = nil) or (CurrentTeam = nil) then
        exit;
    // hog controlled by opponent (net or ai)
    if (CurrentTeam^.ExtDriven) or (CurrentTeam^.Hedgehogs[0].BotLevel <> 0) then
        exit;

    a:= CurrentHedgehog^.Ammo;
    for slot:= 0 to cMaxSlotIndex do
        for index:= 0 to cMaxSlotAmmoIndex do
            if a^[slot,index].Count <> 0 then // yes, ammomenu is hell
                counts[ord(a^[slot,index].AmmoType)-1]:= a^[slot,index].Count;
    HW_getAmmoCounts:= 0;
end;

procedure HW_getAmmoDelays (skipTurns: PByte); cdecl; export;
var a : TAmmoType;
begin
    for a:= Low(TAmmoType) to High(TAmmoType) do
        skipTurns[ord(a)-1]:= byte(Ammoz[a].SkipTurns);
end;

function HW_getTurnsForCurrentTeam: LongInt; cdecl; export;
begin
    HW_getTurnsForCurrentTeam:= 0;
    if (CurrentTeam <> nil) and (CurrentTeam^.Clan <> nil) then
        HW_getTurnsForCurrentTeam:= CurrentTeam^.Clan^.TurnNumber;
end;

function HW_getMaxNumberOfHogs: LongInt; cdecl; export;
begin
    HW_getMaxNumberOfHogs:= cMaxHHIndex + 1;
end;

function HW_getMaxNumberOfTeams: LongInt; cdecl; export;
begin
    HW_getMaxNumberOfTeams:= cMaxTeams;
end;

procedure HW_memoryWarningCallback; cdecl; export;
begin
    ReleaseSound(false);
end;

{$ENDIF}

end.


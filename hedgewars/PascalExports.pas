(*
 *  PascalExports.pas
 *  hwengine
 *
 *  Created by Vittorio on 09/01/10.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 *)


{$INCLUDE "options.inc"}

unit PascalExports;

interface
uses uKeys, GLunit, uWorld, uMisc, uConsole, uTeams, uConsts, uChat, uGears, hwengine;

{$INCLUDE "config.inc"}

implementation

{$IFDEF HWLIBRARY}
var xx, yy: LongInt;

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
    middleClick:= true;
end;

procedure HW_ammoMenu; cdecl; export;
begin
    rightClick:= true;
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

procedure HW_setLandscape(landscape: boolean); cdecl; export;
begin
    if landscape then
    begin
        cOffsetY:= 0;
    end
    else
    begin
        cOffsetY:= 120;
    end;
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

procedure HW_saveCursor(reset: boolean); cdecl; export;
begin
    if reset then
    begin
        CursorPoint.X:= xx;
        CursorPoint.Y:= yy;
    end
    else
    begin
        xx:= CursorPoint.X;
        yy:= CursorPoint.Y;
    end;
end;

function HW_isAmmoOpen: boolean; cdecl; export;
begin
    exit(bShowAmmoMenu);
end;

function HW_isWeaponRequiringClick: boolean; cdecl; export;
begin
    if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) then
        exit( (CurrentHedgehog^.Gear^.State and gstHHChooseTarget) <> 0 )
    else
        exit(false);
end;

function HW_isWeaponTimerable: boolean; cdecl; export;
var CurSlot, CurAmmo: LongWord;
begin
    CurSlot:= CurrentHedgehog^.CurSlot;
    CurAmmo:= CurrentHedgehog^.CurAmmo;
    exit( (CurrentHedgehog^.Ammo^[CurSlot, CurAmmo].Propz and ammoprop_Timerable) <> 0)
end;

function HW_isWeaponSwitch: boolean cdecl; export;
begin
    if CurAmmoGear <> nil then
        exit(CurAmmoGear^.AmmoType = amSwitch) 
    else
        exit(false)
end;

procedure HW_setGrenadeTime(time: LongInt); cdecl; export;
begin
    ParseCommand('/timer ' + inttostr(time), true);
end;

//amSwitch
{$ENDIF}

end.


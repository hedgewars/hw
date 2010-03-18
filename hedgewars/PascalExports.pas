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
uses uKeys, uConsole;

{$INCLUDE "config.inc"}

{$IFDEF IPHONEOS}
// called by pascal code, they deal with the objc code
function  IPH_getDocumentsPath: PChar; cdecl; external;
procedure IPH_showControls; cdecl; external;
{$ENDIF}

{$IFDEF HWLIBRARY}
// retrieve protocol information
procedure HW_versionInfo(netProto: PShortInt; versionStr: PString); cdecl; export;

// called by the touch functions (SDL_uikitview.m)
// they emulate user interaction from mouse or keyboard
procedure HW_click; cdecl; export;
procedure HW_zoomIn; cdecl; export;
procedure HW_zoomOut; cdecl; export;
procedure HW_zoomReset; cdecl; export;
procedure HW_ammoMenu; cdecl; export;
procedure HW_allKeysUp; cdecl; export;
procedure HW_walkLeft; cdecl; export;
procedure HW_walkRight; cdecl; export;
procedure HW_aimUp; cdecl; export;
procedure HW_aimDown; cdecl; export;
procedure HW_shoot; cdecl; export;
procedure HW_whereIsHog; cdecl; export;
procedure HW_chat; cdecl; export;
procedure HW_pause; cdecl; export;
procedure HW_tab; cdecl; export;
{$ENDIF}

implementation

{$IFDEF HWLIBRARY}
procedure HW_versionInfo(netProto: PShortInt; versionStr: PString); cdecl; export;
begin
    if netProto <> nil then netProto^:= cNetProtoVersion;
    if versionStr <> nil then versionStr^:= shortstring(cVersionString);
end;

procedure HW_click; cdecl; export;
begin
    leftClick:= true;
end;

procedure HW_zoomIn; cdecl; export;
begin
    wheelUp:= true;
end;

procedure HW_zoomOut; cdecl; export;
begin
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

procedure HW_allKeysUp; cdecl; export;
begin
    // set all keys to released
    init_uKeys();
end;

procedure HW_walkLeft; cdecl; export;
begin
    leftKey:= true;
end;

procedure HW_walkRight; cdecl; export;
begin
    rightKey:= true;
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

procedure HW_chat; cdecl; export;
begin
    chatAction:= true;
end;

procedure HW_tab; cdecl; export;
begin
    switchAction:= true;
end;

procedure HW_pause; cdecl; export;
begin
    pauseAction:= true;
end;

procedure HW_whereIsHog; cdecl; export;
//var Xcoord, Ycoord: LongInt;
begin
    //Xcoord:= Gear^.dX + WorldDx;
    WriteLnToConsole('HW - hog is at x: ' + ' y:');

    exit
end;
{$ENDIF}

end.


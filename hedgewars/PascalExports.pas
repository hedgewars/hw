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

{$INCLUDE "proto.inc"}

{$IFDEF IPHONEOS}
// called by pascal code, they deal with the objc code
function  IPH_getDocumentsPath: PChar; cdecl; external;
procedure IPH_showControls; cdecl; external;

// retrieve protocol information
function  HW_protoVer: LongInt; cdecl; export;

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

{$ENDIF}

implementation

{$IFDEF IPHONEOS}
function HW_protoVer: LongInt; cdecl; export;
begin
	HW_protoVer:= cNetProtoVersion;
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
	upKey:= false;
	downKey:= false;
	leftKey:= false;
	rightKey:= false;
	spaceKey:= false;
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

procedure HW_whereIsHog; cdecl; export;
//var Xcoord, Ycoord: LongInt;
begin
	//Xcoord:= Gear^.dX + WorldDx;
	WriteLnToConsole('HW - hog is at x: ' + ' y:');

	exit
end;
{$ENDIF}

end.


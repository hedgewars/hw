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

unit uMobile;
interface

{$IFDEF IPHONEOS}
(*  iOS calls written in C/Objc  *)
procedure clearView; cdecl; external;
procedure startSpinning; cdecl; external;
procedure stopSpinning; cdecl; external;
procedure replayBegan; cdecl; external;
procedure replayFinished; cdecl; external;
procedure updateVisualsNewTurn; cdecl; external;
function  isApplePhone: Boolean; cdecl; external;
{$ENDIF}
function  isPhone: Boolean;
procedure doRumble;
procedure doSomethingWhen_AddProgress;
procedure doSomethingWhen_FinishProgress;
procedure doSomethingWhen_NewTurnBeginning;
procedure doSomethingWhen_SaveBeganSynching;
procedure doSomethingWhen_SaveFinishedSynching;

implementation

function isPhone: Boolean;
begin
{$IFDEF IPHONEOS}
    exit(isApplePhone());
{$ENDIF}
    exit(false);
end;

procedure doRumble;
begin
    // fill me!
end;

procedure doSomethingWhen_AddProgress;
begin
{$IFDEF IPHONEOS}
    startSpinning();
{$ENDIF}
end;

procedure doSomethingWhen_FinishProgress;
begin
{$IFDEF IPHONEOS}
    stopSpinning();
{$ENDIF}
end;

procedure doSomethingWhen_NewTurnBeginning;
begin
{$IFDEF IPHONEOS}
    clearView();
    updateVisualsNewTurn();
{$ENDIF}
end;

procedure doSomethingWhen_SaveBeganSynching;
begin
{$IFDEF IPHONEOS}
    replayBegan();
{$ENDIF}
end;

procedure doSomethingWhen_SaveFinishedSynching;
begin
{$IFDEF IPHONEOS}
    replayFinished();
{$ENDIF}
end;


end.

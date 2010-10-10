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
function  isPhone: Boolean; inline;
procedure doRumble; inline;
procedure perfExt_AddProgress; inline;
procedure perfExt_FinishProgress; inline;
procedure perfExt_AmmoUpdate; // don't inline
procedure perfExt_NewTurnBeginning; inline;
procedure perfExt_SaveBeganSynching; inline;
procedure perfExt_SaveFinishedSynching; inline;

implementation
uses uTeams;

function isPhone: Boolean; inline;
begin
{$IFDEF IPHONEOS}
    exit(isApplePhone());
{$ENDIF}
    exit(false);
end;

procedure doRumble; inline;
begin
    // fill me!
end;

procedure perfExt_AddProgress; inline;
begin
{$IFDEF IPHONEOS}
    startSpinning();
{$ENDIF}
end;

procedure perfExt_FinishProgress; inline;
begin
{$IFDEF IPHONEOS}
    stopSpinning();
{$ENDIF}
end;

procedure perfExt_AmmoUpdate; // don't inline
begin
{$IFDEF IPHONEOS}
    if (CurrentTeam^.ExtDriven) or (CurrentTeam^.Hedgehogs[0].BotLevel <> 0) then
        exit(); // the other way around throws a compiler error
    updateVisualsNewTurn();
{$ENDIF}
end;

procedure perfExt_NewTurnBeginning; inline;
begin
{$IFDEF IPHONEOS}
    clearView();
    perfExt_AmmoUpdate();
{$ENDIF}
end;

procedure perfExt_SaveBeganSynching; inline;
begin
{$IFDEF IPHONEOS}
    replayBegan();
{$ENDIF}
end;

procedure perfExt_SaveFinishedSynching; inline;
begin
{$IFDEF IPHONEOS}
    replayFinished();
{$ENDIF}
end;


end.

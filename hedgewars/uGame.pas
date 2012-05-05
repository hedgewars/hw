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

unit uGame;
interface

procedure DoGameTick(Lag: LongInt);

////////////////////
    implementation
////////////////////
uses uInputHandler, uTeams, uIO, uAI, uGears, uSound, uMobile, uVisualGears, uTypes, uVariables{$IFDEF SDL13}, uTouch{$ENDIF};

procedure DoGameTick(Lag: LongInt);
var i: LongInt;
begin
if isPaused then
    exit;
if (not CurrentTeam^.ExtDriven) then
    begin
    NetGetNextCmd; // its for the case of receiving "/say" message
    isInLag:= false;
    SendKeepAliveMessage(Lag)
    end;
if Lag > 100 then
    Lag:= 100
else if (GameType = gmtSave) or (fastUntilLag and (GameType = gmtNet)) then
    Lag:= 2500;

if (GameType = gmtDemo) then 
    if isSpeed then
        Lag:= Lag * 10
    else
        if cOnlyStats then
            Lag:= High(LongInt);
PlayNextVoice;
i:= 1;
while (GameState <> gsExit) and (i <= Lag) do
    begin
    if not CurrentTeam^.ExtDriven then
        begin
        if CurrentHedgehog^.BotLevel <> 0 then
            ProcessBot;
        ProcessGears;
        {$IFDEF SDL13}ProcessTouch;{$ENDIF}
        end
    else
        begin
        NetGetNextCmd;
        if isInLag then
            case GameType of
                gmtNet: begin
                        // just update the health bars
                        AddVisualGear(0, 0, vgtTeamHealthSorter);
                        break;
                        end;
                gmtDemo: begin
                        GameState:= gsExit;
                        exit
                        end;
                gmtSave: begin
                        RestoreTeamsFromSave;
                        SetBinds(CurrentTeam^.Binds);
                        //CurrentHedgehog^.Gear^.Message:= 0; <- produces bugs with further save restoring and demos
                        SetSound;   // restore previous sound state
                        PlayMusic;
                        GameType:= gmtLocal;
                        AddVisualGear(0, 0, vgtTeamHealthSorter);
                        AddVisualGear(0, 0, vgtSmoothWindBar);
                        {$IFDEF IPHONEOS}InitIPC;{$ENDIF}
                        uMobile.SaveLoadingEnded();
                        end;
                end
        else ProcessGears
        end;
    inc(i)
    end
end;

end.

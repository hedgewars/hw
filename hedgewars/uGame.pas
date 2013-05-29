(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
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
uses uInputHandler, uTeams, uIO, uAI, uGears, uSound, uLocale, uCaptions,
    uVisualGears, uTypes, uVariables, uCommands, uConsts
    {$IFDEF USE_TOUCH_INTERFACE}, uTouch{$ENDIF};

procedure DoGameTick(Lag: LongInt);
var i,j : LongInt;
    s: shortstring;
begin
if isPaused then
    exit;

if (not CurrentTeam^.ExtDriven) then
    begin
    NetGetNextCmd; // its for the case of receiving "/say" message
    isInLag:= false;
    FlushMessages(Lag)
    end;

if GameType <> gmtRecord then
    begin
    if Lag > 100 then
        Lag:= 100
    else if (GameType = gmtSave) or (fastUntilLag and (GameType = gmtNet)) then
        Lag:= 2500;

    if (GameType = gmtDemo) then 
        if isSpeed then
            begin
            i:= RealTicks-SpeedStart;
            if i < 2000 then Lag:= Lag*5
            else if i < 4000 then Lag:= Lag*10
            else if i < 6000 then Lag:= Lag*20
            else if i < 8000 then Lag:= Lag*40
            else Lag:= Lag*80;
            end
        else if cOnlyStats then
            Lag:= High(LongInt)
    end;
inc(SoundTimerTicks, Lag);
if SoundTimerTicks >= 50 then
    begin
    SoundTimerTicks:= 0;
    if cVolumeDelta <> 0 then
        begin
        j:= Volume;
        i:= ChangeVolume(cVolumeDelta);
        if isAudioMuted and (j<>i) then
            AddCaption(trmsg[sidMute], cWhiteColor, capgrpVolume)
        else if not isAudioMuted then
            begin
            str(i, s);
            AddCaption(Format(trmsg[sidVolume], s), cWhiteColor, capgrpVolume)
            end
        end;
    end;
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
                gmtDemo, gmtRecord: begin
                        GameState:= gsExit;
                        exit
                        end;
                gmtSave: begin
                        RestoreTeamsFromSave;
                        SetBinds(CurrentTeam^.Binds);
                        StopMessages(gmLeft or gmRight or gmUp or gmDown);
                        ResetSound;   // restore previous sound state
                        PlayMusic;
                        GameType:= gmtLocal;
                        AddVisualGear(0, 0, vgtTeamHealthSorter);
                        AddVisualGear(0, 0, vgtSmoothWindBar);
                        {$IFDEF IPHONEOS}InitIPC;{$ENDIF}
                        with mobileRecord do
                            if SaveLoadingEnded <> nil then
                                SaveLoadingEnded();
                        end;
                end
        else ProcessGears
        end;
    inc(i)
    end
end;

end.

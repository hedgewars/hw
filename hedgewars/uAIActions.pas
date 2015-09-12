(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit uAIActions;
interface
uses uFloat, uTypes;

const MAXACTIONS     = 96;
    aia_none       = 0;
    aia_Left       = 1;
    aia_Right      = 2;
    aia_Timer      = 3;
    aia_attack     = 4;
    aia_Up         = 5;
    aia_Down       = 6;
    aia_Switch     = 7;

    aia_Weapon     = $8000;
    aia_WaitXL     = $8001;
    aia_WaitXR     = $8002;
    aia_LookLeft   = $8003;
    aia_LookRight  = $8004;
    aia_AwareExpl  = $8005;
    aia_HJump      = $8006;
    aia_LJump      = $8007;
    aia_Skip       = $8008;
    aia_Wait       = $8009;
    aia_Put        = $800A;
    aia_waitAngle  = $800B;
    aia_waitAmmoXY = $800C;

    aim_push       = $8000;
    aim_release    = $8001;
    ai_specmask    = $8000;

type TAction = record
        Action: Longword;
        X, Y, Param: LongInt;
        Time: Longword;
        end;

    TActions = record
        Count, Pos: Longword;
        actions: array[0..Pred(MAXACTIONS)] of TAction;
        Score: LongInt;
        isWalkingToABetterPlace: boolean;
        end;

procedure AddAction(var Actions: TActions; Action: Longword; Param: LongInt; TimeDelta: Longword; X, Y: LongInt);
procedure ProcessAction(var Actions: TActions; Me: PGear);

implementation
uses uAIMisc, uAI, uAmmos, uVariables, uCommands, uUtils, uIO{$IFDEF TRACEAIACTIONS}, uConsole{$ENDIF};

var PrevX: LongInt = 0;
    timedelta: Longword = 0;

const ActionIdToStr: array[0..7] of string[16] = (
{aia_none}           '',
{aia_Left}           'left',
{aia_Right}          'right',
{aia_Timer}          'timer',
{aia_attack}         'attack',
{aia_Up}             'up',
{aia_Down}           'down',
{aia_Switch}         'switch'
                     );

{$IFDEF TRACEAIACTIONS}
const SpecActionIdToStr: array[$8000..$800C] of string[16] = (
{aia_Weapon}             'aia_Weapon',
{aia_WaitX}              'aia_WaitX',
{aia_WaitY}              'aia_WaitY',
{aia_LookLeft}           'aia_LookLeft',
{aia_LookRight}          'aia_LookRight',
{aia_AwareExpl}          'aia_AwareExpl',
{aia_HJump}              'aia_HJump',
{aia_LJump}              'aia_LJump',
{aia_Skip}               'aia_Skip',
{aia_Wait}               'aia_Wait',
{aia_Put}                'aia_Put',
{aia_waitAngle}          'aia_waitAngle',
{aia_waitAmmoXY}         'aia_waitAmmoXY'
);

procedure DumpAction(Action: TAction; Me: PGear);
begin
if (Action.Action and ai_specmask) = 0 then
    WriteLnToConsole('AI action: '+ActionIdToStr[Action.Action])
else
    begin
    WriteLnToConsole('AI action: '+SpecActionIdToStr[Action.Action]);
    if (Action.Action = aia_WaitXL) or (Action.Action = aia_WaitXR) then
        WriteLnToConsole('AI action Wait X = '+IntToStr(Action.Param)+', current X = '+IntToStr(hwRound(Me^.X)))

    else if (Action.Action = aia_AwareExpl) then
        WriteLnToConsole('Aware X = ' + IntToStr(Action.X) + ', Y = ' + IntToStr(Action.Y));
    end
end;
{$ENDIF}

procedure AddAction(var Actions: TActions; Action: Longword; Param: LongInt; TimeDelta: Longword; X, Y: LongInt);
begin
if Actions.Count < MAXACTIONS then
    with Actions do
        begin
        actions[Count].Action:= Action;
        actions[Count].Param:= Param;
        actions[Count].X:= X;
        actions[Count].Y:= Y;
        if Count > 0 then
            actions[Count].Time:= TimeDelta
        else
            actions[Count].Time:= GameTicks + TimeDelta;
        inc(Count);
        end
end;

procedure CheckHang(Me: PGear);
begin
if hwRound(Me^.X) <> PrevX then
    begin
    PrevX:= hwRound(Me^.X);
    timedelta:= 0
    end else
        begin
        inc(timedelta);
        if timedelta > 1700 then
            begin
            timedelta:= 0;
            FreeActionsList
            end
        end
end;

procedure ProcessAction(var Actions: TActions; Me: PGear);
var s: shortstring;
begin
repeat
if Actions.Pos >= Actions.Count then exit;

with Actions.actions[Actions.Pos] do
    begin
    if Time > GameTicks then
        exit;
    {$IFDEF TRACEAIACTIONS}
    DumpAction(Actions.actions[Actions.Pos], Me);
    {$ENDIF}
    if (Action and ai_specmask) <> 0 then
        case Action of
            aia_Weapon:
                SetWeapon(TAmmoType(Param));

            aia_WaitXL:
                if hwRound(Me^.X) = Param then
                    begin
                    Action:= aia_LookLeft;
                    Time:= GameTicks;
                    exit
                    end
                    else if hwRound(Me^.X) < Param then
                        begin
                        //OutError('AI: WaitXL assert (' + IntToStr(hwRound(Me^.X)) + ' < ' + IntToStr(Param) + ')', false);
                        FreeActionsList;
                        exit
                        end
                    else
                        begin
                        CheckHang(Me);
                        exit
                        end;

            aia_WaitXR:
                if hwRound(Me^.X) = Param then
                    begin
                    Action:= aia_LookRight;
                    Time:= GameTicks;
                    exit
                    end
                    else if hwRound(Me^.X) > Param then
                        begin
                        //OutError('AI: WaitXR assert (' + IntToStr(hwRound(Me^.X)) + ' > ' + IntToStr(Param) + ')', false);
                        FreeActionsList;
                        exit
                        end
                    else
                        begin
                        CheckHang(Me);
                        exit
                        end;
            aia_LookLeft:
                if not Me^.dX.isNegative then
                    begin
                    ParseCommand('+left', true);
                    exit
                    end
                else
                    ParseCommand('-left', true);
            aia_LookRight:
                if Me^.dX.isNegative then
                    begin
                    ParseCommand('+right', true);
                    exit
                    end
                else ParseCommand('-right', true);
            aia_AwareExpl:
                AwareOfExplosion(X, Y, Param);

            aia_HJump:
                ParseCommand('hjump', true);

            aia_LJump:
                ParseCommand('ljump', true);

            aia_Skip:
                ParseCommand('skip', true);

            aia_Put:
                doPut(X, Y, true);

            aia_waitAngle:
                if LongInt(Me^.Angle) <> Abs(Param) then exit;

            aia_waitAmmoXY:
                if (CurAmmoGear <> nil) and ((hwRound(CurAmmoGear^.X) <> X) or (hwRound(CurAmmoGear^.Y) <> Y)) then
                    exit;
            end
        else
            begin
            s:= ActionIdToStr[Action];
            if (Param and ai_specmask) <> 0 then
                case Param of
                aim_push:
                s:= '+' + s;

                aim_release:
                s:= '-' + s;
            end
        else if Param <> 0 then
            s:= s + ' ' + IntToStr(Param);
        ParseCommand(s, true)
        end
    end;
inc(Actions.Pos);
if Actions.Pos <= Actions.Count then
    inc(Actions.actions[Actions.Pos].Time, GameTicks);
until false
end;

end.

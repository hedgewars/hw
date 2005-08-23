(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uAIActions;
interface
{$INCLUDE options.inc}
const aia_none       = 0;
      aia_Left       = 1;
      aia_Right      = 2;
      aia_Timer      = 3;
      aia_Slot       = 4;
      aia_attack     = 5;
      aia_Up         = 6;
      aia_Down       = 7;

      aia_Weapon     = $80000000;
      aia_WaitX      = $80000001;
      aia_WaitY      = $80000002;
      aia_LookLeft   = $80000003;
      aia_LookRight  = $80000004;

      aim_push       = $80000000;
      aim_release    = $80000001;
      ai_specmask    = $80000000;

type PAction = ^TAction;
     TAction = record
               Action, Param: Longword;
               Time: Longword;
               Next: PAction;
               end;

function AddAction(Action, Param, TimeDelta: Longword): PAction;
procedure FreeActionsList;
function IsActionListEmpty: boolean;
procedure ProcessAction;

implementation
uses uMisc, uConsts, uConsole, uTeams;

const ActionIdToStr: array[0..7] of string[16] = (
{aia_none}           '',
{aia_Left}           'left',
{aia_Right}          'right',
{aia_Timer}          'timer',
{aia_slot}           'slot',
{aia_attack}         'attack',
{aia_Up}             'up',
{aia_Down}           'down'
      );


var ActionList,
    FinAction: PAction;

function AddAction(Action, Param, TimeDelta: Longword): PAction;
begin
New(Result);
TryDo(Result <> nil, errmsgDynamicVar, true);
FillChar(Result^, sizeof(TAction), 0);
Result.Action:= Action;
Result.Param:= Param;
if ActionList = nil then
   begin
   Result.Time:= GameTicks + TimeDelta;
   ActionList:= Result;
   FinAction := Result
   end else
   begin
   Result.Time:= TimeDelta;
   FinAction.Next:= Result;
   FinAction:= Result
   end
end;

procedure DeleteCurrAction;
var t: PAction;
begin
t:= ActionList;
ActionList:= ActionList.Next;
if ActionList = nil then FinAction:= nil
                    else inc(ActionList.Time, t.Time);
Dispose(t)
end;

function IsActionListEmpty: boolean;
begin
Result:= ActionList = nil
end;

procedure FreeActionsList;
begin
while ActionList <> nil do DeleteCurrAction;
end;

procedure SetWeapon(weap: Longword);
var t: integer;
begin
t:= 0;
with CurrentTeam^ do
     with Hedgehogs[CurrHedgehog] do
          while Ammo[CurSlot, CurAmmo].AmmoType <> TAmmotype(weap) do
                begin
                ParseCommand('/slot ' + chr(49 + Ammoz[TAmmoType(weap)].Slot));
                inc(t);
                if t > 10 then OutError('AI: incorrect try to change weapon!', true)
                end
end;

procedure ProcessAction;
var s: shortstring;
begin
if ActionList = nil then exit;
with ActionList^ do
     begin
     if Time > GameTicks then exit;
     if (Action and ai_specmask) <> 0 then
        case Action of
           aia_Weapon: SetWeapon(Param);
            aia_WaitX: with CurrentTeam^ do
                            with Hedgehogs[CurrHedgehog] do
                                 if round(Gear.X) = Param then Time:= GameTicks
                                                          else exit;
            aia_WaitY: with CurrentTeam^ do
                            with Hedgehogs[CurrHedgehog] do
                                 if round(Gear.Y) = Param then Time:= GameTicks
                                                          else exit;
         aia_LookLeft: with CurrentTeam^ do
                            with Hedgehogs[CurrHedgehog] do
                                 if Gear.dX >= 0 then
                                    begin
                                    ParseCommand('+left');
                                    exit
                                    end else ParseCommand('-left');
        aia_LookRight: with CurrentTeam^ do
                            with Hedgehogs[CurrHedgehog] do
                                 if Gear.dX < 0 then
                                    begin
                                    ParseCommand('+right');
                                    exit
                                    end else ParseCommand('-right');
             end else
        begin
        s:= ActionIdToStr[Action];
        if (Param and ai_specmask) <> 0 then
           case Param of
             aim_push: s:= '+' + s;
          aim_release: s:= '-' + s;
             end
          else if Param <> 0 then s:= s + ' ' + inttostr(Param);
        ParseCommand(s)
        end
     end;
DeleteCurrAction
end;

end.

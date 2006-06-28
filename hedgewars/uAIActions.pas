(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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
uses uGears;
const MAXACTIONS = 256;
      aia_none       = 0;
      aia_Left       = 1;
      aia_Right      = 2;
      aia_Timer      = 3;
      aia_attack     = 4;
      aia_Up         = 5;
      aia_Down       = 6;

      aia_Weapon     = $80000000;
      aia_WaitX      = $80000001;
      aia_WaitY      = $80000002;
      aia_LookLeft   = $80000003;
      aia_LookRight  = $80000004;
      aia_AwareExpl  = $80000005;

      aim_push       = $80000000;
      aim_release    = $80000001;
      ai_specmask    = $80000000;

type TAction = record
               Action, Param: Longword;
               X, Y: integer;
               Time: Longword;
               end;
     TActions = record
                Count, Pos: Longword;
                actions: array[0..Pred(MAXACTIONS)] of TAction;
                Score: integer;
                end;

procedure AddAction(var Actions: TActions; Action, Param, TimeDelta: Longword; const X: integer = 0; Y: integer = 0);
procedure ProcessAction(var Actions: TActions; Me: PGear);

implementation
uses uMisc, uTeams, uConsts, uConsole, uAIMisc;

const ActionIdToStr: array[0..6] of string[16] = (
{aia_none}           '',
{aia_Left}           'left',
{aia_Right}          'right',
{aia_Timer}          'timer',
{aia_attack}         'attack',
{aia_Up}             'up',
{aia_Down}           'down'
                     );

procedure AddAction(var Actions: TActions; Action, Param, TimeDelta: Longword; const X: integer = 0; Y: integer = 0);
begin
with Actions do
     begin
     actions[Count].Action:= Action;
     actions[Count].Param:= Param;
     actions[Count].X:= X;
     actions[Count].Y:= Y;
     if Count > 0 then actions[Count].Time:= TimeDelta
                  else actions[Count].Time:= GameTicks + TimeDelta;
     inc(Count);
     TryDo(Count < MAXACTIONS, 'AI: actions overflow', true);
     end
end;

procedure SetWeapon(weap: Longword);
begin
with CurrentTeam^ do
     with Hedgehogs[CurrHedgehog] do
          while Ammo[CurSlot, CurAmmo].AmmoType <> TAmmoType(weap) do
                ParseCommand('/slot ' + chr(49 + Ammoz[TAmmoType(weap)].Slot));
end;

procedure ProcessAction(var Actions: TActions; Me: PGear);
var s: shortstring;
begin
if Actions.Pos >= Actions.Count then exit;
with Actions.actions[Actions.Pos] do
     begin
     if Time > GameTicks then exit;
     if (Action and ai_specmask) <> 0 then
        case Action of
           aia_Weapon: SetWeapon(Param);
            aia_WaitX: if round(Me.X) = Param then Time:= GameTicks
                                              else exit;
            aia_WaitY: if round(Me.Y) = Param then Time:= GameTicks
                                              else exit;
         aia_LookLeft: if Me.dX >= 0 then
                          begin
                          ParseCommand('+left');
                          exit
                          end else ParseCommand('-left');
        aia_LookRight: if Me.dX < 0 then
                          begin
                          ParseCommand('+right');
                          exit
                          end else ParseCommand('-right');
        aia_AwareExpl: AwareOfExplosion(X, Y, Param);
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
inc(Actions.Pos);
if Actions.Pos <= Actions.Count then
   inc(Actions.actions[Actions.Pos].Time, GameTicks)
end;

end.

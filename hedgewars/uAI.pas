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

unit uAI;
interface
{$INCLUDE options.inc}
procedure ProcessBot;

implementation
uses uAIActions, uAIMisc, uMisc, uTeams, uConsts, uAIAmmoTests, uGears, SDLh;

function Go(Gear: PGear; Times: Longword): boolean;
begin
Result:= false
end;

procedure Think;
var Targets: TTargets;
    Angle, Power: integer;
    Time: Longword;

    procedure FindTarget(Flags: Longword);
    var t: integer;
        a, aa: TAmmoType;
        Me: TPoint;
    begin
    t:= 0;
    with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
         begin
         Me.X:= round(Gear.X);
         Me.Y:= round(Gear.Y);
         end;
    repeat
      if isInMultiShoot then with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
                             a:= Ammo[CurSlot, CurAmmo].AmmoType
                        else a:= TAmmoType(random(ord(High(TAmmoType))));
      aa:= a;
      repeat
        if Assigned(AmmoTests[a].Test)
           and ((Flags = 0) or ((Flags and AmmoTests[a].Flags) <> 0)) then
           if AmmoTests[a].Test(Me, Targets.ar[t], Flags, Time, Angle, Power) then
              begin
              AddAction(aia_Weapon, ord(a), 1000);
              if Time <> 0 then AddAction(aia_Timer, Time div 1000, 400);
              exit
              end;
      if a = High(TAmmoType) then a:= Low(TAmmoType)
                             else inc(a)
      until isInMultiShoot or (a = aa);
    inc(t)
    until (t >= Targets.Count)
    end;

    procedure TryGo(lvl, Flags: Longword);
    var tmpGear: TGear;
        i, t: integer;
    begin
    with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
    for t:= aia_Left to aia_Right do
        if IsActionListEmpty then
           begin
           tmpGear:= Gear^;
           i:= 0;
           Gear.Message:= t;
           while HHGo(Gear) do
                 begin
                 if (i mod 5 = 0) then
                    begin
                    FindTarget(Flags);
                    if not IsActionListEmpty then
                       begin
                       if i > 0 then
                          begin
                          AddAction(t, aim_push, 1000);
                          AddAction(aia_WaitX, round(Gear.X), 0);
                          AddAction(t, aim_release, 0)
                          end;
                       Gear^:= tmpGear;
                       exit
                       end
                    end;
                 inc(i)
                 end;
           Gear^:= tmpGear
           end
    end;

begin
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     if ((Gear.State and (gstAttacked or gstAttacking or gstMoving or gstFalling)) <> 0) then exit;

FillTargets(Targets);

TryGo(0, 0);

if IsActionListEmpty then
   TryGo(0, ctfNotFull);
if IsActionListEmpty then
   TryGo(0, ctfBreach);

if IsActionListEmpty then
   begin
   AddAction(aia_Weapon, ord(amSkip), 1000);
   AddAction(aia_Attack, aim_push, 1000);
   exit
   end;

with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     begin
     if (Angle > 0) then AddAction(aia_LookRight, 0, 200)
        else if (Angle < 0) then AddAction(aia_LookLeft, 0, 200);
     Angle:= integer(Gear.Angle) - Abs(Angle);
     if Angle > 0 then
        begin
        AddAction(aia_Up, aim_push, 500);
        AddAction(aia_Up, aim_release, Angle)
        end else if Angle < 0 then
        begin
        AddAction(aia_Down, aim_push, 500);
        AddAction(aia_Down, aim_release, -Angle)
        end;
     AddAction(aia_attack, aim_push, 300);
     AddAction(aia_attack, aim_release, Power);
     end
end;

procedure ProcessBot;
begin
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     if (Gear <> nil)and((Gear.State and gstHHDriven) <> 0) then
        begin
        if IsActionListEmpty then Think;
        ProcessAction
        end
end;

end.

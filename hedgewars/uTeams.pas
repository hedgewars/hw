(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uTeams;
interface
uses SDLh, uConsts, uKeys, uGears, uRandom;
{$INCLUDE options.inc}
type PHedgehog = ^THedgehog;
     PTeam     = ^TTeam;
     PHHAmmo   = ^THHAmmo;
     THedgehog = record
                 Name: string[15];
                 Gear: PGear;
                 NameRect, HealthRect, HealthTagRect: TSDL_Rect;
                 Ammo: PHHAmmo;
                 CurSlot, CurAmmo: LongWord;
                 AltSlot, AltAmmo: LongWord;
                 Team: PTeam;
                 AttacksNum: Longword;
                 visStepPos: LongWord;
                 BotLevel  : LongWord; // 0 - Human player
                 end;
     THHAmmo   = array[0..cMaxSlot, 0..cMaxSlotAmmo] of TAmmo;
     TTeam = record
             Next: PTeam;
             Color: Cardinal;
             TeamName: string[15];
             ExtDriven: boolean;
             Aliases: array[0..cKeyMaxIndex] of shortstring;
             Hedgehogs: array[0..cMaxHHIndex] of THedgehog;
             Ammos: array[0..cMaxHHIndex] of THHAmmo;
             CurrHedgehog: integer;
             NameRect, CrossHairRect, GraveRect: TSDL_Rect;
             GraveName: string;
             FortName: string;
             AttackBar: LongWord;
             end;

var CurrentTeam: PTeam = nil;
    TeamsList: PTeam = nil;

function AddTeam: PTeam;
procedure ApplyAmmoChanges(Hedgehog: PHedgehog);
procedure SwitchHedgehog;
procedure InitTeams;
procedure OnUsedAmmo(Ammo: PHHAmmo);
function  TeamSize(p: PTeam): Longword;

implementation
uses uMisc, uStore, uWorld, uIO, uAIActions;

procedure FreeTeamsList; forward;

procedure SwitchHedgehog;
var tteam: PTeam;
    th: integer;
begin
FreeActionsList;
TargetPoint.X:= NoPointX;
if CurrentTeam = nil then OutError('nil Team', true);
tteam:= CurrentTeam;
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     if Gear <> nil then Gear.Message:= 0;

repeat
  CurrentTeam:= CurrentTeam.Next;
  if CurrentTeam = nil then CurrentTeam:= TeamsList;
  th:= CurrentTeam.CurrHedgehog;
  repeat
    CurrentTeam.CurrHedgehog:= Succ(CurrentTeam.CurrHedgehog) mod cMaxHHIndex;
  until (CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear <> nil) or (CurrentTeam.CurrHedgehog = th)
until (CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear <> nil) or (CurrentTeam = tteam);

if (CurrentTeam = tteam) then
   begin
   if GameType = gmtDemo then
      begin
      SendIPC('q');
      GameState:= gsExit;
      exit
      end else OutError('There''s only one team on map!', true);
   end;
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     begin
     AttacksNum:= 0;
     with Gear^ do
          begin
          State:= State or gstHHDriven;
          Active:= true
          end;
     FollowGear:= Gear
     end;
ResetKbd;
cWindSpeed:= (GetRandom * 2 - 1) * cMaxWindSpeed;
{$IFDEF DEBUGFILE}AddFileLog('Wind = '+FloatToStr(cWindSpeed));{$ENDIF}
ApplyAmmoChanges(@CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog]);
TurnTimeLeft:= cHedgehogTurnTime
end;

procedure SetFirstTurnHedgehog;
var i: integer;
begin
if CurrentTeam=nil then OutError('nil Team (SetFirstTurnHedgehog)', true);
i:= 0;
while (i<cMaxHHIndex)and(CurrentTeam.Hedgehogs[i].Gear=nil) do inc(i);
if CurrentTeam.Hedgehogs[i].Gear = nil then OutError(errmsgIncorrectUse + ' (sfth)', true);
CurrentTeam.CurrHedgehog:= i;
end;

function AddTeam: PTeam;
begin
try
   New(Result);
except Result:= nil; OutError(errmsgDynamicVar, true) end;
FillChar(Result^, sizeof(TTeam), 0);
Result.AttackBar:= 1;
if TeamsList = nil then TeamsList:= Result
                   else begin
                        Result.Next:= TeamsList;
                        TeamsList:= Result
                        end;
CurrentTeam:= Result
end;

procedure FreeTeamsList;
var t, tt: PTeam;
begin
tt:= TeamsList;
TeamsList:= nil;
while tt<>nil do
      begin
      t:= tt;
      tt:= tt.Next;
      try
      Dispose(t)
      except OutError(errmsgDynamicVar) end;
      end;
end;

procedure InitTeams;
var p: PTeam;
    i: integer;
begin
p:= TeamsList;
while p <> nil do
      begin
      for i:= 0 to cMaxHHIndex do
          if p.Hedgehogs[i].Gear <> nil then
             begin
             p.Ammos[i][0, 0]:= Ammoz[amGrenade].Ammo;
             p.Ammos[i][0, 1]:= Ammoz[amUFO].Ammo;
             p.Ammos[i][1, 0]:= Ammoz[amBazooka].Ammo;
             p.Ammos[i][2, 0]:= Ammoz[amShotgun].Ammo;
             p.Ammos[i][3, 0]:= Ammoz[amPickHammer].Ammo;
             p.Ammos[i][3, 1]:= Ammoz[amRope].Ammo;
             p.Ammos[i][4, 0]:= Ammoz[amSkip].Ammo;
             p.Hedgehogs[i].Gear.Health:= 100;
             p.Hedgehogs[i].Ammo:= @p.Ammos[0]
             {0 - общее на всех оружие, i - у каждого своё
             можно группировать ёжиков, чтобы у каждой группы было своё оружие}
             end;
      p:= p.Next
      end;
SetFirstTurnHedgehog;
end;

procedure ApplyAmmoChanges(Hedgehog: PHedgehog);
var s: shortstring;
begin
with Hedgehog^ do
     begin     
     if Ammo[CurSlot, CurAmmo].Count = 0 then
        begin
        CurAmmo:= 0;
        while (CurAmmo <= cMaxSlotAmmo) and (Ammo[CurSlot, CurAmmo].Count = 0) do inc(CurAmmo)
        end;

with Ammo[CurSlot, CurAmmo] do
     begin
     s:= Ammoz[AmmoType].Name;
     if Count <> AMMO_INFINITE then
        s:= s + ' (' + IntToStr(Count) + ')';
     if (Propz and ammoprop_Timerable) <> 0 then
        s:= s + ', ' + inttostr(Timer div 1000) + ' sec';
     AddCaption(s, Team.Color, capgrpAmmoinfo);
     if (Propz and ammoprop_NeedTarget) <> 0
        then begin
        Gear.State:= Gear.State or      gstHHChooseTarget;
        isCursorVisible:= true
        end else begin
        Gear.State:= Gear.State and not gstHHChooseTarget;
        AdjustMPoint;
        isCursorVisible:= false
        end
     end
     end
end;

procedure PackAmmo(Ammo: PHHAmmo; Slot: integer);
var ami: integer;
    b: boolean;
begin
    repeat
      b:= false;
      ami:= 0;
      while (not b) and (ami < cMaxSlotAmmo) do
          if (Ammo[slot, ami].Count = 0)
             and (Ammo[slot, ami + 1].Count > 0) then b:= true
                                                 else inc(ami);
      if b then // есть пустое место
         begin
         Ammo[slot, ami]:= Ammo[slot, ami + 1]
         end
    until not b;
end;

procedure OnUsedAmmo(Ammo: PHHAmmo);
var s, a: Longword;
begin
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     begin
     if CurAmmoGear = nil then begin s:= CurSlot; a:= CurAmmo end
                          else begin s:= AltSlot; a:= AltAmmo end;
     with Ammo[s, a] do
          if Count <> AMMO_INFINITE then
             begin
             dec(Count);
             if Count = 0 then PackAmmo(Ammo, CurSlot)
             end
     end
end;

function  TeamSize(p: PTeam): Longword;
var i: Longword;
begin
Result:= 0;
for i:= 0 to cMaxHHIndex do
    if p.Hedgehogs[i].Gear <> nil then inc(Result)
end;

initialization

finalization

FreeTeamsList

end.

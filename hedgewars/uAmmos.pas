(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2006, 2007 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uAmmos;
interface
uses uConsts, uTeams;
{$INCLUDE options.inc}

procedure AddAmmoStore(s: shortstring);
procedure AssignStores;
procedure AddAmmo(Hedgehog: pointer; ammo: TAmmoType);
function  HHHasAmmo(Hedgehog: pointer; Ammo: TAmmoType): boolean;
procedure PackAmmo(Ammo: PHHAmmo; Slot: LongInt);
procedure OnUsedAmmo(var Hedgehog: THedgehog);

implementation
uses uMisc, uGears;
type TAmmoCounts = array[TAmmoType] of Longword;
var StoresList: array[0..Pred(cMaxHHs)] of PHHAmmo;
    StoreCnt: Longword = 0;

procedure FillAmmoStore(Ammo: PHHAmmo; var cnts: TAmmoCounts);
var mi: array[0..cMaxSlotIndex] of byte;
    a: TAmmoType;
begin
FillChar(mi, sizeof(mi), 0);
FillChar(Ammo^, sizeof(Ammo^), 0);
for a:= Low(TAmmoType) to High(TAmmoType) do
    if cnts[a] > 0 then
       begin
       TryDo(mi[Ammoz[a].Slot] <= cMaxSlotAmmoIndex, 'Ammo slot overflow', true);
       Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]]:= Ammoz[a].Ammo;
       Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]].Count:= cnts[a];
       inc(mi[Ammoz[a].Slot])
       end
end;

procedure AddAmmoStore(s: shortstring);
var cnt: Longword;
    a: TAmmoType;
    ammos: TAmmoCounts;
begin
TryDo(byte(s[0]) = byte(ord(High(TAmmoType)) + 1), 'Invalid ammo scheme (incompatible frontend)', true);

inc(StoreCnt);
TryDo(StoreCnt <= cMaxHHs, 'Ammo stores overflow', true);

new(StoresList[Pred(StoreCnt)]);

for a:= Low(TAmmoType) to High(TAmmoType) do
    begin
    cnt:= byte(s[ord(a) + 1]) - byte('0');
    if cnt = 9 then cnt:= AMMO_INFINITE;
    ammos[a]:= cnt
    end;

FillAmmoStore(StoresList[Pred(StoreCnt)], ammos)
end;

function GetAmmoByNum(num: Longword): PHHAmmo;
begin
TryDo(num < StoreCnt, 'Invalid store number', true);
exit(StoresList[num])
end;

procedure AssignStores;
var t: LongInt;
    i: Longword;
begin
for t:= 0 to Pred(TeamsCount) do
   with TeamsArray[t]^ do
      begin
      for i:= 0 to cMaxHHIndex do
          if Hedgehogs[i].Gear <> nil then
             Hedgehogs[i].Ammo:= GetAmmoByNum(Hedgehogs[i].AmmoStore);
      end
end;

procedure AddAmmo(Hedgehog: pointer; ammo: TAmmoType);
var ammos: TAmmoCounts;
    slot, ami: LongInt;
    hhammo: PHHAmmo;
begin
FillChar(ammos, sizeof(ammos), 0);
hhammo:= PHedgehog(Hedgehog)^.Ammo;

for slot:= 0 to cMaxSlotIndex do
    for ami:= 0 to cMaxSlotAmmoIndex do
        if hhammo^[slot, ami].Count > 0 then
           ammos[hhammo^[slot, ami].AmmoType]:= hhammo^[slot, ami].Count;

if ammos[ammo] <> AMMO_INFINITE then inc(ammos[ammo], Ammoz[ammo].NumberInCase);
FillAmmoStore(hhammo, ammos)
end;

procedure PackAmmo(Ammo: PHHAmmo; Slot: LongInt);
var ami: LongInt;
    b: boolean;
begin
    repeat
      b:= false;
      ami:= 0;
      while (not b) and (ami < cMaxSlotAmmoIndex) do
          if (Ammo^[Slot, ami].Count = 0)
             and (Ammo^[Slot, ami + 1].Count > 0) then b:= true
                                                 else inc(ami);
      if b then // there's a free item in ammo stack
         begin
         Ammo^[Slot, ami]:= Ammo^[Slot, ami + 1];
         Ammo^[Slot, ami + 1].Count:= 0
         end;
    until not b;
end;

procedure OnUsedAmmo(var Hedgehog: THedgehog);
var s, a: Longword;
begin
with Hedgehog do
     begin
     if CurAmmoGear = nil then begin s:= CurSlot; a:= CurAmmo end
                          else begin s:= AltSlot; a:= AltAmmo end;
     with Ammo^[s, a] do
          if Count <> AMMO_INFINITE then
             begin
             dec(Count);
             if Count = 0 then PackAmmo(Ammo, CurSlot)
             end
     end
end;

function  HHHasAmmo(Hedgehog: pointer; Ammo: TAmmoType): boolean;
var slot, ami: LongInt;
begin
Slot:= Ammoz[Ammo].Slot;
ami:= 0;
while (ami <= cMaxSlotAmmoIndex) do
      begin
      with PHedgehog(Hedgehog)^.Ammo^[Slot, ami] do
            if (AmmoType = Ammo) and (Count > 0) then exit(true);
      inc(ami)
      end;
HHHasAmmo:= false
end;

end.

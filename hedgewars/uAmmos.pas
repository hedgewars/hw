(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2006-2008 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uAmmos;
interface
uses uConsts, uTeams;

procedure init_uAmmos;
procedure free_uAmmos;

procedure AddAmmoStore(s: shortstring);
procedure AssignStores;
procedure AddAmmo(var Hedgehog: THedgehog; ammo: TAmmoType);
function  HHHasAmmo(var Hedgehog: THedgehog; Ammo: TAmmoType): boolean;
procedure PackAmmo(Ammo: PHHAmmo; Slot: LongInt);
procedure OnUsedAmmo(var Hedgehog: THedgehog);
procedure ApplyAngleBounds(var Hedgehog: THedgehog; AmmoType: TAmmoType);
procedure ApplyAmmoChanges(var Hedgehog: THedgehog);
procedure SwitchNotHeldAmmo(var Hedgehog: THedgehog);
procedure SetWeapon(weap: TAmmoType);
procedure DisableSomeWeapons;
procedure ResetWeapons;

var shoppa: boolean;

implementation
uses uMisc, uGears, uWorld, uLocale, uConsole;

type TAmmoCounts = array[TAmmoType] of Longword;
var StoresList: array[0..Pred(cMaxHHs)] of PHHAmmo;
    StoreCnt: Longword;

procedure FillAmmoStore(Ammo: PHHAmmo; var cnts: TAmmoCounts);
var mi: array[0..cMaxSlotIndex] of byte;
    a: TAmmoType;
begin
FillChar(mi, sizeof(mi), 0);
FillChar(Ammo^, sizeof(Ammo^), 0);
for a:= Low(TAmmoType) to High(TAmmoType) do
    begin
    if cnts[a] > 0 then
       begin
       TryDo(mi[Ammoz[a].Slot] <= cMaxSlotAmmoIndex, 'Ammo slot overflow', true);
       Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]]:= Ammoz[a].Ammo;

       Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]].Count:= cnts[a];
       Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]].InitialCount:= cnts[a];

       if ((GameFlags and gfPlaceHog) <> 0) and (a = amTeleport) then 
           Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]].Count:= AMMO_INFINITE;
       inc(mi[Ammoz[a].Slot])
       end
    else if ((GameFlags and gfPlaceHog) <> 0) and (a = amTeleport) then 
       begin
       TryDo(mi[Ammoz[a].Slot] <= cMaxSlotAmmoIndex, 'Ammo slot overflow', true);
       Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]]:= Ammoz[a].Ammo;

       Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]].Count:= 0;
       Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]].InitialCount:= 0;

       if ((GameFlags and gfPlaceHog) <> 0) and (a = amTeleport) then 
           Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]].Count:= AMMO_INFINITE;
       inc(mi[Ammoz[a].Slot])
       end
    end
end;

procedure AddAmmoStore(s: shortstring);
const probability: array [0..8] of LongWord = (0,20,30,60,100,150,200,400,600);
var cnt: Longword;
    a: TAmmoType;
    ammos: TAmmoCounts;
    substr: shortstring; // TEMPORARY
begin
TryDo(byte(s[0]) = byte(ord(High(TAmmoType))) * 2, 'Invalid ammo scheme (incompatible frontend)', true);

// FIXME - TEMPORARY hardcoded check on shoppa pending creation of crate *type* probability editor
substr:= Copy(s,1,15);
if (substr = '000000990000009') or 
   (substr = '000000990000000') then
    shoppa:= true;

inc(StoreCnt);
TryDo(StoreCnt <= cMaxHHs, 'Ammo stores overflow', true);

new(StoresList[Pred(StoreCnt)]);

for a:= Low(TAmmoType) to High(TAmmoType) do
    begin
    if a <> amNothing then
        begin
        Ammoz[a].Probability:= probability[byte(s[ord(a) + ord(High(TAmmoType))]) - byte('0')];
		if (TrainingFlags and tfIgnoreDelays) <> 0 then Ammoz[a].SkipTurns:= 0;
        cnt:= byte(s[ord(a)]) - byte('0');
        // avoid things we already have infinite number
        if cnt = 9 then
            begin
            cnt:= AMMO_INFINITE;
            Ammoz[a].Probability:= 0
            end;
        // avoid things we already have by scheme
        // merge this into DisableSomeWeapons ?
        if ((a = amLowGravity) and ((GameFlags and gfLowGravity) <> 0)) or
           ((a = amInvulnerable) and ((GameFlags and gfInvulnerable) <> 0)) or
           ((a = amLaserSight) and ((GameFlags and gfLaserSight) <> 0)) or
           ((a = amVampiric) and ((GameFlags and gfVampiric) <> 0)) then
            begin
            cnt:= 0;
            Ammoz[a].Probability:= 0
            end;
        ammos[a]:= cnt;
        if shoppa then Ammoz[a].NumberInCase:= 1;  // FIXME - TEMPORARY remove when crate number in case editor is added

        if ((GameFlags and gfKing) <> 0) and (Ammoz[a].SkipTurns = 0) and (a <> amTeleport) and (a <> amSkip) then 
            Ammoz[a].SkipTurns:= 1;

        if ((GameFlags and gfPlaceHog) <> 0) and
            (a <> amTeleport) and (a <> amSkip) and 
            (Ammoz[a].SkipTurns < 10000) then inc(Ammoz[a].SkipTurns,10000)
        end else
        ammos[a]:= AMMO_INFINITE
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

procedure AddAmmo(var Hedgehog: THedgehog; ammo: TAmmoType);
var ammos: TAmmoCounts;
    slot, ami: LongInt;
    hhammo: PHHAmmo;
begin
FillChar(ammos, sizeof(ammos), 0);
hhammo:= Hedgehog.Ammo;

for slot:= 0 to cMaxSlotIndex do
    for ami:= 0 to cMaxSlotAmmoIndex do
        if hhammo^[slot, ami].Count > 0 then
           ammos[hhammo^[slot, ami].AmmoType]:= hhammo^[slot, ami].Count;

if ammos[ammo] <> AMMO_INFINITE then
   begin
   inc(ammos[ammo], Ammoz[ammo].NumberInCase);
   if ammos[ammo] > AMMO_INFINITE then ammos[ammo]:= AMMO_INFINITE
   end;

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
      if b then // there is a free item in ammo stack
         begin
         Ammo^[Slot, ami]:= Ammo^[Slot, ami + 1];
         Ammo^[Slot, ami + 1].Count:= 0
         end;
    until not b;
end;

procedure OnUsedAmmo(var Hedgehog: THedgehog);
begin
with Hedgehog do
	begin
	MultiShootAttacks:= 0;
	with Ammo^[CurSlot, CurAmmo] do
		if Count <> AMMO_INFINITE then
			begin
			dec(Count);
			if Count = 0 then
				begin
				PackAmmo(Ammo, CurSlot);
				SwitchNotHeldAmmo(Hedgehog)
				end
			end
	end
end;

function  HHHasAmmo(var Hedgehog: THedgehog; Ammo: TAmmoType): boolean;
var slot, ami: LongInt;
begin
Slot:= Ammoz[Ammo].Slot;
ami:= 0;
while (ami <= cMaxSlotAmmoIndex) do
      begin
      with Hedgehog.Ammo^[Slot, ami] do
            if (AmmoType = Ammo) then
               exit((Count > 0) and (Hedgehog.Team^.Clan^.TurnNumber > Ammoz[AmmoType].SkipTurns));
      inc(ami)
      end;
HHHasAmmo:= false
end;

procedure ApplyAngleBounds(var Hedgehog: THedgehog; AmmoType: TAmmoType);
begin
with Hedgehog do
	begin
	CurMinAngle:= Ammoz[AmmoType].minAngle;
	if Ammoz[AmmoType].maxAngle <> 0 then
		CurMaxAngle:= Ammoz[AmmoType].maxAngle
	else
		CurMaxAngle:= cMaxAngle;

	with Hedgehog.Gear^ do
		begin
		if Angle < CurMinAngle then Angle:= CurMinAngle;
		if Angle > CurMaxAngle then Angle:= CurMaxAngle;
		end
	end
end;

procedure SwitchToFirstLegalAmmo(var Hedgehog: THedgehog);
begin
with Hedgehog do
	begin
	CurAmmo:= 0;
	CurSlot:= 0;
	while (CurSlot <= cMaxSlotIndex) and
		((Ammo^[CurSlot, CurAmmo].Count = 0) or
		(Ammoz[Ammo^[CurSlot, CurAmmo].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber >= 0))
		do
		begin
		while (CurAmmo <= cMaxSlotAmmoIndex) and
			((Ammo^[CurSlot, CurAmmo].Count = 0) or
			(Ammoz[Ammo^[CurSlot, CurAmmo].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber >= 0))
			do inc(CurAmmo);

		if (CurAmmo > cMaxSlotAmmoIndex) then
			begin
			CurAmmo:= 0;
			inc(CurSlot)
			end
		end;
	TryDo(CurSlot <= cMaxSlotIndex, 'Ammo slot index overflow', true)
	end
end;

procedure ApplyAmmoChanges(var Hedgehog: THedgehog);
var s: shortstring;
begin
TargetPoint.X:= NoPointX;

with Hedgehog do
	begin

	if (Ammo^[CurSlot, CurAmmo].Count = 0) then
		SwitchToFirstLegalAmmo(Hedgehog);

        //bad things could happen here in case CurSlot is overflowing
	ApplyAngleBounds(Hedgehog, Ammo^[CurSlot, CurAmmo].AmmoType);

	with Ammo^[CurSlot, CurAmmo] do
		begin
        if AmmoType <> amNothing then
            begin
		    s:= trammo[Ammoz[AmmoType].NameId];
		    if (Count <> AMMO_INFINITE) and not (Hedgehog.Team^.ExtDriven or (Hedgehog.BotLevel > 0)) then
			    s:= s + ' (' + IntToStr(Count) + ')';
		    if (Propz and ammoprop_Timerable) <> 0 then
			    s:= s + ', ' + inttostr(Timer div 1000) + ' ' + trammo[sidSeconds];
		    AddCaption(s, Team^.Clan^.Color, capgrpAmmoinfo);
            end;
		if (Propz and ammoprop_NeedTarget) <> 0
			then begin
			Gear^.State:= Gear^.State or      gstHHChooseTarget;
			isCursorVisible:= true
			end else begin
			Gear^.State:= Gear^.State and not gstHHChooseTarget;
			isCursorVisible:= false
			end;
		ShowCrosshair:= (Propz and ammoprop_NoCrosshair) = 0
		end
	end
end;

procedure SwitchNotHeldAmmo(var Hedgehog: THedgehog);
begin
with Hedgehog do
	if ((Ammo^[CurSlot, CurAmmo].Propz and ammoprop_DontHold) <> 0) or
		(Ammoz[Ammo^[CurSlot, CurAmmo].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber >= 0) then
		SwitchToFirstLegalAmmo(Hedgehog);
end;

procedure SetWeapon(weap: TAmmoType);
begin
ParseCommand('/setweap ' + char(weap), true)
end;

procedure DisableSomeWeapons;
var i, slot, a: Longword;
	t: TAmmoType;
begin
for i:= 0 to Pred(StoreCnt) do
	for slot:= 0 to cMaxSlotIndex do
		begin
		for a:= 0 to cMaxSlotAmmoIndex do
			with StoresList[i]^[slot, a] do
				if (Propz and ammoprop_NotBorder) <> 0 then Count:= 0;

		PackAmmo(StoresList[i], slot)
		end;

for t:= Low(TAmmoType) to High(TAmmoType) do
	if (Ammoz[t].Ammo.Propz and ammoprop_NotBorder) <> 0 then Ammoz[t].Probability:= 0
end;

// Restore indefinitely disabled weapons and initial weapon counts.  Only used for hog placement right now
procedure ResetWeapons;
var i, slot, a: Longword;
	t: TAmmoType;
begin
for i:= 0 to Pred(StoreCnt) do
	for slot:= 0 to cMaxSlotIndex do
		begin
		for a:= 0 to cMaxSlotAmmoIndex do
			with StoresList[i]^[slot, a] do
                if Count <> InitialCount then Count:= InitialCount;

		PackAmmo(StoresList[i], slot)
		end;
for t:= Low(TAmmoType) to High(TAmmoType) do
	if Ammoz[t].SkipTurns >= 10000 then dec(Ammoz[t].SkipTurns,10000);
end;

procedure init_uAmmos;
begin
	shoppa:= false;
	StoreCnt:= 0
end;

procedure free_uAmmos;
var i: LongWord;
begin
	for i:= 0 to Pred(StoreCnt) do Dispose(StoresList[i]);
	StoreCnt:= 0
end;

end.

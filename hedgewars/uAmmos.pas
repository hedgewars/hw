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

unit uAmmos;
interface
uses uConsts, uTypes;

procedure initModule;
procedure freeModule;

procedure AddAmmoStore;
procedure SetAmmoLoadout(var s: shortstring);
procedure SetAmmoProbability(var s: shortstring);
procedure SetAmmoDelay(var s: shortstring);
procedure SetAmmoReinforcement(var s: shortstring);
procedure AssignStores;
procedure AddAmmo(var Hedgehog: THedgehog; ammo: TAmmoType);
procedure AddAmmo(var Hedgehog: THedgehog; ammo: TAmmoType; amt: LongWord);
procedure SetAmmo(var Hedgehog: THedgehog; ammo: TAmmoType; cnt: LongWord);
function  HHHasAmmo(var Hedgehog: THedgehog; Ammo: TAmmoType): LongWord;
procedure PackAmmo(Ammo: PHHAmmo; Slot: LongInt);
procedure OnUsedAmmo(var Hedgehog: THedgehog);
procedure ApplyAngleBounds(var Hedgehog: THedgehog; AmmoType: TAmmoType);
procedure ApplyAmmoChanges(var Hedgehog: THedgehog);
procedure SwitchNotHeldAmmo(var Hedgehog: THedgehog);
procedure SetWeapon(weap: TAmmoType);
procedure DisableSomeWeapons;
procedure ResetWeapons;
function  GetAmmoByNum(num: Longword): PHHAmmo;
function  GetCurAmmoEntry(var Hedgehog: THedgehog): PAmmo;
function  GetAmmoEntry(var Hedgehog: THedgehog; am: TAmmoType): PAmmo;

var StoreCnt: Longword;

implementation
uses uLocale, uVariables, uCommands, uUtils, uCaptions, uDebug;

type TAmmoCounts = array[TAmmoType] of Longword;
var StoresList: array[0..Pred(cMaxHHs)] of PHHAmmo;
    ammoLoadout, ammoProbability, ammoDelay, ammoReinforcement: shortstring;
    InitialCounts: array[0..Pred(cMaxHHs)] of TAmmoCounts;

procedure FillAmmoStore(Ammo: PHHAmmo; var cnts: TAmmoCounts);
var mi: array[0..cMaxSlotIndex] of byte;
    a: TAmmoType;
begin
{$HINTS OFF}
FillChar(mi, sizeof(mi), 0);
{$HINTS ON}
FillChar(Ammo^, sizeof(Ammo^), 0);
for a:= Low(TAmmoType) to High(TAmmoType) do
    begin
    if cnts[a] > 0 then
        begin
        TryDo(mi[Ammoz[a].Slot] <= cMaxSlotAmmoIndex, 'Ammo slot overflow', true);
        Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]]:= Ammoz[a].Ammo;
        with Ammo^[Ammoz[a].Slot, mi[Ammoz[a].Slot]] do
            Count:= cnts[a];
        inc(mi[Ammoz[a].Slot])
        end
    end;
AmmoMenuInvalidated:= true;
end;

procedure AddAmmoStore;
const probability: array [0..8] of LongWord = (0,20,30,60,100,200,400,600,800);
var cnt: Longword;
    a: TAmmoType;
    ammos: TAmmoCounts;
begin
TryDo((byte(ammoLoadout[0]) = byte(ord(High(TAmmoType)))) and (byte(ammoProbability[0]) = byte(ord(High(TAmmoType)))) and (byte(ammoDelay[0]) = byte(ord(High(TAmmoType)))) and (byte(ammoReinforcement[0]) = byte(ord(High(TAmmoType)))), 'Incomplete or missing ammo scheme set (incompatible frontend or demo/save?)', true);

inc(StoreCnt);
TryDo(StoreCnt <= cMaxHHs, 'Ammo stores overflow', true);

new(StoresList[Pred(StoreCnt)]);

for a:= Low(TAmmoType) to High(TAmmoType) do
    begin
    if a <> amNothing then
        begin
        Ammoz[a].Probability:= probability[byte(ammoProbability[ord(a)]) - byte('0')];
        Ammoz[a].SkipTurns:= (byte(ammoDelay[ord(a)]) - byte('0'));
        Ammoz[a].NumberInCase:= (byte(ammoReinforcement[ord(a)]) - byte('0'));
        cnt:= byte(ammoLoadout[ord(a)]) - byte('0');
        // avoid things we already have infinite number
        if cnt = 9 then
            begin
            cnt:= AMMO_INFINITE;
            Ammoz[a].Probability:= 0
            end;
        if Ammoz[a].NumberInCase = 0 then
            Ammoz[a].Probability:= 0;

        // avoid things we already have by scheme
        // merge this into DisableSomeWeapons ?
        if ((a = amLowGravity) and ((GameFlags and gfLowGravity) <> 0))
        or ((a = amInvulnerable) and ((GameFlags and gfInvulnerable) <> 0))
        or ((a = amLaserSight) and ((GameFlags and gfLaserSight) <> 0))
        or ((a = amVampiric) and ((GameFlags and gfVampiric) <> 0))
        or ((a = amExtraTime) and (cHedgehogTurnTime >= 1000000)) then
            begin
            cnt:= 0;
            Ammoz[a].Probability:= 0
            end;
        ammos[a]:= cnt;

        if ((GameFlags and gfKing) <> 0) and ((GameFlags and gfPlaceHog) = 0)
        and (Ammoz[a].SkipTurns = 0) and (a <> amTeleport) and (a <> amSkip) then
            Ammoz[a].SkipTurns:= 1;

        if ((GameFlags and gfPlaceHog) <> 0)
        and (a <> amTeleport) and (a <> amSkip)
        and (Ammoz[a].SkipTurns < 10000) then
            inc(Ammoz[a].SkipTurns,10000);
    if ((GameFlags and gfPlaceHog) <> 0) and (a = amTeleport) then
        ammos[a]:= AMMO_INFINITE
        end 
        
    else
        ammos[a]:= AMMO_INFINITE;
    if ((GameFlags and gfPlaceHog) <> 0) and (a = amTeleport) then 
        InitialCounts[Pred(StoreCnt)][a]:= cnt
    else
        InitialCounts[Pred(StoreCnt)][a]:= ammos[a];
    end;
FillAmmoStore(StoresList[Pred(StoreCnt)], ammos)
end;

function GetAmmoByNum(num: Longword): PHHAmmo;
begin
    TryDo(num < StoreCnt, 'Invalid store number', true);
    GetAmmoByNum:= StoresList[num]
end;

function GetCurAmmoEntry(var Hedgehog: THedgehog): PAmmo;
begin
    GetCurAmmoEntry:= GetAmmoEntry(Hedgehog, Hedgehog.CurAmmoType)
end;

function GetAmmoEntry(var Hedgehog: THedgehog; am: TAmmoType): PAmmo;
var ammoidx, slot: LongWord;
begin
with Hedgehog do
    begin
    slot:= Ammoz[am].Slot;
    ammoidx:= 0;
    while (ammoidx < cMaxSlotAmmoIndex) and (Ammo^[slot, ammoidx].AmmoType <> am) do
        inc(ammoidx);
    GetAmmoEntry:= @Ammo^[slot, ammoidx];
    if (Ammo^[slot, ammoidx].AmmoType <> am) then
        GetAmmoEntry:= GetAmmoEntry(Hedgehog, amNothing)
    end;
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
                begin
                Hedgehogs[i].Ammo:= GetAmmoByNum(Hedgehogs[i].AmmoStore);
                if (GameFlags and gfPlaceHog) <> 0 then
                    Hedgehogs[i].CurAmmoType:= amTeleport
                else
                    Hedgehogs[i].CurAmmoType:= amNothing
                end
        end
end;

procedure AddAmmo(var Hedgehog: THedgehog; ammo: TAmmoType; amt: LongWord);
var cnt: LongWord;
    a: PAmmo;
begin
a:= GetAmmoEntry(Hedgehog, ammo);
if (a^.AmmoType <> amNothing) then
    cnt:= a^.Count
else
    cnt:= 0;
if (cnt <> AMMO_INFINITE) then
    begin
    inc(cnt, amt);
    SetAmmo(Hedgehog, ammo, cnt)
    end
end;

procedure AddAmmo(var Hedgehog: THedgehog; ammo: TAmmoType);
begin
    AddAmmo(Hedgehog, ammo, Ammoz[ammo].NumberInCase);
end;

procedure SetAmmo(var Hedgehog: THedgehog; ammo: TAmmoType; cnt: LongWord);
var ammos: TAmmoCounts;
    slot, ami: LongInt;
    hhammo: PHHAmmo;
    CurWeapon: PAmmo;
begin
{$HINTS OFF}
FillChar(ammos, sizeof(ammos), 0);
{$HINTS ON}
hhammo:= Hedgehog.Ammo;

for slot:= 0 to cMaxSlotIndex do
    for ami:= 0 to cMaxSlotAmmoIndex do
        if hhammo^[slot, ami].Count > 0 then
            ammos[hhammo^[slot, ami].AmmoType]:= hhammo^[slot, ami].Count;

ammos[ammo]:= cnt;
if ammos[ammo] > AMMO_INFINITE then ammos[ammo]:= AMMO_INFINITE;

FillAmmoStore(hhammo, ammos);
CurWeapon:= GetCurAmmoEntry(Hedgehog);
with Hedgehog, CurWeapon^ do
    if (Count = 0) or (AmmoType = amNothing) then
        begin
        PackAmmo(Ammo, Ammoz[AmmoType].Slot);
        CurAmmoType:= amNothing
        end
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
            and (Ammo^[Slot, ami + 1].Count > 0) then
                b:= true
            else
                inc(ami);
        if b then // there is a free item in ammo stack
            begin
            Ammo^[Slot, ami]:= Ammo^[Slot, ami + 1];
            Ammo^[Slot, ami + 1].Count:= 0
            end;
    until not b;
AmmoMenuInvalidated:= true;
end;

procedure OnUsedAmmo(var Hedgehog: THedgehog);
var CurWeapon: PAmmo;
begin
CurWeapon:= GetCurAmmoEntry(Hedgehog);
with Hedgehog do
    begin

    MultiShootAttacks:= 0;
    with CurWeapon^ do
        if Count <> AMMO_INFINITE then
            begin
            dec(Count);
            if Count = 0 then
                begin
                PackAmmo(Ammo, Ammoz[AmmoType].Slot);
                //SwitchNotHeldAmmo(Hedgehog);
                CurAmmoType:= amNothing
                end
            end
    end;
end;

function  HHHasAmmo(var Hedgehog: THedgehog; Ammo: TAmmoType): LongWord;
var slot, ami: LongInt;
begin
    HHHasAmmo:= 0;
    Slot:= Ammoz[Ammo].Slot;
    ami:= 0;
    while (ami <= cMaxSlotAmmoIndex) do
    begin
        with Hedgehog.Ammo^[Slot, ami] do
            if (AmmoType = Ammo) then
                if Hedgehog.Team^.Clan^.TurnNumber > Ammoz[AmmoType].SkipTurns then
                    exit(Count)
                else 
                    exit(0);
        inc(ami)
    end;
end;

procedure ApplyAngleBounds(var Hedgehog: THedgehog; AmmoType: TAmmoType);
begin
if Hedgehog.Gear <> nil then
    with Hedgehog do
        begin
        CurMinAngle:= Ammoz[AmmoType].minAngle;
        if Ammoz[AmmoType].maxAngle <> 0 then
            CurMaxAngle:= Ammoz[AmmoType].maxAngle
        else
            CurMaxAngle:= cMaxAngle;

        with Hedgehog.Gear^ do
            begin
            if Angle < CurMinAngle then
                Angle:= CurMinAngle;
            if Angle > CurMaxAngle then
                Angle:= CurMaxAngle;
            end
        end
end;

procedure SwitchToFirstLegalAmmo(var Hedgehog: THedgehog);
var slot, ammoidx: LongWord;
begin
with Hedgehog do
    begin
    CurAmmoType:= amNothing;
    slot:= 0;
    ammoidx:= 0;
    while (slot <= cMaxSlotIndex) and
        ((Ammo^[slot, ammoidx].Count = 0) or
        (Ammoz[Ammo^[slot, ammoidx].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber >= 0))
        do
            begin
            while (ammoidx <= cMaxSlotAmmoIndex)
            and ((Ammo^[slot, ammoidx].Count = 0) or (Ammoz[Ammo^[slot, ammoidx].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber >= 0))
                do inc(ammoidx);

        if (ammoidx > cMaxSlotAmmoIndex) then
            begin
            ammoidx:= 0;
            inc(slot)
            end
        end;
    TryDo(slot <= cMaxSlotIndex, 'Ammo slot index overflow', true);
    CurAmmoType:= Ammo^[slot, ammoidx].AmmoType;
    end
end;

procedure ApplyAmmoChanges(var Hedgehog: THedgehog);
var s: shortstring;
    CurWeapon: PAmmo;
begin
TargetPoint.X:= NoPointX;

with Hedgehog do
    begin
    Timer:= 10;

    CurWeapon:= GetCurAmmoEntry(Hedgehog);

    if (CurWeapon^.Count = 0) then
        SwitchToFirstLegalAmmo(Hedgehog)
    else if CurWeapon^.AmmoType = amNothing then
        Hedgehog.CurAmmoType:= amNothing;

    CurWeapon:= GetCurAmmoEntry(Hedgehog);

    ApplyAngleBounds(Hedgehog, CurWeapon^.AmmoType);

    with CurWeapon^ do
        begin
        s:= trammo[Ammoz[AmmoType].NameId];
        if (Count <> AMMO_INFINITE) and not (Hedgehog.Team^.ExtDriven or (Hedgehog.BotLevel > 0)) then
            s:= s + ' (' + IntToStr(Count) + ')';
        if (Propz and ammoprop_Timerable) <> 0 then
            s:= s + ', ' + IntToStr(Timer div 1000) + ' ' + trammo[sidSeconds];
        AddCaption(s, Team^.Clan^.Color, capgrpAmmoinfo);
        if (Propz and ammoprop_NeedTarget) <> 0 then
            begin
            if Gear <> nil then Gear^.State:= Gear^.State or      gstHHChooseTarget;
            isCursorVisible:= true
            end
        else
            begin
            if Gear <> nil then Gear^.State:= Gear^.State and not gstHHChooseTarget;
            isCursorVisible:= false
            end;
        end
    end;
end;

procedure SwitchNotHeldAmmo(var Hedgehog: THedgehog);
begin
with Hedgehog do
    if ((Ammoz[CurAmmoType].Ammo.Propz and ammoprop_DontHold) <> 0)
    or (Ammoz[CurAmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber >= 0) then
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
                if (Propz and ammoprop_NotBorder) <> 0 then
                    begin
                    Count:= 0;
                    InitialCounts[i][AmmoType]:= 0
                    end;

        PackAmmo(StoresList[i], slot)
        end;

for t:= Low(TAmmoType) to High(TAmmoType) do
    if (Ammoz[t].Ammo.Propz and ammoprop_NotBorder) <> 0 then
        Ammoz[t].Probability:= 0
end;

procedure SetAmmoLoadout(var s: shortstring);
begin
    ammoLoadout:= s;
end;

procedure SetAmmoProbability(var s: shortstring);
begin
    ammoProbability:= s;
end;

procedure SetAmmoDelay(var s: shortstring);
begin
    ammoDelay:= s;
end;

procedure SetAmmoReinforcement(var s: shortstring);
begin
    ammoReinforcement:= s;
end;

// Restore indefinitely disabled weapons and initial weapon counts.  Only used for hog placement right now
procedure ResetWeapons;
var i, t: Longword;
    a: TAmmoType;
begin
for t:= 0 to Pred(TeamsCount) do
    with TeamsArray[t]^ do
        for i:= 0 to cMaxHHIndex do
            Hedgehogs[i].CurAmmoType:= amNothing;

for i:= 0 to Pred(StoreCnt) do
    FillAmmoStore(StoresList[i], InitialCounts[i]);

for a:= Low(TAmmoType) to High(TAmmoType) do
    if Ammoz[a].SkipTurns >= 10000 then
        dec(Ammoz[a].SkipTurns,10000)
end;



procedure chAddAmmoStore(var descr: shortstring);
begin
descr:= ''; // avoid compiler hint
AddAmmoStore
end;

procedure initModule;
var i: Longword;
begin
    RegisterVariable('ammloadt', @SetAmmoLoadout, false);
    RegisterVariable('ammdelay', @SetAmmoDelay, false);
    RegisterVariable('ammprob',  @SetAmmoProbability, false);
    RegisterVariable('ammreinf', @SetAmmoReinforcement, false);
    RegisterVariable('ammstore', @chAddAmmoStore , false);

    StoreCnt:= 0;
    ammoLoadout:= '';
    ammoProbability:= '';
    ammoDelay:= '';
    ammoReinforcement:= '';
    for i:=1 to ord(High(TAmmoType)) do
        begin
        ammoLoadout:= ammoLoadout + '0';
        ammoProbability:= ammoProbability + '0';
        ammoDelay:= ammoDelay + '0';
        ammoReinforcement:= ammoReinforcement + '0'
        end;
    FillChar(InitialCounts, sizeof(InitialCounts), 0)
end;

procedure freeModule;
var i: LongWord;
begin
    if StoreCnt > 0 then
        for i:= 0 to Pred(StoreCnt) do
            Dispose(StoresList[i])
end;

end.

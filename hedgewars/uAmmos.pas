unit uAmmos;
interface
uses uConsts;
{$INCLUDE options.inc}
type PHHAmmo = ^THHAmmo;
     THHAmmo = array[0..cMaxSlotIndex, 0..cMaxSlotAmmoIndex] of TAmmo;

procedure AddAmmoStore(s: shortstring);
procedure AssignStores;
procedure AddAmmo(Hedgehog: pointer; ammo: TAmmoType);
function  HHHasAmmo(Hedgehog: pointer; Ammo: TAmmoType): boolean;
procedure PackAmmo(Ammo: PHHAmmo; Slot: integer);
procedure OnUsedAmmo(Ammo: PHHAmmo);

implementation
uses uMisc, uTeams, uGears;
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
       Ammo[Ammoz[a].Slot, mi[Ammoz[a].Slot]]:= Ammoz[a].Ammo;
       Ammo[Ammoz[a].Slot, mi[Ammoz[a].Slot]].Count:= cnts[a];
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
Result:= StoresList[num]
end;

procedure AssignStores;
var tteam: PTeam;
    i: Longword;
begin
tteam:= TeamsList;
while tteam <> nil do
      begin
      for i:= 0 to cMaxHHIndex do
          if tteam.Hedgehogs[i].Gear <> nil then
             tteam.Hedgehogs[i].Ammo:= GetAmmoByNum(tteam.Hedgehogs[i].AmmoStore);
      tteam:= tteam.Next
      end
end;

procedure AddAmmo(Hedgehog: pointer; ammo: TAmmoType);
var ammos: TAmmoCounts;
    slot, ami: integer;
    hhammo: PHHAmmo;
begin
FillChar(ammos, sizeof(ammos), 0);
hhammo:= PHedgehog(Hedgehog).Ammo;

for slot:= 0 to cMaxSlotIndex do
    for ami:= 0 to cMaxSlotAmmoIndex do
        if hhammo[slot, ami].Count > 0 then
           ammos[hhammo[slot, ami].AmmoType]:= hhammo[slot, ami].Count;

if ammos[ammo] <> AMMO_INFINITE then inc(ammos[ammo]);
FillAmmoStore(hhammo, ammos)
end;

procedure PackAmmo(Ammo: PHHAmmo; Slot: integer);
var ami: integer;
    b: boolean;
begin
    repeat
      b:= false;
      ami:= 0;
      while (not b) and (ami < cMaxSlotAmmoIndex) do
          if (Ammo[Slot, ami].Count = 0)
             and (Ammo[Slot, ami + 1].Count > 0) then b:= true
                                                 else inc(ami);
      if b then // there's a free item in ammo stack
         begin
         Ammo[Slot, ami]:= Ammo[Slot, ami + 1];
         Ammo[Slot, ami + 1].Count:= 0
         end;
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

function  HHHasAmmo(Hedgehog: pointer; Ammo: TAmmoType): boolean;
var slot, ami: integer;
begin
Slot:= Ammoz[Ammo].Slot;
ami:= 0;
Result:= false;
while (not Result) and (ami <= cMaxSlotAmmoIndex) do
      begin
      with PHedgehog(Hedgehog).Ammo[Slot, ami] do
            if (AmmoType = Ammo) and (Count > 0) then Result:= true;
      inc(ami)
      end
end;

end.

unit uAmmos;
interface
uses uConsts;
{$INCLUDE options.inc}
type PHHAmmo = ^THHAmmo;
     THHAmmo = array[0..cMaxSlotIndex, 0..cMaxSlotAmmoIndex] of TAmmo;

procedure AddAmmoStore(s: shortstring);
procedure AssignStores;

implementation
uses uMisc, uTeams;
var StoresList: array[0..Pred(cMaxHHs)] of PHHAmmo;
    StoreCnt: Longword = 0;

procedure AddAmmoStore(s: shortstring);
var mi: array[0..cMaxSlotIndex] of byte;
    a: TAmmoType;
    cnt: Longword;
    tmp: PHHAmmo;
begin
TryDo(byte(s[0]) = byte(ord(High(TAmmoType)) + 1), 'Invalid ammo scheme (incompatible frontend)', true);

inc(StoreCnt);
TryDo(StoreCnt <= cMaxHHs, 'Ammo stores overflow', true);

new(StoresList[Pred(StoreCnt)]);
tmp:= StoresList[Pred(StoreCnt)];

FillChar(mi, sizeof(mi), 0);
for a:= Low(TAmmoType) to High(TAmmoType) do
    begin
    cnt:= byte(s[ord(a) + 1]) - byte('0');
    if cnt > 0 then
       begin
       if cnt >= 9 then cnt:= AMMO_INFINITE;
       TryDo(mi[Ammoz[a].Slot] <= cMaxSlotAmmoIndex, 'Ammo slot overflow', true);
       tmp[Ammoz[a].Slot, mi[Ammoz[a].Slot]]:= Ammoz[a].Ammo;
       tmp[Ammoz[a].Slot, mi[Ammoz[a].Slot]].Count:= cnt;
       inc(mi[Ammoz[a].Slot])
       end
    end;
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

end.

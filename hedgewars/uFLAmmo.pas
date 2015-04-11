unit uFLAmmo;
interface
uses uFLTypes;

function getAmmosList: PPChar; cdecl;
procedure freeAmmosList;

function ammoByName(s: shortstring): PAmmo;
procedure sendAmmoConfig(var ammo: TAmmo);

implementation
uses uFLUtils, uFLIPC, uPhysFSLayer, uFLData;

const MAX_AMMO_NAMES = 64;
type
    TAmmoArray = array [0..0] of TAmmo;
    PAmmoArray = ^TAmmoArray;
var
    ammoList: PAmmo;
    ammoNumber: LongInt;
    listOfAmmoNames: array[0..MAX_AMMO_NAMES] of PChar;

procedure loadAmmo;
var f: PFSFile;
    ammo: PAmmo;
    ammos: PAmmoArray;
    s: ansistring;
    i: Longword;
begin
    f:= pfsOpenRead('/Config/weapons.ini');
    ammoNumber:= 0;

    if f <> nil then
    begin
        while (not pfsEOF(f)) do
        begin
            pfsReadLnA(f, s);

            if (length(s) > 0) and (s[1] <> '[') then
                inc(ammoNumber);
        end;

        //inc(ammoNumber); // add some default ammo

        ammoList:= GetMem(sizeof(ammoList^) * (ammoNumber + 1));
        ammo:= PAmmo(ammoList);
        pfsSeek(f, 0);

        while (not pfsEOF(f)) do
        begin
            pfsReadLnA(f, s);

            i:= 1;
            while(i <= length(s)) and (s[i] <> '=') do inc(i);

            if i < length(s) then
            begin
                ammo^.ammoName:= copy(s, 1, i - 1);
                delete(s, 1, i);
                // TODO: split into 4 shortstrings
                i:= length(s) div 4;
                ammo^.a:= copy(s, 1, i);
                ammo^.b:= copy(s, i + 1, i);
                ammo^.c:= copy(s, i * 2 + 1, i);
                ammo^.d:= copy(s, i * 3 + 1, i);
                inc(ammo)
            end;
        end;

        pfsClose(f)
    end;
end;


function getAmmosList: PPChar; cdecl;
var i, t, l: Longword;
    ammo: PAmmo;
begin
    if ammoList = nil then
        loadAmmo;

    t:= ammoNumber;
    if t >= MAX_AMMO_NAMES then 
        t:= MAX_AMMO_NAMES;

    ammo:= ammoList;
    for i:= 0 to Pred(t) do
    begin
        l:= length(ammo^.ammoName);
        if l >= 255 then l:= 254;
        ammo^.ammoName[l + 1]:= #0;
        listOfAmmoNames[i]:= @ammo^.ammoName[1];
        inc(ammo)
    end;

    listOfAmmoNames[t]:= nil;

    getAmmosList:= listOfAmmoNames
end;

function ammoByName(s: shortstring): PAmmo;
var i: Longword;
    ammo: PAmmo;
begin
    ammo:= ammoList;
    i:= 0;
    while (i < ammoNumber) and (ammo^.ammoName <> s) do
    begin
        inc(ammo);
        inc(i)
    end;

    if i < ammoNumber then ammoByName:= ammo else ammoByName:= nil
end;

procedure freeAmmosList;
begin
    if ammoList <> nil then
        FreeMem(ammoList, sizeof(ammoList^) * (ammoNumber + 1))
end;


procedure sendAmmoConfig(var ammo: TAmmo);
var i: Longword;
begin
    with ammo do
    begin
        ipcToEngine('eammloadt ' + ammo.a);
        ipcToEngine('eammprob '  + ammo.b);
        ipcToEngine('eammdelay ' + ammo.c);
        ipcToEngine('eammreinf ' + ammo.d);
    end
end;

end.

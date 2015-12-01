unit uFLThemes;
interface

function getThemesList: PPChar; cdecl;
procedure freeThemesList(list: PPChar); cdecl;
function getThemeIcon(themeName: PChar; buffer: PChar; buflen: Longword): Longword; cdecl;

const colorsSet: array[0..8] of shortstring = (
                                               '16712196'
                                               , '4817089'
                                               , '1959610'
                                               , '11878895'
                                               , '10526880'
                                               , '2146048'
                                               , '16681742'
                                               , '6239749'
                                               , '16776961');

implementation
uses uPhysFSLayer;

function getThemesList: PPChar; cdecl;
var list, res, tmp: PPChar;
    i, size: Longword;
begin
    list:= pfsEnumerateFiles('Themes');
    size:= 0;
    tmp:= list;
    while tmp^ <> nil do
    begin
        inc(size);
        inc(tmp)
    end;

    res:= GetMem((3 + size) * sizeof(PChar));
    res^:= PChar(list);
    inc(res);
    res^:= PChar(res + size + 2);
    inc(res);

    getThemesList:= res;

    for i:= 1 to size do
    begin
        if pfsExists('/Themes/' + shortstring(list^) + '/icon.png') then
        begin
            res^:= list^;
            inc(res)
        end;

        inc(list)
    end;

    res^:= nil
end;

procedure freeThemesList(list: PPChar); cdecl;
var listEnd: PPChar;
begin
    dec(list);
    listEnd:= PPChar(list^);
    dec(list);

    pfsFreeList(PPChar(list^));
    freeMem(list, (listEnd - list) * sizeof(PChar))
end;

function getThemeIcon(themeName: PChar; buffer: PChar; buflen: Longword): Longword; cdecl;
var s: shortstring;
    f: PFSFile;
begin
    s:= '/Themes/' + shortstring(themeName) + '/icon@2x.png';

    f:= pfsOpenRead(s);

    if f = nil then
        getThemeIcon:= 0
    else
    begin
        getThemeIcon:= pfsBlockRead(f, buffer, buflen);
        pfsClose(f)
    end;
end;

end.

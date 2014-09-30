unit uFLData;
interface

function getThemesList: PPChar; cdecl;
procedure freeThemesList(list: PPChar); cdecl;
function getThemeIcon(themeName: PChar; buffer: PChar; buflen: Longword): Longword; cdecl;

implementation
uses uPhysFSLayer;

function getThemesList: PPChar; cdecl;
begin
    getThemesList:= pfsEnumerateFiles('Themes')
end;

procedure freeThemesList(list: PPChar); cdecl;
begin
    pfsFreeList(list)
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

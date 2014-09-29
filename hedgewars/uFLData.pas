unit uFLData;
interface

function getThemesList: PPChar; cdecl;
procedure freeThemesList(list: PPChar); cdecl;

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

end.

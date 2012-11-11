
// defines functions used for web port

unit uWeb;
interface

type
    TResourceList = record
        count : Integer;
        files : array[0..500] of shortstring;
    end;

function generateResourceList:TResourceList;

implementation

uses uConsts, uVariables, uTypes;

function readThemeCfg:TResourceList; forward;

function generateResourceList:TResourceList;
var
    cfgRes : TResourceList;
    i,j : Integer;
    t, t2 : shortstring;
    si : TSprite;
    res : TResourceList;

begin

    res.count := 0;

    for i:= 0 to Pred(TeamsCount) do
        with TeamsArray[i]^ do
            begin
                Str(i, t);
                
                res.files[res.count] := UserPathz[ptGraves] + '/' + GraveName;
                res.files[res.count + 1] := UserPathz[ptForts] + '/' + FortName;
                res.files[res.count + 2] := UserPathz[ptGraphics] + '/' + FortName;
                res.files[res.count + 3] := UserPathz[ptFlags] + '/' + flag;

                inc(res.count, 4);
                
            end;
            
    for si:= Low(TSprite) to High(TSprite) do
    with SpritesData[si] do
        begin
            Str(si, t);
            res.files[res.count] := UserPathz[Path] + '/' + FileName;
            res.files[res.count + 1] := UserPathz[AltPath] + '/' + FileName;
            inc(res.count, 2);

        end;
        
    for i:= 0 to Pred(ClansCount) do
    with CLansArray[i]^ do
    begin
        for j:= 0 to Pred(TeamsNumber) do
        begin
            with Teams[j]^ do
            begin
                Str(i, t);
                Str(j, t2);
                res.files[res.count] := UserPathz[ptForts] + '/' + FortName;
                inc(res.count);

            end;
        end;
    end;
    
    cfgRes := readThemeCfg();
    
    for i:= 0 to Pred(cfgRes.count) do
    begin
        res.files[res.count] := cfgRes.files[i];
        inc(res.count);
    end;
    
    res.files[res.count] := UserPathz[ptFlags] + '/cpu';
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptFlags] + '/hedgewars';
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptGraphics] + '/' + cHHFileName;
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptGraphics] + '/Girder';
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptCurrTheme] + '/LandTex';
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptCurrTheme] + '/LandBackTex';
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptCurrTheme] + '/Girder';
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptCurrTheme] + '/Border';
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptMapCurrent] + '/mask';
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptMapCurrent] + '/map';
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptGraphics] + '/missions';
    inc(res.count);
    
    res.files[res.count] := UserPathz[ptGraphics] + '/Progress';
    inc(res.count);
        
    res.files[res.count] := UserPathz[ptGraves] + '/Statue';
    inc(res.count);

    res.files[res.count] := UserPathz[ptGraphics] + '/' + cCHFileName;
    inc(res.count);

    generateResourceList:=res;
end;

function readThemeCfg : TResourceList;
var
s,key : shortstring;
f : TextFile;
i: Integer;
res : TResourceList;
begin
    s:=Pathz[ptCurrTheme] + '/' + cThemeCFGFilename;

    Assign(f, s);
    {$I-}

    filemode := 0;
    Reset(f);

    res.count := 0;
    
    while not eof(f) do
    begin
    Readln(f, s);
    
    if Length(s) = 0 then
        continue;
    if s[1] = ';' then
        continue;
        
    i:= Pos('=', s);
    key:= Trim(Copy(s, 1, Pred(i)));
    Delete(s, 1, i);
    
    if (key = 'object') or (key = 'spray') then
    begin
        i:=Pos(',', s);
        
        res.files[res.count] := Pathz[ptCurrTheme] + '/' + Trim(Copy(s, 1, Pred(i)));
        res.files[res.count + 1] := Pathz[ptGraphics] + '/' + Trim(Copy(s, 1, Pred(i)));
        inc(res.count, 2);
        
    end;
    
    end;

    close(f);
    {$I+}
    
    readThemeCfg := res;
end;

end.

unit uFLSchemes;
interface
uses uFLTypes;

function getSchemesList: PPChar; cdecl;
procedure freeSchemesList;

function schemeByName(s: shortstring): PScheme;
procedure sendSchemeConfig(var scheme: TScheme);

implementation
uses uFLUtils, uFLIPC, uPhysFSLayer, uFLData;

const MAX_SCHEME_NAMES = 64;
type
    TSchemeArray = array [0..0] of TScheme;
    PSchemeArray = ^TSchemeArray;
var
    schemesList: PScheme;
    schemesNumber: LongInt;
    listOfSchemeNames: array[0..MAX_SCHEME_NAMES] of PChar;
    tmpScheme: TScheme;

const ints: array[0 .. 16] of record
            name: shortstring;
            param: ^LongInt;
        end = (
              (name: 'damagefactor'; param: @tmpScheme.damagefactor)
            , (name: 'turntime'; param: @tmpScheme.turntime)
            , (name: 'health'; param: @tmpScheme.health)
            , (name: 'suddendeath'; param: @tmpScheme.suddendeath)
            , (name: 'caseprobability'; param: @tmpScheme.caseprobability)
            , (name: 'minestime'; param: @tmpScheme.minestime)
            , (name: 'landadds'; param: @tmpScheme.landadds)
            , (name: 'minedudpct'; param: @tmpScheme.minedudpct)
            , (name: 'explosives'; param: @tmpScheme.explosives)
            , (name: 'minesnum'; param: @tmpScheme.minesnum)
            , (name: 'healthprobability'; param: @tmpScheme.healthprobability)
            , (name: 'healthcaseamount'; param: @tmpScheme.healthcaseamount)
            , (name: 'waterrise'; param: @tmpScheme.waterrise)
            , (name: 'healthdecrease'; param: @tmpScheme.healthdecrease)
            , (name: 'ropepct'; param: @tmpScheme.ropepct)
            , (name: 'getawaytime'; param: @tmpScheme.getawaytime)
            , (name: 'worldedge'; param: @tmpScheme.worldedge)
              );
const bools: array[0 .. 19] of record
            name: shortstring;
            param: ^boolean;
        end = (
              (name: 'fortsmode'; param: @tmpScheme.fortsmode)
            , (name: 'divteams'; param: @tmpScheme.divteams)
            , (name: 'solidland'; param: @tmpScheme.solidland)
            , (name: 'border'; param: @tmpScheme.border)
            , (name: 'lowgrav'; param: @tmpScheme.lowgrav)
            , (name: 'laser'; param: @tmpScheme.laser)
            , (name: 'invulnerability'; param: @tmpScheme.invulnerability)
            , (name: 'mines'; param: @tmpScheme.mines)
            , (name: 'vampiric'; param: @tmpScheme.vampiric)
            , (name: 'karma'; param: @tmpScheme.karma)
            , (name: 'artillery'; param: @tmpScheme.artillery)
            , (name: 'randomorder'; param: @tmpScheme.randomorder)
            , (name: 'king'; param: @tmpScheme.king)
            , (name: 'placehog'; param: @tmpScheme.placehog)
            , (name: 'sharedammo'; param: @tmpScheme.sharedammo)
            , (name: 'disablegirders'; param: @tmpScheme.disablegirders)
            , (name: 'disablewind'; param: @tmpScheme.disablewind)
            , (name: 'morewind'; param: @tmpScheme.morewind)
            , (name: 'tagteam'; param: @tmpScheme.tagteam)
            , (name: 'bottomborder'; param: @tmpScheme.bottomborder)
              );


procedure loadSchemes;
var f: PFSFile;
    scheme: PScheme;
    schemes: PSchemeArray;
    s: shortstring;
    l, i, ii: Longword;
    isFound: boolean;
begin
    f:= pfsOpenRead('/Config/schemes.ini');
    schemesNumber:= 0;

    if f <> nil then
    begin
        while (not pfsEOF(f)) and (schemesNumber = 0) do
        begin
            pfsReadLn(f, s);

            if copy(s, 1, 5) = 'size=' then
                schemesNumber:= strToInt(midStr(s, 6));
        end;

        //inc(schemesNumber); // add some default schemes

        schemesList:= GetMem(sizeof(schemesList^) * (schemesNumber + 1));
        schemes:= PSchemeArray(schemesList);

        while (not pfsEOF(f)) do
        begin
            pfsReadLn(f, s);

            i:= 1;
            while(i <= length(s)) and (s[i] <> '\') do inc(i);

            if i < length(s) then
            begin
                l:= strToInt(copy(s, 1, i - 1));
                delete(s, 1, i);

                if (l <= schemesNumber) and (l > 0) then
                begin
                    scheme:= @schemes^[l - 1];

                    if copy(s, 1, 5) = 'name=' then
                        tmpScheme.schemeName:= midStr(s, 6)
                    else if copy(s, 1, 12) = 'scriptparam=' then
                        tmpScheme.scriptparam:= midStr(s, 13) else
                    begin
                        ii:= 0;
                        repeat
                            isFound:= readInt(ints[ii].name, s, ints[ii].param^);
                            inc(ii)
                        until isFound or (ii > High(ints));

                        if not isFound then
                            begin
                                ii:= 0;
                                repeat
                                    isFound:= readBool(bools[ii].name, s, bools[ii].param^);
                                    inc(ii)
                                until isFound or (ii > High(bools));
                            end;
                    end;

                    scheme^:= tmpScheme
                end;
            end;
        end;

        pfsClose(f)
    end;
end;


function getSchemesList: PPChar; cdecl;
var i, t, l: Longword;
    scheme: PScheme;
begin
    if schemesList = nil then
        loadSchemes;

    t:= schemesNumber;
    if t >= MAX_SCHEME_NAMES then 
        t:= MAX_SCHEME_NAMES;

    scheme:= schemesList;
    for i:= 0 to Pred(t) do
    begin
        l:= length(scheme^.schemeName);
        if l >= 255 then l:= 254;
        scheme^.schemeName[l + 1]:= #0;
        listOfSchemeNames[i]:= @scheme^.schemeName[1];
        inc(scheme)
    end;

    listOfSchemeNames[t]:= nil;

    getSchemesList:= listOfSchemeNames
end;

function schemeByName(s: shortstring): PScheme;
var i: Longword;
    scheme: PScheme;
begin
    scheme:= schemesList;
    i:= 0;
    while (i < schemesNumber) and (scheme^.schemeName <> s) do
    begin
        inc(scheme);
        inc(i)
    end;

    if i < schemesNumber then schemeByName:= scheme else schemeByName:= nil
end;

procedure freeSchemesList;
begin
    if schemesList <> nil then
        FreeMem(schemesList, sizeof(schemesList^) * (schemesNumber + 1))
end;


procedure sendSchemeConfig(var scheme: TScheme);
var i: Longword;
begin
    with scheme do
    begin
        ipcToEngine('e$turntime ' + inttostr(scheme.turntime));
        ipcToEngine('e$minesnum ' + inttostr(scheme.minesnum));
    end
end;

end.

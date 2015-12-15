unit uFLSchemes;
interface
uses uFLTypes;

function getSchemesList: PPChar; cdecl;
procedure freeSchemesList;

function schemeByName(s: shortstring): PScheme;
procedure sendSchemeConfig(var scheme: TScheme);

implementation
uses uFLUtils, uFLIPC, uPhysFSLayer, uFLThemes;

const MAX_SCHEME_NAMES = 64;
type
    TSchemeArray = array [0..0] of TScheme;
    PSchemeArray = ^TSchemeArray;
var
    schemesList: PScheme;
    schemesNumber: LongInt;
    listOfSchemeNames: array[0..MAX_SCHEME_NAMES] of PChar;
    tmpScheme: TScheme;

const ints: array[0 .. 17] of record
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
            , (name: 'airmines'; param: @tmpScheme.airmines)
              );
const bools: array[0 .. 24] of record
            name: shortstring;
            param: ^boolean;
            flag: Longword;
        end = (
              (name: 'fortsmode'; param: @tmpScheme.fortsmode; flag: $00001000)
            , (name: 'divteams'; param: @tmpScheme.divteams; flag: $00000010)
            , (name: 'solidland'; param: @tmpScheme.solidland; flag: $00000004)
            , (name: 'border'; param: @tmpScheme.border; flag: $00000008)
            , (name: 'lowgrav'; param: @tmpScheme.lowgrav; flag: $00000020)
            , (name: 'laser'; param: @tmpScheme.laser; flag: $00000040)
            , (name: 'invulnerability'; param: @tmpScheme.invulnerability; flag: $00000080)
            , (name: 'resethealth'; param: @tmpScheme.resethealth; flag: $00000100)
            , (name: 'vampiric'; param: @tmpScheme.vampiric; flag: $00000200)
            , (name: 'karma'; param: @tmpScheme.karma; flag: $00000400)
            , (name: 'artillery'; param: @tmpScheme.artillery; flag: $00000800)
            , (name: 'randomorder'; param: @tmpScheme.randomorder; flag: $00002000)
            , (name: 'king'; param: @tmpScheme.king; flag: $00004000)
            , (name: 'placehog'; param: @tmpScheme.placehog; flag: $00008000)
            , (name: 'sharedammo'; param: @tmpScheme.sharedammo; flag: $00010000)
            , (name: 'disablegirders'; param: @tmpScheme.disablegirders; flag: $00020000)
            , (name: 'disablewind'; param: @tmpScheme.disablewind; flag: $00800000)
            , (name: 'morewind'; param: @tmpScheme.morewind; flag: $01000000)
            , (name: 'tagteam'; param: @tmpScheme.tagteam; flag: $02000000)
            , (name: 'bottomborder'; param: @tmpScheme.bottomborder; flag: $04000000)
            , (name: 'disablelandobjects'; param: @tmpScheme.disablelandobjects; flag: $00040000)
            , (name: 'aisurvival'; param: @tmpScheme.aisurvival; flag: $00080000)
            , (name: 'infattack'; param: @tmpScheme.infattack; flag: $00100000)
            , (name: 'resetweps'; param: @tmpScheme.resetweps; flag: $00200000)
            , (name: 'perhogammo'; param: @tmpScheme.perhogammo; flag: $00400000)
              );

procedure loadSchemes;
var f: PFSFile;
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
                    if copy(s, 1, 5) = 'name=' then
                        schemes^[l - 1].schemeName:= midStr(s, 6)
                    else if copy(s, 1, 12) = 'scriptparam=' then
                        schemes^[l - 1].scriptparam:= midStr(s, 13) else
                    begin
                        ii:= 0;
                        repeat
                            isFound:= readInt(ints[ii].name, s, PLongInt(ints[ii].param - @tmpScheme + @schemes^[l - 1])^);
                            inc(ii)
                        until isFound or (ii > High(ints));

                        if not isFound then
                            begin
                                ii:= 0;
                                repeat
                                    isFound:= readBool(bools[ii].name, s, PBoolean(bools[ii].param - @tmpScheme + @schemes^[l - 1])^);
                                    inc(ii)
                                until isFound or (ii > High(bools));
                            end;
                    end;
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
    gf: Longword;
begin
    with scheme do
    begin
        if turntime <> 45 then
            ipcToEngine('e$turntime ' + inttostr(turntime * 1000));
        if minesnum <> 4 then
            ipcToEngine('e$minesnum ' + inttostr(minesnum));
        if damagefactor <> 100 then
            ipcToEngine('e$damagepct ' + inttostr(damagefactor));
        if worldedge > 0 then
            ipcToEngine('e$worldedge ' + inttostr(worldedge));
        if length(scriptparam) > 0 then
            ipcToEngine('e$scriptparam ' + scriptparam);
        if suddendeath <> 15 then
            ipcToEngine('e$sd_turns ' + inttostr(suddendeath));
        if waterrise <> 47 then
            ipcToEngine('e$waterrise ' + inttostr(waterrise));
        if ropepct <> 100 then
            ipcToEngine('e$ropepct ' + inttostr(ropepct));
        if getawaytime <> 100 then
            ipcToEngine('e$getawaytime ' + inttostr(getawaytime));
        if caseprobability <> 5 then
            ipcToEngine('e$casefreq ' + inttostr(caseprobability));
        if healthprobability <> 35 then
            ipcToEngine('e$healthprob ' + inttostr(healthprobability));
        if minestime <> 3 then
            ipcToEngine('e$minestime ' + inttostr(minestime * 1000));
        if minedudpct <> 0 then
            ipcToEngine('e$minedudpct ' + inttostr(minedudpct));
        if explosives <> 2 then
            ipcToEngine('e$explosives ' + inttostr(explosives));
        if airmines <> 0 then
            ipcToEngine('e$airmines ' + inttostr(airmines));
        if healthcaseamount <> 25 then
            ipcToEngine('e$hcaseamount ' + inttostr(healthcaseamount));
        if healthdecrease <> 5 then
            ipcToEngine('e$healthdec ' + inttostr(healthdecrease));

        gf:= 0;

        for i:= Low(bools) to High(bools) do
            if PBoolean(bools[i].param - @tmpScheme + @scheme)^ then
                gf:= gf or bools[i].flag;

        ipcToEngine('e$gmflags ' + inttostr(gf));
    end
end;

end.

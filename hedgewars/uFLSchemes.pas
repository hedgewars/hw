unit uFLSchemes;
interface
uses uFLTypes;

function getSchemesList: PPChar; cdecl;
procedure freeSchemesList;

implementation
uses uFLUtils, uFLIPC, uPhysFSLayer, uFLData;

const MAX_SCHEME_NAMES = 64;
type
    TScheme = record
            schemeName: shortstring;
        end;
    PScheme = ^TScheme;
    TSchemeArray = array [0..0] of TScheme;
    PSchemeArray = ^TSchemeArray;
var
    schemesList: PScheme;
    schemesNumber: LongInt;
    listOfSchemeNames: array[0..MAX_SCHEME_NAMES] of PChar;

procedure loadSchemes;
var f: PFSFile;
    scheme: PScheme;
    schemes: PSchemeArray;
    s: shortstring;
    l, i: Longword;
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

                if (l < schemesNumber) and (l > 0) then
                begin
                    scheme:= @schemes^[l - 1];

                    if copy(s, i + 1, 5) = 'name=' then
                        scheme^. schemeName:= midStr(s, i + 6);
                end;
            end;
        end;

        pfsClose(f)
    end;
{
name=AI TEST
fortsmode=false
divteams=false
solidland=false
border=false
lowgrav=false
laser=false
invulnerability=false
mines=true
damagefactor=100
turntime=40
health=100
suddendeath=0
caseprobability=5
vampiric=false
karma=false
artillery=false
minestime=0
landadds=4
randomorder=true
king=false
placehog=false
sharedammo=false
disablegirders=false
minedudpct=100
explosives=40
disablelandobjects=true
aisurvival=true
resethealth=false
infattack=true
resetweps=true
perhogammo=false
minesnum=0
healthprobability=100
healthcaseamount=50
waterrise=0
healthdecrease=0
disablewind=false
morewind=false
ropepct=100
tagteam=false
getawaytime=100
bottomborder=false
worldedge=1
scriptparam=@Invalid()
}
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


procedure freeSchemesList;
begin
    if schemesList <> nil then
        FreeMem(schemesList, sizeof(schemesList^) * schemesNumber)
end;

end.

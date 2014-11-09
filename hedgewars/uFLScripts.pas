unit uFLScripts;
interface
uses uFLTypes;

function getScriptsList: PPChar; cdecl;
procedure freeScriptsList;

implementation
uses uFLUtils, uFLIPC, uPhysFSLayer, uFLData;

const MAX_SCRIPT_NAMES = 64;
type
    TScript = record
            scriptName: shortstring;
            description: shortstring;
            gameScheme, weapons: shortstring;
        end;
    PScript = ^TScript;
var
    scriptsList: PScript;
    scriptsNumber: Longword;
    listOfScriptNames: array[0..MAX_SCRIPT_NAMES] of PChar;

procedure loadScript(var script: TScript; fileName: shortstring);
var f: PFSFile;
    section: LongInt;
    l: shortstring;
begin
    section:= -1;
    f:= pfsOpenRead(fileName);

    while (not pfsEOF(f)) do
    begin
        pfsReadLn(f, l);
    end;

    pfsClose(f)
end;

procedure loadScripts;
var filesList, tmp: PPChar;
    script: PScript;
    s: shortstring;
    l: Longword;
begin
    filesList:= pfsEnumerateFiles('/Scripts/Multiplayer');
    scriptsNumber:= 0;

    tmp:= filesList;
    while tmp^ <> nil do
    begin
        s:= shortstring(tmp^);
        writeln(stderr, '> ', s);
        l:= length(s);
        if (l > 4) and (copy(s, l - 3, 4) = '.lua') then inc(scriptsNumber);
        inc(tmp)
    end;

    scriptsList:= GetMem(sizeof(scriptsList^) * scriptsNumber);

    script:= scriptsList;
    tmp:= filesList;
    while tmp^ <> nil do
    begin
        s:= shortstring(tmp^);
        l:= length(s);
        if (l > 4) and (copy(s, l - 3, 4) = '.lua') then 
            begin
                loadScript(script^, '/Config/Scripts/' + s);
                inc(script)
            end;
        inc(tmp)
    end;

    pfsFreeList(filesList)
end;


function getScriptsList: PPChar; cdecl;
var i, t, l: Longword;
    script: PScript;
begin
    if scriptsList = nil then
        loadScripts;

    t:= scriptsNumber;
    if t >= MAX_SCRIPT_NAMES then 
        t:= MAX_SCRIPT_NAMES;

    script:= scriptsList;
    for i:= 0 to Pred(t) do
    begin
        l:= length(script^.scriptName);
        if l >= 255 then l:= 254;
        script^.scriptName[l + 1]:= #0;
        listOfScriptNames[i]:= @script^.scriptName[1];
        inc(script)
    end;

    listOfScriptNames[t]:= nil;

    getScriptsList:= listOfScriptNames
end;


procedure freeScriptsList;
begin
    if scriptsList <> nil then
        FreeMem(scriptsList, sizeof(scriptsList^) * scriptsNumber)
end;

end.

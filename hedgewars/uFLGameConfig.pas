unit uFLGameConfig;
interface
uses uFLTypes;

procedure resetGameConfig; cdecl;
procedure runQuickGame; cdecl;
procedure getPreview; cdecl;

procedure registerGUIMessagesCallback(p: pointer; f: TGUICallback); cdecl;

procedure setSeed(seed: PChar); cdecl;
function  getSeed: PChar; cdecl;

procedure tryAddTeam(teamName: PChar);
procedure tryRemoveTeam(teamName: PChar);

implementation
uses uFLIPC, hwengine, uFLUtils, uFLTeams;

var guiCallbackPointer: pointer;
    guiCallbackFunction: TGUICallback;

const
    MAXCONFIGS = 5;
    MAXARGS = 32;

type
    TGameConfig = record
            seed: shortstring;
            theme: shortstring;
            script: shortstring;
            mapgen: Longint;
            gameType: TGameType;
            teams: array[0..7] of TTeam;
            arguments: array[0..Pred(MAXARGS)] of shortstring;
            argv: array[0..Pred(MAXARGS)] of PChar;
            argumentsNumber: Longword;
            end;
    PGameConfig = ^TGameConfig;

var
    currentConfig: TGameConfig;


procedure sendConfig(config: PGameConfig);
var i: Longword;
begin
with config^ do
begin
    case gameType of
    gtPreview: begin
            ipcToEngine('eseed ' + seed);
            ipcToEngine('e$mapgen ' + intToStr(mapgen));
        end;
    gtLocal: begin
            ipcToEngine('eseed ' + seed);
            ipcToEngine('e$mapgen ' + intToStr(mapgen));
            i:= 0;
            while (i < 8) and (teams[i].hogsNumber > 0) do
                begin
                    ipcToEngine('eammloadt 93919294221991210322351110012000000002111001010111110001');
                    ipcToEngine('eammprob 04050405416006555465544647765766666661555101011154111111');
                    ipcToEngine('eammdelay 00000000000002055000000400070040000000002200000006000200');
                    ipcToEngine('eammreinf 13111103121111111231141111111111111112111111011111111111');
                    ipcToEngine('eammstore');
                    sendTeamConfig(teams[i]);
                    inc(i)
                end;
        end;
    end;

    ipcToEngine('!');
end;
end;

procedure queueExecution;
var pConfig: PGameConfig;
    i: Longword;
begin
    new(pConfig);
    pConfig^:= currentConfig;

    with pConfig^ do
        for i:= 0 to Pred(MAXARGS) do
        begin
            if arguments[i][0] = #255 then 
                arguments[i][255]:= #0
            else
                arguments[i][byte(arguments[i][0]) + 1]:= #0;
            argv[i]:= @arguments[i][1]
        end;

    RunEngine(pConfig^.argumentsNumber, @pConfig^.argv);

    sendConfig(pConfig)
end;

procedure resetGameConfig; cdecl;
begin
end;

procedure setSeed(seed: PChar); cdecl;
begin
    currentConfig.seed:= seed
end;

function getSeed: PChar; cdecl;
begin
    getSeed:= str2PChar(currentConfig.seed)
end;

procedure runQuickGame; cdecl;
begin
    with currentConfig do
    begin
        gameType:= gtLocal;
        arguments[0]:= '';
        arguments[1]:= '--internal';
        arguments[2]:= '--nosound';
        argumentsNumber:= 3;

        teams[0]:= createRandomTeam;
        teams[0].color:= '6341088';
        teams[1]:= createRandomTeam;
        teams[1].color:= '2113696';
        teams[1].botLevel:= 1;

        queueExecution;
    end;
end;

procedure getPreview; cdecl;
begin
    with currentConfig do
    begin
        gameType:= gtPreview;
        arguments[0]:= '';
        arguments[1]:= '--internal';
        arguments[2]:= '--landpreview';
        argumentsNumber:= 3;

        queueExecution;
    end;
end;

procedure engineMessageCallback(p: pointer; msg: PChar; len: Longword);
begin
    if len = 128 * 256 then guiCallbackFunction(guiCallbackPointer, mtPreview, msg, len)
end;

procedure registerGUIMessagesCallback(p: pointer; f: TGUICallback); cdecl;
begin
    guiCallbackPointer:= p;
    guiCallbackFunction:= f;

    registerIPCCallback(nil, @engineMessageCallback)
end;


procedure tryAddTeam(teamName: PChar);
var msg: ansistring;
    i, hn, hedgehogsNumber: Longword;
    team: PTeam;
begin
    with currentConfig do
    begin
        hedgehogsNumber:= 0;
        i:= 0;

        while (i < 8) and (teams[i].hogsNumber > 0) do
        begin
            inc(i);
            inc(hedgehogsNumber, teams[i].hogsNumber)
        end;

        // no free space for a team or reached hogs number maximum
        if (i > 7) or (hedgehogsNumber >= 48) then exit;

        team:= teamByName(teamName);
        if team = nil then exit;

        teams[i]:= team^;

        if i = 0 then hn:= 4 else hn:= teams[i - 1].hogsNumber;
        if hn > 48 - hedgehogsNumber then hn:= 48 - hedgehogsNumber;
        teams[i].hogsNumber:= hn;
    end;


    msg:= '0' + #10 + teamName;

    guiCallbackFunction(guiCallbackPointer, mtAddPlayingTeam, @msg[1], length(msg));

    msg:= teamName;

    guiCallbackFunction(guiCallbackPointer, mtRemoveTeam, @msg[1], length(msg))
end;

procedure tryRemoveTeam(teamName: PChar);
var msg: ansistring;
begin
    msg:= teamName;

    guiCallbackFunction(guiCallbackPointer, mtRemovePlayingTeam, @msg[1], length(msg));
    guiCallbackFunction(guiCallbackPointer, mtAddTeam, @msg[1], length(msg))
end;

end.

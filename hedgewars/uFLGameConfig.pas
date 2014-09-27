unit uFLGameConfig;
interface
uses uFLTypes;

procedure resetGameConfig; cdecl;
procedure runQuickGame; cdecl;
procedure getPreview; cdecl;

procedure registerGUIMessagesCallback(p: pointer; f: TGUICallback); cdecl;

procedure setSeed(seed: PChar); cdecl;
function  getSeed: PChar; cdecl;

implementation
uses uFLIPC, hwengine;

var guiCallbackPointer: pointer;
    guiCallbackFunction: TGUICallback;

const
    MAXCONFIGS = 5;
    MAXARGS = 32;

type
    TGameType = (gtPreview, gtLocal);
    THedgehog = record
            name: shortstring;
            hat: shortstring;
            end;
    TTeam = record
            teamName: shortstring;
            flag: shortstring;
            graveName: shortstring;
            fortName: shortstring;
            owner: shortstring;
            extDriven: boolean;
            botLevel: Longword;
            hedgehogs: array[0..7] of THedgehog;
            hogsNumber: Longword;
            end;
    TGameConfig = record
            seed: shortstring;
            theme: shortstring;
            script: shortstring;
            gameType: TGameType;
            teams: array[0..7] of TTeam;
            arguments: array[0..Pred(MAXARGS)] of shortstring;
            argv: array[0..Pred(MAXARGS)] of PChar;
            argumentsNumber: Longword;
            end;
    PGameConfig = ^TGameConfig;

var currentConfig: TGameConfig;
    str2PCharBuffer: array[0..255] of char;

function str2PChar(const s: shortstring): PChar;
var i: Integer;
begin
   for i:= 1 to Length(s) do
      begin
      str2PCharBuffer[i - 1] := s[i];
      end;
   str2PCharBuffer[Length(s)]:= #0;
   str2PChar:= @(str2PCharBuffer[0]);
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

        ipcToEngine('eseed ' + seed);
        ipcToEngine('e$mapgen 0');
        ipcToEngine('!');
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

end.

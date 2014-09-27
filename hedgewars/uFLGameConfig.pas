unit uFLGameConfig;

interface

procedure resetGameConfig; cdecl; export;
procedure runQuickGame; cdecl; export;
procedure getPreview; cdecl; export;

implementation

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
                arguments[i][255] = #0
            else
                arguments[i][byte(arguments[i][0]) + 1] = #0;
            argv[i]:= @arguments[i][1]
        end;

    RunEngine(pConfig^.argumentsNumber, @pConfig^.argv);
end;

procedure resetGameConfig; cdecl;
begin
end;

procedure runQuickGame; cdecl; export;
begin

end;

procedure getPreview; cdecl; export;
begin
    with currentConfig do
    begin
        gameType:= gtPreview;
        arguments[0]:= '';
        arguments[1]:= '--internal';
        arguments[2]:= '--landpreview';
        argumentsNumber:= 3;
    end;

    queueExecution
end;

end.

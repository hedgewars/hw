unit uFLRunQueue;
interface
uses uFLTypes;

procedure queueExecution(var config: TGameConfig);
procedure passFlibEvent(p: pointer); cdecl;

implementation
uses uFLGameConfig, hwengine, uFLThemes, uFLUICallback, uFLIPC;

var runQueue: PGameConfig = nil;

procedure nextRun;
begin
    if runQueue <> nil then
    begin
        if runQueue^.gameType = gtPreview then
            sendUI(mtRenderingPreview, nil, 0);

        ipcRemoveBarrierFromEngineQueue();
        RunEngine(runQueue^.argumentsNumber, @runQueue^.argv);
    end
end;

procedure cleanupConfig;
var t: PGameConfig;
begin
    t:= runQueue;
    runQueue:= t^.nextConfig;
    dispose(t)
end;

procedure queueExecution(var config: TGameConfig);
var pConfig, t, tt: PGameConfig;
    i: Longword;
begin
    new(pConfig);
    pConfig^:= config;

    with pConfig^ do
    begin
        nextConfig:= nil;

        for i:= 0 to Pred(MAXARGS) do
        begin
            if arguments[i][0] = #255 then
                arguments[i][255]:= #0
            else
                arguments[i][byte(arguments[i][0]) + 1]:= #0;
            argv[i]:= @arguments[i][1]
        end;
    end;

    if runQueue = nil then
    begin
        runQueue:= pConfig;

        ipcSetEngineBarrier();
        sendConfig(pConfig);
        nextRun
    end else
    begin
        t:= runQueue;
        while t^.nextConfig <> nil do 
        begin
            if false and (pConfig^.gameType = gtPreview) and (t^.nextConfig^.gameType = gtPreview) and (t <> runQueue) then
            begin
                tt:= t^.nextConfig;
                pConfig^.nextConfig:= tt^.nextConfig;
                t^.nextConfig:= pConfig;
                dispose(tt);
                exit // boo
            end;
            t:= t^.nextConfig;
        end;

        ipcSetEngineBarrier();
        sendConfig(pConfig);
        t^.nextConfig:= pConfig
    end;
end;

procedure passFlibEvent(p: pointer); cdecl;
begin
    case TFLIBEvent(p^) of
        flibGameFinished: begin
            cleanupConfig;
            nextRun
        end;
    end;
end;

end.

unit uFLIPC;
interface
uses SDLh, uFLTypes;

var msgFrontend, msgEngine, msgNet: TIPCMessage;
    mutFrontend, mutEngine, mutNet: PSDL_mutex;
    condFrontend, condEngine, condNet: PSDL_cond;

procedure initIPC;
procedure freeIPC;

procedure ipcToEngine(s: shortstring);
procedure ipcToEngineRaw(p: pointer; len: Longword);
//function  ipcReadFromEngine: shortstring;
//function  ipcCheckFromEngine: boolean;

procedure ipcToNet(s: shortstring);
procedure ipcToNetRaw(p: pointer; len: Longword);

procedure ipcToFrontend(s: shortstring);
procedure ipcToFrontendRaw(p: pointer; len: Longword);
function ipcReadFromFrontend: shortstring;
function ipcCheckFromFrontend: boolean;

procedure registerIPCCallback(p: pointer; f: TIPCCallback);
procedure registerNetCallback(p: pointer; f: TIPCCallback);

implementation

var callbackPointerF: pointer;
    callbackFunctionF: TIPCCallback;
    callbackListenerThreadF: PSDL_Thread;
    callbackPointerN: pointer;
    callbackFunctionN: TIPCCallback;
    callbackListenerThreadN: PSDL_Thread;

procedure ipcSend(var s: TIPCMessage; var msg: TIPCMessage; mut: PSDL_mutex; cond: PSDL_cond);
begin
    SDL_LockMutex(mut);

    while (msg.str[0] > #0) or (msg.buf <> nil) do
        SDL_CondWait(cond, mut);

    msg:= s;
    SDL_CondSignal(cond);
    SDL_UnlockMutex(mut);
end;

function ipcRead(var msg: TIPCMessage; mut: PSDL_mutex; cond: PSDL_cond): TIPCMessage;
var tmp: pointer;
begin
    SDL_LockMutex(mut);
    while (msg.str[0] = #0) and (msg.buf = nil) do
        SDL_CondWait(cond, mut);

    if msg.buf <> nil then
    begin
        tmp:= msg.buf;
        msg.buf:= GetMem(msg.len);
        Move(tmp^, msg.buf^, msg.len);
        FreeMem(tmp, msg.len)
    end;

    ipcRead:= msg;

    msg.str[0]:= #0;
    msg.buf:= nil;

    SDL_CondSignal(cond);
    SDL_UnlockMutex(mut)
end;

function ipcCheck(var msg: TIPCMessage; mut: PSDL_mutex): boolean;
begin
    SDL_LockMutex(mut);
    ipcCheck:= (msg.str[0] > #0) or (msg.buf <> nil);
    SDL_UnlockMutex(mut)
end;

procedure ipcToEngine(s: shortstring);
var msg: TIPCMessage;
begin
    msg.str:= s;
    msg.buf:= nil;
    ipcSend(msg, msgEngine, mutEngine, condEngine)
end;

procedure ipcToFrontend(s: shortstring);
var msg: TIPCMessage;
begin
    msg.str:= s;
    msg.buf:= nil;
    ipcSend(msg, msgFrontend, mutFrontend, condFrontend)
end;

procedure ipcToNet(s: shortstring);
var msg: TIPCMessage;
begin
    msg.str:= s;
    msg.buf:= nil;
    ipcSend(msg, msgNet, mutNet, condNet)
end;

procedure ipcToEngineRaw(p: pointer; len: Longword);
var msg: TIPCMessage;
begin
    msg.str[0]:= #0;
    msg.len:= len;
    msg.buf:= GetMem(len);
    Move(p^, msg.buf^, len);
    ipcSend(msg, msgEngine, mutEngine, condEngine)
end;

procedure ipcToFrontendRaw(p: pointer; len: Longword);
var msg: TIPCMessage;
begin
    msg.str[0]:= #0;
    msg.len:= len;
    msg.buf:= GetMem(len);
    Move(p^, msg.buf^, len);
    ipcSend(msg, msgFrontend, mutFrontend, condFrontend)
end;

procedure ipcToNetRaw(p: pointer; len: Longword);
var msg: TIPCMessage;
begin
    msg.str[0]:= #0;
    msg.len:= len;
    msg.buf:= GetMem(len);
    Move(p^, msg.buf^, len);
    ipcSend(msg, msgNet, mutNet, condNet)
end;

function ipcReadFromEngine: TIPCMessage;
begin
    ipcReadFromEngine:= ipcRead(msgFrontend, mutFrontend, condFrontend)
end;

function ipcReadFromFrontend: shortstring;
begin
    ipcReadFromFrontend:= ipcRead(msgEngine, mutEngine, condEngine).str
end;

function ipcReadToNet: TIPCMessage;
begin
    ipcReadToNet:= ipcRead(msgNet, mutNet, condNet)
end;

function ipcCheckFromEngine: boolean;
begin
    ipcCheckFromEngine:= ipcCheck(msgFrontend, mutFrontend)
end;

function ipcCheckFromFrontend: boolean;
begin
    ipcCheckFromFrontend:= ipcCheck(msgEngine, mutEngine)
end;

function  engineListener(p: pointer): Longint; cdecl; export;
var msg: TIPCMessage;
begin
    engineListener:= 0;
    repeat
        msg:= ipcReadFromEngine();
        if msg.buf = nil then
            callbackFunctionF(callbackPointerF, @msg.str[1], byte(msg.str[0]))
        else
        begin
            callbackFunctionF(callbackPointerF, msg.buf, msg.len);
            FreeMem(msg.buf, msg.len)
        end
    until false
end;

function  netListener(p: pointer): Longint; cdecl; export;
var msg: TIPCMessage;
begin
    netListener:= 0;
    repeat
        msg:= ipcReadToNet();
        if msg.buf = nil then
            callbackFunctionN(callbackPointerN, @msg.str[1], byte(msg.str[0]))
        else
        begin
            callbackFunctionN(callbackPointerN, msg.buf, msg.len);
            FreeMem(msg.buf, msg.len)
        end
    until false
end;

procedure registerIPCCallback(p: pointer; f: TIPCCallback);
begin
    callbackPointerF:= p;
    callbackFunctionF:= f;
    callbackListenerThreadF:= SDL_CreateThread(@engineListener{$IFDEF SDL2}, 'engineListener'{$ENDIF}, nil);
end;

procedure registerNetCallback(p: pointer; f: TIPCCallback);
begin
    callbackPointerN:= p;
    callbackFunctionN:= f;
    callbackListenerThreadN:= SDL_CreateThread(@netListener{$IFDEF SDL2}, 'netListener'{$ENDIF}, nil);
end;

procedure initIPC;
begin
    msgFrontend.str:= '';
    msgFrontend.buf:= nil;
    msgEngine.str:= '';
    msgEngine.buf:= nil;
    msgNet.str:= '';
    msgNet.buf:= nil;

    callbackPointerF:= nil;
    callbackListenerThreadF:= nil;

    mutFrontend:= SDL_CreateMutex;
    mutEngine:= SDL_CreateMutex;
    mutNet:= SDL_CreateMutex;
    condFrontend:= SDL_CreateCond;
    condEngine:= SDL_CreateCond;
    condNet:= SDL_CreateCond;
end;

procedure freeIPC;
begin
    SDL_KillThread(callbackListenerThreadF);
    SDL_KillThread(callbackListenerThreadN);
    SDL_DestroyMutex(mutFrontend);
    SDL_DestroyMutex(mutEngine);
    SDL_DestroyMutex(mutNet);
    SDL_DestroyCond(condFrontend);
    SDL_DestroyCond(condEngine);
    SDL_DestroyCond(condNet);
end;

end.

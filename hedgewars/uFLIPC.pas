unit uFLIPC;
interface
uses SDLh, uFLTypes;

var msgFrontend, msgEngine: TIPCMessage;
    mutFrontend, mutEngine: PSDL_mutex;
    condFrontend, condEngine: PSDL_cond;

procedure initIPC;
procedure freeIPC;

procedure ipcToEngine(s: shortstring);
procedure ipcToEngineRaw(p: pointer; len: Longword);
//function  ipcReadFromEngine: shortstring;
//function  ipcCheckFromEngine: boolean;

procedure ipcToFrontend(s: shortstring);
procedure ipcToFrontendRaw(p: pointer; len: Longword);
function ipcReadFromFrontend: shortstring;
function ipcCheckFromFrontend: boolean;

procedure registerIPCCallback(p: pointer; f: TIPCCallback);

implementation

var callbackPointer: pointer;
    callbackFunction: TIPCCallback;
    callbackListenerThread: PSDL_Thread;

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

function ipcReadFromEngine: TIPCMessage;
begin
    ipcReadFromEngine:= ipcRead(msgFrontend, mutFrontend, condFrontend)
end;

function ipcReadFromFrontend: shortstring;
begin
    ipcReadFromFrontend:= ipcRead(msgEngine, mutEngine, condEngine).str
end;

function ipcCheckFromEngine: boolean;
begin
    ipcCheckFromEngine:= ipcCheck(msgFrontend, mutFrontend)
end;

function ipcCheckFromFrontend: boolean;
begin
    ipcCheckFromFrontend:= ipcCheck(msgEngine, mutEngine)
end;

function  listener(p: pointer): Longint; cdecl; export;
var msg: TIPCMessage;
begin
    listener:= 0;
    repeat
        msg:= ipcReadFromEngine();
        if msg.buf = nil then
            callbackFunction(callbackPointer, @msg.str[1], byte(msg.str[0]))
        else
        begin
            callbackFunction(callbackPointer, msg.buf, msg.len);
            FreeMem(msg.buf, msg.len)
        end
    until false
end;

procedure registerIPCCallback(p: pointer; f: TIPCCallback);
begin
    callbackPointer:= p;
    callbackFunction:= f;
    callbackListenerThread:= SDL_CreateThread(@listener{$IFDEF SDL2}, 'ipcListener'{$ENDIF}, nil);
end;

procedure initIPC;
begin
    msgFrontend.str:= '';
    msgFrontend.buf:= nil;
    msgEngine.str:= '';
    msgEngine.buf:= nil;

    callbackPointer:= nil;
    callbackListenerThread:= nil;

    mutFrontend:= SDL_CreateMutex;
    mutEngine:= SDL_CreateMutex;
    condFrontend:= SDL_CreateCond;
    condEngine:= SDL_CreateCond;
end;

procedure freeIPC;
begin
    SDL_KillThread(callbackListenerThread);
    SDL_DestroyMutex(mutFrontend);
    SDL_DestroyMutex(mutEngine);
    SDL_DestroyCond(condFrontend);
    SDL_DestroyCond(condEngine);
end;

end.

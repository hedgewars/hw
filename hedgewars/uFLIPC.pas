unit uFLIPC;
interface
uses SDLh;

type TIPCMessage = record
                   str: shortstring;
                   len: Longword;
                   buf: Pointer
               end;

var msgFrontend, msgEngine: TIPCMessage;
    mutFrontend, mutEngine: PSDL_mutex;
    condFrontend, condEngine: PSDL_cond;

procedure initIPC;
procedure freeIPC;

procedure ipcToEngine(s: shortstring);
function  ipcReadFromEngine: shortstring;
function  ipcCheckFromEngine: boolean;

procedure ipcToFrontend(s: shortstring);
function ipcReadFromFrontend: shortstring;
function ipcCheckFromFrontend: boolean;

implementation

procedure ipcSend(var s: shortstring; var msg: TIPCMessage; mut: PSDL_mutex; cond: PSDL_cond);
begin
    SDL_LockMutex(mut);
    while (msg.str[0] > #0) or (msg.buf <> nil) do
        SDL_CondWait(cond, mut);

    msg.str:= s;
    SDL_CondSignal(cond);
    SDL_UnlockMutex(mut)
end;

function ipcRead(var msg: TIPCMessage; mut: PSDL_mutex; cond: PSDL_cond): shortstring;
begin
    SDL_LockMutex(mut);
    while (msg.str[0] = #0) and (msg.buf = nil) do
        SDL_CondWait(cond, mut);

    ipcRead:= msg.str;
    msg.str[0]:= #0;
    if msg.buf <> nil then
    begin
        FreeMem(msg.buf, msg.len);
        msg.buf:= nil
    end;

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
begin
    ipcSend(s, msgEngine, mutEngine, condEngine)
end;

procedure ipcToFrontend(s: shortstring);
begin
    ipcSend(s, msgFrontend, mutFrontend, condFrontend)
end;

function ipcReadFromEngine: shortstring;
begin
    ipcReadFromEngine:= ipcRead(msgFrontend, mutFrontend, condFrontend)
end;

function ipcReadFromFrontend: shortstring;
begin
    ipcReadFromFrontend:= ipcRead(msgEngine, mutEngine, condEngine)
end;

function ipcCheckFromEngine: boolean;
begin
    ipcCheckFromEngine:= ipcCheck(msgFrontend, mutFrontend)
end;

function ipcCheckFromFrontend: boolean;
begin
    ipcCheckFromFrontend:= ipcCheck(msgEngine, mutEngine)
end;

procedure initIPC;
begin
    msgFrontend.str:= '';
    msgFrontend.buf:= nil;
    msgEngine.str:= '';
    msgEngine.buf:= nil;

    mutFrontend:= SDL_CreateMutex;
    mutEngine:= SDL_CreateMutex;
    condFrontend:= SDL_CreateCond;
    condEngine:= SDL_CreateCond;
end;

procedure freeIPC;
begin
    SDL_DestroyMutex(mutFrontend);
    SDL_DestroyMutex(mutEngine);
    SDL_DestroyCond(condFrontend);
    SDL_DestroyCond(condEngine);
end;

end.

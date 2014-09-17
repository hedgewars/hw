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

implementation

procedure ipcToEngine(s: shortstring);
begin
    SDL_LockMutex(mutEngine);
    while (msgEngine.str[0] > #0) or (msgEngine.buf <> nil) do
        SDL_CondWait(condEngine, mutEngine);

    msgEngine.str:= s;
    SDL_CondSignal(condEngine);
    SDL_UnlockMutex(mutEngine)
end;

function ipcReadFromEngine: shortstring;
begin
    SDL_LockMutex(mutFrontend);
    while (msgFrontend.str[0] = #0) and (msgFrontend.buf = nil) do
        SDL_CondWait(condFrontend, mutFrontend);

    ipcReadFromEngine:= msgFrontend.str;
    msgFrontend.str[0]:= #0;
    if msgFrontend.buf <> nil then
    begin
        FreeMem(msgFrontend.buf, msgFrontend.len);
        msgFrontend.buf:= nil
    end;

    SDL_CondSignal(condFrontend);
    SDL_UnlockMutex(mutFrontend)
end;

function ipcCheckFromEngine: boolean;
begin
    SDL_LockMutex(mutFrontend);
    ipcCheckFromEngine:= (msgFrontend.str[0] > #0) or (msgFrontend.buf <> nil);
    SDL_UnlockMutex(mutFrontend)
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

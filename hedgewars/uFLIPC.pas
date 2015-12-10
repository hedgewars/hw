unit uFLIPC;
interface
uses SDLh, uFLTypes;

procedure initIPC;
procedure freeIPC;

procedure ipcToEngine(s: shortstring);
procedure ipcToEngineRaw(p: pointer; len: Longword);
procedure ipcCleanEngineQueue();
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
    queueFrontend, queueEngine, queueNet: PIPCQueue;

procedure ipcSend(var s: TIPCMessage; queue: PIPCQueue);
var pmsg: PIPCMessage;
begin
    SDL_LockMutex(queue^.mut);

    s.next:= nil;

    if (queue^.msg.next = nil) and (queue^.msg.str[0] = #0) and (queue^.msg.buf = nil) then
    begin
        queue^.msg:= s;
    end else
    begin
        new(pmsg);
        pmsg^:= s;
        queue^.last^.next:= pmsg;
        queue^.last:= pmsg;
    end;
    SDL_CondSignal(queue^.cond);
    SDL_UnlockMutex(queue^.mut);
end;

function ipcRead(queue: PIPCQueue): TIPCMessage;
var pmsg: PIPCMessage;
begin
    SDL_LockMutex(queue^.mut);
    while (queue^.msg.str[0] = #0) and (queue^.msg.buf = nil) and (queue^.msg.next = nil) do
        SDL_CondWait(queue^.cond, queue^.mut);

    if (queue^.msg.str[0] <> #0) or (queue^.msg.buf <> nil) then
        begin
            ipcRead:= queue^.msg;
            queue^.msg.str[0]:= #0;
            queue^.msg.buf:= nil;
        end else
        begin
            pmsg:= queue^.msg.next;
            ipcRead:= pmsg^;
            queue^.msg.next:= pmsg^.next;
            if queue^.msg.next = nil then queue^.last:= @queue^.msg;
            dispose(pmsg)
        end;

    SDL_UnlockMutex(queue^.mut)
end;

function ipcCheck(queue: PIPCQueue): boolean;
begin
    SDL_LockMutex(queue^.mut);
    ipcCheck:= (queue^.msg.str[0] > #0) or (queue^.msg.buf <> nil) or (queue^.msg.next <> nil);
    SDL_UnlockMutex(queue^.mut)
end;

procedure ipcToEngine(s: shortstring);
var msg: TIPCMessage;
begin
    msg.str:= s;
    msg.buf:= nil;
    ipcSend(msg, queueEngine)
end;

procedure ipcToFrontend(s: shortstring);
var msg: TIPCMessage;
begin
    msg.str:= s;
    msg.buf:= nil;
    ipcSend(msg, queueFrontend)
end;

procedure ipcCleanEngineQueue();
var pmsg, t: PIPCMessage;
    q: PIPCQueue;
begin
    q:= queueEngine;

    SDL_LockMutex(q^.mut);

    pmsg:= @q^.msg;
    q^.last:= pmsg;

    while pmsg <> nil do
    begin
        t:= pmsg^.next;

        if pmsg^.buf <> nil then
            FreeMem(pmsg^.buf, pmsg^.len);

        if pmsg <> @q^.msg then
            dispose(pmsg);
        pmsg:= t
    end;

    q^.msg.next:= nil;
    q^.msg.str[0]:= #0;
    q^.msg.buf:= nil;

    SDL_UnlockMutex(q^.mut);
end;

procedure ipcToNet(s: shortstring);
var msg: TIPCMessage;
begin
    msg.str:= s;
    msg.buf:= nil;
    ipcSend(msg, queueNet)
end;

procedure ipcToEngineRaw(p: pointer; len: Longword);
var msg: TIPCMessage;
begin
    msg.str[0]:= #0;
    msg.len:= len;
    msg.buf:= GetMem(len);
    Move(p^, msg.buf^, len);
    ipcSend(msg, queueEngine)
end;

procedure ipcToFrontendRaw(p: pointer; len: Longword);
var msg: TIPCMessage;
begin
    msg.str[0]:= #0;
    msg.len:= len;
    msg.buf:= GetMem(len);
    Move(p^, msg.buf^, len);
    ipcSend(msg, queueFrontend)
end;

procedure ipcToNetRaw(p: pointer; len: Longword);
var msg: TIPCMessage;
begin
    msg.str[0]:= #0;
    msg.len:= len;
    msg.buf:= GetMem(len);
    Move(p^, msg.buf^, len);
    ipcSend(msg, queueNet)
end;

function ipcReadFromEngine: TIPCMessage;
begin
    ipcReadFromEngine:= ipcRead(queueFrontend)
end;

function ipcReadFromFrontend: shortstring;
begin
    ipcReadFromFrontend:= ipcRead(queueEngine).str
end;

function ipcReadToNet: TIPCMessage;
begin
    ipcReadToNet:= ipcRead(queueNet)
end;

function ipcCheckFromEngine: boolean;
begin
    ipcCheckFromEngine:= ipcCheck(queueFrontend)
end;

function ipcCheckFromFrontend: boolean;
begin
    ipcCheckFromFrontend:= ipcCheck(queueEngine)
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
    callbackListenerThreadF:= SDL_CreateThread(@engineListener, 'engineListener', nil);
end;

procedure registerNetCallback(p: pointer; f: TIPCCallback);
begin
    callbackPointerN:= p;
    callbackFunctionN:= f;
    callbackListenerThreadN:= SDL_CreateThread(@netListener, 'netListener', nil);
end;

function createQueue: PIPCQueue;
var q: PIPCQueue;
begin
    new(q);
    q^.msg.str:= '';
    q^.msg.buf:= nil;
    q^.mut:= SDL_CreateMutex;
    q^.cond:= SDL_CreateCond;
    q^.msg.next:= nil;
    q^.last:= @q^.msg;
    createQueue:= q
end;

procedure destroyQueue(queue: PIPCQueue);
begin
    SDL_DestroyCond(queue^.cond);
    SDL_DestroyMutex(queue^.mut);
    dispose(queue);
end;

procedure initIPC;
begin
    queueFrontend:= createQueue;
    queueEngine:= createQueue;
    queueNet:= createQueue;

    callbackPointerF:= nil;
    callbackListenerThreadF:= nil;
end;

procedure freeIPC;
begin
    //FIXME SDL_KillThread(callbackListenerThreadF);
    //FIXME SDL_KillThread(callbackListenerThreadN);
    destroyQueue(queueFrontend);
    destroyQueue(queueEngine);
    destroyQueue(queueNet);
end;

end.

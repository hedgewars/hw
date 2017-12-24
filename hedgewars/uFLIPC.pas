unit uFLIPC;
interface
uses SDLh, uFLTypes;

procedure initIPC;
procedure freeIPC;

procedure ipcToEngine(s: shortstring);
procedure ipcToEngineRaw(p: pointer; len: Longword); cdecl;
procedure ipcSetEngineBarrier(); cdecl;
procedure ipcRemoveBarrierFromEngineQueue(); cdecl;
//function  ipcReadFromEngine: shortstring;
//function  ipcCheckFromEngine: boolean;

procedure ipcToFrontend(s: shortstring);
procedure ipcToFrontendRaw(p: pointer; len: Longword);
function ipcReadFromFrontend: TIPCMessage;
function ipcCheckFromFrontend: boolean;

procedure registerIPCCallback(p: pointer; f: TIPCCallback);

implementation

var callbackPointerF: pointer;
    callbackFunctionF: TIPCCallback;
    callbackListenerThreadF: PSDL_Thread;
    queueFrontend, queueEngine: PIPCQueue;

procedure ipcSend(var s: TIPCMessage; queue: PIPCQueue);
var pmsg: PIPCMessage;
begin
    SDL_LockMutex(queue^.mut);

    s.next:= nil;
    s.barrier:= 0;

    if (queue^.msg.next = nil) and (queue^.msg.str[0] = #0) and (queue^.msg.buf = nil) and (queue^.msg.barrier = 0) then
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
    while ((queue^.msg.str[0] = #0) and (queue^.msg.buf = nil))
            and ((queue^.msg.barrier > 0) or (queue^.msg.next = nil) or ((queue^.msg.next^.barrier > 0) and (queue^.msg.next^.str[0] = #0) and (queue^.msg.next^.buf = nil))) do
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
            if pmsg^.barrier > 0 then
            begin
                pmsg^.str[0]:= #0;
                pmsg^.buf:= nil
            end else
            begin
                queue^.msg.next:= pmsg^.next;
                if queue^.msg.next = nil then queue^.last:= @queue^.msg;
                dispose(pmsg)
            end
        end;

    SDL_UnlockMutex(queue^.mut)
end;

function ipcCheck(queue: PIPCQueue): boolean;
begin
    SDL_LockMutex(queue^.mut);
    ipcCheck:= (queue^.msg.str[0] > #0) or (queue^.msg.buf <> nil) or
               ((queue^.msg.barrier = 0) and (queue^.msg.next <> nil) and ((queue^.msg.next^.barrier = 0) or (queue^.msg.next^.str[0] <> #0) or (queue^.msg.next^.buf <> nil)));
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

procedure ipcSetEngineBarrier(); cdecl;
begin
    SDL_LockMutex(queueEngine^.mut);

    inc(queueEngine^.last^.barrier);

    SDL_UnlockMutex(queueEngine^.mut);
end;

procedure ipcRemoveBarrierFromEngineQueue(); cdecl;
var pmsg, t: PIPCMessage;
    q: PIPCQueue;
begin
    q:= queueEngine;

    SDL_LockMutex(q^.mut);

    pmsg:= @q^.msg;
    while pmsg <> nil do
    begin
        t:= pmsg^.next;
        q^.msg.next:= t;

        pmsg^.str[0]:= #0;
        if pmsg^.buf <> nil then
        begin
            FreeMem(pmsg^.buf, pmsg^.len);
            pmsg^.buf:= nil
        end;

        if pmsg <> @q^.msg then
            if pmsg^.barrier = 0 then
                dispose(pmsg)
            else
            if pmsg^.barrier = 1 then
            begin
                dispose(pmsg);
                t:= nil
            end else
            begin
                dec(pmsg^.barrier);
                q^.msg.next:= pmsg;
                t:= nil
            end
        else
            if pmsg^.barrier > 0 then 
            begin
                dec(pmsg^.barrier);
                t:= nil
            end;

        pmsg:= t
    end;

    if q^.msg.next = nil then q^.last:= @q^.msg;

    q^.msg.str[0]:= #0;
    q^.msg.buf:= nil;

    SDL_UnlockMutex(q^.mut);
end;

procedure ipcToEngineRaw(p: pointer; len: Longword); cdecl;
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

function ipcReadFromEngine: TIPCMessage;
begin
    ipcReadFromEngine:= ipcRead(queueFrontend)
end;

function ipcReadFromFrontend: TIPCMessage;
begin
    ipcReadFromFrontend:= ipcRead(queueEngine)
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

procedure registerIPCCallback(p: pointer; f: TIPCCallback);
begin
    callbackPointerF:= p;
    callbackFunctionF:= f;
    callbackListenerThreadF:= SDL_CreateThread(@engineListener, 'engineListener', nil);
end;

function createQueue: PIPCQueue;
var q: PIPCQueue;
begin
    new(q);
    q^.msg.str:= '';
    q^.msg.buf:= nil;
    q^.msg.barrier:= 0;
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

    callbackPointerF:= nil;
    callbackListenerThreadF:= nil;
end;

procedure freeIPC;
begin
    //FIXME SDL_KillThread(callbackListenerThreadF);
    destroyQueue(queueFrontend);
    destroyQueue(queueEngine);
end;

end.

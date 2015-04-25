unit uFLNet;
interface

procedure connectOfficialServer;

procedure initModule;
procedure freeModule;

implementation
uses SDLh;

var sock: PTCPSocket;
    fds: PSDLNet_SocketSet;
    netReaderThread: PSDL_Thread;
    sockbuf: shortstring;
    sockbufpos: byte;

function getNextChar: char;
var r: byte;
begin
    if sockbufpos < byte(sockbuf[0]) then
    begin
        inc(sockbufpos);
        getNextChar:= sockbuf[sockbufpos];
    end else
    begin
        r:= SDLNet_TCP_Recv(sock, @sockbuf[1], 255);
        if r > 0 then
        begin
            sockbufpos:= 1;
            sockbuf[0]:= char(i);
            getNextChar:= sockbuf[1];
        end else
        begin
            sockbufpos:= 0;
            sockbuf[0]:= #0;
            getNextChar:= #0
        end;
end;

function netReader(data: pointer): LongInt; cdecl; export;
begin
end;

procedure connectOfficialServer;
var ipaddr: TIPAddress;
begin
    if sock <> nil then
        exit;

    if SDLNet_ResolveHost(ipaddr, PChar('netserver.hedgewars.org'), 46631) = 0 then
        sock:= SDLNet_TCP_Open(ipaddr);

    sockbufpos:= 0;
    sockbuf:= '';
    netReaderThread:= SDL_CreateThread(@netReader{$IFDEF SDL2}, 'netReader'{$ENDIF}, nil);
end;

procedure initModule;
begin
    sock:= nil;

    SDLNet_Init;
    fds:= SDLNet_AllocSocketSet(1);
end;

procedure freeModule;
begin
end;

end.

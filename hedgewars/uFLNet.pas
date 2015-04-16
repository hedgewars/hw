unit uFLNet;
interface

procedure connectOfficialServer;

procedure initModule;
procedure freeModule;

implementation
uses SDLh;

var sock: PTCPSocket;
    fds: PSDLNet_SocketSet;

procedure connectOfficialServer;
var ipaddr: TIPAddress;
begin
    if sock <> nil then 
        exit;

    if SDLNet_ResolveHost(ipaddr, PChar('netserver.hedgewars.org'), 46631) = 0 then
        sock:= SDLNet_TCP_Open(ipaddr)
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

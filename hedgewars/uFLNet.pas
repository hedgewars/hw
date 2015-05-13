unit uFLNet;
interface

procedure connectOfficialServer;

procedure initModule;
procedure freeModule;

implementation
uses SDLh;
type TCmdType = (cmd_ASKPASSWORD, cmd_BANLIST, cmd_BYE, cmd_CHAT, cmd_CLIENT_FLAGS, cmd_CONNECTED, cmd_EM, cmd_HH_NUM, cmd_INFO, cmd_JOINED, cmd_JOINING, cmd_KICKED, cmd_LEFT, cmd_LOBBY_JOINED, cmd_LOBBY_LEFT, cmd_NICK, cmd_NOTICE, cmd_PING, cmd_PROTO, cmd_ROOMS, cmd_ROUND_FINISHED, cmd_RUN_GAME, cmd_SERVER_AUTH, cmd_SERVER_MESSAGE, cmd_SERVER_VARS, cmd_TEAM_ACCEPTED, cmd_TEAM_COLOR, cmd_WARNING, cmd___UNKNOWN__);

type
    TNetState = (netDisconnected, netLoggedIn);
    TParserState = record
                       cmd: TCmdType;
                       l: LongInt;
                       netState: TNetState;
                   end;
    PHandler = procedure;

var state: TParserState;

// generated stuff here
const letters: array[0..235] of char = ('A', 'S', 'K', 'P', 'A', 'S', 'S', 'W', 'O', 'R', 'D', #10, #0, 'B', 'A', 'N', 'L', 'I', 'S', 'T', #10, #0, 'Y', 'E', #10, #0, 'C', 'H', 'A', 'T', #10, #0, 'L', 'I', 'E', 'N', 'T', '_', 'F', 'L', 'A', 'G', 'S', #10, #0, 'O', 'N', 'N', 'E', 'C', 'T', 'E', 'D', #10, #0, 'E', 'M', #10, #0, 'H', 'H', '_', 'N', 'U', 'M', #10, #0, 'I', 'N', 'F', 'O', #10, #0, 'J', 'O', 'I', 'N', 'E', 'D', #10, #0, 'I', 'N', 'G', #10, #0, 'K', 'I', 'C', 'K', 'E', 'D', #10, #0, 'L', 'E', 'F', 'T', #10, #0, 'O', 'B', 'B', 'Y', ':', 'J', 'O', 'I', 'N', 'E', 'D', #10, #0, 'L', 'E', 'F', 'T', #10, #0, 'N', 'I', 'C', 'K', #10, #0, 'O', 'T', 'I', 'C', 'E', #10, #0, 'P', 'I', 'N', 'G', #10, #0, 'R', 'O', 'T', 'O', #10, #0, 'R', 'O', 'O', 'M', 'S', #10, #0, 'U', 'N', 'D', '_', 'F', 'I', 'N', 'I', 'S', 'H', 'E', 'D', #10, #0, 'U', 'N', '_', 'G', 'A', 'M', 'E', #10, #0, 'S', 'E', 'R', 'V', 'E', 'R', '_', 'A', 'U', 'T', 'H', #10, #0, 'M', 'E', 'S', 'S', 'A', 'G', 'E', #10, #0, 'V', 'A', 'R', 'S', #10, #0, 'T', 'E', 'A', 'M', '_', 'A', 'C', 'C', 'E', 'P', 'T', 'E', 'D', #10, #0, 'C', 'O', 'L', 'O', 'R', #10, #0, 'W', 'A', 'R', 'N', 'I', 'N', 'G', #10, #0, '$', #10, #0);

const commands: array[0..235] of integer = (13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -38, 13, 8, 0, 0, 0, 0, 0, 0, -37, 0, 0, 0, -36, 29, 5, 0, 0, 0, -35, 13, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -34, 0, 0, 0, 0, 0, 0, 0, 0, 0, -33, 4, 0, 0, -32, 8, 0, 0, 0, 0, 0, 0, -31, 6, 0, 0, 0, 0, -30, 13, 0, 0, 0, 4, 0, 0, -29, 0, 0, 0, 0, -28, 8, 0, 0, 0, 0, 0, 0, -27, 25, 5, 0, 0, 0, -26, 0, 0, 0, 0, 0, 8, 0, 0, 0, 0, 0, 0, -25, 0, 0, 0, 0, 0, -24, 13, 5, 0, 0, 0, -23, 0, 0, 0, 0, 0, 0, -22, 12, 5, 0, 0, 0, -21, 0, 0, 0, 0, 0, -20, 30, 20, 5, 0, 0, 0, -19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -18, 0, 0, 0, 0, 0, 0, 0, 0, -17, 28, 0, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, -16, 9, 0, 0, 0, 0, 0, 0, 0, -15, 0, 0, 0, 0, 0, -14, 22, 0, 0, 0, 0, 10, 0, 0, 0, 0, 0, 0, 0, 0, -13, 0, 0, 0, 0, 0, 0, -12, 9, 0, 0, 0, 0, 0, 0, 0, -11, 0, 0, -10);

procedure handler_ASKPASSWORD;
begin
    state.cmd:= cmd_ASKPASSWORD;
end;

procedure handler_BANLIST;
begin
    state.cmd:= cmd_BANLIST;
end;

procedure handler_BYE;
begin
    state.cmd:= cmd_BYE;
end;

procedure handler_CHAT;
begin
    state.cmd:= cmd_CHAT;
end;

procedure handler_CLIENT_FLAGS;
begin
    state.cmd:= cmd_CLIENT_FLAGS;
end;

procedure handler_CONNECTED;
begin
    state.cmd:= cmd_CONNECTED;
end;

procedure handler_EM;
begin
    state.cmd:= cmd_EM;
end;

procedure handler_HH_NUM;
begin
    state.cmd:= cmd_HH_NUM;
end;

procedure handler_INFO;
begin
    state.cmd:= cmd_INFO;
end;

procedure handler_JOINED;
begin
    state.cmd:= cmd_JOINED;
end;

procedure handler_JOINING;
begin
    state.cmd:= cmd_JOINING;
end;

procedure handler_KICKED;
begin
    state.cmd:= cmd_KICKED;
end;

procedure handler_LEFT;
begin
    state.cmd:= cmd_LEFT;
end;

procedure handler_LOBBY_JOINED;
begin
    state.cmd:= cmd_LOBBY_JOINED;
end;

procedure handler_LOBBY_LEFT;
begin
    state.cmd:= cmd_LOBBY_LEFT;
end;

procedure handler_NICK;
begin
    state.cmd:= cmd_NICK;
end;

procedure handler_NOTICE;
begin
    state.cmd:= cmd_NOTICE;
end;

procedure handler_PING;
begin
    state.cmd:= cmd_PING;
end;

procedure handler_PROTO;
begin
    state.cmd:= cmd_PROTO;
end;

procedure handler_ROOMS;
begin
    state.cmd:= cmd_ROOMS;
end;

procedure handler_ROUND_FINISHED;
begin
    state.cmd:= cmd_ROUND_FINISHED;
end;

procedure handler_RUN_GAME;
begin
    state.cmd:= cmd_RUN_GAME;
end;

procedure handler_SERVER_AUTH;
begin
    state.cmd:= cmd_SERVER_AUTH;
end;

procedure handler_SERVER_MESSAGE;
begin
    state.cmd:= cmd_SERVER_MESSAGE;
end;

procedure handler_SERVER_VARS;
begin
    state.cmd:= cmd_SERVER_VARS;
end;

procedure handler_TEAM_ACCEPTED;
begin
    state.cmd:= cmd_TEAM_ACCEPTED;
end;

procedure handler_TEAM_COLOR;
begin
    state.cmd:= cmd_TEAM_COLOR;
end;

procedure handler_WARNING;
begin
    state.cmd:= cmd_WARNING;
end;

procedure handler___UNKNOWN__;
begin
    state.cmd:= cmd___UNKNOWN__;
end;

const handlers: array[0..28] of PHandler = (@handler___UNKNOWN__, @handler_WARNING, @handler_TEAM_COLOR, @handler_TEAM_ACCEPTED, @handler_SERVER_VARS, @handler_SERVER_MESSAGE, @handler_SERVER_AUTH, @handler_RUN_GAME, @handler_ROUND_FINISHED, @handler_ROOMS, @handler_PROTO, @handler_PING, @handler_NOTICE, @handler_NICK, @handler_LOBBY_LEFT, @handler_LOBBY_JOINED, @handler_LEFT, @handler_KICKED, @handler_JOINING, @handler_JOINED, @handler_INFO, @handler_HH_NUM, @handler_EM, @handler_CONNECTED, @handler_CLIENT_FLAGS, @handler_CHAT, @handler_BYE, @handler_BANLIST, @handler_ASKPASSWORD);


// end of generated stuff
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
            sockbuf[0]:= char(r);
            getNextChar:= sockbuf[1];
        end else
        begin
            sockbufpos:= 0;
            sockbuf[0]:= #0;
            getNextChar:= #0
        end
    end
end;

function netReader(data: pointer): LongInt; cdecl; export;
var c: char;
begin
repeat
    c:= getNextChar;
    if c = #0 then
        state.netState:= netDisconnected;
    if c = letters[state.l] then
        if commands[state.l] < 0 then
            handlers[-10 - commands[state.l]]()
        else
            inc(state.l)
    else
        if commands[state.l] = 0 then
            // unknown cmd
        else
            repeat
                inc(state.l, commands[state.l])
            until (letters[state.l] = c) or (commands[state.l] = 0)
until state.netState = netDisconnected
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

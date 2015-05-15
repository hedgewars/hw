unit uFLNet;
interface

procedure connectOfficialServer;

procedure initModule;
procedure freeModule;

implementation
uses SDLh;

const endCmd: array[0..1] of char = (#10, #10);

function getNextChar: char; forward;
function getCurrChar: char; forward;
procedure sendNet(s: shortstring); forward;

type TCmdType = (cmd_ASKPASSWORD, cmd_BANLIST, cmd_BYE, cmd_CHAT, cmd_CLIENT_FLAGS, cmd_CONNECTED, cmd_EM, cmd_HH_NUM, cmd_INFO, cmd_JOINED, cmd_JOINING, cmd_KICKED, cmd_LEFT, cmd_LOBBY_JOINED, cmd_LOBBY_LEFT, cmd_NICK, cmd_NOTICE, cmd_PING, cmd_PROTO, cmd_ROOMS, cmd_ROUND_FINISHED, cmd_RUN_GAME, cmd_SERVER_AUTH, cmd_SERVER_MESSAGE, cmd_SERVER_VARS, cmd_TEAM_ACCEPTED, cmd_TEAM_COLOR, cmd_WARNING, cmd___UNKNOWN__);

type
    TNetState = (netDisconnected, netConnecting, netLoggedIn);
    TParserState = record
                       cmd: TCmdType;
                       l: LongInt;
                       netState: TNetState;
                       buf: shortstring;
                       bufpos: byte;
                   end;
    PHandler = procedure;

var state: TParserState;

// generated stuff here
const letters: array[0..206] of char = ('A', 'S', 'K', 'P', 'A', 'S', 'S', 'W', 'O', 'R', 'D', #10, 'B', 'A', 'N', 'L', 'I', 'S', 'T', #10, 'Y', 'E', #10, 'C', 'H', 'A', 'T', #10, 'L', 'I', 'E', 'N', 'T', '_', 'F', 'L', 'A', 'G', 'S', #10, 'O', 'N', 'N', 'E', 'C', 'T', 'E', 'D', #10, 'E', 'M', #10, 'H', 'H', '_', 'N', 'U', 'M', #10, 'I', 'N', 'F', 'O', #10, 'J', 'O', 'I', 'N', 'E', 'D', #10, 'I', 'N', 'G', #10, 'K', 'I', 'C', 'K', 'E', 'D', #10, 'L', 'E', 'F', 'T', #10, 'O', 'B', 'B', 'Y', ':', 'J', 'O', 'I', 'N', 'E', 'D', #10, 'L', 'E', 'F', 'T', #10, 'N', 'I', 'C', 'K', #10, 'O', 'T', 'I', 'C', 'E', #10, 'P', 'I', 'N', 'G', #10, 'R', 'O', 'T', 'O', #10, 'R', 'O', 'O', 'M', 'S', #10, 'U', 'N', 'D', '_', 'F', 'I', 'N', 'I', 'S', 'H', 'E', 'D', #10, 'U', 'N', '_', 'G', 'A', 'M', 'E', #10, 'S', 'E', 'R', 'V', 'E', 'R', '_', 'A', 'U', 'T', 'H', #10, 'M', 'E', 'S', 'S', 'A', 'G', 'E', #10, 'V', 'A', 'R', 'S', #10, 'T', 'E', 'A', 'M', '_', 'A', 'C', 'C', 'E', 'P', 'T', 'E', 'D', #10, 'C', 'O', 'L', 'O', 'R', #10, 'W', 'A', 'R', 'N', 'I', 'N', 'G', #10, #0, #10);

const commands: array[0..206] of integer = (12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -38, 11, 7, 0, 0, 0, 0, 0, -37, 0, 0, -36, 26, 4, 0, 0, -35, 12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -34, 0, 0, 0, 0, 0, 0, 0, 0, -33, 3, 0, -32, 7, 0, 0, 0, 0, 0, -31, 5, 0, 0, 0, -30, 11, 0, 0, 0, 3, 0, -29, 0, 0, 0, -28, 7, 0, 0, 0, 0, 0, -27, 22, 4, 0, 0, -26, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, -25, 0, 0, 0, 0, -24, 11, 4, 0, 0, -23, 0, 0, 0, 0, 0, -22, 10, 4, 0, 0, -21, 0, 0, 0, 0, -20, 27, 18, 4, 0, 0, -19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -18, 0, 0, 0, 0, 0, 0, 0, -17, 25, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, -16, 8, 0, 0, 0, 0, 0, 0, -15, 0, 0, 0, 0, -14, 20, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, -13, 0, 0, 0, 0, 0, -12, 8, 0, 0, 0, 0, 0, 0, -11, 0, -10);

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

    sendNet('PONG');
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

    writeln('[NET] Unknown cmd');
end;

const handlers: array[0..28] of PHandler = (@handler___UNKNOWN__, @handler_WARNING, @handler_TEAM_COLOR, @handler_TEAM_ACCEPTED, @handler_SERVER_VARS, @handler_SERVER_MESSAGE, @handler_SERVER_AUTH, @handler_RUN_GAME, @handler_ROUND_FINISHED, @handler_ROOMS, @handler_PROTO, @handler_PING, @handler_NOTICE, @handler_NICK, @handler_LOBBY_LEFT, @handler_LOBBY_JOINED, @handler_LEFT, @handler_KICKED, @handler_JOINING, @handler_JOINED, @handler_INFO, @handler_HH_NUM, @handler_EM, @handler_CONNECTED, @handler_CLIENT_FLAGS, @handler_CHAT, @handler_BYE, @handler_BANLIST, @handler_ASKPASSWORD);


// end of generated stuff
procedure handleTail;
var cnt: Longint;
    c: char;
begin
    state.l:= 0;

    c:= getCurrChar;
    repeat
        if c = #10 then cnt:= 0 else cnt:= 1;
        repeat
            c:= getNextChar;
            inc(cnt)
        until (c = #0) or (c = #10);
    until (c = #0) or (cnt = 1)
end;

var sock: PTCPSocket;
    fds: PSDLNet_SocketSet;
    netReaderThread: PSDL_Thread;

function getCurrChar: char;
begin
    getCurrChar:= state.buf[state.bufpos]
end;

function getNextChar: char;
var r: byte;
begin
    if state.bufpos < byte(state.buf[0]) then
    begin
        inc(state.bufpos);
    end else
    begin
        r:= SDLNet_TCP_Recv(sock, @state.buf[1], 255);
        if r > 0 then
        begin
            state.bufpos:= 1;
            state.buf[0]:= char(r);
        end else
        begin
            state.bufpos:= 0;
            state.buf[0]:= #0;
        end
    end;

    getNextChar:= state.buf[state.bufpos];
end;

function netReader(data: pointer): LongInt; cdecl; export;
var c: char;
begin
repeat
    c:= getNextChar;
    writeln('>>>>> ', c, ' [', letters[state.l], '] ', commands[state.l]);
    if c = #0 then
        state.netState:= netDisconnected
    else
    begin
        while (letters[state.l] <> c) and (commands[state.l] > 0) do
            inc(state.l, commands[state.l]);

        if c = letters[state.l] then
            if commands[state.l] < 0 then
                begin
                    handlers[-10 - commands[state.l]]();
                    handleTail()
                end
            else
                inc(state.l)
        else
        begin
            handler___UNKNOWN__();
            handleTail()
        end
    end
until state.netState = netDisconnected;

writeln('[NET] netReader: disconnected');
end;

procedure sendNet(s: shortstring);
begin
    writeln('[NET] Send: ', s);
    SDLNet_TCP_Send(sock, @s[1], byte(s[0]));
    SDLNet_TCP_Send(sock, @endCmd, 2);
end;

procedure connectOfficialServer;
var ipaddr: TIPAddress;
begin
    if sock <> nil then
        exit;

    if SDLNet_ResolveHost(ipaddr, PChar('netserver.hedgewars.org'), 46631) = 0 then
        sock:= SDLNet_TCP_Open(ipaddr);

    state.bufpos:= 0;
    state.buf:= '';

    state.l:= 0;
    state.netState:= netConnecting;

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

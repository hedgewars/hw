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

type TCmdType = (cmd___UNKNOWN__, cmd_WARNING, cmd_TEAM_COLOR, cmd_TEAM_ACCEPTED, cmd_SERVER_VARS, cmd_SERVER_MESSAGE, cmd_SERVER_AUTH, cmd_RUN_GAME, cmd_ROUND_FINISHED, cmd_ROOMS, cmd_PROTO, cmd_PING, cmd_NOTICE, cmd_NICK, cmd_LOBBY_LEFT, cmd_LOBBY_JOINED, cmd_LEFT, cmd_KICKED, cmd_JOINING, cmd_JOINED, cmd_INFO, cmd_HH_NUM, cmd_EM, cmd_CONNECTED, cmd_CLIENT_FLAGS, cmd_CHAT, cmd_BYE, cmd_BANLIST, cmd_ASKPASSWORD);

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
end;

procedure handler_BANLIST;
begin
end;

procedure handler_BYE;
begin
end;

procedure handler_CHAT;
begin
end;

procedure handler_CLIENT_FLAGS;
begin
end;

procedure handler_CONNECTED;
begin
end;

procedure handler_EM;
begin
end;

procedure handler_HH_NUM;
begin
end;

procedure handler_INFO;
begin
end;

procedure handler_JOINED;
begin
end;

procedure handler_JOINING;
begin
end;

procedure handler_KICKED;
begin
end;

procedure handler_LEFT;
begin
end;

procedure handler_LOBBY_JOINED;
begin
end;

procedure handler_LOBBY_LEFT;
begin
end;

procedure handler_NICK;
begin
end;

procedure handler_NOTICE;
begin
end;

procedure handler_PING;
begin
    sendNet('PONG')
end;

procedure handler_PROTO;
begin
end;

procedure handler_ROOMS;
begin
end;

procedure handler_ROUND_FINISHED;
begin
end;

procedure handler_RUN_GAME;
begin
end;

procedure handler_SERVER_AUTH;
begin
end;

procedure handler_SERVER_MESSAGE;
begin
end;

procedure handler_SERVER_VARS;
begin
end;

procedure handler_TEAM_ACCEPTED;
begin
end;

procedure handler_TEAM_COLOR;
begin
end;

procedure handler_WARNING;
begin
end;

procedure handler___UNKNOWN__;
begin
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

function netWriter(sock: PTCPSocket): LongInt; cdecl; export;
begin
    netWriter:= 0;
end;

function netReader(data: pointer): LongInt; cdecl; export;
var c: char;
    ipaddr: TIPAddress;
begin
    netReader:= 0;

    if SDLNet_ResolveHost(ipaddr, PChar('netserver.hedgewars.org'), 46631) = 0 then
        sock:= SDLNet_TCP_Open(ipaddr);

    SDL_CreateThread(@netWriter{$IFDEF SDL2}, 'netWriter'{$ENDIF}, sock);

    repeat
        c:= getNextChar;
        //writeln('>>>>> ', c, ' [', letters[state.l], '] ', commands[state.l]);
        if c = #0 then
            state.netState:= netDisconnected
        else
        begin
            while (letters[state.l] <> c) and (commands[state.l] > 0) do
                inc(state.l, commands[state.l]);

            if c = letters[state.l] then
                if commands[state.l] < 0 then
                begin
                    state.cmd:= TCmdType(-10 - commands[state.l]);
                    writeln('[NET] ', state.cmd);
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

    sock:= nil;

    writeln('[NET] netReader: disconnected');
end;

procedure sendNet(s: shortstring);
begin
    writeln('[NET] Send: ', s);
    SDLNet_TCP_Send(sock, @s[1], byte(s[0]));
    SDLNet_TCP_Send(sock, @endCmd, 2);
end;

procedure connectOfficialServer;
begin
    if sock <> nil then
        exit;

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
end;

procedure freeModule;
begin
end;

end.

unit uFLNet;
interface

procedure connectOfficialServer;

procedure initModule;
procedure freeModule;
procedure sendNet(s: shortstring);
procedure sendNetLn(s: shortstring);

implementation
uses SDLh, uFLIPC, uFLTypes, uFLUICallback, uFLNetTypes, uFLUtils;

const endCmd: string = #10 + #10;

function getNextChar: char; forward;
function getCurrChar: char; forward;

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

procedure handleTail; forward;
function getShortString: shortstring; forward;

// generated stuff here
const letters: array[0..212] of char = ('A', 'S', 'K', 'P', 'A', 'S', 'S', 'W',
    'O', 'R', 'D', #10, 'B', 'A', 'N', 'L', 'I', 'S', 'T', #10, 'Y', 'E', #10, 'C',
    'H', 'A', 'T', #10, 'L', 'I', 'E', 'N', 'T', '_', 'F', 'L', 'A', 'G', 'S', #10,
    'O', 'N', 'N', 'E', 'C', 'T', 'E', 'D', #10, 'E', 'M', #10, 'R', 'R', 'O', 'R',
    #10, 'H', 'H', '_', 'N', 'U', 'M', #10, 'I', 'N', 'F', 'O', #10, 'J', 'O', 'I',
    'N', 'E', 'D', #10, 'I', 'N', 'G', #10, 'K', 'I', 'C', 'K', 'E', 'D', #10, 'L',
    'E', 'F', 'T', #10, 'O', 'B', 'B', 'Y', ':', 'J', 'O', 'I', 'N', 'E', 'D', #10,
    'L', 'E', 'F', 'T', #10, 'N', 'I', 'C', 'K', #10, 'O', 'T', 'I', 'C', 'E', #10,
    'P', 'I', 'N', 'G', #10, 'R', 'O', 'T', 'O', #10, 'R', 'O', 'O', 'M', 'S', #10,
    #10, 'U', 'N', 'D', '_', 'F', 'I', 'N', 'I', 'S', 'H', 'E', 'D', #10, 'U', 'N',
    '_', 'G', 'A', 'M', 'E', #10, 'S', 'E', 'R', 'V', 'E', 'R', '_', 'A', 'U', 'T',
    'H', #10, 'M', 'E', 'S', 'S', 'A', 'G', 'E', #10, 'V', 'A', 'R', 'S', #10, 'T',
    'E', 'A', 'M', '_', 'A', 'C', 'C', 'E', 'P', 'T', 'E', 'D', #10, 'C', 'O', 'L',
    'O', 'R', #10, 'W', 'A', 'R', 'N', 'I', 'N', 'G', #10, #0, #10);
const commands: array[0..212] of integer = (12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    -40, 11, 7, 0, 0, 0, 0, 0, -39, 0, 0, -38, 26, 4, 0, 0, -37, 12, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, -36, 0, 0, 0, 0, 0, 0, 0, 0, -35, 8, 2, -34, 0, 0, 0, 0, -33, 7,
    0, 0, 0, 0, 0, -32, 5, 0, 0, 0, -31, 11, 0, 0, 0, 3, 0, -30, 0, 0, 0, -29, 7, 0,
    0, 0, 0, 0, -28, 22, 4, 0, 0, -27, 0, 0, 0, 0, 0, 7, 0, 0, 0, 0, 0, -26, 0, 0,
    0, 0, -25, 11, 4, 0, 0, -24, 0, 0, 0, 0, 0, -23, 10, 4, 0, 0, -22, 0, 0, 0, 0,
    -21, 28, 19, 5, 3, 2, -19, -20, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -18, 0, 0, 0,
    0, 0, 0, 0, -17, 25, 0, 0, 0, 0, 0, 0, 5, 0, 0, 0, -16, 8, 0, 0, 0, 0, 0, 0,
    -15, 0, 0, 0, 0, -14, 20, 0, 0, 0, 0, 9, 0, 0, 0, 0, 0, 0, 0, -13, 0, 0, 0, 0,
    0, -12, 8, 0, 0, 0, 0, 0, 0, -11, 0, -10);

procedure handler_;
begin
    sendUI(mtNetData, @state.cmd, sizeof(state.cmd));
    writeln('handler_');
    handleTail()
end;

procedure handler_L;
begin
    writeln('handler_L');
    handleTail()
end;

procedure handler_ML;
begin
    writeln('handler_ML');
    handleTail()
end;

procedure handler_MS;
var cmd: TCmdParamS;
    f: boolean;
begin
    sendUI(mtNetData, @state.cmd, sizeof(state.cmd));
    cmd.cmd:= Succ(state.cmd);

    repeat
        cmd.str1:= getShortString;
        f:= cmd.str1[0] <> #0;
        if f then
            sendUI(mtNetData, @cmd, sizeof(cmd));
    until not f
end;

procedure handler_S;
begin
    writeln('handler_S');
    handleTail()
end;

procedure handler_SL;
var cmd: TCmdParamSL;
begin
    cmd.cmd:= state.cmd;
    cmd.str1:= getShortString;
    if cmd.str1[0] = #0 then exit;
    cmd.str2:= getShortString; // FIXME should be long string
    if cmd.str2[0] = #0 then exit;
    sendUI(mtNetData, @cmd, sizeof(cmd));
    handleTail()
end;

procedure handler_SMS;
begin
    writeln('handler_SMS');
    handleTail()
end;

procedure handler__i;
var cmd: TCmdParami;
    s: shortstring;
begin
    writeln('handler__i');
    s:= getShortString();
    if s[0] = #0 then exit;
    cmd.cmd:= state.cmd;
    s:= getShortString();
    if s[0] = #0 then exit;
    cmd.param1:= strToInt(s);
    sendUI(mtNetData, @cmd, sizeof(cmd));
    handleTail()
end;

procedure handler_i;
begin
    writeln('handler_i');
    handleTail()
end;

procedure handler__UNKNOWN_;
begin
    writeln('[NET] Unknown cmd');
    handleTail()
end;

const handlers: array[0..30] of PHandler = (@handler__UNKNOWN_, @handler_L, @handler_MS, @handler_S,
    @handler_SL, @handler_L, @handler_S, @handler_, @handler_, @handler_MS,
    @handler_MS, @handler_i, @handler_MS, @handler_L, @handler_S, @handler_SL,
    @handler_MS, @handler_SMS, @handler_, @handler_S, @handler_MS, @handler_MS,
    @handler_MS, @handler_L, @handler_ML, @handler__i, @handler_SMS, @handler_SL,
    @handler_SL, @handler_MS, @handler_S);
const net2cmd: array[0..30] of TCmdType = (cmd_WARNING, cmd_WARNING,
    cmd_TEAM_COLOR, cmd_TEAM_ACCEPTED, cmd_SERVER_VARS, cmd_SERVER_MESSAGE,
    cmd_SERVER_AUTH, cmd_RUN_GAME, cmd_ROUND_FINISHED, cmd_ROOMS, cmd_ROOM,
    cmd_PROTO, cmd_PING, cmd_NOTICE, cmd_NICK, cmd_LOBBY_LEFT, cmd_LOBBY_JOINED,
    cmd_LEFT, cmd_KICKED, cmd_JOINING, cmd_JOINED, cmd_INFO, cmd_HH_NUM, cmd_ERROR,
    cmd_EM, cmd_CONNECTED, cmd_CLIENT_FLAGS, cmd_CHAT, cmd_BYE, cmd_BANLIST,
    cmd_ASKPASSWORD);



// end of generated stuff
procedure handleTail;
var cnt: Longint;
    c: char;
begin
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

function netReader(data: pointer): LongInt; cdecl; export;
var c: char;
    ipaddr: TIPAddress;
begin
    netReader:= 0;

    if SDLNet_ResolveHost(ipaddr, PChar('netserver.hedgewars.org'), 46631) = 0 then
        sock:= SDLNet_TCP_Open(ipaddr);

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
                    state.cmd:= net2cmd[-10 - commands[state.l]];
                    writeln('[NET] ', state.cmd);
                    handlers[-10 - commands[state.l]]();
                    state.l:= 0
                end
                else
                    inc(state.l)
            else
            begin
                handler__UNKNOWN_()
            end
        end
    until state.netState = netDisconnected;

    SDLNet_TCP_Close(sock);
    sock:= nil;

    writeln('[NET] netReader: disconnected');
end;

procedure sendNet(s: shortstring);
begin
    writeln('[NET] Send: ', s);
    ipcToNet(s + endCmd);
end;

procedure sendNetLn(s: shortstring);
begin
    writeln('[NET] Send: ', s);
    ipcToNet(s + #10);
end;

function getShortString: shortstring;
var s: shortstring;
    c: char;
begin
    s[0]:= #0;

    repeat
        inc(s[0]);
        s[byte(s[0])]:= getNextChar
    until (s[0] = #255) or (s[byte(s[0])] = #10) or (s[byte(s[0])] = #0);

    if s[byte(s[0])] = #10 then
        dec(s[0])
    else
        repeat c:= getNextChar until (c = #0) or (c = #10);

    getShortString:= s
end;

procedure netSendCallback(p: pointer; msg: PChar; len: Longword);
begin
    // W A R N I N G: totally thread-unsafe due to use of sock variable
    SDLNet_TCP_Send(sock, msg, len);
end;

procedure connectOfficialServer;
begin
    if sock <> nil then
        exit;

    state.bufpos:= 0;
    state.buf:= '';

    state.l:= 0;
    state.netState:= netConnecting;

    netReaderThread:= SDL_CreateThread(@netReader, 'netReader', nil);
    SDL_DetachThread(netReaderThread)
end;

procedure initModule;
begin
    sock:= nil;

    SDLNet_Init;

    registerNetCallback(nil, @netSendCallback);
end;

procedure freeModule;
begin
end;

end.

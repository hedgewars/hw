(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *)

{$INCLUDE "options.inc"}

unit uIO;
interface
uses SDLh, uTypes;

procedure initModule;
procedure freeModule;

procedure InitIPC;
procedure SendIPC(s: shortstring);
procedure SendIPCXY(cmd: char; X, Y: LongInt);
procedure SendIPCRaw(p: pointer; len: Longword);
procedure SendIPCAndWaitReply(s: shortstring);
procedure SendKeepAliveMessage(Lag: Longword);
procedure LoadRecordFromFile(fileName: shortstring);
procedure SendStat(sit: TStatInfoType; s: shortstring);
procedure IPCWaitPongEvent;
procedure IPCCheckSock;
procedure NetGetNextCmd;
procedure doPut(putX, putY: LongInt; fromAI: boolean);

implementation
uses uConsole, uConsts, uVariables, uCommands, uUtils, uDebug;

const
    cSendEmptyPacketTime = 1000;

type PCmd = ^TCmd;
     TCmd = packed record
            Next: PCmd;
            loTime: Word;
            case byte of
            1: (len: byte;
                cmd: Char;
                X, Y: LongInt);
            2: (str: shortstring);
            end;

var IPCSock: PTCPSocket;
    fds: PSDLNet_SocketSet;
    isPonged: boolean;
    SocketString: shortstring;

    headcmd: PCmd;
    lastcmd: PCmd;

    SendEmptyPacketTicks: LongWord;

function AddCmd(Time: Word; str: shortstring): PCmd;
var command: PCmd;
begin
new(command);
FillChar(command^, sizeof(TCmd), 0);
command^.loTime:= Time;
command^.str:= str;
if command^.cmd <> 'F' then dec(command^.len, 2); // cut timestamp
if headcmd = nil then
    begin
    headcmd:= command;
    lastcmd:= command
    end
else
    begin
    lastcmd^.Next:= command;
    lastcmd:= command
    end;
AddCmd:= command;
end;

procedure RemoveCmd;
var tmp: PCmd;
begin
TryDo(headcmd <> nil, 'Engine bug: headcmd = nil', true);
tmp:= headcmd;
headcmd:= headcmd^.Next;
if headcmd = nil then
    lastcmd:= nil;
dispose(tmp)
end;

procedure InitIPC;
var ipaddr: TIPAddress;
begin
    WriteToConsole('Init SDL_Net... ');
    SDLTry(SDLNet_Init = 0, true);
    fds:= SDLNet_AllocSocketSet(1);
    SDLTry(fds <> nil, true);
    WriteLnToConsole(msgOK);
    WriteToConsole('Establishing IPC connection to tcp 127.0.0.1:' + IntToStr(ipcPort) + ' ');
    {$HINTS OFF}
    SDLTry(SDLNet_ResolveHost(ipaddr, PChar('127.0.0.1'), ipcPort) = 0, true);
    {$HINTS ON}
    IPCSock:= SDLNet_TCP_Open(ipaddr);
    SDLTry(IPCSock <> nil, true);
    WriteLnToConsole(msgOK)
end;

procedure ParseIPCCommand(s: shortstring);
var loTicks: Word;
begin
case s[1] of
     '!': begin AddFileLog('Ping? Pong!'); isPonged:= true; end;
     '?': SendIPC(_S'!');
     'e': ParseCommand(copy(s, 2, Length(s) - 1), true);
     'E': OutError(copy(s, 2, Length(s) - 1), true);
     'W': OutError(copy(s, 2, Length(s) - 1), false);
     'M': ParseCommand('landcheck ' + s, true);
     'T': case s[2] of
               'L': GameType:= gmtLocal;
               'D': GameType:= gmtDemo;
               'N': GameType:= gmtNet;
               'S': GameType:= gmtSave;
               'V': GameType:= gmtRecord;
               else OutError(errmsgIncorrectUse + ' IPC "T" :' + s[2], true) end;
     'V': begin
              if s[2] = '.' then
                  ParseCommand('campvar ' + copy(s, 3, length(s) - 2), true);
          end
     else
     loTicks:= SDLNet_Read16(@s[byte(s[0]) - 1]);
     AddCmd(loTicks, s);
     AddFileLog('[IPC in] '+s[1]+' ticks '+IntToStr(lastcmd^.loTime));
     end
end;

procedure IPCCheckSock;
var i: LongInt;
    s: shortstring;
begin
    if IPCSock = nil then
        exit;

    fds^.numsockets:= 0;
    SDLNet_AddSocket(fds, IPCSock);

    while SDLNet_CheckSockets(fds, 0) > 0 do
    begin
        i:= SDLNet_TCP_Recv(IPCSock, @s[1], 255 - Length(SocketString));
        if i > 0 then
        begin
            s[0]:= char(i);
            SocketString:= SocketString + s;
            while (Length(SocketString) > 1) and (Length(SocketString) > byte(SocketString[1])) do
            begin
                ParseIPCCommand(copy(SocketString, 2, byte(SocketString[1])));
                Delete(SocketString, 1, Succ(byte(SocketString[1])))
            end
        end
    else
        OutError('IPC connection lost', true)
    end;
end;

procedure LoadRecordFromFile(fileName: shortstring);
var f: file;
    ss: shortstring = '';
    i: LongInt;
    s: shortstring;
begin

// set RDNLY on file open
filemode:= 0;
{$I-}
assign(f, fileName);
reset(f, 1);

tryDo(IOResult = 0, 'Error opening file ' + fileName, true);

i:= 0; // avoid compiler hints
s[0]:= #0;
repeat
    BlockRead(f, s[1], 255 - Length(ss), i);
    if i > 0 then
        begin
        s[0]:= char(i);
        ss:= ss + s;
        while (Length(ss) > 1)and(Length(ss) > byte(ss[1])) do
            begin
            ParseIPCCommand(copy(ss, 2, byte(ss[1])));
            Delete(ss, 1, Succ(byte(ss[1])))
            end
        end
until i = 0;

close(f)
{$I+}
end;

procedure SendStat(sit: TStatInfoType; s: shortstring);
const stc: array [TStatInfoType] of char = ('r', 'D', 'k', 'K', 'H', 'T', 'P', 's', 'S', 'B');
var buf: shortstring;
begin
buf:= 'i' + stc[sit] + s;
SendIPCRaw(@buf[0], length(buf) + 1)
end;


procedure SendIPC(s: shortstring);
begin
if IPCSock <> nil then
    begin
    SendEmptyPacketTicks:= 0;
    if s[0]>#251 then
        s[0]:= #251;
        
    SDLNet_Write16(GameTicks, @s[Succ(byte(s[0]))]);
    AddFileLog('[IPC out] '+ s[1]);
    inc(s[0], 2);
    SDLNet_TCP_Send(IPCSock, @s, Succ(byte(s[0])))
    end
end;

procedure SendIPCRaw(p: pointer; len: Longword);
begin
if IPCSock <> nil then
    begin
    SDLNet_TCP_Send(IPCSock, p, len)
    end
end;

procedure SendIPCXY(cmd: char; X, Y: LongInt);
var s: shortstring;
begin
s[0]:= #9;
s[1]:= cmd;
SDLNet_Write32(X, @s[2]);
SDLNet_Write32(Y, @s[6]);
SendIPC(s)
end;

procedure IPCWaitPongEvent;
begin
isPonged:= false;
repeat
    IPCCheckSock;
    SDL_Delay(1)
until isPonged
end;

procedure SendIPCAndWaitReply(s: shortstring);
begin
SendIPC(s);
SendIPC(_S'?');
IPCWaitPongEvent
end;

procedure SendKeepAliveMessage(Lag: Longword);
begin
inc(SendEmptyPacketTicks, Lag);
if (SendEmptyPacketTicks >= cSendEmptyPacketTime) then
    SendIPC(_S'+')
end;

procedure NetGetNextCmd;
var tmpflag: boolean;
    s: shortstring;
    x32, y32: LongInt;
begin
tmpflag:= true;

while (headcmd <> nil)
    and (tmpflag or (headcmd^.cmd = '#')) // '#' is the only cmd which can be sent within same tick after 'N'
    and ((GameTicks = hiTicks shl 16 + headcmd^.loTime)
        or (headcmd^.cmd = 's') // for these commands time is not specified
        or (headcmd^.cmd = 'h') // seems the hedgewars protocol does not allow remote synced commands
        or (headcmd^.cmd = '#') // must be synced for saves to work
        or (headcmd^.cmd = 'b')
        or (headcmd^.cmd = 'F')) do
    begin
    case headcmd^.cmd of
        '+': ; // do nothing - it is just an empty packet
        '#': begin
            AddFileLog('hiTicks increment by remote message');
            inc(hiTicks);
            end;
        'L': ParseCommand('+left', true);
        'l': ParseCommand('-left', true);
        'R': ParseCommand('+right', true);
        'r': ParseCommand('-right', true);
        'U': ParseCommand('+up', true);
        'u': ParseCommand('-up', true);
        'D': ParseCommand('+down', true);
        'd': ParseCommand('-down', true);
        'Z': ParseCommand('+precise', true);
        'z': ParseCommand('-precise', true);
        'A': ParseCommand('+attack', true);
        'a': ParseCommand('-attack', true);
        'S': ParseCommand('switch', true);
        'j': ParseCommand('ljump', true);
        'J': ParseCommand('hjump', true);
        ',': ParseCommand('skip', true);
        'c': begin
            s:= copy(headcmd^.str, 2, Pred(headcmd^.len));
            ParseCommand('gencmd ' + s, true);
             end;
        's': begin
            s:= copy(headcmd^.str, 2, Pred(headcmd^.len));
            ParseCommand('chatmsg ' + s, true);
            WriteLnToConsole(s)
             end;
        'b': begin
            s:= copy(headcmd^.str, 2, Pred(headcmd^.len));
            ParseCommand('chatmsg ' + #4 + s, true);
            WriteLnToConsole(s)
             end;
// TODO: deprecate 'F'
        'F': ParseCommand('teamgone ' + copy(headcmd^.str, 2, Pred(headcmd^.len)), true);
        'N': begin
            tmpflag:= false;
            lastTurnChecksum:= SDLNet_Read32(@headcmd^.str[2]);
            AddFileLog('got cmd "N": time '+IntToStr(hiTicks shl 16 + headcmd^.loTime))
             end;
        'p': begin
            x32:= SDLNet_Read32(@(headcmd^.X));
            y32:= SDLNet_Read32(@(headcmd^.Y));
            doPut(x32, y32, false)
             end;
        'P': begin
            // these are equations solved for CursorPoint
            // SDLNet_Read16(@(headcmd^.X)) == CursorPoint.X - WorldDx;
            // SDLNet_Read16(@(headcmd^.Y)) == cScreenHeight - CursorPoint.Y - WorldDy;
            if not (CurrentTeam^.ExtDriven and bShowAmmoMenu) then
               begin
               CursorPoint.X:= LongInt(SDLNet_Read32(@(headcmd^.X))) + WorldDx;
               CursorPoint.Y:= cScreenHeight - LongInt(SDLNet_Read32(@(headcmd^.Y))) - WorldDy
               end
             end;
        'w': ParseCommand('setweap ' + headcmd^.str[2], true);
        't': ParseCommand('taunt ' + headcmd^.str[2], true);
        'h': ParseCommand('hogsay ' + copy(headcmd^.str, 2, Pred(headcmd^.len)), true);
        '1'..'5': ParseCommand('timer ' + headcmd^.cmd, true);
        else
            if (headcmd^.cmd >= #128) and (headcmd^.cmd <= char(128 + cMaxSlotIndex)) then
                ParseCommand('slot ' + char(byte(headcmd^.cmd) - 79), true)
                else
                OutError('Unexpected protocol command: ' + headcmd^.cmd, True)
        end;
    RemoveCmd
    end;

if (headcmd <> nil) and tmpflag and (not CurrentTeam^.hasGone) then
    TryDo(GameTicks < hiTicks shl 16 + headcmd^.loTime,
            'oops, queue error. in buffer: ' + headcmd^.cmd +
            ' (' + IntToStr(GameTicks) + ' > ' +
            IntToStr(hiTicks shl 16 + headcmd^.loTime) + ')',
            true);

isInLag:= (headcmd = nil) and tmpflag and (not CurrentTeam^.hasGone);

if isInLag then fastUntilLag:= false
end;

procedure chFatalError(var s: shortstring);
begin
    SendIPC('E' + s);
end;

procedure doPut(putX, putY: LongInt; fromAI: boolean);
begin
if CheckNoTeamOrHH or isPaused then
    exit;
bShowFinger:= false;
if not CurrentTeam^.ExtDriven and bShowAmmoMenu then
    begin
    bSelected:= true;
    exit
    end;

with CurrentHedgehog^.Gear^,
    CurrentHedgehog^ do
    if (State and gstHHChooseTarget) <> 0 then
        begin
        isCursorVisible:= false;
        if not CurrentTeam^.ExtDriven then
            begin
            if fromAI then
                begin
                TargetPoint.X:= putX;
                TargetPoint.Y:= putY
                end
            else
                begin
                TargetPoint.X:= CursorPoint.X - WorldDx;
                TargetPoint.Y:= cScreenHeight - CursorPoint.Y - WorldDy;
                end;
            SendIPCXY('p', TargetPoint.X, TargetPoint.Y);
            end
        else
            begin
            TargetPoint.X:= putX;
            TargetPoint.Y:= putY
            end;
        AddFileLog('put: ' + inttostr(TargetPoint.X) + ', ' + inttostr(TargetPoint.Y));
        State:= State and (not gstHHChooseTarget);
        if (Ammoz[CurAmmoType].Ammo.Propz and ammoprop_AttackingPut) <> 0 then
            Message:= Message or (gmAttack and InputMask);
        end
    else
        if CurrentTeam^.ExtDriven then
            OutError('got /put while not being in choose target mode', false)
end;

procedure initModule;
begin
    RegisterVariable('fatal', @chFatalError, true );

    IPCSock:= nil;

    headcmd:= nil;
    lastcmd:= nil;
    isPonged:= false;
    SocketString:= '';
    
    hiTicks:= 0;
    SendEmptyPacketTicks:= 0;
end;

procedure freeModule;
begin
    while headcmd <> nil do RemoveCmd;
    SDLNet_FreeSocketSet(fds);
    SDLNet_TCP_Close(IPCSock);
    SDLNet_Quit();
end;

end.

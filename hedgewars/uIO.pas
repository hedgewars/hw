(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004, 2005, 2007, 2008 Andrey Korotaev <unC0Rr@gmail.com>
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
uses SDLh;

var ipcPort: Word = 0;
    hiTicks: Word;

procedure initModule;
procedure freeModule;

procedure SendIPC(s: shortstring);
procedure SendIPCXY(cmd: char; X, Y: SmallInt);
procedure SendIPCRaw(p: pointer; len: Longword);
procedure SendIPCAndWaitReply(s: shortstring);
procedure SendIPCTimeInc;
procedure SendKeepAliveMessage(Lag: Longword);
procedure LoadRecordFromFile(fileName: shortstring);
procedure IPCWaitPongEvent;
procedure IPCCheckSock;
procedure InitIPC;
procedure CloseIPC;
procedure NetGetNextCmd;

implementation
uses uConsole, uConsts, uMisc, uLand, uChat, uTeams, uTypes, uVariables, uCommands;

type PCmd = ^TCmd;
     TCmd = packed record
            Next: PCmd;
            loTime: Word;
            case byte of
            1: (len: byte;
                cmd: Char;
                X, Y: SmallInt);
            2: (str: shortstring);
            end;

var IPCSock: PTCPSocket;
    fds: PSDLNet_SocketSet;
    isPonged: boolean;

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
   end else
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
if headcmd = nil then lastcmd:= nil;
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
WriteToConsole('Establishing IPC connection... ');
{$HINTS OFF}
SDLTry(SDLNet_ResolveHost(ipaddr, '127.0.0.1', ipcPort) = 0, true);
{$HINTS ON}
IPCSock:= SDLNet_TCP_Open(ipaddr);
SDLTry(IPCSock <> nil, true);
WriteLnToConsole(msgOK)
end;

procedure CloseIPC;
begin
    SDLNet_FreeSocketSet(fds);
    SDLNet_TCP_Close(IPCSock);
    SDLNet_Quit();
end;

procedure ParseIPCCommand(s: shortstring);
var loTicks: Word;
begin
case s[1] of
     '!': begin {$IFDEF DEBUGFILE}AddFileLog('Ping? Pong!');{$ENDIF}isPonged:= true; end;
     '?': SendIPC('!');
     'e': ParseCommand(copy(s, 2, Length(s) - 1), true);
     'E': OutError(copy(s, 2, Length(s) - 1), true);
     'W': OutError(copy(s, 2, Length(s) - 1), false);
     'M': CheckLandDigest(s);
     'T': case s[2] of
               'L': GameType:= gmtLocal;
               'D': GameType:= gmtDemo;
               'N': GameType:= gmtNet;
               'S': GameType:= gmtSave;
               else OutError(errmsgIncorrectUse + ' IPC "T" :' + s[2], true) end;
     else
     loTicks:= SDLNet_Read16(@s[byte(s[0]) - 1]);
     AddCmd(loTicks, s);
     {$IFDEF DEBUGFILE}AddFileLog('IPC in: '+s[1]+' ticks '+inttostr(lastcmd^.loTime));{$ENDIF}
     end
end;

procedure IPCCheckSock;
const ss: shortstring = '';
var i: LongInt;
    buf: array[0..255] of byte;
    s: shortstring absolute buf;
begin
if IPCSock = nil then
   exit;

fds^.numsockets:= 0;
SDLNet_AddSocket(fds, IPCSock);

while SDLNet_CheckSockets(fds, 0) > 0 do
    begin
    i:= SDLNet_TCP_Recv(IPCSock, @buf[1], 255 - Length(ss));
    if i > 0 then
        begin
        buf[0]:= i;
        ss:= ss + s;
        while (Length(ss) > 1) and (Length(ss) > byte(ss[1])) do
            begin
            ParseIPCCommand(copy(ss, 2, byte(ss[1])));
            Delete(ss, 1, Succ(byte(ss[1])))
            end
        end else OutError('IPC connection lost', true)
    end;
end;

procedure LoadRecordFromFile(fileName: shortstring);
var f: file;
    ss: shortstring = '';
    i: LongInt;
    buf: array[0..255] of byte;
    s: shortstring absolute buf;
begin

// set RDNLY on file open
filemode:= 0;

assign(f, fileName);
reset(f, 1);

i:= 0; // avoid compiler hints
buf[0]:= 0;
repeat
    BlockRead(f, buf[1], 255 - Length(ss), i);
    if i > 0 then
        begin
        buf[0]:= i;
        ss:= ss + s;
        while (Length(ss) > 1)and(Length(ss) > byte(ss[1])) do
            begin
            ParseIPCCommand(copy(ss, 2, byte(ss[1])));
            Delete(ss, 1, Succ(byte(ss[1])))
            end
        end
until i = 0;

close(f)
end;

procedure SendIPC(s: shortstring);
begin
if IPCSock <> nil then
    begin
    SendEmptyPacketTicks:= 0;
    if s[0]>#251 then s[0]:= #251;
    SDLNet_Write16(GameTicks, @s[Succ(byte(s[0]))]);
    {$IFDEF DEBUGFILE}AddFileLog('IPC send: '+ s[1]);{$ENDIF}
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

procedure SendIPCXY(cmd: char; X, Y: SmallInt);
var s: shortstring;
begin
s[0]:= #5;
s[1]:= cmd;
SDLNet_Write16(X, @s[2]);
SDLNet_Write16(Y, @s[4]);
SendIPC(s)
end;

procedure SendIPCTimeInc;
const timeinc: shortstring = '#';
begin
{$IFDEF DEBUGFILE}AddFileLog('IPC Send #');{$ENDIF}
SendIPCRaw(@timeinc, 2)
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
SendIPC('?');
IPCWaitPongEvent
end;

procedure SendKeepAliveMessage(Lag: Longword);
begin
inc(SendEmptyPacketTicks, Lag);
if (SendEmptyPacketTicks >= cSendEmptyPacketTime) then
    SendIPC('+')
end;

procedure NetGetNextCmd;
var tmpflag: boolean;
    s: shortstring;
    x16, y16: SmallInt;
begin
tmpflag:= true;

while (headcmd <> nil)
    and (tmpflag or (headcmd^.cmd = '#')) // '#' is the only cmd which can be sent within same tick after 'N'
    and ((GameTicks = hiTicks shl 16 + headcmd^.loTime)
        or (headcmd^.cmd = 's') // for these commands time is not specified
        or (headcmd^.cmd = '#')
        or (headcmd^.cmd = 'b')
        or (headcmd^.cmd = 'F')) do
    begin
    case headcmd^.cmd of
        '+': ; // do nothing - it is just an empty packet
        '#': inc(hiTicks);
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
        's': begin
            s:= copy(headcmd^.str, 2, Pred(headcmd^.len));
            AddChatString(s);
            WriteLnToConsole(s)
            end;
        'b': begin
            s:= copy(headcmd^.str, 2, Pred(headcmd^.len));
            AddChatString(#4 + s);
            WriteLnToConsole(s)
            end;
        'F': TeamGone(copy(headcmd^.str, 2, Pred(headcmd^.len)));
        'N': begin
            tmpflag:= false;
            {$IFDEF DEBUGFILE}AddFileLog('got cmd "N": time '+inttostr(hiTicks shl 16 + headcmd^.loTime)){$ENDIF}
            end;
        'p': begin
            x16:= SDLNet_Read16(@(headcmd^.X));
            y16:= SDLNet_Read16(@(headcmd^.Y));
            doPut(x16, y16, false)
            end;
        'P': begin
            // these are equations solved for CursorPoint
            // SDLNet_Read16(@(headcmd^.X)) == CursorPoint.X - WorldDx;
            // SDLNet_Read16(@(headcmd^.Y)) == cScreenHeight - CursorPoint.Y - WorldDy;
            if not (CurrentTeam^.ExtDriven and bShowAmmoMenu) then
               begin
               CursorPoint.X:= SmallInt(SDLNet_Read16(@(headcmd^.X))) + WorldDx;
               CursorPoint.Y:= cScreenHeight - SmallInt(SDLNet_Read16(@(headcmd^.Y))) - WorldDy
               end
            end;
        'w': ParseCommand('setweap ' + headcmd^.str[2], true);
        't': ParseCommand('taunt ' + headcmd^.str[2], true);
        'h': ParseCommand('hogsay ' + copy(headcmd^.str, 2, Pred(headcmd^.len)), true);
        '1'..'5': ParseCommand('timer ' + headcmd^.cmd, true);
        #128..char(128 + cMaxSlotIndex): ParseCommand('slot ' + char(byte(headcmd^.cmd) - 79), true)
        else
            OutError('Unexpected protocol command: ' + headcmd^.cmd, True)
        end;
    RemoveCmd
    end;

if (headcmd <> nil) and tmpflag and (not CurrentTeam^.hasGone) then
    TryDo(GameTicks < hiTicks shl 16 + headcmd^.loTime,
            'oops, queue error. in buffer: ' + headcmd^.cmd +
            ' (' + inttostr(GameTicks) + ' > ' +
            inttostr(hiTicks shl 16 + headcmd^.loTime) + ')',
            true);

isInLag:= (headcmd = nil) and tmpflag and (not CurrentTeam^.hasGone);

if isInLag then fastUntilLag:= false
end;

procedure initModule;
begin
    IPCSock:= nil;

    headcmd:= nil;
    lastcmd:= nil;
    isPonged:= false;   // was const

    hiTicks:= 0;
    SendEmptyPacketTicks:= 0;
end;

procedure freeModule;
begin
    ipcPort:= 0;
end;

end.

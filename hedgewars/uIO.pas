(*
 * Hedgewars, a worms-like game
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

unit uIO;
interface
uses SDLh;
{$INCLUDE options.inc}

const ipcPort: Word = 0;

procedure SendIPC(s: shortstring);
procedure SendIPCXY(cmd: char; X, Y: SmallInt);
procedure SendIPCRaw(p: pointer; len: Longword);
procedure SendIPCAndWaitReply(s: shortstring);
procedure SendIPCTimeInc;
procedure IPCWaitPongEvent;
procedure IPCCheckSock;
procedure InitIPC;
procedure CloseIPC;
procedure NetGetNextCmd;

var hiTicks: Word = 0;

implementation
uses uConsole, uConsts, uWorld, uMisc, uLand, uChat;
const isPonged: boolean = false;

type PCmd = ^TCmd;
     TCmd = packed record
            Next: PCmd;
            Time: LongWord;
            case byte of
            1: (len: byte;
                cmd: Char;
                X, Y: SmallInt);
            2: (str: shortstring);
            end;

var  IPCSock: PTCPSocket = nil;
     fds: PSDLNet_SocketSet;

     headcmd: PCmd = nil;
     lastcmd: PCmd = nil;

function AddCmd(Time: Longword; str: shortstring): PCmd;
var Result: PCmd;
begin
new(Result);
FillChar(Result^, sizeof(TCmd), 0);
Result^.Time:= Time;
Result^.str:= str;
dec(Result^.len, 2); // cut timestamp
if headcmd = nil then
   begin
   headcmd:= Result;
   lastcmd:= Result
   end else
   begin
   lastcmd^.Next:= Result;
   lastcmd:= Result
   end;
AddCmd:= Result
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
SDLTry(SDLNet_ResolveHost(ipaddr, '127.0.0.1', ipcPort) = 0, true);
IPCSock:= SDLNet_TCP_Open(ipaddr);
SDLTry(IPCSock <> nil, true);
WriteLnToConsole(msgOK)
end;

procedure CloseIPC;
begin
SDLNet_FreeSocketSet(fds);
SDLNet_TCP_Close(IPCSock);
SDLNet_Quit
end;

procedure ParseIPCCommand(s: shortstring);
var loTicks: Word;
begin
case s[1] of
     '!': begin {$IFDEF DEBUGFILE}AddFileLog('Ping? Pong!');{$ENDIF}isPonged:= true; end;
     '?': SendIPC('!');
     '#': inc(hiTicks);
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
     AddCmd(hiTicks shl 16 + loTicks, s);
     {$IFDEF DEBUGFILE}AddFileLog('IPC in: '+s[1]+' ticks '+inttostr(lastcmd^.Time));{$ENDIF}
     end
end;

procedure IPCCheckSock;
const ss: string = '';
var i: LongInt;
    buf: array[0..255] of byte;
    s: shortstring absolute buf;
begin
fds^.numsockets:= 0;
SDLNet_AddSocket(fds, IPCSock);

while SDLNet_CheckSockets(fds, 0) > 0 do
      begin
      i:= SDLNet_TCP_Recv(IPCSock, @buf[1], 255 - Length(ss));
      if i > 0 then
         begin
         buf[0]:= i;
         ss:= ss + s;
         while (Length(ss) > 1)and(Length(ss) > byte(ss[1])) do
               begin
               ParseIPCCommand(copy(ss, 2, byte(ss[1])));
               Delete(ss, 1, Succ(byte(ss[1])))
               end
         end else OutError('IPC connection lost', true)
      end;
end;

procedure SendIPC(s: shortstring);
begin
if IPCSock <> nil then
   begin
   if s[0]>#251 then s[0]:= #251;
   SDLNet_Write16(GameTicks, @s[Succ(byte(s[0]))]);
   {$IFDEF DEBUGFILE}AddFileLog('IPC send: '+s);{$ENDIF}
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

procedure NetGetNextCmd;
var tmpflag: boolean;
    s: shortstring;
begin
while (headcmd <> nil) and (headcmd^.cmd = 's') do
      begin
      s:= copy(headcmd^.str, 2, Pred(headcmd^.len));
      AddChatString(s);
      WriteLnToConsole(s);
      RemoveCmd
      end;

if (headcmd <> nil) then
   TryDo(GameTicks <= headcmd^.Time,
         'oops, queue error. in buffer: ' + headcmd^.cmd +
         ' (' + inttostr(GameTicks) + ' > ' +
         inttostr(headcmd^.Time) + ')',
         true);

tmpflag:= true;
while (headcmd <> nil) and (GameTicks = headcmd^.Time) do
   begin
   tmpflag:= true;
   case headcmd^.cmd of
        'L': ParseCommand('+left', true);
        'l': ParseCommand('-left', true);
        'R': ParseCommand('+right', true);
        'r': ParseCommand('-right', true);
        'U': ParseCommand('+up', true);
        'u': ParseCommand('-up', true);
        'D': ParseCommand('+down', true);
        'd': ParseCommand('-down', true);
        'A': ParseCommand('+attack', true);
        'a': ParseCommand('-attack', true);
        'S': ParseCommand('switch', true);
        'j': ParseCommand('ljump', true);
        'J': ParseCommand('hjump', true);
        ',': ParseCommand('skip', true);
        'N': begin
             tmpflag:= false;
             {$IFDEF DEBUGFILE}AddFileLog('got cmd "N": time '+inttostr(headcmd^.Time)){$ENDIF}
             end;
        'p': begin
             TargetPoint.X:= SmallInt(SDLNet_Read16(@(headcmd^.X)));
             TargetPoint.Y:= SmallInt(SDLNet_Read16(@(headcmd^.Y)));
             ParseCommand('put', true)
             end;
        'P': begin
             CursorPoint.X:= SmallInt(SDLNet_Read16(@(headcmd^.X)) + WorldDx);
             CursorPoint.Y:= SmallInt(SDLNet_Read16(@(headcmd^.Y)) + WorldDy);
             end;
        'w': ParseCommand('setweap ' + headcmd^.str[2], true);
        '1'..'5': ParseCommand('timer ' + headcmd^.cmd, true);
        #128..char(128 + cMaxSlotIndex): ParseCommand('slot ' + char(byte(headcmd^.cmd) - 79), true)
        end;
   RemoveCmd
   end;
isInLag:= (headcmd = nil) and tmpflag
end;

end.

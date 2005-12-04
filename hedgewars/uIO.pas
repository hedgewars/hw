(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uIO;
interface
uses SDLh;
{$INCLUDE options.inc}

const ipcPort: Word = 0;

procedure SendIPC(s: shortstring);
procedure SendIPCAndWaitReply(s: shortstring);
procedure IPCCheckSock;
procedure InitIPC;
procedure CloseIPC;
procedure NetGetNextCmd;
procedure LoadFortPoints(Fort: shortstring; isRight: boolean; Count: Longword);

implementation
uses uConsole, uConsts, uWorld, uMisc, uRandom, uLand;
const isPonged: boolean = false;
var  IPCSock: PTCPSocket;
     fds: PSDLNet_SocketSet;

     extcmd: array[word] of packed record
                                   Time: LongWord;
                                   case byte of
                                        1: (len: byte;
                                            cmd: Char;
                                            X, Y: integer;);
                                        2: (str: shortstring);
                                   end;
     cmdcurpos: integer = 0;
     cmdendpos: integer = -1;

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
begin
case s[1] of
     '!': begin {$IFDEF DEBUGFILE}AddFileLog('Ping? Pong!');{$ENDIF}isPonged:= true; end;
     '?': SendIPC('!');
     'e': ParseCommand(copy(s, 2, Length(s) - 1));
     'E': OutError(copy(s, 2, Length(s) - 1), true);
     'W': OutError(copy(s, 2, Length(s) - 1), false);
     'T': case s[2] of
               'L': GameType:= gmtLocal;
               'D': GameType:= gmtDemo;
               'N': GameType:= gmtNet;
               else OutError(errmsgIncorrectUse + ' IPC "T" :' + s[2], true) end;
     else
     inc(cmdendpos);
     extcmd[cmdendpos].Time := PLongWord(@s[byte(s[0]) - 3])^;
     extcmd[cmdendpos].str  := s;
     {$IFDEF DEBUGFILE}AddFileLog('IPC in: '+s[1]+' ticks '+inttostr(extcmd[cmdendpos].Time)+' at '+inttostr(cmdendpos));{$ENDIF}
     dec(extcmd[cmdendpos].len, 4)
     end
end;

procedure IPCCheckSock;
const ss: string = '';
var i: integer;
    buf: array[0..255] of byte;
    s: shortstring absolute buf;
begin
fds.numsockets:= 0;
SDLNet_AddSocket(fds, IPCSock);

while SDLNet_CheckSockets(fds, 0) > 0 do
      begin
      i:= SDLNet_TCP_Recv(IPCSock, @buf[1], 255);
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
//WriteLnToConsole(s);
if s[0]>#251 then s[0]:= #251;
PLongWord(@s[Succ(byte(s[0]))])^:= GameTicks;
{$IFDEF DEBUGFILE}AddFileLog('IPC send: '+s);{$ENDIF}
inc(s[0],4);
SDLNet_TCP_Send(IPCSock, @s, Succ(byte(s[0])))
end;

procedure SendIPCAndWaitReply(s: shortstring);
begin
SendIPC(s);
SendIPC('?');
isPonged:= false;
repeat
   IPCCheckSock;
   SDL_Delay(1)
until isPonged
end;

procedure NetGetNextCmd;
var tmpflag: boolean;
begin
while (cmdcurpos <= cmdendpos)and(extcmd[cmdcurpos].cmd = 's') do
      begin
      WriteLnToConsole('> ' + copy(extcmd[cmdcurpos].str, 2, Pred(extcmd[cmdcurpos].len)));
      AddCaption('> ' + copy(extcmd[cmdcurpos].str, 2, Pred(extcmd[cmdcurpos].len)), $FFFFFF, capgrpNetSay);
      inc(cmdcurpos)
      end;
         
if cmdcurpos <= cmdendpos then
   if GameTicks > extcmd[cmdcurpos].Time then
      outerror('oops, queue error. in buffer: '+extcmd[cmdcurpos].cmd+' ('+inttostr(GameTicks)+' > '+inttostr(extcmd[cmdcurpos].Time)+')', true);

tmpflag:= true;
while (cmdcurpos <= cmdendpos)and(GameTicks = extcmd[cmdcurpos].Time) do
   begin
   case extcmd[cmdcurpos].cmd of
        'L': ParseCommand('/+left');
        'l': ParseCommand('/-left');
        'R': ParseCommand('/+right');
        'r': ParseCommand('/-right');
        'U': ParseCommand('/+up');
        'u': ParseCommand('/-up');
        'D': ParseCommand('/+down');
        'd': ParseCommand('/-down');
        'A': ParseCommand('/+attack');
        'a': ParseCommand('/-attack');
        'S': ParseCommand('/switch');
        'j': ParseCommand('/ljump');
        'J': ParseCommand('/hjump');
        'N': begin
             tmpflag:= false;
             {$IFDEF DEBUGFILE}AddFileLog('got cmd "N": time '+inttostr(extcmd[cmdcurpos].Time)){$ENDIF}
             end;
        'p': begin
             TargetPoint.X:= extcmd[cmdcurpos].X;
             TargetPoint.Y:= extcmd[cmdcurpos].Y;
             ParseCommand('/put')
             end;
        'P': begin
             CursorPoint.X:= extcmd[cmdcurpos].X + WorldDx;
             CursorPoint.Y:= extcmd[cmdcurpos].Y + WorldDy;
             end;
        '1'..'5': ParseCommand('/timer ' + extcmd[cmdcurpos].cmd);
        #128..#134: ParseCommand('/slot ' + char(byte(extcmd[cmdcurpos].cmd) - 79))
        end;
   inc(cmdcurpos)
   end;
isInLag:= (cmdcurpos > cmdendpos) and tmpflag
end;

procedure LoadFortPoints(Fort: shortstring; isRight: boolean; Count: Longword);
const cMAXFORTPOINTS = 20;
var f: textfile;
    i, t: integer;
    cnt: Longword;
    ar: array[0..Pred(cMAXFORTPOINTS)] of TPoint;
    p: TPoint;
begin
if isRight then Fort:= Pathz[ptForts] + Fort + 'R.txt'
           else Fort:= Pathz[ptForts] + Fort + 'L.txt';
WriteToConsole(msgLoading + Fort + ' ');
{$I-}
AssignFile(f, Fort);
Reset(f);
cnt:= 0;
while not (eof(f) or (cnt = cMAXFORTPOINTS)) do
      begin
      Readln(f, ar[cnt].x, ar[cnt].y);
      if isRight then inc(ar[cnt].x, 1024);
      inc(cnt);
      end;
Closefile(f);
{$I+}
TryDo(IOResult = 0, msgFailed, true);
WriteLnToConsole(msgOK);
TryDo(Count < cnt, 'Fort doesn''t contain needed amount of spawn points', true);
for i:= 0 to Pred(cnt) do
    begin
    t:= GetRandom(cnt);
    if i <> t then
       begin
       p:= ar[i];
       ar[i]:= ar[t];
       ar[t]:= p
       end
    end;
for i:= 0 to Pred(Count) do
    AddHHPoint(ar[i].x, ar[i].y);
end;

end.

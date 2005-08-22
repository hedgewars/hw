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

unit fIPC;{$J+}
interface
uses Messages, WinSock, Windows;
const
      IN_IPC_PORT  = 46631;
      WM_ASYNC_IPCEVENT = WM_USER + 1;

function InitIPCServer: boolean;
procedure SendIPC(s: shortstring);
procedure IPCEvent(sock: TSocket; lParam: LPARAM);

var DemoFileName: string;

implementation
uses fGUI, fMisc, fNet, uConsts, fGame, SysUtils, fConsts;

var hIPCListenSockTCP : TSocket = INVALID_SOCKET;
    hIPCServerSocket  : TSocket = INVALID_SOCKET;

function InitIPCServer: boolean;
var myaddrTCP: TSockAddrIn;
    t: integer;
begin
Result:= false;
hIPCListenSockTCP:= socket(AF_INET, SOCK_STREAM, 0);
myaddrTCP.sin_family      := AF_INET;
myaddrTCP.sin_addr.s_addr := $0100007F;
myaddrTCP.sin_port        := htons(IN_IPC_PORT);
t:= sizeof(TSockAddrIn);
if (   bind(hIPCListenSockTCP, myaddrTCP, t) <> 0) then exit;
if ( listen(hIPCListenSockTCP, 1)            <> 0) then exit;
WSAAsyncSelect(hIPCListenSockTCP, hwndMain, WM_ASYNC_IPCEVENT, FD_ACCEPT or FD_READ or FD_CLOSE);
Result:= true
end;

procedure SendIPC(s: shortstring);
begin
if hIPCServerSocket <> INVALID_SOCKET then
   begin
   send(hIPCServerSocket, s[0], Succ(byte(s[0])), 0);
   if fWriteDemo then
      if not((Length(s) > 5) and (copy(s, 1, 5) = 'ebind')) then
         WriteRawToDemo(s)
   end;
end;

procedure SendConfig;
const cBufLength = $10000;
{$INCLUDE revision.inc}
var f: file;
    buf: array[0..Pred(cBufLength)] of byte;
    i, t: integer;
    s: shortstring;
    sbuf:string;
begin
SendIPC('WFrontend svn ' + cRevision);
SendIPC(format('e$sound %d',[SendMessage(HSetSndCheck, BM_GETCHECK, 0, 0)]));
case GameType of
    gtLocal: begin
             SendIPC(format('e$gmflags %d',[0]));
             SendIPC('eaddteam');
             ExecCFG(Pathz[ptTeams] + 'unC0Rr.cfg');
             SendIPC('ecolor 65535');
             SendIPC('eadd hh0 0');
             SendIPC('eadd hh1 0');
             SendIPC('eadd hh2 0');
             SendIPC('eadd hh3 0');
             SendIPC('eaddteam');
             ExecCFG(Pathz[ptTeams] + 'test.cfg');
             SendIPC('eadd hh0 1');
             SendIPC('eadd hh1 1');
             SendIPC('eadd hh2 1');
             SendIPC('eadd hh3 1');
             SendIPC('ecolor 16776960');
             end;
     gtDemo: begin
             AssignFile(f, DemoFileName);
             {$I-}
             Reset(f, 1);
             if IOResult <> 0 then
                begin
                SendIPC('ECannot open file: "' + Pathz[ptDemos] + sbuf + '"');
                exit;
                end;
             s:= 'TD';
             s[0]:= #6;
             PLongWord(@s[3])^:= FileSize(f);
             SendIPC(s);  // посылаем тип игры - демо и размер демки
             BlockRead(f, buf, cBufLength, t); // вырезаем seed
             i:= 0;
             while (chr(buf[i]) <> cDemoSeedSeparator)and (i < t) do inc(i);
             inc(i);
             // посылаем остаток файла
             repeat
             while i < t do
                   begin
                   CopyMemory(@s[0], @buf[i], Succ(buf[i]));
                   SendIPC(s);
                   inc(i, buf[i]);
                   inc(i)
                   end;
             i:= 0;
             BlockRead(f, buf, cBufLength, t);
             until t = 0;
             Closefile(f);
             {$I+}
             end;
     gtNet: SendNet('C');
     end;
end;

procedure ParseIPCCommand(s: shortstring);
begin
case s[1] of
     '?': if GameType = gtNet then SendNet('?') else SendIPC('!');
     'C': SendConfig;
     else if GameType = gtNet then SendNet(s);
          if fWriteDemo and (s[1] <> '+') then WriteRawToDemo(s)
     end;
end;

procedure IPCEvent(sock: TSocket; lParam: LPARAM);
const sipc: string = '';
var WSAEvent: word;
    i: integer;
    buf: array[0..255] of byte;
    s: shortstring absolute buf;
begin
WSAEvent:= WSAGETSELECTEVENT(lParam);
case WSAEvent of
   FD_CLOSE: begin
             closesocket(sock);
             hIPCServerSocket:= INVALID_SOCKET;
             exit
             end;
    FD_READ: begin
             repeat
             i:= recv(sock, buf[1], 255, 0);
             if i > 0 then
                begin
                buf[0]:= i;
                sipc:= sipc + s;
                SplitStream2Commands(sipc, ParseIPCCommand);
                end;
             until i < 1;
             end;
 FD_ACCEPT:  hIPCServerSocket:= accept(hIPCListenSockTCP, nil, nil);
   end
end;

end.

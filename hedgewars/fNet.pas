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

unit fNet;{$J+}
interface
uses Messages, WinSock, Windows;
const
      NET_PORT = 46632;
      WM_ASYNC_NETEVENT = WM_USER + 2;

procedure SendNet(s: shortstring);
procedure SendNetAndWait(s: shortstring);
procedure NetConnect;
procedure NetEvent(sock: TSocket; lParam: LPARAM);

var
    TeamCount: LongWord;

implementation
uses fGUI, fMisc, fGame, fIPC, uConsts, IniFiles, SysUtils;
var
    hNetClientSocket: TSocket = INVALID_SOCKET;
    isPonged: boolean;

procedure SendNet(s: shortstring);
begin
if hNetClientSocket <> INVALID_SOCKET then
   send(hNetClientSocket, s[0], Succ(byte(s[0])), 0)
end;

procedure SendNetAndWait(s: shortstring);
begin
SendNet(s);
SendNet('?');
isPonged:= false;
repeat
  ProcessMessages;
  sleep(1)
until isPonged
end;

procedure ParseNetCommand(s: shortstring);
var sbuf : string;
begin
case s[1] of
     '?': SendNet('!');
     'i': begin
          sbuf:= GetWindowTextStr(HNetNameEdit);
          SendNet('n' + sbuf);;
          end;
     'z': begin
          seed:= copy(s, 2, length(s) - 1)
          end;
     'G': begin
          GameType:= gtNet;
          GameStart
          end;
     '@': ExecCFG(Pathz[ptTeams] + 'unC0Rr.cfg');
     '!': begin
          isPonged:= true;
          SendIPC('!');
          end;
     'T': TeamCount:= PLongWord(@s[2])^
     else SendIPC(s) end;
end;

procedure NetConnect;
var rmaddr: SOCKADDR_IN;
    inif: TIniFile;
    sbuf1,sbuf2: string;
begin
sbuf1:= GetWindowTextStr(HNetIPEdit);
inif:= TIniFile.Create(ExtractFilePath(ParamStr(0))+'hw.ini');
inif.WriteString('Net','IP' , sbuf1);
sbuf2:= GetWindowTextStr(HNetNameEdit);
inif.WriteString('Net','Nick', sbuf2);
inif.Free;
SetWindowText(HNetConnectionStatic,'Connecting...');
rmaddr.sin_family      := AF_INET;
rmaddr.sin_addr.s_addr := inet_addr(PChar(sbuf1));
rmaddr.sin_port        := htons(NET_PORT);
hNetClientSocket:= socket(AF_INET, SOCK_STREAM, 0);
if INVALID_SOCKET = hNetClientSocket then
   begin
   MessageBox(hwndMain,'connect failed','failed',MB_OK);
   SetWindowText(HNetConnectionStatic,'Error on connect');
   exit
   end;
WSAAsyncSelect(hNetClientSocket, hwndMain, WM_ASYNC_NETEVENT, FD_CONNECT or FD_READ or FD_CLOSE);
connect(hNetClientSocket, rmaddr, sizeof(rmaddr))
end;

procedure NetEvent(sock: TSocket; lParam: LPARAM);
const snet: string = '';
var WSAEvent: word;
    i: integer;
    buf: array[0..255] of byte;
    s: shortstring absolute buf;
begin
WSAEvent:= WSAGETSELECTEVENT(lParam);
case WSAEvent of
   FD_CLOSE: begin
             closesocket(sock);
//           hIPCServerSocket:= INVALID_SOCKET;      гм-гм... FIXME: что-то тут должно быть имхо
             SetWindowText(HNetConnectionStatic, 'Disconnected');
             GameType:= gtLocal
             end;
    FD_READ: begin
             repeat
             i:= recv(sock, buf[1], 255, 0);
             if i > 0 then
                begin
                buf[0]:= i;
                snet:= snet + s;
                SplitStream2Commands(snet, ParseNetCommand);
                end;
             until i < 1
             end;
 FD_CONNECT: begin
             i:= WSAGETSELECTERROR(lParam);
             if i<>0 then
                begin
                closesocket(sock);
                MessageBox(hwndMain,'Error on connect', 'Error', MB_OK);
                SetWindowText(HNetConnectionStatic, 'Error on connect')
                end else
                begin
                SetWindowText(HNetConnectionStatic,'connected');
                GameType:= gtNet
                end;
             end
    end
end;

end.

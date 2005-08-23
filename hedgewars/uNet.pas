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

unit uNet;
interface
uses WinSock, Messages;
const
      IN_NET_PORT  = 46632;
      WM_ASYNC_NETEVENT = WM_USER + 7;

type TCommandHandler = procedure (s: shortstring);

procedure SplitStream2Commands(var ss: string; Handler: TCommandHandler);
procedure SendSock(Socket: TSocket; s: shortstring);
procedure InitServer;
procedure NetSockEvent(sock, lParam: Longword);

var hNetListenSockTCP: TSocket = INVALID_SOCKET;

implementation
uses uServerMisc, uPlayers;

procedure SplitStream2Commands(var ss: string; Handler: TCommandHandler);
var s: shortstring;
begin
while (Length(ss) > 1)and(Length(ss) > byte(ss[1])) do
      begin
      s:= copy(ss, 2, byte(ss[1]));
      Delete(ss, 1, Succ(byte(ss[1])));
      Handler(s)
      end;
end;

procedure SendSock(Socket: TSocket; s: shortstring);
begin
//writeln(socket, '> ', s);
send(Socket, s[0], Succ(byte(s[0])), 0)
end;

procedure InitServer;
var myaddrTCP: TSockAddrIn;
    t: integer;
    stWSADataTCPIP : WSADATA;
begin
TryDo(WSAStartup($0101, stWSADataTCPIP) = 0, 'Error on WSAStartup');
hNetListenSockTCP:= socket(AF_INET, SOCK_STREAM, 0);
myaddrTCP.sin_family      := AF_INET;
myaddrTCP.sin_addr.s_addr := $0;
myaddrTCP.sin_port        := htons(IN_NET_PORT);
t:= sizeof(TSockAddrIn);
TryDo(   bind(hNetListenSockTCP, myaddrTCP, t) = 0, 'Error on bind'  );
TryDo( listen(hNetListenSockTCP, 1)            = 0, 'Error on listen');
WSAAsyncSelect(hNetListenSockTCP, hwndMain, WM_ASYNC_NETEVENT, FD_ACCEPT or FD_READ or FD_CLOSE)
end;

procedure ParseNetCommand(Player: PPlayer; s: shortstring);
begin
case s[1] of
     '?': SendSock(player.socket, '!');
     'n': begin
          player.Name:= copy(s, 2, length(s) - 1);
          Writeln(player.socket, ' now is ', player.Name)
          end;
     'C': SendConfig(player);
     'G': SendAll('G');
     'T': begin
          s[0]:= #5;
          s[1]:= 'T';
          PLongWord(@s[2])^:= GetTeamCount;
          SendSock(player.socket, s)
          end;
     'K': SelectFirstCFGTeam;
     'k': SelectNextCFGTeam;
     'h': ConfCurrTeam(s);
     else SendAllButOne(Player, s) end
end;

procedure NetSockEvent(sock, lParam: Longword);
var i: integer;
    buf: array[0..255] of byte;
    s: shortstring absolute buf;
    WSAEvent: word;
    player: PPlayer;
    sa: TSockAddr;
begin
WSAEvent:= WSAGETSELECTEVENT(lParam);
case WSAEvent of
      FD_ACCEPT: begin
                 i:= sizeof(sa);
                 sock:= accept(hNetListenSockTCP, @sa, @i);
                 Writeln('Connected player ', sock, ' from ', inet_ntoa(sa.sin_addr));
                 AddPlayer(sock);
                 SendSock(sock, 'i')
                 end;
       FD_CLOSE: begin
                 player:= FindPlayerbySock(sock);
                 TryDo(player <> nil, 'FD_CLOSE from unknown player??');
                 Write('Player quit: ');
                 if player.Name[0]=#0 then Writeln('socket ', player.socket)
                                      else Writeln(player.Name);
                 DeletePlayer(player);
                 closesocket(sock);
                 end;
        FD_READ: begin
                 player:= FindPlayerbySock(sock);
                 TryDo(player <> nil, 'FD_READ from unknown player??');
                 repeat
                 i:= recv(sock, buf[1], 255, 0);
                 if i > 0 then
                    begin
                    buf[0]:= i;
                    player.inbuf:= player.inbuf + s;
                    while (Length(player.inbuf) > 1)and(Length(player.inbuf) > byte(player.inbuf[1])) do
                          begin
                          ParseNetCommand(player, copy(player.inbuf, 2, byte(player.inbuf[1])));
                          Delete(player.inbuf, 1, Succ(byte(player.inbuf[1])))
                          end;
                    end;
                 until i < 1;
                 end
     end
end;


end.

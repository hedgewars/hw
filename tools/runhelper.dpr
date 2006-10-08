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

program runhelper;
{$APPTYPE CONSOLE}
{$J+}
uses SDLh;
var servsock, clsock: PTCPSocket;
    ip: TIPAddress;
    event: TSDL_Event;

procedure Send(s: shortstring);
begin
SDLNet_TCP_Send(clsock, @s, succ(byte(s[0])))
end;

procedure SendConfig;
begin
Send('TL');
Send('e$gmflags 1');
Send('eseed -=31337=-');
Send('etheme steel');
Send('eaddteam');
Send('ename team "C0CuCKAzZz"');
Send('ename hh0 "hh0"');
Send('ename hh1 "hh1');
Send('ename hh2 "hh2');
Send('ename hh3 "hh3');
Send('ename hh4 "hh4');
Send('ename hh5 "Just hedgehog"');
Send('ename hh6 "hh5');
Send('ename hh7 "hh6');
Send('ebind left  "+left"');
Send('ebind right "+right"');
Send('ebind up    "+up"');
Send('ebind down  "+down"');
Send('ebind F1  "slot 1"');
Send('ebind F2  "slot 2"');
Send('ebind F3  "slot 3"');
Send('ebind F4  "slot 4"');
Send('ebind F5  "slot 5"');
Send('ebind F6  "slot 6"');
Send('ebind F7  "slot 7"');
Send('ebind F8  "slot 8"');
Send('ebind F10 "quit"');
Send('ebind F11 "capture"');
Send('ebind space     "+attack"');
Send('ebind return    "ljump"');
Send('ebind backspace "hjump"');
Send('ebind tab       "switch"');
Send('ebind 1 "timer 1"');
Send('ebind 2 "timer 2"');
Send('ebind 3 "timer 3"');
Send('ebind 4 "timer 4"');
Send('ebind 5 "timer 5"');
Send('ebind mousel "put"');
Send('egrave "coffin"');
Send('efort "Barrelhouse"');
Send('ecolor 65535');
Send('eadd hh0 0');
Send('eadd hh1 0');
Send('eadd hh2 0');
Send('eadd hh3 0');
Send('eaddteam');
Send('ename team "-= 1 =-"');
Send('ename hh0 "hh0"');
Send('ename hh1 "hh1');
Send('ename hh2 "hh2');
Send('ename hh3 "hh3');
Send('ename hh4 "hh4');
Send('ename hh5 "Just hedgehog"');
Send('ename hh6 "hh5');
Send('ename hh7 "hh6');
Send('egrave Bone');
Send('ecolor 16776960');
Send('eadd hh0 1');
Send('eadd hh1 1');
Send('eadd hh2 1');
Send('eadd hh3 1');
Send('efort Barrelhouse');
end;

procedure ParseCmd(s: shortstring);
begin
case s[1] of
     '?': Send('!');
     'C': SendConfig;
     end;
end;

procedure DoIt;
const ss: string = '';
var s: shortstring;
    i: integer;
begin
i:= SDLNet_TCP_Recv(clsock, @s[1], 255);
if i <= 0  then
   begin
   if i = -1 then exit;
   SDLNet_TCP_Close(clsock);
   clsock:= nil;
   ss:= '';
   exit
   end;
byte(s[0]):= i;
ss:= ss + s;
while (Length(ss) > 1)and(Length(ss) > byte(ss[1])) do
      begin
      s:= copy(ss, 2, byte(ss[1]));
      Delete(ss, 1, Succ(byte(ss[1])));
      ParseCmd(s)
      end;
end;

begin
WriteLn('run hwengine 640 480 16 46631 0 1 ru.txt 128');
SDL_Init(0);
SDLNet_Init;
ip.host:= 0;     
ip.port:= $27B6;
servsock:= SDLNet_TCP_Open(ip);
repeat
  if clsock = nil then
     clsock:= SDLNet_TCP_Accept(servsock);
  if clsock <> nil then
     DoIt;
  SDL_PollEvent(@event);
  SDL_Delay(1)
until event.type_ = SDL_QUITEV;
SDLNet_Quit;
SDL_Quit
end.

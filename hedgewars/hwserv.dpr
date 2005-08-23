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

program hwserv;
{$APPTYPE CONSOLE}
uses
  Windows,
  WinSock,
  Messages,
  uServerMisc in 'uServerMisc.pas',
  uNet, 
  uPlayers in 'uPlayers.pas';

function MainWndProc(hwnd: HWND;  Message: UINT;  wParam: WPARAM;  lParam: LPARAM): LRESULT; stdcall;
begin
case Message of
     WM_CLOSE  : begin
                 PostQuitMessage(0);
                 end;
     WM_ASYNC_NETEVENT: NetSockEvent(wParam, lParam);
     end;
Result:= DefWindowProc(hwnd, Message, wParam,lParam)
end;

procedure DoCreateWindow;
var   wc: WNDCLASS;
begin
FillChar(wc, sizeof(wc), 0);
wc.style         := CS_VREDRAW or CS_HREDRAW;
wc.lpfnWndProc   := @MainWndProc;
wc.hInstance     := hInstance;
wc.lpszClassName := cAppName;
TryDo(RegisterClass(wc) <> 0, 'Cannot register window class');
hwndMain := CreateWindowEx( 0, cAppName, cAppTitle, WS_POPUP,
	                    0, 0,
	                    GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN),
                            0, 0, hInstance, nil);
TryDo(hwndMain <> 0, 'Cannot create window')
end;

procedure ProcessMessages;
var Message: Windows.MSG;
begin
if PeekMessage(Message,0,0,0,PM_REMOVE) then
  if Message.message <> WM_QUIT then
    begin
    TranslateMessage(Message);
    DispatchMessage(Message)
    end else isTerminated:= true
end;

begin
WriteLn('-= Hedgewars server =-');
WriteLn('protocol version ', cProtVer);
DoCreateWindow;
InitServer;
repeat
ProcessMessages;
until isTerminated
end.

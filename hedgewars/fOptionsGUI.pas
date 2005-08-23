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

unit fOptionsGUI;
interface
uses windows,
     messages,SysUtils;

procedure DoCreateOptionsWindow;
procedure ShowOptionsWindow;
procedure DoCreateOptionsControls;

var HOptTeamName, HOptBGStatic : HWND;
    HOptHedgeName : array[0..7] of HWND; 



implementation
uses fGUI,
     fConsts, fMisc;

procedure ShowOptionsWindow;
begin
ShowWindow(hwndOptions,SW_SHOW);
ShowWindow(hwndMain, SW_HIDE);
ShowWindow(HOptTeamName,SW_SHOW)
end;

procedure DoCreateOptionsControls;
var i:integer;
begin
HOptBGStatic  := CreateWindow('STATIC','opt bg img'   ,WS_CHILD or WS_VISIBLE or SS_OWNERDRAW, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN) , hwndOptions, cOptBGStatic, HInstance, nil);
HOptTeamName  := CreateWindow('EDIT','Колючая Команда',WS_CHILD or WS_TABSTOP or WS_VISIBLE, trunc(260 * scrx), trunc(70 *scry), trunc(215* scrx) , trunc(28*scry) , hwndOptions, cOptTeamName, HInstance, nil);
for i := 0 to 7 do
HOptHedgeName[i] := CreateWindow('EDIT',PChar('Йож '+inttostr(i+1)),WS_CHILD or WS_TABSTOP or WS_VISIBLE, trunc(110 * scrx), trunc((102+i*28)*scry), trunc(260* scrx) , trunc(25*scry) , hwndOptions, cOptTeamName, HInstance, nil);
end;

procedure DoCreateOptionsWindow;
var  wc: WNDCLASS;
begin
FillChar(wc, sizeof(wc), 0);
wc.style         := CS_VREDRAW or CS_HREDRAW;
wc.hbrBackground := COLOR_BACKGROUND;
wc.lpfnWndProc   := @MainWndProc;
wc.hInstance     := hInstance;
wc.lpszClassName := cOptionsName;
wc.hCursor := LoadCursor(hwndOptions,IDC_ARROW);
if RegisterClass(wc) = 0 then begin MessageBox(0,'RegisterClass failed for opts wnd','Failed',MB_OK); halt; end;
hwndOptions := CreateWindowEx(0, cOptionsName, cOptionsTitle, WS_POPUP,
	                    0, 0,
	                    GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN),
                            0, 0, hInstance, nil)
end;


end.

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

unit fGUI;
interface
uses Windows;

procedure ProcessMessages;
function GetWindowTextStr(hwnd: HWND): string;
procedure DoControlPress(wParam: WPARAM;  lParam: LPARAM);
procedure DoDrawButton(idCtl: UINT; lpmis: PDrawItemStruct);
procedure LoadGraphics;
procedure DoDestroy;
procedure DoCreateControls;
procedure DoCreateMainWindow;


var hwndMain,hwndOptions: HWND;
var isTerminated: boolean = false;
var //main menu
    bitmap       ,optbmp        ,localbmp      ,netbmp      ,demobmp    ,exitbmp      ,setsbmp      : HBITMAP;
    BackGroundDC ,OptBGroundDC  ,DCLocalGame   ,DCNetGame   ,DCDemoPlay ,DCExitGame   ,DCSettings   : HDC;
                  HLocalGameBtn ,HNetGameBtm ,HDemoBtn   ,HExitGameBtn ,HSettingsBtn, HBGStatic : HWND;
    //other
    HNetIPEdit,HNetIPStatic: HWND;
    HNetNameEdit,HNetNameStatic,HNetConnectionStatic: HWND;
    HNetJoinBtn,HNetBeginBtn,HNetBackBtn:HWND;
    HDemoList,HDemoBeginBtn,HDemoBackBtn,HDemoAllBtn:HWND;
    HSetResEdit,HFullScrCheck,HSetDemoCheck,HSetSndCheck,HSetSaveBtn,HSetBackBtn,HSetShowTeamOptionsBtn:HWND;
    scrx, scry: real;


implementation
uses fConsts, Messages, SysUtils, uConsts, fGame, fNet, fMisc, fOptionsGUI;

function GetWindowTextStr(hwnd: HWND): string;
var i: integer;
begin
i:= GetWindowTextLength(hwnd);
SetLength(Result, i);
GetWindowText(hwnd, PChar(Result), Succ(i))
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

procedure HideMain;
begin
ShowWindow(HLocalGameBtn,SW_HIDE);
ShowWindow(HNetGameBtm,SW_HIDE);
ShowWindow(HDemoBtn,SW_HIDE);
ShowWindow(HSettingsBtn,SW_HIDE);
ShowWindow(HExitGameBtn,SW_HIDE)
end;

procedure ShowMain;
begin
ShowWindow(HLocalGameBtn,SW_SHOW);
ShowWindow(HNetGameBtm,SW_SHOW);
ShowWindow(HDemoBtn,SW_SHOW);
ShowWindow(HSettingsBtn,SW_SHOW);
ShowWindow(HExitGameBtn,SW_SHOW);
SetFocus(HLocalGameBtn)
end;



procedure ShowNetGameMenu;
begin
HideMain;
ShowWindow(HNetIPStatic,SW_SHOW);
ShowWindow(HNetIPEdit,SW_SHOW);
ShowWindow(HNetNameStatic,SW_SHOW);
ShowWindow(HNetNameEdit,SW_SHOW);  
ShowWindow(HNetConnectionStatic,SW_SHOW);
ShowWindow(HNetJoinBtn,SW_SHOW);
ShowWindow(HNetBeginBtn,SW_SHOW);
ShowWindow(HNetBackBtn,SW_SHOW);
SetFocus(HNetJoinBtn)
end;


procedure ShowMainFromNetMenu;
begin
ShowWindow(HNetIPEdit,SW_HIDE);
ShowWindow(HNetIPStatic,SW_HIDE);
ShowWindow(HNetNameEdit,SW_HIDE);
ShowWindow(HNetNameStatic,SW_HIDE);
ShowWindow(HNetConnectionStatic,SW_HIDE);
ShowWindow(HNetJoinBtn,SW_HIDE);
ShowWindow(HNetBeginBtn,SW_HIDE);
ShowWindow(HNetBackBtn,SW_HIDE);
ShowMain
end;


procedure ShowDemoMenu;
var i: integer;
    sr: TSearchRec;
begin
SendMessage(HDemoList, LB_RESETCONTENT, 0, 0);
i:= FindFirst(format('%s*.hwd_%d',[Pathz[ptDemos], cNetProtoVersion]), faAnyFile and not faDirectory, sr);
while i = 0 do
      begin
      SendMessage(HDemoList, LB_ADDSTRING, 0, LPARAM(PChar(sr.Name)));
      i:= FindNext(sr)
      end;
FindClose(sr);

HideMain;

ShowWindow(HDemoList,SW_SHOW);
ShowWindow(HDemoBeginBtn,SW_SHOW);
ShowWindow(HDemoAllBtn,SW_SHOW);
ShowWindow(HDemoBackBtn,SW_SHOW);
SetFocus(HDemoList)
end;

procedure ShowMainFromDemoMenu;
begin
ShowWindow(HDemoList,SW_HIDE);
ShowWindow(HDemoBeginBtn,SW_HIDE);
ShowWindow(HDemoAllBtn,SW_HIDE);
ShowWindow(HDemoBackBtn,SW_HIDE);
ShowMain
end;

procedure ShowSettingsMenu;
begin
HideMain;
ShowWindow(HSetResEdit,SW_SHOW);
ShowWindow(HFullScrCheck,SW_SHOW);
ShowWindow(HSetDemoCheck,SW_SHOW);
ShowWindow(HSetSndCheck,SW_SHOW);
ShowWindow(HSetSaveBtn,SW_SHOW);
ShowWindow(HSetBackBtn,SW_SHOW);
ShowWindow(HSetShowTeamOptionsBtn,SW_SHOW);
SetFocus(HSetResEdit)
end;

procedure ShowMainFromSettings;
begin
ShowWindow(HSetResEdit,SW_HIDE);
ShowWindow(HFullScrCheck,SW_HIDE);
ShowWindow(HSetDemoCheck,SW_HIDE);
ShowWindow(HSetSndCheck,SW_HIDE);
ShowWindow(HSetSaveBtn,SW_HIDE);
ShowWindow(HSetBackBtn,SW_HIDE);
ShowWindow(HSetShowTeamOptionsBtn,SW_HIDE);
ShowMain
end;

procedure DoControlPress(wParam: WPARAM;  lParam: LPARAM);
begin
case LOWORD(wParam) of
    cLocalGameBtn : StartLocalGame;
    cNetGameBtn   : ShowNetGameMenu;
    cDemoBtn      : ShowDemoMenu;
    cSettingsBtn  : ShowSettingsMenu;
    cExitGameBtn  : Halt;
    cNetBackBtn   : ShowMainFromNetMenu;
    cNetJoinBtn   : NetConnect;
    cNetBeginBtn  : StartNetGame;
    cDemoBackBtn  : ShowMainFromDemoMenu;
    cDemoAllBtn   : MessageBeep(0);//PlayAllDemos;
    cDemoBeginBtn : StartDemoView;
    cSetSaveBtn   : SaveSettings;
    cSetBackBtn   : ShowMainFromSettings;
    cSetShowTeamOptions : ShowOptionsWindow;
    end
end;

procedure DoDrawButton(idCtl: UINT; lpmis: PDrawItemStruct);
begin
case lpmis.CtlID of
  cLocalGameBtn: StretchBlt(lpmis.hDC,0,0,trunc(309*scrx),trunc(22*scry),DCLocalGame,0,0,309,22,SRCCOPY);
    cNetGameBtn: StretchBlt(lpmis.hDC,0,0,trunc(272*scrx),trunc(22*scry),DCNetGame  ,0,0,272,22,SRCCOPY);
       cDemoBtn: StretchBlt(lpmis.hDC,0,0,trunc(181*scrx),trunc(22*scry),DCDemoPlay ,0,0,181,22,SRCCOPY);
   cSettingsBtn: StretchBlt(lpmis.hDC,0,0,trunc(147*scrx),trunc(22*scry),DCSettings ,0,0,147,22,SRCCOPY);
   cExitGameBtn: StretchBlt(lpmis.hDC,0,0,trunc(272*scrx),trunc(22*scry),DCExitGame ,0,0,272,22,SRCCOPY);
      cBGStatic: StretchBlt(lpmis.hDC,0,0,trunc(1024*scrx),trunc(768*scry),BackGroundDC,0,0,1024,768,SRCCOPY);
   cOptBGStatic: StretchBlt(lpmis.hDC,0,0,trunc(1024*scrx),trunc(768*scry),OptBGroundDC,0,0,1024,768,SRCCOPY);
     end
end;

procedure LoadGraphics;
begin
scrx :=  GetSystemMetrics(SM_CXSCREEN)/1024;
scry :=  GetSystemMetrics(SM_CYSCREEN)/768;
LoadOwnerBitmap(bitmap, cGFXPath + 'front.bmp',      BackGroundDC,hwndMain);
LoadOwnerBitmap(optbmp, cGFXPath + 'TeamSettings.bmp',OptBGroundDC,hwndOptions);
LoadOwnerBitmap(localbmp,cGFXPath + 'startlocal.bmp', DCLocalGame,cLocalGameBtn);
LoadOwnerBitmap(netbmp,  cGFXPath + 'startnet.bmp',   DCNetGame,  cNetGameBtn);
LoadOwnerBitmap(demobmp, cGFXPath + 'playdemo.bmp',   DCDemoPlay, cDemoBtn);
LoadOwnerBitmap(setsbmp, cGFXPath + 'settings.bmp',   DCSettings, cSettingsBtn);
LoadOwnerBitmap(exitbmp, cGFXPath + 'exit.bmp',       DCExitGame, cExitGameBtn);
end;

procedure DoDestroy;
begin
DeleteObject(localbmp);
DeleteObject(optbmp);
DeleteObject(bitmap);
DeleteObject(netbmp);
DeleteObject(demobmp);
DeleteObject(setsbmp);
DeleteObject(bitmap);
DeleteDC(DCLocalGame);
DeleteDC(DCNetGame);
DeleteDC(DCDemoPlay);
DeleteDC(DCSettings);
DeleteDC(BackGroundDC);
DeleteDC(OptBGroundDC)
end;

procedure DoCreateControls;
begin
HBGStatic      := CreateWindow('STATIC','bg image static'  ,WS_CHILD or WS_VISIBLE or SS_OWNERDRAW, 0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN), hwndMain, cBGStatic, HInstance, nil);
/// main menu ///
HLocalGameBtn  := CreateWindow('button','local game button',WS_CHILD or WS_VISIBLE or BS_OWNERDRAW, trunc(510 * scrx), trunc(400 *scry), trunc(309* scrx) , trunc(22*scry) , hwndMain , cLocalGameBtn, HInstance,  nil );
HNetGameBtm    := CreateWindow('button',  'net game button',WS_CHILD or WS_VISIBLE or BS_OWNERDRAW, trunc(530 * scrx), trunc(450 *scry), trunc(272* scrx) , trunc(22*scry) , hwndMain ,   cNetGameBtn, HInstance,  nil );
HDemoBtn       := CreateWindow('button', 'play demo button',WS_CHILD or WS_VISIBLE or BS_OWNERDRAW, trunc(570 * scrx), trunc(500 *scry), trunc(181* scrx) , trunc(22*scry) , hwndMain ,      cDemoBtn, HInstance,  nil );
HSettingsBtn   := CreateWindow('button', 'settings  button',WS_CHILD or WS_VISIBLE or BS_OWNERDRAW, trunc(590 * scrx), trunc(550 *scry), trunc(147* scrx) , trunc(22*scry) , hwndMain ,  cSettingsBtn, HInstance,  nil );
HExitGameBtn   := CreateWindow('button', 'exit game button',WS_CHILD or WS_VISIBLE or BS_OWNERDRAW, trunc(530 * scrx), trunc(600 *scry), trunc(272* scrx) , trunc(22*scry) , hwndMain ,  cExitGameBtn, HInstance,  nil );
/// local menu ///
/// net menu ///
HNetIPEdit     := CreateWindow('EDIT', '255.255.255.255'   ,WS_CHILD or WS_TABSTOP,                     trunc(570* scrx), trunc(400*scry) , 150 , 16 , hwndMain ,  cNetIpEdit,     HInstance,  nil );
HNetIPStatic   := CreateWindow('STATIC','IP :'             ,WS_CHILD or SS_SIMPLE,                      trunc(520* scrx), trunc(400*scry) , 50  , 16 , hwndMain ,  cNetIpStatic,   HInstance,  nil );
HNetNameEdit   := CreateWindow('EDIT', 'Hedgewarrior'      ,WS_CHILD or WS_TABSTOP,                     trunc(570* scrx), trunc(420*scry) , 150 , 16 , hwndMain ,  cNetNameEdit,   HInstance,  nil );
HNetNameStatic := CreateWindow('STATIC','Name : '          ,WS_CHILD or SS_SIMPLE,                      trunc(520* scrx), trunc(420*scry) , 50  , 16 , hwndMain ,  cNetNameStatic, HInstance,  nil );
HNetConnectionStatic
               := CreateWindow('STATIC','not connected'    ,WS_CHILD,                                   trunc(520* scrx), trunc(450*scry) , 90 , 16 , hwndMain ,  cNetConnStatic,  HInstance,  nil );
HNetJoinBtn    := CreateWindow('BUTTON','Join Game'        ,WS_CHILD or BS_FLAT or WS_TABSTOP,          trunc(520* scrx), trunc(550*scry) , 90 , 20 , hwndMain ,  cNetJoinBtn,     HInstance,  nil );
HNetBeginBtn   := CreateWindow('BUTTON','Begin Game'       ,WS_CHILD or BS_FLAT or WS_TABSTOP,          trunc(520* scrx), trunc(575*scry) , 90 , 20 , hwndMain ,  cNetBeginBtn,    HInstance,  nil );
HNetBackBtn    := CreateWindow('BUTTON','Back'             ,WS_CHILD or BS_FLAT or WS_TABSTOP,          trunc(520* scrx), trunc(600*scry) , 90 , 20 , hwndMain ,  cNetBackBtn,     HInstance,  nil );
/// demo menu ///
HDemoList      := CreateWindow('LISTBOX',''                ,WS_CHILD or WS_TABSTOP, trunc(530* scrx),   trunc(400*scry) , trunc(200* scrx), trunc(200*scry), hwndMain,  cDemoList, HInstance,  nil );
HDemoBeginBtn  := CreateWindow('BUTTON','Play demo'        ,WS_CHILD or BS_FLAT or WS_TABSTOP,          trunc(750* scrx), trunc(400*scry) , 100 , 20 , hwndMain ,  cDemoBeginBtn,   HInstance,  nil );
HDemoAllBtn    := CreateWindow('BUTTON','Play all demos'   ,WS_CHILD or BS_FLAT or WS_TABSTOP,          trunc(750* scrx), trunc(425*scry) , 100 , 20 , hwndMain ,  cDemoAllBtn,     HInstance,  nil );
HDemoBackBtn   := CreateWindow('BUTTON','Back'             ,WS_CHILD or BS_FLAT or WS_TABSTOP,          trunc(750* scrx), trunc(450*scry) , 100 , 20 , hwndMain ,  cDemoBackBtn,    HInstance,  nil );

/// settings menu ///
HSetResEdit    := CreateWindow('COMBOBOX', ''              ,WS_CHILD or CBS_DROPDOWNLIST or WS_TABSTOP, trunc(530* scrx), trunc(420*scry) , 150 , 100 , hwndMain ,  cSetResEdit,   HInstance,  nil );

SendMessage(HSetResEdit, CB_ADDSTRING, 0, LPARAM(PChar('640x480')));
SendMessage(HSetResEdit, CB_ADDSTRING, 0, LPARAM(PChar('800x600')));
SendMessage(HSetResEdit, CB_ADDSTRING, 0, LPARAM(PChar('1024x768')));
SendMessage(HSetResEdit, CB_ADDSTRING, 0, LPARAM(PChar('1280x1024')));

HFullScrCheck  := CreateWindow('BUTTON','Fullscreen'       ,WS_CHILD or BS_AUTOCHECKBOX or WS_TABSTOP,  trunc(530* scrx), trunc(450*scry) , 110 , 20 , hwndMain ,  cSetFScrCheck,  HInstance,  nil );
HSetDemoCheck  := CreateWindow('BUTTON','Record Demo'      ,WS_CHILD or BS_AUTOCHECKBOX or WS_TABSTOP,  trunc(530* scrx), trunc(475*scry) , 110 , 20 , hwndMain ,  cSetDemoCheck,  HInstance,  nil );
HSetSndCheck   := CreateWindow('BUTTON','Enable Sound'     ,WS_CHILD or BS_AUTOCHECKBOX or WS_TABSTOP,  trunc(530* scrx), trunc(500*scry) , 110 , 20 , hwndMain ,  cSetSndCheck,   HInstance,  nil );
HSetSaveBtn    := CreateWindow('BUTTON','Save Settings'    ,WS_CHILD or BS_FLAT or WS_TABSTOP,          trunc(530* scrx), trunc(580*scry) , 100 , 20 , hwndMain ,  cSetSaveBtn,    HInstance,  nil );
HSetBackBtn    := CreateWindow('BUTTON','Back'             ,WS_CHILD or BS_FLAT or WS_TABSTOP,          trunc(730* scrx), trunc(580*scry) , 90  , 20 , hwndMain ,  cSetBackBtn,    HInstance,  nil );
HSetShowTeamOptionsBtn    := CreateWindow('BUTTON','Show Team Options' ,WS_CHILD or BS_FLAT or WS_TABSTOP, trunc(700* scrx), trunc(420*scry) , 140  , 20 , hwndMain ,  cSetShowTeamOptions,    HInstance,  nil );
end;

procedure DoCreateMainWindow;
var  wc: WNDCLASS;
begin
FillChar(wc, sizeof(wc), 0);
wc.style         := CS_VREDRAW or CS_HREDRAW;
wc.hbrBackground := COLOR_BACKGROUND;
wc.lpfnWndProc   := @MainWndProc;
wc.hInstance     := hInstance;
wc.lpszClassName := cAppName;
wc.hCursor := LoadCursor(hwndMain,IDC_ARROW);
if RegisterClass(wc) = 0 then begin MessageBox(0,'RegisterClass failed for main wnd','Failed',MB_OK); halt; end;
hwndMain := CreateWindowEx( 0, cAppName, cAppTitle, WS_POPUP,
	                    0, 0,
	                    GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN),
                            0, 0, hInstance, nil);

ShowWindow(hwndMain,SW_SHOW);
UpdateWindow(hwndMain)
end;


end.

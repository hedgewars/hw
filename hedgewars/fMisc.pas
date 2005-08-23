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

unit fMisc;
{$J+}
interface
uses uConsts, Windows;
const
      fWriteDemo: boolean = false;
type
      TGameType = (gtLocal, gtNet, gtDemo);
      TCommandHandler = procedure (s: shortstring);

procedure ExecCFG(FileName: String);
procedure AssignDemoFile(Filename: shortstring);
procedure WriteRawToDemo(s: shortstring);
procedure WriteStrToDemo(s: shortstring);
procedure CloseDemoFile;
procedure GenRandomSeed;
procedure SaveSettings;
procedure SplitStream2Commands(var ss: string; Handler: TCommandHandler);
function MainWndProc(hwnd: HWND;  Message: UINT;  wParam: WPARAM;  lParam: LPARAM): LRESULT; stdcall;
procedure LoadOwnerBitmap(var bmp: HBITMAP; name: string; var dc: HDC; owner:cardinal );
procedure DoInit;
procedure InitWSA;

var
    seed: shortstring;
    GameType: TGameType;

implementation
uses fIPC, uRandom, IniFiles, SysUtils, Messages, fGUI, fNet, WinSock, fOptionsGUI;
var fDemo: file;

procedure ExecCFG(FileName: String);
var f: textfile;
    s: shortstring;
begin
AssignFile(f, FileName);
{$I-}
Reset(f);
{$I+}
if IOResult<>0 then SendIPC('ECannot open file: "' + FileName + '"');
while not eof(f) do
      begin
      ReadLn(f, s);
      if (s[0]<>#0)and(s[1]<>';') then SendIPC('e' + s);
      end;
CloseFile(f)
end;

procedure AssignDemoFile(Filename: shortstring);
begin
Assign(fDemo, Filename);
Rewrite(fDemo, 1)
end;

procedure WriteRawToDemo(s: shortstring);
begin
if not fWriteDemo then exit;
BlockWrite(fDemo, s[0], Succ(byte(s[0])))
end;

procedure WriteStrToDemo(s: shortstring);
begin
if not fWriteDemo then exit;
BlockWrite(fDemo, s[1], byte(s[0]))
end;

procedure CloseDemoFile;
begin
CloseFile(fDemo)
end;

procedure GenRandomSeed;
var i: integer;
begin
seed[0]:= chr(7 + GetRandom(6));
for i:= 1 to byte(seed[0]) do seed[i]:= chr(byte('A') + GetRandom(26));
seed:= '('+seed+')'
end;

procedure SaveSettings;
var inif: TIniFile;
begin
inif:= TIniFile.Create(ExtractFilePath(ParamStr(0))+'hw.ini');
inif.WriteInteger('Misc', 'ResIndex', SendMessage(HSetResEdit, CB_GETCURSEL, 0, 0));
inif.WriteInteger('Misc', 'EnableSound', SendMessage(HSetSndCheck, BM_GETCHECK, 0, 0));
inif.WriteInteger('Misc', 'Fullscreen', SendMessage(HFullScrCheck, BM_GETCHECK, 0, 0));
inif.UpdateFile;
inif.Free
end;

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

function MainWndProc(hwnd: HWND;  Message: UINT;  wParam: WPARAM;  lParam: LPARAM): LRESULT; stdcall;
begin
case Message of
     WM_ASYNC_IPCEVENT: IPCEvent(wParam, lParam);
     WM_ASYNC_NETEVENT: NetEvent(wParam, lParam);
     WM_COMMAND : DoControlPress(wParam, lParam);
     WM_DRAWITEM: DoDrawButton(wParam,PDRAWITEMSTRUCT(lParam));
     WM_CLOSE   : PostQuitMessage(0);
     WM_DESTROY : if hwnd = hwndMain then DoDestroy
     end;
Result:= DefWindowProc(hwnd, Message, wParam,lParam)
end;

procedure LoadOwnerBitmap(var bmp: HBITMAP; name: string; var dc: HDC; owner:cardinal );
begin
bmp := LoadImage(0,PChar(name), IMAGE_BITMAP,0,0,LR_LOADFROMFILE);
if bmp = 0 then
   begin
   MessageBox(hwndMain, PChar(name + ' not found'), 'damn', MB_OK);
   PostQuitMessage(0);
   end;
dc:=CreateCompatibleDC(GetDC(owner));
SelectObject(dc,bmp);
end;

procedure DoInit;
var sr: TSearchRec;
    i: integer;
    inif: TIniFile;
    p: TPoint;
begin
GetCursorPos(p);
SetRandomParams(IntToStr(GetTickCount), IntToStr(p.X)+'(ρευσ)'+IntToStr(p.Y));
i:= FindFirst('Data\Maps\*', faDirectory, sr);
while i=0 do
      begin
      if sr.Name[1]<>'.' then ;//LBMaps.Items.Add(sr.Name);
      i:= FindNext(sr)
      end;
FindClose(sr);

inif:= TIniFile.Create(ExtractFilePath(ParamStr(0))+'hw.ini');
i:= inif.ReadInteger('Misc', 'ResIndex', 0);
if inif.ReadBool('Misc', 'EnableSound', true) then SendMessage(HSetSndCheck,BM_SETCHECK,BST_CHECKED,0);
if inif.ReadBool('Misc', 'Fullscreen', true) then SendMessage(HFullScrCheck,BM_SETCHECK,BST_CHECKED,0);
if (i>=0)and(i<=3) then SendMessage(HSetResEdit,CB_SETCURSEL,i,0);
SetWindowText(HNetIPEdit,PChar(inif.ReadString('Net','IP'  , ''       )));
SetWindowText(HNetNameEdit,PChar(inif.ReadString('Net','Nick', 'Unnamed')));
inif.Free;
SendMessage(HSetDemoCheck, BM_SETCHECK, BST_CHECKED, 0);
end;

procedure InitWSA;
var stWSADataTCPIP: WSADATA;
begin
if WSAStartup($0101, stWSADataTCPIP)<>0 then
   begin
   MessageBox(0, 'WSAStartup error !', 'NET ERROR!!!', 0);
   halt
   end;
if not InitIPCServer then
   begin
   MessageBox(0, 'Error on init IPC server!', 'IPC Error', 0);
   halt
   end
end;


end.

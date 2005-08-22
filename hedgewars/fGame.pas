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

unit fGame;
interface
uses Windows;

procedure GameStart;
procedure StartNetGame;
procedure StartDemoView;
procedure StartLocalGame;

implementation
uses fMisc, fGUI, uConsts, uRandom, Messages, fConsts, SysUtils, fIPC, fNet;
const
    fmCreate         = $FFFF;
    fmOpenRead       = $0000;
    fmOpenWrite      = $0001;
    fmOpenReadWrite  = $0002;

var
    MapPoints: array[0..19] of TPoint;

function GetNextLine(var f: textfile): string;
begin
repeat
  Readln(f, Result)
until (Length(Result)>0)and(Result[1] <> '#')
end;

function GetThemeBySeed: string;
var f: text;
    i, n, t: integer;
begin
Result:= '';
n:= 37;
for i:= 1 to Length(seed) do
    n:= (n shl 1) xor byte(seed[i]) xor n;
FileMode:= fmOpenRead;
AssignFile(f, Pathz[ptThemes] + 'themes.cfg');
{$I-}
Reset(f);
val(GetNextLine(f), i, t);
if i > 0 then
   begin
   n:= n mod i;
   for i:= 0 to n do Result:= GetNextLine(f)
   end;
CloseFile(f);
{$I+}
FileMode:= fmOpenReadWrite;
if IOResult <> 0 then
   begin
   MessageBox(hwndMain,PChar(String('Missing, corrupted or cannot access critical file'#13#10+Pathz[ptThemes] + 'themes.cfg')),'Ahctung!!!',MB_OK);
   exit
   end
end;

function ExecAndWait(FileName:String; Visibility : integer): Cardinal;
var WorkDir: String;
    StartupInfo:TStartupInfo;
    ProcessInfo:TProcessInformation;
begin
GetDir(0, WorkDir);
FillChar(StartupInfo, Sizeof(StartupInfo), 0);
with StartupInfo do
     begin
     cb:= Sizeof(StartupInfo);
     dwFlags:= STARTF_USESHOWWINDOW;
     wShowWindow:= Visibility
     end;
if not CreateProcess(nil, PChar(FileName), nil, nil,
                     false, CREATE_DEFAULT_ERROR_MODE or CREATE_NEW_CONSOLE or NORMAL_PRIORITY_CLASS,
                     nil, nil, StartupInfo, ProcessInfo)
   then Result:= High(Cardinal)
   else begin
   while WaitforSingleObject(ProcessInfo.hProcess, 0) = WAIT_TIMEOUT do
         begin
         Sleep(10);
         ProcessMessages;
         end;
   GetExitCodeProcess(ProcessInfo.hProcess, Result);
   CloseHandle(ProcessInfo.hProcess);
   CloseHandle(ProcessInfo.hThread)
   end
end;

procedure GameStart;
var sTheme:string;
begin
if seed = '' then
   begin
   MessageBox(hwndMain,'seed is unknown, but game started','Ahctung!!!',MB_OK);
   exit
   end;
sTheme:= GetThemeBySeed;
//if ExecAndWait('landgen.exe ' + sTheme + ' ' + seed, SW_HIDE) = 0 then
   begin
   ShowWindow(hwndMain, SW_MINIMIZE);
   fWriteDemo:= SendMessage(HSetDemoCheck, BM_GETCHECK, 0, 0) = BST_CHECKED;
   if fWriteDemo then
      begin
      AssignDemoFile('demo.hwd_1');
      inc(seed[0]);
      seed[Length(seed)]:= cDemoSeedSeparator;
      WriteStrToDemo(seed)
      end;
   case ExecAndWait(format('hw.exe %s %s %d %s %d',[Resolutions[SendMessage(HSetResEdit,CB_GETCURSEL,0,0)], sTheme, IN_IPC_PORT, seed, SendMessage(HFullScrCheck,BM_GETCHECK,0,0)]), SW_NORMAL) of
        High(Cardinal): MessageBox(hwndMain,'error executing game','fuck!',MB_OK);
        end;
   if fWriteDemo then
      CloseDemoFile;
   seed:= '';
   ShowWindow(hwndMain, SW_RESTORE)
   end {else begin
   MessageBox(hwndMain,'error executing landgen','fuck!',MB_OK);
   exit
   end; }
end;

procedure StartNetGame;
var i, ii: LongWord;
    s: shortstring;
    p: TPoint;
    sbuf: string;
begin // totally broken
GenRandomSeed;
SendNet('z'+seed);
sbuf:= GetThemeBySeed;
if ExecAndWait(format('landgen.exe %s %s',[sbuf, seed]), SW_HIDE) <> 0 then
   begin
   MessageBox(hwndMain,'error executing landgen','error',MB_OK);
   exit;
   end;
SendNetAndWait('T');
SendNet('K');          {
for i:= 1 to TeamCount do
    begin
    s[0]:= #9;
    s[1]:= 'h';
    for ii:= 0 to 1 do
        begin
        p:= GetRandomMapPoint;
        PLongWord(@s[2])^:= p.X;
        PLongWord(@s[6])^:= p.Y;
        SendNet(s);
        end;
    if i < TeamCount then SendNet('k');
    end;     }
SendNet('G')
end;

procedure StartDemoView;
const cBufSize = 32;
var f: file;
    buf: array[0..pred(cBufSize)] of byte;
    i, t: integer;
begin
if SendMessage(HDemoList,LB_GETCURSEL,0,0) = LB_ERR then//LBDemos.ItemIndex<0 then
   begin
   MessageBox(hwndMain,'Выбери демку слева','hint',MB_OK);
   exit
   end;
GameType:= gtDemo;
i:= SendMessage(HDemoList,LB_GETCURSEL,0,0);
t:= SendMessage(HDemoList, LB_GETTEXTLEN, i, 0);
SetLength(DemoFileName, t);
SendMessage(HDemoList,LB_GETTEXT, i, LPARAM(@DemoFileName[1]));
DemoFileName:= Pathz[ptDemos] + DemoFileName;
AssignFile(f, DemoFileName);
{$I-}
FileMode:= fmOpenRead;
Reset(f, 1);
FileMode:= fmOpenReadWrite;
if IOResult <> 0 then
   begin
   MessageBox(hwndMain,'file not found','error',MB_OK);
   exit;
   end;
BlockRead(f, buf, cBufSize, t); // вырезаем seed
seed:= '';
i:= 0;
while (char(buf[i]) <> cDemoSeedSeparator)and (i < t) do
      begin
      seed:= seed + chr(buf[i]);
      inc(i);
      end;
CloseFile(f);
{$I+}
GameStart
end;

procedure StartLocalGame;
begin
GenRandomSeed;
GameType:= gtLocal;
GameStart
end;



end.

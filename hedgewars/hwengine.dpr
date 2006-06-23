(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

program hwengine;
{$APPTYPE CONSOLE}
uses
  SDLh,
  uConsts in 'uConsts.pas',
  uGame in 'uGame.pas',
  uMisc in 'uMisc.pas',
  uStore in 'uStore.pas',
  uWorld in 'uWorld.pas',
  uIO in 'uIO.pas',
  uGears in 'uGears.pas',
  uConsole in 'uConsole.pas',
  uKeys in 'uKeys.pas',
  uTeams in 'uTeams.pas',
  uSound in 'uSound.pas',
  uRandom in 'uRandom.pas',
  uAI in 'uAI.pas',
  uCollisions in 'uCollisions.pas',
  uLand in 'uLand.pas',
  uLandTemplates in 'uLandTemplates.pas',
  uLandObjects in 'uLandObjects.pas',
  uLandGraphics in 'uLandGraphics.pas',
  uAIMisc in 'uAIMisc.pas',
  uAIAmmoTests in 'uAIAmmoTests.pas',
  uAIActions in 'uAIActions.pas';

{$INCLUDE options.inc}

// also: GSHandlers.inc
//       CCHandlers.inc
//       HHHandlers.inc


procedure OnDestroy; forward;

////////////////////////////////
procedure DoTimer(Lag: integer);  // - обработка таймера
var s: string;
begin
case GameState of
   gsLandGen: begin
              GenMap;
              GameState:= gsStart;
              end;
     gsStart: begin
              AssignHHCoords;
              AddMiscGears;
              AdjustColor(cColorNearBlack);
              AdjustColor(cWaterColor);
              AdjustColor(cWhiteColor);
              StoreLoad;
              AdjustColor(cConsoleSplitterColor);
              ResetKbd;
              SoundLoad;
              PlayMusic;
              GameState:= gsGame
              end;
     gsGame : begin
              ProcessKbd;
              DoGameTick(Lag);
              DrawWorld(Lag, SDLPrimSurface);
              end;
   gsConsole: begin
              DoGameTick(Lag);
              DrawWorld(Lag, SDLPrimSurface);
              DrawConsole(SDLPrimSurface);
              end;
     gsExit : begin
              OnDestroy;
              end;
     end;
SDL_Flip(SDLPrimSurface);
if flagMakeCapture then
   begin
   flagMakeCapture:= false;
   s:= 'hw_' + ParamStr(5) + '_' + inttostr(GameTicks) + '.bmp';
   WriteLnToConsole('Saving ' + s);
   SDL_SaveBMP_RW(SDLPrimSurface, SDL_RWFromFile(PChar(s), 'wb'), 1)
   end;
end;

////////////////////
procedure OnDestroy;   // - очищаем память
begin
{$IFDEF DEBUGFILE}AddFileLog('Freeing resources...');{$ENDIF}
if isSoundEnabled then ReleaseSound;
StoreRelease;
CloseIPC;
TTF_Quit;
SDL_Quit;
halt
end;

///////////////////
procedure MainLoop;
var PrevTime,
    CurrTime: Cardinal;
    event: TSDL_Event;
begin
PrevTime:= SDL_GetTicks;
repeat
while SDL_PollEvent(@event) <> 0 do
      case event.type_ of
           SDL_KEYDOWN: case GameState of
                             gsGame: if event.key.keysym.sym = 96 then
                                        begin
                                        cConsoleYAdd:= cConsoleHeight;
                                        GameState:= gsConsole
                                        end;
                          gsConsole: KeyPressConsole(event.key.keysym.sym);
                             end;
           SDL_QUITEV: isTerminated:= true
           end;
CurrTime:= SDL_GetTicks;
if PrevTime + cTimerInterval <= CurrTime then
   begin
   DoTimer(CurrTime - PrevTime);
   PrevTime:= CurrTime
   end else {sleep(1)};
IPCCheckSock
until isTerminated
end;

////////////////////
procedure GetParams;
var c: integer;
{$IFDEF DEBUGFILE}
    i: integer;
begin
for i:= 0 to ParamCount do
    AddFileLog(inttostr(i) + ': ' + ParamStr(i));
{$ELSE}
begin
{$ENDIF}
if ParamCount=6 then
   begin
   val(ParamStr(1), cScreenWidth, c);
   val(ParamStr(2), cScreenHeight, c);
   val(ParamStr(3), cBits, c);
   val(ParamStr(4), ipcPort, c);
   cFullScreen:= ParamStr(5) = '1';
   isSoundEnabled:= ParamStr(6) = '1';
   end else OutError(errmsgShouldntRun, true);
end;

procedure ShowMainWindow;
var flags: Longword;
begin
flags:= SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_HWACCEL;
if cFullScreen then flags:= flags or SDL_FULLSCREEN
               else SDL_WM_SetCaption('Hedgewars', nil);
SDLPrimSurface:= SDL_SetVideoMode(cScreenWidth, cScreenHeight, cBits, flags);
TryDo(SDLPrimSurface <> nil, errmsgCreateSurface, true);
PixelFormat:= SDLPrimSurface.format;
SDL_ShowCursor(0);
end;
////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// m a i n ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

begin
WriteLnToConsole('HedgeWars 0.1 alpha');
WriteLnToConsole('  -= by unC0Rr =-  ');
GetParams;
Randomize;

WriteToConsole('Init SDL... ');
SDLTry(SDL_Init(SDL_INIT_VIDEO) >= 0, true);
WriteLnToConsole(msgOK);

WriteToConsole('Init SDL_ttf... ');
SDLTry(TTF_Init >= 0, true);
WriteLnToConsole(msgOK);

ShowMainWindow;

InitKbdKeyTable;
InitIPC;
WriteLnToConsole(msgGettingConfig);
SendIPCAndWaitReply('C');        // запрос конфига игры
InitTeams;

if isSoundEnabled then InitSound;
InitWorld;

StoreInit;

isDeveloperMode:= false;

TryDo(InitStepsFlags = cifAllInited,
      'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')',
      true);

MainLoop

end.

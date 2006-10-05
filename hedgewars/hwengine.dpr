(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
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
  uAIMisc in 'uAIMisc.pas',
  uAIAmmoTests in 'uAIAmmoTests.pas',
  uAIActions in 'uAIActions.pas',
  uCollisions in 'uCollisions.pas',
  uLand in 'uLand.pas',
  uLandTemplates in 'uLandTemplates.pas',
  uLandObjects in 'uLandObjects.pas',
  uLandGraphics in 'uLandGraphics.pas',
  uLocale in 'uLocale.pas';

{$INCLUDE options.inc}

// also: GSHandlers.inc
//       CCHandlers.inc
//       HHHandlers.inc


procedure OnDestroy; forward;

////////////////////////////////
procedure DoTimer(Lag: integer);
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
              if GameType = gmtSave then
                 begin
                 isSEBackup:= isSoundEnabled;
                 isSoundEnabled:= false
                 end;
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
   s:= 'hw_' + cSeed + '_' + inttostr(GameTicks) + '.bmp';
   WriteLnToConsole('Saving ' + s);
   SDL_SaveBMP_RW(SDLPrimSurface, SDL_RWFromFile(PChar(s), 'wb'), 1)
   end;
end;

////////////////////
procedure OnDestroy;
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
    i: integer;
    p: TPathType;
begin
PathPrefix:= ParamStr(0);
for i:= 1 to Length(PathPrefix) do
    if PathPrefix[i] = '\' then PathPrefix[i]:= '/';
i:= Length(PathPrefix);
while (i > 0) and not (PathPrefix[i] = '/') do dec(i);
Delete(PathPrefix, i, Length(PathPrefix) - i + 1);
dec(i);
while (i > 0) and not (PathPrefix[i] = '/') do dec(i);
Delete(PathPrefix, i, Length(PathPrefix) - i + 1);
PathPrefix:= PathPrefix + '/share/hedgewars/';
for p:= Low(TPathType) to High(TPathType) do
    if p <> ptMapCurrent then Pathz[p]:= PathPrefix + Pathz[p];

{$IFDEF DEBUGFILE}
AddFileLog('Prefix: "' + PathPrefix +'"');
for i:= 0 to ParamCount do
    AddFileLog(inttostr(i) + ': ' + ParamStr(i));
{$ENDIF}
case ParamCount of
  8: begin
     val(ParamStr(1), cScreenWidth, c);
     val(ParamStr(2), cScreenHeight, c);
     cBitsStr:= ParamStr(3);
     val(cBitsStr, cBits, c);
     val(ParamStr(4), ipcPort, c);
     cFullScreen:= ParamStr(5) = '1';
     isSoundEnabled:= ParamStr(6) = '1';
     cLocaleFName:= ParamStr(7);
     val(ParamStr(8), cInitVolume, c);
     end;
  2: begin
     val(ParamStr(1), ipcPort, c);
     GameType:= gmtLandPreview;
     if ParamStr(2) <> 'landpreview' then OutError(errmsgShouldntRun, true);
     end
   else
   OutError(errmsgShouldntRun, true)
   end
end;

procedure ShowMainWindow;
begin
if cFullScreen then ParseCommand('fullscr 1')
               else ParseCommand('fullscr 0')
end;

///////////////
procedure Game;
begin
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

LoadLocale(Pathz[ptLocale] + '/' + cLocaleFName);

SendIPCAndWaitReply('C');        // ask for game config
InitTeams;

if isSoundEnabled then InitSound;
InitWorld;

StoreInit;

isDeveloperMode:= false;

TryDo(InitStepsFlags = cifAllInited,
      'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')',
      true);

MainLoop
end;

/////////////////////////
procedure GenLandPreview;
begin
InitIPC;
IPCWaitPongEvent;
TryDo(InitStepsFlags = cifRandomize,
      'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')',
      true);

GenPreview;
WriteLnToConsole('Sending preview...');
SendIPCRaw(@Preview, sizeof(Preview));
WriteLnToConsole('Preview sent, disconnect');
CloseIPC
end;

////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// m a i n ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

begin
WriteLnToConsole('-= HedgeWars 0.2 =-');
WriteLnToConsole('  -= by unC0Rr =-  ');
GetParams;
Randomize;

if GameType = gmtLandPreview then GenLandPreview
                             else Game
end.

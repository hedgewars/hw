 (*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2007 Andrey Korotaev <unC0Rr@gmail.com>
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

{$INCLUDE "options.inc"}

program hwengine;
uses
	SDLh in 'SDLh.pas',
{$IFDEF GLES11}
	gles11,
{$ELSE}
	GL,
{$ENDIF}
	uConsts in 'uConsts.pas',
	uGame in 'uGame.pas',
	uMisc in 'uMisc.pas',
	uStore in 'uStore.pas',
	uWorld in 'uWorld.pas',
	uIO in 'uIO.pas',
	uGears in 'uGears.pas',
	uVisualGears in 'uVisualGears.pas',
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
	uLocale in 'uLocale.pas',
	uAmmos in 'uAmmos.pas',
	uSHA in 'uSHA.pas',
	uFloat in 'uFloat.pas',
	uStats in 'uStats.pas',
	uChat in 'uChat.pas',
	uLandTexture in 'uLandTexture.pas';

// also: GSHandlers.inc
//       CCHandlers.inc
//       HHHandlers.inc
//       SinTable.inc
//       proto.inc

var recordFileName : shortstring = '';

procedure OnDestroy; forward;

////////////////////////////////
procedure DoTimer(Lag: LongInt);
{$IFNDEF IPHONEOS}
var s: string;
{$ENDIF}
begin
inc(RealTicks, Lag);

case GameState of
	gsLandGen: begin
			GenMap;
			GameState:= gsStart;
			end;
	gsStart: begin
			if HasBorder then DisableSomeWeapons;
			AddClouds;
			AssignHHCoords;
			AddMiscGears;
			StoreLoad;
			InitWorld;
			ResetKbd;
			SoundLoad;
			if GameType = gmtSave then
				begin
				isSEBackup:= isSoundEnabled;
				isSoundEnabled:= false
				end;
			FinishProgress;
			PlayMusic;
			SetScale(zoom);
			GameState:= gsGame
			end;
	gsConfirm,
	gsGame: begin
			DrawWorld(Lag); // never place between ProcessKbd and DoGameTick - bugs due to /put cmd and isCursorVisible
			ProcessKbd;
			DoGameTick(Lag);
			ProcessVisualGears(Lag);
			end;
	gsChat: begin
			DrawWorld(Lag);
			DoGameTick(Lag);
			ProcessVisualGears(Lag);
			end;
	gsExit: begin
			OnDestroy;
			end;
	end;

SDL_GL_SwapBuffers();
{$IFNDEF IPHONEOS}
// not going to make captures on the iPhone (nor resizing)
if flagMakeCapture then
	begin
	flagMakeCapture:= false;
	s:= 'hw_' + cSeed + '_' + inttostr(GameTicks) + '.tga';
	WriteLnToConsole('Saving ' + s);
	MakeScreenshot(s);
//	SDL_SaveBMP_RW(SDLPrimSurface, SDL_RWFromFile(Str2PChar(s), 'wb'), 1)
	end;
end;

////////////////////////////////
procedure Resize(w, h: LongInt);
begin
cScreenWidth:= w;
cScreenHeight:= h;
if cFullScreen then
	ParseCommand('/fullscr 1', true)
else
	ParseCommand('/fullscr 0', true);
{$ENDIF}
end;

////////////////////
procedure OnDestroy;
begin
{$IFDEF DEBUGFILE}AddFileLog('Freeing resources...');{$ENDIF}
	if isSoundEnabled then ReleaseSound();
	StoreRelease();
	FreeLand();
	SendKB();
	CloseIPC();
	TTF_Quit();
//{$IFNDEF IPHONEOS}
	// TODO: don't halt and don't clean, return to the previous view
	SDL_Quit();
	halt();
//{$ENDIF}
end;

///////////////////
procedure MainLoop;
var PrevTime,
    CurrTime: Longword;
    event: TSDL_Event;
{$IFDEF TOUCHINPUT}
var tiltValue: LongInt;
{$ENDIF}
begin
PrevTime:= SDL_GetTicks;
repeat
while SDL_PollEvent(@event) <> 0 do
	case event.type_ of
{$IFDEF SDL13}
		SDL_WINDOWEVENT:
{$ELSE}
		SDL_KEYDOWN: if GameState = gsChat then KeyPressChat(event.key.keysym.unicode);
		SDL_ACTIVEEVENT:
{$ENDIF}
			if (event.active.state and SDL_APPINPUTFOCUS) <> 0 then
				cHasFocus:= event.active.gain = 1;
		//SDL_VIDEORESIZE: Resize(max(event.resize.w, 600), max(event.resize.h, 450));
{$IFDEF IPHONEOS}
(*		SDL_JOYAXISMOTION: begin
                {* axis 0 = left and right;
                   axis 1 = up and down;
                   axis 2 = back and forth; *}

			WriteLnToConsole('*********************************************       accelerometer');
			
			tiltValue:= SDL_JoystickGetAxis(uKeys.theJoystick, 0);

			if (CurrentTeam <> nil) then
			begin
{$IFDEF DEBUGFILE}
				AddFileLog('Joystick: 0; Axis: 0; Value: ' + inttostr(tiltValue));
{$ENDIF}
					if tiltValue > 1500 then
					begin
						uKeys.rightKey:= true;
						uKeys.isWalking:= true;
					end
					else
						if tiltValue <= -1500 then
						begin 
							uKeys.leftKey:= true;
							uKeys.isWalking:= true;
						end
						else
							if (tiltValue  > -1500) and (tiltValue <= 1500) and (movedbybuttons = false) then uKeys.isWalking:= false;  
                        end;
			end;*)
{$ELSE}
		SDL_MOUSEBUTTONDOWN: if event.button.button = SDL_BUTTON_WHEELDOWN then uKeys.wheelDown:= true;
		SDL_MOUSEBUTTONUP: if event.button.button = SDL_BUTTON_WHEELUP then uKeys.wheelUp:= true;
		SDL_JOYAXISMOTION: ControllerAxisEvent(event.jaxis.which, event.jaxis.axis, event.jaxis.value);
		SDL_JOYHATMOTION: ControllerHatEvent(event.jhat.which, event.jhat.hat, event.jhat.value);
		SDL_JOYBUTTONDOWN: ControllerButtonEvent(event.jbutton.which, event.jbutton.button, true);
		SDL_JOYBUTTONUP: ControllerButtonEvent(event.jbutton.which, event.jbutton.button, false);
{$ENDIF}
		SDL_QUITEV: isTerminated:= true
        end;

CurrTime:= SDL_GetTicks;
if PrevTime + cTimerInterval <= CurrTime then
   begin
   DoTimer(CurrTime - PrevTime);
   PrevTime:= CurrTime
   end else SDL_Delay(1);
IPCCheckSock
until isTerminated

end;

/////////////////////
procedure DisplayUsage;
begin
	WriteLn('Wrong argument format: correct configurations is');
	WriteLn();
	WriteLn('  hwengine <path to data folder> <path to replay file> [option]');
	WriteLn();
	WriteLn('where [option] must be specified either as');
	WriteLn(' --set-video [screen width] [screen height] [color dept]');
	WriteLn(' --set-audio [volume] [enable music] [enable sounds]');
	WriteLn(' --set-other [language file] [full screen] [show FPS]');
	WriteLn(' --set-multimedia [screen height] [screen width] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen]');
	WriteLn(' --set-everything [screen height] [screen width] [color dept] [volume] [enable music] [enable sounds] [language file] [full screen] [show FPS] [alternate damage] [timer value] [reduced quality]');
	WriteLn();
	WriteLn('Read documentation online at http://www.hedgewars.org/node/1465 for more information');
	halt(1);
end;

////////////////////
procedure GetParams;
var
{$IFDEF DEBUGFILE}
    i: LongInt;
{$ENDIF}
    p: TPathType;
begin

case ParamCount of
 17: begin
     val(ParamStr(2), cScreenWidth);
     val(ParamStr(3), cScreenHeight);
     cInitWidth:= cScreenWidth;
     cInitHeight:= cScreenHeight;
     cBitsStr:= ParamStr(4);
     val(cBitsStr, cBits);
     val(ParamStr(5), ipcPort);
     cFullScreen:= ParamStr(6) = '1';
     isSoundEnabled:= ParamStr(7) = '1';
     cVSyncInUse:= ParamStr(8) = '1';
     cLocaleFName:= ParamStr(9);
     val(ParamStr(10), cInitVolume);
     val(ParamStr(11), cTimerInterval);
     PathPrefix:= ParamStr(12);
     cShowFPS:= ParamStr(13) = '1';
     cAltDamage:= ParamStr(14) = '1';
     UserNick:= DecodeBase64(ParamStr(15));
     isMusicEnabled:= ParamStr(16) = '1';
     cReducedQuality:= ParamStr(17) = '1';
     for p:= Succ(Low(TPathType)) to High(TPathType) do
         if p <> ptMapCurrent then Pathz[p]:= PathPrefix + '/' + Pathz[p]
     end;
{$IFDEF IPHONEOS}
  0: begin
        PathPrefix:= 'Data';
        recordFileName:= 'save.hws';
        val('320', cScreenWidth);
        val('480', cScreenHeight);
        cInitWidth:= cScreenWidth;
        cInitHeight:= cScreenHeight;
        cBitsStr:= '32';
        val(cBitsStr, cBits);
        val('100', cInitVolume);
        isMusicEnabled:= false;
        isSoundEnabled:= false;
        cLocaleFName:= 'en.txt';
        cFullScreen:= true; //T or F is is the same here
        cAltDamage:= false;
        cShowFPS:= true;
        val('8', cTimerInterval);
        cReducedQuality:= false;

        for p:= Succ(Low(TPathType)) to High(TPathType) do
                if p <> ptMapCurrent then Pathz[p]:= PathPrefix + '/' + Pathz[p]
     end;
{$ENDIF}
  3: begin
     val(ParamStr(2), ipcPort);
     GameType:= gmtLandPreview;
     if ParamStr(3) <> 'landpreview' then OutError(errmsgShouldntRun, true);
     end;
  2: begin
		PathPrefix:= ParamStr(1);
		recordFileName:= ParamStr(2);

		for p:= Succ(Low(TPathType)) to High(TPathType) do
			if p <> ptMapCurrent then Pathz[p]:= PathPrefix + '/' + Pathz[p]
     end;
  6: begin
		PathPrefix:= ParamStr(1);
		recordFileName:= ParamStr(2);

		if ParamStr(3) = '--set-video'	then
		begin
			val(ParamStr(4), cScreenWidth);
			val(ParamStr(5), cScreenHeight);
			cInitWidth:= cScreenWidth;
			cInitHeight:= cScreenHeight;
			cBitsStr:= ParamStr(6);
			val(cBitsStr, cBits);
		end
		else
		begin
			if ParamStr(3) = '--set-audio' then
			begin
				val(ParamStr(4), cInitVolume);
				isMusicEnabled:= ParamStr(5) = '1';
				isSoundEnabled:= ParamStr(6) = '1';
			end
			else
			begin
				if ParamStr(3) = '--set-other' then
				begin
					cLocaleFName:= ParamStr(4);
					cFullScreen:= ParamStr(5) = '1';
					cShowFPS:= ParamStr(6) = '1';
				end
				else DisplayUsage;
			end
		end;

		for p:= Succ(Low(TPathType)) to High(TPathType) do
			if p <> ptMapCurrent then Pathz[p]:= PathPrefix + '/' + Pathz[p]
	end;
 11: begin
		PathPrefix:= ParamStr(1);
		recordFileName:= ParamStr(2);

		if ParamStr(3) = '--set-multimedia' then
		begin
			val(ParamStr(4), cScreenWidth);
			val(ParamStr(5), cScreenHeight);
			cInitWidth:= cScreenWidth;
			cInitHeight:= cScreenHeight;
			cBitsStr:= ParamStr(6);
			val(cBitsStr, cBits);
			val(ParamStr(7), cInitVolume);
			isMusicEnabled:= ParamStr(8) = '1';
			isSoundEnabled:= ParamStr(9) = '1';
			cLocaleFName:= ParamStr(10);
			cFullScreen:= ParamStr(11) = '1';
		end
		else DisplayUsage;

		for p:= Succ(Low(TPathType)) to High(TPathType) do
			if p <> ptMapCurrent then Pathz[p]:= PathPrefix + '/' + Pathz[p]
	end;
 15: begin
		PathPrefix:= ParamStr(1);
		recordFileName:= ParamStr(2);
		if ParamStr(3) = '--set-everything' then
		begin
			val(ParamStr(4), cScreenWidth);
			val(ParamStr(5), cScreenHeight);
			cInitWidth:= cScreenWidth;
			cInitHeight:= cScreenHeight;
			cBitsStr:= ParamStr(6);
			val(cBitsStr, cBits);
			val(ParamStr(7), cInitVolume);
			isMusicEnabled:= ParamStr(8) = '1';
			isSoundEnabled:= ParamStr(9) = '1';
			cLocaleFName:= ParamStr(10);
			cFullScreen:= ParamStr(11) = '1';
			cAltDamage:= ParamStr(12) = '1';
			cShowFPS:= ParamStr(13) = '1';
			val(ParamStr(14), cTimerInterval);
			cReducedQuality:= ParamStr(15) = '1';
		end
		else DisplayUsage;

		for p:= Succ(Low(TPathType)) to High(TPathType) do
			if p <> ptMapCurrent then Pathz[p]:= PathPrefix + '/' + Pathz[p]
	end;
	else DisplayUsage;
	end;

{$IFDEF DEBUGFILE}
AddFileLog('Prefix: "' + PathPrefix +'"');
for i:= 0 to ParamCount do
	AddFileLog(inttostr(i) + ': ' + ParamStr(i));
{$IFDEF IPHONEOS}
	WriteLnToConsole('Saving debug file at: ' + get_documents_path());
{$ENDIF}
{$ENDIF}
end;

/////////////////////////
procedure ShowMainWindow;
begin
	if cFullScreen then ParseCommand('fullscr 1', true)
	else ParseCommand('fullscr 0', true);
	SDL_ShowCursor(0)
end;

///////////////
procedure Game;
var s: shortstring;
begin
WriteToConsole('Init SDL... ');
SDLTry(SDL_Init(SDL_INIT_VIDEO) >= 0, true);
WriteLnToConsole(msgOK);

SDL_EnableUNICODE(1);

WriteToConsole('Init SDL_ttf... ');
SDLTry(TTF_Init <> -1, true);
WriteLnToConsole(msgOK);

ShowMainWindow;

AddProgress;

ControllerInit; // has to happen before InitKbdKeyTable to map keys
InitKbdKeyTable;

if recordFileName = '' then InitIPC;
WriteLnToConsole(msgGettingConfig);

if cLocaleFName <> 'en.txt' then
	LoadLocale(Pathz[ptLocale] + '/en.txt');
LoadLocale(Pathz[ptLocale] + '/' + cLocaleFName);

if recordFileName = '' then
	SendIPCAndWaitReply('C')        // ask for game config
else
 	LoadRecordFromFile(recordFileName);

s:= 'eproto ' + inttostr(cNetProtoVersion);
SendIPCRaw(@s[0], Length(s) + 1); // send proto version

InitTeams;
AssignStores;

if isSoundEnabled then
	InitSound;

isDeveloperMode:= false;

TryDo(InitStepsFlags = cifAllInited, 'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')', true);

MainLoop;
ControllerClose
end;

/////////////////////////
procedure GenLandPreview;
var Preview: TPreview;
	h: byte;
begin
InitIPC;
IPCWaitPongEvent;
TryDo(InitStepsFlags = cifRandomize, 'Some parameters not set (flags = ' + inttostr(InitStepsFlags) + ')', true);

Preview:= GenPreview;
WriteLnToConsole('Sending preview...');
SendIPCRaw(@Preview, sizeof(Preview));
h:= MaxHedgehogs;
SendIPCRaw(@h, sizeof(h));
WriteLnToConsole('Preview sent, disconnect');
CloseIPC
end;

////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// m a i n ////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

begin
WriteLnToConsole('Hedgewars ' + cVersionString + ' engine (network protocol: ' + inttostr(cNetProtoVersion) + ')');
GetParams;

Randomize;

if GameType = gmtLandPreview then GenLandPreview
                             else Game
end.


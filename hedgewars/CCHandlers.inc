(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2009 Andrey Korotaev <unC0Rr@gmail.com>
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

function CheckNoTeamOrHH: boolean;
var bRes: boolean;
begin
bRes:= (CurrentTeam = nil) or (CurrentHedgehog^.Gear = nil);
{$IFDEF DEBUGFILE}
if bRes then
   if CurrentTeam = nil then AddFileLog('CONSOLE: CurTeam = nil')
                        else AddFileLog('CONSOLE: CurTeam <> nil, Gear = nil');
{$ENDIF}
CheckNoTeamOrHH:= bRes;
end;
////////////////////////////////////////////////////////////////////////////////
procedure chQuit(var s: shortstring);
const prevGState: TGameState = gsConfirm;
begin
if GameState <> gsConfirm then
        begin
        prevGState:= GameState;
        GameState:= gsConfirm
        end else
        GameState:= prevGState
end;

procedure chConfirm(var s: shortstring);
begin
if GameState = gsConfirm then
	begin
	SendIPC('Q');
	GameState:= gsExit
	end
else
    begin
    GameState:= gsChat;
    KeyPressChat(27);
    KeyPressChat(47);
    KeyPressChat(116);
    KeyPressChat(101);
    KeyPressChat(97);
    KeyPressChat(109);
    KeyPressChat(32)
    end
end;

procedure chCheckProto(var s: shortstring);
var i, c: LongInt;
begin
if isDeveloperMode then
   begin
   val(s, i, c);
   if (c <> 0) or (i = 0) then exit;
   TryDo(i <= cNetProtoVersion, 'Protocol version mismatch: engine is too old', true);
   TryDo(i >= cNetProtoVersion, 'Protocol version mismatch: engine is too new', true)
   end
end;

procedure chAddTeam(var s: shortstring);
var Color: Longword;
    ts: shortstring;
begin
if isDeveloperMode then
   begin
   SplitBySpace(s, ts);
   val(s, Color);
   TryDo(Color <> 0, 'Error: black team color', true);

   // color is always little endian so the mask must be constant also in big endian archs
   Color:= Color or $FF000000;
 	
   AddTeam(Color);
   CurrentTeam^.TeamName:= ts;
   if GameType in [gmtDemo, gmtSave] then CurrentTeam^.ExtDriven:= true;

   CurrentTeam^.voicepack:= AskForVoicepack('Default')
   end
end;

procedure chTeamLocal(var s: shortstring);
begin
if not isDeveloperMode then exit;
if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/rdriven"', true);
CurrentTeam^.ExtDriven:= true
end;

procedure chGrave(var s: shortstring);
begin
if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/grave"', true);
if s[1]='"' then Delete(s, 1, 1);
if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
CurrentTeam^.GraveName:= s
end;

procedure chFort(var s: shortstring);
begin
if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/fort"', true);
if s[1]='"' then Delete(s, 1, 1);
if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
CurrentTeam^.FortName:= s
end;

procedure chVoicepack(var s: shortstring);
begin
if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/voicepack"', true);
if s[1]='"' then Delete(s, 1, 1);
if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
CurrentTeam^.voicepack:= AskForVoicepack(s)
end;

procedure chAddHH(var id: shortstring);
var s: shortstring;
    Gear: PGear;
begin
if (not isDeveloperMode) or (CurrentTeam = nil) then exit;
with CurrentTeam^ do
	begin
	SplitBySpace(id, s);
	CurrentHedgehog:= @Hedgehogs[HedgehogsNumber];
	val(id, CurrentHedgehog^.BotLevel);
	Gear:= AddGear(0, 0, gtHedgehog, 0, _0, _0, 0);
	SplitBySpace(s, id);
	val(s, Gear^.Health);
	TryDo(Gear^.Health > 0, 'Invalid hedgehog health', true);
	PHedgehog(Gear^.Hedgehog)^.Team:= CurrentTeam;
	CurrentHedgehog^.AmmoStore:= ClansCount - 1; // FIXME HACK to get ammostores work
	CurrentHedgehog^.Gear:= Gear;
	CurrentHedgehog^.Name:= id;
	inc(HedgehogsNumber)
	end
end;

procedure chSetHat(var s: shortstring);
begin
if (not isDeveloperMode) or (CurrentTeam = nil) then exit;
with CurrentTeam^ do
	if s = '' then
		CurrentHedgehog^.Hat:= 'NoHat'
	else
		CurrentHedgehog^.Hat:= s
end;

procedure chSetHHCoords(var x: shortstring);
var y: shortstring;
    t: Longint;
begin
if (not isDeveloperMode) or (CurrentHedgehog = nil) or (CurrentHedgehog^.Gear = nil) then exit;
SplitBySpace(x, y);
val(x, t);
CurrentHedgehog^.Gear^.X:= int2hwFloat(t);
val(y, t);
CurrentHedgehog^.Gear^.Y:= int2hwFloat(t)
end;

procedure chAddAmmoStore(var descr: shortstring);
begin
AddAmmoStore(descr)
end;

procedure chBind(var id: shortstring);
var s: shortstring;
    b: LongInt;
begin
if CurrentTeam = nil then exit;
SplitBySpace(id, s);
if s[1]='"' then Delete(s, 1, 1);
if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
b:= KeyNameToCode(id);
if b = 0 then OutError(errmsgUnknownVariable + ' "' + id + '"', false)
         else CurrentTeam^.Binds[b]:= s
end;

procedure chCurU_p(var s: shortstring);
begin
CursorMovementY:= -1;
end;

procedure chCurU_m(var s: shortstring);
begin
CursorMovementY:= 0;
end;

procedure chCurD_p(var s: shortstring);
begin
CursorMovementY:= 1;
end;

procedure chCurD_m(var s: shortstring);
begin
CursorMovementY:= 0;
end;

procedure chCurL_p(var s: shortstring);
begin
CursorMovementX:= -1;
end;

procedure chCurL_m(var s: shortstring);
begin
CursorMovementX:= 0;
end;

procedure chCurR_p(var s: shortstring);
begin
CursorMovementX:= 1;
end;

procedure chCurR_m(var s: shortstring);
begin
CursorMovementX:= 0;
end;

procedure chLeft_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
bShowFinger:= false;
if not CurrentTeam^.ExtDriven then SendIPC('L');
with CurrentHedgehog^.Gear^ do
    Message:= Message or gm_Left
end;

procedure chLeft_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('l');
with CurrentHedgehog^.Gear^ do
     Message:= Message and not gm_Left
end;

procedure chRight_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
bShowFinger:= false;
if not CurrentTeam^.ExtDriven then SendIPC('R');
with CurrentHedgehog^.Gear^ do
    Message:= Message or gm_Right
end;

procedure chRight_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('r');
with CurrentHedgehog^.Gear^ do
     Message:= Message and not gm_Right
end;

procedure chUp_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
bShowFinger:= false;
if not CurrentTeam^.ExtDriven then SendIPC('U');
with CurrentHedgehog^.Gear^ do
    Message:= Message or gm_Up
end;

procedure chUp_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('u');
with CurrentHedgehog^.Gear^ do
     Message:= Message and not gm_Up
end;

procedure chDown_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
bShowFinger:= false;
if not CurrentTeam^.ExtDriven then SendIPC('D');
with CurrentHedgehog^.Gear^ do
    Message:= Message or gm_Down
end;

procedure chDown_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('d');
with CurrentHedgehog^.Gear^ do
     Message:= Message and not gm_Down
end;

procedure chPrecise_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
bShowFinger:= false;
if not CurrentTeam^.ExtDriven then SendIPC('Z');
with CurrentHedgehog^.Gear^ do
    Message:= Message or gm_Precise
end;

procedure chPrecise_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('z');
with CurrentHedgehog^.Gear^ do
     Message:= Message and not gm_Precise
end;

procedure chLJump(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
bShowFinger:= false;
if not CurrentTeam^.ExtDriven then SendIPC('j');
with CurrentHedgehog^.Gear^ do
    Message:= Message or gm_LJump
end;

procedure chHJump(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
bShowFinger:= false;
if not CurrentTeam^.ExtDriven then SendIPC('J');
with CurrentHedgehog^.Gear^ do
    Message:= Message or gm_HJump
end;

procedure chAttack_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
     begin
     {$IFDEF DEBUGFILE}AddFileLog('/+attack: hedgehog''s Gear^.State = '+inttostr(State));{$ENDIF}
     if ((State and gstHHDriven) <> 0) then
        begin
        FollowGear:= CurrentHedgehog^.Gear;
        if not CurrentTeam^.ExtDriven then SendIPC('A');
        Message:= Message or gm_Attack
        end
     end
end;

procedure chAttack_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
with CurrentHedgehog^.Gear^ do
     begin
     if not CurrentTeam^.ExtDriven and
        ((Message and gm_Attack) <> 0) then SendIPC('a');
     Message:= Message and not gm_Attack
     end
end;

procedure chSwitch(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('S');
with CurrentHedgehog^.Gear^ do
     Message:= Message or gm_Switch
end;

procedure chNextTurn(var s: shortstring);
begin
TryDo(AllInactive, '/nextturn called when not all gears are inactive', true);

if not CurrentTeam^.ExtDriven then SendIPC('N');
TickTrigger(trigTurns);
{$IFDEF DEBUGFILE}AddFileLog('Doing SwitchHedgehog: time '+inttostr(GameTicks));{$ENDIF}
end;

procedure chSay(var s: shortstring);
begin
SendIPC('s' + s);

if copy(s, 1, 4) = '/me ' then
	s:= #2'* ' + UserNick + ' ' + copy(s, 5, Length(s) - 4)
else
	s:= #1 + UserNick + ': ' + s;

AddChatString(s)
end;

procedure chTeamSay(var s: shortstring);
begin
SendIPC('b' + s);

s:= #4 + UserNick + '(team): ' + s;

AddChatString(s)
end;

procedure chTimer(var s: shortstring);
begin
if (s[0] <> #1) or (s[1] < '1') or (s[1] > '5') or CheckNoTeamOrHH then exit;
bShowFinger:= false;

if not CurrentTeam^.ExtDriven then SendIPC(s);
with CurrentHedgehog^.Gear^ do
     begin
     Message:= Message or gm_Timer;
     MsgParam:= byte(s[1]) - ord('0')
     end
end;

procedure chSlot(var s: shortstring);
var slot: LongWord;
begin
if (s[0] <> #1) or CheckNoTeamOrHH then exit;
bShowFinger:= false;
slot:= byte(s[1]) - 49;
if slot > cMaxSlotIndex then exit;
if not CurrentTeam^.ExtDriven then SendIPC(char(byte(s[1]) + 79));
with CurrentHedgehog^.Gear^ do
     begin
     Message:= Message or gm_Slot;
     MsgParam:= slot
     end
end;

procedure chSetWeapon(var s: shortstring);
begin
if (s[0] <> #1) or CheckNoTeamOrHH then exit;

if TAmmoType(s[1]) > High(TAmmoType) then exit;

if not CurrentTeam^.ExtDriven then SendIPC('w' + s);

with CurrentHedgehog^.Gear^ do
     begin
     Message:= Message or gm_Weapon;
     MsgParam:= byte(s[1])
     end
end;

procedure chTaunt(var s: shortstring);
begin
if (s[0] <> #1) or CheckNoTeamOrHH then exit;

if TWave(s[1]) > High(TWave) then exit;

if not CurrentTeam^.ExtDriven then SendIPC('t' + s);

with CurrentHedgehog^.Gear^ do
     begin
     Message:= Message or gm_Animate;
     MsgParam:= byte(s[1])
     end
end;

procedure chHogSay(var s: shortstring);
var Gear: PVisualGear;
    text: shortstring;
begin
text:= copy(s, 2, Length(s)-1);
if CheckNoTeamOrHH
  or ((CurrentHedgehog^.Gear^.State and gstHHDriven) = 0) then
    begin
    chSay(text);
    exit
    end;

if not CurrentTeam^.ExtDriven then SendIPC('h' + s);

if byte(s[1]) < 4 then
    begin
    Gear:= AddVisualGear(0, 0, vgtSpeechBubble);
    if Gear <> nil then
       begin
       Gear^.Hedgehog:= CurrentHedgehog;
       Gear^.Text:= text;
       Gear^.FrameTicks:= byte(s[1])
       end
    end
else
    begin
    SpeechType:= byte(s[1])-3;
    SpeechText:= text
    end;

end;

procedure chNewGrave;
begin
if CheckNoTeamOrHH then exit;

if not CurrentTeam^.ExtDriven then SendIPC('g');

AddGear(hwRound(CurrentHedgehog^.Gear^.X), hwRound(CurrentHedgehog^.Gear^.Y), gtGrave, 0, _0, _0, 0)
end;

procedure doPut(putX, putY: LongInt; fromAI: boolean);
begin
if CheckNoTeamOrHH then exit;
if bShowAmmoMenu then
	begin
	bSelected:= true;
	exit
	end;

with CurrentHedgehog^.Gear^,
	CurrentHedgehog^ do
	if (State and gstHHChooseTarget) <> 0 then
		begin
		isCursorVisible:= false;
		if not CurrentTeam^.ExtDriven then
			begin
			if fromAI then
				begin
				TargetPoint.X:= putX;
				TargetPoint.Y:= putY
				end else
				begin
				TargetPoint.X:= CursorPoint.X - WorldDx;
				TargetPoint.Y:= cScreenHeight - CursorPoint.Y - WorldDy;
				end;
			SendIPCXY('p', TargetPoint.X, TargetPoint.Y);
			end
		else
			begin
			TargetPoint.X:= putX;
			TargetPoint.Y:= putY
			end;
		{$IFDEF DEBUGFILE}AddFilelog('put: ' + inttostr(TargetPoint.X) + ', ' + inttostr(TargetPoint.Y));{$ENDIF}
		State:= State and not gstHHChooseTarget;
		if (Ammo^[CurSlot, CurAmmo].Propz and ammoprop_AttackingPut) <> 0 then
			Message:= Message or gm_Attack;
		end
	else
		if CurrentTeam^.ExtDriven then
			OutError('got /put while not being in choose target mode', false)
end;

procedure chPut(var s: shortstring);
begin
doPut(0, 0, false)
end;

procedure chCapture(var s: shortstring);
begin
flagMakeCapture:= true
end;

procedure chSkip(var s: shortstring);
begin
if not CurrentTeam^.ExtDriven then SendIPC(',');
uStats.Skipped;
skipFlag:= true
end;

procedure chSetMap(var s: shortstring);
begin
if isDeveloperMode then
   begin
   Pathz[ptMapCurrent]:= Pathz[ptMaps] + '/' + s;
   InitStepsFlags:= InitStepsFlags or cifMap
   end
end;

procedure chSetTheme(var s: shortstring);
begin
if isDeveloperMode then
   begin
   Pathz[ptCurrTheme]:= Pathz[ptThemes] + '/' + s;
   InitStepsFlags:= InitStepsFlags or cifTheme
   end
end;

procedure chSetSeed(var s: shortstring);
begin
if isDeveloperMode then
   begin
   SetRandomSeed(s);
   cSeed:= s;
   InitStepsFlags:= InitStepsFlags or cifRandomize
   end
end;

procedure chAmmoMenu(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
with CurrentTeam^ do
     with Hedgehogs[CurrHedgehog] do
          begin
          bSelected:= false;

          if bShowAmmoMenu then bShowAmmoMenu:= false
          else if ((Gear^.State and (gstAttacking or gstAttacked)) <> 0) or (MultiShootAttacks > 0)
               or ((Gear^.State and gstHHDriven) = 0) then else bShowAmmoMenu:= true
          end
end;

procedure chFullScr(var s: shortstring);
var flags: Longword = 0;
{$IFDEF DEBUGFILE}
    buf: array[byte] of char;
{$ENDIF}
{$IFDEF SDL13}
	windowID: TSDL_WindowID;
{$ENDIF}
begin
	if Length(s) = 0 then cFullScreen:= not cFullScreen
	else cFullScreen:= s = '1';

{$IFDEF DEBUGFILE}
	AddFileLog('Prepare to change video parameters...');
{$ENDIF}

	flags:= SDL_OPENGL;// or SDL_RESIZABLE;
{$IFDEF IPHONEOS}
	// remove the topbar from the iPhone
	flags:= flags or SDL_NOFRAME;
{$ENDIF}

	if cFullScreen then
	begin
		flags:= flags or SDL_FULLSCREEN;
		cScreenWidth:= cInitWidth;
		cScreenHeight:= cInitHeight
	end;

	SDL_WM_SetCaption('Hedgewars', nil);
	if SDLPrimSurface <> nil then
	begin
{$IFDEF DEBUGFILE}
		AddFileLog('Freeing old primary surface...');
{$ENDIF}
		SDL_FreeSurface(SDLPrimSurface);
	end;
	
{$IFDEF SDL13}
	windowID:= SDL_CreateWindow(nil, 0, 0, cScreenWidth, cScreenHeight,	SDL_WINDOW_OPENGL or SDL_WINDOW_SHOWN 
				{$IFDEF IPHONEOS} or SDL_WINDOW_BORDERLESS{$ENDIF});
    SDL_CreateRenderer(windowID, 0, 0);
	PixelFormat:=nil;// SDLPrimSurface^.format;
	
	SDL_SetRenderDrawColor(0, 0, 0, 255);
    SDL_RenderFill(nil);
    SDL_RenderPresent();
{$ELSE}
	SDLPrimSurface:= SDL_SetVideoMode(cScreenWidth, cScreenHeight, cBits, flags);
	SDLTry(SDLPrimSurface <> nil, true);
	PixelFormat:= SDLPrimSurface^.format;
{$ENDIF}

{$IFDEF DEBUGFILE}
	AddFileLog('Setting up OpenGL...');
	AddFileLog('SDL video driver: ' + string(SDL_VideoDriverName(buf, sizeof(buf))));
{$ENDIF}
	SetupOpenGL();
end;

procedure chVol_p(var s: shortstring);
begin
inc(cVolumeDelta, 3)
end;

procedure chVol_m(var s: shortstring);
begin
dec(cVolumeDelta, 3)
end;

procedure chFindhh(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
bShowFinger:= true;
FollowGear:= CurrentHedgehog^.Gear
end;

procedure chPause(var s: shortstring);
begin
if gameType <> gmtNet then
	isPaused:= not isPaused;
SDL_ShowCursor(ord(isPaused))
end;

procedure chRotateMask(var s: shortstring);
begin
inc(cTagsMaskIndex);
if cTagsMaskIndex > High(cTagsMasks) then cTagsMaskIndex:= Low(cTagsMasks);

// HACK: skip "health only" if all hogs are invulnerable
if ((GameFlags and gfInvulnerable) <> 0) and ((cTagsMasks[cTagsMaskIndex] and not htTransparent) = htHealth) then chRotateMask(s);
end;

procedure chAddTrigger(var s: shortstring);
const MAXPARAMS = 16;
var params: array[0..Pred(MAXPARAMS)] of Longword;
    i: LongInt;
    c: char;
    tmp: shortstring;
begin
c:= s[1];
Delete(s, 1, 1);

i:= 0;
while (i < MAXPARAMS) and
      (Length(s) > 0) do
    begin
    SplitBySpace(s, tmp);
    val(s, params[i]);
    s:= tmp;
    inc(i)
    end;

case c of
  's': begin // sTYPE TICKS LIVES GEARTYPE X Y GEARTRIGGER
       TryDo(i = 7, errmsgWrongNumber, true);
       AddTriggerSpawner(params[0], params[1], params[2], TGearType(params[3]), params[4], params[5], params[6]);
       end;
  'C': begin
       TryDo(i = 3, errmsgWrongNumber, true);
       AddTriggerSuccess(params[0], params[1], params[2]);
       end;
  'F': begin
       TryDo(i = 3, errmsgWrongNumber, true);
       AddTriggerFail(params[0], params[1], params[2]);
       end;
  end
end;

procedure chSpeedup_p(var s: shortstring);
begin
isSpeed:= true
end;

procedure chSpeedup_m(var s: shortstring);
begin
isSpeed:= false
end;

procedure chZoomIn(var s: shortstring);
begin
{$IFDEF IPHONEOS}
if ZoomValue < 3.5 then
{$ELSE}
if ZoomValue < 3.0 then
{$ENDIF}
        ZoomValue:= ZoomValue + 0.25;
end;

procedure chZoomOut(var s: shortstring);
begin
{$IFDEF IPHONEOS}
if ZoomValue > 0.5 then
{$ELSE}
if ZoomValue > 1.0 then
{$ENDIF}
        ZoomValue:= ZoomValue - 0.25;
end;

procedure chZoomReset(var s: shortstring);
begin
ZoomValue:= 2.0
end;

procedure chChat(var s: shortstring);
begin
GameState:= gsChat;
KeyPressChat(27)
end;

procedure chHistory(var s: shortstring);
begin
uChat.showAll:= not uChat.showAll
end;

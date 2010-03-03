(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2008 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uConsole;
interface
uses uFloat;

var isDeveloperMode: boolean;
type TVariableType = (vtCommand, vtLongInt, vthwFloat, vtBoolean);
     TCommandHandler = procedure (var params: shortstring);

procedure init_uConsole;
procedure free_uConsole;
procedure WriteToConsole(s: shortstring);
procedure WriteLnToConsole(s: shortstring);
procedure ParseCommand(CmdStr: shortstring; TrustedSource: boolean);
procedure StopMessages(Message: Longword);
function  GetLastConsoleLine: shortstring;

procedure doPut(putX, putY: LongInt; fromAI: boolean);

implementation
uses uMisc, uStore, Types, uConsts, uGears, uTeams, uIO, uKeys, uWorld, uLand,
     uRandom, uAmmos, uTriggers, uStats, uGame, uChat, SDLh, uSound, uVisualGears, uScript;

const cLineWidth: LongInt = 0;
      cLinesCount = 256;

type  PVariable = ^TVariable;
      TVariable = record
                     Next: PVariable;
                     Name: string[15];
                    VType: TVariableType;
                  Handler: pointer;
                  Trusted: boolean;
                  end;
      TTextLine = record
                  s: shortstring;
                  end;

var   ConsoleLines: array[byte] of TTextLine;
      CurrLine: LongInt;
      Variables: PVariable;

procedure SetLine(var tl: TTextLine; str: shortstring);
begin
with tl do
     s:= str;
end;

function RegisterVariable(Name: shortstring; VType: TVariableType; p: pointer; Trusted: boolean): PVariable;
var value: PVariable;
begin
New(value);
TryDo(value <> nil, 'RegisterVariable: value = nil', true);
FillChar(value^, sizeof(TVariable), 0);
value^.Name:= Name;
value^.VType:= VType;
value^.Handler:= p;
value^.Trusted:= Trusted;

if Variables = nil then Variables:= value
                   else begin
                        value^.Next:= Variables;
                        Variables:= value
                        end;

RegisterVariable:= value;
end;

procedure FreeVariablesList;
var t, tt: PVariable;
begin
tt:= Variables;
Variables:= nil;
while tt <> nil do
      begin
      t:= tt;
      tt:= tt^.Next;
      Dispose(t)
      end;
end;

procedure WriteToConsole(s: shortstring);
var Len: LongInt;
    done: boolean;
begin
	{$IFDEF DEBUGFILE}AddFileLog('Console write: ' + s);{$ENDIF}
	Write(s);
	done:= false;
	
	while not done do
	begin
		Len:= cLineWidth - Length(ConsoleLines[CurrLine].s);
		SetLine(ConsoleLines[CurrLine], ConsoleLines[CurrLine].s + copy(s, 1, Len));
		Delete(s, 1, Len);
		if byte(ConsoleLines[CurrLine].s[0]) = cLineWidth then
		begin
			inc(CurrLine);
			if CurrLine = cLinesCount then CurrLine:= 0;
			PByte(@ConsoleLines[CurrLine].s)^:= 0
		end;
		done:= (Length(s) = 0);
	end;
end;

procedure WriteLnToConsole(s: shortstring);
begin
	WriteToConsole(s);
	WriteLn;
	inc(CurrLine);
	if CurrLine = cLinesCount then
		CurrLine:= 0;
	PByte(@ConsoleLines[CurrLine].s)^:= 0
end;

procedure ParseCommand(CmdStr: shortstring; TrustedSource: boolean);
type PhwFloat = ^hwFloat;
var ii: LongInt;
    s: shortstring;
    t: PVariable;
    c: char;
begin
//WriteLnToConsole(CmdStr);
if CmdStr[0]=#0 then exit;
{$IFDEF DEBUGFILE}AddFileLog('ParseCommand "' + CmdStr + '"');{$ENDIF}
c:= CmdStr[1];
if c in ['/', '$'] then Delete(CmdStr, 1, 1) else c:= '/';
SplitBySpace(CmdStr, s);
t:= Variables;
while t <> nil do
      begin
      if t^.Name = CmdStr then
         begin
         if TrustedSource or t^.Trusted then
            case t^.VType of
              vtCommand: if c='/' then
                         begin
                         TCommandHandler(t^.Handler)(s);
                         end;
              vtLongInt: if c='$' then
                         if s[0]=#0 then
                            begin
                            str(PLongInt(t^.Handler)^, s);
                            WriteLnToConsole('$' + CmdStr + ' is "' + s + '"');
                            end else val(s, PLongInt(t^.Handler)^);
              vthwFloat: if c='$' then
                         if s[0]=#0 then
                            begin
                            //str(PhwFloat(t^.Handler)^:4:6, s);
                            WriteLnToConsole('$' + CmdStr + ' is "' + s + '"');
                            end else; //val(s, PhwFloat(t^.Handler)^, i);
             vtBoolean: if c='$' then
                         if s[0]=#0 then
                            begin
                            str(ord(boolean(t^.Handler^)), s);
                            WriteLnToConsole('$' + CmdStr + ' is "' + s + '"');
                            end else
                            begin
                            val(s, ii);
                            boolean(t^.Handler^):= not (ii = 0)
                            end;
              end;
         exit
         end else t:= t^.Next
      end;
case c of
     '$': WriteLnToConsole(errmsgUnknownVariable + ': "$' + CmdStr + '"')
     else WriteLnToConsole(errmsgUnknownCommand  + ': "/' + CmdStr + '"') end
end;

function GetLastConsoleLine: shortstring;
var valueStr: shortstring;
	i: LongWord;
begin
i:= (CurrLine + cLinesCount - 2) mod cLinesCount;
valueStr:= ConsoleLines[i].s;

valueStr:= valueStr + #10;

i:= (CurrLine + cLinesCount - 1) mod cLinesCount;
valueStr:= valueStr + ConsoleLines[i].s;

GetLastConsoleLine:= valueStr;
end;

procedure StopMessages(Message: Longword);
begin
if (Message and gm_Left) <> 0 then ParseCommand('/-left', true) else
if (Message and gm_Right) <> 0 then ParseCommand('/-right', true) else
if (Message and gm_Up) <> 0 then ParseCommand('/-up', true) else
if (Message and gm_Down) <> 0 then ParseCommand('/-down', true) else
if (Message and gm_Attack) <> 0 then ParseCommand('/-attack', true)
end;

{$INCLUDE "CCHandlers.inc"}
procedure init_uConsole;
var i: LongInt;
begin
	CurrLine:= 0;
	Variables:= nil;
	isDeveloperMode:= true;
	
	// initConsole
	cLineWidth:= cScreenWidth div 10;
	if cLineWidth > 255 then
		cLineWidth:= 255;
	for i:= 0 to Pred(cLinesCount) do 
		PByte(@ConsoleLines[i])^:= 0;
	
	RegisterVariable('proto'   , vtCommand, @chCheckProto   , true );
	RegisterVariable('spectate', vtBoolean, @fastUntilLag   , false);
	RegisterVariable('capture' , vtCommand, @chCapture      , true );
	RegisterVariable('rotmask' , vtCommand, @chRotateMask   , true );
	RegisterVariable('addteam' , vtCommand, @chAddTeam      , false);
	RegisterVariable('addtrig' , vtCommand, @chAddTrigger   , false);
	RegisterVariable('rdriven' , vtCommand, @chTeamLocal    , false);
	RegisterVariable('map'     , vtCommand, @chSetMap       , false);
	RegisterVariable('theme'   , vtCommand, @chSetTheme     , false);
	RegisterVariable('seed'    , vtCommand, @chSetSeed      , false);
	RegisterVariable('template_filter', vtLongInt, @cTemplateFilter, false);
	RegisterVariable('delay'   , vtLongInt, @cInactDelay    , false);
	RegisterVariable('casefreq', vtLongInt, @cCaseFactor    , false);
	RegisterVariable('sd_turns', vtLongInt, @cSuddenDTurns  , false);
	RegisterVariable('damagepct',vtLongInt, @cDamagePercent , false);
	RegisterVariable('minedudpct',vtLongInt,@cMineDudPercent, false);
	RegisterVariable('landadds', vtLongInt, @cLandAdditions , false);
	RegisterVariable('explosives',vtLongInt,@cExplosives    , false);
	RegisterVariable('gmflags' , vtLongInt, @GameFlags      , false);
	RegisterVariable('trflags' , vtLongInt, @TrainingFlags  , false);
	RegisterVariable('turntime', vtLongInt, @cHedgehogTurnTime, false);
	RegisterVariable('minestime',vtLongInt, @cMinesTime     , false);
	RegisterVariable('fort'    , vtCommand, @chFort         , false);
	RegisterVariable('voicepack',vtCommand, @chVoicepack    , false);
	RegisterVariable('grave'   , vtCommand, @chGrave        , false);
	RegisterVariable('bind'    , vtCommand, @chBind         , true );
	RegisterVariable('addhh'   , vtCommand, @chAddHH        , false);
	RegisterVariable('hat'     , vtCommand, @chSetHat       , false);
	RegisterVariable('hhcoords', vtCommand, @chSetHHCoords  , false);
	RegisterVariable('ammstore', vtCommand, @chAddAmmoStore , false);
	RegisterVariable('quit'    , vtCommand, @chQuit         , true );
	RegisterVariable('confirm' , vtCommand, @chConfirm      , true );
	RegisterVariable('+speedup', vtCommand, @chSpeedup_p    , true );
	RegisterVariable('-speedup', vtCommand, @chSpeedup_m    , true );
	RegisterVariable('zoomin'  , vtCommand, @chZoomIn       , true );
	RegisterVariable('zoomout' , vtCommand, @chZoomOut      , true );
	RegisterVariable('zoomreset',vtCommand, @chZoomReset    , true );
	RegisterVariable('skip'    , vtCommand, @chSkip         , false);
	RegisterVariable('history' , vtCommand, @chHistory      , true );
	RegisterVariable('chat'    , vtCommand, @chChat         , true );
	RegisterVariable('newgrave', vtCommand, @chNewGrave     , false);
	RegisterVariable('say'     , vtCommand, @chSay          , true );
	RegisterVariable('hogsay'  , vtCommand, @chHogSay       , true );
	RegisterVariable('team'    , vtCommand, @chTeamSay      , true );
	RegisterVariable('ammomenu', vtCommand, @chAmmoMenu     , true);
	RegisterVariable('+precise', vtCommand, @chPrecise_p    , false);
	RegisterVariable('-precise', vtCommand, @chPrecise_m    , false);
	RegisterVariable('+left'   , vtCommand, @chLeft_p       , false);
	RegisterVariable('-left'   , vtCommand, @chLeft_m       , false);
	RegisterVariable('+right'  , vtCommand, @chRight_p      , false);
	RegisterVariable('-right'  , vtCommand, @chRight_m      , false);
	RegisterVariable('+up'     , vtCommand, @chUp_p         , false);
	RegisterVariable('-up'     , vtCommand, @chUp_m         , false);
	RegisterVariable('+down'   , vtCommand, @chDown_p       , false);
	RegisterVariable('-down'   , vtCommand, @chDown_m       , false);
	RegisterVariable('+attack' , vtCommand, @chAttack_p     , false);
	RegisterVariable('-attack' , vtCommand, @chAttack_m     , false);
	RegisterVariable('switch'  , vtCommand, @chSwitch       , false);
	RegisterVariable('nextturn', vtCommand, @chNextTurn     , false);
	RegisterVariable('timer'   , vtCommand, @chTimer        , false);
	RegisterVariable('taunt'   , vtCommand, @chTaunt        , false);
	RegisterVariable('setweap' , vtCommand, @chSetWeapon    , false);
	RegisterVariable('slot'    , vtCommand, @chSlot         , false);
	RegisterVariable('put'     , vtCommand, @chPut          , false);
	RegisterVariable('ljump'   , vtCommand, @chLJump        , false);
	RegisterVariable('hjump'   , vtCommand, @chHJump        , false);
	RegisterVariable('fullscr' , vtCommand, @chFullScr      , true );
	RegisterVariable('+volup'  , vtCommand, @chVol_p        , true );
	RegisterVariable('-volup'  , vtCommand, @chVol_m        , true );
	RegisterVariable('+voldown', vtCommand, @chVol_m        , true );
	RegisterVariable('-voldown', vtCommand, @chVol_p        , true );
	RegisterVariable('findhh'  , vtCommand, @chFindhh       , true );
	RegisterVariable('pause'   , vtCommand, @chPause        , true );
	RegisterVariable('+cur_u'  , vtCommand, @chCurU_p       , true );
	RegisterVariable('-cur_u'  , vtCommand, @chCurU_m       , true );
	RegisterVariable('+cur_d'  , vtCommand, @chCurD_p       , true );
	RegisterVariable('-cur_d'  , vtCommand, @chCurD_m       , true );
	RegisterVariable('+cur_l'  , vtCommand, @chCurL_p       , true );
	RegisterVariable('-cur_l'  , vtCommand, @chCurL_m       , true );
	RegisterVariable('+cur_r'  , vtCommand, @chCurR_p       , true );
	RegisterVariable('-cur_r'  , vtCommand, @chCurR_m       , true );
	RegisterVariable('flag'    , vtCommand, @chFlag         , false);
	RegisterVariable('script'  , vtCommand, @chScript       , false);
end;

procedure free_uConsole;
begin
	FreeVariablesList();
end;

end.

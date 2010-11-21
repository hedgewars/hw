(*
* Hedgewars, a free turn based strategy game
* Copyright (c) 2004-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

////////////////////////////////////////////////////////////////////////////////
procedure chQuit(var s: shortstring);
const prevGState: TGameState = gsConfirm;
begin
s:= s; // avoid compiler hint
if GameState <> gsConfirm then
        begin
        prevGState:= GameState;
        GameState:= gsConfirm
        end else
        GameState:= prevGState
end;

procedure chConfirm(var s: shortstring);
begin
s:= s; // avoid compiler hint
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

procedure chTeamLocal(var s: shortstring);
begin
s:= s; // avoid compiler hint
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

procedure chFlag(var s: shortstring);
begin
if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/flag"', true);
if s[1]='"' then Delete(s, 1, 1);
if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
CurrentTeam^.flag:= s
end;

procedure chScript(var s: shortstring);
begin
if s[1]='"' then Delete(s, 1, 1);
if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
ScriptLoad(s)
end;

procedure chSetHat(var s: shortstring);
begin
if (not isDeveloperMode) or (CurrentTeam = nil) then exit;
with CurrentTeam^ do
    begin
    if not CurrentHedgehog^.King then
    if (s = '') or 
        (((GameFlags and gfKing) <> 0) and (s = 'crown')) or
        ((Length(s) > 39) and (Copy(s,1,8) = 'Reserved') and (Copy(s,9,32) <> PlayerHash)) then
        CurrentHedgehog^.Hat:= 'NoHat'
    else
        CurrentHedgehog^.Hat:= s
    end;
end;

procedure chSetAmmoLoadout(var descr: shortstring);
begin
SetAmmoLoadout(descr)
end;

procedure chSetAmmoDelay(var descr: shortstring);
begin
SetAmmoDelay(descr)
end;

procedure chSetAmmoProbability(var descr: shortstring);
begin
SetAmmoProbability(descr)
end;

procedure chSetAmmoReinforcement(var descr: shortstring);
begin
SetAmmoReinforcement(descr)
end;

procedure chAddAmmoStore(var descr: shortstring);
begin
descr:= ''; // avoid compiler hint
AddAmmoStore
end;

procedure chBind(var id: shortstring);
var s: shortstring;
    b: LongInt;
begin
s:= '';
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
s:= s; // avoid compiler hint
CursorMovementY:= -1;
end;

procedure chCurU_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementY:= 0;
end;

procedure chCurD_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementY:= 1;
end;

procedure chCurD_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementY:= 0;
end;

procedure chCurL_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementX:= -1;
end;

procedure chCurL_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementX:= 0;
end;

procedure chCurR_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementX:= 1;
end;

procedure chCurR_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
CursorMovementX:= 0;
end;

procedure chLeft_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH or isPaused then exit;
if not CurrentTeam^.ExtDriven then SendIPC('L');
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or gmLeft
end;

procedure chLeft_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('l');
with CurrentHedgehog^.Gear^ do
    Message:= Message and not gmLeft
end;

procedure chRight_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH or isPaused then exit;
if not CurrentTeam^.ExtDriven then SendIPC('R');
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or gmRight
end;

procedure chRight_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('r');
with CurrentHedgehog^.Gear^ do
    Message:= Message and not gmRight
end;

procedure chUp_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH or isPaused then exit;
if not CurrentTeam^.ExtDriven then SendIPC('U');
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or gmUp
end;

procedure chUp_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('u');
with CurrentHedgehog^.Gear^ do
    Message:= Message and not gmUp
end;

procedure chDown_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH or isPaused then exit;
if not CurrentTeam^.ExtDriven then SendIPC('D');
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or gmDown
end;

procedure chDown_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('d');
with CurrentHedgehog^.Gear^ do
    Message:= Message and not gmDown
end;

procedure chPrecise_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH or isPaused then exit;
if not CurrentTeam^.ExtDriven then SendIPC('Z');
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or gmPrecise
end;

procedure chPrecise_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then exit;
if not CurrentTeam^.ExtDriven then SendIPC('z');
with CurrentHedgehog^.Gear^ do
    Message:= Message and not gmPrecise
end;

procedure chLJump(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH or isPaused then exit;
if not CurrentTeam^.ExtDriven then SendIPC('j');
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or gmLJump
end;

procedure chHJump(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH or isPaused then exit;
if not CurrentTeam^.ExtDriven then SendIPC('J');
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or gmHJump
end;

procedure chAttack_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH or isPaused then exit;
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    begin
    {$IFDEF DEBUGFILE}AddFileLog('/+attack: hedgehog''s Gear^.State = '+inttostr(State));{$ENDIF}
    if ((State and gstHHDriven) <> 0) then
        begin
        FollowGear:= CurrentHedgehog^.Gear;
        if not CurrentTeam^.ExtDriven then SendIPC('A');
        Message:= Message or gmAttack
        end
    end
end;

procedure chAttack_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then exit;
with CurrentHedgehog^.Gear^ do
    begin
    if not CurrentTeam^.ExtDriven and
        ((Message and gmAttack) <> 0) then SendIPC('a');
    Message:= Message and not gmAttack
    end
end;

procedure chSwitch(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH or isPaused then exit;
if not CurrentTeam^.ExtDriven then SendIPC('S');
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    Message:= Message or gmSwitch
end;

procedure chNextTurn(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    TryDo(AllInactive, '/nextturn called when not all gears are inactive', true);

    if not CurrentTeam^.ExtDriven then SendIPC('N');
{$IFDEF DEBUGFILE}
    AddFileLog('Doing SwitchHedgehog: time '+inttostr(GameTicks));
{$ENDIF}
    perfExt_NewTurnBeginning();
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

s:= #4 + '[Team] ' + UserNick + ': ' + s;

AddChatString(s)
end;

procedure chTimer(var s: shortstring);
begin
if (s[0] <> #1) or (s[1] < '1') or (s[1] > '5') or CheckNoTeamOrHH then exit;

if not CurrentTeam^.ExtDriven then SendIPC(s);
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    begin
    Message:= Message or gmTimer;
    MsgParam:= byte(s[1]) - ord('0')
    end
end;

procedure chSlot(var s: shortstring);
var slot: LongWord;
begin
if (s[0] <> #1) or CheckNoTeamOrHH then exit;
slot:= byte(s[1]) - 49;
if slot > cMaxSlotIndex then exit;
if not CurrentTeam^.ExtDriven then SendIPC(char(byte(s[1]) + 79));
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
with CurrentHedgehog^.Gear^ do
    begin
    Message:= Message or gmSlot;
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
        Message:= Message or gmWeapon;
        MsgParam:= byte(s[1]);
    end;
end;

procedure chTaunt(var s: shortstring);
begin
if (s[0] <> #1) or CheckNoTeamOrHH then exit;

if TWave(s[1]) > High(TWave) then exit;

if not CurrentTeam^.ExtDriven then SendIPC('t' + s);

with CurrentHedgehog^.Gear^ do
    begin
    Message:= Message or gmAnimate;
    MsgParam:= byte(s[1])
    end
end;

procedure doPut(putX, putY: LongInt; fromAI: boolean);
begin
if CheckNoTeamOrHH or isPaused then exit;
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
bShowFinger:= false;
if not CurrentTeam^.ExtDriven and bShowAmmoMenu then
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
        if (Ammoz[CurAmmoType].Ammo.Propz and ammoprop_AttackingPut) <> 0 then
            Message:= Message or gmAttack;
        end
    else
        if CurrentTeam^.ExtDriven then
            OutError('got /put while not being in choose target mode', false)
end;

procedure chPut(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    doPut(0, 0, false);
end;

procedure chCapture(var s: shortstring);
begin
s:= s; // avoid compiler hint
flagMakeCapture:= true
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
s:= s; // avoid compiler hint
if CheckNoTeamOrHH then
    bShowAmmoMenu:= true
else
    begin
    with CurrentTeam^ do
        with Hedgehogs[CurrHedgehog] do
            begin
            bSelected:= false;

            if bShowAmmoMenu then bShowAmmoMenu:= false
            else if ((Gear^.State and (gstAttacking or gstAttacked)) <> 0) or 
                    ((MultiShootAttacks > 0) and ((Ammoz[CurAmmoType].Ammo.Propz and ammoprop_NoRoundEnd) = 0)) or
                    ((Gear^.State and gstHHDriven) = 0) then else bShowAmmoMenu:= true
            end;
    if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1
    end
end;

procedure chVol_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
inc(cVolumeDelta, 3)
end;

procedure chVol_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
dec(cVolumeDelta, 3)
end;

procedure chFindhh(var s: shortstring);
begin
s:= s; // avoid compiler hint
if CheckNoTeamOrHH or isPaused then exit;
bShowFinger:= true;
FollowGear:= CurrentHedgehog^.Gear
end;

procedure chPause(var s: shortstring);
begin
s:= s; // avoid compiler hint
if ReadyTimeLeft > 1 then ReadyTimeLeft:= 1;
if gameType <> gmtNet then
    isPaused:= not isPaused;
SDL_ShowCursor(ord(isPaused))
end;

procedure chRotateMask(var s: shortstring);
begin
s:= s; // avoid compiler hint
if ((GameFlags and gfInvulnerable) = 0) then cTagsMask:= cTagsMasks[cTagsMask] else cTagsMask:= cTagsMasksNoHealth[cTagsMask];
end;

procedure chSpeedup_p(var s: shortstring);
begin
s:= s; // avoid compiler hint
isSpeed:= true
end;

procedure chSpeedup_m(var s: shortstring);
begin
s:= s; // avoid compiler hint
isSpeed:= false
end;

procedure chZoomIn(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    if ZoomValue < cMinZoomLevel then
        ZoomValue:= ZoomValue + cZoomDelta;
end;

procedure chZoomOut(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    if ZoomValue > cMaxZoomLevel then
        ZoomValue:= ZoomValue - cZoomDelta;
end;

procedure chZoomReset(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    ZoomValue:= cDefaultZoomLevel;
end;

procedure chChat(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    GameState:= gsChat;
    KeyPressChat(27)
end;

procedure chHistory(var s: shortstring);
begin
    s:= s; // avoid compiler hint
    uChat.showAll:= not uChat.showAll
end;


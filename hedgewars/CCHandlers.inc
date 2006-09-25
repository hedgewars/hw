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

function CheckNoTeamOrHH: boolean;
begin
Result:= (CurrentTeam=nil) or (CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear = nil);
{$IFDEF DEBUGFILE}
if Result then
   if CurrentTeam = nil then AddFileLog('CONSOLE: CurTeam = nil')
                        else AddFileLog('CONSOLE: CurTeam <> nil, Gear = nil')
{$ENDIF}
end;
////////////////////////////////////////////////////////////////////////////////
procedure chQuit(var s: shortstring);
begin
GameState:= gsExit
end;

procedure chAddTeam(var s: shortstring);
const TeamsCount: Longword = 0;
begin
if isDeveloperMode then
   begin
   inc(TeamsCount);
   TryDo(TeamsCount <= 5, 'Too many teams', true);
   AddTeam
   end;
   
if GameType in [gmtDemo, gmtSave] then CurrentTeam.ExtDriven:= true
end;

procedure chTeamLocal(var s: shortstring);
begin
if not isDeveloperMode then exit;
if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/rdriven"', true);
CurrentTeam.ExtDriven:= true
end;

procedure chName(var id: shortstring);
var s: shortstring;
begin
if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/name"', true);
SplitBySpace(id, s);
if s[1]='"' then Delete(s, 1, 1);
if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
if id = 'team' then CurrentTeam.TeamName:= s
else if (id[1] = 'h') and (id[2] = 'h')
     and (id[3] >= '0') and (id[3] <= chr(ord('0')+cMaxHHIndex)) then
   CurrentTeam.Hedgehogs[byte(id[3])-48].Name:= s
else OutError(errmsgUnknownVariable + ' "' + id + '"')
end;

procedure chGrave(var s: shortstring);
begin
if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/grave"', true);
if s[1]='"' then Delete(s, 1, 1);
if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
CurrentTeam.GraveName:= s
end;

procedure chFort(var s: shortstring);
begin
if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/grave"', true);
if s[1]='"' then Delete(s, 1, 1);
if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
CurrentTeam.FortName:= s
end;

procedure chColor(var id: shortstring);
var c: integer;
begin
if CurrentTeam = nil then OutError(errmsgIncorrectUse + ' "/color"', true);
val(id, CurrentTeam.Color, c);
AdjustColor(CurrentTeam.Color)
end;

procedure chAdd(var id: shortstring);
var s: shortstring;
    c: integer;
    Gear: PGear;
    b: byte;
begin
if (not isDeveloperMode)or(CurrentTeam=nil) then exit;
SplitBySpace(id, s);
if (id[1]='h')and(id[2]='h')and(id[3]>='0')and(id[3]<='7') then
   begin
   b:= byte(id[3])-48;
   val(s, CurrentTeam.Hedgehogs[b].BotLevel, c);
   Gear:= AddGear(0, 0, gtHedgehog, 0);
   Gear.Hedgehog:= @CurrentTeam.Hedgehogs[b];
   PHedgehog(Gear.Hedgehog).Team:= CurrentTeam;
   CurrentTeam.Hedgehogs[b].Gear:= Gear
   end
else OutError(errmsgUnknownVariable + ' "' + id + '"', true)
end;

procedure chBind(var id: shortstring);
var s: shortstring;
    b: integer;
begin
if CurrentTeam = nil then exit;
SplitBySpace(id, s);
if s[1]='"' then Delete(s, 1, 1);
if s[byte(s[0])]='"' then Delete(s, byte(s[0]), 1);
b:= KeyNameToCode(id);
if b = 0 then OutError(errmsgUnknownVariable + ' "' + id + '"')
         else CurrentTeam.Aliases[b]:= s
end;

procedure chLeft_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('L');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
    Message:= Message or gm_Left
end;

procedure chLeft_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('l');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
     Message:= Message and not gm_Left
end;

procedure chRight_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('R');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
    Message:= Message or gm_Right
end;

procedure chRight_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('r');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
     Message:= Message and not gm_Right
end;

procedure chUp_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('U');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
    Message:= Message or gm_Up
end;

procedure chUp_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('u');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
     Message:= Message and not gm_Up
end;

procedure chDown_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('D');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
    Message:= Message or gm_Down
end;

procedure chDown_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('d');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
     Message:= Message and not gm_Down
end;

procedure chLJump(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('j');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
    Message:= Message or gm_LJump
end;

procedure chHJump(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('J');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
    Message:= Message or gm_HJump
end;

procedure chAttack_p(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
     begin
     {$IFDEF DEBUGFILE}AddFileLog('/+attack: Gear.State = '+inttostr(State));{$ENDIF}
     if ((State and gstHHDriven)<>0)and((State and (gstAttacked or gstHHChooseTarget or gstMoving)) = 0) then
        begin
        FollowGear:= CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear;
        if not CurrentTeam.ExtDriven then SendIPC('A');
        Message:= Message or gm_Attack
        end
     end
end;

procedure chAttack_m(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
     begin
     if not CurrentTeam.ExtDriven and
        ((Message and gm_Attack) <> 0) then SendIPC('a');
     Message:= Message and not gm_Attack
     end
end;

procedure chSwitch(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if not CurrentTeam.ExtDriven then SendIPC('S');
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
     Message:= Message or gm_Switch
end;

procedure chNextTurn(var s: shortstring);
begin
if AllInactive then
   begin
   if not CurrentTeam.ExtDriven then SendIPC('N');
   {$IFDEF DEBUGFILE}AddFileLog('Doing SwitchHedgehog: time '+inttostr(GameTicks));{$ENDIF}
   SwitchHedgehog;
   end
end;

procedure chSay(var s: shortstring);
begin
WriteLnToConsole('> ' + s);
SendIPC('s'+s)
end;

procedure chTimer(var s: shortstring);
begin
if (s[0] <> #1) or (s[1] < '1') or (s[1] > '5') or (CurrentTeam = nil) then exit;
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     if (Ammo[CurSlot, CurAmmo].Propz and ammoprop_Timerable) <> 0 then
        begin
        Ammo[CurSlot, CurAmmo].Timer:= 1000 * (byte(s[1]) - 48);
        with CurrentTeam^ do
             ApplyAmmoChanges(Hedgehogs[CurrHedgehog]);
        if not CurrentTeam.ExtDriven then SendIPC(s);
        end
end;

procedure chSlot(var s: shortstring);
var slot: LongWord;
    caSlot, caAmmo: PLongword;
begin
if (s[0] <> #1) or CheckNoTeamOrHH then exit;
slot:= byte(s[1]) - 49;
if slot > cMaxSlotIndex then exit;
if not CurrentTeam.ExtDriven then SendIPC(char(byte(s[1]) + 79));
with CurrentTeam^ do
     begin
     with Hedgehogs[CurrHedgehog] do
          begin
          if ((Gear.State and (gstAttacking or gstAttacked)) <> 0) or (AttacksNum > 0)
             or ((Gear.State and gstHHDriven) = 0) then exit; // во время стрельбы исключает смену оружия
          if CurAmmoGear = nil then begin caSlot:= @CurSlot; caAmmo:= @CurAmmo end
                               else begin caSlot:= @AltSlot; caAmmo:= @AltAmmo end;
          if caSlot^ = slot then
             begin
             inc(caAmmo^);
             if (caAmmo^ > cMaxSlotAmmoIndex) or (Ammo[slot, caAmmo^].Count = 0) then caAmmo^:= 0
             end else
             if Ammo[slot, 0].Count > 0 then
                begin
                caSlot^:= slot;
                caAmmo^:= 0;
                end;
          end;
     ApplyAmmoChanges(Hedgehogs[CurrHedgehog])
     end
end;

procedure chPut(var s: shortstring);
begin
if CheckNoTeamOrHH then exit;
if bShowAmmoMenu then
   begin
   bSelected:= true;
   exit
   end;
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear^ do
     if (State and gstHHChooseTarget) <> 0 then
        begin
        isCursorVisible:= false;
        if not CurrentTeam.ExtDriven then
           begin
           SDL_GetMouseState(@TargetPoint.X, @TargetPoint.Y);
           dec(TargetPoint.X, WorldDx);
           dec(TargetPoint.Y, WorldDy);
           SendIPCXY('p', TargetPoint.X, TargetPoint.Y);
           end;
        State:= State and not gstHHChooseTarget;
        end else if CurrentTeam.ExtDriven then OutError('got /put while not being in choose target mode', false)
end;

procedure chCapture(var s: shortstring);
begin
flagMakeCapture:= true
end;

procedure chSkip(var s: shortstring);
begin
if not CurrentTeam.ExtDriven then SendIPC(',');
TurnTimeLeft:= 0
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
          else if ((Gear.State and (gstAttacking or gstAttacked)) <> 0) or (AttacksNum > 0)
               or ((Gear.State and gstHHDriven) = 0) then else bShowAmmoMenu:= true
          end
end;

procedure chFullScr(var s: shortstring);
var flags: Longword;
begin
if Length(s) = 0 then cFullScreen:= not cFullScreen
                 else cFullScreen:= s = '1';
   
flags:= SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_HWACCEL;
if cFullScreen then flags:= flags or SDL_FULLSCREEN
               else SDL_WM_SetCaption('Hedgewars', nil);
SDL_FreeSurface(SDLPrimSurface);
SDLPrimSurface:= SDL_SetVideoMode(cScreenWidth, cScreenHeight, cBits, flags);
TryDo(SDLPrimSurface <> nil, errmsgCreateSurface, true);
PixelFormat:= SDLPrimSurface.format;
SDL_ShowCursor(0)
end;


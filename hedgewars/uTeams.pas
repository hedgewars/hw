(*
 * Hedgewars, a worms-like game
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

unit uTeams;
interface
uses SDLh, uConsts, uKeys, uGears, uRandom, uFloat;
{$INCLUDE options.inc}

type PHHAmmo = ^THHAmmo;
     THHAmmo = array[0..cMaxSlotIndex, 0..cMaxSlotAmmoIndex] of TAmmo;

type PHedgehog = ^THedgehog;
     PTeam     = ^TTeam;
     THedgehog = record
                 Name: string[MAXNAMELEN];
                 Gear: PGear;
                 NameTag, HealthTag: PSDL_Surface;
                 Ammo: PHHAmmo;
                 AmmoStore: Longword;
                 CurSlot, CurAmmo: LongWord;
                 AltSlot, AltAmmo: LongWord;
                 Team: PTeam;
                 AttacksNum: Longword;
                 visStepPos: LongWord;
                 BotLevel  : LongWord; // 0 - Human player
                 DamageGiven: Longword;
                 MaxStepDamage: Longword;
                 end;
     TTeam = record
             Color, AdjColor: Longword;
             TeamName: string[MAXNAMELEN];
             ExtDriven: boolean;
             Binds: TBinds;
             Hedgehogs: array[0..cMaxHHIndex] of THedgehog;
             CurrHedgehog: LongInt;
             NameTag: PSDL_Surface;
             CrosshairSurf: PSDL_Surface;
             GraveRect, HealthRect: TSDL_Rect;
             GraveName: string;
             FortName: string;
             TeamHealth: LongInt;
             TeamHealthBarWidth: LongInt;
             DrawHealthY: LongInt;
             AttackBar: LongWord;
             HedgehogsNumber: byte;
             end;

var CurrentTeam: PTeam = nil;
    TeamsArray: array[0..Pred(cMaxTeams)] of PTeam;
    TeamsCount: Longword = 0;
    CurMinAngle, CurMaxAngle: Longword;

function AddTeam: PTeam;
procedure ApplyAmmoChanges(var Hedgehog: THedgehog);
procedure SwitchHedgehog;
procedure InitTeams;
function  TeamSize(p: PTeam): Longword;
procedure RecountTeamHealth(team: PTeam);
procedure RestoreTeamsFromSave;
function CheckForWin: boolean;
procedure SetWeapon(weap: TAmmoType);
procedure SendStats;

implementation
uses uMisc, uWorld, uAI, uLocale, uConsole, uAmmos;
const MaxTeamHealth: LongInt = 0;

procedure FreeTeamsList; forward;

function CheckForWin: boolean;
var team, AliveTeam: PTeam;
    s: shortstring;
begin
if TeamsCount >= 2 then exit(false);
CheckForWin:= true;

TurnTimeLeft:= 0;
if TeamsCount = 0 then
   begin // draw
   AddCaption(trmsg[sidDraw], $FFFFFF, capgrpGameState);
   SendStat(siGameResult, trmsg[sidDraw]);
   AddGear(0, 0, gtATFinishGame, 0, _0, _0, 2000)
   end else // win
   begin
   s:= Format(trmsg[sidWinner], TeamsArray[0]^.TeamName);
   AddCaption(s, $FFFFFF, capgrpGameState);
   SendStat(siGameResult, s);
   AddGear(0, 0, gtATFinishGame, 0, _0, _0, 2000)
   end;
SendStats
end;

procedure SwitchHedgehog;
var th: LongInt;
    t: LongWord;
    g: PGear;
begin
FreeActionsList;
TargetPoint.X:= NoPointX;
TryDo(CurrentTeam <> nil, 'nil Team', true);

with CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog] do
     if Gear <> nil then
        begin
        AttacksNum:= 0;
        Gear^.Message:= 0;
        Gear^.Z:= cHHZ;
        RemoveGearFromList(Gear);
        InsertGearToList(Gear)
        end;

t:= 0;
while CurrentTeam <> TeamsArray[t] do inc(t);
CurrentTeam:= TeamsArray[(t + 1) mod TeamsCount];

th:= CurrentTeam^.CurrHedgehog;
repeat
  CurrentTeam^.CurrHedgehog:= Succ(CurrentTeam^.CurrHedgehog) mod (cMaxHHIndex + 1);
until (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil) or (CurrentTeam^.CurrHedgehog = th);

with CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog] do
     begin
     with Gear^ do
          begin
          Z:= cCurrHHZ;
          State:= gstHHDriven;
          Active:= true
          end;
     RemoveGearFromList(Gear);
     InsertGearToList(Gear);
     FollowGear:= Gear
     end;
ResetKbd;

cWindSpeed:= rndSign(GetRandom * cMaxWindSpeed);
g:= AddGear(0, 0, gtATSmoothWindCh, 0, _0, _0, 1);
g^.Tag:= hwRound(cWindSpeed * 72 / cMaxWindSpeed);
{$IFDEF DEBUGFILE}AddFileLog('Wind = '+FloatToStr(cWindSpeed));{$ENDIF}
ApplyAmmoChanges(CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog]);
if CurrentTeam^.ExtDriven then SetDefaultBinds
                          else SetBinds(CurrentTeam^.Binds);
bShowFinger:= true;
TurnTimeLeft:= cHedgehogTurnTime
end;

function AddTeam: PTeam;
var Result: PTeam;
begin
TryDo(TeamsCount <= cMaxTeams, 'Too many teams', true);
New(Result);
TryDo(Result <> nil, 'AddTeam: Result = nil', true);
FillChar(Result^, sizeof(TTeam), 0);
Result^.AttackBar:= 2;
Result^.CurrHedgehog:= cMaxHHIndex;

TeamsArray[TeamsCount]:= Result;
inc(TeamsCount);

CurrentTeam:= Result;
AddTeam:= Result
end;

procedure FreeTeamsList;
var t: LongInt;
begin
for t:= 0 to Pred(TeamsCount) do Dispose(TeamsArray[t]);
TeamsCount:= 0
end;

procedure RecountAllTeamsHealth;
var t: LongInt;
begin 
for t:= 0 to Pred(TeamsCount) do
    RecountTeamHealth(TeamsArray[t])
end;

procedure InitTeams;
var i, t: LongInt;
    th: LongInt;
begin
for t:= 0 to Pred(TeamsCount) do
   with TeamsArray[t]^ do
      begin
      th:= 0;
      for i:= 0 to cMaxHHIndex do
          if Hedgehogs[i].Gear <> nil then
             inc(th, Hedgehogs[i].Gear^.Health);
      if th > MaxTeamHealth then MaxTeamHealth:= th;
      end;
RecountAllTeamsHealth
end;

procedure ApplyAmmoChanges(var Hedgehog: THedgehog);
var s: shortstring;
begin
TargetPoint.X:= NoPointX;

with Hedgehog do
     begin
     if Ammo^[CurSlot, CurAmmo].Count = 0 then
        begin
        CurAmmo:= 0;
        CurSlot:= 0;
        while (CurSlot <= cMaxSlotIndex) and (Ammo^[CurSlot, CurAmmo].Count = 0) do inc(CurSlot)
        end;

with Ammo^[CurSlot, CurAmmo] do
     begin
     CurMinAngle:= Ammoz[AmmoType].minAngle;
     if Ammoz[AmmoType].maxAngle <> 0 then CurMaxAngle:= Ammoz[AmmoType].maxAngle
                                      else CurMaxAngle:= cMaxAngle;
     with Hedgehog.Gear^ do
        begin
        if Angle < CurMinAngle then Angle:= CurMinAngle;
        if Angle > CurMaxAngle then Angle:= CurMaxAngle;
        end;

     s:= trammo[Ammoz[AmmoType].NameId];
     if Count <> AMMO_INFINITE then
        s:= s + ' (' + IntToStr(Count) + ')';
     if (Propz and ammoprop_Timerable) <> 0 then
        s:= s + ', ' + inttostr(Timer div 1000) + ' ' + trammo[sidSeconds];
     AddCaption(s, Team^.Color, capgrpAmmoinfo);
     if (Propz and ammoprop_NeedTarget) <> 0
        then begin
        Gear^.State:= Gear^.State or      gstHHChooseTarget;
        isCursorVisible:= true
        end else begin
        Gear^.State:= Gear^.State and not gstHHChooseTarget;
        isCursorVisible:= false
        end;
     ShowCrosshair:= (Propz and ammoprop_NoCrosshair) = 0
     end
     end
end;

function  TeamSize(p: PTeam): Longword;
var i, Result: Longword;
begin
Result:= 0;
for i:= 0 to cMaxHHIndex do
    if p^.Hedgehogs[i].Gear <> nil then inc(Result);
TeamSize:= Result
end;

procedure RecountTeamHealth(team: PTeam);
var i: LongInt;
begin
with team^ do
     begin
     TeamHealthBarWidth:= 0;
     for i:= 0 to cMaxHHIndex do
         if Hedgehogs[i].Gear <> nil then
            inc(TeamHealthBarWidth, Hedgehogs[i].Gear^.Health);
     TeamHealth:= TeamHealthBarWidth;
     if TeamHealthBarWidth > MaxTeamHealth then
        begin
        MaxTeamHealth:= TeamHealthBarWidth;
        RecountAllTeamsHealth;
        end else TeamHealthBarWidth:= (TeamHealthBarWidth * cTeamHealthWidth) div MaxTeamHealth
     end;
// FIXME: at the game init, gtTeamHealthSorters are created for each team, and they work simultaneously
AddGear(0, 0, gtTeamHealthSorter, 0, _0, _0, 0)
end;

procedure RestoreTeamsFromSave;
var t: LongInt;
begin
for t:= 0 to Pred(TeamsCount) do
   TeamsArray[t]^.ExtDriven:= false
end;

procedure SetWeapon(weap: TAmmoType);
var t: LongInt;
begin
t:= cMaxSlotAmmoIndex;
with CurrentTeam^ do
     with Hedgehogs[CurrHedgehog] do
          while (Ammo^[CurSlot, CurAmmo].AmmoType <> weap) and (t >= 0) do
                begin
                ParseCommand('/slot ' + chr(49 + Ammoz[TAmmoType(weap)].Slot), true);
                dec(t)
                end
end;

procedure SendStats;
var i, t: LongInt;
    msd: Longword; msdhh: PHedgehog;
begin
msd:= 0; msdhh:= nil;
for t:= 0 to Pred(TeamsCount) do
   with TeamsArray[t]^ do
      begin
      for i:= 0 to cMaxHHIndex do
          if Hedgehogs[i].MaxStepDamage > msd then
             begin
             msdhh:= @Hedgehogs[i];
             msd:= Hedgehogs[i].MaxStepDamage
             end;
      end;
if msdhh <> nil then SendStat(siMaxStepDamage, inttostr(msdhh^.MaxStepDamage) + ' ' +
                                               msdhh^.Name + ' (' + msdhh^.Team^.TeamName + ')');
if KilledHHs > 0 then SendStat(siKilledHHs, inttostr(KilledHHs));
end;

initialization

finalization

FreeTeamsList

end.

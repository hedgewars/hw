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

unit uTeams;
interface
uses SDLh, uConsts, uKeys, uGears, uRandom, uAmmos;
{$INCLUDE options.inc}
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
             Next: PTeam;
             Color, AdjColor: Longword;
             TeamName: string[MAXNAMELEN];
             ExtDriven: boolean;
             Binds: TBinds;
             Hedgehogs: array[0..cMaxHHIndex] of THedgehog;
             CurrHedgehog: integer;
             NameTag: PSDL_Surface;
             CrosshairSurf: PSDL_Surface;
             GraveRect, HealthRect: TSDL_Rect;
             GraveName: string;
             FortName: string;
             TeamHealth: integer;
             TeamHealthBarWidth: integer;
             DrawHealthY: integer;
             AttackBar: LongWord;
             end;

var CurrentTeam: PTeam = nil;
    TeamsList: PTeam = nil;
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
uses uMisc, uWorld, uAI, uLocale, uConsole;
const MaxTeamHealth: integer = 0;

procedure FreeTeamsList; forward;

function CheckForWin: boolean;
var team, AliveTeam: PTeam;
    AliveCount: Longword;
    s: shortstring;
begin
Result:= false;
AliveCount:= 0;
AliveTeam:= nil;
team:= TeamsList;
while team <> nil do
      begin
      if team.TeamHealth > 0 then
         begin
         inc(AliveCount);
         AliveTeam:= team
         end;
      team:= team.Next
      end;

if AliveCount >= 2 then exit;
Result:= true;

TurnTimeLeft:= 0;
if AliveCount = 0 then
   begin // draw
   AddCaption(trmsg[sidDraw], $FFFFFF, capgrpGameState);
   SendStat(siGameResult, trmsg[sidDraw]);
   AddGear(0, 0, gtATFinishGame, 0, 0, 0, 2000)
   end else // win
   begin
   s:= Format(trmsg[sidWinner], AliveTeam.TeamName);
   AddCaption(s, $FFFFFF, capgrpGameState);
   SendStat(siGameResult, s);
   AddGear(0, 0, gtATFinishGame, 0, 0, 0, 2000)
   end;
SendStats
end;

procedure SwitchHedgehog;
var tteam: PTeam;
    th: integer;
begin
FreeActionsList;
TargetPoint.X:= NoPointX;
TryDo(CurrentTeam <> nil, 'nil Team', true);
tteam:= CurrentTeam;
with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     if Gear <> nil then
        begin
        Gear.Message:= 0;
        Gear.Z:= cHHZ
        end;

repeat
  CurrentTeam:= CurrentTeam.Next;
  if CurrentTeam = nil then CurrentTeam:= TeamsList;
  th:= CurrentTeam.CurrHedgehog;
  repeat
    CurrentTeam.CurrHedgehog:= Succ(CurrentTeam.CurrHedgehog) mod (cMaxHHIndex + 1);
  until (CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear <> nil) or (CurrentTeam.CurrHedgehog = th)
until (CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear <> nil) or (CurrentTeam = tteam);

TryDo(CurrentTeam <> tteam, 'Switch hedgehog: only one team?!', true);

with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
     begin
     AttacksNum:= 0;
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
cWindSpeed:= (GetRandom * 2 - 1) * cMaxWindSpeed;
AddGear(0, 0, gtATSmoothWindCh, 0, 0, 0, 1).Tag:= round(72 * cWindSpeed / cMaxWindSpeed);
{$IFDEF DEBUGFILE}AddFileLog('Wind = '+FloatToStr(cWindSpeed));{$ENDIF}
ApplyAmmoChanges(CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog]);
if CurrentTeam.ExtDriven then SetDefaultBinds
                         else SetBinds(CurrentTeam.Binds);
bShowFinger:= true;
TurnTimeLeft:= cHedgehogTurnTime
end;

function AddTeam: PTeam;
begin
New(Result);
TryDo(Result <> nil, 'AddTeam: Result = nil', true);
FillChar(Result^, sizeof(TTeam), 0);
Result.AttackBar:= 2;
Result.CurrHedgehog:= cMaxHHIndex;
if TeamsList = nil then TeamsList:= Result
                   else begin
                        Result.Next:= TeamsList;
                        TeamsList:= Result
                        end;
CurrentTeam:= Result
end;

procedure FreeTeamsList;
var t, tt: PTeam;
begin
tt:= TeamsList;
TeamsList:= nil;
while tt<>nil do
      begin
      t:= tt;
      tt:= tt.Next;
      Dispose(t)
      end;
end;

procedure RecountAllTeamsHealth;
var p: PTeam;
begin
p:= TeamsList;
while p <> nil do
      begin
      RecountTeamHealth(p);
      p:= p.Next
      end
end;

procedure InitTeams;
var p: PTeam;
    i: integer;
    th: integer;
begin
p:= TeamsList;
while p <> nil do
      begin
      th:= 0;
      for i:= 0 to cMaxHHIndex do
          if p.Hedgehogs[i].Gear <> nil then
             begin
             p.Hedgehogs[i].Gear.Health:= 100;
             inc(th, 100);
             end;
      if th > MaxTeamHealth then MaxTeamHealth:= th;
      p:= p.Next
      end;
RecountAllTeamsHealth
end;

procedure ApplyAmmoChanges(var Hedgehog: THedgehog);
var s: shortstring;
begin
TargetPoint.X:= NoPointX;

with Hedgehog do
     begin
     if Ammo[CurSlot, CurAmmo].Count = 0 then
        begin
        CurAmmo:= 0;
        CurSlot:= 0;
        while (CurSlot <= cMaxSlotIndex) and (Ammo[CurSlot, CurAmmo].Count = 0) do inc(CurSlot)
        end;

with Ammo[CurSlot, CurAmmo] do
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
     AddCaption(s, Team.Color, capgrpAmmoinfo);
     if (Propz and ammoprop_NeedTarget) <> 0
        then begin
        Gear.State:= Gear.State or      gstHHChooseTarget;
        isCursorVisible:= true
        end else begin
        Gear.State:= Gear.State and not gstHHChooseTarget;
        isCursorVisible:= false
        end;
     ShowCrosshair:= (Propz and ammoprop_NoCrosshair) = 0
     end
     end
end;

function  TeamSize(p: PTeam): Longword;
var i: Longword;
begin
Result:= 0;
for i:= 0 to cMaxHHIndex do
    if p.Hedgehogs[i].Gear <> nil then inc(Result)
end;

procedure RecountTeamHealth(team: PTeam);
var i: integer;
begin
with team^ do
     begin
     TeamHealthBarWidth:= 0;
     for i:= 0 to cMaxHHIndex do
         if Hedgehogs[i].Gear <> nil then
            inc(TeamHealthBarWidth, Hedgehogs[i].Gear.Health);
     TeamHealth:= TeamHealthBarWidth;
     if TeamHealthBarWidth > MaxTeamHealth then
        begin
        MaxTeamHealth:= TeamHealthBarWidth;
        RecountAllTeamsHealth;
        end else TeamHealthBarWidth:= (TeamHealthBarWidth * cTeamHealthWidth) div MaxTeamHealth
     end;
// FIXME: at the game init, gtTeamHealthSorters are created for each team, and they work simultaneously
AddGear(0, 0, gtTeamHealthSorter, 0)
end;

procedure RestoreTeamsFromSave;
var p: PTeam;
begin
p:= TeamsList;
while p <> nil do
      begin
      p.ExtDriven:= false;
      p:= p.Next
      end;
end;

procedure SetWeapon(weap: TAmmoType);
var t: integer;
begin
t:= cMaxSlotAmmoIndex;
with CurrentTeam^ do
     with Hedgehogs[CurrHedgehog] do
          while (Ammo[CurSlot, CurAmmo].AmmoType <> weap) and (t >= 0) do
                begin
                ParseCommand('/slot ' + chr(49 + Ammoz[TAmmoType(weap)].Slot));
                dec(t)
                end
end;

procedure SendStats;
var p: PTeam;
    i: integer;
    msd: Longword; msdhh: PHedgehog;
begin
msd:= 0; msdhh:= nil;
p:= TeamsList;
while p <> nil do
      begin
      for i:= 0 to cMaxHHIndex do
          if p.Hedgehogs[i].MaxStepDamage > msd then
             begin
             msdhh:= @p.Hedgehogs[i];
             msd:= p.Hedgehogs[i].MaxStepDamage
             end;
      p:= p.Next
      end;
if msdhh <> nil then SendStat(siMaxStepDamage, inttostr(msdhh.MaxStepDamage) + ' ' +
                                               msdhh.Name + ' (' + msdhh.Team.TeamName + ')');
if KilledHHs > 0 then SendStat(siKilledHHs, inttostr(KilledHHs));
end;

initialization

finalization

FreeTeamsList

end.

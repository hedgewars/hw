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
     PClan     = ^TClan;
     THedgehog = record
                 Name: string[MAXNAMELEN];
                 Gear: PGear;
                 NameTagTex: PTexture;
                 HealthTagTex: PTexture;
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
             Clan: PClan;
             TeamName: string[MAXNAMELEN];
             ExtDriven: boolean;
             Binds: TBinds;
             Hedgehogs: array[0..cMaxHHIndex] of THedgehog;
             CurrHedgehog: LongWord;
             NameTagTex: PTexture;
             CrosshairTex,
             GraveTex,
             HealthTex: PTexture;
             GraveName: string;
             FortName: string;
             TeamHealth: LongInt;
             TeamHealthBarWidth,
             NewTeamHealthBarWidth: LongInt;
             DrawHealthY: LongInt;
             AttackBar: LongWord;
             HedgehogsNumber: Longword;
             end;
     TClan = record
             Color: Longword;
             Teams: array[0..Pred(cMaxTeams)] of PTeam;
             TeamsNumber: Longword;
             CurrTeam: LongWord;
             ClanHealth: LongInt;
             ClanIndex: LongInt;
             end;

var CurrentTeam: PTeam = nil;
    CurrentHedgehog: PHedgehog = nil;
    TeamsArray: array[0..Pred(cMaxTeams)] of PTeam;
    TeamsCount: Longword = 0;
    ClansArray: array[0..Pred(cMaxTeams)] of PClan;
    ClansCount: Longword = 0;
    CurMinAngle, CurMaxAngle: Longword;

function AddTeam(TeamColor: Longword): PTeam;
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
var AliveClan: PClan;
    s: shortstring;
    t, AliveCount: LongInt;
begin
AliveCount:= 0;
for t:= 0 to Pred(ClansCount) do
    if ClansArray[t]^.ClanHealth > 0 then
       begin
       inc(AliveCount);
       AliveClan:= ClansArray[t]
       end;

if  (AliveCount > 1) or
   ((AliveCount = 1) and ((GameFlags and gfOneClanMode) <> 0)) then exit(false);
CheckForWin:= true;

TurnTimeLeft:= 0;
if AliveCount = 0 then
   begin // draw
   AddCaption(trmsg[sidDraw], $FFFFFF, capgrpGameState);
   SendStat(siGameResult, trmsg[sidDraw]);
   AddGear(0, 0, gtATFinishGame, 0, _0, _0, 2000)
   end else // win
   with AliveClan^ do
     begin
     if TeamsNumber = 1 then
        s:= Format(trmsg[sidWinner], Teams[0]^.TeamName)  // team wins
     else
        s:= Format(trmsg[sidWinner], Teams[0]^.TeamName); // clan wins

     AddCaption(s, $FFFFFF, capgrpGameState);
     SendStat(siGameResult, s);
     AddGear(0, 0, gtATFinishGame, 0, _0, _0, 2000)
     end;
SendStats
end;

procedure SwitchHedgehog;
var c: LongWord;
    g: PGear;
    PrevHH, PrevTeam: LongWord;
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
        SwitchNotHoldedAmmo(CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog]);
        RemoveGearFromList(Gear);
        InsertGearToList(Gear)
        end;

c:= CurrentTeam^.Clan^.ClanIndex;
repeat
  c:= Succ(c) mod ClansCount;
  with ClansArray[c]^ do
    repeat
    PrevTeam:= CurrTeam;
    CurrTeam:= Succ(CurrTeam) mod TeamsNumber;
    CurrentTeam:= Teams[CurrTeam];
    with CurrentTeam^ do
      begin
      PrevHH:= CurrHedgehog;
      repeat
        CurrHedgehog:= Succ(CurrHedgehog) mod HedgehogsNumber;
      until (Hedgehogs[CurrHedgehog].Gear <> nil) or (CurrHedgehog = PrevHH)
      end
    until (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil) or (PrevTeam = CurrTeam);
until CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil;

CurrentHedgehog:= @(CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog]);
with CurrentHedgehog^ do
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
ApplyAmmoChanges(CurrentHedgehog^);
if CurrentTeam^.ExtDriven then SetDefaultBinds
                          else SetBinds(CurrentTeam^.Binds);
bShowFinger:= true;
TurnTimeLeft:= cHedgehogTurnTime
end;

function AddTeam(TeamColor: Longword): PTeam;
var Result: PTeam;
    c: LongInt;
begin
TryDo(TeamsCount <= cMaxTeams, 'Too many teams', true);
New(Result);
TryDo(Result <> nil, 'AddTeam: Result = nil', true);
FillChar(Result^, sizeof(TTeam), 0);
Result^.AttackBar:= 2;
Result^.CurrHedgehog:= cMaxHHIndex;

TeamsArray[TeamsCount]:= Result;
inc(TeamsCount);

c:= Pred(ClansCount);
while (c >= 0) and (ClansArray[c]^.Color <> TeamColor) do dec(c);
if c < 0 then
   begin
   new(Result^.Clan);
   FillChar(Result^.Clan^, sizeof(TClan), 0);
   ClansArray[ClansCount]:= Result^.Clan;
   inc(ClansCount);
   with Result^.Clan^ do
        begin
        ClanIndex:= Pred(ClansCount);
        Color:= TeamColor
        end
   end else
   begin
   Result^.Clan:= ClansArray[c];
   end;

with Result^.Clan^ do
    begin
    Teams[TeamsNumber]:= Result;
    inc(TeamsNumber)
    end;

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

function  TeamSize(p: PTeam): Longword;
var i, Result: Longword;
begin
Result:= 0;
for i:= 0 to cMaxHHIndex do
    if p^.Hedgehogs[i].Gear <> nil then inc(Result);
TeamSize:= Result
end;

procedure RecountClanHealth(clan: PClan);
var i: LongInt;
begin
with clan^ do
    begin
    ClanHealth:= 0;
    for i:= 0 to Pred(TeamsNumber) do
        inc(ClanHealth, Teams[i]^.TeamHealth)
    end
end;

procedure RecountTeamHealth(team: PTeam);
var i: LongInt;
begin
with team^ do
     begin
     NewTeamHealthBarWidth:= 0;
     for i:= 0 to cMaxHHIndex do
         if Hedgehogs[i].Gear <> nil then
            inc(NewTeamHealthBarWidth, Hedgehogs[i].Gear^.Health);
     TeamHealth:= NewTeamHealthBarWidth;
     if NewTeamHealthBarWidth > MaxTeamHealth then
        begin
        MaxTeamHealth:= NewTeamHealthBarWidth;
        RecountAllTeamsHealth;
        end else NewTeamHealthBarWidth:= (NewTeamHealthBarWidth * cTeamHealthWidth) div MaxTeamHealth
     end;

RecountClanHealth(team^.Clan);

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

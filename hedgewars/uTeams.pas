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

unit uTeams;
interface
uses uConsts, uKeys, uGears, uRandom, uFloat, uStats, uVisualGears, uCollisions, GLunit, uSound;

type PHHAmmo = ^THHAmmo;
    THHAmmo = array[0..cMaxSlotIndex, 0..cMaxSlotAmmoIndex] of TAmmo;

    PHedgehog = ^THedgehog;
    PTeam     = ^TTeam;
    PClan     = ^TClan;

    THedgehog = record
            Name: string[MAXNAMELEN];
            Gear: PGear;
            SpeechGear: PVisualGear;
            NameTagTex,
            HealthTagTex,
            HatTex: PTexture;
            Ammo: PHHAmmo;
            AmmoStore: Longword;
            CurSlot, CurAmmo: LongWord;
            Team: PTeam;
            MultiShootAttacks: Longword;
            visStepPos: LongWord;
            BotLevel  : Byte; // 0 - Human player
            HatVisibility: GLfloat;
            stats: TStatistics;
            Hat: shortstring;
            King: boolean;  // Flag for a bunch of hedgehog attributes
            Unplaced: boolean;  // Flag for hog placing mode
            Timer: Longword;
            Effects: Array[THogEffect] of boolean;
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
            HealthTex,
            AIKillsTex,
            FlagTex: PTexture;
            Flag: shortstring;
            GraveName: shortstring;
            FortName: shortstring;
            TeamHealth: LongInt;
            TeamHealthBarWidth,
            NewTeamHealthBarWidth: LongInt;
            DrawHealthY: LongInt;
            AttackBar: LongWord;
            HedgehogsNumber: Longword;
            hasGone: boolean;
            voicepack: PVoicepack;
            PlayerHash: shortstring;   // md5 hash of player name. For temporary enabling of hats as thank you. Hashed for privacy of players
            stats: TTeamStats;
            end;

    TClan = record
            Color: Longword;
            Teams: array[0..Pred(cMaxTeams)] of PTeam;
            TeamsNumber: Longword;
            CurrTeam: LongWord;
            ClanHealth: LongInt;
            ClanIndex: LongInt;
            TurnNumber: LongWord;
            end;

var CurrentTeam: PTeam;
    PreviousTeam: PTeam;
    CurrentHedgehog: PHedgehog;
    TeamsArray: array[0..Pred(cMaxTeams)] of PTeam;
    TeamsCount: Longword;
    ClansArray: array[0..Pred(cMaxTeams)] of PClan;
    ClansCount: Longword;
    LocalClan: LongInt;  // last non-bot, non-extdriven clan
    LocalAmmo: LongInt;  // last non-bot, non-extdriven clan's first team's ammo index
    CurMinAngle, CurMaxAngle: Longword;

procedure initModule;
procedure freeModule;
function  AddTeam(TeamColor: Longword): PTeam;
procedure SwitchHedgehog;
procedure AfterSwitchHedgehog;
procedure InitTeams;
function  TeamSize(p: PTeam): Longword;
procedure RecountTeamHealth(team: PTeam);
procedure RestoreTeamsFromSave;
function  CheckForWin: boolean;
procedure TeamGone(s: shortstring);
procedure TeamGoneEffect(var Team: TTeam);
function GetTeamStatString(p: PTeam): shortstring;

implementation
uses uMisc, uWorld, uLocale, uAmmos, uChat;
const MaxTeamHealth: LongInt = 0;

function CheckForWin: boolean;
var AliveClan: PClan;
    s: shortstring;
    t, AliveCount, i, j: LongInt;
begin
AliveCount:= 0;
for t:= 0 to Pred(ClansCount) do
    if ClansArray[t]^.ClanHealth > 0 then
        begin
        inc(AliveCount);
        AliveClan:= ClansArray[t]
        end;

if (AliveCount > 1)
or ((AliveCount = 1) and ((GameFlags and gfOneClanMode) <> 0)) then exit(false);
CheckForWin:= true;

TurnTimeLeft:= 0;
ReadyTimeLeft:= 0;
if AliveCount = 0 then
    begin // draw
    AddCaption(trmsg[sidDraw], cWhiteColor, capgrpGameState);
    SendStat(siGameResult, trmsg[sidDraw]);
    AddGear(0, 0, gtATFinishGame, 0, _0, _0, 3000)
    end else // win
    with AliveClan^ do
        begin
        if TeamsNumber = 1 then
            s:= Format(shortstring(trmsg[sidWinner]), Teams[0]^.TeamName)  // team wins
        else
            s:= Format(shortstring(trmsg[sidWinner]), Teams[0]^.TeamName); // clan wins

        for j:= 0 to Pred(TeamsNumber) do
            with Teams[j]^ do
                for i:= 0 to cMaxHHIndex do
                    with Hedgehogs[i] do
                        if (Gear <> nil) then
                            Gear^.State:= gstWinner;

        AddCaption(s, cWhiteColor, capgrpGameState);
        SendStat(siGameResult, s);
        AddGear(0, 0, gtATFinishGame, 0, _0, _0, 3000)
        end;
SendStats
end;

procedure SwitchHedgehog;
var c: LongWord;
    PrevHH, PrevTeam: LongWord;
begin
TargetPoint.X:= NoPointX;
TryDo(CurrentTeam <> nil, 'nil Team', true);
with CurrentHedgehog^ do
    if (PreviousTeam <> nil) and PlacingHogs and Unplaced then
        begin
        Unplaced:= false;
        if Gear <> nil then
           begin
           DeleteCI(Gear);
           FindPlace(Gear, false, 0, LAND_WIDTH);
           if Gear <> nil then AddGearCI(Gear)
           end
        end;

PreviousTeam:= CurrentTeam;

with CurrentHedgehog^ do
    begin
    if Gear <> nil then
        begin
        MultiShootAttacks:= 0;
        Gear^.Message:= 0;
        Gear^.Z:= cHHZ;
        RemoveGearFromList(Gear);
        InsertGearToList(Gear)
        end
    end;

c:= CurrentTeam^.Clan^.ClanIndex;
repeat
    inc(c);
    if c = ClansCount then
        begin
        if not PlacingHogs then inc(TotalRounds);
        c:= 0
        end;

    with ClansArray[c]^ do
        begin
        PrevTeam:= CurrTeam;
        repeat
            CurrTeam:= Succ(CurrTeam) mod TeamsNumber;
            CurrentTeam:= Teams[CurrTeam];
            with CurrentTeam^ do
                begin
                PrevHH:= CurrHedgehog mod HedgehogsNumber; // prevent infinite loop when CurrHedgehog = 7, but HedgehogsNumber < 8 (team is destroyed before its first turn)
                repeat
                    CurrHedgehog:= Succ(CurrHedgehog) mod HedgehogsNumber;
                until (Hedgehogs[CurrHedgehog].Gear <> nil) or (CurrHedgehog = PrevHH)
                end
        until (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil) or (PrevTeam = CurrTeam);
        end
until (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil);

CurrentHedgehog:= @(CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog])
end;

procedure AfterSwitchHedgehog;
var g: PGear;
    i, t: LongInt;
begin
if PlacingHogs then
   begin
   PlacingHogs:= false;
   for t:= 0 to Pred(TeamsCount) do
      for i:= 0 to cMaxHHIndex do
          if (TeamsArray[t]^.Hedgehogs[i].Gear <> nil) and (TeamsArray[t]^.Hedgehogs[i].Unplaced) then
             PlacingHogs:= true;

   if not PlacingHogs then // Reset  various things I mucked with
      begin
      for i:= 0 to ClansCount do
         if ClansArray[i] <> nil then ClansArray[i]^.TurnNumber:= 0;
      ResetWeapons
      end
   end;

inc(CurrentTeam^.Clan^.TurnNumber);

SwitchNotHeldAmmo(CurrentHedgehog^);

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

cWindSpeed:= rndSign(GetRandom * 2 * cMaxWindSpeed);
g:= AddGear(0, 0, gtATSmoothWindCh, 0, _0, _0, 1);
g^.Tag:= hwRound(cWindSpeed * 72 / cMaxWindSpeed);
{$IFDEF DEBUGFILE}AddFileLog('Wind = '+FloatToStr(cWindSpeed));{$ENDIF}
ApplyAmmoChanges(CurrentHedgehog^);

if not CurrentTeam^.ExtDriven then SetBinds(CurrentTeam^.Binds);

bShowFinger:= true;

if PlacingHogs then
   begin
   if CurrentHedgehog^.Unplaced then TurnTimeLeft:= 15000
   else TurnTimeLeft:= 0
   end
else TurnTimeLeft:= cHedgehogTurnTime;
if (TurnTimeLeft > 0) and (CurrentHedgehog^.BotLevel = 0) then
    begin
    if CurrentTeam^.ExtDriven then
        PlaySound(sndIllGetYou, CurrentTeam^.voicepack)
    else
        PlaySound(sndYesSir, CurrentTeam^.voicepack);
    ReadyTimeLeft:= cReadyDelay
    end
else
    begin
    if TurnTimeLeft > 0 then
        PlaySound(sndIllGetYou, CurrentTeam^.voicepack);
    ReadyTimeLeft:= 0
    end
end;

function AddTeam(TeamColor: Longword): PTeam;
var team: PTeam;
    c: LongInt;
begin
TryDo(TeamsCount < cMaxTeams, 'Too many teams', true);
New(team);
TryDo(team <> nil, 'AddTeam: team = nil', true);
FillChar(team^, sizeof(TTeam), 0);
team^.AttackBar:= 2;
team^.CurrHedgehog:= 0;
team^.Flag:= 'hedgewars';

TeamsArray[TeamsCount]:= team;
inc(TeamsCount);

c:= Pred(ClansCount);
while (c >= 0) and (ClansArray[c]^.Color <> TeamColor) do dec(c);
if c < 0 then
   begin
   new(team^.Clan);
   FillChar(team^.Clan^, sizeof(TClan), 0);
   ClansArray[ClansCount]:= team^.Clan;
   inc(ClansCount);
   with team^.Clan^ do
        begin
        ClanIndex:= Pred(ClansCount);
        Color:= TeamColor;
        end
   end else
   begin
   team^.Clan:= ClansArray[c];
   end;

with team^.Clan^ do
    begin
    Teams[TeamsNumber]:= team;
    inc(TeamsNumber)
    end;

CurrentTeam:= team;
AddTeam:= team;
end;

procedure RecountAllTeamsHealth;
var t: LongInt;
begin
for t:= 0 to Pred(TeamsCount) do
    RecountTeamHealth(TeamsArray[t])
end;

procedure InitTeams;
var i, t: LongInt;
    th, h: LongInt;
begin

for t:= 0 to Pred(TeamsCount) do
   with TeamsArray[t]^ do
      begin
      if (not ExtDriven) and (Hedgehogs[0].BotLevel = 0) then
          begin
          LocalClan:= Clan^.ClanIndex;
          LocalAmmo:= Hedgehogs[0].AmmoStore
          end;
      th:= 0;
      for i:= 0 to cMaxHHIndex do
          if Hedgehogs[i].Gear <> nil then
             inc(th, Hedgehogs[i].Gear^.Health);
      if th > MaxTeamHealth then MaxTeamHealth:= th;
      // Some initial King buffs
      if (GameFlags and gfKing) <> 0 then
          begin
          Hedgehogs[0].King:= true;
          Hedgehogs[0].Hat:= 'crown';
          Hedgehogs[0].Effects[hePoisoned] := false;
          h:= Hedgehogs[0].Gear^.Health;
          Hedgehogs[0].Gear^.Health:= hwRound(int2hwFloat(th)*_0_375);
          if Hedgehogs[0].Gear^.Health > h then
              begin
              dec(th, h);
              inc(th, Hedgehogs[0].Gear^.Health);
              if th > MaxTeamHealth then MaxTeamHealth:= th
              end
          else Hedgehogs[0].Gear^.Health:= h
          end;
      end;

RecountAllTeamsHealth
end;

function  TeamSize(p: PTeam): Longword;
var i, value: Longword;
begin
value:= 0;
for i:= 0 to cMaxHHIndex do
    if p^.Hedgehogs[i].Gear <> nil then inc(value);
TeamSize:= value;
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

    if not hasGone then
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

AddVisualGear(0, 0, vgtTeamHealthSorter)
end;

procedure RestoreTeamsFromSave;
var t: LongInt;
begin
for t:= 0 to Pred(TeamsCount) do
   TeamsArray[t]^.ExtDriven:= false
end;

procedure TeamGone(s: shortstring);
var t: LongInt;
begin
t:= 0;
while (t < cMaxTeams)
    and (TeamsArray[t] <> nil)
    and (TeamsArray[t]^.TeamName <> s) do inc(t);
if (t = cMaxTeams) or (TeamsArray[t] = nil) then exit;

with TeamsArray[t]^ do
    begin
    AddChatString('** '+ TeamName + ' is gone');
    hasGone:= true
    end;

RecountTeamHealth(TeamsArray[t])
end;

procedure TeamGoneEffect(var Team: TTeam);
var i: LongInt;
begin
with Team do
    for i:= 0 to cMaxHHIndex do
        with Hedgehogs[i] do
            if Gear <> nil then
                begin
                Gear^.Invulnerable:= false;
                Gear^.Damage:= Gear^.Health
                end
end;

function GetTeamStatString(p: PTeam): shortstring;
var s: ansistring;
begin
    s:= p^.TeamName + ':' + inttostr(p^.TeamHealth) + ':';
    GetTeamStatString:= s;
end;

procedure initModule;
begin
    CurrentTeam:= nil;
    PreviousTeam:= nil;
    CurrentHedgehog:= nil;
    TeamsCount:= 0;
    ClansCount:= 0;
    LocalClan:= -1;
    LocalAmmo:= -1;
end;

procedure freeModule;
var i: LongWord;
begin
   if TeamsCount > 0 then
     begin
     for i:= 0 to Pred(TeamsCount) do Dispose(TeamsArray[i]);
     for i:= 0 to Pred(ClansCount) do Dispose(ClansArray[i]);
     end;
   TeamsCount:= 0;
   ClansCount:= 0
end;

end.

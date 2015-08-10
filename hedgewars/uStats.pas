(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit uStats;
interface
uses uConsts, uTypes;

var TotalRounds: LongInt;
    FinishedTurnsTotal: LongInt;
    SendHealthStatsOn : boolean = true;

procedure initModule;
procedure freeModule;

procedure AmmoUsed(am: TAmmoType);
procedure HedgehogDamaged(Gear: PGear; Attacker: PHedgehog; Damage: Longword; killed: boolean);
procedure Skipped;
procedure TurnReaction;
procedure SendStats;
procedure hedgehogFlight(Gear: PGear; time: Longword);
procedure declareAchievement(id, teamname, location: shortstring; value: LongInt);

implementation
uses uSound, uLocale, uVariables, uUtils, uIO, uCaptions, uDebug, uMisc, uConsole, uScript;

var DamageClan  : Longword = 0;
    DamageTotal : Longword = 0;
    DamageTurn  : Longword = 0;
    KillsClan   : LongWord = 0;
    Kills       : LongWord = 0;
    KillsTotal  : LongWord = 0;
    AmmoUsedCount : Longword = 0;
    AmmoDamagingUsed : boolean = false;
    SkippedTurns: LongWord = 0;
    isTurnSkipped: boolean = false;
    vpHurtSameClan: PVoicepack = nil;
    vpHurtEnemy: PVoicepack = nil;

procedure HedgehogDamaged(Gear: PGear; Attacker: PHedgehog; Damage: Longword; killed: boolean);
begin
if Attacker^.Team^.Clan = Gear^.Hedgehog^.Team^.Clan then
    vpHurtSameClan:= CurrentHedgehog^.Team^.voicepack
else
    vpHurtEnemy:= Gear^.Hedgehog^.Team^.voicepack;

//////////////////////////

inc(Attacker^.stats.StepDamageGiven, Damage);
inc(Attacker^.stats.DamageGiven, Damage);
inc(Gear^.Hedgehog^.stats.StepDamageRecv, Damage);

if CurrentHedgehog^.Team^.Clan = Gear^.Hedgehog^.Team^.Clan then inc(DamageClan, Damage);

if killed then
    begin
    inc(Attacker^.stats.StepKills);
    inc(Kills);
    inc(KillsTotal);
    inc(Attacker^.Team^.stats.Kills);
    if (Attacker^.Team^.TeamName = Gear^.Hedgehog^.Team^.TeamName) then
        begin
        inc(Attacker^.Team^.stats.TeamKills);
        inc(Attacker^.Team^.stats.TeamDamage, Gear^.Damage);
    end;
    if Gear = Attacker^.Gear then
        inc(Attacker^.Team^.stats.Suicides);
    if Attacker^.Team^.Clan = Gear^.Hedgehog^.Team^.Clan then
        inc(KillsClan);
    end;

inc(DamageTotal, Damage);
inc(DamageTurn, Damage)
end;

procedure Skipped;
begin
inc(SkippedTurns);
isTurnSkipped:= true
end;

procedure TurnReaction;
var i, t: LongInt;
    s: ansistring;
begin
TryDo(not bBetweenTurns, 'Engine bug: TurnReaction between turns', true);

inc(FinishedTurnsTotal);
if FinishedTurnsTotal <> 0 then
    begin
    s:= ansistring(CurrentHedgehog^.Name);
    inc(CurrentHedgehog^.stats.FinishedTurns);

    if (CurrentHedgehog^.stats.DamageGiven = DamageTotal) and (DamageTotal > 0) then
        AddVoice(sndFirstBlood, CurrentTeam^.voicepack)

    else if CurrentHedgehog^.stats.StepDamageRecv > 0 then
        begin
        AddVoice(sndStupid, PreviousTeam^.voicepack);
        if CurrentHedgehog^.stats.DamageGiven = CurrentHedgehog^.stats.StepDamageRecv then
            AddCaption(FormatA(GetEventString(eidHurtSelf), s), cWhiteColor, capgrpMessage);
        end

    else if DamageClan <> 0 then
        if DamageTurn > DamageClan then
            if random(2) = 0 then
                AddVoice(sndNutter, CurrentTeam^.voicepack)
            else
                AddVoice(sndWatchIt, vpHurtSameClan)
        else
            if random(2) = 0 then
                AddVoice(sndSameTeam, vpHurtSameClan)
            else
                AddVoice(sndTraitor, vpHurtSameClan)

    else if CurrentHedgehog^.stats.StepDamageGiven <> 0 then
        if Kills > 0 then
            AddVoice(sndEnemyDown, CurrentTeam^.voicepack)
        else
            AddVoice(sndRegret, vpHurtEnemy)

    else if AmmoDamagingUsed then
        AddVoice(sndMissed, PreviousTeam^.voicepack)
    else if (AmmoUsedCount > 0) and (not isTurnSkipped) then
        begin end// nothing ?
    else if isTurnSkipped then
        begin
        AddVoice(sndBoring, PreviousTeam^.voicepack);
        AddCaption(FormatA(GetEventString(eidTurnSkipped), s), cWhiteColor, capgrpMessage);
        end
    else if not PlacingHogs then
        AddVoice(sndCoward, PreviousTeam^.voicepack);
    end;


for t:= 0 to Pred(TeamsCount) do // send even on zero turn
    with TeamsArray[t]^ do
        for i:= 0 to cMaxHHIndex do
            with Hedgehogs[i].stats do
                begin
                inc(DamageRecv, StepDamageRecv);
                inc(DamageGiven, StepDamageGiven);
                if StepDamageRecv > MaxStepDamageRecv then
                    MaxStepDamageRecv:= StepDamageRecv;
                if StepDamageGiven > MaxStepDamageGiven then
                    MaxStepDamageGiven:= StepDamageGiven;
                if StepKills > MaxStepKills then
                    MaxStepKills:= StepKills;
                StepKills:= 0;
                StepDamageRecv:= 0;
                StepDamageGiven:= 0
                end;

if SendHealthStatsOn then
    for t:= 0 to Pred(ClansCount) do
        with ClansArray[t]^ do
            begin
            SendStat(siClanHealth, IntToStr(Color) + ' ' + IntToStr(ClanHealth));
            end;

Kills:= 0;
KillsClan:= 0;
DamageClan:= 0;
DamageTurn:= 0;
AmmoUsedCount:= 0;
AmmoDamagingUsed:= false;
isTurnSkipped:= false
end;

procedure AmmoUsed(am: TAmmoType);
begin
inc(AmmoUsedCount);
AmmoDamagingUsed:= AmmoDamagingUsed or Ammoz[am].isDamaging
end;

procedure hedgehogFlight(Gear: PGear; time: Longword);
begin
if time > 4000 then
    begin
    WriteLnToConsole('FLIGHT');
    WriteLnToConsole(Gear^.Hedgehog^.Team^.TeamName);
    WriteLnToConsole(inttostr(time));
    WriteLnToConsole( '');
    end
end;

procedure SendStats;
var i, t: LongInt;
    msd, msk: Longword; msdhh, mskhh: PHedgehog;
    mskcnt: Longword;
    maxTeamKills : Longword;
    maxTeamKillsName : shortstring;
    maxTurnSkips : Longword;
    maxTurnSkipsName : shortstring;
    maxTeamDamage : Longword;
    maxTeamDamageName : shortstring;
    winnersClan : PClan;
begin
if SendHealthStatsOn then
    msd:= 0; msdhh:= nil;
    msk:= 0; mskhh:= nil;
    mskcnt:= 0;
    maxTeamKills := 0;
    maxTurnSkips := 0;
    maxTeamDamage := 0;
    winnersClan:= nil;

    for t:= 0 to Pred(TeamsCount) do
        with TeamsArray[t]^ do
        begin
            if not ExtDriven then
                SendStat(siTeamStats, GetTeamStatString(TeamsArray[t]));
            for i:= 0 to cMaxHHIndex do
                begin
                if Hedgehogs[i].stats.MaxStepDamageGiven > msd then
                    begin
                    msdhh:= @Hedgehogs[i];
                    msd:= Hedgehogs[i].stats.MaxStepDamageGiven
                    end;
                if Hedgehogs[i].stats.MaxStepKills >= msk then
                    if Hedgehogs[i].stats.MaxStepKills = msk then
                        inc(mskcnt)
                    else
                        begin
                        mskcnt:= 1;
                        mskhh:= @Hedgehogs[i];
                        msk:= Hedgehogs[i].stats.MaxStepKills
                        end;
            end;

            { send player stats for winner teams }
            if Clan^.ClanHealth > 0 then
                begin
                winnersClan:= Clan;
                SendStat(siPlayerKills, IntToStr(Clan^.Color) + ' ' +
                    IntToStr(stats.Kills) + ' ' + TeamName);
            end;

            { determine maximum values of TeamKills, TurnSkips, TeamDamage }
            if stats.TeamKills > maxTeamKills then
                begin
                maxTeamKills := stats.TeamKills;
                maxTeamKillsName := TeamName;
            end;
            if stats.TurnSkips > maxTurnSkips then
                begin
                maxTurnSkips := stats.TurnSkips;
                maxTurnSkipsName := TeamName;
            end;
            if stats.TeamDamage > maxTeamDamage then
                begin
                maxTeamDamage := stats.TeamDamage;
                maxTeamDamageName := TeamName;
            end;

        end;

    { now send player stats for loser teams }
    for t:= 0 to Pred(TeamsCount) do
        begin
        with TeamsArray[t]^ do
            begin
            if Clan^.ClanHealth = 0 then
                begin
                SendStat(siPlayerKills, IntToStr(Clan^.Color) + ' ' +
                    IntToStr(stats.Kills) + ' ' + TeamName);
            end;
        end;
    end;

    if msdhh <> nil then
        SendStat(siMaxStepDamage, IntToStr(msd) + ' ' + msdhh^.Name + ' (' + msdhh^.Team^.TeamName + ')');
    if mskcnt = 1 then
        SendStat(siMaxStepKills, IntToStr(msk) + ' ' + mskhh^.Name + ' (' + mskhh^.Team^.TeamName + ')');

    if maxTeamKills > 1 then
        SendStat(siMaxTeamKills, IntToStr(maxTeamKills) + ' ' + maxTeamKillsName);
    if maxTurnSkips > 2 then
        SendStat(siMaxTurnSkips, IntToStr(maxTurnSkips) + ' ' + maxTurnSkipsName);
    if maxTeamDamage > 30 then
        SendStat(siMaxTeamDamage, IntToStr(maxTeamDamage) + ' ' + maxTeamDamageName);

    if KilledHHs > 0 then
        SendStat(siKilledHHs, IntToStr(KilledHHs));

    // now to console
    if winnersClan <> nil then
        begin
        WriteLnToConsole('WINNERS');
        WriteLnToConsole(inttostr(winnersClan^.TeamsNumber));
        for t:= 0 to winnersClan^.TeamsNumber - 1 do
            WriteLnToConsole(winnersClan^.Teams[t]^.TeamName);
        end
    else
        WriteLnToConsole('DRAW');

    ScriptCall('onAchievementsDeclaration');
end;

procedure declareAchievement(id, teamname, location: shortstring; value: LongInt);
begin
if (length(id) = 0) or (length(teamname) = 0) or (length(location) = 0) then exit;
    WriteLnToConsole('ACHIEVEMENT');
    WriteLnToConsole(id);
    WriteLnToConsole(teamname);
    WriteLnToConsole(location);
    WriteLnToConsole(inttostr(value));
end;

procedure initModule;
begin
    TotalRounds:= -1;
    FinishedTurnsTotal:= -1;
end;

procedure freeModule;
begin
end;

end.

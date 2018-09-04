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

var TotalRoundsPre: LongInt; // Helper variable for calculating start of Sudden Death and more. Starts at -1 and is incremented on the turn BEFORE the turn which marks the start of the next round. Always -1 while in hog placing phase
    TotalRoundsReal: LongInt; // Total number of rounds played (-1 if not started or in hog placing phase). Exported to Lua as 'TotalRounds'
    FinishedTurnsTotal: LongInt;
    SendGameResultOn : boolean = true;
    SendRankingStatsOn : boolean = true;
    SendAchievementsStatsOn : boolean = true;
    SendHealthStatsOn : boolean = true;
    ClanDeathLog : PClanDeathLogEntry;

procedure initModule;
procedure freeModule;

procedure AmmoUsed(am: TAmmoType);
procedure HedgehogPoisoned(Gear: PGear; Attacker: PHedgehog);
procedure HedgehogSacrificed(Hedgehog: PHedgehog);
procedure HedgehogDamaged(Gear: PGear; Attacker: PHedgehog; Damage: Longword; killed: boolean);
procedure TargetHit;
procedure Skipped;
procedure TurnStats;
procedure TurnReaction;
procedure TurnStatsReset;
procedure SendStats;
procedure hedgehogFlight(Gear: PGear; time: Longword);
procedure declareAchievement(id, teamname, location: shortstring; value: LongInt);
procedure startGhostPoints(n: LongInt);
procedure dumpPoint(x, y: LongInt);

implementation
uses uSound, uLocale, uVariables, uUtils, uIO, uCaptions, uMisc, uConsole, uScript;

var DamageClan  : Longword = 0;
    DamageTotal : Longword = 0;
    DamageTurn  : Longword = 0;
    PoisonTurn  : Longword = 0; // Poisoned enemies per turn
    PoisonClan  : Longword = 0; // Poisoned own clan members in turn
    PoisonTotal : Longword = 0; // Poisoned hogs in whole round
    KillsClan   : LongWord = 0;
    Kills       : LongWord = 0;
    KillsTotal  : LongWord = 0;
    HitTargets  : LongWord = 0; // Target (gtTarget) hits per turn
    AmmoUsedCount : Longword = 0;
    AmmoDamagingUsed : boolean = false;
    SkippedTurns: LongWord = 0;
    isTurnSkipped: boolean = false;
    vpHurtSameClan: PVoicepack = nil;
    vpHurtEnemy: PVoicepack = nil;

procedure HedgehogPoisoned(Gear: PGear; Attacker: PHedgehog);
begin
    if Attacker^.Team^.Clan = Gear^.HEdgehog^.Team^.Clan then
        begin
        vpHurtSameClan:= CurrentHedgehog^.Team^.voicepack;
        inc(PoisonClan)
        end
    else
        begin
        vpHurtEnemy:= Gear^.Hedgehog^.Team^.voicepack;
        inc(PoisonTurn)
        end;
    Gear^.Hedgehog^.stats.StepPoisoned:= true;
    inc(PoisonTotal)
end;

procedure HedgehogSacrificed(Hedgehog: PHedgehog);
begin
    Hedgehog^.stats.Sacrificed:= true
end;

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
    Gear^.Hedgehog^.stats.StepDied:= true;
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

procedure TargetHit();
begin
   inc(HitTargets)
end;

procedure Skipped;
begin
inc(SkippedTurns);
isTurnSkipped:= true
end;

procedure TurnStats;
var i, t: LongInt;
    c: Longword;
    newEntry: PClanDeathLogEntry;
begin
inc(FinishedTurnsTotal);

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
                end;

// Write into the death log which clans died in this turn,
// important for final rankings.
c:= 0;
newEntry:= nil;
for t:= 0 to Pred(ClansCount) do
    with ClansArray[t]^ do
        begin
        if (ClanHealth = 0) and (ClansArray[t]^.DeathLogged = false) then
            begin
            if c = 0 then
                begin
                new(newEntry);
                newEntry^.Turn := FinishedTurnsTotal;
                newEntry^.NextEntry := nil;
                end;

            newEntry^.KilledClans[c]:= ClansArray[t];
            inc(c);
            newEntry^.KilledClansCount := c;
            ClansArray[t]^.DeathLogged:= true;
            end;

        if SendHealthStatsOn then
            SendStat(siClanHealth, IntToStr(Color) + ' ' + IntToStr(ClanHealth));
        end;
if newEntry <> nil then
    begin
    if ClanDeathLog <> nil then
        begin
        newEntry^.NextEntry:= ClanDeathLog;
        end;
    ClanDeathLog:= newEntry;
    end;

end;

procedure TurnReaction;
var killsCheck: LongInt;
    s: ansistring;
begin
//TryDo(not bBetweenTurns, 'Engine bug: TurnReaction between turns', true);

if FinishedTurnsTotal <> 0 then
    begin
    s:= ansistring(CurrentHedgehog^.Name);
    inc(CurrentHedgehog^.stats.FinishedTurns);
    // If the hog sacrificed (=kamikaze/piano) itself, this needs to be taken into accounts for the reactions later
    if (CurrentHedgehog^.stats.Sacrificed) then
        killsCheck:= 1
    else
        killsCheck:= 0;

    // First blood (first damage, poison or kill)
    if ((DamageTotal > 0) or (KillsTotal > 0) or (PoisonTotal > 0)) and ((CurrentHedgehog^.stats.DamageGiven = DamageTotal) and (CurrentHedgehog^.stats.StepKills = KillsTotal) and (PoisonTotal = PoisonTurn + PoisonClan)) then
        AddVoice(sndFirstBlood, CurrentTeam^.voicepack)

    // Hog hurts, poisons or kills itself (except sacrifice)
    else if (CurrentHedgehog^.stats.Sacrificed = false) and ((CurrentHedgehog^.stats.StepDamageRecv > 0) or (CurrentHedgehog^.stats.StepPoisoned) or (CurrentHedgehog^.stats.StepDied)) then
        begin
        AddVoice(sndStupid, PreviousTeam^.voicepack);
        // Message for hurting itself only (not drowning)
        if (CurrentHedgehog^.stats.DamageGiven = CurrentHedgehog^.stats.StepDamageRecv) and (CurrentHedgehog^.stats.StepDamageRecv >= 1) then
            AddCaption(FormatA(GetEventString(eidHurtSelf), s), capcolDefault, capgrpMessage);
        end

    // Hog hurts, poisons or kills own team/clan member. Sacrifice is taken into account
    else if (DamageClan <> 0) or (KillsClan > killsCheck) or (PoisonClan <> 0) then
        if (DamageTurn > DamageClan) or (Kills > KillsClan) then
            if random(2) = 0 then
                AddVoice(sndNutter, CurrentTeam^.voicepack)
            else
                AddVoice(sndWatchIt, vpHurtSameClan)
        else
            if random(2) = 0 then
                AddVoice(sndSameTeam, vpHurtSameClan)
            else
                AddVoice(sndTraitor, vpHurtSameClan)

    // Hog hurts, kills or poisons enemy
    else if (CurrentHedgehog^.stats.StepDamageGiven <> 0) or (CurrentHedgehog^.stats.StepKills > killsCheck) or (PoisonTurn <> 0) then
        if Kills > killsCheck then
            AddVoice(sndEnemyDown, CurrentTeam^.voicepack)
        else
            AddVoice(sndRegret, vpHurtEnemy)

    // Missed shot
    // A miss is defined as a shot with a damaging weapon with 0 kills, 0 damage, 0 hogs poisoned and 0 targets hit
    else if AmmoDamagingUsed and (Kills <= killsCheck) and (PoisonTurn = 0) and (PoisonClan = 0) and (DamageTurn = 0) and (HitTargets = 0) then
        // Chance to call hedgehog stupid if sacrificed for nothing
        if CurrentHedgehog^.stats.Sacrificed then
            if random(2) = 0 then
                AddVoice(sndMissed, PreviousTeam^.voicepack)
            else
                AddVoice(sndStupid, PreviousTeam^.voicepack)
        else
            AddVoice(sndMissed, PreviousTeam^.voicepack)

    // Timeout
    else if (AmmoUsedCount > 0) and (not isTurnSkipped) then
        begin end// nothing ?

    // Turn skipped
    else if isTurnSkipped and (not PlacingHogs) then
        begin
        AddVoice(sndCoward, PreviousTeam^.voicepack);
        AddCaption(FormatA(GetEventString(eidTurnSkipped), s), capcolDefault, capgrpMessage);
        end
    end;
end;

procedure TurnStatsReset;
var t, i: LongInt;
begin
for t:= 0 to Pred(TeamsCount) do // send even on zero turn
    with TeamsArray[t]^ do
        for i:= 0 to cMaxHHIndex do
            with Hedgehogs[i].stats do
                begin
                StepKills:= 0;
                StepDamageRecv:= 0;
                StepDamageGiven:= 0;
                StepPoisoned:= false;
                StepDied:= false;
                end;

Kills:= 0;
KillsClan:= 0;
DamageClan:= 0;
DamageTurn:= 0;
HitTargets:= 0;
PoisonClan:= 0;
PoisonTurn:= 0;
AmmoUsedCount:= 0;
AmmoDamagingUsed:= false;
isTurnSkipped:= false;
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
var i, t, c: LongInt;
    msd, msk: Longword; msdhh, mskhh: PHedgehog;
    mskcnt: Longword;
    maxTeamKills : Longword;
    maxTeamKillsName : shortstring;
    maxTurnSkips : Longword;
    maxTurnSkipsName : shortstring;
    maxTeamDamage : Longword;
    maxTeamDamageName : shortstring;
    winnersClan : PClan;
    deathEntry : PClanDeathLogEntry;
    currentRank: Longword;
begin
if SendHealthStatsOn then
    msd:= 0; msdhh:= nil;
    msk:= 0; mskhh:= nil;
    mskcnt:= 0;
    maxTeamKills := 0;
    maxTurnSkips := 0;
    maxTeamDamage := 0;
    winnersClan:= nil;
    currentRank:= 0;

    for t:= 0 to Pred(TeamsCount) do
        with TeamsArray[t]^ do
        begin
            if (not ExtDriven) and SendRankingStatsOn then
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

            { Send player stats for winner clans/teams.
            The clan that survived is ranked 1st. }
            if Clan^.ClanHealth > 0 then
                begin
                winnersClan:= Clan;
                if SendRankingStatsOn then
                    begin
                    currentRank:= 1;
                    SendStat(siTeamRank, '1');
                    SendStat(siPlayerKills, IntToStr(Clan^.Color) + ' ' +
                        IntToStr(stats.Kills) + ' ' + TeamName);
                    end;
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

    inc(currentRank);

    { Now send player stats for loser teams/clans.
    The losing clans are ranked in the reverse order they died.
    The clan that died last is ranked 2nd,
    the clan that died second to last is ranked 3rd,
    and so on.
    Clans that died in the same turn share their rank.
    If a clan died multiple times in the match
    (e.g. due to resurrection), only the *latest* death of
    that clan counts (handled in gtResurrector).
    }
    deathEntry := ClanDeathLog;
    i:= 0;
    if SendRankingStatsOn then
        while (deathEntry <> nil) do
            begin
            for c:= 0 to Pred(deathEntry^.KilledClansCount) do
                if ((deathEntry^.KilledClans[c]^.ClanHealth) = 0) and (not deathEntry^.KilledClans[c]^.StatsHandled) then
                    begin
                    for t:= 0 to Pred(TeamsCount) do
                        if TeamsArray[t]^.Clan^.ClanIndex = deathEntry^.KilledClans[c]^.ClanIndex then
                            begin
                            inc(i);
                            SendStat(siTeamRank, IntToStr(currentRank));
                            SendStat(siPlayerKills, IntToStr(deathEntry^.killedClans[c]^.Color) + ' ' +
                                IntToStr(TeamsArray[t]^.stats.Kills) + ' ' + TeamsArray[t]^.TeamName);
                            end;
                    deathEntry^.KilledClans[c]^.StatsHandled:= true;
                    end;
            if i > 0 then
                inc(currentRank, i);
            i:= 0;
            deathEntry:= deathEntry^.NextEntry;
            end;

    // “Achievements” / Details part of stats screen
    if SendAchievementsStatsOn then
        begin
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
        end;

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

procedure startGhostPoints(n: LongInt);
begin
    WriteLnToConsole('GHOST_POINTS');
    WriteLnToConsole(inttostr(n));
end;

procedure dumpPoint(x, y: LongInt);
begin
    WriteLnToConsole(inttostr(x));
    WriteLnToConsole(inttostr(y));
end;

procedure initModule;
begin
    DamageClan  := 0;
    DamageTotal := 0;
    DamageTurn  := 0;
    PoisonClan  := 0;
    PoisonTurn  := 0;
    KillsClan   := 0;
    Kills       := 0;
    KillsTotal  := 0;
    HitTargets  := 0;
    AmmoUsedCount := 0;
    AmmoDamagingUsed := false;
    SkippedTurns:= 0;
    isTurnSkipped:= false;
    vpHurtSameClan:= nil;
    vpHurtEnemy:= nil;
    TotalRoundsPre:= -1;
    TotalRoundsReal:= -1;
    FinishedTurnsTotal:= -1;
    ClanDeathLog:= nil;
end;

procedure freeModule;
begin
end;

end.

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
    // Variables to disable certain portions of game stats (set by Lua)
    SendGameResultOn : boolean = true;
    SendRankingStatsOn : boolean = true;
    SendAchievementsStatsOn : boolean = true;
    SendHealthStatsOn : boolean = true;
    // Clan death log, used for game stats
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

var DamageClan  : Longword = 0;         // Damage of own clan in turn
    DamageTeam  : Longword = 0;         // Damage of own team tin turn
    DamageTotal : Longword = 0;         // Total damage dealt in game
    DamageTurn  : Longword = 0;         // Damage in turn
    PoisonTurn  : Longword = 0;         // Poisoned enemies in turn
    PoisonClan  : Longword = 0;         // Poisoned own clan members in turn
    PoisonTeam  : Longword = 0;         // Poisoned own team members in turn
    PoisonTotal : Longword = 0;         // Poisoned hogs in whole round
    KillsClan   : LongWord = 0;         // Own clan members killed in turn
    KillsTeam   : LongWord = 0;         // Own team members killed in turn
    KillsSD     : LongWord = 0;         // Killed hedgehogs in turn that died by Sudden Death water rise
    Kills       : LongWord = 0;         // Killed hedgehogs in turn (including those that died by Sudden Death water rise)
    KillsTotal  : LongWord = 0;         // Total killed hedgehogs in game
    HitTargets  : LongWord = 0;         // Target (gtTarget) hits in turn
    AmmoUsedCount : Longword = 0;       // Number of times an ammo has been used this turn
    AmmoDamagingUsed : boolean = false; // true if damaging ammo was used in turn
    FirstBlood  : boolean = false;      // true if the “First blood” taunt has been used in this game
    LeaveMeAlone : boolean = false;     // true if the “Leave me alone” taunt is to be used this turn
    SkippedTurns: LongWord = 0;         // number of skipped turns in game
    isTurnSkipped: boolean = false;     // true if this turn was skipped
    vpHurtSameClan: PVoicepack = nil;   // voicepack of current clan (used for taunts)
    vpHurtEnemy: PVoicepack = nil;      // voicepack of enemy (used for taunts)

procedure HedgehogPoisoned(Gear: PGear; Attacker: PHedgehog);
begin
    if Attacker^.Team^.Clan = Gear^.Hedgehog^.Team^.Clan then
        begin
        vpHurtSameClan:= Gear^.Hedgehog^.Team^.voicepack;
        inc(PoisonClan);
        if Attacker^.Team = Gear^.Hedgehog^.Team then
            inc(PoisonTeam);
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
    vpHurtSameClan:= Gear^.Hedgehog^.Team^.voicepack
else
    begin
    vpHurtEnemy:= Gear^.Hedgehog^.Team^.voicepack;
    if (not killed) and (not bDuringWaterRise) then
        begin
        // Check if victim got attacked by RevengeHog again
        if (Gear^.Hedgehog^.RevengeHog <> nil) and (Gear^.Hedgehog^.RevengeHog = Attacker) then
            LeaveMeAlone:= true;
        // Check if attacker got revenge
        if (Attacker^.RevengeHog <> nil) and (Attacker^.RevengeHog = Gear^.Hedgehog) then
            begin
            Attacker^.stats.GotRevenge:= true;
            // Also reset the "in-row" counter to restore LeaveMeAlone/CutItOut taunts
            Attacker^.stats.StepDamageRecvInRow:= 0;
            Attacker^.RevengeHog:= nil;
            end
        // If not, victim remembers their attacker to plan *their* revenge
        else
            Gear^.Hedgehog^.RevengeHog:= Attacker;
        end
    end;

//////////////////////////

if (not bDuringWaterRise) then
    begin
    inc(Attacker^.stats.StepDamageGiven, Damage);
    inc(Gear^.Hedgehog^.stats.StepDamageRecv, Damage);
    end;

if CurrentHedgehog^.Team^.Clan = Gear^.Hedgehog^.Team^.Clan then inc(DamageClan, Damage);
if CurrentHedgehog^.Team = Gear^.Hedgehog^.Team then inc(DamageTeam, Damage);

if killed then
    begin
    Gear^.Hedgehog^.stats.StepDied:= true;
    inc(Kills);

    inc(KillsTotal);

    if bDuringWaterRise then
        inc(KillsSD)
    else
        begin
        inc(Attacker^.stats.StepKills);
        inc(Attacker^.Team^.stats.Kills);
        if (Attacker^.Team^.TeamName = Gear^.Hedgehog^.Team^.TeamName) then
            begin
            inc(Attacker^.Team^.stats.TeamKills);
            inc(Attacker^.Team^.stats.TeamDamage, Gear^.Damage);
        end;
        if Gear = Attacker^.Gear then
            inc(Attacker^.Team^.stats.Suicides);
        if Attacker^.Team^.Clan = Gear^.Hedgehog^.Team^.Clan then
            begin
            inc(KillsClan);
            if Attacker^.Team = Gear^.Hedgehog^.Team then
                inc(KillsTeam);
            end;
        end;
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
            begin
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
                if (Hedgehogs[i].Team <> nil) and (Hedgehogs[i].Team^.Clan^.ClanIndex <> CurrentHedgehog^.Team^.Clan^.ClanIndex) then
                    begin
                    if StepDamageRecv > 0 then
                        inc(StepDamageRecvInRow)
                    else
                        StepDamageRecvInRow:= 0;
                    if StepDamageRecvInRow >= 3 then
                        LeaveMeAlone:= true;
                    end;
                end;
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

    // killsCheck is used to take deaths into account that were not a traditional "kill"
    // Hogs that died during SD water rise do not count as "kills" for taunts
    killsCheck:= KillsSD;
    // If the hog sacrificed (=kamikaze/piano) itself, this needs to be taken into account for the reactions later
    if (CurrentHedgehog^.stats.Sacrificed) then
        inc(killsCheck);

    // First blood (first damage, poison or kill)
    if (not FirstBlood) and (ClansCount > 1) and ((DamageTotal > 0) or (KillsTotal > 0) or (PoisonTotal > 0)) and ((CurrentHedgehog^.stats.DamageGiven = DamageTotal) and (CurrentHedgehog^.stats.StepKills = KillsTotal) and (PoisonTotal = PoisonTurn + PoisonClan)) then
        begin
        FirstBlood:= true;
        AddVoice(sndFirstBlood, CurrentTeam^.voicepack);
        end

    // Hog hurts, poisons or kills itself (except sacrifice)
    else if (CurrentHedgehog^.stats.Sacrificed = false) and ((CurrentHedgehog^.stats.StepDamageRecv > 0) or (CurrentHedgehog^.stats.StepPoisoned) or (CurrentHedgehog^.stats.StepDied)) then
        // Hurt itself only (without dying)
        if (CurrentHedgehog^.stats.StepDamageGiven = CurrentHedgehog^.stats.StepDamageRecv) and (CurrentHedgehog^.stats.StepDamageRecv >= 1) and (not CurrentHedgehog^.stats.StepDied) then
            begin
            // Announcer message + random taunt
            AddCaption(FormatA(GetEventString(eidHurtSelf), s), capcolDefault, capgrpMessage);
            if (CurrentHedgehog^.stats.StepDamageGiven <= CurrentHedgehog^.stats.StepDamageRecv) and (CurrentHedgehog^.stats.StepDamageRecv >= 1) then
                case random(3) of
                0: AddVoice(sndStupid, PreviousTeam^.voicepack);
                1: AddVoice(sndBugger, CurrentTeam^.voicepack);
                2: AddVoice(sndDrat, CurrentTeam^.voicepack);
                end;
            end
        // Hurt itself and others, or died
        else
            AddVoice(sndStupid, PreviousTeam^.voicepack)

    // Hog hurts, poisons or kills own team/clan member. Sacrifice is taken into account
    else if (DamageClan <> 0) or (KillsClan > killsCheck) or (PoisonClan <> 0) then
        if (DamageTurn > DamageClan) or ((Kills-KillsSD) > KillsClan) then
            if random(2) = 0 then
                AddVoice(sndNutter, CurrentTeam^.voicepack)
            else
                AddVoice(sndWatchIt, vpHurtSameClan)
        else
            // Attacked same team
            if (random(2) = 0) and ((DamageTeam <> 0) or (KillsTeam > killsCheck) or (PoisonTeam <> 0)) then
                AddVoice(sndSameTeam, vpHurtSameClan)
            // Attacked same team or a clan member
            else
                AddVoice(sndTraitor, vpHurtSameClan)

    // Hog hurts, kills or poisons enemy
    else if (CurrentHedgehog^.stats.StepDamageGiven <> 0) or (CurrentHedgehog^.stats.StepKills > killsCheck) or (PoisonTurn <> 0) then
        // 3 kills or more
        if Kills > killsCheck + 2 then
            AddVoice(sndAmazing, CurrentTeam^.voicepack)
        // 2 kills
        else if Kills = (killsCheck + 2) then
            if random(2) = 0 then
                AddVoice(sndBrilliant, CurrentTeam^.voicepack)
            else
                AddVoice(sndExcellent, CurrentTeam^.voicepack)
        // 1 kill
        else if Kills = (killsCheck + 1) then
            AddVoice(sndEnemyDown, CurrentTeam^.voicepack)
        // 0 kills, only damage or poison
        else
            // possible reactions of victim, in the order of preference:
            // 1. claiming revenge
            // 2. complaining about getting attacked too often
            // 3. threatening enemy with retaliation
            if CurrentHedgehog^.stats.GotRevenge then
                begin
                AddVoice(sndRevenge, CurrentHedgehog^.Team^.voicepack);
                // If revenge taunt was added, one of the following voices is
                // added as fallback (4th param), in case of a missing Revenge sound file.
                case random(4) of
                    0: AddVoice(sndRegret, vpHurtEnemy, false, true);
                    1: AddVoice(sndGonnaGetYou, vpHurtEnemy, false, true);
                    2: AddVoice(sndIllGetYou, vpHurtEnemy, false, true);
                    3: AddVoice(sndJustYouWait, vpHurtEnemy, false, true);
                    end;
                end
            else
                if LeaveMeAlone then
                    if random(2) = 0 then
                        AddVoice(sndCutItOut, vpHurtEnemy)
                    else
                        AddVoice(sndLeaveMeAlone, vpHurtEnemy)
                else
                    case random(4) of
                        0: AddVoice(sndRegret, vpHurtEnemy);
                        1: AddVoice(sndGonnaGetYou, vpHurtEnemy);
                        2: AddVoice(sndIllGetYou, vpHurtEnemy);
                        3: AddVoice(sndJustYouWait, vpHurtEnemy);
                    end

    // Missed shot
    // A miss is defined as a shot with a damaging weapon with 0 kills, 0 damage, 0 hogs poisoned and 0 targets hit
    else if AmmoDamagingUsed and (Kills <= killsCheck) and (PoisonTurn = 0) and (PoisonClan = 0) and (DamageTurn = 0) and (HitTargets = 0) then
        // Chance to call hedgehog stupid or nutter if sacrificed for nothing
        if CurrentHedgehog^.stats.Sacrificed then
            case random(3) of
            0: AddVoice(sndMissed, PreviousTeam^.voicepack);
            1: AddVoice(sndStupid, PreviousTeam^.voicepack);
            2: AddVoice(sndNutter, PreviousTeam^.voicepack);
            end
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
                GotRevenge:= false;
                end;

Kills:= 0;
KillsSD:= 0;
KillsClan:= 0;
KillsTeam:= 0;
DamageClan:= 0;
DamageTeam:= 0;
DamageTurn:= 0;
HitTargets:= 0;
PoisonClan:= 0;
PoisonTeam:= 0;
PoisonTurn:= 0;
AmmoUsedCount:= 0;
LeaveMeAlone:= false;
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
                    SendStat(siTeamRank, _S'1');
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
                            SendStat(siTeamRank, IntToStr(currentRank));
                            SendStat(siPlayerKills, IntToStr(deathEntry^.killedClans[c]^.Color) + ' ' +
                                IntToStr(TeamsArray[t]^.stats.Kills) + ' ' + TeamsArray[t]^.TeamName);
                            end;
                    deathEntry^.KilledClans[c]^.StatsHandled:= true;
                    inc(i);
                    end;
            if i > 0 then
                inc(currentRank, i);
            i:= 0;
            deathEntry:= deathEntry^.NextEntry;
            end;

    // "Achievements" / Details part of stats screen
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
        ScriptCall('onGameResult', winnersClan^.ClanIndex);
        WriteLnToConsole('WINNERS');
        WriteLnToConsole(inttostr(winnersClan^.TeamsNumber));
        for t:= 0 to winnersClan^.TeamsNumber - 1 do
            WriteLnToConsole(winnersClan^.Teams[t]^.TeamName);
        end
    else
        begin
        ScriptCall('onGameResult', -1);
        WriteLnToConsole('DRAW');
        end;

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
    DamageTeam  := 0;
    DamageTotal := 0;
    DamageTurn  := 0;
    PoisonClan  := 0;
    PoisonTeam  := 0;
    PoisonTurn  := 0;
    KillsClan   := 0;
    KillsTeam   := 0;
    KillsSD     := 0;
    Kills       := 0;
    KillsTotal  := 0;
    HitTargets  := 0;
    AmmoUsedCount := 0;
    AmmoDamagingUsed := false;
    FirstBlood:= false;
    LeaveMeAlone := false;
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

(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2008 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uStats;
interface
uses uGears, uConsts;

type TStatistics = record
                   DamageRecv,
                   DamageGiven: Longword;
                   StepDamageRecv,
                   StepDamageGiven,
                   StepKills: Longword;
                   MaxStepDamageRecv,
                   MaxStepDamageGiven,
                   MaxStepKills: Longword;
                   FinishedTurns: Longword;
                   end;

var TotalRounds: LongInt;
    FinishedTurnsTotal: LongInt;

procedure initModule;
procedure freeModule;

procedure AmmoUsed(am: TAmmoType);
procedure HedgehogDamaged(Gear: PGear);
procedure Skipped;
procedure TurnReaction;
procedure SendStats;

implementation
uses uTeams, uSound, uMisc, uLocale, uWorld;
var DamageGiven : Longword = 0;
    DamageClan  : Longword = 0;
    DamageTotal : Longword = 0;
    KillsClan   : LongWord = 0;
    Kills       : LongWord = 0;
    KillsTotal  : LongWord = 0;
    AmmoUsedCount : Longword = 0;
    AmmoDamagingUsed : boolean = false;
    SkippedTurns: LongWord = 0;
    isTurnSkipped: boolean = false;
    vpHurtSameClan: PVoicepack = nil;
    vpHurtEnemy: PVoicepack = nil;

procedure HedgehogDamaged(Gear: PGear);
begin
if CurrentHedgehog^.Team^.Clan = PHedgehog(Gear^.Hedgehog)^.Team^.Clan then
    vpHurtSameClan:= CurrentHedgehog^.Team^.voicepack
else
    vpHurtEnemy:= PHedgehog(Gear^.Hedgehog)^.Team^.voicepack;

if bBetweenTurns then exit;

//////////////////////////

if Gear <> CurrentHedgehog^.Gear then
    inc(CurrentHedgehog^.stats.StepDamageGiven, Gear^.Damage);

if CurrentHedgehog^.Team^.Clan = PHedgehog(Gear^.Hedgehog)^.Team^.Clan then inc(DamageClan, Gear^.Damage);

if Gear^.Health <= Gear^.Damage then
    begin
    inc(CurrentHedgehog^.stats.StepKills);
    inc(Kills);
    inc(KillsTotal);
    if CurrentHedgehog^.Team^.Clan = PHedgehog(Gear^.Hedgehog)^.Team^.Clan then inc(KillsClan);
    end;

inc(PHedgehog(Gear^.Hedgehog)^.stats.StepDamageRecv, Gear^.Damage);
inc(DamageGiven, Gear^.Damage);
inc(DamageTotal, Gear^.Damage)
end;

procedure Skipped;
begin
inc(SkippedTurns);
isTurnSkipped:= true
end;

procedure TurnReaction;
var i, t: LongInt;
begin
TryDo(not bBetweenTurns, 'Engine bug: TurnReaction between turns', true);

inc(FinishedTurnsTotal);
if FinishedTurnsTotal <> 0 then
    begin
    inc(CurrentHedgehog^.stats.FinishedTurns);

    if (DamageGiven = DamageTotal) and (DamageTotal > 0) then
        PlaySound(sndFirstBlood, CurrentTeam^.voicepack)

    else if CurrentHedgehog^.stats.StepDamageRecv > 0 then
        begin
        PlaySound(sndStupid, PreviousTeam^.voicepack);
        if DamageGiven = CurrentHedgehog^.stats.StepDamageRecv then AddCaption(Format(GetEventString(eidHurtSelf), CurrentHedgehog^.Name), cWhiteColor, capgrpMessage);
        end
    else if DamageClan <> 0 then
        if DamageTotal > DamageClan then
            if random(2) = 0 then
                PlaySound(sndNutter, CurrentTeam^.voicepack)
            else
                PlaySound(sndWatchIt, vpHurtSameClan)
        else
            if random(2) = 0 then
                PlaySound(sndSameTeam, vpHurtSameClan)
            else
                PlaySound(sndTraitor, vpHurtSameClan)
    else if DamageGiven <> 0 then
        if Kills > 0 then
            PlaySound(sndEnemyDown, CurrentTeam^.voicepack)
        else
            PlaySound(sndRegret, vpHurtEnemy)

    else if AmmoDamagingUsed then
        PlaySound(sndMissed, PreviousTeam^.voicepack)
    else if (AmmoUsedCount > 0) and not isTurnSkipped then
        // nothing ?
    else if isTurnSkipped then
        begin
        PlaySound(sndBoring, PreviousTeam^.voicepack);
        AddCaption(Format(GetEventString(eidTurnSkipped), CurrentHedgehog^.Name), cWhiteColor, capgrpMessage);
        end
    else if not PlacingHogs then
        PlaySound(sndCoward, PreviousTeam^.voicepack);
    end;


for t:= 0 to Pred(TeamsCount) do // send even on zero turn
    with TeamsArray[t]^ do
        for i:= 0 to cMaxHHIndex do
            with Hedgehogs[i].stats do
                begin
                inc(DamageRecv, StepDamageRecv);
                inc(DamageGiven, StepDamageGiven);
                if StepDamageRecv > MaxStepDamageRecv then MaxStepDamageRecv:= StepDamageRecv;
                if StepDamageGiven > MaxStepDamageGiven then MaxStepDamageGiven:= StepDamageGiven;
                if StepKills > MaxStepKills then MaxStepKills:= StepKills;
                StepKills:= 0;
                StepDamageRecv:= 0;
                StepDamageGiven:= 0
                end;

for t:= 0 to Pred(ClansCount) do
    with ClansArray[t]^ do
        begin
        SendStat(siClanHealth, inttostr(Color) + ' ' + inttostr(ClanHealth));
        end;

Kills:= 0;
KillsClan:= 0;
DamageGiven:= 0;
DamageClan:= 0;
AmmoUsedCount:= 0;
AmmoDamagingUsed:= false;
isTurnSkipped:= false
end;

procedure AmmoUsed(am: TAmmoType);
begin
inc(AmmoUsedCount);
AmmoDamagingUsed:= AmmoDamagingUsed or Ammoz[am].isDamaging
end;

procedure SendStats;
var i, t: LongInt;
    msd, msk: Longword; msdhh, mskhh: PHedgehog;
    mskcnt: Longword;
begin
msd:= 0; msdhh:= nil;
msk:= 0; mskhh:= nil;
mskcnt:= 0;

for t:= 0 to Pred(TeamsCount) do
    with TeamsArray[t]^ do
        begin
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
            end
        end;
if msdhh <> nil then
    SendStat(siMaxStepDamage, inttostr(msd) + ' ' + msdhh^.Name + ' (' + msdhh^.Team^.TeamName + ')');
if mskcnt = 1 then
    SendStat(siMaxStepKills, inttostr(msk) + ' ' + mskhh^.Name + ' (' + mskhh^.Team^.TeamName + ')');

if KilledHHs > 0 then SendStat(siKilledHHs, inttostr(KilledHHs));
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

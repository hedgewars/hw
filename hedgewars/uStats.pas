(*
 * Hedgewars, a worms-like game
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

procedure AmmoUsed(am: TAmmoType);
procedure HedgehogDamaged(Gear: PGear);
procedure Skipped;
procedure TurnReaction;
procedure SendStats;

implementation
uses uTeams, uSound, uMisc;
var DamageGiven : Longword = 0;
    DamageClan  : Longword = 0;
    DamageTotal : Longword = 0;
    KillsClan   : LongWord = 0;
    Kills       : LongWord = 0;
    KillsTotal  : LongWord = 0;
    AmmoUsedCount : Longword = 0;
    AmmoDamagingUsed : boolean = false;
    FinishedTurnsTotal: LongInt = -1;
    SkippedTurns: LongWord = 0;
    isTurnSkipped: boolean = false;

procedure HedgehogDamaged(Gear: PGear);
begin
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
var Gear: PGear;
    i, t: LongInt;
begin
inc(FinishedTurnsTotal);
if FinishedTurnsTotal = 0 then exit;

inc(CurrentHedgehog^.stats.FinishedTurns);

if (DamageGiven = DamageTotal) and (DamageTotal > 0) then
	PlaySound(sndFirstBlood, false)

else if CurrentHedgehog^.stats.StepDamageRecv > 0 then
	PlaySound(sndStupid, false)

else if DamageClan <> 0 then
	if DamageTotal > DamageClan then
		if random(2) = 0 then
			PlaySound(sndNutter, false)
		else
			PlaySound(sndWatchIt, false)
	else
		if random(2) = 0 then
			PlaySound(sndSameTeam, false)
		else
			PlaySound(sndTraitor, false)

else if DamageGiven <> 0 then
	if Kills > 0 then
		PlaySound(sndEnemyDown, false)
	else
		PlaySound(sndRegret, false)

else if AmmoDamagingUsed then
	PlaySound(sndMissed, false)
else if AmmoUsedCount > 0 then
	// nothing ?
else if isTurnSkipped then
	PlaySound(sndBoring, false)
else
	PlaySound(sndCoward, false);


for t:= 0 to Pred(TeamsCount) do
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

end.
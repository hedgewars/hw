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
                   StepDamageGiven: Longword;
                   MaxStepDamageRecv,
                   MaxStepDamageGiven: Longword;
                   FinishedTurns: Longword;
                   end;

procedure AmmoUsed(am: TAmmoType);
procedure HedgehogDamaged(Gear: PGear; Damage: Longword);
procedure TurnReaction;
procedure SendStats;

implementation
uses uTeams, uSound, uMisc;
var DamageGiven : Longword = 0;
    DamageClan  : Longword = 0;
    DamageTotal : Longword = 0;
    AmmoUsedCount : Longword = 0;
    AmmoDamagingUsed : boolean = false;

procedure HedgehogDamaged(Gear: PGear; Damage: Longword);
begin
if Gear <> CurrentHedgehog^.Gear then
   inc(CurrentHedgehog^.stats.StepDamageGiven, Damage);

if CurrentHedgehog^.Team^.Clan = PHedgehog(Gear^.Hedgehog)^.Team^.Clan then inc(DamageClan, Damage);


inc(PHedgehog(Gear^.Hedgehog)^.stats.StepDamageRecv, Damage);
inc(DamageGiven, Damage);
inc(DamageTotal, Damage)
end;

procedure TurnReaction;
var Gear: PGear;
begin
inc(CurrentHedgehog^.stats.FinishedTurns);

if (DamageGiven = DamageTotal) and (DamageTotal > 0) then PlaySound(sndFirstBlood, false)
else if CurrentHedgehog^.stats.StepDamageRecv > 0 then PlaySound(sndStupid, false)
else if DamageClan <> 0 then
else if DamageGiven <> 0 then
else if AmmoDamagingUsed then PlaySound(sndMissed, false);

Gear:= GearsList;
while Gear <> nil do
  begin
  if Gear^.Kind = gtHedgehog then
    with PHedgehog(Gear^.Hedgehog)^.stats do
      begin
      inc(DamageRecv, StepDamageRecv);
      inc(DamageGiven, StepDamageGiven);
      if StepDamageRecv > MaxStepDamageRecv then MaxStepDamageRecv:= StepDamageRecv;
      if StepDamageGiven > MaxStepDamageGiven then MaxStepDamageGiven:= StepDamageGiven;
      StepDamageRecv:= 0;
      StepDamageGiven:= 0
      end;
  Gear:= Gear^.NextGear
  end;

DamageGiven:= 0;
DamageClan:= 0;
AmmoUsedCount:= 0;
AmmoDamagingUsed:= false
end;

procedure AmmoUsed(am: TAmmoType);
begin
inc(AmmoUsedCount);
AmmoDamagingUsed:= AmmoDamagingUsed or Ammoz[am].isDamaging
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
          if Hedgehogs[i].stats.StepDamageGiven > msd then
             begin
             msdhh:= @Hedgehogs[i];
             msd:= Hedgehogs[i].stats.StepDamageGiven
             end;
      end;
if msdhh <> nil then SendStat(siMaxStepDamage, inttostr(msd) + ' ' +
                                               msdhh^.Name + ' (' + msdhh^.Team^.TeamName + ')');
if KilledHHs > 0 then SendStat(siKilledHHs, inttostr(KilledHHs));
end;

end.
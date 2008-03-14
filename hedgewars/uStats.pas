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
uses uGears;

type TStatistics = record
                   DamageRecv,
                   DamageGiven: Longword;
                   StepDamageRecv,
                   StepDamageGiven: Longword;
                   MaxStepDamageRecv,
                   MaxStepDamageGiven: Longword;
                   Turns: Longword;
                   end;

procedure HedgehogDamaged(Gear: PGear; Damage: Longword);
procedure TurnReaction;
procedure SendStats;

implementation
uses uTeams, uSound, uConsts;

procedure HedgehogDamaged(Gear: PGear; Damage: Longword);
begin
if Gear <> CurrentHedgehog^.Gear then
   inc(CurrentHedgehog^.stats.StepDamageGiven, Damage);
inc(PHedgehog(Gear^.Hedgehog)^.stats.StepDamageRecv, Damage)
end;

procedure TurnReaction;
begin
end;

procedure SendStats;
//var i, t: LongInt;
//    msd: Longword; msdhh: PHedgehog;
begin
(*msd:= 0; msdhh:= nil;
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
if KilledHHs > 0 then SendStat(siKilledHHs, inttostr(KilledHHs));*)
end;

end.
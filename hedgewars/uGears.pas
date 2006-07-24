(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uGears;
interface
uses SDLh, uConsts;
{$INCLUDE options.inc}
const AllInactive: boolean = false;

type PGear = ^TGear;
     TGearStepProcedure = procedure (Gear: PGear);
     TGear = record
             NextGear, PrevGear: PGear;
             Active: Boolean;
             State : Cardinal;
             X : Real;
             Y : Real;
             dX: Real;
             dY: Real;
             Kind: TGearType;
             Pos: Longword;
             doStep: TGearStepProcedure;
             Radius: integer;
             Angle, Power : Cardinal;
             DirAngle: real;
             Timer : LongWord;
             Elasticity: Real;
             Friction  : Real;
             Message : Longword;
             Hedgehog: pointer;
             Health, Damage: integer;
             CollIndex: Longword;
             Tag: integer;
             end;

function  AddGear(X, Y: integer; Kind: TGearType; State: Cardinal; const dX: real=0.0; dY: real=0.0; Timer: LongWord=0): PGear;
procedure ProcessGears;
procedure SetAllToActive;
procedure SetAllHHToActive;
procedure DrawGears(Surface: PSDL_Surface);
procedure FreeGearsList;
procedure AddMiscGears;
procedure AssignHHCoords;

var CurAmmoGear: PGear = nil;
    GearsList: PGear = nil;

implementation
uses uWorld, uMisc, uStore, uConsole, uSound, uTeams, uRandom, uCollisions,
     uLand, uIO, uLandGraphics, uAIMisc, uLocale;
var RopePoints: record
                Count: Longword;
                HookAngle: integer;
                ar: array[0..300] of record
                                  X, Y: real;
                                  dLen: real;
                                  b: boolean;
                                  end;
                 end;

procedure DeleteGear(Gear: PGear); forward;
procedure doMakeExplosion(X, Y, Radius: integer; Mask: LongWord); forward;
procedure AmmoShove(Ammo: PGear; Damage, Power: integer); forward;
procedure AmmoFlameWork(Ammo: PGear); forward;
function  CheckGearNear(Gear: PGear; Kind: TGearType; rX, rY: integer): PGear; forward;
procedure SpawnBoxOfSmth; forward;
procedure AfterAttack; forward;
procedure FindPlace(Gear: PGear; withFall: boolean; Left, Right: integer); forward;

{$INCLUDE GSHandlers.inc}
{$INCLUDE HHHandlers.inc}

const doStepHandlers: array[TGearType] of TGearStepProcedure = (
                                                               doStepCloud,
                                                               doStepBomb,
                                                               doStepHedgehog,
                                                               doStepGrenade,
                                                               doStepHealthTag,
                                                               doStepGrave,
                                                               doStepUFO,
                                                               doStepShotgunShot,
                                                               doStepPickHammer,
                                                               doStepRope,
                                                               doStepSmokeTrace,
                                                               doStepExplosion,
                                                               doStepMine,
                                                               doStepCase,
                                                               doStepDEagleShot,
                                                               doStepDynamite,
                                                               doStepTeamHealthSorter,
                                                               doStepBomb,
                                                               doStepCluster,
                                                               doStepShover,
                                                               doStepFlame,
                                                               doStepFirePunch,
                                                               doStepActionTimer,
                                                               doStepActionTimer,
                                                               doStepActionTimer
                                                               );

function AddGear(X, Y: integer; Kind: TGearType; State: Cardinal; const dX: real=0.0; dY: real=0.0; Timer: LongWord=0): PGear;
const Counter: Longword = 0;
begin
inc(Counter);
{$IFDEF DEBUGFILE}AddFileLog('AddGear: ('+inttostr(x)+','+inttostr(y)+')');{$ENDIF}
New(Result);
{$IFDEF DEBUGFILE}AddFileLog('AddGear: handle = '+inttostr(integer(Result)));{$ENDIF}
FillChar(Result^, sizeof(TGear), 0);
Result.X:= X;
Result.Y:= Y;
Result.Kind := Kind;
Result.State:= State;
Result.Active:= true;
Result.dX:= dX;
Result.dY:= dY;
Result.doStep:= doStepHandlers[Kind];
Result.CollIndex:= High(Longword);
Result.Timer:= Timer;
if CurrentTeam <> nil then
   Result.Hedgehog:= @CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog];
case Kind of
   gtAmmo_Bomb: begin
                Result.Radius:= 4;
                Result.Elasticity:= 0.6;
                Result.Friction:= 0.995;
                end;
    gtHedgehog: begin
                Result.Radius:= cHHRadius;
                Result.Elasticity:= 0.002;
                Result.Friction:= 0.999;
                Result.Angle:= cMaxAngle div 2;
                end;
gtAmmo_Grenade: begin
                Result.Radius:= 4;
                end;
   gtHealthTag: begin
                Result.Timer:= 1500;
                end;
       gtGrave: begin
                Result.Radius:= 10;
                Result.Elasticity:= 0.6;
                end;
         gtUFO: begin
                Result.Radius:= 5;
                Result.Timer:= 500;
                Result.Elasticity:= 0.9
                end;
 gtShotgunShot: begin
                Result.Timer:= 900;
                Result.Radius:= 2
                end;
  gtPickHammer: begin
                Result.Radius:= 10;
                Result.Timer:= 4000
                end;
  gtSmokeTrace: begin
                Result.X:= Result.X - 16;
                Result.Y:= Result.Y - 16;
                Result.State:= 8
                end;
        gtRope: begin
                Result.Radius:= 3;
                Result.Friction:= 500;
                RopePoints.Count:= 0;
                end;
   gtExplosion: begin
                Result.X:= Result.X - 25;
                Result.Y:= Result.Y - 25;
                end;
        gtMine: begin
                Result.Radius:= 3;
                Result.Elasticity:= 0.55;
                Result.Friction:= 0.995;
                Result.Timer:= 3000;
                end;
        gtCase: begin
                Result.Radius:= 16;
                Result.Elasticity:= 0.6
                end;
  gtDEagleShot: begin
                Result.Radius:= 1;
                Result.Radius:= 1;
                Result.Health:= 50
                end;
    gtDynamite: begin
                Result.Radius:= 3;
                Result.Elasticity:= 0.55;
                Result.Friction:= 0.03;
                Result.Timer:= 5000;
                end;
 gtClusterBomb: begin
                Result.Radius:= 4;
                Result.Elasticity:= 0.6;
                Result.Friction:= 0.995;
                end;
       gtFlame: begin
                Result.Angle:= Counter mod 64;
                Result.Radius:= 1;
                Result.Health:= 2;
                Result.dY:= (getrandom - 0.8) * 0.03;
                Result.dX:= (getrandom - 0.5) * 0.4
                end;
   gtFirePunch: begin
                Result.Radius:= 15;
                Result.Tag:= Y
                end;
     end;
if GearsList = nil then GearsList:= Result
                   else begin
                   GearsList.PrevGear:= Result;
                   Result.NextGear:= GearsList;
                   GearsList:= Result
                   end
end;

procedure DeleteGear(Gear: PGear);
var team: PTeam;
begin
if Gear.CollIndex < High(Longword) then DeleteCI(Gear);
if Gear.Kind = gtHedgehog then
   if CurAmmoGear <> nil then
      begin
      {$IFDEF DEBUGFILE}AddFileLog('DeleteGear: Sending gm_Destroy, hh handle = '+inttostr(integer(Gear)));{$ENDIF}
      Gear.Message:= gm_Destroy;
      CurAmmoGear.Message:= gm_Destroy;
      exit
      end else
      begin
      team:= PHedgehog(Gear.Hedgehog).Team;
      PHedgehog(Gear.Hedgehog).Gear:= nil;
      RecountTeamHealth(team);
      end;
if CurAmmoGear = Gear then CurAmmoGear:= nil;
if FollowGear = Gear then FollowGear:= nil;
{$IFDEF DEBUGFILE}AddFileLog('DeleteGear: handle = '+inttostr(integer(Gear)));{$ENDIF}
if Gear.NextGear <> nil then Gear.NextGear.PrevGear:= Gear.PrevGear;
if Gear.PrevGear <> nil then Gear.PrevGear.NextGear:= Gear.NextGear
                        else begin
                        GearsList:= Gear^.NextGear;
                        if GearsList <> nil then GearsList.PrevGear:= nil
                        end;
Dispose(Gear)
end;

function CheckNoDamage: boolean; // returns TRUE in case of no damaged hhs
var Gear: PGear;
begin
Result:= true;
Gear:= GearsList;
while Gear <> nil do
      begin
      if Gear.Kind = gtHedgehog then
         if Gear.Damage <> 0 then
            begin
            Result:= false;
            if Gear.Health < Gear.Damage then Gear.Health:= 0
                                         else dec(Gear.Health, Gear.Damage);
            AddGear(Round(Gear.X), Round(Gear.Y) - 32, gtHealthTag, Gear.Damage).Hedgehog:= Gear.Hedgehog;
            RenderHealth(PHedgehog(Gear.Hedgehog)^);
            RecountTeamHealth(PHedgehog(Gear.Hedgehog)^.Team);
            
            Gear.Damage:= 0
            end;
      Gear:= Gear.NextGear
      end;
CheckForWin
end;

procedure ProcessGears;
const delay: integer = cInactDelay;
      step: (stDelay, stChDmg, stSpawn, stNTurn) = stDelay;
var Gear, t: PGear;
{$IFDEF COUNTTICKS}
    tickcntA, tickcntB: LongWord;
const cntSecTicks: LongWord = 0;
{$ENDIF}
begin
{$IFDEF COUNTTICKS}
asm
        push    eax
        push    edx
        rdtsc
        mov     tickcntA, eax
        mov     tickcntB, edx
        pop     edx
        pop     eax
end;
{$ENDIF}
AllInactive:= true;
t:= GearsList;
while t<>nil do
      begin
      Gear:= t;
      t:= Gear.NextGear;
      if Gear.Active then Gear.doStep(Gear);
      end;
if AllInactive then
   case step of
        stDelay: begin
                 dec(delay);
                 if delay = 0 then
                    begin
                    inc(step);
                    delay:= cInactDelay
                    end
                 end;
        stChDmg: if CheckNoDamage then inc(step) else step:= stDelay;
        stSpawn: begin
                 if not isInMultiShoot then SpawnBoxOfSmth;
                 inc(step)
                 end;
        stNTurn: begin
                 AwareOfExplosion(0, 0, 0);
                 if isInMultiShoot then isInMultiShoot:= false
                                   else ParseCommand('/nextturn');
                 step:= Low(step)
                 end;
        end;

if TurnTimeLeft > 0 then
   if CurrentTeam <> nil then
      if CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear <> nil then
         if ((CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear.State and gstAttacking) = 0)
            and not isInMultiShoot then dec(TurnTimeLeft);
            
inc(GameTicks);
{$IFDEF COUNTTICKS}
asm
        push    eax
        push    edx
        rdtsc
        sub     eax, [tickcntA]
        sbb     edx, [tickcntB]
        add     [cntSecTicks], eax
        pop     edx
        pop     eax
end;
if (GameTicks and 1023) = 0 then
   begin
   cntTicks:= cntSecTicks shr 10;
   {$IFDEF DEBUGFILE}
   AddFileLog('<' + inttostr(cntTicks) + '>x1024 ticks');
   {$ENDIF}
   cntSecTicks:= 0
   end;
{$ENDIF}
end;

procedure SetAllToActive;
var t: PGear;
begin
AllInactive:= false;
t:= GearsList;
while t<>nil do
      begin
      t.Active:= true;
      t:= t.NextGear
      end
end;

procedure SetAllHHToActive;
var t: PGear;
begin
AllInactive:= false;
t:= GearsList;
while t<>nil do
      begin
      if t.Kind = gtHedgehog then t.Active:= true;
      t:= t.NextGear
      end
end;

procedure DrawGears(Surface: PSDL_Surface);
var Gear: PGear;
    i: Longword;
    roplen: real;

    procedure DrawRopeLine(X1, Y1, X2, Y2: integer);
    const nodlen = 5;
    var i, x, y: integer;
        t, k, ladd: real;
    begin
    if (X1 = X2) and (Y1 = Y2) then
       begin
       OutError('WARNING: zero length rope line!');
       exit
       end;
    if abs(X1 - X2) > abs(Y1 - Y2) then
       begin
       if X1 > X2 then
          begin
          i:= X1;
          X1:= X2;
          X2:= i;
          i:= Y1;
          Y1:= Y2;
          Y2:= i
          end;
       k:= (Y2 - Y1) / (X2 - X1);
       ladd:= sqrt(1 + sqr(k));
       if X1 < 0 then
          begin
          t:= Y1 - 2 - k * X1;
          X1:= 0
          end else t:= Y1 - 2;
       if X2 > cScreenWidth then X2:= cScreenWidth;
       for x:= X1 to X2 do
           begin
           roplen:= roplen + ladd;
           if roplen > nodlen then
              begin
              DrawGear(sRopeNode, x - 2, round(t) - 2, Surface);
              roplen:= roplen - nodlen;
              end;
           t:= t + k;
           end;
       end else
       begin
       if Y1 > Y2 then
          begin
          i:= X1;
          X1:= X2;
          X2:= i;
          i:= Y1;
          Y1:= Y2;
          Y2:= i
          end;
       k:= (X2 - X1) / (Y2 - Y1);
       ladd:= sqrt(1 + sqr(k));
       if Y1 < 0 then
          begin
          t:= X1 - 2 - k * Y1;
          Y1:= 0
          end else t:= X1 - 2;
       if Y2 > cScreenHeight then Y2:= cScreenHeight;
       for y:= Y1 to Y2 do
           begin
           roplen:= roplen + ladd;
           if roplen > nodlen then
              begin
              DrawGear(sRopeNode, round(t) - 2, y - 2, Surface);
              roplen:= roplen - nodlen;
              end;
           t:= t + k;
           end;
       end
    end;

begin
Gear:= GearsList;
while Gear<>nil do
      begin
      case Gear.Kind of
           gtCloud: DrawSprite(sprCloud   , Round(Gear.X) + WorldDx, Round(Gear.Y) + WorldDy, Gear.State, Surface);
       gtAmmo_Bomb: DrawSprite(sprBomb , Round(Gear.X) - 8 + WorldDx, Round(Gear.Y) - 8 + WorldDy, trunc(Gear.DirAngle), Surface);
        gtHedgehog: DrawHedgehog(Round(Gear.X) - 14 + WorldDx, Round(Gear.Y) - 18 + WorldDy, Sign(Gear.dX),
                                 0, PHedgehog(Gear.Hedgehog).visStepPos div 2,
                                 Surface);
    gtAmmo_Grenade: DrawSprite(sprGrenade , Round(Gear.X) - 16 + WorldDx, Round(Gear.Y) - 16 + WorldDy, DxDy2Angle32(Gear.dY, Gear.dX), Surface);
       gtHealthTag: DrawCaption(Round(Gear.X) + WorldDx, Round(Gear.Y) + WorldDy, PHedgehog(Gear.Hedgehog).HealthTagRect, Surface, true);
           gtGrave: DrawSpriteFromRect(PHedgehog(Gear.Hedgehog).Team.GraveRect, Round(Gear.X) + WorldDx - 16, Round(Gear.Y) + WorldDy - 16, 32, (GameTicks shr 7) and 7, Surface);
             gtUFO: DrawSprite(sprUFO, Round(Gear.X) - 16 + WorldDx, Round(Gear.Y) - 16 + WorldDy, (GameTicks shr 7) mod 4, Surface);
      gtSmokeTrace: if Gear.State < 8 then DrawSprite(sprSmokeTrace, Round(Gear.X) + WorldDx, Round(Gear.Y) + WorldDy, Gear.State, Surface);
            gtRope: begin
                    roplen:= 0;
                    if RopePoints.Count > 0 then
                       begin
                       i:= 0;
                       while i < Pred(RopePoints.Count) do
                             begin
                             DrawRopeLine(Round(RopePoints.ar[i].X) + WorldDx, Round(RopePoints.ar[i].Y) + WorldDy,
                                          Round(RopePoints.ar[Succ(i)].X) + WorldDx, Round(RopePoints.ar[Succ(i)].Y) + WorldDy);
                             inc(i)
                             end;
                       DrawRopeLine(Round(RopePoints.ar[i].X) + WorldDx, Round(RopePoints.ar[i].Y) + WorldDy,
                                    Round(Gear.X) + WorldDx, Round(Gear.Y) + WorldDy);
                       DrawRopeLine(Round(Gear.X) + WorldDx, Round(Gear.Y) + WorldDy,
                                    Round(PHedgehog(Gear.Hedgehog).Gear.X) + WorldDx, Round(PHedgehog(Gear.Hedgehog).Gear.Y) + WorldDy);
                       DrawSprite(sprRopeHook, Round(RopePoints.ar[0].X) + WorldDx - 16, Round(RopePoints.ar[0].Y) + WorldDy - 16, RopePoints.HookAngle, Surface);
                       end else
                       begin
                       DrawRopeLine(Round(Gear.X) + WorldDx, Round(Gear.Y) + WorldDy,
                                    Round(PHedgehog(Gear.Hedgehog).Gear.X) + WorldDx, Round(PHedgehog(Gear.Hedgehog).Gear.Y) + WorldDy);
                       DrawSprite(sprRopeHook, Round(Gear.X) - 16 + WorldDx, Round(Gear.Y) - 16 + WorldDy, DxDy2Angle32(Gear.dY, Gear.dX), Surface);
                       end;
                    end;
       gtExplosion: DrawSprite(sprExplosion50, Round(Gear.X) + WorldDx, Round(Gear.Y) + WorldDy, Gear.State, Surface);
            gtMine: if ((Gear.State and gstAttacking) = 0)or((Gear.Timer and $3FF) < 420)
                       then DrawSprite(sprMineOff , Round(Gear.X) - 8 + WorldDx, Round(Gear.Y) - 8 + WorldDy, trunc(Gear.DirAngle), Surface)
                       else DrawSprite(sprMineOn  , Round(Gear.X) - 8 + WorldDx, Round(Gear.Y) - 8 + WorldDy, trunc(Gear.DirAngle), Surface);
        gtDynamite: DrawSprite2(sprDynamite, Round(Gear.X) - 16 + WorldDx, Round(Gear.Y) - 25 + WorldDy, Gear.Tag and 1, Gear.Tag shr 1, Surface);
            gtCase: case Gear.Pos of
                         posCaseAmmo  : DrawSprite(sprCase, Round(Gear.X) - 16 + WorldDx, Round(Gear.Y) - 16 + WorldDy, 0, Surface);
                         posCaseHealth: DrawSprite(sprFAid, Round(Gear.X) - 24 + WorldDx, Round(Gear.Y) - 24 + WorldDy, (GameTicks shr 6) mod 13, Surface);
                         end;
     gtClusterBomb: DrawSprite(sprClusterBomb, Round(Gear.X) - 8 + WorldDx, Round(Gear.Y) - 8 + WorldDy, trunc(Gear.DirAngle), Surface);
         gtCluster: DrawSprite(sprClusterParticle, Round(Gear.X) - 8 + WorldDx, Round(Gear.Y) - 8 + WorldDy, 0, Surface);
           gtFlame: DrawSprite(sprFlame, Round(Gear.X) - 8 + WorldDx, Round(Gear.Y) - 8 + WorldDy,(GameTicks div 128 + Gear.Angle) mod 8, Surface);
              end;
      Gear:= Gear.NextGear
      end;
end;

procedure FreeGearsList;
var t, tt: PGear;
begin
tt:= GearsList;
GearsList:= nil;
while tt<>nil do
      begin
      t:= tt;
      tt:= tt.NextGear;
      Dispose(t)
      end;
end;

procedure AddMiscGears;
var i: integer;
begin
for i:= 0 to cCloudsNumber do
    AddGear( - cScreenWidth + i * ((cScreenWidth * 2 + 2304) div cCloudsNumber), -140, gtCloud, random(4),
             (0.5-random)*0.02, ((i mod 2) * 2 - 1) * (0.005 + 0.015*random));
AddGear(0, 0, gtATStartGame, 0, 0, 0, 2000);
if (GameFlags and gfForts) = 0 then
   for i:= 0 to 3 do
       FindPlace(AddGear(0, 0, gtMine, 0), false, 0, 2048);
end;

procedure doMakeExplosion(X, Y, Radius: integer; Mask: LongWord);
var Gear: PGear;
    dmg: integer;
begin
TargetPoint.X:= NoPointX;
{$IFDEF DEBUGFILE}if Radius > 3 then AddFileLog('Explosion: at (' + inttostr(x) + ',' + inttostr(y) + ')');{$ENDIF}
DrawExplosion(X, Y, Radius);
if Radius = 50 then AddGear(X, Y, gtExplosion, 0);
if (Mask and EXPLAutoSound)<>0 then PlaySound(sndExplosion);
if (Mask and EXPLAllDamageInRadius)=0 then Radius:= Radius shl 1;
Gear:= GearsList;
while Gear <> nil do
      begin
      dmg:= Radius - Round(sqrt(sqr(Gear.X - X) + sqr(Gear.Y - Y)));
      if dmg > 0 then
         begin
         dmg:= dmg shr 1;
         case Gear.Kind of
              gtHedgehog,
                  gtMine,
                  gtCase,
                 gtFlame: begin
                          if (Mask and EXPLNoDamage) = 0 then inc(Gear.Damage, dmg);
                          if ((Mask and EXPLDoNotTouchHH) = 0) or (Gear.Kind <> gtHedgehog) then
                             begin
                             Gear.dX:= Gear.dX + dmg / 200 * Sign(Gear.X - X);
                             Gear.dY:= Gear.dY + dmg / 200 * Sign(Gear.Y - Y);
                             Gear.Active:= true;
                             FollowGear:= Gear
                             end;
                          end;
                 gtGrave: begin
                          Gear.dY:= - dmg / 250;
                          Gear.Active:= true;
                          end;
              end;
         end;
      Gear:= Gear.NextGear
      end;
uAIMisc.AwareOfExplosion(0, 0, 0)
end;

procedure AmmoShove(Ammo: PGear; Damage, Power: integer);
var t: PGearArray;
    i: integer;
begin
t:= CheckGearsCollision(Ammo);
i:= t.Count;
while i > 0 do
    begin
    dec(i);
    if (t.ar[i].State and gstNoDamage) = 0 then
       case t.ar[i].Kind of
           gtHedgehog,
               gtMine,
               gtCase: begin
                       inc(t.ar[i].Damage, Damage);
                       t.ar[i].dX:= Ammo.dX * Power * 0.01;
                       t.ar[i].dY:= Ammo.dY * Power * 0.01;
                       t.ar[i].Active:= true;
                       DeleteCI(t.ar[i]);
                       FollowGear:= t.ar[i]
                       end;
           end
    end
end;

procedure AssignHHCoords;
var Team: PTeam;
    i, t: integer;
begin
Team:= TeamsList;
t:= 0;
while Team <> nil do
      begin
      for i:= 0 to cMaxHHIndex do
          with Team.Hedgehogs[i] do
               if Gear <> nil then
                  if (GameFlags and gfForts) = 0 then FindPlace(Gear, false, 0, 2048)
                                                 else FindPlace(Gear, false, t, t + 1024);
      inc(t, 1024);
      Team:= Team.Next
      end
end;

function CheckGearNear(Gear: PGear; Kind: TGearType; rX, rY: integer): PGear;
var t: PGear;
begin
t:= GearsList;
rX:= sqr(rX);
rY:= sqr(rY);
while t <> nil do
      begin
      if (t <> Gear) and (t.Kind = Kind) then
         if sqr(Gear.X - t.X) / rX + sqr(Gear.Y - t.Y) / rY <= 1 then
            begin
            Result:= t;
            exit
            end;
      t:= t.NextGear
      end;
Result:= nil
end;

procedure AmmoFlameWork(Ammo: PGear);
var t: PGear;
begin
t:= GearsList;
while t <> nil do
      begin
      if (t.Kind = gtHedgehog) and (t.Y < Ammo.Y) then
         if sqr(Ammo.X - t.X) + sqr(Ammo.Y - t.Y - cHHRadius) * 2 <= sqr(4) then
            begin
            inc(t.Damage, 5);
            t.dX:= t.dX + (t.X - Ammo.X) * 0.02;
            t.dY:= - 0.25;
            t.Active:= true;
            DeleteCI(t);
            FollowGear:= t
            end;
      t:= t.NextGear
      end;
end;

function CheckGearsNear(mX, mY: integer; Kind: TGearsType; rX, rY: integer): PGear;
var t: PGear;
begin
t:= GearsList;
rX:= sqr(rX);
rY:= sqr(rY);
while t <> nil do
      begin
      if t.Kind in Kind then
         if sqr(mX - t.X) / rX + sqr(mY - t.Y) / rY <= 1 then
            begin
            Result:= t;
            exit
            end;
      t:= t.NextGear
      end;
Result:= nil
end;

function CountGears(Kind: TGearType): Longword;
var t: PGear;
begin
Result:= 0;
t:= GearsList;
while t <> nil do
      begin
      if t.Kind = Kind then inc(Result);
      t:= t.NextGear
      end;
end;

procedure SpawnBoxOfSmth;
begin
if (CountGears(gtCase) > 2) or (getrandom(3) <> 0) then exit;
FollowGear:= AddGear(0, 0, gtCase, 0);
FollowGear.Health:= 25;
FollowGear.Pos:= posCaseHealth;
FindPlace(FollowGear, true, 0, 2048)
end;

procedure FindPlace(Gear: PGear; withFall: boolean; Left, Right: integer);

    function CountNonZeroz(x, y, r: integer): integer;
    var i: integer;
    begin
    Result:= 0;
    if (y and $FFFFFC00) <> 0 then exit;
    for i:= max(x - r, 0) to min(x + r, 2043) do
        if Land[y, i] <> 0 then inc(Result)
    end;

var fx, x: integer;
    y, sy: integer;
    ar: array[0..512] of TPoint;
    cnt, delta: Longword;
begin
fx:= Left + integer(GetRandom(Right - Left));
x:= fx;
delta:= 130;
repeat
  repeat
     inc(x, Gear.Radius);
     if x > Right then x:= Left + (x mod (Right - left));
     cnt:= 0;
     y:= -Gear.Radius * 2;
     while y < 1023 do
        begin
        repeat
          inc(y, 2);
        until (y > 1023) or (CountNonZeroz(x, y, Gear.Radius - 1) = 0);
        sy:= y;
        repeat
          inc(y);
        until (y > 1023) or (CountNonZeroz(x, y, Gear.Radius - 1) <> 0);
        if (y - sy > Gear.Radius * 2)
        and (y < 1023)
        and (CheckGearsNear(x, y - Gear.Radius, [gtHedgehog, gtMine, gtCase], 110, 110) = nil) then
           begin
           ar[cnt].X:= x;
           if withFall then ar[cnt].Y:= sy + Gear.Radius
                       else ar[cnt].Y:= y - Gear.Radius;
           inc(cnt)
           end;
        inc(y, 80)
        end;
     if cnt > 0 then
        with ar[GetRandom(cnt)] do
          begin
          Gear.X:= x;
          Gear.Y:= y;
         {$IFDEF DEBUGFILE}
         AddFileLog('Assigned Gear ' + inttostr(integer(Gear)) +
                    ' coordinates (' + inttostr(x) +
                    ',' + inttostr(y) + ')');
         {$ENDIF}
          exit
          end
  until (x - Gear.Radius < fx) and (x + Gear.Radius > fx);
dec(Delta, 20)
until (Delta < 70);
OutError('Couldn''t find place for Gear ' + inttostr(integer(Gear)), false);
DeleteGear(Gear)
end;

initialization

finalization
FreeGearsList

end.

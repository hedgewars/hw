(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uGears;
interface
uses SDLh, uConsts, uFloat;
{$INCLUDE options.inc}
const AllInactive: boolean = false;

type PGear = ^TGear;
     TGearStepProcedure = procedure (Gear: PGear);
     TGear = record
             NextGear, PrevGear: PGear;
             Active: Boolean;
             State : Longword;
             X : hwFloat;
             Y : hwFloat;
             dX: hwFloat;
             dY: hwFloat;
             Kind: TGearType;
             Pos: Longword;
             doStep: TGearStepProcedure;
             Radius: integer;
             Angle, Power : Longword;
             DirAngle: hwFloat;
             Timer : LongWord;
             Elasticity: hwFloat;
             Friction  : hwFloat;
             Message : Longword;
             Hedgehog: pointer;
             Health, Damage: integer;
             CollIndex: Longword;
             Tag: integer;
             Surf: PSDL_Surface;
             Z: Longword;
             end;

function  AddGear(X, Y: integer; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
procedure ProcessGears;
procedure SetAllToActive;
procedure SetAllHHToActive;
procedure DrawGears(Surface: PSDL_Surface);
procedure FreeGearsList;
procedure AddMiscGears;
procedure AddClouds;
procedure AssignHHCoords;
procedure InsertGearToList(Gear: PGear);
procedure RemoveGearFromList(Gear: PGear);

var CurAmmoGear: PGear = nil;
    GearsList: PGear = nil;
    KilledHHs: Longword = 0;

implementation
uses uWorld, uMisc, uStore, uConsole, uSound, uTeams, uRandom, uCollisions,
     uLand, uIO, uLandGraphics, uAIMisc, uLocale, uAI, uAmmos;
var RopePoints: record
                Count: Longword;
                HookAngle: integer;
                ar: array[0..300] of record
                                  X, Y: hwFloat;
                                  dLen: hwFloat;
                                  b: boolean;
                                  end;
                 end;
    StepDamage: Longword = 0;

procedure DeleteGear(Gear: PGear); forward;
procedure doMakeExplosion(X, Y, Radius: integer; Mask: LongWord); forward;
procedure AmmoShove(Ammo: PGear; Damage, Power: integer); forward;
procedure AmmoFlameWork(Ammo: PGear); forward;
function  CheckGearNear(Gear: PGear; Kind: TGearType; rX, rY: integer): PGear; forward;
procedure SpawnBoxOfSmth; forward;
procedure AfterAttack; forward;
procedure FindPlace(Gear: PGear; withFall: boolean; Left, Right: integer); forward;
procedure HedgehogStep(Gear: PGear); forward;
procedure HedgehogChAngle(Gear: PGear); forward;

{$INCLUDE GSHandlers.inc}
{$INCLUDE HHHandlers.inc}

const doStepHandlers: array[TGearType] of TGearStepProcedure = (
                                                               @doStepCloud,
                                                               @doStepBomb,
                                                               @doStepHedgehog,
                                                               @doStepGrenade,
                                                               @doStepHealthTag,
                                                               @doStepGrave,
                                                               @doStepUFO,
                                                               @doStepShotgunShot,
                                                               @doStepPickHammer,
                                                               @doStepRope,
                                                               @doStepSmokeTrace,
                                                               @doStepExplosion,
                                                               @doStepMine,
                                                               @doStepCase,
                                                               @doStepDEagleShot,
                                                               @doStepDynamite,
                                                               @doStepTeamHealthSorter,
                                                               @doStepBomb,
                                                               @doStepCluster,
                                                               @doStepShover,
                                                               @doStepFlame,
                                                               @doStepFirePunch,
                                                               @doStepActionTimer,
                                                               @doStepActionTimer,
                                                               @doStepActionTimer,
                                                               @doStepParachute,
                                                               @doStepAirAttack,
                                                               @doStepAirBomb,
                                                               @doStepBlowTorch
                                                               );

procedure InsertGearToList(Gear: PGear);
var tmp: PGear;
begin
if GearsList = nil then
   GearsList:= Gear
   else begin
   // WARNING: this code assumes that the first gears added to the list are clouds (have maximal Z)
   tmp:= GearsList;
   while (tmp <> nil) and (tmp^.Z < Gear^.Z) do
          tmp:= tmp^.NextGear;

   if tmp^.PrevGear <> nil then tmp^.PrevGear^.NextGear:= Gear;
   Gear^.PrevGear:= tmp^.PrevGear;
   tmp^.PrevGear:= Gear;
   Gear^.NextGear:= tmp;
   if GearsList = tmp then GearsList:= Gear
   end
end;

procedure RemoveGearFromList(Gear: PGear);
begin
if Gear^.NextGear <> nil then Gear^.NextGear^.PrevGear:= Gear^.PrevGear;
if Gear^.PrevGear <> nil then Gear^.PrevGear^.NextGear:= Gear^.NextGear
   else begin
   GearsList:= Gear^.NextGear;
   if GearsList <> nil then GearsList^.PrevGear:= nil
   end;
end;

function AddGear(X, Y: integer; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
const Counter: Longword = 0;
var Result: PGear;
begin
inc(Counter);
{$IFDEF DEBUGFILE}AddFileLog('AddGear: ('+inttostr(x)+','+inttostr(y)+'), d('+floattostr(dX)+','+floattostr(dY)+')');{$ENDIF}
New(Result);
{$IFDEF DEBUGFILE}AddFileLog('AddGear: type = '+inttostr(ord(Kind))+'; handle = '+inttostr(integer(Result)));{$ENDIF}
FillChar(Result^, sizeof(TGear), 0);
Result^.X:= X;
Result^.Y:= Y;
Result^.Kind := Kind;
Result^.State:= State;
Result^.Active:= true;
Result^.dX:= dX;
Result^.dY:= dY;
Result^.doStep:= doStepHandlers[Kind];
Result^.CollIndex:= High(Longword);
Result^.Timer:= Timer;
if CurrentTeam <> nil then
   Result^.Hedgehog:= @(CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog]);
case Kind of
       gtCloud: Result^.Z:= High(Result^.Z);
   gtAmmo_Bomb: begin
                Result^.Radius:= 4;
                Result^.Elasticity:= _0_6;
                Result^.Friction:= _0_995;
                end;
    gtHedgehog: begin
                Result^.Radius:= cHHRadius;
                Result^.Elasticity:= _0_35;
                Result^.Friction:= _0_999;
                Result^.Angle:= cMaxAngle div 2;
                Result^.Z:= cHHZ;
                end;
gtAmmo_Grenade: begin
                Result^.Radius:= 4;
                end;
   gtHealthTag: begin
                Result^.Timer:= 1500;
                Result^.Z:= 2000;
                end;
       gtGrave: begin
                Result^.Radius:= 10;
                Result^.Elasticity:= _0_6;
                end;
         gtUFO: begin
                Result^.Radius:= 5;
                Result^.Timer:= 500;
                Result^.Elasticity:= _0_9
                end;
 gtShotgunShot: begin
                Result^.Timer:= 900;
                Result^.Radius:= 2
                end;
  gtPickHammer: begin
                Result^.Radius:= 10;
                Result^.Timer:= 4000
                end;
  gtSmokeTrace: begin
                Result^.X:= Result^.X - 16;
                Result^.Y:= Result^.Y - 16;
                Result^.State:= 8
                end;
        gtRope: begin
                Result^.Radius:= 3;
                Result^.Friction:= 500;
                RopePoints.Count:= 0;
                end;
   gtExplosion: begin
                Result^.X:= Result^.X - 25;
                Result^.Y:= Result^.Y - 25;
                end;
        gtMine: begin
                Result^.Radius:= 3;
                Result^.Elasticity:= _0_55;
                Result^.Friction:= _0_995;
                Result^.Timer:= 3000;
                end;
        gtCase: begin
                Result^.Radius:= 16;
                Result^.Elasticity:= _0_4
                end;
  gtDEagleShot: begin
                Result^.Radius:= 1;
                Result^.Radius:= 1;
                Result^.Health:= 50
                end;
    gtDynamite: begin
                Result^.Radius:= 3;
                Result^.Elasticity:= _0_55;
                Result^.Friction:= _0_03;
                Result^.Timer:= 5000;
                end;
 gtClusterBomb: begin
                Result^.Radius:= 4;
                Result^.Elasticity:= _0_6;
                Result^.Friction:= _0_995;
                end;
       gtFlame: begin
                Result^.Angle:= Counter mod 64;
                Result^.Radius:= 1;
                Result^.Health:= 2;
                Result^.dY:= (getrandom - _0_8) * _0_03;
                Result^.dX:= (getrandom - _0_5) * _0_4
                end;
   gtFirePunch: begin
                Result^.Radius:= 15;
                Result^.Tag:= Y
                end;
     gtAirBomb: begin
                Result^.Radius:= 10;
                end;
   gtBlowTorch: begin
                Result^.Radius:= cHHRadius;
                Result^.Timer:= 7500;
                end;
     end;
InsertGearToList(Result);
AddGear:= Result
end;

procedure DeleteGear(Gear: PGear);
var team: PTeam;
    t: Longword;
begin
if Gear^.CollIndex < High(Longword) then DeleteCI(Gear);
if Gear^.Surf <> nil then SDL_FreeSurface(Gear^.Surf);
if Gear^.Kind = gtHedgehog then
   if CurAmmoGear <> nil then
      begin
      {$IFDEF DEBUGFILE}AddFileLog('DeleteGear: Sending gm_Destroy, hh handle = '+inttostr(integer(Gear)));{$ENDIF}
      Gear^.Message:= gm_Destroy;
      CurAmmoGear^.Message:= gm_Destroy;
      exit
      end else
      begin
      if not (Gear^.Y < cWaterLine) then
         begin
         t:= max(Gear^.Damage, Gear^.Health);
         AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtHealthTag, t, 0, 0, 0)^.Hedgehog:= Gear^.Hedgehog;
         inc(StepDamage, t)
         end;
      team:= PHedgehog(Gear^.Hedgehog)^.Team;
      if CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear = Gear then
         FreeActionsList; // to avoid ThinkThread on drawned gear
      PHedgehog(Gear^.Hedgehog)^.Gear:= nil;
      inc(KilledHHs);
      RecountTeamHealth(team);
      end;
{$IFDEF DEBUGFILE}AddFileLog('DeleteGear: handle = '+inttostr(integer(Gear)));{$ENDIF}
if CurAmmoGear = Gear then CurAmmoGear:= nil;
if FollowGear = Gear then FollowGear:= nil;
RemoveGearFromList(Gear);
Dispose(Gear)
end;

function CheckNoDamage: boolean; // returns TRUE in case of no damaged hhs
var Gear: PGear;
begin
CheckNoDamage:= true;
Gear:= GearsList;
while Gear <> nil do
      begin
      if Gear^.Kind = gtHedgehog then
         if Gear^.Damage <> 0 then
            begin
            CheckNoDamage:= false;
            inc(StepDamage, Gear^.Damage);
            if Gear^.Health < Gear^.Damage then Gear^.Health:= 0
                                         else dec(Gear^.Health, Gear^.Damage);
            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y) - cHHRadius - 12 - PHedgehog(Gear^.Hedgehog)^.HealthTag^.h,
                    gtHealthTag, Gear^.Damage, 0, 0, 0)^.Hedgehog:= Gear^.Hedgehog;
            RenderHealth(PHedgehog(Gear^.Hedgehog)^);
            RecountTeamHealth(PHedgehog(Gear^.Hedgehog)^.Team);

            Gear^.Damage:= 0
            end;
      Gear:= Gear^.NextGear
      end;
end;

procedure ProcessGears;
const delay: integer = cInactDelay;
      step: (stDelay, stChDmg, stChWin, stSpawn, stNTurn) = stDelay;
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
      t:= Gear^.NextGear;
      if Gear^.Active then Gear^.doStep(Gear);
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
        stChWin: if not CheckForWin then inc(step) else step:= stDelay;
        stSpawn: begin
                 if not isInMultiShoot then SpawnBoxOfSmth;
                 inc(step)
                 end;
        stNTurn: begin
                 //AwareOfExplosion(0, 0, 0);
                 if isInMultiShoot then isInMultiShoot:= false
                    else begin
                    with CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog] do
                         if MaxStepDamage < StepDamage then MaxStepDamage:= StepDamage;
                    StepDamage:= 0;
                    ParseCommand('/nextturn', true);
                    end;
                 step:= Low(step)
                 end;
        end;

if TurnTimeLeft > 0 then
   if CurrentTeam <> nil then
      if CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil then
         if ((CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear^.State and gstAttacking) = 0)
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
while t <> nil do
      begin
      t^.Active:= true;
      t:= t^.NextGear
      end
end;

procedure SetAllHHToActive;
var t: PGear;
begin
AllInactive:= false;
t:= GearsList;
while t <> nil do
      begin
      if t^.Kind = gtHedgehog then t^.Active:= true;
      t:= t^.NextGear
      end
end;

procedure DrawHH(Gear: PGear; Surface: PSDL_Surface);
var t: integer;
begin
DrawHedgehog(hwRound(Gear^.X) - 14 + WorldDx, hwRound(Gear^.Y) - 18 + WorldDy,
             hwSign(Gear^.dX), 0,
             PHedgehog(Gear^.Hedgehog)^.visStepPos div 2,
             Surface);

with PHedgehog(Gear^.Hedgehog)^ do
     if Gear^.State = 0 then
        begin
        t:= hwRound(Gear^.Y) - cHHRadius - 10 + WorldDy;
        dec(t, HealthTag^.h + 2);
        DrawCentered(hwRound(Gear^.X) + WorldDx, t, HealthTag, Surface);
        dec(t, NameTag^.h + 2);
        DrawCentered(hwRound(Gear^.X) + WorldDx, t, NameTag, Surface);
        dec(t, Team^.NameTag^.h + 2);
        DrawCentered(hwRound(Gear^.X) + WorldDx, t, Team^.NameTag, Surface)
        end else // Current hedgehog
        begin
        if bShowFinger and ((Gear^.State and gstHHDriven) <> 0) then
           DrawSprite(sprFinger, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 64 + WorldDy,
                      GameTicks div 32 mod 16, Surface);
        if (Gear^.State and (gstMoving or gstDrowning or gstFalling)) = 0 then
           if (Gear^.State and gstHHThinking) <> 0 then
              DrawGear(sQuestion, hwRound(Gear^.X) - 10 + WorldDx, hwRound(Gear^.Y) - cHHRadius - 34 + WorldDy, Surface)
              else
              if ShowCrosshair and ((Gear^.State and gstAttacked) = 0) then
                 DrawSurfSprite(Round(hwRound(Gear^.X) + hwSign(Gear^.dX) * Sin(Gear^.Angle*pi/cMaxAngle)*60) + WorldDx - 11,
                           Round(hwRound(Gear^.Y) - Cos(Gear^.Angle*pi/cMaxAngle)*60) + WorldDy - 12,
                           24, (18 + hwSign(Gear^.dX) * integer(((Gear^.Angle * 72 div cMaxAngle) + 1) div 2) mod 18) mod 18,
                           Team^.CrosshairSurf, Surface);
        end;
end;

procedure DrawGears(Surface: PSDL_Surface);
var Gear: PGear;
    i: Longword;
    roplen: hwFloat;

    procedure DrawRopeLine(X1, Y1, X2, Y2: integer);
    const nodlen = 5;
    var i, x, y: integer;
        t, k, ladd: hwFloat;
    begin
    if (X1 = X2) and (Y1 = Y2) then
       begin
       OutError('WARNING: zero length rope line!', false);
       exit
       end;
{    if abs(X1 - X2) > abs(Y1 - Y2) then
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
}    end;

begin
Gear:= GearsList;
while Gear<>nil do
      begin
      case Gear^.Kind of
           gtCloud: DrawSprite(sprCloud   , hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.State, Surface);
       gtAmmo_Bomb: DrawSprite(sprBomb , hwRound(Gear^.X) - 8 + WorldDx, hwRound(Gear^.Y) - 8 + WorldDy, hwRound(Gear^.DirAngle), Surface);
        gtHedgehog: DrawHH(Gear, Surface);
    gtAmmo_Grenade: DrawSprite(sprGrenade , hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, DxDy2Angle32(Gear^.dY.QWordValue, Gear^.dX.QWordValue), Surface);
       gtHealthTag: if Gear^.Surf <> nil then DrawCentered(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Surf, Surface);
           gtGrave: DrawSpriteFromRect(PHedgehog(Gear^.Hedgehog)^.Team^.GraveRect, hwRound(Gear^.X) + WorldDx - 16, hwRound(Gear^.Y) + WorldDy - 16, 32, (GameTicks shr 7) and 7, Surface);
             gtUFO: DrawSprite(sprUFO, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, (GameTicks shr 7) mod 4, Surface);
      gtSmokeTrace: if Gear^.State < 8 then DrawSprite(sprSmokeTrace, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.State, Surface);
            gtRope: begin
                    roplen:= 0;
                    if RopePoints.Count > 0 then
                       begin
                       i:= 0;
                       while i < Pred(RopePoints.Count) do
                             begin
                             DrawRopeLine(hwRound(RopePoints.ar[i].X) + WorldDx, hwRound(RopePoints.ar[i].Y) + WorldDy,
                                          hwRound(RopePoints.ar[Succ(i)].X) + WorldDx, hwRound(RopePoints.ar[Succ(i)].Y) + WorldDy);
                             inc(i)
                             end;
                       DrawRopeLine(hwRound(RopePoints.ar[i].X) + WorldDx, hwRound(RopePoints.ar[i].Y) + WorldDy,
                                    hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy);
                       DrawRopeLine(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,
                                    hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.X) + WorldDx, hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.Y) + WorldDy);
                       DrawSprite(sprRopeHook, hwRound(RopePoints.ar[0].X) + WorldDx - 16, hwRound(RopePoints.ar[0].Y) + WorldDy - 16, RopePoints.HookAngle, Surface);
                       end else
                       begin
                       DrawRopeLine(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,
                                    hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.X) + WorldDx, hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.Y) + WorldDy);
                       DrawSprite(sprRopeHook, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, DxDy2Angle32(Gear^.dY.QWordValue, Gear^.dX.QWordValue), Surface);
                       end;
                    end;
       gtExplosion: DrawSprite(sprExplosion50, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.State, Surface);
            gtMine: if ((Gear^.State and gstAttacking) = 0)or((Gear^.Timer and $3FF) < 420)
                       then DrawSprite(sprMineOff , hwRound(Gear^.X) - 8 + WorldDx, hwRound(Gear^.Y) - 8 + WorldDy, hwRound(Gear^.DirAngle), Surface)
                       else DrawSprite(sprMineOn  , hwRound(Gear^.X) - 8 + WorldDx, hwRound(Gear^.Y) - 8 + WorldDy, hwRound(Gear^.DirAngle), Surface);
        gtDynamite: DrawSprite2(sprDynamite, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 25 + WorldDy, Gear^.Tag and 1, Gear^.Tag shr 1, Surface);
            gtCase: case Gear^.Pos of
                         posCaseAmmo  : DrawSprite(sprCase, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, 0, Surface);
                         posCaseHealth: DrawSprite(sprFAid, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, (GameTicks shr 6) mod 13, Surface);
                         end;
     gtClusterBomb: DrawSprite(sprClusterBomb, hwRound(Gear^.X) - 8 + WorldDx, hwRound(Gear^.Y) - 8 + WorldDy, hwRound(Gear^.DirAngle), Surface);
         gtCluster: DrawSprite(sprClusterParticle, hwRound(Gear^.X) - 8 + WorldDx, hwRound(Gear^.Y) - 8 + WorldDy, 0, Surface);
           gtFlame: DrawSprite(sprFlame, hwRound(Gear^.X) - 8 + WorldDx, hwRound(Gear^.Y) - 8 + WorldDy,(GameTicks div 128 + Gear^.Angle) mod 8, Surface);
         gtAirBomb: DrawSprite(sprAirBomb , hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, DxDy2Angle32(Gear^.dY.QWordValue, Gear^.dX.QWordValue), Surface);
       gtAirAttack: DrawSprite(sprAirplane, hwRound(Gear^.X) - 60 + WorldDx, hwRound(Gear^.Y) - 25 + WorldDy, 0, Surface);
              end;
      Gear:= Gear^.NextGear
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
      tt:= tt^.NextGear;
      Dispose(t)
      end;
end;

procedure AddMiscGears;
var i: integer;
begin
AddGear(0, 0, gtATStartGame, 0, 0, 0, 2000);
if (GameFlags and gfForts) = 0 then
   for i:= 0 to 3 do
       FindPlace(AddGear(0, 0, gtMine, 0, 0, 0, 0), false, 0, 2048);
end;

procedure AddClouds;
var i: integer;
begin
for i:= 0 to cCloudsNumber do
    AddGear( - cScreenWidth + i * ((cScreenWidth * 2 + 2304) div cCloudsNumber), -140, gtCloud, random(4),
//             (0.5-random)*0.1, ((i mod 2) * 2 - 1) * (0.005 + 0.015*random), 0)
             0, 0, 0)
end;

procedure doMakeExplosion(X, Y, Radius: integer; Mask: LongWord);
var Gear: PGear;
    dmg: integer;
begin
TargetPoint.X:= NoPointX;
{$IFDEF DEBUGFILE}if Radius > 3 then AddFileLog('Explosion: at (' + inttostr(x) + ',' + inttostr(y) + ')');{$ENDIF}
if (Mask and EXPLDontDraw) = 0 then DrawExplosion(X, Y, Radius);
if Radius = 50 then AddGear(X, Y, gtExplosion, 0, 0, 0, 0);
if (Mask and EXPLAutoSound)<>0 then PlaySound(sndExplosion, false);
if (Mask and EXPLAllDamageInRadius)=0 then Radius:= Radius shl 1;
Gear:= GearsList;
while Gear <> nil do
      begin
      dmg:= Radius - hwRound(Distance(Gear^.X - X, Gear^.Y - Y));
      if dmg > 0 then
         begin
         dmg:= dmg shr 1;
         case Gear^.Kind of
              gtHedgehog,
                  gtMine,
                  gtCase,
                 gtFlame: begin
                          if (Mask and EXPLNoDamage) = 0 then inc(Gear^.Damage, dmg);
                          if ((Mask and EXPLDoNotTouchHH) = 0) or (Gear^.Kind <> gtHedgehog) then
                             begin
                             Gear^.dX:= Gear^.dX + (_0_005 * dmg + cHHKick)* hwSign(Gear^.X - X);
                             Gear^.dY:= Gear^.dY + (_0_005 * dmg + cHHKick)* hwSign(Gear^.Y - Y);
                             Gear^.Active:= true;
                             FollowGear:= Gear
                             end;
                          end;
                 gtGrave: begin
                          Gear^.dY:= - _0_004 * dmg;
                          Gear^.Active:= true;
                          end;
              end;
         end;
      Gear:= Gear^.NextGear
      end;
//uAIMisc.AwareOfExplosion(0, 0, 0)
end;

procedure AmmoShove(Ammo: PGear; Damage, Power: integer);
var t: PGearArray;
    i: integer;
    hh: PHedgehog;
begin
t:= CheckGearsCollision(Ammo);
i:= t^.Count;
hh:= Ammo^.Hedgehog;
while i > 0 do
    begin
    dec(i);
    if (t^.ar[i]^.State and gstNoDamage) = 0 then
       case t^.ar[i]^.Kind of
           gtHedgehog,
               gtMine,
               gtCase: begin
                       inc(t^.ar[i]^.Damage, Damage);
                       inc(hh^.DamageGiven, Damage);
                       t^.ar[i]^.dX:= Ammo^.dX * Power * _0_01;
                       t^.ar[i]^.dY:= Ammo^.dY * Power * _0_01;
                       t^.ar[i]^.Active:= true;
                       DeleteCI(t^.ar[i]);
                       FollowGear:= t^.ar[i]
                       end;
           end
    end;
SetAllToActive
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
          with Team^.Hedgehogs[i] do
               if Gear <> nil then
                  if (GameFlags and gfForts) = 0 then FindPlace(Gear, false, 0, 2048)
                                                 else FindPlace(Gear, false, t, t + 1024);
      inc(t, 1024);
      Team:= Team^.Next
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
      if (t <> Gear) and (t^.Kind = Kind) then
         if not((hwSqr(Gear^.X - t^.X) / rX + hwSqr(Gear^.Y - t^.Y) / rY) > 1) then
            exit(t);
      t:= t^.NextGear
      end;
CheckGearNear:= nil
end;

procedure AmmoFlameWork(Ammo: PGear);
var t: PGear;
begin
t:= GearsList;
while t <> nil do
      begin
      if (t^.Kind = gtHedgehog) and (t^.Y < Ammo^.Y) then
         if not (hwSqr(Ammo^.X - t^.X) + hwSqr(Ammo^.Y - t^.Y - cHHRadius) * 2 > 2) then
            begin
            inc(t^.Damage, 5);
            t^.dX:= t^.dX + (t^.X - Ammo^.X) * _0_02;
            t^.dY:= - _0_25;
            t^.Active:= true;
            DeleteCI(t);
            FollowGear:= t
            end;
      t:= t^.NextGear
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
      if t^.Kind in Kind then
         if not (hwSqr(mX - t^.X) / rX + hwSqr(mY - t^.Y) / rY > 1) then
            exit(t);
      t:= t^.NextGear
      end;
CheckGearsNear:= nil
end;

function CountGears(Kind: TGearType): Longword;
var t: PGear;
    Result: Longword;
begin
Result:= 0;
t:= GearsList;
while t <> nil do
      begin
      if t^.Kind = Kind then inc(Result);
      t:= t^.NextGear
      end;
CountGears:= Result
end;

procedure SpawnBoxOfSmth;
begin
if (CountGears(gtCase) >= 5) or (getrandom(cCaseFactor) <> 0) then exit;
FollowGear:= AddGear(0, 0, gtCase, 0, 0, 0, 0);
case getrandom(2) of
     0: begin
        FollowGear^.Health:= 25;
        FollowGear^.Pos:= posCaseHealth
        end;
     1: begin
        FollowGear^.Pos:= posCaseAmmo;
        FollowGear^.State:= Longword(amMineStrike)
        end;
     end;
FindPlace(FollowGear, true, 0, 2048)
end;

procedure FindPlace(Gear: PGear; withFall: boolean; Left, Right: integer);

    function CountNonZeroz(x, y, r: integer): integer;
    var i: integer;
        Result: integer;
    begin
    Result:= 0;
    if (y and $FFFFFC00) <> 0 then exit;
    for i:= max(x - r, 0) to min(x + r, 2043) do
        if Land[y, i] <> 0 then inc(Result);
    CountNonZeroz:= Result
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
     inc(x, Gear^.Radius);
     if x > Right then x:= Left + (x mod (Right - left));
     cnt:= 0;
     y:= -Gear^.Radius * 2;
     while y < 1023 do
        begin
        repeat
          inc(y, 2);
        until (y > 1023) or (CountNonZeroz(x, y, Gear^.Radius - 1) = 0);
        sy:= y;
        repeat
          inc(y);
        until (y > 1023) or (CountNonZeroz(x, y, Gear^.Radius - 1) <> 0);
        if (y - sy > Gear^.Radius * 2)
        and (y < 1023)
        and (CheckGearsNear(x, y - Gear^.Radius, [gtHedgehog, gtMine, gtCase], 110, 110) = nil) then
           begin
           ar[cnt].X:= x;
           if withFall then ar[cnt].Y:= sy + Gear^.Radius
                       else ar[cnt].Y:= y - Gear^.Radius;
           inc(cnt)
           end;
        inc(y, 80)
        end;
     if cnt > 0 then
        with ar[GetRandom(cnt)] do
          begin
          Gear^.X:= x;
          Gear^.Y:= y;
         {$IFDEF DEBUGFILE}
         AddFileLog('Assigned Gear ' + inttostr(integer(Gear)) +
                    ' coordinates (' + inttostr(x) +
                    ',' + inttostr(y) + ')');
         {$ENDIF}
          exit
          end
  until (x - Gear^.Radius < fx) and (x + Gear^.Radius > fx);
dec(Delta, 20)
until (Delta < 70);
OutError('Couldn''t find place for Gear ' + inttostr(integer(Gear)), false);
DeleteGear(Gear)
end;

initialization

finalization
FreeGearsList;

end.

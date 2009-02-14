(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2009 Andrey Korotaev <unC0Rr@gmail.com>
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
      PrvInactive: boolean = false;

type PGear = ^TGear;
	TGearStepProcedure = procedure (Gear: PGear);
	TGear = record
			NextGear, PrevGear: PGear;
			Active: Boolean;
			Ammo : PAmmo;
			State : Longword;
			X : hwFloat;
			Y : hwFloat;
			dX: hwFloat;
			dY: hwFloat;
			Kind: TGearType;
			Pos: Longword;
			doStep: TGearStepProcedure;
			Radius: LongInt;
			Angle, Power : Longword;
			DirAngle: real;
			Timer : LongWord;
			Elasticity: hwFloat;
			Friction  : hwFloat;
			Message, MsgParam : Longword;
			Hedgehog: pointer;
			Health, Damage: LongInt;
			CollisionIndex: LongInt;
			Tag: LongInt;
			Tex: PTexture;
			Z: Longword;
			IntersectGear: PGear;
			TriggerId: Longword;
			uid: Longword;
			end;

function  AddGear(X, Y: LongInt; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
procedure ProcessGears;
procedure SetAllToActive;
procedure SetAllHHToActive;
procedure DrawGears;
procedure FreeGearsList;
procedure AddMiscGears;
procedure AssignHHCoords;
procedure InsertGearToList(Gear: PGear);
procedure RemoveGearFromList(Gear: PGear);

var CurAmmoGear: PGear = nil;
    GearsList: PGear = nil;
    KilledHHs: Longword = 0;

implementation
uses uWorld, uMisc, uStore, uConsole, uSound, uTeams, uRandom, uCollisions,
	uLand, uIO, uLandGraphics, uAIMisc, uLocale, uAI, uAmmos, uTriggers, GL,
	uStats, uVisualGears;

const MAXROPEPOINTS = 384;
var RopePoints: record
                Count: Longword;
                HookAngle: GLfloat;
                ar: array[0..MAXROPEPOINTS] of record
                                  X, Y: hwFloat;
                                  dLen: hwFloat;
                                  b: boolean;
                                  end;
                 end;

procedure DeleteGear(Gear: PGear); forward;
procedure doMakeExplosion(X, Y, Radius: LongInt; Mask: LongWord); forward;
procedure AmmoShove(Ammo: PGear; Damage, Power: LongInt); forward;
//procedure AmmoFlameWork(Ammo: PGear); forward;
function  CheckGearNear(Gear: PGear; Kind: TGearType; rX, rY: LongInt): PGear; forward;
procedure SpawnBoxOfSmth; forward;
procedure AfterAttack; forward;
procedure FindPlace(var Gear: PGear; withFall: boolean; Left, Right: LongInt); forward;
procedure HedgehogStep(Gear: PGear); forward;
procedure doStepHedgehogMoving(Gear: PGear); forward;
procedure HedgehogChAngle(Gear: PGear); forward;
procedure ShotgunShot(Gear: PGear); forward;
procedure PickUp(HH, Gear: PGear); forward;

{$INCLUDE GSHandlers.inc}
{$INCLUDE HHHandlers.inc}

const doStepHandlers: array[TGearType] of TGearStepProcedure = (
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
			@doStepBlowTorch,
			@doStepGirder,
			@doStepTeleport,
			@doStepSwitcher,
			@doStepCase,
			@doStepMortar,
			@doStepWhip,
			@doStepKamikaze,
			@doStepCake,
			@doStepSeduction,
			@doStepWatermelon,
			@doStepCluster,
			@doStepBomb,
			@doStepSmokeTrace,
			@doStepWaterUp,
			@doStepDrill,
			@doStepBallgun,
			@doStepBomb,
			@doStepRCPlane
			);

procedure InsertGearToList(Gear: PGear);
var tmp, ptmp: PGear;
begin
if GearsList = nil then
	GearsList:= Gear
	else begin
	tmp:= GearsList;
	ptmp:= GearsList;
	while (tmp <> nil) and (tmp^.Z <= Gear^.Z) do
		begin
		ptmp:= tmp;
		tmp:= tmp^.NextGear
		end;

	if ptmp <> nil then
		begin
		Gear^.NextGear:= ptmp^.NextGear;
		Gear^.PrevGear:= ptmp;
		if ptmp^.NextGear <> nil then ptmp^.NextGear^.PrevGear:= Gear;
		ptmp^.NextGear:= Gear
		end
	else GearsList:= Gear
	end
end;

procedure RemoveGearFromList(Gear: PGear);
begin
if Gear^.NextGear <> nil then Gear^.NextGear^.PrevGear:= Gear^.PrevGear;
if Gear^.PrevGear <> nil then
	Gear^.PrevGear^.NextGear:= Gear^.NextGear
else
	GearsList:= Gear^.NextGear
end;

function AddGear(X, Y: LongInt; Kind: TGearType; State: Longword; dX, dY: hwFloat; Timer: LongWord): PGear;
const Counter: Longword = 0;
var Result: PGear;
begin
inc(Counter);
{$IFDEF DEBUGFILE}
AddFileLog('AddGear: #' + inttostr(Counter) + ' (' + inttostr(x) + ',' + inttostr(y) + '), d(' + floattostr(dX) + ',' + floattostr(dY) + ') type = ' + inttostr(ord(Kind)));
{$ENDIF}

New(Result);
FillChar(Result^, sizeof(TGear), 0);
Result^.X:= int2hwFloat(X);
Result^.Y:= int2hwFloat(Y);
Result^.Kind := Kind;
Result^.State:= State;
Result^.Active:= true;
Result^.dX:= dX;
Result^.dY:= dY;
Result^.doStep:= doStepHandlers[Kind];
Result^.CollisionIndex:= -1;
Result^.Timer:= Timer;
Result^.Z:= cUsualZ;
Result^.uid:= Counter;

if CurrentTeam <> nil then
	begin
	Result^.Hedgehog:= CurrentHedgehog;
	Result^.IntersectGear:= CurrentHedgehog^.Gear
	end;

case Kind of
   gtAmmo_Bomb,
 gtClusterBomb: begin
                Result^.Radius:= 4;
                Result^.Elasticity:= _0_6;
                Result^.Friction:= _0_96;
                end;
  gtWatermelon: begin
                Result^.Radius:= 4;
                Result^.Elasticity:= _0_8;
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
                Result^.Z:= 2001;
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
  gtSmokeTrace,
   gtEvilTrace: begin
                Result^.X:= Result^.X - _16;
                Result^.Y:= Result^.Y - _16;
                Result^.State:= 8;
                Result^.Z:= cSmokeZ
                end;
        gtRope: begin
                Result^.Radius:= 3;
                Result^.Friction:= _450;
                RopePoints.Count:= 0;
                end;
   gtExplosion: begin
                Result^.X:= Result^.X;
                Result^.Y:= Result^.Y;
                end;
        gtMine: begin
                Result^.State:= Result^.State or gstMoving;
                Result^.Radius:= 2;
                Result^.Elasticity:= _0_55;
                Result^.Friction:= _0_995;
                Result^.Timer:= 3000;
                end;
        gtCase: begin
                Result^.Radius:= 16;
                Result^.Elasticity:= _0_3
                end;
  gtDEagleShot: begin
                Result^.Radius:= 1;
                Result^.Health:= 50
                end;
    gtDynamite: begin
                Result^.Radius:= 3;
                Result^.Elasticity:= _0_55;
                Result^.Friction:= _0_03;
                Result^.Timer:= 5000;
                end;
     gtCluster: Result^.Radius:= 2;
      gtShover: Result^.Radius:= 20;
       gtFlame: begin
                Result^.Tag:= Counter mod 32;
                Result^.Radius:= 1;
                Result^.Health:= 5;
                if (Result^.dY.QWordValue = 0) and (Result^.dX.QWordValue = 0) then
                	begin
                	Result^.dY:= (getrandom - _0_8) * _0_03;
                	Result^.dX:= (getrandom - _0_5) * _0_4
                	end
                end;
   gtFirePunch: begin
                Result^.Radius:= 15;
                Result^.Tag:= Y
                end;
     gtAirBomb: begin
                Result^.Radius:= 5;
                end;
   gtBlowTorch: begin
                Result^.Radius:= cHHRadius + cBlowTorchC;
                Result^.Timer:= 7500;
                end;
    gtSwitcher: begin
                Result^.Z:= cCurrHHZ
                end;
      gtTarget: begin
                Result^.Radius:= 16;
                Result^.Elasticity:= _0_3
                end;
      gtMortar: begin
                Result^.Radius:= 4;
                Result^.Elasticity:= _0_2;
                Result^.Friction:= _0_08
                end;
        gtWhip: Result^.Radius:= 20;
    gtKamikaze: begin
                Result^.Health:= 2048;
                Result^.Radius:= 20
                end;
        gtCake: begin
                Result^.Health:= 2048;
                Result^.Radius:= 7;
                Result^.Z:= cOnHHZ;
                if hwSign(dX) > 0 then Result^.Angle:= 1 else Result^.Angle:= 3
                end;
 gtHellishBomb: begin
                Result^.Radius:= 4;
                Result^.Elasticity:= _0_5;
                Result^.Friction:= _0_96;
                end;
       gtDrill: begin
                Result^.Timer:= 5000;
                Result^.Radius:= 4;
                end;
        gtBall: begin
                Result^.Radius:= 5;
                Result^.Tag:= random(8);
                Result^.Timer:= 5000;
                Result^.Elasticity:= _0_7;
                Result^.Friction:= _0_995;
                end;
     gtBallgun: begin
                Result^.Timer:= 5001;
                end;
     gtRCPlane: begin
                Result^.Timer:= 15000;
                Result^.Health:= 3;
                Result^.Radius:= 8;
                end;
     end;
InsertGearToList(Result);
AddGear:= Result
end;

procedure DeleteGear(Gear: PGear);
var team: PTeam;
	t: Longword;
begin
DeleteCI(Gear);

if Gear^.Tex <> nil then
	begin
	FreeTexture(Gear^.Tex);
	Gear^.Tex:= nil
	end;

if Gear^.Kind = gtHedgehog then
	if CurAmmoGear <> nil then
		begin
		Gear^.Message:= gm_Destroy;
		CurAmmoGear^.Message:= gm_Destroy;
		exit
		end
	else
		begin
		if not (hwRound(Gear^.Y) < cWaterLine) then
			begin
			t:= max(Gear^.Damage, Gear^.Health);
			Gear^.Damage:= t;
			AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtHealthTag, t, _0, _0, 0)^.Hedgehog:= Gear^.Hedgehog;
			uStats.HedgehogDamaged(Gear)
			end;
	
		team:= PHedgehog(Gear^.Hedgehog)^.Team;
		if CurrentHedgehog^.Gear = Gear then
			FreeActionsList; // to avoid ThinkThread on drawned gear
		
		PHedgehog(Gear^.Hedgehog)^.Gear:= nil;
		inc(KilledHHs);
		RecountTeamHealth(team)
		end;
{$IFDEF DEBUGFILE}
with Gear^ do AddFileLog('Delete: #' + inttostr(uid) + ' (' + inttostr(hwRound(x)) + ',' + inttostr(hwRound(y)) + '), d(' + floattostr(dX) + ',' + floattostr(dY) + ') type = ' + inttostr(ord(Kind)));
{$ENDIF}

if Gear^.TriggerId <> 0 then TickTrigger(Gear^.TriggerId);
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
		uStats.HedgehogDamaged(Gear);

		if Gear^.Health < Gear^.Damage then
			Gear^.Health:= 0
		else
			dec(Gear^.Health, Gear^.Damage);

		AddGear(hwRound(Gear^.X), hwRound(Gear^.Y) - cHHRadius - 12,
				gtHealthTag, Gear^.Damage, _0, _0, 0)^.Hedgehog:= Gear^.Hedgehog;

		RenderHealth(PHedgehog(Gear^.Hedgehog)^);
		RecountTeamHealth(PHedgehog(Gear^.Hedgehog)^.Team);

		Gear^.Damage:= 0
		end;
	Gear:= Gear^.NextGear
	end;
end;

procedure HealthMachine;
var Gear: PGear;
begin
Gear:= GearsList;

while Gear <> nil do
	begin
	if Gear^.Kind = gtHedgehog then
		Gear^.Damage:= min(cHealthDecrease, Gear^.Health - 1);

	Gear:= Gear^.NextGear
	end;
end;

procedure ProcessGears;
const delay: LongWord = 0;
	step: (stDelay, stChDmg, stTurnReact,
			stAfterDelay, stChWin, stWater, stChWin2, stHealth,
			stSpawn, stNTurn) = stDelay;

var Gear, t: PGear;
begin
PrvInactive:= AllInactive;
AllInactive:= true;

t:= GearsList;
while t <> nil do
	begin
	Gear:= t;
	t:= Gear^.NextGear;
	if Gear^.Active then Gear^.doStep(Gear);
	end;

if AllInactive then
case step of
	stDelay: begin
		if delay = 0 then
			delay:= cInactDelay
		else
			dec(delay);

		if delay = 0 then
			inc(step)
		end;
	stChDmg: begin
			if CheckNoDamage then inc(step) else step:= stDelay;
			if SweepDirty then
				begin
				SetAllToActive;
				step:= stChDmg
				end;
			end;
	stTurnReact: begin
		if (not bBetweenTurns) and (not isInMultiShoot) then
			begin
			uStats.TurnReaction;
			inc(step)
		end else
			inc(step, 2);
		end;
	stAfterDelay: begin
		if delay = 0 then
			delay:= cInactDelay
		else
			dec(delay);

		if delay = 0 then
		inc(step)
		end;
	stChWin: begin
			CheckForWin;
			inc(step)
			end;
	stWater: if (not bBetweenTurns) and (not isInMultiShoot) then
				begin
				if TotalRounds = cSuddenDTurns + 2 then bWaterRising:= true;

				if bWaterRising then
				AddGear(0, 0, gtWaterUp, 0, _0, _0, 0);

				inc(step)
				end else inc(step);
	stChWin2: begin
			CheckForWin;
			inc(step)
			end;
	stHealth: begin
			if (TotalRounds = cSuddenDTurns) and (cHealthDecrease = 0) then
				begin
				cHealthDecrease:= 5;
				AddCaption(trmsg[sidSuddenDeath], $FFFFFF, capgrpGameState)
				end;

			if (cHealthDecrease = 0)
				or bBetweenTurns
				or isInMultiShoot
				or (TotalRounds = 0) then inc(step)
			else begin
				bBetweenTurns:= true;
				HealthMachine;
				step:= stChDmg
				end
			end;
	stSpawn: begin
			if not isInMultiShoot then SpawnBoxOfSmth;
			inc(step)
			end;
	stNTurn: begin
			if isInMultiShoot then isInMultiShoot:= false
			else begin
			ParseCommand('/nextturn', true);
			SwitchHedgehog;

			inc(step);

			AfterSwitchHedgehog;
			bBetweenTurns:= false
			end;
			step:= Low(step)
			end;
	end;

if TurnTimeLeft > 0 then
		if CurrentHedgehog^.Gear <> nil then
			if ((CurrentHedgehog^.Gear^.State and gstAttacking) = 0)
				and not isInMultiShoot then
				begin
				if (TurnTimeLeft = 5000)
					and (CurrentHedgehog^.Gear <> nil)
					and ((CurrentHedgehog^.Gear^.State and gstAttacked) = 0) then
						PlaySound(sndHurry, false, CurrentTeam^.voicepack);
				dec(TurnTimeLeft)
				end;

if (not CurrentTeam^.ExtDriven) and
	((GameTicks and $FFFF) = $FFFF) then
	begin
	SendIPCTimeInc;
	inc(hiTicks) // we do not recieve a message for this
	end;

inc(GameTicks)
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

procedure DrawHH(Gear: PGear);
var t: LongInt;
	amt: TAmmoType;
	hx, hy, m: LongInt;
	aAngle, dAngle: real;
	defaultPos, HatVisible: boolean;
begin
if (Gear^.State and gstHHDeath) <> 0 then
	begin
	DrawSprite(sprHHDeath, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 26 + WorldDy, Gear^.Pos);
	exit
	end;

defaultPos:= true;
HatVisible:= false;

if (Gear^.State and gstDrowning) <> 0 then
	begin
	DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
			hwSign(Gear^.dX),
			1,
			7,
			0);
	defaultPos:= false
	end else

if (Gear^.State and gstWinner) <> 0 then
	begin
	DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
			hwSign(Gear^.dX),
			2,
			0,
			0);
	defaultPos:= false
	end else

if (Gear^.State and gstHHDriven) <> 0 then
	begin
	hx:= hwRound(Gear^.X) + 1 + 8 * hwSign(Gear^.dX) + WorldDx;
	hy:= hwRound(Gear^.Y) - 2 + WorldDy;
	aangle:= Gear^.Angle * 180 / cMaxAngle - 90;

	if CurAmmoGear <> nil then
	begin
		case CurAmmoGear^.Kind of
			gtShotgunShot: begin
					if (CurAmmoGear^.State and gstAnimation <> 0) then
						DrawRotated(sprShotgun, hx, hy, hwSign(Gear^.dX), aangle)
					else
						DrawRotated(sprHandShotgun, hx, hy, hwSign(Gear^.dX), aangle);
					HatVisible:= true
				end;
			gtDEagleShot: DrawRotated(sprDEagle, hx, hy, hwSign(Gear^.dX), aangle);
			gtBallgun: DrawRotated(sprHandBallgun, hx, hy, hwSign(Gear^.dX), aangle);
			gtRCPlane: begin
				DrawRotated(sprHandPlane, hx, hy, hwSign(Gear^.dX), 0);
				defaultPos:= false
				end;
			gtRope: begin
				if Gear^.X < CurAmmoGear^.X then
					begin
					dAngle:= 0;
					m:= 1
					end else
					begin
					dAngle:= 180;
					m:= -1
					end;
				DrawHedgehog(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,
						m,
						1,
						0,
						DxDy2Angle(CurAmmoGear^.dY, CurAmmoGear^.dX) + dAngle);
				defaultPos:= false
				end;
			gtBlowTorch: begin
				DrawRotated(sprBlowTorch, hx, hy, hwSign(Gear^.dX), aangle);
				DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
						hwSign(Gear^.dX),
						3,
						PHedgehog(Gear^.Hedgehog)^.visStepPos div 2,
						0);
				defaultPos:= false
				end;
			gtShover: DrawRotated(sprHandBaseball, hx, hy, hwSign(Gear^.dX), aangle + 180);
			gtFirePunch: begin
				DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
						hwSign(Gear^.dX),
						1,
						4,
						0);
				defaultPos:= false
				end;
			gtPickHammer,
			gtTeleport: defaultPos:= false;
			gtWhip: begin
				DrawRotatedF(sprWhip,
						hwRound(Gear^.X) + 1 + WorldDx,
						hwRound(Gear^.Y) - 3 + WorldDy,
						1,
						hwSign(Gear^.dX),
						0);
				defaultPos:= false
				end;
			gtKamikaze: begin
				if CurAmmoGear^.Pos = 0 then
					DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
							hwSign(Gear^.dX),
							1,
							6,
							0)
				else
					DrawRotatedF(sprKamikaze,
							hwRound(Gear^.X) + WorldDx,
							hwRound(Gear^.Y) + WorldDy,
							CurAmmoGear^.Pos - 1,
							1,
							DxDy2Angle(Gear^.dY, Gear^.dX));

				defaultPos:= false
				end;
			gtSeduction: begin
				if CurAmmoGear^.Pos >= 6 then
					DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
							hwSign(Gear^.dX),
							2,
							2,
							0)
				else
					begin
					DrawRotatedF(sprDress,
							hwRound(Gear^.X) + WorldDx,
							hwRound(Gear^.Y) + WorldDy,
							CurAmmoGear^.Pos,
							hwSign(Gear^.dX),
							0);
					DrawSprite(sprCensored, hwRound(Gear^.X) - 32 + WorldDx, hwRound(Gear^.Y) - 20 + WorldDy, 0)
					end;
				defaultPos:= false
				end;
		end;

		case CurAmmoGear^.Kind of
			gtShotgunShot,
			gtDEagleShot,
			gtShover: begin
				DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
						hwSign(Gear^.dX),
						0,
						4,
						0);
				defaultPos:= false
			end
		end
	end else

	if ((Gear^.State and gstHHJumping) <> 0) then
	begin
	if ((Gear^.State and gstHHHJump) <> 0) then
		DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
			- hwSign(Gear^.dX),
			1,
			1,
			0)
		else
		DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
			hwSign(Gear^.dX),
			1,
			1,
			0);
	defaultPos:= false
	end else

	if (Gear^.Message and (gm_Left or gm_Right) <> 0) then
		begin
		DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
			hwSign(Gear^.dX),
			0,
			PHedgehog(Gear^.Hedgehog)^.visStepPos div 2,
			0);
		defaultPos:= false;
		HatVisible:= true
		end
	else

	if ((Gear^.State and gstAnimation) <> 0) then
		begin
		DrawRotatedF(Wavez[TWave(Gear^.Tag)].Sprite,
				hwRound(Gear^.X) + 1 + WorldDx,
				hwRound(Gear^.Y) - 3 + WorldDy,
				Gear^.Pos,
				hwSign(Gear^.dX),
				0.0);
		defaultPos:= false
		end
	else
	if ((Gear^.State and gstAttacked) = 0) then
	begin
		amt:= CurrentHedgehog^.Ammo^[CurrentHedgehog^.CurSlot, CurrentHedgehog^.CurAmmo].AmmoType;
		case amt of
			amBazooka,
			amMortar: DrawRotated(sprHandBazooka, hx, hy, hwSign(Gear^.dX), aangle);
			amBallgun: DrawRotated(sprHandBallgun, hx, hy, hwSign(Gear^.dX), aangle);
			amDrill: DrawRotated(sprHandDrill, hx, hy, hwSign(Gear^.dX), aangle);
			amRope: DrawRotated(sprHandRope, hx, hy, hwSign(Gear^.dX), aangle);
			amShotgun: DrawRotated(sprHandShotgun, hx, hy, hwSign(Gear^.dX), aangle);
			amDEagle: DrawRotated(sprHandDEagle, hx, hy, hwSign(Gear^.dX), aangle);
			amBlowTorch: DrawRotated(sprHandBlowTorch, hx, hy, hwSign(Gear^.dX), aangle);
			amRCPlane: begin
				DrawRotated(sprHandPlane, hx, hy, hwSign(Gear^.dX), 0);
				defaultPos:= false
				end;
		end;

		case amt of
			amAirAttack,
			amMineStrike: DrawRotated(sprHandAirAttack, hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) + WorldDy, hwSign(Gear^.dX), 0);
			amPickHammer: DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
						hwSign(Gear^.dX),
						1,
						2,
						0);
			amBlowTorch: DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
						hwSign(Gear^.dX),
						1,
						3,
						0);
			amTeleport: DrawRotatedF(sprTeleport, hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy, 0, hwSign(Gear^.dX), 0);
			amKamikaze: DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
						hwSign(Gear^.dX),
						1,
						5,
						0);
			amWhip: DrawRotatedF(sprWhip,
						hwRound(Gear^.X) + 1 + WorldDx,
						hwRound(Gear^.Y) - 3 + WorldDy,
						0,
						hwSign(Gear^.dX),
						0);
		else
			DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
				hwSign(Gear^.dX),
				0,
				4,
				0);
			
			HatVisible:= true;
			with PHedgehog(Gear^.Hedgehog)^ do
				if (HatTex <> nil)
				and (HatVisibility > 0) then
					DrawTextureF(HatTex,
						HatVisibility,
						hwRound(Gear^.X) + 1 + WorldDx,
						hwRound(Gear^.Y) - 8 + WorldDy,
						0,
						hwSign(Gear^.dX),
						32);
		end;

		case amt of
			amBaseballBat: DrawRotated(sprHandBaseball,
					hwRound(Gear^.X) + 1 - 4 * hwSign(Gear^.dX) + WorldDx,
					hwRound(Gear^.Y) + 6 + WorldDy, hwSign(Gear^.dX), aangle);
		end;

		defaultPos:= false
	end
end else // not gstHHDriven
	begin
	if (Gear^.Damage > 0)
	and (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) > _0_003) then
		begin
		DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
			hwSign(Gear^.dX),
			2,
			1,
			Gear^.DirAngle);
		defaultPos:= false
		end else

	if ((Gear^.State and gstHHJumping) <> 0) then
		begin
		if ((Gear^.State and gstHHHJump) <> 0) then
			DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
				- hwSign(Gear^.dX),
				1,
				1,
				0)
			else
			DrawHedgehog(hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy,
				hwSign(Gear^.dX),
				1,
				1,
				0);
			defaultPos:= false
		end;
	end;

with PHedgehog(Gear^.Hedgehog)^ do
	begin
	if defaultPos then
		begin
		DrawRotatedF(sprHHIdle,
			hwRound(Gear^.X) + 1 + WorldDx,
			hwRound(Gear^.Y) - 3 + WorldDy,
			(RealTicks div 128 + Gear^.Pos) mod 19,
			hwSign(Gear^.dX),
			0);
		HatVisible:= true;
		end;

	if HatVisible then
		if HatVisibility < 1.0 then
			HatVisibility:= HatVisibility + 0.2
		else
	else
		if HatVisibility > 0.0 then
			HatVisibility:= HatVisibility - 0.2;
	
	if (HatTex <> nil)
	and (HatVisibility > 0) then
		if DefaultPos then
			DrawTextureF(HatTex,
				HatVisibility,
				hwRound(Gear^.X) + 1 + WorldDx,
				hwRound(Gear^.Y) - 8 + WorldDy,
				(RealTicks div 128 + Gear^.Pos) mod 19,
				hwSign(Gear^.dX),
				32)
		else
			DrawTextureF(HatTex,
				HatVisibility,
				hwRound(Gear^.X) + 1 + WorldDx,
				hwRound(Gear^.Y) - 8 + WorldDy,
				0,
				hwSign(Gear^.dX),
				32);
	end;


with PHedgehog(Gear^.Hedgehog)^ do
	begin
	if ((Gear^.State and not gstWinner) = 0)
		or (bShowFinger and ((Gear^.State and gstHHDriven) <> 0)) then
		begin
		t:= hwRound(Gear^.Y) - cHHRadius - 12 + WorldDy;
		if (cTagsMask and 1) <> 0 then
			begin
			dec(t, HealthTagTex^.h + 2);
			DrawCentered(hwRound(Gear^.X) + WorldDx, t, HealthTagTex)
			end;
		if (cTagsMask and 2) <> 0 then
			begin
			dec(t, NameTagTex^.h + 2);
			DrawCentered(hwRound(Gear^.X) + WorldDx, t, NameTagTex)
			end;
		if (cTagsMask and 4) <> 0 then
			begin
			dec(t, Team^.NameTagTex^.h + 2);
			DrawCentered(hwRound(Gear^.X) + WorldDx, t, Team^.NameTagTex)
			end
		end;
	if (Gear^.State and gstHHDriven) <> 0 then // Current hedgehog
		begin
		if bShowFinger and ((Gear^.State and gstHHDriven) <> 0) then
			DrawSprite(sprFinger, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 64 + WorldDy,
						GameTicks div 32 mod 16);

		if (Gear^.State and gstDrowning) = 0 then
			if (Gear^.State and gstHHThinking) <> 0 then
				DrawSprite(sprQuestion, hwRound(Gear^.X) - 10 + WorldDx, hwRound(Gear^.Y) - cHHRadius - 34 + WorldDy, 0)
				else
				if ShowCrosshair and ((Gear^.State and (gstAttacked or gstAnimation)) = 0) then
					begin
					if ((Gear^.State and gstHHHJump) <> 0) then m:= -1 else m:= 1;
					DrawRotatedTex(Team^.CrosshairTex,
							12, 12,
							Round(hwRound(Gear^.X) + hwSign(Gear^.dX) * m * Sin(Gear^.Angle*pi/cMaxAngle) * 80) + WorldDx,
							Round(hwRound(Gear^.Y) - Cos(Gear^.Angle*pi/cMaxAngle) * 80) + WorldDy, 0,
							hwSign(Gear^.dX) * (Gear^.Angle * 180.0) / cMaxAngle)
					end
			end
	end
end;

procedure DrawGears;
var Gear, HHGear: PGear;
    i: Longword;
    roplen: LongInt;

    procedure DrawRopeLine(X1, Y1, X2, Y2: LongInt);
    var  eX, eY, dX, dY: LongInt;
         i, sX, sY, x, y, d: LongInt;
         b: boolean;
    begin
    if (X1 = X2) and (Y1 = Y2) then
       begin
       OutError('WARNING: zero length rope line!', false);
       exit
       end;
    eX:= 0;
    eY:= 0;
    dX:= X2 - X1;
    dY:= Y2 - Y1;

    if (dX > 0) then sX:= 1
    else
      if (dX < 0) then
         begin
         sX:= -1;
         dX:= -dX
         end else sX:= dX;

    if (dY > 0) then sY:= 1
       else
    if (dY < 0) then
       begin
       sY:= -1;
       dY:= -dY
       end else sY:= dY;

    if (dX > dY) then d:= dX
                 else d:= dY;

    x:= X1;
    y:= Y1;

    for i:= 0 to d do
        begin
        inc(eX, dX);
        inc(eY, dY);
        b:= false;
        if (eX > d) then
           begin
           dec(eX, d);
           inc(x, sX);
           b:= true
           end;
        if (eY > d) then
           begin
           dec(eY, d);
           inc(y, sY);
           b:= true
           end;
        if b then
           begin
           inc(roplen);
           if (roplen mod 4) = 0 then DrawSprite(sprRopeNode, x - 2, y - 2, 0)
           end
       end
    end;

begin
Gear:= GearsList;
while Gear<>nil do
	begin
	case Gear^.Kind of
       gtAmmo_Bomb: DrawRotated(sprBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);

       gtRCPlane: if (Gear^.Tag = -1) then
                     DrawRotated(sprPlane, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, -1,  DxDy2Angle(Gear^.dX, Gear^.dY) + 90)
                  else
                     DrawRotated(sprPlane, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,0,DxDy2Angle(Gear^.dY, Gear^.dX));
       
       gtBall: DrawRotatedf(sprBalls, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Tag,0, DxDy2Angle(Gear^.dY, Gear^.dX));
       
       gtDrill: DrawRotated(sprDrill, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
        
        gtHedgehog: DrawHH(Gear);
    
    gtAmmo_Grenade: DrawRotated(sprGrenade, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
       
       gtHealthTag: if Gear^.Tex <> nil then DrawCentered(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Tex);
           
           gtGrave: DrawSurfSprite(hwRound(Gear^.X) + WorldDx - 16, hwRound(Gear^.Y) + WorldDy - 16, 32, (GameTicks shr 7) and 7, PHedgehog(Gear^.Hedgehog)^.Team^.GraveTex);
             
             gtUFO: DrawSprite(sprUFO, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, (GameTicks shr 7) mod 4);
      
      gtPickHammer: DrawSprite(sprPHammer, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 50 + LongInt(((GameTicks shr 5) and 1) * 2) + WorldDy, 0);
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
                       DrawRotated(sprRopeHook, hwRound(RopePoints.ar[0].X) + WorldDx, hwRound(RopePoints.ar[0].Y) + WorldDy, 1, RopePoints.HookAngle)
                       end else
                       if Gear^.Elasticity.QWordValue > 0 then
                       begin
                       DrawRopeLine(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy,
                                    hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.X) + WorldDx, hwRound(PHedgehog(Gear^.Hedgehog)^.Gear^.Y) + WorldDy);
                       DrawRotated(sprRopeHook, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
                       end;
                    end;
      gtSmokeTrace: if Gear^.State < 8 then DrawSprite(sprSmokeTrace, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.State);
       gtExplosion: DrawSprite(sprExplosion50, hwRound(Gear^.X) - 32 + WorldDx, hwRound(Gear^.Y) - 32 + WorldDy, Gear^.State);
            gtMine: if ((Gear^.State and gstAttacking) = 0)or((Gear^.Timer and $3FF) < 420)
                       then DrawRotated(sprMineOff, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle)
                       else DrawRotated(sprMineOn, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
            gtCase: case Gear^.Pos of
                         posCaseAmmo  : begin
                                        i:= (GameTicks shr 6) mod 64;
                                        if i > 18 then i:= 0;
                                        DrawSprite(sprCase, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, i);
                                        end;
                         posCaseHealth: begin
                                        i:= (GameTicks shr 6) mod 64;
                                        if i > 12 then i:= 0;
                                        DrawSprite(sprFAid, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 24 + WorldDy, i);
                                        end;
                         end;
        gtDynamite: DrawSprite2(sprDynamite, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 25 + WorldDy, Gear^.Tag and 1, Gear^.Tag shr 1);
     gtClusterBomb: DrawRotated(sprClusterBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
         gtCluster: DrawSprite(sprClusterParticle, hwRound(Gear^.X) - 8 + WorldDx, hwRound(Gear^.Y) - 8 + WorldDy, 0);
           gtFlame: DrawSprite(sprFlame, hwRound(Gear^.X) - 8 + WorldDx, hwRound(Gear^.Y) - 8 + WorldDy, (GameTicks div 128 + LongWord(Gear^.Tag)) mod 8);
       gtParachute: DrawSprite(sprParachute, hwRound(Gear^.X) - 24 + WorldDx, hwRound(Gear^.Y) - 48 + WorldDy, 0);
       gtAirAttack: if Gear^.Tag > 0 then DrawSprite(sprAirplane, hwRound(Gear^.X) - 60 + WorldDx, hwRound(Gear^.Y) - 25 + WorldDy, 0)
                                     else DrawSprite(sprAirplane, hwRound(Gear^.X) - 60 + WorldDx, hwRound(Gear^.Y) - 25 + WorldDy, 1);
         gtAirBomb: DrawRotated(sprAirBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
        gtTeleport: begin
                    HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
                    DrawRotatedF(sprTeleport, hwRound(Gear^.X) + 1 + WorldDx, hwRound(Gear^.Y) - 3 + WorldDy, Gear^.Pos, hwSign(HHGear^.dX), 0);
                    DrawRotatedF(sprTeleport, hwRound(HHGear^.X) + 1 + WorldDx, hwRound(HHGear^.Y) - 3 + WorldDy, 11 - Gear^.Pos, hwSign(HHGear^.dX), 0);
                    end;
        gtSwitcher: DrawSprite(sprSwitch, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 56 + WorldDy, (GameTicks shr 6) mod 12);
          gtTarget: DrawSprite(sprTarget, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, 0);
          gtMortar: DrawRotated(sprMortar, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, DxDy2Angle(Gear^.dY, Gear^.dX));
          gtCake: if Gear^.Pos = 6 then
                     DrawRotatedf(sprCakeWalk, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, (GameTicks div 40) mod 6, hwSign(Gear^.dX), Gear^.DirAngle + hwSign(Gear^.dX) * 90)
                  else
                     DrawRotatedf(sprCakeDown, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 5 - Gear^.Pos, hwSign(Gear^.dX), 0);
       gtSeduction: if Gear^.Pos >= 14 then DrawSprite(sprSeduction, hwRound(Gear^.X) - 16 + WorldDx, hwRound(Gear^.Y) - 16 + WorldDy, 0);
      gtWatermelon: DrawRotatedf(sprWatermelon, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, 0, Gear^.DirAngle);
      gtMelonPiece: DrawRotatedf(sprWatermelon, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 1, 0, Gear^.DirAngle);
     gtHellishBomb: DrawRotated(sprHellishBomb, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 0, Gear^.DirAngle);
      gtEvilTrace: if Gear^.State < 8 then DrawSprite(sprEvilTrace, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.State);
         end;
      Gear:= Gear^.NextGear
      end;
end;

procedure FreeGearsList;
var t, tt: PGear;
begin
tt:= GearsList;
GearsList:= nil;
while tt <> nil do
	begin
	t:= tt;
	tt:= tt^.NextGear;
	Dispose(t)
	end;
end;

procedure AddMiscGears;
var i: LongInt;
	Gear: PGear;
begin
AddGear(0, 0, gtATStartGame, 0, _0, _0, 2000);

if (GameFlags and gfForts) = 0 then
	for i:= 0 to Pred(cLandAdditions) do
		begin
		Gear:= AddGear(0, 0, gtMine, 0, _0, _0, 0);
		FindPlace(Gear, false, 0, LAND_WIDTH)
		end
end;

procedure doMakeExplosion(X, Y, Radius: LongInt; Mask: LongWord);
var Gear: PGear;
    dmg, dmgRadius: LongInt;
begin
TargetPoint.X:= NoPointX;
{$IFDEF DEBUGFILE}if Radius > 4 then AddFileLog('Explosion: at (' + inttostr(x) + ',' + inttostr(y) + ')');{$ENDIF}
if (Radius > 10) then AddGear(X, Y, gtExplosion, 0, _0, _0, 0);
if (Mask and EXPLAutoSound) <> 0 then PlaySound(sndExplosion, false, nil);

if (Mask and EXPLAllDamageInRadius) = 0 then
	dmgRadius:= Radius shl 1
else
	dmgRadius:= Radius;

Gear:= GearsList;
while Gear <> nil do
	begin
	dmg:= dmgRadius  + cHHRadius div 2 - hwRound(Distance(Gear^.X - int2hwFloat(X), Gear^.Y - int2hwFloat(Y)));
	if (dmg > 1) and
		((Gear^.State and gstNoDamage) = 0) then
		begin
		dmg:= min(dmg div 2, Radius);
		case Gear^.Kind of
			gtHedgehog,
				gtMine,
				gtCase,
				gtTarget,
				gtFlame: begin
						//{$IFDEF DEBUGFILE}AddFileLog('Damage: ' + inttostr(dmg));{$ENDIF}
						if (Mask and EXPLNoDamage) = 0 then
							begin
							inc(Gear^.Damage, dmg);
							if Gear^.Kind = gtHedgehog then
								AddDamageTag(hwRound(Gear^.X), hwRound(Gear^.Y), dmg, PHedgehog(Gear^.Hedgehog)^.Team^.Clan^.Color)
							end;
						if ((Mask and EXPLDoNotTouchHH) = 0) or (Gear^.Kind <> gtHedgehog) then
							begin
							DeleteCI(Gear);
							Gear^.dX:= Gear^.dX + SignAs(_0_005 * dmg + cHHKick, Gear^.X - int2hwFloat(X));
							Gear^.dY:= Gear^.dY + SignAs(_0_005 * dmg + cHHKick, Gear^.Y - int2hwFloat(Y));
							Gear^.State:= (Gear^.State or gstMoving) and (not gstWinner);
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

if (Mask and EXPLDontDraw) = 0 then
	if (GameFlags and gfSolidLand) = 0 then DrawExplosion(X, Y, Radius);

uAIMisc.AwareOfExplosion(0, 0, 0)
end;

procedure ShotgunShot(Gear: PGear);
var t: PGear;
    dmg: LongInt;
begin
Gear^.Radius:= cShotgunRadius;
t:= GearsList;
while t <> nil do
	begin
	dmg:= min(Gear^.Radius + t^.Radius - hwRound(Distance(Gear^.X - t^.X, Gear^.Y - t^.Y)), 25);
	if dmg > 0 then
	case t^.Kind of
		gtHedgehog,
			gtMine,
			gtCase,
			gtTarget: begin
					inc(t^.Damage, dmg);

					if t^.Kind = gtHedgehog then
						AddDamageTag(hwRound(Gear^.X), hwRound(Gear^.Y), dmg, PHedgehog(t^.Hedgehog)^.Team^.Clan^.Color);

					DeleteCI(t);
					t^.dX:= t^.dX + Gear^.dX * dmg * _0_01 + SignAs(cHHKick, Gear^.dX);
					t^.dY:= t^.dY + Gear^.dY * dmg * _0_01;
					t^.State:= t^.State or gstMoving;
					t^.Active:= true;
					FollowGear:= t
					end;
			gtGrave: begin
					t^.dY:= - _0_1;
					t^.Active:= true
					end;
		end;
	t:= t^.NextGear
	end;
if (GameFlags and gfSolidLand) = 0 then DrawExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), cShotgunRadius)
end;

procedure AmmoShove(Ammo: PGear; Damage, Power: LongInt);
var t: PGearArray;
    i: LongInt;
begin
t:= CheckGearsCollision(Ammo);
i:= t^.Count;

while i > 0 do
	begin
	dec(i);
	if (t^.ar[i]^.State and gstNoDamage) = 0 then
		case t^.ar[i]^.Kind of
			gtHedgehog,
			gtMine,
			gtTarget,
			gtCase: begin
					if (Ammo^.Kind = gtDrill) then begin Ammo^.Timer:= 0; exit; end;
					inc(t^.ar[i]^.Damage, Damage);

					if (t^.ar[i]^.Kind = gtHedgehog) and (Damage > 0) then
						AddDamageTag(hwRound(t^.ar[i]^.X), hwRound(t^.ar[i]^.Y), Damage, PHedgehog(t^.ar[i]^.Hedgehog)^.Team^.Clan^.Color);

					DeleteCI(t^.ar[i]);
					t^.ar[i]^.dX:= Ammo^.dX * Power * _0_01;
					t^.ar[i]^.dY:= Ammo^.dY * Power * _0_01;
					t^.ar[i]^.Active:= true;
					t^.ar[i]^.State:= t^.ar[i]^.State or gstMoving;

					if TestCollisionXwithGear(t^.ar[i], hwSign(t^.ar[i]^.dX)) then
						begin
						if not (TestCollisionXwithXYShift(t^.ar[i], _0, -3, hwSign(t^.ar[i]^.dX))
							or TestCollisionYwithGear(t^.ar[i], -1)) then t^.ar[i]^.Y:= t^.ar[i]^.Y - _1;
						if not (TestCollisionXwithXYShift(t^.ar[i], _0, -2, hwSign(t^.ar[i]^.dX))
							or TestCollisionYwithGear(t^.ar[i], -1)) then t^.ar[i]^.Y:= t^.ar[i]^.Y - _1;
						if not (TestCollisionXwithXYShift(t^.ar[i], _0, -1, hwSign(t^.ar[i]^.dX))
							or TestCollisionYwithGear(t^.ar[i], -1)) then t^.ar[i]^.Y:= t^.ar[i]^.Y - _1;
						end;
					
					FollowGear:= t^.ar[i]
					end;
		end
	end;
SetAllToActive
end;

procedure AssignHHCoords;
var i, t, p, j: LongInt;
	ar: array[0..Pred(cMaxHHs)] of PHedgehog;
	Count: Longword;
begin
if (GameFlags and (gfForts or gfDivideTeams)) <> 0 then
	begin
	t:= 0;
	TryDo(ClansCount = 2, 'More or less than 2 clans on map in divided teams mode!', true);
	for p:= 0 to 1 do
		begin
		with ClansArray[p]^ do
			for j:= 0 to Pred(TeamsNumber) do
				with Teams[j]^ do
					for i:= 0 to cMaxHHIndex do
						with Hedgehogs[i] do
							if (Gear <> nil) and (Gear^.X.QWordValue = 0) then
								begin
								FindPlace(Gear, false, t, t + LAND_WIDTH div 2);// could make Gear == nil
								if Gear <> nil then
									begin
									Gear^.Pos:= GetRandom(49);
									Gear^.dX.isNegative:= p = 1;
									end
								end;
		t:= LAND_WIDTH div 2
		end
	end else // mix hedgehogs
	begin
	Count:= 0;
	for p:= 0 to Pred(TeamsCount) do
		with TeamsArray[p]^ do
		begin
		for i:= 0 to cMaxHHIndex do
			with Hedgehogs[i] do
				if (Gear <> nil) and (Gear^.X.QWordValue = 0) then
					begin
					ar[Count]:= @Hedgehogs[i];
					inc(Count)
					end;
		end;
    // unC0Rr, while it is true user can watch value on map screen, IMO this (and check above) should be enforced in UI
    // - is there a good place to put values for the different widgets to check?  Right now they are kind of disconnected.
    //it'd be nice if divide teams, forts mode and hh per map could all be checked by the team widget, or maybe disable start button
	TryDo(Count <= MaxHedgehogs, 'Too many hedgehogs for this map!', true);
	while (Count > 0) do
		begin
		i:= GetRandom(Count);
		FindPlace(ar[i]^.Gear, false, 0, LAND_WIDTH);
		if ar[i]^.Gear <> nil then
			begin
			ar[i]^.Gear^.dX.isNegative:= hwRound(ar[i]^.Gear^.X) > LAND_WIDTH div 2;
			ar[i]^.Gear^.Pos:= GetRandom(19)
			end;
		ar[i]:= ar[Count - 1];
		dec(Count)
		end
	end
end;

function CheckGearNear(Gear: PGear; Kind: TGearType; rX, rY: LongInt): PGear;
var t: PGear;
begin
t:= GearsList;
rX:= sqr(rX);
rY:= sqr(rY);

while t <> nil do
	begin
	if (t <> Gear) and (t^.Kind = Kind) then
		if not((hwSqr(Gear^.X - t^.X) / rX + hwSqr(Gear^.Y - t^.Y) / rY) > _1) then
		exit(t);
	t:= t^.NextGear
	end;

CheckGearNear:= nil
end;

{procedure AmmoFlameWork(Ammo: PGear);
var t: PGear;
begin
t:= GearsList;
while t <> nil do
	begin
	if (t^.Kind = gtHedgehog) and (t^.Y < Ammo^.Y) then
		if not (hwSqr(Ammo^.X - t^.X) + hwSqr(Ammo^.Y - t^.Y - int2hwFloat(cHHRadius)) * 2 > _2) then
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
end;}

function CheckGearsNear(mX, mY: LongInt; Kind: TGearsType; rX, rY: LongInt): PGear;
var t: PGear;
begin
t:= GearsList;
rX:= sqr(rX);
rY:= sqr(rY);
while t <> nil do
	begin
	if t^.Kind in Kind then
		if not (hwSqr(int2hwFloat(mX) - t^.X) / rX + hwSqr(int2hwFloat(mY) - t^.Y) / rY > _1) then
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
var t: LongInt;
    i: TAmmoType;
begin
if (cCaseFactor = 0) or
   (CountGears(gtCase) >= 5) or
   (getrandom(cCaseFactor) <> 0) then exit;

FollowGear:= AddGear(0, 0, gtCase, 0, _0, _0, 0);
case getrandom(2) of
     0: begin
        FollowGear^.Health:= 25;
        FollowGear^.Pos:= posCaseHealth
        end;
     1: begin
        t:= 0;
        for i:= Low(TAmmoType) to High(TAmmoType) do
            inc(t, Ammoz[i].Probability);
        t:= GetRandom(t);
        i:= Low(TAmmoType);
        dec(t, Ammoz[i].Probability);
        while t >= 0 do
          begin
          inc(i);
          dec(t, Ammoz[i].Probability)
          end;
        PlaySound(sndReinforce, false, CurrentTeam^.voicepack);
        FollowGear^.Pos:= posCaseAmmo;
        FollowGear^.State:= Longword(i)
        end;
     end;
 
FindPlace(FollowGear, true, 0, LAND_WIDTH)
end;

procedure FindPlace(var Gear: PGear; withFall: boolean; Left, Right: LongInt);

	function CountNonZeroz(x, y, r: LongInt): LongInt;
	var i: LongInt;
		Result: LongInt;
	begin
	Result:= 0;
	if (y and LAND_HEIGHT_MASK) = 0 then
		for i:= max(x - r, 0) to min(x + r, LAND_WIDTH - 4) do
			if Land[y, i] <> 0 then inc(Result);
	CountNonZeroz:= Result
	end;

var x: LongInt;
	y, sy: LongInt;
	ar: array[0..511] of TPoint;
	ar2: array[0..1023] of TPoint;
	cnt, cnt2: Longword;
	delta: LongInt;
begin
delta:= 250;
cnt2:= 0;
repeat
	x:= Left + LongInt(GetRandom(Delta));
	repeat
		inc(x, Delta);
		cnt:= 0;
		y:= -Gear^.Radius * 2;
		while y < LAND_HEIGHT do
			begin
			repeat
				inc(y, 2);
			until (y >= LAND_HEIGHT) or (CountNonZeroz(x, y, Gear^.Radius - 1) = 0);
			
			sy:= y;

			repeat
				inc(y);
			until (y >= LAND_HEIGHT) or (CountNonZeroz(x, y, Gear^.Radius - 1) <> 0);
			
			if (y - sy > Gear^.Radius * 2)
				and (y < LAND_HEIGHT)
				and (CheckGearsNear(x, y - Gear^.Radius, [gtHedgehog, gtMine, gtCase], 110, 110) = nil) then
				begin
				ar[cnt].X:= x;
				if withFall then ar[cnt].Y:= sy + Gear^.Radius
							else ar[cnt].Y:= y - Gear^.Radius;
				inc(cnt)
				end;
			
			inc(y, 45)
			end;
		
		if cnt > 0 then
			with ar[GetRandom(cnt)] do
				begin
				ar2[cnt2].x:= x;
				ar2[cnt2].y:= y;
				inc(cnt2)
				end
	until (x + Delta > Right);
	
	dec(Delta, 60)
until (cnt2 > 0) or (Delta < 70);

if cnt2 > 0 then
	with ar2[GetRandom(cnt2)] do
		begin
		Gear^.X:= int2hwFloat(x);
		Gear^.Y:= int2hwFloat(y);
		{$IFDEF DEBUGFILE}
		AddFileLog('Assigned Gear coordinates (' + inttostr(x) + ',' + inttostr(y) + ')');
		{$ENDIF}
		end
	else
	begin
	OutError('Can''t find place for Gear', false);
	DeleteGear(Gear);
	Gear:= nil
	end
end;

initialization

finalization
FreeGearsList;

end.

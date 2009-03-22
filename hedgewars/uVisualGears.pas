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

unit uVisualGears;
interface
uses SDLh, uConsts,
{$IFDEF IPHONE}
	gles11,
{$ELSE}
	GL,
{$ENDIF}
	uFloat;
{$INCLUDE options.inc}
const AllInactive: boolean = false;

type PVisualGear = ^TVisualGear;
	TVGearStepProcedure = procedure (Gear: PVisualGear; Steps: Longword);
	TVisualGear = record
		NextGear, PrevGear: PVisualGear;
		Frame,
		FrameTicks: Longword;
		X : hwFloat;
		Y : hwFloat;
		dX: hwFloat;
		dY: hwFloat;
		mdY: QWord;
		Angle, dAngle: real;
		Kind: TVisualGearType;
		doStep: TVGearStepProcedure;
		Tex: PTexture;
		end;

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType): PVisualGear;
procedure ProcessVisualGears(Steps: Longword);
procedure DrawVisualGears(Layer: LongWord);
procedure DeleteVisualGear(Gear: PVisualGear);
procedure AddClouds;
procedure AddDamageTag(X, Y, Damage, Color: LongWord);

var VisualGearsList: PVisualGear = nil;
	vobFrameTicks, vobFramesCount: Longword;
	vobVelocity, vobFallSpeed: LongInt;

implementation
uses uWorld, uMisc, uStore;
const cExplFrameTicks = 110;

procedure AddDamageTag(X, Y, Damage, Color: LongWord);
var s: shortstring;
	Gear: PVisualGear;
begin
if cAltDamage then
	begin
	Gear:= AddVisualGear(X, Y, vgtSmallDamageTag);
	if Gear <> nil then
		with Gear^ do
			begin
			str(Damage, s);
			Tex:= RenderStringTex(s, Color, fntSmall);
			end
	end
end;


// ==================================================================
procedure doStepFlake(Gear: PVisualGear; Steps: Longword);
begin
with Gear^ do
	begin
	inc(FrameTicks, Steps);
	if FrameTicks > vobFrameTicks then
		begin
		dec(FrameTicks, vobFrameTicks);
		inc(Frame);
		if Frame = vobFramesCount then Frame:= 0
		end
	end;

Gear^.X:= Gear^.X + (cWindSpeed * 200 + Gear^.dX) * Steps;
Gear^.Y:= Gear^.Y + (Gear^.dY + cGravity * vobFallSpeed) * Steps;
Gear^.Angle:= Gear^.Angle + Gear^.dAngle * Steps;

if hwRound(Gear^.X) < -cScreenWidth - 64 then Gear^.X:= int2hwFloat(cScreenWidth + LAND_WIDTH) else
if hwRound(Gear^.X) > cScreenWidth + LAND_WIDTH then Gear^.X:= int2hwFloat(-cScreenWidth - 64);
// if hwRound(Gear^.Y) < (LAND_HEIGHT - 1024 - 75) then Gear^.Y:= Gear^.Y + int2hwFloat(25); // For if flag is set for flakes rising upwards?
if hwRound(Gear^.Y) > (LAND_HEIGHT + 75) then Gear^.Y:= Gear^.Y - int2hwFloat(1024 + 150) // TODO - configure in theme (jellies for example could use limited range)
end;

procedure doStepCloud(Gear: PVisualGear; Steps: Longword);
var i: Longword;
begin
Gear^.X:= Gear^.X + (cWindSpeed * 200 + Gear^.dX) * Steps;

for i:= 0 to Steps - 1 do
	begin
	if hwRound(Gear^.Y) > LAND_HEIGHT-1184 then // TODO - configure in theme
		Gear^.dY:= Gear^.dY - _1div50000
	else
		Gear^.dY:= Gear^.dY + _1div50000;

	Gear^.Y:= Gear^.Y + Gear^.dY
	end;

if hwRound(Gear^.X) < -cScreenWidth - 256 then Gear^.X:= int2hwFloat(cScreenWidth + LAND_WIDTH) else
if hwRound(Gear^.X) > cScreenWidth + LAND_WIDTH then Gear^.X:= int2hwFloat(-cScreenWidth - 256)
end;

procedure doStepExpl(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
//Gear^.dY:= Gear^.dY + cGravity;

if Gear^.FrameTicks <= Steps then
	if Gear^.Frame = 0 then DeleteVisualGear(Gear)
	else
		begin
		dec(Gear^.Frame);
		Gear^.FrameTicks:= cExplFrameTicks
		end
	else dec(Gear^.FrameTicks, Steps)
end;

procedure doStepFire(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;// + cGravity * (Steps * Steps);
Gear^.dY:= Gear^.dY + cGravity * Steps;

if Gear^.FrameTicks <= Steps then
	DeleteVisualGear(Gear)
else
	dec(Gear^.FrameTicks, Steps)
end;

procedure doStepSmallDamage(Gear: PVisualGear; Steps: Longword);
begin
Gear^.Y:= Gear^.Y - _0_02 * Steps;

if Gear^.FrameTicks <= Steps then
	DeleteVisualGear(Gear)
else
	dec(Gear^.FrameTicks, Steps)
end;

// ==================================================================
const doStepHandlers: array[TVisualGearType] of TVGearStepProcedure =
		(
			@doStepFlake,
			@doStepCloud,
			@doStepExpl,
			@doStepExpl,
			@doStepFire,
			@doStepSmallDamage
		);

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType): PVisualGear;
var Result: PVisualGear;
	t: Longword;
	sp: hwFloat;
begin
if (GameType = gmtSave) or (fastUntilLag and (GameType = gmtNet)) then // we're scrolling now
	if Kind <> vgtCloud then
		begin
		AddVisualGear:= nil;
		exit
		end;

if cReducedQuality then
	begin
	AddVisualGear:= nil;
	exit
	end;

New(Result);
FillChar(Result^, sizeof(TVisualGear), 0);
Result^.X:= int2hwFloat(X);
Result^.Y:= int2hwFloat(Y);
Result^.Kind := Kind;
Result^.doStep:= doStepHandlers[Kind];

with Result^ do
	case Kind of
	vgtFlake: begin
				FrameTicks:= random(vobFrameTicks);
				Frame:= random(vobFramesCount);
				Angle:= random * 360;
				dx.isNegative:= random(2) = 0;
				dx.QWordValue:= random(100000000);
				dy.isNegative:= false;
				dy.QWordValue:= random(70000000);
				dAngle:= (random(2) * 2 - 1) * (1 + random) * vobVelocity / 1000
				end;
	vgtCloud: begin
				Frame:= random(4);
				dx.isNegative:= random(2) = 0;
				dx.QWordValue:= random(214748364);
				dy.isNegative:= random(2) = 0;
				dy.QWordValue:= 21474836 + random(64424509);
				mdY:= dy.QWordValue
				end;
	vgtExplPart,
	vgtExplPart2: begin
				t:= random(1024);
				sp:= _0_001 * (random(95) + 70);
				dx:= AngleSin(t) * sp;
				dx.isNegative:= random(2) = 0;
				dy:= AngleCos(t) * sp;
				dy.isNegative:= random(2) = 0;
				Frame:= 7 - random(3);
				FrameTicks:= cExplFrameTicks
				end;
		vgtFire: begin
				t:= random(1024);
				sp:= _0_001 * (random(85) + 95);
				dx:= AngleSin(t) * sp;
				dx.isNegative:= random(2) = 0;
				dy:= AngleCos(t) * sp;
				dy.isNegative:= random(2) = 0;
				FrameTicks:= 650 + random(250);
				Frame:= random(8)
				end;
	vgtSmallDamageTag: begin
				Result^.FrameTicks:= 1100
				end;
		end;

if VisualGearsList <> nil then
	begin
	VisualGearsList^.PrevGear:= Result;
	Result^.NextGear:= VisualGearsList
	end;
VisualGearsList:= Result;

AddVisualGear:= Result
end;

procedure DeleteVisualGear(Gear: PVisualGear);
begin
if Gear^.Tex <> nil then
	FreeTexture(Gear^.Tex);

if Gear^.NextGear <> nil then Gear^.NextGear^.PrevGear:= Gear^.PrevGear;
if Gear^.PrevGear <> nil then Gear^.PrevGear^.NextGear:= Gear^.NextGear
   else VisualGearsList:= Gear^.NextGear;

Dispose(Gear)
end;

procedure ProcessVisualGears(Steps: Longword);
var Gear, t: PVisualGear;
begin
if Steps = 0 then exit;

t:= VisualGearsList;
while t <> nil do
      begin
      Gear:= t;
      t:= Gear^.NextGear;
      Gear^.doStep(Gear, Steps)
      end
end;

procedure DrawVisualGears(Layer: LongWord);
var Gear: PVisualGear;
begin
Gear:= VisualGearsList;
case Layer of
	0: while Gear <> nil do
		begin
		case Gear^.Kind of
			vgtFlake: if vobVelocity = 0 then
						DrawSprite(sprFlake, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Frame)
					else
						DrawRotatedF(sprFlake, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Frame, 1, Gear^.Angle);
			vgtCloud: DrawSprite(sprCloud, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Frame);
			end;
		Gear:= Gear^.NextGear
		end;
	1: while Gear <> nil do
		begin
		case Gear^.Kind of
			vgtExplPart: DrawSprite(sprExplPart, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 7 - Gear^.Frame);
			vgtExplPart2: DrawSprite(sprExplPart2, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, 7 - Gear^.Frame);
			vgtFire: DrawSprite(sprFlame, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, (RealTicks div 64 + Gear^.Frame) mod 8);
			vgtSmallDamageTag: DrawCentered(hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.Tex);
			end;
		Gear:= Gear^.NextGear
		end
	end
end;

procedure AddClouds;
var i: LongInt;
begin
for i:= 0 to cCloudsNumber - 1 do
    AddVisualGear( - cScreenWidth + i * ((cScreenWidth * 2 + (LAND_WIDTH+256)) div (cCloudsNumber + 1)), LAND_HEIGHT-1184, vgtCloud)
end;

initialization

finalization

end.

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

unit uVisualGears;
interface
uses SDLh, uConsts, uFloat, GL;
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
             end;

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType): PVisualGear;
procedure ProcessVisualGears(Steps: Longword);
procedure DrawVisualGears();
procedure AddClouds;

var VisualGearsList: PVisualGear = nil;
    vobFrameTicks, vobFramesCount: Longword;
    vobVelocity, vobFallSpeed: LongInt;

implementation
uses uWorld, uMisc, uStore;

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

if hwRound(Gear^.X) < -cScreenWidth - 64 then Gear^.X:= int2hwFloat(cScreenWidth + 2048) else
if hwRound(Gear^.X) > cScreenWidth + 2048 then Gear^.X:= int2hwFloat(-cScreenWidth - 64);
if hwRound(Gear^.Y) > 1100 then Gear^.Y:= Gear^.Y - int2hwFloat(1228)
end;

procedure doStepCloud(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + (cWindSpeed * 200 + Gear^.dX) * Steps;
if hwRound(Gear^.Y) > -160 then Gear^.dY:= Gear^.dY - _1div50000 * Steps
                           else Gear^.dY:= Gear^.dY + _1div50000 * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;

if hwRound(Gear^.X) < -cScreenWidth - 256 then Gear^.X:= int2hwFloat(cScreenWidth + 2048) else
if hwRound(Gear^.X) > cScreenWidth + 2048 then Gear^.X:= int2hwFloat(-cScreenWidth - 256)
end;

// ==================================================================
const doStepHandlers: array[TVisualGearType] of TVGearStepProcedure =
                        (
                          @doStepFlake,
                          @doStepCloud
                        );

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType): PVisualGear;
var Result: PVisualGear;
begin
New(Result);
FillChar(Result^, sizeof(TVisualGear), 0);
Result^.X:= int2hwFloat(X);
Result^.Y:= int2hwFloat(Y);
Result^.Kind := Kind;
Result^.doStep:= doStepHandlers[Kind];

case Kind of
   vgtFlake: with Result^ do
               begin
               FrameTicks:= random(vobFrameTicks);
               Frame:= random(vobFramesCount);
               Angle:= random * 360;
               dx.isNegative:= random(2) = 0;
               dx.QWordValue:= random(100000000);
               dy.isNegative:= false;
               dy.QWordValue:= random(70000000);
               dAngle:= (random(2) * 2 - 1) * (1 + random) * vobVelocity / 1000
               end;
   vgtCloud: with Result^ do
               begin
               Frame:= random(4);
               dx.isNegative:= random(2) = 0;
               dx.QWordValue:= random(214748364);
               dy.isNegative:= random(2) = 0;
               dy.QWordValue:= 21474836 + random(64424509);
               mdY:= dy.QWordValue
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

procedure DrawVisualGears();
var Gear: PVisualGear;
begin
Gear:= VisualGearsList;
while Gear <> nil do
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
end;

procedure AddClouds;
var i: LongInt;
begin
for i:= 0 to cCloudsNumber do
    AddVisualGear( - cScreenWidth + i * ((cScreenWidth * 2 + 2304) div cCloudsNumber), -140, vgtCloud)
end;

initialization

finalization

end.

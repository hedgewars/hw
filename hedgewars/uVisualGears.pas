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
uses SDLh, uConsts, uFloat;
{$INCLUDE options.inc}
const AllInactive: boolean = false;

type PVisualGear = ^TVisualGear;
     TVGearStepProcedure = procedure (Gear: PVisualGear; Steps: Longword);
     TVisualGear = record
             NextGear, PrevGear: PVisualGear;
             State : Longword;
             X : hwFloat;
             Y : hwFloat;
             dX: hwFloat;
             dY: hwFloat;
             Kind: TVisualGearType;
             doStep: TVGearStepProcedure;
             end;

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; dX, dY: hwFloat): PVisualGear;
procedure ProcessVisualGears(Steps: Longword);
procedure DrawVisualGears();
procedure AddClouds;

var VisualGearsList: PVisualGear = nil;

implementation
uses uWorld, uMisc, uStore, GL;

// ==================================================================
procedure doStepFlake(Gear: PVisualGear; Steps: Longword);
begin
end;

procedure doStepCloud(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + (cWindSpeed * 200 + Gear^.dX) * Steps;
if hwRound(Gear^.Y) > -160 then Gear^.dY:= Gear^.dY - _1div50000
                           else Gear^.dY:= Gear^.dY + _1div50000;
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

function  AddVisualGear(X, Y: LongInt; Kind: TVisualGearType; dX, dY: hwFloat): PVisualGear;
var Result: PVisualGear;
begin
New(Result);
FillChar(Result^, sizeof(TVisualGearType), 0);
Result^.X:= int2hwFloat(X);
Result^.Y:= int2hwFloat(Y);
Result^.Kind := Kind;
Result^.dX:= dX;
Result^.dY:= dY;
Result^.doStep:= doStepHandlers[Kind];

case Kind of
   vgtCloud: Result^.State:= random(4);
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
           vgtFlake: ;
           vgtCloud: DrawSprite(sprCloud, hwRound(Gear^.X) + WorldDx, hwRound(Gear^.Y) + WorldDy, Gear^.State, nil);
              end;
      Gear:= Gear^.NextGear
      end;
end;

procedure AddClouds;
var i: LongInt;
    dx, dy: hwFloat;
begin
for i:= 0 to cCloudsNumber do
    begin
    dx.isNegative:= random(2) = 1;
    dx.QWordValue:= random(214748364);
    dy.isNegative:= (i and 1) = 1;
    dy.QWordValue:= 21474836 + random(64424509);
    AddVisualGear( - cScreenWidth + i * ((cScreenWidth * 2 + 2304) div cCloudsNumber), -140,
             vgtCloud, dx, dy)
    end
end;

initialization

finalization

end.

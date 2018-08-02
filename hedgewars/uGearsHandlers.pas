(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2015 Andrey Korotaev <unC0Rr@gmail.com>
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
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 *)

{$INCLUDE "options.inc"}

unit uGearsHandlers;
interface

uses uTypes;

function cakeStep(Gear: PGear): boolean;

implementation

uses SDLh, uFloat, uCollisions, uVariables, uGearsUtils;



const dirs: array[0..3] of TPoint = ((x: 0;  y: -1),
                                     (x: 1;  y:  0),
                                     (x: 0;  y:  1),
                                     (x: -1; y:  0));

procedure PrevAngle(Gear: PGear; dA: LongInt); inline;
begin
    inc(Gear^.WDTimer);
    Gear^.Angle := (LongInt(Gear^.Angle) - dA) and 3
end;

procedure NextAngle(Gear: PGear; dA: LongInt); inline;
begin
    inc(Gear^.WDTimer);
    Gear^.Angle := (LongInt(Gear^.Angle) + dA) and 3
end;

function cakeStep(Gear: PGear): boolean;
var
    xx, yy, xxn, yyn: LongInt;
    dA: LongInt;
begin
    dA := hwSign(Gear^.dX);
    xx := dirs[Gear^.Angle].x;
    yy := dirs[Gear^.Angle].y;
    xxn := dirs[(LongInt(Gear^.Angle) + dA) and 3].x;
    yyn := dirs[(LongInt(Gear^.Angle) + dA) and 3].y;

    if (xx = 0) then
        if TestCollisionYwithGear(Gear, yy) <> 0 then
            PrevAngle(Gear, dA)
        else
            begin
            Gear^.Tag := 0;

            if TestCollisionXwithGear(Gear, xxn) <> 0 then
                Gear^.WDTimer:= 0;

            Gear^.Y := Gear^.Y + int2hwFloat(yy);
            if TestCollisionXwithGear(Gear, xxn) = 0 then
                begin
                Gear^.X := Gear^.X + int2hwFloat(xxn);
                NextAngle(Gear, dA)
                end
            end;

    if (yy = 0) then
        if TestCollisionXwithGear(Gear, xx) <> 0 then
            PrevAngle(Gear, dA)
        else
            begin
            Gear^.Tag := 0;

            if TestCollisionYwithGear(Gear, yyn) <> 0 then
                Gear^.WDTimer:= 0;

            Gear^.X := Gear^.X + int2hwFloat(xx);
            if TestCollisionYwithGear(Gear, yyn) = 0 then
                begin
                Gear^.Y := Gear^.Y + int2hwFloat(yyn);
                NextAngle(Gear, dA)
                end
            end;

    // Handle world wrap and bounce edge manually
    if (WorldEdge = weWrap) and
        ((hwRound(Gear^.X) <= LongInt(leftX)) or (hwRound(Gear^.X) >= LongInt(rightX))) then
        begin
        LeftImpactTimer:= 150;
        RightImpactTimer:= 150;
        Gear^.WDTimer:= 4;
        Gear^.Karma:= 2;
        end
    else if (WorldEdge = weBounce) and
        (((hwRound(Gear^.X) - Gear^.Radius) < LongInt(leftX)) or ((hwRound(Gear^.X) + Gear^.Radius) > LongInt(rightX))) then
        begin
        if (hwRound(Gear^.X) - Gear^.Radius < LongInt(leftX)) then
            LeftImpactTimer:= 333
        else
            RightImpactTimer:= 333;
        Gear^.Karma:= 1;
        Gear^.WDTimer:= 0;
        if (Gear^.Radius > 2) and (Gear^.dX.QWordValue > _0_001.QWordValue) then
            AddBounceEffectForGear(Gear);
        end;

    cakeStep:= Gear^.WDTimer < 4
end;

end.

(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

{$INCLUDE "options.inc"}

unit uGearsHandlers;
interface

uses uTypes;

procedure cakeStep(Gear: PGear);

implementation

uses SDLh, uFloat, uCollisions;



const dirs: array[0..3] of TPoint =   ((X: 0; Y: -1), (X: 1; Y: 0),(X: 0; Y: 1),(X: -1; Y: 0));

procedure PrevAngle(Gear: PGear; dA: LongInt); inline;
begin
    Gear^.Angle := (Gear^.Angle - dA) and 3
end;

procedure NextAngle(Gear: PGear; dA: LongInt); inline;
begin
    Gear^.Angle := (Gear^.Angle + dA) and 3
end;

procedure cakeStep(Gear: PGear);
var
    xx, yy, xxn, yyn: LongInt;
    dA: LongInt;
    tdx, tdy: hwFloat;
begin
    dA := hwSign(Gear^.dX);
    xx := dirs[Gear^.Angle].x;
    yy := dirs[Gear^.Angle].y;
    xxn := dirs[(LongInt(Gear^.Angle) + 4 + dA) mod 4].x;
    yyn := dirs[(LongInt(Gear^.Angle) + 4 + dA) mod 4].y;

    if (xx = 0) then
        if TestCollisionYwithGear(Gear, yy) <> 0 then
            PrevAngle(Gear, dA)
    else
        begin
        Gear^.Tag := 0;
        Gear^.Y := Gear^.Y + int2hwFloat(yy);
        if not TestCollisionXwithGear(Gear, xxn) then
            begin
            Gear^.X := Gear^.X + int2hwFloat(xxn);
            NextAngle(Gear, dA)
            end;
        end;

    if (yy = 0) then
        if TestCollisionXwithGear(Gear, xx) then
            PrevAngle(Gear, dA)
    else
        begin
        Gear^.Tag := 0;
        Gear^.X := Gear^.X + int2hwFloat(xx);
        if TestCollisionYwithGear(Gear, yyn) = 0 then
            begin
            Gear^.Y := Gear^.Y + int2hwFloat(yyn);
            NextAngle(Gear, dA)
            end;
        end;
end;

end.

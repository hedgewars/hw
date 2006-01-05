(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uAIAmmoTests;
interface
uses uConsts, SDLh;
{$INCLUDE options.inc}
const ctfNotFull = $00000001;
      ctfBreach  = $00000002;
      
function TestGrenade(Me, Targ: TPoint; Flags: Longword; out Time: Longword; out Angle, Power: integer): boolean;
function TestBazooka(Me, Targ: TPoint; Flags: Longword; out Time: Longword; out Angle, Power: integer): boolean;
function TestShotgun(Me, Targ: TPoint; Flags: Longword; out Time: Longword; out Angle, Power: integer): boolean;

type TAmmoTestProc = function (Me, Targ: TPoint; Flags: Longword; out Time: Longword; out Angle, Power: integer): boolean;
const AmmoTests: array[TAmmoType] of
                    record
                    Test: TAmmoTestProc;
                    Flags: Longword;
                    end = (
                    ( Test: TestGrenade;
                      Flags: ctfNotFull;
                    ),
                    ( Test: TestBazooka;
                      Flags: ctfNotFull or ctfBreach;
                    ),
                    ( Test: nil;
                      Flags: 0;
                    ),
                    ( Test: TestShotgun;
                      Flags: ctfBreach;
                    ),
                    ( Test: nil;
                      Flags: 0;
                    ),
                    ( Test: nil;
                      Flags: 0;
                    ),
                    ( Test: nil;
                      Flags: 0;
                    ),
                    ( Test: nil;
                      Flags: 0;
                    ),
                    ( Test: nil;
                      Flags: 0;
                    )
                    );

implementation
uses uMisc, uAIMisc;

function TestGrenade(Me, Targ: TPoint; Flags: Longword; out Time: Longword; out Angle, Power: integer): boolean;
var Vx, Vy, r: real;
    flHasTrace: boolean;

    function CheckTrace: boolean;
    var x, y, dY: real;
        t: integer;
    begin
    x:= Me.X;
    y:= Me.Y;
    dY:= -Vy;
    Result:= false;
    if (Flags and ctfNotFull) = 0 then t:= Time
                                  else t:= Time - 100;
    repeat
      x:= x + Vx;
      y:= y + dY;
      dY:= dY + cGravity;
      if TestColl(round(x), round(y), 5) then exit;
      dec(t);
    until t <= 0;
    Result:= true
    end;

begin
Result:= false;
Time:= 0;
flHasTrace:= false;
repeat
  inc(Time, 1000);
  Vx:= (Targ.X - Me.X) / Time;
  Vy:= cGravity*(Time div 2) - (Targ.Y - Me.Y) / Time;
  r:= sqr(Vx) + sqr(Vy);
  if r <= 1 then flHasTrace:= CheckTrace
            else exit
until flHasTrace or (Time = 5000);
if not flHasTrace then exit;
r:= sqrt(r);
Angle:= DxDy2Angle(Vx, Vy);
Power:= round(r * cMaxPower);
Result:= true
end;

function TestBazooka(Me, Targ: TPoint; Flags: Longword; out Time: Longword; out Angle, Power: integer): boolean;
var Vx, Vy, r: real;
    rTime: real;
    flHasTrace: boolean;

    function CheckTrace: boolean;
    var x, y, dX, dY: real;
        t: integer;
    begin
    x:= Me.X + Vx*20;
    y:= Me.Y + Vy*20;
    dX:= Vx;
    dY:= -Vy;
    Result:= false;
    if (Flags and ctfNotFull) = 0 then t:= trunc(rTime)
                                  else t:= trunc(rTime) - 100;
    repeat
      x:= x + dX;
      y:= y + dY;
      dX:= dX + cWindSpeed;
      dY:= dY + cGravity;
      if TestColl(round(x), round(y), 5) then
         begin
         if (Flags and ctfBreach) <> 0 then
            Result:= NoMyHHNear(round(x), round(y), 110);
         exit
         end;
      dec(t)
    until t <= 0;
    Result:= true
    end;

begin
Time:= 0;
Result:= false;
rTime:= 10;
flHasTrace:= false;
repeat
  rTime:= rTime + 100 + random*300;
  Vx:= - cWindSpeed * rTime / 2 + (Targ.X - Me.X) / rTime;
  Vy:= cGravity * rTime / 2 - (Targ.Y - Me.Y) / rTime;
  r:= sqr(Vx) + sqr(Vy);
  if r <= 1 then flHasTrace:= CheckTrace
until flHasTrace or (rTime >= 5000);
if not flHasTrace then exit;
r:= sqrt(r);
Angle:= DxDy2Angle(Vx, Vy);
Power:= round(r * cMaxPower);
Result:= true
end;

function TestShotgun(Me, Targ: TPoint; Flags: Longword; out Time: Longword; out Angle, Power: integer): boolean;
var Vx, Vy, x, y: real;
begin
Time:= 0;
Power:= 1;
Vx:= (Targ.X - Me.X)/1024;
Vy:= (Targ.Y - Me.Y)/1024;
x:= Me.X;
y:= Me.Y;
Angle:= DxDy2Angle(Vx, -Vy);
repeat
  x:= x + vX;
  y:= y + vY;
  if TestColl(round(x), round(y), 2) then
     begin
     if (Flags and ctfBreach) <> 0 then
        Result:= NoMyHHNear(round(x), round(y), 27)
        else Result:= false;
     exit
     end
until (abs(Targ.X - x) + abs(Targ.Y - y) < 4) or (x < 0) or (y < 0) or (x > 2048) or (y > 1024);
Result:= true
end;


end.

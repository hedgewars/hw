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

unit uRandom;
(*
 * This unit supplies platform-independent functions for getting various
 * pseudo-random values based on a shared seed.
 *
 * This is necessary for accomplishing pseudo-random behavior in the game
 * without causing a desynchronisation of different clients when playing over
 * a network.
 *)
interface
uses uFloat;

procedure SetRandomSeed(Seed: shortstring; dropAdditionalPart: boolean); // Sets the seed that should be used for generating pseudo-random values.
function  GetRandomf: hwFloat; // Returns a pseudo-random hwFloat.
function  GetRandom(m: LongWord): LongWord; inline; // Returns a positive pseudo-random integer smaller than m.
procedure AddRandomness(r: LongWord); inline;
function  rndSign(num: hwFloat): hwFloat; // Returns num with a random chance of having a inverted sign.


implementation

var cirbuf: array[0..63] of Longword;
    n: byte;

procedure AddRandomness(r: LongWord); inline;
begin
n:= (n + 1) and $3F;
   cirbuf[n]:= cirbuf[n] xor r;
end;

function GetNext: Longword; inline;
begin
    n:= (n + 1) and $3F;
    cirbuf[n]:=
           (cirbuf[(n + 40) and $3F] +           {n - 24 mod 64}
            cirbuf[(n +  9) and $3F])            {n - 55 mod 64}
            and $7FFFFFFF;                       {mod 2^31}

    GetNext:= cirbuf[n];
end;

procedure SetRandomSeed(Seed: shortstring; dropAdditionalPart: boolean);
var i, t, l: Longword;
begin
n:= 54;

if Length(Seed) > 54 then
    Seed:= copy(Seed, 1, 54); // not 55 to ensure we have odd numbers in cirbuf

t:= 0;
l:= Length(Seed);

while (t < l) and ((not dropAdditionalPart) or (Seed[t + 1] <> '|')) do
    begin
    cirbuf[t]:= byte(Seed[t + 1]);
    inc(t)
    end;

for i:= t to 54 do
    cirbuf[i]:= $A98765 + 68; // odd number

for i:= 0 to 2047 do
   GetNext;
end;

function GetRandomf: hwFloat;
begin
GetNext;
GetRandomf.isNegative:= false;
GetRandomf.QWordValue:= GetNext
end;

function GetRandom(m: LongWord): LongWord; inline;
begin
GetNext;
GetRandom:= GetNext mod m
end;

function rndSign(num: hwFloat): hwFloat;
begin
num.isNegative:= odd(GetNext);
rndSign:= num
end;

end.

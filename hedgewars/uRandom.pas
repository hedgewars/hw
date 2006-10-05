(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004-2006 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uRandom;
interface
{$INCLUDE options.inc}

procedure SetRandomSeed(Seed: shortstring);
function  GetRandom: Double; overload;
function  GetRandom(m: LongWord): LongWord; overload;

implementation
var cirbuf: array[0..63] of Longword;
    n: byte = 54;

function GetNext: Longword;
begin
n:= (n + 1) and $3F;
cirbuf[n]:=
           (cirbuf[(n + 40) and $3F] +           {n - 24 mod 64}
            cirbuf[(n +  9) and $3F])            {n - 55 mod 64}
            and $7FFFFFFF;                       {mod 2^31}

Result:= cirbuf[n]
end;

procedure SetRandomSeed(Seed: shortstring);
var i: Longword;
begin
n:= 54;

if Length(Seed) > 54 then Seed:= copy(Seed, 1, 54); // not 55 to ensure we have odd numbers in cirbuf

for i:= 0 to pred(Length(Seed)) do
    cirbuf[i]:= byte(Seed[i + 1]) * (i + 1);

for i:= Length(Seed) to 54 do
    cirbuf[i]:= i * 7 + 1;

for i:= 0 to 1023 do GetNext
end;

function GetRandom: Double;
begin
Result:= frac( GetNext * 0.00073 + GetNext * 0.00301)
end;

function GetRandom(m: LongWord): LongWord;
begin
GetNext;
Result:= GetNext mod m
end;

end.

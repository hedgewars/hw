(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uRandom;
interface

procedure SetRandomSeed(Seed: shortstring);
function  GetRandom: Double; overload;
function  GetRandom(m: LongWord): LongWord; overload;

implementation
var cirbuf: array[0..63] of Longword;
    n: byte;

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
if Length(Seed) > 60 then Seed:= copy(Seed, 1, 60); // not 64 to ensure we have even numbers in cirbuf
for i:= 0 to pred(Length(Seed)) do
    cirbuf[i]:= byte(Seed[i + 1]) * 35791253;

for i:= Length(Seed) to 63 do
    cirbuf[i]:= i * 23860799;

for i:= 0 to 1024 do GetNext;
end;

function GetRandom: Double;
begin
Result:= frac( GetNext * 0.0007301 + GetNext * 0.003019)
end;

function GetRandom(m: LongWord): LongWord;
begin
GetNext;
Result:= GetNext mod m
end;

end.

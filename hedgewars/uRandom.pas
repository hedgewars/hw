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
uses uSHA;

procedure SetRandomParams(Seed: shortstring; FillBuf: shortstring);
function  GetRandom: real; overload;
function  GetRandom(m: LongWord): LongWord; overload;

implementation
var  sc1, sc2: TSHA1Context;
     Fill: shortstring;

procedure SetRandomParams(Seed: shortstring; FillBuf: shortstring);
begin
SHA1Init(sc1);
SHA1Update(sc1, @Seed, Length(Seed)+1);
Fill:= FillBuf
end;

function GetRandom: real;
var dig: TSHA1Digest;
begin
SHA1Update(sc1, @Fill[1], Length(Fill));
sc2:= sc1;
dig:= SHA1Final(sc1);
Result:= frac( dig.LongWords[0]*0.0000731563977
               + pi * dig.Words[6]
               + 0.0109070019*dig.Words[9]);
sc1:= sc2
end;

function  GetRandom(m: LongWord): LongWord;
var dig: TSHA1Digest;
begin
SHA1Update(sc1, @Fill[1], Length(Fill));
sc2:= sc1;
dig:= SHA1Final(sc1);
Result:= (((dig.LongWords[0] mod m) + (dig.LongWords[2] mod m)) mod m + (dig.LongWords[3] mod m)) mod m;
sc1:= sc2
end;

end.

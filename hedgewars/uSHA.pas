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

unit uSHA;
interface

type TSHA1Context = packed record
                    H: array[0..4] of LongWord;
                    Length, CurrLength: Int64;
                    Buf: array[0..63] of byte;
                    end;
     TSHA1Digest = record
                   case byte of
                        0: (LongWords: array[0.. 4] of LongWord);
                        1: (    Words: array[0.. 9] of     Word);
                        2: (    Bytes: array[0..19] of     Byte)
                   end;

procedure SHA1Init(var Context: TSHA1Context);
procedure SHA1Update(var Context: TSHA1Context; Buf: Pointer; Length: LongWord);
function  SHA1Final(Context: TSHA1Context): TSHA1Digest;

implementation

function _bswap(X: LongWord): LongWord; assembler;
asm
  bswap eax
end;

function rol(x: LongWord; y: Byte): LongWord; assembler;
asm
  mov   cl,dl
  rol   eax,cl
end;

function Ft(t, b, c, d: LongWord): LongWord;
begin
case t of
      0..19: Result := (b and c) or ((not b) and d);
     20..39: Result :=  b xor c xor d;
     40..59: Result := (b and c) or (b and d) or (c and d);
     else    Result :=  b xor c xor d;
  end;
end;

function Kt(t: Byte): LongWord;
begin
  case t of
     0..19: Result := $5A827999;
    20..39: Result := $6ED9EBA1;
    40..59: Result := $8F1BBCDC;
  else
    Result := $CA62C1D6
  end;
end;


procedure SHA1Hash(var Context: TSHA1Context);
var S: array[0..4 ] of LongWord;
    W: array[0..79] of LongWord;
    i, t: LongWord;
begin
move(Context.H, S, sizeof(S));
for i:= 0 to 15 do
    W[i]:= _bswap(PLongWord(LongWord(@Context.Buf)+i*4)^);
for i := 16 to 79 do
    W[i] := rol(W[i - 3] xor W[i - 8] xor W[i - 14] xor W[i - 16], 1);
for i := 0 to 79 do
    begin
    t:= rol(S[0], 5) + Ft(i, S[1], S[2], S[3]) + S[4] + W[i] + Kt(i);
    S[4]:= S[3];
    S[3]:= S[2];
    S[2]:= rol(S[1], 30);
    S[1]:= S[0];
    S[0]:= t
    end;
for i := 0 to 4 do
    Context.H[i]:= Context.H[i] + S[i]
end;

procedure SHA1Init(var Context: TSHA1Context);
begin
  with Context do
       begin
       Length    := 0;
       CurrLength:= 0;
       H[0]:= $67452301;
       H[1]:= $EFCDAB89;
       H[2]:= $98BADCFE;
       H[3]:= $10325476;
       H[4]:= $C3D2E1F0
  end
end;

procedure SHA1Update(var Context: TSHA1Context; Buf: Pointer; Length: LongWord);
var i: integer;
begin
for i:= 1 to Length do
    begin
    Context.Buf[Context.CurrLength]:= PByte(Buf)^;
    inc(Context.CurrLength);
    inc(LongWord(Buf));
    if Context.CurrLength=64 then
       begin
       SHA1Hash(Context);
       inc(Context.Length, 512);
       Context.CurrLength:=0
       end
    end
end;

function  SHA1Final(Context: TSHA1Context): TSHA1Digest;
var i: LongWord;
begin
Context.Length:= Context.Length + Context.CurrLength shl 3;
Context.Buf[Context.CurrLength]:= $80;
inc(Context.CurrLength);
if Context.CurrLength>56 then
   begin
   FillChar(Context.Buf[Context.CurrLength],64-Context.CurrLength,0);
   Context.CurrLength:= 64;
   SHA1Hash(Context);
   Context.CurrLength:=0
   end;
FillChar(Context.Buf[Context.CurrLength],56-Context.CurrLength,0);
for i:= 56 to 63 do
    Context.Buf[i] := (Context.Length shr ((63 - i) * 8)) and $FF;
SHA1Hash(Context);
move(Context.H, Result, sizeof(TSHA1Digest));
FillChar(Context, sizeof(Context), 0)
end;

end.

(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2010 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uSHA;
interface
uses SDLh;

type TSHA1Context = packed record
                    H: array[0..4] of LongWord;
                    Length, CurrLength: Int64;
                    Buf: array[0..63] of byte;
                    end;
     TSHA1Digest =  array[0..4] of LongWord;

procedure SHA1Init(var Context: TSHA1Context);
procedure SHA1Update(var Context: TSHA1Context; Buf: PByteArray; Length: LongWord);
procedure SHA1UpdateLongwords(var Context: TSHA1Context; Buf: PLongwordArray; Length: LongWord);
function  SHA1Final(Context: TSHA1Context): TSHA1Digest;

implementation

function rol(x: LongWord; y: Byte): LongWord;
begin
  rol:= (X shl y) or (X shr (32 - y))
end;

function Ft(t, b, c, d: LongWord): LongWord;
begin
case t of
      0..19: Ft := (b and c) or ((not b) and d);
     20..39: Ft :=  b xor c xor d;
     40..59: Ft := (b and c) or (b and d) or (c and d);
     else    Ft :=  b xor c xor d;
  end;
end;

function Kt(t: Byte): LongWord;
begin
  case t of
     0..19: Kt := $5A827999;
    20..39: Kt := $6ED9EBA1;
    40..59: Kt := $8F1BBCDC;
  else
    Kt := $CA62C1D6
  end;
end;


procedure SHA1Hash(var Context: TSHA1Context);
var S: array[0..4 ] of LongWord;
    W: array[0..79] of LongWord;
    i, t: LongWord;
begin
{$HINTS OFF}
move(Context.H, S, sizeof(S));
{$HINTS ON}
for i:= 0 to 15 do
    SDLNet_Write32(PLongWordArray(@Context.Buf)^[i], @W[i]);

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

procedure SHA1Update(var Context: TSHA1Context; Buf: PByteArray; Length: LongWord);
var i: Longword;
begin
for i:= 0 to Pred(Length) do
    begin
    Context.Buf[Context.CurrLength]:= Buf^[i];
    inc(Context.CurrLength);
    if Context.CurrLength = 64 then
       begin
       SHA1Hash(Context);
       inc(Context.Length, 512);
       Context.CurrLength:= 0
       end
    end
end;

procedure SHA1UpdateLongwords(var Context: TSHA1Context; Buf: PLongwordArray; Length: LongWord);
var i: Longword;
begin
    for i:= 0 to Pred(Length div 4) do
    begin
        SDLNet_Write32(Buf^[i], @Context.Buf[Context.CurrLength]);
        inc(Context.CurrLength, 4);
        if Context.CurrLength = 64 then
        begin
            SHA1Hash(Context);
            inc(Context.Length, 512);
            Context.CurrLength:= 0
        end
    end
end;

function  SHA1Final(Context: TSHA1Context): TSHA1Digest;
var i: LongWord;
begin
    Context.Length:= Context.Length + Context.CurrLength shl 3;
    Context.Buf[Context.CurrLength]:= $80;
    inc(Context.CurrLength);

    if Context.CurrLength > 56 then
    begin
        FillChar(Context.Buf[Context.CurrLength], 64 - Context.CurrLength, 0);
        Context.CurrLength:= 64;
        SHA1Hash(Context);
        Context.CurrLength:=0
    end;

    FillChar(Context.Buf[Context.CurrLength], 56 - Context.CurrLength, 0);

    for i:= 56 to 63 do
        Context.Buf[i] := (Context.Length shr ((63 - i) * 8)) and $FF;
    SHA1Hash(Context);
    for i:= 0 to 4 do
        SHA1Final[i]:= Context.H[i];
    
    FillChar(Context, sizeof(Context), 0)
end;

end.

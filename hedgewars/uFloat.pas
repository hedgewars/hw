(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2011 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uFloat;
interface

{$IFDEF FPC}
{$IFDEF ENDIAN_LITTLE}
type hwFloat = record
               isNegative: boolean;
               case byte of
               0: (Frac, Round: Longword);
               1: (QWordValue : QWord);
               end;
{$ELSE}
type hwFloat = record
               isNegative: boolean;
               case byte of
               0: (Round, Frac: Longword);
               1: (QWordValue : QWord);
               end;
{$ENDIF}

function int2hwFloat (const i: LongInt) : hwFloat; inline;

operator + (const z1, z2: hwFloat) z : hwFloat; inline;
operator - (const z1, z2: hwFloat) z : hwFloat; inline;
operator - (const z1: hwFloat) z : hwFloat; inline;

operator * (const z1, z2: hwFloat) z : hwFloat; inline;
operator * (const z1: hwFloat; const z2: LongInt) z : hwFloat; inline;
operator / (const z1: hwFloat; z2: hwFloat) z : hwFloat; inline;
operator / (const z1: hwFloat; const z2: LongInt) z : hwFloat; inline;

operator < (const z1, z2: hwFloat) b : boolean; inline;
operator > (const z1, z2: hwFloat) b : boolean; inline;

function cstr(const z: hwFloat): shortstring;
function hwRound(const t: hwFloat): LongInt; inline;
function hwAbs(const t: hwFloat): hwFloat; inline;
function hwSqr(const t: hwFloat): hwFloat; inline;
function hwSqrt(const t: hwFloat): hwFloat; inline;
function Distance(const dx, dy: hwFloat): hwFloat;
function DistanceI(const dx, dy: LongInt): hwFloat;
function AngleSin(const Angle: Longword): hwFloat;
function AngleCos(const Angle: Longword): hwFloat;
function SignAs(const num, signum: hwFloat): hwFloat; inline;
function hwSign(r: hwFloat): LongInt; inline;

{$IFDEF FPC}
{$J-}
{$ENDIF}
{$WARNINGS OFF}
const  _1div1024: hwFloat = (isNegative: false; QWordValue:     4194304);
      _1div10000: hwFloat = (isNegative: false; QWordValue:      429496);
      _1div50000: hwFloat = (isNegative: false; QWordValue:       85899);
     _1div100000: hwFloat = (isNegative: false; QWordValue:       42950);
          _1div3: hwFloat = (isNegative: false; QWordValue:  1431655766);
            hwPi: hwFloat = (isNegative: false; QWordValue: 13493037704);
       _0_000004: hwFloat = (isNegative: false; QWordValue:       17179);
       _0_000064: hwFloat = (isNegative: false; QWordValue:      274878);
         _0_0002: hwFloat = (isNegative: false; QWordValue:      858993);
         _0_0005: hwFloat = (isNegative: false; QWordValue:     2147484);
          _0_001: hwFloat = (isNegative: false; QWordValue:     4294967);
          _0_003: hwFloat = (isNegative: false; QWordValue:    12884902);
          _0_004: hwFloat = (isNegative: false; QWordValue:    17179869);
          _0_005: hwFloat = (isNegative: false; QWordValue:    21474836);
          _0_008: hwFloat = (isNegative: false; QWordValue:    34359738);
           _0_01: hwFloat = (isNegative: false; QWordValue:    42949673);
           _0_02: hwFloat = (isNegative: false; QWordValue:    85899345);
           _0_03: hwFloat = (isNegative: false; QWordValue:   128849018);
           _0_08: hwFloat = (isNegative: false; QWordValue:   343597383);
            _0_1: hwFloat = (isNegative: false; QWordValue:   429496730);
           _0_15: hwFloat = (isNegative: false; QWordValue:   644245094);
            _0_2: hwFloat = (isNegative: false; QWordValue:   858993459);
           _0_25: hwFloat = (isNegative: false; QWordValue:  1073741824);
            _0_3: hwFloat = (isNegative: false; QWordValue:  1288490189);
           _0_35: hwFloat = (isNegative: false; QWordValue:  1503238553);
          _0_375: hwFloat = (isNegative: false; QWordValue:  4294967296 * 3 div 8);
           _0_39: hwFloat = (isNegative: false; QWordValue:  1675037245);
            _0_4: hwFloat = (isNegative: false; QWordValue:  1717986918);
           _0_45: hwFloat = (isNegative: false; QWordValue:  1932735283);
            _0_5: hwFloat = (isNegative: false; QWordValue:  2147483648);
           _0_55: hwFloat = (isNegative: false; QWordValue:  2362232012);
            _0_6: hwFloat = (isNegative: false; QWordValue:  2576980377);
           _0_64: hwFloat = (isNegative: false; QWordValue:  2748779064);
            _0_7: hwFloat = (isNegative: false; QWordValue:  3006477107);
            _0_8: hwFloat = (isNegative: false; QWordValue:  3435973837);
           _0_84: hwFloat = (isNegative: false; QWordValue:  3607772528);
           _0_87: hwFloat = (isNegative: false; QWordValue:  3736621547);
            _0_9: hwFloat = (isNegative: false; QWordValue:  3865470566);
           _0_93: hwFloat = (isNegative: false; QWordValue:  3994319585);
           _0_96: hwFloat = (isNegative: false; QWordValue:  4123168604);
          _0_995: hwFloat = (isNegative: false; QWordValue:  4273492459);
          _0_999: hwFloat = (isNegative: false; QWordValue:  4290672328);
              _0: hwFloat = (isNegative: false; QWordValue:           0);
              _1: hwFloat = (isNegative: false; QWordValue:  4294967296);
            _1_5: hwFloat = (isNegative: false; QWordValue:  4294967296 * 3 div 2);
            _1_9: hwFloat = (isNegative: false; QWordValue:  8160437862);
              _2: hwFloat = (isNegative: false; QWordValue:  4294967296 * 2);
              _3: hwFloat = (isNegative: false; QWordValue:  4294967296 * 3);
              _4: hwFloat = (isNegative: false; QWordValue:  4294967296 * 4);
              _5: hwFloat = (isNegative: false; QWordValue:  4294967296 * 5);
              _6: hwFloat = (isNegative: false; QWordValue:  4294967296 * 6);
             _10: hwFloat = (isNegative: false; QWordValue:  4294967296 * 10);
             _12: hwFloat = (isNegative: false; QWordValue:  4294967296 * 12);
             _16: hwFloat = (isNegative: false; QWordValue:  4294967296 * 16);
             _19: hwFloat = (isNegative: false; QWordValue:  4294967296 * 19);
             _20: hwFloat = (isNegative: false; QWordValue:  4294967296 * 20);
             _25: hwFloat = (isNegative: false; QWordValue:  4294967296 * 25);
             _30: hwFloat = (isNegative: false; QWordValue:  4294967296 * 30);
             _40: hwFloat = (isNegative: false; QWordValue:  4294967296 * 40);
             _50: hwFloat = (isNegative: false; QWordValue:  4294967296 * 50);
             _70: hwFloat = (isNegative: false; QWordValue:  4294967296 * 70);
            _128: hwFloat = (isNegative: false; QWordValue:  4294967296 * 128);
            _256: hwFloat = (isNegative: false; QWordValue:  4294967296 * 256);
            _300: hwFloat = (isNegative: false; QWordValue:  4294967296 * 300);
            _450: hwFloat = (isNegative: false; QWordValue:  4294967296 * 450);
           _1024: hwFloat = (isNegative: false; QWordValue:  4294967296 * 1024);
           _2048: hwFloat = (isNegative: false; QWordValue:  4294967296 * 2048);
           _4096: hwFloat = (isNegative: false; QWordValue:  4294967296 * 4096);
          _10000: hwFloat = (isNegative: false; QWordValue:  4294967296 * 10000);

         cLittle: hwFloat = (isNegative: false; QWordValue:           1);
         cHHKick: hwFloat = (isNegative: false; QWordValue:    42949673);  // _0_01
{$WARNINGS ON}
{$ENDIF}

{$IFNDEF FPC}
type hwFloat = Extended;
{$ENDIF}

implementation
uses uSinTable;


{$IFDEF FPC}

function int2hwFloat (const i: LongInt) : hwFloat;
begin
int2hwFloat.isNegative:= i < 0;
int2hwFloat.Round:= abs(i);
int2hwFloat.Frac:= 0
end;

operator + (const z1, z2: hwFloat) z : hwFloat;
begin
if z1.isNegative = z2.isNegative then
   begin
   z.isNegative:= z1.isNegative;
   z.QWordValue:= z1.QWordValue + z2.QWordValue
   end
else
   if z1.QWordValue > z2.QWordValue then
      begin
      z.isNegative:= z1.isNegative;
      z.QWordValue:= z1.QWordValue - z2.QWordValue
      end else
      begin
      z.isNegative:= z2.isNegative;
      z.QWordValue:= z2.QWordValue - z1.QWordValue
      end
end;

operator - (const z1, z2: hwFloat) z : hwFloat;
begin
if z1.isNegative = z2.isNegative then
   if z1.QWordValue > z2.QWordValue then
      begin
      z.isNegative:= z1.isNegative;
      z.QWordValue:= z1.QWordValue - z2.QWordValue
      end else
      begin
      z.isNegative:= not z2.isNegative;
      z.QWordValue:= z2.QWordValue - z1.QWordValue
      end
else begin
     z.isNegative:= z1.isNegative;
     z.QWordValue:= z1.QWordValue + z2.QWordValue
     end
end;

operator - (const z1: hwFloat) z : hwFloat;
begin
z:= z1;
z.isNegative:= not z.isNegative
end;


operator * (const z1, z2: hwFloat) z : hwFloat;
begin
z.isNegative:= z1.isNegative xor z2.isNegative;
z.QWordValue:= QWord(z1.Round) * z2.Frac +
               QWord(z1.Frac) * z2.Round +
               ((QWord(z1.Frac) * z2.Frac) shr 32);
z.Round:= z.Round + QWord(z1.Round) * z2.Round;
end;

operator * (const z1: hwFloat; const z2: LongInt) z : hwFloat;
begin
z.isNegative:= z1.isNegative xor (z2 < 0);
z.QWordValue:= z1.QWordValue * abs(z2)
end;

operator / (const z1: hwFloat; z2: hwFloat) z : hwFloat;
var t: hwFloat;
begin
z.isNegative:= z1.isNegative xor z2.isNegative;
z.Round:= z1.QWordValue div z2.QWordValue;
t:= z1 - z2 * z.Round;
if t.QWordValue = 0 then
   z.Frac:= 0
else
   begin
   while ((t.QWordValue and $8000000000000000) = 0) and
         ((z2.QWordValue and $8000000000000000) = 0) do
         begin
         t.QWordValue:= t.QWordValue shl 1;
         z2.QWordValue:= z2.QWordValue shl 1
         end;
   if z2.Round > 0 then z.Frac:= (t.QWordValue) div (z2.Round)
                   else z.Frac:= 0
   end
end;

operator / (const z1: hwFloat; const z2: LongInt) z : hwFloat;
begin
z.isNegative:= z1.isNegative xor (z2 < 0);
z.QWordValue:= z1.QWordValue div abs(z2)
end;

operator < (const z1, z2: hwFloat) b : boolean;
begin
if z1.isNegative xor z2.isNegative then
   b:= z1.isNegative
else
   if z1.QWordValue = z2.QWordValue then
      b:= false
   else
      b:= (z1.QWordValue < z2.QWordValue) xor z1.isNegative
end;

operator > (const z1, z2: hwFloat) b : boolean;
begin
if z1.isNegative xor z2.isNegative then
   b:= z2.isNegative
else
   if z1.QWordValue = z2.QWordValue then
      b:= false
   else
      b:= (z1.QWordValue > z2.QWordValue) xor z2.isNegative
end;

function cstr(const z: hwFloat): shortstring;
var tmpstr: shortstring;
begin
str(z.Round, cstr);
if z.Frac <> 0 then
   begin
   str(z.Frac / $100000000:1:15, tmpstr);
   delete(tmpstr, 1, 2);
   cstr:= cstr + '.' + tmpstr
   end;
if z.isNegative then cstr:= '-' + cstr
end;

function hwRound(const t: hwFloat): LongInt;
begin
if t.isNegative then hwRound:= -(t.Round and $7FFFFFFF)
                else hwRound:= t.Round and $7FFFFFFF
end;

function hwAbs(const t: hwFloat): hwFloat;
begin
hwAbs:= t;
hwAbs.isNegative:= false
end;

function hwSqr(const t: hwFloat): hwFloat;
begin
hwSqr.isNegative:= false;
hwSqr.QWordValue:=
      ((QWord(t.Round) * t.Round) shl 32)
    + QWord(t.Round) * t.Frac * 2
    + ((QWord(t.Frac) * t.Frac) shr 32);
end;

function hwSqrt(const t: hwFloat): hwFloat;
var l, r: QWord;
    c: hwFloat;
begin
hwSqrt.isNegative:= false;

if t.Round = 0 then
   begin
   l:= t.QWordValue;
   r:= $100000000
   end else
   begin
   l:= $100000000;
   r:= t.QWordValue div 2 + $80000000; // r:= t / 2 + 0.5
   if r > $FFFFFFFFFFFF then r:= $FFFFFFFFFFFF
   end;

repeat
  c.QWordValue:= (l + r) div 2;
  if hwSqr(c).QWordValue > t.QWordValue then r:= c.QWordValue else l:= c.QWordValue
until r - l <= 1;

hwSqrt.QWordValue:= l
end;

function Distance(const dx, dy: hwFloat): hwFloat;
begin
Distance:= hwSqrt(hwSqr(dx) + hwSqr(dy))
end;

function DistanceI(const dx, dy: LongInt): hwFloat;
begin
DistanceI:= hwSqrt(int2hwFloat(sqr(dx) + sqr(dy)))
end;

function SignAs(const num, signum: hwFloat): hwFloat;
begin
SignAs.QWordValue:= num.QWordValue;
SignAs.isNegative:= signum.isNegative
end;

function hwSign(r: hwFloat): LongInt;
begin
// yes, we have negative zero for a reason
if r.isNegative then hwSign:= -1 else hwSign:= 1
end;


function AngleSin(const Angle: Longword): hwFloat;
begin
//TryDo((Angle >= 0) and (Angle <= 2048), 'Sin param exceeds limits', true);
AngleSin.isNegative:= false;
if Angle < 1024 then AngleSin.QWordValue:= SinTable[Angle]
                else AngleSin.QWordValue:= SinTable[2048 - Angle]
end;

function AngleCos(const Angle: Longword): hwFloat;
begin
//TryDo((Angle >= 0) and (Angle <= 2048), 'Cos param exceeds limits', true);
AngleCos.isNegative:= Angle > 1024;
if Angle < 1024 then AngleCos.QWordValue:= SinTable[1024 - Angle]
                else AngleCos.QWordValue:= SinTable[Angle - 1024]
end;

{$ENDIF}

end.

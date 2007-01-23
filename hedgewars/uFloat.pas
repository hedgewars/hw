(*
 * Hedgewars, a Worms style game
 * Copyright (c) 2007 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uFloat;
interface

{$IFDEF FPC}
{$ifdef FPC_LITTLE_ENDIAN}
type hwFloat = record
               isNegative: boolean;
               case byte of
               0: (Frac, Round: Longword);
               1: (QWordValue : QWord);
               end;
{$else FPC_LITTLE_ENDIAN}
type hwFloat = record
               isNegative: boolean;
               case byte of
               0: (Round, Frac: Longword);
               1: (QWordValue : QWord);
               end;
{$endif FPC_LITTLE_ENDIAN}

operator := (i: LongInt) z : hwFloat;

operator + (z1, z2: hwFloat) z : hwFloat;
operator - (z1, z2: hwFloat) z : hwFloat;
operator - (z1: hwFloat) z : hwFloat;

operator * (z1, z2: hwFloat) z : hwFloat;
operator * (z1: hwFloat; z2: LongInt) z : hwFloat;
operator / (z1, z2: hwFloat) z : hwFloat;

operator < (z1, z2: hwFloat) b : boolean;
operator > (z1, z2: hwFloat) b : boolean;

function cstr(z: hwFloat): string;
function hwRound(t: hwFloat): integer;
function hwAbs(t: hwFloat): hwFloat;
function hwSqr(t: hwFloat): hwFloat;
function hwSqrt(t: hwFloat): hwFloat;
function Distance(dx, dy: hwFloat): hwFloat;
function AngleSin(Angle: Longword): hwFloat;
function AngleCos(Angle: Longword): hwFloat;

const  _1div1024: hwFloat = (isNegative: false; QWordValue:     4194304);
      _1div10000: hwFloat = (isNegative: false; QWordValue:      429496);
      _1div50000: hwFloat = (isNegative: false; QWordValue:       85899);
     _1div100000: hwFloat = (isNegative: false; QWordValue:       42950);
          _1div3: hwFloat = (isNegative: false; QWordValue:  1431655766);
            hwPi: hwFloat = (isNegative: false; QWordValue: 13493037704);
       _0_000004: hwFloat = (isNegative: false; QWordValue:       17179);
         _0_0002: hwFloat = (isNegative: false; QWordValue:      858993);
          _0_001: hwFloat = (isNegative: false; QWordValue:     4294967);
          _0_003: hwFloat = (isNegative: false; QWordValue:    12884902);
          _0_004: hwFloat = (isNegative: false; QWordValue:    17179869);
          _0_005: hwFloat = (isNegative: false; QWordValue:    21474836);
           _0_01: hwFloat = (isNegative: false; QWordValue:    42949673);
           _0_02: hwFloat = (isNegative: false; QWordValue:    85899345);
           _0_03: hwFloat = (isNegative: false; QWordValue:   128849018);
           _0_08: hwFloat = (isNegative: false; QWordValue:   343597383);
            _0_1: hwFloat = (isNegative: false; QWordValue:   429496729);
           _0_15: hwFloat = (isNegative: false; QWordValue:   644245094);
            _0_2: hwFloat = (isNegative: false; QWordValue:   858993459);
           _0_25: hwFloat = (isNegative: false; QWordValue:  1073741824);
            _0_3: hwFloat = (isNegative: false; QWordValue:  1288490189);
           _0_35: hwFloat = (isNegative: false; QWordValue:  1503238553);
            _0_4: hwFloat = (isNegative: false; QWordValue:  1717986918);
           _0_45: hwFloat = (isNegative: false; QWordValue:  1932735283);
            _0_5: hwFloat = (isNegative: false; QWordValue:  2147483648);
           _0_55: hwFloat = (isNegative: false; QWordValue:  2362232012);
            _0_6: hwFloat = (isNegative: false; QWordValue:  2576980377);
            _0_7: hwFloat = (isNegative: false; QWordValue:  3006477107);
            _0_8: hwFloat = (isNegative: false; QWordValue:  3435973837);
           _0_84: hwFloat = (isNegative: false; QWordValue:  3607772528);
           _0_87: hwFloat = (isNegative: false; QWordValue:  3736621547);
            _0_9: hwFloat = (isNegative: false; QWordValue:  3865470566);
           _0_93: hwFloat = (isNegative: false; QWordValue:  3994319585);
           _0_96: hwFloat = (isNegative: false; QWordValue:  4123168604);
          _0_995: hwFloat = (isNegative: false; QWordValue:  4273492459);
          _0_999: hwFloat = (isNegative: false; QWordValue:  4290672328);
            _1_9: hwFloat = (isNegative: false; QWordValue:  8160437862);

         cLittle: hwFloat = (isNegative: false; QWordValue:           1);
         cHHKick: hwFloat = (isNegative: false; QWordValue:   128849018);
{$ENDIF}

{$IFNDEF FPC}
type hwFloat = Extended;
{$ENDIF}

implementation
uses uConsts;

{$IFDEF FPC}

operator := (i: LongInt) z : hwFloat;
begin
z.isNegative:= i < 0;
z.Round:= abs(i);
z.Frac:= 0
end;

operator + (z1, z2: hwFloat) z : hwFloat;
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

operator - (z1, z2: hwFloat) z : hwFloat;
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

operator - (z1: hwFloat) z : hwFloat;
begin
z:= z1;
z.isNegative:= not z.isNegative
end;


operator * (z1, z2: hwFloat) z : hwFloat;
begin
z.isNegative:= z1.isNegative xor z2.isNegative;
z.QWordValue:= QWord(z1.Round) * z2.Frac +
               QWord(z1.Frac) * z2.Round +
               ((QWord(z1.Frac) * z2.Frac) shr 32);
z.Round:= z.Round + QWord(z1.Round) * z2.Round;
end;

operator * (z1: hwFloat; z2: LongInt) z : hwFloat;
begin
z.isNegative:= z1.isNegative xor (z2 < 0);
z2:= abs(z2);
z.QWordValue:= z1.QWordValue * z2
end;

operator / (z1, z2: hwFloat) z : hwFloat;
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
   z.Frac:= (t.QWordValue) div (z2.Round)
   end
end;

operator < (z1, z2: hwFloat) b : boolean;
begin
if z1.isNegative <> z2.isNegative then
   b:= z1.isNegative
else
   if z1.QWordValue = z2.QWordValue then
      b:= false
   else
      b:= (z1.QWordValue < z2.QWordValue) xor z1.isNegative
end;

operator > (z1, z2: hwFloat) b : boolean;
begin
if z1.isNegative <> z2.isNegative then
   b:= z2.isNegative
else
   if z1.QWordValue = z2.QWordValue then
      b:= false
   else
      b:= (z1.QWordValue > z2.QWordValue) xor z2.isNegative
end;

function cstr(z: hwFloat): string;
var tmpstr: string;
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

function hwRound(t: hwFloat): integer;
begin
if t.isNegative then hwRound:= -t.Round
                else hwRound:= t.Round
end;

function hwAbs(t: hwFloat): hwFloat;
begin
hwAbs:= t;
hwAbs.isNegative:= false
end;

function hwSqr(t: hwFloat): hwFloat;
begin
hwSqr:= t * t
end;

function hwSqrt(t: hwFloat): hwFloat;
begin
hwSqrt.isNegative:= false;
hwSqrt.QWordValue:= Round(sqrt(1.0 / $100000000 * (t.QWordValue)) * $100000000)
end;

function Distance(dx, dy: hwFloat): hwFloat;
var x, y: hwFloat;
    Result: hwFloat;
begin
x:= dx * dx;
y:= dy * dy;
Result:= x + y;
Result.QWordValue:= Round(sqrt(1.0 / $100000000 * (Result.QWordValue)) * $100000000);
Distance:= Result
end;

{$INCLUDE SinTable.inc}

function AngleSin(Angle: Longword): hwFloat;
begin
AngleSin.isNegative:= false;
if Angle < 1024 then AngleSin.QWordValue:= SinTable[Angle]
                else AngleSin.QWordValue:= SinTable[2048 - Angle]
end;

function AngleCos(Angle: Longword): hwFloat;
var CosVal: Extended;
begin
AngleCos.isNegative:= Angle > 1024;
if Angle < 1024 then AngleCos.QWordValue:= SinTable[1024 - Angle]
                else AngleCos.QWordValue:= SinTable[Angle - 1024]
end;

{$ENDIF}

end.

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

unit uFloat;
(*
 * This unit provides a custom data type, hwFloat.
 *
 * hwFloat represents a fixed point number - the value and operations
 * of this numbers are independent from the hardware architecture
 * the game runs on.
 *
 * This is important for calculations that affect the course of the game
 * and would lead to different results if based on a hardware dependent
 * data type.
 *
 * Note: Not all comparisons are implemented.
 *)
interface

type HWFloat = record data: array[0..15] of byte end;

// Returns an hwFloat that represents the value of integer parameter i
function int2hwFloat (const i: LongInt) : hwFloat; 
function hwFloat2Float (const i: hwFloat) : double;

// The implemented operators

operator = (const z1, z2: hwFloat) z : boolean; 
{$IFDEF PAS2C}
operator <> (const z1, z2: hwFloat) z : boolean; 
{$ENDIF}
operator + (const z1, z2: hwFloat) z : hwFloat; 
operator - (const z1, z2: hwFloat) z : hwFloat; 
operator - (const z1: hwFloat) z : hwFloat; 

operator * (const z1, z2: hwFloat) z : hwFloat; 
operator * (const z1: hwFloat; const z2: LongInt) z : hwFloat; 
operator / (const z1: hwFloat; z2: hwFloat) z : hwFloat; 
operator / (const z1: hwFloat; const z2: LongInt) z : hwFloat; 

operator < (const z1, z2: hwFloat) b : boolean; 
operator > (const z1, z2: hwFloat) b : boolean; 


// Various functions for hwFloat (some are inlined in the resulting code for better performance)

function cstr(const z: hwFloat): shortstring; // Returns a shortstring representations of the hwFloat.
function hwRound(const t: hwFloat): LongInt;  // Does NOT really round but returns the integer representation of the hwFloat without fractional digits. (-_0_9 -> -0, _1_5 -> _1)
function hwAbs(const t: hwFloat): hwFloat;  // Returns the value of t with positive sign.
function hwSqr(const t: hwFloat): hwFloat;  // Returns the square value of parameter t.
function hwSqrt(const x: hwFloat): hwFloat;  // Returns the the positive square root of parameter t.
function Distance(const dx, dy: hwFloat): hwFloat; // Returns the distance between two points in 2-dimensional space, of which the parameters are the horizontal and vertical distance.
function SqrDistance(const dx, dy: hwFloat): hwFloat;
function DistanceI(const dx, dy: LongInt): hwFloat; // Same as above for integer parameters.
function AngleSin(const Angle: Longword): hwFloat;
function AngleCos(const Angle: Longword): hwFloat;
function vector2Angle(const x, y: hwFloat): LongInt;
function SignAs(const num, signum: hwFloat): hwFloat;  // Returns an hwFloat with the value of parameter num and the sign of signum.
function WithSign(const num: hwFloat; is_negative: boolean): hwFloat;
function hwSign(r: hwFloat): LongInt;  // Returns an integer with value 1 and sign of parameter r.
function isZero(const z: hwFloat): boolean;
function isNegative(const z: hwFloat): boolean;

implementation
uses uRust, uSinTable, uConsts;

function int2hwFloat (const i: LongInt) : hwFloat;
begin
    int2hwFloat:= hwf_new(i, 1);
end;

function hwFloat2Float (const i: hwFloat) : double;
begin
    hwFloat2Float:= hwf_to_f64(i)
end;

operator = (const z1, z2: hwFloat) z : boolean; 
begin
    z:= hwf_op_eq(z1, z2)
end;

{$IFDEF PAS2C}
operator <> (const z1, z2: hwFloat) z : boolean; 
begin
    z:= not hwf_op_eq(z1, z2)
end;
{$ENDIF}

operator + (const z1, z2: hwFloat) z : hwFloat; 
begin
    z:= hwf_op_plus(z1, z2)
end;

operator - (const z1, z2: hwFloat) z : hwFloat; 
begin
    z:= hwf_op_minus(z1, z2)
end;

function isZero(const z: hwFloat): boolean; 
begin
    isZero := hwf_is_zero(z);
end;

function isNegative(const z: hwFloat): boolean;
begin
    isNegative := hwf_is_negative(z);
end;

operator < (const z1, z2: hwFloat) b : boolean; 
begin
    b:= hwf_op_lt(z1, z2)
end;

operator > (const z1, z2: hwFloat) b : boolean; 
begin
    b:= hwf_op_gt(z1, z2)
end;

operator - (const z1: hwFloat) z : hwFloat; 
begin
    z:= hwf_op_neg(z1)
end;


operator * (const z1, z2: hwFloat) z : hwFloat; 
begin
    z:= hwf_op_mul(z1, z2)
end;

operator * (const z1: hwFloat; const z2: LongInt) z : hwFloat; 
begin
    z:= hwf_op_mul_int(z1, z2)
end;

operator / (const z1: hwFloat; z2: hwFloat) z : hwFloat; 
begin
    z:= hwf_op_div(z1, z2)
end;

operator / (const z1: hwFloat; const z2: LongInt) z : hwFloat; 
begin
    z:= hwf_op_div_int(z1, z2)
end;

function cstr(const z: hwFloat): shortstring;
begin
    cstr:= hwf_to_str(z)
end;

function hwRound(const t: hwFloat): LongInt;
begin
    hwRound:= hwf_round(t)
end;

function hwAbs(const t: hwFloat): hwFloat;
begin
    hwAbs:= hwf_abs(t)
end;

function hwSqr(const t: hwFloat): hwFloat; 
begin
    hwSqr:= hwf_sqr(t)
end;

function hwSqrt(const x: hwFloat): hwFloat;
begin
    hwSqrt:= hwf_sqrt(x);
end;

function Distance(const dx, dy: hwFloat): hwFloat;
begin
    Distance:= hwf_distance(dx, dy)
end;

function SqrDistance(const dx, dy: hwFloat): hwFloat;
begin
    SqrDistance:= hwf_sqr_distance(dx, dy)
end;

function DistanceI(const dx, dy: LongInt): hwFloat;
begin
    DistanceI:= hwf_sqrt(hwf_new(sqr(dx) + sqr(dy), 1))
end;

function SignAs(const num, signum: hwFloat): hwFloat;
begin
    SignAs:= hwf_sign_as(num, signum)
end;

function WithSign(const num: hwFloat; is_negative: boolean): hwFloat;
begin
    WithSign:= hwf_with_sign(num, is_negative)
end;

function hwSign(r: hwFloat): LongInt;
begin
    hwSign:= hwf_signum(r)
end;

function AngleSin(const Angle: Longword): hwFloat;
begin
//TryDo((Angle >= 0) and (Angle <= 2048), 'Sin param exceeds limits', true);
if Angle < 1024 then
    AngleSin:= hwf_raw(false, SinTable[Angle])
else
    AngleSin:= hwf_raw(false, SinTable[2048 - Angle])
end;

function AngleCos(const Angle: Longword): hwFloat;
begin
//TryDo((Angle >= 0) and (Angle <= 2048), 'Cos param exceeds limits', true);
if Angle < 1024 then
    AngleCos:= hwf_raw(false, SinTable[1024 - Angle])
else
    AngleCos:= hwf_raw(Angle > 1024, SinTable[Angle - 1024])
end;

function vector2Angle(const x, y: hwFloat): LongInt;
var d, nf: hwFloat;
    l, r, c, oc: Longword;
begin
    d:= _1 / hwf_distance(x, y);

    nf:= hwAbs(y * d);

    l:= 0;
    r:= 1024;
    c:= 0;

    repeat
        oc:= c;

        c:= (l + r) shr 1;

        if nf < hwf_raw(false, SinTable[c]) then
            r:= c
        else
            l:= c;

    until (oc = c);

    if hwf_is_negative(x) then c:= 2048 - c;
    if hwf_is_negative(y) then c:= - c;

    vector2Angle:= c
end;

end.

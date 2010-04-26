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

unit uRandom;
interface
uses uFloat;
{$INCLUDE "config.inc"}

procedure initModule;
procedure freeModule;

procedure SetRandomSeed(Seed: shortstring);
function  GetRandom: hwFloat; overload;
function  GetRandom(m: LongWord): LongWord; overload;
function  rndSign(num: hwFloat): hwFloat;
{$IFDEF DEBUGFILE}
procedure DumpBuffer;
{$ENDIF}

implementation
uses uMisc{$IFDEF DEBUGFILE},uConsole{$ENDIF};

var cirbuf: array[0..63] of Longword;
    n: byte;

function GetNext: Longword;
begin
n:= (n + 1) and $3F;
cirbuf[n]:=
           (cirbuf[(n + 40) and $3F] +           {n - 24 mod 64}
            cirbuf[(n +  9) and $3F])            {n - 55 mod 64}
            and $7FFFFFFF;                       {mod 2^31}

GetNext:= cirbuf[n]
end;

procedure SetRandomSeed(Seed: shortstring);
var i: Longword;
begin
n:= 54;

if Length(Seed) > 54 then Seed:= copy(Seed, 1, 54); // not 55 to ensure we have odd numbers in cirbuf

for i:= 0 to Pred(Length(Seed)) do
    cirbuf[i]:= byte(Seed[i + 1]);

for i:= Length(Seed) to 54 do
    cirbuf[i]:= $A98765 + (cNetProtoVersion * 2); // odd number

for i:= 0 to 1023 do GetNext
end;

function GetRandom: hwFloat;
begin
GetNext;
GetRandom.isNegative:= false;
GetRandom.QWordValue:= GetNext
end;

function GetRandom(m: LongWord): LongWord;
begin
TryDo((m > 0),'GetRandom(0) called! Please report this to the developers!',true);
GetNext;
GetRandom:= GetNext mod m
end;

function rndSign(num: hwFloat): hwFloat;
begin
num.isNegative:= odd(GetNext);
rndSign:= num
end;

{$IFDEF DEBUGFILE}
procedure DumpBuffer;
var i: LongInt;
begin
for i:= 0 to 63 do
    AddFileLog('[' + inttostr(i) + '] = ' + inttostr(cirbuf[i]))
end;
{$ENDIF}

procedure initModule;
begin
    n:= 54;
    FillChar(cirbuf, 64*sizeof(Longword), 0);
end;

procedure freeModule;
begin

end;

end.

{$INCLUDE "options.inc"}
unit uUtils;

interface
uses uTypes, uFloat, GLunit;

procedure SplitBySpace(var a, b: shortstring);
procedure SplitByChar(var a, b: ansistring; c: char);

function  EnumToStr(const en : TGearType) : shortstring; overload;
function  EnumToStr(const en : TSound) : shortstring; overload;
function  EnumToStr(const en : TAmmoType) : shortstring; overload;
function  EnumToStr(const en : THogEffect) : shortstring; overload;

function  Min(a, b: LongInt): LongInt; inline;
function  Max(a, b: LongInt): LongInt; inline;

function  IntToStr(n: LongInt): shortstring;
function  FloatToStr(n: hwFloat): shortstring;

function  DxDy2Angle(const _dY, _dX: hwFloat): GLfloat;
function  DxDy2Angle32(const _dY, _dX: hwFloat): LongInt;
function  DxDy2AttackAngle(const _dY, _dX: hwFloat): LongInt;

procedure SetLittle(var r: hwFloat);

function  Str2PChar(const s: shortstring): PChar;
function  DecodeBase64(s: shortstring): shortstring;

function  isPowerOf2(i: Longword): boolean;
function  toPowerOf2(i: Longword): Longword; inline;

function  endian(independent: LongWord): LongWord; inline;

function  CheckCJKFont(s: ansistring; font: THWFont): THWFont;

{$IFDEF DEBUGFILE}
procedure AddFileLog(s: shortstring);
{$ENDIF}

function CheckNoTeamOrHH: boolean; inline;

procedure initModule;
procedure freeModule;

function  GetLaunchX(at: TAmmoType; dir: LongInt; angle: LongInt): LongInt;
function  GetLaunchY(at: TAmmoType; angle: LongInt): LongInt;

implementation
uses typinfo, Math, uConsts, uVariables, SysUtils;

var
{$IFDEF DEBUGFILE}
    f: textfile;
{$ENDIF}

// should this include "strtolower()" for the split string?
procedure SplitBySpace(var a, b: shortstring);
var i, t: LongInt;
begin
i:= Pos(' ', a);
if i > 0 then
    begin
    for t:= 1 to Pred(i) do
        if (a[t] >= 'A')and(a[t] <= 'Z') then Inc(a[t], 32);
    b:= copy(a, i + 1, Length(a) - i);
    byte(a[0]):= Pred(i)
    end else b:= '';
end;

procedure SplitByChar(var a, b: ansistring; c: char);
var i: LongInt;
begin
i:= Pos(c, a);
if i > 0 then
    begin
    b:= copy(a, i + 1, Length(a) - i);
    setlength(a, Pred(i));
    end else b:= '';
end;

function EnumToStr(const en : TGearType) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TGearType), ord(en))
end;

function EnumToStr(const en : TSound) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TSound), ord(en))
end;

function EnumToStr(const en : TAmmoType) : shortstring; overload;
begin
EnumToStr:= GetEnumName(TypeInfo(TAmmoType), ord(en))
end;

function EnumToStr(const en: THogEffect) : shortstring; overload;
begin
    EnumToStr := GetEnumName(TypeInfo(THogEffect), ord(en))
end;


function Min(a, b: LongInt): LongInt;
begin
if a < b then Min:= a else Min:= b
end;

function Max(a, b: LongInt): LongInt;
begin
if a > b then Max:= a else Max:= b
end;


function IntToStr(n: LongInt): shortstring;
begin
str(n, IntToStr)
end;

function FloatToStr(n: hwFloat): shortstring;
begin
FloatToStr:= cstr(n) + '_' + inttostr(Lo(n.QWordValue))
end;


function DxDy2Angle(const _dY, _dX: hwFloat): GLfloat;
var dY, dX: Extended;
begin
dY:= _dY.QWordValue / $100000000;
if _dY.isNegative then dY:= - dY;
dX:= _dX.QWordValue / $100000000;
if _dX.isNegative then dX:= - dX;
DxDy2Angle:= arctan2(dY, dX) * 180 / pi
end;

function DxDy2Angle32(const _dY, _dX: hwFloat): LongInt;
const _16divPI: Extended = 16/pi;
var dY, dX: Extended;
begin
dY:= _dY.QWordValue / $100000000;
if _dY.isNegative then dY:= - dY;
dX:= _dX.QWordValue / $100000000;
if _dX.isNegative then dX:= - dX;
DxDy2Angle32:= trunc(arctan2(dY, dX) * _16divPI) and $1f
end;

function DxDy2AttackAngle(const _dY, _dX: hwFloat): LongInt;
const MaxAngleDivPI: Extended = cMaxAngle/pi;
var dY, dX: Extended;
begin
dY:= _dY.QWordValue / $100000000;
if _dY.isNegative then dY:= - dY;
dX:= _dX.QWordValue / $100000000;
if _dX.isNegative then dX:= - dX;
DxDy2AttackAngle:= trunc(arctan2(dY, dX) * MaxAngleDivPI)
end;


procedure SetLittle(var r: hwFloat);
begin
r:= SignAs(cLittle, r)
end;


function isPowerOf2(i: Longword): boolean;
begin
if i = 0 then exit(true);
while not odd(i) do i:= i shr 1;
isPowerOf2:= (i = 1)
end;

function toPowerOf2(i: Longword): Longword;
begin
toPowerOf2:= 1;
while (toPowerOf2 < i) do toPowerOf2:= toPowerOf2 shl 1
end;


function DecodeBase64(s: shortstring): shortstring;
const table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
var i, t, c: Longword;
begin
c:= 0;
for i:= 1 to Length(s) do
    begin
    t:= Pos(s[i], table);
    if s[i] = '=' then inc(c);
    if t > 0 then byte(s[i]):= t - 1 else byte(s[i]):= 0
    end;

i:= 1;
t:= 1;
while i <= length(s) do
    begin
    DecodeBase64[t    ]:= char((byte(s[i    ]) shl 2) or (byte(s[i + 1]) shr 4));
    DecodeBase64[t + 1]:= char((byte(s[i + 1]) shl 4) or (byte(s[i + 2]) shr 2));
    DecodeBase64[t + 2]:= char((byte(s[i + 2]) shl 6) or (byte(s[i + 3])      ));
    inc(t, 3);
    inc(i, 4)
    end;

if c < 3 then t:= t - c;

byte(DecodeBase64[0]):= t - 1
end;


function Str2PChar(const s: shortstring): PChar;
const CharArray: array[byte] of Char = '';
begin
CharArray:= s;
CharArray[Length(s)]:= #0;
Str2PChar:= @CharArray
end;


function endian(independent: LongWord): LongWord; inline;
begin
{$IFDEF ENDIAN_LITTLE}
endian:= independent;
{$ELSE}
endian:= (((independent and $FF000000) shr 24) or
          ((independent and $00FF0000) shr 8) or
          ((independent and $0000FF00) shl 8) or
          ((independent and $000000FF) shl 24))
{$ENDIF}
end;


{$IFDEF DEBUGFILE}
procedure AddFileLog(s: shortstring);
begin
writeln(f, GameTicks: 6, ': ', s);
flush(f)
end;
{$ENDIF}


function CheckCJKFont(s: ansistring; font: THWFont): THWFont;
var l, i : LongInt;
    u: WideChar;
    tmpstr: array[0..256] of WideChar;
begin

{$IFNDEF IPHONEOS}
// remove chinese fonts for now
if (font >= CJKfnt16) or (length(s) = 0) then
{$ENDIF}
    exit(font);

l:= Utf8ToUnicode(@tmpstr, Str2PChar(s), length(s))-1;
i:= 0;
while i < l do
    begin
    u:= tmpstr[i];
    if (#$2E80  <= u) and  (
                           (u <= #$2FDF )  or // CJK Radicals Supplement / Kangxi Radicals
       ((#$2FF0  <= u) and (u <= #$303F))  or // Ideographic Description Characters / CJK Radicals Supplement
       ((#$31C0  <= u) and (u <= #$31EF))  or // CJK Strokes
       ((#$3200  <= u) and (u <= #$4DBF))  or // Enclosed CJK Letters and Months / CJK Compatibility / CJK Unified Ideographs Extension A
       ((#$4E00  <= u) and (u <= #$9FFF))  or // CJK Unified Ideographs
       ((#$F900  <= u) and (u <= #$FAFF))  or // CJK Compatibility Ideographs
       ((#$FE30  <= u) and (u <= #$FE4F)))    // CJK Compatibility Forms
       then exit(THWFont( ord(font) + ((ord(High(THWFont))+1) div 2) ));
    inc(i)
    end;
exit(font);
(* two more to check. pascal WideChar is only 16 bit though
       ((#$20000 <= u) and (u >= #$2A6DF)) or // CJK Unified Ideographs Extension B
       ((#$2F800 <= u) and (u >= #$2FA1F)))   // CJK Compatibility Ideographs Supplement *)
end;


function GetLaunchX(at: TAmmoType; dir: LongInt; angle: LongInt): LongInt;
begin
    if (Ammoz[at].ejectX <> 0) or (Ammoz[at].ejectY <> 0) then
        GetLaunchX:= sign(dir) * (8 + hwRound(AngleSin(angle) * Ammoz[at].ejectX) + hwRound(AngleCos(angle) * Ammoz[at].ejectY))
    else
        GetLaunchX:= 0
end;

function GetLaunchY(at: TAmmoType; angle: LongInt): LongInt;
begin
    if (Ammoz[at].ejectX <> 0) or (Ammoz[at].ejectY <> 0) then
        GetLaunchY:= hwRound(AngleSin(angle) * Ammoz[at].ejectY) - hwRound(AngleCos(angle) * Ammoz[at].ejectX) - 2
    else
        GetLaunchY:= 0
end;

function CheckNoTeamOrHH: boolean;
var bRes: boolean;
begin
CheckNoTeamOrHH:= (CurrentTeam = nil) or (CurrentHedgehog^.Gear = nil);
end;

procedure initModule;
{$IFDEF DEBUGFILE}{$IFNDEF IPHONEOS}var i: LongInt;{$ENDIF}{$ENDIF}
begin
{$IFDEF DEBUGFILE}
{$I-}
{$IFDEF IPHONEOS}
    Assign(f,'../Documents/hw-' + cLogfileBase + '.log');
    Rewrite(f);
{$ELSE}
    if (ParamStr(1) <> '') and (ParamStr(2) <> '') then
        if (ParamCount <> 3) and (ParamCount <> cDefaultParamNum) then
        begin
            for i:= 0 to 7 do
            begin
                assign(f, ExtractFileDir(ParamStr(2)) + '/' + cLogfileBase + inttostr(i) + '.log');
                rewrite(f);
                if IOResult = 0 then break;
            end;
            if IOResult <> 0 then f:= stderr; // if everything fails, write to stderr
        end
        else
        begin
            for i:= 0 to 7 do
            begin
                assign(f, ParamStr(1) + '/Logs/' + cLogfileBase + inttostr(i) + '.log');
                rewrite(f);
                if IOResult = 0 then break;
            end;
            if IOResult <> 0 then f:= stderr; // if everything fails, write to stderr
        end
    else
        f:= stderr;
{$ENDIF}
{$I+}
{$ENDIF}

end;

procedure freeModule;
begin
    recordFileName:= '';

{$IFDEF DEBUGFILE}
    writeln(f, 'halt at ', GameTicks, ' ticks. TurnTimeLeft = ', TurnTimeLeft);
    flush(f);
    close(f);
{$ENDIF}
end;

end.
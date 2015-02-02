unit uFLUtils;
interface

function str2PChar(const s: shortstring): PChar;
function intToStr(n: LongInt): shortstring;
function strToInt(s: shortstring): LongInt;
function midStr(s: shortstring; pos: byte): shortstring;
procedure underScore2Space(var s: shortstring);
function readInt(name, input: shortstring; var value: LongInt): boolean;
function readBool(name, input: shortstring; var value: boolean): boolean;

implementation

var
    str2PCharBuffer: array[0..255] of char;

function str2PChar(const s: shortstring): PChar;
var i: Integer;
begin
   for i:= 1 to Length(s) do
      begin
      str2PCharBuffer[i - 1] := s[i];
      end;
   str2PCharBuffer[Length(s)]:= #0;
   str2PChar:= @(str2PCharBuffer[0]);
end;

function intToStr(n: LongInt): shortstring;
begin
    str(n, intToStr)
end;

function strToInt(s: shortstring): LongInt;
begin
val(s, strToInt);
end;

function midStr(s: shortstring; pos: byte): shortstring;
begin
    midStr:= copy(s, pos, length(s) - pos + 1)
end;

procedure underScore2Space(var s: shortstring);
var i: LongInt;
begin
    for i:= length(s) downto 1 do
        if s[i] = '_' then s[i]:= ' '
end;

function readInt(name, input: shortstring; var value: LongInt): boolean;
var l: LongInt;
begin
    name:= name + '=';
    l:= length(name);

    if copy(input, 1, l) = name then
    begin
        value:= strToInt(midStr(input, l + 1));
        readInt:= true
    end
    else
        readInt:= false
end;

function readBool(name, input: shortstring; var value: boolean): boolean;
var l: LongInt;
begin
    name:= name + '=';
    l:= length(name);

    if copy(input, 1, l) = name then
    begin
        value:= (length(input) > l) and (input[l + 1] <> 'f');
        readBool:= true
    end
    else
        readBool:= false
end;

end.

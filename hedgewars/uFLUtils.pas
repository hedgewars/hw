unit uFLUtils;
interface

function str2PChar(const s: shortstring): PChar;
function intToStr(n: LongInt): shortstring;
function midStr(s: shortstring; pos: byte): shortstring;
procedure underScore2Space(var s: shortstring);

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

end.

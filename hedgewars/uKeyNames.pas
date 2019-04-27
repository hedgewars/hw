(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2019 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uKeyNames;
interface
uses uConsts;

type TKeyNames = array [0..cKeyMaxIndex] of string[15];

procedure populateKeyNames(var KeyArray: TKeyNames);
// procedure generateKeyNames(); // DEBUG (see below)

implementation

uses uPhysFSLayer, uUtils, uVariables, uTypes, uConsole;

procedure populateKeyNames(var KeyArray: TKeyNames);
var f: PfsFile;
    l, keyname, tmp: shortstring;
    i, scancode: LongInt;
begin
(*
 KeyArray is a mapping from SDL scancodes to Hedgewars key identifiers.
 Hedgewars key identifiers are strings with a maximum length of 15
 and are used internally to identify keys in the engine and in settings.ini.
*)

(* Key identifiers are read from an RFC 4180-compliant CSV file.
- 1st column: SDL scancode
- 2nd column: Hedgewars key ID *)
if pfsExists(cPathz[ptMisc]+'/keys.csv') then
    begin
    f:= pfsOpenRead(cPathz[ptMisc]+'/keys.csv');
    l:= '';
    pfsReadLn(f, l);
    while (not pfsEOF(f)) and (l <> '') do
        begin
        tmp:= '';
        i:= 1;
        while (i <= length(l)) and (l[i] <> ',') do
            begin
            tmp:= tmp + l[i];
            inc(i)
            end;
        scancode:= StrToInt(tmp);

        if i < length(l) then
            begin
            keyname:= copy(l, i + 1, length(l) - i);
            if (keyname[1] = '"') and (keyname[length(keyname)] = '"') then
                keyname:= copy(keyname, 2, length(keyname) - 2)
            else
                keyname:= copy(keyname, 1, length(keyname) - 1);
            end;

        pfsReadLn(f, l);
        KeyArray[scancode]:= keyname;
        end;

    pfsClose(f)
    end
else
    begin
    WriteLnToConsole('misc/keys.csv file not found');
    AddFileLog('misc/keys.csv file not found');
    halt(haltStartupError);
    end;

// generateKeyNames(); // DEBUG (see below)
end;

(*
The Hedgewars key identifiers were obtained with the following algorithm:

Basically:
- For each SDL scancode, do:
   - Take the printable SDL scancode key name (with SDL_GetScancodeName)
   - Replace spaces with underscores
   - Lowercase it
   - Cap string length to 15 characters
- Manually fix duplicates

See also:

https://wiki.libsdl.org/SDLScancodeLookup
https://wiki.libsdl.org/SDL_Scancode

NOTE: For compability reasons, existing identifiers should not be renamed.

*)

(* DEBUG
   Uncomment this to generate a list of key names in
   CSV format (RFC 4180) and print it out on console.
   Don't forget to fix duplicates! *)
(*
procedure generateKeyNames();
var i, t: LongInt;
s, s2: shortstring;
begin
    for i := 0 to cKeyMaxIndex - 5 do
        begin
        s := shortstring(SDL_GetScancodeName(TSDL_Scancode(i)));
        for t := 1 to Length(s) do
            if s[t] = ' ' then
                s[t] := '_';
        s2:= copy(s, 1, 15);
        if s2 = '"' then
            WriteLnToConsole(IntToStr(i)+',"\""')
        else if s2 <> '' then
            WriteLnToConsole(IntToStr(i)+',"'+LowerCase(s2)+'"');
        end;
end;
*)

end.

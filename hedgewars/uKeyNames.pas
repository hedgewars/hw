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

procedure populateKeyNames(var KeyArray: TKeyNames);
begin
(*
 This is a mapping from SDL scancodes to Hedgewars key identifiers.
 Hedgewars key identifiers are strings with a maximum length of 15
 and are used internally to identify keys in the engine and in settings.ini.
*)
    KeyArray[4] := 'a';
    KeyArray[5] := 'b';
    KeyArray[6] := 'c';
    KeyArray[7] := 'd';
    KeyArray[8] := 'e';
    KeyArray[9] := 'f';
    KeyArray[10] := 'g';
    KeyArray[11] := 'h';
    KeyArray[12] := 'i';
    KeyArray[13] := 'j';
    KeyArray[14] := 'k';
    KeyArray[15] := 'l';
    KeyArray[16] := 'm';
    KeyArray[17] := 'n';
    KeyArray[18] := 'o';
    KeyArray[19] := 'p';
    KeyArray[20] := 'q';
    KeyArray[21] := 'r';
    KeyArray[22] := 's';
    KeyArray[23] := 't';
    KeyArray[24] := 'u';
    KeyArray[25] := 'v';
    KeyArray[26] := 'w';
    KeyArray[27] := 'x';
    KeyArray[28] := 'y';
    KeyArray[29] := 'z';
    KeyArray[30] := '1';
    KeyArray[31] := '2';
    KeyArray[32] := '3';
    KeyArray[33] := '4';
    KeyArray[34] := '5';
    KeyArray[35] := '6';
    KeyArray[36] := '7';
    KeyArray[37] := '8';
    KeyArray[38] := '9';
    KeyArray[39] := '0';
    KeyArray[40] := 'return';
    KeyArray[41] := 'escape';
    KeyArray[42] := 'backspace';
    KeyArray[43] := 'tab';
    KeyArray[44] := 'space';
    KeyArray[45] := '-';
    KeyArray[46] := '=';
    KeyArray[47] := '[';
    KeyArray[48] := ']';
    KeyArray[49] := '\';
    KeyArray[50] := '#';
    KeyArray[51] := ';';
    KeyArray[52] := '''';
    KeyArray[53] := '`';
    KeyArray[54] := ',';
    KeyArray[55] := '.';
    KeyArray[56] := '/';
    KeyArray[57] := 'capslock';
    KeyArray[58] := 'f1';
    KeyArray[59] := 'f2';
    KeyArray[60] := 'f3';
    KeyArray[61] := 'f4';
    KeyArray[62] := 'f5';
    KeyArray[63] := 'f6';
    KeyArray[64] := 'f7';
    KeyArray[65] := 'f8';
    KeyArray[66] := 'f9';
    KeyArray[67] := 'f10';
    KeyArray[68] := 'f11';
    KeyArray[69] := 'f12';
    KeyArray[70] := 'printscreen';
    KeyArray[71] := 'scrolllock';
    KeyArray[72] := 'pause';
    KeyArray[73] := 'insert';
    KeyArray[74] := 'home';
    KeyArray[75] := 'pageup';
    KeyArray[76] := 'delete';
    KeyArray[77] := 'end';
    KeyArray[78] := 'pagedown';
    KeyArray[79] := 'right';
    KeyArray[80] := 'left';
    KeyArray[81] := 'down';
    KeyArray[82] := 'up';
    KeyArray[83] := 'numlock';
    KeyArray[84] := 'keypad_/';
    KeyArray[85] := 'keypad_*';
    KeyArray[86] := 'keypad_-';
    KeyArray[87] := 'keypad_+';
    KeyArray[88] := 'keypad_enter';
    KeyArray[89] := 'keypad_1';
    KeyArray[90] := 'keypad_2';
    KeyArray[91] := 'keypad_3';
    KeyArray[92] := 'keypad_4';
    KeyArray[93] := 'keypad_5';
    KeyArray[94] := 'keypad_6';
    KeyArray[95] := 'keypad_7';
    KeyArray[96] := 'keypad_8';
    KeyArray[97] := 'keypad_9';
    KeyArray[98] := 'keypad_0';
    KeyArray[99] := 'keypad_.';
    KeyArray[101] := 'menu';
    KeyArray[102] := 'power';
    KeyArray[103] := 'keypad_=';
    KeyArray[104] := 'f13';
    KeyArray[105] := 'f14';
    KeyArray[106] := 'f15';
    KeyArray[107] := 'f16';
    KeyArray[108] := 'f17';
    KeyArray[109] := 'f18';
    KeyArray[110] := 'f19';
    KeyArray[111] := 'f20';
    KeyArray[112] := 'f21';
    KeyArray[113] := 'f22';
    KeyArray[114] := 'f23';
    KeyArray[115] := 'f24';
    KeyArray[116] := 'execute';
    KeyArray[117] := 'help';
    KeyArray[118] := 'menu';
    KeyArray[119] := 'select';
    KeyArray[120] := 'stop';
    KeyArray[121] := 'again';
    KeyArray[122] := 'undo';
    KeyArray[123] := 'cut';
    KeyArray[124] := 'copy';
    KeyArray[125] := 'paste';
    KeyArray[126] := 'find';
    KeyArray[127] := 'mute';
    KeyArray[128] := 'volumeup';
    KeyArray[129] := 'volumedown';
    KeyArray[133] := 'keypad_,';
    KeyArray[134] := 'keypad_=_(as400';
    KeyArray[153] := 'alterase';
    KeyArray[154] := 'sysreq';
    KeyArray[155] := 'cancel';
    KeyArray[156] := 'clear';
    KeyArray[157] := 'prior';
    KeyArray[158] := 'return2';
    KeyArray[159] := 'separator';
    KeyArray[160] := 'out';
    KeyArray[161] := 'oper';
    KeyArray[162] := 'clear_/_again';
    KeyArray[163] := 'crsel';
    KeyArray[164] := 'exsel';
    KeyArray[176] := 'keypad_00';
    KeyArray[177] := 'keypad_000';
    KeyArray[178] := 'thousandssepara';
    KeyArray[179] := 'decimalseparato';
    KeyArray[180] := 'currencyunit';
    KeyArray[181] := 'currencysubunit';
    KeyArray[182] := 'keypad_(';
    KeyArray[183] := 'keypad_)';
    KeyArray[184] := 'keypad_{';
    KeyArray[185] := 'keypad_}';
    KeyArray[186] := 'keypad_tab';
    KeyArray[187] := 'keypad_backspac';
    KeyArray[188] := 'keypad_a';
    KeyArray[189] := 'keypad_b';
    KeyArray[190] := 'keypad_c';
    KeyArray[191] := 'keypad_d';
    KeyArray[192] := 'keypad_e';
    KeyArray[193] := 'keypad_f';
    KeyArray[194] := 'keypad_xor';
    KeyArray[195] := 'keypad_^';
    KeyArray[196] := 'keypad_%';
    KeyArray[197] := 'keypad_<';
    KeyArray[198] := 'keypad_>';
    KeyArray[199] := 'keypad_&';
    KeyArray[200] := 'keypad_&&';
    KeyArray[201] := 'keypad_|';
    KeyArray[202] := 'keypad_||';
    KeyArray[203] := 'keypad_:';
    KeyArray[204] := 'keypad_#';
    KeyArray[205] := 'keypad_space';
    KeyArray[206] := 'keypad_@';
    KeyArray[207] := 'keypad_!';
    KeyArray[208] := 'keypad_memstore';
    KeyArray[209] := 'keypad_memrecal';
    KeyArray[210] := 'keypad_memclear';
    KeyArray[211] := 'keypad_memadd';
    KeyArray[212] := 'keypad_memsubtr';
    KeyArray[213] := 'keypad_memmulti';
    KeyArray[214] := 'keypad_memdivid';
    KeyArray[215] := 'keypad_+/-';
    KeyArray[216] := 'keypad_clear';
    KeyArray[217] := 'keypad_clearent';
    KeyArray[218] := 'keypad_binary';
    KeyArray[219] := 'keypad_octal';
    KeyArray[220] := 'keypad_decimal';
    KeyArray[221] := 'keypad_hexadeci';
    KeyArray[224] := 'left_ctrl';
    KeyArray[225] := 'left_shift';
    KeyArray[226] := 'left_alt';
    KeyArray[227] := 'left_gui';
    KeyArray[228] := 'right_ctrl';
    KeyArray[229] := 'right_shift';
    KeyArray[230] := 'right_alt';
    KeyArray[231] := 'right_gui';
    KeyArray[257] := 'modeswitch';
    KeyArray[258] := 'audionext';
    KeyArray[259] := 'audioprev';
    KeyArray[260] := 'audiostop';
    KeyArray[261] := 'audioplay';
    KeyArray[262] := 'audiomute';
    KeyArray[263] := 'mediaselect';
    KeyArray[264] := 'www';
    KeyArray[265] := 'mail';
    KeyArray[266] := 'calculator';
    KeyArray[267] := 'computer';
    KeyArray[268] := 'ac_search';
    KeyArray[269] := 'ac_home';
    KeyArray[270] := 'ac_back';
    KeyArray[271] := 'ac_forward';
    KeyArray[272] := 'ac_stop';
    KeyArray[273] := 'ac_refresh';
    KeyArray[274] := 'ac_bookmarks';
    KeyArray[275] := 'brightnessdown';
    KeyArray[276] := 'brightnessup';
    KeyArray[277] := 'displayswitch';
    KeyArray[278] := 'kbdillumtoggle';
    KeyArray[279] := 'kbdillumdown';
    KeyArray[280] := 'kbdillumup';
    KeyArray[281] := 'eject';
    KeyArray[282] := 'sleep';
    KeyArray[283] := 'app1';
    KeyArray[284] := 'app2';
    KeyArray[285] := 'audiorewind';
    KeyArray[286] := 'audiofastforwar';

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

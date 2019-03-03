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

unit uScript;
(*
 * This unit defines, implements and registers functions and
 * variables/constants bindings for usage in Lua scripts.
 *
 * Please keep https://hedgewars.org/kb/LuaAPI up to date!
 *
 * Note: If you add a new function, make sure to test if _all_ parameters
 *       work as intended! (Especially conversions errors can sneak in
 *       unnoticed and render the parameter useless!)
 *)
interface

procedure ScriptPrintStack;
procedure ScriptClearStack;

function ScriptLoad(name : shortstring; mustExist : boolean): boolean;
procedure ScriptOnPreviewInit;
procedure ScriptOnGameInit;
procedure ScriptOnScreenResize;
procedure ScriptSetInteger(name : shortstring; value : LongInt);
procedure ScriptSetString(name : shortstring; value : shortstring);
procedure ScriptSetMapGlobals;

procedure ScriptCall(fname : shortstring);
function ScriptCall(fname : shortstring; par1: LongInt) : LongInt;
function ScriptCall(fname : shortstring; par1, par2: LongInt) : LongInt;
function ScriptCall(fname : shortstring; par1, par2, par3: LongInt) : LongInt;
function ScriptCall(fname : shortstring; par1, par2, par3, par4 : LongInt) : LongInt;
function ScriptExists(fname : shortstring) : boolean;

procedure LuaParseString(s: shortString);

//function ParseCommandOverride(key, value : shortstring) : shortstring;  This did not work out well

procedure initModule;
procedure freeModule;

implementation

uses LuaPas,
    uConsole,
    uConsts,
    uGears,
    uGearsList,
    uGearsUtils,
    uFloat,
    uWorld,
    uAmmos,
    uTeams,
    uSound,
    uChat,
    uStats,
    uStore,
    uRandom,
    uTypes,
    uVariables,
    uCommands,
    uCaptions,
    uDebug,
    uCollisions,
    uRenderUtils,
    uTextures,
    uLandGraphics,
    uUtils,
    uIO,
    uVisualGearsList,
    uGearsHandlersMess,
    uPhysFSLayer,
    uLocale,
    SDLh
{$IFNDEF PAS2C}
    , typinfo
{$ENDIF}
    ;

var luaState : Plua_State;
    ScriptAmmoLoadout : shortstring;
    ScriptAmmoProbability : shortstring;
    ScriptAmmoDelay : shortstring;
    ScriptAmmoReinforcement : shortstring;
    ScriptLoaded : boolean;
    PointsBuffer: shortstring;
    PrevCursorX, PrevCursorY: LongInt;
    PendingTurnTimeLeft, PendingReadyTimeLeft: LongWord;
    isPendingTurnTimeLeft, isPendingReadyTimeLeft: boolean;

{$IFDEF USE_LUA_SCRIPT}
procedure ScriptPrepareAmmoStore; forward;
procedure ScriptApplyAmmoStore; forward;
procedure ScriptSetAmmo(ammo : TAmmoType; count, probability, delay, reinforcement: Byte); forward;
procedure ScriptSetAmmoDelay(ammo : TAmmoType; delay: LongWord); forward;

var LuaDebugInfo: lua_Debug;

procedure SetGlobals; forward;
procedure GetGlobals; forward;
procedure LuaParseString(s: shortString);
begin
    SetGlobals;
    AddFileLog('[Lua] input string: ' + s);
    AddChatString(#3 + '[Lua] > ' + s);
    if luaL_dostring(luaState, Str2PChar(s)) <> 0 then
        begin
        AddFileLog('[Lua] input string parsing error!');
        AddChatString(#5 + '[Lua] Error while parsing!');
        end
    else
        GetGlobals();
end;

function LuaUpdateDebugInfo(): Boolean;
begin
    FillChar(LuaDebugInfo, sizeof(LuaDebugInfo), 0);

    if lua_getstack(luaState, 1, @LuaDebugInfo) = 0 then
        exit(false); // stack not deep enough

    // get source name and line count
    lua_getinfo(luaState, PChar('Sl'), @LuaDebugInfo);
    exit(true);
end;

procedure LuaErrorOrWarning(s: shortstring; isWarning: boolean);
var src, intro: shortstring;
const
    maxsrclen = 20;
begin
    if isWarning then
        intro:= 'LUA WARNING'
    else
        intro:= 'LUA ERROR';
    if LuaUpdateDebugInfo() then
        begin
        src:= StrPas(LuaDebugInfo.source);
        s:= intro + ': [ ... '
            + copy(src, Length(src) - maxsrclen, maxsrclen - 3) + ':'
            + inttostr(LuaDebugInfo.currentLine) + ']: ' + s;
        end
    else
        s:= intro + ': ' + s;
    WriteLnToConsole(s);
    if isWarning then
        AddChatString(#0 + s)
    else
        AddChatString(#5 + s);
    if cTestLua and (not isWarning) then
        halt(HaltTestLuaError);
end;

procedure LuaError(s: shortstring);
begin
    LuaErrorOrWarning(s, false);
end;

procedure LuaWarning(s: shortstring);
begin
    LuaErrorOrWarning(s, true);
end;

procedure LuaCallError(error, call, paramsyntax: shortstring);
begin
    LuaError(call + ': ' + error);
    LuaError('-- SYNTAX: ' + call + ' ( ' + paramsyntax + ' )');
end;

procedure LuaParameterCountError(expected, call, paramsyntax: shortstring; wrongcount: LongInt); inline;
begin
    // TODO: i18n?
    LuaCallError('Wrong number of parameters! (is: ' + inttostr(wrongcount) + ', should be: '+ expected + ')', call, paramsyntax);
end;

// compare with allowed count
function CheckLuaParamCount(L : Plua_State; count: LongInt; call, paramsyntax: shortstring): boolean; inline;
var c: LongInt;
begin
    c:= lua_gettop(L);
    if c <> count then
        begin
        LuaParameterCountError('exactly ' + inttostr(count), call, paramsyntax, c);
        exit(false);
        end;

    CheckLuaParamCount:= true;
end;

// check if is either count1 or count2
function CheckAndFetchParamCount(L : Plua_State; count1, count2: LongInt; call, paramsyntax: shortstring; out actual: LongInt): boolean; inline;
begin
    actual:= lua_gettop(L);
    if (actual <> count1) and (actual <> count2) then
        begin
        LuaParameterCountError('either ' + inttostr(count1) + ' or ' + inttostr(count2), call, paramsyntax, actual);
        exit(false);
        end;

    CheckAndFetchParamCount:= true;
end;

// check if is in range of count1 and count2
function CheckAndFetchParamCountRange(L : Plua_State; count1, count2: LongInt; call, paramsyntax: shortstring; out actual: LongInt): boolean; inline;
begin
    actual:= lua_gettop(L);
    if (actual < count1) or (actual > count2) then
        begin
        LuaParameterCountError('at least ' + inttostr(count1) + ', but at most ' + inttostr(count2), call, paramsyntax, actual);
        exit(false);
        end;

    CheckAndFetchParamCountRange:= true;
end;

// check if is same or higher as minCount
function CheckAndFetchLuaParamMinCount(L : Plua_State; minCount: LongInt; call, paramsyntax: shortstring; out actual: LongInt): boolean; inline;
begin
    actual:= lua_gettop(L);
    if (actual < minCount) then
        begin
        LuaParameterCountError(inttostr(minCount) + ' or more', call, paramsyntax, actual);
        exit(false);
        end;

    CheckAndFetchLuaParamMinCount:= true;
end;

function LuaToGearTypeOrd(L : Plua_State; i: LongInt; call, paramsyntax: shortstring): LongInt; inline;
begin
    if lua_isnoneornil(L, i) then i:= -1
    else i:= Trunc(lua_tonumber(L, i));
    if (i < ord(Low(TGearType))) or (i > ord(High(TGearType))) then
        begin
        LuaCallError('Invalid gearType!', call, paramsyntax);
        LuaToGearTypeOrd:= -1;
        end
    else
        LuaToGearTypeOrd:= i;
end;

function LuaToVisualGearTypeOrd(L : Plua_State; i: LongInt; call, paramsyntax: shortstring): LongInt; inline;
begin
    if lua_isnoneornil(L, i) then i:= -1
    else i:= Trunc(lua_tonumber(L, i));
    if (i < ord(Low(TVisualGearType))) or (i > ord(High(TVisualGearType))) then
        begin
        LuaCallError('Invalid visualGearType!', call, paramsyntax);
        LuaToVisualGearTypeOrd:= -1;
        end
    else
        LuaToVisualGearTypeOrd:= i;
end;

function LuaToAmmoTypeOrd(L : Plua_State; i: LongInt; call, paramsyntax: shortstring): LongInt; inline;
begin
    if lua_isnoneornil(L, i) then i:= -1
    else i:= Trunc(lua_tonumber(L, i));
    if (i < ord(Low(TAmmoType))) or (i > ord(High(TAmmoType))) then
        begin
        LuaCallError('Invalid ammoType!', call, paramsyntax);
        LuaToAmmoTypeOrd:= -1;
        end
    else
        LuaToAmmoTypeOrd:= i;
end;

function LuaToStatInfoTypeOrd(L : Plua_State; i: LongInt; call, paramsyntax: shortstring): LongInt; inline;
begin
    if lua_isnoneornil(L, i) then i:= -1
    else i:= Trunc(lua_tonumber(L, i));
    if (i < ord(Low(TStatInfoType))) or (i > ord(High(TStatInfoType))) then
        begin
        LuaCallError('Invalid statInfoType!', call, paramsyntax);
        LuaToStatInfoTypeOrd:= -1;
        end
    else
        LuaToStatInfoTypeOrd:= i;
end;

function LuaToSoundOrd(L : Plua_State; i: LongInt; call, paramsyntax: shortstring): LongInt; inline;
begin
    if lua_isnoneornil(L, i) then i:= -1
    else i:= Trunc(lua_tonumber(L, i));
    if (i < ord(Low(TSound))) or (i > ord(High(TSound))) then
        begin
        LuaCallError('Invalid soundId!', call, paramsyntax);
        LuaToSoundOrd:= -1;
        end
    else
        LuaToSoundOrd:= i;
end;

function LuaToHogEffectOrd(L : Plua_State; i: LongInt; call, paramsyntax: shortstring): LongInt; inline;
begin
    if lua_isnoneornil(L, i) then i:= -1
    else i:= Trunc(lua_tonumber(L, i));
    if (i < ord(Low(THogEffect))) or (i > ord(High(THogEffect))) then
        begin
        LuaCallError('Invalid effect type!', call, paramsyntax);
        LuaToHogEffectOrd:= -1;
        end
    else
        LuaToHogEffectOrd:= i;
end;

function LuaToCapGroupOrd(L : Plua_State; i: LongInt; call, paramsyntax: shortstring): LongInt; inline;
begin
    if lua_isnoneornil(L, i) then i:= -1
    else i:= Trunc(lua_tonumber(L, i));
    if (i < ord(Low(TCapGroup))) or (i > ord(High(TCapGroup))) then
        begin
        LuaCallError('Invalid capgroup type!', call, paramsyntax);
        LuaToCapGroupOrd:= -1;
        end
    else
        LuaToCapGroupOrd:= i;
end;

function LuaToSpriteOrd(L : Plua_State; i: LongInt; call, paramsyntax: shortstring): LongInt; inline;
begin
    if lua_isnoneornil(L, i) then i:= -1
    else i:= Trunc(lua_tonumber(L, i));
    if (i < ord(Low(TSprite))) or (i > ord(High(TSprite))) then
        begin
        LuaCallError('Invalid sprite id!', call, paramsyntax);
        LuaToSpriteOrd:= -1;
        end
    else
        LuaToSpriteOrd:= i;
end;

function LuaToMapGenOrd(L : Plua_State; i: LongInt; call, paramsyntax: shortstring): LongInt; inline;
begin
    if lua_isnoneornil(L, i) then i:= -1
    else i:= Trunc(lua_tonumber(L, i));
    if (i < ord(Low(TMapGen))) or (i > ord(High(TMapGen))) then
        begin
        LuaCallError('Invalid mapgen id!', call, paramsyntax);
        LuaToMapGenOrd:= -1;
        end
    else
        LuaToMapGenOrd:= i;
end;

// wrapped calls

// functions called from Lua:
// function(L : Plua_State) : LongInt; Cdecl;
// where L contains the state, returns the number of return values on the stack
// call CheckLuaParamCount or CheckAndFetchParamCount
// to validate/get the number of passed arguments (see their call definitions)
//
// use as return value the number of variables pushed back to the lua script

function lc_band(L: PLua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 2, 'band', 'value1, value2') then
        lua_pushnumber(L, Trunc(lua_tonumber(L, 2)) and Trunc(lua_tonumber(L, 1)))
    else
        lua_pushnil(L);
    lc_band := 1;
end;

function lc_bor(L: PLua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 2, 'bor', 'value1, value2') then
        lua_pushnumber(L, Trunc(lua_tonumber(L, 2)) or Trunc(lua_tonumber(L, 1)))
    else
        lua_pushnil(L);
    lc_bor := 1;
end;

function lc_bnot(L: PLua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'bnot', 'value') then
        lua_pushnumber(L, (not Trunc(lua_tonumber(L, 1))))
    else
        lua_pushnil(L);
    lc_bnot := 1;
end;

function lc_div(L: PLua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 2, 'div', 'dividend, divisor') then
        lua_pushnumber(L, Trunc(lua_tonumber(L, 1)) div Trunc(lua_tonumber(L, 2)))
    else
        lua_pushnil(L);
    lc_div := 1;
end;

function lc_getinputmask(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'GetInputMask', '') then
        lua_pushnumber(L, InputMask);
    lc_getinputmask:= 1
end;

function lc_setinputmask(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'SetInputMask', 'mask') then
        InputMask:= Trunc(lua_tonumber(L, 1));
    lc_setinputmask:= 0
end;

function lc_writelntoconsole(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'WriteLnToConsole', 'string') then
        WriteLnToConsole('Lua: ' + lua_tostring(L ,1));
    lc_writelntoconsole:= 0;
end;

function lc_writelntochat(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'WriteLnToChat', 'string') then
        AddChatString(#2 + lua_tostring(L, 1));
    lc_writelntochat:= 0;
end;

function lc_parsecommand(L : Plua_State) : LongInt; Cdecl;
var t: PChar;
    i,c: LongWord;
    s: shortstring;
begin
    if CheckLuaParamCount(L, 1, 'ParseCommand', 'string') then
        begin
        t:= lua_tolstring(L, 1, Psize_t(@c));

        for i:= 1 to c do s[i]:= t[i-1];
        s[0]:= char(c);

        ParseCommand(s, true, true);

        end;
    lc_parsecommand:= 0;
end;

// sets weapon to the desired ammo type
function lc_setweapon(L : Plua_State) : LongInt; Cdecl;
var at: LongInt;
const
    call = 'SetWeapon';
    params = 'ammoType';
begin
    // no point to run this without any CurrentHedgehog
    if (CurrentHedgehog <> nil) and (CheckLuaParamCount(L, 1, call, params)) then
        begin
        at:= LuaToAmmoTypeOrd(L, 1, call, params);
        if at >= 0 then
            ParseCommand('setweap ' + char(at), true, true);
        end;
    lc_setweapon:= 0;
end;

// enable/disable cinematic effects
function lc_setcinematicmode(L : Plua_State) : LongInt; Cdecl;
const
    call = 'SetCinematicMode';
    params = 'enable';
begin
    if (CheckLuaParamCount(L, 1, call, params)) then
        begin
        CinematicScript:= lua_toboolean(L, 1);
        end;
    lc_setcinematicmode:= 0;
end;

// no parameter means reset to default (and 0 means unlimited)
function lc_setmaxbuilddistance(L : Plua_State) : LongInt; Cdecl;
var np: LongInt;
const
    call = 'SetMaxBuildDistance';
    params = '[ distInPx ]';
begin
    if CheckAndFetchParamCountRange(L, 0, 1, call, params, np) then
        begin
        if np = 0 then
            begin
            // no args? reset
            cBuildMaxDist:= cDefaultBuildMaxDist;
            end
        else
            CBuildMaxDist:= Trunc(lua_tonumber(L, 1));
        end;
    lc_setmaxbuilddistance:= 0;
end;

// sets weapon to whatever weapons is next (wraps around, amSkip is skipped)
function lc_setnextweapon(L : Plua_State) : LongInt; Cdecl;
var at          : LongInt;
    nextAmmo    : TAmmo;
    s, a, cs, fa: LongInt;
const
    call = 'SetNextWeapon';
    params = '';
begin
    if (CurrentHedgehog <> nil) and (CheckLuaParamCount(L, 0, call, params)) then
        begin
        at:= -1;
        with CurrentHedgehog^ do
            begin
            cs:= 0; // current slot
            fa:= 0; // first ammo item to check

            // if something is selected, find it is successor
            if curAmmoType <> amNothing then
                begin
                // get current slot index
                cs:= Ammoz[CurAmmoType].Slot;
                // find current ammo index
                while (fa < cMaxSlotAmmoIndex)
                    and (Ammo^[cs, fa].AmmoType <> CurAmmoType) do
                        inc(fa);
                // increase once more because we will not successor
                inc(fa);
                end;

            // find first available ammo
            // revisit current slot too (current item might not be first)
            for s:= cs to cs + cMaxSlotIndex + 1 do
                begin
                for a:= fa to cMaxSlotAmmoIndex do
                    begin
                    // check if we went full circle
                    if (a = fa) and (s = cs + cMaxSlotIndex + 1)  then
                        exit(0);

                    // get ammo
                    nextAmmo:= Ammo^[s mod (cMaxSlotIndex + 1), a];
                    // only switch to ammos the hog actually has
                    if (nextAmmo.AmmoType <> amNothing)
                        and (nextAmmo.AmmoType <> amSkip) and (nextAmmo.Count > 0) then
                            begin
                            at:= ord(nextAmmo.AmmoType);
                            break;
                            end;
                    end;
                // stop slot loop if something was found
                if at >= 0 then
                    break;
                // check following slots starting with first item
                fa:= 0;
                end;
            end;

        if at >= 0 then
            ParseCommand('setweap ' + char(at), true, true);
        end;
    lc_setnextweapon:= 0;
end;

function lc_showmission(L : Plua_State) : LongInt; Cdecl;
var n: LongInt;
begin
    if CheckAndFetchParamCount(L, 5, 6, 'ShowMission', 'caption, subcaption, text, icon, time [, forceDisplay]', n) then
        if n = 5 then
            ShowMission(lua_tostringA(L, 1), lua_tostringA(L, 2), lua_tostringA(L, 3), Trunc(lua_tonumber(L, 4)), Trunc(lua_tonumber(L, 5)))
        else
            ShowMission(lua_tostringA(L, 1), lua_tostringA(L, 2), lua_tostringA(L, 3), Trunc(lua_tonumber(L, 4)), Trunc(lua_tonumber(L, 5)), lua_toboolean(L, 6));
    lc_showmission:= 0;
end;

function lc_hidemission(L : Plua_State) : LongInt; Cdecl;
begin
    L:= L; // avoid compiler hint
    HideMission;
    lc_hidemission:= 0;
end;

function lc_setammotexts(L : Plua_State) : LongInt; Cdecl;
const
    call = 'SetAmmoTexts';
    params = 'ammoType, name, caption, description [, showExtra]';
var n: integer;
    showExtra: boolean;
begin
    if CheckAndFetchParamCount(L, 4, 5, call, params, n) then
        begin
        if n = 5 then
            showExtra:= lua_toboolean(L, 5)
        else
            showExtra:= true;
        SetAmmoTexts(TAmmoType(LuaToAmmoTypeOrd(L, 1, call, params)), lua_tostringA(L, 2), lua_tostringA(L, 3), lua_tostringA(L, 4), showExtra);
        end;
    lc_setammotexts:= 0;
end;

function lc_setammodescriptionappendix(L : Plua_State) : LongInt; Cdecl;
const
    call = 'SetAmmoDescriptionAppendix';
    params = 'ammoType, descAppend';
var
    ammoType: TAmmoType;
    descAppend: ansistring;
begin
    if CheckLuaParamCount(L, 2, call, params) then
        begin
        ammoType := TAmmoType(LuaToAmmoTypeOrd(L, 1, call, params));
        descAppend := lua_tostringA(L, 2);
        trluaammoa[Ammoz[ammoType].NameId] := descAppend;
        end;
    lc_setammodescriptionappendix := 0;
end;

function lc_enablegameflags(L : Plua_State) : LongInt; Cdecl;
var i, n : integer;
begin
    // can have 1 or more arguments
    if CheckAndFetchLuaParamMinCount(L, 1, 'EnableGameFlags', 'gameFlag, ... ', n) then
        begin
        for i:= 1 to n do
            GameFlags := GameFlags or LongWord(Trunc(lua_tonumber(L, i)));
        ScriptSetInteger('GameFlags', GameFlags);
        end;
    lc_enablegameflags:= 0;
end;

function lc_disablegameflags(L : Plua_State) : LongInt; Cdecl;
var i , n: integer;
begin
    // can have 1 or more arguments
    if CheckAndFetchLuaParamMinCount(L, 1, 'DisableGameFlags', 'gameFlag, ... ', n) then
        begin
        for i:= 1 to n do
            GameFlags := GameFlags and (not LongWord(Trunc(lua_tonumber(L, i))));
        ScriptSetInteger('GameFlags', GameFlags);
        end;
    lc_disablegameflags:= 0;
end;

function lc_cleargameflags(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'ClearGameFlags', '') then
        begin
        GameFlags:= 0;
        ScriptSetInteger('GameFlags', GameFlags);
        end;
    lc_cleargameflags:= 0;
end;

function lc_getgameflag(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'GetGameFlag', 'gameflag') then
        lua_pushboolean(L, (GameFlags and LongWord(Trunc(lua_tonumber(L, 1))) <> 0))
    else
        lua_pushnil(L);
    lc_getgameflag:= 1;
end;

function lc_addcaption(L : Plua_State) : LongInt; Cdecl;
var cg: LongInt;
const
    call = 'AddCaption';
    params = 'text [, color, captiongroup]';
begin
    if CheckAndFetchParamCount(L, 1, 3, call, params, cg) then
        begin
        if cg = 1 then
            AddCaption(lua_tostringA(L, 1), capcolDefault, capgrpMessage)
        else
            begin
            cg:= LuaToCapGroupOrd(L, 3, call, params);
            if cg >= 0 then
                AddCaption(lua_tostringA(L, 1), Trunc(lua_tonumber(L, 2)) shr 8, TCapGroup(cg));
            end
        end;
    lc_addcaption:= 0;
end;

function lc_spawnfakehealthcrate(L: Plua_State) : LongInt; Cdecl;
var gear: PGear;
    explode, poison: boolean;
    n: LongInt;
begin
    if CheckAndFetchParamCountRange(L, 2, 4, 'SpawnFakeHealthCrate', 'x, y [, explode [, poison]]', n) then
        begin
        explode:= false;
        poison:= false;
        if (n >= 3) and (not lua_isnil(L, 3)) then
            explode:= lua_toboolean(L, 3);
        if (n = 4) and (not lua_isnil(L, 4)) then
            poison:= lua_toboolean(L, 4);

        gear := SpawnFakeCrateAt(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)),
        HealthCrate, explode, poison);
        if gear <> nil then
             lua_pushnumber(L, gear^.uid)
        else lua_pushnil(L)
        end
    else
        lua_pushnil(L);
    lc_spawnfakehealthcrate := 1;
end;

function lc_spawnfakeammocrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
    explode, poison: boolean;
    n: LongInt;
begin
    if CheckAndFetchParamCountRange(L, 2, 4, 'SpawnFakeAmmoCrate', 'x, y [, explode [, poison]]', n) then
        begin
        explode:= false;
        poison:= false;
        if (n >= 3) and (not lua_isnil(L, 3)) then
            explode:= lua_toboolean(L, 3);
        if (n = 4) and (not lua_isnil(L, 4)) then
            poison:= lua_toboolean(L, 4);

        gear := SpawnFakeCrateAt(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)),
        AmmoCrate, explode, poison);
        if gear <> nil then
             lua_pushnumber(L, gear^.uid)
        else lua_pushnil(L)
        end
    else
        lua_pushnil(L);
    lc_spawnfakeammocrate := 1;
end;

function lc_spawnfakeutilitycrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
    explode, poison: boolean;
    n: LongInt;
begin
    if CheckAndFetchParamCountRange(L, 2, 4, 'SpawnFakeUtilityCrate', 'x, y [, explode [, poison]]', n) then
        begin
        explode:= false;
        poison:= false;
        if (n >= 3) and (not lua_isnil(L, 3)) then
            explode:= lua_toboolean(L, 3);
        if (n = 4) and (not lua_isnil(L, 4)) then
            poison:= lua_toboolean(L, 4);

        gear := SpawnFakeCrateAt(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)),
        UtilityCrate, explode, poison);
        if gear <> nil then
             lua_pushnumber(L, gear^.uid)
        else lua_pushnil(L)
        end
    else
        lua_pushnil(L);
    lc_spawnfakeutilitycrate := 1;
end;

function lc_spawnhealthcrate(L: Plua_State) : LongInt; Cdecl;
var gear: PGear;
var health, n: LongInt;
begin
    if CheckAndFetchParamCount(L, 2, 3, 'SpawnHealthCrate', 'x, y [, health]', n) then
        begin
        if n = 3 then
            health:= Trunc(lua_tonumber(L, 3))
        else
            health:= cHealthCaseAmount;
        gear := SpawnCustomCrateAt(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)), HealthCrate, health, 0);
        if gear <> nil then
             lua_pushnumber(L, gear^.uid)
        else lua_pushnil(L);
        end
    else
        lua_pushnil(L);
    lc_spawnhealthcrate := 1;
end;

function lc_spawnammocrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
    n   : LongInt;
begin
    if CheckAndFetchParamCount(L, 3, 4, 'SpawnAmmoCrate', 'x, y, content [, amount]', n) then
        begin
        if n = 3 then
             gear := SpawnCustomCrateAt(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)), AmmoCrate, Trunc(lua_tonumber(L, 3)), 0)
        else gear := SpawnCustomCrateAt(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)), AmmoCrate, Trunc(lua_tonumber(L, 3)), Trunc(lua_tonumber(L, 4)));
        if gear <> nil then
             lua_pushnumber(L, gear^.uid)
        else lua_pushnil(L);
        end
    else
        lua_pushnil(L);
    lc_spawnammocrate := 1;
end;

function lc_spawnutilitycrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
    n   : LongInt;
begin
    if CheckAndFetchParamCount(L, 3, 4, 'SpawnUtilityCrate', 'x, y, content [, amount]', n) then
        begin
        if n = 3 then
             gear := SpawnCustomCrateAt(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)), UtilityCrate, Trunc(lua_tonumber(L, 3)), 0)
        else gear := SpawnCustomCrateAt(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)), UtilityCrate, Trunc(lua_tonumber(L, 3)), Trunc(lua_tonumber(L, 4)));
        if gear <> nil then
             lua_pushnumber(L, gear^.uid)
        else lua_pushnil(L);
       end
    else
        lua_pushnil(L);
    lc_spawnutilitycrate := 1;
end;

function lc_spawnsupplycrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
    n, at:LongInt;
    t:    TCrateType;
begin
    if CheckAndFetchParamCount(L, 3, 4, 'SpawnSupplyCrate', 'x, y, content [, amount]', n) then
        begin
        // Get crate type (ammo or utility)
        at:= Trunc(lua_tonumber(L, 3));
        if (Ammoz[TAmmoType(at)].Ammo.Propz and ammoprop_Utility) <> 0 then
            t:= UtilityCrate
        else
            t:= AmmoCrate;
        if n = 3 then
             gear := SpawnCustomCrateAt(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)), t, at, 0)
        else gear := SpawnCustomCrateAt(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)), t, at, Trunc(lua_tonumber(L, 4)));
        if gear <> nil then
             lua_pushnumber(L, gear^.uid)
        else lua_pushnil(L);
        end
    else
        lua_pushnil(L);
    lc_spawnsupplycrate := 1;
end;

function lc_addgear(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
    x, y, s, t: LongInt;
    dx, dy: hwFloat;
    gt: TGearType;
const
    call = 'AddGear';
    params = 'x, y, gearType, state, dx, dy, timer';
begin
    if CheckLuaParamCount(L, 7, call, params) then
        begin
        t:= LuaToGearTypeOrd(L, 3, call, params);
        if t >= 0 then
            begin
            gt:= TGearType(t);
            x:= Trunc(lua_tonumber(L, 1));
            y:= Trunc(lua_tonumber(L, 2));
            s:= Trunc(lua_tonumber(L, 4));
            dx:= int2hwFloat(Trunc(lua_tonumber(L, 5))) / 1000000;
            dy:= int2hwFloat(Trunc(lua_tonumber(L, 6))) / 1000000;
            t:= Trunc(lua_tonumber(L, 7));

            gear:= AddGear(x, y, gt, s, dx, dy, t);
            lastGearByUID:= gear;
            lua_pushnumber(L, gear^.uid)
            end
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L);
    lc_addgear:= 1; // 1 return value
end;

function lc_deletegear(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'DeleteGear', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            gear^.Message:= gear^.Message or gmDelete;
        end;
    lc_deletegear:= 0
end;

function lc_addvisualgear(L : Plua_State) : LongInt; Cdecl;
var vg : PVisualGear;
    x, y, s, n, layer: LongInt;
    c: Boolean;
    vgt: TVisualGearType;
    uid: Longword;
const
    call = 'AddVisualGear';
    params = 'x, y, visualGearType, state, critical [, layer]';
begin
    uid:= 0;
    if CheckAndFetchParamCount(L, 5, 6, call, params, n) then
        begin
        s:= LuaToVisualGearTypeOrd(L, 3, call, params);
        if s >= 0 then
            begin
            vgt:= TVisualGearType(s);
            x:= Trunc(lua_tonumber(L, 1));
            y:= Trunc(lua_tonumber(L, 2));
            s:= Trunc(lua_tonumber(L, 4));
            c:= lua_toboolean(L, 5);

            if n = 6 then
                begin
                layer:= Trunc(lua_tonumber(L, 6));
                vg:= AddVisualGear(x, y, vgt, s, c, layer);
                end
            else
                vg:= AddVisualGear(x, y, vgt, s, c);

            if vg <> nil then
                begin
                lastVisualGearByUID:= vg;
                uid:= vg^.uid;
                lua_pushnumber(L, uid);
                end;
            end
            else
                lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_addvisualgear:= 1; // 1 return value
end;

function lc_deletevisualgear(L : Plua_State) : LongInt; Cdecl;
var vg : PVisualGear;
begin
    vg:= nil;
    if CheckLuaParamCount(L, 1, 'DeleteVisualGear', 'vgUid') then
        begin
        vg:= VisualGearByUID(Trunc(lua_tonumber(L, 1)));
        if vg <> nil then
            DeleteVisualGear(vg);
        end;
    // allow caller to know whether there was something to delete
    lua_pushboolean(L, vg <> nil);
    lc_deletevisualgear:= 1
end;

function lc_getvisualgeartype(L : Plua_State) : LongInt; Cdecl;
var vg : PVisualGear;
begin
    if CheckLuaParamCount(L, 1, 'GetVisualGearType', 'vgUid') then
        begin
        vg := VisualGearByUID(Trunc(lua_tonumber(L, 1)));
        if vg <> nil then
            lua_pushnumber(L, ord(vg^.Kind))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getvisualgeartype:= 1
end;


function lc_getvisualgearvalues(L : Plua_State) : LongInt; Cdecl;
var vg: PVisualGear;
begin
    if CheckLuaParamCount(L, 1, 'GetVisualGearValues', 'vgUid') then
        begin
        vg:= VisualGearByUID(Trunc(lua_tonumber(L, 1)));
        if vg <> nil then
            begin
            lua_pushnumber(L, round(vg^.X));
            lua_pushnumber(L, round(vg^.Y));
            lua_pushnumber(L, vg^.dX);
            lua_pushnumber(L, vg^.dY);
            lua_pushnumber(L, vg^.Angle);
            lua_pushnumber(L, vg^.Frame);
            lua_pushnumber(L, vg^.FrameTicks);
            lua_pushnumber(L, vg^.State);
            lua_pushnumber(L, vg^.Timer);
            lua_pushnumber(L, vg^.Tint);
            lua_pushnumber(L, vg^.Scale);
            end
        else
            begin
            lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
            lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
            end
        end
    else
        begin
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
        end;
    lc_getvisualgearvalues:= 10
end;

function lc_setvisualgearvalues(L : Plua_State) : LongInt; Cdecl;
var vg : PVisualGear;
begin
// Param count can be 1-11 at present
//    if CheckLuaParamCount(L, 11, 'SetVisualGearValues', 'vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint, Scale') then
//        begin
        vg:= VisualGearByUID(Trunc(lua_tonumber(L, 1)));
        if vg <> nil then
            begin
            if not lua_isnoneornil(L, 2) then
                vg^.X:= Trunc(lua_tonumber(L, 2));
            if not lua_isnoneornil(L, 3) then
                vg^.Y:= Trunc(lua_tonumber(L, 3));
            if not lua_isnoneornil(L, 4) then
                vg^.dX:= lua_tonumber(L, 4);
            if not lua_isnoneornil(L, 5) then
                vg^.dY:= lua_tonumber(L, 5);
            if not lua_isnoneornil(L, 6) then
                vg^.Angle:= lua_tonumber(L, 6);
            if not lua_isnoneornil(L, 7) then
                vg^.Frame:= Trunc(lua_tonumber(L, 7));
            if not lua_isnoneornil(L, 8) then
                vg^.FrameTicks:= Trunc(lua_tonumber(L, 8));
            if not lua_isnoneornil(L, 9) then
                vg^.State:= Trunc(lua_tonumber(L, 9));
            if not lua_isnoneornil(L, 10) then
                vg^.Timer:= Trunc(lua_tonumber(L, 10));
            if not lua_isnoneornil(L, 11) then
                vg^.Tint:= Trunc(lua_tonumber(L, 11));
            if not lua_isnoneornil(L, 12) then
                vg^.Scale:= Trunc(lua_tonumber(L, 12))
            end;
//        end
//    else
//        lua_pushnil(L); // return value on stack (nil)
    lc_setvisualgearvalues:= 0
end;

// so. going to use this to get/set some of the more obscure gear values which were not already exposed elsewhere
// can keep adding things in the future. isnoneornil makes it safe
function lc_getgearvalues(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearValues', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            lua_pushnumber(L, gear^.Angle);
            lua_pushnumber(L, gear^.Power);
            lua_pushnumber(L, gear^.WDTimer);
            lua_pushnumber(L, gear^.Radius);
            lua_pushnumber(L, hwRound(gear^.Density * _10000));
            lua_pushnumber(L, gear^.Karma);
            lua_pushnumber(L,  gear^.DirAngle);
            lua_pushnumber(L, gear^.AdvBounce);
            lua_pushnumber(L, Integer(gear^.ImpactSound));
            lua_pushnumber(L, gear^.nImpactSounds);
            lua_pushnumber(L, gear^.Tint);
            lua_pushnumber(L, gear^.Damage);
            lua_pushnumber(L, gear^.Boom)
            end
        else
            begin
            lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
            lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
            lua_pushnil(L); lua_pushnil(L); lua_pushnil(L)
            end
        end
    else
        begin
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L)
        end;
    lc_getgearvalues:= 13
end;

function lc_setgearvalues(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
// Currently allows 1-14 params
//    if CheckLuaParamCount(L, 14, 'SetGearValues', 'gearUid, Angle, Power, WDTimer, Radius, Density, Karma, DirAngle, AdvBounce, ImpactSound, # ImpactSounds, Tint, Damage, Boom') then
//        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            if not lua_isnoneornil(L, 2) then
                gear^.Angle := Trunc(lua_tonumber(L, 2));
            if not lua_isnoneornil(L, 3) then
                gear^.Power := Trunc(lua_tonumber(L, 3));
            if not lua_isnoneornil(L, 4) then
                gear^.WDTimer := Trunc(lua_tonumber(L, 4));
            if not lua_isnoneornil(L, 5) then
                gear^.Radius := Trunc(lua_tonumber(L, 5));
            if not lua_isnoneornil(L, 6) then
                gear^.Density:= int2hwFloat(Trunc(lua_tonumber(L, 6))) / 10000;
            if not lua_isnoneornil(L, 7) then
                gear^.Karma := Trunc(lua_tonumber(L, 7));
            if not lua_isnoneornil(L, 8) then
                gear^.DirAngle:= lua_tonumber(L, 8);
            if not lua_isnoneornil(L, 9) then
                gear^.AdvBounce := Trunc(lua_tonumber(L, 9));
            if not lua_isnoneornil(L, 10) then
                gear^.ImpactSound := TSound(Trunc(lua_tonumber(L, 10)));
            if not lua_isnoneornil(L, 11) then
                gear^.nImpactSounds := Trunc(lua_tonumber(L, 11));
            if not lua_isnoneornil(L, 12) then
                gear^.Tint := Trunc(lua_tonumber(L, 12));
            if not lua_isnoneornil(L, 13) then
                gear^.Damage := Trunc(lua_tonumber(L, 13));
            if not lua_isnoneornil(L, 14) then
                gear^.Boom := Trunc(lua_tonumber(L, 14));
            end;
//        end
//    else
//        lua_pushnil(L); // return value on stack (nil)
    lc_setgearvalues:= 0
end;

function lc_getfollowgear(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'GetFollowGear', '') then
        begin
        if FollowGear = nil then
            lua_pushnil(L)
        else
            lua_pushnumber(L, FollowGear^.uid);
        end
    else
        lua_pushnil(L);
    lc_getfollowgear:= 1; // 1 return value
end;

function lc_getgeartype(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearType', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, ord(gear^.Kind))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getgeartype:= 1
end;

function lc_getgearmessage(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearMessage', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, gear^.message)
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getgearmessage:= 1
end;

function lc_getgearelasticity(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearElasticity', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, hwRound(gear^.elasticity * _10000))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getgearelasticity:= 1
end;

function lc_setgearelasticity(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetGearElasticity', 'gearUid, Elasticity') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            gear^.Elasticity:= int2hwFloat(Trunc(lua_tonumber(L, 2))) / 10000
        end;
    lc_setgearelasticity:= 0
end;

function lc_getgearfriction(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearFriction', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, hwRound(gear^.friction * _10000))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getgearfriction:= 1
end;

function lc_setgearfriction(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetGearFriction', 'gearUid, Friction') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            gear^.Friction:= int2hwFloat(Trunc(lua_tonumber(L, 2))) / 10000
        end;
    lc_setgearfriction:= 0
end;

function lc_setgearmessage(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetGearMessage', 'gearUid, message') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            gear^.message:= Trunc(lua_tonumber(L, 2));
        end;
    lc_setgearmessage:= 0
end;

function lc_getgearpos(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearPos', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, gear^.Pos)
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getgearpos:= 1
end;

function lc_setgearpos(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetGearPos', 'gearUid, value') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            gear^.Pos:= Trunc(lua_tonumber(L, 2));
        end;
    lc_setgearpos:= 0
end;

function lc_getgearcollisionmask(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearCollisionMask', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, gear^.CollisionMask)
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getgearcollisionmask:= 1
end;

function lc_setgearcollisionmask(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetGearCollisionMask', 'gearUid, mask') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            gear^.CollisionMask:= Trunc(lua_tonumber(L, 2));
        end;
    lc_setgearcollisionmask:= 0
end;

function lc_gethoglevel(L : Plua_State): LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogLevel', 'gearUid') then
        begin
        gear := GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            lua_pushnumber(L, gear^.Hedgehog^.BotLevel)
        else
            lua_pushnil(L);
    end;
    lc_gethoglevel := 1;
end;

function lc_sethoglevel(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetHogLevel', 'gearUid, level') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            gear^.Hedgehog^.BotLevel:= Trunc(lua_tonumber(L, 2));
        end;
    lc_sethoglevel:= 0
end;

function lc_gethogclan(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogClan', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            begin
            lua_pushnumber(L, gear^.Hedgehog^.Team^.Clan^.ClanIndex)
            end
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gethogclan:= 1
end;

function lc_getclancolor(L : Plua_State) : LongInt; Cdecl;
var idx: integer;
begin
    if CheckLuaParamCount(L, 1, 'GetClanColor', 'clanIdx') then
        begin
        idx:= Trunc(lua_tonumber(L, 1));
        if (not lua_isnumber(L, 1)) then
            begin
            LuaError('Argument ''clanIdx'' must be a number!');
            lua_pushnil(L);
            end
        else if (idx < 0) or (idx >= ClansCount) then
            begin
            LuaError('Argument ''clanIdx'' out of range! (There are currently ' + IntToStr(ClansCount) + ' clans, so valid range is: 0-' + IntToStr(ClansCount-1) + ')');
            lua_pushnil(L);
            end
        else
            lua_pushnumber(L, ClansArray[idx]^.Color shl 8 or $FF);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getclancolor:= 1
end;

function lc_setclancolor(L : Plua_State) : LongInt; Cdecl;
var clan : PClan;
    team : PTeam;
    hh  : THedgehog;
    i, j : LongInt;
    colorArg: Int64;
    color: LongWord;
begin
    if CheckLuaParamCount(L, 2, 'SetClanColor', 'clan, color') then
        begin
        i:= Trunc(lua_tonumber(L,1));
        if i >= ClansCount then exit(0);
        clan := ClansArray[i];
        colorArg:= Trunc(lua_tonumber(L, 2));
        if (colorArg < 0) and (abs(colorArg) <= cClanColors) then
            // Pick clan color from settings (recommended)
            color:= ClanColorArray[Pred(abs(colorArg))]
        else if (colorArg >= 0) and (colorArg <= $ffffffff) then
            // Specify color directly
            color:= colorArg shr 8
        else
            begin
            OutError('Lua error: SetClanColor: Invalid ''color'' argument, must be between '+IntToStr(-cClanColors)+' and 0xffffffff!', true);
            lc_setclancolor:= 0;
            exit;
            end;

        clan^.Color:= color;

        for i:= 0 to Pred(clan^.TeamsNumber) do
            begin
            team:= clan^.Teams[i];
            for j:= 0 to cMaxHHIndex do
                begin
                hh:= team^.Hedgehogs[j];
                if (hh.Gear <> nil) or (hh.GearHidden <> nil) then
                    begin
                    FreeAndNilTexture(hh.NameTagTex);
                    hh.NameTagTex:= RenderStringTex(ansistring(hh.Name), clan^.Color, fnt16);
                    RenderHealth(hh);
                    team^.Hedgehogs[j]:= hh;
                    end;
                end;
            FreeAndNilTexture(team^.NameTagTex);
            team^.NameTagTex:= RenderStringTex(ansistring(clan^.Teams[i]^.TeamName), clan^.Color, fnt16);
            end;

        FreeAndNilTexture(clan^.HealthTex);
        clan^.HealthTex:= makeHealthBarTexture(cTeamHealthWidth + 5, clan^.Teams[0]^.NameTagTex^.h, clan^.Color);
        end;

    lc_setclancolor:= 0
end;

function lc_gethogvoicepack(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogVoicepack', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Team^.Voicepack^.name))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gethogvoicepack:= 1
end;

function lc_gethoggrave(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogGrave', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Team^.GraveName))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gethoggrave:= 1
end;

function lc_gethogflag(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogFlag', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        // TODO error messages
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Team^.Flag))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gethogflag:= 1
end;

function lc_gethogfort(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogFort', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        // TODO error messages
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Team^.FortName))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gethogfort:= 1
end;

function lc_ishoglocal(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'IsHogLocal', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        // TODO error messages
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            lua_pushboolean(L, IsHogLocal(gear^.Hedgehog))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_ishoglocal:= 1
end;

function lc_gethogteamname(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogTeamName', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        // TODO error messages
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Team^.TeamName))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gethogteamname:= 1
end;

function lc_sethogteamname(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetHogTeamName', 'gearUid, name') then
        begin
        gear := GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            begin
            gear^.Hedgehog^.Team^.TeamName := lua_tostring(L, 2);

            FreeAndNilTexture(gear^.Hedgehog^.Team^.NameTagTex);
            gear^.Hedgehog^.Team^.NameTagTex:= RenderStringTex(ansistring(gear^.Hedgehog^.Team^.TeamName), gear^.Hedgehog^.Team^.Clan^.Color, fnt16);
            end
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_sethogteamname:= 1
end;

function lc_gethogname(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogName', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            begin
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Name))
            end
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gethogname:= 1
end;

function lc_sethogname(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetHogName', 'gearUid, name') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            begin
            gear^.Hedgehog^.Name:= lua_tostring(L, 2);

            FreeAndNilTexture(gear^.Hedgehog^.NameTagTex);
            gear^.Hedgehog^.NameTagTex:= RenderStringTex(ansistring(gear^.Hedgehog^.Name), gear^.Hedgehog^.Team^.Clan^.Color, fnt16)
            end
        end;
    lc_sethogname:= 0;
end;

function lc_gettimer(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetTimer', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, gear^.Timer)
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gettimer:= 1
end;

function lc_getflighttime(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetFlightTime', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, gear^.FlightTime)
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getflighttime:= 1
end;

function lc_gethealth(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHealth', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, gear^.Health)
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gethealth:= 1
end;

function lc_getx(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetX', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, hwRound(gear^.X))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getx:= 1
end;

function lc_gety(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetY', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, hwRound(gear^.Y))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gety:= 1
end;

function lc_copypv(L : Plua_State) : LongInt; Cdecl;
var gears, geard : PGear;
begin
    if CheckLuaParamCount(L, 2, 'CopyPV', 'fromGearUid, toGearUid') then
        begin
        gears:= GearByUID(Trunc(lua_tonumber(L, 1)));
        geard:= GearByUID(Trunc(lua_tonumber(L, 2)));
        if (gears <> nil) and (geard <> nil) then
            begin
            geard^.X:= gears^.X;
            geard^.Y:= gears^.Y;
            geard^.dX:= gears^.dX;
            geard^.dY:= gears^.dY;
            end
        end;
    lc_copypv:= 0
end;

function lc_followgear(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'FollowGear', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then FollowGear:= gear
        end;
    lc_followgear:= 0
end;

function lc_hogsay(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
   vgear : PVisualGear;
       s : LongWord;
       n : LongInt;
begin
    if CheckAndFetchParamCount(L, 3, 4, 'HogSay', 'gearUid, text, manner [, vgState]', n) then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            // state defaults to 0 if state param is given
            if n = 4 then
                s:= Trunc(lua_tonumber(L, 4))
            else
                s:= 0;
            vgear:= AddVisualGear(0, 0, vgtSpeechBubble, s, true);
            if vgear <> nil then
               begin
               vgear^.Text:= lua_tostring(L, 2);
               if Gear^.Kind = gtHedgehog then
                   begin
                   AddChatString(#9+Format(shortstring(trmsg[sidChatHog]), gear^.Hedgehog^.Name, vgear^.text));
                   vgear^.Hedgehog:= gear^.Hedgehog
                   end
               else vgear^.Frame:= gear^.uid;

               vgear^.FrameTicks:= Trunc(lua_tonumber(L, 3));
               if (vgear^.FrameTicks < 1) or (vgear^.FrameTicks > 3) then
                   vgear^.FrameTicks:= 1;
               lua_pushnumber(L, vgear^.Uid);
               end
            end
        else
            lua_pushnil(L)
        end
    else
        lua_pushnil(L);
    lc_hogsay:= 1
end;

function lc_switchhog(L : Plua_State) : LongInt; Cdecl;
var gear, prevgear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'SwitchHog', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
// should we allow this when there is no current hedgehog? might do some odd(er) things to turn sequence.
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) and (CurrentHedgehog <> nil) then
            begin
            prevgear := CurrentHedgehog^.Gear;
            if prevgear <> nil then
                begin
                prevgear^.Active := false;
                prevgear^.State:= prevgear^.State and (not gstHHDriven);
                prevgear^.Z := cHHZ;
                prevgear^.Message:= prevgear^.Message or gmRemoveFromList or gmAddToList;
                end;

            SwitchCurrentHedgehog(gear^.Hedgehog);
            AmmoMenuInvalidated:= true;
            CurrentTeam:= CurrentHedgehog^.Team;

            repeat
                CurrentTeam^.CurrHedgehog := (CurrentTeam^.CurrHedgehog + 1) mod CurrentTeam^.HedgehogsNumber
            until
                CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear = CurrentHedgehog^.Gear;

            gear^.State:= gear^.State or gstHHDriven;
            gear^.Active := true;
            gear^.Z := cCurrHHZ;
            gear^.Message:= gear^.Message or gmRemoveFromList or gmAddToList;
            end
        end;
    lc_switchhog:= 0
end;

function lc_enableswitchhog(L : Plua_State) : LongInt; Cdecl;
var gear, iterator: PGear;
    alreadySwitching: boolean;
begin
    if CheckLuaParamCount(L, 0, 'EnableSwitchHog', '') then
        if ((CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil)) then
            begin
            alreadySwitching:= false;
            iterator:= GearsList;
            // Check if there's already a switcher gear
            while (iterator <> nil) do
                begin
                if (iterator^.Kind = gtSwitcher) then
                    begin
                    alreadySwitching:= true;
                    lua_pushnumber(L, iterator^.Uid);
                    break;
                    end;
                iterator:= iterator^.NextGear;
                end;
            if (not alreadySwitching) then
                begin
                // Enable switching and return gear UID
                gear:= AddGear(hwRound(CurrentHedgehog^.Gear^.X), hwRound(CurrentHedgehog^.Gear^.Y), gtSwitcher, 0, _0, _0, 0);
                CurAmmoGear:= gear;
                lastGearByUID:= gear;
                bShowFinger:= false;
                lua_pushnumber(L, gear^.Uid);
                end;
            end
    // Return nil on failure
        else
            lua_pushnil(L)
    else
        lua_pushnil(L);
    lc_enableswitchhog:= 1;
end;

function lc_addammo(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
    at, n, c: LongInt;
const
    call = 'AddAmmo';
    params = 'gearUid, ammoType [, ammoCount]';
begin
    if CheckAndFetchParamCount(L, 2, 3, call, params, n) then
        begin
        at:= LuaToAmmoTypeOrd(L, 2, call, params);
        if (at >= 0) and (TAmmoType(at) <> amNothing) then
            begin
            gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
            if (gear <> nil) and (gear^.Hedgehog <> nil) then
                if n = 2 then
                    AddAmmo(gear^.Hedgehog^, TAmmoType(at))
                else
                    begin
                    c:= Trunc(lua_tonumber(L, 3));
                    if (c = 0) and (CurrentHedgehog = gear^.Hedgehog) and (gear^.Hedgehog^.CurAmmoType = TAmmoType(at)) then
                        ParseCommand('setweap ' + char(0), true, true);
                    SetAmmo(gear^.Hedgehog^, TAmmoType(at), c);
                    end;
            end;
        end;
    lc_addammo:= 0
end;

function lc_getammocount(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
    ammo : PAmmo;
    at   : LongInt;
const
    call = 'GetAmmoCount';
    params = 'gearUid, ammoType';
begin
    if CheckLuaParamCount(L, 2, call, params) then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and (gear^.Hedgehog <> nil) then
            begin
            at:= LuaToAmmoTypeOrd(L, 2, call, params);
            if at >= 0 then
                begin
                ammo:= GetAmmoEntry(gear^.Hedgehog^, TAmmoType(at));
                if ammo^.AmmoType = amNothing then
                    lua_pushnumber(L, 0)
                else
                    lua_pushnumber(L, ammo^.Count);
                end;
            end
        else lua_pushnumber(L, 0);
        end
    else
        lua_pushnil(L);
    lc_getammocount:= 1
end;

function lc_sethealth(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetHealth', 'gearUid, health') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            gear^.Health:= Trunc(lua_tonumber(L, 2));

            if (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
                begin
                if gear^.Health > cMaxHogHealth then
                    gear^.Health:= cMaxHogHealth;
                if gear^.Health < 0 then
                    gear^.Health:= 0;
                RenderHealth(gear^.Hedgehog^);
                RecountTeamHealth(gear^.Hedgehog^.Team)
                end;
            // Why did this do a "setalltoactive" ?
            //SetAllToActive;
            Gear^.Active:= true;
            AllInactive:= false
            end
        end;
    lc_sethealth:= 0
end;

function lc_healhog(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
    healthBoost, n: LongInt;
begin
    if CheckAndFetchParamCountRange(L, 2, 4, 'HealHog', 'gearUid, healthBoost [, showMessage [, tint]]', n) then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        healthBoost:= Trunc(lua_tonumber(L, 2));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) and (healthBoost >= 1) then
            begin
            healthBoost:= IncHogHealth(gear^.Hedgehog, healthBoost);
            RenderHealth(gear^.Hedgehog^);
            RecountTeamHealth(gear^.Hedgehog^.Team);
            if n = 4 then
                HHHeal(gear^.Hedgehog, healthBoost, lua_toboolean(L, 3), Trunc(lua_tonumber(L, 4)))
            else if n = 3 then
                HHHeal(gear^.Hedgehog, healthBoost, lua_toboolean(L, 3))
            else if n = 2 then
                HHHeal(gear^.Hedgehog, healthBoost, true);
            Gear^.Active:= true;
            AllInactive:= false
            end
        end;
    lc_healhog:= 0
end;

function lc_settimer(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetTimer', 'gearUid, timer') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then gear^.Timer:= Trunc(lua_tonumber(L, 2))
        end;
    lc_settimer:= 0
end;

function lc_setflighttime(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetFlightTime', 'gearUid, flighttime') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then gear^.FlightTime:= Trunc(lua_tonumber(L, 2))
        end;
    lc_setflighttime:= 0
end;

function lc_seteffect(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
    t   : LongInt;
const
    call = 'SetEffect';
    params = 'gearUid, effect, effectState';
begin
    if CheckLuaParamCount(L, 3, call, params) then
        begin
        t:= LuaToHogEffectOrd(L, 2, call, params);
        if t >= 0 then
            begin
            gear := GearByUID(Trunc(lua_tonumber(L, 1)));
            if (gear <> nil) and (gear^.Hedgehog <> nil) then
                gear^.Hedgehog^.Effects[THogEffect(t)]:= Trunc(lua_tonumber(L, 3));
            end;
        end;
    lc_seteffect := 0;
end;

function lc_geteffect(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
    t    : LongInt;
const
    call = 'GetEffect';
    params = 'gearUid, effect';
begin
    if CheckLuaParamCount(L, 2, call, params) then
        begin
        t:= LuaToHogEffectOrd(L, 2, call, params);
        if t >= 0 then
            begin
            gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
            if (gear <> nil) and (gear^.Hedgehog <> nil) then
                lua_pushnumber(L, gear^.Hedgehog^.Effects[THogEffect(t)])
            else
                lua_pushnumber(L, 0)
            end;
        end
    else
        lua_pushnumber(L, 0);
    lc_geteffect:= 1
end;

function lc_setstate(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetState', 'gearUid, state') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            gear^.State:= Trunc(lua_tonumber(L, 2));
            SetAllToActive;
            end
        end;
    lc_setstate:= 0
end;

function lc_getstate(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetState', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, gear^.State)
        else
            lua_pushnil(L)
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getstate:= 1
end;

function lc_gettag(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetTag', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, gear^.Tag)
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gettag:= 1
end;

function lc_settag(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetTag', 'gearUid, tag') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            gear^.Tag:= Trunc(lua_tonumber(L, 2));
            SetAllToActive;
            end
        end;
    lc_settag:= 0
end;

function lc_endgame(L : Plua_State) : LongInt; Cdecl;
begin
    L:= L; // avoid compiler hint
    AddGear(0, 0, gtATFinishGame, 0, _0, _0, 3000);
    lc_endgame:= 0
end;

function lc_endturn(L : Plua_State) : LongInt; Cdecl;
var n: LongInt;
const
    call = 'EndTurn';
    params = '[noTaunts]';
begin
    if CheckAndFetchParamCount(L, 0, 1, call, params, n) then
        if n >= 1 then
            LuaNoEndTurnTaunts:= lua_toboolean(L, 1);
    LuaEndTurnRequested:= true;
    lc_endturn:= 0
end;

function lc_retreat(L : Plua_State) : LongInt; Cdecl;
var n, time: LongInt;
    respectFactor: Boolean;
const
    call = 'Retreat';
    params = 'time [, respectGetAwayTimeFactor]';
begin
    if CheckAndFetchParamCount(L, 1, 2, call, params, n) then
        begin
        IsGetAwayTime:= true;
        AttackBar:= 0;
        time:= Trunc(lua_tonumber(L, 1));
        if n = 2 then
            respectFactor:= lua_toboolean(L, 2)
        else
            respectFactor:= True;
        if respectFactor then
            PendingTurnTimeLeft:= (time * cGetAwayTime) div 100
        else
            PendingTurnTimeLeft:= time;
        isPendingTurnTimeLeft:= true;
        if ((CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil)) then
            begin
            CurrentHedgehog^.Gear^.State:= CurrentHedgehog^.Gear^.State or gstAttacked;
            CurrentHedgehog^.Gear^.State:= CurrentHedgehog^.Gear^.State and (not gstAttacking);
            end;
        end;
    lc_retreat:= 0
end;

function lc_skipturn(L : Plua_State): LongInt; Cdecl;
begin
    L:= L; // avoid compiler hint
    ParseCommand('skip', true, true);
    lc_skipturn:= 0;
end;

function lc_sendstat(L : Plua_State) : LongInt; Cdecl;
var statInfo : TStatInfoType;
    i, n     : LongInt;
    color, tn: shortstring;
    needsTn  : boolean;
const
    call = 'SendStat';
    params = 'statInfoType, color [, teamname]';
begin
    if CheckAndFetchParamCount(L, 2, 3, call, params, n) then
        begin
        i:= LuaToStatInfoTypeOrd(L, 1, call, params);
        if i >= 0 then
            begin
            statInfo:= TStatInfoType(i);
            needsTn:= ((statInfo = siPlayerKills) or (statInfo = siClanHealth));
            // check if param count is correct for the used statInfo
            if (n = 3) <> needsTn then
                begin
                if n = 3 then
                    LuaCallError(EnumToStr(statInfo) + ' does not support the teamname parameter', call, params)
                else
                    LuaCallError(EnumToStr(statInfo) + ' requires the teamname parameter', call, params);
                end
            else // count is correct!
                begin
                if needsTn then
                    begin
                    // 3: team name
                    for i:= 0 to Pred(TeamsCount) do
                        begin
                        color:= _S'0';
                        tn:= lua_tostring(L, 3);
                        with TeamsArray[i]^ do
                            begin
                                if TeamName = tn then
                                    begin
                                    color := uUtils.IntToStr(Clan^.Color);
                                    Break;
                                    end
                            end
                        end;
                    if (statInfo = siPlayerKills) then
                        begin
                            SendStat(siPlayerKills, color + ' ' +
                                lua_tostring(L, 2) + ' ' + tn);
                        end
                    else if (statInfo = siClanHealth) then
                        begin
                            SendStat(siClanHealth, color + ' ' +
                                lua_tostring(L, 2));
                        end
                    end
                else
                    begin
                    SendStat(statInfo,lua_tostring(L, 2));
                    end;
                end;
            end;
        end;
    lc_sendstat:= 0
end;

function lc_sendgameresultoff(L : Plua_State) : LongInt; Cdecl;
begin
    L:= L; // avoid compiler hint
    uStats.SendGameResultOn := false;
    lc_sendgameresultoff:= 0
end;

function lc_sendrankingstatsoff(L : Plua_State) : LongInt; Cdecl;
begin
    L:= L; // avoid compiler hint
    uStats.SendRankingStatsOn := false;
    lc_sendrankingstatsoff:= 0
end;

function lc_sendachievementsstatsoff(L : Plua_State) : LongInt; Cdecl;
begin
    L:= L; // avoid compiler hint
    uStats.SendAchievementsStatsOn := false;
    lc_sendachievementsstatsoff:= 0
end;

function lc_sendhealthstatsoff(L : Plua_State) : LongInt; Cdecl;
begin
    L:= L; // avoid compiler hint
    uStats.SendHealthStatsOn := false;
    lc_sendhealthstatsoff:= 0
end;

function lc_findplace(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
    fall: boolean;
    tryhard: boolean;
    left, right, n: LongInt;
begin
    if CheckAndFetchParamCount(L, 4, 5, 'FindPlace', 'gearUid, fall, left, right [, tryHarder]', n) then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        fall:= lua_toboolean(L, 2);
        left:= Trunc(lua_tonumber(L, 3));
        right:= Trunc(lua_tonumber(L, 4));
        if n = 5 then
            tryhard:= lua_toboolean(L, 5)
        else
            tryhard:= false;
        if gear <> nil then
            FindPlace(gear, fall, left, right, tryhard);
        if gear <> nil then
            lua_pushnumber(L, gear^.uid)
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_findplace:= 1
end;

function lc_playsound(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
    n, s: LongInt;
    instaVoice: boolean;
const
    call = 'PlaySound';
    params = 'soundId [, hhGearUid [, instaVoice]]';
begin
    if CheckAndFetchParamCountRange(L, 1, 3, call, params, n) then
        begin
        s:= LuaToSoundOrd(L, 1, call, params);
        if s >= 0 then
            begin
            // no gear specified
            if n = 1 then
                PlaySound(TSound(s), false, true)
            else
                begin
                gear:= GearByUID(Trunc(lua_tonumber(L, 2)));
                if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
                    begin
                    instaVoice:= false;
                    if n = 3 then
                        instaVoice:= lua_toboolean(L, 3);
                    if instaVoice then
                        PlaySoundV(TSound(s), gear^.Hedgehog^.Team^.Voicepack, false, true)
                    else
                        AddVoice(TSound(s), gear^.Hedgehog^.Team^.Voicepack, true, false);
                    end;
                end;
            end;
        end;
    lc_playsound:= 0;
end;

function lc_playmusicsound(L : Plua_State) : LongInt; Cdecl;
var s: LongInt;
const
    call = 'PlayMusicSound';
    params = 'soundId';
begin
    if CheckLuaParamCount(L, 1, call, params) then
        begin
        s:= LuaToSoundOrd(L, 1, call, params);
        if s >= 0 then
            PlayMusicSound(TSound(s))
        end;
    lc_playmusicsound:= 0;
end;

function lc_stopmusicsound(L : Plua_State) : LongInt; Cdecl;
var s: LongInt;
const
    call = 'StopMusicSound';
    params = 'soundId';
begin
    if CheckLuaParamCount(L, 1, call, params) then
        begin
        s:= LuaToSoundOrd(L, 1, call, params);
        if s >= 0 then
            StopMusicSound(TSound(s))
        end;
    lc_stopmusicsound:= 0;
end;


function lc_setsoundmask(L : Plua_State) : LongInt; Cdecl;
var s: LongInt;
    soundState: boolean;
const
    call = 'SetSoundMask';
    params = 'soundId, isMasked';
begin
    if CheckLuaParamCount(L, 2, call, params) then
        begin
        s:= LuaToSoundOrd(L, 1, call, params);
        if s <> Ord(sndNone) then
            begin
            soundState:= lua_toboolean(L, 2);
            MaskedSounds[TSound(s)]:= soundState;
            end;
        end;
    lc_setsoundmask:= 0;
end;

function lc_addteam(L : Plua_State) : LongInt; Cdecl;
var np: LongInt;
    colorArg: Int64;
    colorStr: shortstring;
begin
    if CheckAndFetchParamCount(L, 5, 6, 'AddTeam', 'teamname, color, grave, fort, voicepack [, flag]', np) then
        begin
        colorArg:= Trunc(lua_tonumber(L, 2));
        if (colorArg < 0) and (abs(colorArg) <= cClanColors) then
            // Pick clan color from settings (recommended)
            colorStr:= IntToStr(ClanColorArray[Pred(abs(colorArg))])
        else if (colorArg >= 0) and (colorArg <= $ffffffff) then
            // Specify color directly
            colorStr:= IntToStr(colorArg)
        else
            begin
            OutError('Lua error: AddTeam: Invalid ''color'' argument, must be between '+IntToStr(-cClanColors)+' and 0xffffffff!', true);
            lua_pushnil(L);
            lua_pushnil(L);
            lc_addteam:= 2;
            exit;
            end;
        ParseCommand('addteam x ' + colorStr + ' ' + lua_tostring(L, 1), true, true);
        ParseCommand('grave ' + lua_tostring(L, 3), true, true);
        ParseCommand('fort ' + lua_tostring(L, 4), true, true);
        ParseCommand('voicepack ' + lua_tostring(L, 5), true, true);
        if (np = 6) then ParseCommand('flag ' + lua_tostring(L, 6), true, true);
        // If there's a mission team, copy it's control scheme.
        // So in singleplayer missions, all teams use the player team's controls.
        if MissionTeam <> nil then
            CurrentTeam^.Binds:= MissionTeam^.Binds
        // Default keys otherwise
        else
            CurrentTeam^.Binds:= DefaultBinds;
        // push team name and index
        lua_pushstring(L, str2pchar(CurrentTeam^.TeamName));
        lua_pushnumber(L, TeamsCount - 1);
        end
    else
        begin
        lua_pushnil(L);
        lua_pushnil(L);
        end;
    lc_addteam:= 2;
end;

function lc_addmissionteam(L : Plua_State) : LongInt; Cdecl;
var colorArg: Int64;
    colorStr: shortstring;
begin
    if CheckLuaParamCount(L, 1, 'AddMissionTeam', 'color') then
        begin
        if(MissionTeam = nil) then
            begin
            OutError('Lua error: AddMissionTeam: Could not add team. Note: This function only works in singleplayer missions!', true);
            lc_addmissionteam:= 0;
            exit;
            end;

        colorArg:= Trunc(lua_tonumber(L, 1));
        if (colorArg < 0) and (abs(colorArg) <= cClanColors) then
            // Pick clan color from settings (recommended)
            colorStr:= IntToStr(ClanColorArray[Pred(abs(colorArg))])
        else if (colorArg >= 0) and (colorArg <= $ffffffff) then
            // Specify color directly
            colorStr:= IntToStr(colorArg)
        else
            begin
            OutError('Lua error: AddMissionTeam: Invalid ''color'' argument, must be between '+IntToStr(-cClanColors)+' and 0xffffffff!', true);
            lua_pushnil(L);
            lua_pushnil(L);
            lc_addmissionteam:= 2;
            exit;
            end;

        ParseCommand('addteam x ' + colorStr + ' ' + MissionTeam^.TeamName, true, true);
        ParseCommand('grave ' + MissionTeam^.GraveName, true, true);
        ParseCommand('fort ' + MissionTeam^.FortName, true, true);
        ParseCommand('voicepack ' + MissionTeam^.Voicepack^.name, true, true);
        ParseCommand('flag ' + MissionTeam^.Flag, true, true);
        CurrentTeam^.Binds:= MissionTeam^.Binds;
        // push real team name and team index
        lua_pushstring(L, str2pchar(CurrentTeam^.TeamName));
        lua_pushnumber(L, TeamsCount - 1);
        end
    else
        begin
        lua_pushnil(L);
        lua_pushnil(L);
        end;
    lc_addmissionteam:= 2;
end;

function lc_setteamlabel(L : Plua_State) : LongInt; Cdecl;
var teamValue: ansistring;
    i, n: LongInt;
    success: boolean;
begin
	success:= false;
    if CheckAndFetchParamCount(L, 1, 2, 'SetTeamLabel', 'teamname[, label]', n) then
        begin
        success:= false;
        // fetch team
        if TeamsCount > 0 then
            for i:= 0 to Pred(TeamsCount) do
                begin
                // skip teams that don't have matching name
                if TeamsArray[i]^.TeamName <> lua_tostring(L, 1) then
                    continue;

                // value of type nil? Then let's clear the team value
                if (n < 2) or lua_isnil(L, 2) then
                    begin
                    FreeAndNilTexture(TeamsArray[i]^.LuaTeamValueTex);
                    TeamsArray[i]^.hasLuaTeamValue:= false;
                    success:= true;
                    end
                // value of type string? Then let's set the team value
                else if (lua_isstring(L, 2)) then
                    begin
                    teamValue:= lua_tostring(L, 2);
                    TeamsArray[i]^.LuaTeamValue:= teamValue;
                    FreeAndNilTexture(TeamsArray[i]^.LuaTeamValueTex);
                    TeamsArray[i]^.LuaTeamValueTex := RenderStringTex(teamValue, TeamsArray[i]^.Clan^.Color, fnt16);
                    TeamsArray[i]^.hasLuaTeamValue:= true;
                    success:= true;
                    end;
                // don't change more than one team
                break;
                end;
        end;
    // return true if operation was successful, false otherwise
    lua_pushboolean(L, success);
    lc_setteamlabel:= 1;
end;

function lc_setteampassive(L : Plua_State) : LongInt; Cdecl;
var i, j: LongInt;
    success, passive, passiveClan: boolean;
begin
	success:= false;
    if CheckLuaParamCount(L, 2, 'SetTeamPassive', 'teamname, isPassive') then
        begin
        success:= false;
        // fetch team
        if TeamsCount > 0 then
            for i:= 0 to Pred(TeamsCount) do
                if TeamsArray[i]^.TeamName = lua_tostring(L, 1) then
                    begin
                    passive:= lua_toboolean(L, 2);
                    TeamsArray[i]^.Passive:= passive;
                    // also update clan state
                    if passive then
                        begin
                        passiveClan:= true;
                        for j:= 0 to Pred(TeamsCount) do
                            if (not TeamsArray[j]^.Passive) then
                                begin
                                passiveClan:= false;
                                break;
                                end;
                        end
                    else
                        passiveClan:= false;
                    TeamsArray[i]^.Clan^.Passive:= passiveClan;

                    success:= true;
                    // don't change more than one team
                    break;
                    end;
        end;
    // return true if operation was successful, false otherwise
    lua_pushboolean(L, success);
    lc_setteampassive:= 1;
end;

function lc_getteamname(L : Plua_State) : LongInt; Cdecl;
var t: LongInt;
begin
    if CheckLuaParamCount(L, 1, 'GetTeamName', 'teamIdx') then
        begin
        t:= Trunc(lua_tonumber(L, 1));
        if (t < 0) or (t >= TeamsCount) then
            lua_pushnil(L)
        else
            lua_pushstring(L, str2pchar(TeamsArray[t]^.TeamName));
        end
    else
        lua_pushnil(L);
    lc_getteamname:= 1;
end;

function lc_getteamindex(L : Plua_state) : LongInt; Cdecl;
var i: LongInt;
    found: boolean;
begin
    found:= false;
    if CheckLuaParamCount(L, 1, 'GetTeamIndex', 'teamname') then
        if TeamsCount > 0 then
            for i:= 0 to Pred(TeamsCount) do
                begin
                // skip teams that don't have matching name
                if TeamsArray[i]^.TeamName <> lua_tostring(L, 1) then
                    continue;
                lua_pushnumber(L, i);
                found:= true;
                break;
                end;
    if (not found) then
        lua_pushnil(L);
    lc_getteamindex:= 1;
end;

function lc_getteamclan(L : Plua_state) : LongInt; Cdecl;
var i: LongInt;
    found: boolean;
begin
    found:= false;
    if CheckLuaParamCount(L, 1, 'GetTeamClan', 'teamname') then
        if TeamsCount > 0 then
            for i:= 0 to Pred(TeamsCount) do
                begin
                // skip teams that don't have matching name
                if TeamsArray[i]^.TeamName <> lua_tostring(L, 1) then
                    continue;
                lua_pushnumber(L, TeamsArray[i]^.Clan^.ClanIndex);
                found:= true;
                break;
                end;
    if (not found) then
        lua_pushnil(L);
    lc_getteamclan:= 1;
end;

function lc_dismissteam(L : Plua_State) : LongInt; Cdecl;
var HHGear: PGear;
    i, h  : LongInt;
    hidden: boolean;
begin
    if CheckLuaParamCount(L, 1, 'DismissTeam', 'teamname') then
        begin
        if TeamsCount > 0 then
            for i:= 0 to Pred(TeamsCount) do
                begin
                // skip teams that don't have matching name
                if TeamsArray[i]^.TeamName <> lua_tostring(L, 1) then
                    continue;

                // destroy all hogs of matching team, including the hidden ones
                for h:= 0 to cMaxHHIndex do
                    begin
                    hidden:= (TeamsArray[i]^.Hedgehogs[h].GearHidden <> nil);
                    if hidden then
                        RestoreHog(@TeamsArray[i]^.Hedgehogs[h]);
                    // destroy hedgehog gear, if any
                    HHGear:= TeamsArray[i]^.Hedgehogs[h].Gear;
                    if HHGear <> nil then
                        begin
                        // smoke effect
                        if (not hidden) then
                            begin
                            AddVisualGear(hwRound(HHGear^.X), hwRound(HHGear^.Y), vgtSmokeWhite);
                            AddVisualGear(hwRound(HHGear^.X) - 16 + Random(32), hwRound(HHGear^.Y) - 16 + Random(32), vgtSmokeWhite);
                            AddVisualGear(hwRound(HHGear^.X) - 16 + Random(32), hwRound(HHGear^.Y) - 16 + Random(32), vgtSmokeWhite);
                            AddVisualGear(hwRound(HHGear^.X) - 16 + Random(32), hwRound(HHGear^.Y) - 16 + Random(32), vgtSmokeWhite);
                            AddVisualGear(hwRound(HHGear^.X) - 16 + Random(32), hwRound(HHGear^.Y) - 16 + Random(32), vgtSmokeWhite);
                            end;
                        HHGear^.Message:= HHGear^.Message or gmDestroy;
                        HHGear^.Active:= true;
                        AllInactive:= false;
                        end;
                    end;
                // can't dismiss more than one team
                break;
                end;
        end;
    lc_dismissteam:= 0;
end;

function lc_getteamstats(L : Plua_State) : LongInt; Cdecl;
var i: LongInt;
begin
    if CheckLuaParamCount(L, 1, 'GetTeamStats', 'teamname') then
        begin
        if TeamsCount > 0 then
            for i:= 0 to Pred(TeamsCount) do
                begin
                // skip teams that don't have matching name
                if TeamsArray[i]^.TeamName <> lua_tostring(L, 1) then
                    continue;

                lua_newtable(L);

                lua_pushstring(L, str2pchar('Kills'));
                lua_pushnumber(L, TeamsArray[i]^.stats.Kills);
                lua_settable(L, -3);

                lua_pushstring(L, str2pchar('Suicides'));
                lua_pushnumber(L, TeamsArray[i]^.stats.Suicides);
                lua_settable(L, -3);

                lua_pushstring(L, str2pchar('AIKills'));
                lua_pushnumber(L, TeamsArray[i]^.stats.AIKills);
                lua_settable(L, -3);

                lua_pushstring(L, str2pchar('TeamKills'));
                lua_pushnumber(L, TeamsArray[i]^.stats.TeamKills);
                lua_settable(L, -3);

                lua_pushstring(L, str2pchar('TurnSkips'));
                lua_pushnumber(L, TeamsArray[i]^.stats.TurnSkips);
                lua_settable(L, -3);

                lua_pushstring(L, str2pchar('TeamDamage'));
                lua_pushnumber(L, TeamsArray[i]^.stats.TeamDamage);
                lua_settable(L, -3);

                end;
        end
    else
        lua_pushnil(L);
    lc_getteamstats:= 1;
end;



function lc_addhog(L : Plua_State) : LongInt; Cdecl;
var hatName: ShortString;
begin
    if CheckLuaParamCount(L, 4, 'AddHog', 'hogname, botlevel, health, hat') then
        begin
        hatName:= lua_tostring(L, 4);
        ParseCommand('addhh ' + lua_tostring(L, 2) + ' ' + lua_tostring(L, 3) + ' ' + lua_tostring(L, 1), true, true);
        ParseCommand('hat ' + hatName, true, true);
        lua_pushnumber(L, CurrentHedgehog^.Gear^.uid);
        end
    else
        lua_pushnil(L);
    lc_addhog:= 1;
end;

function lc_addmissionhog(L : Plua_State) : LongInt; Cdecl;
var hatName: ShortString;
begin
    if CheckLuaParamCount(L, 1, 'AddMissionHog', 'health') then
        begin
        if(MissionTeam = nil) then
            begin
            OutError('Lua error: AddMissionHog: Could not add hog. Mission team is not set!', true);
            lua_pushnil(L);
            lc_addmissionhog:= 1;
            exit;
            end;
        with MissionTeam^.Hedgehogs[CurrentTeam^.HedgehogsNumber] do
            begin
            hatName:= Hat;
            ParseCommand('addhh ' + IntToStr(BotLevel) + ' ' + lua_tostring(L, 1) + ' ' + Name, true, true);
            ParseCommand('hat ' + hatName, true, true);
            end;
        lua_pushnumber(L, CurrentHedgehog^.Gear^.uid);
        end
    else
        lua_pushnil(L);
    lc_addmissionhog:= 1;
end;

function lc_hogturnleft(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 2, 'HogTurnLeft', 'gearUid, boolean') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            gear^.dX.isNegative:= lua_toboolean(L, 2);
        end;
    lc_hogturnleft:= 0;
end;

function lc_getgearposition(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearPosition', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            lua_pushnumber(L, hwRound(gear^.X));
            lua_pushnumber(L, hwRound(gear^.Y))
            end
        else
            begin
            lua_pushnil(L);
            lua_pushnil(L)
            end;
        end
    else
        begin
        lua_pushnil(L);
        lua_pushnil(L)
        end;
    lc_getgearposition:= 2;
end;

function lc_setgearposition(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
    col: boolean;
    x, y: LongInt;
begin
    if CheckLuaParamCount(L, 3, 'SetGearPosition', 'gearUid, x, y') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            col:= gear^.CollisionIndex >= 0;
            x:= Trunc(lua_tonumber(L, 2));
            y:= Trunc(lua_tonumber(L, 3));
            if col then
                DeleteCI(gear);
            gear^.X:= int2hwfloat(x);
            gear^.Y:= int2hwfloat(y);
            if col then
                AddCI(gear);
            SetAllToActive
            end
        end;
    lc_setgearposition:= 0
end;

function lc_getgeartarget(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearTarget', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            lua_pushnumber(L, gear^.Target.X);
            lua_pushnumber(L, gear^.Target.Y)
            end
        else
            begin
            lua_pushnil(L);
            lua_pushnil(L)
            end
        end
    else
        begin
        lua_pushnil(L);
        lua_pushnil(L)
        end;
    lc_getgeartarget:= 2;
end;

function lc_setgeartarget(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 3, 'SetGearTarget', 'gearUid, x, y') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            gear^.Target.X:= Trunc(lua_tonumber(L, 2));
            gear^.Target.Y:= Trunc(lua_tonumber(L, 3))
            end
        end;
    lc_setgeartarget:= 0
end;

function lc_getgearvelocity(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
var t: LongInt;
begin
    if CheckLuaParamCount(L, 1, 'GetGearVelocity', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            t:= hwRound(gear^.dX * 1000000);
            // gear dX determines hog orientation
            if (gear^.dX.isNegative) and (t = 0) then t:= -1;
            lua_pushnumber(L, t);
            lua_pushnumber(L, hwRound(gear^.dY * 1000000))
            end
        end
    else
        begin
        lua_pushnil(L);
        lua_pushnil(L);
        end;
    lc_getgearvelocity:= 2;
end;

function lc_setgearvelocity(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 3, 'SetGearVelocity', 'gearUid, dx, dy') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            begin
            gear^.dX:= int2hwFloat(Trunc(lua_tonumber(L, 2))) / 1000000;
            gear^.dY:= int2hwFloat(Trunc(lua_tonumber(L, 3))) / 1000000;
            SetAllToActive;
            end
        end;
    lc_setgearvelocity:= 0
end;

function lc_setzoom(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'SetZoom', 'zoomLevel') then
        begin
        ZoomValue:= lua_tonumber(L, 1);
        if ZoomValue < cMaxZoomLevel then
            ZoomValue:= cMaxZoomLevel;
        if ZoomValue > cMinZoomLevel then
            ZoomValue:= cMinZoomLevel;
        end;
    lc_setzoom:= 0
end;

function lc_getzoom(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'GetZoom', '') then
        lua_pushnumber(L, ZoomValue)
    else
        lua_pushnil(L);
    lc_getzoom:= 1
end;

function lc_setammo(L : Plua_State) : LongInt; Cdecl;
var np, at: LongInt;
const
    call = 'SetAmmo';
    params = 'ammoType, count, probability, delay [, numberInCrate]';
begin
    if CheckAndFetchParamCount(L, 4, 5, call, params, np) then
        begin
        at:= LuaToAmmoTypeOrd(L, 1, call, params);
        if at >= 0 then
            begin
            if np = 4 then
                ScriptSetAmmo(TAmmoType(at), Trunc(lua_tonumber(L, 2)), Trunc(lua_tonumber(L, 3)), Trunc(lua_tonumber(L, 4)), 1)
            else
                ScriptSetAmmo(TAmmoType(at), Trunc(lua_tonumber(L, 2)), Trunc(lua_tonumber(L, 3)), Trunc(lua_tonumber(L, 4)), Trunc(lua_tonumber(L, 5)));
            end;
        end;
    lc_setammo:= 0
end;


function lc_getammo(L : Plua_State) : LongInt; Cdecl;
var i, at, rawProb, probLevel: LongInt;
const
    call = 'GetAmmo';
    params = 'ammoType';
begin
    lc_getammo:= 0;
    if CheckLuaParamCount(L, 1, call, params) then
        begin
        at:= LuaToAmmoTypeOrd(L, 1, call, params);
        if at >= 0 then
            begin
            // Ammo count
            i:= InitialAmmoCounts[TAmmoType(at)];
            if i = AMMO_INFINITE then
                i:= 9;
            lua_pushnumber(L, i);
            // Probability
            rawProb:=  Ammoz[TAmmoType(at)].Probability;
            probLevel:= -1;
            for i := 0 to High(probabilityLevels) do
                if rawProb = probabilityLevels[i] then
                    probLevel:= i;
            lua_pushnumber(L, probLevel);
            // Delay in turns
            lua_pushnumber(L, Ammoz[TAmmoType(at)].SkipTurns);
            // Number in case
            lua_pushnumber(L, Ammoz[TAmmoType(at)].NumberInCase);
            lc_getammo:= 4
            end
        end;
end;


function lc_setammodelay(L : Plua_State) : LongInt; Cdecl;
var at, delay: LongInt;
const
    call = 'SetAmmoDelay';
    params = 'ammoType, delay';
begin
    if CheckLuaParamCount(L, 2, call, params) then
        begin
        at:= LuaToAmmoTypeOrd(L, 1, call, params);
        delay:= Trunc(lua_tonumber(L, 2));
        if (at >= 0) and (TAmmoType(at) <> amNothing) then
            begin
            ScriptSetAmmoDelay(TAmmoType(at), delay);
            // Unselect weapon if neccessary
            if (delay > 0) and (CurrentHedgehog <> nil) and (CurrentHedgehog^.CurAmmoType = TAmmoType(at)) then
                ParseCommand('setweap ' + char(0), true, true);
            end;
        end;
    lc_setammodelay:= 0
end;

function lc_getrandom(L : Plua_State) : LongInt; Cdecl;
var m : LongInt;
begin
    if CheckLuaParamCount(L, 1, 'GetRandom', 'number') then
        begin
        m:= Trunc(lua_tonumber(L, 1));
        if (m > 0) then
            lua_pushnumber(L, GetRandom(m))
        else
            begin
            LuaError('Lua: Tried to pass 0 to GetRandom!');
            lua_pushnil(L);
            end
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getrandom:= 1
end;

function lc_setwind(L : Plua_State) : LongInt; Cdecl;
var vg: PVisualGear;
begin
    if CheckLuaParamCount(L, 1, 'SetWind', 'windSpeed') then
        begin
        cWindSpeed:= int2hwfloat(Trunc(lua_tonumber(L, 1))) / 100 * cMaxWindSpeed;
        cWindSpeedf:= SignAs(cWindSpeed,cWindSpeed).QWordValue / SignAs(_1,_1).QWordValue;
        if cWindSpeed.isNegative then
            cWindSpeedf := -cWindSpeedf;
        vg:= AddVisualGear(0, 0, vgtSmoothWindBar);
        if vg <> nil then vg^.dAngle:= hwFloat2Float(cWindSpeed);
            AddFileLog('Script set wind = '+FloatToStr(cWindSpeed));
        end;
    lc_setwind:= 0
end;

function lc_getwind(L : Plua_State) : LongInt; Cdecl;
var wind: extended;
begin
    if CheckLuaParamCount(L, 0, 'GetWind', '') then
        begin
        wind:= hwFloat2float((cWindSpeed / cMaxWindSpeed) * 100);
        if wind < -100 then
            wind:= -100
        else if wind > 100 then
            wind:= 100;
        lua_pushnumber(L, wind);
        end
    else
        lua_pushnil(L);
    lc_getwind:= 1
end;

function lc_maphasborder(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'MapHasBorder', '') then
        lua_pushboolean(L, hasBorder)
    else
        lua_pushnil(L);
    lc_maphasborder:= 1
end;

function lc_getgearradius(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearRadius', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            lua_pushnumber(L, gear^.Radius)
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getgearradius:= 1
end;

function lc_gethoghat(L : Plua_State): LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogHat', 'gearUid') then
        begin
        gear := GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Hat))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L);
    lc_gethoghat := 1;
end;

function lc_sethoghat(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
    hat: ShortString;
begin
    if CheckLuaParamCount(L, 2, 'SetHogHat', 'gearUid, hat') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            begin
            hat:= lua_tostring(L, 2);
            gear^.Hedgehog^.Hat:= hat;
            AddFileLog('Changed hat to: '+hat);
            if (Length(hat) > 39) and (Copy(hat,1,8) = 'Reserved') and (Copy(hat,9,32) = gear^.Hedgehog^.Team^.PlayerHash) then
                LoadHedgehogHat(gear^.Hedgehog^, 'Reserved/' + Copy(hat,9,Length(hat)-8))
            else
                LoadHedgehogHat(gear^.Hedgehog^, hat)
            end
        end;
    lc_sethoghat:= 0;
end;

function lc_placesprite(L : Plua_State) : LongInt; Cdecl;
var spr   : TSprite;
    lf    : Word;
    tint  : LongWord;
    i, n : LongInt;
    placed, behind, flipHoriz, flipVert : boolean;
const
    call = 'PlaceSprite';
    params = 'x, y, sprite, frameIdx, tint, behind, flipHoriz, flipVert [, landFlag, ... ]';
begin
    placed:= false;
    if CheckAndFetchLuaParamMinCount(L, 4, call, params, n) then
        begin
        if not lua_isnoneornil(L, 5) then
            tint := Trunc(lua_tonumber(L, 5))
        else tint := $FFFFFFFF;
        if not lua_isnoneornil(L, 6) then
            behind := lua_toboolean(L, 6)
        else behind := false;
        if not lua_isnoneornil(L, 7) then
            flipHoriz := lua_toboolean(L, 7)
        else flipHoriz := false;
        if not lua_isnoneornil(L, 8) then
            flipVert := lua_toboolean(L, 8)
        else flipVert := false;
        lf:= 0;

        // accept any amount of landflags, loop is never executed if n<9
        for i:= 9 to n do
            lf:= lf or Trunc(lua_tonumber(L, i));

        n:= LuaToSpriteOrd(L, 3, call, params);
        if n >= 0 then
            begin
            spr:= TSprite(n);
            if SpritesData[spr].Surface = nil then
                LuaError(call + ': ' + EnumToStr(spr) + ' cannot be placed! (required information not loaded)' )
            else
                placed:= ForcePlaceOnLand(
                    Trunc(lua_tonumber(L, 1)) - SpritesData[spr].Width div 2,
                    Trunc(lua_tonumber(L, 2)) - SpritesData[spr].Height div 2,
                    spr, Trunc(lua_tonumber(L, 4)), lf, tint, behind, flipHoriz, flipVert);
            end;
        end;

    lua_pushboolean(L, placed);
    lc_placesprite:= 1
end;

function lc_erasesprite(L : Plua_State) : LongInt; Cdecl;
var spr   : TSprite;
    lf    : Word;
    i, n : LongInt;
    eraseOnLFMatch, onlyEraseLF, flipHoriz, flipVert : boolean;
const
    call = 'EraseSprite';
    params = 'x, y, sprite, frameIdx, eraseOnLFMatch, onlyEraseLF, flipHoriz, flipVert [, landFlag, ... ]';
begin
    if CheckAndFetchLuaParamMinCount(L, 4, call, params, n) then
        begin
        if not lua_isnoneornil(L, 5) then
            eraseOnLFMatch := lua_toboolean(L, 5)
        else eraseOnLFMatch := false;
        if not lua_isnoneornil(L, 6) then
            onlyEraseLF := lua_toboolean(L, 6)
        else onlyEraseLF := false;
        if not lua_isnoneornil(L, 7) then
            flipHoriz := lua_toboolean(L, 7)
        else flipHoriz := false;
        if not lua_isnoneornil(L, 8) then
            flipVert := lua_toboolean(L, 8)
        else flipVert := false;
        lf:= 0;

        // accept any amount of landflags, loop is never executed if n<9
        for i:= 9 to n do
            lf:= lf or Trunc(lua_tonumber(L, i));

        n:= LuaToSpriteOrd(L, 3, call, params);
        if n >= 0 then
            begin
            spr:= TSprite(n);
            if SpritesData[spr].Surface = nil then
                LuaError(call + ': ' + EnumToStr(spr) + ' cannot be placed! (required information not loaded)' )
            else
                EraseLand(
                    Trunc(lua_tonumber(L, 1)) - SpritesData[spr].Width div 2,
                    Trunc(lua_tonumber(L, 2)) - SpritesData[spr].Height div 2,
                    spr, Trunc(lua_tonumber(L, 4)), lf, eraseOnLFMatch, onlyEraseLF, flipHoriz, flipVert);
            end;
        end;
    lc_erasesprite:= 0
end;

function lc_placegirder(L : Plua_State) : LongInt; Cdecl;
var placed: boolean;
begin
    placed:= false;
    if CheckLuaParamCount(L, 3, 'PlaceGirder', 'x, y, frameIdx') then
        placed:= TryPlaceOnLandSimple(
            Trunc(lua_tonumber(L, 1)) - SpritesData[sprAmGirder].Width div 2,
            Trunc(lua_tonumber(L, 2)) - SpritesData[sprAmGirder].Height div 2,
            sprAmGirder, Trunc(lua_tonumber(L, 3)), true, false);

    lua_pushboolean(L, placed);
    lc_placegirder:= 1
end;

function lc_placerubber(L : Plua_State) : LongInt; Cdecl;
var placed: boolean;
begin
    placed:= false;
    if CheckLuaParamCount(L, 3, 'PlaceRubber', 'x, y, frameIdx') then
        placed:= TryPlaceOnLand(
            Trunc(lua_tonumber(L, 1)) - SpritesData[sprAmRubber].Width div 2,
            Trunc(lua_tonumber(L, 2)) - SpritesData[sprAmRubber].Height div 2,
            sprAmRubber, Trunc(lua_tonumber(L, 3)), true, lfBouncy);

    lua_pushboolean(L, placed);
    lc_placerubber:= 1
end;

function lc_getcurammotype(L : Plua_State): LongInt; Cdecl;
begin
    if (CurrentHedgehog <> nil) and (CheckLuaParamCount(L, 0, 'GetCurAmmoType', '')) then
        lua_pushnumber(L, ord(CurrentHedgehog^.CurAmmoType))
    else
        lua_pushnumber(L, ord(amNothing));
    lc_getcurammotype := 1;
end;

function lc_savecampaignvar(L : Plua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 2, 'SaveCampaignVar', 'varname, value') then
        SendIPC('V!' + lua_tostring(L, 1) + ' ' + lua_tostring(L, 2) + #0);
    lc_savecampaignvar := 0;
end;

function lc_getcampaignvar(L : Plua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'GetCampaignVar', 'varname') then
        SendIPCAndWaitReply('V?' + lua_tostring(L, 1) + #0);
    lua_pushstring(L, str2pchar(CampaignVariable));
    lc_getcampaignvar := 1;
end;

function lc_savemissionvar(L : Plua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 2, 'SaveMissionVar', 'varname, value') then
        SendIPC('v!' + lua_tostring(L, 1) + ' ' + lua_tostring(L, 2) + #0);
    lc_savemissionvar := 0;
end;

function lc_getmissionvar(L : Plua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'GetMissionVar', 'varname') then
        SendIPCAndWaitReply('v?' + lua_tostring(L, 1) + #0);
    lua_pushstring(L, str2pchar(MissionVariable));
    lc_getmissionvar := 1;
end;

function lc_hidehog(L: Plua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 1, 'HideHog', 'gearUid') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and (gear^.hedgehog <> nil) then
            begin
            HideHog(gear^.hedgehog);
            lua_pushboolean(L, true);
            end
        else
            lua_pushboolean(L, false);
        end;
    lc_hidehog := 1;
end;

function lc_restorehog(L: Plua_State): LongInt; Cdecl;
var i, h: LongInt;
    uid: LongWord;
begin
    if CheckLuaParamCount(L, 1, 'RestoreHog', 'gearUid') then
        begin
        uid:= LongWord(Trunc(lua_tonumber(L, 1)));
        if TeamsCount > 0 then
            for i:= 0 to Pred(TeamsCount) do
                for h:= 0 to cMaxHHIndex do
                    if (TeamsArray[i]^.Hedgehogs[h].GearHidden <> nil) and (TeamsArray[i]^.Hedgehogs[h].GearHidden^.uid = uid) then
                        begin
                        RestoreHog(@TeamsArray[i]^.Hedgehogs[h]);
                        exit(0)
                        end
        end;
    lc_restorehog := 0;
end;

function lc_ishoghidden(L: Plua_State): LongInt; Cdecl;
var i, h: LongInt;
    uid: LongWord;
    gear: PGear;
begin
    if CheckLuaParamCount(L, 1, 'IsHogHidden', 'gearUid') then
        begin
        uid:= LongWord(Trunc(lua_tonumber(L, 1)));
        gear:= GearByUID(uid);
        if (gear <> nil) and (gear^.hedgehog <> nil) then
            begin
            lua_pushboolean(L, false);
            lc_ishoghidden:= 1;
            exit;
            end
        else
            if TeamsCount > 0 then
                for i:= 0 to Pred(TeamsCount) do
                    for h:= 0 to cMaxHHIndex do
                        if (TeamsArray[i]^.Hedgehogs[h].GearHidden <> nil) and (TeamsArray[i]^.Hedgehogs[h].GearHidden^.uid = uid) then
                            begin
                            lua_pushboolean(L, true);
                            lc_ishoghidden:= 1;
                            exit;
                            end
        end;
    lua_pushnil(L);
    lc_ishoghidden:= 1;
end;

// boolean TestRectForObstacle(x1, y1, x2, y2, landOnly)
function lc_testrectforobstacle(L : Plua_State) : LongInt; Cdecl;
var rtn: Boolean;
begin
    if CheckLuaParamCount(L, 5, 'TestRectForObstacle', 'x1, y1, x2, y2, landOnly') then
        begin
        rtn:= TestRectangleForObstacle(
                    Trunc(lua_tonumber(L, 1)),
                    Trunc(lua_tonumber(L, 2)),
                    Trunc(lua_tonumber(L, 3)),
                    Trunc(lua_tonumber(L, 4)),
                    lua_toboolean(L, 5)
                    );
        lua_pushboolean(L, rtn);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_testrectforobstacle:= 1
end;


function lc_getgravity(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'GetGravity', '') then
        lua_pushnumber(L, hwRound(SignAs(_0_5, cGravity) + (cGravity * 50 / cMaxWindSpeed)));
    lc_getgravity:= 1
end;

function lc_setgravity(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'SetGravity', 'percent') then
        begin
        cGravity:= _0_02 * Trunc(lua_tonumber(L, 1)) * cMaxWindSpeed;
        cGravityf:= 0.00025 * Trunc(lua_tonumber(L, 1)) * 0.02
        end;
    lc_setgravity:= 0
end;

function lc_setwaterline(L : Plua_State) : LongInt; Cdecl;
var iterator: PGear;
begin
    if CheckLuaParamCount(L, 1, 'SetWaterLine', 'waterline') then
        begin
        cWaterLine:= Trunc(lua_tonumber(L,1));
        AllInactive:= false;
        iterator:= GearsList;
        while iterator <> nil do
            begin
            if not (iterator^.Kind in [gtPortal, gtAirAttack]) and (iterator^.Message and (gmAllStoppable or gmLJump or gmHJump) = 0) then
                begin
                iterator^.Active:= true;
                if iterator^.dY.QWordValue = 0 then iterator^.dY.isNegative:= false;
                iterator^.State:= iterator^.State or gstMoving;
                DeleteCI(iterator)
                end;
            iterator:= iterator^.NextGear
            end
        end;
    lc_setwaterline:= 0
end;

function lc_setgearaihints(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetGearAIHints', 'gearUid, aiHints') then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if gear <> nil then
            gear^.aihints:= Trunc(lua_tonumber(L, 2));
        end;
    lc_setgearaihints:= 0
end;


function lc_hedgewarsscriptload(L : Plua_State) : LongInt; Cdecl;
var success : boolean;
    n : LongInt;
begin
	success:= false;
    if CheckAndFetchParamCount(L, 1, 2, 'HedgewarsScriptLoad', 'scriptPath [, mustExist]', n) then
        begin
        if n = 1 then
            success:= ScriptLoad(lua_tostring(L, 1), true)
        else
            success:= ScriptLoad(lua_tostring(L, 1), lua_toboolean(L, 2));
        end
    else
        success:= false;
    lua_pushboolean(L, success);
    lc_hedgewarsscriptload:= 1;
end;


function lc_declareachievement(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 4, 'DeclareAchievement', 'achievementId, teamname, location, value') then
        declareAchievement(lua_tostring(L, 1), lua_tostring(L, 2), lua_tostring(L, 3), Trunc(lua_tonumber(L, 4)));
    lc_declareachievement:= 0
end;

function lc_getammoname(L : Plua_state) : LongInt; Cdecl;
var np, at: LongInt;
    ignoreOverwrite: Boolean;
const call = 'GetAmmoName';
      params = 'ammoType [, ignoreOverwrite ]';
begin
    if CheckAndFetchParamCountRange(L, 1, 2, call, params, np) then
        begin
        at:= LuaToAmmoTypeOrd(L, 1, call, params);
        ignoreOverwrite := false;
        if np > 1 then
            ignoreOverwrite := lua_toboolean(L, 2);
        if at >= 0 then
            if (not ignoreOverwrite) and (length(trluaammo[Ammoz[TAmmoType(at)].NameId]) > 0) then
                lua_pushstring(L, PChar(trluaammo[Ammoz[TAmmoType(at)].NameId]))
            else
                lua_pushstring(L, PChar(trammo[Ammoz[TAmmoType(at)].NameId]));
        end
    else
        lua_pushnil(L);
    lc_getammoname:= 1;
end;

function lc_getammotimer(L : Plua_state) : LongInt; Cdecl;
var at: LongInt;
    weapon: PAmmo;
    gear: PGear;
const call = 'GetAmmoTimer';
      params = 'gearUid, ammoType';
begin
    if CheckLuaParamCount(L, 2, call, params) then
        begin
        gear:= GearByUID(Trunc(lua_tonumber(L, 1)));
        if (gear <> nil) and (gear^.Hedgehog <> nil) then
            begin
            at:= LuaToAmmoTypeOrd(L, 2, call, params);
            weapon:= GetAmmoEntry(gear^.Hedgehog^, TAmmoType(at));
            if (Ammoz[TAmmoType(at)].Ammo.Propz and ammoprop_Timerable) <> 0 then
                lua_pushnumber(L, weapon^.Timer)
            else
                lua_pushnil(L);
            end
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L);
    lc_getammotimer:= 1;
end;

function lc_setvampiric(L : Plua_state) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'SetVampiric', 'bool') then
        cVampiric := lua_toboolean(L, 1);
    lc_setvampiric := 0;
end;

function lc_getvampiric(L : Plua_state) : LongInt; Cdecl;
begin
    lua_pushboolean(L, cVampiric);
    lc_getvampiric := 1;
end;

function lc_setlasersight(L : Plua_state) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'SetLaserSight', 'bool') then
        cLaserSighting:= lua_toboolean(L, 1);
    lc_setlasersight:= 0;
end;

function lc_getlasersight(L : Plua_state) : LongInt; Cdecl;
begin
    lua_pushboolean(L, cLaserSighting);
    lc_getlasersight:= 1;
end;

function lc_explode(L : Plua_state) : LongInt; Cdecl;
var mask: LongWord;
    n: LongInt;
begin
    if CheckAndFetchParamCount(L, 3, 4, 'Explode', 'x, y, radius[, options]', n) then
        if CurrentHedgehog <> nil then
            begin
            mask:= EXPLAutoSound;
            if (n = 4) then
                mask:= Trunc(lua_tonumber(L, 4));
            doMakeExplosion(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)), Trunc(lua_tonumber(L, 3)), CurrentHedgehog, mask);
            lua_pushboolean(L, true);
            end
        else
            lua_pushboolean(L, false)
    else
        lua_pushboolean(L, false);
    lc_explode:= 1;
end;

function lc_setturntimeleft(L : Plua_State) : LongInt; Cdecl;
var number: Int64;
begin
    if CheckLuaParamCount(L, 1, 'SetTurnTimeLeft', 'newTurnTimeLeft') then
        begin
        number:= Trunc(lua_tonumber(L, 1));
        if number < 0 then
            number:= 0;
        if number > cMaxTurnTime then
            number:= cMaxTurnTime;
        // The real TurnTimeLeft will be set in SetGlobals
        PendingTurnTimeLeft:= number;
        isPendingTurnTimeLeft:= true;
        end;
    lc_setturntimeleft:= 0;
end;

function lc_setreadytimeleft(L : Plua_State) : LongInt; Cdecl;
var number: Int64;
begin
    if CheckLuaParamCount(L, 1, 'SetReadyTimeLeft', 'newReadyTimeLeft') then
        begin
        number:= Trunc(lua_tonumber(L, 1));
        if number < 0 then
            number:= 0;
        if number > cMaxTurnTime then
            number:= cMaxTurnTime;
        // The real ReadyTimeLeft will be set in SetGlobals
        PendingReadyTimeLeft:= number;
        isPendingReadyTimeLeft:= true;
        end;
    lc_setreadytimeleft:= 0;
end;

function lc_setturntimepaused(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'SetTurnTimePaused', 'isPaused') then
        LuaClockPaused:= lua_toboolean(L, 1);
    lc_setturntimepaused:= 0;
end;

function lc_getturntimepaused(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'GetTurnTimePaused', '') then
        lua_pushboolean(L, LuaClockPaused)
    else
        lua_pushnil(L);
    lc_getturntimepaused:= 1;
end;

function lc_startghostpoints(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'StartGhostPoints', 'count') then
        startGhostPoints(Trunc(lua_tonumber(L, 1)));
    lc_startghostpoints:= 0
end;

function lc_dumppoint(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 2, 'DumpPoint', 'x, y') then
        dumpPoint(Trunc(lua_tonumber(L, 1)), Trunc(lua_tonumber(L, 2)));
    lc_dumppoint:= 0
end;


procedure ScriptFlushPoints();
begin
    ParseCommand('draw ' + PointsBuffer, true, true);
    PointsBuffer:= '';
end;


function lc_addPoint(L : Plua_State) : LongInt; Cdecl;
var np, param: LongInt;
begin
    if CheckAndFetchParamCountRange(L, 2, 4, 'AddPoint', 'x, y [, width [, erase] ]', np) then
        begin
        // x
        param:= LongInt(Trunc(lua_tonumber(L,1)));
        PointsBuffer:= PointsBuffer + char((param shr 8) and $FF);
        PointsBuffer:= PointsBuffer + char((param and $FF));
        // y
        param:= LongInt(Trunc(lua_tonumber(L,2)));
        PointsBuffer:= PointsBuffer + char((param shr 8) and $FF);
        PointsBuffer:= PointsBuffer + char((param and $FF));
        // width
        if np > 2 then
            begin
            param:= Trunc(lua_tonumber(L,3));
            param:= (param or $80);
            // erase
            if (np > 3) and lua_toboolean(L, 4) then
                param:= (param or $40);
            PointsBuffer:= PointsBuffer + char(param);
            end
        // no width defined
        else
            PointsBuffer:= PointsBuffer + char(0);

        // flush before shortstring limit length is reached
        if length(PointsBuffer) > 245 then
            ScriptFlushPoints();
        end;
    lc_addPoint:= 0
end;


function lc_flushPoints(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'FlushPoints', '') then
        if length(PointsBuffer) > 0 then
            ScriptFlushPoints();
    lc_flushPoints:= 0
end;

// stuff for lua tests
function lc_endluatest(L : Plua_State) : LongInt; Cdecl;
var rstring: shortstring;
const
    call = 'EndLuaTest';
    params = 'TEST_SUCCESSFUL or TEST_FAILED';
begin
    if CheckLuaParamCount(L, 1, call, params) then
        begin

        case Trunc(lua_tonumber(L, 1)) of
            HaltTestSuccess : rstring:= 'Success';
            HaltTestFailed: rstring:= 'FAILED';
        else
            begin
            LuaCallError('Parameter must be either ' + params, call, params);
            exit(0);
            end;
        end;

        if cTestLua then
            begin
            WriteLnToConsole('Lua test finished, result: ' + rstring);
            halt(Trunc(lua_tonumber(L, 1)));
            end
        else LuaError('Not in lua test mode, engine will keep running. Reported test result: ' + rstring);

        end;

    lc_endluatest:= 0;
end;
///////////////////

procedure ScriptPrintStack;
var n, i : LongInt;
begin
    n:= lua_gettop(luaState);
    WriteLnToConsole('Lua: Stack (' + inttostr(n) + ' elements):');
    for i:= 1 to n do
        if not lua_isboolean(luaState, i) then
            WriteLnToConsole('Lua:  ' + inttostr(i) + ': ' + lua_tostring(luaState, i))
        else if lua_toboolean(luaState, i) then
            WriteLnToConsole('Lua:  ' + inttostr(i) + ': true')
        else
            WriteLnToConsole('Lua:  ' + inttostr(i) + ': false');
end;

procedure ScriptClearStack;
begin
    lua_settop(luaState, 0)
end;

procedure ScriptSetNil(name : shortstring);
begin
    lua_pushnil(luaState);
    lua_setglobal(luaState, Str2PChar(name));
end;

procedure ScriptSetInteger(name : shortstring; value : LongInt);
begin
    lua_pushnumber(luaState, value);
    lua_setglobal(luaState, Str2PChar(name));
end;

procedure ScriptSetString(name : shortstring; value : shortstring);
begin
    lua_pushstring(luaState, Str2PChar(value));
    lua_setglobal(luaState, Str2PChar(name));
end;

function ScriptGetInteger(name : shortstring) : LongInt;
begin
    lua_getglobal(luaState, Str2PChar(name));
    ScriptGetInteger:= Trunc(lua_tonumber(luaState, -1));
    lua_pop(luaState, 1);
end;

function ScriptGetString(name : shortstring) : shortstring;
begin
    lua_getglobal(luaState, Str2PChar(name));
    ScriptGetString:= lua_tostring(luaState, -1);
    lua_pop(luaState, 1);
end;

function ScriptGetAnsiString(name : shortstring) : ansistring;
begin
    lua_getglobal(luaState, Str2PChar(name));
    ScriptGetAnsiString:= lua_tostringa(luaState, -1);
    lua_pop(luaState, 1);
end;

procedure ScriptOnPreviewInit;
begin
// not required if there is no script to run
if not ScriptLoaded then
    exit;

ScriptSetString('Seed', cSeed);
ScriptSetInteger('TemplateFilter', cTemplateFilter);
ScriptSetInteger('TemplateNumber', LuaTemplateNumber);
ScriptSetInteger('MapGen', ord(cMapGen));
ScriptSetInteger('MapFeatureSize', cFeatureSize);

ScriptCall('onPreviewInit');

// pop game variables
ParseCommand('seed ' + ScriptGetString('Seed'), true, true);
cTemplateFilter  := ScriptGetInteger('TemplateFilter');
LuaTemplateNumber:= ScriptGetInteger('TemplateNumber');
cMapGen          := TMapGen(ScriptGetInteger('MapGen'));
cFeatureSize     := ScriptGetInteger('MapFeatureSize');
end;

procedure ScriptOnGameInit;
var i, j, k: LongInt;
begin
// not required if there is no script to run
if not ScriptLoaded then
    exit;

// push game variables so they may be modified by the script
ScriptSetInteger('CursorX', NoPointX);
ScriptSetInteger('CursorY', NoPointX);
ScriptSetInteger('GameFlags', GameFlags);
ScriptSetInteger('WorldEdge', ord(WorldEdge));
ScriptSetString('Seed', cSeed);
ScriptSetInteger('TemplateFilter', cTemplateFilter);
ScriptSetInteger('TemplateNumber', LuaTemplateNumber);
ScriptSetInteger('MapGen', ord(cMapGen));
ScriptSetInteger('MapFeatureSize', cFeatureSize);
ScriptSetInteger('ScreenHeight', cScreenHeight);
ScriptSetInteger('ScreenWidth', cScreenWidth);
ScriptSetInteger('TurnTime', cHedgehogTurnTime);
ScriptSetInteger('CaseFreq', cCaseFactor);
ScriptSetInteger('MaxCaseDrops', cMaxCaseDrops);
ScriptSetInteger('HealthCaseProb', cHealthCaseProb);
ScriptSetInteger('HealthCaseAmount', cHealthCaseAmount);
ScriptSetInteger('InitHealth', cInitHealth);
ScriptSetInteger('DamagePercent', cDamagePercent);
ScriptSetInteger('RopePercent', cRopePercent);
ScriptSetInteger('MinesNum', cLandMines);
ScriptSetInteger('MinesTime', cMinesTime);
ScriptSetInteger('MineDudPercent', cMineDudPercent);
ScriptSetInteger('AirMinesNum', cAirMines);
ScriptSetInteger('Explosives', cExplosives);
ScriptSetInteger('Delay', cInactDelay);
ScriptSetInteger('Ready', cReadyDelay);
ScriptSetInteger('SuddenDeathTurns', cSuddenDTurns);
ScriptSetInteger('WaterRise', cWaterRise);
ScriptSetInteger('HealthDecrease', cHealthDecrease);
ScriptSetInteger('GetAwayTime', cGetAwayTime);
ScriptSetInteger('AmmoTypeMax', Ord(High(TAmmoType)));
ScriptSetString('Map', cMapName);
ScriptSetString('Theme', Theme);
ScriptSetString('Goals', '');

ScriptCall('onGameInit');

// pop game variables
ParseCommand('seed ' + ScriptGetString('Seed'), true, true);
cTemplateFilter  := ScriptGetInteger('TemplateFilter');
LuaTemplateNumber:= ScriptGetInteger('TemplateNumber');
cMapGen          := TMapGen(ScriptGetInteger('MapGen'));
cFeatureSize     := ScriptGetInteger('MapFeatureSize');
GameFlags        := ScriptGetInteger('GameFlags');
WorldEdge        := TWorldEdge(ScriptGetInteger('WorldEdge'));
cHedgehogTurnTime:= ScriptGetInteger('TurnTime');
cCaseFactor      := ScriptGetInteger('CaseFreq');
cMaxCaseDrops    := ScriptGetInteger('MaxCaseDrops');
cHealthCaseProb  := ScriptGetInteger('HealthCaseProb');
cHealthCaseAmount:= ScriptGetInteger('HealthCaseAmount');
cInitHealth      := ScriptGetInteger('InitHealth');
cDamagePercent   := ScriptGetInteger('DamagePercent');
cRopePercent     := ScriptGetInteger('RopePercent');
cLandMines       := ScriptGetInteger('MinesNum');
cMinesTime       := ScriptGetInteger('MinesTime');
cMineDudPercent  := ScriptGetInteger('MineDudPercent');
cAirMines        := ScriptGetInteger('AirMinesNum');
cExplosives      := ScriptGetInteger('Explosives');
cInactDelay      := ScriptGetInteger('Delay');
cReadyDelay      := ScriptGetInteger('Ready');
cSuddenDTurns    := ScriptGetInteger('SuddenDeathTurns');
cWaterRise       := ScriptGetInteger('WaterRise');
cHealthDecrease  := ScriptGetInteger('HealthDecrease');
cGetAwayTime     := ScriptGetInteger('GetAwayTime');

if cMapName <> ScriptGetString('Map') then
    ParseCommand('map ' + ScriptGetString('Map'), true, true);
if ScriptGetString('Theme') <> '' then
    ParseCommand('theme ' + ScriptGetString('Theme'), true, true);
LuaGoals:= ScriptGetAnsiString('Goals');

// Support lua changing the ammo layout - assume all hogs have same ammo, note this might leave a few ammo stores lying around.
k:= 0;
if (GameFlags and gfSharedAmmo) <> 0 then
    for i:= 0 to Pred(ClansCount) do
        for j:= 0 to Pred(ClansArray[i]^.TeamsNumber) do
            for k:= 0 to Pred(ClansArray[i]^.Teams[j]^.HedgehogsNumber) do
                ClansArray[i]^.Teams[j]^.Hedgehogs[k].AmmoStore:= i
else if (GameFlags and gfPerHogAmmo) <> 0 then
    for i:= 0 to Pred(TeamsCount) do
        for j:= 0 to Pred(TeamsArray[i]^.HedgehogsNumber) do
            begin
            TeamsArray[i]^.Hedgehogs[j].AmmoStore:= k;
            if StoreCnt-1 < k then AddAmmoStore;
            inc(k)
            end
else
    for i:= 0 to Pred(TeamsCount) do
        begin
        for j:= 0 to Pred(TeamsArray[i]^.HedgehogsNumber) do
            TeamsArray[i]^.Hedgehogs[j].AmmoStore:= k;
        if StoreCnt-1 < k then AddAmmoStore;
        inc(k)
        end;
if ScriptExists('onAmmoStoreInit') or ScriptExists('onNewAmmoStore') then
    begin
    // reset ammostore (quite unclean, but works?)
    uAmmos.freeModule;
    uAmmos.initModule;
    if ScriptExists('onAmmoStoreInit') then
        begin
        ScriptPrepareAmmoStore;
        ScriptCall('onAmmoStoreInit');
        SetAmmoLoadout(ScriptAmmoLoadout);
        SetAmmoProbability(ScriptAmmoProbability);
        SetAmmoDelay(ScriptAmmoDelay);
        SetAmmoReinforcement(ScriptAmmoReinforcement)
        end;
    ScriptApplyAmmoStore
    end;

ScriptSetInteger('ClansCount', ClansCount);
ScriptSetInteger('TeamsCount', TeamsCount);
end;


// Update values of screen dimensions and allow script to react to resolution change
procedure ScriptOnScreenResize();
begin
ScriptSetInteger('ScreenHeight', cScreenHeight);
ScriptSetInteger('ScreenWidth', cScreenWidth);
ScriptCall('onScreenResize');
end;

// custom script loader via physfs, passed to lua_load
const BUFSIZE = 1024;

var inComment: boolean;
var inQuote: boolean;
var locSum: LongWord;
var braceCount: LongWord;
var wordCount: LongWord;
var lastChar: char;
function  ScriptReader(L: Plua_State; f: PFSFile; sz: Psize_t) : PChar; Cdecl;
var mybuf: PChar;
    i: LongInt;
begin
    SetRandomSeed(cSeed,true);
    mybuf := physfsReader(L, f, sz);
    if (mybuf <> nil) and ((sz^) > 0) then
        begin
            for i:= 0 to sz^-1 do
                begin
                    if (lastChar = '-') and (mybuf[i] = '-') then
                        inComment := true
                    else if not inComment and (byte(mybuf[i]) > $20) and (byte(mybuf[i]) < $7F) and (mybuf[i]<>'-') then
                        begin
                        AddRandomness(byte(mybuf[i]));  // wish I had the seed...
                        CheckSum := CheckSum xor GetRandom($FFFFFFFF);
                        end;
                    lastChar := mybuf[i];
                    // lua apparently allows --  [===============[  as a valid block comment start.  
                    // I can't be bothered to check for that nonsense. Will allow limited single line without [
                    if (byte(mybuf[i]) = $0D) or (byte(mybuf[i]) = $0A) or (mybuf[i] = '[') then
                        inComment := false
                end;
        end;
    ScriptReader:= mybuf
end;
function  ScriptLocaleReader(L: Plua_State; f: PFSFile; sz: Psize_t) : PChar; Cdecl;
var mybuf: PChar;
    i: LongInt;
begin
    mybuf := physfsReader(L, f, sz);
    if (mybuf <> nil) and ((sz^) > 0) then
        begin
            for i:= 0 to sz^-1 do
                begin
                    if not inComment and (mybuf[i] = '"') and (lastChar <> '\') then
                        inQuote := not inQuote;
                    if not inQuote and (lastChar = '-') and (mybuf[i] = '-') then
                        inComment := true;
                    if not inComment and (not inQuote) then
                       locSum := locSum xor (byte(mybuf[i]) shl (i mod 4));
                    if not inComment and (not inQuote) and
                        ((mybuf[i] = '(') or
                        (mybuf[i] = ')') or
                        (mybuf[i] = '+') or
                        (mybuf[i] = '#') or
                        (braceCount > 2) or
                        (wordCount > 6)) then
                       CheckSum := locSum;
                    if not inComment and (not inQuote) and ((mybuf[i] = '{') or (mybuf[i] = '}')) then
                        inc(braceCount);
                    if not inComment and (not inQuote) and
                        (((byte(mybuf[i]) > $40) and (byte(mybuf[i]) < $5B)) or
                        ((byte(mybuf[i]) > $60) and (byte(mybuf[i]) < $7B)) or
                        ((byte(mybuf[i]) >= $30) and (byte(mybuf[i]) < $3A))) then
                        inc(wordCount);
                    lastChar := mybuf[i];
                    // this allows at least supporting the commented strings at end of line with lua script names
                    if (byte(mybuf[i]) = $0D) or (byte(mybuf[i]) = $0A) or (mybuf[i] = '[') then
                        inComment := false
                end;
        end;
    ScriptLocaleReader:= mybuf
end;

function ScriptLoad(name : shortstring; mustExist : boolean): boolean;
var ret : LongInt;
      s : shortstring;
      f : PFSFile;
    buf : array[0..Pred(BUFSIZE)] of byte;
begin
inComment:= false;
inQuote:= false;
lastChar:= 'X';
braceCount:= 0;
wordCount:= 0;
locSum:= 0;
s:= cPathz[ptData] + name;
if not pfsExists(s) then
    begin
    if mustExist then
        OutError('Script not found: ' + name, true)
    else
        AddFileLog('[LUA] Script not found: ' + name);
    ScriptLoad:= false;
    exit;
    end;

f:= pfsOpenRead(s);
if f = nil then
    OutError('Error reading script: ' + name, true);

hedgewarsMountPackage(Str2PChar(copy(s, 3, length(s)-6)+'.hwp'));

physfsReaderSetBuffer(@buf);
if (Pos('Locale/',s) <> 0) or (s = 'Scripts/OfficialChallengeHashes.lua') then
     ret:= lua_load(luaState, @ScriptLocaleReader, f, Str2PChar(s))
else
    begin
    SetRandomSeed(cSeed,true);
    ret:= lua_load(luaState, @ScriptReader, f, Str2PChar(s))
    end;
pfsClose(f);

if ret <> 0 then
    begin
    LuaError('Failed to load ' + name + '(error ' + IntToStr(ret) + ')');
    LuaError(lua_tostring(luaState, -1));
    ScriptLoad:= false;
    end
else
    begin
    WriteLnToConsole('Lua: ' + name + ' loaded');
    // call the script file
    lua_pcall(luaState, 0, 0, 0);
    ScriptLoaded:= true;
    ScriptLoad:= true;
    end;
end;

procedure SetGlobals;
var x, y: LongInt;
begin
ScriptSetInteger('TurnTimeLeft', TurnTimeLeft);
ScriptSetInteger('ReadyTimeLeft', ReadyTimeLeft);
ScriptSetInteger('GameTime', GameTicks);
ScriptSetInteger('TotalRounds', TotalRoundsReal);
ScriptSetInteger('WaterLine', cWaterLine);
if isCursorVisible and (not bShowAmmoMenu) then
    begin
    x:= CursorPoint.X - WorldDx;
    y:= cScreenHeight - CursorPoint.Y - WorldDy;
    if (PrevCursorX <> x) or
       (PrevCursorY <> y) then
        begin
        ScriptSetInteger('CursorX', x);
        ScriptSetInteger('CursorY', y);
        PrevCursorX:= x;
        PrevCursorY:= y;
        end
    end
else
    begin
    ScriptSetInteger('CursorX', NoPointX);
    ScriptSetInteger('CursorY', NoPointX);
    PrevCursorX:= NoPointX;
    PrevCursorY:= NoPointX
    end;

if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) then
    ScriptSetInteger('CurrentHedgehog', CurrentHedgehog^.Gear^.UID)
else
    ScriptSetNil('CurrentHedgehog');
end;

procedure ScriptSetMapGlobals;
begin
ScriptSetInteger('LAND_WIDTH', LAND_WIDTH);
ScriptSetInteger('LAND_HEIGHT', LAND_HEIGHT);
ScriptSetInteger('LeftX', leftX);
ScriptSetInteger('RightX', rightX);
ScriptSetInteger('TopY', topY);
end;

procedure GetGlobals;
var currentTTL, currentRTL, newTTL, newRTL: LongInt;
begin
// Setting TurnTimeLeft and ReadyTimeLeft should now be done in the setter functions.
// SetTurnTimeLeft and SetReadTimeLeft.
// GetGloals should be removed in a future release.

// DEPRECATED: Read TurnTimeLeft and ReadyTimeLeft from script directly.
// TODO: Remove this behaviour in a future version.
currentTTL:= TurnTimeLeft;
currentRTL:= ReadyTimeLeft;
newTTL:= ScriptGetInteger('TurnTimeLeft');
newRTL:= ScriptGetInteger('ReadyTimeLeft');
if (currentTTL <> newTTL) and (not isPendingTurnTimeLeft) then
    begin
    TurnTimeLeft:= newTTL;
    LuaWarning('Writing to TurnTimeLeft directly is deprecated! Use SetTurnTimeLeft instead!');
    end;

if (currentRTL <> newRTL) and (not isPendingReadyTimeLeft) then
    begin
    ReadyTimeLeft:= newRTL;
    LuaWarning('Writing to ReadyTimeLeft directly is deprecated! Use SetReadyTimeLeft instead!');
    end;

// Set TurnTimeLeft and ReadyTimeLeft if activated by SetTurnTimeLeft and SetReadyTimeLeft before
if isPendingTurnTimeLeft then
    begin
    TurnTimeLeft:= PendingTurnTimeLeft;
    ScriptSetInteger('TurnTimeLeft', TurnTimeLeft);
    isPendingTurnTimeLeft:= false;
    end;
if isPendingReadyTimeLeft then
    begin
    ReadyTimeLeft:= PendingReadyTimeLeft;
    ScriptSetInteger('ReadyTimeLeft', ReadyTimeLeft);
    isPendingReadyTimeLeft:= false;
    end;
end;

procedure ScriptCall(fname : shortstring);
begin
if (not ScriptLoaded) or (not ScriptExists(fname)) then
    exit;
SetGlobals;
lua_getglobal(luaState, Str2PChar(fname));
if lua_pcall(luaState, 0, 0, 0) <> 0 then
    begin
    LuaError('Error while calling ' + fname + ': ' + lua_tostring(luaState, -1));
    lua_pop(luaState, 1)
    end;
GetGlobals;
end;

(*
function ParseCommandOverride(key, value : shortstring) : shortstring;
begin
ParseCommandOverride:= value;
if not ScriptExists('ParseCommandOverride') then
    exit;
lua_getglobal(luaState, Str2PChar('ParseCommandOverride'));
lua_pushstring(luaState, Str2PChar(key));
lua_pushstring(luaState, Str2PChar(value));
if lua_pcall(luaState, 2, 1, 0) <> 0 then
    begin
    LuaError('Lua: Error while calling ParseCommandOverride: ' + lua_tostring(luaState, -1));
    lua_pop(luaState, 1)
    end
else
    begin
    ParseCommandOverride:= lua_tostring(luaState, -1);
    lua_pop(luaState, 1)
    end;
end;
*)

function ScriptCall(fname : shortstring; par1: LongInt) : LongInt;
begin
ScriptCall:= ScriptCall(fname, par1, 0, 0, 0)
end;

function ScriptCall(fname : shortstring; par1, par2: LongInt) : LongInt;
begin
ScriptCall:= ScriptCall(fname, par1, par2, 0, 0)
end;

function ScriptCall(fname : shortstring; par1, par2, par3: LongInt) : LongInt;
begin
ScriptCall:= ScriptCall(fname, par1, par2, par3, 0)
end;

function ScriptCall(fname : shortstring; par1, par2, par3, par4 : LongInt) : LongInt;
begin
if (not ScriptLoaded) or (not ScriptExists(fname)) then
    exit(0);
SetGlobals;
lua_getglobal(luaState, Str2PChar(fname));
lua_pushnumber(luaState, par1);
lua_pushnumber(luaState, par2);
lua_pushnumber(luaState, par3);
lua_pushnumber(luaState, par4);
ScriptCall:= 0;
if lua_pcall(luaState, 4, 1, 0) <> 0 then
    begin
    LuaError('Error while calling ' + fname + ': ' + lua_tostring(luaState, -1));
    lua_pop(luaState, 1)
    end
else
    begin
    ScriptCall:= Trunc(lua_tonumber(luaState, -1));
    lua_pop(luaState, 1)
    end;
GetGlobals;
end;

function ScriptExists(fname : shortstring) : boolean;
begin
if not ScriptLoaded then
    begin
    ScriptExists:= false;
    exit
    end;
lua_getglobal(luaState, Str2PChar(fname));
ScriptExists:= not lua_isnoneornil(luaState, -1);
lua_pop(luaState, 1)
end;

procedure ScriptPrepareAmmoStore;
var i: ShortInt;
begin
ScriptAmmoLoadout:= '';
ScriptAmmoDelay:= '';
ScriptAmmoProbability:= '';
ScriptAmmoReinforcement:= '';
for i:=1 to ord(High(TAmmoType)) do
    begin
    ScriptAmmoLoadout:= ScriptAmmoLoadout + '0';
    ScriptAmmoProbability:= ScriptAmmoProbability + '0';
    ScriptAmmoDelay:= ScriptAmmoDelay + '0';
    ScriptAmmoReinforcement:= ScriptAmmoReinforcement + '0';
    end;
end;

procedure ScriptSetAmmo(ammo : TAmmoType; count, probability, delay, reinforcement: Byte);
begin
//if (ord(ammo) < 1) or (count > 9) or (count < 0) or (probability < 0) or (probability > 8) or (delay < 0) or (delay > 9) or (reinforcement < 0) or (reinforcement > 8) then
if (ord(ammo) < 1) or (count > 9) or (probability > 8) or (delay > 9) or (reinforcement > 8) then
    exit;
ScriptAmmoLoadout[ord(ammo)]:= inttostr(count)[1];
ScriptAmmoProbability[ord(ammo)]:= inttostr(probability)[1];
ScriptSetAmmoDelay(ammo, delay);
ScriptAmmoReinforcement[ord(ammo)]:= inttostr(reinforcement)[1];
end;

procedure ScriptSetAmmoDelay(ammo : TAmmoType; delay: LongWord);
begin
// change loadout string if ammo store has not been initialized yet
if (StoreCnt = 0) then
    begin
    if (delay <= 9) then
        ScriptAmmoDelay[ord(ammo)]:= inttostr(delay)[1];
    end
// change 'live' delay values
else if (CurrentTeam <> nil) then
    begin
    ammoz[ammo].SkipTurns:= CurrentTeam^.Clan^.TurnNumber + delay;
    if ammoz[ammo].SkipTurns > 0 then
        dec(ammoz[ammo].SkipTurns);
    AmmoMenuInvalidated:= true;
    end;
end;

procedure ScriptApplyAmmoStore;
var i, j, k : LongInt;
begin
if (GameFlags and gfSharedAmmo) <> 0 then
    for i:= 0 to Pred(ClansCount) do
        begin
        if ScriptExists('onNewAmmoStore') then
            begin
            ScriptPrepareAmmoStore;
            ScriptCall('onNewAmmoStore',i,-1);
            SetAmmoLoadout(ScriptAmmoLoadout);
            SetAmmoProbability(ScriptAmmoProbability);
            SetAmmoDelay(ScriptAmmoDelay);
            SetAmmoReinforcement(ScriptAmmoReinforcement)
            end;
        AddAmmoStore;
        for j:= 0 to Pred(ClansArray[i]^.TeamsNumber) do
            for k:= 0 to Pred(ClansArray[i]^.Teams[j]^.HedgehogsNumber) do
                ClansArray[i]^.Teams[j]^.Hedgehogs[k].AmmoStore:= StoreCnt - 1
        end
else if (GameFlags and gfPerHogAmmo) <> 0 then
    for i:= 0 to Pred(TeamsCount) do
        for j:= 0 to Pred(TeamsArray[i]^.HedgehogsNumber) do
            begin
            if ScriptExists('onNewAmmoStore') then
                begin
                ScriptPrepareAmmoStore;
                ScriptCall('onNewAmmoStore',i,j);
                SetAmmoLoadout(ScriptAmmoLoadout);
                SetAmmoProbability(ScriptAmmoProbability);
                SetAmmoDelay(ScriptAmmoDelay);
                SetAmmoReinforcement(ScriptAmmoReinforcement)
                end;
            AddAmmoStore;
            TeamsArray[i]^.Hedgehogs[j].AmmoStore:= StoreCnt - 1
            end
else
    for i:= 0 to Pred(TeamsCount) do
        begin
        if ScriptExists('onNewAmmoStore') then
            begin
            ScriptPrepareAmmoStore;
            ScriptCall('onNewAmmoStore',i,-1);
            SetAmmoLoadout(ScriptAmmoLoadout);
            SetAmmoProbability(ScriptAmmoProbability);
            SetAmmoDelay(ScriptAmmoDelay);
            SetAmmoReinforcement(ScriptAmmoReinforcement)
            end;
        AddAmmoStore;
        for j:= 0 to Pred(TeamsArray[i]^.HedgehogsNumber) do
            TeamsArray[i]^.Hedgehogs[j].AmmoStore:= StoreCnt - 1
        end
end;

procedure initModule;
var at : TGearType;
    vgt: TVisualGearType;
    am : TAmmoType;
    si : TStatInfoType;
    st : TSound;
    he : THogEffect;
    cg : TCapGroup;
    spr: TSprite;
    mg : TMapGen;
    we : TWorldEdge;
begin
// initialize lua
luaState:= lua_open;
if checkFails(luaState <> nil, 'lua_open failed', true) then exit;

// open internal libraries
luaopen_base(luaState);
luaopen_string(luaState);
luaopen_math(luaState);
luaopen_table(luaState);

// import some variables
ScriptSetString(_S'LOCALE', cLanguage);

{$IFDEF USE_TOUCH_INTERFACE}
ScriptSetString(_S'INTERFACE', 'touch');
{$ELSE}
ScriptSetString(_S'INTERFACE', 'desktop');
{$ENDIF}

// Add aliases for amDuck and gtDuck because rubber duck was removed.
// amDuck and gtDuck are deprecated and should be removed later.
// TODO: Remove these aliases in a later version.
ScriptSetInteger('amDuck', Ord(amCreeper));
ScriptSetInteger('gtDuck', Ord(gtCreeper));

// import game flags
ScriptSetInteger('gfSwitchHog', gfSwitchHog);
ScriptSetInteger('gfMultiWeapon', gfMultiWeapon);
ScriptSetInteger('gfSolidLand', gfSolidLand);
ScriptSetInteger('gfBorder', gfBorder);
ScriptSetInteger('gfBottomBorder', gfBottomBorder);
ScriptSetInteger('gfDivideTeams', gfDivideTeams);
ScriptSetInteger('gfLowGravity', gfLowGravity);
ScriptSetInteger('gfLaserSight', gfLaserSight);
ScriptSetInteger('gfInvulnerable', gfInvulnerable);
ScriptSetInteger('gfResetHealth', gfResetHealth);
ScriptSetInteger('gfVampiric', gfVampiric);
ScriptSetInteger('gfKarma', gfKarma);
ScriptSetInteger('gfArtillery', gfArtillery);
ScriptSetInteger('gfOneClanMode', gfOneClanMode);
ScriptSetInteger('gfRandomOrder', gfRandomOrder);
ScriptSetInteger('gfKing', gfKing);
ScriptSetInteger('gfPlaceHog', gfPlaceHog);
ScriptSetInteger('gfSharedAmmo', gfSharedAmmo);
ScriptSetInteger('gfDisableGirders', gfDisableGirders);
ScriptSetInteger('gfDisableLandObjects', gfDisableLandObjects);
ScriptSetInteger('gfAISurvival', gfAISurvival);
ScriptSetInteger('gfInfAttack', gfInfAttack);
ScriptSetInteger('gfResetWeps', gfResetWeps);
ScriptSetInteger('gfPerHogAmmo', gfPerHogAmmo);
ScriptSetInteger('gfDisableWind', gfDisableWind);
ScriptSetInteger('gfMoreWind', gfMoreWind);
ScriptSetInteger('gfTagTeam', gfTagTeam);
ScriptSetInteger('gfShoppaBorder', gfShoppaBorder);

ScriptSetInteger('gmLeft', gmLeft);
ScriptSetInteger('gmRight', gmRight);
ScriptSetInteger('gmUp', gmUp);
ScriptSetInteger('gmDown', gmDown);
ScriptSetInteger('gmSwitch', gmSwitch);
ScriptSetInteger('gmAttack', gmAttack);
ScriptSetInteger('gmLJump', gmLJump);
ScriptSetInteger('gmHJump', gmHJump);
ScriptSetInteger('gmDestroy', gmDestroy);
ScriptSetInteger('gmSlot', gmSlot);
ScriptSetInteger('gmWeapon', gmWeapon);
ScriptSetInteger('gmTimer', gmTimer);
ScriptSetInteger('gmAnimate', gmAnimate);
ScriptSetInteger('gmPrecise', gmPrecise);
ScriptSetInteger('gmAllStoppable', gmAllStoppable);

// speech bubbles
ScriptSetInteger('SAY_SAY', 1);
ScriptSetInteger('SAY_THINK', 2);
ScriptSetInteger('SAY_SHOUT', 3);

// other
ScriptSetInteger('AMMO_INFINITE', AMMO_INFINITE);
ScriptSetInteger('JETPACK_FUEL_INFINITE', JETPACK_FUEL_INFINITE);
ScriptSetInteger('BIRDY_ENERGY_INFINITE', BIRDY_ENERGY_INFINITE);
ScriptSetInteger('NO_CURSOR', NoPointX);
ScriptSetInteger('MAX_HOG_HEALTH', cMaxHogHealth);
ScriptSetInteger('MAX_TURN_TIME', cMaxTurnTime);

// register gear types
for at:= Low(TGearType) to High(TGearType) do
    ScriptSetInteger(EnumToStr(at), ord(at));

for vgt:= Low(TVisualGearType) to High(TVisualGearType) do
    ScriptSetInteger(EnumToStr(vgt), ord(vgt));

// register sounds
for st:= Low(TSound) to High(TSound) do
    ScriptSetInteger(EnumToStr(st), ord(st));

// register ammo types
for am:= Low(TAmmoType) to High(TAmmoType) do
    ScriptSetInteger(EnumToStr(am), ord(am));

for si:= Low(TStatInfoType) to High(TStatInfoType) do
    ScriptSetInteger(EnumToStr(si), ord(si));

for he:= Low(THogEffect) to High(THogEffect) do
    ScriptSetInteger(EnumToStr(he), ord(he));

for cg:= Low(TCapGroup) to High(TCapGroup) do
    ScriptSetInteger(EnumToStr(cg), ord(cg));

for spr:= Low(TSprite) to High(TSprite) do
    ScriptSetInteger(EnumToStr(spr), ord(spr));

for mg:= Low(TMapGen) to High(TMapGen) do
    ScriptSetInteger(EnumToStr(mg), ord(mg));

for we:= Low(TWorldEdge) to High(TWorldEdge) do
    ScriptSetInteger(EnumToStr(we), ord(we));

ScriptSetInteger('capcolDefault'    , capcolDefault);
ScriptSetInteger('capcolSetting'    , capcolSetting);

ScriptSetInteger('gstDrowning'      , gstDrowning);
ScriptSetInteger('gstHHDriven'      , gstHHDriven);
ScriptSetInteger('gstMoving'        , gstMoving);
ScriptSetInteger('gstAttacked'      , gstAttacked);
ScriptSetInteger('gstAttacking'     , gstAttacking);
ScriptSetInteger('gstCollision'     , gstCollision);
ScriptSetInteger('gstChooseTarget'  , gstChooseTarget);
ScriptSetInteger('gstHHJumping'     , gstHHJumping);
ScriptSetInteger('gsttmpFlag'       , gsttmpFlag);
ScriptSetInteger('gstHHThinking'    , gstHHThinking);
ScriptSetInteger('gstNoDamage'      , gstNoDamage);
ScriptSetInteger('gstHHHJump'       , gstHHHJump);
ScriptSetInteger('gstAnimation'     , gstAnimation);
ScriptSetInteger('gstHHDeath'       , gstHHDeath);
ScriptSetInteger('gstWinner'        , gstWinner);
ScriptSetInteger('gstWait'          , gstWait);
ScriptSetInteger('gstNotKickable'   , gstNotKickable);
ScriptSetInteger('gstLoser'         , gstLoser);
ScriptSetInteger('gstHHGone'        , gstHHGone);
ScriptSetInteger('gstInvisible'     , gstInvisible);
ScriptSetInteger('gstSubmersible'   , gstSubmersible);
ScriptSetInteger('gstFrozen'        , gstFrozen);
ScriptSetInteger('gstNoGravity'     , gstNoGravity);

// ai hints
ScriptSetInteger('aihUsualProcessing', aihUsualProcessing);
ScriptSetInteger('aihDoesntMatter'   , aihDoesntMatter);

// land flags (partial)
ScriptSetInteger('lfIndestructible', lfIndestructible);
ScriptSetInteger('lfIce'           , lfIce);
ScriptSetInteger('lfBouncy'        , lfBouncy);

ScriptSetInteger('lfLandMask'      , lfLandMask);
ScriptSetInteger('lfCurHogCrate'   , lfCurHogCrate);
ScriptSetInteger('lfHHMask'        , lfHHMask);
ScriptSetInteger('lfNotHHObjMask'  , lfNotHHObjMask);
ScriptSetInteger('lfAllObjMask'    , lfAllObjMask);

// explosion constants
ScriptSetInteger('EXPLAutoSound'    , EXPLAutoSound);
ScriptSetInteger('EXPLNoDamage'     , EXPLNoDamage);
ScriptSetInteger('EXPLDoNotTouchHH' , EXPLDoNotTouchHH);
ScriptSetInteger('EXPLDontDraw'     , EXPLDontDraw);
ScriptSetInteger('EXPLNoGfx'        , EXPLNoGfx);
ScriptSetInteger('EXPLPoisoned'     , EXPLPoisoned);
ScriptSetInteger('EXPLDoNotTouchAny', EXPLDoNotTouchAny);
ScriptSetInteger('EXPLForceDraw'    , EXPLForceDraw);

// register functions
lua_register(luaState, _P'HideHog', @lc_hidehog);
lua_register(luaState, _P'RestoreHog', @lc_restorehog);
lua_register(luaState, _P'IsHogHidden', @lc_ishoghidden);
lua_register(luaState, _P'SaveCampaignVar', @lc_savecampaignvar);
lua_register(luaState, _P'GetCampaignVar', @lc_getcampaignvar);
lua_register(luaState, _P'SaveMissionVar', @lc_savemissionvar);
lua_register(luaState, _P'GetMissionVar', @lc_getmissionvar);
lua_register(luaState, _P'band', @lc_band);
lua_register(luaState, _P'bor', @lc_bor);
lua_register(luaState, _P'bnot', @lc_bnot);
lua_register(luaState, _P'div', @lc_div);
lua_register(luaState, _P'GetInputMask', @lc_getinputmask);
lua_register(luaState, _P'SetInputMask', @lc_setinputmask);
lua_register(luaState, _P'AddGear', @lc_addgear);
lua_register(luaState, _P'DismissTeam', @lc_dismissteam);
lua_register(luaState, _P'EnableGameFlags', @lc_enablegameflags);
lua_register(luaState, _P'DisableGameFlags', @lc_disablegameflags);
lua_register(luaState, _P'ClearGameFlags', @lc_cleargameflags);
lua_register(luaState, _P'GetGameFlag', @lc_getgameflag);
lua_register(luaState, _P'DeleteGear', @lc_deletegear);
lua_register(luaState, _P'AddVisualGear', @lc_addvisualgear);
lua_register(luaState, _P'DeleteVisualGear', @lc_deletevisualgear);
lua_register(luaState, _P'GetVisualGearType', @lc_getvisualgeartype);
lua_register(luaState, _P'GetVisualGearValues', @lc_getvisualgearvalues);
lua_register(luaState, _P'SetVisualGearValues', @lc_setvisualgearvalues);
lua_register(luaState, _P'GetGearValues', @lc_getgearvalues);
lua_register(luaState, _P'SetGearValues', @lc_setgearvalues);
lua_register(luaState, _P'SpawnHealthCrate', @lc_spawnhealthcrate);
lua_register(luaState, _P'SpawnAmmoCrate', @lc_spawnammocrate);
lua_register(luaState, _P'SpawnUtilityCrate', @lc_spawnutilitycrate);
lua_register(luaState, _P'SpawnSupplyCrate', @lc_spawnsupplycrate);
lua_register(luaState, _P'SpawnFakeHealthCrate', @lc_spawnfakehealthcrate);
lua_register(luaState, _P'SpawnFakeAmmoCrate', @lc_spawnfakeammocrate);
lua_register(luaState, _P'SpawnFakeUtilityCrate', @lc_spawnfakeutilitycrate);
lua_register(luaState, _P'WriteLnToConsole', @lc_writelntoconsole);
lua_register(luaState, _P'WriteLnToChat', @lc_writelntochat);
lua_register(luaState, _P'GetGearType', @lc_getgeartype);
lua_register(luaState, _P'EndGame', @lc_endgame);
lua_register(luaState, _P'EndTurn', @lc_endturn);
lua_register(luaState, _P'Retreat', @lc_retreat);
lua_register(luaState, _P'SkipTurn', @lc_skipturn);
lua_register(luaState, _P'GetTeamStats', @lc_getteamstats);
lua_register(luaState, _P'SendStat', @lc_sendstat);
lua_register(luaState, _P'SendGameResultOff', @lc_sendgameresultoff);
lua_register(luaState, _P'SendRankingStatsOff', @lc_sendrankingstatsoff);
lua_register(luaState, _P'SendAchievementsStatsOff', @lc_sendachievementsstatsoff);
lua_register(luaState, _P'SendHealthStatsOff', @lc_sendhealthstatsoff);
lua_register(luaState, _P'FindPlace', @lc_findplace);
lua_register(luaState, _P'SetGearPosition', @lc_setgearposition);
lua_register(luaState, _P'GetGearPosition', @lc_getgearposition);
lua_register(luaState, _P'SetGearTarget', @lc_setgeartarget);
lua_register(luaState, _P'GetGearTarget', @lc_getgeartarget);
lua_register(luaState, _P'SetGearVelocity', @lc_setgearvelocity);
lua_register(luaState, _P'GetGearVelocity', @lc_getgearvelocity);
lua_register(luaState, _P'ParseCommand', @lc_parsecommand);
lua_register(luaState, _P'ShowMission', @lc_showmission);
lua_register(luaState, _P'HideMission', @lc_hidemission);
lua_register(luaState, _P'SetAmmoTexts', @lc_setammotexts);
lua_register(luaState, _P'SetAmmoDescriptionAppendix', @lc_setammodescriptionappendix);
lua_register(luaState, _P'AddCaption', @lc_addcaption);
lua_register(luaState, _P'SetAmmo', @lc_setammo);
lua_register(luaState, _P'GetAmmo', @lc_getammo);
lua_register(luaState, _P'SetAmmoDelay', @lc_setammodelay);
lua_register(luaState, _P'PlaySound', @lc_playsound);
lua_register(luaState, _P'PlayMusicSound', @lc_playmusicsound);
lua_register(luaState, _P'StopMusicSound', @lc_stopmusicsound);
lua_register(luaState, _P'SetSoundMask', @lc_setsoundmask);
lua_register(luaState, _P'GetTeamName', @lc_getteamname);
lua_register(luaState, _P'GetTeamIndex', @lc_getteamindex);
lua_register(luaState, _P'GetTeamClan', @lc_getteamclan);
lua_register(luaState, _P'AddTeam', @lc_addteam);
lua_register(luaState, _P'AddMissionTeam', @lc_addmissionteam);
lua_register(luaState, _P'SetTeamLabel', @lc_setteamlabel);
lua_register(luaState, _P'SetTeamPassive', @lc_setteampassive);
lua_register(luaState, _P'AddHog', @lc_addhog);
lua_register(luaState, _P'AddMissionHog', @lc_addmissionhog);
lua_register(luaState, _P'AddAmmo', @lc_addammo);
lua_register(luaState, _P'GetAmmoCount', @lc_getammocount);
lua_register(luaState, _P'HealHog', @lc_healhog);
lua_register(luaState, _P'SetHealth', @lc_sethealth);
lua_register(luaState, _P'GetHealth', @lc_gethealth);
lua_register(luaState, _P'SetEffect', @lc_seteffect);
lua_register(luaState, _P'GetEffect', @lc_geteffect);
lua_register(luaState, _P'GetHogClan', @lc_gethogclan);
lua_register(luaState, _P'GetClanColor', @lc_getclancolor);
lua_register(luaState, _P'SetClanColor', @lc_setclancolor);
lua_register(luaState, _P'GetHogVoicepack', @lc_gethogvoicepack);
lua_register(luaState, _P'GetHogFlag', @lc_gethogflag);
lua_register(luaState, _P'GetHogFort', @lc_gethogfort);
lua_register(luaState, _P'GetHogGrave', @lc_gethoggrave);
lua_register(luaState, _P'IsHogLocal', @lc_ishoglocal);
lua_register(luaState, _P'GetHogTeamName', @lc_gethogteamname);
lua_register(luaState, _P'SetHogTeamName', @lc_sethogteamname);
lua_register(luaState, _P'GetHogName', @lc_gethogname);
lua_register(luaState, _P'SetHogName', @lc_sethogname);
lua_register(luaState, _P'GetHogLevel', @lc_gethoglevel);
lua_register(luaState, _P'SetHogLevel', @lc_sethoglevel);
lua_register(luaState, _P'GetX', @lc_getx);
lua_register(luaState, _P'GetY', @lc_gety);
lua_register(luaState, _P'CopyPV', @lc_copypv);
lua_register(luaState, _P'FollowGear', @lc_followgear);
lua_register(luaState, _P'GetFollowGear', @lc_getfollowgear);
lua_register(luaState, _P'SetState', @lc_setstate);
lua_register(luaState, _P'GetState', @lc_getstate);
lua_register(luaState, _P'GetTag', @lc_gettag);
lua_register(luaState, _P'SetTag', @lc_settag);
lua_register(luaState, _P'SetTimer', @lc_settimer);
lua_register(luaState, _P'GetTimer', @lc_gettimer);
lua_register(luaState, _P'SetFlightTime', @lc_setflighttime);
lua_register(luaState, _P'GetFlightTime', @lc_getflighttime);
lua_register(luaState, _P'SetZoom', @lc_setzoom);
lua_register(luaState, _P'GetZoom', @lc_getzoom);
lua_register(luaState, _P'HogSay', @lc_hogsay);
lua_register(luaState, _P'SwitchHog', @lc_switchhog);
lua_register(luaState, _P'EnableSwitchHog', @lc_enableswitchhog);
lua_register(luaState, _P'HogTurnLeft', @lc_hogturnleft);
lua_register(luaState, _P'GetGearElasticity', @lc_getgearelasticity);
lua_register(luaState, _P'SetGearElasticity', @lc_setgearelasticity);
lua_register(luaState, _P'GetGearFriction', @lc_getgearfriction);
lua_register(luaState, _P'SetGearFriction', @lc_setgearfriction);
lua_register(luaState, _P'GetGearRadius', @lc_getgearradius);
lua_register(luaState, _P'GetGearMessage', @lc_getgearmessage);
lua_register(luaState, _P'SetGearMessage', @lc_setgearmessage);
lua_register(luaState, _P'GetGearPos', @lc_getgearpos);
lua_register(luaState, _P'SetGearPos', @lc_setgearpos);
lua_register(luaState, _P'GetGearCollisionMask', @lc_getgearcollisionmask);
lua_register(luaState, _P'SetGearCollisionMask', @lc_setgearcollisionmask);
lua_register(luaState, _P'GetRandom', @lc_getrandom);
lua_register(luaState, _P'SetWind', @lc_setwind);
lua_register(luaState, _P'GetWind', @lc_getwind);
lua_register(luaState, _P'MapHasBorder', @lc_maphasborder);
lua_register(luaState, _P'GetHogHat', @lc_gethoghat);
lua_register(luaState, _P'SetHogHat', @lc_sethoghat);
lua_register(luaState, _P'EraseSprite', @lc_erasesprite);
lua_register(luaState, _P'PlaceSprite', @lc_placesprite);
lua_register(luaState, _P'PlaceGirder', @lc_placegirder);
lua_register(luaState, _P'PlaceRubber', @lc_placerubber);
lua_register(luaState, _P'GetCurAmmoType', @lc_getcurammotype);
lua_register(luaState, _P'TestRectForObstacle', @lc_testrectforobstacle);
lua_register(luaState, _P'GetGravity', @lc_getgravity);
lua_register(luaState, _P'SetGravity', @lc_setgravity);
lua_register(luaState, _P'SetWaterLine', @lc_setwaterline);
lua_register(luaState, _P'SetNextWeapon', @lc_setnextweapon);
lua_register(luaState, _P'SetWeapon', @lc_setweapon);
lua_register(luaState, _P'SetCinematicMode', @lc_setcinematicmode);
lua_register(luaState, _P'SetMaxBuildDistance', @lc_setmaxbuilddistance);
lua_register(luaState, _P'GetAmmoName', @lc_getammoname);
lua_register(luaState, _P'GetAmmoTimer', @lc_getammotimer);
lua_register(luaState, _P'SetVampiric', @lc_setvampiric);
lua_register(luaState, _P'GetVampiric', @lc_getvampiric);
lua_register(luaState, _P'SetLaserSight', @lc_setlasersight);
lua_register(luaState, _P'GetLaserSight', @lc_getlasersight);
lua_register(luaState, _P'Explode', @lc_explode);
lua_register(luaState, _P'SetTurnTimeLeft', @lc_setturntimeleft);
lua_register(luaState, _P'SetReadyTimeLeft', @lc_setreadytimeleft);
lua_register(luaState, _P'SetTurnTimePaused', @lc_setturntimepaused);
lua_register(luaState, _P'GetTurnTimePaused', @lc_getturntimepaused);
// drawn map functions
lua_register(luaState, _P'AddPoint', @lc_addPoint);
lua_register(luaState, _P'FlushPoints', @lc_flushPoints);

lua_register(luaState, _P'SetGearAIHints', @lc_setgearaihints);
lua_register(luaState, _P'HedgewarsScriptLoad', @lc_hedgewarsscriptload);
lua_register(luaState, _P'DeclareAchievement', @lc_declareachievement);
lua_register(luaState, _P'StartGhostPoints', @lc_startghostpoints);
lua_register(luaState, _P'DumpPoint', @lc_dumppoint);

ScriptSetInteger('TEST_SUCCESSFUL'   , HaltTestSuccess);
ScriptSetInteger('TEST_FAILED'       , HaltTestFailed);
lua_register(luaState, _P'EndLuaTest', @lc_endluatest);

ScriptClearStack; // just to be sure stack is empty
ScriptLoaded:= false;
end;

procedure freeModule;
begin
lua_close(luaState);
end;

{$ELSE}
procedure ScriptPrintStack;
begin
end;

procedure ScriptClearStack;
begin
end;

procedure ScriptLoad(name : shortstring);
begin
    name:= name; // avoid hint
end;

procedure ScriptOnGameInit;
begin
end;

procedure ScriptCall(fname : shortstring);
begin
    fname:= fname; // avoid hint
end;

function ScriptCall(fname : shortstring; par1, par2, par3, par4 : LongInt) : LongInt;
begin
    // avoid hints
    fname:= fname;
    par1:= par1;
    par2:= par2;
    par3:= par3;
    par4:= par4;
    ScriptCall:= 0
end;

function ScriptCall(fname : shortstring; par1: LongInt) : LongInt;
begin
    // avoid hints
    fname:= fname;
    par1:= par1;
    ScriptCall:= 0
end;

function ScriptCall(fname : shortstring; par1, par2: LongInt) : LongInt;
begin
    // avoid hints
    fname:= fname;
    par1:= par1;
    par2:= par2;
    ScriptCall:= 0
end;

function ScriptCall(fname : shortstring; par1, par2, par3: LongInt) : LongInt;
begin
    // avoid hints
    fname:= fname;
    par1:= par1;
    par2:= par2;
    par3:= par3;
    ScriptCall:= 0
end;

function ScriptExists(fname : shortstring) : boolean;
begin
    fname:= fname; // avoid hint
    ScriptExists:= false
end;
(*
function ParseCommandOverride(key, value : shortstring) : shortstring;
begin
    // avoid hints
    key:= key;
    value:= value;
    ParseCommandOverride:= ''
end;
*)

procedure ScriptOnScreenResize;
begin
end;

procedure ScriptOnPreviewInit;
begin
end;

procedure ScriptSetInteger(name : shortstring; value : LongInt);
begin
end;

procedure ScriptSetString(name : shortstring; value : shortstring);
begin
end;

procedure LuaParseString(s : ShortString);
begin
end;

procedure initModule;
begin
PointsBuffer:= '';
PrevCursorX:= NoPointX;
PrevCursorY:= NoPointX;
isPendingTurnTimeLeft:= false;
isPendingReadyTimeLeft:= false;
end;

procedure freeModule;
begin
end;

{$ENDIF}
end.

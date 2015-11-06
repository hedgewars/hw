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
 * Please keep http://code.google.com/p/hedgewars/wiki/LuaAPI up to date!
 *
 * Note: If you add a new function, make sure to test if _all_ parameters
 *       work as intended! (Especially conversions errors can sneak in
 *       unnoticed and render the parameter useless!)
 *)
interface

procedure ScriptPrintStack;
procedure ScriptClearStack;

procedure ScriptLoad(name : shortstring);
procedure ScriptOnPreviewInit;
procedure ScriptOnGameInit;
procedure ScriptOnScreenResize;
procedure ScriptSetInteger(name : shortstring; value : LongInt);
procedure ScriptSetString(name : shortstring; value : shortstring);

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
{$IFDEF USE_LUA_SCRIPT}

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
    uUtils,
    uCaptions,
    uDebug,
    uCollisions,
    uRenderUtils,
    uTextures,
    uLandGraphics,
    SysUtils,
    uIO,
    uVisualGearsList,
    uGearsHandlersMess,
    uPhysFSLayer,
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
    mapDims : boolean;
    PointsBuffer: shortstring;
    prevCursorPoint: TPoint;  // why is tpoint still in sdlh...

procedure ScriptPrepareAmmoStore; forward;
procedure ScriptApplyAmmoStore; forward;
procedure ScriptSetAmmo(ammo : TAmmoType; count, probability, delay, reinforcement: Byte); forward;
procedure ScriptSetAmmoDelay(ammo : TAmmoType; delay: Byte); forward;

var LuaDebugInfo: lua_Debug;

procedure SetGlobals; forward;
procedure LuaParseString(s: shortString);
begin
    SetGlobals;
    AddFileLog('[Lua] input string: ' + s);
    AddChatString(#3 + '[Lua] > ' + s);
    if luaL_dostring(luaState, Str2PChar(s)) <> 0 then
        begin
        AddFileLog('[Lua] input string parsing error!');
        AddChatString(#5 + '[Lua] Error while parsing!');
        end;
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

procedure LuaError(s: shortstring);
var src: shortstring;
const
    maxsrclen = 20;
begin
    if LuaUpdateDebugInfo() then
        begin
        src:= StrPas(LuaDebugInfo.source);
        s:= 'LUA ERROR [ ... '
            + copy(src, Length(src) - maxsrclen, maxsrclen - 3) + ':'
            + inttostr(LuaDebugInfo.currentLine) + ']: ' + s;
        end
    else
        s:= 'LUA ERROR: ' + s;
    WriteLnToConsole(s);
    AddChatString(#5 + s);
    if cTestLua then
        halt(HaltTestLuaError);
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
    else i:= lua_tointeger(L, i);
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
    else i:= lua_tointeger(L, i);
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
    else i:= lua_tointeger(L, i);
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
    else i:= lua_tointeger(L, i);
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
    else i:= lua_tointeger(L, i);
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
    else i:= lua_tointeger(L, i);
    if (i < ord(Low(THogEffect))) or (i > ord(High(THogEffect))) then
        begin
        LuaCallError('Invalid gear type!', call, paramsyntax);
        LuaToHogEffectOrd:= -1;
        end
    else
        LuaToHogEffectOrd:= i;
end;

function LuaToCapGroupOrd(L : Plua_State; i: LongInt; call, paramsyntax: shortstring): LongInt; inline;
begin
    if lua_isnoneornil(L, i) then i:= -1
    else i:= lua_tointeger(L, i);
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
    else i:= lua_tointeger(L, i);
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
    else i:= lua_tointeger(L, i);
    if (i < ord(Low(TMapGen))) or (i > ord(High(TMapGen))) then
        begin
        LuaCallError('Invalid mapgen id!', call, paramsyntax);
        LuaToMapGenOrd:= -1;
        end
    else
        LuaToMapGenOrd:= i;
end;

// wrapped calls //

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
        lua_pushinteger(L, lua_tointeger(L, 2) and lua_tointeger(L, 1))
    else
        lua_pushnil(L);
    lc_band := 1;
end;

function lc_bor(L: PLua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 2, 'bor', 'value1, value2') then
        lua_pushinteger(L, lua_tointeger(L, 2) or lua_tointeger(L, 1))
    else
        lua_pushnil(L);
    lc_bor := 1;
end;

function lc_bnot(L: PLua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'bnot', 'value') then
        lua_pushinteger(L, (not lua_tointeger(L, 1)))
    else
        lua_pushnil(L);
    lc_bnot := 1;
end;

function lc_div(L: PLua_State): LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 2, 'div', 'dividend, divisor') then
        lua_pushinteger(L, lua_tointeger(L, 1) div lua_tointeger(L, 2))
    else
        lua_pushnil(L);
    lc_div := 1;
end;

function lc_getinputmask(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'GetInputMask', '') then
        lua_pushinteger(L, InputMask);
    lc_getinputmask:= 1
end;

function lc_setinputmask(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'SetInputMask', 'mask') then
        InputMask:= lua_tointeger(L, 1);
    lc_setinputmask:= 0
end;

function lc_writelntoconsole(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'WriteLnToConsole', 'string') then
        WriteLnToConsole('Lua: ' + lua_tostring(L ,1));
    lc_writelntoconsole:= 0;
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
            CBuildMaxDist:= lua_tointeger(L, 1);
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

            // if something is selected, find it's successor
            if curAmmoType <> amNothing then
                begin
                // get current slot index
                cs:= Ammoz[CurAmmoType].Slot;
                // find current ammo index
                while (fa < cMaxSlotAmmoIndex)
                    and (Ammo^[cs, fa].AmmoType <> CurAmmoType) do
                        inc(fa);
                // increase once more because we won't successor
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
begin
    if CheckLuaParamCount(L, 5, 'ShowMission', 'caption, subcaption, text, icon, time') then
        ShowMission(lua_tostringA(L, 1), lua_tostringA(L, 2), lua_tostringA(L, 3), lua_tointeger(L, 4), lua_tointeger(L, 5));
    lc_showmission:= 0;
end;

function lc_hidemission(L : Plua_State) : LongInt; Cdecl;
begin
    L:= L; // avoid compiler hint
    HideMission;
    lc_hidemission:= 0;
end;

function lc_enablegameflags(L : Plua_State) : LongInt; Cdecl;
var i, n : integer;
begin
    // can have 1 or more arguments
    if CheckAndFetchLuaParamMinCount(L, 1, 'EnableGameFlags', 'gameFlag, ... ', n) then
        begin
        for i:= 1 to n do
            GameFlags := GameFlags or LongWord(lua_tointeger(L, i));
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
            GameFlags := GameFlags and (not LongWord(lua_tointeger(L, i)));
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
        lua_pushboolean(L, (GameFlags and LongWord(lua_tointeger(L, 1)) <> 0))
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
            AddCaption(lua_tostringA(L, 1), cWhiteColor, capgrpMessage)
        else
            begin
            cg:= LuaToCapGroupOrd(L, 3, call, params);
            if cg >= 0 then
                AddCaption(lua_tostringA(L, 1), lua_tointeger(L, 2) shr 8, TCapGroup(cg));
            end
        end;
    lc_addcaption:= 0;
end;

function lc_campaignlock(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'CampaignLock', 'TODO') then
        begin
        // TODO
        end;
    lc_campaignlock:= 0;
end;

function lc_campaignunlock(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'CampaignUnlock', 'TODO') then
        begin
        // TODO
        end;
    lc_campaignunlock:= 0;
end;

function lc_spawnfakehealthcrate(L: Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 4,'SpawnFakeHealthCrate', 'x, y, explode, poison') then
        begin
        gear := SpawnFakeCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2),
        HealthCrate, lua_toboolean(L, 3), lua_toboolean(L, 4));
        if gear <> nil then
             lua_pushinteger(L, gear^.uid)
        else lua_pushnil(L)
        end
    else
        lua_pushnil(L);
    lc_spawnfakehealthcrate := 1;
end;

function lc_spawnfakeammocrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 4,'SpawnFakeAmmoCrate', 'x, y, explode, poison') then
        begin
        gear := SpawnFakeCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2),
        AmmoCrate, lua_toboolean(L, 3), lua_toboolean(L, 4));
        if gear <> nil then
             lua_pushinteger(L, gear^.uid)
        else lua_pushnil(L)
        end
    else
        lua_pushnil(L);
    lc_spawnfakeammocrate := 1;
end;

function lc_spawnfakeutilitycrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 4,'SpawnFakeUtilityCrate', 'x, y, explode, poison') then
        begin
        gear := SpawnFakeCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2),
        UtilityCrate, lua_toboolean(L, 3), lua_toboolean(L, 4));
        if gear <> nil then
             lua_pushinteger(L, gear^.uid)
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
            health:= lua_tointeger(L, 3)
        else
            health:= cHealthCaseAmount;
        gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2), HealthCrate, health, 0);
        if gear <> nil then
             lua_pushinteger(L, gear^.uid)
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
             gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2), AmmoCrate, lua_tointeger(L, 3), 0)
        else gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2), AmmoCrate, lua_tointeger(L, 3), lua_tointeger(L, 4));
        if gear <> nil then
             lua_pushinteger(L, gear^.uid)
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
             gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2), UtilityCrate, lua_tointeger(L, 3), 0)
        else gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2), UtilityCrate, lua_tointeger(L, 3), lua_tointeger(L, 4));
        if gear <> nil then
             lua_pushinteger(L, gear^.uid)
        else lua_pushnil(L);
       end
    else
        lua_pushnil(L);
    lc_spawnutilitycrate := 1;
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
            x:= lua_tointeger(L, 1);
            y:= lua_tointeger(L, 2);
            s:= lua_tointeger(L, 4);
            dx:= int2hwFloat(lua_tointeger(L, 5)) / 1000000;
            dy:= int2hwFloat(lua_tointeger(L, 6)) / 1000000;
            t:= lua_tointeger(L, 7);

            gear:= AddGear(x, y, gt, s, dx, dy, t);
            lastGearByUID:= gear;
            lua_pushinteger(L, gear^.uid)
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
        gear:= GearByUID(lua_tointeger(L, 1));
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
            x:= lua_tointeger(L, 1);
            y:= lua_tointeger(L, 2);
            s:= lua_tointeger(L, 4);
            c:= lua_toboolean(L, 5);

            if n = 6 then
                begin
                layer:= lua_tointeger(L, 6);
                vg:= AddVisualGear(x, y, vgt, s, c, layer);
                end
            else
                vg:= AddVisualGear(x, y, vgt, s, c);

            if vg <> nil then
                begin
                lastVisualGearByUID:= vg;
                uid:= vg^.uid;
                lua_pushinteger(L, uid);
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
        vg:= VisualGearByUID(lua_tointeger(L, 1));
        if vg <> nil then
            DeleteVisualGear(vg);
        end;
    // allow caller to know whether there was something to delete
    lua_pushboolean(L, vg <> nil);
    lc_deletevisualgear:= 1
end;

function lc_getvisualgearvalues(L : Plua_State) : LongInt; Cdecl;
var vg: PVisualGear;
begin
    if CheckLuaParamCount(L, 1, 'GetVisualGearValues', 'vgUid') then
        begin
        vg:= VisualGearByUID(lua_tointeger(L, 1));
        if vg <> nil then
            begin
            lua_pushinteger(L, round(vg^.X));
            lua_pushinteger(L, round(vg^.Y));
            lua_pushnumber(L, vg^.dX);
            lua_pushnumber(L, vg^.dY);
            lua_pushnumber(L, vg^.Angle);
            lua_pushinteger(L, vg^.Frame);
            lua_pushinteger(L, vg^.FrameTicks);
            lua_pushinteger(L, vg^.State);
            lua_pushinteger(L, vg^.Timer);
            lua_pushinteger(L, vg^.Tint);
            end
        else
            begin
            lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
            lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
            end
        end
    else
        begin
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
        end;
    lc_getvisualgearvalues:= 10
end;

function lc_setvisualgearvalues(L : Plua_State) : LongInt; Cdecl;
var vg : PVisualGear;
begin
// Param count can be 1-11 at present
//    if CheckLuaParamCount(L, 11, 'SetVisualGearValues', 'vgUid, X, Y, dX, dY, Angle, Frame, FrameTicks, State, Timer, Tint') then
//        begin
        vg:= VisualGearByUID(lua_tointeger(L, 1));
        if vg <> nil then
            begin
            if not lua_isnoneornil(L, 2) then
                vg^.X:= lua_tointeger(L, 2);
            if not lua_isnoneornil(L, 3) then
                vg^.Y:= lua_tointeger(L, 3);
            if not lua_isnoneornil(L, 4) then
                vg^.dX:= lua_tonumber(L, 4);
            if not lua_isnoneornil(L, 5) then
                vg^.dY:= lua_tonumber(L, 5);
            if not lua_isnoneornil(L, 6) then
                vg^.Angle:= lua_tonumber(L, 6);
            if not lua_isnoneornil(L, 7) then
                vg^.Frame:= lua_tointeger(L, 7);
            if not lua_isnoneornil(L, 8) then
                vg^.FrameTicks:= lua_tointeger(L, 8);
            if not lua_isnoneornil(L, 9) then
                vg^.State:= lua_tointeger(L, 9);
            if not lua_isnoneornil(L, 10) then
                vg^.Timer:= lua_tointeger(L, 10);
            if not lua_isnoneornil(L, 11) then
                vg^.Tint:= lua_tointeger(L, 11)
            end;
//        end
//    else
//        lua_pushnil(L); // return value on stack (nil)
    lc_setvisualgearvalues:= 0
end;

// so. going to use this to get/set some of the more obscure gear values which weren't already exposed elsewhere
// can keep adding things in the future. isnoneornil makes it safe
function lc_getgearvalues(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearValues', 'gearUid') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            lua_pushinteger(L, gear^.Angle);
            lua_pushinteger(L, gear^.Power);
            lua_pushinteger(L, gear^.WDTimer);
            lua_pushinteger(L, gear^.Radius);
            lua_pushinteger(L, hwRound(gear^.Density * _10000));
            lua_pushinteger(L, gear^.Karma);
            lua_pushnumber(L,  gear^.DirAngle);
            lua_pushinteger(L, gear^.AdvBounce);
            lua_pushinteger(L, Integer(gear^.ImpactSound));
            lua_pushinteger(L, gear^.nImpactSounds);
            lua_pushinteger(L, gear^.Tint);
            lua_pushinteger(L, gear^.Damage)
            end
        else
            begin
            lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
            lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
            lua_pushnil(L); lua_pushnil(L)
            end
        end
    else
        begin
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
        lua_pushnil(L); lua_pushnil(L)
        end;
    lc_getgearvalues:= 12
end;

function lc_setgearvalues(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
// Currently allows 1-13 params
//    if CheckLuaParamCount(L, 13, 'SetGearValues', 'gearUid, Angle, Power, WDTimer, Radius, Density, Karma, DirAngle, AdvBounce, ImpactSound, # ImpactSounds, Tint, Damage') then
//        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            if not lua_isnoneornil(L, 2) then
                gear^.Angle := lua_tointeger(L, 2);
            if not lua_isnoneornil(L, 3) then
                gear^.Power := lua_tointeger(L, 3);
            if not lua_isnoneornil(L, 4) then
                gear^.WDTimer := lua_tointeger(L, 4);
            if not lua_isnoneornil(L, 5) then
                gear^.Radius := lua_tointeger(L, 5);
            if not lua_isnoneornil(L, 6) then
                gear^.Density:= int2hwFloat(lua_tointeger(L, 6)) / 10000;
            if not lua_isnoneornil(L, 7) then
                gear^.Karma := lua_tointeger(L, 7);
            if not lua_isnoneornil(L, 8) then
                gear^.DirAngle:= lua_tonumber(L, 8);
            if not lua_isnoneornil(L, 9) then
                gear^.AdvBounce := lua_tointeger(L, 9);
            if not lua_isnoneornil(L, 10) then
                gear^.ImpactSound := TSound(lua_tointeger(L, 10));
            if not lua_isnoneornil(L, 11) then
                gear^.nImpactSounds := lua_tointeger(L, 11);
            if not lua_isnoneornil(L, 12) then
                gear^.Tint := lua_tointeger(L, 12);
            if not lua_isnoneornil(L, 13) then
                gear^.Damage := lua_tointeger(L, 13);
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
            lua_pushinteger(L, FollowGear^.uid);
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, ord(gear^.Kind))
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.message)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, hwRound(gear^.elasticity * _10000))
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            gear^.Elasticity:= int2hwFloat(lua_tointeger(L, 2)) / 10000
        end;
    lc_setgearelasticity:= 0
end;

function lc_getgearfriction(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearFriction', 'gearUid') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, hwRound(gear^.friction * _10000))
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            gear^.Friction:= int2hwFloat(lua_tointeger(L, 2)) / 10000
        end;
    lc_setgearfriction:= 0
end;

function lc_setgearmessage(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetGearMessage', 'gearUid, message') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            gear^.message:= lua_tointeger(L, 2);
        end;
    lc_setgearmessage:= 0
end;

function lc_getgearpos(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearPos', 'gearUid') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.Pos)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            gear^.Pos:= lua_tointeger(L, 2);
        end;
    lc_setgearpos:= 0
end;

function lc_getgearcollisionmask(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetGearCollisionMask', 'gearUid') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.CollisionMask)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            gear^.CollisionMask:= lua_tointeger(L, 2);
        end;
    lc_setgearcollisionmask:= 0
end;

function lc_gethoglevel(L : Plua_State): LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogLevel', 'gearUid') then
        begin
        gear := GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            lua_pushinteger(L, gear^.Hedgehog^.BotLevel)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            gear^.Hedgehog^.BotLevel:= lua_tointeger(L, 2);
        end;
    lc_sethoglevel:= 0
end;

function lc_gethogclan(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogClan', 'gearUid') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            begin
            lua_pushinteger(L, gear^.Hedgehog^.Team^.Clan^.ClanIndex)
            end
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gethogclan:= 1
end;

function lc_getclancolor(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'GetClanColor', 'clan') then
        lua_pushinteger(L, ClansArray[lua_tointeger(L, 1)]^.Color shl 8 or $FF)
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_getclancolor:= 1
end;

function lc_setclancolor(L : Plua_State) : LongInt; Cdecl;
var clan : PClan;
    team : PTeam;
    hh   : THedgehog;
    i, j : LongInt;
begin
    if CheckLuaParamCount(L, 2, 'SetClanColor', 'clan, color') then
        begin
	i:= lua_tointeger(L,1);
	if i >= ClansCount then exit(0);
        clan := ClansArray[i];
        clan^.Color:= lua_tointeger(L, 2) shr 8;

        for i:= 0 to Pred(clan^.TeamsNumber) do
            begin
            team:= clan^.Teams[i];
            for j:= 0 to 7 do
                begin
                hh:= team^.Hedgehogs[j];
                if (hh.Gear <> nil) or (hh.GearHidden <> nil) then
                    begin
                    FreeAndNilTexture(hh.NameTagTex);
                    hh.NameTagTex:= RenderStringTex(ansistring(hh.Name), clan^.Color, fnt16);
                    RenderHealth(hh);
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
        gear:= GearByUID(lua_tointeger(L, 1));
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
        gear:= GearByUID(lua_tointeger(L, 1));
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Team^.Flag))
        else
            lua_pushnil(L);
        end
    else
        lua_pushnil(L); // return value on stack (nil)
    lc_gethogflag:= 1
end;

function lc_gethogteamname(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 1, 'GetHogTeamName', 'gearUid') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
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
        gear := GearByUID(lua_tointeger(L, 1));
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
        gear:= GearByUID(lua_tointeger(L, 1));
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
        gear:= GearByUID(lua_tointeger(L, 1));
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.Timer)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.FlightTime)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.Health)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, hwRound(gear^.X))
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, hwRound(gear^.Y))
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
        gears:= GearByUID(lua_tointeger(L, 1));
        geard:= GearByUID(lua_tointeger(L, 2));
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
        gear:= GearByUID(lua_tointeger(L, 1));
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            // state defaults to 0 if state param is given
            if n = 4 then
                s:= lua_tointeger(L, 4)
            else
                s:= 0;
            vgear:= AddVisualGear(0, 0, vgtSpeechBubble, s, true);
            if vgear <> nil then
               begin
               vgear^.Text:= lua_tostring(L, 2);
               if Gear^.Kind = gtHedgehog then
                   begin
                   AddChatString(#9+'[' + gear^.Hedgehog^.Name + '] '+vgear^.text);
                   vgear^.Hedgehog:= gear^.Hedgehog
                   end
               else vgear^.Frame:= gear^.uid;

               vgear^.FrameTicks:= lua_tointeger(L, 3);
               if (vgear^.FrameTicks < 1) or (vgear^.FrameTicks > 3) then
                   vgear^.FrameTicks:= 1;
               lua_pushinteger(L, vgear^.Uid);
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
        gear:= GearByUID(lua_tointeger(L, 1));
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
            CurrentTeam:= CurrentHedgehog^.Team;

            gear^.State:= gear^.State or gstHHDriven;
            gear^.Active := true;
            gear^.Z := cCurrHHZ;
            gear^.Message:= gear^.Message or gmRemoveFromList or gmAddToList;
            end
        end;
    lc_switchhog:= 0
end;

function lc_addammo(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
    at, n: LongInt;
const
    call = 'AddAmmo';
    params = 'gearUid, ammoType [, ammoCount]';
begin
    if CheckAndFetchParamCount(L, 2, 3, call, params, n) then
        begin
        at:= LuaToAmmoTypeOrd(L, 2, call, params);
        if at >= 0 then
            begin
            gear:= GearByUID(lua_tointeger(L, 1));
            if (gear <> nil) and (gear^.Hedgehog <> nil) then
                if n = 2 then
                    AddAmmo(gear^.Hedgehog^, TAmmoType(at))
                else
                    SetAmmo(gear^.Hedgehog^, TAmmoType(at), lua_tointeger(L, 3))
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Hedgehog <> nil) then
            begin
            at:= LuaToAmmoTypeOrd(L, 2, call, params);
            if at >= 0 then
                begin
                ammo:= GetAmmoEntry(gear^.Hedgehog^, TAmmoType(at));
                if ammo^.AmmoType = amNothing then
                    lua_pushinteger(L, 0)
                else
                    lua_pushinteger(L, ammo^.Count);
                end;
            end
        else lua_pushinteger(L, 0);
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            gear^.Health:= lua_tointeger(L, 2);

            if (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
                begin
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

function lc_settimer(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetTimer', 'gearUid, timer') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then gear^.Timer:= lua_tointeger(L, 2)
        end;
    lc_settimer:= 0
end;

function lc_setflighttime(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetFlightTime', 'gearUid, flighttime') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then gear^.FlightTime:= lua_tointeger(L, 2)
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
            gear := GearByUID(lua_tointeger(L, 1));
            if (gear <> nil) and (gear^.Hedgehog <> nil) then
                gear^.Hedgehog^.Effects[THogEffect(t)]:= lua_tointeger(L, 3);
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
            gear:= GearByUID(lua_tointeger(L, 1));
            if (gear <> nil) and (gear^.Hedgehog <> nil) then
                lua_pushinteger(L, gear^.Hedgehog^.Effects[THogEffect(t)])
            else
                lua_pushinteger(L, 0)
            end;
        end
    else
        lua_pushinteger(L, 0);
    lc_geteffect:= 1
end;

function lc_setstate(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if CheckLuaParamCount(L, 2, 'SetState', 'gearUid, state') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            gear^.State:= lua_tointeger(L, 2);
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.State)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.Tag)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            gear^.Tag:= lua_tointeger(L, 2);
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
        gear:= GearByUID(lua_tointeger(L, 1));
        fall:= lua_toboolean(L, 2);
        left:= lua_tointeger(L, 3);
        right:= lua_tointeger(L, 4);
        if n = 5 then
            tryhard:= lua_toboolean(L, 5)
        else
            tryhard:= false;
        if gear <> nil then
            FindPlace(gear, fall, left, right, tryhard);
        if gear <> nil then
            lua_pushinteger(L, gear^.uid)
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
const
    call = 'PlaySound';
    params = 'soundId [, hhGearUid]';
begin
    if CheckAndFetchParamCount(L, 1, 2, call, params, n) then
        begin
        s:= LuaToSoundOrd(L, 1, call, params);
        if s >= 0 then
            begin
            // no gear specified
            if n = 1 then
                PlaySound(TSound(s))
            else
                begin
                gear:= GearByUID(lua_tointeger(L, 2));
                if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
                    AddVoice(TSound(s),gear^.Hedgehog^.Team^.Voicepack)
                end;
            end;
        end;
    lc_playsound:= 0;
end;

function lc_addteam(L : Plua_State) : LongInt; Cdecl;
var np: LongInt;
begin
    if CheckAndFetchParamCount(L, 5, 6, 'AddTeam', 'teamname, color, grave, fort, voicepack [, flag]', np) then
        begin
        ParseCommand('addteam x ' + lua_tostring(L, 2) + ' ' + lua_tostring(L, 1), true, true);
        ParseCommand('grave ' + lua_tostring(L, 3), true, true);
        ParseCommand('fort ' + lua_tostring(L, 4), true, true);
        ParseCommand('voicepack ' + lua_tostring(L, 5), true, true);
        if (np = 6) then ParseCommand('flag ' + lua_tostring(L, 6), true, true);
        CurrentTeam^.Binds:= DefaultBinds
        // fails on x64
        //lua_pushinteger(L, LongInt(CurrentTeam));
        end;
    //else
        //lua_pushnil(L)
    lc_addteam:= 0;//1;
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
                        end;
                    end;
                // can't dismiss more than one team
                break;
                end;
        end;
    lc_dismissteam:= 0;
end;

function lc_addhog(L : Plua_State) : LongInt; Cdecl;
var temp: ShortString;
begin
    if CheckLuaParamCount(L, 4, 'AddHog', 'hogname, botlevel, health, hat') then
        begin
        temp:= lua_tostring(L, 4);
        ParseCommand('addhh ' + lua_tostring(L, 2) + ' ' + lua_tostring(L, 3) + ' ' + lua_tostring(L, 1), true, true);
        ParseCommand('hat ' + temp, true, true);
        lua_pushinteger(L, CurrentHedgehog^.Gear^.uid);
        end
    else
        lua_pushnil(L);
    lc_addhog:= 1;
end;

function lc_hogturnleft(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 2, 'HogTurnLeft', 'gearUid, boolean') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            lua_pushinteger(L, hwRound(gear^.X));
            lua_pushinteger(L, hwRound(gear^.Y))
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            col:= gear^.CollisionIndex >= 0;
            x:= lua_tointeger(L, 2);
            y:= lua_tointeger(L, 3);
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            lua_pushinteger(L, gear^.Target.X);
            lua_pushinteger(L, gear^.Target.Y)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            gear^.Target.X:= lua_tointeger(L, 2);
            gear^.Target.Y:= lua_tointeger(L, 3)
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            t:= hwRound(gear^.dX * 1000000);
            // gear dX determines hog orientation
            if (gear^.dX.isNegative) and (t = 0) then t:= -1;
            lua_pushinteger(L, t);
            lua_pushinteger(L, hwRound(gear^.dY * 1000000))
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            gear^.dX:= int2hwFloat(lua_tointeger(L, 2)) / 1000000;
            gear^.dY:= int2hwFloat(lua_tointeger(L, 3)) / 1000000;
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
                ScriptSetAmmo(TAmmoType(at), lua_tointeger(L, 2), lua_tointeger(L, 3), lua_tointeger(L, 4), 1)
            else
                ScriptSetAmmo(TAmmoType(at), lua_tointeger(L, 2), lua_tointeger(L, 3), lua_tointeger(L, 4), lua_tointeger(L, 5));
            end;
        end;
    lc_setammo:= 0
end;

function lc_setammodelay(L : Plua_State) : LongInt; Cdecl;
var at: LongInt;
const
    call = 'SetAmmoDelay';
    params = 'ammoType, delay';
begin
    if CheckLuaParamCount(L, 2, call, params) then
        begin
        at:= LuaToAmmoTypeOrd(L, 1, call, params);
        if at >= 0 then
            ScriptSetAmmoDelay(TAmmoType(at), lua_tointeger(L, 2));
        end;
    lc_setammodelay:= 0
end;

function lc_setammostore(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 4, 'SetAmmoStore', 'loadouts, probabilities, delays, reinforments') then
        begin
        ScriptAmmoLoadout:= lua_tostring(L, 1);
        ScriptAmmoProbability:= lua_tostring(L, 2);
        ScriptAmmoDelay:= lua_tostring(L, 3);
        ScriptAmmoReinforcement:= lua_tostring(L, 4);
        end;
    lc_setammostore:= 0
end;

function lc_getrandom(L : Plua_State) : LongInt; Cdecl;
var m : LongInt;
begin
    if CheckLuaParamCount(L, 1, 'GetRandom', 'number') then
        begin
        m:= lua_tointeger(L, 1);
        if (m > 0) then
            lua_pushinteger(L, GetRandom(m))
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
begin
    if CheckLuaParamCount(L, 1, 'SetWind', 'windSpeed') then
        begin
        cWindSpeed:= int2hwfloat(lua_tointeger(L, 1)) / 100 * cMaxWindSpeed;
        cWindSpeedf:= SignAs(cWindSpeed,cWindSpeed).QWordValue / SignAs(_1,_1).QWordValue;
        if cWindSpeed.isNegative then
            CWindSpeedf := -cWindSpeedf;
        AddVisualGear(0, 0, vgtSmoothWindBar);
        end;
    lc_setwind:= 0
end;

function lc_getdatapath(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'GetDataPath', '') then
        lua_pushstring(L, str2pchar(cPathz[ptData]))
    else
        lua_pushnil(L);
    lc_getdatapath:= 1
end;

function lc_getuserdatapath(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 0, 'GetUserDataPath', '') then
        lua_pushstring(L, str2pchar(cPathz[ptData]))
    else
        lua_pushnil(L);
    lc_getuserdatapath:= 1
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
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.Radius)
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
        gear := GearByUID(lua_tointeger(L, 1));
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
        gear:= GearByUID(lua_tointeger(L, 1));
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
    params = 'x, y, sprite, frameIdx, tint, behind, flipHoriz, flipVert, [, landFlag, ... ]';
begin
    placed:= false;
    if CheckAndFetchLuaParamMinCount(L, 4, call, params, n) then
        begin
        if not lua_isnoneornil(L, 5) then
	        tint := lua_tointeger(L, 5)
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
            lf:= lf or lua_tointeger(L, i);

        n:= LuaToSpriteOrd(L, 3, call, params);
        if n >= 0 then
            begin
            spr:= TSprite(n);
            if SpritesData[spr].Surface = nil then
                LuaError(call + ': ' + EnumToStr(spr) + ' cannot be placed! (required information not loaded)' )
            else
                placed:= ForcePlaceOnLand(
                    lua_tointeger(L, 1) - SpritesData[spr].Width div 2,
                    lua_tointeger(L, 2) - SpritesData[spr].Height div 2,
                    spr, lua_tointeger(L, 4), lf, tint, behind, flipHoriz, flipVert);
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
    params = 'x, y, sprite, frameIdx, eraseOnLFMatch, onlyEraseLF, flipHoriz, flipVert, [, landFlag, ... ]';
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
            lf:= lf or lua_tointeger(L, i);

        n:= LuaToSpriteOrd(L, 3, call, params);
        if n >= 0 then
            begin
            spr:= TSprite(n);
            if SpritesData[spr].Surface = nil then
                LuaError(call + ': ' + EnumToStr(spr) + ' cannot be placed! (required information not loaded)' )
            else
                EraseLand(
                    lua_tointeger(L, 1) - SpritesData[spr].Width div 2,
                    lua_tointeger(L, 2) - SpritesData[spr].Height div 2,
                    spr, lua_tointeger(L, 4), lf, eraseOnLFMatch, onlyEraseLF, flipHoriz, flipVert);
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
            lua_tointeger(L, 1) - SpritesData[sprAmGirder].Width div 2,
            lua_tointeger(L, 2) - SpritesData[sprAmGirder].Height div 2,
            sprAmGirder, lua_tointeger(L, 3), true, false);

    lua_pushboolean(L, placed);
    lc_placegirder:= 1
end;

function lc_getcurammotype(L : Plua_State): LongInt; Cdecl;
begin
    if (CurrentHedgehog <> nil) and (CheckLuaParamCount(L, 0, 'GetCurAmmoType', '')) then
        lua_pushinteger(L, ord(CurrentHedgehog^.CurAmmoType))
    else
        lua_pushinteger(L, ord(amNothing));
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

function lc_hidehog(L: Plua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if CheckLuaParamCount(L, 1, 'HideHog', 'gearUid') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        HideHog(gear^.hedgehog)
        end;
    lc_hidehog := 0;
end;

function lc_restorehog(L: Plua_State): LongInt; Cdecl;
var i, h: LongInt;
    uid: LongWord;
begin
    if CheckLuaParamCount(L, 1, 'RestoreHog', 'gearUid') then
        begin
        uid:= LongWord(lua_tointeger(L, 1));
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

// boolean TestRectForObstacle(x1, y1, x2, y2, landOnly)
function lc_testrectforobstacle(L : Plua_State) : LongInt; Cdecl;
var rtn: Boolean;
begin
    if CheckLuaParamCount(L, 5, 'TestRectForObstacle', 'x1, y1, x2, y2, landOnly') then
        begin
        rtn:= TestRectangleForObstacle(
                    lua_tointeger(L, 1),
                    lua_tointeger(L, 2),
                    lua_tointeger(L, 3),
                    lua_tointeger(L, 4),
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
        lua_pushinteger(L, hwRound(SignAs(_0_5, cGravity) + (cGravity * 50 / cMaxWindSpeed)));
    lc_getgravity:= 1
end;

function lc_setgravity(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'SetGravity', 'percent') then
        begin
        cGravity:= _0_02 * lua_tointeger(L, 1) * cMaxWindSpeed;
        cGravityf:= 0.00025 * lua_tointeger(L, 1) * 0.02
        end;
    lc_setgravity:= 0
end;

function lc_setwaterline(L : Plua_State) : LongInt; Cdecl;
var iterator: PGear;
begin
    if CheckLuaParamCount(L, 1, 'SetWaterLine', 'waterline') then
        begin
        cWaterLine:= lua_tointeger(L,1);
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
    if CheckLuaParamCount(L, 2, 'SetAIHintOnGear', 'gearUid, aiHints') then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            gear^.aihints:= lua_tointeger(L, 2);
        end;
    lc_setgearaihints:= 0
end;


function lc_hedgewarsscriptload(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 1, 'HedgewarsScriptLoad', 'scriptPath') then
        ScriptLoad(lua_tostring(L, 1))
    else
        lua_pushnil(L);
    lc_hedgewarsscriptload:= 0;
end;


function lc_declareachievement(L : Plua_State) : LongInt; Cdecl;
begin
    if CheckLuaParamCount(L, 4, 'DeclareAchievement', 'achievementId, teamname, location, value') then
        declareAchievement(lua_tostring(L, 1), lua_tostring(L, 2), lua_tostring(L, 3), lua_tointeger(L, 4));
    lc_declareachievement:= 0
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
        param:= LongInt(lua_tointeger(L,1));
        PointsBuffer:= PointsBuffer + char((param shr 8) and $FF);
        PointsBuffer:= PointsBuffer + char((param and $FF));
        // y
        param:= LongInt(lua_tointeger(L,2));
        PointsBuffer:= PointsBuffer + char((param shr 8) and $FF);
        PointsBuffer:= PointsBuffer + char((param and $FF));
        // width
        if np > 2 then
            begin
            param:= lua_tointeger(L,3);
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

        case lua_tointeger(L, 1) of
            HaltTestSuccess : rstring:= 'Success';
            HaltTestLuaError: rstring:= 'FAILED';
        else
            begin
            LuaCallError('Parameter must be either ' + params, call, params);
            exit(0);
            end;
        end;

        if cTestLua then
            begin
            WriteLnToConsole('Lua test finished, result: ' + rstring);
            halt(lua_tointeger(L, 1));
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
    lua_pushinteger(luaState, value);
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
    ScriptGetInteger:= lua_tointeger(luaState, -1);
    lua_pop(luaState, 1);
end;

function ScriptGetString(name : shortstring) : shortstring;
begin
    lua_getglobal(luaState, Str2PChar(name));
    ScriptGetString:= lua_tostring(luaState, -1);
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
ScriptSetInteger('CursorX', CursorPoint.X);
ScriptSetInteger('CursorY', CursorPoint.Y);
ScriptSetInteger('BorderColor', ExplosionBorderColor);
ScriptSetInteger('GameFlags', GameFlags);
ScriptSetString('Seed', cSeed);
ScriptSetInteger('TemplateFilter', cTemplateFilter);
ScriptSetInteger('TemplateNumber', LuaTemplateNumber);
ScriptSetInteger('MapGen', ord(cMapGen));
ScriptSetInteger('MapFeatureSize', cFeatureSize);
ScriptSetInteger('ScreenHeight', cScreenHeight);
ScriptSetInteger('ScreenWidth', cScreenWidth);
ScriptSetInteger('TurnTime', cHedgehogTurnTime);
ScriptSetInteger('CaseFreq', cCaseFactor);
ScriptSetInteger('HealthCaseProb', cHealthCaseProb);
ScriptSetInteger('HealthCaseAmount', cHealthCaseAmount);
ScriptSetInteger('DamagePercent', cDamagePercent);
ScriptSetInteger('RopePercent', cRopePercent);
ScriptSetInteger('MinesNum', cLandMines);
ScriptSetInteger('MinesTime', cMinesTime);
ScriptSetInteger('MineDudPercent', cMineDudPercent);
ScriptSetInteger('Explosives', cExplosives);
ScriptSetInteger('Delay', cInactDelay);
ScriptSetInteger('Ready', cReadyDelay);
ScriptSetInteger('SuddenDeathTurns', cSuddenDTurns);
ScriptSetInteger('WaterRise', cWaterRise);
ScriptSetInteger('HealthDecrease', cHealthDecrease);
ScriptSetInteger('GetAwayTime', cGetAwayTime);
ScriptSetString('Map', cMapName);
ScriptSetString('Theme', '');
ScriptSetString('Goals', '');

ScriptCall('onGameInit');

// pop game variables
ParseCommand('seed ' + ScriptGetString('Seed'), true, true);
cTemplateFilter  := ScriptGetInteger('TemplateFilter');
LuaTemplateNumber:= ScriptGetInteger('TemplateNumber');
cMapGen          := TMapGen(ScriptGetInteger('MapGen'));
cFeatureSize     := ScriptGetInteger('MapFeatureSize');
GameFlags        := ScriptGetInteger('GameFlags');
cHedgehogTurnTime:= ScriptGetInteger('TurnTime');
cCaseFactor      := ScriptGetInteger('CaseFreq');
cHealthCaseProb  := ScriptGetInteger('HealthCaseProb');
cHealthCaseAmount:= ScriptGetInteger('HealthCaseAmount');
cDamagePercent   := ScriptGetInteger('DamagePercent');
cRopePercent     := ScriptGetInteger('RopePercent');
cLandMines       := ScriptGetInteger('MinesNum');
cMinesTime       := ScriptGetInteger('MinesTime');
cMineDudPercent  := ScriptGetInteger('MineDudPercent');
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
LuaGoals:= ScriptGetString('Goals');

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
mapDims:= false
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

procedure ScriptLoad(name : shortstring);
var ret : LongInt;
      s : shortstring;
      f : PFSFile;
    buf : array[0..Pred(BUFSIZE)] of byte;
begin
s:= cPathz[ptData] + name;
if not pfsExists(s) then
    begin
    AddFileLog('[LUA] Script not found: ' + name);
    exit;
    end;

f:= pfsOpenRead(s);
if f = nil then
    exit;

physfsReaderSetBuffer(@buf);
ret:= lua_load(luaState, @physfsReader, f, Str2PChar(s));
pfsClose(f);

if ret <> 0 then
    begin
    LuaError('Failed to load ' + name + '(error ' + IntToStr(ret) + ')');
    LuaError(lua_tostring(luaState, -1));
    end
else
    begin
    WriteLnToConsole('Lua: ' + name + ' loaded');
    // call the script file
    lua_pcall(luaState, 0, 0, 0);
    ScriptLoaded:= true
    end;
hedgewarsMountPackage(Str2PChar(copy(s, 1, length(s)-4)+'.hwp'));
end;

procedure SetGlobals;
begin
ScriptSetInteger('TurnTimeLeft', TurnTimeLeft);
ScriptSetInteger('GameTime', GameTicks);
ScriptSetInteger('TotalRounds', TotalRounds);
ScriptSetInteger('WaterLine', cWaterLine);
if isCursorVisible and (not bShowAmmoMenu) then
    begin
    if (prevCursorPoint.X <> CursorPoint.X) or 
       (prevCursorPoint.Y <> CursorPoint.Y) then
        begin
        ScriptSetInteger('CursorX', CursorPoint.X - WorldDx);
        ScriptSetInteger('CursorY', cScreenHeight - CursorPoint.Y- WorldDy);
        prevCursorPoint.X:= CursorPoint.X;
        prevCursorPoint.Y:= CursorPoint.Y;
        end
    end
else
    begin
    ScriptSetInteger('CursorX', NoPointX);
    ScriptSetInteger('CursorY', NoPointX);
    prevCursorPoint.X:= NoPointX;
    prevCursorPoint.Y:= NoPointX
    end;

if not mapDims then
    begin
    mapDims:= true;
    ScriptSetInteger('LAND_WIDTH', LAND_WIDTH);
    ScriptSetInteger('LAND_HEIGHT', LAND_HEIGHT);
    ScriptSetInteger('LeftX', leftX);
    ScriptSetInteger('RightX', rightX);
    ScriptSetInteger('TopY', topY)
    end;
if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) then
    ScriptSetInteger('CurrentHedgehog', CurrentHedgehog^.Gear^.UID)
else
    ScriptSetNil('CurrentHedgehog');
end;

procedure GetGlobals;
begin
// TODO
// Use setters instead, because globals should be read-only!
// Otherwise globals might be changed by Lua, but then unexpectatly overwritten by engine when a ScriptCall is triggered by whatever Lua is doing!
// Sure, one could work around that in engine (e.g. by setting writable globals in SetGlobals only when their engine-side value has actually changed since SetGlobals was called the last time...), but things just get messier and messier then.
// It is inconsistent anyway to have some globals be read-only and others not with no indication whatsoever.
// -- sheepluva
TurnTimeLeft:= ScriptGetInteger('TurnTimeLeft');
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
lua_pushinteger(luaState, par1);
lua_pushinteger(luaState, par2);
lua_pushinteger(luaState, par3);
lua_pushinteger(luaState, par4);
ScriptCall:= 0;
if lua_pcall(luaState, 4, 1, 0) <> 0 then
    begin
    LuaError('Error while calling ' + fname + ': ' + lua_tostring(luaState, -1));
    lua_pop(luaState, 1)
    end
else
    begin
    ScriptCall:= lua_tointeger(luaState, -1);
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
lua_pop(luaState, -1)
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

procedure ScriptSetAmmoDelay(ammo : TAmmoType; delay: Byte);
begin
// change loadout string if ammo store hasn't been initialized yet
if (StoreCnt = 0) then
begin
    if (delay <= 9) then
        ScriptAmmoDelay[ord(ammo)]:= inttostr(delay)[1];
end
// change "live" delay values
else if (CurrentTeam <> nil) then
        ammoz[ammo].SkipTurns:= CurrentTeam^.Clan^.TurnNumber + delay;
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
begin
// initialize lua
luaState:= lua_open;
TryDo(luaState <> nil, 'lua_open failed', true);

// open internal libraries
luaopen_base(luaState);
luaopen_string(luaState);
luaopen_math(luaState);
luaopen_table(luaState);

// import some variables
ScriptSetString(_S'L', cLocale);

// import game flags
ScriptSetInteger('gfForts', gfForts);
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

// land flags
ScriptSetInteger('lfIndestructible', lfIndestructible);
ScriptSetInteger('lfIce'           , lfIce);
ScriptSetInteger('lfBouncy'        , lfBouncy);

// register functions
lua_register(luaState, _P'HideHog', @lc_hidehog);
lua_register(luaState, _P'RestoreHog', @lc_restorehog);
lua_register(luaState, _P'SaveCampaignVar', @lc_savecampaignvar);
lua_register(luaState, _P'GetCampaignVar', @lc_getcampaignvar);
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
lua_register(luaState, _P'GetVisualGearValues', @lc_getvisualgearvalues);
lua_register(luaState, _P'SetVisualGearValues', @lc_setvisualgearvalues);
lua_register(luaState, _P'GetGearValues', @lc_getgearvalues);
lua_register(luaState, _P'SetGearValues', @lc_setgearvalues);
lua_register(luaState, _P'SpawnHealthCrate', @lc_spawnhealthcrate);
lua_register(luaState, _P'SpawnAmmoCrate', @lc_spawnammocrate);
lua_register(luaState, _P'SpawnUtilityCrate', @lc_spawnutilitycrate);
lua_register(luaState, _P'SpawnFakeHealthCrate', @lc_spawnfakehealthcrate);
lua_register(luaState, _P'SpawnFakeAmmoCrate', @lc_spawnfakeammocrate);
lua_register(luaState, _P'SpawnFakeUtilityCrate', @lc_spawnfakeutilitycrate);
lua_register(luaState, _P'WriteLnToConsole', @lc_writelntoconsole);
lua_register(luaState, _P'GetGearType', @lc_getgeartype);
lua_register(luaState, _P'EndGame', @lc_endgame);
lua_register(luaState, _P'SendStat', @lc_sendstat);
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
lua_register(luaState, _P'AddCaption', @lc_addcaption);
lua_register(luaState, _P'SetAmmo', @lc_setammo);
lua_register(luaState, _P'SetAmmoDelay', @lc_setammodelay);
lua_register(luaState, _P'SetAmmoStore', @lc_setammostore);
lua_register(luaState, _P'PlaySound', @lc_playsound);
lua_register(luaState, _P'AddTeam', @lc_addteam);
lua_register(luaState, _P'AddHog', @lc_addhog);
lua_register(luaState, _P'AddAmmo', @lc_addammo);
lua_register(luaState, _P'GetAmmoCount', @lc_getammocount);
lua_register(luaState, _P'SetHealth', @lc_sethealth);
lua_register(luaState, _P'GetHealth', @lc_gethealth);
lua_register(luaState, _P'SetEffect', @lc_seteffect);
lua_register(luaState, _P'GetEffect', @lc_geteffect);
lua_register(luaState, _P'GetHogClan', @lc_gethogclan);
lua_register(luaState, _P'GetClanColor', @lc_getclancolor);
lua_register(luaState, _P'SetClanColor', @lc_setclancolor);
lua_register(luaState, _P'GetHogVoicepack', @lc_gethogvoicepack);
lua_register(luaState, _P'GetHogFlag', @lc_gethogflag);
lua_register(luaState, _P'GetHogGrave', @lc_gethoggrave);
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
lua_register(luaState, _P'HogTurnLeft', @lc_hogturnleft);
lua_register(luaState, _P'CampaignLock', @lc_campaignlock);
lua_register(luaState, _P'CampaignUnlock', @lc_campaignunlock);
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
lua_register(luaState, _P'GetDataPath', @lc_getdatapath);
lua_register(luaState, _P'GetUserDataPath', @lc_getuserdatapath);
lua_register(luaState, _P'MapHasBorder', @lc_maphasborder);
lua_register(luaState, _P'GetHogHat', @lc_gethoghat);
lua_register(luaState, _P'SetHogHat', @lc_sethoghat);
lua_register(luaState, _P'EraseSprite', @lc_erasesprite);
lua_register(luaState, _P'PlaceSprite', @lc_placesprite);
lua_register(luaState, _P'PlaceGirder', @lc_placegirder);
lua_register(luaState, _P'GetCurAmmoType', @lc_getcurammotype);
lua_register(luaState, _P'TestRectForObstacle', @lc_testrectforobstacle);
lua_register(luaState, _P'GetGravity', @lc_getgravity);
lua_register(luaState, _P'SetGravity', @lc_setgravity);
lua_register(luaState, _P'SetWaterLine', @lc_setwaterline);
lua_register(luaState, _P'SetNextWeapon', @lc_setnextweapon);
lua_register(luaState, _P'SetWeapon', @lc_setweapon);
lua_register(luaState, _P'SetMaxBuildDistance', @lc_setmaxbuilddistance);
// drawn map functions
lua_register(luaState, _P'AddPoint', @lc_addPoint);
lua_register(luaState, _P'FlushPoints', @lc_flushPoints);

lua_register(luaState, _P'SetGearAIHints', @lc_setgearaihints);
lua_register(luaState, _P'HedgewarsScriptLoad', @lc_hedgewarsscriptload);
lua_register(luaState, _P'DeclareAchievement', @lc_declareachievement);

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

procedure initModule;
begin
mapDims:= false;
PointsBuffer:= '';
prevCursorPoint.X:= NoPointX;
prevCursorPoint.Y:= 0;
end;

procedure freeModule;
begin
end;

{$ENDIF}
end.

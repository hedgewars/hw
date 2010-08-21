(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2010 Andrey Korotaev <unC0Rr@gmail.com>
 * Lua integration (c) 2010 Mario Liebisch <mario.liebisch@googlemail.com>
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

unit uScript;
interface

procedure ScriptPrintStack;
procedure ScriptClearStack;

procedure ScriptLoad(name : shortstring);
procedure ScriptOnGameInit;

procedure ScriptCall(fname : shortstring);
function ScriptCall(fname : shortstring; par1: LongInt) : LongInt;
function ScriptCall(fname : shortstring; par1, par2: LongInt) : LongInt;
function ScriptCall(fname : shortstring; par1, par2, par3: LongInt) : LongInt;
function ScriptCall(fname : shortstring; par1, par2, par3, par4 : LongInt) : LongInt;
function ScriptExists(fname : shortstring) : boolean;

procedure initModule;
procedure freeModule;

implementation
{$IFNDEF IPHONEOS}
uses LuaPas in 'LuaPas.pas',
    uConsole,
    uMisc,
    uConsts,
    uGears,
    uFloat,
    uWorld,
    uAmmos,
    uSound,
    uTeams,
    uKeys,
    uChat;

var luaState : Plua_State;
    ScriptAmmoLoadout : shortstring;
    ScriptAmmoProbability : shortstring;
    ScriptAmmoDelay : shortstring;
    ScriptAmmoReinforcement : shortstring;
    ScriptLoaded : boolean;

procedure ScriptPrepareAmmoStore; forward;
procedure ScriptApplyAmmoStore; forward;
procedure ScriptSetAmmo(ammo : TAmmoType; count, propability, delay, reinforcement: Byte); forward;

procedure LuaError(s: shortstring);
begin
    WriteLnToConsole(s);
    AddChatString(#5 + s);
end;

// wrapped calls //

// functions called from Lua:
// function(L : Plua_State) : LongInt; Cdecl;
// where L contains the state, returns the number of return values on the stack
// call lua_gettop(L) to receive number of parameters passed

function lc_writelntoconsole(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) = 1 then
        begin
        WriteLnToConsole('Lua: ' + lua_tostring(L ,1));
        end
    else
        LuaError('Lua: Wrong number of parameters passed to WriteLnToConsole!');
    lc_writelntoconsole:= 0;
end;

function lc_parsecommand(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) = 1 then
        begin
        ParseCommand(lua_tostring(L ,1), true);
        end
    else
        LuaError('Lua: Wrong number of parameters passed to ParseCommand!');
    lc_parsecommand:= 0;
end;

function lc_showmission(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) = 5 then
        begin
        ShowMission(lua_tostring(L, 1), lua_tostring(L, 2), lua_tostring(L, 3), lua_tointeger(L, 4), lua_tointeger(L, 5));
        end
    else
        LuaError('Lua: Wrong number of parameters passed to ShowMission!');
    lc_showmission:= 0;
end;

function lc_hidemission(L : Plua_State) : LongInt; Cdecl;
begin
    L:= L; // avoid compiler hint
    HideMission;
    lc_hidemission:= 0;
end;

function lc_spawnhealthcrate(L: Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 2 then begin
        LuaError('Lua: Wrong number of parameters passed to SpawnHealthCrate!');
        lua_pushnil(L);
    end
    else begin
        gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2),
            HealthCrate, 0);
        lua_pushnumber(L, gear^.uid);
    end;
    lc_spawnhealthcrate := 1;        
end;

function lc_spawnammocrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 3 then begin
        LuaError('Lua: Wrong number of parameters passed to SpawnAmmoCrate!');
        lua_pushnil(L);
    end
    else begin
        gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2),
            AmmoCrate, lua_tointeger(L, 3));
        lua_pushnumber(L, gear^.uid);
    end;
    lc_spawnammocrate := 1;
end;

function lc_spawnutilitycrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 3 then begin
        LuaError('Lua: Wrong number of parameters passed to SpawnUtilityCrate!');
        lua_pushnil(L);
    end
    else begin  
        gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2),
            UtilityCrate, lua_tointeger(L, 3));
        lua_pushnumber(L, gear^.uid);
    end;
    lc_spawnutilitycrate := 1;
end;

function lc_addgear(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
    x, y, s, t: LongInt;
    dx, dy: hwFloat;
    gt: TGearType;
begin
    if lua_gettop(L) <> 7 then
        begin
        LuaError('Lua: Wrong number of parameters passed to AddGear!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        x:= lua_tointeger(L, 1);
        y:= lua_tointeger(L, 2);
        gt:= TGearType(lua_tointeger(L, 3));
        s:= lua_tointeger(L, 4);
        dx:= int2hwFloat(round(lua_tonumber(L, 5) * 1000)) / 1000;
        dy:= int2hwFloat(round(lua_tonumber(L, 6) * 1000)) / 1000;
        t:= lua_tointeger(L, 7);

        gear:= AddGear(x, y, gt, s, dx, dy, t);
        lua_pushnumber(L, gear^.uid)
        end;
    lc_addgear:= 1; // 1 return value
end;

function lc_getfollowgear(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 0 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetFollowGear!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        if FollowGear = nil then
            lua_pushnil(L)
        else
            lua_pushnumber(L, FollowGear^.uid);
    lc_getfollowgear:= 1; // 1 return value
end;

function lc_getgeartype(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetGearType!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, ord(gear^.Kind))
        else
            lua_pushnil(L);
        end;
    lc_getgeartype:= 1
end;

function lc_gethogclan(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetHogClan!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            begin
            lua_pushinteger(L, PHedgehog(gear^.Hedgehog)^.Team^.Clan^.ClanIndex)
            end
        else
            lua_pushnil(L);
        end;
    lc_gethogclan:= 1
end;

function lc_gethogname(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetHogName!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            begin
            lua_pushstring(L, str2pchar(PHedgehog(gear^.Hedgehog)^.Name))
            end
        else
            lua_pushnil(L);
        end;
    lc_gethogname:= 1
end;

function lc_gettimer(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetTimer!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushnumber(L, gear^.Timer)
        else
            lua_pushnil(L);
        end;
    lc_gettimer:= 1
end;

function lc_gethealth(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetHealth!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushnumber(L, gear^.Health)
        else
            lua_pushnil(L);
        end;
    lc_gethealth:= 1
end;

function lc_getx(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetX!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushnumber(L, hwRound(gear^.X))
        else
            lua_pushnil(L);
        end;
    lc_getx:= 1
end;

function lc_gety(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetY!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushnumber(L, hwRound(gear^.Y))
        else
            lua_pushnil(L);
        end;
    lc_gety:= 1
end;

function lc_copypv(L : Plua_State) : LongInt; Cdecl;
var gears, geard : PGear;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to CopyPV!');
        end
    else
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
    lc_copypv:= 1
end;

function lc_copypv2(L : Plua_State) : LongInt; Cdecl;
var gears, geard : PGear;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to CopyPV2!');
        end
    else
        begin
        gears:= GearByUID(lua_tointeger(L, 1));
        geard:= GearByUID(lua_tointeger(L, 2));
        if (gears <> nil) and (geard <> nil) then
            begin
            geard^.X:= gears^.X;
            geard^.Y:= gears^.Y;
            geard^.dX:= gears^.dX * 2;
            geard^.dY:= gears^.dY * 2;
            end
        end;
    lc_copypv2:= 1
end;

function lc_followgear(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to FollowGear!')
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then FollowGear:= gear
        end;
    lc_followgear:= 0
end;

function lc_sethealth(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to SetHealth!');
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            gear^.Health:= lua_tointeger(L, 2);
            SetAllToActive;
            end
        end;
    lc_sethealth:= 0
end;

function lc_settimer(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to SetTimer!');
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then gear^.Timer:= lua_tointeger(L, 2)
        end;
    lc_settimer:= 0
end;

function lc_setstate(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to SetState!');
        end
    else
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
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetState!');
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.State)
        else
            lua_pushnil(L)
        end;
    lc_getstate:= 1
end;

function lc_settag(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to SetTag!');
        end
    else
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
    GameState:= gsExit;
    lc_endgame:= 0
end;

function lc_findplace(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
    fall: boolean;
    left, right: LongInt;
begin
    if lua_gettop(L) <> 4 then
        LuaError('Lua: Wrong number of parameters passed to FindPlace!')
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        fall:= lua_toboolean(L, 2);
        left:= lua_tointeger(L, 3);
        right:= lua_tointeger(L, 4);
        if gear <> nil then
            FindPlace(gear, fall, left, right)
        end;
    lc_findplace:= 0
end;

function lc_playsound(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to PlaySound!')
    else
        PlaySound(TSound(lua_tointeger(L, 1)));
    lc_playsound:= 0;
end;

function lc_addteam(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 5 then
        begin
        LuaError('Lua: Wrong number of parameters passed to AddTeam!');
        //lua_pushnil(L)
        end
    else
        begin
        ParseCommand('addteam x ' + lua_tostring(L, 2) + ' ' + lua_tostring(L, 1), true);
        ParseCommand('grave ' + lua_tostring(L, 3), true);
        ParseCommand('fort ' + lua_tostring(L, 4), true);
        ParseCommand('voicepack ' + lua_tostring(L, 5), true);
        CurrentTeam^.Binds:= DefaultBinds
        // fails on x64
        //lua_pushinteger(L, LongInt(CurrentTeam));
        end;
    lc_addteam:= 0;//1;
end;

function lc_addhog(L : Plua_State) : LongInt; Cdecl;
var temp: ShortString;
begin
    if lua_gettop(L) <> 4 then
        begin
        LuaError('Lua: Wrong number of parameters passed to AddHog!');
        lua_pushnil(L)
        end
    else
        begin
        temp:= lua_tostring(L, 4);
        ParseCommand('addhh ' + lua_tostring(L, 2) + ' ' + lua_tostring(L, 3) + ' ' + lua_tostring(L, 1), true);
        ParseCommand('hat ' + temp, true);
        lua_pushinteger(L, CurrentHedgehog^.Gear^.uid);
        end;
    lc_addhog:= 1;
end;

function lc_getgearposition(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetGearPosition!');
        lua_pushnil(L);
        lua_pushnil(L)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            lua_pushinteger(L, hwRound(gear^.X));
            lua_pushinteger(L, hwRound(gear^.Y))
            end
        end;
    lc_getgearposition:= 2;
end;

function lc_setgearposition(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
    x, y: LongInt;
begin
    if lua_gettop(L) <> 3 then
        LuaError('Lua: Wrong number of parameters passed to SetGearPosition!')
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            x:= lua_tointeger(L, 2);
            y:= lua_tointeger(L, 3);
            gear^.X:= int2hwfloat(x);
            gear^.Y:= int2hwfloat(y);
            SetAllToActive;
            end
        end;
    lc_setgearposition:= 0
end;

function lc_setzoom(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to SetZoom!')
    else
        begin
        ZoomValue:= lua_tonumber(L, 1);
        if ZoomValue < cMaxZoomLevel then ZoomValue:= cMaxZoomLevel;
        if ZoomValue > cMinZoomLevel then ZoomValue:= cMinZoomLevel;
        end;
    lc_setzoom:= 0
end;

function lc_getzoom(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 0 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetZoom!');
        lua_pushnil(L)
        end
    else
        lua_pushnumber(L, ZoomValue);
    lc_getzoom:= 1
end;

function lc_setammo(L : Plua_State) : LongInt; Cdecl;
var np: LongInt;
begin
    np:= lua_gettop(L);
    if (np < 4) or (np > 5) then
        LuaError('Lua: Wrong number of parameters passed to SetAmmo!')
    else if np = 4 then
        ScriptSetAmmo(TAmmoType(lua_tointeger(L, 1)), lua_tointeger(L, 2), lua_tointeger(L, 3), lua_tointeger(L, 4), 1)
    else
        ScriptSetAmmo(TAmmoType(lua_tointeger(L, 1)), lua_tointeger(L, 2), lua_tointeger(L, 3), lua_tointeger(L, 4), lua_tointeger(L, 5));
    lc_setammo:= 0
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

procedure ScriptOnGameInit;
var s, t : ansistring;
begin
// not required if there is no script to run
if not ScriptLoaded then
    exit;

// push game variables so they may be modified by the script
ScriptSetInteger('GameFlags', GameFlags);
ScriptSetString('Seed', cSeed);
ScriptSetInteger('TurnTime', cHedgehogTurnTime);
ScriptSetInteger('CaseFreq', cCaseFactor);
ScriptSetInteger('LandAdds', cLandAdditions);
ScriptSetInteger('Explosives', cExplosives);
ScriptSetInteger('Delay', cInactDelay);
ScriptSetInteger('SuddenDeathTurns', cSuddenDTurns);
ScriptSetString('Map', '');
ScriptSetString('Theme', '');

// import locale
s:= cLocaleFName;
t:= '';
SplitByChar(s, t, '.');
ScriptSetString('L', s);

ScriptCall('onGameInit');

// pop game variables
ParseCommand('seed ' + ScriptGetString('Seed'), true);
ParseCommand('$gmflags ' + ScriptGetString('GameFlags'), true);
ParseCommand('$turntime ' + ScriptGetString('TurnTime'), true);
ParseCommand('$casefreq ' + ScriptGetString('CaseFreq'), true);
ParseCommand('$landadds ' + ScriptGetString('LandAdds'), true);
ParseCommand('$explosives ' + ScriptGetString('Explosives'), true);
ParseCommand('$delay ' + ScriptGetString('Delay'), true);
ParseCommand('$sd_turns ' + ScriptGetString('SuddenDeathTurns'), true);
if ScriptGetString('Map') <> '' then
    ParseCommand('map ' + ScriptGetString('Map'), true);
if ScriptGetString('Theme') <> '' then
    ParseCommand('theme ' + ScriptGetString('Theme'), true);

if ScriptExists('onAmmoStoreInit') then
    begin
    ScriptPrepareAmmoStore;
    ScriptCall('onAmmoStoreInit');
    ScriptApplyAmmoStore
    end;

ScriptSetInteger('ClansCount', ClansCount)
end;

procedure ScriptLoad(name : shortstring);
var ret : LongInt;
begin
ret:= luaL_loadfile(luaState, Str2PChar(name));
if ret <> 0 then
    LuaError('Lua: Failed to load ' + name + '(error ' + IntToStr(ret) + ')')
else
    begin
    WriteLnToConsole('Lua: ' + name + ' loaded');
    // call the script file
    lua_pcall(luaState, 0, 0, 0);
    ScriptLoaded:= true
    end
end;

procedure SetGlobals;
begin
ScriptSetInteger('TurnTimeLeft', TurnTimeLeft);
if (CurrentHedgehog <> nil) and (CurrentHedgehog^.Gear <> nil) then
    ScriptSetInteger('CurrentHedgehog', CurrentHedgehog^.Gear^.UID)
else
    ScriptSetNil('CurrentHedgehog');
end;

procedure GetGlobals;
begin
TurnTimeLeft:= ScriptGetInteger('TurnTimeLeft');
end;

procedure ScriptCall(fname : shortstring);
begin
if not ScriptLoaded or not ScriptExists(fname) then
    exit;
SetGlobals;
lua_getglobal(luaState, Str2PChar(fname));
if lua_pcall(luaState, 0, 0, 0) <> 0 then
    begin
    LuaError('Lua: Error while calling ' + fname + ': ' + lua_tostring(luaState, -1));
    lua_pop(luaState, 1)
    end;
GetGlobals;
end;

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
if not ScriptLoaded or not ScriptExists(fname) then
    exit;
SetGlobals;
lua_getglobal(luaState, Str2PChar(fname));
lua_pushinteger(luaState, par1);
lua_pushinteger(luaState, par2);
lua_pushinteger(luaState, par3);
lua_pushinteger(luaState, par4);
ScriptCall:= 0;
if lua_pcall(luaState, 4, 1, 0) <> 0 then
    begin
    LuaError('Lua: Error while calling ' + fname + ': ' + lua_tostring(luaState, -1));
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
// reset ammostore (quite unclean, but works?)
uAmmos.freeModule;
uAmmos.initModule;
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

procedure ScriptSetAmmo(ammo : TAmmoType; count, propability, delay, reinforcement: Byte);
begin
if (ord(ammo) < 1) or (count > 9) or (count < 0) or (propability < 0) or (propability > 8) or (delay < 0) or (delay > 9) or (reinforcement < 0) or (reinforcement > 8) then
    exit;
ScriptAmmoLoadout[ord(ammo)]:= inttostr(count)[1];
ScriptAmmoProbability[ord(ammo)]:= inttostr(propability)[1];
ScriptAmmoDelay[ord(ammo)]:= inttostr(delay)[1];
ScriptAmmoReinforcement[ord(ammo)]:= inttostr(reinforcement)[1];
end;

procedure ScriptApplyAmmoStore;
var i : LongInt;
begin
SetAmmoLoadout(ScriptAmmoLoadout);
SetAmmoProbability(ScriptAmmoProbability);
SetAmmoDelay(ScriptAmmoDelay);
SetAmmoReinforcement(ScriptAmmoReinforcement);
for i:= 0 to Pred(TeamsCount) do
    AddAmmoStore;
end;

procedure initModule;
var at : TGearType;
    am : TAmmoType;
    st : TSound;
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
ScriptSetInteger('LAND_WIDTH', LAND_WIDTH);
ScriptSetInteger('LAND_HEIGHT', LAND_HEIGHT);

// import game flags
ScriptSetInteger('gfForts', gfForts);
ScriptSetInteger('gfMultiWeapon', gfMultiWeapon);
ScriptSetInteger('gfSolidLand', gfSolidLand);
ScriptSetInteger('gfBorder', gfBorder);
ScriptSetInteger('gfDivideTeams', gfDivideTeams);
ScriptSetInteger('gfLowGravity', gfLowGravity);
ScriptSetInteger('gfLaserSight', gfLaserSight);
ScriptSetInteger('gfInvulnerable', gfInvulnerable);
ScriptSetInteger('gfMines', gfMines);
ScriptSetInteger('gfVampiric', gfVampiric);
ScriptSetInteger('gfKarma', gfKarma);
ScriptSetInteger('gfArtillery', gfArtillery);
ScriptSetInteger('gfOneClanMode', gfOneClanMode);
ScriptSetInteger('gfRandomOrder', gfRandomOrder);
ScriptSetInteger('gfKing', gfKing);
ScriptSetInteger('gfPlaceHog', gfPlaceHog);
ScriptSetInteger('gfSharedAmmo', gfSharedAmmo);
ScriptSetInteger('gfDisableGirders', gfDisableGirders);
ScriptSetInteger('gfExplosives', gfExplosives);

// register gear types
for at:= Low(TGearType) to High(TGearType) do
    ScriptSetInteger(EnumToStr(at), ord(at));

// register sounds
for st:= Low(TSound) to High(TSound) do
    ScriptSetInteger(EnumToStr(st), ord(st));

// register ammo types
for am:= Low(TAmmoType) to High(TAmmoType) do
    ScriptSetInteger(EnumToStr(am), ord(am));

// register functions
lua_register(luaState, 'AddGear', @lc_addgear);
lua_register(luaState, 'SpawnHealthCrate', @lc_spawnhealthcrate);
lua_register(luaState, 'SpawnAmmoCrate', @lc_spawnammocrate);
lua_register(luaState, 'SpawnUtilityCrate', @lc_spawnutilitycrate);
lua_register(luaState, 'WriteLnToConsole', @lc_writelntoconsole);
lua_register(luaState, 'GetGearType', @lc_getgeartype);
lua_register(luaState, 'EndGame', @lc_endgame);
lua_register(luaState, 'FindPlace', @lc_findplace);
lua_register(luaState, 'SetGearPosition', @lc_setgearposition);
lua_register(luaState, 'GetGearPosition', @lc_getgearposition);
lua_register(luaState, 'ParseCommand', @lc_parsecommand);
lua_register(luaState, 'ShowMission', @lc_showmission);
lua_register(luaState, 'HideMission', @lc_hidemission);
lua_register(luaState, 'SetAmmo', @lc_setammo);
lua_register(luaState, 'PlaySound', @lc_playsound);
lua_register(luaState, 'AddTeam', @lc_addteam);
lua_register(luaState, 'AddHog', @lc_addhog);
lua_register(luaState, 'SetHealth', @lc_sethealth);
lua_register(luaState, 'GetHogClan', @lc_gethogclan);
lua_register(luaState, 'GetHogName', @lc_gethogname);
lua_register(luaState, 'GetX', @lc_getx);
lua_register(luaState, 'GetY', @lc_gety);
lua_register(luaState, 'CopyPV', @lc_copypv);
lua_register(luaState, 'CopyPV2', @lc_copypv2);
lua_register(luaState, 'FollowGear', @lc_followgear);
lua_register(luaState, 'GetFollowGear', @lc_getfollowgear);
lua_register(luaState, 'SetState', @lc_setstate);
lua_register(luaState, 'GetState', @lc_getstate);
lua_register(luaState, 'SetTag', @lc_settag);
lua_register(luaState, 'SetTimer', @lc_settimer);
lua_register(luaState, 'GetTimer', @lc_gettimer);
lua_register(luaState, 'GetHealth', @lc_gethealth);
lua_register(luaState, 'SetZoom', @lc_setzoom);
lua_register(luaState, 'GetZoom', @lc_getzoom);


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
end;

procedure ScriptOnGameInit;
begin
end;

procedure ScriptCall(fname : shortstring);
begin
end;

function ScriptCall(fname : shortstring; par1, par2, par3, par4 : LongInt) : LongInt;
begin
ScriptCall:= 0
end;

function ScriptCall(fname : shortstring; par1: LongInt) : LongInt;
begin
ScriptCall:= 0
end;

function ScriptCall(fname : shortstring; par1, par2: LongInt) : LongInt;
begin
ScriptCall:= 0
end;

function ScriptCall(fname : shortstring; par1, par2, par3: LongInt) : LongInt;
begin
ScriptCall:= 0
end;

function ScriptExists(fname : shortstring) : boolean;
begin
ScriptExists:= false
end;

procedure initModule;
begin
end;

procedure freeModule;
begin
end;

{$ENDIF}
end.

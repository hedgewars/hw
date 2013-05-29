(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2013 Andrey Korotaev <unC0Rr@gmail.com>
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
procedure ScriptOnGameInit;
procedure ScriptOnScreenResize;
procedure ScriptSetInteger(name : shortstring; value : LongInt);

procedure ScriptCall(fname : shortstring);
function ScriptCall(fname : shortstring; par1: LongInt) : LongInt;
function ScriptCall(fname : shortstring; par1, par2: LongInt) : LongInt;
function ScriptCall(fname : shortstring; par1, par2, par3: LongInt) : LongInt;
function ScriptCall(fname : shortstring; par1, par2, par3, par4 : LongInt) : LongInt;
function ScriptExists(fname : shortstring) : boolean;


//function ParseCommandOverride(key, value : shortstring) : shortstring;  This did not work out well

procedure initModule;
procedure freeModule;

implementation
{$IFDEF USE_LUA_SCRIPT}
uses LuaPas,
    uConsole,
    uConsts,
    uVisualGears,
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
    SDLh,
    SysUtils, 
    uIO,
    uPhysFSLayer
    ;

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

function lc_band(L: PLua_State): LongInt; Cdecl;
begin
    if lua_gettop(L) <> 2 then 
        begin
        LuaError('Lua: Wrong number of parameters passed to band!');
        lua_pushnil(L);
        end
    else
        lua_pushinteger(L, lua_tointeger(L, 2) and lua_tointeger(L, 1));
    lc_band := 1;
end;

function lc_bor(L: PLua_State): LongInt; Cdecl;
begin
    if lua_gettop(L) <> 2 then 
        begin
        LuaError('Lua: Wrong number of parameters passed to bor!');
        lua_pushnil(L);
        end
    else
        lua_pushinteger(L, lua_tointeger(L, 2) or lua_tointeger(L, 1));
    lc_bor := 1;
end;

function lc_bnot(L: PLua_State): LongInt; Cdecl;
begin
    if lua_gettop(L) <> 1 then 
        begin
        LuaError('Lua: Wrong number of parameters passed to bnot!');
        lua_pushnil(L);
        end
    else
        lua_pushinteger(L, not lua_tointeger(L, 1));
    lc_bnot := 1;
end;

function lc_div(L: PLua_State): LongInt; Cdecl;
begin
    if lua_gettop(L) <> 2 then 
        begin
        LuaError('Lua: Wrong number of parameters passed to div!');
        lua_pushnil(L);
        end
    else
        lua_pushinteger(L, lua_tointeger(L, 1) div lua_tointeger(L, 2));
    lc_div := 1;
end;

function lc_getinputmask(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 0 then
        LuaError('Lua: Wrong number of parameters passed to GetInputMask!')
    else
        lua_pushinteger(L, InputMask);
    lc_getinputmask:= 1
end;

function lc_setinputmask(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to SetInputMask!')
    else
        InputMask:= lua_tointeger(L, 1);
    lc_setinputmask:= 0
end;

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
var t: PChar;
    i,c: LongWord;
    s: shortstring;
begin
    if lua_gettop(L) = 1 then
        begin
        t:= lua_tolstring(L,1,@c);

        for i:= 1 to c do s[i]:= t[i-1];
        s[0]:= char(c);

        ParseCommand(s, true, true);

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

function lc_enablegameflags(L : Plua_State) : LongInt; Cdecl;
var i : integer;
begin
    for i:= 1 to lua_gettop(L) do
        if (GameFlags and lua_tointeger(L, i)) = 0 then
            GameFlags := GameFlags + LongWord(lua_tointeger(L, i));
    ScriptSetInteger('GameFlags', GameFlags);
    lc_enablegameflags:= 0;
end;

function lc_disablegameflags(L : Plua_State) : LongInt; Cdecl;
var i : integer;
begin
    for i:= 1 to lua_gettop(L) do
        if (GameFlags and lua_tointeger(L, i)) <> 0 then
            GameFlags := GameFlags - LongWord(lua_tointeger(L, i));
    ScriptSetInteger('GameFlags', GameFlags);
    lc_disablegameflags:= 0;
end;

function lc_cleargameflags(L : Plua_State) : LongInt; Cdecl;
begin
    // Silence hint
    L:= L;
    GameFlags:= 0;
    ScriptSetInteger('GameFlags', GameFlags);
    lc_cleargameflags:= 0;
end;

function lc_addcaption(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) = 1 then
        AddCaption(lua_tostring(L, 1), cWhiteColor, capgrpMessage)
    else if lua_gettop(L) = 3 then
        begin
        AddCaption(lua_tostring(L, 1), lua_tointeger(L, 2) shr 8, TCapGroup(lua_tointeger(L, 3)));
        end
    else
        LuaError('Lua: Wrong number of parameters passed to AddCaption!');
    lc_addcaption:= 0;
end;

function lc_campaignlock(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) = 1 then
        begin
        // to be done
        end
    else
        LuaError('Lua: Wrong number of parameters passed to CampaignLock!');
    lc_campaignlock:= 0;
end;

function lc_campaignunlock(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) = 1 then
        begin
        // to be done
        end
    else
        LuaError('Lua: Wrong number of parameters passed to CampaignUnlock!');
    lc_campaignunlock:= 0;
end;

function lc_spawnfakehealthcrate(L: Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 4 then
        begin
        LuaError('Lua: Wrong number of parameters passed to SpawnFakeHealthCrate!');
        lua_pushnil(L);
        end
    else
        begin
        gear := SpawnFakeCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2),
        HealthCrate, lua_toboolean(L, 3), lua_toboolean(L, 4));
        lua_pushinteger(L, gear^.uid);
        end;
    lc_spawnfakehealthcrate := 1;        
end;

function lc_spawnfakeammocrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 4 then
        begin
        LuaError('Lua: Wrong number of parameters passed to SpawnFakeAmmoCrate!');
        lua_pushnil(L);
        end
    else
        begin
        gear := SpawnFakeCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2),
        AmmoCrate, lua_toboolean(L, 3), lua_toboolean(L, 4));
        lua_pushinteger(L, gear^.uid);
        end;
    lc_spawnfakeammocrate := 1;
end;

function lc_spawnfakeutilitycrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 4 then
        begin
        LuaError('Lua: Wrong number of parameters passed to SpawnFakeUtilityCrate!');
        lua_pushnil(L);
        end
    else
        begin  
        gear := SpawnFakeCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2),
        UtilityCrate, lua_toboolean(L, 3), lua_toboolean(L, 4));
        lua_pushinteger(L, gear^.uid);
        end;
    lc_spawnfakeutilitycrate := 1;
end;

function lc_spawnhealthcrate(L: Plua_State) : LongInt; Cdecl;
var gear: PGear;
var health: LongInt;
begin
    if (lua_gettop(L) < 2) or (lua_gettop(L) > 3) then
        begin
        LuaError('Lua: Wrong number of parameters passed to SpawnHealthCrate!');
        lua_pushnil(L);
        end
    else
        begin
        if lua_gettop(L) = 3 then
            health:= lua_tointeger(L, 3)
        else
            health:= cHealthCaseAmount;
        gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2), HealthCrate, health, 0);
        if gear <> nil then
            lua_pushinteger(L, gear^.uid)
        else
            lua_pushnil(L);
        end;
    lc_spawnhealthcrate := 1;        
end;

function lc_spawnammocrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if (lua_gettop(L) <> 3) and (lua_gettop(L) <> 4) then
        begin
        LuaError('Lua: Wrong number of parameters passed to SpawnAmmoCrate!');
        lua_pushnil(L);
        end
    else
        begin
        if (lua_gettop(L) = 3) then 
             gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2), AmmoCrate, lua_tointeger(L, 3), 0)
        else gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2), AmmoCrate, lua_tointeger(L, 3), lua_tointeger(L, 4));
        if gear <> nil then
            lua_pushinteger(L, gear^.uid)
        else
            lua_pushnil(L);
        end;
    lc_spawnammocrate := 1;
end;

function lc_spawnutilitycrate(L: PLua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if (lua_gettop(L) <> 3) and (lua_gettop(L) <> 4) then
        begin
        LuaError('Lua: Wrong number of parameters passed to SpawnUtilityCrate!');
        lua_pushnil(L);
        end
    else
        begin
        if (lua_gettop(L) = 3) then
             gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2), UtilityCrate, lua_tointeger(L, 3), 0)
        else gear := SpawnCustomCrateAt(lua_tointeger(L, 1), lua_tointeger(L, 2), UtilityCrate, lua_tointeger(L, 3), lua_tointeger(L, 4));
        if gear <> nil then
            lua_pushinteger(L, gear^.uid)
        else
            lua_pushnil(L);
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
        dx:= int2hwFloat(lua_tointeger(L, 5)) / 1000000;
        dy:= int2hwFloat(lua_tointeger(L, 6)) / 1000000;
        t:= lua_tointeger(L, 7);

        gear:= AddGear(x, y, gt, s, dx, dy, t);
        lastGearByUID:= gear;
        lua_pushinteger(L, gear^.uid)
        end;
    lc_addgear:= 1; // 1 return value
end;

function lc_deletegear(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to DeleteGear!');
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            gear^.Message:= gear^.Message or gmDelete;
        end;
    lc_deletegear:= 0
end;

function lc_addvisualgear(L : Plua_State) : LongInt; Cdecl;
var vg : PVisualGear;
    x, y, s: LongInt;
    c: Boolean;
    vgt: TVisualGearType;
begin
    if lua_gettop(L) <> 5 then
        begin
        LuaError('Lua: Wrong number of parameters passed to AddVisualGear!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        x:= lua_tointeger(L, 1);
        y:= lua_tointeger(L, 2);
        vgt:= TVisualGearType(lua_tointeger(L, 3));
        s:= lua_tointeger(L, 4);
        c:= lua_toboolean(L, 5);

        vg:= AddVisualGear(x, y, vgt, s, c);
        if vg <> nil then 
            begin
            lastVisualGearByUID:= vg;
            lua_pushinteger(L, vg^.uid)
            end
        else
            lua_pushinteger(L, 0)
        end;
    lc_addvisualgear:= 1; // 1 return value
end;

function lc_deletevisualgear(L : Plua_State) : LongInt; Cdecl;
var vg : PVisualGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to DeleteVisualGear!');
        end
    else
        begin
        vg:= VisualGearByUID(lua_tointeger(L, 1));
        if vg <> nil then
            DeleteVisualGear(vg);
        end;
    lc_deletevisualgear:= 0
end;

function lc_getvisualgearvalues(L : Plua_State) : LongInt; Cdecl;
var vg: PVisualGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetVisualGearValues!');
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L);
        lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L)
        end
    else
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
            lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L); lua_pushnil(L)
            end
        end;
    lc_getvisualgearvalues:= 10;
end;

function lc_setvisualgearvalues(L : Plua_State) : LongInt; Cdecl;
var vg : PVisualGear;
begin
    if lua_gettop(L) <> 11 then
        begin
        LuaError('Lua: Wrong number of parameters passed to SetVisualGearValues!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        vg:= VisualGearByUID(lua_tointeger(L, 1));
        if vg <> nil then
            begin
            vg^.X:= lua_tointeger(L, 2);
            vg^.Y:= lua_tointeger(L, 3);
            vg^.dX:= lua_tonumber(L, 4);
            vg^.dY:= lua_tonumber(L, 5);
            vg^.Angle:= lua_tonumber(L, 6);
            vg^.Frame:= lua_tointeger(L, 7);
            if lua_tointeger(L, 8) <> 0 then
                vg^.FrameTicks:= lua_tointeger(L, 8);  // find a better way to do this. maybe need to break all these up.
            vg^.State:= lua_tointeger(L, 9);
            vg^.Timer:= lua_tointeger(L, 10);
            vg^.Tint:= lua_tointeger(L, 11);
            end
        end;
    lc_setvisualgearvalues:= 0;
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
            lua_pushinteger(L, FollowGear^.uid);
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

function lc_getgearmessage(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetGearMessage!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.message)
        else
            lua_pushnil(L);
        end;
    lc_getgearmessage:= 1
end;

function lc_getgearelasticity(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetGearElasticity!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, hwRound(gear^.elasticity * _10000))
        else
            lua_pushnil(L);
        end;
    lc_getgearelasticity:= 1
end;

function lc_setgearmessage(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 2 then
        LuaError('Lua: Wrong number of parameters passed to SetGearMessage!')
    else
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
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetGearPos!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.Pos)
        else
            lua_pushnil(L);
        end;
    lc_getgearpos:= 1
end;

function lc_setgearpos(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 2 then
        LuaError('Lua: Wrong number of parameters passed to SetGearPos!')
    else
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
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetGearCollisionMask!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.CollisionMask)
        else
            lua_pushnil(L);
        end;
    lc_getgearcollisionmask:= 1
end;

function lc_setgearcollisionmask(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 2 then
        LuaError('Lua: Wrong number of parameters passed to SetGearCollisionMask!')
    else
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
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to GetHogLevel!')
    else
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
    if lua_gettop(L) <> 2 then
        LuaError('Lua: Wrong number of parameters passed to SetHogLevel!')
    else
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
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetHogClan!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            begin
            lua_pushinteger(L, gear^.Hedgehog^.Team^.Clan^.ClanIndex)
            end
        else
            lua_pushnil(L);
        end;
    lc_gethogclan:= 1
end;

function lc_getclancolor(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetClanColor!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else lua_pushinteger(L, ClansArray[lua_tointeger(L, 1)]^.Color shl 8 or $FF);
    lc_getclancolor:= 1
end;

function lc_setclancolor(L : Plua_State) : LongInt; Cdecl;
var clan : PClan;
    team : PTeam;
    hh   : THedgehog;
    i, j : LongInt;
    r, rr: TSDL_Rect;
    texsurf: PSDL_Surface;
begin
    if lua_gettop(L) <> 2 then
        LuaError('Lua: Wrong number of parameters passed to SetClanColor!')
    else
        begin
        clan := ClansArray[lua_tointeger(L, 1)];
        clan^.Color:= lua_tointeger(L, 2) shr 8;
        for i:= 0 to Pred(clan^.TeamsNumber) do
            begin
            team:= clan^.Teams[i];
            for j:= 0 to 7 do
                begin
                hh:= team^.Hedgehogs[j];
                if (hh.Gear <> nil) or (hh.GearHidden <> nil) then 
                    begin
                    FreeTexture(hh.NameTagTex);
                    hh.NameTagTex:= RenderStringTex(hh.Name, clan^.Color, fnt16);
                    RenderHealth(hh);
                    end;
                end;
            FreeTexture(team^.NameTagTex);
            team^.NameTagTex:= RenderStringTex(clan^.Teams[i]^.TeamName, clan^.Color, fnt16);
            r.w:= cTeamHealthWidth + 5;
            r.h:= team^.NameTagTex^.h;

            texsurf:= SDL_CreateRGBSurface(SDL_SWSURFACE, r.w, r.h, 32, RMask, GMask, BMask, AMask);
            TryDo(texsurf <> nil, errmsgCreateSurface, true);
            TryDo(SDL_SetColorKey(texsurf, SDL_SRCCOLORKEY, 0) = 0, errmsgTransparentSet, true);

            DrawRoundRect(@r, cWhiteColor, cNearBlackColor, texsurf, true);
            rr:= r;
            inc(rr.x, 2); dec(rr.w, 4); inc(rr.y, 2); dec(rr.h, 4);
            DrawRoundRect(@rr, clan^.Color, clan^.Color, texsurf, false);

            FreeTexture(team^.HealthTex);
            team^.HealthTex:= Surface2Tex(texsurf, false);
            SDL_FreeSurface(texsurf);
            MakeCrossHairs
            end
        end;
    lc_setclancolor:= 0
end;

function lc_gethogteamname(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetHogTeamName!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            begin
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Team^.TeamName))
            end
        else
            lua_pushnil(L);
        end;
    lc_gethogteamname:= 1
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
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            begin
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Name))
            end
        else
            lua_pushnil(L);
        end;
    lc_gethogname:= 1
end;

function lc_sethogname(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
  hogName: ShortString;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to SetHogName!');
        lua_pushnil(L)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then

        hogName:= lua_tostring(L, 2);
            gear^.Hedgehog^.Name:= hogName;

        FreeTexture(gear^.Hedgehog^.NameTagTex);
        gear^.Hedgehog^.NameTagTex:= RenderStringTex(gear^.Hedgehog^.Name, gear^.Hedgehog^.Team^.Clan^.Color, fnt16);

        end;
    lc_sethogname:= 0;
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
            lua_pushinteger(L, gear^.Timer)
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
            lua_pushinteger(L, gear^.Health)
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
            lua_pushinteger(L, hwRound(gear^.X))
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
            lua_pushinteger(L, hwRound(gear^.Y))
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

function lc_hogsay(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
   vgear : PVisualGear;
       s : LongWord;
begin
    if lua_gettop(L) = 4 then
        s:= lua_tointeger(L, 4)
    else
        s:= 0;

    if (lua_gettop(L) = 4) or (lua_gettop(L) = 3) then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            vgear:= AddVisualGear(0, 0, vgtSpeechBubble, s, true);
            if vgear <> nil then
               begin
               vgear^.Text:= lua_tostring(L, 2);
               vgear^.Hedgehog:= gear^.Hedgehog;
               vgear^.FrameTicks:= lua_tointeger(L, 3);
               if (vgear^.FrameTicks < 1) or (vgear^.FrameTicks > 3) then
                   vgear^.FrameTicks:= 1;
               lua_pushinteger(L, vgear^.Uid)
               end
            end
            else
                lua_pushnil(L)
        end
    else LuaError('Lua: Wrong number of parameters passed to HogSay!');
    lc_hogsay:= 1
end;

function lc_switchhog(L : Plua_State) : LongInt; Cdecl;
var gear, prevgear : PGear;
begin
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to SwitchHog!')
    else
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

{function lc_addammo(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin

    if lua_gettop(L) = 3 then
    begin
    gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Hedgehog <> nil) then
            AddAmmoAmount(gear^.Hedgehog^, TAmmoType(lua_tointeger(L, 2)), lua_tointeger(L,3) );
    end else
    
    if lua_gettop(L) = 2 then
    begin
    gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Hedgehog <> nil) then
            AddAmmo(gear^.Hedgehog^, TAmmoType(lua_tointeger(L, 2)));
    end else
    begin
        LuaError('Lua: Wrong number of parameters passed to AddAmmo!');
    end;

    lc_addammo:= 0;

end;}

function lc_addammo(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if (lua_gettop(L) = 3) or (lua_gettop(L) = 2) then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Hedgehog <> nil) then
            if lua_gettop(L) = 2 then
                AddAmmo(gear^.Hedgehog^, TAmmoType(lua_tointeger(L, 2)))
            else
                SetAmmo(gear^.Hedgehog^, TAmmoType(lua_tointeger(L, 2)), lua_tointeger(L, 3))
        end
    else LuaError('Lua: Wrong number of parameters passed to AddAmmo!');
    lc_addammo:= 0
end;

function lc_getammocount(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
    ammo : PAmmo;
begin
    if (lua_gettop(L) = 2) then
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Hedgehog <> nil) then 
            begin
            ammo:= GetAmmoEntry(gear^.Hedgehog^, TAmmoType(lua_tointeger(L, 2)));
            if ammo^.AmmoType = amNothing then
                lua_pushinteger(L, 0)
            else
                lua_pushinteger(L, ammo^.Count)
            end
        else lua_pushinteger(L, 0)
        end
    else 
        begin
        LuaError('Lua: Wrong number of parameters passed to GetAmmoCount!');
        lua_pushnil(L)
        end;
    lc_getammocount:= 1
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

        if (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            begin  
            RenderHealth(gear^.Hedgehog^);
            RecountTeamHealth(gear^.Hedgehog^.Team)
            end;

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

function lc_seteffect(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 3 then
        LuaError('Lua: Wrong number of parameters passed to SetEffect!')
    else begin
        gear := GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Hedgehog <> nil) then
            gear^.Hedgehog^.Effects[THogEffect(lua_tointeger(L, 2))]:= lua_tointeger(L, 3);
    end;
    lc_seteffect := 0;
end;
function lc_geteffect(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetEffect!');
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Hedgehog <> nil) then
            lua_pushinteger(L, gear^.Hedgehog^.Effects[THogEffect(lua_tointeger(L, 2))])
        else
            lua_pushinteger(L, 0)
        end;
    lc_geteffect:= 1
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

function lc_gettag(L : Plua_State) : LongInt; Cdecl;
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
            lua_pushinteger(L, gear^.Tag)
        else
            lua_pushnil(L);
        end;
    lc_gettag:= 1
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
    AddGear(0, 0, gtATFinishGame, 0, _0, _0, 3000);
    lc_endgame:= 0
end;

function lc_findplace(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
    fall: boolean;
    tryhard: boolean;
    left, right: LongInt;
begin
    tryhard:= false;
    if (lua_gettop(L) <> 4) and (lua_gettop(L) <> 5) then
        LuaError('Lua: Wrong number of parameters passed to FindPlace!')
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        fall:= lua_toboolean(L, 2);
        left:= lua_tointeger(L, 3);
        right:= lua_tointeger(L, 4);
        if lua_gettop(L) = 5 then
            tryhard:= lua_toboolean(L, 5);
        if gear <> nil then
            FindPlace(gear, fall, left, right, tryhard);
        if gear <> nil then
            lua_pushinteger(L, gear^.uid)
        else
            lua_pushnil(L);
        end;
    lc_findplace:= 1
end;

function lc_playsound(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) = 1 then
        PlaySound(TSound(lua_tointeger(L, 1)))
    else if lua_gettop(L) = 2 then
        begin
        gear:= GearByUID(lua_tointeger(L, 2));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            AddVoice(TSound(lua_tointeger(L, 1)),gear^.Hedgehog^.Team^.Voicepack)
        end
    else LuaError('Lua: Wrong number of parameters passed to PlaySound!');
    lc_playsound:= 0;
end;

function lc_addteam(L : Plua_State) : LongInt; Cdecl;
var np: LongInt;
begin
    np:= lua_gettop(L);
    if (np < 5) or (np > 6) then
        begin
        LuaError('Lua: Wrong number of parameters passed to AddTeam!');
        //lua_pushnil(L)
        end
    else
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
        ParseCommand('addhh ' + lua_tostring(L, 2) + ' ' + lua_tostring(L, 3) + ' ' + lua_tostring(L, 1), true, true);
        ParseCommand('hat ' + temp, true, true);
        lua_pushinteger(L, CurrentHedgehog^.Gear^.uid);
        end;
    lc_addhog:= 1;
end;

function lc_hogturnleft(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to HogTurnLeft!');
        end
    else
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
        else
            begin
            lua_pushnil(L);
            lua_pushnil(L)
            end;
        end;
    lc_getgearposition:= 2;
end;

function lc_setgearposition(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
    col: boolean;
    x, y: LongInt;
begin
    if lua_gettop(L) <> 3 then
        LuaError('Lua: Wrong number of parameters passed to SetGearPosition!')
    else
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
                AddGearCI(gear);
            SetAllToActive
            end
        end;
    lc_setgearposition:= 0
end;

function lc_getgeartarget(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetGearTarget!');
        lua_pushnil(L);
        lua_pushnil(L)
        end
    else
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
        end;
    lc_getgeartarget:= 2;
end;

function lc_setgeartarget(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 3 then
        LuaError('Lua: Wrong number of parameters passed to SetGearTarget!')
    else
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
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetGearVelocity!');
        lua_pushnil(L);
        lua_pushnil(L)
        end
    else
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
        end;
    lc_getgearvelocity:= 2;
end;

function lc_setgearvelocity(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 3 then
        LuaError('Lua: Wrong number of parameters passed to SetGearVelocity!')
    else
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
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to SetZoom!')
    else
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

function lc_setammostore(L : Plua_State) : LongInt; Cdecl;
var np: LongInt;
begin
    np:= lua_gettop(L);
    if (np <> 4) then
        LuaError('Lua: Wrong number of parameters passed to SetAmmoStore!')
    else
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
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetRandom!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        m:= lua_tointeger(L, 1);
        if (m > 0) then
            lua_pushinteger(L, GetRandom(m))
        else
            begin
            LuaError('Lua: Tried to pass 0 to GetRandom!');
            lua_pushnil(L);
            end
        end;
    lc_getrandom:= 1
end;

function lc_setwind(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to SetWind!')
    else
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
    if lua_gettop(L) <> 0 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetDataPath!');
        lua_pushnil(L);
        end
    else
        lua_pushstring(L, str2pchar(cPathz[ptData]));
    lc_getdatapath:= 1
end;

function lc_getuserdatapath(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 0 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetUserDataPath!');
        lua_pushnil(L);
        end
    else
        lua_pushstring(L, str2pchar(cPathz[ptData]));
    lc_getuserdatapath:= 1
end;

function lc_maphasborder(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 0 then
        begin
        LuaError('Lua: Wrong number of parameters passed to MapHasBorder!');
        lua_pushnil(L);
        end
    else
        lua_pushboolean(L, hasBorder);
    lc_maphasborder:= 1
end;

function lc_getgearradius(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetGearRadius!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            lua_pushinteger(L, gear^.Radius)
        else
            lua_pushnil(L);
        end;
    lc_getgearradius:= 1
end;

function lc_gethoghat(L : Plua_State): LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to GetHogHat!')
    else begin
        gear := GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and ((gear^.Kind = gtHedgehog) or (gear^.Kind = gtGrave)) and (gear^.Hedgehog <> nil) then
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Hat))
        else
            lua_pushnil(L);
    end;
    lc_gethoghat := 1;
end;

function lc_sethoghat(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
    hat: ShortString;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to SetHogHat!');
        lua_pushnil(L)
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            hat:= lua_tostring(L, 2);
            gear^.Hedgehog^.Hat:= hat;
AddFileLog('Changed hat to: '+hat);
            if (Length(hat) > 39) and (Copy(hat,1,8) = 'Reserved') and (Copy(hat,9,32) = gear^.Hedgehog^.Team^.PlayerHash) then
                LoadHedgehogHat(gear^.Hedgehog^, 'Reserved/' + Copy(hat,9,Length(hat)-8))
            else
                LoadHedgehogHat(gear^.Hedgehog^, hat);
        end;
    lc_sethoghat:= 0;
end;

function lc_placegirder(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 3 then
        LuaError('Lua: Wrong number of parameters passed to PlaceGirder!')
    else
        TryPlaceOnLand(
            lua_tointeger(L, 1) - SpritesData[sprAmGirder].Width div 2,
            lua_tointeger(L, 2) - SpritesData[sprAmGirder].Height div 2,
            sprAmGirder, lua_tointeger(L, 3), true, false);
    lc_placegirder:= 0
end;

function lc_getcurammotype(L : Plua_State): LongInt; Cdecl;
begin
    if lua_gettop(L) <> 0 then
        LuaError('Lua: Wrong number of parameters passed to GetCurAmmoType!')
    else
        lua_pushinteger(L, ord(CurrentHedgehog^.CurAmmoType));
    lc_getcurammotype := 1;
end;

function lc_savecampaignvar(L : Plua_State): LongInt; Cdecl;
begin
    if lua_gettop(L) <> 2 then
        LuaError('Lua: Wrong number of parameters passed to SaveCampaignVar!')
    else begin
        SendIPC('V!' + lua_tostring(L, 1) + ' ' + lua_tostring(L, 2) + #0);
    end;
    lc_savecampaignvar := 0;
end;

function lc_getcampaignvar(L : Plua_State): LongInt; Cdecl;
begin
    if (lua_gettop(L) <> 1) then
        LuaError('Lua: Wrong number of parameters passed to GetCampaignVar!')
    else
        SendIPCAndWaitReply('V?' + lua_tostring(L, 1));
    lua_pushstring(L, str2pchar(CampaignVariable));
    lc_getcampaignvar := 1;
end;

function lc_hidehog(L: Plua_State): LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to HideHog!')
    else
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
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to RestoreHog!')
    else
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
    if lua_gettop(L) <> 5 then
        begin
        LuaError('Lua: Wrong number of parameters passed to TestRectForObstacle!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else
        begin
        rtn:= TestRectancleForObstacle(
                    lua_tointeger(L, 1),
                    lua_tointeger(L, 2),
                    lua_tointeger(L, 3),
                    lua_tointeger(L, 4),
                    lua_toboolean(L, 5)
                    );
        lua_pushboolean(L, rtn);
        end;
    lc_testrectforobstacle:= 1
end;


function lc_setaihintsongear(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 2 then
        LuaError('Lua: Wrong number of parameters passed to SetAIHintOnGear!')
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            gear^.aihints:= lua_tointeger(L, 2);
        end;
    lc_setaihintsongear:= 0
end;


function lc_hedgewarsscriptload(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to HedgewarsScriptLoad!');
        lua_pushnil(L)
        end
    else
        ScriptLoad(lua_tostring(L, 1));
    lc_hedgewarsscriptload:= 0;
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
var i, j, k: LongInt;
begin
// not required if there is no script to run
if not ScriptLoaded then
    exit;

// push game variables so they may be modified by the script
ScriptSetInteger('BorderColor', ExplosionBorderColor);
ScriptSetInteger('GameFlags', GameFlags);
ScriptSetString('Seed', cSeed);
ScriptSetInteger('TemplateFilter', cTemplateFilter);
ScriptSetInteger('TemplateNumber', LuaTemplateNumber);
ScriptSetInteger('MapGen', cMapGen);
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
ScriptSetString('Map', cMapName);

ScriptSetString('Theme', '');
ScriptSetString('Goals', '');

ScriptCall('onGameInit');

// pop game variables
ParseCommand('seed ' + ScriptGetString('Seed'), true, true);
cTemplateFilter  := ScriptGetInteger('TemplateFilter');
LuaTemplateNumber:= ScriptGetInteger('TemplateNumber');
cMapGen          := ScriptGetInteger('MapGen');
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
ScriptSetInteger('TeamsCount', TeamsCount)
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
    exit;

f:= pfsOpenRead(s);
if f = nil then 
    exit;

physfsReaderSetBuffer(@buf);
ret:= lua_load(luaState, @physfsReader, f, Str2PChar(s));
pfsClose(f);

if ret <> 0 then
    begin
    LuaError('Lua: Failed to load ' + name + '(error ' + IntToStr(ret) + ')');
    LuaError('Lua: ' + lua_tostring(luaState, -1));
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
if GameTicks = 0 then
    begin
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
TurnTimeLeft:= ScriptGetInteger('TurnTimeLeft');
end;

procedure ScriptCall(fname : shortstring);
begin
if not ScriptLoaded or (not ScriptExists(fname)) then
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
if not ScriptLoaded or (not ScriptExists(fname)) then
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
//if (ord(ammo) < 1) or (count > 9) or (count < 0) or (propability < 0) or (propability > 8) or (delay < 0) or (delay > 9) or (reinforcement < 0) or (reinforcement > 8) then
if (ord(ammo) < 1) or (count > 9) or (propability > 8) or (delay > 9) or (reinforcement > 8) then
    exit;
ScriptAmmoLoadout[ord(ammo)]:= inttostr(count)[1];
ScriptAmmoProbability[ord(ammo)]:= inttostr(propability)[1];
ScriptAmmoDelay[ord(ammo)]:= inttostr(delay)[1];
ScriptAmmoReinforcement[ord(ammo)]:= inttostr(reinforcement)[1];
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
    st : TSound;
    he : THogEffect;
    cg : TCapGroup;
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

for he:= Low(THogEffect) to High(THogEffect) do
    ScriptSetInteger(EnumToStr(he), ord(he));

for cg:= Low(TCapGroup) to High(TCapGroup) do
    ScriptSetInteger(EnumToStr(cg), ord(cg));

ScriptSetInteger('gstDrowning'       ,$00000001);
ScriptSetInteger('gstHHDriven'       ,$00000002);
ScriptSetInteger('gstMoving'         ,$00000004);
ScriptSetInteger('gstAttacked'       ,$00000008);
ScriptSetInteger('gstAttacking'      ,$00000010);
ScriptSetInteger('gstCollision'      ,$00000020);
ScriptSetInteger('gstHHChooseTarget' ,$00000040);
ScriptSetInteger('gstHHJumping'      ,$00000100);
ScriptSetInteger('gsttmpFlag'        ,$00000200);
ScriptSetInteger('gstHHThinking'     ,$00000800);
ScriptSetInteger('gstNoDamage'       ,$00001000);
ScriptSetInteger('gstHHHJump'        ,$00002000);
ScriptSetInteger('gstAnimation'      ,$00004000);
ScriptSetInteger('gstHHDeath'        ,$00008000);
ScriptSetInteger('gstWinner'         ,$00010000);
ScriptSetInteger('gstWait'           ,$00020000);
ScriptSetInteger('gstNotKickable'    ,$00040000);
ScriptSetInteger('gstLoser'          ,$00080000);
ScriptSetInteger('gstHHGone'         ,$00100000);
ScriptSetInteger('gstInvisible'      ,$00200000);

// ai hints
ScriptSetInteger('aihUsualProcessing' ,$00000000);
ScriptSetInteger('aihDoesntMatter'    ,$00000001);

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
lua_register(luaState, _P'EnableGameFlags', @lc_enablegameflags);
lua_register(luaState, _P'DisableGameFlags', @lc_disablegameflags);
lua_register(luaState, _P'ClearGameFlags', @lc_cleargameflags);
lua_register(luaState, _P'DeleteGear', @lc_deletegear);
lua_register(luaState, _P'AddVisualGear', @lc_addvisualgear);
lua_register(luaState, _P'DeleteVisualGear', @lc_deletevisualgear);
lua_register(luaState, _P'GetVisualGearValues', @lc_getvisualgearvalues);
lua_register(luaState, _P'SetVisualGearValues', @lc_setvisualgearvalues);
lua_register(luaState, _P'SpawnHealthCrate', @lc_spawnhealthcrate);
lua_register(luaState, _P'SpawnAmmoCrate', @lc_spawnammocrate);
lua_register(luaState, _P'SpawnUtilityCrate', @lc_spawnutilitycrate);
lua_register(luaState, _P'SpawnFakeHealthCrate', @lc_spawnfakehealthcrate);
lua_register(luaState, _P'SpawnFakeAmmoCrate', @lc_spawnfakeammocrate);
lua_register(luaState, _P'SpawnFakeUtilityCrate', @lc_spawnfakeutilitycrate);
lua_register(luaState, _P'WriteLnToConsole', @lc_writelntoconsole);
lua_register(luaState, _P'GetGearType', @lc_getgeartype);
lua_register(luaState, _P'EndGame', @lc_endgame);
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
lua_register(luaState, _P'GetHogTeamName', @lc_gethogteamname);
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
lua_register(luaState, _P'SetZoom', @lc_setzoom);
lua_register(luaState, _P'GetZoom', @lc_getzoom);
lua_register(luaState, _P'HogSay', @lc_hogsay);
lua_register(luaState, _P'SwitchHog', @lc_switchhog);
lua_register(luaState, _P'HogTurnLeft', @lc_hogturnleft);
lua_register(luaState, _P'CampaignLock', @lc_campaignlock);
lua_register(luaState, _P'CampaignUnlock', @lc_campaignunlock);
lua_register(luaState, _P'GetGearElasticity', @lc_getgearelasticity);
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
lua_register(luaState, _P'PlaceGirder', @lc_placegirder);
lua_register(luaState, _P'GetCurAmmoType', @lc_getcurammotype);
lua_register(luaState, _P'TestRectForObstacle', @lc_testrectforobstacle);

lua_register(luaState, _P'SetGearAIHints', @lc_setaihintsongear);
lua_register(luaState, _P'HedgewarsScriptLoad', @lc_hedgewarsscriptload);


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
end;

procedure freeModule;
begin
end;

{$ENDIF}
end.

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
{$IFNDEF LUA_DISABLED}
uses LuaPas in 'LuaPas.pas',
    uConsole,
    uConsts,
    uVisualGears,
    uGears,
    uFloat,
    uWorld,
    uAmmos,
    uSound,
    uChat,
    uStats,
    uRandom,
    uTypes,
    uVariables,
    uCommands,
    uUtils,
    uKeys,
    uCaptions,
    uDebug;

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
    else lua_pushinteger(L, lua_tointeger(L, 2) and lua_tointeger(L, 1));
    lc_band := 1;
end;

function lc_bor(L: PLua_State): LongInt; Cdecl;
begin
    if lua_gettop(L) <> 2 then 
        begin
        LuaError('Lua: Wrong number of parameters passed to bor!');
        lua_pushnil(L);
        end
    else lua_pushinteger(L, lua_tointeger(L, 2) or lua_tointeger(L, 1));
    lc_bor := 1;
end;

function lc_bnot(L: PLua_State): LongInt; Cdecl;
begin
    if lua_gettop(L) <> 1 then 
        begin
        LuaError('Lua: Wrong number of parameters passed to bnot!');
        lua_pushnil(L);
        end
    else lua_pushinteger(L, not lua_tointeger(L, 1));
    lc_bnot := 1;
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

function lc_addcaption(L : Plua_State) : LongInt; Cdecl;
begin
    if lua_gettop(L) = 1 then
        begin
        AddCaption(lua_tostring(L, 1), cWhiteColor, capgrpMessage);
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
        lua_pushinteger(L, gear^.uid);
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
        lua_pushinteger(L, gear^.uid);
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
        lua_pushinteger(L, gear^.uid);
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
        if gear <> nil then DeleteGear(gear);
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
        if vg <> nil then lua_pushinteger(L, vg^.uid)
        else lua_pushinteger(L, 0)
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
        if vg <> nil then DeleteVisualGear(vg);
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
            vg^.FrameTicks:= lua_tointeger(L, 8);
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

function lc_gethoglevel(L : Plua_State): LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        LuaError('Lua: Wrong number of parameters passed to GetHogLevel!')
    else begin
        gear := GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
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
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            begin
            lua_pushinteger(L, gear^.Hedgehog^.Team^.Clan^.ClanIndex)
            end
        else
            lua_pushnil(L);
        end;
    lc_gethogclan:= 1
end;

function lc_getclancolor(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 1 then
        begin
        LuaError('Lua: Wrong number of parameters passed to GetClanColor!');
        lua_pushnil(L); // return value on stack (nil)
        end
    else lua_pushinteger(L, ClansArray[lua_tointeger(L, 1)]^.Color shl 8 or $FF);
    lc_getclancolor:= 1
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
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
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
        if (gear <> nil) and (gear^.Kind = gtHedgehog) and (gear^.Hedgehog <> nil) then
            begin
            lua_pushstring(L, str2pchar(gear^.Hedgehog^.Name))
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

function lc_hogsay(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
   vgear : PVisualGear;
begin
    if lua_gettop(L) <> 3 then
        begin
        LuaError('Lua: Wrong number of parameters passed to HogSay!');
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            begin
            vgear:= AddVisualGear(0, 0, vgtSpeechBubble);
            if vgear <> nil then
               begin
               vgear^.Text:= lua_tostring(L, 2);
               vgear^.Hedgehog:= gear^.Hedgehog;
               vgear^.FrameTicks:= lua_tointeger(L, 3);
               if (vgear^.FrameTicks < 1) or (vgear^.FrameTicks > 3) then vgear^.FrameTicks:= 1;
               end;
            end
        end;
    lc_hogsay:= 0
end;

function lc_addammo(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
    if lua_gettop(L) <> 2 then
        begin
        LuaError('Lua: Wrong number of parameters passed to AddAmmo!');
        end
    else
        begin
        gear:= GearByUID(lua_tointeger(L, 1));
        if (gear <> nil) and (gear^.Hedgehog <> nil) then
            AddAmmo(gear^.Hedgehog^, TAmmoType(lua_tointeger(L, 2)));
        end;
    lc_addammo:= 0
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

function lc_seteffect(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
    if lua_gettop(L) <> 3 then
        LuaError('Lua: Wrong number of parameters passed to SetEffect!')
    else begin
        gear := GearByUID(lua_tointeger(L, 1));
        if gear <> nil then
            gear^.Hedgehog^.Effects[THogEffect(lua_tointeger(L, 2))]:= lua_toboolean(L, 3);
    end;
    lc_seteffect := 0;
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
        AddGear(0, 0, gtATSmoothWindCh, 0, _0, _0, 1)^.Tag:= hwRound(cWindSpeed * 72 / cMaxWindSpeed);
        end;
    lc_setwind:= 0
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
ScriptSetInteger('HealthCaseProb', cHealthCaseProb);
ScriptSetInteger('HealthCaseAmount', cHealthCaseAmount);
ScriptSetInteger('DamagePercent', cDamagePercent);
ScriptSetInteger('MinesNum', cLandMines);
ScriptSetInteger('MinesTime', cMinesTime);
ScriptSetInteger('MineDudPercent', cMineDudPercent);
ScriptSetInteger('Explosives', cExplosives);
ScriptSetInteger('Delay', cInactDelay);
ScriptSetInteger('Ready', cReadyDelay);
ScriptSetInteger('SuddenDeathTurns', cSuddenDTurns);
ScriptSetInteger('WaterRise', cWaterRise);
ScriptSetInteger('HealthDecrease', cHealthDecrease);
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
ParseCommand('$healthprob ' + ScriptGetString('HealthCaseProb'), true);
ParseCommand('$hcaseamount ' + ScriptGetString('HealthCaseAmount'), true);
ParseCommand('$damagepct ' + ScriptGetString('DamagePercent'), true);
ParseCommand('$minesnum ' + ScriptGetString('MinesNum'), true);
ParseCommand('$minestime ' + ScriptGetString('MinesTime'), true);
ParseCommand('$minedudpct ' + ScriptGetString('MineDudPercent'), true);
ParseCommand('$explosives ' + ScriptGetString('Explosives'), true);
ParseCommand('$delay ' + ScriptGetString('Delay'), true);
ParseCommand('$ready ' + ScriptGetString('Ready'), true);
ParseCommand('$sd_turns ' + ScriptGetString('SuddenDeathTurns'), true);
ParseCommand('$waterrise ' + ScriptGetString('WaterRise'), true);
ParseCommand('$healthdec ' + ScriptGetString('HealthDecrease'), true);
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

ScriptSetInteger('ClansCount', ClansCount);
ScriptSetInteger('TeamsCount', TeamsCount)
end;

procedure ScriptLoad(name : shortstring);
var ret : LongInt;
begin
ret:= luaL_loadfile(luaState, Str2PChar(Pathz[ptData] + '/' + name));
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
    end
end;

procedure SetGlobals;
begin
ScriptSetInteger('TurnTimeLeft', TurnTimeLeft);
ScriptSetInteger('GameTime', GameTicks);
ScriptSetInteger('RealTime', RealTicks);
ScriptSetInteger('TotalRounds', TotalRounds);
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
    vgt: TVisualGearType;
    am : TAmmoType;
    st : TSound;
    he: THogEffect;
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

// register functions
lua_register(luaState, 'band', @lc_band);
lua_register(luaState, 'bor', @lc_bor);
lua_register(luaState, 'bnot', @lc_bnot);
lua_register(luaState, 'AddGear', @lc_addgear);
lua_register(luaState, 'DeleteGear', @lc_deletegear);
lua_register(luaState, 'AddVisualGear', @lc_addvisualgear);
lua_register(luaState, 'DeleteVisualGear', @lc_deletevisualgear);
lua_register(luaState, 'GetVisualGearValues', @lc_getvisualgearvalues);
lua_register(luaState, 'SetVisualGearValues', @lc_setvisualgearvalues);
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
lua_register(luaState, 'AddCaption', @lc_addcaption);
lua_register(luaState, 'SetAmmo', @lc_setammo);
lua_register(luaState, 'PlaySound', @lc_playsound);
lua_register(luaState, 'AddTeam', @lc_addteam);
lua_register(luaState, 'AddHog', @lc_addhog);
lua_register(luaState, 'AddAmmo', @lc_addammo);
lua_register(luaState, 'SetHealth', @lc_sethealth);
lua_register(luaState, 'GetHealth', @lc_gethealth);
lua_register(luaState, 'SetEffect', @lc_seteffect);
lua_register(luaState, 'GetHogClan', @lc_gethogclan);
lua_register(luaState, 'GetClanColor', @lc_getclancolor);
lua_register(luaState, 'GetHogTeamName', @lc_gethogteamname);
lua_register(luaState, 'GetHogName', @lc_gethogname);
lua_register(luaState, 'GetHogLevel', @lc_gethoglevel);
lua_register(luaState, 'SetHogLevel', @lc_sethoglevel);
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
lua_register(luaState, 'SetZoom', @lc_setzoom);
lua_register(luaState, 'GetZoom', @lc_getzoom);
lua_register(luaState, 'HogSay', @lc_hogsay);
lua_register(luaState, 'HogTurnLeft', @lc_hogturnleft);
lua_register(luaState, 'CampaignLock', @lc_campaignlock);
lua_register(luaState, 'CampaignUnlock', @lc_campaignunlock);
lua_register(luaState, 'GetGearMessage', @lc_getgearmessage);
lua_register(luaState, 'SetGearMessage', @lc_setgearmessage);
lua_register(luaState, 'GetRandom', @lc_getrandom);
lua_register(luaState, 'SetWind', @lc_setwind);


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

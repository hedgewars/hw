(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2008 Andrey Korotaev <unC0Rr@gmail.com>
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

procedure ScriptLoad(name : string);
procedure ScriptOnGameInit;

procedure ScriptCall(fname : string);
function ScriptCall(fname : string; par1: LongInt) : LongInt;
function ScriptCall(fname : string; par1, par2: LongInt) : LongInt;
function ScriptCall(fname : string; par1, par2, par3: LongInt) : LongInt;
function ScriptCall(fname : string; par1, par2, par3, par4 : LongInt) : LongInt;

procedure init_uScript;
procedure free_uScript;

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
	typinfo;
	
var luaState : Plua_State;
	ScriptAmmoStore : string;
	ScriptLoaded : boolean;
	
procedure ScriptPrepareAmmoStore; forward;
procedure ScriptApplyAmmoStore; forward;
procedure ScriptSetAmmo(ammo : TAmmoType; count, propability: Byte); forward;

// wrapped calls //

// functions called from lua:
// function(L : Plua_State) : LongInt; Cdecl;
// where L contains the state, returns the number of return values on the stack
// call lua_gettop(L) to receive number of parameters passed

function lc_writelntoconsole(L : Plua_State) : LongInt; Cdecl;
begin
	if lua_gettop(L) = 1 then
		begin
		WriteLnToConsole('LUA: ' + lua_tostring(L ,1));
		end
	else
		WriteLnToConsole('LUA: Wrong number of parameters passed to WriteLnToConsole!');
	lc_writelntoconsole:= 0;
end;

function lc_parsecommand(L : Plua_State) : LongInt; Cdecl;
begin
	if lua_gettop(L) = 1 then
		begin
		ParseCommand(lua_tostring(L ,1), true);
		end
	else
		WriteLnToConsole('LUA: Wrong number of parameters passed to ParseCommand!');
	lc_parsecommand:= 0;
end;

function lc_showmission(L : Plua_State) : LongInt; Cdecl;
begin
	if lua_gettop(L) = 5 then
		begin
		ShowMission(lua_tostring(L, 1), lua_tostring(L, 2), lua_tostring(L, 3), lua_tointeger(L, 4), lua_tointeger(L, 5));
		end
	else
		WriteLnToConsole('LUA: Wrong number of parameters passed to ShowMission!');
	lc_showmission:= 0;
end;

function lc_hidemission(L : Plua_State) : LongInt; Cdecl;
begin
	HideMission;
	lc_hidemission:= 0;
end;

function lc_addgear(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
	x, y, s, t: LongInt;
	dx, dy: hwFloat;
	gt: TGearType;
begin
	if lua_gettop(L) <> 7 then
		begin
		WriteLnToConsole('LUA: Wrong number of parameters passed to AddGear!');
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

function lc_getgeartype(L : Plua_State) : LongInt; Cdecl;
var gear : PGear;
begin
	if lua_gettop(L) <> 1 then
		begin
		WriteLnToConsole('LUA: Wrong number of parameters passed to GetGearType!');
		lua_pushnil(L); // return value on stack (nil)
		end
	else
		begin
		gear:= GearByUID(lua_tointeger(L, 1));
		if gear <> nil then
			lua_pushinteger(L, ord(gear^.Kind))
		end;
	lc_getgeartype:= 1
end;

function lc_endgame(L : Plua_State) : LongInt; Cdecl;
begin
	GameState:= gsExit;
	lc_endgame:= 0
end;

function lc_findplace(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
	fall: boolean;
	left, right: LongInt;
begin
	if lua_gettop(L) <> 4 then
		WriteLnToConsole('LUA: Wrong number of parameters passed to FindPlace!')
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
		WriteLnToConsole('LUA: Wrong number of parameters passed to PlaySound!')
	else
		PlaySound(TSound(lua_tointeger(L, 1)));
	lc_playsound:= 0;
end;

function lc_addteam(L : Plua_State) : LongInt; Cdecl;
begin
	if lua_gettop(L) <> 5 then
		begin
		WriteLnToConsole('LUA: Wrong number of parameters passed to AddTeam!');
		//lua_pushnil(L)
		end
	else
		begin
		ParseCommand('addteam ' + lua_tostring(L, 2) + ' ' + lua_tostring(L, 1), true);
		ParseCommand('grave ' + lua_tostring(L, 3), true);
		ParseCommand('fort ' + lua_tostring(L, 4), true);
		ParseCommand('voicepack ' + lua_tostring(L, 5), true);
		CurrentTeam^.Binds:= DefaultBinds;
		// fails on x64
		//lua_pushinteger(L, LongInt(CurrentTeam));
		end;
	lc_addteam:= 0;//1;
end;

function lc_addhog(L : Plua_State) : LongInt; Cdecl;
begin
	if lua_gettop(L) <> 4 then
		begin
		WriteLnToConsole('LUA: Wrong number of parameters passed to AddHog!');
		lua_pushnil(L)
		end
	else
		begin
		ParseCommand('addhh ' + lua_tostring(L, 2) + ' ' + lua_tostring(L, 3) + ' ' + lua_tostring(L, 1), true);
		ParseCommand('hat ' + lua_tostring(L, 4), true);
		lua_pushinteger(L, CurrentHedgehog^.Gear^.uid);
		end;
	lc_addhog:= 1;
end;

function lc_getgearposition(L : Plua_State) : LongInt; Cdecl;
var gear: PGear;
begin
	if lua_gettop(L) <> 1 then
		begin
		WriteLnToConsole('LUA: Wrong number of parameters passed to GetGearPosition!');
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
		WriteLnToConsole('LUA: Wrong number of parameters passed to SetGearPosition!')
	else
		begin
		gear:= GearByUID(lua_tointeger(L, 1));
		if gear <> nil then
			begin
			x:= lua_tointeger(L, 2);
			y:= lua_tointeger(L, 3);
			gear^.X:= int2hwfloat(x);
			gear^.Y:= int2hwfloat(y);
			end
		end;
	lc_setgearposition:= 0
end;

function lc_setammo(L : Plua_State) : LongInt; Cdecl;
begin
	if lua_gettop(L) <> 3 then
		WriteLnToConsole('LUA: Wrong number of parameters passed to SetAmmo!')
	else
		begin
		ScriptSetAmmo(TAmmoType(lua_tointeger(L, 1)), lua_tointeger(L, 2), lua_tointeger(L, 3));
		end;
	lc_setammo:= 0
end;
///////////////////

procedure ScriptPrintStack;
var n, i : LongInt;
begin
	n:= lua_gettop(luaState);
	WriteLnToConsole('LUA: Stack (' + inttostr(n) + ' elements):');
	for i:= 1 to n do
		if not lua_isboolean(luaState, i) then
			WriteLnToConsole('LUA:  ' + inttostr(i) + ': ' + lua_tostring(luaState, i))
		else if lua_toboolean(luaState, i) then
			WriteLnToConsole('LUA:  ' + inttostr(i) + ': true')
		else
			WriteLnToConsole('LUA:  ' + inttostr(i) + ': false');
end;

procedure ScriptClearStack;
begin
lua_settop(luaState, 0)
end;

procedure ScriptSetInteger(name : string; value : LongInt);
begin
lua_pushinteger(luaState, value);
lua_setglobal(luaState, Str2PChar(name));
end;

procedure ScriptSetString(name : string; value : string);
begin
lua_pushstring(luaState, Str2PChar(value));
lua_setglobal(luaState, Str2PChar(name));
end;

function ScriptGetInteger(name : string) : LongInt;
begin
lua_getglobal(luaState, Str2PChar(name));
ScriptGetInteger:= lua_tointeger(luaState, -1);
lua_pop(luaState, 1);
end;

function ScriptGetString(name : string) : string;
begin
lua_getglobal(luaState, Str2PChar(name));
ScriptGetString:= lua_tostring(luaState, -1);
lua_pop(luaState, 1);
end;

procedure ScriptOnGameInit;
begin
	// not required if there's no script to run
	if not ScriptLoaded then
		exit;
			
	// push game variables so they may be modified by the script
	ScriptSetInteger('GameFlags', GameFlags);
	ScriptSetString('Seed', cSeed);
	ScriptSetInteger('TurnTime', cHedgehogTurnTime);
	ScriptSetInteger('CaseFreq', cCaseFactor);
	ScriptSetInteger('LandAdds', cLandAdditions);
	ScriptSetInteger('Delay', cInactDelay);
	ScriptSetString('Map', '');
	ScriptSetString('Theme', '');

	ScriptCall('onGameInit');
	
	// pop game variables
	ParseCommand('seed ' + ScriptGetString('Seed'), true);
	ParseCommand('$gmflags ' + ScriptGetString('GameFlags'), true);
	ParseCommand('$turntime ' + ScriptGetString('TurnTime'), true);
	ParseCommand('$casefreq ' + ScriptGetString('CaseFreq'), true);
	ParseCommand('$landadds ' + ScriptGetString('LandAdds'), true);
	ParseCommand('$delay ' + ScriptGetString('Delay'), true);
	if ScriptGetString('Map') <> '' then
		ParseCommand('map ' + ScriptGetString('Map'), true);
	if ScriptGetString('Theme') <> '' then
		ParseCommand('theme ' + ScriptGetString('Theme'), true);	

	ScriptPrepareAmmoStore;
	ScriptCall('onAmmoStoreInit');
	ScriptApplyAmmoStore;
end;

procedure ScriptLoad(name : string);
var ret : LongInt;
begin
	ret:= luaL_loadfile(luaState, Str2PChar(name));
	if ret <> 0 then
		WriteLnToConsole('LUA: Failed to load ' + name + '(error ' + IntToStr(ret) + ')')
	else
		begin
		WriteLnToConsole('LUA: ' + name + ' loaded');
		// call the script file
		lua_pcall(luaState, 0, 0, 0);
		ScriptLoaded:= true
		end
end;

procedure ScriptCall(fname : string);
begin
	if not ScriptLoaded then
		exit;
	lua_getglobal(luaState, Str2PChar(fname));
	if lua_pcall(luaState, 0, 0, 0) <> 0 then
		begin
		WriteLnToConsole('LUA: Error while calling ' + fname + ': ' + lua_tostring(luaState, -1));
		lua_pop(luaState, 1)
		end;
end;

function ScriptCall(fname : string; par1: LongInt) : LongInt;
begin
ScriptCall:= ScriptCall(fname, par1, 0, 0, 0)
end;

function ScriptCall(fname : string; par1, par2: LongInt) : LongInt;
begin
ScriptCall:= ScriptCall(fname, par1, par2, 0, 0)
end;

function ScriptCall(fname : string; par1, par2, par3: LongInt) : LongInt;
begin
ScriptCall:= ScriptCall(fname, par1, par2, par3, 0)
end;

function ScriptCall(fname : string; par1, par2, par3, par4 : LongInt) : LongInt;
begin
	if not ScriptLoaded then
		exit;

	lua_getglobal(luaState, Str2PChar(fname));
	lua_pushinteger(luaState, par1);
	lua_pushinteger(luaState, par2);
	lua_pushinteger(luaState, par3);
	lua_pushinteger(luaState, par4);
	ScriptCall:= 0;
	if lua_pcall(luaState, 4, 1, 0) <> 0 then
		begin
		WriteLnToConsole('LUA: Error while calling ' + fname + ': ' + lua_tostring(luaState, -1));
		lua_pop(luaState, 1)
		end
	else
		begin
		ScriptCall:= lua_tointeger(luaState, -1);
		lua_pop(luaState, 1)
		end;
end;

procedure ScriptPrepareAmmoStore;
var i: ShortInt;
begin
ScriptAmmoStore:= '';
for i:=1 to ord(High(TAmmoType)) do
	ScriptAmmoStore:= ScriptAmmoStore + '00';
end;

procedure ScriptSetAmmo(ammo : TAmmoType; count, propability: Byte);
begin
if (ord(ammo) < 1) or (count > 9) or (count < 0) or (propability < 0) or (propability > 8) then
	exit;
ScriptAmmoStore[ord(ammo)]:= inttostr(count)[1];
ScriptAmmoStore[ord(ammo) + ord(high(TAmmoType))]:= inttostr(propability)[1];
end;

procedure ScriptApplyAmmoStore;
begin
	AddAmmoStore(ScriptAmmoStore);
end;

// small helper functions making registering enums a lot easier
function str(const en : TGearType) : string; overload;
begin
str:= GetEnumName(TypeInfo(TGearType), ord(en))
end;

function str(const en : TSound) : string; overload;
begin
str:= GetEnumName(TypeInfo(TSound), ord(en))
end;

function str(const en : TAmmoType) : string; overload;
begin
str:= GetEnumName(TypeInfo(TAmmoType), ord(en))
end;
///////////////////

procedure init_uScript;
var at : TGearType;
	am : TAmmoType;
	st : TSound;
begin
// initialize lua
luaState:= lua_open;

// open internal libraries
luaopen_base(luaState);
luaopen_string(luaState);
luaopen_math(luaState);

// import some variables
ScriptSetInteger('LAND_WIDTH', LAND_WIDTH);
ScriptSetInteger('LAND_HEIGHT', LAND_HEIGHT);

// import game flags
ScriptSetInteger('gfForts',gfForts);
ScriptSetInteger('gfMultiWeapon',gfMultiWeapon);
ScriptSetInteger('gfSolidLand',gfSolidLand);
ScriptSetInteger('gfBorder',gfBorder);
ScriptSetInteger('gfDivideTeams',gfDivideTeams);
ScriptSetInteger('gfLowGravity',gfLowGravity);
ScriptSetInteger('gfLaserSight',gfLaserSight);
ScriptSetInteger('gfInvulnerable',gfInvulnerable);
ScriptSetInteger('gfMines',gfMines);
ScriptSetInteger('gfVampiric',gfVampiric);
ScriptSetInteger('gfKarma',gfKarma);
ScriptSetInteger('gfArtillery',gfArtillery);
ScriptSetInteger('gfOneClanMode',gfOneClanMode);
ScriptSetInteger('gfRandomOrder',gfRandomOrder);
ScriptSetInteger('gfKing',gfKing);

// register gear types
for at:= Low(TGearType) to High(TGearType) do
	ScriptSetInteger(str(at), ord(at));

// register sounds
for st:= Low(TSound) to High(TSound) do
	ScriptSetInteger(str(st), ord(st));

// register ammo types
for am:= Low(TAmmoType) to High(TAmmoType) do
	ScriptSetInteger(str(am), ord(am));
	
// register functions
lua_register(luaState, 'AddGear', @lc_addgear);
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

ScriptClearStack; // just to be sure stack is empty
ScriptLoaded:= false;
end;

procedure free_uScript;
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

procedure ScriptLoad(name : string);
begin
end;

procedure ScriptOnGameInit;
begin
end;

procedure ScriptCall(fname : string);
begin
end;

function ScriptCall(fname : string; par1, par2, par3, par4 : LongInt) : LongInt;
begin
ScriptCall:= nil
end;

procedure init_uScript;
begin
end;

procedure free_uScript;
begin
end;

{$ENDIF}
end.

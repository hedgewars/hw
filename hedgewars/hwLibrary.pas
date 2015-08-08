(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2014 Andrey Korotaev <unC0Rr@gmail.com>
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

(*
 * When engine is compiled as library this unit will export functions
 * as C declarations for convenient library usage in your application
 * and language of choice.
 *
 * See also: C declarations on Wikipedia
 *           http://en.wikipedia.org/wiki/X86_calling_conventions#cdecl
 *)

Library hwLibrary;

uses hwengine, uTypes, uConsts, uVariables, uSound, uCommands, uUtils,
     uLocale{$IFDEF ANDROID}, jni{$ENDIF};

{$INCLUDE "config.inc"}

// retrieve protocol information
procedure HW_versionInfo(netProto: PLongInt; versionStr: PPChar); cdecl; export;
begin
    netProto^:= cNetProtoVersion;
    versionStr^:= cVersionString;
end;

function HW_versionString: PChar; cdecl; export;
begin
    exit(cVersionString + '-r' + cRevisionString + ' (' + cHashString + ')');
end;

// equivalent to esc+y; when closeFrontend = true the game exits after memory cleanup
procedure HW_terminate(closeFrontend: boolean); cdecl; export;
begin
    closeFrontend:= closeFrontend; // avoid hint
    ParseCommand('forcequit', true);
end;

function HW_getWeaponNameByIndex(whichone: LongInt): PChar; cdecl; export;
begin
    HW_getWeaponNameByIndex:= (str2pchar(trammo[Ammoz[TAmmoType(whichone+1)].NameId]));
end;

(*function HW_getWeaponCaptionByIndex(whichone: LongInt): PChar; cdecl; export;
begin
    HW_getWeaponCaptionByIndex:= (str2pchar(trammoc[Ammoz[TAmmoType(whichone+1)].NameId]));
end;

function HW_getWeaponDescriptionByIndex(whichone: LongInt): PChar; cdecl; export;
begin
    HW_getWeaponDescriptionByIndex:= (str2pchar(trammod[Ammoz[TAmmoType(whichone+1)].NameId]));
end;*)

function HW_getNumberOfWeapons: LongInt; cdecl; export;
begin
    HW_getNumberOfWeapons:= ord(high(TAmmoType));
end;

function HW_getMaxNumberOfHogs: LongInt; cdecl; export;
begin
    HW_getMaxNumberOfHogs:= cMaxHHIndex + 1;
end;

function HW_getMaxNumberOfTeams: LongInt; cdecl; export;
begin
    HW_getMaxNumberOfTeams:= cMaxTeams;
end;

procedure HW_memoryWarningCallback; cdecl; export;
begin
    ReleaseSound(false);
end;

{$IFDEF ANDROID}
function JNI_HW_versionInfoNet(env: PJNIEnv; obj: JObject):JInt;cdecl;
begin
    env:= env; // avoid hint
    obj:= obj; // avoid hint
    JNI_HW_versionInfoNet:= cNetProtoVersion;
end;

function JNI_HW_versionInfoVersion(env: PJNIEnv; obj: JObject):JString; cdecl;
var envderef : JNIEnv;
begin
    obj:= obj; // avoid hint
    envderef:= @env;
    JNI_HW_versionInfoVersion := envderef^.NewStringUTF(env, PChar(cVersionString));
end;

procedure JNI_HW_GenLandPreview(env: PJNIEnv; c: JClass; port: JInt); cdecl;
begin
    GenLandPreview(port);
end;

exports
    JNI_HW_versionInfoNet name Java_Prefix+'HWversionInfoNetProto',
    JNI_HW_versionInfoVersion name Java_Prefix+'HWversionInfoVersion',
    JNI_HW_GenLandPreview name Java_Prefix + 'HWGenLandPreview',
    HW_getNumberOfweapons name Java_Prefix + 'HWgetNumberOfWeapons',
    HW_getMaxNumberOfHogs name Java_Prefix + 'HWgetMaxNumberOfHogs',
    HW_getMaxNumberOfTeams name Java_Prefix + 'HWgetMaxNumberOfTeams',
    Game;
{$ELSE}
exports
    RunEngine,
{$IFDEF MOBILE}
    GenLandPreview,
{$ENDIF}
    LoadLocaleWrapper,
    HW_versionInfo,
    HW_versionString,
    HW_terminate,
    HW_getNumberOfWeapons,
    HW_getMaxNumberOfHogs,
    HW_getMaxNumberOfTeams,
    HW_getWeaponNameByIndex,
    HW_memoryWarningCallback;
{$ENDIF}

begin
end.

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

{$IFNDEF FPC}
    {$ERROR Only FreePascal Compiler is supported!}
{$ENDIF}

{$MACRO ON}
{$MODE OBJFPC}
{$DEFINE GLunit:=GL}
{$WRITEABLECONST OFF}
{$IMPLICITEXCEPTIONS OFF}
{$VARSTRINGCHECKS ON}

{$DEFINE USE_LUA_SCRIPT}

{$IFDEF ANDROID}
    {$DEFINE MOBILE}
    {$DEFINE USE_CONTEXT_RESTORE}
    {$DEFINE Java_Prefix:= 'Java_org_hedgewars_hedgeroid_EngineProtocol_PascalExports_'}
{$ENDIF}

{$IFDEF IPHONEOS}
    {$DEFINE MOBILE}
{$ENDIF}

{$IFDEF MOBILE}
    {$DEFINE HWLIBRARY}
    {$DEFINE GLunit:=gles11}
    {$DEFINE USE_LANDSCAPE_AMMOMENU}
    {$DEFINE USE_TOUCH_INTERFACE}
{$ELSE}
    {$DEFINE USE_AM_NUMCOLUMN}
    {$IFNDEF WEBGL}
        {$DEFINE USE_S3D_RENDERING}
    {$ENDIF}
{$ENDIF}


{$IFDEF WIN32}
    {$DEFINE USE_CONTEXT_RESTORE}
{$ENDIF}

{$IFDEF DARWIN}
    {$IFNDEF IPHONEOS}
        {$DEFINE USE_CONTEXT_RESTORE}
    {$ENDIF}
{$ENDIF}

{$DEFINE _S:=}
{$DEFINE _P:=}

//{$DEFINE TRACEAIACTIONS}
//{$DEFINE COUNTTICKS}


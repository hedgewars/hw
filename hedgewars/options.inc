(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

{$IFDEF FPC}
    {$WRITEABLECONST OFF}
    {$IMPLICITEXCEPTIONS OFF}
    {$VARSTRINGCHECKS ON}
    {$MODE OBJFPC}
{$ELSE}
    {$ERROR Only Free Pascal supported!}
{$ENDIF}

{$MACRO ON}
{$DEFINE GLunit:=GL}

{$DEFINE GL2}

{$IFDEF ANDROID}
    {$DEFINE SDL13}
    {$DEFINE HWLIBRARY}
    {$DEFINE S3D_DISABLED}
    {$DEFINE GLunit:=gles11}
    {$DEFINE MOBILE}
    {$DEFINE Java_Prefix:= 'Java_org_hedgewars_hedgeroid_EngineProtocol_PascalExports_'}
    {$DEFINE USE_SDLTHREADS}
    {$DEFINE USE_CONTEXT_RESTORE}
    {$DEFINE USE_LANDSCAPE_AMMOMENU}
    {$DEFINE USE_TOUCH_INTERFACE}
{$ENDIF}

{$IFDEF IPHONEOS}
    {$DEFINE SDL13}
    {$DEFINE HWLIBRARY}
    {$DEFINE S3D_DISABLED}
    {$DEFINE GLunit:=gles11}
    {$DEFINE MOBILE}
    {$DEFINE USE_LANDSCAPE_AMMOMENU}
    {$DEFINE USE_TOUCH_INTERFACE}
{$ENDIF}

{$IFDEF GL2}
    {$DEFINE S3D_DISABLED}
{$ENDIF}

{$IFDEF WIN32}
    {$DEFINE USE_CONTEXT_RESTORE}
{$ENDIF}

{$IFNDEF IPHONEOS}
    {$IFDEF DARWIN}
        {$DEFINE USE_CONTEXT_RESTORE}
    {$ENDIF}
    // not needed on ios because DEBUGFILE is switched from command line
    {$DEFINE DEBUGFILE}
    //{$DEFINE TRACEAIACTIONS}
    //{$DEFINE COUNTTICKS}
{$ENDIF}

{$IFNDEF MOBILE}
    {$DEFINE USE_AM_NUMCOLUMN}
{$ENDIF}

{$DEFINE USE_LUA_SCRIPT}

{$IFDEF PAS2C}
    {$DEFINE NOCONSOLE}
    {$DEFINE USE_SDLTHREADS}
{$ENDIF}

{$DEFINE _S:=}
{$DEFINE _P:=}

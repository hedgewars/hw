(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004, 2005 Andrey Korotaev <unC0Rr@gmail.com>
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
  {$J+}
{$ELSE}
  {$ERROR Only Free Pascal supported!}
{$ENDIF}

{$MODE OBJFPC}
{$MACRO ON}

{$DEFINE GLunit:=GL,GLext}

{$IFDEF IPHONEOS}
  {$DEFINE SDL13}
  {$DEFINE SDL_MIXER_NEWER}
  {$DEFINE SDL_IMAGE_NEWER}
  {$DEFINE HWLIBRARY}
  {$DEFINE NOCONSOLE}
  {$DEFINE GLunit:=gles11}
{$ENDIF}

{$IFNDEF DARWIN}
  {$DEFINE DEBUGFILE}
  {  $DEFINE DUMP}
  {  $DEFINE TRACEAIACTIONS}
  {  $DEFINE COUNTTICKS}
{$ENDIF}

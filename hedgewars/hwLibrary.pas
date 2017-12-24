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

(*
 * When engine is compiled as library this unit will export functions
 * as C declarations for convenient library usage in your application
 * and language of choice.
 *
 * See also: C declarations on Wikipedia
 *           http://en.wikipedia.org/wiki/X86_calling_conventions#cdecl
 *)

Library hwLibrary;

uses hwengine
    , uTypes
    , uConsts
    , uVariables
    , uSound
    , uCommands
    , uFLTypes
    , uFLIPC
    , uPhysFSLayer
    , uFLUICallback
    , uFLRunQueue
    ;

{$INCLUDE "config.inc"}

procedure flibInit(localPrefix, userPrefix: PChar); cdecl;
begin
    initIPC;
    uPhysFSLayer.initModule(localPrefix, userPrefix);
end;

procedure flibFree; cdecl;
begin
    uPhysFSLayer.freemodule;
    freeIPC;
end;

exports
    registerUIMessagesCallback,
    flibInit,
    flibFree,
    ipcToEngineRaw,
    ipcSetEngineBarrier,
    ipcRemoveBarrierFromEngineQueue,
    RunEngine
    ;

begin
end.

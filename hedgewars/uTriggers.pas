(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2007 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uTriggers;

interface
uses SDLh, uConsts;
{$INCLUDE options.inc}

procedure AddTrigger(id: Longword);
procedure DoTrigger(id: Longword);

implementation
uses uGears;
type PTrigger = ^TTrigger;
     TTrigger = record
                id: Longword;
                Next: PTrigger;
                end;
var TriggerList: PTrigger = nil;

procedure AddTrigger(id: Longword);
var tmp: PTrigger;
begin
new(tmp);
FillChar(tmp^, sizeof(TGear), 0);

tmp^.id:= id;
if TriggerList <> nil then tmp^.Next:= TriggerList;
TriggerList:= tmp
end;

procedure DoTrigger(id: Longword);
begin
end;

end.
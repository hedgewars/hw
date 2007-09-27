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
const trigTurns = $80000001;

type TTrigAction = (taSpawnGear, taSuccessFinish);

procedure AddTriggerSpawner(id, Ticks, Lives: Longword; X, Y: LongInt; GearType: TGearType; GearTriggerId: Longword);
procedure AddTriggerSuccess(tId: Longword);
procedure TickTrigger(id: Longword);

implementation
uses uGears, uFloat, uMisc, uWorld;
type PTrigger = ^TTrigger;
     TTrigger = record
                id: Longword;
                Ticks: Longword;
                Lives: Longword;
                TicksPerLife: LongWord;
                Action: TTrigAction;
                X, Y: LongInt;
                SpawnGearType: TGearType;
                SpawnGearTriggerId: Longword;
                Next: PTrigger;
                end;
var TriggerList: PTrigger = nil;

function AddTrigger: PTrigger;
var tmp: PTrigger;
begin
new(tmp);
FillChar(tmp^, sizeof(TTrigger), 0);
if TriggerList <> nil then tmp^.Next:= TriggerList;
TriggerList:= tmp;
AddTrigger:= tmp
end;

procedure AddTriggerSpawner(id, Ticks, Lives: Longword; X, Y: LongInt; GearType: TGearType; GearTriggerId: Longword);
var tmp: PTrigger;
begin
if (Ticks = 0) or (Lives = 0) then exit;
{$IFDEF DEBUGFILE}AddFileLog('Add spawner trigger: ' + inttostr(id) + ', gear triggers  ' + inttostr(GearTriggerId));{$ENDIF}

tmp:= AddTrigger;
tmp^.id:= id;
tmp^.Ticks:= Ticks;
tmp^.TicksPerLife:= Ticks;
tmp^.Lives:= Lives;
tmp^.Action:= taSpawnGear;
tmp^.X:= X;
tmp^.Y:= Y;
tmp^.SpawnGearType:= GearType;
tmp^.SpawnGearTriggerId:= GearTriggerId
end;

procedure AddTriggerSuccess(tId: Longword);
begin
with AddTrigger^ do
     begin
     id:= tId;
     Ticks:= 1;
     TicksPerLife:= 1;
     Action:= taSuccessFinish
     end
end;

procedure TickTriggerT(Trigger: PTrigger);
begin
with Trigger^ do
  case Action of
     taSpawnGear: begin
                  FollowGear:= AddGear(X, Y, SpawnGearType, 0, _0, _0, 0);
                  FollowGear^.TriggerId:= SpawnGearTriggerId
                  end;
 taSuccessFinish: begin
                  GameState:= gsExit
                  end
  end
end;

procedure TickTrigger(id: Longword);
var t, pt, nt: PTrigger;
begin
t:= TriggerList;
pt:= nil;

while (t <> nil) do
  begin
  nt:= t^.Next;
  if (t^.id = id) then
    begin
    dec(t^.Ticks);
    if (t^.Ticks = 0) then
       begin
       TickTriggerT(t);
       dec(t^.Lives);
       t^.Ticks:= t^.TicksPerLife;
       if (t^.Lives = 0) then
          begin
          if t = TriggerList then TriggerList:= nt
                             else pt^.Next:= nt;
          Dispose(t)
          end
       end
    end;
  pt:= t;
  t:= nt
  end
end;

end.
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

unit uLandPainted;

interface

procedure Draw;
procedure initModule;
procedure freeModule;

implementation
uses uLandGraphics, uConsts, uVariables, uUtils, SDLh, uCommands, uScript;

type PointRec = packed record
    X, Y: SmallInt;
    flags: byte;
    end;

type
    PPointEntry = ^PointEntry;
    PointEntry = record
        point: PointRec;
        next: PPointEntry;
        end;

var pointsListHead, pointsListLast: PPointEntry;

procedure chDraw(var s: shortstring);
var rec: PointRec;
    prec: ^PointRec;
    pe: PPointEntry;
    i, l: byte;
begin
    i:= 1;
    l:= length(s);
    while i < l do
        begin
        prec:= @s[i];
        rec:= prec^;
        rec.X:= SDLNet_Read16(@rec.X);
        rec.Y:= SDLNet_Read16(@rec.Y);
        if rec.X < -318 then rec.X:= -318;
        if rec.X > 4096+318 then rec.X:= 4096+318;
        if rec.Y < -318 then rec.Y:= -318;
        if rec.Y > 2048+318 then rec.Y:= 2048+318;

        new(pe);
        if pointsListLast = nil then
            pointsListHead:= pe
        else
            pointsListLast^.next:= pe;
        pointsListLast:= pe;

        pe^.point:= rec;
        pe^.next:= nil;

        inc(i, 5)
        end;
end;

procedure Draw;
var pe: PPointEntry;
    prevPoint: PointRec;
    radius: LongInt;
    color: Longword;
begin
    // shutup compiler
    prevPoint.X:= 0;
    prevPoint.Y:= 0;
    radius:= 0;

    pe:= pointsListHead;
    while (pe <> nil) and (pe^.point.flags and $80 = 0) do
        begin
        ScriptCall('onSpecialPoint', pe^.point.X, pe^.point.Y, pe^.point.flags);
        pe:= pe^.next;
        end;

    while(pe <> nil) do
        begin
        if (pe^.point.flags and $80 <> 0) then
            begin
            if (pe^.point.flags and $40 <> 0) then
                color:= 0
                else
                color:= lfBasic;
            radius:= (pe^.point.flags and $3F) * 5 + 3;
            AddFileLog('[DRAW] Move to: ('+inttostr(pe^.point.X)+','+inttostr(pe^.point.Y)+'), radius = '+inttostr(radius));
            FillRoundInLand(pe^.point.X, pe^.point.Y, radius, color)
            end
            else
            begin
            AddFileLog('[DRAW] Line to: ('+inttostr(pe^.point.X)+','+inttostr(pe^.point.Y)+'), radius = '+inttostr(radius));
            DrawThickLine(prevPoint.X, prevPoint.Y, pe^.point.X, pe^.point.Y, radius, color);
            FillRoundInLand(pe^.point.X, pe^.point.Y, radius, color)
            end;

        prevPoint:= pe^.point;
        pe:= pe^.next;
        end;
end;

procedure initModule;
begin
    pointsListHead:= nil;
    pointsListLast:= nil;

    RegisterVariable('draw', @chDraw, false);
end;

procedure freeModule;
var pe, pp: PPointEntry;
begin
    pe:= pointsListHead;
    while(pe <> nil) do
        begin
        pp:= pe;
        pe:= pe^.next;
        dispose(pp);
        end;
end;

end.

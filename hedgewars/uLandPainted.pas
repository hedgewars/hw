(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2010 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uLandPainted;

interface

procedure Draw;
procedure initModule;

implementation
uses uLandGraphics, uConsts, uUtils, SDLh, uCommands, uDebug;

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

procedure DrawLineOnLand(X1, Y1, X2, Y2: LongInt);
var  eX, eY, dX, dY: LongInt;
    i, sX, sY, x, y, d: LongInt;
    b: boolean;
    len: LongWord;
begin
    len:= 0;
    if (X1 = X2) and (Y1 = Y2) then
        begin
        exit
        end;
    eX:= 0;
    eY:= 0;
    dX:= X2 - X1;
    dY:= Y2 - Y1;

    if (dX > 0) then sX:= 1
    else
    if (dX < 0) then
        begin
        sX:= -1;
        dX:= -dX
        end else sX:= dX;

    if (dY > 0) then sY:= 1
    else
    if (dY < 0) then
        begin
        sY:= -1;
        dY:= -dY
        end else sY:= dY;

        if (dX > dY) then d:= dX
                    else d:= dY;

        x:= X1;
        y:= Y1;

        for i:= 0 to d do
            begin
            inc(eX, dX);
            inc(eY, dY);
            b:= false;
            if (eX > d) then
                begin
                dec(eX, d);
                inc(x, sX);
                b:= true
                end;
            if (eY > d) then
                begin
                dec(eY, d);
                inc(y, sY);
                b:= true
                end;
            if b then
                begin
                inc(len);
                if (len mod 4) = 0 then FillRoundInLand(X, Y, 34, lfBasic)
                end
        end
end;

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

        pe:= new(PPointEntry);
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
begin
    // shutup compiler
    prevPoint.X:= 0;
    prevPoint.Y:= 0;

    pe:= pointsListHead;
    TryDo((pe = nil) or (pe^.point.flags and $80 <> 0), 'Corrupted draw data', true);

    while(pe <> nil) do
        begin
        if (pe^.point.flags and $80 <> 0) then
            FillRoundInLand(pe^.point.X, pe^.point.Y, 34, lfBasic)
            else
            DrawLineOnLand(prevPoint.X, prevPoint.Y, pe^.point.X, pe^.point.Y);

        prevPoint:= pe^.point;
        pe:= pe^.next;  
        end;
end;

procedure initModule;
begin
    pointsListHead:= nil;
    pointsListLast:= nil;

    RegisterVariable('draw', vtCommand, @chDraw, false);
end;

end.

(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uLandTemplates;
interface
uses SDLh, uFloat;
{$INCLUDE options.inc}

type PPointArray = ^TPointArray;
     TPointArray = array[0..64] of TSDL_Rect;
     TEdgeTemplate = record
                     BasePoints: PPointArray;
                     BasePointsCount: Longword;
                     FillPoints: PPointArray;
                     FillPointsCount: Longword;
                     canMirror, canFlip: boolean;
                     end;

const Template0Points: array[0..4] of TSDL_Rect =
      (
       (x:  400; y: 1100; w: 1; h: 1),
       (x:  250; y:  400; w: 200; h: 200),
       (x:  923; y:  620; w: 200; h: 400),
       (x: 1600; y:  400; w: 200; h: 200),
       (x: 1450; y: 1100; w: 1; h: 1)
      );
      Template0FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const EdgeTemplates: array[0..0] of TEdgeTemplate =
      (
       (BasePoints: @Template0Points;
        BasePointsCount: Succ(High(Template0Points));
        FillPoints: @Template0FPoints;
        FillPointsCount: Succ(High(Template0FPoints));
        canMirror: false; canFlip: false;
       )
      );



implementation

end.

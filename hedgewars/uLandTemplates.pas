(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2005-2008 Andrey Korotaev <unC0Rr@gmail.com>
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
uses SDLh;
{$INCLUDE options.inc}

const NTPX = Low(TSDL_Rect.x); 

type PPointArray = ^TPointArray;
     TPointArray = array[0..64] of TSDL_Rect;
     TEdgeTemplate = record
                     BasePoints: PPointArray;
                     BasePointsCount: Longword;
                     FillPoints: PPointArray;
                     FillPointsCount: Longword;
                     BezierizeCount: Longword;
                     RandPassesCount: Longword;
                     TemplateHeight, TemplateWidth: LongInt;
                     canMirror, canFlip, isNegative, canInvert: boolean;
                     end;

//////////////////////////////////////////////////////////////////////////////
/////////////////// MIRRORED FOUR TIMES //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
// Hi unC0Rr.  Yeah, I know this is kind of lame.  Real templates should probably
// be made from scratch for taller/wider area.  But hey, for testing.
// The first 18 are in all 4 quadrants, the last 18 are in only the bottom 2
const Template0Points: array[0..18] of TSDL_Rect =
      (
       (x:  324; y:  756; w:  196; h:  204),
       (x:  224; y:  596; w:  404; h:   60),
       (x:  240; y:  268; w:  464; h:  152),
       (x:  876; y:  236; w:  168; h:  348),
       (x: 1204; y:   56; w:  148; h:  700),
       (x: 1516; y:   52; w:  192; h:  664),
       (x: 1808; y:   60; w:  328; h:  496),
       (x: 2292; y:   92; w:  184; h:  492),
       (x: 2664; y:  216; w:  196; h:  340),
       (x: 3004; y:  108; w:  176; h:  480),
       (x: 3260; y:  368; w:  120; h:  348),
       (x: 3476; y:  460; w:  208; h:  448),
       (x: 3268; y:  906; w:  192; h:   96),
       (x: 2876; y:  664; w:  204; h:  310),
       (x: 2240; y:  748; w:  344; h:  224),
       (x: 1584; y:  796; w:  440; h:  250),
       (x:  892; y:  852; w:  324; h:  184),
       (x:  576; y:  976; w:   16; h:   28),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template0FPoints: array[0..0] of TPoint =
      (
       (x: 2047; y:    0)
      );

//////////////////////////////////////////////////////////////////////////////
/////////////////// END MIRRORED TWO TIMES ///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

const EdgeTemplates: array[0..0] of TEdgeTemplate =
      (
       (BasePoints: @Template0Points;
        BasePointsCount: Succ(High(Template0Points));
        FillPoints: @Template0FPoints;
        FillPointsCount: Succ(High(Template0FPoints));
        BezierizeCount: 4;
        RandPassesCount: 12;
        TemplateHeight: 1024; TemplateWidth: 4096;
        canMirror: true; canFlip: false; isNegative: true; canInvert: false;
       )
      );



implementation

end.

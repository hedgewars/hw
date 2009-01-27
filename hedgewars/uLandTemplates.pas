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
const Template0Points: array[0..37] of TSDL_Rect =
      (
       (x:  410; y: 1024; w:    1; h:    1),
       (x:  160; y:  760; w:  130; h:  170),
       (x:  342; y:  706; w:  316; h:  150),
       (x:  238; y:  386; w:  270; h:  180),
       (x:  246; y:  176; w:  242; h:  156),
       (x:  552; y:  128; w:  610; h:  300),
       (x:  750; y:  468; w:  352; h:  324),
       (x:  650; y: 1024; w:  500; h:    1),
       (x: 1250; y: 1100; w:    1; h:    1),
       (x: 1490; y: 1024; w:    1; h:    1),
       (x: 1452; y:  904; w:   74; h:   12),
       (x: 1248; y:  575; w:   68; h:  425),
       (x: 1426; y:  592; w:  140; h:  142),
       (x: 1310; y:  192; w:  150; h:  350),
       (x: 1588; y:  194; w:  148; h:  242),
       (x: 1618; y:  472; w:  276; h:  314),
       (x: 1710; y:  850; w:  130; h:   86),
       (x: 1734; y: 1024; w:    1; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1),
       (x: 2458; y: 1024; w:    1; h:    1), // X + 2048
       (x: 2208; y:  760; w:  130; h:  170),
       (x: 2390; y:  706; w:  316; h:  150),
       (x: 2286; y:  386; w:  270; h:  180),
       (x: 2294; y:  176; w:  242; h:  156),
       (x: 2600; y:  128; w:  610; h:  300),
       (x: 2798; y:  468; w:  352; h:  324),
       (x: 2698; y: 1024; w:  500; h:    1),
       (x: 3298; y: 1100; w:    1; h:    1),
       (x: 3538; y: 1024; w:    1; h:    1),
       (x: 3500; y:  904; w:   74; h:   12),
       (x: 3296; y:  575; w:   68; h:  425),
       (x: 3474; y:  592; w:  140; h:  142),
       (x: 3358; y:  192; w:  150; h:  350),
       (x: 3636; y:  194; w:  148; h:  242),
       (x: 3666; y:  472; w:  276; h:  314),
       (x: 3758; y:  850; w:  130; h:   86),
       (x: 3782; y: 1024; w:    1; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template0FPoints: array[0..0] of TPoint =
      (
       (x: 2047; y:    0)
      );
const Template1Points: array[0..4] of TSDL_Rect =
      (
       (x:  100; y:  100; w:    1; h:    1),
       (x:  100; y:  100; w: 3000; h: 1500),
       (x:  500; y:  500; w: 2000; h: 1000),
       (x: 4000; y: 2000; w:    1; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template1FPoints: array[0..0] of TPoint =
      (
       (x: 2047; y:    0)
      );

//////////////////////////////////////////////////////////////////////////////
/////////////////// END MIRRORED TWO TIMES ///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

const EdgeTemplates: array[0..1] of TEdgeTemplate =
      (
       (BasePoints: @Template0Points;
        BasePointsCount: Succ(High(Template0Points));
        FillPoints: @Template0FPoints;
        FillPointsCount: Succ(High(Template0FPoints));
        BezierizeCount: 3;
        RandPassesCount: 8;
        TemplateHeight: 1024; TemplateWidth: 4096;
        canMirror: true; canFlip: false; isNegative: false; canInvert: true;
// Yes. I know this isn't a good map to invert, just testing
       ),
       (BasePoints: @Template1Points;
        BasePointsCount: Succ(High(Template1Points));
        FillPoints: @Template0FPoints;
        FillPointsCount: Succ(High(Template1FPoints));
        BezierizeCount: 6;
        RandPassesCount: 8;
        TemplateHeight: 2048; TemplateWidth: 4096;
        canMirror: true; canFlip: false; isNegative: true; canInvert: false;
// make a decent cave about one time in, oh, 5 or 6 :-/
       )
      );



implementation

end.

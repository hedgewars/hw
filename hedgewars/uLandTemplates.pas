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

const NTPX = Low(TSDL_Rect.x); 

type PPointArray = ^TPointArray;
     TPointArray = array[0..64] of TSDL_Rect;
     TEdgeTemplate = record
                     BasePoints: PPointArray;
                     BasePointsCount: Longword;
                     FillPoints: PPointArray;
                     FillPointsCount: Longword;
                     RandPassesCount: Longword;
                     canMirror, canFlip: boolean;
                     end;

const Template0Points: array[0..18] of TSDL_Rect =
      (
       (x:  410; y: 1024; w:    1; h:    1),
       (x:  160; y:  760; w:  130; h:  170),
       (x:  342; y:  706; w:  316; h:  150),
       (x:  238; y:  386; w:  270; h:  180),
       (x:  246; y:  176; w:  242; h:  156),
       (x:  622; y:  128; w:  480; h:  300),
       (x:  806; y:  468; w:  152; h:  324),
       (x:  650; y: 1024; w:  500; h:    1),
       (x: 1250; y: 1100; w:    1; h:    1),
       (x: 1490; y: 1024; w:    1; h:    1),
       (x: 1452; y:  904; w:   74; h:   12),
       (x: 1248; y:  575; w:   68; h:  425),
       (x: 1426; y:  592; w:  140; h:  142),
       (x: 1310; y:  192; w:  150; h:  350),
       (x: 1588; y:  194; w:  148; h:  332),
       (x: 1618; y:  472; w:  276; h:  314),
       (x: 1710; y:  850; w:  130; h:   86),
       (x: 1734; y: 1024; w:    1; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template0FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template1Points: array[0..15] of TSDL_Rect =
      (
       (x:  400; y: 1024; w:   25; h:    1),
       (x:  284; y:  892; w:  254; h:   58),
       (x:  492; y:  634; w:  100; h:  200),
       (x:  274; y:  256; w:  276; h:  400),
       (x:  620; y:  254; w:  125; h:  270),
       (x:  680; y:  550; w:   96; h:  390),
       (x:  826; y:  614; w:  110; h:  350),
       (x:  800; y:  186; w:  150; h:  380),
       (x: 1000; y:  186; w:  170; h:  375),
       (x: 1012; y:  540; w:  188; h:  298),
       (x: 1240; y:  668; w:  136; h:  172),
       (x: 1270; y:  194; w:  120; h:  392),
       (x: 1514; y:  194; w:  364; h:  362),
       (x: 1450; y:  652; w:  315; h:  232),
       (x: 1460; y: 1024; w:   25; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template1FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template2Points: array[0..21] of TSDL_Rect =
      (
       (x:  354; y: 1024; w:    1; h:    1),
       (x:  232; y:  926; w:  226; h:   60),
       (x:  120; y:  846; w:  298; h:   62),
       (x:  280; y:  704; w:  210; h:  102),
       (x:  208; y:  422; w:  192; h:  248),
       (x:  292; y:  160; w:  206; h:  240),
       (x:  526; y:  172; w:   92; h:  334),
       (x:  462; y:  528; w:  226; h:  126),
       (x:  556; y:  678; w:  268; h:  156),
       (x:  722; y:  164; w:  138; h:  500),
       (x:  890; y:  156; w:   94; h:  352),
       (x:  898; y:  562; w:  170; h:  264),
       (x: 1092; y:  384; w:   84; h:  446),
       (x: 1206; y:  200; w:  158; h:  278),
       (x: 1300; y:  490; w:  104; h:  336),
       (x: 1416; y:  546; w:   90; h:  398),
       (x: 1546; y:  192; w:  134; h:  532),
       (x: 1702; y:  246; w:  156; h:  258),
       (x: 1700; y:  548; w:  132; h:  340),
       (x: 1534; y:  898; w:  252; h:   82),
       (x: 1604; y: 1024; w:    1; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template2FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template3Points: array[0..16] of TSDL_Rect =
      (
       (x:  348; y: 1024; w:    1; h:    1),
       (x:  236; y:  852; w:  208; h:   72),
       (x:  498; y:  710; w:  308; h:   60),
       (x:  728; y:  852; w:  434; h:   40),
       (x: 1174; y:  712; w:  332; h:   40),
       (x: 1402; y:  838; w:  226; h:   36),
       (x: 1530; y: 1024; w:    1; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1),
       (x: 1660; y:  498; w:  111; h:  111),
       (x: 1270; y:  476; w:   34; h:  102),
       (x:  682; y:  414; w:  284; h:  132),
       (x:  230; y:  328; w:  126; h:  168),
       (x:  410; y:  174; w:  114; h:  100),
       (x:  790; y:  172; w:  352; h:  120),
       (x: 1274; y:  128; w:   60; h:  240),
       (x: 1434; y:  222; w:  254; h:  116),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template3FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template4Points: array[0..22] of TSDL_Rect =
      (
       (x:  418; y: 1024; w:    1; h:    1),
       (x:  248; y:  900; w:  186; h:   62),
       (x:  272; y:  692; w:  254; h:  138),
       (x:  610; y:  768; w:   90; h:  166),
       (x:  820; y:  616; w:  224; h:  258),
       (x: 1242; y:  758; w:   96; h:  146),
       (x: 1550; y:  698; w:  224; h:  134),
       (x: 1530; y:  902; w:  210; h:   54),
       (x: 1532; y: 1024; w:    1; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1),
       (x:  202; y:  418; w:  110; h:   92),
       (x:  252; y:  312; w:  160; h:   32),
       (x:  150; y:  168; w:  134; h:   78),
       (x:  702; y:  160; w:  132; h:   84),
       (x:  702; y:  308; w:  230; h:   36),
       (x:  720; y:  408; w:  166; h:   96),
       (x: NTPX; y:    0; w:    1; h:    1),
       (x: 1702; y:  434; w:  202; h:   42),
       (x: 1252; y:  388; w:  134; h:   98),
       (x: 1214; y:  152; w:  116; h:  154),
       (x: 1428; y:  252; w:  150; h:   70),
       (x: 1750; y:  152; w:   86; h:  220),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template4FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const EdgeTemplates: array[0..4] of TEdgeTemplate =
      (
       (BasePoints: @Template0Points;
        BasePointsCount: Succ(High(Template0Points));
        FillPoints: @Template0FPoints;
        FillPointsCount: Succ(High(Template0FPoints));
        RandPassesCount: 4;
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template1Points;
        BasePointsCount: Succ(High(Template1Points));
        FillPoints: @Template1FPoints;
        FillPointsCount: Succ(High(Template1FPoints));
        RandPassesCount: 3;
        canMirror: false; canFlip: false;
       ),
       (BasePoints: @Template2Points;
        BasePointsCount: Succ(High(Template2Points));
        FillPoints: @Template2FPoints;
        FillPointsCount: Succ(High(Template2FPoints));
        RandPassesCount: 3;
        canMirror: false; canFlip: false;
       ),
       (BasePoints: @Template3Points;
        BasePointsCount: Succ(High(Template3Points));
        FillPoints: @Template3FPoints;
        FillPointsCount: Succ(High(Template3FPoints));
        RandPassesCount: 3;
        canMirror: false; canFlip: false;
       ),
       (BasePoints: @Template4Points;
        BasePointsCount: Succ(High(Template4Points));
        FillPoints: @Template4FPoints;
        FillPointsCount: Succ(High(Template4FPoints));
        RandPassesCount: 3;
        canMirror: false; canFlip: false;
       )
      );



implementation

end.

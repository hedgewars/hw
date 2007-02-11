(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005-2007 Andrey Korotaev <unC0Rr@gmail.com>
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
                     BezierizeCount: Longword;
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
       (x:  254; y:  246; w:  276; h:  380),
       (x:  620; y:  254; w:  125; h:  270),
       (x:  680; y:  550; w:   96; h:  390),
       (x:  826; y:  614; w:  110; h:  350),
       (x:  800; y:  186; w:  150; h:  380),
       (x: 1000; y:  186; w:  170; h:  375),
       (x: 1012; y:  590; w:  188; h:  298),
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

const Template5Points: array[0..15] of TSDL_Rect =
      (
       (x:  274; y: 1024; w:    1; h:    1),
       (x:  190; y:  918; w:  168; h:   26),
       (x:  382; y:  576; w:  122; h:  314),
       (x:  568; y:  744; w:   56; h:  180),
       (x:  678; y:  856; w:   64; h:   56),
       (x:  740; y:  650; w:  106; h:  220),
       (x:  644; y:  496; w:  162; h:  140),
       (x:  496; y:  210; w:  886; h:  174),
       (x:  934; y:  448; w:  296; h:  108),
       (x:  950; y:  752; w:  152; h:  146),
       (x: 1172; y:  774; w:   60; h:  152),
       (x: 1284; y:  722; w:  150; h:  138),
       (x: 1494; y:  364; w:   56; h:  582),
       (x: 1620; y:  774; w:   94; h:  232),
       (x: 1612; y: 1024; w:    1; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1)
       );

      Template5FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template6Points: array[0..13] of TSDL_Rect =
      (
       (x:  368; y: 1022; w:    2; h:    2),
       (x:  266; y:  840; w:  302; h:  110),
       (x:  294; y:  512; w:  104; h:  290),
       (x:  570; y:  580; w:  364; h:  122),
       (x:  568; y:  440; w:  368; h:  100),
       (x:  232; y:  260; w:  482; h:  130),
       (x:  778; y:  242; w:   62; h:   64),
       (x:  990; y:  154; w:   58; h:  246),
       (x: 1200; y:  276; w:  590; h:   98),
       (x: 1088; y:  442; w:  214; h:  188),
       (x: 1050; y:  686; w:  406; h:   92),
       (x: 1584; y:  502; w:  190; h:  412),
       (x: 1646; y: 1020; w:    2; h:    2),
       (x: NTPX; y:    0; w:    1; h:    1)
       );
      Template6FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template7Points: array[0..5] of TSDL_Rect =
      (
       (x:  162; y: 1024; w:  400; h:    1),
       (x:  226; y:  234; w:  142; h:  360),
       (x:  936; y:  740; w:  400; h:  200),
       (x: 1576; y:  176; w:  186; h:  550),
       (x: 1430; y: 1024; w:  454; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template7FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );


const Template8Points: array[0..19] of TSDL_Rect =
      (
       (x:  364; y: 1024; w:   20; h:    1),
       (x:  290; y:  860; w:   64; h:   62),
       (x:  486; y:  750; w:   52; h:  146),
       (x:  256; y:  590; w:  116; h:  144),
       (x:  470; y:  468; w:  138; h:  168),
       (x:  242; y:  242; w:  158; h:  162),
       (x:  508; y:  310; w:  198; h:   72),
       (x:  770; y:  228; w:  118; h:  134),
       (x:  636; y:  718; w:  142; h:  132),
       (x:  968; y:  700; w:  172; h:   58),
       (x:  970; y:  804; w:  172; h:   62),
       (x: 1232; y:  704; w:   82; h:  226),
       (x: 1356; y:  594; w:   64; h:  152),
       (x: 1214; y:  334; w:  106; h:  152),
       (x: 1410; y:  260; w:  380; h:   82),
       (x: 1528; y:  422; w:   30; h:  118),
       (x: 1540; y:  588; w:  212; h:   50),
       (x: 1464; y:  746; w:  128; h:  146),
       (x: 1630; y: 1024; w:   20; h:    1),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template8FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template9Points: array[0..31] of TSDL_Rect =
      (
       (x:  340; y: 1022; w:    2; h:    2),
       (x:  276; y:  902; w:   44; h:   54),
       (x:  434; y:  836; w:   58; h:   90),
       (x:  266; y:  734; w:   80; h:   80),
       (x:  246; y:  604; w:   96; h:  108),
       (x:  426; y:  646; w:  110; h:  112),
       (x:  234; y:  292; w:  118; h:  164),
       (x:  428; y:  396; w:  130; h:  110),
       (x:  516; y:  198; w:  344; h:   78),
       (x:  688; y:  426; w:   50; h:   40),
       (x:  626; y:  560; w:   32; h:  148),
       (x:  698; y:  650; w:  160; h:   34),
       (x:  674; y:  788; w:   36; h:  136),
       (x: 1014; y:  848; w:   48; h:   48),
       (x: 1086; y:  728; w:   64; h:   88),
       (x:  958; y:  660; w:   70; h:   74),
       (x: 1116; y:  596; w:   68; h:   70),
       (x: 1118; y:  484; w:   68; h:   82),
       (x:  958; y:  324; w:   44; h:  140),
       (x: 1272; y:  306; w:   52; h:   66),
       (x: 1254; y:  502; w:   58; h:   66),
       (x: 1234; y:  760; w:   76; h:  112),
       (x: 1380; y:  762; w:  124; h:   64),
       (x: 1472; y:  472; w:   54; h:  134),
       (x: 1410; y:  196; w:  246; h:   62),
       (x: 1706; y:  154; w:   38; h:  238),
       (x: 1812; y:  348; w:   28; h:   28),
       (x: 1692; y:  524; w:  144; h:   94),
       (x: 1632; y:  678; w:  248; h:   20),
       (x: 1632; y:  802; w:  238; h:   16),
       (x: 1680; y: 1020; w:    2; h:    2),
       (x: NTPX; y:    0; w:    1; h:    1)
      );
      Template9FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );


const EdgeTemplates: array[0..9] of TEdgeTemplate =
      (
       (BasePoints: @Template0Points;
        BasePointsCount: Succ(High(Template0Points));
        FillPoints: @Template0FPoints;
        FillPointsCount: Succ(High(Template0FPoints));
        BezierizeCount: 3;
        RandPassesCount: 1;
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template1Points;
        BasePointsCount: Succ(High(Template1Points));
        FillPoints: @Template1FPoints;
        FillPointsCount: Succ(High(Template1FPoints));
        BezierizeCount: 3;
        RandPassesCount: 2;
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template2Points;
        BasePointsCount: Succ(High(Template2Points));
        FillPoints: @Template2FPoints;
        FillPointsCount: Succ(High(Template2FPoints));
        BezierizeCount: 2;
        RandPassesCount: 2;
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template3Points;
        BasePointsCount: Succ(High(Template3Points));
        FillPoints: @Template3FPoints;
        FillPointsCount: Succ(High(Template3FPoints));
        BezierizeCount: 3;
        RandPassesCount: 2;
        canMirror: false; canFlip: false;
       ),
       (BasePoints: @Template4Points;
        BasePointsCount: Succ(High(Template4Points));
        FillPoints: @Template4FPoints;
        FillPointsCount: Succ(High(Template4FPoints));
        BezierizeCount: 3;
        RandPassesCount: 2;
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template5Points;
        BasePointsCount: Succ(High(Template5Points));
        FillPoints: @Template5FPoints;
        FillPointsCount: Succ(High(Template5FPoints));
        BezierizeCount: 2;
        RandPassesCount: 3;
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template6Points;
        BasePointsCount: Succ(High(Template6Points));
        FillPoints: @Template6FPoints;
        FillPointsCount: Succ(High(Template6FPoints));
        BezierizeCount: 3;
        RandPassesCount: 1;
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template7Points;
        BasePointsCount: Succ(High(Template7Points));
        FillPoints: @Template7FPoints;
        FillPointsCount: Succ(High(Template7FPoints));
        BezierizeCount: 4;
        RandPassesCount: 1;
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template8Points;
        BasePointsCount: Succ(High(Template8Points));
        FillPoints: @Template8FPoints;
        FillPointsCount: Succ(High(Template8FPoints));
        BezierizeCount: 2;
        RandPassesCount: 2;
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template9Points;
        BasePointsCount: Succ(High(Template9Points));
        FillPoints: @Template9FPoints;
        FillPointsCount: Succ(High(Template9FPoints));
        BezierizeCount: 2;
        RandPassesCount: 3;
        canMirror: true; canFlip: false;
       )
      );



implementation

end.

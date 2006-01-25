(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uLandTemplates;
interface
uses SDLh;
{$INCLUDE options.inc}

type PPointArray = ^TPointArray;
     TPointArray = array[0..0] of TPoint;
     TEdgeTemplate = record
                     BasePoints: PPointArray;
                     BasePointsCount: Longword;
                     BezPassCnt: Longword; 
                     PassMin, PassDelta: Longword;
                     WaveAmplMin, WaveAmplDelta: real;
                     WaveFreqMin, WaveFreqDelta: real;
                     FillPoints: PPointArray;
                     FillPointsCount: Longword;
                     canMirror, canFlip: boolean;
                     end;

const Template0Points: array[0..4] of TPoint =
      (
       (x:  500; y: 1500),
       (x:  350; y:  400),
       (x: 1023; y:  820),
       (x: 1700; y:  400),
       (x: 1550; y: 1500)
      );
      Template0FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template1Points: array[0..12] of TPoint =
      (
       (x:  300; y: 1500),
       (x:  300; y: 1000),
       (x:  250; y:  750),
       (x:  550; y:  480),
       (x:  650; y:  780),
       (x:  810; y:  780),
       (x:  800; y:  500),
       (x: 1200; y:  500),
       (x: 1300; y:  800),
       (x: 1500; y:  500),
       (x: 1800; y:  750),
       (x: 1750; y: 1000),
       (x: 1750; y: 1500)
      );
      Template1FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template2Points: array[0..28] of TPoint =
      (
       (x:  350; y: 1500),
       (x:  350; y: 1000),
       (x:  190; y:  850),
       (x:  500; y:  750),
       (x:  520; y:  450),
       (x:  190; y:  600),
       (x:  210; y:  260),
       (x:  800; y:  310),
       (x: 1350; y:  220),
       (x: 1250; y:  360),
       (x: 1550; y:  520),
       (x: 1100; y:  400),
       (x:  900; y:  470),
       (x:  650; y:  400),
       (x:  900; y:  750),
       (x:  600; y:  750),
       (x:  600; y:  850),
       (x: 1100; y:  900),
       (x: 1200; y: 1000),
       (x: 1200; y: 1300),
       (x: 1400; y: 1300),
       (x: 1400; y: 1000),
       (x: 1280; y:  850),
       (x: 1150; y:  630),
       (x: 1600; y:  850),
       (x: 1800; y:  600),
       (x: 1900; y:  600),
       (x: 1700; y: 1010),
       (x: 1700; y: 1500)
      );
      Template2FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template3Points: array[0..23] of TPoint =
      (
       (x:  200; y: 1500),
       (x:  200; y: 1000),
       (x:  390; y:  650),
       (x:  210; y:  260),
       (x: 1000; y:  420),
       (x: 1100; y:  200),
       (x: 1250; y:  420),
       (x: 1250; y:  620),
       (x:  900; y:  610),
       (x:  650; y:  450),
       (x:  550; y:  500),
       (x:  650; y:  700),
       (x: 1200; y:  800),
       (x: 1200; y: 1000),
       (x: 1200; y: 1200),
       (x: 1400; y: 1200),
       (x: 1400; y: 1000),
       (x: 1280; y:  750),
       (x: 1500; y:  600),
       (x: 1400; y:  200),
       (x: 1800; y:  200),
       (x: 1700; y:  600),
       (x: 1900; y: 1010),
       (x: 1800; y: 1200)
      );
      Template3FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template4Points: array[0..38] of TPoint =
      (
       (x:  200; y: 1500),
       (x:  200; y: 1000),
       (x:  210; y:  800),
       (x:  480; y:  830),
       (x:  460; y:  700),
       (x:  150; y:  610),
       (x:  150; y:  310),
       (x:  220; y:  200),
       (x:  340; y:  195),
       (x:  410; y:  415),
       (x:  420; y:  495),
       (x:  535; y:  615),
       (x:  705; y:  600),
       (x:  760; y:  425),
       (x:  815; y:  230),
       (x:  970; y:  200),
       (x: 1050; y:  360),
       (x:  850; y:  590),
       (x: 1070; y:  790),
       (x: 1000; y: 1000),
       (x: 1000; y: 1500),
       (x: 1250; y: 1500),
       (x: 1250; y: 1000),
       (x: 1260; y:  830),
       (x: 1290; y:  700),
       (x: 1270; y:  450),
       (x: 1180; y:  280),
       (x: 1210; y:  160),
       (x: 1370; y:  160),
       (x: 1505; y:  205),
       (x: 1630; y:  315),
       (x: 1660; y:  450),
       (x: 1580; y:  620),
       (x: 1670; y:  725),
       (x: 1800; y:  730),
       (x: 1860; y:  680),
       (x: 1925; y:  810),
       (x: 1800; y: 1000),
       (x: 1800; y: 1500)
      );
      Template4FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );
    
const Template5Points: array[0..10] of TPoint =
      (
       (x:  225; y: 1260),
       (x:  254; y:  226),
       (x:  729; y:  238),
       (x:  658; y:  441),
       (x:  661; y:  651),
       (x: 1023; y:  759),
       (x: 1374; y:  648),
       (x: 1473; y:  285),
       (x: 1803; y:  207),
       (x: 1839; y:  801),
       (x: 1674; y: 1239)
      );
      Template5FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template6Points: array[0..20] of TPoint =
      (
       (x:  318; y: 1494),
       (x:  270; y: 1023),
       (x:  252; y:  921),
       (x:  480; y:  888),
       (x:  492; y:  753),
       (x:  654; y:  756),
       (x:  687; y:  630),
       (x:  906; y:  627),
       (x:  987; y:  813),
       (x: 1125; y:  825),
       (x: 1134; y:  645),
       (x: 1236; y:  558),
       (x: 1260; y:  438),
       (x: 1467; y:  462),
       (x: 1536; y:  348),
       (x: 1680; y:  402),
       (x: 1713; y:  594),
       (x: 1593; y:  693),
       (x: 1707; y:  774),
       (x: 1728; y:  894),
       (x: 1788; y: 1491)
      );
      Template6FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template7Points: array[0..43] of TPoint =
      (
       (x:  180; y: 1485),
       (x:  411; y: 1020),
       (x:  402; y:  912),
       (x:  141; y:  897),
       (x:  156; y:  729),
       (x:  417; y:  813),
       (x:  432; y:  585),
       (x:  147; y:  570),
       (x:  138; y:  435),
       (x:  444; y:  417),
       (x:  447; y:  207),
       (x:  573; y:  261),
       (x:  663; y:  201),
       (x:  711; y:  375),
       (x:  897; y:  411),
       (x:  936; y:  498),
       (x:  663; y:  558),
       (x:  669; y:  762),
       (x:  957; y:  723),
       (x:  984; y:  864),
       (x:  729; y:  879),
       (x:  879; y: 1020),
       (x:  981; y: 1449),
       (x: 1242; y: 1449),
       (x: 1476; y: 1020),
       (x: 1470; y:  900),
       (x: 1284; y:  897),
       (x: 1218; y:  774),
       (x: 1464; y:  765),
       (x: 1464; y:  672),
       (x: 1119; y:  630),
       (x: 1116; y:  537),
       (x: 1485; y:  501),
       (x: 1167; y:  246),
       (x: 1263; y:  180),
       (x: 1572; y:  312),
       (x: 1767; y:  162),
       (x: 1827; y:  306),
       (x: 1647; y:  465),
       (x: 1875; y:  621),
       (x: 1683; y:  747),
       (x: 1665; y:  831),
       (x: 1818; y:  951),
       (x: 1893; y: 1476)
      );
      Template7FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template8Points: array[0..23] of TPoint =
      (
       (x:  222; y: 1482),
       (x:  354; y: 1023),
       (x:  249; y:  783),
       (x:  240; y:  421),
       (x:  411; y:  401),
       (x:  432; y:  777),
       (x:  573; y:  777),
       (x:  567; y:  300),
       (x:  696; y:  250),
       (x:  744; y:  683),
       (x:  897; y:  698),
       (x:  885; y:  450),
       (x: 1032; y:  479),
       (x: 1065; y:  698),
       (x: 1200; y:  690),
       (x: 1200; y:  218),
       (x: 1326; y:  252),
       (x: 1359; y:  786),
       (x: 1470; y:  810),
       (x: 1485; y:  379),
       (x: 1608; y:  342),
       (x: 1641; y:  819),
       (x: 1719; y:  864),
       (x: 1746; y: 1440)
      );
      Template8FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const Template9Points: array[0..23] of TPoint =
      (
       (x:  384; y: 1488),
       (x:  210; y: 1023),
       (x:  213; y:  891),
       (x:  501; y:  861),
       (x:  228; y:  657),
       (x:  558; y:  676),
       (x:  561; y:  513),
       (x:  246; y:  354),
       (x:  609; y:  393),
       (x:  876; y:  309),
       (x:  759; y:  576),
       (x:  759; y:  762),
       (x: 1113; y:  750),
       (x: 1128; y:  873),
       (x: 1488; y:  870),
       (x: 1473; y:  678),
       (x: 1182; y:  501),
       (x: 1515; y:  507),
       (x: 1776; y:  393),
       (x: 1668; y:  630),
       (x: 1833; y:  714),
       (x: 1674; y:  837),
       (x: 1800; y: 1020),
       (x: 1632; y: 1491)
      );
      Template9FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y:    0)
      );

const EdgeTemplates: array[0..9] of TEdgeTemplate =
      (
       (BasePoints: @Template0Points;
        BasePointsCount: Succ(High(Template0Points));
        BezPassCnt: 4;
        PassMin: 10; PassDelta: 5;
        WaveAmplMin:    17; WaveAmplDelta: 20;
        WaveFreqMin: 0.010; WaveFreqDelta: 0.002;
        FillPoints: @Template0FPoints;
        FillPointsCount: Succ(High(Template0FPoints));
        canMirror: false; canFlip: false;
       ),
       (BasePoints: @Template1Points;
        BasePointsCount: Succ(High(Template1Points));
        BezPassCnt: 3;
        PassMin: 10; PassDelta: 2;
        WaveAmplMin:    25; WaveAmplDelta: 15;
        WaveFreqMin: 0.008; WaveFreqDelta: 0.002;
        FillPoints: @Template1FPoints;
        FillPointsCount: Succ(High(Template1FPoints));
        canMirror: false; canFlip: false;
       ),
       (BasePoints: @Template2Points;
        BasePointsCount: Succ(High(Template2Points));
        BezPassCnt: 3;
        PassMin: 14; PassDelta: 3;
        WaveAmplMin:    10; WaveAmplDelta: 10;
        WaveFreqMin: 0.010; WaveFreqDelta: 0.002;
        FillPoints: @Template2FPoints;
        FillPointsCount: Succ(High(Template2FPoints));
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template3Points;
        BasePointsCount: Succ(High(Template3Points));
        BezPassCnt: 4;
        PassMin: 15; PassDelta: 2;
        WaveAmplMin:    8; WaveAmplDelta: 12;
        WaveFreqMin: 0.015; WaveFreqDelta: 0.0015;
        FillPoints: @Template3FPoints;
        FillPointsCount: Succ(High(Template3FPoints));
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template4Points;
        BasePointsCount: Succ(High(Template4Points));
        BezPassCnt: 3;
        PassMin: 19; PassDelta: 5;
        WaveAmplMin:    12; WaveAmplDelta: 14;
        WaveFreqMin: 0.008; WaveFreqDelta: 0.001;
        FillPoints: @Template4FPoints;
        FillPointsCount: Succ(High(Template4FPoints));
        canMirror: true; canFlip: false;
       ),
       (BasePoints: @Template5Points;
        BasePointsCount: Succ(High(Template5Points));
        BezPassCnt: 4;
        PassMin: 15; PassDelta: 1;
        WaveAmplMin:    15; WaveAmplDelta: 14;
        WaveFreqMin: 0.008; WaveFreqDelta: 0.002;
        FillPoints: @Template5FPoints;
        FillPointsCount: Succ(High(Template5FPoints));
        canMirror: true; canFlip: false;
       ),
      (BasePoints: @Template6Points;
       BasePointsCount: Succ(High(Template6Points));
       BezPassCnt: 3;
       PassMin: 15; PassDelta: 1;
       WaveAmplMin:    15; WaveAmplDelta: 10;
       WaveFreqMin: 0.010; WaveFreqDelta: 0.0015;
       FillPoints: @Template6FPoints;
       FillPointsCount: Succ(High(Template6FPoints));
       canMirror: true; canFlip: false;
      ),
      (BasePoints: @Template7Points;
       BasePointsCount: Succ(High(Template7Points));
       BezPassCnt: 3;
       PassMin: 12; PassDelta: 4;
       WaveAmplMin:     5; WaveAmplDelta: 15;
       WaveFreqMin: 0.015; WaveFreqDelta: 0.002;
       FillPoints: @Template7FPoints;
       FillPointsCount: Succ(High(Template7FPoints));
       canMirror: true; canFlip: false;
      ),
      (BasePoints: @Template8Points;
       BasePointsCount: Succ(High(Template8Points));
       BezPassCnt: 4;
       PassMin:  9; PassDelta: 3;
       WaveAmplMin:    18; WaveAmplDelta: 18;
       WaveFreqMin: 0.010; WaveFreqDelta: 0.002;
       FillPoints: @Template8FPoints;
       FillPointsCount: Succ(High(Template8FPoints));
       canMirror: true; canFlip: false;
      ),
      (BasePoints: @Template9Points;
       BasePointsCount: Succ(High(Template8Points));
       BezPassCnt: 4;
       PassMin: 17; PassDelta: 3;
       WaveAmplMin:    10; WaveAmplDelta: 10;
       WaveFreqMin: 0.010; WaveFreqDelta: 0.002;
       FillPoints: @Template9FPoints;
       FillPointsCount: Succ(High(Template9FPoints));
       canMirror: true; canFlip: false;
      )
      );



implementation

end.

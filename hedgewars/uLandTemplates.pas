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
       (x: 1023; y: 1023)
      );

const Template1Points: array[0..6] of TPoint =
      (
       (x:  300; y: 1500),
       (x:  300; y: 1000),
       (x:  250; y:  750),
       (x: 1200; y:  500),
       (x: 1800; y:  750),
       (x: 1750; y: 1000),
       (x: 1750; y: 1500)
      );
      Template1FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y: 1023)
      );

const Template2Points: array[0..21] of TPoint =
      (
       (x:  350; y: 1500),
       (x:  350; y: 1000),
       (x:  190; y:  850),
       (x:  500; y:  750),
       (x:  520; y:  450),
       (x:  190; y:  600),
       (x:  210; y:  260),
       (x: 1650; y:  220),
       (x: 1650; y:  460),
       (x:  900; y:  410),
       (x:  650; y:  400),
       (x: 1200; y: 1000),
       (x: 1200; y: 1200),
       (x: 1400; y: 1200),
       (x: 1400; y: 1000),
       (x: 1280; y:  750),
       (x: 1150; y:  530),
       (x: 1700; y:  750),
       (x: 1800; y:  600),
       (x: 1900; y:  600),
       (x: 1700; y: 1010),
       (x: 1700; y: 1200)
      );
      Template2FPoints: array[0..1] of TPoint =
      (
       (x:  600; y: 1023),
       (x: 1500; y: 1023)
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
      Template3FPoints: array[0..1] of TPoint =
      (
       (x:  500; y: 1023),
       (x: 1500; y: 1023)
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
      Template4FPoints: array[0..1] of TPoint =
      (
       (x:  500; y: 1023),
       (x: 1500; y: 1023)
      );

const EdgeTemplates: array[0..4] of TEdgeTemplate =
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
        BezPassCnt: 4;
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
       )
      );

implementation

end.

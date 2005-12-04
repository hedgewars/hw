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
       (x: 1023; y:  600),
       (x: 1800; y:  750),
       (x: 1750; y: 1000),
       (x: 1750; y: 1500)
      );
      Template1FPoints: array[0..0] of TPoint =
      (
       (x: 1023; y: 1023)
      );

const Template2Points: array[0..18] of TPoint =
      (
       (x:  350; y: 1500),
       (x:  350; y: 1000),
       (x:  190; y:  650),
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

const EdgeTemplates: array[0..2] of TEdgeTemplate =
      (
       (BasePoints: @Template0Points;
        BasePointsCount: Succ(High(Template0Points));
        BezPassCnt: 4;
        PassMin: 5; PassDelta: 1;
        WaveAmplMin:    27; WaveAmplDelta: 22;
        WaveFreqMin: 0.010; WaveFreqDelta: 0.015;
        FillPoints: @Template0FPoints;
        FillPointsCount: Succ(High(Template0FPoints));
       ),
       (BasePoints: @Template1Points;
        BasePointsCount: Succ(High(Template1Points));
        BezPassCnt: 4;
        PassMin: 6; PassDelta: 2;
        WaveAmplMin:    20; WaveAmplDelta: 10;
        WaveFreqMin: 0.015; WaveFreqDelta: 0.020;
        FillPoints: @Template1FPoints;
        FillPointsCount: Succ(High(Template1FPoints));
       ),
       (BasePoints: @Template2Points;
        BasePointsCount: Succ(High(Template2Points));
        BezPassCnt: 2;
        PassMin: 4; PassDelta: 1;
        WaveAmplMin:    30; WaveAmplDelta: 15;
        WaveFreqMin: 0.010; WaveFreqDelta: 0.015;
        FillPoints: @Template2FPoints;
        FillPointsCount: Succ(High(Template2FPoints));
       )
      );

implementation

end.

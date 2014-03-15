unit uLandGenTemplateBased;
interface

uses uLandTemplates;

procedure GenTemplated(var Template: TEdgeTemplate);

implementation
uses uVariables, uConsts, uFloat, uLandOutline, uLandUtils, uRandom, SDLh;


procedure SetPoints(var Template: TEdgeTemplate; var pa: TPixAr; fps: PPointArray);
var i: LongInt;
begin
    with Template do
        begin
        pa.Count:= BasePointsCount;
        for i:= 0 to pred(pa.Count) do
            begin
            pa.ar[i].x:= BasePoints^[i].x + LongInt(GetRandom(BasePoints^[i].w));
            if pa.ar[i].x <> NTPX then
                pa.ar[i].x:= pa.ar[i].x + ((LAND_WIDTH - Template.TemplateWidth) div 2);
            pa.ar[i].y:= BasePoints^[i].y + LongInt(GetRandom(BasePoints^[i].h)) + LAND_HEIGHT - LongInt(Template.TemplateHeight)
            end;

        if canMirror then
            if getrandom(2) = 0 then
                begin
                for i:= 0 to pred(BasePointsCount) do
                if pa.ar[i].x <> NTPX then
                    pa.ar[i].x:= LAND_WIDTH - 1 - pa.ar[i].x;
                for i:= 0 to pred(FillPointsCount) do
                    fps^[i].x:= LAND_WIDTH - 1 - fps^[i].x;
                end;

(*  Experiment in making this option more useful
     if ((not isNegative) and (cTemplateFilter = 4)) or
        (canFlip and (getrandom(2) = 0)) then
           begin
           for i:= 0 to pred(BasePointsCount) do
               begin
               pa.ar[i].y:= LAND_HEIGHT - 1 - pa.ar[i].y + (LAND_HEIGHT - TemplateHeight) * 2;
               if pa.ar[i].y > LAND_HEIGHT - 1 then
                   pa.ar[i].y:= LAND_HEIGHT - 1;
               end;
           for i:= 0 to pred(FillPointsCount) do
               begin
               FillPoints^[i].y:= LAND_HEIGHT - 1 - FillPoints^[i].y + (LAND_HEIGHT - TemplateHeight) * 2;
               if FillPoints^[i].y > LAND_HEIGHT - 1 then
                   FillPoints^[i].y:= LAND_HEIGHT - 1;
               end;
           end;
     end
*)
// template recycling.  Pull these off the floor a bit
    if (not isNegative) and (cTemplateFilter = 4) then
        begin
        for i:= 0 to pred(BasePointsCount) do
            begin
            dec(pa.ar[i].y, 100);
            if pa.ar[i].y < 0 then
                pa.ar[i].y:= 0;
            end;
        for i:= 0 to pred(FillPointsCount) do
            begin
            dec(fps^[i].y, 100);
            if fps^[i].y < 0 then
                fps^[i].y:= 0;
            end;
        end;

    if (canFlip and (getrandom(2) = 0)) then
        begin
        for i:= 0 to pred(BasePointsCount) do
            pa.ar[i].y:= LAND_HEIGHT - 1 - pa.ar[i].y;
        for i:= 0 to pred(FillPointsCount) do
            fps^[i].y:= LAND_HEIGHT - 1 - fps^[i].y;
        end;
    end
end;


procedure Distort1(var Template: TEdgeTemplate; var pa: TPixAr);
var i: Longword;
begin
    for i:= 1 to Template.BezierizeCount do
        begin
        BezierizeEdge(pa, _0_5);
        RandomizePoints(pa);
        RandomizePoints(pa)
        end;
    for i:= 1 to Template.RandPassesCount do
        RandomizePoints(pa);
    BezierizeEdge(pa, _0_1);
end;


procedure FindLimits(si: LongInt; var pa: TPixAr);
var p1, p2, mp, ap: TPoint;
    i, t1, t2, a, b, p, q, iy, ix, aqpb: LongInt;
begin
    // [p1, p2] is segment we're trying to divide
    p1:= pa.ar[si];
    p2:= pa.ar[si + 1];

    // its middle point
    mp.x:= (p1.x + p2.x) div 2;
    mp.y:= (p1.y + p2.y) div 2;
    // another point on the perpendicular bisector
    ap.x:= mp.x + p2.y - p1.y;
    ap.y:= mp.y + p1.x - p2.x;

    for i:= 0 to pa.Count - 1 do
        if i <> si then
        begin
            // check if it intersects
            t1:= (mp.x - pa.ar[i].x) * (mp.y - ap.y) - (mp.x - ap.x) * (mp.y - pa.ar[i].y);
            t2:= (mp.x - pa.ar[i + 1].x) * (mp.y - ap.y) - (mp.x - ap.x) * (mp.y - pa.ar[i + 1].y);

            if (t1 > 0) <> (t2 > 0) then // yes it does, hard arith follows
            begin
                a:= p2.y - p1.y;
                b:= p1.x - p2.x;
                p:= pa.ar[i + 1].x - pa.ar[i].x;
                q:= pa.ar[i + 1].y - pa.ar[i].y;
                aqpb:= a * q - p * b;

                if (aqpb <> 0) then
                begin
                    // (ix; iy) is intersection point
                    iy:= (((pa.ar[i].x - mp.x) * b + mp.y * a) * q - pa.ar[i].y * p * b);
                    if b <> 0 then
                        ix:= (iy - mp.y * aqpb) * a div b div aqpb + mp.x;
                    else
                        ix:= (iy - pa.ar[i].y * aqpb) * p div q div aqpb + pa.ar[i].x;
                    iy:= iy div aqpb;

                    writeln('>>>     Intersection     <<<');
                    writeln(p1.x, '; ', p1.y, ' - ', p2.x, '; ', p2.y);
                    writeln(pa.ar[i].x, '; ', pa.ar[i].y, ' - ', pa.ar[i + 1].x, '; ', pa.ar[i + 1].y);
                    writeln('== ', ix, '; ', iy);
                end;
            end;
        end;
end;

procedure DivideEdges(var pa: TPixAr);
var npa: TPixAr;
    i: LongInt;
begin
    i:= 0;
    npa.Count:= 0;
    while i < pa.Count do
    begin
        if i = 0 then
        begin
            FindLimits(0, pa);
            npa.ar[npa.Count]:= pa.ar[i];
            pa.ar[i].y:= 300;
            npa.ar[npa.Count + 1]:= pa.ar[i];
            inc(npa.Count, 2)
        end else
        begin
            npa.ar[npa.Count]:= pa.ar[i];
            inc(npa.Count)
        end;

        inc(i)
    end;

    pa:= npa;
end;

procedure Distort2(var Template: TEdgeTemplate; var pa: TPixAr);
//var i: Longword;
begin
    DivideEdges(pa);
    {for i:= 1 to Template.BezierizeCount do
        begin
        BezierizeEdge(pa, _0_5);
        RandomizePoints(pa);
        RandomizePoints(pa)
        end;
    for i:= 1 to Template.RandPassesCount do
        RandomizePoints(pa);}
    BezierizeEdge(pa, _0_9);
end;


procedure GenTemplated(var Template: TEdgeTemplate);
var pa: TPixAr;
    i: Longword;
    y, x: Longword;
    fps: TPointArray;
begin
    fps:=Template.FillPoints^;
    ResizeLand(Template.TemplateWidth, Template.TemplateHeight);
    for y:= 0 to LAND_HEIGHT - 1 do
        for x:= 0 to LAND_WIDTH - 1 do
            Land[y, x]:= lfBasic;
    {$HINTS OFF}
    SetPoints(Template, pa, @fps);
    {$HINTS ON}

    Distort1(Template, pa);

    DrawEdge(pa, 0);

    with Template do
        for i:= 0 to pred(FillPointsCount) do
            with fps[i] do
                FillLand(x, y, 0, 0);

    DrawEdge(pa, lfBasic);

    MaxHedgehogs:= Template.MaxHedgehogs;
    hasGirders:= Template.hasGirders;
    playHeight:= Template.TemplateHeight;
    playWidth:= Template.TemplateWidth;
    leftX:= ((LAND_WIDTH - playWidth) div 2);
    rightX:= (playWidth + ((LAND_WIDTH - playWidth) div 2)) - 1;
    topY:= LAND_HEIGHT - playHeight;

    // HACK: force to only cavern even if a cavern map is invertable if cTemplateFilter = 4 ?
    if (cTemplateFilter = 4)
    or (Template.canInvert and (getrandom(2) = 0))
    or (not Template.canInvert and Template.isNegative) then
        begin
        hasBorder:= true;
        for y:= 0 to LAND_HEIGHT - 1 do
            for x:= 0 to LAND_WIDTH - 1 do
                if (y < topY) or (x < leftX) or (x > rightX) then
                    Land[y, x]:= 0
                else
                    begin
                    if Land[y, x] = 0 then
                        Land[y, x]:= lfBasic
                    else if Land[y, x] = lfBasic then
                        Land[y, x]:= 0;
                    end;
        end;
end;


end.

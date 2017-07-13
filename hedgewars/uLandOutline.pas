unit uLandOutline;

interface

uses uConsts, SDLh, uFloat;

type TPixAr = record
              Count: Longword;
              ar: array[0..Pred(cMaxEdgePoints)] of TPoint;
              end;

procedure DrawEdge(var pa: TPixAr; value: Word);
procedure FillLand(x, y: LongInt; border, value: Word);
procedure BezierizeEdge(var pa: TPixAr; Delta: hwFloat);
procedure RandomizePoints(var pa: TPixAr);

implementation

uses uLandGraphics, uDebug, uVariables, uLandTemplates, uRandom, uUtils;



var Stack: record
           Count: Longword;
           points: array[0..8192] of record
                                     xl, xr, y, dir: LongInt;
                                     end
           end;


procedure Push(_xl, _xr, _y, _dir: LongInt);
begin
    if checkFails(Stack.Count <= 8192, 'FillLand: stack overflow', true) then exit;
    _y:= _y + _dir;
    if (_y < 0) or (_y >= LAND_HEIGHT) then
        exit;
    with Stack.points[Stack.Count] do
        begin
        xl:= _xl;
        xr:= _xr;
        y:= _y;
        dir:= _dir
        end;
    inc(Stack.Count)
end;

procedure Pop(var _xl, _xr, _y, _dir: LongInt);
begin
    dec(Stack.Count);
    with Stack.points[Stack.Count] do
        begin
        _xl:= xl;
        _xr:= xr;
        _y:= y;
        _dir:= dir
        end
end;

procedure FillLand(x, y: LongInt; border, value: Word);
var xl, xr, dir: LongInt;
begin
    Stack.Count:= 0;
    xl:= x - 1;
    xr:= x;
    Push(xl, xr, y, -1);
    Push(xl, xr, y,  1);
    dir:= 0;
    while Stack.Count > 0 do
        begin
        Pop(xl, xr, y, dir);
        while (xl > 0) and (Land[y, xl] <> border) and (Land[y, xl] <> value) do
            dec(xl);
        while (xr < LAND_WIDTH - 1) and (Land[y, xr] <> border) and (Land[y, xr] <> value) do
            inc(xr);
        while (xl < xr) do
            begin
            while (xl <= xr) and ((Land[y, xl] = border) or (Land[y, xl] = value)) do
                inc(xl);
            x:= xl;
            while (xl <= xr) and (Land[y, xl] <> border) and (Land[y, xl] <> value) do
                begin
                Land[y, xl]:= value;
                inc(xl)
                end;
            if x < xl then
                begin
                Push(x, Pred(xl), y, dir);
                Push(x, Pred(xl), y,-dir);
                end;
            end;
        end;
end;

procedure DrawEdge(var pa: TPixAr; value: Word);
var i: LongInt;
begin
    i:= 0;
    with pa do
        while i < LongInt(Count) - 1 do
            if (ar[i + 1].X = NTPX) then
                inc(i, 2)
            else
                begin
                DrawLine(ar[i].x, ar[i].y, ar[i + 1].x, ar[i + 1].y, value);
                inc(i)
                end
end;


procedure Vector(p1, p2, p3: TPoint; var Vx, Vy: hwFloat);
var d1, d2, d: hwFloat;
begin
    Vx:= int2hwFloat(p1.X - p3.X);
    Vy:= int2hwFloat(p1.Y - p3.Y);

    d2:= Distance(Vx, Vy);

    if d2.QWordValue = 0 then
        begin
        Vx:= _0;
        Vy:= _0
        end
    else
        begin
        d:= DistanceI(p2.X - p1.X, p2.Y - p1.Y);
        d1:= DistanceI(p2.X - p3.X, p2.Y - p3.Y);

        if d1 < d then
            d:= d1;
        if d2 < d then
            d:= d2;

        d2:= d * _1div3 / d2;

        Vx:= Vx * d2;
        Vy:= Vy * d2
        end
end;

procedure AddLoopPoints(var pa, opa: TPixAr; StartI, EndI: LongInt; Delta: hwFloat);
var i, pi, ni: LongInt;
    NVx, NVy, PVx, PVy: hwFloat;
    x1, x2, y1, y2: LongInt;
    tsq, tcb, t, r1, r2, r3, cx1, cx2, cy1, cy2: hwFloat;
    X, Y: LongInt;
begin
    if pa.Count < cMaxEdgePoints - 2 then
        begin
        pi:= EndI;
        i:= StartI;
        ni:= Succ(StartI);
        {$HINTS OFF}
        Vector(opa.ar[pi], opa.ar[i], opa.ar[ni], NVx, NVy);
        {$HINTS ON}
        repeat
            i:= ni;
            inc(pi);
            if pi > EndI then
                pi:= StartI;
            inc(ni);
            if ni > EndI then
                ni:= StartI;
            PVx:= NVx;
            PVy:= NVy;
            Vector(opa.ar[pi], opa.ar[i], opa.ar[ni], NVx, NVy);

            x1:= opa.ar[pi].x;
            y1:= opa.ar[pi].y;
            x2:= opa.ar[i].x;
            y2:= opa.ar[i].y;

            cx1:= int2hwFloat(x1) - PVx;
            cy1:= int2hwFloat(y1) - PVy;
            cx2:= int2hwFloat(x2) + NVx;
            cy2:= int2hwFloat(y2) + NVy;
            t:= _0;
            while (t.Round = 0) and (pa.Count < cMaxEdgePoints-2) do
                begin
                tsq:= t * t;
                tcb:= tsq * t;
                r1:= (_1 - t*3 + tsq*3 - tcb);
                r2:= (     t*3 - tsq*6 + tcb*3);
                r3:= (           tsq*3 - tcb*3);
                X:= hwRound(r1 * x1 + r2 * cx1 + r3 * cx2 + tcb * x2);
                Y:= hwRound(r1 * y1 + r2 * cy1 + r3 * cy2 + tcb * y2);
                t:= t + Delta;
                pa.ar[pa.Count].x:= X;
                pa.ar[pa.Count].y:= Y;
                inc(pa.Count);
                //TryDo(pa.Count <= cMaxEdgePoints, 'Edge points overflow', true)
                end;
        until i = StartI;
        end;

    pa.ar[pa.Count].x:= opa.ar[StartI].X;
    pa.ar[pa.Count].y:= opa.ar[StartI].Y;
    inc(pa.Count)
end;

procedure BezierizeEdge(var pa: TPixAr; Delta: hwFloat);
var i, StartLoop: LongInt;
    opa: TPixAr;
begin
opa:= pa;
pa.Count:= 0;
i:= 0;
StartLoop:= 0;
while (i < LongInt(opa.Count)) and (pa.Count < cMaxEdgePoints-1) do
    if (opa.ar[i + 1].X = NTPX) then
        begin
        AddLoopPoints(pa, opa, StartLoop, i, Delta);
        inc(i, 2);
        StartLoop:= i;
        pa.ar[pa.Count].X:= NTPX;
        pa.ar[pa.Count].Y:= 0;
        inc(pa.Count);
        end else inc(i)
end;


function CheckIntersect(V1, V2, V3, V4: TPoint): boolean;
var c1, c2, dm: LongInt;
begin
    CheckIntersect:= false;
    dm:= (V4.y - V3.y) * (V2.x - V1.x) - (V4.x - V3.x) * (V2.y - V1.y);
    c1:= (V4.x - V3.x) * (V1.y - V3.y) - (V4.y - V3.y) * (V1.x - V3.x);
    if dm = 0 then
        exit;

    CheckIntersect:= true;
    c2:= (V2.x - V3.x) * (V1.y - V3.y) - (V2.y - V3.y) * (V1.x - V3.x);
    if dm > 0 then
    begin
        if (c1 < 0) or (c1 > dm) then
            CheckIntersect:= false
        else if (c2 < 0) or (c2 > dm) then
            CheckIntersect:= false;
    end
    else
    begin
        if (c1 > 0) or (c1 < dm) then
            CheckIntersect:= false
        else if (c2 > 0) or (c2 < dm) then
            CheckIntersect:= false;
    end;

    //AddFileLog('1  (' + inttostr(V1.x) + ',' + inttostr(V1.y) + ')x(' + inttostr(V2.x) + ',' + inttostr(V2.y) + ')');
    //AddFileLog('2  (' + inttostr(V3.x) + ',' + inttostr(V3.y) + ')x(' + inttostr(V4.x) + ',' + inttostr(V4.y) + ')');
end;


function CheckSelfIntersect(var pa: TPixAr; ind: Longword): boolean;
var i: Longword;
begin
    CheckSelfIntersect:= false;
    if (ind <= 0) or (LongInt(ind) >= Pred(pa.Count)) then
        exit;

    CheckSelfIntersect:= true;
    for i:= 1 to pa.Count - 3 do
        if (i <= ind - 1) or (i >= ind + 2) then
        begin
            if (i <> ind - 1) and CheckIntersect(pa.ar[ind], pa.ar[ind - 1], pa.ar[i], pa.ar[i - 1]) then
                exit;
            if (i <> ind + 2) and CheckIntersect(pa.ar[ind], pa.ar[ind + 1], pa.ar[i], pa.ar[i - 1]) then
                exit;
        end;
    CheckSelfIntersect:= false
end;

procedure RandomizePoints(var pa: TPixAr);
const cEdge = 55;
      cMinDist = 8;
var radz: array[0..Pred(cMaxEdgePoints)] of LongInt;
    i, k, dist, px, py: LongInt;
begin
    for i:= 0 to Pred(pa.Count) do
    begin
    radz[i]:= 0;
        with pa.ar[i] do
            if x <> NTPX then
            begin
            radz[i]:= Min(Max(x - cEdge, 0), Max(LAND_WIDTH - cEdge - x, 0));
            radz[i]:= Min(radz[i], Min(Max(y - cEdge, 0), Max(LAND_HEIGHT - cEdge - y, 0)));
            if radz[i] > 0 then
                for k:= 0 to Pred(i) do
                begin
                dist:= Max(abs(x - pa.ar[k].x), abs(y - pa.ar[k].y));
                radz[k]:= Max(0, Min((dist - cMinDist) div 2, radz[k]));
                radz[i]:= Max(0, Min(dist - radz[k] - cMinDist, radz[i]))
                end
            end;
    end;

    for i:= 0 to Pred(pa.Count) do
        with pa.ar[i] do
            if ((x and LAND_WIDTH_MASK) = 0) and ((y and LAND_HEIGHT_MASK) = 0) then
            begin
            px:= x;
            py:= y;
            x:= x + LongInt(GetRandom(7) - 3) * (radz[i] * 5 div 7) div 3;
            y:= y + LongInt(GetRandom(7) - 3) * (radz[i] * 5 div 7) div 3;
            if CheckSelfIntersect(pa, i) then
                begin
                x:= px;
                y:= py
                end;
            end
end;


end.

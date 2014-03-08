{$INCLUDE "options.inc"}

unit uLandGenPerlin;
interface

procedure GenPerlin;

implementation
uses uVariables, uConsts, uRandom, math; // for min()

var fadear: array[byte] of LongInt;
    p: array[0..511] of LongInt;

function fade(t: LongInt) : LongInt; inline;
var t0, t1: LongInt;
begin
    t0:= fadear[t shr 8];
    t1:= fadear[min(255, t shr 8 + 1)];

    fade:= t0 + ((t and 255) * (t1 - t0) shr 8)
end;


function lerp(t, a, b: LongInt) : LongInt; inline;
begin
    lerp:= a + (t * (b - a) shr 12)
end;


function grad(hash, x, y: LongInt) : LongInt;
var h, v, u: LongInt;
begin
    h:= hash and 15;
    if h < 8 then u:= x else u:= y;
    if h < 4 then v:= y else
        if (h = 12) or (h = 14) then v:= x else v:= 0;

    if (h and 1) <> 0 then u:= -u;
    if (h and 2) <> 0 then v:= -v;

    grad:= u + v
end;


function inoise(x, y: LongInt) : LongInt;
const N = $10000;
var xx, yy, u, v, A, AA, AB, B, BA, BB: LongInt;
begin
    xx:= (x shr 16) and 255;
    yy:= (y shr 16) and 255;

    x:= x and $FFFF;
    y:= y and $FFFF;

    u:= fade(x);
    v:= fade(y);

    A:= p[xx    ] + yy; AA:= p[A]; AB:= p[A + 1];
    B:= p[xx + 1] + yy; BA:= p[B]; BB:= p[B + 1];

    inoise:=
            lerp(v, lerp(u, grad(p[AA  ], x   , y  ),
                            grad(p[BA  ], x-N , y  )),
                    lerp(u, grad(p[AB  ], x   , y-N),
                            grad(p[BB  ], x-N , y-N)));
end;

function f(t: double): double;
begin
    f:= t * t * t * (t * (t * 6 - 15) + 10);
end;

procedure inoise_setup();
var i, ii, t: LongInt;
begin
    for i:= 0 to 254 do
        p[i]:= i + 1;
    p[255]:= 0;

    for i:= 0 to 254 do
    begin
        ii:= GetRandom(256 - i) + i;
        t:= p[i];
        p[i]:= p[ii];
        p[ii]:= t
    end;

    for i:= 0 to 255 do
        p[256 + i]:= p[i];

    for i:= 0 to 255 do
        fadear[i]:= trunc($1000 * f(i / 256));
end;

const detail = 120000*3;
    field = 3;
    width = 4096;
    height = 2048;
    bottomPlateHeight = 90;
    bottomPlateMargin = 1200;
    plateFactor = 1;

procedure GenPerlin;
var y, x, dy, di, dj, r: LongInt;
begin
    inoise_setup();

    for y:= 1024 to pred(height) do
    begin
        di:= detail * field * y div height;
        for x:= 0 to pred(width) do
        begin
            dj:= detail * field * x div width;
            r:= (abs(inoise(di, dj))) shr 8 and $ff;
            //r:= r - max(0, abs(x - width div 2) - width * 55 div 128); // fade on edges
            //r:= r - max(0, - abs(x - width div 2) + width * 2 div 100); // split vertically in the middle


            //r:= r + (trunc(1000 - sqrt(sqr(x - (width div 2)) * 4 + sqr(y - height * 5 div 4) * 22))) div 600 * 20; // ellipse
            r:= r + (trunc(2000 - (abs(x - (width div 2)) * 2 + abs(y - height * 5 div 4) * 4))) div 26; // manhattan length ellipse

            if (y > height - bottomPlateHeight) and (x > bottomPlateMargin) and (x + bottomPlateMargin < width) then
            begin
                dy:= (y - height + bottomPlateHeight) * plateFactor;
                r:= r + dy;

                if x < bottomPlateMargin + bottomPlateHeight then
                    r:= r + (x - bottomPlateMargin - bottomPlateHeight) * plateFactor
                else
                if x + bottomPlateMargin + bottomPlateHeight > width then
                    r:= r - (x - width + bottomPlateMargin + bottomPlateHeight) * plateFactor;
            end;
            if r < 0 then Land[y, x]:= 0 else Land[y, x]:= lfBasic;

        end;
    end;

    leftX:= 0;
    rightX:= 4095;
    topY:= 0;
    hasBorder:= false;
end;

end.

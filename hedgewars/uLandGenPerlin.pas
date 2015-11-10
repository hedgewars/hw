{$INCLUDE "options.inc"}

unit uLandGenPerlin;
interface

procedure GenPerlin;

implementation
uses uVariables
    , uConsts
    , uRandom
    , uLandOutline // FillLand
    , uUtils
    ;

var p: array[0..511] of LongInt;

const fadear: array[byte] of LongInt =
(0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 2, 3, 3, 4, 6, 7, 9, 10, 12,
14, 17, 19, 22, 25, 29, 32, 36, 40, 45, 49, 54, 60, 65, 71,
77, 84, 91, 98, 105, 113, 121, 130, 139, 148, 158, 167, 178,
188, 199, 211, 222, 234, 247, 259, 273, 286, 300, 314, 329, 344,
359, 374, 390, 407, 424, 441, 458, 476, 494, 512, 531, 550,
570, 589, 609, 630, 651, 672, 693, 715, 737, 759, 782, 805, 828,
851, 875, 899, 923, 948, 973, 998, 1023, 1049, 1074, 1100, 1127,
1153, 1180, 1207, 1234, 1261, 1289, 1316, 1344, 1372, 1400, 1429,
1457, 1486, 1515, 1543, 1572, 1602, 1631, 1660, 1690, 1719, 1749,
1778, 1808, 1838, 1868, 1898, 1928, 1958, 1988, 2018, 2048, 2077,
2107, 2137, 2167, 2197, 2227, 2257, 2287, 2317, 2346, 2376, 2405,
2435, 2464, 2493, 2523, 2552, 2580, 2609, 2638, 2666, 2695, 2723,
2751, 2779, 2806, 2834, 2861, 2888, 2915, 2942, 2968, 2995, 3021,
3046, 3072, 3097, 3122, 3147, 3172, 3196, 3220, 3244, 3267, 3290,
3313, 3336, 3358, 3380, 3402, 3423, 3444, 3465, 3486, 3506, 3525,
3545, 3564, 3583, 3601, 3619, 3637, 3654, 3672, 3688, 3705, 3721,
3736, 3751, 3766, 3781, 3795, 3809, 3822, 3836, 3848, 3861, 3873,
3884, 3896, 3907, 3917, 3928, 3937, 3947, 3956, 3965, 3974, 3982,
3990, 3997, 4004, 4011, 4018, 4024, 4030, 4035, 4041, 4046, 4050,
4055, 4059, 4063, 4066, 4070, 4073, 4076, 4078, 4081, 4083, 4085,
4086, 4088, 4089, 4091, 4092, 4092, 4093, 4094, 4094, 4095, 4095,
4095, 4095, 4095, 4095, 4095);

function fade(t: LongInt) : LongInt; inline;
var t0, t1: LongInt;
begin
    t0:= fadear[t shr 8];

    if t0 = fadear[255] then
        t1:= t0
    else
        t1:= fadear[t shr 8 + 1];

    fade:= t0 + ((t and 255) * (t1 - t0) shr 8)
end;


function lerp(t, a, b: LongInt) : LongInt; inline;
begin
    lerp:= a + ((Int64(b) - a) * t shr 12)
end;


function grad(hash, x, y: LongInt) : LongInt; inline;
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


function inoise(x, y: LongInt) : LongInt; inline;
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

procedure inoise_setup();
var i, ii, t: Longword;
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
end;

const width = 4096;
      height = 2048;
      minY = 500;

    //bottomPlateHeight = 90;
    //bottomPlateMargin = 1200;
    margin = 200;

procedure GenPerlin;
var y, x, di, dj, r, param1, param2, rCutoff, detail: LongInt;
var df: Int64;
begin
    param1:= cTemplateFilter div 3;
    param2:= cTemplateFilter mod 3;
    rCutoff:= min(max((26-cFeatureSize)*4,15),85);
    detail:= (26-cFeatureSize)*16000+50000; // feature size is a slider from 1-25 at present. flip it for perlin

    df:= detail * (6 - param2 * 2);

    inoise_setup();

    for y:= minY to pred(height) do
    begin
        di:= df * y div height;
        for x:= 0 to pred(width) do
        begin
            dj:= df * x div width;

            r:= ((abs(inoise(di, dj)) + y*4) mod 65536 - (height - y) * 8) div 256;

            //r:= (abs(inoise(di, dj))) shr 8 and $ff;
            if (x < margin) or (x > width - margin) then r:= r - abs(x - width div 2) + width div 2 - margin; // fade on edges

            //r:= r - max(0, - abs(x - width div 2) + width * 2 div 100); // split vertically in the middle
            //r:= r + (trunc(1000 - sqrt(sqr(x - (width div 2)) * 4 + sqr(y - height * 5 div 4) * 22))) div 600 * 20; // ellipse
            //r:= r + 1 - ((abs(x - (width div 2)) + abs(y - height) * 2)) div 32; // manhattan length ellipse

            {
            if (y > height - bottomPlateHeight) and (x > bottomPlateMargin) and (x + bottomPlateMargin < width) then
            begin
                dy:= (y - height + bottomPlateHeight);
                r:= r + dy;

                if x < bottomPlateMargin + bottomPlateHeight then
                    r:= r + (x - bottomPlateMargin - bottomPlateHeight)
                else
                if x + bottomPlateMargin + bottomPlateHeight > width then
                    r:= r - (x - width + bottomPlateMargin + bottomPlateHeight);
            end;
            }

            if r < rCutoff then
                Land[y, x]:= 0
            else if param1 = 0 then
                Land[y, x]:= lfObjMask
            else
                Land[y, x]:= lfBasic
        end;
    end;

    if param1 = 0 then
        begin
        for x:= 0 to width do
            if Land[height - 1, x] = lfObjMask then FillLand(x, height - 1, 0, lfBasic);

        // strip all lfObjMask pixels
        for y:= minY to LAND_HEIGHT - 1 do
            for x:= 0 to LAND_WIDTH - 1 do
                if Land[y, x] = lfObjMask then
                    Land[y, x]:= 0;
        end;

    leftX:= 0;
    rightX:= 4095;
    topY:= 0;
    hasBorder:= false;
end;

end.

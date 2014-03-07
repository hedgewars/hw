{$INCLUDE "options.inc"}

unit uLandGenPerlin;
interface

procedure GenPerlin;

implementation
uses uVariables, uConsts, uRandom, math; // for min()

var fadear: array[byte] of LongInt;
    p: array[0..511] of LongInt;

function fade(t: LongInt) : LongInt;
var t0, t1: LongInt;
begin
    t0:= fadear[t shr 8];
    t1:= fadear[min(255, t shr 8 + 1)];

    fade:= t0 + ((t and 255) * (t1 - t0) shr 8)
end;


function lerp(t, a, b: LongInt) : LongInt;
begin
    lerp:= a + (t * (b - a) shr 12)
end;


function grad(hash, x, y, z: LongInt) : LongInt;
var h, v, u: LongInt;
begin
    h:= hash and 15;
    if h < 8 then u:= x else u:= y;
    if h < 4 then v:= y else
        if (h = 12) or (h = 14) then v:= x else v:= z;

    if odd(h) then u:= -u;
    if odd(h shr 1) then v:= -v;

    grad:= u + v
end;


function inoise(x, y, z: LongInt) : LongInt;
const N = $10000;
var xx, yy, zz, u, v, w, A, AA, AB, B, BA, BB: LongInt;
begin
    xx:= (x shr 16) and 255;
    yy:= (y shr 16) and 255;
    zz:= (z shr 16) and 255;

    x:= x and $FFFF;
    y:= y and $FFFF;
    z:= z and $FFFF;

    u:= fade(x);
    v:= fade(y);
    w:= fade(z);

    A:= p[xx    ] + yy; AA:= p[A] + zz; AB:= p[A + 1] + zz;
    B:= p[xx + 1] + yy; BA:= p[B] + zz; BB:= p[B + 1] + zz;

    inoise:=
 lerp(w, lerp(v, lerp(u, grad(p[AA  ], x   , y   , z   ),
                                     grad(p[BA  ], x-N , y   , z   )),
                             lerp(u, grad(p[AB  ], x   , y-N , z   ),
                                     grad(p[BB  ], x-N , y-N , z   ))),
                     lerp(v, lerp(u, grad(p[AA+1], x   , y   , z-N ),
                                     grad(p[BA+1], x-N , y   , z-N )),
                             lerp(u, grad(p[AB+1], x   , y-N , z-N ),
                                     grad(p[BB+1], x-N , y-N , z-N ))));
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

procedure GenPerlin;
var y, x, di, dj, r: LongInt;
begin
    inoise_setup();

    for y:= 0 to pred(height) do
    begin
        di:= detail * field * y div height;
        for x:= 0 to pred(width) do
        begin
            dj:= detail * field * x div width;
            r:= (abs(inoise(di, dj, detail*field)) + y*4) mod 65536 div 256;
            r:= r - max(0, abs(x - width div 2) - width * 45 div 100);
            //r:= r - max(0, - abs(x - width div 2) + width * 2 div 100);


            r:= r + (trunc(1000 - sqrt(sqr(x - (width div 2)) * 4 + sqr(y - height * 5 div 4) * 22))) div 600 * 20;

            if r < 0 then Land[y, x]:= 0 else Land[y, x]:= lfBasic;

        end;
    end;
end;

end.

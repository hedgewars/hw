{$INCLUDE "options.inc"}

unit uLandGenPerlin;
interface

procedure GenPerlin;

implementation
uses uVariables, uConsts, math; // for min()

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

const permutation: array[byte] of LongInt = ( 151,160,137,91,90,15,
   131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
   190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
   88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
   77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
   102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
   135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
   5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
   223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
   129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
   251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
   49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
   138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
   );

procedure inoise_setup();
var i: LongInt;
begin
    for i:= 0 to 255 do
        begin
        p[256 + i]:= permutation[i];
        p[i]:= permutation[i]
        end;

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

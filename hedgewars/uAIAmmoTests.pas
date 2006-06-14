unit uAIAmmoTests;
interface
uses SDLh;

function TestBazooka(Me, Targ: TPoint; out Time: Longword; out Angle, Power: integer): integer;

implementation
uses uMisc, uAIMisc;
const cMyHHDamageScore = -3000;

function Metric(x1, y1, x2, y2: integer): integer;
begin
Result:= abs(x1 - x2) + abs(y1 - y2)
end;

function TestBazooka(Me, Targ: TPoint; out Time: Longword; out Angle, Power: integer): integer;
var Vx, Vy, r: real;
    rTime: real;
    Score: integer;

    function CheckTrace: integer;
    var x, y, dX, dY: real;
        t: integer;
    begin
    x:= Me.X;
    y:= Me.Y;
    dX:= Vx;
    dY:= -Vy;
    t:= trunc(rTime);
    repeat
      x:= x + dX;
      y:= y + dY;
      dX:= dX + cWindSpeed;
      dY:= dY + cGravity;
      dec(t)
    until TestColl(round(x), round(y), 5) or (t <= 0);
    if NoMyHHNear(round(x), round(y), 110) then
         Result:= - Metric(round(x), round(y), Targ.x, Targ.y) div 16
    else Result:= cMyHHDamageScore;
    end;

begin
Time:= 0;
rTime:= 10;
Result:= Low(integer);
repeat
  rTime:= rTime + 70 + random*200;
  Vx:= - cWindSpeed * rTime / 2 + (Targ.X - Me.X) / rTime;
  Vy:= cGravity * rTime / 2 - (Targ.Y - Me.Y) / rTime;
  r:= sqr(Vx) + sqr(Vy);
  if r <= 1 then
     begin
     Score:= CheckTrace;
     if Result <= Score then
        begin
        r:= sqrt(r);
        Angle:= DxDy2AttackAngle(Vx, Vy);
        Power:= round(r * cMaxPower);
        Result:= Score
        end;
     end
until (rTime >= 5000)
end;

end.

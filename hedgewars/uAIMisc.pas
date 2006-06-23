unit uAIMisc;
interface
uses SDLh, uConsts, uGears;

type TTarget = record
               Point: TPoint;
               Score: integer;
               end;
     TTargets = record
                Count: Longword;
                ar: array[0..cMaxHHIndex*5] of TTarget;
                end;

procedure FillTargets;
procedure FillBonuses(isAfterAttack: boolean);
function RatePlace(Gear: PGear): integer;
function DxDy2AttackAngle(const _dY, _dX: Extended): integer;
function TestColl(x, y, r: integer): boolean;
function RateExplosion(Me: PGear; x, y, r: integer): integer;
function HHGo(Gear: PGear): boolean;

var ThinkingHH: PGear;
    Targets: TTargets;

implementation
uses uTeams, uMisc, uLand, uCollisions;
const KillScore = 200;
      MAXBONUS = 1024;
      
type TBonus = record
              X, Y: integer;
              Radius: integer;
              Score: integer;
              end;
var bonuses: record
             Count: Longword;
             ar: array[0..Pred(MAXBONUS)] of TBonus;
             end;

procedure FillTargets;
var t: PTeam;
    i: Longword;
begin
Targets.Count:= 0;
t:= TeamsList;
while t <> nil do
      begin
      for i:= 0 to cMaxHHIndex do
          if (t.Hedgehogs[i].Gear <> nil)
             and (t.Hedgehogs[i].Gear <> ThinkingHH) then
             begin
             with Targets.ar[Targets.Count], t.Hedgehogs[i] do
                  begin
                  Point.X:= Round(Gear.X);
                  Point.Y:= Round(Gear.Y);
                  if t <> CurrentTeam then Score:=  Gear.Health
                                      else Score:= -Gear.Health
                  end;
             inc(Targets.Count)
             end;
      t:= t.Next
      end
end;

procedure FillBonuses(isAfterAttack: boolean);
var Gear: PGear;
    MyColor: Longword;

    procedure AddBonus(x, y: integer; r: Longword; s: integer);
    begin
    bonuses.ar[bonuses.Count].x:= x;
    bonuses.ar[bonuses.Count].y:= y;
    bonuses.ar[bonuses.Count].Radius:= r;
    bonuses.ar[bonuses.Count].Score:= s;
    inc(bonuses.Count);
    TryDo(bonuses.Count <= MAXBONUS, 'Bonuses overflow', true)
    end;

begin
bonuses.Count:= 0;
MyColor:= PHedgehog(ThinkingHH.Hedgehog).Team.Color;
Gear:= GearsList;
while Gear <> nil do
      begin
      case Gear.Kind of
           gtCase: AddBonus(round(Gear.X), round(Gear.Y), 33, 25);
           gtMine: AddBonus(round(Gear.X), round(Gear.Y), 46, -50);
           gtDynamite: AddBonus(round(Gear.X), round(Gear.Y), 150, -75);
           gtHedgehog: begin
                       if Gear.Damage >= Gear.Health then AddBonus(round(Gear.X), round(Gear.Y), 50, -25);
                       if isAfterAttack
                          and (ThinkingHH.Hedgehog <> Gear.Hedgehog)
                          and (MyColor = PHedgehog(Gear.Hedgehog).Team.Color) then AddBonus(round(Gear.X), round(Gear.Y), 100, -1);
                       end;
           end;
      Gear:= Gear.NextGear
      end
end;

function RatePlace(Gear: PGear): integer;
var i, r: integer;
begin
Result:= 0;
for i:= 0 to Pred(bonuses.Count) do
    with bonuses.ar[i] do
         begin
         r:= round(sqrt(sqr(Gear.X - X) + sqr(Gear.Y - y)));
         if r < Radius then
            inc(Result, Score * (Radius - r))
         end;
end;

function DxDy2AttackAngle(const _dY, _dX: Extended): integer;
const piDIVMaxAngle: Extended = pi/cMaxAngle;
asm
        fld     _dY
        fld     _dX
        fpatan
        fld     piDIVMaxAngle
        fdiv
        sub     esp, 4
        fistp   dword ptr [esp]
        pop     eax
end;

function TestColl(x, y, r: integer): boolean;
begin
Result:=(((x-r) and $FFFFF800) = 0)and(((y-r) and $FFFFFC00) = 0) and (Land[y-r, x-r] <> 0);
if Result then exit;
Result:=(((x-r) and $FFFFF800) = 0)and(((y+r) and $FFFFFC00) = 0) and (Land[y+r, x-r] <> 0);
if Result then exit;
Result:=(((x+r) and $FFFFF800) = 0)and(((y-r) and $FFFFFC00) = 0) and (Land[y-r, x+r] <> 0);
if Result then exit;
Result:=(((x+r) and $FFFFF800) = 0)and(((y+r) and $FFFFFC00) = 0) and (Land[y+r, x+r] <> 0);
end;

function RateExplosion(Me: PGear; x, y, r: integer): integer;
var i, dmg: integer;
begin
Result:= 0;
// add our virtual position
with Targets.ar[Targets.Count] do
     begin
     Point.x:= round(Me.X);
     Point.y:= round(Me.Y);
     Score:= - ThinkingHH.Health
     end;
// rate explosion
for i:= 0 to Targets.Count do
    with Targets.ar[i] do
         begin
         dmg:= r - Round(sqrt(sqr(Point.x - x) + sqr(Point.y - y)));
         if dmg > 0 then
            begin
            dmg:= dmg shr 1;
            if dmg > abs(Score) then
               if Score > 0 then inc(Result, KillScore)
                            else dec(Result, KillScore * 3)
            else
               if Score > 0 then inc(Result, dmg)
                            else dec(Result, dmg * 3)
            end;
         end;
Result:= Result * 1024
end;

function HHGo(Gear: PGear): boolean;
var pX, pY: integer;
begin
Result:= false;
repeat
pX:= round(Gear.X);
pY:= round(Gear.Y);
if pY + cHHRadius >= cWaterLine then exit;
if (Gear.State and gstFalling) <> 0 then
   begin
   Gear.dY:= Gear.dY + cGravity;
   if Gear.dY > 0.35 then exit;
   Gear.Y:= Gear.Y + Gear.dY;
   if TestCollisionYwithGear(Gear, 1) then
      begin
      Gear.State:= Gear.State and not (gstFalling or gstHHJumping);
      Gear.dY:= 0
      end;
   continue
   end;
   {if ((Gear.Message and gm_LJump )<>0) then
      begin
      Gear.Message:= 0;
      if not HHTestCollisionYwithGear(Gear, -1) then
         if not TestCollisionXwithXYShift(Gear, 0, -2, Sign(Gear.dX)) then Gear.Y:= Gear.Y - 2 else
         if not TestCollisionXwithXYShift(Gear, 0, -1, Sign(Gear.dX)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithGear(Gear, Sign(Gear.dX))
         or   HHTestCollisionYwithGear(Gear, -1)) then
         begin
         Gear.dY:= -0.15;
         Gear.dX:= Sign(Gear.dX) * 0.15;
         Gear.State:= Gear.State or gstFalling or gstHHJumping;
         exit
         end;
      end;}
   if (Gear.Message and gm_Left  )<>0 then Gear.dX:= -1.0 else
   if (Gear.Message and gm_Right )<>0 then Gear.dX:=  1.0 else exit;
   if TestCollisionXwithGear(Gear, Sign(Gear.dX)) then
      begin
      if not (TestCollisionXwithXYShift(Gear, 0, -6, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -5, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -4, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -3, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -2, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      if not (TestCollisionXwithXYShift(Gear, 0, -1, Sign(Gear.dX))
         or TestCollisionYwithGear(Gear, -1)) then Gear.Y:= Gear.Y - 1;
      end;

   if not TestCollisionXwithGear(Gear, Sign(Gear.dX)) then Gear.X:= Gear.X + Gear.dX;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
   begin
   Gear.Y:= Gear.Y + 1;
   if not TestCollisionYwithGear(Gear, 1) then
      begin
      Gear.Y:= Gear.Y - 6;
      Gear.dY:= 0;
      Gear.dX:= 0.0000001 * Sign(Gear.dX);
      Gear.State:= Gear.State or gstFalling
      end
   end
   end
   end
   end
   end
   end;
if (pX <> round(Gear.X))and ((Gear.State and gstFalling) = 0) then
   begin
   Result:= true;
   exit
   end;
until (pX = round(Gear.X)) and (pY = round(Gear.Y)) and ((Gear.State and gstFalling) = 0);
end;

end.

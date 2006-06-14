unit uAIMisc;
interface
uses SDLh, uConsts;

type TTarget = record
               Point: TPoint;
               Score: integer;
               end;
     TTargets = record
                Count: Longword;
                ar: array[0..cMaxHHIndex*5] of TTarget;
                end;

procedure FillTargets(var Targets: TTargets);
function DxDy2AttackAngle(const _dY, _dX: Extended): integer;
function TestColl(x, y, r: integer): boolean;
function NoMyHHNear(x, y, r: integer): boolean;

implementation
uses uTeams, uMisc, uLand;

procedure FillTargets(var Targets: TTargets);
var t: PTeam;
    i: Longword;
begin
Targets.Count:= 0;
t:= TeamsList;
while t <> nil do
      begin
      if t <> CurrentTeam then
         for i:= 0 to cMaxHHIndex do
             if t.Hedgehogs[i].Gear <> nil then
                begin
                with Targets.ar[Targets.Count], t.Hedgehogs[i] do
                     begin
                     Point.X:= Round(Gear.X);
                     Point.Y:= Round(Gear.Y);
                     Score:= 100 - Gear.Health
                     end;
                inc(Targets.Count)
                end;
      t:= t.Next
      end
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

function NoMyHHNear(x, y, r: integer): boolean;
var i: integer;
begin
i:= 0;
r:= sqr(r);
Result:= true;
repeat
  with CurrentTeam.Hedgehogs[i] do
       if Gear <> nil then
          if sqr(Gear.X - x) + sqr(Gear.Y - y) <= r then
             begin
             Result:= false;
             exit
             end;
inc(i)
until i > cMaxHHIndex
end;

end.

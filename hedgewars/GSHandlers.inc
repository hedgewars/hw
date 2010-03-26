(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2009 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *)

procedure makeHogsWorry(x, y: hwFloat; r: LongInt);
var gi: PGear;
     d: LongInt;
begin
    gi:= GearsList;
    while gi <> nil do
        begin
        d:= r - hwRound(Distance(gi^.X - x, gi^.Y - y));
        if (d > 1) and (gi^.Kind = gtHedgehog) and not gi^.Invulnerable and (GetRandom(2) = 0) then
            begin
            if (CurrentHedgehog^.Gear = gi) then
                PlaySound(sndOops, PHedgehog(gi^.Hedgehog)^.Team^.voicepack)
            else
                begin
                if (gi^.State and gstMoving) = 0 then
                    gi^.State:= gi^.State or gstLoser;
                if d > r div 2 then
                    PlaySound(sndNooo, PHedgehog(gi^.Hedgehog)^.Team^.voicepack)
                else
                    PlaySound(sndUhOh, PHedgehog(gi^.Hedgehog)^.Team^.voicepack);
                end;
            end;
        gi:= gi^.NextGear
        end;
end;
////////////////////////////////////////////////////////////////////////////////
procedure doStepDrowningGear(Gear: PGear); forward;

function CheckGearDrowning(Gear: PGear): boolean;
var skipSpeed, skipAngle, skipDecay: hwFloat;
    i, maxDrops: LongInt;
    particle: PVisualGear;
begin
// probably needs tweaking. might need to be in a case statement based upon gear type
//(not Gear^.dY.isNegative) and  this should not be necessary
if cWaterLine < hwRound(Gear^.Y) + Gear^.Radius then
    begin
    skipSpeed:= _0_25;  // was 0.36 - couldn't manage baseball bat. Tiy's build is 0.36...
    skipAngle:= _1 + _0_9;  // these should perhaps also be constants, once work out what proper values are
    skipDecay:= _0_87;  // this could perhaps be a tiny bit higher.
    if  (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) > skipSpeed) and
        (hwAbs(Gear^.dX) > skipAngle * hwAbs(Gear^.dY)) then
       begin
       Gear^.dY.isNegative:= true;
       Gear^.dY:= Gear^.dY * skipDecay;
       Gear^.dX:= Gear^.dX * skipDecay;
       CheckGearDrowning:= false
       end
    else
        begin
        CheckGearDrowning:= true;
        Gear^.State:= gstDrowning;
        Gear^.RenderTimer:= false;
        if (Gear^.Kind <> gtSniperRifleShot) and (Gear^.Kind <> gtShotgunShot) and (Gear^.Kind <> gtDEagleShot) then
          Gear^.doStep:= @doStepDrowningGear;
        if Gear^.Kind = gtHedgehog then
            begin
            Gear^.State:= Gear^.State and (not gstHHDriven);
            AddCaption(Format(GetEventString(eidDrowned), PHedgehog(Gear^.Hedgehog)^.Name), cWhiteColor, capgrpMessage);
            end
        end;
    PlaySound(sndSplash);
    
    if not cReducedQuality then 
        begin
        AddVisualGear(hwRound(Gear^.X), cWaterLine, vgtSplash);
       
        maxDrops := (Gear^.Radius div 2) + hwRound(Gear^.dX * Gear^.Radius * 2) + hwRound(Gear^.dY * Gear^.Radius * 2);
        for i:= max(maxDrops div 3, min(32, Random(maxDrops))) downto 0 do 
            begin
            particle := AddVisualGear(hwRound(Gear^.X) - 3 + Random(6), cWaterLine, vgtDroplet);
            if particle <> nil then
                begin
                particle^.dX := particle^.dX - (Gear^.dX / 10);
                particle^.dY := particle^.dY - (Gear^.dY / 5)
                end
            end
        end;
    end
    else
    CheckGearDrowning:= false
end;

procedure CheckCollision(Gear: PGear);
begin
if TestCollisionXwithGear(Gear, hwSign(Gear^.X)) or TestCollisionYwithGear(Gear, hwSign(Gear^.Y))
    then Gear^.State:= Gear^.State or      gstCollision
    else Gear^.State:= Gear^.State and not gstCollision
end;

procedure CheckHHDamage(Gear: PGear);
var 
    dmg: Longword;
    i: LongInt;
    particle: PVisualGear;
begin
if _0_4 < Gear^.dY then
    begin
    dmg:= ModifyDamage(1 + hwRound((hwAbs(Gear^.dY) - _0_4) * 70), Gear);
    if dmg < 1 then exit;

    for i:= min(12, (3 + dmg div 10)) downto 0 do begin
        particle := AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust);
        if particle <> nil then particle^.dX := particle^.dX + (Gear^.dX / 5);
        end;

    if(Gear^.Invulnerable) then exit;

    if _0_6 < Gear^.dY then
        PlaySound(sndOw4, PHedgehog(Gear^.Hedgehog)^.Team^.voicepack)
    else
        PlaySound(sndOw1, PHedgehog(Gear^.Hedgehog)^.Team^.voicepack);

    ApplyDamage(Gear, dmg);
    end
end;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
procedure CalcRotationDirAngle(Gear: PGear);
var dAngle: real;
begin
dAngle:= (hwAbs(Gear^.dX) + hwAbs(Gear^.dY)).QWordValue / $80000000;
if not Gear^.dX.isNegative then
    Gear^.DirAngle:= Gear^.DirAngle + dAngle
else
    Gear^.DirAngle:= Gear^.DirAngle - dAngle;

if Gear^.DirAngle < 0 then Gear^.DirAngle:= Gear^.DirAngle + 360
else if 360 < Gear^.DirAngle then Gear^.DirAngle:= Gear^.DirAngle - 360
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDrowningGear(Gear: PGear);
begin
AllInactive:= false;
Gear^.Y:= Gear^.Y + cDrownSpeed;
Gear^.X:= Gear^.X + Gear^.dX * cDrownSpeed;
if (cWaterOpacity > $FE) or (hwRound(Gear^.Y) > Gear^.Radius + cWaterLine + cVisibleWater) then DeleteGear(Gear);
// Create some bubbles (0.5% might be better but causes too few bubbles sometimes)
if (cWaterOpacity < $FF) and ((GameTicks and $1F) = 0) then
    if (Gear^.Kind = gtHedgehog) and (Random(4) = 0) then
        AddVisualGear(hwRound(Gear^.X) - Gear^.Radius, hwRound(Gear^.Y) - Gear^.Radius, vgtBubble)
    else if Random(12) = 0 then
        AddVisualGear(hwRound(Gear^.X) - Gear^.Radius, hwRound(Gear^.Y) - Gear^.Radius, vgtBubble)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFallingGear(Gear: PGear);
var isFalling: boolean;
    //tmp: QWord;
    tdX, tdY: hwFloat;
    collV, collH: LongInt;
begin
Gear^.State:= Gear^.State and not gstCollision;
collV:= 0; 
collH:= 0;
tdX:= Gear^.dX;
tdY:= Gear^.dY;

if Gear^.dY.isNegative then
    begin
    isFalling:= true;
    if TestCollisionYwithGear(Gear, -1) then
        begin
        collV:= -1;
        Gear^.dX:=   Gear^.dX * Gear^.Friction;
        Gear^.dY:= - Gear^.dY * Gear^.Elasticity;
        Gear^.State:= Gear^.State or gstCollision
        end
    else if (Gear^.AdvBounce=1) and TestCollisionYwithGear(Gear, 1) then collV:= 1;
    end 
else if TestCollisionYwithGear(Gear, 1) then
    begin
    collV:= 1;
    isFalling:= false;
    Gear^.dX:=   Gear^.dX * Gear^.Friction;
    Gear^.dY:= - Gear^.dY * Gear^.Elasticity;
    Gear^.State:= Gear^.State or gstCollision
    end
else
    begin
    isFalling:= true;
    if (Gear^.AdvBounce=1) and not Gear^.dY.isNegative and TestCollisionYwithGear(Gear, -1) then collV:= -1;
    end;


if TestCollisionXwithGear(Gear, hwSign(Gear^.dX)) then
    begin
    collH:= hwSign(Gear^.dX);
    Gear^.dX:= - Gear^.dX * Gear^.Elasticity;
    Gear^.dY:=   Gear^.dY * Gear^.Elasticity;
    Gear^.State:= Gear^.State or gstCollision
    end 
else if (Gear^.AdvBounce=1) and TestCollisionXwithGear(Gear, -hwSign(Gear^.dX)) then collH:= -hwSign(Gear^.dX);

//if Gear^.AdvBounce and (collV <>0) and (collH <> 0) and (hwSqr(tdX) + hwSqr(tdY) > _0_08) then
if (Gear^.AdvBounce=1) and (collV <>0) and (collH <> 0) and ((tdX.QWordValue + tdY.QWordValue) > _0_2.QWordValue) then
    begin
    Gear^.dX:= tdY*Gear^.Elasticity*Gear^.Friction;
    Gear^.dY:= tdX*Gear^.Elasticity;//*Gear^.Friction;
    Gear^.dY.isNegative:= not tdY.isNegative;
    isFalling:= false;
    Gear^.AdvBounce:= 10;
    end;

if Gear^.AdvBounce > 1 then dec(Gear^.AdvBounce);

if isFalling then Gear^.dY:= Gear^.dY + cGravity;

Gear^.X:= Gear^.X + Gear^.dX;
Gear^.Y:= Gear^.Y + Gear^.dY;
CheckGearDrowning(Gear);
//if (hwSqr(Gear^.dX) + hwSqr(Gear^.dY) < _0_0002) and
if ((Gear^.dX.QWordValue + Gear^.dY.QWordValue) < _0_02.QWordValue) and
    (not isFalling) then
    Gear^.State:= Gear^.State and not gstMoving
else
    Gear^.State:= Gear^.State or      gstMoving
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBomb(Gear: PGear);
var i: LongInt;
    dX, dY: hwFloat;
    Fire: PGear;
begin
AllInactive:= false;

doStepFallingGear(Gear);

dec(Gear^.Timer);
if Gear^.Timer = 1000 then // might need adjustments
    case Gear^.Kind of
        gtAmmo_Bomb: makeHogsWorry(Gear^.X, Gear^.Y, 50);
        gtClusterBomb: makeHogsWorry(Gear^.X, Gear^.Y, 20);
        gtWatermelon: makeHogsWorry(Gear^.X, Gear^.Y, 75);
        gtHellishBomb: makeHogsWorry(Gear^.X, Gear^.Y, 90);
    end;

if (Gear^.Kind = gtBall) and ((Gear^.State and gstTmpFlag) <> 0) then
    begin
    CheckCollision(Gear);
    if (Gear^.State and gstCollision) <> 0 then
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 20, EXPLDontDraw or EXPLNoGfx);
    end;

if Gear^.Timer = 0 then
    begin
    case Gear^.Kind of
        gtAmmo_Bomb: doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
             gtBall: doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 40, EXPLAutoSound);
        gtClusterBomb: begin
                doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 20, EXPLAutoSound);
                for i:= 0 to 4 do
                    begin
                    dX:= rndSign(GetRandom * _0_1);
                    dY:= (GetRandom - _3) * _0_08;
                    AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtCluster, 0, dX, dY, 25);
                    end
                end;
        gtWatermelon: begin
                doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 75, EXPLAutoSound);
                for i:= 0 to 5 do
                    begin
                    dX:= rndSign(GetRandom * _0_1);
                    dY:= (GetRandom - _1_5) * _0_3;
                    AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtMelonPiece, 0, dX, dY, 75)^.DirAngle:= i * 60;
                    end
                end;
        gtHellishBomb: begin
                doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 90, EXPLAutoSound);
                for i:= 0 to 127 do
                    begin
                    dX:= AngleCos(i * 16) * _0_5 * (GetRandom + _1);
                    dY:= AngleSin(i * 16) * _0_5 * (GetRandom + _1);
                    Fire:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, dX, dY, 0);
                    if i mod 2 = 0 then Fire^.State:= Fire^.State or gsttmpFlag;
                    Fire:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, dX, -dY, 0);
                    if i mod 2 <> 0 then Fire^.State:= Fire^.State or gsttmpFlag;
                    end
                end;
        end;
    DeleteGear(Gear);
    exit
    end;

CalcRotationDirAngle(Gear);

if Gear^.Kind = gtHellishBomb then
    begin
    if Gear^.Timer = 3000 then PlaySound(sndHellish);

    if (GameTicks and $3F) = 0 then
        if (Gear^.State and gstCollision) = 0 then
            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtEvilTrace, 0, _0, _0, 0);
    end;

if (Gear^.State and (gstCollision or gstMoving)) = (gstCollision or gstMoving) then
    if (hwAbs(Gear^.dX) > _0_1) or
       (hwAbs(Gear^.dY) > _0_1) then
        PlaySound(sndGrenadeImpact)
end;
////////////////////////////////////////////////////////////////////////////////
procedure doStepMolotov(Gear: PGear);
var i: LongInt;
    dX, dY: hwFloat;
    Fire: PGear;
begin
    AllInactive:= false;
    
    doStepFallingGear(Gear);
    CalcRotationDirAngle(Gear);

    if (Gear^.State and gstCollision) <> 0 then begin
        PlaySound(sndMolotov);
        //doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 5, EXPLAutoSound);
        for i:= 0 to 20 do begin
                dX:= AngleCos(i * 2) * ((_0_1*(i div 5))) * (GetRandom + _1);
                dY:= AngleSin(i * 8) * _0_5 * (GetRandom + _1);
                Fire:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, dX, dY, 0);
                Fire^.State:= Fire^.State or gsttmpFlag;
                Fire:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, dX, -dY, 0);
                Fire^.State:= Fire^.State or gsttmpFlag;
                Fire:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, -dX, dY, 0);
                Fire^.State:= Fire^.State or gsttmpFlag;
                Fire:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, -dX, -dY, 0);
                Fire^.State:= Fire^.State or gsttmpFlag;
        end;
        DeleteGear(Gear);
        exit
    end;
end;

procedure doStepWatermelon(Gear: PGear);
begin
AllInactive:= false;
Gear^.doStep:= @doStepBomb
end;

procedure doStepCluster(Gear: PGear);
begin
AllInactive:= false;
doStepFallingGear(Gear);
if (Gear^.State and gstCollision) <> 0 then
    begin
    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), Gear^.Timer, EXPLAutoSound);
    DeleteGear(Gear);
    exit
    end;

if (Gear^.Kind = gtMelonPiece) or (Gear^.Kind = gtBall) then
    CalcRotationDirAngle(Gear)
else
    if (GameTicks and $1F) = 0 then
        AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepGrenade(Gear: PGear);
begin
AllInactive:= false;
Gear^.dX:= Gear^.dX + cWindSpeed;
doStepFallingGear(Gear);
if (Gear^.State and gstCollision) <> 0 then
    begin
    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
    DeleteGear(Gear);
    exit
    end;
if (GameTicks and $3F) = 0 then
    AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHealthTagWork(Gear: PGear);
begin
if Gear^.Kind = gtHealthTag then
    AllInactive:= false;

dec(Gear^.Timer);
Gear^.Y:= Gear^.Y + Gear^.dY;

if Gear^.Timer = 0 then
    begin
    if (Gear^.Kind = gtHealthTag) and (PHedgehog(Gear^.Hedgehog)^.Gear <> nil) then
        PHedgehog(Gear^.Hedgehog)^.Gear^.Active:= true; // to let current hh die
    DeleteGear(Gear)
    end
end;

procedure doStepHealthTagWorkUnderWater(Gear: PGear);
begin
AllInactive:= false;

Gear^.Y:= Gear^.Y - _0_08;

if hwRound(Gear^.Y) < cWaterLine + 10 then
    DeleteGear(Gear)
end;

procedure doStepHealthTag(Gear: PGear);
var s: shortstring;
begin
AllInactive:= false;
Gear^.dY:= -_0_08;

str(Gear^.State, s);
Gear^.Tex:= RenderStringTex(s, PHedgehog(Gear^.Hedgehog)^.Team^.Clan^.Color, fnt16);

if hwRound(Gear^.Y) < cWaterLine then
    Gear^.doStep:= @doStepHealthTagWork
else
    Gear^.doStep:= @doStepHealthTagWorkUnderWater;

Gear^.Y:= Gear^.Y - int2hwFloat(Gear^.Tex^.h)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepGrave(Gear: PGear);
begin
AllInactive:= false;
if Gear^.dY.isNegative then
   if TestCollisionY(Gear, -1) then Gear^.dY:= _0;

if not Gear^.dY.isNegative then
   if TestCollisionY(Gear, 1) then
      begin
      Gear^.dY:= - Gear^.dY * Gear^.Elasticity;
      if Gear^.dY > - _1div1024 then
         begin
         Gear^.Active:= false;
         exit
         end else if Gear^.dY < - _0_03 then PlaySound(sndGraveImpact)
      end;

Gear^.Y:= Gear^.Y + Gear^.dY;
CheckGearDrowning(Gear);
Gear^.dY:= Gear^.dY + cGravity
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepUFOWork(Gear: PGear);
var t: hwFloat;
    y: LongInt;
begin
AllInactive:= false;
t:= Distance(Gear^.dX, Gear^.dY);
Gear^.dX:= Gear^.Elasticity * (Gear^.dX + _0_000004 * (TargetPoint.X - hwRound(Gear^.X)));
Gear^.dY:= Gear^.Elasticity * (Gear^.dY + _0_000004 * (TargetPoint.Y - hwRound(Gear^.Y)));
t:= t / Distance(Gear^.dX, Gear^.dY);
Gear^.dX:= Gear^.dX * t;
Gear^.dY:= Gear^.dY * t;
Gear^.X:= Gear^.X + Gear^.dX;
Gear^.Y:= Gear^.Y + Gear^.dY;

if (GameTicks and $3F) = 0 then
   begin
   y:= hwRound(Gear^.Y);
   if y + Gear^.Radius < cWaterLine then
      AddGear(hwRound(Gear^.X), y, gtSmokeTrace, 0, _0, _0, 0);
   end;

CheckCollision(Gear);
dec(Gear^.Timer);
if ((Gear^.State and gstCollision) <> 0) or (Gear^.Timer = 0) then
   begin
   StopSound(Gear^.SoundChannel);
   doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
   DeleteGear(Gear);
   end;
end;

procedure doStepUFO(Gear: PGear);
begin
AllInactive:= false;
Gear^.X:= Gear^.X + Gear^.dX;
Gear^.Y:= Gear^.Y + Gear^.dY;
Gear^.dY:= Gear^.dY + cGravity;
CheckCollision(Gear);
if (Gear^.State and gstCollision) <> 0 then
   begin
   doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
   DeleteGear(Gear);
   exit
   end;
dec(Gear^.Timer);
if Gear^.Timer = 0 then
   begin
   Gear^.SoundChannel:= LoopSound(sndUFO);
   Gear^.Timer:= 5000;
   Gear^.doStep:= @doStepUFOWork
   end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShotIdle(Gear: PGear);
begin
AllInactive:= false;
inc(Gear^.Timer);
if Gear^.Timer > 75 then
    begin
    DeleteGear(Gear);
    AfterAttack
    end
end;

procedure doStepShotgunShot(Gear: PGear);
var i: LongWord;
    shell: PVisualGear;
begin
AllInactive:= false;

if ((Gear^.State and gstAnimation) = 0) then
    begin
    dec(Gear^.Timer);
    if Gear^.Timer = 0 then
        begin
        PlaySound(sndShotgunFire);
        shell:= AddVisualGear(hwRound(Gear^.x), hwRound(Gear^.y), vgtShell);
        if shell <> nil then
        begin 
           shell^.dX:= gear^.dX / -4;
           shell^.dY:= gear^.dY / -4;
           shell^.Frame:= 0
        end;
        Gear^.State:= Gear^.State or gstAnimation
        end;
    exit
    end
    else inc(Gear^.Timer);

i:= 200;
repeat
Gear^.X:= Gear^.X + Gear^.dX;
Gear^.Y:= Gear^.Y + Gear^.dY;
CheckCollision(Gear);
if (Gear^.State and gstCollision) <> 0 then
    begin
    Gear^.X:= Gear^.X + Gear^.dX * 8;
    Gear^.Y:= Gear^.Y + Gear^.dY * 8;
    ShotgunShot(Gear);
    Gear^.doStep:= @doStepShotIdle;
    exit
    end;

CheckGearDrowning(Gear);
if (Gear^.State and gstDrowning) <> 0 then
    begin
    Gear^.doStep:= @doStepShotIdle;
    exit
    end;
dec(i)
until i = 0;
if (hwRound(Gear^.X) and LAND_WIDTH_MASK <> 0) or (hwRound(Gear^.Y) and LAND_HEIGHT_MASK <> 0) then
    Gear^.doStep:= @doStepShotIdle
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBulletWork(Gear: PGear);
var i, x, y: LongWord;
    oX, oY: hwFloat;
begin
AllInactive:= false;
inc(Gear^.Timer);
i:= 80;
oX:= Gear^.X;
oY:= Gear^.Y;
repeat
  Gear^.X:= Gear^.X + Gear^.dX;
  Gear^.Y:= Gear^.Y + Gear^.dY;
  x:= hwRound(Gear^.X);
  y:= hwRound(Gear^.Y);
  if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0)
     and (Land[y, x] <> 0) then inc(Gear^.Damage);
  if Gear^.Damage > 5 then
      if Gear^.Ammo^.AmmoType = amDEagle then
          AmmoShove(Gear, 7, 20)
      else
          AmmoShove(Gear, Gear^.Timer, 20);
  CheckGearDrowning(Gear);
  dec(i)
until (i = 0) or (Gear^.Damage > Gear^.Health) or ((Gear^.State and gstDrowning) <> 0);
if Gear^.Damage > 0 then
   begin
   DrawTunnel(oX, oY, Gear^.dX, Gear^.dY, 82 - i, 1);
   dec(Gear^.Health, Gear^.Damage);
   Gear^.Damage:= 0
   end;
if ((Gear^.State and gstDrowning) <> 0) and (Gear^.Damage < Gear^.Health) and (cWaterOpacity < $FF) then
    begin
    for i:=(Gear^.Health - Gear^.Damage) * 4 downto 0 do
        begin
        if Random(6) = 0 then
            AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtBubble);
        Gear^.X:= Gear^.X + Gear^.dX;
        Gear^.Y:= Gear^.Y + Gear^.dY;
        end;
    end;

if (Gear^.Health <= 0)
    or (hwRound(Gear^.X) and LAND_WIDTH_MASK <> 0)
    or (hwRound(Gear^.Y) and LAND_HEIGHT_MASK <> 0) then
    begin
    if (Gear^.Kind = gtSniperRifleShot) and ((GameFlags and gfLaserSight) = 0) then cLaserSighting:= false;
    if (Gear^.Ammo^.NumPerTurn <= CurrentHedgehog^.MultiShootAttacks) and
       ((GameFlags and gfArtillery) = 0) then cArtillery:= false;
    Gear^.doStep:= @doStepShotIdle
    end;
end;

procedure doStepDEagleShot(Gear: PGear);
begin
PlaySound(sndGun);
Gear^.doStep:= @doStepBulletWork
end;

procedure doStepSniperRifleShot(Gear: PGear);
var HHGear: PGear;
    shell: PVisualGear;
begin
cArtillery:= true;
HHGear:=PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.State:= HHGear^.State or gstNotKickable;
HedgehogChAngle(HHGear);
if not cLaserSighting then // game does not have default laser sight. turn it on and give them a chance to aim
    begin
    cLaserSighting:= true;
    HHGear^.Message:= 0;
    if(HHGear^.Angle - 32 >= 0) then dec(HHGear^.Angle,32)
    end;

if (HHGear^.Message and gm_Attack) <> 0 then
    begin
    shell:= AddVisualGear(hwRound(Gear^.x), hwRound(Gear^.y), vgtShell);
    if shell <> nil then
       begin
       shell^.dX:= gear^.dX / -2;
       shell^.dY:= gear^.dY / -2;
       shell^.Frame:= 1
       end;
    Gear^.State:= Gear^.State or gstAnimation;
    Gear^.dX:= SignAs(AngleSin(HHGear^.Angle), HHGear^.dX) * _0_5;
    Gear^.dY:= -AngleCos(HHGear^.Angle) * _0_5;
    PlaySound(sndGun);
    Gear^.doStep:= @doStepBulletWork;
    end
else
    if (GameTicks mod 32) = 0 then
        if (GameTicks mod 4096) < 2048 then
            begin
            if(HHGear^.Angle + 1 <= cMaxAngle) then inc(HHGear^.Angle)
            end
        else
            if(HHGear^.Angle - 1 >= 0) then dec(HHGear^.Angle);

if (TurnTimeLeft > 0) then
    dec(TurnTimeLeft)
else
    begin
    DeleteGear(Gear);
    AfterAttack
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepActionTimer(Gear: PGear);
begin
dec(Gear^.Timer);
case Gear^.Kind of
    gtATStartGame: begin
                   AllInactive:= false;
                   if Gear^.Timer = 0 then
                      AddCaption(trmsg[sidStartFight], cWhiteColor, capgrpGameState);
                   end;
 gtATSmoothWindCh: begin
                   if Gear^.Timer = 0 then
                      begin
                      if WindBarWidth < Gear^.Tag then inc(WindBarWidth)
                         else if WindBarWidth > Gear^.Tag then dec(WindBarWidth);
                      if WindBarWidth <> Gear^.Tag then Gear^.Timer:= 10;
                      end
                   end;
   gtATFinishGame: begin
                   AllInactive:= false;
                   if Gear^.Timer = 0 then
                      begin
                      SendIPC('N');
                      SendIPC('q');
                      GameState:= gsExit
                      end
                   end;
     end;
if Gear^.Timer = 0 then DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepPickHammerWork(Gear: PGear);
var i, ei: LongInt;
    HHGear: PGear;
begin
AllInactive:= false;
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
dec(Gear^.Timer);
if (Gear^.Timer = 0)or((Gear^.Message and gm_Destroy) <> 0)or((HHGear^.State and gstHHDriven) = 0) then
    begin
    StopSound(Gear^.SoundChannel);
    DeleteGear(Gear);
    AfterAttack;
    exit
    end;

if (Gear^.Timer mod 33) = 0 then
    begin
    HHGear^.State:= HHGear^.State or gstNoDamage;
    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y) + 7, 6, EXPLDontDraw);
    HHGear^.State:= HHGear^.State and not gstNoDamage
    end;

if (Gear^.Timer mod 47) = 0 then
    begin
    i:= hwRound(Gear^.X) - Gear^.Radius - LongInt(GetRandom(2));
    ei:= hwRound(Gear^.X) + Gear^.Radius + LongInt(GetRandom(2));
    while i <= ei do
        begin
        DrawExplosion(i, hwRound(Gear^.Y) + 3, 3);
        inc(i, 1)
        end;

    if CheckLandValue(hwRound(Gear^.X + Gear^.dX + SignAs(_6,Gear^.dX)), hwRound(Gear^.Y + _1_9), COLOR_INDESTRUCTIBLE) then
        begin
        Gear^.X:= Gear^.X + Gear^.dX;
        Gear^.Y:= Gear^.Y + _1_9;
        end;
    SetAllHHToActive;
    end;
if TestCollisionYwithGear(Gear, 1) then
    begin
    Gear^.dY:= _0;
    SetLittle(HHGear^.dX);
    HHGear^.dY:= _0;
    end else
    begin
    Gear^.dY:= Gear^.dY + cGravity;
    Gear^.Y:= Gear^.Y + Gear^.dY;
    if hwRound(Gear^.Y) > cWaterLine then Gear^.Timer:= 1
    end;

Gear^.X:= Gear^.X + HHGear^.dX;
HHGear^.X:= Gear^.X;
HHGear^.Y:= Gear^.Y - int2hwFloat(cHHRadius);

if (Gear^.Message and gm_Attack) <> 0 then
   if (Gear^.State and gsttmpFlag) <> 0 then Gear^.Timer:= 1 else else
   if (Gear^.State and gsttmpFlag) = 0 then Gear^.State:= Gear^.State or gsttmpFlag;
if ((Gear^.Message and gm_Left) <> 0) then Gear^.dX:= - _0_3 else
   if ((Gear^.Message and gm_Right) <> 0) then Gear^.dX:= _0_3
                                          else Gear^.dX:= _0;
end;

procedure doStepPickHammer(Gear: PGear);
var i, y: LongInt;
    ar: TRangeArray;
    HHGear: PGear;
begin
i:= 0;
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;

y:= hwRound(Gear^.Y) - cHHRadius * 2;
while y < hwRound(Gear^.Y) do
   begin
   ar[i].Left := hwRound(Gear^.X) - Gear^.Radius - LongInt(GetRandom(2));
   ar[i].Right:= hwRound(Gear^.X) + Gear^.Radius + LongInt(GetRandom(2));
   inc(y, 2);
   inc(i)
   end;

DrawHLinesExplosions(@ar, 3, hwRound(Gear^.Y) - cHHRadius * 2, 2, Pred(i));
Gear^.dY:= HHGear^.dY;
DeleteCI(HHGear);

Gear^.SoundChannel:= LoopSound(sndPickhammer);
doStepPickHammerWork(Gear);
Gear^.doStep:= @doStepPickHammerWork
end;

////////////////////////////////////////////////////////////////////////////////
var BTPrevAngle, BTSteps: LongInt;

procedure doStepBlowTorchWork(Gear: PGear);
var HHGear: PGear;
    b: boolean;
    prevX: LongInt;
begin
AllInactive:= false;
dec(Gear^.Timer);
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;

HedgehogChAngle(HHGear);

b:= false;

if abs(LongInt(HHGear^.Angle) - BTPrevAngle) > 7  then
    begin
    Gear^.dX:= SignAs(AngleSin(HHGear^.Angle) * _0_5, HHGear^.dX);
    Gear^.dY:= AngleCos(HHGear^.Angle) * ( - _0_5);
    BTPrevAngle:= HHGear^.Angle;
    b:= true
    end;

if ((HHGear^.State and gstMoving) <> 0) then
    begin
    doStepHedgehogMoving(HHGear);
    if (HHGear^.State and gstHHDriven) = 0 then Gear^.Timer:= 0
    end;

if Gear^.Timer mod cHHStepTicks = 0 then
    begin
    b:= true;
    if Gear^.dX.isNegative then
        HHGear^.Message:= (HHGear^.Message and (gm_Attack or gm_Up or gm_Down)) or gm_Left
    else
        HHGear^.Message:= (HHGear^.Message and (gm_Attack or gm_Up or gm_Down)) or gm_Right;

    if ((HHGear^.State and gstMoving) = 0) then
        begin
        HHGear^.State:= HHGear^.State and not gstAttacking;
        prevX:= hwRound(HHGear^.X);

// why the call to HedgehogStep then a further increment of X?
        if (prevX = hwRound(HHGear^.X)) and
           CheckLandValue(hwRound(HHGear^.X + SignAs(_6, HHGear^.dX)), hwRound(HHGear^.Y), COLOR_INDESTRUCTIBLE) then HedgehogStep(HHGear);

        if (prevX = hwRound(HHGear^.X)) and
           CheckLandValue(hwRound(HHGear^.X + SignAs(_6, HHGear^.dX)), hwRound(HHGear^.Y), COLOR_INDESTRUCTIBLE) then HHGear^.X:= HHGear^.X + SignAs(_1, HHGear^.dX);
        HHGear^.State:= HHGear^.State or gstAttacking
        end;

    inc(BTSteps);
    if BTSteps = 7 then
        begin
        BTSteps:= 0;
        if CheckLandValue(hwRound(HHGear^.X + Gear^.dX * (cHHRadius + cBlowTorchC) + SignAs(_6,Gear^.dX)), hwRound(HHGear^.Y + Gear^.dY * (cHHRadius + cBlowTorchC)), COLOR_INDESTRUCTIBLE) then
            begin
            Gear^.X:= HHGear^.X + Gear^.dX * (cHHRadius + cBlowTorchC);
            Gear^.Y:= HHGear^.Y + Gear^.dY * (cHHRadius + cBlowTorchC);
            end;
        HHGear^.State:= HHGear^.State or gstNoDamage;
        AmmoShove(Gear, 2, 15);
        HHGear^.State:= HHGear^.State and not gstNoDamage
        end;
    end;

if b then
   DrawTunnel(HHGear^.X - Gear^.dX * cHHRadius, HHGear^.Y - _4 - Gear^.dY * cHHRadius + hwAbs(Gear^.dY) * 7,
              Gear^.dX, Gear^.dY,
              cHHRadius * 5, cHHRadius * 2 + 7);

if (Gear^.Timer = 0) or ((HHGear^.Message and gm_Attack) <> 0) then
    begin
    HHGear^.Message:= 0;
    HHGear^.State:= HHGear^.State and (not gstNotKickable);
    DeleteGear(Gear);
    AfterAttack
    end
end;

procedure doStepBlowTorch(Gear: PGear);
var HHGear: PGear;
begin
BTPrevAngle:= High(LongInt);
BTSteps:= 0;
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.Message:= 0;
HHGear^.State:= HHGear^.State or gstNotKickable;
Gear^.doStep:= @doStepBlowTorchWork
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepRope(Gear: PGear); forward;

procedure doStepRopeAfterAttack(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
if ((HHGear^.State and gstHHDriven) = 0)
    or (CheckGearDrowning(HHGear))
    or TestCollisionYwithGear(HHGear, 1) then
    begin
    DeleteGear(Gear);
    isCursorVisible:= false;
    exit
    end;

HedgehogChAngle(HHGear);

if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then SetLittle(HHGear^.dX);

if HHGear^.dY.isNegative and TestCollisionYwithGear(HHGear, -1) then HHGear^.dY:= _0;
HHGear^.X:= HHGear^.X + HHGear^.dX;
HHGear^.Y:= HHGear^.Y + HHGear^.dY;
HHGear^.dY:= HHGear^.dY + cGravity;

if (Gear^.Message and gm_Attack) <> 0 then
    begin
    Gear^.X:= HHGear^.X;
    Gear^.Y:= HHGear^.Y;

    ApplyAngleBounds(PHedgehog(Gear^.Hedgehog)^, amRope);

    Gear^.dX:= SignAs(AngleSin(HHGear^.Angle), HHGear^.dX);
    Gear^.dY:= -AngleCos(HHGear^.Angle);
    Gear^.Friction:= _450;
    Gear^.Elasticity:= _0;
    Gear^.State:= Gear^.State and not gsttmpflag;
    Gear^.doStep:= @doStepRope
    end
end;

procedure doStepRopeWork(Gear: PGear);
var HHGear: PGear;
    len, tx, ty, nx, ny, ropeDx, ropeDy, mdX, mdY: hwFloat;
    lx, ly: LongInt;
    haveCollision,
    haveDivided: boolean;

    procedure DeleteMe;
    begin
    with HHGear^ do
        begin
        Message:= Message and not gm_Attack;
        State:= (State or gstMoving) and not gstWinner;
        end;
    DeleteGear(Gear)
    end;

    procedure WaitCollision;
    begin
    with HHGear^ do
        begin
        Message:= Message and not gm_Attack;
        State:= State or gstMoving;
        end;
    RopePoints.Count:= 0;
    Gear^.Elasticity:= _0;
    Gear^.doStep:= @doStepRopeAfterAttack
    end;

begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;

if ((HHGear^.State and gstHHDriven) = 0)
    or (CheckGearDrowning(HHGear)) then
    begin
    DeleteMe;
    exit
    end;

if (Gear^.Message and gm_Left  <> 0) then HHGear^.dX:= HHGear^.dX - _0_0002 else
if (Gear^.Message and gm_Right <> 0) then HHGear^.dX:= HHGear^.dX + _0_0002;

if not TestCollisionYwithGear(HHGear, 1) then HHGear^.dY:= HHGear^.dY + cGravity;

ropeDx:= HHGear^.X - Gear^.X; // vector between hedgehog and rope attaching point
ropeDy:= HHGear^.Y - Gear^.Y;

mdX:= ropeDx + HHGear^.dX;
mdY:= ropeDy + HHGear^.dY;
len:= _1 / Distance(mdX, mdY);
mdX:= mdX * len; // rope vector plus hedgehog direction vector normalized
mdY:= mdY * len;

Gear^.dX:= mdX; // for visual purposes only
Gear^.dY:= mdY;

/////
    tx:= HHGear^.X;
    ty:= HHGear^.Y;

    if ((Gear^.Message and gm_Down) <> 0) and (Gear^.Elasticity < Gear^.Friction) then
        if not (TestCollisionXwithGear(HHGear, hwSign(ropeDx))
                or TestCollisionYwithGear(HHGear, hwSign(ropeDy))) then
                    Gear^.Elasticity:= Gear^.Elasticity + _0_3;

    if ((Gear^.Message and gm_Up) <> 0) and (Gear^.Elasticity > _30) then
        if not (TestCollisionXwithGear(HHGear, -hwSign(ropeDx))
                or TestCollisionYwithGear(HHGear, -hwSign(ropeDy))) then
                    Gear^.Elasticity:= Gear^.Elasticity - _0_3;

    HHGear^.X:= Gear^.X + mdX * Gear^.Elasticity;
    HHGear^.Y:= Gear^.Y + mdY * Gear^.Elasticity;

    HHGear^.dX:= HHGear^.X - tx;
    HHGear^.dY:= HHGear^.Y - ty;
////


    haveDivided:= false;
    // check whether rope needs dividing
    len:= _1 / Distance(ropeDx, ropeDy); // old rope pos
    nx:= ropeDx * len;
    ny:= ropeDy * len;

    len:= Gear^.Elasticity - _0_3x70;
    while len > _3 do
            begin
            lx:= hwRound(Gear^.X + mdX * len);
            ly:= hwRound(Gear^.Y + mdY * len);
            if ((ly and LAND_HEIGHT_MASK) = 0) and ((lx and LAND_WIDTH_MASK) = 0) and (Land[ly, lx] <> 0) then
                begin
                with RopePoints.ar[RopePoints.Count] do
                    begin
                    X:= Gear^.X;
                    Y:= Gear^.Y;
                    if RopePoints.Count = 0 then RopePoints.HookAngle:= DxDy2Angle(Gear^.dY, Gear^.dX);
                    b:= (nx * HHGear^.dY) > (ny * HHGear^.dX);
                    dLen:= len
                    end;
                with RopePoints.rounded[RopePoints.Count] do
                    begin
                    X:= hwRound(Gear^.X);
                    Y:= hwRound(Gear^.Y);
                    end;

                Gear^.X:= Gear^.X + nx * len;
                Gear^.Y:= Gear^.Y + ny * len;
                inc(RopePoints.Count);
                TryDo(RopePoints.Count <= MAXROPEPOINTS, 'Rope points overflow', true);
                Gear^.Elasticity:= Gear^.Elasticity - len;
                Gear^.Friction:= Gear^.Friction - len;
                haveDivided:= true;
                break
                end;
            len:= len - _0_3 // should be the same as increase step
            end;

if not haveDivided then
    if RopePoints.Count > 0 then // check whether the last dividing point could be removed
        begin
        tx:= RopePoints.ar[Pred(RopePoints.Count)].X;
        ty:= RopePoints.ar[Pred(RopePoints.Count)].Y;
        if RopePoints.ar[Pred(RopePoints.Count)].b xor ((tx - Gear^.X) * (ty - HHGear^.Y) > (tx - HHGear^.X) * (ty - Gear^.Y)) then
            begin
            dec(RopePoints.Count);
            Gear^.X:= RopePoints.ar[RopePoints.Count].X;
            Gear^.Y:= RopePoints.ar[RopePoints.Count].Y;
            Gear^.Elasticity:= Gear^.Elasticity + RopePoints.ar[RopePoints.Count].dLen;
            Gear^.Friction:= Gear^.Friction + RopePoints.ar[RopePoints.Count].dLen
            end
        end;

haveCollision:= false;
if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then
    begin
    HHGear^.dX:= -_0_6 * HHGear^.dX;
    haveCollision:= true
    end;
if TestCollisionYwithGear(HHGear, hwSign(HHGear^.dY)) then
    begin
    HHGear^.dY:= -_0_6 * HHGear^.dY;
    haveCollision:= true
    end;

if haveCollision
    and (Gear^.Message and (gm_Left or gm_Right) <> 0)
    and (Gear^.Message and (gm_Up or gm_Down) <> 0) then
    begin
    HHGear^.dX:= SignAs(hwAbs(HHGear^.dX) + _0_2, HHGear^.dX);
    HHGear^.dY:= SignAs(hwAbs(HHGear^.dY) + _0_2, HHGear^.dY)
    end;

len:= Distance(HHGear^.dX, HHGear^.dY);
if len > _0_8 then
    begin
    len:= _0_8 / len;
    HHGear^.dX:= HHGear^.dX * len;
    HHGear^.dY:= HHGear^.dY * len;
    end;

if (Gear^.Message and gm_Attack) <> 0 then
    if (Gear^.State and gsttmpFlag) <> 0 then
        with PHedgehog(Gear^.Hedgehog)^ do
            if Ammo^[CurSlot, CurAmmo].AmmoType <> amParachute then
                WaitCollision
            else
                DeleteMe
    else
else
    if (Gear^.State and gsttmpFlag) = 0 then
        Gear^.State:= Gear^.State or gsttmpFlag;
end;

procedure doStepRopeAttach(Gear: PGear);
var HHGear: PGear;
    tx, ty, tt: hwFloat;

    procedure RemoveFromAmmo;
    begin
    if (Gear^.State and gstAttacked) = 0 then
        begin
        OnUsedAmmo(PHedgehog(HHGear^.Hedgehog)^);
        Gear^.State:= Gear^.State or gstAttacked
        end;
    ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^)
    end;

begin
Gear^.X:= Gear^.X - Gear^.dX;
Gear^.Y:= Gear^.Y - Gear^.dY;
Gear^.Elasticity:= Gear^.Elasticity + _1;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
DeleteCI(HHGear);

if (HHGear^.State and gstMoving) <> 0 then
    begin
    if TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then SetLittle(HHGear^.dX);
    if HHGear^.dY.isNegative and TestCollisionYwithGear(HHGear, -1) then HHGear^.dY:= _0;

    HHGear^.X:= HHGear^.X + HHGear^.dX;
    Gear^.X:= Gear^.X + HHGear^.dX;

    if TestCollisionYwithGear(HHGear, 1) then
        begin
        CheckHHDamage(HHGear);
        HHGear^.dY:= _0;
        //HHGear^.State:= HHGear^.State and not (gstHHJumping or gstHHHJump);
        end else
        begin
        HHGear^.Y:= HHGear^.Y + HHGear^.dY;
        Gear^.Y:= Gear^.Y + HHGear^.dY;
        HHGear^.dY:= HHGear^.dY + cGravity;
        end;
        
    tt:= Gear^.Elasticity;
    tx:= _0;
    ty:= _0;
    while tt > _20 do
        begin
        if  TestCollisionXwithXYShift(Gear, tx, hwRound(ty), -hwSign(Gear^.dX))
        or TestCollisionYwithXYShift(Gear, hwRound(tx), hwRound(ty), -hwSign(Gear^.dY)) then
            begin
            Gear^.X:= Gear^.X + tx;
            Gear^.Y:= Gear^.Y + ty;
            Gear^.Elasticity:= tt;
            Gear^.doStep:= @doStepRopeWork;
            with HHGear^ do State:= State and not (gstAttacking or gstHHJumping or gstHHHJump);

            RemoveFromAmmo;

            tt:= _0;
            exit
            end;
        tx:= tx + Gear^.dX + Gear^.dX;
        ty:= ty + Gear^.dY + Gear^.dY;
        tt:= tt - _2;
        end;
    end;

CheckCollision(Gear);

if (Gear^.State and gstCollision) <> 0 then
    if Gear^.Elasticity < _10 then
        Gear^.Elasticity:= _10000
    else
        begin
        Gear^.doStep:= @doStepRopeWork;
        with HHGear^ do State:= State and not (gstAttacking or gstHHJumping or gstHHHJump);

        RemoveFromAmmo;

        exit
        end;

if (Gear^.Elasticity > Gear^.Friction)
or ((Gear^.Message and gm_Attack) = 0)
or ((HHGear^.State and gstHHDriven) = 0)
or (HHGear^.Damage > 0) then
    begin
    with PHedgehog(Gear^.Hedgehog)^.Gear^ do
        begin
        State:= State and not gstAttacking;
        Message:= Message and not gm_Attack
        end;
    DeleteGear(Gear)
    end
end;

procedure doStepRope(Gear: PGear);
begin
Gear^.dX:= - Gear^.dX;
Gear^.dY:= - Gear^.dY;
Gear^.doStep:= @doStepRopeAttach
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmokeTrace(Gear: PGear);
begin
inc(Gear^.Timer);
if Gear^.Timer > 64 then
    begin
    Gear^.Timer:= 0;
    dec(Gear^.State)
    end;
Gear^.dX:= Gear^.dX + cWindSpeed;
Gear^.X:= Gear^.X + Gear^.dX;
if Gear^.State = 0 then DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepExplosionWork(Gear: PGear);
begin
inc(Gear^.Timer);
if Gear^.Timer > 75 then
    begin
    inc(Gear^.State);
    Gear^.Timer:= 0;
    if Gear^.State > 5 then DeleteGear(Gear)
    end;
end;

procedure doStepExplosion(Gear: PGear);
var i: LongWord;
begin
for i:= 0 to 31 do AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtFire);
for i:= 0 to 8 do AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtExplPart);
for i:= 0 to 8 do AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtExplPart2);
Gear^.doStep:= @doStepExplosionWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepMine(Gear: PGear);
begin
if (Gear^.State and gstMoving) <> 0 then
    begin
    DeleteCI(Gear);
    doStepFallingGear(Gear);
    if (Gear^.State and gstMoving) = 0 then
        begin
        AddGearCI(Gear);
        Gear^.dX:= _0;
        Gear^.dY:= _0
        end;
    CalcRotationDirAngle(Gear);
    AllInactive:= false
    end else
    if ((GameTicks and $3F) = 25) then
        doStepFallingGear(Gear);

if ((Gear^.State and gsttmpFlag) <> 0) and (Gear^.Health <> 0) then
    if ((Gear^.State and gstAttacking) = 0) then
        begin
        if ((GameTicks and $1F) = 0) then
            if CheckGearNear(Gear, gtHedgehog, 46, 32) <> nil then Gear^.State:= Gear^.State or gstAttacking
        end else // gstAttacking <> 0
        begin
        AllInactive:= false;
        if (Gear^.Timer and $FF) = 0 then PlaySound(sndMineTick);
        if Gear^.Timer = 0 then
            begin
            if ((Gear^.State and gstWait) <> 0) or 
               (cMineDudPercent = 0) or
               (getRandom(100) > cMineDudPercent) then
               begin
               doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
               DeleteGear(Gear)
               end
            else
               begin
               AddVisualGear(hwRound(Gear^.X) - 4  + Random(8), hwRound(Gear^.Y) - 4 - Random(4), vgtSmoke);
               PlaySound(sndVaporize);
               Gear^.Health:= 0;
               end;
            exit
            end;
        dec(Gear^.Timer);
        end else // gsttmpFlag = 0
    if TurnTimeLeft = 0 then Gear^.State:= Gear^.State or gsttmpFlag;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDynamite(Gear: PGear);
begin
doStepFallingGear(Gear);
AllInactive:= false;
if Gear^.Timer mod 166 = 0 then inc(Gear^.Tag);
if Gear^.Timer = 1000 then // might need better timing
    makeHogsWorry(Gear^.X, Gear^.Y, 75);
if Gear^.Timer = 0 then
    begin
    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 75, EXPLAutoSound);
    DeleteGear(Gear);
    exit
    end;
dec(Gear^.Timer);
end;

///////////////////////////////////////////////////////////////////////////////

(*
TODO
Increase damage as barrel smokes?
Try tweaking friction some more
*)
procedure doStepRollingBarrel(Gear: PGear);
var i: LongInt;
    particle: PVisualGear;
begin
Gear^.State:= Gear^.State or gstAnimation;
if ((Gear^.dX.QWordValue <> 0) or (Gear^.dY.QWordValue <> 0))  then
    begin
    DeleteCI(Gear);
    AllInactive:= false;
    if not Gear^.dY.isNegative and (Gear^.dY > _0_03) and TestCollisionYwithGear(Gear, 1) then
        begin
        Gear^.State:= Gear^.State or gsttmpFlag;
        inc(Gear^.Damage, hwRound(Gear^.dY * _50));
        for i:= min(12, hwRound(Gear^.dY*_10)) downto 0 do 
            begin
            particle:= AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust);
            if particle <> nil then particle^.dX := particle^.dX + (Gear^.dX / 5)
            end
        end
    else if not Gear^.dX.isNegative and (Gear^.dX > _0_03) and TestCollisionXwithGear(Gear, 1) then
        inc(Gear^.Damage, hwRound(Gear^.dX * _50))
    else if Gear^.dY.isNegative and (Gear^.dY < -_0_03) and TestCollisionYwithGear(Gear, -1) then
        inc(Gear^.Damage, hwRound(Gear^.dY * -_50))
    else if Gear^.dX.isNegative and (Gear^.dX < -_0_03) and TestCollisionXwithGear(Gear, -1) then
        inc(Gear^.Damage, hwRound(Gear^.dX * -_50));
    if Gear^.Damage <> 0 then PlaySound(sndGrenadeImpact);
    doStepFallingGear(Gear);
    CalcRotationDirAngle(Gear);
    CheckGearDrowning(Gear)
    end
else 
    begin
    Gear^.State:= Gear^.State or gsttmpFlag;
    AddGearCI(Gear)
    end;
(*
Attempt to make a barrel knock itself over an edge.  Would need more checks to avoid issues like burn damage
    begin
    x:= hwRound(Gear^.X);
    y:= hwRound(Gear^.Y);
    if (((y+1) and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) then
        if (Land[y+1, x] = 0) then
            begin
            if (((y+1) and LAND_HEIGHT_MASK) = 0) and (((x+Gear^.Radius-2) and LAND_WIDTH_MASK) = 0) and (Land[y+1, x+Gear^.Radius-2] = 0) then
                Gear^.dX:= -_0_08
            else if (((y+1 and LAND_HEIGHT_MASK)) = 0) and (((x-(Gear^.Radius-2)) and LAND_WIDTH_MASK) = 0) and (Land[y+1, x-(Gear^.Radius-2)] = 0) then
                Gear^.dX:= _0_08;
            end;
    if Gear^.dX.QWordValue = 0 then AddGearCI(Gear)
    end; *)

if not Gear^.dY.isNegative and (Gear^.dY < _0_001) and TestCollisionYwithGear(Gear, 1) then Gear^.dY:= _0;
if hwAbs(Gear^.dX) < _0_001 then Gear^.dX:= _0;
    
if ((Gear^.Health * 100 div cBarrelHealth) < random(90)) and ((GameTicks and $FF) = 0) then
    if (cBarrelHealth div Gear^.Health) > 2 then 
        AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmoke)
    else
        AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmokeWhite);
dec(Gear^.Health, Gear^.Damage);
Gear^.Damage:= 0;
if Gear^.Health <= 0 then Gear^.doStep:= @doStepCase; // Hand off to doStepCase for the explosion

end;

procedure doStepCase(Gear: PGear);
var i, x, y: LongInt;
    k: TGearType;
    exBoom: boolean;
    dX, dY: HWFloat;
begin
k:= Gear^.Kind;
exBoom:= false;

if (Gear^.Message and gm_Destroy) > 0 then
    begin
    DeleteGear(Gear);
    FreeActionsList;
    SetAllToActive; // something (hh, mine, etc...) could be on top of the case
    with CurrentHedgehog^ do
        if Gear <> nil then Gear^.Message:= Gear^.Message and not (gm_LJump or gm_HJump);
    exit
    end;

if k = gtExplosives then
    begin
    //if V > _0_03 then Gear^.State:= Gear^.State or gstAnimation;
    if (hwAbs(Gear^.dX) > _0_15) or ((hwAbs(Gear^.dY) > _0_15) and (hwAbs(Gear^.dX) > _0_02)) then Gear^.doStep:= @doStepRollingBarrel;
    
    if ((Gear^.Health * 100 div cBarrelHealth) < random(90)) and ((GameTicks and $FF) = 0) then
        if (cBarrelHealth div Gear^.Health) > 2 then 
            AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmoke)
        else
            AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), hwRound(Gear^.Y) - 2, vgtSmokeWhite);
    dec(Gear^.Health, Gear^.Damage);
    Gear^.Damage:= 0;
    if Gear^.Health <= 0 then
        exBoom:= true;
    end;

if (Gear^.Damage > 0) or exBoom then
    begin
    x:= hwRound(Gear^.X);
    y:= hwRound(Gear^.Y);
    DeleteGear(Gear); // <-- delete gear!

    if k = gtCase then
        begin
        doMakeExplosion(x, y, 25, EXPLAutoSound);
        for i:= 0 to 63 do
            AddGear(x, y, gtFlame, 0, _0, _0, 0);
        end
    else if k = gtExplosives then
        begin
        doMakeExplosion(x, y, 75, EXPLAutoSound);
        for i:= 0 to 31 do
            begin
            dX:= AngleCos(i * 64) * _0_5 * (getrandom + _1);
            dY:= AngleSin(i * 64) * _0_5 * (getrandom + _1);
            AddGear(x, y, gtFlame, 0, dX, dY, 0);
            AddGear(x, y, gtFlame, 0, -dX, -dY, 0)^.State:= gsttmpFlag;
            end
        end;
    exit
    end;

if (Gear^.dY.QWordValue <> 0) or (not TestCollisionYwithGear(Gear, 1)) then
    begin
    AllInactive:= false;
    Gear^.dY:= Gear^.dY + cGravity;
    Gear^.Y:= Gear^.Y + Gear^.dY;
    if (not Gear^.dY.isNegative) and (Gear^.dY > _0_001) then SetAllHHToActive;
    if (Gear^.dY.isNegative) and TestCollisionYwithGear(Gear, -1) then Gear^.dY:= _0;
    if (not Gear^.dY.isNegative) and TestCollisionYwithGear(Gear, 1) then
        begin
        if (Gear^.dY > _0_02) and (k = gtExplosives) then
            inc(Gear^.Damage, hwRound(Gear^.dY * _40));

        if Gear^.dY > _0_2 then
            for i:= min(12, hwRound(Gear^.dY*_10)) downto 0 do 
                AddVisualGear(hwRound(Gear^.X) - 5 + Random(10), hwRound(Gear^.Y) + 12, vgtDust);
        Gear^.dY:= - Gear^.dY * Gear^.Elasticity;
        if Gear^.dY > - _0_001 then Gear^.dY:= _0
            else if Gear^.dY < - _0_03 then
                if Gear^.Kind = gtExplosives then
                    PlaySound(sndGrenadeImpact)
                else
                    PlaySound(sndGraveImpact);
        end;
    //if Gear^.dY > - _0_001 then Gear^.dY:= _0
    CheckGearDrowning(Gear);
    end;

if (Gear^.dY.QWordValue = 0) then AddGearCI(Gear)
       else if (Gear^.dY.QWordValue <> 0) then DeleteCI(Gear)
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepTarget(Gear: PGear);
begin
if (Gear^.Timer = 0) and (Gear^.Tag = 0) then
    PlaySound(sndWarp);

if (Gear^.Tag = 0) and (Gear^.Timer < 1000) then
    inc(Gear^.Timer)
else if Gear^.Tag = 1 then
    begin
        Gear^.Tag:= 2;
        if (TrainingFlags and tfTimeTrial) <> 0 then
            begin
            inc(TurnTimeLeft, TrainingTimeInc);
            
            if TrainingTimeInc > TrainingTimeInM then
                dec(TrainingTimeInc, TrainingTimeInD);
            if TurnTimeLeft > TrainingTimeMax then
                TurnTimeLeft:= TrainingTimeMax;
            end;
    end
else if Gear^.Tag = 2 then
    if Gear^.Timer > 0 then
        dec(Gear^.Timer)
    else
        begin
            if (TrainingFlags and tfTargetRespawn) <> 0 then
                begin
                TrainingTargetGear:= AddGear(0, 0, gtTarget, 0, _0, _0, 0);
                FindPlace(TrainingTargetGear, false, 0, LAND_WIDTH);
                end;
            DeleteGear(Gear);
            exit;
        end;

doStepCase(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepIdle(Gear: PGear);
begin
AllInactive:= false;
dec(Gear^.Timer);
if Gear^.Timer = 0 then
    begin
    DeleteGear(Gear);
    AfterAttack
    end
end;

procedure doStepShover(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.State:= HHGear^.State or gstNoDamage;
DeleteCI(HHGear);

AmmoShove(Gear, 30, 115);

HHGear^.State:= HHGear^.State and not gstNoDamage;
Gear^.Timer:= 250;
Gear^.doStep:= @doStepIdle
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepWhip(Gear: PGear);
var HHGear: PGear;
    i: LongInt;
begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.State:= HHGear^.State or gstNoDamage;
DeleteCI(HHGear);

for i:= 0 to 3 do
    begin
    AmmoShove(Gear, 30, 25);
    Gear^.X:= Gear^.X + Gear^.dX * 5
    end;

HHGear^.State:= HHGear^.State and not gstNoDamage;
Gear^.Timer:= 250;
Gear^.doStep:= @doStepIdle
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFlame(Gear: PGear);
var i: Integer;
begin
    if (Gear^.State and gsttmpFlag) = 0 then AllInactive:= false;

if not TestCollisionYwithGear(Gear, 1) then
    begin
    AllInactive:= false;
    if hwAbs(Gear^.dX) > _0_01 then
        Gear^.dX:= Gear^.dX * _0_995;
     if (Gear^.State and gsttmpFlag) <> 0 then Gear^.dY:= Gear^.dY + _2*cGravity else
    Gear^.dY:= Gear^.dY + cGravity;
    if hwAbs(Gear^.dY) > _0_2 then Gear^.dY:= Gear^.dY * _0_995;

    if (Gear^.State and gsttmpFlag) <> 0 then Gear^.X:= Gear^.X + Gear^.dX else
    Gear^.X:= Gear^.X + Gear^.dX + cWindSpeed * 640;
    Gear^.Y:= Gear^.Y + Gear^.dY;

    if (hwRound(Gear^.Y) > cWaterLine) then
        begin
        for i:= 0 to 3 do
            AddVisualGear(hwRound(Gear^.X) - 16 + Random(32), cWaterLine - 16 + Random(16), vgtSteam);
        PlaySound(sndVaporize);
        DeleteGear(Gear);
        exit
        end
    end else begin
        if (Gear^.State and gsttmpFlag) <> 0 then 
            begin
            Gear^.Radius:= 9;
            AmmoShove(Gear, 2, 30);
            Gear^.Radius:= 1
            end;
        if Gear^.Timer > 0 then
            begin
            dec(Gear^.Timer);
            inc(Gear^.Damage)
            end
        else begin
// Standard fire
            if (Gear^.State and gsttmpFlag) = 0 then
                begin
                Gear^.Radius:= 9;
                AmmoShove(Gear, 4, 100);
                Gear^.Radius:= 1;
                doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 4, EXPLNoDamage);
                if Random(100) > 90 then
                  for i:= 0 to Random(3) do
                    AddVisualGear(hwRound(Gear^.X) - 3 + Random(6), hwRound(Gear^.Y) - 2, vgtSmoke);
                if Gear^.Health > 0 then dec(Gear^.Health);
                Gear^.Timer:= 450 - Gear^.Tag * 8
                end
                else begin
// Modified fire
                if ((GameTicks and $7FF) = 0) and ((GameFlags and gfSolidLand) = 0) then begin
                    DrawExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 4);
                    
                    for i:= 0 to Random(3) do
                      AddVisualGear(hwRound(Gear^.X) - 3 + Random(6), hwRound(Gear^.Y) - 2, vgtSmoke);
                end;
                // This one is interesting.  I think I understand the purpose, but I wonder if a bit more fuzzy of kicking could be done with getrandom.
                Gear^.Timer:= 100 - Gear^.Tag * 3;
                if (Gear^.Damage > 3000+Gear^.Tag*1500) then Gear^.Health:= 0
                end
            end
        end;
if Gear^.Health = 0 then begin
  if (Gear^.State and gsttmpFlag) = 0 then begin
    if Random(100) > 80 then begin
      for i:= 0 to Random(3) do begin
        AddVisualGear(hwRound(Gear^.X) - 3 + Random(6), hwRound(Gear^.Y) - 2, vgtSmoke);
      end;
    end;
  end else begin
    for i:= 0 to Random(3) do begin
      AddVisualGear(hwRound(Gear^.X) - 3 + Random(6), hwRound(Gear^.Y) - 2, vgtSmoke);
    end;
  end;
  
  DeleteGear(Gear)
  end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFirePunchWork(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;
if ((Gear^.Message and gm_Destroy) <> 0) then
    begin
    DeleteGear(Gear);
    AfterAttack;
    exit
    end;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
if hwRound(HHGear^.Y) <= Gear^.Tag - 2 then
    begin
    Gear^.Tag:= hwRound(HHGear^.Y);
    DrawTunnel(HHGear^.X - int2hwFloat(cHHRadius), HHGear^.Y - _1, _0_5, _0, cHHRadius * 4, 2);
    HHGear^.State:= HHGear^.State or gstNoDamage;
    Gear^.Y:= HHGear^.Y;
    AmmoShove(Gear, 30, 40);
    HHGear^.State:= HHGear^.State and not gstNoDamage
    end;

HHGear^.dY:= HHGear^.dY + cGravity;
if not (HHGear^.dY.isNegative) then
    begin
    HHGear^.State:= HHGear^.State or gstMoving;
    DeleteGear(Gear);
    AfterAttack;
    exit
    end;

if CheckLandValue(hwRound(HHGear^.X), hwRound(HHGear^.Y + HHGear^.dY + SignAs(_6,Gear^.dY)), COLOR_INDESTRUCTIBLE) then
   HHGear^.Y:= HHGear^.Y + HHGear^.dY
end;

procedure doStepFirePunch(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
DeleteCI(HHGear);
HHGear^.X:= int2hwFloat(hwRound(HHGear^.X)) - _0_5;
HHGear^.dX:= SignAs(cLittle, Gear^.dX);

HHGear^.dY:= - _0_3;

Gear^.X:= HHGear^.X;
Gear^.dX:= SignAs(_0_45, Gear^.dX);
Gear^.dY:= - _0_9;
Gear^.doStep:= @doStepFirePunchWork;
DrawTunnel(HHGear^.X - int2hwFloat(cHHRadius), HHGear^.Y + _1, _0_5, _0, cHHRadius * 4, 5);

PlaySound(TSound(ord(sndFirePunch1) + GetRandom(6)), PHedgehog(HHGear^.Hedgehog)^.Team^.voicepack)
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepParachuteWork(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;

inc(Gear^.Timer);

if TestCollisionYwithGear(HHGear, 1)
    or ((HHGear^.State and gstHHDriven) = 0)
    or CheckGearDrowning(HHGear)
    or ((Gear^.Message and gm_Attack) <> 0) then
    begin
    with HHGear^ do
        begin
        Message:= 0;
        SetLittle(dX);
        dY:= _0;
        State:= State or gstMoving;
        end;
    DeleteGear(Gear);
    isCursorVisible:= false;
    exit
    end;

if not TestCollisionXwithGear(HHGear, hwSign(HHGear^.dX)) then
    HHGear^.X:= HHGear^.X + cWindSpeed * 200;

if (Gear^.Message and gm_Left) <> 0 then HHGear^.X:= HHGear^.X - cMaxWindSpeed * 40
else if (Gear^.Message and gm_Right) <> 0 then HHGear^.X:= HHGear^.X + cMaxWindSpeed * 40;
if (Gear^.Message and gm_Up) <> 0 then HHGear^.Y:= HHGear^.Y - cGravity * 40
else if (Gear^.Message and gm_Down) <> 0 then HHGear^.Y:= HHGear^.Y + cGravity * 40;

HHGear^.Y:= HHGear^.Y + cGravity * 100;
Gear^.X:= HHGear^.X;
Gear^.Y:= HHGear^.Y
end;

procedure doStepParachute(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;

DeleteCI(HHGear);

OnUsedAmmo(PHedgehog(HHGear^.Hedgehog)^);
ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^);

HHGear^.State:= HHGear^.State and not (gstAttacking or gstAttacked or gstMoving);
HHGear^.Message:= HHGear^.Message and not gm_Attack;

Gear^.doStep:= @doStepParachuteWork;

Gear^.Message:= HHGear^.Message;
doStepParachuteWork(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepAirAttackWork(Gear: PGear);
var i: Longint;
begin
AllInactive:= false;
Gear^.X:= Gear^.X + cAirPlaneSpeed * Gear^.Tag;

if (Gear^.Health > 0)and(not (Gear^.X < Gear^.dX))and(Gear^.X < Gear^.dX + cAirPlaneSpeed) then
    begin
    dec(Gear^.Health);
    case Gear^.State of
            0: FollowGear:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtAirBomb, 0, cBombsSpeed * Gear^.Tag, _0, 0);
            1: FollowGear:= AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtMine,    0, cBombsSpeed * Gear^.Tag, _0, 0);
            2: for i:= -19 to 19 do
                FollowGear:= AddGear(hwRound(Gear^.X) + i div 3, hwRound(Gear^.Y), gtFlame, 0, _0_001 * i, _0, 0);
            end;
    Gear^.dX:= Gear^.dX + int2hwFloat(30 * Gear^.Tag)
    end;

if (GameTicks and $3F) = 0 then
    AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0);

if (hwRound(Gear^.X) > (LAND_WIDTH+1024)) or (hwRound(Gear^.X) < -1024) then DeleteGear(Gear)
end;

procedure doStepAirAttack(Gear: PGear);
begin
AllInactive:= false;

if Gear^.X.QWordValue = 0 then
    begin
    Gear^.Tag:=  1;
    Gear^.X:= -_1024;
    end
else
    begin
    Gear^.Tag:= -1;
    Gear^.X:= int2hwFloat(LAND_WIDTH + 1024);
    end;

Gear^.Y:= int2hwFloat(topY-300);
Gear^.dX:= int2hwFloat(TargetPoint.X - 5 * Gear^.Tag * 15);

if (int2hwFloat(TargetPoint.Y) - Gear^.Y > _0) and (Gear^.State <> 2) then
        Gear^.dX:= Gear^.dX - cBombsSpeed * hwSqrt((int2hwFloat(TargetPoint.Y) - Gear^.Y) * 2 / cGravity) * Gear^.Tag;

Gear^.Health:= 6;
Gear^.doStep:= @doStepAirAttackWork;
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepAirBomb(Gear: PGear);
begin
AllInactive:= false;
doStepFallingGear(Gear);
if (Gear^.State and gstCollision) <> 0 then
    begin
    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 30, EXPLAutoSound);
    DeleteGear(Gear);
    exit
    end;
if (GameTicks and $3F) = 0 then
    AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0)
end;

////////////////////////////////////////////////////////////////////////////////

procedure doStepGirder(Gear: PGear);
var HHGear: PGear;
    x, y, tx, ty: hwFloat;
begin
AllInactive:= false;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
tx:= int2hwFloat(TargetPoint.X);
ty:= int2hwFloat(TargetPoint.Y);
x:= HHGear^.X;
y:= HHGear^.Y;

if (Distance(tx - x, ty - y) > _256) or
   not TryPlaceOnLand(TargetPoint.X - SpritesData[sprAmGirder].Width div 2,
                      TargetPoint.Y - SpritesData[sprAmGirder].Height div 2,
                      sprAmGirder, Gear^.State, true) then
    begin
    PlaySound(sndDenied);
    HHGear^.Message:= HHGear^.Message and not gm_Attack;
    HHGear^.State:= HHGear^.State and not gstAttacking;
    HHGear^.State:= HHGear^.State or gstHHChooseTarget;
    isCursorVisible:= true;
    DeleteGear(Gear)
    end
else begin
    PlaySound(sndPlaced);
    DeleteGear(Gear);
    OnUsedAmmo(PHedgehog(HHGear^.Hedgehog)^);
    ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^)
    end;

HHGear^.State:= HHGear^.State and not (gstAttacking or gstAttacked);
HHGear^.Message:= HHGear^.Message and not gm_Attack;
TargetPoint.X:= NoPointX
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepTeleportAfter(Gear: PGear);
var HHGear: PGear;
begin
PHedgehog(Gear^.Hedgehog)^.Unplaced:= false;
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.Y:= HHGear^.Y + HHGear^.dY; // hedgehog falling to collect cases
HHGear^.dY:= HHGear^.dY + cGravity;
if TestCollisionYwithGear(HHGear, 1)
    or CheckGearDrowning(HHGear) then
    begin
    DeleteGear(Gear);
    AfterAttack
    end
end;

procedure doStepTeleportAnim(Gear: PGear);
begin
inc(Gear^.Timer);
if Gear^.Timer = 65 then
    begin
    Gear^.Timer:= 0;
    inc(Gear^.Pos);
    if Gear^.Pos = 11 then
        Gear^.doStep:= @doStepTeleportAfter
    end;
end;

procedure doStepTeleport(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
if not TryPlaceOnLand(TargetPoint.X - SpritesData[sprHHTelepMask].Width div 2,
                      TargetPoint.Y - SpritesData[sprHHTelepMask].Height div 2,
                      sprHHTelepMask, 0, false) then
        begin
        HHGear^.Message:= HHGear^.Message and not gm_Attack;
        HHGear^.State:= HHGear^.State and not gstAttacking;
        HHGear^.State:= HHGear^.State or gstHHChooseTarget;
        DeleteGear(Gear);
        isCursorVisible:= true;
        PlaySound(sndDenied)
        end
    else begin
        DeleteCI(HHGear);
        SetAllHHToActive;
        Gear^.doStep:= @doStepTeleportAnim;
        Gear^.X:= HHGear^.X;
        Gear^.Y:= HHGear^.Y;
        HHGear^.X:= int2hwFloat(TargetPoint.X);
        HHGear^.Y:= int2hwFloat(TargetPoint.Y);
        HHGear^.State:= HHGear^.State or gstMoving;
        playSound(sndWarp)
        end;
TargetPoint.X:= NoPointX;

end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSwitcherWork(Gear: PGear);
var HHGear: PGear;
    Msg, State: Longword;
begin
AllInactive:= false;

if ((Gear^.Message and not gm_Switch) <> 0) or (TurnTimeLeft = 0) then
    begin
    HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
    Msg:= Gear^.Message and not gm_Switch;
    DeleteGear(Gear);
    OnUsedAmmo(PHedgehog(HHGear^.Hedgehog)^);
    ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^);

    HHGear:= CurrentHedgehog^.Gear;
    ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^);
    HHGear^.Message:= Msg;
    exit
    end;

if (Gear^.Message and gm_Switch) <> 0 then
    begin
    HHGear:= CurrentHedgehog^.Gear;
    HHGear^.Message:= HHGear^.Message and not gm_Switch;
    Gear^.Message:= Gear^.Message and not gm_Switch;
    State:= HHGear^.State;
    HHGear^.State:= 0;
    HHGear^.Active:= false;
    HHGear^.Z:= cHHZ;
    RemoveGearFromList(HHGear);
    InsertGearToList(HHGear);

    PlaySound(sndSwitchHog);
    
    repeat
        CurrentTeam^.CurrHedgehog:= Succ(CurrentTeam^.CurrHedgehog) mod (CurrentTeam^.HedgehogsNumber);
    until (CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog].Gear <> nil);

    CurrentHedgehog:= @CurrentTeam^.Hedgehogs[CurrentTeam^.CurrHedgehog];

    HHGear:= CurrentHedgehog^.Gear;
    HHGear^.State:= State;
    HHGear^.Active:= true;
    FollowGear:= HHGear;
    HHGear^.Z:= cCurrHHZ;
    RemoveGearFromList(HHGear);
    InsertGearToList(HHGear);
    Gear^.X:= HHGear^.X;
    Gear^.Y:= HHGear^.Y
    end;
end;

procedure doStepSwitcher(Gear: PGear);
var HHGear: PGear;
begin
Gear^.doStep:= @doStepSwitcherWork;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
with HHGear^ do
    begin
    State:= State and not gstAttacking;
    Message:= Message and not gm_Attack
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepMortar(Gear: PGear);
var dX, dY: hwFloat;
    i: LongInt;
    dxn, dyn: boolean;
begin
AllInactive:= false;
dxn:= Gear^.dX.isNegative;
dyn:= Gear^.dY.isNegative;

doStepFallingGear(Gear);
if (Gear^.State and gstCollision) <> 0 then
    begin
    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 20, EXPLAutoSound);

    Gear^.dX.isNegative:= not dxn;
    Gear^.dY.isNegative:= not dyn;
    for i:= 0 to 4 do
        begin
        dX:= Gear^.dX + (GetRandom - _0_5) * _0_03;
        dY:= Gear^.dY + (GetRandom - _0_5) * _0_03;
        AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtCluster, 0, dX, dY, 25);
        end;

    DeleteGear(Gear);
    exit
    end;

if (GameTicks and $3F) = 0 then
    AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepKamikazeWork(Gear: PGear);
const upd: Longword = 0;
var i: LongWord;
    HHGear: PGear;
begin
AllInactive:= false;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.State:= HHGear^.State or gstNoDamage;
DeleteCI(HHGear);

i:= 2;
repeat
    Gear^.X:= Gear^.X + HHGear^.dX;
    Gear^.Y:= Gear^.Y + HHGear^.dY;
    HHGear^.X:= Gear^.X;
    HHGear^.Y:= Gear^.Y;

    inc(Gear^.Damage, 2);

//  if TestCollisionXwithGear(HHGear, hwSign(Gear^.dX))
//      or TestCollisionYwithGear(HHGear, hwSign(Gear^.dY)) then inc(Gear^.Damage, 3);

    dec(i)
until (i = 0) or (Gear^.Damage > Gear^.Health);

inc(upd);
if upd > 3 then
    begin
    if Gear^.Health < 1500 then Gear^.Pos:= 2;

    AmmoShove(Gear, 30, 40);

    DrawTunnel(HHGear^.X - HHGear^.dX * 10,
            HHGear^.Y - _2 - HHGear^.dY * 10 + hwAbs(HHGear^.dY) * 2,
            HHGear^.dX,
            HHGear^.dY,
            20 + cHHRadius * 2,
            cHHRadius * 2 + 6);

    upd:= 0
    end;

if Gear^.Health < Gear^.Damage then
    begin
    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 30, EXPLAutoSound);
    AfterAttack;
    DeleteGear(Gear);
    DeleteGear(HHGear);
    end else
    begin
    dec(Gear^.Health, Gear^.Damage);
    Gear^.Damage:= 0
    end
end;

procedure doStepKamikazeIdle(Gear: PGear);
begin
AllInactive:= false;
dec(Gear^.Timer);
if Gear^.Timer = 0 then
    begin
    Gear^.Pos:= 1;
    PlaySound(sndKamikaze, PHedgehog(Gear^.Hedgehog)^.Team^.voicepack);
    Gear^.doStep:= @doStepKamikazeWork
    end
end;

procedure doStepKamikaze(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;

HHGear^.dX:= Gear^.dX;
HHGear^.dY:= Gear^.dY;

Gear^.dX:= SignAs(_0_45, Gear^.dX);
Gear^.dY:= - _0_9;

Gear^.Timer:= 550;

Gear^.doStep:= @doStepKamikazeIdle
end;

////////////////////////////////////////////////////////////////////////////////
const cakeh = 27;
      cakeDmg = 75;
var CakePoints: array[0..Pred(cakeh)] of record x, y: hwFloat; end;
    CakeI: Longword;

procedure doStepCakeExpl(Gear: PGear);
begin
AllInactive:= false;

inc(Gear^.Tag);
if Gear^.Tag < 2250 then exit;

doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), cakeDmg, EXPLAutoSound);
AfterAttack;
DeleteGear(Gear)
end;

procedure doStepCakeDown(Gear: PGear);
var gi: PGear;
    dmg: LongInt;
begin
AllInactive:= false;

inc(Gear^.Tag);
if Gear^.Tag < 100 then exit;
Gear^.Tag:= 0;

if Gear^.Pos = 0 then
    begin
    gi:= GearsList;
    while gi <> nil do
        begin
        dmg:= cakeDmg * 2 - hwRound(Distance(gi^.X - Gear^.X, gi^.Y - Gear^.Y));
        if (dmg > 1) and (gi^.Kind = gtHedgehog) then
            if (CurrentHedgehog^.Gear = gi) and (not gi^.Invulnerable) then
                gi^.State:= gi^.State or gstLoser
            else
                gi^.State:= gi^.State or gstWinner;
        gi:= gi^.NextGear
        end;
    Gear^.doStep:= @doStepCakeExpl;
    PlaySound(sndCake)
    end else dec(Gear^.Pos)
end;


procedure doStepCakeWork(Gear: PGear);
const dirs: array[0..3] of TPoint = ((x: 0; y: -1), (x: 1; y: 0),(x: 0; y: 1),(x: -1; y: 0));
var xx, yy, xxn, yyn: LongInt;
    da: LongInt;
    tdx, tdy: hwFloat;

    procedure PrevAngle;
    begin
    Gear^.Angle:= (LongInt(Gear^.Angle) + 4 - dA) mod 4
    end;

    procedure NextAngle;
    begin
    Gear^.Angle:= (LongInt(Gear^.Angle) + 4 + dA) mod 4
    end;

begin
AllInactive:= false;

inc(Gear^.Tag);
if Gear^.Tag < 7 then exit;

dA:= hwSign(Gear^.dX);
xx:= dirs[Gear^.Angle].x;
yy:= dirs[Gear^.Angle].y;
xxn:= dirs[(LongInt(Gear^.Angle) + 4 + dA) mod 4].x;
yyn:= dirs[(LongInt(Gear^.Angle) + 4 + dA) mod 4].y;

if (xx = 0) then
    if TestCollisionYwithGear(Gear, yy) then
        PrevAngle
    else begin
        Gear^.Tag:= 0;
        Gear^.Y:= Gear^.Y + int2hwFloat(yy);
        if not TestCollisionXwithGear(Gear, xxn) then
            begin
            Gear^.X:= Gear^.X + int2hwFloat(xxn);
            NextAngle
            end;
        end;

if (yy = 0) then
    if TestCollisionXwithGear(Gear, xx) then
        PrevAngle
    else begin
        Gear^.Tag:= 0;
        Gear^.X:= Gear^.X + int2hwFloat(xx);
        if not TestCollisionYwithGear(Gear, yyn) then
            begin
            Gear^.Y:= Gear^.Y + int2hwFloat(yyn);
            NextAngle
            end;
        end;

if Gear^.Tag = 0 then
    begin
    CakeI:= (CakeI + 1) mod cakeh;
    tdx:= CakePoints[CakeI].x - Gear^.X;
    tdy:= - CakePoints[CakeI].y + Gear^.Y;
    CakePoints[CakeI].x:= Gear^.X;
    CakePoints[CakeI].y:= Gear^.Y;
    Gear^.DirAngle:= DxDy2Angle(tdx, tdy);
    end;

dec(Gear^.Health);
Gear^.Timer:= Gear^.Health*10; // This is not seconds, but at least it is *some* feedback
if (Gear^.Health = 0) or ((Gear^.Message and gm_Attack) <> 0) then
    begin
    FollowGear:= Gear;
    Gear^.RenderTimer:= false;
    Gear^.doStep:= @doStepCakeDown
    end
end;

procedure doStepCakeUp(Gear: PGear);
var i: Longword;
begin
AllInactive:= false;

inc(Gear^.Tag);
if Gear^.Tag < 100 then exit;
Gear^.Tag:= 0;

if Gear^.Pos = 6 then
    begin
    for i:= 0 to Pred(cakeh) do
        begin
        CakePoints[i].x:= Gear^.X;
        CakePoints[i].y:= Gear^.Y
        end;
    CakeI:= 0;
    Gear^.doStep:= @doStepCakeWork
    end else inc(Gear^.Pos)
end;

procedure doStepCakeFall(Gear: PGear);
begin
AllInactive:= false;

Gear^.dY:= Gear^.dY + cGravity;
if TestCollisionYwithGear(Gear, 1) then
    Gear^.doStep:= @doStepCakeUp
else
    begin
    Gear^.Y:= Gear^.Y + Gear^.dY;
    if CheckGearDrowning(Gear) then AfterAttack
    end
end;

procedure doStepCake(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.Message:= HHGear^.Message and (not gm_Attack);
DeleteCI(HHGear);

FollowGear:= Gear;

Gear^.doStep:= @doStepCakeFall
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSeductionWork(Gear: PGear);
var x, y: LongInt;
begin
AllInactive:= false;

Gear^.X:= Gear^.X + Gear^.dX;
Gear^.Y:= Gear^.Y + Gear^.dY;
x:= hwRound(Gear^.X);
y:= hwRound(Gear^.Y);

if ((y and LAND_HEIGHT_MASK) = 0) and ((x and LAND_WIDTH_MASK) = 0) then
    if (Land[y, x] <> 0) then
        begin
        Gear^.dX.isNegative:= not Gear^.dX.isNegative;
        Gear^.dY.isNegative:= not Gear^.dY.isNegative;
        Gear^.dX:= Gear^.dX * _1_5;
        Gear^.dY:= Gear^.dY * _1_5 - _0_3;
        AmmoShove(Gear, 0, 40);
        AfterAttack;
        DeleteGear(Gear)
        end
    else
else
    begin
    AfterAttack;
    DeleteGear(Gear)
    end
end;

procedure doStepSeductionWear(Gear: PGear);
begin
AllInactive:= false;
inc(Gear^.Timer);
if Gear^.Timer > 250 then
    begin
    Gear^.Timer:= 0;
    inc(Gear^.Pos);
    if Gear^.Pos = 5 then
        PlaySound(sndYoohoo, PHedgehog(Gear^.Hedgehog)^.Team^.voicepack)
    end;

if Gear^.Pos = 14 then
    Gear^.doStep:= @doStepSeductionWork
end;

procedure doStepSeduction(Gear: PGear);
begin
AllInactive:= false;
DeleteCI(PHedgehog(Gear^.Hedgehog)^.Gear);
Gear^.doStep:= @doStepSeductionWear
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepWaterUp(Gear: PGear);
var i: LongWord;
begin
AllInactive:= false;

inc(Gear^.Timer);
if Gear^.Timer = 17 then
    Gear^.Timer:= 0
else
    exit;

if cWaterLine > 0 then
    begin
    dec(cWaterLine);
    for i:= 0 to LAND_WIDTH - 1 do
        Land[cWaterLine, i]:= 0;
    SetAllToActive
    end;

inc(Gear^.Tag);
if (Gear^.Tag = 47) or (cWaterLine = 0) then
    DeleteGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDrillDrilling(Gear: PGear);
var t: PGearArray;
    ox, oy: hwFloat;
begin
AllInactive:= false;

if (Gear^.Timer > 0) and ((Gear^.Timer mod 10) = 0) then
    begin
    ox:= Gear^.X;
    oy:= Gear^.Y;
    Gear^.X:= Gear^.X + Gear^.dX;
    Gear^.Y:= Gear^.Y + Gear^.dY;
    DrawTunnel(oX, oY, Gear^.dX, Gear^.dY, 2, 6);
    if(CheckGearDrowning(Gear)) then
        begin
        StopSound(Gear^.SoundChannel);
        exit
        end
    end;

t:= CheckGearsCollision(Gear); //fixes drill not exploding when touching HH bug
if (Gear^.Timer = 0)
or (t^.Count <> 0)
or (not TestCollisionYWithGear(Gear, hwSign(Gear^.dY))
and not TestCollisionXWithGear(Gear, hwSign(Gear^.dX)))
or (Land[hwRound(Gear^.Y), hwRound(Gear^.X)] = COLOR_INDESTRUCTIBLE) then
    begin //out of time or exited ground
    StopSound(Gear^.SoundChannel);
    doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
    DeleteGear(Gear);
    exit
    end;

dec(Gear^.Timer);
end;

procedure doStepDrill(Gear: PGear);
var t: PGearArray;
    oldDx, oldDy: hwFloat;
    t2: hwFloat;
begin
AllInactive:= false;

Gear^.dX:= Gear^.dX + cWindSpeed;
oldDx:= Gear^.dX;
oldDy:= Gear^.dY;

doStepFallingGear(Gear);

if (GameTicks and $3F) = 0 then
    AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0);

if ((Gear^.State and gstCollision) <> 0) then begin //hit
    Gear^.dX:= oldDx;
    Gear^.dY:= oldDy;

    t:= CheckGearsCollision(Gear);
    if (t^.Count = 0) then begin //hit the ground not the HH
        t2 := _0_5 / Distance(Gear^.dX, Gear^.dY);
        Gear^.dX:= Gear^.dX * t2;
        Gear^.dY:= Gear^.dY * t2;
    end else begin //explode right on contact with HH
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 50, EXPLAutoSound);
        DeleteGear(Gear);
        exit;
        end;

    Gear^.SoundChannel:= LoopSound(sndPickhammer);
    Gear^.doStep:= @doStepDrillDrilling;
    dec(Gear^.Timer)
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBallgunWork(Gear: PGear);
var HHGear: PGear;
    rx, ry: hwFloat;
begin
    AllInactive:= false;
    dec(Gear^.Timer);
    HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
    HedgehogChAngle(HHGear);
    if (Gear^.Timer mod 100) = 0 then
        begin
        rx:= rndSign(getRandom * _0_1);
        ry:= rndSign(getRandom * _0_1);

        AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtBall, 0,
                SignAs(AngleSin(HHGear^.Angle) * _0_8, HHGear^.dX) + rx,
                AngleCos(HHGear^.Angle) * ( - _0_8) + ry,
                0);

        PlaySound(sndGun);
        end;

    if (Gear^.Timer = 0) or (HHGear^.Damage <> 0) then
        begin
        DeleteGear(Gear);
        AfterAttack
        end
end;

procedure doStepBallgun(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.Message:= HHGear^.Message and not (gm_Up or gm_Down);
HHGear^.State:= HHGear^.State or gstNotKickable;
Gear^.doStep:= @doStepBallgunWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepRCPlaneWork(Gear: PGear);
const cAngleSpeed = 3;
var HHGear: PGear;
    i: LongInt;
    dX, dY: hwFloat;
    fChanged: boolean;
    trueAngle: Longword;
    t: PGear;
begin
AllInactive:= false;

if ((TrainingFlags and tfRCPlane) = 0) and (Gear^.Timer > 0) then dec(Gear^.Timer);

if ((TrainingFlags and tfRCPlane) <> 0) and ((TrainingFlags and tfTimeTrial) <> 0 ) and (TimeTrialStartTime = 0) then TimeTrialStartTime:= RealTicks;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
FollowGear:= Gear;

fChanged:= false;
if ((HHGear^.State and gstHHDriven) = 0) or (Gear^.Timer = 0) then
    begin
    fChanged:= true;
    if Gear^.Angle > 2048 then dec(Gear^.Angle) else
        if Gear^.Angle < 2048 then inc(Gear^.Angle) else fChanged:= false
    end
else
    begin
    if ((Gear^.Message and gm_Left) <> 0) then
        begin
        fChanged:= true;
        Gear^.Angle:= (Gear^.Angle + (4096 - cAngleSpeed)) mod 4096
        end;

    if ((Gear^.Message and gm_Right) <> 0) then
        begin
        fChanged:= true;
        Gear^.Angle:= (Gear^.Angle + cAngleSpeed) mod 4096
        end
    end;

if fChanged then
    begin
    Gear^.dX.isNegative:= (Gear^.Angle > 2048);
    if Gear^.dX.isNegative then
        trueAngle:= 4096 - Gear^.Angle
    else
        trueAngle:= Gear^.Angle;

    Gear^.dX:= SignAs(AngleSin(trueAngle), Gear^.dX) * _0_25;
    Gear^.dY:= AngleCos(trueAngle) * -_0_25;
    end;

Gear^.X:= Gear^.X + Gear^.dX;
Gear^.Y:= Gear^.Y + Gear^.dY;

if (TrainingFlags and tfRCPlane) = 0 then
    begin
    if (GameTicks and $FF) = 0 then
        if Gear^.Timer < 3500 then
            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtEvilTrace, 0, _0, _0, 0)
        else
            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0);

    if ((HHGear^.Message and gm_Attack) <> 0) and (Gear^.Health <> 0) then
        begin
        HHGear^.Message := HHGear^.Message and not gm_Attack;
        AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtAirBomb, 0, Gear^.dX * _0_5, Gear^.dY * _0_5, 0);
        dec(Gear^.Health)
        end;

    if ((HHGear^.Message and gm_LJump) <> 0)
        and ((Gear^.State and gsttmpFlag) = 0) then
        begin
        Gear^.State:= Gear^.State or gsttmpFlag;
        PauseMusic;
        playSound(sndRideOfTheValkyries);
        end;

    // pickup bonuses
    t:= CheckGearNear(Gear, gtCase, 36, 36);
    if t <> nil then
        PickUp(HHGear, t);
    end
else
    begin
    if (GameTicks and $FF) = 0 then
        AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0);

    // pickup targets
    t:= CheckGearNear(Gear, gtTarget, 36, 36);
    if t <> nil then
        begin
        if t^.Tag <> 0 then // collect it only once
            exit;
        PlaySound(sndShotgunReload);
        t^.Tag:= 1;
        TrainingTargetGear:= nil; // remove target cursor
        exit;
        end;

    if (TurnTimeLeft > 0) then 
        dec(TurnTimeLeft)
    end;
        
CheckCollision(Gear);

if ((Gear^.State and gstCollision) <> 0) or (((TrainingFlags and tfRCPlane) <> 0) and (TurnTimeLeft = 0))
    or CheckGearDrowning(Gear) then
    begin
    if ((TrainingFlags and tfRCPlane) <> 0) and ((TrainingFlags and tfTimeTrial) <> 0 ) and (TimeTrialStopTime = 0) then TimeTrialStopTime:= RealTicks;
    StopSound(Gear^.SoundChannel);
    StopSound(sndRideOfTheValkyries);
    ResumeMusic;

    if ((Gear^.State and gstCollision) <> 0) or (((TrainingFlags and tfRCPlane) <> 0) and (TurnTimeLeft = 0)) then
        begin
        doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 25, EXPLAutoSound);
        for i:= 0 to 32 do
            begin
            dX:= AngleCos(i * 64) * _0_5 * (GetRandom + _1);
            dY:= AngleSin(i * 64) * _0_5 * (GetRandom + _1);
            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, dX, dY, 0);
            AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtFlame, 0, dX, -dY, 0);
            end;
        DeleteGear(Gear)
        end;

    AfterAttack;
    CurAmmoGear:= nil;
    TurnTimeLeft:= 14 * 125;
    
    if (TrainingFlags and tfRCPlane) <> 0 then
        TurnTimeLeft:= 0; // HACK: RCPlane training allows unlimited plane starts in last 2 seconds

    HHGear^.Message:= 0;
    ParseCommand('/taunt '#1, true)
    end
end;

procedure doStepRCPlane(Gear: PGear);
var HHGear: PGear;
begin
HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
HHGear^.Message:= 0;
HHGear^.State:= HHGear^.State or gstNotKickable;
Gear^.Angle:= HHGear^.Angle;
Gear^.Tag:= hwSign(HHGear^.dX);
if HHGear^.dX.isNegative then Gear^.Angle:= 4096 - Gear^.Angle;
Gear^.doStep:= @doStepRCPlaneWork
end;

procedure doStepJetpackWork(Gear: PGear);
var HHGear: PGear;
    fuel: LongInt;
    move: hwFloat;
begin
AllInactive:= false;
HHGear:=PHedgehog(Gear^.Hedgehog)^.Gear;
//dec(Gear^.Timer);
move:= _0_1;
fuel:= 50;
(*if (HHGear^.Message and gm_Precise) <> 0 then
    begin
    move:= _0_02;
    fuel:= 5;
    end;*)

if (HHGear^.Message and gm_Up) <> 0 then
    begin
    if (not HHGear^.dY.isNegative) or (HHGear^.Y > -_256) then
        HHGear^.dY:= HHGear^.dY - move;
    HHGear^.dY:= HHGear^.dY - move;
    dec(Gear^.Health, fuel);
    Gear^.MsgParam:= Gear^.MsgParam or gm_Up;
    Gear^.Timer:= GameTicks
    end;
if (HHGear^.Message and gm_Left) <> 0 then move.isNegative:= true;
if (HHGear^.Message and (gm_Left or gm_Right)) <> 0 then
    begin
    HHGear^.dX:= HHGear^.dX + (move * _0_2);
    dec(Gear^.Health, fuel div 5);
    Gear^.MsgParam:= Gear^.MsgParam or (HHGear^.Message and (gm_Left or gm_Right));
    Gear^.Timer:= GameTicks
    end;

// erases them all at once :-/
if (Gear^.Timer <> 0) and (GameTicks - Gear^.Timer > 250) then
    begin
    Gear^.Timer:= 0;
    Gear^.MsgParam:= 0
    end;

if Gear^.Health < 0 then Gear^.Health:= 0;
if (GameTicks and $3F) = 0 then
       begin
//AddCaption('Fuel: '+inttostr(round(Gear^.Health/20))+'%', cWhiteColor, capgrpAmmostate);
       if Gear^.Tex <> nil then FreeTexture(Gear^.Tex);
       Gear^.Tex:= RenderStringTex(trmsg[sidFuel] + ': ' + inttostr(round(Gear^.Health / 20)) + '%', cWhiteColor, fntSmall)
       end;

if HHGear^.Message and (gm_Attack or gm_Up or gm_Precise or gm_Left or gm_Right) <> 0 then Gear^.State:= Gear^.State and not gsttmpFlag;
HHGear^.Message:= HHGear^.Message and not (gm_Up or gm_Precise or gm_Left or gm_Right);
HHGear^.State:= HHGear^.State or gstMoving;

Gear^.X:= HHGear^.X;
Gear^.Y:= HHGear^.Y;
// For some reason I need to reapply followgear here, something else grabs it otherwise.
if not bShowAmmoMenu then FollowGear:= HHGear;

if ((Gear^.State and gsttmpFlag) = 0) or (HHGear^.dY < _0) then doStepHedgehogMoving(HHGear);

if  (Gear^.Health = 0)
    or (HHGear^.Damage <> 0)
    or CheckGearDrowning(HHGear)
    or (TurnTimeLeft = 0)
    // allow brief ground touches - to be fair on this, might need another counter
    or (((GameTicks and $1FF) = 0) and (not HHGear^.dY.isNegative) and TestCollisionYwithGear(HHGear, 1))
    or ((Gear^.Message and gm_Attack) <> 0) then
    begin
    with HHGear^ do
        begin
        Message:= 0;
        Active:= true;
        State:= State or gstMoving
        end;
    DeleteGear(Gear);
    isCursorVisible:= false;
//    if Gear^.Tex <> nil then FreeTexture(Gear^.Tex);
//    Gear^.Tex:= RenderStringTex(trmsg[sidFuel] + ': ' + inttostr(round(Gear^.Health / 20)) + '%', cWhiteColor, fntSmall)
    //AddCaption(trmsg[sidFuel]+': '+inttostr(round(Gear^.Health/20))+'%', cWhiteColor, capgrpAmmostate);
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepJetpack(Gear: PGear);
var HHGear: PGear;
begin
Gear^.doStep:= @doStepJetpackWork;

HHGear:= PHedgehog(Gear^.Hedgehog)^.Gear;
FollowGear:= HHGear;
OnUsedAmmo(PHedgehog(HHGear^.Hedgehog)^);
ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^);
with HHGear^ do
    begin
    State:= State and not gstAttacking;
    Message:= Message and not (gm_Attack or gm_Up or gm_Precise or gm_Left or gm_Right);
    if (dY < _0_1) and (dY > -_0_1) then
        begin
        Gear^.State:= Gear^.State or gsttmpFlag;
        dY:= dY - _0_2
        end
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBirdyVanish(Gear: PGear);
begin
Gear^.Pos:= 0;
if Gear^.Timer < 500 then
    inc(Gear^.Timer, 1)
else
    DeleteGear(Gear);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBirdyFly(Gear: PGear);
var HHGear: PGear;
    fuel: LongInt;
    move: hwFloat;
begin
HHGear:= CurrentHedgehog^.Gear;

move:= _0_1;
fuel:= 50;

if Gear^.Pos > 0 then
    dec(Gear^.Pos, 1)
else if (HHGear^.Message and (gm_Left or gm_Right or gm_Up)) <> 0 then
    Gear^.Pos:= 500;

if HHGear^.dX.isNegative then
    Gear^.Tag:= -1
else
    Gear^.Tag:= 1;

if (HHGear^.Message and gm_Up) <> 0 then
    begin
    if (not HHGear^.dY.isNegative) or (HHGear^.Y > -_256) then
        HHGear^.dY:= HHGear^.dY - move;
    HHGear^.dY:= HHGear^.dY - move;
    dec(Gear^.Health, fuel);
    Gear^.MsgParam:= Gear^.MsgParam or gm_Up;
    end;
if (HHGear^.Message and gm_Left) <> 0 then move.isNegative:= true;
if (HHGear^.Message and (gm_Left or gm_Right)) <> 0 then
    begin
    HHGear^.dX:= HHGear^.dX + (move * _0_2);
    dec(Gear^.Health, fuel div 5);
    Gear^.MsgParam:= Gear^.MsgParam or (HHGear^.Message and (gm_Left or gm_Right));
    end;

if Gear^.Health < 0 then Gear^.Health:= 0;
if (GameTicks and $3F) = 0 then
       begin
       if Gear^.Tex <> nil then FreeTexture(Gear^.Tex);
       Gear^.Tex:= RenderStringTex(trmsg[sidFuel] + ': ' + inttostr(round(Gear^.Health / 20)) + '%', cWhiteColor, fntSmall)
       end;

if (HHGear^.Message and gm_Attack <> 0) then begin
        HHGear^.Message := HHGear^.Message and not gm_Attack;
		if Gear^.FlightTime > 0 then begin
			AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtEgg, 0, Gear^.dX * _0_5, Gear^.dY, 0);
			dec(Gear^.FlightTime)
		end;
end;

if HHGear^.Message and (gm_Up or gm_Precise or gm_Left or gm_Right) <> 0 then Gear^.State:= Gear^.State and not gsttmpFlag;
HHGear^.Message:= HHGear^.Message and not (gm_Up or gm_Precise or gm_Left or gm_Right);
HHGear^.State:= HHGear^.State or gstMoving;

Gear^.X:= HHGear^.X;
Gear^.Y:= HHGear^.Y - int2hwFloat(32);
// For some reason I need to reapply followgear here, something else grabs it otherwise.
if not bShowAmmoMenu then FollowGear:= HHGear;

if ((Gear^.State and gsttmpFlag) = 0) or (HHGear^.dY < _0) then doStepHedgehogMoving(HHGear);

if  (Gear^.Health = 0)
    or (HHGear^.Damage <> 0)
    or CheckGearDrowning(HHGear)
    or (TurnTimeLeft = 0)
    // allow brief ground touches - to be fair on this, might need another counter
    or (((GameTicks and $1FF) = 0) and (not HHGear^.dY.isNegative) and TestCollisionYwithGear(HHGear, 1))
    or ((Gear^.Message and gm_Attack) <> 0) then
    begin
    with HHGear^ do
        begin
        Message:= 0;
        Active:= true;
        State:= State or gstMoving
        end;
    Gear^.doStep:= @doStepBirdyVanish;
    isCursorVisible:= false;
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBirdyDescend(Gear: PGear);
var HHGear: PGear;
begin
AllInactive:= false;
if Gear^.Timer > 0 then
    dec(Gear^.Timer, 1)
else if CurrentHedgehog = nil then
    begin
    Gear^.doStep:= @doStepBirdyVanish;
    exit
    end;
HHGear:= CurrentHedgehog^.Gear;
HHGear^.Message:= HHGear^.Message and not (gm_Up or gm_Precise or gm_Left or gm_Right);
if abs(hwRound(HHGear^.Y - Gear^.Y)) > 32 then
    begin
    if Gear^.Timer = 0 then
        Gear^.Y:= Gear^.Y + _0_1
    end
else if Gear^.Timer = 0 then
    begin
    Gear^.doStep:= @doStepBirdyFly;
    HHGear^.dY:= -_0_2
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBirdy(Gear: PGear);
var HHGear: PGear;
begin
Gear^.doStep:= @doStepBirdyDescend;
if CurrentHedgehog = nil then
    begin
    DeleteGear(Gear);
    exit
    end;

HHGear:= CurrentHedgehog^.Gear;

if HHGear^.dX.isNegative then
    Gear^.Tag:= -1
else
    Gear^.Tag:= 1;
Gear^.Pos:= 0;
AllInactive:= false;
FollowGear:= HHGear;
OnUsedAmmo(PHedgehog(HHGear^.Hedgehog)^);
ApplyAmmoChanges(PHedgehog(HHGear^.Hedgehog)^);
with HHGear^ do
    begin
    State:= State and not gstAttacking;
    Message:= Message and not (gm_Attack or gm_Up or gm_Precise or gm_Left or gm_Right)
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBigExplosionWork(Gear: PGear);
var maxMovement: LongInt;
begin
inc(Gear^.Timer);
if (Gear^.Timer and 5) = 0 then
    begin
    maxMovement := max(1, 13 - ((Gear^.Timer * 15) div 250));
    ShakeCamera(maxMovement);
    end;
if Gear^.Timer > 250 then DeleteGear(Gear);
end;

procedure doStepBigExplosion(Gear: PGear);
var i: LongWord;
begin
AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtSmokeRing);
for i:= 0 to 46 do AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtFire);
for i:= 0 to 15 do AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtExplPart);
for i:= 0 to 15 do AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtExplPart2);
Gear^.doStep:= @doStepBigExplosionWork
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepEggWork(Gear: PGear);
begin
	AllInactive:= false;
	Gear^.dX:= Gear^.dX + cWindSpeed;
	doStepFallingGear(Gear);
	if (Gear^.State and gstCollision) <> 0 then
	begin
		doMakeExplosion(hwRound(Gear^.X), hwRound(Gear^.Y), 25, EXPLAutoSound);
		DeleteGear(Gear);
		exit
	end;
	if (GameTicks and $3F) = 0 then
		AddGear(hwRound(Gear^.X), hwRound(Gear^.Y), gtSmokeTrace, 0, _0, _0, 0)
end;

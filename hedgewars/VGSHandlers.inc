(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2010 Andrey Korotaev <unC0Rr@gmail.com>
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
procedure doStepFlake(Gear: PVisualGear; Steps: Longword);
var sign: float;
begin
if vobCount = 0 then exit;

sign:= 1;
with Gear^ do
    begin
    inc(FrameTicks, Steps);
    if FrameTicks > vobFrameTicks then
        begin
        dec(FrameTicks, vobFrameTicks);
        inc(Frame);
        if Frame = vobFramesCount then Frame:= 0
        end;
    X:= X + (cWindSpeedf * 200 + dX + tdX) * Steps;
    Y:= Y + (dY + tdY + cGravityf * vobFallSpeed) * Steps;
    Angle:= Angle + dAngle * Steps;
    if Angle > 360 then
        Angle:= Angle - 360
    else
        if Angle < - 360 then
            Angle:= Angle + 360;
    
  
    if (round(X) >= cLeftScreenBorder) and
       (round(X) <= cRightScreenBorder) and
       (round(Y) - 75 <= LAND_HEIGHT) and
       (Timer > 0) and (Timer-Steps > 0) then
        begin
        if tdX > 0 then sign := 1
        else sign:= -1;
        tdX:= tdX - 0.005*Steps*sign;
        if ((sign < 0) and (tdX > 0)) or ((sign > 0) and (tdX < 0)) then tdX:= 0;
        if tdX > 0 then sign := 1
        else sign:= -1;
        tdY:= tdY - 0.005*Steps*sign;
        if ((sign < 0) and (tdY > 0)) or ((sign > 0) and (tdY < 0)) then tdY:= 0;
        dec(Timer, Steps)
        end
    else
        begin
        if round(X) < cLeftScreenBorder then X:= X + cScreenSpace else
        if round(X) > cRightScreenBorder then X:= X - cScreenSpace;
        // if round(Y) < (LAND_HEIGHT - 1024 - 75) then Y:= Y + float(25); // For if flag is set for flakes rising upwards?
        if round(Y) - 75 > LAND_HEIGHT then Y:= Y - float(1024 + 150); // TODO - configure in theme (jellies for example could use limited range)
        Timer:= 0;
        tdX:= 0;
        tdY:= 0
        end;
    end;

end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBeeTrace(Gear: PVisualGear; Steps: Longword);
begin
if Gear^.FrameTicks > Steps then
    dec(Gear^.FrameTicks, Steps)
else
    DeleteVisualGear(Gear);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepCloud(Gear: PVisualGear; Steps: Longword);
var s: Longword;
    t: float;
begin
Gear^.X:= Gear^.X + (cWindSpeedf * 750 * Gear^.dX) * Steps;

// up-and-down-bounce magic
s := (GameTicks + Gear^.Timer) mod 4096;
t := 8 * AngleSin(s mod 2048).QWordValue / 4294967296;
if (s < 2048) then t := -t;

Gear^.Y := LAND_HEIGHT - 1184 + LongInt(Gear^.Timer mod 8) + t;

if round(Gear^.X) < cLeftScreenBorder then Gear^.X:= Gear^.X + cScreenSpace else
if round(Gear^.X) > cRightScreenBorder then Gear^.X:= Gear^.X - cScreenSpace
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepExpl(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
//Gear^.dY:= Gear^.dY + cGravityf;

if Gear^.FrameTicks <= Steps then
    if Gear^.Frame = 0 then DeleteVisualGear(Gear)
    else
        begin
        dec(Gear^.Frame);
        Gear^.FrameTicks:= cExplFrameTicks
        end
    else dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepNote(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps / 2;

Gear^.Angle:= Gear^.Angle + (Gear^.Frame + 1) * Steps / 10;
while Gear^.Angle > cMaxAngle do
    Gear^.Angle:= Gear^.Angle - cMaxAngle;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepLineTrail(Gear: PVisualGear; Steps: Longword);
begin
Steps := Steps;
if Gear^.Timer <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.Timer, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepEgg(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps;

Gear^.Angle:= round(Gear^.Angle + Steps) mod cMaxAngle;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFire(Gear: PVisualGear; Steps: Longword);
var vgt: PVisualGear;
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;// + cGravityf * (Steps * Steps);
if (Gear^.State and gstTmpFlag) = 0 then
    begin
    Gear^.dY:= Gear^.dY + cGravityf * Steps;
    if ((GameTicks mod 200) < Steps + 1) then
        begin
        vgt:= AddVisualGear(round(Gear^.X), round(Gear^.Y), vgtFire);
        if vgt <> nil then
            begin
            vgt^.dx:= 0;
            vgt^.dy:= 0;
            vgt^.State:= gstTmpFlag;
            end;
        end
    end
else
    inc(Steps, Steps);

if Gear^.FrameTicks <= Steps then
       DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepShell(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps;

Gear^.Angle:= round(Gear^.Angle + Steps) mod cMaxAngle;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

procedure doStepSmallDamage(Gear: PVisualGear; Steps: Longword);
begin
Gear^.Y:= Gear^.Y - 0.02 * Steps;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBubble(Gear: PVisualGear; Steps: Longword);
begin
    Gear^.X:= Gear^.X + Gear^.dX * Steps;
    Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
    Gear^.Y:= Gear^.Y - cDrownSpeedf * Steps;

    Gear^.dX := Gear^.dX / (1.001 * Steps);
    Gear^.dY := Gear^.dY / (1.001 * Steps);

    if (Gear^.FrameTicks <= Steps) or (round(Gear^.Y) < cWaterLine) then
        DeleteVisualGear(Gear)
    else
        dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHealth(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;
Gear^.Y:= Gear^.Y - Gear^.dY * Steps;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSteam(Gear: PVisualGear; Steps: Longword);
begin
    Gear^.X:= Gear^.X + (cWindSpeedf * 100 + Gear^.dX) * Steps;
    Gear^.Y:= Gear^.Y - cDrownSpeedf * Steps;

    if Gear^.FrameTicks <= Steps then
        if Gear^.Frame = 0 then DeleteVisualGear(Gear)
        else
            begin
            if Random(2) = 0 then dec(Gear^.Frame);
            Gear^.FrameTicks:= cExplFrameTicks
            end
        else dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepAmmo(Gear: PVisualGear; Steps: Longword);
begin
    Gear^.Y:= Gear^.Y - cDrownSpeedf * Steps;

    Gear^.scale:= Gear^.scale + 0.0025 * Steps;
    Gear^.alpha:= Gear^.alpha - 0.0015 * Steps;

    if Gear^.alpha < 0 then DeleteVisualGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmoke(Gear: PVisualGear; Steps: Longword);
begin
    Gear^.X:= Gear^.X + (cWindSpeedf + Gear^.dX) * Steps;
    Gear^.Y:= Gear^.Y - (cDrownSpeedf + Gear^.dY) * Steps;

    Gear^.dX := Gear^.dX + (cWindSpeedf * 0.3 * Steps);
    //Gear^.dY := Gear^.dY - (cDrownSpeedf * 0.995);

    if Gear^.FrameTicks <= Steps then
        if Gear^.Frame = 0 then DeleteVisualGear(Gear)
        else
            begin
            if Random(2) = 0 then dec(Gear^.Frame);
            Gear^.FrameTicks:= cExplFrameTicks
            end
        else dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDust(Gear: PVisualGear; Steps: Longword);
begin
    Gear^.X:= Gear^.X + (cWindSpeedf + (cWindSpeedf * 0.03 * Steps) + Gear^.dX) * Steps;
    Gear^.Y:= Gear^.Y - (Gear^.dY) * Steps;

    Gear^.dX := Gear^.dX - (Gear^.dX * 0.005 * Steps);
    Gear^.dY := Gear^.dY - (cDrownSpeedf * 0.001 * Steps);

    if Gear^.FrameTicks <= Steps then
        if Gear^.Frame = 0 then DeleteVisualGear(Gear)
        else
            begin
            dec(Gear^.Frame);
            Gear^.FrameTicks:= cExplFrameTicks
            end
        else dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSplash(Gear: PVisualGear; Steps: Longword);
begin
  if Gear^.FrameTicks <= Steps then
      DeleteVisualGear(Gear)
  else
      dec(Gear^.FrameTicks, Steps);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepDroplet(Gear: PVisualGear; Steps: Longword);
begin
  Gear^.X:= Gear^.X + Gear^.dX * Steps;

  Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
  Gear^.dY:= Gear^.dY + cGravityf * Steps;

  if round(Gear^.Y) > cWaterLine then begin
    DeleteVisualGear(Gear);
    PlaySound(TSound(ord(sndDroplet1) + Random(3)));
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmokeRing(Gear: PVisualGear; Steps: Longword);
begin
inc(Gear^.Timer, Steps);
if Gear^.Timer >= Gear^.FrameTicks then DeleteVisualGear(Gear)
else
    begin
    Gear^.scale := 1.25 * (-power(2, -10 * Int(Gear^.Timer)/Gear^.FrameTicks) + 1) + 0.4;
    Gear^.alpha := 1 - power(Gear^.Timer / 350, 4);
    if Gear^.alpha < 0 then Gear^.alpha:= 0;
    end;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFeather(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps;

Gear^.Angle:= round(Gear^.Angle + Steps) mod cMaxAngle;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
const cSorterWorkTime = 640;
var thexchar: array[0..cMaxTeams] of
            record
            dy, ny, dw: LongInt;
            team: PTeam;
            SortFactor: QWord;
            end;
    currsorter: PVisualGear = nil;

procedure doStepTeamHealthSorterWork(Gear: PVisualGear; Steps: Longword);
var i, t: LongInt;
begin
for t:= 1 to Steps do
    begin
    dec(Gear^.Timer);
    if (Gear^.Timer and 15) = 0 then
        for i:= 0 to Pred(TeamsCount) do
            with thexchar[i] do
                begin
                {$WARNINGS OFF}
                team^.DrawHealthY:= ny + dy * LongInt(Gear^.Timer) div 640;
                team^.TeamHealthBarWidth:= team^.NewTeamHealthBarWidth + dw * LongInt(Gear^.Timer) div cSorterWorkTime;
                {$WARNINGS ON}
                end;

    if (Gear^.Timer = 0) or (currsorter <> Gear) then
        begin
        if currsorter = Gear then currsorter:= nil;
        DeleteVisualGear(Gear);
        exit
        end
    end
end;

procedure doStepTeamHealthSorter(Gear: PVisualGear; Steps: Longword);
var i: Longword;
    b: boolean;
    t: LongInt;
begin
Steps:= Steps; // avoid compiler hint
for t:= 0 to Pred(TeamsCount) do
    with thexchar[t] do
        begin
        dy:= TeamsArray[t]^.DrawHealthY;
        dw:= TeamsArray[t]^.TeamHealthBarWidth - TeamsArray[t]^.NewTeamHealthBarWidth;
        team:= TeamsArray[t];
        SortFactor:= TeamsArray[t]^.Clan^.ClanHealth;
        SortFactor:= (SortFactor shl  3) + TeamsArray[t]^.Clan^.ClanIndex;
        SortFactor:= (SortFactor shl 30) + TeamsArray[t]^.TeamHealth;
        end;

if TeamsCount > 1 then
    repeat
    b:= true;
    for t:= 0 to TeamsCount - 2 do
        if (thexchar[t].SortFactor > thexchar[Succ(t)].SortFactor) then
            begin
            thexchar[cMaxTeams]:= thexchar[t];
            thexchar[t]:= thexchar[Succ(t)];
            thexchar[Succ(t)]:= thexchar[cMaxTeams];
            b:= false
            end
    until b;

t:= - 4;
for i:= 0 to Pred(TeamsCount) do
    with thexchar[i] do
        begin
        dec(t, team^.HealthTex^.h + 2);
        ny:= t;
        dy:= dy - ny
        end;

Gear^.Timer:= cSorterWorkTime;
Gear^.doStep:= @doStepTeamHealthSorterWork;
currsorter:= Gear;
//doStepTeamHealthSorterWork(Gear, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSpeechBubbleWork(Gear: PVisualGear; Steps: Longword);
begin
if Gear^.Timer > Steps then dec(Gear^.Timer, Steps) else Gear^.Timer:= 0;

if (Gear^.Hedgehog^.Gear <> nil) then
    begin
    Gear^.X:= Gear^.Hedgehog^.Gear^.X.QWordValue/4294967296 + (Gear^.Tex^.w div 2  - Gear^.FrameTicks);
    Gear^.Y:= Gear^.Hedgehog^.Gear^.Y.QWordValue/4294967296 - (16 + Gear^.Tex^.h);
    end;

if Gear^.Timer = 0 then
    begin
    if Gear^.Hedgehog^.SpeechGear = Gear then
        Gear^.Hedgehog^.SpeechGear:= nil;
    DeleteVisualGear(Gear)
    end;
end;

procedure doStepSpeechBubble(Gear: PVisualGear; Steps: Longword);
begin
Steps:= Steps; // avoid compiler hint

with Gear^.Hedgehog^ do
    if SpeechGear <> nil then SpeechGear^.Timer:= 0;

Gear^.Hedgehog^.SpeechGear:= Gear;

Gear^.Timer:= max(Length(Gear^.Text) * 150, 3000);

Gear^.Tex:= RenderSpeechBubbleTex(Gear^.Text, Gear^.FrameTicks, fnt16);

case Gear^.FrameTicks of
    1: Gear^.FrameTicks:= SpritesData[sprSpeechTail].Width-28;
    2: Gear^.FrameTicks:= SpritesData[sprThoughtTail].Width-20;
    3: Gear^.FrameTicks:= SpritesData[sprShoutTail].Width-10;
    end;

Gear^.doStep:= @doStepSpeechBubbleWork;

Gear^.Y:= Gear^.Y - float(Gear^.Tex^.h)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHealthTagWork(Gear: PVisualGear; Steps: Longword);
begin
if Steps > Gear^.Timer then
    DeleteVisualGear(Gear)
else
    begin
    dec(Gear^.Timer, Steps);
    Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
    end;
end;

procedure doStepHealthTagWorkUnderWater(Gear: PVisualGear; Steps: Longword);
begin
if round(Gear^.Y) - 10 < cWaterLine then
    DeleteVisualGear(Gear)
else
    Gear^.Y:= Gear^.Y - 0.08 * Steps;

end;

procedure doStepHealthTag(Gear: PVisualGear; Steps: Longword);
var s: shortstring;
begin
s:= '';

Gear^.dY:= -0.08;

str(Gear^.State, s);
if Gear^.Hedgehog <> nil then
    Gear^.Tex:= RenderStringTex(s, Gear^.Hedgehog^.Team^.Clan^.Color, fnt16)
else
    Gear^.Tex:= RenderStringTex(s, cWhiteColor, fnt16);

if round(Gear^.Y) < cWaterLine then
    Gear^.doStep:= @doStepHealthTagWork
else
    Gear^.doStep:= @doStepHealthTagWorkUnderWater;

Gear^.Y:= Gear^.Y - float(Gear^.Tex^.h);

if Steps > 1 then Gear^.doStep(Gear, Steps-1);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmokeTrace(Gear: PVisualGear; Steps: Longword);
begin
inc(Gear^.Timer, Steps );
if Gear^.Timer > 64 then
    begin
    if Gear^.State = 0 then
      begin
      DeleteVisualGear(Gear);
      exit;
      end;
    dec(Gear^.State, Gear^.Timer div 65);
    Gear^.Timer:= Gear^.Timer mod 65;
    end;
Gear^.dX:= Gear^.dX + cWindSpeedf * Steps;
Gear^.X:= Gear^.X + Gear^.dX;
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepExplosionWork(Gear: PVisualGear; Steps: Longword);
begin
inc(Gear^.Timer, Steps);
if Gear^.Timer > 75 then
    begin
    inc(Gear^.State, Gear^.Timer div 76);
    Gear^.Timer:= Gear^.Timer mod 76;
    if Gear^.State > 5 then DeleteVisualGear(Gear);
    end;
end;

procedure doStepExplosion(Gear: PVisualGear; Steps: Longword);
var i: LongWord;
gX,gY: LongInt;
begin
gX:= round(Gear^.X);
gY:= round(Gear^.Y);
for i:= 0 to 31 do AddVisualGear(gX, gY, vgtFire);
for i:= 0 to  8 do AddVisualGear(gX, gY, vgtExplPart);
for i:= 0 to  8 do AddVisualGear(gX, gY, vgtExplPart2);
Gear^.doStep:= @doStepExplosionWork;
if Steps > 1 then Gear^.doStep(Gear, Steps-1);
end;


////////////////////////////////////////////////////////////////////////////////
procedure doStepBigExplosionWork(Gear: PVisualGear; Steps: Longword);
//var maxMovement: LongInt;
begin

inc(Gear^.Timer, Steps);
(*
FIXME - This block desyncs due to the way WorldDx is important for various things network related.
One possible solution is, instead of using WorldDx, to use straight gl/SDL calls to jitter the screen a bit.
if (Gear^.Timer and 5) = 0 then
    begin
    maxMovement := max(1, 13 - ((Gear^.Timer * 15) div 250));
    ShakeCamera(maxMovement);
    end;
*)
if Gear^.Timer > 250 then DeleteVisualGear(Gear);
end;

procedure doStepBigExplosion(Gear: PVisualGear; Steps: Longword);
var i: LongWord;
gX,gY: LongInt;
begin
gX:= round(Gear^.X);
gY:= round(Gear^.Y);
AddVisualGear(gX, gY, vgtSmokeRing);
for i:= 0 to 46 do AddVisualGear(gX, gY, vgtFire);
for i:= 0 to 15 do AddVisualGear(gX, gY, vgtExplPart);
for i:= 0 to 15 do AddVisualGear(gX, gY, vgtExplPart2);
Gear^.doStep:= @doStepBigExplosionWork;
if Steps > 1 then Gear^.doStep(Gear, Steps-1);
performRumble();
end;

procedure doStepChunk(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravityf * Steps;

Gear^.Angle:= round(Gear^.Angle + Steps) mod cMaxAngle;

if round(Gear^.Y) > cWaterLine then
    begin
    AddVisualGear(round(Gear^.X), round(Gear^.Y), vgtDroplet);
    DeleteVisualGear(Gear);
    end
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBulletHit(Gear: PVisualGear; Steps: Longword);
begin
  if Gear^.FrameTicks <= Steps then
      DeleteVisualGear(Gear)
  else
      dec(Gear^.FrameTicks, Steps);
end;

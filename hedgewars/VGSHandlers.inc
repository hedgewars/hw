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
var sign: hwFloat;
begin
sign:= _1;
with Gear^ do
    begin
    inc(FrameTicks, Steps);
    if FrameTicks > vobFrameTicks then
        begin
        dec(FrameTicks, vobFrameTicks);
        inc(Frame);
        if Frame = vobFramesCount then Frame:= 0
        end;
    X:= X + (cWindSpeed * 200 + dX + tdX) * Steps;
    Y:= Y + (dY + tdY + cGravity * vobFallSpeed) * Steps;
    Angle:= Angle + dAngle * Steps;
  
    if (hwRound(X) >= -cScreenWidth - 64) and
       (hwRound(X) <= cScreenWidth + LAND_WIDTH) and
       (hwRound(Y) <= (LAND_HEIGHT + 75)) and 
       (Timer > 0) and (Timer-Steps > 0) then
        begin
        sign.isNegative:=tdX.isNegative;
        tdX:= tdX - _0_005*Steps*sign;
        if (sign.isNegative and (tdX > _0)) or (not sign.isNegative and (tdX < _0)) then tdX:= _0;
        sign.isNegative:=tdY.isNegative;
        tdY:= tdY - _0_005*Steps*sign;
        if (sign.isNegative and (tdY > _0)) or (not sign.isNegative and (tdY < _0)) then tdY:= _0;
        dec(Timer, Steps)
        end
    else
        begin
        if hwRound(X) < -cScreenWidth - 64 then X:= int2hwFloat(cScreenWidth + LAND_WIDTH) else
        if hwRound(X) > cScreenWidth + LAND_WIDTH then X:= int2hwFloat(-cScreenWidth - 64);
        // if hwRound(Y) < (LAND_HEIGHT - 1024 - 75) then Y:= Y + int2hwFloat(25); // For if flag is set for flakes rising upwards?
        if hwRound(Y) > (LAND_HEIGHT + 75) then Y:= Y - int2hwFloat(1024 + 150); // TODO - configure in theme (jellies for example could use limited range)
        Timer:= 0;
        tdX:= _0;
        tdY:= _0
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
var i: Longword;
begin
Gear^.X:= Gear^.X + (cWindSpeed * 200 + Gear^.dX) * Steps;

for i:= 0 to Steps - 1 do
    begin
    if hwRound(Gear^.Y) > LAND_HEIGHT-1184 then // TODO - configure in theme
        Gear^.dY:= Gear^.dY - _1div50000
    else
        Gear^.dY:= Gear^.dY + _1div50000;

    Gear^.Y:= Gear^.Y + Gear^.dY
    end;

if hwRound(Gear^.X) < -cScreenWidth - 256 then Gear^.X:= int2hwFloat(cScreenWidth + LAND_WIDTH) else
if hwRound(Gear^.X) > cScreenWidth + LAND_WIDTH then Gear^.X:= int2hwFloat(-cScreenWidth - 256)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepExpl(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
//Gear^.dY:= Gear^.dY + cGravity;

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
procedure doStepEgg(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
Gear^.dY:= Gear^.dY + cGravity * Steps;

Gear^.Angle:= round(Gear^.Angle + Steps) mod cMaxAngle;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepFire(Gear: PVisualGear; Steps: Longword);
begin
Gear^.X:= Gear^.X + Gear^.dX * Steps;

Gear^.Y:= Gear^.Y + Gear^.dY * Steps;// + cGravity * (Steps * Steps);
Gear^.dY:= Gear^.dY + cGravity * Steps;

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
Gear^.dY:= Gear^.dY + cGravity * Steps;

Gear^.Angle:= round(Gear^.Angle + Steps) mod cMaxAngle;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

procedure doStepSmallDamage(Gear: PVisualGear; Steps: Longword);
begin
Gear^.Y:= Gear^.Y - _0_02 * Steps;

if Gear^.FrameTicks <= Steps then
    DeleteVisualGear(Gear)
else
    dec(Gear^.FrameTicks, Steps)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepBubble(Gear: PVisualGear; Steps: Longword);
begin
    Gear^.X:= Gear^.X + (cWindSpeed * 100 + Gear^.dX) * Steps;
    Gear^.Y:= Gear^.Y - cDrownSpeed * Steps;

    if (Gear^.FrameTicks <= Steps) or (hwRound(Gear^.Y) < cWaterLine) then
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
    Gear^.X:= Gear^.X + (cWindSpeed * 100 + Gear^.dX) * Steps;
    Gear^.Y:= Gear^.Y - cDrownSpeed * Steps;

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
    Gear^.Y:= Gear^.Y - cDrownSpeed * Steps;

    Gear^.scale:= Gear^.scale + 0.0025 * Steps;
    Gear^.alpha:= Gear^.alpha - 0.0015 * Steps;

    if Gear^.alpha < 0 then DeleteVisualGear(Gear)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmoke(Gear: PVisualGear; Steps: Longword);
begin
    Gear^.X:= Gear^.X + (cWindSpeed + Gear^.dX) * Steps;
    Gear^.Y:= Gear^.Y - (cDrownSpeed + Gear^.dY) * Steps;

    Gear^.dX := Gear^.dX + (cWindSpeed * _0_3 * Steps);
    //Gear^.dY := Gear^.dY - (cDrownSpeed * _0_995);

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
    Gear^.X:= Gear^.X + (cWindSpeed + (cWindSpeed * _0_03 * Steps) + Gear^.dX) * Steps;
    Gear^.Y:= Gear^.Y - (Gear^.dY) * Steps;

    Gear^.dX := Gear^.dX - (Gear^.dX * _0_005 * Steps);
    Gear^.dY := Gear^.dY - (cDrownSpeed * _0_001 * Steps);

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
  Gear^.dY:= Gear^.dY + cGravity * Steps;

  if hwRound(Gear^.Y) > cWaterLine then begin
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
Gear^.dY:= Gear^.dY + cGravity * Steps;

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

if (PHedgehog(Gear^.Hedgehog)^.Gear <> nil) then
    begin
    Gear^.X:= PHedgehog(Gear^.Hedgehog)^.Gear^.X + int2hwFloat(Gear^.Tex^.w div 2  - Gear^.FrameTicks);
    Gear^.Y:= PHedgehog(Gear^.Hedgehog)^.Gear^.Y - int2hwFloat(16 + Gear^.Tex^.h);
    end;

if Gear^.Timer = 0 then
    begin
    if PHedgehog(Gear^.Hedgehog)^.SpeechGear = Gear then
        PHedgehog(Gear^.Hedgehog)^.SpeechGear:= nil;
    DeleteVisualGear(Gear)
    end;
end;

procedure doStepSpeechBubble(Gear: PVisualGear; Steps: Longword);
begin
Steps:= Steps; // avoid compiler hint

with PHedgehog(Gear^.Hedgehog)^ do
    if SpeechGear <> nil then SpeechGear^.Timer:= 0;

PHedgehog(Gear^.Hedgehog)^.SpeechGear:= Gear;

Gear^.Timer:= max(Length(Gear^.Text) * 150, 3000);

Gear^.Tex:= RenderSpeechBubbleTex(Gear^.Text, Gear^.FrameTicks, fnt16);

case Gear^.FrameTicks of
    1: Gear^.FrameTicks:= SpritesData[sprSpeechTail].Width-28;
    2: Gear^.FrameTicks:= SpritesData[sprThoughtTail].Width-20;
    3: Gear^.FrameTicks:= SpritesData[sprShoutTail].Width-10;
    end;

Gear^.doStep:= @doStepSpeechBubbleWork;

Gear^.Y:= Gear^.Y - int2hwFloat(Gear^.Tex^.h)
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepHealthTagWork(Gear: PVisualGear; Steps: Longword);
begin
if Steps > Gear^.Timer then
    begin
    DeleteVisualGear(Gear);
    end
else
    begin
    dec(Gear^.Timer, Steps);
    Gear^.Y:= Gear^.Y + Gear^.dY * Steps;
    end;
end;

procedure doStepHealthTagWorkUnderWater(Gear: PVisualGear; Steps: Longword);
begin
if hwRound(Gear^.Y) < cWaterLine + 10 then
    DeleteVisualGear(Gear)
else
    Gear^.Y:= Gear^.Y - _0_08 * Steps;

end;

procedure doStepHealthTag(Gear: PVisualGear; Steps: Longword);
var s: shortstring;
begin
s:= '';

Gear^.dY:= -_0_08;

str(Gear^.State, s);
Gear^.Tex:= RenderStringTex(s, PHedgehog(Gear^.Hedgehog)^.Team^.Clan^.Color, fnt16);
// if you segfault here you probably added this healthtag directly
// maybe you should call spawnHealthTagForHH() in uGears.pas instead

if hwRound(Gear^.Y) < cWaterLine then
    Gear^.doStep:= @doStepHealthTagWork
else
    Gear^.doStep:= @doStepHealthTagWorkUnderWater;

Gear^.Y:= Gear^.Y - int2hwFloat(Gear^.Tex^.h);

if Steps > 1 then Gear^.doStep(Gear, Steps-1);
end;

////////////////////////////////////////////////////////////////////////////////
procedure doStepSmokeTrace(Gear: PVisualGear; Steps: Longword);
var i: Longword;
begin
inc(Gear^.Timer, Steps );
if Gear^.Timer > 64 then
    begin
    dec(Gear^.State, Gear^.Timer div 65);
    Gear^.Timer:= Gear^.Timer mod 65;
    end;
for i:= 1 to Steps do
    begin
    Gear^.dX:= Gear^.dX + cWindSpeed;
    Gear^.X:= Gear^.X + Gear^.dX;
    end;
if Gear^.State = 0 then DeleteVisualGear(Gear);
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
begin

for i:= 0 to 31 do AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtFire);
for i:= 0 to 8 do AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtExplPart);
for i:= 0 to 8 do AddVisualGear(hwRound(Gear^.X), hwRound(Gear^.Y), vgtExplPart2);
Gear^.doStep:= @doStepExplosionWork;
if Steps > 1 then Gear^.doStep(Gear, Steps-1);
end;


////////////////////////////////////////////////////////////////////////////////
procedure doStepBigExplosionWork(Gear: PVisualGear; Steps: Longword);
var maxMovement: LongInt;
begin

inc(Gear^.Timer, Steps);
if (Gear^.Timer and 5) = 0 then
    begin
    maxMovement := max(1, 13 - ((Gear^.Timer * 15) div 250));
    ShakeCamera(maxMovement);
    end;
if Gear^.Timer > 250 then DeleteVisualGear(Gear);
end;

procedure doStepBigExplosion(Gear: PVisualGear; Steps: Longword);
var i: LongWord;
gX,gY: LongInt;
begin
gX:= hwRound(Gear^.X);
gY:= hwRound(Gear^.Y);
AddVisualGear(gX, gY, vgtSmokeRing);
for i:= 0 to 46 do AddVisualGear(gX, gY, vgtFire);
for i:= 0 to 15 do AddVisualGear(gX, gY, vgtExplPart);
for i:= 0 to 15 do AddVisualGear(gX, gY, vgtExplPart2);
Gear^.doStep:= @doStepBigExplosionWork;
if Steps > 1 then Gear^.doStep(Gear, Steps-1);
end;

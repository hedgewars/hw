(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005, 2006 Andrey Korotaev <unC0Rr@gmail.com>
 *
 * Distributed under the terms of the BSD-modified licence:
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * with the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 3. The name of the author may not be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

unit uWorld;
interface
uses SDLh, uGears;
{$INCLUDE options.inc}
const WorldDx: integer = -512;
      WorldDy: integer = -256;

procedure InitWorld;
procedure DrawWorld(Lag: integer; Surface: PSDL_Surface);
procedure AddCaption(s: shortstring; Color, Group: LongWord);
procedure MoveCamera;

{$IFDEF COUNTTICKS}
var cntTicks: LongWord;
{$ENDIF}
var FollowGear: PGear = nil;
    WindBarWidth: integer = 0;

implementation
uses uStore, uMisc, uConsts, uTeams, uIO;
const RealTicks: Longword = 0;
      Frames: Longword = 0;
      FPS: Longword = 0;
      CountTicks: Longword = 0;
      prevPoint: TPoint = (X: 0; Y: 0);
      
type TCaptionStr = record
                   r: TSDL_Rect;
                   StorePos,
                   Group,
                   EndTime: LongWord;
                   end;

var cWaterSprCount: integer;
    Captions: array[0..Pred(cMaxCaptions)] of TCaptionStr;

procedure InitWorld;
begin
cWaterSprCount:= 1 + cScreenWidth div (SpritesData[sprWater].Width);
cScreenEdgesDist:= Min(cScreenWidth div 4, cScreenHeight div 4);
SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
prevPoint.X:= cScreenWidth div 2;
prevPoint.Y:= cScreenHeight div 2;
WorldDx:=  - 1024 + cScreenWidth div 2;
WorldDy:=  - 512 + cScreenHeight div 2
end;

procedure DrawWorld(Lag: integer; Surface: PSDL_Surface);
var i, t: integer;
    r: TSDL_Rect;
    team: PTeam;
    tdx, tdy: real;

    procedure DrawRepeated(spr: TSprite; Shift: integer);
    var i, w: integer;
    begin
    w:= SpritesData[spr].Width;
    i:= Shift mod w;
    if i > 0 then dec(i, w);
    repeat
      DrawSprite(spr, i, WorldDy + 1024 - SpritesData[spr].Height, 0, Surface);
      inc(i, w)
    until i > cScreenWidth
    end;

begin
// Sky
inc(RealTicks, Lag);
r.h:= WorldDy;
if r.h > 0 then
   begin
   if r.h > cScreenHeight then r.h:= cScreenHeight;
   r.x:= 0;
   r.y:= 0;
   r.w:= cScreenWidth;
   SDL_FillRect(Surface, @r, cSkyColor)
   end;
// background
DrawRepeated(sprSky, WorldDx * 3 div 8);
DrawRepeated(sprHorizont, WorldDx * 3 div 5);

// Waves
{$WARNINGS OFF}
for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * 256  + ((WorldDx + (RealTicks shr 6)      ) and $FF), cWaterLine + WorldDy - 64, 0, Surface);
for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * 256  + ((WorldDx - (RealTicks shr 6) + 192) and $FF), cWaterLine + WorldDy - 48, 0, Surface);
{$WARNINGS ON}

DrawLand(WorldDx, WorldDy, Surface);
// Water
r.y:= WorldDy + cWaterLine + 32;
if r.y < cScreenHeight then
   begin
   if r.y < 0 then r.y:= 0;
   r.h:= cScreenHeight - r.y;
   r.x:= 0;
   r.w:= cScreenWidth;
   SDL_FillRect(Surface, @r, cWaterColor)
   end;

DrawGears(Surface);

team:= TeamsList;
while team<>nil do
      begin
      for i:= 0 to 7 do
          with team.Hedgehogs[i] do
               if Gear<>nil then
                  if Gear.State = 0 then
                     begin
                     DrawCaption( round(Gear.X) + WorldDx,
                                  round(Gear.Y) - cHHRadius - 30 + WorldDy,
                                  HealthRect, Surface, true);
                     DrawCaption( round(Gear.X) + WorldDx,
                                  round(Gear.Y) - cHHRadius - 54 + WorldDy,
                                  NameRect, Surface);
//                     DrawCaption( round(Gear.X) + WorldDx,
//                                  round(Gear.Y) - Gear.Radius - 60 + WorldDy,
//                                  Team.NameRect, Surface);
                     end else // Current hedgehog
                     begin
                     if (Gear.State and (gstMoving or gstDrowning or gstFalling)) = 0 then
                        if (Gear.State and gstHHThinking) <> 0 then
                           DrawGear(sQuestion, Round(Gear.X)  - 10 + WorldDx, Round(Gear.Y) - cHHRadius - 34 + WorldDy, Surface)
                        else
                        if ShowCrosshair and ((Gear.State and gstAttacked) = 0) then
                           DrawCaption(Round(Gear.X + Sign(Gear.dX) * Sin(Gear.Angle*pi/cMaxAngle)*60) + WorldDx,
                                       Round(Gear.Y - Cos(Gear.Angle*pi/cMaxAngle)*60) + WorldDy - 4,
                                       Team.CrossHairRect, Surface)
                     end;
      team:= team.Next
      end;

// Waves
{$WARNINGS OFF}
for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * 256  + ((WorldDx + (RealTicks shr 6) +  64) and $FF), cWaterLine + WorldDy - 32, 0, Surface);
for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * 256  + ((WorldDx - (RealTicks shr 6) + 128) and $FF), cWaterLine + WorldDy - 16, 0, Surface);
for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * 256  + ((WorldDx + (RealTicks shr 6)      ) and $FF), cWaterLine + WorldDy     , 0, Surface);
{$WARNINGS ON}

// Turn time
if TurnTimeLeft <> 0 then
   begin
   i:= Succ(Pred(TurnTimeLeft) div 1000);
   if i>99 then t:= 112
      else if i>9 then t:= 96
                  else t:= 80;
   DrawSprite(sprFrame, t, cScreenHeight - 48, 1, Surface);
   while i > 0 do
         begin
         dec(t, 32);
         DrawSprite(sprBigDigit, t, cScreenHeight - 48, i mod 10, Surface);
         i:= i div 10
         end;
   DrawSprite(sprFrame, t - 4, cScreenHeight - 48, 0, Surface);
   end;

// Attack bar
if CurrentTeam <> nil then
   case AttackBar of
        1: begin
           r:= StuffPoz[sPowerBar];
           {$WARNINGS OFF}
           r.w:= (CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog].Gear.Power * 256) div cPowerDivisor;
           {$WARNINGS ON}
           DrawSpriteFromRect(r, cScreenWidth - 272, cScreenHeight - 48, 16, 0, Surface);
           end;
        2: with CurrentTeam.Hedgehogs[CurrentTeam.CurrHedgehog] do
                begin
                tdx:= Sign(Gear.dX) * Sin(Gear.Angle*pi/cMaxAngle);
                tdy:= - Cos(Gear.Angle*pi/cMaxAngle);
                for i:= (Gear.Power * 24) div cPowerDivisor downto 0 do
                    DrawSprite(sprPower, round(Gear.X + WorldDx + tdx * (24 + i * 2)) - 16,
                                         round(Gear.Y + WorldDy + tdy * (24 + i * 2)) - 12,
                                         i, Surface)
                end
        end;

// Target
if TargetPoint.X <> NoPointX then DrawSprite(sprTargetP, TargetPoint.X + WorldDx - 16, TargetPoint.Y + WorldDy - 16, 0, Surface);

// Captions
i:= 0;
while (i < cMaxCaptions) do
    begin
    with Captions[i] do
         if EndTime > 0 then DrawCaption(cScreenWidth div 2, 8 + i * 32 + cConsoleYAdd, r, Surface, true);
    inc(i)
    end;
while (Captions[0].EndTime > 0) and (Captions[0].EndTime <= RealTicks) do
    begin
    for i:= 1 to Pred(cMaxCaptions) do
        Captions[Pred(i)]:= Captions[i];
    Captions[Pred(cMaxCaptions)].EndTime:= 0
    end;

// Teams Healths
team:= TeamsList;
while team <> nil do
      begin
      DrawFromStoreRect(cScreenWidth div 2 - team.NameRect.w - 3,
                        Team.DrawHealthY,
                        @team.NameRect, Surface);
      r:= team.HealthRect;
      r.w:= 3 + team.TeamHealth;
      DrawFromStoreRect(cScreenWidth div 2,
                        Team.DrawHealthY,
                        @r, Surface);
      inc(r.x, cTeamHealthWidth + 3);
      r.w:= 2;
      DrawFromStoreRect(cScreenWidth div 2 + team.TeamHealth + 3,
                        Team.DrawHealthY,
                        @r, Surface);
      team:= team.Next
      end;

// Lag alert
if isInLag then DrawSprite(sprLag, 32, 32  + cConsoleYAdd, (RealTicks shr 7) mod 7, Surface);

// Wind bar
DrawGear(sWindBar, cScreenWidth - 180, cScreenHeight - 30, Surface);
if WindBarWidth > 0 then
   begin
   with StuffPoz[sWindR] do
        begin
        {$WARNINGS OFF}
        r.x:= x + 8 - (RealTicks shr 6) mod 8;
        {$WARNINGS ON}
        r.y:= y;
        r.w:= WindBarWidth;
        r.h:= 13;
        end;
   DrawSpriteFromRect(r, cScreenWidth - 103, cScreenHeight - 28, 13, 0, Surface);
   end else
 if WindBarWidth < 0 then
   begin
   with StuffPoz[sWindL] do
        begin
        {$WARNINGS OFF}
        r.x:= x + (WindBarWidth + RealTicks shr 6) mod 8;
        {$WARNINGS ON}
        r.y:= y;
        r.w:= - WindBarWidth;
        r.h:= 13;
        end;
   DrawSpriteFromRect(r, cScreenWidth - 106 + WindBarWidth, cScreenHeight - 28, 13, 0, Surface);
   end;

// Cursor
if isCursorVisible then DrawSprite(sprArrow, CursorPoint.X, CursorPoint.Y, (RealTicks shr 6) mod 8, Surface);

{$IFDEF COUNTTICKS}
DXOutText(10, 10, fnt16, inttostr(cntTicks), Surface);
{$ENDIF}

inc(Frames);
inc(CountTicks, Lag);
if CountTicks >= 1000 then
   begin
   FPS:= Frames;
   Frames:= 0;
   CountTicks:= 0;
   end;
if cShowFPS then DXOutText(cScreenWidth - 50, 10, fnt16, inttostr(FPS) + ' fps', Surface)
end;

procedure AddCaption(s: shortstring; Color, Group: LongWord);
var i, t, m, k: LongWord;
begin
i:= 0;
while (i < cMaxCaptions) and (Captions[i].Group <> Group)do inc(i);
if i < cMaxCaptions then
   begin
   while (i < Pred(cMaxCaptions)) do
         begin
         Captions[i]:= Captions[Succ(i)];
         inc(i)
         end;
   Captions[Pred(cMaxCaptions)].EndTime:= 0
   end;
   
if Captions[Pred(cMaxCaptions)].EndTime > 0 then
   begin
   m:= Pred(cMaxCaptions);
   for i:= 1 to m do
       Captions[Pred(i)]:= Captions[i];
   Captions[m].EndTime:= 0
   end else
   begin
   m:= 0;
   while (m < cMaxCaptions)and(Captions[m].EndTime > 0) do inc(m)
   end;

k:= 0;
for i:= 0 to Pred(cMaxCaptions) do
    for t:= 0 to Pred(cMaxCaptions) do
        if (Captions[t].EndTime > 0)and(Captions[t].StorePos = k) then inc(k);

Captions[m].r:= RenderString(s, Color, k);
Captions[m].StorePos:= k;
Captions[m].Group:= Group;
Captions[m].EndTime:= RealTicks + 1200
end;

procedure MoveCamera;
const PrevSentPointTime: LongWord = 0;
var s: string[9];
begin
if not (CurrentTeam.ExtDriven and isCursorVisible) then SDL_GetMouseState(@CursorPoint.X, @CursorPoint.Y);
if (FollowGear <> nil) then
   if abs(CursorPoint.X - prevPoint.X) + abs(CursorPoint.Y - prevpoint.Y) > 4 then
      begin
      FollowGear:= nil;
      exit
      end
      else begin
      CursorPoint.x:= (CursorPoint.x * 7 + (round(FollowGear.X + Sign(FollowGear.dX) * 100) + WorldDx)) div 8;
      CursorPoint.y:= (CursorPoint.y * 7 + (round(FollowGear.Y) + WorldDy)) div 8
      end;

if ((CursorPoint.X = prevPoint.X)and(CursorPoint.Y = prevpoint.Y)) then exit;

if isCursorVisible then
   begin
   if (not CurrentTeam.ExtDriven)and(GameTicks >= PrevSentPointTime + cSendCursorPosTime) then
      begin
      s[0]:= #9;
      s[1]:= 'P';
      PInteger(@s[2])^:= CursorPoint.X - WorldDx;
      PInteger(@s[6])^:= CursorPoint.Y - WorldDy;
      SendIPC(s);
      PrevSentPointTime:= GameTicks
      end;
   end;
if isCursorVisible or (FollowGear <> nil) then
   begin
   if CursorPoint.X < cScreenEdgesDist then
         begin
         WorldDx:= WorldDx - CursorPoint.X + cScreenEdgesDist;
         CursorPoint.X:= cScreenEdgesDist
         end else
      if CursorPoint.X > cScreenWidth - cScreenEdgesDist then
         begin
         WorldDx:= WorldDx - CursorPoint.X + cScreenWidth - cScreenEdgesDist;
         CursorPoint.X:= cScreenWidth - cScreenEdgesDist
         end;
      if CursorPoint.Y < cScreenEdgesDist then
         begin
         WorldDy:= WorldDy - CursorPoint.Y + cScreenEdgesDist;
         CursorPoint.Y:= cScreenEdgesDist
         end else
      if CursorPoint.Y > cScreenHeight - cScreenEdgesDist then
         begin
         WorldDy:= WorldDy - CursorPoint.Y + cScreenHeight - cScreenEdgesDist;
         CursorPoint.Y:= cScreenHeight - cScreenEdgesDist
         end;
   end else
   begin
      WorldDx:= WorldDx - CursorPoint.X + prevPoint.X;
      WorldDy:= WorldDy - CursorPoint.Y + prevPoint.Y;
      CursorPoint.X:= (cScreenWidth  shr 1);
      CursorPoint.Y:= (cScreenHeight shr 1);
   end;
SDL_WarpMouse(CursorPoint.X, CursorPoint.Y);
prevPoint:= CursorPoint;
if WorldDy < cScreenHeight - cWaterLine - cVisibleWater then WorldDy:= cScreenHeight - cWaterLine - cVisibleWater;
if WorldDy >  2048 then WorldDy:=  2048;
if WorldDx < -2048 then WorldDx:= -2048;
if WorldDx > cScreenWidth then WorldDx:=  cScreenWidth;
end;

initialization
FillChar(Captions, sizeof(Captions), 0)

end.

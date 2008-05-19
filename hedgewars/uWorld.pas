(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004-2008 Andrey Korotaev <unC0Rr@gmail.com>
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

unit uWorld;
interface
uses SDLh, uGears, uConsts, uFloat;
{$INCLUDE options.inc}
const WorldDx: LongInt = -512;
      WorldDy: LongInt = -256;

procedure InitWorld;
procedure DrawWorld(Lag: LongInt; Surface: PSDL_Surface);
procedure AddCaption(s: string; Color: Longword; Group: TCapGroup);

{$IFDEF COUNTTICKS}
var cntTicks: LongWord;
{$ENDIF}
var FollowGear: PGear = nil;
    WindBarWidth: LongInt = 0;
    bShowAmmoMenu: boolean = false;
    bSelected: boolean = false;
    bShowFinger: boolean = false;
    Frames: Longword = 0;

implementation
uses uStore, uMisc, uTeams, uIO, uConsole, uKeys, uLocale, uSound, GL,
     uAmmos, uVisualGears, uChat;
const FPS: Longword = 0;
      CountTicks: Longword = 0;
      SoundTimerTicks: Longword = 0;
      prevPoint: TPoint = (X: 0; Y: 0);

type TCaptionStr = record
                   Tex: PTexture;
                   EndTime: LongWord;
                   end;

var cWaterSprCount: LongInt;
    Captions: array[TCapGroup] of TCaptionStr;
    AMxLeft, AMxCurr, SlotsNum: LongInt;
    tmpSurface: PSDL_Surface;
    fpsTexture: PTexture = nil;

procedure InitWorld;
begin
cWaterSprCount:= 1 + cScreenWidth div (SpritesData[sprWater].Width);
cGearScrEdgesDist:= Min(cScreenWidth div 2 - 100, cScreenHeight div 2 - 50);
SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
prevPoint.X:= cScreenWidth div 2;
prevPoint.Y:= cScreenHeight div 2;
WorldDx:=  - 1024 + cScreenWidth div 2;
WorldDy:=  - 512 + cScreenHeight div 2;
AMxLeft:= cScreenWidth - 210;
AMxCurr:= cScreenWidth
end;

procedure ShowAmmoMenu(Surface: PSDL_Surface);
const MENUSPEED = 15;
var x, y, i, t: LongInt;
    Slot, Pos: LongInt;
begin
if (TurnTimeLeft = 0) or KbdKeyPressed then bShowAmmoMenu:= false;
if bShowAmmoMenu then
   begin
   if AMxCurr = cScreenWidth then prevPoint.X:= 0;
   if AMxCurr > AMxLeft then dec(AMxCurr, MENUSPEED);
   end else
   begin
   if AMxCurr = AMxLeft then
      begin
      CursorPoint.X:= cScreenWidth div 2;
      CursorPoint.Y:= cScreenHeight div 2;
      prevPoint:= CursorPoint;
      SDL_WarpMouse(CursorPoint.X, CursorPoint.Y)
      end;
   if AMxCurr < cScreenWidth then inc(AMxCurr, MENUSPEED);
   end;

if CurrentTeam = nil then exit;
Slot:= 0;
Pos:= -1;
with CurrentHedgehog^ do
     begin
     if Ammo = nil then exit;
     SlotsNum:= 0;
     x:= AMxCurr;
     y:= cScreenHeight - 40;
     dec(y);
     DrawSprite(sprAMBorders, x, y, 0);
     dec(y);
     DrawSprite(sprAMBorders, x, y, 1);
     dec(y, 33);
     DrawSprite(sprAMSlotName, x, y, 0);
     for i:= cMaxSlotIndex downto 0 do
         if Ammo^[i, 0].Count > 0 then
            begin
            if (CursorPoint.Y >= y - 33) and (CursorPoint.Y < y) then Slot:= i;
            dec(y, 33);
            inc(SlotsNum);
            DrawSprite(sprAMSlot, x, y, 0);
            DrawSprite(sprAMSlotKeys, x + 2, y + 1, i);
            t:= 0;
            while (t <= cMaxSlotAmmoIndex) and (Ammo^[i, t].Count > 0) do
                  begin
                  DrawSprite(sprAMAmmos, x + t * 33 + 35, y + 1, LongInt(Ammo^[i, t].AmmoType));
                  if (Slot = i) and (CursorPoint.X >= x + t * 33 + 35) and (CursorPoint.X < x + t * 33 + 68) then
                     begin
                     DrawSprite(sprAMSelection, x + t * 33 + 35, y + 1, 0);
                     Pos:= t;
                     end;
                  inc(t)
                  end
            end;
     dec(y, 1);
     DrawSprite(sprAMBorders, x, y, 0);

     if (Pos >= 0) then
        if Ammo^[Slot, Pos].Count > 0 then
           begin
           DrawTexture(AMxCurr + 10, cScreenHeight - 68, Ammoz[Ammo^[Slot, Pos].AmmoType].NameTex);
           if Ammo^[Slot, Pos].Count < 10 then
              DrawTexture(AMxCurr + 175, cScreenHeight - 68, CountTexz[Ammo^[Slot, Pos].Count]);
           if bSelected then
              begin
              bShowAmmoMenu:= false;
              SetWeapon(Ammo^[Slot, Pos].AmmoType);
              bSelected:= false;
              exit
              end;
           end;
     end;

bSelected:= false;
if AMxLeft = AMxCurr then DrawSprite(sprArrow, CursorPoint.X, CursorPoint.Y, (RealTicks shr 6) mod 8)
end;

procedure MoveCamera; forward;

procedure DrawWorld(Lag: LongInt; Surface: PSDL_Surface);
var i, t: LongInt;
    r: TSDL_Rect;
    tdx, tdy: Double;
    grp: TCapGroup;
    s: string[15];

    procedure DrawRepeated(spr: TSprite; Shift: LongInt);
    var i, w: LongInt;
    begin
    w:= SpritesData[spr].Width;
    i:= Shift mod w;
    if i > 0 then dec(i, w);
    repeat
      DrawSprite(spr, i, WorldDy + 1024 - SpritesData[spr].Height, 0);
      inc(i, w)
    until i > cScreenWidth
    end;

begin
// Sky
glClear(GL_COLOR_BUFFER_BIT);
glEnable(GL_BLEND);
glEnable(GL_TEXTURE_2D);
//glPushMatrix;
//glScalef(1.0, 1.0, 1.0);

if not isPaused then MoveCamera;

// background
DrawRepeated(sprSky, WorldDx * 3 div 8);
DrawRepeated(sprHorizont, WorldDx * 3 div 5);

DrawVisualGears;

// Waves
{$WARNINGS OFF}
for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * 256  + ((WorldDx + (RealTicks shr 6)      ) and $FF), cWaterLine + WorldDy - 64, 0);
for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * 256  + ((WorldDx - (RealTicks shr 6) + 192) and $FF), cWaterLine + WorldDy - 48, 0);
{$WARNINGS ON}

DrawLand(WorldDx, WorldDy);
// Water
r.y:= WorldDy + cWaterLine + 32;
if r.y < cScreenHeight then
   begin
   if r.y < 0 then r.y:= 0;

   glDisable(GL_TEXTURE_2D);
   glBegin(GL_QUADS);
    glColor3ub($54, $5C, $9D); // water color
    glVertex2i(0, r.y);
    glVertex2i(cScreenWidth, r.y);
    glColor3ub($34, $3C, $7D); // deep water color
    glVertex2i(cScreenWidth, cScreenHeight);
    glVertex2i(0, cScreenHeight);
   glEnd();

   glColor4f(1, 1, 1, 1); // disable coloring
   glEnable(GL_TEXTURE_2D)
   end;

DrawGears(Surface);

// Waves
{$WARNINGS OFF}
for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * 256  + ((WorldDx + (RealTicks shr 6) +  64) and $FF), cWaterLine + WorldDy - 32, 0);
for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * 256  + ((WorldDx - (RealTicks shr 6) + 128) and $FF), cWaterLine + WorldDy - 16, 0);
for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * 256  + ((WorldDx + (RealTicks shr 6)      ) and $FF), cWaterLine + WorldDy     , 0);
{$WARNINGS ON}

// Turn time
if TurnTimeLeft <> 0 then
   begin
   i:= Succ(Pred(TurnTimeLeft) div 1000);
   if i>99 then t:= 112
      else if i>9 then t:= 96
                  else t:= 80;
   DrawSprite(sprFrame, t, cScreenHeight - 48, 1);
   while i > 0 do
         begin
         dec(t, 32);
         DrawSprite(sprBigDigit, t, cScreenHeight - 48, i mod 10);
         i:= i div 10
         end;
   DrawSprite(sprFrame, t - 4, cScreenHeight - 48, 0);
   end;

// Attack bar
if CurrentTeam <> nil then
   case AttackBar of
(*        1: begin
           r:= StuffPoz[sPowerBar];
           {$WARNINGS OFF}
           r.w:= (CurrentHedgehog^.Gear^.Power * 256) div cPowerDivisor;
           {$WARNINGS ON}
           DrawSpriteFromRect(r, cScreenWidth - 272, cScreenHeight - 48, 16, 0, Surface);
           end;
*)        2: with CurrentHedgehog^ do
                begin
                tdx:= hwSign(Gear^.dX) * Sin(Gear^.Angle * Pi / cMaxAngle);
                tdy:= - Cos(Gear^.Angle * Pi / cMaxAngle);
                for i:= (Gear^.Power * 24) div cPowerDivisor downto 0 do
                    DrawSprite(sprPower, hwRound(Gear^.X) + system.round(WorldDx + tdx * (24 + i * 2)) - 16,
                                         hwRound(Gear^.Y) + system.round(WorldDy + tdy * (24 + i * 2)) - 12,
                                         i)
                end
        end;

// Target
if TargetPoint.X <> NoPointX then DrawSprite(sprTargetP, TargetPoint.X + WorldDx - 16, TargetPoint.Y + WorldDy - 16, 0);

//glPopMatrix;

// Captions
i:= 8;
for grp:= Low(TCapGroup) to High(TCapGroup) do
    with Captions[grp] do
         if Tex <> nil then
            begin
            DrawCentered(cScreenWidth div 2, i + cConsoleYAdd, Tex);
            inc(i, Tex^.h + 2);
            if EndTime <= RealTicks then
               begin
               FreeTexture(Tex);
               Tex:= nil;
               EndTime:= 0
               end
            end;

// Teams Healths
for t:= 0 to Pred(TeamsCount) do
   with TeamsArray[t]^ do
      begin
      DrawTexture(cScreenWidth div 2 - NameTagTex^.w - 3, DrawHealthY, NameTagTex);

      r.x:= 0;
      r.y:= 0;
      r.w:= 2 + TeamHealthBarWidth;
      r.h:= HealthTex^.h;

      DrawFromRect(cScreenWidth div 2,
                        DrawHealthY,
                        @r, HealthTex);

      inc(r.x, cTeamHealthWidth + 2);
      r.w:= 3;

      DrawFromRect(cScreenWidth div 2 + TeamHealthBarWidth + 2,
                        DrawHealthY,
                        @r, HealthTex);
      end;

// Lag alert
if isInLag then DrawSprite(sprLag, 32, 32  + cConsoleYAdd, (RealTicks shr 7) mod 12);

// Wind bar
DrawSprite(sprWindBar, cScreenWidth - 180, cScreenHeight - 30, 0);
if WindBarWidth > 0 then
   begin
   {$WARNINGS OFF}
   r.x:= 8 - (RealTicks shr 6) mod 8;
   {$WARNINGS ON}
   r.y:= 0;
   r.w:= WindBarWidth;
   r.h:= 13;
   DrawSpriteFromRect(sprWindR, r, cScreenWidth - 103, cScreenHeight - 28, 13, 0);
   end else
 if WindBarWidth < 0 then
   begin
   {$WARNINGS OFF}
   r.x:= (WindBarWidth + RealTicks shr 6) mod 8;
   {$WARNINGS ON}
   r.y:= 0;
   r.w:= - WindBarWidth;
   r.h:= 13;
   DrawSpriteFromRect(sprWindL, r, cScreenWidth - 106 + WindBarWidth, cScreenHeight - 28, 13, 0);
   end;

// AmmoMenu
if (AMxCurr < cScreenWidth) or bShowAmmoMenu then ShowAmmoMenu(Surface);

DrawChat;

// Cursor
if isCursorVisible then
   begin
   if not bShowAmmoMenu then
     with CurrentHedgehog^ do
       if (Gear^.State and gstHHChooseTarget) <> 0 then
         begin
         i:= Ammo^[CurSlot, CurAmmo].Pos;
         with Ammoz[Ammo^[CurSlot, CurAmmo].AmmoType] do
           if PosCount > 1 then
              DrawSprite(PosSprite, CursorPoint.X - SpritesData[PosSprite].Width div 2,
                                    CursorPoint.Y - SpritesData[PosSprite].Height div 2,
                                    i);
         end;
   DrawSprite(sprArrow, CursorPoint.X, CursorPoint.Y, (RealTicks shr 6) mod 8)
   end;

if isPaused then DrawCentered(cScreenWidth div 2, cScreenHeight div 2, PauseTexture);

inc(Frames);
if cShowFPS then
   begin
   inc(CountTicks, Lag);
   if CountTicks >= 1000 then
      begin
      FPS:= Frames;
      Frames:= 0;
      CountTicks:= 0;
      s:= inttostr(FPS) + ' fps';
      if fpsTexture <> nil then FreeTexture(fpsTexture);
      tmpSurface:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(s), $FFFFFF);
      fpsTexture:= Surface2Tex(tmpSurface);
      SDL_FreeSurface(tmpSurface)
      end;
   if fpsTexture <> nil then
      DrawTexture(cScreenWidth - 50, 10, fpsTexture);
   end;

inc(SoundTimerTicks, Lag);
if SoundTimerTicks >= 50 then
   begin
   SoundTimerTicks:= 0;
   if cVolumeDelta <> 0 then
      begin
      str(ChangeVolume(cVolumeDelta), s);
      AddCaption(Format(trmsg[sidVolume], s), $FFFFFF, capgrpVolume)
      end
   end;

glDisable(GL_TEXTURE_2D);
glDisable(GL_BLEND)
end;

procedure AddCaption(s: string; Color: Longword; Group: TCapGroup);
begin
if Group in [capgrpGameState, capgrpNetSay] then WriteLnToConsole(s);
if Captions[Group].Tex <> nil then FreeTexture(Captions[Group].Tex);

Captions[Group].Tex:= RenderStringTex(s, Color, fntBig);
Captions[Group].EndTime:= RealTicks + 1500
end;

procedure MoveCamera;
const PrevSentPointTime: LongWord = 0;
var EdgesDist: LongInt;
begin
if (not (CurrentTeam^.ExtDriven and isCursorVisible))
   and cHasFocus then SDL_GetMouseState(@CursorPoint.X, @CursorPoint.Y);

if (FollowGear <> nil) then
   if abs(CursorPoint.X - prevPoint.X) + abs(CursorPoint.Y - prevpoint.Y) > 4 then
      begin
      FollowGear:= nil;
      exit
      end
      else begin
      CursorPoint.x:= (prevPoint.x * 7 + (hwRound(FollowGear^.X) + hwSign(FollowGear^.dX) * 100) + WorldDx) div 8;
      CursorPoint.y:= (prevPoint.y * 7 + (hwRound(FollowGear^.Y) + WorldDy)) div 8
      end;

if ((CursorPoint.X = prevPoint.X)and(CursorPoint.Y = prevpoint.Y)) then exit;

if AMxCurr < cScreenWidth then
   begin
   if CursorPoint.X < AMxCurr + 35 then CursorPoint.X:= AMxCurr + 35;
   if CursorPoint.X > AMxCurr + 200 then CursorPoint.X:= AMxCurr + 200;
   if CursorPoint.Y < cScreenHeight - 75 - SlotsNum * 33 then CursorPoint.Y:= cScreenHeight - 75 - SlotsNum * 33;
   if CursorPoint.Y > cScreenHeight - 76 then CursorPoint.Y:= cScreenHeight - 76;
   prevPoint:= CursorPoint;
   if cHasFocus then SDL_WarpMouse(CursorPoint.X, CursorPoint.Y);
   exit
   end;

if isCursorVisible then
   begin
   if (not CurrentTeam^.ExtDriven)and(GameTicks >= PrevSentPointTime + cSendCursorPosTime) then
      begin
      SendIPCXY('P', CursorPoint.X - WorldDx, CursorPoint.Y - WorldDy);
      PrevSentPointTime:= GameTicks
      end;
   end;

if isCursorVisible or (FollowGear <> nil) then
   begin
   if isCursorVisible then EdgesDist:= cCursorEdgesDist
                      else EdgesDist:= cGearScrEdgesDist;
   if CursorPoint.X < EdgesDist then
         begin
         WorldDx:= WorldDx - CursorPoint.X + EdgesDist;
         CursorPoint.X:= EdgesDist
         end else
      if CursorPoint.X > cScreenWidth - EdgesDist then
         begin
         WorldDx:= WorldDx - CursorPoint.X + cScreenWidth - EdgesDist;
         CursorPoint.X:= cScreenWidth - EdgesDist
         end;
      if CursorPoint.Y < EdgesDist then
         begin
         WorldDy:= WorldDy - CursorPoint.Y + EdgesDist;
         CursorPoint.Y:= EdgesDist
         end else
      if CursorPoint.Y > cScreenHeight - EdgesDist then
         begin
         WorldDy:= WorldDy - CursorPoint.Y + cScreenHeight - EdgesDist;
         CursorPoint.Y:= cScreenHeight - EdgesDist
         end;
   end else
   if cHasFocus then
      begin
      WorldDx:= WorldDx - CursorPoint.X + prevPoint.X;
      WorldDy:= WorldDy - CursorPoint.Y + prevPoint.Y;
      CursorPoint.X:= (cScreenWidth  shr 1);
      CursorPoint.Y:= (cScreenHeight shr 1);
      end;

if cHasFocus then SDL_WarpMouse(CursorPoint.X, CursorPoint.Y);
prevPoint:= CursorPoint;
if WorldDy < cScreenHeight - cWaterLine - cVisibleWater then WorldDy:= cScreenHeight - cWaterLine - cVisibleWater;
if WorldDy >  2048 then WorldDy:=  2048;
if WorldDx < -2048 then WorldDx:= -2048;
if WorldDx > cScreenWidth then WorldDx:=  cScreenWidth;
end;

initialization
FillChar(Captions, sizeof(Captions), 0)

end.

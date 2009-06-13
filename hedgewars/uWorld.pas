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

unit uWorld;
interface
uses SDLh, uGears, uConsts, uFloat;
{$INCLUDE options.inc}
const WorldDx: LongInt = -512;
      WorldDy: LongInt = -256;

procedure InitWorld;
procedure DrawWorld(Lag: LongInt);
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
	WaterColor, DeepWaterColor: TSDL_Color;
	cWaterSprCount: LongInt;

implementation
uses uStore, uMisc, uTeams, uIO, uConsole, uKeys, uLocale, uSound,
{$IFDEF GLES11}
	gles11,
{$ELSE}
	GL,
{$ENDIF}
     uAmmos, uVisualGears, uChat, uLandTexture, uLand;

const FPS: Longword = 0;
      CountTicks: Longword = 0;
      SoundTimerTicks: Longword = 0;
      prevPoint: TPoint = (X: 0; Y: 0);

type TCaptionStr = record
                   Tex: PTexture;
                   EndTime: LongWord;
                   end;

var cWaveWidth, cWaveHeight: LongInt;
	Captions: array[TCapGroup] of TCaptionStr;
	AMxShift, SlotsNum: LongInt;
	tmpSurface: PSDL_Surface;
	fpsTexture: PTexture = nil;

procedure InitWorld;
begin
cWaveWidth:= SpritesData[sprWater].Width;
cWaveHeight:= SpritesData[sprWater].Height;
cGearScrEdgesDist:= Min(cScreenWidth div 2 - 100, cScreenHeight div 2 - 50);
SDL_WarpMouse(cScreenWidth div 2, cScreenHeight div 2);
prevPoint.X:= cScreenWidth div 2;
prevPoint.Y:= cScreenHeight div 2;
WorldDx:=  - (LAND_WIDTH div 2) + cScreenWidth div 2;
//WorldDy:=  - (LAND_HEIGHT div 2) + cScreenHeight div 2;
WorldDy:=  - (LAND_HEIGHT - (playHeight div 2)) + (cScreenHeight div 2);
AMxShift:= 210
end;

procedure ShowAmmoMenu;
const MENUSPEED = 15;
var x, y, i, t, l: LongInt;
    Slot, Pos: LongInt;
begin
if (TurnTimeLeft = 0) or KbdKeyPressed then bShowAmmoMenu:= false;
if bShowAmmoMenu then
   begin
   if AMxShift = 210 then prevPoint.X:= 0;
   if cReducedQuality then
       AMxShift:= 0
   else
       if AMxShift > 0 then dec(AMxShift, MENUSPEED);
   end else
   begin
   if AMxShift = 0 then
      begin
      CursorPoint.X:= cScreenWidth div 2;
      CursorPoint.Y:= cScreenHeight div 2;
      prevPoint:= CursorPoint;
      SDL_WarpMouse(CursorPoint.X, CursorPoint.Y)
      end;
   if cReducedQuality then
       AMxShift:= 210
   else
       if AMxShift < 210 then inc(AMxShift, MENUSPEED);
   end;

if CurrentTeam = nil then exit;
Slot:= 0;
Pos:= -1;
with CurrentHedgehog^ do
	begin
	if Ammo = nil then exit;
	SlotsNum:= 0;
	x:= cScreenWidth div 2 - 210 + AMxShift;
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
				l:= Ammoz[Ammo^[i, t].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber;

				if l >= 0 then
					begin
					DrawSprite(sprAMAmmosBW, x + t * 33 + 35, y + 1, LongInt(Ammo^[i, t].AmmoType));
					DrawSprite(sprTurnsLeft, x + t * 33 + 51, y + 17, l);
					end else
					DrawSprite(sprAMAmmos, x + t * 33 + 35, y + 1, LongInt(Ammo^[i, t].AmmoType));

				if (Slot = i)
				and (CursorPoint.X >= x + t * 33 + 35)
				and (CursorPoint.X < x + t * 33 + 68) then
					begin
					if (l < 0) then DrawSprite(sprAMSelection, x + t * 33 + 35, y + 1, 0);
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
		DrawTexture(cScreenWidth div 2 - 200 + AMxShift, cScreenHeight - 68, Ammoz[Ammo^[Slot, Pos].AmmoType].NameTex);
		
		if Ammo^[Slot, Pos].Count < AMMO_INFINITE then
			DrawTexture(cScreenWidth + AMxShift - 35, cScreenHeight - 68, CountTexz[Ammo^[Slot, Pos].Count]);
		
		if bSelected and (Ammoz[Ammo^[Slot, Pos].AmmoType].SkipTurns - CurrentTeam^.Clan^.TurnNumber < 0) then
			begin
			bShowAmmoMenu:= false;
			SetWeapon(Ammo^[Slot, Pos].AmmoType);
			bSelected:= false;
			exit
			end;
		end;
	end;

bSelected:= false;
if AMxShift = 0 then DrawSprite(sprArrow, CursorPoint.X, CursorPoint.Y, (RealTicks shr 6) mod 8)
end;

procedure MoveCamera; forward;

procedure DrawWater;
var VertexBuffer: array [0..3] of TVertex2f;
    r: TSDL_Rect;
    lw, lh: GLfloat;
begin
lw:= cScreenWidth / cScaleFactor;
lh:= cScreenHeight * 2 / cScaleFactor;
// Water
r.y:= WorldDy + cWaterLine + 32;
if r.y < cScreenHeight * 2 / cScaleFactor then
	begin
	if r.y < 0 then r.y:= 0;

	glDisable(GL_TEXTURE_2D);
	VertexBuffer[0].X:= -lw;
	VertexBuffer[0].Y:= r.y;
	VertexBuffer[1].X:= lw;
	VertexBuffer[1].Y:= r.y;
	VertexBuffer[2].X:= lw;
	VertexBuffer[2].Y:= lh;
	VertexBuffer[3].X:= -lw;
	VertexBuffer[3].Y:= lh;

	glEnableClientState (GL_COLOR_ARRAY);
	glColorPointer(3, GL_UNSIGNED_BYTE, 0, @WaterColorArray[0]);

	glEnableClientState(GL_VERTEX_ARRAY);
	glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
	
	glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

	glEnableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_COLOR_ARRAY);

	glColor4f(1, 1, 1, 1); // disable coloring
	glEnable(GL_TEXTURE_2D)
	end
end;

procedure DrawWorld(Lag: LongInt);
var i, t: LongInt;
    r: TSDL_Rect;
    tdx, tdy: Double;
    grp: TCapGroup;
    s: string[15];

    procedure DrawRepeated(spr: TSprite; Shift: LongInt);
    var i, w, sw: LongInt;
    begin
    sw:= round(cScreenWidth / cScaleFactor);
    w:= SpritesData[spr].Width;
    i:= Shift mod w;
    if i > 0 then dec(i, w);
    dec(i, sw);
    //addfilelog(inttostr(sw));
    repeat
      DrawSprite(spr, i, WorldDy + LAND_HEIGHT - SpritesData[spr].Height, 0);
      inc(i, w)
    until i > sw
    end;

begin
// Sky
glClear(GL_COLOR_BUFFER_BIT);
glEnable(GL_BLEND);
glEnable(GL_TEXTURE_2D);
//glPushMatrix;
//glScalef(1.0, 1.0, 1.0);

if not isPaused then MoveCamera;

if not cReducedQuality then
    begin
    // background
    DrawRepeated(sprSky, WorldDx * 3 div 8);
    DrawRepeated(sprHorizont, WorldDx * 3 div 5);

    DrawVisualGears(0);

    // Waves
    {$WARNINGS OFF}
//    for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * cWaveWidth  + ((WorldDx + (RealTicks shr 6)      ) mod cWaveWidth), cWaterLine + WorldDy - (cWaveHeight*2), 0);
//    for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * cWaveWidth + ((WorldDx - (RealTicks shr 6) + 100) mod cWaveWidth), cWaterLine + WorldDy - (cWaveHeight + cWaveHeight div 2), 0);
    {$WARNINGS ON}
    end;


DrawLand(WorldDx, WorldDy);

DrawWater;

// Attack bar
if CurrentTeam <> nil then
	case AttackBar of
(*        1: begin
		r:= StuffPoz[sPowerBar];
		{$WARNINGS OFF}
		r.w:= (CurrentHedgehog^.Gear^.Power * 256) div cPowerDivisor;
		{$WARNINGS ON}
		DrawSpriteFromRect(r, cScreenWidth - 272, cScreenHeight - 48, 16, 0, Surface);
		end;*)
		2: with CurrentHedgehog^ do
				begin
				tdx:= hwSign(Gear^.dX) * Sin(Gear^.Angle * Pi / cMaxAngle);
				tdy:= - Cos(Gear^.Angle * Pi / cMaxAngle);
				for i:= (Gear^.Power * 24) div cPowerDivisor downto 0 do
					DrawSprite(sprPower,
							hwRound(Gear^.X) + system.round(WorldDx + tdx * (24 + i * 2)) - 16,
							hwRound(Gear^.Y) + system.round(WorldDy + tdy * (24 + i * 2)) - 12,
							i)
				end
		end;

DrawGears;

DrawVisualGears(1);

// Waves
{$WARNINGS OFF}
//for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * cWaveWidth  + ((WorldDx + (RealTicks shr 6) +  25) mod cWaveWidth), cWaterLine + WorldDy - cWaveHeight, 0);
//for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * cWaveWidth  + ((WorldDx - (RealTicks shr 6) +  50) mod cWaveWidth), cWaterLine + WorldDy - (cWaveHeight div 2), 0);
//for i:= -1 to cWaterSprCount do DrawSprite(sprWater,  i * cWaveWidth  + ((WorldDx + (RealTicks shr 6) +  75) mod cWaveWidth), cWaterLine + WorldDy     , 0);


// Target
if TargetPoint.X <> NoPointX then DrawSprite(sprTargetP, TargetPoint.X + WorldDx - 16, TargetPoint.Y + WorldDy - 16, 0);

{$WARNINGS ON}
SetScale(2.0);

// Turn time
if TurnTimeLeft <> 0 then
   begin
   i:= Succ(Pred(TurnTimeLeft) div 1000);
   if i>99 then t:= 112
      else if i>9 then t:= 96
                  else t:= 80;
   DrawSprite(sprFrame, -cScreenWidth div 2 + t, cScreenHeight - 48, 1);
   while i > 0 do
         begin
         dec(t, 32);
         DrawSprite(sprBigDigit, -cScreenWidth div 2 + t, cScreenHeight - 48, i mod 10);
         i:= i div 10
         end;
   DrawSprite(sprFrame, -cScreenWidth div 2 + t - 4, cScreenHeight - 48, 0);
   end;

// Captions
i:= 8;
for grp:= Low(TCapGroup) to High(TCapGroup) do
    with Captions[grp] do
         if Tex <> nil then
            begin
            DrawCentered(0, i, Tex);
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
      DrawTexture(- NameTagTex^.w - 3, cScreenHeight + DrawHealthY, NameTagTex);

      r.x:= 0;
      r.y:= 0;
      r.w:= 2 + TeamHealthBarWidth;
      r.h:= HealthTex^.h;

      DrawFromRect(0,
                        cScreenHeight + DrawHealthY,
                        @r, HealthTex);

      inc(r.x, cTeamHealthWidth + 2);
      r.w:= 3;

      DrawFromRect(TeamHealthBarWidth + 2,
                        cScreenHeight + DrawHealthY,
                        @r, HealthTex);
      end;

// Lag alert
if isInLag then DrawSprite(sprLag, 32 - cScreenWidth div 2, 32, (RealTicks shr 7) mod 12);

// Wind bar
DrawSprite(sprWindBar, cScreenWidth div 2 - 180, cScreenHeight - 30, 0);
if WindBarWidth > 0 then
   begin
   {$WARNINGS OFF}
   r.x:= 8 - (RealTicks shr 6) mod 8;
   {$WARNINGS ON}
   r.y:= 0;
   r.w:= WindBarWidth;
   r.h:= 13;
   DrawSpriteFromRect(sprWindR, r, cScreenWidth div 2 - 103, cScreenHeight - 28, 13, 0);
   end else
 if WindBarWidth < 0 then
   begin
   {$WARNINGS OFF}
   r.x:= (WindBarWidth + RealTicks shr 6) mod 8;
   {$WARNINGS ON}
   r.y:= 0;
   r.w:= - WindBarWidth;
   r.h:= 13;
   DrawSpriteFromRect(sprWindL, r, cScreenWidth div 2 - 106 + WindBarWidth, cScreenHeight - 28, 13, 0);
   end;

// AmmoMenu
if (AMxShift < 210) or bShowAmmoMenu then ShowAmmoMenu;

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
{$IFNDEF IPHONEOS}
      tmpSurface:= TTF_RenderUTF8_Blended(Fontz[fnt16].Handle, Str2PChar(s), $FFFFFF);
{$ENDIF}
      fpsTexture:= Surface2Tex(tmpSurface);
      SDL_FreeSurface(tmpSurface)
      end;
   if fpsTexture <> nil then
      DrawTexture(cScreenWidth div 2 - 50, 10, fpsTexture);
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

if GameState = gsConfirm then DrawCentered(0, cScreenHeight div 2, ConfirmTexture);

SetScale(zoom);

glDisable(GL_TEXTURE_2D);
glDisable(GL_BLEND)
end;

procedure AddCaption(s: string; Color: Longword; Group: TCapGroup);
begin
//if Group in [capgrpGameState] then WriteLnToConsole(s);
if Captions[Group].Tex <> nil then FreeTexture(Captions[Group].Tex);

Captions[Group].Tex:= RenderStringTex(s, Color, fntBig);

case Group of
	capgrpGameState: Captions[Group].EndTime:= RealTicks + 2200
	else
	Captions[Group].EndTime:= RealTicks + 1570
	end;
end;

procedure MoveCamera;
const PrevSentPointTime: LongWord = 0;
var EdgesDist, cw: LongInt;
begin
cw:= round(cScreenWidth / cScaleFactor);


if (not (CurrentTeam^.ExtDriven and isCursorVisible))
	and cHasFocus then
	begin
	SDL_GetMouseState(@CursorPoint.X, @CursorPoint.Y);
	CursorPoint.X:= CursorPoint.X - cScreenWidth div 2;
//	CursorPoint.X:= round((CursorPoint.X - cScreenWidth / 2) * 2 / cScaleFactor);
//	CursorPoint.Y:= round(CursorPoint.Y * 2 / cScaleFactor);
	end;

if (FollowGear <> nil) and (not isCursorVisible) then
	if abs(CursorPoint.X - prevPoint.X) + abs(CursorPoint.Y - prevpoint.Y) > 4 then
		begin
		FollowGear:= nil;
		prevPoint.X:= CursorPoint.X;
		prevPoint.Y:= CursorPoint.Y;
		exit
		end
		else begin
		CursorPoint.x:= (prevPoint.x * 7 + (hwRound(FollowGear^.X) + hwSign(FollowGear^.dX) * 100) + WorldDx) div 8;
		CursorPoint.y:= (prevPoint.y * 7 + (hwRound(FollowGear^.Y) + WorldDy)) div 8
		end;

if ((CursorPoint.X = prevPoint.X)and(CursorPoint.Y = prevpoint.Y)) then exit;

if AMxShift < 210 then
	begin
	if CursorPoint.X < cScreenWidth + AMxShift - 175 then CursorPoint.X:= cScreenWidth + AMxShift - 175;
	if CursorPoint.X > cScreenWidth + AMxShift - 10 then CursorPoint.X:= cScreenWidth + AMxShift - 10;
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
   if CursorPoint.X < - cw + EdgesDist then
         begin
         WorldDx:= WorldDx - CursorPoint.X - cw + EdgesDist;
         CursorPoint.X:= EdgesDist
         end else
      if CursorPoint.X > cw - EdgesDist then
         begin
         WorldDx:= WorldDx - CursorPoint.X + cw - EdgesDist;
         CursorPoint.X:= cScreenWidth - EdgesDist
         end;
      if CursorPoint.Y < EdgesDist then
         begin
         WorldDy:= WorldDy - CursorPoint.Y + EdgesDist;
         CursorPoint.Y:= EdgesDist
         end else
      if CursorPoint.Y > cScreenHeight - EdgesDist then
         begin
         WorldDy:= WorldDy - CursorPoint.Y + round(cScreenHeight * 2 / cScaleFactor) - EdgesDist;
         CursorPoint.Y:= cScreenHeight - EdgesDist
         end;
   end else
   if cHasFocus then
      begin
      WorldDx:= WorldDx - CursorPoint.X + prevPoint.X;
      WorldDy:= WorldDy - CursorPoint.Y + prevPoint.Y;
      CursorPoint.X:= 0;
      CursorPoint.Y:= cScreenHeight div 2;
      end;

if cHasFocus then SDL_WarpMouse(CursorPoint.X + cScreenWidth div 2, CursorPoint.Y);
prevPoint:= CursorPoint;
if WorldDy < cScreenHeight - cWaterLine - cVisibleWater then WorldDy:= cScreenHeight - cWaterLine - cVisibleWater;
if WorldDy > LAND_HEIGHT + 1024 then WorldDy:= LAND_HEIGHT + 1024;
if WorldDx < -round(LAND_WIDTH * 2 / cScaleFactor) then WorldDx:= -round(LAND_WIDTH * 2 / cScaleFactor);
if WorldDx > cw then WorldDx:= cw;
end;

initialization
FillChar(Captions, sizeof(Captions), 0)

end.

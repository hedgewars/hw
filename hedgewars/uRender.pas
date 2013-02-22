(*
 * Hedgewars, a free turn based strategy game
 * Copyright (c) 2004-2012 Andrey Korotaev <unC0Rr@gmail.com>
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

{$INCLUDE "options.inc"}

unit uRender;

interface

uses SDLh, uTypes, GLunit, uConsts;

procedure DrawSprite            (Sprite: TSprite; X, Y, Frame: LongInt);
procedure DrawSprite            (Sprite: TSprite; X, Y, FrameX, FrameY: LongInt);
procedure DrawSpriteFromRect    (Sprite: TSprite; r: TSDL_Rect; X, Y, Height, Position: LongInt);
procedure DrawSpriteClipped     (Sprite: TSprite; X, Y, TopY, RightX, BottomY, LeftX: LongInt);
procedure DrawSpriteRotated     (Sprite: TSprite; X, Y, Dir: LongInt; Angle: real);
procedure DrawSpriteRotatedF    (Sprite: TSprite; X, Y, Frame, Dir: LongInt; Angle: real);

procedure DrawTexture           (X, Y: LongInt; Texture: PTexture); inline;
procedure DrawTexture           (X, Y: LongInt; Texture: PTexture; Scale: GLfloat);
procedure DrawTextureFromRect   (X, Y: LongInt; r: PSDL_Rect; SourceTexture: PTexture);
procedure DrawTextureFromRect   (X, Y, W, H: LongInt; r: PSDL_Rect; SourceTexture: PTexture);
procedure DrawTextureCentered   (X, Top: LongInt; Source: PTexture);
procedure DrawTextureF          (Texture: PTexture; Scale: GLfloat; X, Y, Frame, Dir, w, h: LongInt);
procedure DrawTextureRotated    (Texture: PTexture; hw, hh, X, Y, Dir: LongInt; Angle: real);
procedure DrawTextureRotatedF   (Texture: PTexture; Scale, OffsetX, OffsetY: GLfloat; X, Y, Frame, Dir, w, h: LongInt; Angle: real);

procedure DrawCircle            (X, Y, Radius, Width: LongInt);
procedure DrawCircle            (X, Y, Radius, Width: LongInt; r, g, b, a: Byte);

procedure DrawLine              (X0, Y0, X1, Y1, Width: Single; r, g, b, a: Byte);
procedure DrawFillRect          (r: TSDL_Rect);
procedure DrawHedgehog          (X, Y: LongInt; Dir: LongInt; Pos, Step: LongWord; Angle: real);
procedure DrawScreenWidget      (widget: POnScreenWidget);

procedure Tint                  (r, g, b, a: Byte); inline;
procedure Tint                  (c: Longword); inline;


implementation
uses uVariables;

{$IFDEF USE_TOUCH_INTERFACE}
const
    FADE_ANIM_TIME = 500;
    MOVE_ANIM_TIME = 500;
{$ENDIF}

var LastTint: LongWord = 0;

procedure DrawSpriteFromRect(Sprite: TSprite; r: TSDL_Rect; X, Y, Height, Position: LongInt);
begin
r.y:= r.y + Height * Position;
r.h:= Height;
DrawTextureFromRect(X, Y, @r, SpritesData[Sprite].Texture)
end;

procedure DrawTextureFromRect(X, Y: LongInt; r: PSDL_Rect; SourceTexture: PTexture);
begin
DrawTextureFromRect(X, Y, r^.w, r^.h, r, SourceTexture)
end;

procedure DrawTextureFromRect(X, Y, W, H: LongInt; r: PSDL_Rect; SourceTexture: PTexture);
var rr: TSDL_Rect;
    _l, _r, _t, _b: real;
    VertexBuffer, TextureBuffer: array [0..3] of TVertex2f;
begin
if (SourceTexture^.h = 0) or (SourceTexture^.w = 0) then
    exit;

// do not draw anything outside the visible screen space (first check fixes some sprite drawing, e.g. hedgehogs)
if (abs(X) > W) and ((abs(X + W / 2) - W / 2) > cScreenWidth / cScaleFactor) then
    exit;
if (abs(Y) > H) and ((abs(Y + H / 2 - (0.5 * cScreenHeight)) - H / 2) > cScreenHeight / cScaleFactor) then
    exit;

rr.x:= X;
rr.y:= Y;
rr.w:= W;
rr.h:= H;

_l:= r^.x / SourceTexture^.w * SourceTexture^.rx;
_r:= (r^.x + r^.w) / SourceTexture^.w * SourceTexture^.rx;
_t:= r^.y / SourceTexture^.h * SourceTexture^.ry;
_b:= (r^.y + r^.h) / SourceTexture^.h * SourceTexture^.ry;

glBindTexture(GL_TEXTURE_2D, SourceTexture^.id);

VertexBuffer[0].X:= X;
VertexBuffer[0].Y:= Y;
VertexBuffer[1].X:= rr.w + X;
VertexBuffer[1].Y:= Y;
VertexBuffer[2].X:= rr.w + X;
VertexBuffer[2].Y:= rr.h + Y;
VertexBuffer[3].X:= X;
VertexBuffer[3].Y:= rr.h + Y;

TextureBuffer[0].X:= _l;
TextureBuffer[0].Y:= _t;
TextureBuffer[1].X:= _r;
TextureBuffer[1].Y:= _t;
TextureBuffer[2].X:= _r;
TextureBuffer[2].Y:= _b;
TextureBuffer[3].X:= _l;
TextureBuffer[3].Y:= _b;

glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glTexCoordPointer(2, GL_FLOAT, 0, @TextureBuffer[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));
end;

procedure DrawTexture(X, Y: LongInt; Texture: PTexture); inline;
begin
    DrawTexture(X, Y, Texture, 1.0);
end;

procedure DrawTexture(X, Y: LongInt; Texture: PTexture; Scale: GLfloat);
begin

glPushMatrix;
glTranslatef(X, Y, 0);
glScalef(Scale, Scale, 1);

glBindTexture(GL_TEXTURE_2D, Texture^.id);

glVertexPointer(2, GL_FLOAT, 0, @Texture^.vb);
glTexCoordPointer(2, GL_FLOAT, 0, @Texture^.tb);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(Texture^.vb));

glPopMatrix
end;

procedure DrawTextureF(Texture: PTexture; Scale: GLfloat; X, Y, Frame, Dir, w, h: LongInt);
begin
    DrawTextureRotatedF(Texture, Scale, 0, 0, X, Y, Frame, Dir, w, h, 0)
end;

procedure DrawTextureRotatedF(Texture: PTexture; Scale, OffsetX, OffsetY: GLfloat; X, Y, Frame, Dir, w, h: LongInt; Angle: real);
var ft, fb, fl, fr: GLfloat;
    hw, nx, ny: LongInt;
    VertexBuffer, TextureBuffer: array [0..3] of TVertex2f;
begin
// do not draw anything outside the visible screen space (first check fixes some sprite drawing, e.g. hedgehogs)
if (abs(X) > W) and ((abs(X + dir * OffsetX) - W / 2) * cScaleFactor > cScreenWidth) then
    exit;
if (abs(Y) > H) and ((abs(Y + OffsetY - (0.5 * cScreenHeight)) - W / 2) * cScaleFactor > cScreenHeight) then
    exit;

glPushMatrix;
glTranslatef(X, Y, 0);
if Dir = 0 then Dir:= 1;

glRotatef(Angle, 0, 0, Dir);

glTranslatef(Dir*OffsetX, OffsetY, 0);
glScalef(Scale, Scale, 1);

// Any reason for this call? And why only in t direction, not s?
//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

hw:= w div (2 div Dir);

nx:= round(Texture^.w / w); // number of horizontal frames
ny:= round(Texture^.h / h); // number of vertical frames

ft:= (Frame mod ny) * Texture^.ry / ny;
fb:= ((Frame mod ny) + 1) * Texture^.ry / ny;
fl:= (Frame div ny) * Texture^.rx / nx;
fr:= ((Frame div ny) + 1) * Texture^.rx / nx;

glBindTexture(GL_TEXTURE_2D, Texture^.id);

VertexBuffer[0].X:= -hw;
VertexBuffer[0].Y:= w / -2;
VertexBuffer[1].X:= hw;
VertexBuffer[1].Y:= w / -2;
VertexBuffer[2].X:= hw;
VertexBuffer[2].Y:= w / 2;
VertexBuffer[3].X:= -hw;
VertexBuffer[3].Y:= w / 2;

TextureBuffer[0].X:= fl;
TextureBuffer[0].Y:= ft;
TextureBuffer[1].X:= fr;
TextureBuffer[1].Y:= ft;
TextureBuffer[2].X:= fr;
TextureBuffer[2].Y:= fb;
TextureBuffer[3].X:= fl;
TextureBuffer[3].Y:= fb;

glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glTexCoordPointer(2, GL_FLOAT, 0, @TextureBuffer[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

glPopMatrix
end;

procedure DrawSpriteRotated(Sprite: TSprite; X, Y, Dir: LongInt; Angle: real);
begin
    DrawTextureRotated(SpritesData[Sprite].Texture,
        SpritesData[Sprite].Width,
        SpritesData[Sprite].Height,
        X, Y, Dir, Angle)
end;

procedure DrawSpriteRotatedF(Sprite: TSprite; X, Y, Frame, Dir: LongInt; Angle: real);
begin
glPushMatrix;
glTranslatef(X, Y, 0);

if Dir < 0 then
    glRotatef(Angle, 0, 0, -1)
else
    glRotatef(Angle, 0, 0,  1);
if Dir < 0 then
    glScalef(-1.0, 1.0, 1.0);

DrawSprite(Sprite, -SpritesData[Sprite].Width div 2, -SpritesData[Sprite].Height div 2, Frame);

glPopMatrix
end;

procedure DrawTextureRotated(Texture: PTexture; hw, hh, X, Y, Dir: LongInt; Angle: real);
var VertexBuffer: array [0..3] of TVertex2f;
begin
// do not draw anything outside the visible screen space (first check fixes some sprite drawing, e.g. hedgehogs)
if (abs(X) > 2 * hw) and ((abs(X) - hw) > cScreenWidth / cScaleFactor) then
    exit;
if (abs(Y) > 2 * hh) and ((abs(Y - 0.5 * cScreenHeight) - hh) > cScreenHeight / cScaleFactor) then
    exit;

glPushMatrix;
glTranslatef(X, Y, 0);

if Dir < 0 then
    begin
    hw:= - hw;
    glRotatef(Angle, 0, 0, -1);
    end
else
    glRotatef(Angle, 0, 0,  1);


glBindTexture(GL_TEXTURE_2D, Texture^.id);

VertexBuffer[0].X:= -hw;
VertexBuffer[0].Y:= -hh;
VertexBuffer[1].X:= hw;
VertexBuffer[1].Y:= -hh;
VertexBuffer[2].X:= hw;
VertexBuffer[2].Y:= hh;
VertexBuffer[3].X:= -hw;
VertexBuffer[3].Y:= hh;

glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glTexCoordPointer(2, GL_FLOAT, 0, @Texture^.tb);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

glPopMatrix
end;

procedure DrawSprite(Sprite: TSprite; X, Y, Frame: LongInt);
var row, col, numFramesFirstCol: LongInt;
begin
    if SpritesData[Sprite].imageHeight = 0 then
        exit;
    numFramesFirstCol:= SpritesData[Sprite].imageHeight div SpritesData[Sprite].Height;
    row:= Frame mod numFramesFirstCol;
    col:= Frame div numFramesFirstCol;
    DrawSprite(Sprite, X, Y, col, row);
end;

procedure DrawSprite(Sprite: TSprite; X, Y, FrameX, FrameY: LongInt);
var r: TSDL_Rect;
begin
    r.x:= FrameX * SpritesData[Sprite].Width;
    r.w:= SpritesData[Sprite].Width;
    r.y:= FrameY * SpritesData[Sprite].Height;
    r.h:= SpritesData[Sprite].Height;
    DrawTextureFromRect(X, Y, @r, SpritesData[Sprite].Texture)
end;

procedure DrawSpriteClipped(Sprite: TSprite; X, Y, TopY, RightX, BottomY, LeftX: LongInt);
var r: TSDL_Rect;
begin
r.x:= 0;
r.y:= 0;
r.w:= SpritesData[Sprite].Width;
r.h:= SpritesData[Sprite].Height;

if (X < LeftX) then
    r.x:= LeftX - X;
if (Y < TopY) then
    r.y:= TopY - Y;

if (Y + SpritesData[Sprite].Height > BottomY) then
    r.h:= BottomY - Y + 1;
if (X + SpritesData[Sprite].Width > RightX) then
    r.w:= RightX - X + 1;

dec(r.h, r.y);
dec(r.w, r.x);

DrawTextureFromRect(X + r.x, Y + r.y, @r, SpritesData[Sprite].Texture)
end;

procedure DrawTextureCentered(X, Top: LongInt; Source: PTexture);
var scale: GLfloat;
begin
    if (Source^.w + 20) > cScreenWidth then
        scale:= cScreenWidth / (Source^.w + 20)
    else
        scale:= 1.0;
    DrawTexture(X - round(Source^.w * scale) div 2, Top, Source, scale)
end;

procedure DrawLine(X0, Y0, X1, Y1, Width: Single; r, g, b, a: Byte);
var VertexBuffer: array [0..3] of TVertex2f;
begin
    glDisable(GL_TEXTURE_2D);
    glEnable(GL_LINE_SMOOTH);

    glPushMatrix;
    glTranslatef(WorldDx, WorldDy, 0);
    glLineWidth(Width);

    Tint(r, g, b, a);
    VertexBuffer[0].X:= X0;
    VertexBuffer[0].Y:= Y0;
    VertexBuffer[1].X:= X1;
    VertexBuffer[1].Y:= Y1;

    glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
    glDrawArrays(GL_LINES, 0, Length(VertexBuffer));
    Tint($FF, $FF, $FF, $FF);
    
    glPopMatrix;
    
    glEnable(GL_TEXTURE_2D);
    glDisable(GL_LINE_SMOOTH);
end;

procedure DrawFillRect(r: TSDL_Rect);
var VertexBuffer: array [0..3] of TVertex2f;
begin
// do not draw anything outside the visible screen space (first check fixes some sprite drawing, e.g. hedgehogs)
if (abs(r.x) > r.w) and ((abs(r.x + r.w / 2) - r.w / 2) * cScaleFactor > cScreenWidth) then
    exit;
if (abs(r.y) > r.h) and ((abs(r.y + r.h / 2 - (0.5 * cScreenHeight)) - r.h / 2) * cScaleFactor > cScreenHeight) then
    exit;

glDisable(GL_TEXTURE_2D);

Tint($00, $00, $00, $80);

VertexBuffer[0].X:= r.x;
VertexBuffer[0].Y:= r.y;
VertexBuffer[1].X:= r.x + r.w;
VertexBuffer[1].Y:= r.y;
VertexBuffer[2].X:= r.x + r.w;
VertexBuffer[2].Y:= r.y + r.h;
VertexBuffer[3].X:= r.x;
VertexBuffer[3].Y:= r.y + r.h;

glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

Tint($FF, $FF, $FF, $FF);
glEnable(GL_TEXTURE_2D)
end;

procedure DrawCircle(X, Y, Radius, Width: LongInt; r, g, b, a: Byte); 
begin
    Tint(r, g, b, a);
    DrawCircle(X, Y, Radius, Width); 
    Tint($FF, $FF, $FF, $FF);
end;

procedure DrawCircle(X, Y, Radius, Width: LongInt); 
var
    i: LongInt;
    CircleVertex: array [0..59] of TVertex2f;
begin
    for i := 0 to 59 do begin
        CircleVertex[i].X := X + Radius*cos(i*pi/30);
        CircleVertex[i].Y := Y + Radius*sin(i*pi/30);
    end;
    glDisable(GL_TEXTURE_2D);
    glEnable(GL_LINE_SMOOTH);
    glPushMatrix;
    glLineWidth(Width);
    glVertexPointer(2, GL_FLOAT, 0, @CircleVertex[0]);
    glDrawArrays(GL_LINE_LOOP, 0, 60);
    glPopMatrix;
    glEnable(GL_TEXTURE_2D);
    glDisable(GL_LINE_SMOOTH);
end;


procedure DrawHedgehog(X, Y: LongInt; Dir: LongInt; Pos, Step: LongWord; Angle: real);
const VertexBuffer: array [0..3] of TVertex2f = (
        (X: -16; Y: -16),
        (X:  16; Y: -16),
        (X:  16; Y:  16),
        (X: -16; Y:  16));
var l, r, t, b: real;
    TextureBuffer: array [0..3] of TVertex2f;
begin
    // do not draw anything outside the visible screen space (first check fixes some sprite drawing, e.g. hedgehogs)
    if (abs(X) > 32) and ((abs(X) - 16) * cScaleFactor > cScreenWidth) then
        exit;
    if (abs(Y) > 32) and ((abs(Y - 0.5 * cScreenHeight) - 16) * cScaleFactor > cScreenHeight) then
        exit;

    t:= Pos * 32 / HHTexture^.h;
    b:= (Pos + 1) * 32 / HHTexture^.h;

    if Dir = -1 then
        begin
        l:= (Step + 1) * 32 / HHTexture^.w;
        r:= Step * 32 / HHTexture^.w
        end
    else
        begin
        l:= Step * 32 / HHTexture^.w;
        r:= (Step + 1) * 32 / HHTexture^.w
    end;


    glPushMatrix();
    glTranslatef(X, Y, 0);
    glRotatef(Angle, 0, 0, 1);

    glBindTexture(GL_TEXTURE_2D, HHTexture^.id);

    TextureBuffer[0].X:= l;
    TextureBuffer[0].Y:= t;
    TextureBuffer[1].X:= r;
    TextureBuffer[1].Y:= t;
    TextureBuffer[2].X:= r;
    TextureBuffer[2].Y:= b;
    TextureBuffer[3].X:= l;
    TextureBuffer[3].Y:= b;

    glVertexPointer(2, GL_FLOAT, 0, @VertexBuffer[0]);
    glTexCoordPointer(2, GL_FLOAT, 0, @TextureBuffer[0]);
    glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

    glPopMatrix
end;

procedure DrawScreenWidget(widget: POnScreenWidget);
{$IFDEF USE_TOUCH_INTERFACE}
var alpha: byte = $FF;
begin
with widget^ do
    begin
    if (fadeAnimStart <> 0) then
        begin
        if RealTicks > (fadeAnimStart + FADE_ANIM_TIME) then
            fadeAnimStart:= 0
        else
            if show then 
                alpha:= Byte(trunc((RealTicks - fadeAnimStart)/FADE_ANIM_TIME * $FF))
            else 
                alpha:= Byte($FF - trunc((RealTicks - fadeAnimStart)/FADE_ANIM_TIME * $FF));
        end;

    with moveAnim do
        if animate then
            if RealTicks > (startTime + MOVE_ANIM_TIME) then
                begin
                startTime:= 0;
                animate:= false;
                frame.x:= target.x;
                frame.y:= target.y;
                active.x:= active.x + (target.x - source.x);
                active.y:= active.y + (target.y - source.y);
                end
            else
                begin
                frame.x:= source.x + Round((target.x - source.x) * ((RealTicks - startTime) / MOVE_ANIM_TIME));
                frame.y:= source.y + Round((target.y - source.y) * ((RealTicks - startTime) / MOVE_ANIM_TIME));
                end;

    if show or (fadeAnimStart <> 0) then
        begin
        Tint($FF, $FF, $FF, alpha);
        DrawTexture(frame.x, frame.y, spritesData[sprite].Texture, buttonScale);
        Tint($FF, $FF, $FF, $FF);
        end;
    end;
{$ELSE}
begin
widget:= widget; // avoid hint
{$ENDIF}
end;

procedure Tint(r, g, b, a: Byte); inline;
var nc, tw: Longword;
begin
    nc:= (a shl 24) or (b shl 16) or (g shl 8) or r;

    if nc = lastTint then
        exit;

    if GrayScale then
        begin
        tw:= round(r * RGB_LUMINANCE_RED + g * RGB_LUMINANCE_GREEN + b * RGB_LUMINANCE_BLUE);
        if tw > 255 then
            tw:= 255;
        r:= tw;
        g:= tw;
        b:= tw
        end;

    glColor4ub(r, g, b, a);
    lastTint:= nc;
end;

procedure Tint(c: Longword); inline;
begin
    Tint(((c shr 24) and $FF), ((c shr 16) and $FF), (c shr 8) and $FF, (c and $FF))
end;

end.

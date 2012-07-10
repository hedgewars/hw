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

uses SDLh, uTypes, GLunit, uConsts, uTextures, math;

procedure DrawSprite            (Sprite: TSprite; X, Y, Frame: LongInt);
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

// This is just temporary and becomes non public once everything changed to GL2
procedure UpdateModelview;
procedure ResetModelview;
procedure SetOffset(X, Y: Longint);
procedure ResetRotation;


implementation
uses uVariables, uStore;

const DegToRad =  0.01745329252; // 2PI / 360

procedure UpdateModelview;
begin
{$IFDEF GL2}
    UpdateModelviewProjection;
{$ELSE}
    glLoadMatrixf(@mModelview[0,0]);
{$ENDIF}
end;

procedure ResetModelview;
begin
    mModelview[0,0]:= 1.0; mModelview[1,0]:=0.0; mModelview[3,0]:= 0;
    mModelview[0,1]:= 0.0; mModelview[1,1]:=1.0; mModelview[3,1]:= 0;
    UpdateModelview;
end;

procedure SetOffset(X, Y: Longint);
begin
    mModelview[3,0]:= X;
    mModelview[3,1]:= Y;
end;

procedure AddOffset(X, Y: GLfloat); // probably want to refactor this to use integers
begin
    mModelview[3,0]:=mModelview[3,0] + mModelview[0,0]*X + mModelview[1,0]*Y;
    mModelview[3,1]:=mModelview[3,1] + mModelview[0,1]*X + mModelview[1,1]*Y;
end;

procedure SetScale(Scale: GLfloat);
begin
    mModelview[0,0]:= Scale;
    mModelview[1,1]:= Scale;
end;

procedure AddScale(Scale: GLfloat);
begin
    mModelview[0,0]:= mModelview[0,0]*Scale; mModelview[1,0]:= mModelview[1,0]*Scale;
    mModelview[0,1]:= mModelview[0,1]*Scale; mModelview[1,1]:= mModelview[1,1]*Scale;
end;

procedure AddScale(X, Y: GLfloat);
begin
    mModelview[0,0]:= mModelview[0,0]*X; mModelview[1,0]:= mModelview[1,0]*Y;
    mModelview[0,1]:= mModelview[0,1]*X; mModelview[1,1]:= mModelview[1,1]*Y;
end;


procedure SetRotation(Angle, ZAxis: GLfloat);
var s, c: Extended;
begin
    SinCos(Angle*DegToRad, s, c);
    mModelview[0,0]:= c;       mModelview[1,0]:=-s*ZAxis;
    mModelview[0,1]:= s*ZAxis; mModelview[1,1]:= c;
end;

procedure ResetRotation;
begin
    mModelview[0,0]:= 1.0; mModelview[1,0]:=0.0;
    mModelview[0,1]:= 0.0; mModelview[1,1]:=1.0;
end;

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
var 
    rr: TSDL_Rect;
    VertexBuffer, TextureBuffer: TVertexRect;
    _l, _r, _t, _b: GLfloat;
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

    glBindTexture(GL_TEXTURE_2D, SourceTexture^.atlas^.id);

    ComputeTexcoords(SourceTexture, r, @TextureBuffer);

    _l:= X + SourceTexture^.cropInfo.l;
    _r:= X + rr.w - SourceTexture^.cropInfo.l - SourceTexture^.cropInfo.r;
    _t:= Y + SourceTexture^.cropInfo.t;
    _b:= Y + rr.h - SourceTexture^.cropInfo.t - SourceTexture^.cropInfo.b;


    VertexBuffer[0].X:= _l;
    VertexBuffer[0].Y:= _t;
    VertexBuffer[1].X:= _r;
    VertexBuffer[1].Y:= _t;
    VertexBuffer[2].X:= _r;
    VertexBuffer[2].Y:= _b;
    VertexBuffer[3].X:= _l;
    VertexBuffer[3].Y:= _b;

    SetVertexPointer(@VertexBuffer[0]);
    //SetTexCoordPointer(@TextureBuffer[0]);
    SetTexCoordPointer(@SourceTexture^.tb[0]);
    glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));
end;

procedure DrawTexture(X, Y: LongInt; Texture: PTexture); inline;
begin
    DrawTexture(X, Y, Texture, 1.0);
end;

procedure DrawTexture(X, Y: LongInt; Texture: PTexture; Scale: GLfloat);
begin
SetOffset(X, Y);
ResetRotation;
SetScale(Scale);
UpdateModelview;

glBindTexture(GL_TEXTURE_2D, Texture^.atlas^.id);

SetVertexPointer(@Texture^.vb);
SetTexCoordPointer(@Texture^.tb);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(Texture^.vb));
ResetModelview;
end;

procedure DrawTextureF(Texture: PTexture; Scale: GLfloat; X, Y, Frame, Dir, w, h: LongInt);
begin
    DrawTextureRotatedF(Texture, Scale, 0, 0, X, Y, Frame, Dir, w, h, 0)
end;

procedure DrawTextureRotatedF(Texture: PTexture; Scale, OffsetX, OffsetY: GLfloat; X, Y, Frame, Dir, w, h: LongInt; Angle: real);
var hw, nx, ny: LongInt;
    r: TSDL_Rect;
    VertexBuffer, TextureBuffer: array [0..3] of TVertex2f;
    _l, _r, _t, _b: GLfloat;
begin

    while (Frame > 0) and (Texture <> nil) do
    begin
        Texture:= Texture^.nextFrame;
        dec(Frame);
    end;

    if Texture = nil then
        exit;

// do not draw anything outside the visible screen space (first check fixes some sprite drawing, e.g. hedgehogs)
if (abs(X) > W) and ((abs(X + dir * OffsetX) - W / 2) * cScaleFactor > cScreenWidth) then
    exit;
if (abs(Y) > H) and ((abs(Y + OffsetY - (0.5 * cScreenHeight)) - W / 2) * cScaleFactor > cScreenHeight) then
    exit;

SetOffset(X, Y);
if Dir = 0 then Dir:= 1;

SetRotation(Angle, Dir);
AddOffset(Dir*OffsetX, OffsetY);
AddScale(Scale);
UpdateModelview;

// Any reason for this call? And why only in t direction, not s?
//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

hw:= w div (2 div Dir);

r.y:=0;
r.x:=0;
r.w:=w;
r.h:=h;
ComputeTexcoords(Texture, @r, @TextureBuffer);

glBindTexture(GL_TEXTURE_2D, Texture^.atlas^.id);

_l:= -hw + Texture^.cropInfo.l;
_t:= w/-2 + Texture^.cropInfo.t;
_r:= hw - Texture^.cropInfo.l - Texture^.cropInfo.r;
_b:= w/2 - Texture^.cropInfo.t - Texture^.cropInfo.b;

VertexBuffer[0].X:= _l;
VertexBuffer[0].Y:= _t;
VertexBuffer[1].X:= _r;
VertexBuffer[1].Y:= _t;
VertexBuffer[2].X:= _r;
VertexBuffer[2].Y:= _b;
VertexBuffer[3].X:= _l;
VertexBuffer[3].Y:= _b;

SetVertexPointer(@VertexBuffer[0]);
//SetTexCoordPointer(@TextureBuffer[0]);
SetTexCoordPointer(@Texture^.tb[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

ResetModelview;
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
SetOffset(X, Y);
if Dir < 0 then
    SetRotation(Angle, -1.0)
else
    SetRotation(Angle, 1.0);
if Dir < 0 then
    AddScale(-1.0, 1.0);
UpdateModelview;

DrawSprite(Sprite, -SpritesData[Sprite].Width div 2, -SpritesData[Sprite].Height div 2, Frame);

ResetModelview;
end;

procedure DrawTextureRotated(Texture: PTexture; hw, hh, X, Y, Dir: LongInt; Angle: real);
var VertexBuffer: array [0..3] of TVertex2f;
    _l, _r, _t, _b: GLfloat;
begin
// do not draw anything outside the visible screen space (first check fixes some sprite drawing, e.g. hedgehogs)
if (abs(X) > 2 * hw) and ((abs(X) - hw) > cScreenWidth / cScaleFactor) then
    exit;
if (abs(Y) > 2 * hh) and ((abs(Y - 0.5 * cScreenHeight) - hh) > cScreenHeight / cScaleFactor) then
    exit;

SetOffset(X, Y);

if Dir < 0 then
    begin
    hw:= - hw;
    SetRotation(Angle, -1.0);
    end
else
    SetRotation(Angle, 1.0);
UpdateModelview;

glBindTexture(GL_TEXTURE_2D, Texture^.atlas^.id);

_l:= -hw + Texture^.cropInfo.l;
_t:= -hh + Texture^.cropInfo.t;
_r:= hw - Texture^.cropInfo.l - Texture^.cropInfo.r;
_b:= hh - Texture^.cropInfo.t - Texture^.cropInfo.b;

VertexBuffer[0].X:= _l;
VertexBuffer[0].Y:= _t;
VertexBuffer[1].X:= _r;
VertexBuffer[1].Y:= _t;
VertexBuffer[2].X:= _r;
VertexBuffer[2].Y:= _b;
VertexBuffer[3].X:= _l;
VertexBuffer[3].Y:= _b;

SetVertexPointer(@VertexBuffer[0]);
SetTexCoordPointer(@Texture^.tb);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

ResetModelview;
end;

procedure DrawSprite(Sprite: TSprite; X, Y, Frame: LongInt);
var 
    r: TSDL_Rect;
    tex: PTexture;
begin
    if SpritesData[Sprite].imageHeight = 0 then
        exit;

    tex:= SpritesData[Sprite].Texture;

    while (Frame > 0) and (tex <> nil) do
    begin
        tex:= tex^.nextFrame;
        dec(Frame);
    end;

    if (tex = nil) or (tex^.w = 0) or (tex^.h = 0) then
        exit;

    r.x:= 0;
    r.w:= SpritesData[Sprite].Width;
    r.y:= 0;
    r.h:= SpritesData[Sprite].Height;
    DrawTextureFromRect(X, Y, @r, tex)
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

    ResetRotation;
    SetOffset(WorldDx, WorldDy);
    UpdateModelview;
    glLineWidth(Width);

    Tint(r, g, b, a);
    VertexBuffer[0].X:= X0;
    VertexBuffer[0].Y:= Y0;
    VertexBuffer[1].X:= X1;
    VertexBuffer[1].Y:= Y1;

    SetVertexPointer(@VertexBuffer[0]);
    glDrawArrays(GL_LINES, 0, Length(VertexBuffer));
    Tint($FF, $FF, $FF, $FF);
    
    ResetModelview;
    
    glEnable(GL_TEXTURE_2D);
    glDisable(GL_LINE_SMOOTH);
end;

procedure DrawFillRect(r: TSDL_Rect);
var VertexBuffer: array [0..3] of TVertex2f;
begin
SetOffset(0, 0);
ResetRotation;
UpdateModelview;

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

SetVertexPointer(@VertexBuffer[0]);
glDrawArrays(GL_TRIANGLE_FAN, 0, Length(VertexBuffer));

Tint($FF, $FF, $FF, $FF);
glEnable(GL_TEXTURE_2D);

ResetModelview;
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
    SetOffset(0, 0);
    ResetRotation;
    UpdateModelview;
    glLineWidth(Width);
    SetVertexPointer(@CircleVertex[0]);
    glDrawArrays(GL_LINE_LOOP, 0, 60);
    glEnable(GL_TEXTURE_2D);
    glDisable(GL_LINE_SMOOTH);
    ResetModelview;
end;


procedure DrawHedgehog(X, Y: LongInt; Dir: LongInt; Pos, Step: LongWord; Angle: real);
const VertexBuffers: array[0..1] of TVertexRect = (
        ((x: -16; y: -16),
         (x:  16; y: -16),
         (x:  16; y:  16),
         (x: -16; y:  16)),
        ((x:  16; y: -16),
         (x: -16; y: -16),
         (x: -16; y:  16),
         (x:  16; y:  16)));
var r: TSDL_Rect;
    TextureBuffer: array [0..3] of TVertex2f;
begin
    // do not draw anything outside the visible screen space (first check fixes some sprite drawing, e.g. hedgehogs)
    if (abs(X) > 32) and ((abs(X) - 16) * cScaleFactor > cScreenWidth) then
        exit;
    if (abs(Y) > 32) and ((abs(Y - 0.5 * cScreenHeight) - 16) * cScaleFactor > cScreenHeight) then
        exit;

    r.x:=Step * 32;
    r.y:=Pos * 32;
    r.w:=32;
    r.h:=32;
    ComputeTexcoords(HHTexture, @r, @TextureBuffer);

    SetOffset(X, Y);
    SetRotation(Angle, 1.0);
    UpdateModelview;

    glBindTexture(GL_TEXTURE_2D, HHTexture^.atlas^.id);
    if Dir = -1 then
        SetVertexPointer(@VertexBuffers[1][0])
    else
        SetVertexPointer(@VertexBuffers[0][0]);
    SetTexCoordPointer(@TextureBuffer[0]);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

    ResetModelview;
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

end.

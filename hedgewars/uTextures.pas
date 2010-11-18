{$INCLUDE "options.inc"}

unit uTextures;
interface
uses SDLh, uTypes;

function  NewTexture(width, height: Longword; buf: Pointer): PTexture;
function  Surface2Tex(surf: PSDL_Surface; enableClamp: boolean): PTexture;
procedure FreeTexture(tex: PTexture);

procedure initModule;
procedure freeModule;

implementation
uses GLunit, uUtils, uVariables, uConsts, uMisc, uIO;

var TextureList: PTexture;


procedure SetTextureParameters(enableClamp: Boolean);
begin
    if enableClamp and ((cReducedQuality and rqClampLess) = 0) then
    begin
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE)
    end;
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
end;

procedure ResetVertexArrays(texture: PTexture);
begin
with texture^ do
    begin
    vb[0].X:= 0;
    vb[0].Y:= 0;
    vb[1].X:= w;
    vb[1].Y:= 0;
    vb[2].X:= w;
    vb[2].Y:= h;
    vb[3].X:= 0;
    vb[3].Y:= h;

    tb[0].X:= 0;
    tb[0].Y:= 0;
    tb[1].X:= rx;
    tb[1].Y:= 0;
    tb[2].X:= rx;
    tb[2].Y:= ry;
    tb[3].X:= 0;
    tb[3].Y:= ry
    end;
end;

function NewTexture(width, height: Longword; buf: Pointer): PTexture;
begin
new(NewTexture);
NewTexture^.PrevTexture:= nil;
NewTexture^.NextTexture:= nil;
NewTexture^.Scale:= 1;
if TextureList <> nil then
    begin
    TextureList^.PrevTexture:= NewTexture;
    NewTexture^.NextTexture:= TextureList
    end;
TextureList:= NewTexture;

NewTexture^.w:= width;
NewTexture^.h:= height;
NewTexture^.rx:= 1.0;
NewTexture^.ry:= 1.0;

ResetVertexArrays(NewTexture);

glGenTextures(1, @NewTexture^.id);

glBindTexture(GL_TEXTURE_2D, NewTexture^.id);
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, buf);

SetTextureParameters(true);
end;

function Surface2Tex(surf: PSDL_Surface; enableClamp: boolean): PTexture;
var tw, th, x, y: Longword;
    tmpp: pointer;
    fromP4, toP4: PLongWordArray;
begin
new(Surface2Tex);
Surface2Tex^.PrevTexture:= nil;
Surface2Tex^.NextTexture:= nil;
if TextureList <> nil then
    begin
    TextureList^.PrevTexture:= Surface2Tex;
    Surface2Tex^.NextTexture:= TextureList
    end;
TextureList:= Surface2Tex;

Surface2Tex^.w:= surf^.w;
Surface2Tex^.h:= surf^.h;

if (surf^.format^.BytesPerPixel <> 4) then
    begin
    TryDo(false, 'Surface2Tex failed, expecting 32 bit surface', true);
    Surface2Tex^.id:= 0;
    exit
    end;


glGenTextures(1, @Surface2Tex^.id);

glBindTexture(GL_TEXTURE_2D, Surface2Tex^.id);

if SDL_MustLock(surf) then
    SDLTry(SDL_LockSurface(surf) >= 0, true);

if (not SupportNPOTT) and (not (isPowerOf2(Surf^.w) and isPowerOf2(Surf^.h))) then
    begin
    tw:= toPowerOf2(Surf^.w);
    th:= toPowerOf2(Surf^.h);

    Surface2Tex^.rx:= Surf^.w / tw;
    Surface2Tex^.ry:= Surf^.h / th;

    GetMem(tmpp, tw * th * surf^.format^.BytesPerPixel);

    fromP4:= Surf^.pixels;
    toP4:= tmpp;

    for y:= 0 to Pred(Surf^.h) do
        begin
        for x:= 0 to Pred(Surf^.w) do toP4^[x]:= fromP4^[x];
        for x:= Surf^.w to Pred(tw) do toP4^[x]:= 0;
        toP4:= @(toP4^[tw]);
        fromP4:= @(fromP4^[Surf^.pitch div 4])
        end;

    for y:= Surf^.h to Pred(th) do
        begin
        for x:= 0 to Pred(tw) do toP4^[x]:= 0;
        toP4:= @(toP4^[tw])
        end;

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, tw, th, 0, GL_RGBA, GL_UNSIGNED_BYTE, tmpp);

    FreeMem(tmpp, tw * th * surf^.format^.BytesPerPixel)
    end
else
    begin
    Surface2Tex^.rx:= 1.0;
    Surface2Tex^.ry:= 1.0;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, surf^.w, surf^.h, 0, GL_RGBA, GL_UNSIGNED_BYTE, surf^.pixels);
    end;

ResetVertexArrays(Surface2Tex);

if SDL_MustLock(surf) then
    SDL_UnlockSurface(surf);

SetTextureParameters(enableClamp);
end;

procedure FreeTexture(tex: PTexture);
begin
    if tex <> nil then
    begin
        if tex^.NextTexture <> nil then
            tex^.NextTexture^.PrevTexture:= tex^.PrevTexture;
        if tex^.PrevTexture <> nil then
            tex^.PrevTexture^.NextTexture:= tex^.NextTexture
        else
            TextureList:= tex^.NextTexture;
        glDeleteTextures(1, @tex^.id);
        Dispose(tex);
    end
end;

procedure initModule;
begin
TextureList:= nil;
end;

procedure freeModule;
begin
    while TextureList <> nil do FreeTexture(TextureList);
end;

end.
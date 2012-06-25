{$INCLUDE "options.inc"}
{$IF GLunit = GL}{$DEFINE GLunit:=GL,GLext}{$ENDIF}

unit uAtlas;

interface

uses SDLh, uTypes;

procedure initModule;

function Surface2Tex_(surf: PSDL_Surface; enableClamp: boolean): PTexture;
procedure FreeTexture_(sprite: PTexture);

implementation

uses GLunit, uBinPacker, uDebug, png, sysutils;

const
    MaxAtlases = 1;    // Maximum number of atlases (textures) to allocate
    MaxTexSize = 4096; // Maximum atlas size in pixels
    MinTexSize = 128;  // Minimum atlas size in pixels
    CompressionThreshold = 0.4; // Try to compact (half the size of) an atlas, when occupancy is less than this

type
    AtlasInfo = record
        PackerInfo: Atlas;     // Rectangle packer context
        TextureInfo: TAtlas;   // OpenGL texture information
        Allocated: boolean;    // indicates if this atlas is in use
    end;

var
    Info: array[0..MaxAtlases-1] of AtlasInfo;


////////////////////////////////////////////////////////////////////////////////
// Debug routines

var
    DumpID: Integer;
    DumpFile: File of byte;

const
    PNG_COLOR_TYPE_RGBA = 6;
    PNG_COLOR_TYPE_RGB = 2;
    PNG_INTERLACE_NONE = 0;
    PNG_COMPRESSION_TYPE_DEFAULT = 0;
    PNG_FILTER_TYPE_DEFAULT = 0;
    


procedure writefunc(png: png_structp; buffer: png_bytep; size: QWord); cdecl;
var
    p: Pbyte;
    i: Integer;
begin
  //TStream(png_get_io_ptr(png)).Write(buffer^, size);
    BlockWrite(DumpFile, buffer^, size);
{    p:= PByte(buffer^);
    for i:=0 to pred(size) do
    begin
        Write(DumpFile, p^);
        inc(p);
    end;}
end;

function IntToStrPad(i: Integer): string;
var
  s: string;
begin
   s:= IntToStr(i);
   if (i < 10) then s:='0' + s;
   if (i < 100) then s:='0' + s;

   IntToStrPad:=s;
end;

procedure DumpAtlas(var info: AtlasInfo);
var
    png: png_structp;
    png_info: png_infop;
    w, h, sz: Integer;
    filename: string;
    rows: array of png_bytep;
    size: Integer;
    i, j: Integer;
    mem, p, pp: PByte;
begin
    filename:= '/home/wolfgangst/hedgewars/dump/atlas_' + IntToStrPad(DumpID) + '.png';
    Assign(DumpFile, filename);
    inc(DumpID);
    Rewrite(DumpFile);

    w:= info.TextureInfo.w;
    h:= info.TextureInfo.h;
    size:= w * h * 4;
    SetLength(rows, h);
    GetMem(mem, size);

    glBindTexture(GL_TEXTURE_2D, info.TextureInfo.id);

    glGetTexImage(GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, mem);

    p:= mem;
    for i:= 0 to pred(h) do
    begin
        rows[i]:= p;
        pp:= p;
        inc(pp, 3);
        {for j:= 0 to pred(w) do
        begin
            pp^:=255;
            inc(pp, 4);
        end;}
        inc(p, w * 4);
    end;

    png := png_create_write_struct(PNG_LIBPNG_VER_STRING, nil, nil, nil);
    png_info := png_create_info_struct(png);

    png_set_write_fn(png, nil, @writefunc, nil);
    png_set_IHDR(png, png_info, w, h, 8, PNG_COLOR_TYPE_RGBA, PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_DEFAULT);
    png_write_info(png, png_info);
    png_write_image(png, @rows[0]);
    png_write_end(png, png_info);
    png_destroy_write_struct(@png, @png_info);

    FreeMem(mem);
    
    SetLength(rows, 0);
    Close(DumpFile);

    //if (DumpID >= 30) then
    //    halt(0);
end;

////////////////////////////////////////////////////////////////////////////////
// Upload routines

function createTexture(width, height: Integer): TAtlas;
var
  nullTex: Pointer;
begin
    createTexture.w:= width;
    createTexture.h:= height;
    createTexture.priority:= 0;
    glGenTextures(1, @createTexture.id);
    glBindTexture(GL_TEXTURE_2D, createTexture.id);

    //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
    
    GetMem(NullTex, width * height * 4);
    FillChar(NullTex^, width * height * 4, 0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NullTex);
    FreeMem(NullTex);

    glBindTexture(GL_TEXTURE_2D, 0);
end;

function Min(x, y: Single): Single;
begin
  if x < y then
    Min:=x
  else Min:=y;
end;

function Max(x, y: Single): Single;
begin
  if x > y then
    Max:=x
  else Max:=y;
end;


procedure HSVToRGB(const H, S, V: Single; out R, G, B: Single); 
const 
    SectionSize = 60/360; 
var 
    Section: Single; 
    SectionIndex: Integer; 
    f: single; 
    p, q, t: Single; 
begin
    if H < 0 then 
    begin 
        R:= V; 
        G:= R; 
        B:= R; 
    end 
    else 
    begin 
        Section:= H/SectionSize; 
        SectionIndex:= Trunc(Section); 
        f:= Section - SectionIndex; 
        p:= V * ( 1 - S ); 
        q:= V * ( 1 - S * f ); 
        t:= V * ( 1 - S * ( 1 - f ) ); 
        case SectionIndex of 
            0: 
            begin 
                R:= V; 
                G:= t; 
                B:= p; 
            end; 
            1: 
            begin 
                R:= q; 
                G:= V; 
                B:= p; 
            end; 
            2: 
            begin 
                R:= p; 
                G:= V; 
                B:= t; 
            end; 
            3: 
            begin 
                R:= p; 
                G:= q; 
                B:= V; 
            end; 
            4: 
            begin 
                R:= t; 
                G:= p; 
                B:= V; 
            end; 
            else 
                R:= V; 
                G:= p; 
                B:= q; 
        end; 
    end; 
end; 

procedure DebugColorize(surf: PSDL_Surface);
var
    sz: Integer;
    p: PByte;
    i: Integer;
    r, g, b, a, inva: Integer;
    randr, randg, randb: Single;
    randh: Single;
begin
    sz:= surf^.w * surf^.h;
    p:= surf^.pixels;
    //randr:=Random;
    //randg:=Random;
    //randb:=1 - min(randr, randg);
    randh:=Random;
    HSVToRGB(randh, 1.0, 1.0, randr, randg, randb);
    for i:=0 to pred(sz) do
    begin
        a:= p[3];
        inva:= 255 - a;

        r:=Trunc(inva*randr + p[0]*a/255);
        g:=Trunc(inva*randg + p[1]*a/255);
        b:=Trunc(inva*randb + p[2]*a/255);
        if r > 255 then r:= 255;
        if g > 255 then g:= 255;
        if b > 255 then b:= 255;

        p[0]:=r;
        p[1]:=g;
        p[2]:=b;
        p[3]:=255;
        inc(p, 4);
    end;
end;

procedure Upload(var info: AtlasInfo; sprite: Rectangle; surf: PSDL_Surface);
var
    sp: PTexture;
    i, j, stride: Integer;
    scanline: PByte;
begin
    writeln('Uploading sprite to ', sprite.x, ',', sprite.y, ',', sprite.width, ',', sprite.height);
    sp:= PTexture(sprite.UserData);
    sp^.x:= sprite.x;
    sp^.y:= sprite.y;
    sp^.isRotated:= sp^.w <> sprite.width;
    sp^.atlas:= @info.TextureInfo;

    if SDL_MustLock(surf) then
        SDLTry(SDL_LockSurface(surf) >= 0, true);

    //if GrayScale then
    //    Surface2GrayScale(surf);
    DebugColorize(surf);

    glBindTexture(GL_TEXTURE_2D, info.TextureInfo.id);
    if (sp^.isRotated) then
    begin
        scanline:= surf^.pixels;
        for i:= 0 to pred(sprite.width) do
        begin
            glTexSubImage2D(GL_TEXTURE_2D, 0, sprite.x + i, sprite.y, 1, sprite.height, GL_RGBA, GL_UNSIGNED_BYTE, scanline);
            inc(scanline, sprite.height * 4);
        end;
    end
    else
        glTexSubImage2D(GL_TEXTURE_2D, 0, sprite.x, sprite.y, sprite.width, sprite.height, GL_RGBA, GL_UNSIGNED_BYTE, surf^.pixels);
    glBindTexture(GL_TEXTURE_2D, 0);

    if SDL_MustLock(surf) then
        SDL_UnlockSurface(surf);
end;

{$DEFINE HAS_PBO}
procedure Repack(var info: AtlasInfo; newAtlas: Atlas; newSprite: PTexture; surf: PSDL_Surface);
var
{$IFDEF HAS_PBO}
    pbo: GLuint;
{$ENDIF}
    base: PByte;
    oldSize: Integer;
    oldWidth: Integer;
    offset: Integer;
    i,j : Integer;
    r: Rectangle;
    sp: PTexture;
    newIsRotated: boolean;
    newSpriteRect: Rectangle;
begin
    writeln('Repacking atlas (', info.PackerInfo.width, 'x', info.PackerInfo.height, ')', ' -> (', newAtlas.width, 'x', newAtlas.height, ')');

{$IFDEF RETAIN_SURFACES}
    // we can simply re-upload from RAM

    // delete the old atlas
    glDeleteTextures(1, @info.TextureInfo.id);

    // create a new atlas with different size
    info.TextureInfo:= createTexture(newAtlas.width, newAtlas.height);
    glBindTexture(GL_TEXTURE_2D, info.TextureInfo.id);

    atlasDelete(info.PackerInfo);
    info.PackerInfo:= newAtlas;

    // and process all sprites of the new atlas
    for i:=0 to pred(newAtlas.usedRectangles.count) do
    begin
        r:= newAtlas.usedRectangles.data[i];
        sp:= PTexture(r.UserData);
        Upload(info, r, sp^.surface);
    end;

{$ELSE}
    // as we dont have access to the original sprites in ram anymore,
    // we need to copy from the existing atlas to an PBO, delete the original texture
    // and finally copy from the PBO back to the new texture object

    // allocate a PBO and copy from old atlas to it
    oldSize:= info.TextureInfo.w * info.TextureInfo.h * 4;
    oldWidth:= info.TextureInfo.w;

    glBindTexture(GL_TEXTURE_2D, info.TextureInfo.id);

{$IFDEF HAS_PBO}
    base:= nil;
    glGenBuffers(1, @pbo);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, pbo);
    glBufferData(GL_PIXEL_PACK_BUFFER, oldSize, nil, GL_COPY);
    //glGetTexImage( GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, nil);
    
    glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo);
{$ELSE}
    GetMem(base, oldSize);
    glGetTexImage( GL_TEXTURE_2D, 0, GL_RGBA, GL_UNSIGNED_BYTE, base);
{$ENDIF}

    // delete the old atlas
    glDeleteTextures(1, @info.TextureInfo.id);

    // create a new atlas with different size
    info.TextureInfo:= createTexture(newAtlas.width, newAtlas.height);
    glBindTexture(GL_TEXTURE_2D, info.TextureInfo.id);
    
    
    // and process all sprites of the new atlas
    for i:=0 to pred(newAtlas.usedRectangles.count) do
    begin
        r:= newAtlas.usedRectangles.data[i];
        sp:= PTexture(r.UserData);
        if sp = newSprite then // this is the to be added sprite
        begin
            // we need to do defer the upload till after this loop, 
            // as we currently upload from the PBO to texture
            newSpriteRect:= r;
            continue;
        end;

        newIsRotated:= sp^.w <> r.width;
        if newIsRotated <> sp^.isRotated then
        begin
            glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
            glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
            glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);
            offset:= sp^.x + sp^.y * oldWidth;
            for j:= 0 to pred(r.width) do
            begin
                glTexSubImage2D(GL_TEXTURE_2D, 0, r.x + j, r.y, 1, r.height, GL_RGBA, GL_UNSIGNED_BYTE, base + offset * 4);
                inc(offset, oldWidth);
            end;
        end 
        else
        begin
            glPixelStorei(GL_UNPACK_ROW_LENGTH, oldWidth);
            glPixelStorei(GL_UNPACK_SKIP_PIXELS, sp^.x);
            glPixelStorei(GL_UNPACK_SKIP_ROWS, sp^.y);
            glTexSubImage2D(GL_TEXTURE_2D, 0, r.x, r.y, r.width, r.height, GL_RGBA, GL_UNSIGNED_BYTE, base);
        end;

        sp^.x:= r.x;
        sp^.y:= r.y;
        sp^.isRotated:= newIsRotated;
        sp^.atlas:= @info.TextureInfo;
    end;
    glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glPixelStorei(GL_UNPACK_SKIP_PIXELS, 0);
    glPixelStorei(GL_UNPACK_SKIP_ROWS, 0);

    atlasDelete(info.PackerInfo);
    info.PackerInfo:= newAtlas;

{$IFDEF HAS_PBO}
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0);
    glDeleteBuffers(1, @pbo);
{$ELSE}
    FreeMem(base, oldSize);
{$ENDIF}

    // finally upload the new sprite (if any)
    if newSprite <> nil then
        Upload(info, newSpriteRect, surf);

    glBindTexture(GL_TEXTURE_2D, 0);
{$ENDIF}
end;


////////////////////////////////////////////////////////////////////////////////
// Utility functions

function SizeForSprite(sprite: PTexture): Size;
begin
    SizeForSprite.width:= sprite^.w;
    SizeForSprite.height:= sprite^.h;
    SizeForSprite.UserData:= sprite;
end;

procedure EnlargeSize(var x: Integer; var y: Integer);
begin
    if (y < x) then
        y:= y + y
    else
        x:= x + x;
end;

procedure CompactSize(var x: Integer; var y: Integer);
begin
    if (x > y) then
        x:= x div 2
    else
        y:= y div 2;
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite allocation logic

function TryRepack(var info: AtlasInfo; w, h: Integer; hasNewSprite: boolean; 
                   newSprite: Size; surf: PSDL_Surface): boolean;
var
    sizes: SizeList;
    repackedAtlas: Atlas;
    sprite: PTexture;
    i: Integer;
    rects: RectangleList; // we wont really need this as we do a full repack using the atlas later on
begin
    TryRepack:= false;

    // STEP 1: collect sizes of all existing sprites
    sizeListInit(sizes);
    for i:= 0 to pred(info.PackerInfo.usedRectangles.count) do
    begin
        sprite:= PTexture(info.PackerInfo.usedRectangles.data[i].UserData);
        sizeListAdd(sizes, SizeForSprite(sprite));
    end;

    // STEP 2: add the new sprite to the list
    if hasNewSprite then
        sizeListAdd(sizes, newSprite);

    // STEP 3: try to create a non adaptive re-packing using the whole list
    repackedAtlas:= atlasNew(w, h);
    rectangleListInit(rects);
    if atlasInsertSet(repackedAtlas, sizes, rects) then
    begin
        TryRepack:= true;
        if hasNewSprite then
            sprite:= PTexture(newSprite.UserData)
        else
            sprite:= nil;
        Repack(info, repackedAtlas, sprite, surf);
        // repack assigns repackedAtlas to the current info and deletes the old one
        // thus we wont do atlasDelete(repackedAtlas); here 
        rectangleListClear(rects);
        sizeListClear(sizes);
        DumpAtlas(info);
        exit;
    end;

    rectangleListClear(rects);
    sizeListClear(sizes);
    atlasDelete(repackedAtlas);
end;

function TryInsert(var info: AtlasInfo; newSprite: Size; surf: PSDL_Surface): boolean;
var
    rect: Rectangle;
    sprite: PTexture;
begin
    TryInsert:= false;

    if atlasInsertAdaptive(info.PackerInfo, newSprite, rect) then
    begin
        // we succeeded adaptivley allocating the sprite to the i'th atlas.
        Upload(info, rect, surf);
        DumpAtlas(info);
        TryInsert:= true;
    end;
end;

function Surface2Tex_(surf: PSDL_Surface; enableClamp: boolean): PTexture;
var
    sz: Size;
    sprite: PTexture;
    currentWidth, currentHeight: Integer;
    i: Integer;
begin
    if (surf^.w > MaxTexSize) or (surf^.h > MaxTexSize) then
    begin
        // we could at best downscale the sprite, abort for now
        writeln('Sprite size larger than maximum texture size');
        halt(-1);        
    end;

    // allocate the sprite
    new(sprite);
    Surface2Tex_:= sprite;

    sprite^.w:= surf^.w;
    sprite^.h:= surf^.h;
    sprite^.x:= 0;
    sprite^.y:= 0;
    sprite^.isRotated:= false;
    sprite^.surface:= surf;

    sz:= SizeForSprite(sprite);

    // STEP 1
    // try to allocate the new sprite in one of the existing atlases
    for i:= 0 to pred(MaxAtlases) do
    begin
        if not Info[i].Allocated then
            continue;
        if TryInsert(Info[i], sz, surf) then
            exit; 
    end;


    // STEP 2
    // none of the atlases has space left for the allocation, try a garbage collection
    for i:= 0 to pred(MaxAtlases) do
    begin
        if not Info[i].Allocated then
            continue;

        if TryRepack(Info[i], Info[i].PackerInfo.width, Info[i].PackerInfo.height, true, sz, surf) then
            exit;
    end;

    // STEP 3
    // none of the atlases could be repacked in a way to fit the new sprite, try enlarging
    for i:= 0 to pred(MaxAtlases) do
    begin
        if not Info[i].Allocated then
            continue;

        currentWidth:= Info[i].PackerInfo.width;
        currentHeight:= Info[i].PackerInfo.height;

        EnlargeSize(currentWidth, currentHeight);
        while (currentWidth <= MaxTexSize) and (currentHeight <= MaxTexSize) do
        begin
            if TryRepack(Info[i], currentWidth, currentHeight, true, sz, surf) then
                exit;
            EnlargeSize(currentWidth, currentHeight);
        end;
    end;

    // STEP 4
    // none of the existing atlases could be resized, try to allocate a new atlas
    for i:= 0 to pred(MaxAtlases) do
    begin
        if Info[i].Allocated then
            continue;

        currentWidth:= MinTexSize;
        currentHeight:= MinTexSize;
        while (sz.width > currentWidth) do
            currentWidth:= currentWidth + currentWidth;
        while (sz.height > currentHeight) do
            currentHeight:= currentHeight + currentHeight;

        with Info[i] do
        begin
            PackerInfo:= atlasNew(currentWidth, currentHeight);
            TextureInfo:= createTexture(currentWidth, currentHeight);
            Allocated:= true;
        end;

        if TryInsert(Info[i], sz, surf) then
            exit;

        // this shouldnt have happened, the rectpacker should be able to fit the sprite
        // into an unused rectangle that is the same size or larger than the requested sprite.
        writeln('Internal error: atlas allocation failed');
        halt(-1);
    end;

    // we reached the upperbound of resources we are willing to allocate
    writeln('Exhausted maximum sprite allocation size');
    halt(-1);
end;

////////////////////////////////////////////////////////////////////////////////
// Sprite deallocation logic


procedure FreeTexture_(sprite: PTexture);
var
    i, j, deleteAt: Integer;
    usedArea: Integer;
    totalArea: Integer;
    r: Rectangle;
    atlasW, atlasH: Integer;
    unused: Size;
begin
    if sprite = nil then
        exit;

    for i:= 0 to pred(MaxAtlases) do
    begin
        if sprite^.atlas <> @Info[i].TextureInfo then
            continue;

        usedArea:= 0;
        for j:=0 to pred(Info[i].PackerInfo.usedRectangles.count) do
        begin
            r:= Info[i].PackerInfo.usedRectangles.data[j];
            if r.UserData = sprite then
                deleteAt:= j
            else
                inc(usedArea, r.width * r.height);
        end;

        rectangleListRemoveAt(Info[i].PackerInfo.usedRectangles, j);
        dispose(sprite);

        while true do
        begin
            atlasW:= Info[i].PackerInfo.width;
            atlasH:= Info[i].PackerInfo.height;
            totalArea:=  atlasW * atlasH;
            if usedArea >= totalArea * CompressionThreshold then
                exit;

            if (atlasW = MinTexSize) and (atlasH = MinTexSize) then
                exit; // we could try to move everything from this to another atlas here

            CompactSize(atlasW, atlasH);
            unused:= unused;
            TryRepack(Info[i], atlasW, atlasH, false, unused, nil);
        end;
    end;
end;

procedure initModule;
var
    i: Integer;
begin
    DumpID:=0;
    for i:= 0 to pred(MaxAtlases) do
        Info[i].Allocated:= false;
end;

end.

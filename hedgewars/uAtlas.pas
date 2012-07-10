{$INCLUDE "options.inc"}
{$IF GLunit = GL}{$DEFINE GLunit:=GL,GLext}{$ENDIF}

unit uAtlas;

interface

uses SDLh, uTypes;

procedure initModule;

function Surface2Tex_(surf: PSDL_Surface; enableClamp: boolean): PTexture;
procedure FreeTexture_(sprite: PTexture);
procedure DebugAtlas;
procedure DumpInfo(tex: PTexture);

implementation

uses GLunit, uBinPacker, uDebug, png, sysutils, uTextures;

const
    MaxAtlases = 4;    // Maximum number of atlases (textures) to allocate
    MaxTexSize = 1024; // Maximum atlas size in pixels
    MinTexSize = 128;  // Minimum atlas size in pixels
    CompressionThreshold = 0.4; // Try to compact (half the size of) an atlas, when occupancy is less than this

type
    AtlasInfo = record
        PackerInfo: Atlas;     // Rectangle packer context
        TextureInfo: TAtlas;   // OpenGL texture information
        Allocated: boolean;    // indicates if this atlas is in use
        DumpID: Integer;
    end;

var
    Info: array[0..MaxAtlases-1] of AtlasInfo;


////////////////////////////////////////////////////////////////////////////////
// Debug routines

procedure DumpInfo(tex: PTexture);
var
    frame: Integer;
    i, atlasID: Integer;
    aw, ah: Integer;
begin
    if tex = nil then
        exit;

    frame:= 0;
    writeln(stdout, 'Texture: ' + IntToHex(Integer(tex), 8));

    while tex <> nil do
    begin
        atlasID:= -1;
        for i:= 0 to Pred(MaxAtlases) do
            if tex^.atlas = @Info[i].TextureInfo then
                atlasID:=i;

        aw:= tex^.atlas^.w;
        ah:= tex^.atlas^.h;   
 
        writeln(stdout, 'Frame   : ' + IntToStr(frame));
        writeln(stdout, 'Size    : ' + IntToStr(tex^.w) + 'x' + IntToStr(tex^.h));
        writeln(stdout, 'Atlas   : ' + IntToStr(atlasID));
        writeln(stdout, 'Location: ' + IntToStr(tex^.x) + 'x' + IntToStr(tex^.y));
        writeln(stdout, 'TB      : ' + '(' + FloatToStrF(tex^.tb[0].X, ffFixed, 15, 4) + ',' + FloatToStrF(tex^.tb[0].Y, ffFixed, 15, 4) + ') '
                                     + '(' + FloatToStrF(tex^.tb[1].X, ffFixed, 15, 4) + ',' + FloatToStrF(tex^.tb[1].Y, ffFixed, 15, 4) + ') '
                                     + '(' + FloatToStrF(tex^.tb[2].X, ffFixed, 15, 4) + ',' + FloatToStrF(tex^.tb[2].Y, ffFixed, 15, 4) + ') '
                                     + '(' + FloatToStrF(tex^.tb[3].X, ffFixed, 15, 4) + ',' + FloatToStrF(tex^.tb[3].Y, ffFixed, 15, 4) + ')');

        writeln(stdout, 'TB.ABS  : ' + '(' + FloatToStrF(tex^.tb[0].X * aw, ffFixed, 15, 4) + ',' + FloatToStrF(tex^.tb[0].Y * ah, ffFixed, 15, 4) + ') '
                                     + '(' + FloatToStrF(tex^.tb[1].X * aw, ffFixed, 15, 4) + ',' + FloatToStrF(tex^.tb[1].Y * ah, ffFixed, 15, 4) + ') '
                                     + '(' + FloatToStrF(tex^.tb[2].X * aw, ffFixed, 15, 4) + ',' + FloatToStrF(tex^.tb[2].Y * ah, ffFixed, 15, 4) + ') '
                                     + '(' + FloatToStrF(tex^.tb[3].X * aw, ffFixed, 15, 4) + ',' + FloatToStrF(tex^.tb[3].Y * ah, ffFixed, 15, 4) + ')');

        inc(frame);
        tex:= tex^.nextFrame;
    end;
    halt(0);
end;

procedure AssertCount(tex: PTexture; count: Integer);
var
    i, j: Integer;
    found: Integer;
begin
    found:= 0;
    for i:= 0 to pred(MaxAtlases) do
    begin
        if not Info[i].Allocated then
            continue;
        for j:=0 to pred(Info[i].PackerInfo.usedRectangles.count) do
        begin
            if Info[i].PackerInfo.usedRectangles.data[j].UserData = tex then
                inc(found);
        end;
    end;
    if found <> count then
    begin
        writeln('AssertCount(', IntToHex(Integer(tex), 8), ') failed, found ', found, ' times');

        for i:= 0 to pred(MaxAtlases) do
        begin
            if not Info[i].Allocated then
                continue;
            for j:=0 to pred(Info[i].PackerInfo.usedRectangles.count) do
            begin
                if Info[i].PackerInfo.usedRectangles.data[j].UserData = tex then
                    writeln(' found in atlas ', i, ' at slot ', j);
            end;
        end;
        halt(-2);
    end;
end;

var
    DumpFile: File of byte;

const
    PNG_COLOR_TYPE_RGBA = 6;
    PNG_COLOR_TYPE_RGB = 2;
    PNG_INTERLACE_NONE = 0;
    PNG_COMPRESSION_TYPE_DEFAULT = 0;
    PNG_FILTER_TYPE_DEFAULT = 0;
    


procedure writefunc(png: png_structp; buffer: png_bytep; size: QWord); cdecl;
begin
    BlockWrite(DumpFile, buffer^, size);
end;

function IntToStrPad(i: Integer): string;
var
  s: string;
begin
   s:= IntToStr(i);
   if (i < 10) then s:='0' + s;
   if (i < 100) then s:='0' + s;
   if (i < 1000) then s:='0' + s;

   IntToStrPad:=s;
end;

// GL1 ATLAS DEBUG ONLY CODE!
procedure DebugAtlas;
{$IFDEF DEBUG_ATLAS}
var
    vp: array[0..3] of GLint;
    prog: GLint;
    i: Integer;
    x, y: Integer;
const
    SZ = 512;
begin
    x:= 0;
    y:= 0;
    for i:= 0 to pred(MaxAtlases) do
    begin
        if not Info[i].allocated then
            continue;
        glGetIntegerv(GL_VIEWPORT, @vp);
{$IFDEF GL2}
        glGetIntegerv(GL_CURRENT_PROGRAM, @prog);
        glUseProgram(0);
{$ENDIF}
        glPushMatrix;
        glLoadIdentity;
        glMatrixMode(GL_PROJECTION);
        glPushMatrix;
        glLoadIdentity;
        glOrtho(0, vp[2], vp[3], 0, -1, 1);

        glDisable(GL_CULL_FACE);

        glBindTexture(GL_TEXTURE_2D, Info[i].TextureInfo.id);
        glBegin(GL_QUADS);
        glTexCoord2f(0.0, 0.0);
        glVertex2i(x * SZ, y * SZ);
        glTexCoord2f(1.0, 0.0);
        glVertex2i((x + 1) * SZ, y * SZ);
        glTexCoord2f(1.0, 1.0);
        glVertex2i((x + 1) * SZ, (y + 1) * SZ);
        glTexCoord2f(0.0, 1.0);
        glVertex2i(x * SZ, (y + 1) * SZ);
        glEnd();

        glPopMatrix;
        glMatrixMode(GL_MODELVIEW);
        glPopMatrix;

        inc(x);
        if (x = 2) then
        begin
            x:=0;
            inc(y);
        end;
     
{$IFDEF GL2}
        glUseProgram(prog);
{$ENDIF}
    end;
end;
{$ELSE}
begin;
end;
{$ENDIF}

procedure DumpAtlas(var dinfo: AtlasInfo);
var
    png: png_structp;
    png_info: png_infop;
    w, h, sz: Integer;
    filename: string;
    rows: array of png_bytep;
    size: Integer;
    i, j: Integer;
    idx: Integer;
    mem, p, pp: PByte;
begin
    idx:= -1;
    for i:= 0 to Pred(MaxAtlases) do
        if @dinfo = @Info[i] then
            idx:=i;

    filename:= '/home/wolfgangst/hedgewars/dump/atlas_' + IntToStr(idx) + '_' + IntToStrPad(dinfo.DumpID) + '.png';
    Assign(DumpFile, filename);
    inc(dinfo.DumpID);
    Rewrite(DumpFile);

    w:= dinfo.TextureInfo.w;
    h:= dinfo.TextureInfo.h;
    size:= w * h * 4;
    SetLength(rows, h);
    GetMem(mem, size);

    glBindTexture(GL_TEXTURE_2D, dinfo.TextureInfo.id);

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

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

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

procedure DebugChecker(surf: PSDL_Surface);
var
    sz: Integer;
    p, q: PByte;
    randr, randg, randb: Single;
    randrb, randgb, randbb: Byte;
    randh: Single;
    x, y: Integer;
begin
    sz:= surf^.w * surf^.h;
    p:= surf^.pixels;
    randh:=Random;
    HSVToRGB(randh, 1.0, 1.0, randr, randg, randb);
    randrb:= Trunc(255*randr);
    randgb:= Trunc(255*randg);
    randbb:= Trunc(255*randb);

    p:= surf^.pixels;
    for y:=0 to Pred(surf^.h) do
    begin
        q:= p;
        for x:=0 to Pred(surf^.w) do
        begin
            if ((x xor y) and 1) = 1 then
            begin
                q[0]:= randrb;
                q[1]:= randgb;
                q[2]:= randbb;
                q[3]:= 255;
            end else
            begin
                q[0]:= 0;
                q[1]:= 0;
                q[2]:= 0;
                q[3]:= 255;
            end;
            inc(q, 4);
        end;
        inc(p, surf^.pitch);
    end;
    
end;


procedure Upload(var info: AtlasInfo; sprite: Rectangle; surf: PSDL_Surface);
var
    sp: PTexture;
    i, j, stride: Integer;
    scanline: PByte;
    r: TSDL_Rect;
begin
    //writeln('Uploading sprite to ', sprite.x, ',', sprite.y, ',', sprite.width, ',', sprite.height);
    sp:= PTexture(sprite.UserData);
    sp^.x:= sprite.x;
    sp^.y:= sprite.y;
    sp^.isRotated:= sp^.w <> sprite.width;
    sp^.atlas:= @info.TextureInfo;

    if SDL_MustLock(surf) then
        SDLTry(SDL_LockSurface(surf) >= 0, true);

    //if GrayScale then
    //    Surface2GrayScale(surf);
    //DebugColorize(surf);
    DebugChecker(surf);

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

    r.x:= 0;
    r.y:= 0;
    r.w:= sp^.w;
    r.h:= sp^.h;
    ComputeTexcoords(sp, @r, @sp^.tb);
end;

procedure Repack(var info: AtlasInfo; newAtlas: Atlas);
var
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

    glBindTexture(GL_TEXTURE_2D, 0);
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

function TryRepack(var info: AtlasInfo; w, h: Integer; hasNewSprite: boolean; newSprite: Size): boolean;
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
        Repack(info, repackedAtlas);
        // repack assigns repackedAtlas to the current info and deletes the old one
        // thus we wont do atlasDelete(repackedAtlas); here 
        rectangleListClear(rects);
        sizeListClear(sizes);
        //DumpAtlas(info);
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
        //DumpAtlas(info);
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
    sprite^.shared:= true;
    sprite^.nextFrame:= nil;

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

        if TryRepack(Info[i], Info[i].PackerInfo.width, Info[i].PackerInfo.height, true, sz) then
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
            if TryRepack(Info[i], currentWidth, currentHeight, true, sz) then
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

    deleteAt:= -1;
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

        rectangleListRemoveAt(Info[i].PackerInfo.usedRectangles, deleteAt);
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
            TryRepack(Info[i], atlasW, atlasH, false, unused);
        end;

        exit;
    end;
end;

procedure initModule;
var
    i: Integer;
begin
    for i:= 0 to pred(MaxAtlases) do
    begin
        Info[i].Allocated:= false;
        Info[i].DumpID:=0;
    end;
end;

end.

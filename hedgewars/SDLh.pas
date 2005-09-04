(*
 * Hedgewars, a worms-like game
 * Copyright (c) 2004, 2005 Andrey Korotaev <unC0Rr@gmail.com>
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

unit SDLh;
interface
{$IFDEF LINUX}
{$DEFINE UNIX}
{$ENDIF}
{$IFDEF FREEBSD}
{$DEFINE UNIX}
{$ENDIF}

{$IFDEF UNIX}
{$linklib c}
{$linklib pthread}  // кажется, это только для FreeBSD, не уверен
{$ENDIF}

{$IFDEF FPC}
  {$MODE Delphi}
  {$PACKRECORDS 4}
{$ENDIF}

(*  SDL *)
const {$IFDEF WIN32}
      SDLLibName = 'SDL.dll';
      {$ENDIF}
      {$IFDEF UNIX}
      SDLLibName = 'libSDL.so';
      {$ENDIF}
      SDL_SWSURFACE   = $00000000;
      SDL_HWSURFACE   = $00000001;
      SDL_ASYNCBLIT   = $00000004;
      SDL_ANYFORMAT   = $10000000;
      SDL_HWPALETTE   = $20000000;
      SDL_DOUBLEBUF   = $40000000;
      SDL_FULLSCREEN  = $80000000;
      SDL_NOFRAME     = $00000020;
      SDL_HWACCEL     = $00000100;
      SDL_SRCCOLORKEY = $00001000;
      SDL_RLEACCEL    = $00004000;
      
      SDL_NOEVENT     = 0;
      SDL_KEYDOWN     = 2;
      SDL_KEYUP       = 3;
      SDL_QUITEV      = 12;

      SDL_INIT_VIDEO  = $00000020;
      SDL_INIT_AUDIO  = $00000010;
      
type PSDL_Rect = ^TSDL_Rect;
     TSDL_Rect = record
                 x, y: SmallInt;
                 w, h: Word;
                 end;

     TPoint = record
              x: Integer;
              y: Integer;
              end;

     PSDL_PixelFormat = ^TSDL_PixelFormat;
     TSDL_PixelFormat = record
                        palette: Pointer;
                        BitsPerPixel : Byte;
                        BytesPerPixel: Byte;
                        Rloss : Byte;
                        Gloss : Byte;
                        Bloss : Byte;
                        Aloss : Byte;
                        Rshift: Byte;
                        Gshift: Byte;
                        Bshift: Byte;
                        Ashift: Byte;
                        RMask : Longword;
                        GMask : Longword;
                        BMask : Longword;
                        AMask : Longword;
                        colorkey: Longword;
                        alpha : Byte;
                        end;


     PSDL_Surface = ^TSDL_Surface;
     TSDL_Surface = record
                    flags : Longword;
                    format: PSDL_PixelFormat;
                    w, h  : Integer;
                    pitch : Word;
                    pixels: Pointer;
                    offset: Integer;
                    hwdata: Pointer;
                    clip_rect: TSDL_Rect;
                    unused1,
                    locked   : Longword;
                    Blitmap  : Pointer;
                    format_version: Longword;
                    refcount : Integer;
                    end;

     PSDL_Color = ^TSDL_Color;
     TSDL_Color = record
                  r: Byte;
                  g: Byte;
                  b: Byte;
                  a: Byte;
                  end;

     PSDL_RWops = ^TSDL_RWops;
     TSeek = function( context: PSDL_RWops; offset: Integer; whence: Integer ): Integer; cdecl;
     TRead = function( context: PSDL_RWops; Ptr: Pointer; size: Integer; maxnum : Integer ): Integer;  cdecl;
     TWrite = function( context: PSDL_RWops; Ptr: Pointer; size: Integer; num: Integer ): Integer; cdecl;
     TClose = function( context: PSDL_RWops ): Integer; cdecl;

     TStdio = record
              autoclose: Integer;
              fp: pointer;
              end;

     TMem = record
            base: PByte;
            here: PByte;
            stop: PByte;
            end;

     TUnknown = record
                data1: Pointer;
                end;

     TSDL_RWops = record
                  seek: TSeek;
                  read: TRead;
                  write: TWrite;
                  close: TClose;
                  type_: Longword;
                  case Byte of
                       0: (stdio: TStdio);
                       1: (mem: TMem);
                       2: (unknown: TUnknown);
                       end;

     TSDL_KeySym = record
                   scancode: Byte;
                   sym,
                   modifier: Longword;
                   unicode: Word;
                   end;

     TSDL_KeyboardEvent = record
                          type_: Byte;
                          which: Byte;
                          state: Byte;
                          keysym: TSDL_KeySym;
                          end;

     TSDL_QuitEvent = record
                      type_: Byte;
                      end;
     PSDL_Event = ^TSDL_Event;
     TSDL_Event = record
                  case Byte of
                       SDL_NOEVENT: (type_: byte);
                       SDL_KEYDOWN, SDL_KEYUP: (key: TSDL_KeyboardEvent);
                       SDL_QUITEV: (quit: TSDL_QuitEvent);
                       end;

     PByteArray = ^TByteArray;
     TByteArray = array[0..32767] of Byte;

function  SDL_Init(flags: Longword): Integer; cdecl; external SDLLibName;
procedure SDL_Quit; cdecl; external SDLLibName;

procedure SDL_Delay(msec: Longword); cdecl; external SDLLibName;
function  SDL_GetTicks: Longword; cdecl; external SDLLibName;

function  SDL_MustLock(Surface: PSDL_Surface): Boolean;
function  SDL_LockSurface(Surface: PSDL_Surface): Integer; cdecl; external SDLLibName;
procedure SDL_UnlockSurface(Surface: PSDL_Surface); cdecl; external SDLLibName;

function  SDL_GetError: PChar; cdecl; external SDLLibName;

function  SDL_SetVideoMode(width, height, bpp: Integer; flags: Longword): PSDL_Surface; cdecl; external SDLLibName;
function  SDL_CreateRGBSurface(flags: Longword; Width, Height, Depth: Integer; RMask, GMask, BMask, AMask: Longword): PSDL_Surface; cdecl; external SDLLibName;
function  SDL_CreateRGBSurfaceFrom(pixels: Pointer; width, height, depth, pitch: Integer; RMask, GMask, BMask, AMask: Longword): PSDL_Surface; cdecl; external SDLLibName;
procedure SDL_FreeSurface(Surface: PSDL_Surface); cdecl; external SDLLibName;
function  SDL_SetColorKey(surface: PSDL_Surface; flag, key: Longword): Integer; cdecl; external SDLLibName;

function  SDL_UpperBlit(src: PSDL_Surface; srcrect: PSDL_Rect; dst: PSDL_Surface; dstrect: PSDL_Rect): Integer; cdecl; external SDLLibName;
function  SDL_FillRect(dst: PSDL_Surface; dstrect: PSDL_Rect; color: Longword): Integer; cdecl; external SDLLibName;
procedure SDL_UpdateRect(Screen: PSDL_Surface; x, y: Integer; w, h: Longword); cdecl; external SDLLibName;
function  SDL_Flip(Screen: PSDL_Surface): Integer; cdecl; external SDLLibName;

procedure SDL_GetRGB(pixel: Longword; fmt: PSDL_PixelFormat; r, g, b: PByte); cdecl; external SDLLibName;
function  SDL_MapRGB(format: PSDL_PixelFormat; r, g, b: Byte): Integer; cdecl; external SDLLibName;

function  SDL_DisplayFormat(Surface: PSDL_Surface): PSDL_Surface; cdecl; external SDLLibName;

function  SDL_RWFromFile(filename, mode: PChar): PSDL_RWops; cdecl; external SDLLibName;
function  SDL_SaveBMP_RW(surface: PSDL_Surface; dst: PSDL_RWops; freedst: Integer): Integer; cdecl; external SDLLibName;

function  SDL_GetKeyState(numkeys: PInteger): PByteArray; cdecl; external SDLLibName;
function  SDL_GetMouseState(x, y: PInteger): Byte; cdecl; external SDLLibName;
function  SDL_GetKeyName(key: Longword): PChar; cdecl; external SDLLibName;
procedure SDL_WarpMouse(x, y: Word); cdecl; external SDLLibName;

function  SDL_PollEvent(event: PSDL_Event): Integer; cdecl; external SDLLibName;

function  SDL_ShowCursor(toggle: Integer): Integer; cdecl; external SDLLibName;

procedure SDL_WM_SetCaption(title: PChar; icon: PChar); cdecl; external SDLLibName;

(*  TTF  *)

const {$IFDEF WIN32}
      SDL_TTFLibName = 'SDL_ttf.dll';
      {$ENDIF}
      {$IFDEF UNIX}
      SDL_TTFLibName = 'libSDL_ttf.so';
      {$ENDIF}


type PTTF_Font = ^TTTF_font;
     TTTF_Font = record
                 end;

function TTF_Init: integer; cdecl; external SDL_TTFLibName;
procedure TTF_Quit; cdecl; external SDL_TTFLibName;


function TTF_SizeText(font : PTTF_Font; const text: PChar; var w, h: integer): Integer; cdecl; external SDL_TTFLibName;
function TTF_RenderText_Solid(font : PTTF_Font; const text: PChar; fg: TSDL_Color): PSDL_Surface; cdecl; external SDL_TTFLibName;
function TTF_RenderText_Blended(font : PTTF_Font; const text: PChar; fg: TSDL_Color): PSDL_Surface; cdecl; external SDL_TTFLibName;
function TTF_OpenFont(const filename: Pchar; size: integer): PTTF_Font; cdecl; external SDL_TTFLibName;

(*  SDL_mixer *)

const {$IFDEF WIN32}
      SDL_MixerLibName = 'SDL_mixer.dll';
      {$ENDIF}
      {$IFDEF UNIX}
      SDL_MixerLibName = 'libSDL_mixer.so';
      {$ENDIF}

type PMixChunk = ^TMixChunk;
     TMixChunk = record
                 allocated: Longword;
                 abuf     : PByte;
                 alen     : Longword;
                 volume   : PByte;
                  end;
     TMusic = (MUS_CMD, MUS_WAV, MUS_MOD, MUS_MID, MUS_OGG, MUS_MP3);
     TMix_Fading = (MIX_NO_FADING, MIX_FADING_OUT, MIX_FADING_IN);

     TMidiSong = record
               samples : Integer;
               events  : pointer;
               end;

     TMusicUnion = record
        case Byte of
             0: ( midi : TMidiSong );
             1: ( ogg  : pointer);
             end;

     PMixMusic = ^TMixMusic;
     TMixMusic = record
                 type_  : TMusic;
                 data   : TMusicUnion;
                 fading : TMix_Fading;
                 fade_volume,
                 fade_step,
                 fade_steps,
                 error  : integer;
                 end;

function  Mix_OpenAudio(frequency: integer; format: Word; channels: integer; chunksize: integer): integer; cdecl; external SDL_MixerLibName;
procedure Mix_CloseAudio; cdecl; external SDL_MixerLibName;

function  Mix_VolumeMusic(volume: integer): integer; cdecl; external SDL_MixerLibName;

function Mix_AllocateChannels(numchans: integer): integer; cdecl; external SDL_MixerLibName;
procedure Mix_FreeChunk(chunk: PMixChunk); cdecl; external SDL_MixerLibName;
procedure Mix_FreeMusic(music: PMixMusic); cdecl; external SDL_MixerLibName;

function  Mix_LoadWAV_RW(src: PSDL_RWops; freesrc: integer): PMixChunk; cdecl; external SDL_MixerLibName;
function  Mix_LoadMUS(const filename: PChar): PMixMusic; cdecl; external SDL_MixerLibName;

function  Mix_Playing(channel: integer): integer; cdecl; external SDL_MixerLibName;
function  Mix_PlayingMusic: integer; cdecl; external SDL_MixerLibName;

function  Mix_PlayChannelTimed(channel: integer; chunk: PMixChunk; loops: integer; ticks: integer): integer; cdecl; external SDL_MixerLibName;
function  Mix_PlayMusic(music: PMixMusic; loops: integer): integer; cdecl; external SDL_MixerLibName;
function  Mix_HaltChannel(channel: integer): integer; cdecl; external SDL_MixerLibName;

(*  SDL_image *)

const {$IFDEF WIN32}
      SDL_ImageLibName = 'SDL_image.dll';
      {$ENDIF}
      {$IFDEF UNIX}
      SDL_ImageLibName = 'libSDL_image.so';
      {$ENDIF}

function IMG_Load(const _file: PChar): PSDL_Surface; cdecl; external SDL_ImageLibName;

(*  SDL_net *)

const {$IFDEF WIN32}
      SDL_NetLibName = 'SDL_net.dll';
      {$ENDIF}
      {$IFDEF UNIX}
      SDL_NetLibName = 'libSDL_net.so';
      {$ENDIF}

type TIPAddress = record
                  host: Longword;
                  port: Word;
                  end;

     PTCPSocket = ^TTCPSocket;
     TTCPSocket = record
                  ready,
                  channel: integer;
                  remoteAddress,
                  localAddress: TIPaddress;
                  sflag: integer;
                  end;
     PSDLNet_SocketSet = ^TSDLNet_SocketSet;
     TSDLNet_SocketSet = record
                         numsockets,
                         maxsockets: integer;
                         sockets: PTCPSocket;
                         end;

function SDLNet_Init: integer; cdecl; external SDL_NetLibName;
procedure SDLNet_Quit; cdecl; external SDL_NetLibName;

function SDLNet_AllocSocketSet(maxsockets: integer): PSDLNet_SocketSet; cdecl; external SDL_NetLibName;
function SDLNet_ResolveHost(var address: TIPaddress; host: PCHar; port: Word): integer; cdecl; external SDL_NetLibName;
function SDLNet_TCP_Accept(server: PTCPsocket): PTCPSocket; cdecl; external SDL_NetLibName;
function SDLNet_TCP_Open(var ip: TIPaddress): PTCPSocket; cdecl; external SDL_NetLibName;
function SDLNet_TCP_Send(sock: PTCPsocket; data: Pointer; len: integer): integer; cdecl; external SDL_NetLibName;
function SDLNet_TCP_Recv(sock: PTCPsocket; data: Pointer; len: integer): integer; cdecl; external SDL_NetLibName;
procedure SDLNet_TCP_Close(sock: PTCPsocket); cdecl; external SDL_NetLibName;
procedure SDLNet_FreeSocketSet(_set: PSDLNet_SocketSet); cdecl; external SDL_NetLibName;
function SDLNet_AddSocket(_set: PSDLNet_SocketSet; sock: PTCPSocket): integer; cdecl; external SDL_NetLibName;
function SDLNet_CheckSockets(_set: PSDLNet_SocketSet; timeout: integer): integer; cdecl; external SDL_NetLibName;


implementation

function SDL_MustLock(Surface: PSDL_Surface): Boolean;
begin
Result:= ( surface^.offset <> 0 )
       or(( surface^.flags and (SDL_HWSURFACE or SDL_ASYNCBLIT or SDL_RLEACCEL)) <> 0)
end;

end.
